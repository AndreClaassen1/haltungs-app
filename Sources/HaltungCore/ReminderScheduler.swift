import Foundation

/// Eine faellige Erinnerung mit ihrem berechneten Faelligkeitszeitpunkt.
public struct ScheduledReminder: Equatable, Sendable {
    public let config: ReminderConfig
    public let dueDate: Date

    public init(config: ReminderConfig, dueDate: Date) {
        self.config = config
        self.dueDate = dueDate
    }
}

/// Reine, deterministische Scheduling-Logik. Kein Timer, kein State: alle
/// Eingaben werden uebergeben, damit die Engine in der App nur noch die Uhr und
/// die Persistenz beisteuert. Voll unit-testbar.
public struct ReminderScheduler: Sendable {

    public init() {}

    /// Naechster Faelligkeitszeitpunkt einer einzelnen Erinnerung.
    /// Basis ist die letzte Ausloesung, ersatzweise der Sitzungsstart.
    ///
    /// Ist `snoozedUntil` gesetzt (Nutzer hat "Spaeter erinnern" gedrueckt), gilt
    /// dieser Zeitpunkt statt des regulaeren Takts: ein expliziter Kurz-Snooze
    /// erinnert bewusst frueher (oder spaeter) als das volle Intervall.
    public func nextDueDate(
        for config: ReminderConfig,
        lastFired: Date?,
        sessionStart: Date,
        snoozedUntil: Date? = nil
    ) -> Date {
        if let snoozedUntil { return snoozedUntil }
        let base = lastFired ?? sessionStart
        return base.addingTimeInterval(config.intervalSeconds)
    }

    /// Mindestabstand zwischen zwei Unterbrechungen (Ruhephase). Nach jeder
    /// ausgeloesten Erinnerung feuert fuer diese Dauer keine weitere, damit sich
    /// gleichzeitig faellige Cues nicht zu einem Schwall haeufen, sondern
    /// nacheinander ausgespielt werden. Default, falls die App keinen Wert
    /// uebergibt; die App liest die einstellbare Dauer aus den Einstellungen.
    public static let minInterruptionGap: TimeInterval = 10 * 60

    /// Die jetzt faellige Erinnerung mit der hoechsten Prioritaet, sofern der
    /// Zeitpunkt im Arbeitszeitfenster liegt und die Ruhephase seit der letzten
    /// Unterbrechung abgelaufen ist. Liefert nil, wenn nichts faellig ist oder die
    /// Ruhephase noch laeuft. Bei gleicher Prioritaet entscheidet die fruehere
    /// Faelligkeit. Mehrere gleichzeitig Faellige werden so ueber aufeinander
    /// folgende Aufrufe (je nach Ruhephase) nacheinander ausgespielt.
    ///
    /// - Parameter lastAnyFired: Zeitpunkt der letzten Unterbrechung ueber *alle*
    ///   Erinnerungen. nil heisst: in dieser Sitzung feuerte noch nichts.
    /// - Parameter mutedUntil: Globale Stummschaltung. Bis zu diesem Zeitpunkt
    ///   feuert keine Erinnerung. Anders als der Snooze wirkt sie ueber alle
    ///   Erinnerungen hinweg und laesst die einzelnen Takte unangetastet: nach dem
    ///   Ende der Stille sind faellig gewordene Cues sofort wieder dran.
    public func dueReminder(
        configs: [ReminderConfig],
        lastFired: [UUID: Date],
        now: Date,
        sessionStart: Date,
        workWindow: WorkWindow,
        lastAnyFired: Date? = nil,
        minGap: TimeInterval = minInterruptionGap,
        snoozedUntil: [UUID: Date] = [:],
        mutedUntil: Date? = nil,
        calendar: Calendar = .current
    ) -> ReminderConfig? {
        if let mutedUntil, now < mutedUntil { return nil }

        guard workWindow.contains(now, calendar: calendar) else { return nil }

        // Ruhephase: seit der letzten Unterbrechung muss minGap vergangen sein.
        if let lastAnyFired, now.timeIntervalSince(lastAnyFired) < minGap {
            return nil
        }

        let dueNow: [ScheduledReminder] = configs
            .filter { $0.isEnabled }
            .map { cfg in
                ScheduledReminder(
                    config: cfg,
                    dueDate: nextDueDate(
                        for: cfg,
                        lastFired: lastFired[cfg.id],
                        sessionStart: sessionStart,
                        snoozedUntil: snoozedUntil[cfg.id]
                    )
                )
            }
            .filter { $0.dueDate <= now }

        return dueNow.min { lhs, rhs in
            if lhs.config.priority != rhs.config.priority {
                return lhs.config.priority < rhs.config.priority
            }
            return lhs.dueDate < rhs.dueDate
        }?.config
    }

    /// Hebt eine rohe Faelligkeit auf den Zeitpunkt an, zu dem die Erinnerung
    /// tatsaechlich fruehestens ausgeloest werden kann. `nextDueDate` rechnet nur
    /// Takt und Snooze; die Guards in `dueReminder` (Ruhephase, Arbeitszeitfenster)
    /// verschieben das Feuern aber weiter nach hinten. Ohne diese Korrektur zeigt
    /// die Oberflaeche einen Countdown, der bei null nichts ausloest — etwa um
    /// 20:00 Uhr bei einem Fenster 8 bis 18 Uhr.
    ///
    /// Die Stummschaltung bleibt bewusst aussen vor: sie ist ein vom Nutzer
    /// gesetzter Zustand, den die Oberflaeche benennt ("Stumm bis ..."), statt ihn
    /// in einen Countdown zu uebersetzen.
    ///
    /// - Parameter restEndsAt: Ende der laufenden Ruhephase, falls eine laeuft.
    public func effectiveDueDate(
        rawDue: Date,
        workWindow: WorkWindow,
        restEndsAt: Date? = nil,
        calendar: Calendar = .current
    ) -> Date {
        var candidate = rawDue
        if let restEndsAt, restEndsAt > candidate { candidate = restEndsAt }
        if !workWindow.contains(candidate, calendar: calendar) {
            candidate = workWindow.nextStart(after: candidate, calendar: calendar)
        }
        return candidate
    }

    /// Anzeige-Projektion: je aktiver Erinnerung der Zeitpunkt, zu dem sie
    /// tatsaechlich fruehestens kommt (Takt bzw. Snooze, angehoben durch
    /// Ruhephase und Arbeitszeitfenster). Basis fuer den Countdown in der
    /// Kopfzeile und die "in X min"-Spalte der Liste.
    ///
    /// Bewusst hier und nicht in der Engine: es ist Scheduling-Logik und damit
    /// testbar zu halten. Die Stummschaltung bleibt aussen vor — sie wird als
    /// Zustand benannt, nicht als Countdown dargestellt.
    public func projectedDueDates(
        configs: [ReminderConfig],
        lastFired: [UUID: Date],
        sessionStart: Date,
        workWindow: WorkWindow,
        snoozedUntil: [UUID: Date] = [:],
        restEndsAt: Date? = nil,
        calendar: Calendar = .current
    ) -> [(config: ReminderConfig, due: Date)] {
        configs
            .filter(\.isEnabled)
            .map { config in
                let raw = nextDueDate(
                    for: config,
                    lastFired: lastFired[config.id],
                    sessionStart: sessionStart,
                    snoozedUntil: snoozedUntil[config.id]
                )
                let due = effectiveDueDate(
                    rawDue: raw, workWindow: workWindow,
                    restEndsAt: restEndsAt, calendar: calendar
                )
                return (config: config, due: due)
            }
    }

    /// Startluecke, ab der ein Takt nicht mehr fortgesetzt, sondern frisch
    /// gestartet wird (Standard: 1 Stunde).
    public static let sessionGap: TimeInterval = 60 * 60

    /// Bereinigt persistierte Ausloese-Zeitpunkte beim Start: jeder einzelne
    /// `lastFired`, der laenger als `gap` zurueckliegt, wird verworfen — die
    /// zugehoerige Erinnerung startet dann frisch ab Sitzungsstart und wird erst
    /// nach ihrem vollen Intervall wieder faellig, statt sofort. Frische Werte
    /// (juenger als `gap`) bleiben erhalten, ein schneller Neustart verschiebt den
    /// Rhythmus also nicht. Die Schwelle wirkt pro Erinnerung, damit ein einzelner
    /// kuerzlich gefeuerter Takt die uebrigen, laengst veralteten nicht mitzieht.
    public func freshLastFired(
        _ lastFired: [UUID: Date],
        now: Date,
        gap: TimeInterval = sessionGap
    ) -> [UUID: Date] {
        lastFired.filter { now.timeIntervalSince($0.value) <= gap }
    }

}
