import Testing
import Foundation
@testable import HaltungCore

@Suite("DayStatsCalculator")
struct DayStatsTests {

    func event(_ hour: Int, _ minute: Int, kind: ReminderKind, outcome: ReminderOutcome, phase: Phase = .sitting) -> ReminderEvent {
        ReminderEvent(date: berlinDate(hour, minute), kind: kind, outcome: outcome, phase: phase)
    }

    @Test("Leeres Log ergibt Nullstatistik")
    func emptyLog() {
        let stats = DayStatsCalculator.compute(events: [], dayStart: berlinDate(8, 0), now: berlinDate(12, 0))
        #expect(stats == DayStats())
    }

    @Test("Zaehlt bestaetigte und gesnoozte Erinnerungen")
    func countsOutcomes() {
        let events = [
            event(9, 0, kind: .postureCue, outcome: .completed),
            event(9, 30, kind: .eyeBreak, outcome: .snoozed),
            event(10, 0, kind: .microBreak, outcome: .completed)
        ]
        let stats = DayStatsCalculator.compute(events: events, dayStart: berlinDate(8, 0), now: berlinDate(12, 0))
        #expect(stats.completed == 2)
        #expect(stats.snoozed == 1)
    }

    @Test("Zaehlt Sitz-Steh-Wechsel")
    func countsSwitches() {
        let events = [
            event(9, 0, kind: .sitStand, outcome: .completed),
            event(9, 45, kind: .sitStand, outcome: .completed),
            event(10, 0, kind: .sitStand, outcome: .snoozed)
        ]
        let stats = DayStatsCalculator.compute(events: events, dayStart: berlinDate(8, 0), now: berlinDate(12, 0))
        #expect(stats.sitStandSwitches == 2)
    }

    @Test("Berechnet Stehzeit aus Wechseln")
    func computesStandingTime() {
        // Start sitzend. Um 9:00 wird Stehen bestaetigt, um 9:30 wieder Sitzen.
        // Stehzeit also 30 Minuten = 1800 Sekunden.
        let events = [
            event(9, 0, kind: .sitStand, outcome: .completed),
            event(9, 30, kind: .sitStand, outcome: .completed)
        ]
        let stats = DayStatsCalculator.compute(events: events, dayStart: berlinDate(8, 0), now: berlinDate(12, 0))
        #expect(stats.standingSeconds == 1800)
    }

    @Test("Laufende Stehzeit bis jetzt wird mitgezaehlt")
    func ongoingStandingTime() {
        // Um 11:00 Stehen bestaetigt, jetzt ist 11:20 und noch im Stehen.
        let events = [
            event(11, 0, kind: .sitStand, outcome: .completed)
        ]
        let stats = DayStatsCalculator.compute(events: events, dayStart: berlinDate(8, 0), now: berlinDate(11, 20))
        #expect(stats.standingSeconds == 1200)
    }
}
