import Testing
@testable import HaltungCore

@Suite("ReminderKind")
struct ReminderKindTests {

    @Test("Standard-Haltungen haben eine Anleitung")
    func standardKindsHaveHowTo() {
        let standard: [ReminderKind] = [.sitStand, .postureCue, .microBreak, .eyeBreak, .mobility]
        for kind in standard {
            #expect(!kind.howTo.isEmpty)
        }
    }

    @Test("Eigene Erinnerung hat keine vorgegebene Anleitung")
    func customHasNoHowTo() {
        #expect(ReminderKind.custom.howTo.isEmpty)
    }

    @Test("Jede Haltung hat ein Piktogramm und einen Namen")
    func everyKindHasIconAndName() {
        for kind in ReminderKind.allCases {
            #expect(!kind.systemImageName.isEmpty)
            #expect(!kind.displayName.isEmpty)
        }
    }

    @Test("Sitz-Steh-Wechsel hat richtungsabhängige Cues")
    func sitStandDirectionalCue() {
        #expect(ReminderKind.sitStand.directionalCue(for: .sitting)?.contains("Aufstehen") == true)
        #expect(ReminderKind.sitStand.directionalCue(for: .standing)?.contains("Hinsetzen") == true)
    }

    @Test("Andere Haltungen haben keinen richtungsabhängigen Cue")
    func nonSitStandNoDirectionalCue() {
        #expect(ReminderKind.microBreak.directionalCue(for: .sitting) == nil)
    }

    @Test("Sitz-Steh-Anleitung unterscheidet sich je Phase")
    func sitStandHowToDiffersByPhase() {
        #expect(ReminderKind.sitStand.howTo(for: .sitting) != ReminderKind.sitStand.howTo(for: .standing))
    }
}
