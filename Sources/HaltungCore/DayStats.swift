import Foundation

/// Aggregierte Tageswerte fuer die Statistik-Ansicht.
public struct DayStats: Equatable, Sendable {
    /// Anzahl bestaetigter Sitz-Steh-Wechsel.
    public var sitStandSwitches: Int
    /// Insgesamt bestaetigte Erinnerungen.
    public var completed: Int
    /// Insgesamt verschobene (gesnoozte) Erinnerungen.
    public var snoozed: Int
    /// Geschaetzte Stehzeit in Sekunden, abgeleitet aus den Sitz-Steh-Wechseln.
    public var standingSeconds: TimeInterval

    public init(
        sitStandSwitches: Int = 0,
        completed: Int = 0,
        snoozed: Int = 0,
        standingSeconds: TimeInterval = 0
    ) {
        self.sitStandSwitches = sitStandSwitches
        self.completed = completed
        self.snoozed = snoozed
        self.standingSeconds = standingSeconds
    }
}

/// Berechnet Tagesstatistiken aus dem Ereignis-Log. Rein und testbar.
public enum DayStatsCalculator {

    /// - Parameters:
    ///   - events: Ereignisse des Tages (Reihenfolge egal, wird sortiert).
    ///   - dayStart: Beginn des Tages (z.B. Mitternacht oder erster Sitzungsbeginn).
    ///   - now: aktueller Zeitpunkt fuer die laufende Stehzeit.
    ///   - startPhase: Phase zu Tagesbeginn (Default Sitzen).
    public static func compute(
        events: [ReminderEvent],
        dayStart: Date,
        now: Date,
        startPhase: Phase = .sitting
    ) -> DayStats {
        let completed = events.filter { $0.outcome == .completed }.count
        let snoozed = events.filter { $0.outcome == .snoozed }.count

        let switches = events
            .filter { $0.kind == .sitStand && $0.outcome == .completed }
            .sorted { $0.date < $1.date }

        var phase = startPhase
        var standing: TimeInterval = 0
        var lastChange = dayStart

        for event in switches {
            if phase == .standing {
                standing += event.date.timeIntervalSince(lastChange)
            }
            phase = phase.toggled
            lastChange = event.date
        }
        if phase == .standing {
            standing += now.timeIntervalSince(lastChange)
        }

        return DayStats(
            sitStandSwitches: switches.count,
            completed: completed,
            snoozed: snoozed,
            standingSeconds: max(0, standing)
        )
    }
}
