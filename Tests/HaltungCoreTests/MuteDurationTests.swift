import Testing
import Foundation
@testable import HaltungCore

@Suite("MuteDuration")
struct MuteDurationTests {

    @Test("Die drei Stufen decken 60, 90 und 120 Minuten ab")
    func minutesPerCase() {
        #expect(MuteDuration.allCases.map(\.minutes) == [60, 90, 120])
    }

    @Test("end rechnet die Dauer auf den Startzeitpunkt")
    func endFromStart() {
        #expect(MuteDuration.ninetyMinutes.end(from: berlinDate(10, 0)) == berlinDate(11, 30))
        #expect(MuteDuration.twoHours.end(from: berlinDate(10, 0)) == berlinDate(12, 0))
    }
}
