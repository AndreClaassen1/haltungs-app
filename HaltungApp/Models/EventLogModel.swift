import Foundation
import SwiftData
import HaltungCore

/// Persistenter Eintrag im Ereignis-Log. Basis fuer die Tagesstatistik.
@Model
final class EventLogModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kindRaw: String
    var outcomeRaw: String
    var phaseRaw: String

    init(event: ReminderEvent) {
        self.id = event.id
        self.date = event.date
        self.kindRaw = event.kind.rawValue
        self.outcomeRaw = event.outcome.rawValue
        self.phaseRaw = event.phase.rawValue
    }

    var event: ReminderEvent {
        ReminderEvent(
            id: id,
            date: date,
            kind: ReminderKind(rawValue: kindRaw) ?? .custom,
            outcome: ReminderOutcome(rawValue: outcomeRaw) ?? .completed,
            phase: Phase(rawValue: phaseRaw) ?? .sitting
        )
    }
}
