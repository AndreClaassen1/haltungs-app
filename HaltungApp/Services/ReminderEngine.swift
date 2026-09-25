import Foundation
import SwiftData
import Observation
import HaltungCore

/// Treibende Engine der App. Haelt Phase und Sitzungsstart, taktet einen Timer,
/// nutzt den reinen Scheduler aus HaltungCore und steuert Notifications und
/// Overlay. Liest die konfigurierbaren Erinnerungen frisch aus SwiftData.
///
/// Jede aktive Erinnerung laeuft in ihrem eigenen, unabhaengigen Takt (Basis:
/// letzte Ausloesung plus Intervall). Werden mehrere gleichzeitig faellig,
/// entscheidet die Prioritaet (bei Gleichstand die fruehere Faelligkeit) — pro
/// Tick feuert nur eine, die uebrigen ruecken beim naechsten Tick nach.
@MainActor
@Observable
final class ReminderEngine {
    private let context: ModelContext
    private let notifications: NotificationService
    private let overlay: OverlayController
    private let scheduler = ReminderScheduler()

    /// Aktuelle Haltung, gespiegelt im Menubar-Icon.
    var currentPhase: Phase = .sitting
    /// Naechster Faelligkeitszeitpunkt fuer die Anzeige.
    private(set) var nextDueDate: Date?
    /// Name der naechsten faelligen Erinnerung (fuer die Kopfzeile).
    private(set) var nextReminderName: String?
    /// Gerade praesentierte Erinnerung (Overlay aktiv), verhindert Stapeln.
    private(set) var presented: ReminderConfig?
    /// Editierbare Erinnerungs-Modelle fuer die Einstellungs-Tabelle. Wird von
    /// der Engine aus demselben Kontext gepflegt, der auch das Scheduling speist.
    private(set) var reminderModels: [ReminderTypeModel] = []
    /// Projizierte Faelligkeit je Erinnerung fuer die "in X min"-Anzeige.
    private(set) var projectedDue: [UUID: Date] = [:]
    /// Ende der globalen Stummschaltung, nil wenn nicht stummgeschaltet.
    /// Spiegelt den persistierten Wert fuer die UI; der Tick raeumt ihn auf,
    /// sobald die Stille abgelaufen ist.
    private(set) var mutedUntil: Date?

    private let sessionStart = Date()
    /// Letzte Ausloesung je Erinnerung — Basis fuer den unabhaengigen Takt.
    private var lastFired: [UUID: Date] = [:]
    /// Kurz-Snooze je Erinnerung: explizit gesetzter naechster Faelligkeitszeitpunkt,
    /// der den regulaeren Takt voruebergehend ersetzt. Bewusst nur im Speicher —
    /// ein Snooze ist kurzlebig und muss einen Neustart nicht ueberleben.
    private var snoozedUntil: [UUID: Date] = [:]
    private var tickTask: Task<Void, Never>?

    init(context: ModelContext, notifications: NotificationService, overlay: OverlayController) {
        self.context = context
        self.notifications = notifications
        self.overlay = overlay
        seedIfNeeded()
        refreshReminderModels()
        migrateLegacyUmlauts()
        backfillVideoURLs()
        hydrateLastFired()
        restorePhase()
        mutedUntil = AppSettings.current().muteUntil
        recomputeNextDue()
        notifications.configure()
        notifications.onTap = { [weak self] id in
            self?.showInfo(forID: id)
        }
    }

    // MARK: - Zustand wiederherstellen

    /// Laedt die persistierten Ausloese-Zeitpunkte aus den Modellen, damit Timer
    /// und Countdown einen kurzen Neustart ueberstehen. Einzelne Takte, deren
    /// letzte Ausloesung laenger als die Sitzungsluecke zurueckliegt (Pause,
    /// Feierabend, Tageswechsel), werden verworfen und starten frisch ab
    /// Sitzungsstart, statt sofort faellig zu sein.
    private func hydrateLastFired() {
        let persisted = Dictionary(
            uniqueKeysWithValues: reminderModels.compactMap { model in
                model.lastFired.map { (model.id, $0) }
            }
        )
        lastFired = scheduler.freshLastFired(persisted, now: sessionStart)
    }

    /// Stellt die aktuelle Phase aus dem heutigen Ereignis-Log her: jeder
    /// bestaetigte Sitz-Steh-Wechsel kippt die Phase, Start ist Sitzen.
    private func restorePhase() {
        let dayStart = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<EventLogModel>(
            predicate: #Predicate { $0.date >= dayStart }
        )
        let events = ((try? context.fetch(descriptor)) ?? []).map(\.event)
        let switches = events.filter { $0.kind == .sitStand && $0.outcome == .completed }.count
        currentPhase = switches % 2 == 0 ? .sitting : .standing
    }

    /// Ersetzt unveraenderte Standard-Erinnerungen, die noch die alten
    /// ASCII-Schreibungen tragen, durch die korrekten Umlaut-Defaults. Vom Nutzer
    /// editierte Zeilen bleiben unangetastet, da sie nicht exakt den Alt-Werten gleichen.
    private func migrateLegacyUmlauts() {
        let current = Dictionary(
            DefaultReminders.makeAll().map { ($0.kind, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let legacy: [ReminderKind: (name: String, cue: String)] = [
            .mobility: (
                "Mobilisationsuebung",
                "Mobilisation: Kinn zuruecknehmen (Chin-Tuck), Brustkorb oeffnen, Schultern kreisen."
            ),
            .postureCue: (
                "Haltungs-Cue",
                "Brustbein heben, Schultern locker nach hinten und unten, Kinn leicht zurueck."
            ),
            .eyeBreak: (
                "Augenpause",
                "Blick fuer 20 Sekunden in die Ferne, etwa 6 Meter weg (20-20-20-Regel)."
            )
        ]
        var changed = false
        for model in reminderModels {
            guard let old = legacy[model.kind], let new = current[model.kind] else { continue }
            if model.name == old.name && model.cueText == old.cue {
                model.name = new.name
                model.cueText = new.cueText
                changed = true
            }
        }
        if changed {
            try? context.save()
            refreshReminderModels()
        }
    }

    /// Traegt einmalig die Default-Video-Links nach: fuellt nur leere (nil) Slots,
    /// respektiert also bewusst editierte oder geloeschte Links. Das UserDefaults-
    /// Flag sorgt dafuer, dass der Backfill nur beim ersten Start nach Einfuehrung
    /// der Video-Links laeuft und ein spaeter geloeschter Link nicht wiederkehrt.
    /// Traegt voreingestellte Video-Links bei bestehenden Erinnerungen ohne Link nach.
    /// Noetig, weil `seedIfNeeded()` nur eine leere DB befuellt — Bestands-DBs, die vor
    /// dem Video-Feature angelegt wurden, haetten sonst nie einen Link.
    ///
    /// Pro Default-Video (kind + URL) wird gemerkt, ob es schon nachgetragen wurde.
    /// Dadurch (1) wird jeder Default-Link genau einmal nachgetragen, (2) kommen auch
    /// kuenftig neu hinzugefuegte Default-Videos automatisch nach und (3) bleibt ein
    /// vom Nutzer bewusst geleerter Link geleert (das Paar gilt als erledigt).
    private func backfillVideoURLs() {
        let key = "backfilledVideoDefaults"
        var done = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])

        let defaults = DefaultReminders.makeAll().compactMap { config -> (ReminderKind, String)? in
            config.videoURL.map { (config.kind, $0.absoluteString) }
        }

        var changed = false
        for (kind, url) in defaults {
            let token = "\(kind.rawValue)|\(url)"
            guard !done.contains(token) else { continue }
            for model in reminderModels where model.kind == kind && model.videoURLString == nil {
                model.videoURLString = url
                changed = true
            }
            done.insert(token)
        }

        if changed {
            try? context.save()
            refreshReminderModels()
        }
        UserDefaults.standard.set(Array(done), forKey: key)
    }

    /// Setzt den Ausloese-Zeitpunkt einer Erinnerung im Speicher und persistiert ihn.
    private func setLastFired(_ id: UUID, _ date: Date) {
        lastFired[id] = date
        if let model = reminderModels.first(where: { $0.id == id }) {
            model.lastFired = date
            try? context.save()
        }
    }

    // MARK: - Lifecycle

    func start() {
        Task { await notifications.requestAuthorization() }
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                await MainActor.run { self?.tick() }
            }
        }
    }

    /// Stoppt den Tick-Timer (z.B. fuer Tests oder beim Beenden).
    func stop() {
        tickTask?.cancel()
        tickTask = nil
    }

    // MARK: - Konfiguration laden

    private func fetchModels() -> [ReminderTypeModel] {
        let descriptor = FetchDescriptor<ReminderTypeModel>(
            sortBy: [SortDescriptor(\.order)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func currentConfigs() -> [ReminderConfig] {
        fetchModels().map(\.config)
    }

    /// Passt eine Konfiguration an die aktuelle Phase an: im Stehen nutzt der
    /// Sitz-Steh-Wechsel die kuerzere Stehdauer statt des Sitz-Intervalls.
    private func effective(_ config: ReminderConfig, standingMinutes: Int) -> ReminderConfig {
        guard config.kind == .sitStand, currentPhase == .standing else { return config }
        var adjusted = config
        adjusted.intervalMinutes = standingMinutes
        return adjusted
    }

    /// Alle aktiven Erinnerungen mit phasenabhaengig angepasstem Intervall — die
    /// Basis fuer das parallele Scheduling. Die Stehdauer wird einmal uebergeben,
    /// damit der Tick-Pfad UserDefaults nicht pro Erinnerung liest.
    private func effectiveEnabledConfigs(standingMinutes: Int) -> [ReminderConfig] {
        currentConfigs().filter(\.isEnabled).map { effective($0, standingMinutes: standingMinutes) }
    }

    /// Naechste Faelligkeit einer Erinnerung fuer die "in X min"-Anzeige im Menue.
    func nextDue(for config: ReminderConfig) -> Date? {
        projectedDue[config.id]
    }

    /// Aktualisiert die editierbare Modell-Liste fuer die Einstellungen.
    private func refreshReminderModels() {
        reminderModels = fetchModels()
    }

    private func seedIfNeeded() {
        let descriptor = FetchDescriptor<ReminderTypeModel>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        for config in DefaultReminders.makeAll() {
            context.insert(ReminderTypeModel(config: config))
        }
        try? context.save()
    }

    /// Setzt die Erinnerungstypen-Tabelle auf die orthopaedischen Defaults zurueck.
    func resetToDefaults() {
        let descriptor = FetchDescriptor<ReminderTypeModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        for model in existing {
            context.delete(model)
        }
        for config in DefaultReminders.makeAll() {
            context.insert(ReminderTypeModel(config: config))
        }
        try? context.save()
        lastFired.removeAll()
        snoozedUntil.removeAll()
        refreshReminderModels()
        recomputeNextDue()
    }

    /// Fuegt eine neue, frei konfigurierbare Erinnerung hinzu.
    func addReminder() {
        let nextOrder = (reminderModels.map(\.order).max() ?? -1) + 1
        let config = ReminderConfig(
            name: "Neue Erinnerung",
            kind: .custom,
            intervalMinutes: 30,
            modality: .sound,
            cueText: "Kurz innehalten und Haltung prüfen.",
            priority: 5,
            order: nextOrder
        )
        context.insert(ReminderTypeModel(config: config))
        try? context.save()
        refreshReminderModels()
        recomputeNextDue()
    }

    /// Entfernt Erinnerungen an den gegebenen Positionen der Tabelle.
    func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            snoozedUntil[reminderModels[index].id] = nil
            context.delete(reminderModels[index])
        }
        try? context.save()
        refreshReminderModels()
        recomputeNextDue()
    }

    /// Persistiert Inline-Aenderungen an einer Erinnerungszeile.
    func saveEdits() {
        try? context.save()
        recomputeNextDue()
    }

    // MARK: - Tick

    private func tick() {
        guard presented == nil else { return }
        let settings = AppSettings.current()
        let now = Date()
        // Abgelaufene Stummschaltung aufraeumen: AppSettings liefert nur noch
        // laufende Mutes, der Spiegel fuer die UI folgt hier nach. Nur bei echter
        // Aenderung schreiben — ein unbedingter Setter wuerde die Observation und
        // damit das Menubar-Icon alle 10 Sekunden unnoetig invalidieren.
        if mutedUntil != settings.muteUntil {
            mutedUntil = settings.muteUntil
        }
        // Reine Abkuerzung: massgeblich ist der Mute-Guard im Scheduler (siehe
        // Uebergabe unten), hier sparen wir waehrend der Stille nur den Fetch und
        // die Projektion — die Anzeige zeigt ohnehin "stumm", `unmute()` holt sie
        // sofort nach.
        guard settings.muteUntil == nil else { return }
        let configs = effectiveEnabledConfigs(standingMinutes: settings.standingMinutes)
        if let due = scheduler.dueReminder(
            configs: configs,
            lastFired: lastFired,
            now: now,
            sessionStart: sessionStart,
            workWindow: settings.workWindow,
            lastAnyFired: lastAnyFired,
            minGap: TimeInterval(settings.restMinutes) * 60,
            snoozedUntil: snoozedUntil,
            mutedUntil: settings.muteUntil
        ) {
            fire(due, settings: settings)
        }
        // configs und settings wiederverwenden: spart Fetch und Defaults-Lesen im selben Tick.
        recomputeNextDue(configs: configs, settings: settings)
    }

    /// Laedt Einstellungen und Configs selbst — fuer alle user-getriggerten
    /// Aufrufer ausserhalb des Ticks.
    private func recomputeNextDue() {
        let settings = AppSettings.current()
        recomputeNextDue(
            configs: effectiveEnabledConfigs(standingMinutes: settings.standingMinutes),
            settings: settings
        )
    }

    /// Aktualisiert projizierte Faelligkeiten und naechste Erinnerung.
    ///
    /// Angezeigt wird nicht die rohe Faelligkeit, sondern der Zeitpunkt, zu dem
    /// die Erinnerung tatsaechlich fruehestens kommt — sonst laeuft der Countdown
    /// ausserhalb der Arbeitszeit oder waehrend der Ruhephase auf null, ohne dass
    /// etwas passiert. Die Rechnung selbst steckt im Scheduler (testbar), hier
    /// bleibt nur das Verteilen auf den beobachtbaren Zustand.
    private func recomputeNextDue(configs: [ReminderConfig], settings: AppSettings) {
        let projected = scheduler.projectedDueDates(
            configs: configs,
            lastFired: lastFired,
            sessionStart: sessionStart,
            workWindow: settings.workWindow,
            snoozedUntil: snoozedUntil,
            restEndsAt: restEndsAt(settings)
        )

        projectedDue = Dictionary(projected.map { ($0.config.id, $0.due) },
                                  uniquingKeysWith: { first, _ in first })
        let soonest = projected.min { $0.due < $1.due }
        nextDueDate = soonest?.due
        nextReminderName = soonest?.config.name
    }

    /// Zeitpunkt der letzten Ausloesung ueber *alle* Erinnerungen — Basis fuer
    /// die Ruhephase, in der nichts Weiteres feuert.
    private var lastAnyFired: Date? { lastFired.values.max() }

    /// Ende der laufenden Ruhephase, nil wenn in dieser Sitzung noch nichts feuerte.
    private func restEndsAt(_ settings: AppSettings) -> Date? {
        lastAnyFired?.addingTimeInterval(TimeInterval(settings.restMinutes) * 60)
    }

    // MARK: - Ausloesen und Reagieren

    private func fire(_ config: ReminderConfig, settings: AppSettings) {
        let playSound = settings.soundEnabled && config.modality.playsSound
        let body = config.kind.directionalCue(for: currentPhase) ?? config.cueText
        notifications.notify(config, body: body, playSound: playSound)

        let showsOverlay = config.modality.showsOverlay && settings.overlayEnabled

        if showsOverlay {
            presented = config
            overlay.show(
                config: config,
                phase: currentPhase,
                onComplete: { [weak self] in self?.complete(config) },
                onSnooze: { [weak self] in self?.snooze(config) },
                onIgnore: { [weak self] in self?.ignore(config) }
            )
        } else {
            // Passive Erinnerung ohne Overlay: Takt sofort neu starten.
            setLastFired(config.id, Date())
        }
        // Kein recomputeNextDue() noetig: der aufrufende tick() recomputed direkt danach.
    }

    /// Markiert eine fällige Erinnerung als erledigt und startet ihren Takt neu;
    /// beim Sitz-Steh-Wechsel kippt zusaetzlich die Phase.
    func complete(_ config: ReminderConfig) {
        if config.kind == .sitStand {
            currentPhase = currentPhase.toggled
        }
        snoozedUntil[config.id] = nil
        setLastFired(config.id, Date())
        log(config.kind, outcome: .completed)
        presented = nil
        recomputeNextDue()
    }

    /// "Später erinnern" ist ein echter Kurz-Snooze: der reguläre Takt bleibt
    /// unangetastet, stattdessen wird die nächste Fälligkeit explizit auf jetzt
    /// plus die eingestellte Snooze-Dauer gesetzt. So meldet sich derselbe Cue
    /// nach wenigen Minuten erneut, statt erst ein ganzes Intervall später.
    func snooze(_ config: ReminderConfig) {
        let minutes = AppSettings.current().snoozeMinutes
        snoozedUntil[config.id] = Date().addingTimeInterval(TimeInterval(minutes) * 60)
        log(config.kind, outcome: .snoozed)
        presented = nil
        recomputeNextDue()
    }

    /// "Ignorieren" lässt den fälligen Cue diesmal aus: der Takt startet voll neu,
    /// die nächste Fälligkeit liegt also ein ganzes reguläres Intervall entfernt.
    /// Zeitlich wie ein erledigter Cue, nur ohne die Übung tatsächlich zu machen
    /// (kein Phasenwechsel beim Sitz-Steh-Wechsel).
    func ignore(_ config: ReminderConfig) {
        snoozedUntil[config.id] = nil
        setLastFired(config.id, Date())
        log(config.kind, outcome: .snoozed)
        presented = nil
        recomputeNextDue()
    }

    // MARK: - Stummschaltung

    /// Stellt die App fuer die gewaehlte Dauer still. Ein bereits offenes Overlay
    /// wird geschlossen — sonst blieben Panel und `presented` haengen und der Tick
    /// (der auf `presented == nil` wartet) wuerde nach dem Mute nicht weiterlaufen.
    /// Die Takte der einzelnen Erinnerungen laufen bewusst weiter: nach der Stille
    /// ist sofort dran, was inzwischen faellig geworden ist.
    ///
    /// Bewusst ohne Log-Eintrag: wer stumm schaltet, will gerade keine Erinnerung —
    /// der weggeraeumte Cue zaehlt weder als erledigt noch als gesnoozt und wuerde
    /// die Tagesstatistik nur verrauschen.
    func mute(for duration: MuteDuration) {
        let end = duration.end(from: Date())
        AppSettings.setMuteUntil(end)
        mutedUntil = end
        if presented != nil {
            overlay.dismiss()
            presented = nil
        }
    }

    /// Hebt die Stummschaltung vorzeitig auf. Die waehrend der Stille ausgelassene
    /// Projektion wird sofort nachgeholt, damit der Countdown nicht bis zum
    /// naechsten Tick veraltet dasteht.
    func unmute() {
        AppSettings.setMuteUntil(nil)
        mutedUntil = nil
        recomputeNextDue()
    }

    /// Manueller Sitz-Steh-Wechsel ueber das Menue.
    func manualSwitch() {
        currentPhase = currentPhase.toggled
        log(.sitStand, outcome: .completed)
        if let sitStand = currentConfigs().first(where: { $0.kind == .sitStand }) {
            snoozedUntil[sitStand.id] = nil
            setLastFired(sitStand.id, Date())
        }
        recomputeNextDue()
    }

    // MARK: - Info-Panel

    /// Oeffnet das Info-Panel einer Haltung anhand ihrer ID (z.B. aus dem
    /// Notification-Klick). Tut nichts, wenn die Erinnerung nicht mehr existiert.
    func showInfo(forID id: UUID) {
        guard let config = currentConfigs().first(where: { $0.id == id }) else { return }
        showInfo(config)
    }

    /// Zeigt das Info-Panel einer Haltung als reine Vorschau. Die Buttons
    /// schliessen nur das Panel und beeinflussen den Takt nicht.
    func showInfo(_ config: ReminderConfig) {
        presented = config
        overlay.show(
            config: config,
            phase: currentPhase,
            onComplete: { [weak self] in self?.dismissPreview() },
            onSnooze: { [weak self] in self?.dismissPreview() },
            onIgnore: { [weak self] in self?.dismissPreview() }
        )
    }

    private func dismissPreview() {
        presented = nil
    }

    /// Aktuelle Erinnerungen fuer die anklickbare Liste im Menubar.
    func infoList() -> [ReminderConfig] {
        currentConfigs()
    }

    private func log(_ kind: ReminderKind, outcome: ReminderOutcome) {
        let event = ReminderEvent(date: Date(), kind: kind, outcome: outcome, phase: currentPhase)
        context.insert(EventLogModel(event: event))
        try? context.save()
    }

    // MARK: - Statistik

    func todayStats() -> DayStats {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<EventLogModel>(
            predicate: #Predicate { $0.date >= dayStart }
        )
        let events = ((try? context.fetch(descriptor)) ?? []).map(\.event)
        return DayStatsCalculator.compute(events: events, dayStart: dayStart, now: Date())
    }
}
