import Testing
import Foundation
@testable import HaltungCore

@Suite("ReminderScheduler")
struct ReminderSchedulerTests {

    let scheduler = ReminderScheduler()

    func config(interval: Int, priority: Int, enabled: Bool = true, kind: ReminderKind = .custom) -> ReminderConfig {
        ReminderConfig(
            name: "Test",
            kind: kind,
            isEnabled: enabled,
            intervalMinutes: interval,
            modality: .sound,
            cueText: "Cue",
            priority: priority,
            order: 0
        )
    }

    @Test("nextDueDate basiert auf lastFired plus Intervall")
    func nextDueFromLastFired() {
        let cfg = config(interval: 30, priority: 0)
        let due = scheduler.nextDueDate(for: cfg, lastFired: berlinDate(10, 0), sessionStart: berlinDate(9, 0))
        #expect(due == berlinDate(10, 30))
    }

    @Test("nextDueDate faellt auf sessionStart zurueck wenn nie gefeuert")
    func nextDueFromSessionStart() {
        let cfg = config(interval: 15, priority: 0)
        let due = scheduler.nextDueDate(for: cfg, lastFired: nil, sessionStart: berlinDate(9, 0))
        #expect(due == berlinDate(9, 15))
    }

    @Test("snoozedUntil ersetzt den regulaeren Takt")
    func snoozeOverridesRegularDue() {
        let cfg = config(interval: 30, priority: 0)
        // Regulaer waere 10:30 faellig — der Kurz-Snooze zieht auf 10:05 vor.
        let due = scheduler.nextDueDate(
            for: cfg,
            lastFired: berlinDate(10, 0),
            sessionStart: berlinDate(9, 0),
            snoozedUntil: berlinDate(10, 5)
        )
        #expect(due == berlinDate(10, 5))
    }

    @Test("Gesnoozte Erinnerung feuert erst zum Snooze-Zeitpunkt, nicht im regulaeren Takt")
    func snoozeDelaysDueReminder() {
        let cfg = config(interval: 30, priority: 0)
        // Regulaer waere ab 9:30 faellig; der Snooze schiebt auf 9:35.
        let lastFired: [UUID: Date] = [cfg.id: berlinDate(9, 0)]
        let snoozed: [UUID: Date] = [cfg.id: berlinDate(9, 35)]

        // Um 9:31 regulaer faellig, aber durch den Snooze noch nicht.
        let blocked = scheduler.dueReminder(
            configs: [cfg],
            lastFired: lastFired,
            now: berlinDate(9, 31),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            snoozedUntil: snoozed,
            calendar: berlinCalendar
        )
        #expect(blocked == nil)

        // Ab 9:35 feuert sie.
        let released = scheduler.dueReminder(
            configs: [cfg],
            lastFired: lastFired,
            now: berlinDate(9, 35),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            snoozedUntil: snoozed,
            calendar: berlinCalendar
        )
        #expect(released?.id == cfg.id)
    }

    @Test("effectiveDueDate laesst eine Faelligkeit im Fenster unveraendert")
    func effectiveDueInsideWindow() {
        let due = scheduler.effectiveDueDate(
            rawDue: berlinDate(10, 30),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(due == berlinDate(10, 30))
    }

    @Test("effectiveDueDate schiebt eine Faelligkeit nach Feierabend auf den naechsten Morgen")
    func effectiveDueAfterWorkWindow() {
        // Um 20:12 faellig, Fenster 8 bis 18 — kommt erst am naechsten Tag um 8:00.
        let due = scheduler.effectiveDueDate(
            rawDue: berlinDate(20, 12),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(due == berlinDate(8, 0, day: 10))
    }

    @Test("effectiveDueDate schiebt eine Faelligkeit vor Arbeitsbeginn auf den Start")
    func effectiveDueBeforeWorkWindow() {
        let due = scheduler.effectiveDueDate(
            rawDue: berlinDate(6, 45),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(due == berlinDate(8, 0))
    }

    @Test("effectiveDueDate hebt eine Faelligkeit auf das Ende der Ruhephase an")
    func effectiveDueDuringRest() {
        // Regulaer um 10:02 faellig, aber die Ruhephase laeuft noch bis 10:10.
        let due = scheduler.effectiveDueDate(
            rawDue: berlinDate(10, 2),
            workWindow: .standard,
            restEndsAt: berlinDate(10, 10),
            calendar: berlinCalendar
        )
        #expect(due == berlinDate(10, 10))
    }

    @Test("Eine abgelaufene Ruhephase verschiebt nichts")
    func effectiveDueAfterRest() {
        let due = scheduler.effectiveDueDate(
            rawDue: berlinDate(10, 30),
            workWindow: .standard,
            restEndsAt: berlinDate(10, 10),
            calendar: berlinCalendar
        )
        #expect(due == berlinDate(10, 30))
    }

    @Test("Ruhephase ueber das Fensterende hinaus schiebt auf den naechsten Morgen")
    func effectiveDueRestPastWorkWindow() {
        // Kurz vor 18:00 faellig, Ruhephase reicht bis 18:05 — also erst morgen.
        let due = scheduler.effectiveDueDate(
            rawDue: berlinDate(17, 58),
            workWindow: .standard,
            restEndsAt: berlinDate(18, 5),
            calendar: berlinCalendar
        )
        #expect(due == berlinDate(8, 0, day: 10))
    }

    @Test("Stummschaltung unterdrueckt jede faellige Erinnerung")
    func muteSuppressesDueReminder() {
        let cfg = config(interval: 30, priority: 0)
        // Regulaer seit 9:30 faellig, aber bis 11:00 ist stumm geschaltet.
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(9, 0)],
            now: berlinDate(10, 0),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            mutedUntil: berlinDate(11, 0),
            calendar: berlinCalendar
        )
        #expect(result == nil)
    }

    @Test("Nach Ende der Stummschaltung feuert die aufgestaute Erinnerung sofort")
    func muteReleasesAfterEnd() {
        let cfg = config(interval: 30, priority: 0)
        // Der Takt lief waehrend der Stille weiter — ab 11:00 ist sie sofort dran.
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(9, 0)],
            now: berlinDate(11, 0),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            mutedUntil: berlinDate(11, 0),
            calendar: berlinCalendar
        )
        #expect(result?.id == cfg.id)
    }

    @Test("Eine abgelaufene Stummschaltung bleibt wirkungslos")
    func pastMuteHasNoEffect() {
        let cfg = config(interval: 30, priority: 0)
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(9, 0)],
            now: berlinDate(10, 0),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            mutedUntil: berlinDate(9, 30),
            calendar: berlinCalendar
        )
        #expect(result?.id == cfg.id)
    }

    @Test("Keine faellige Erinnerung ausserhalb des Arbeitszeitfensters")
    func nothingOutsideWorkWindow() {
        let cfg = config(interval: 1, priority: 0)
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [:],
            now: berlinDate(20, 0),
            sessionStart: berlinDate(19, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(result == nil)
    }

    @Test("Faellige Erinnerung wird im Arbeitszeitfenster geliefert")
    func dueInsideWorkWindow() {
        let cfg = config(interval: 30, priority: 0)
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(9, 0)],
            now: berlinDate(9, 31),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(result?.id == cfg.id)
    }

    @Test("Noch nicht faellige Erinnerung wird nicht geliefert")
    func notYetDue() {
        let cfg = config(interval: 30, priority: 0)
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(9, 0)],
            now: berlinDate(9, 20),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(result == nil)
    }

    @Test("Bei Kollision gewinnt die hoehere Prioritaet (kleinere Zahl)")
    func priorityWins() {
        let high = config(interval: 10, priority: 0, kind: .sitStand)
        let low = config(interval: 10, priority: 5, kind: .postureCue)
        let result = scheduler.dueReminder(
            configs: [low, high],
            lastFired: [high.id: berlinDate(9, 0), low.id: berlinDate(9, 0)],
            now: berlinDate(9, 30),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(result?.id == high.id)
    }

    @Test("Deaktivierte Erinnerungen werden ignoriert")
    func disabledIgnored() {
        let cfg = config(interval: 10, priority: 0, enabled: false)
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(9, 0)],
            now: berlinDate(9, 30),
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(result == nil)
    }

    @Test("projectedDueDates liefert je Erinnerung den fruehesten Zeitpunkt")
    func projectedSoonest() {
        let a = config(interval: 30, priority: 0)
        let b = config(interval: 15, priority: 1)
        let projected = scheduler.projectedDueDates(
            configs: [a, b],
            lastFired: [:],
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(projected.count == 2)
        #expect(projected.min { $0.due < $1.due }?.due == berlinDate(9, 15))
    }

    @Test("projectedDueDates laesst deaktivierte Erinnerungen aus")
    func projectedSkipsDisabled() {
        let on = config(interval: 30, priority: 0)
        let off = config(interval: 15, priority: 1, enabled: false)
        let projected = scheduler.projectedDueDates(
            configs: [on, off],
            lastFired: [:],
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(projected.map(\.config.id) == [on.id])
    }

    @Test("projectedDueDates schiebt eine Faelligkeit nach Feierabend auf den naechsten Morgen")
    func projectedRespectsWorkWindow() {
        // Letzte Ausloesung 17:50, Intervall 30 min -> regulaer 18:20, also nach
        // Feierabend. Angezeigt werden muss der naechste Morgen, nicht 18:20.
        let cfg = config(interval: 30, priority: 0)
        let projected = scheduler.projectedDueDates(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(17, 50)],
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            calendar: berlinCalendar
        )
        #expect(projected.first?.due == berlinDate(8, 0, day: 10))
    }

    @Test("projectedDueDates beruecksichtigt den Snooze")
    func projectedRespectsSnooze() {
        let cfg = config(interval: 30, priority: 0)
        let projected = scheduler.projectedDueDates(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(10, 0)],
            sessionStart: berlinDate(9, 0),
            workWindow: .standard,
            snoozedUntil: [cfg.id: berlinDate(10, 5)],
            calendar: berlinCalendar
        )
        #expect(projected.first?.due == berlinDate(10, 5))
    }

    @Test("Veraltete Takte werden verworfen, frische bleiben — pro Erinnerung")
    func staleDiscardedFreshKept() {
        let stale = UUID()
        let fresh = UUID()
        let map: [UUID: Date] = [
            stale: berlinDate(7, 30),  // 90 min alt -> verwerfen
            fresh: berlinDate(8, 50)   // 10 min alt -> behalten
        ]
        let result = scheduler.freshLastFired(map, now: berlinDate(9, 0))
        #expect(result[fresh] == berlinDate(8, 50))
        #expect(result[stale] == nil)
    }

    @Test("Ein kuerzlich gefeuerter Takt zieht veraltete nicht mit")
    func recentDoesNotRescueStale() {
        // Genau der Fehlerfall: eine Erinnerung lief vor 10 min, eine andere
        // traegt noch einen Wert von gestern. Nur die frische darf bleiben.
        let recent = UUID()
        let yesterday = UUID()
        let map: [UUID: Date] = [
            recent: berlinDate(8, 50),
            yesterday: berlinDate(16, 0, day: 8)
        ]
        let result = scheduler.freshLastFired(map, now: berlinDate(9, 0))
        #expect(result[recent] == berlinDate(8, 50))
        #expect(result[yesterday] == nil)
    }

    @Test("Genau an der Schwelle bleibt der Takt erhalten")
    func exactlyAtThresholdKeeps() {
        let id = UUID()
        let map: [UUID: Date] = [id: berlinDate(8, 0)]
        // Luecke == sessionGap (60 min): nicht groesser, also behalten.
        let fresh = scheduler.freshLastFired(map, now: berlinDate(9, 0))
        #expect(fresh == map)
    }

    @Test("Leere Eingabe bleibt leer")
    func emptyStaysEmpty() {
        let fresh = scheduler.freshLastFired([:], now: berlinDate(9, 0))
        #expect(fresh.isEmpty)
    }

    @Test("Nach grosser Luecke basiert die Faelligkeit auf sessionStart")
    func dueAfterGapUsesSessionStart() {
        let cfg = config(interval: 30, priority: 0)
        let sessionStart = berlinDate(9, 0)
        // Gestern gefeuert: ergaebe ohne Bereinigung eine laengst ueberfaellige Erinnerung.
        let persisted: [UUID: Date] = [cfg.id: berlinDate(15, 0, day: 8)]
        let fresh = scheduler.freshLastFired(persisted, now: sessionStart)
        let due = scheduler.nextDueDate(for: cfg, lastFired: fresh[cfg.id], sessionStart: sessionStart)
        #expect(due == berlinDate(9, 30))
    }

    // MARK: - Ruhephase (Mindestabstand zwischen Unterbrechungen)

    @Test("Innerhalb der Ruhephase feuert nichts, obwohl faellig")
    func cooldownBlocks() {
        let cfg = config(interval: 15, priority: 0)
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(8, 0)],
            now: berlinDate(9, 0),
            sessionStart: berlinDate(8, 0),
            workWindow: .standard,
            lastAnyFired: berlinDate(8, 58),  // vor 2 min < 5 min Ruhephase
            minGap: 5 * 60,
            calendar: berlinCalendar
        )
        #expect(result == nil)
    }

    @Test("Nach Ablauf der Ruhephase feuert die hoechste Prioritaet")
    func cooldownReleasesHighestPriority() {
        let high = config(interval: 15, priority: 0)
        let low = config(interval: 15, priority: 5)
        let result = scheduler.dueReminder(
            configs: [low, high],
            lastFired: [high.id: berlinDate(8, 0), low.id: berlinDate(8, 0)],
            now: berlinDate(9, 0),
            sessionStart: berlinDate(8, 0),
            workWindow: .standard,
            lastAnyFired: berlinDate(8, 54),  // vor 6 min > 5 min Ruhephase
            minGap: 5 * 60,
            calendar: berlinCalendar
        )
        #expect(result?.id == high.id)
    }

    @Test("Ohne vorherige Unterbrechung feuert die faellige sofort")
    func noCooldownWhenNothingFired() {
        let cfg = config(interval: 15, priority: 0)
        let result = scheduler.dueReminder(
            configs: [cfg],
            lastFired: [cfg.id: berlinDate(8, 0)],
            now: berlinDate(9, 0),
            sessionStart: berlinDate(8, 0),
            workWindow: .standard,
            lastAnyFired: nil,
            calendar: berlinCalendar
        )
        #expect(result?.id == cfg.id)
    }

    @Test("Gleichzeitig Faellige werden ueber die Ruhephase nacheinander ausgespielt")
    func staggeredPlayout() {
        let a = config(interval: 15, priority: 0)
        let b = config(interval: 15, priority: 1)

        // Slot 1: noch nichts gefeuert -> hoechste Prioritaet (a) feuert.
        let first = scheduler.dueReminder(
            configs: [a, b],
            lastFired: [a.id: berlinDate(8, 0), b.id: berlinDate(8, 0)],
            now: berlinDate(9, 0),
            sessionStart: berlinDate(8, 0),
            workWindow: .standard,
            lastAnyFired: nil,
            calendar: berlinCalendar
        )
        #expect(first?.id == a.id)

        // Kurz danach: a hat gefeuert -> Ruhephase haelt b noch zurueck.
        let blocked = scheduler.dueReminder(
            configs: [a, b],
            lastFired: [a.id: berlinDate(9, 0), b.id: berlinDate(8, 0)],
            now: berlinDate(9, 1),
            sessionStart: berlinDate(8, 0),
            workWindow: .standard,
            lastAnyFired: berlinDate(9, 0),
            minGap: 5 * 60,
            calendar: berlinCalendar
        )
        #expect(blocked == nil)

        // Nach Ablauf der Ruhephase: a ist wieder im Takt, b noch faellig -> b feuert.
        let second = scheduler.dueReminder(
            configs: [a, b],
            lastFired: [a.id: berlinDate(9, 0), b.id: berlinDate(8, 0)],
            now: berlinDate(9, 6),
            sessionStart: berlinDate(8, 0),
            workWindow: .standard,
            lastAnyFired: berlinDate(9, 0),
            minGap: 5 * 60,
            calendar: berlinCalendar
        )
        #expect(second?.id == b.id)
    }
}
