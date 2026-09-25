import Testing
import Foundation
@testable import HaltungCore

@Suite("DefaultReminders")
struct DefaultRemindersTests {

    @Test("Liefert genau fuenf Standard-Erinnerungen")
    func fiveDefaults() {
        #expect(DefaultReminders.makeAll().count == 5)
    }

    @Test("Sitz-Steh-Wechsel hat hoechste Prioritaet")
    func sitStandHighestPriority() {
        let all = DefaultReminders.makeAll()
        let sitStand = all.first { $0.kind == .sitStand }
        #expect(sitStand != nil)
        let minPriority = all.map(\.priority).min()
        #expect(sitStand?.priority == minPriority)
    }

    @Test("Jeder Default hat frische, eindeutige IDs")
    func uniqueIDs() {
        let a = DefaultReminders.makeAll()
        let b = DefaultReminders.makeAll()
        let idsA = Set(a.map(\.id))
        let idsB = Set(b.map(\.id))
        #expect(idsA.count == a.count)
        #expect(idsA.isDisjoint(with: idsB))
    }

    @Test("Alle Default-Intervalle sind positiv")
    func positiveIntervals() {
        for cfg in DefaultReminders.makeAll() {
            #expect(cfg.intervalMinutes > 0)
        }
    }
}
