import Foundation

/// Wie der Nutzer auf eine Erinnerung reagiert hat.
public enum ReminderOutcome: String, Codable, Sendable, CaseIterable {
    case completed
    case snoozed
    case missed
}

/// Ein Eintrag im Ereignis-Log. Basis fuer die Tagesstatistik.
public struct ReminderEvent: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID
    public var date: Date
    public var kind: ReminderKind
    public var outcome: ReminderOutcome
    /// Phase zum Zeitpunkt des Ereignisses.
    public var phase: Phase

    public init(
        id: UUID = UUID(),
        date: Date,
        kind: ReminderKind,
        outcome: ReminderOutcome,
        phase: Phase
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.outcome = outcome
        self.phase = phase
    }
}
