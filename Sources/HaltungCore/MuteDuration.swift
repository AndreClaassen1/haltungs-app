import Foundation

/// Waehlbare Dauern fuer die globale Stummschaltung. Bewusst wenige, grobe
/// Stufen: die Stummschaltung deckt Meetings und Fokusbloecke ab, nicht die
/// minutengenaue Feinsteuerung — dafuer gibt es den Snooze je Erinnerung.
public enum MuteDuration: Int, CaseIterable, Sendable {
    case oneHour = 60
    case ninetyMinutes = 90
    case twoHours = 120

    /// Dauer der Stille in Minuten.
    public var minutes: Int { rawValue }

    public var displayName: String {
        switch self {
        case .oneHour: "1 Stunde"
        case .ninetyMinutes: "1,5 Stunden"
        case .twoHours: "2 Stunden"
        }
    }

    /// Endzeitpunkt der Stille, gerechnet ab dem uebergebenen Startzeitpunkt.
    public func end(from start: Date) -> Date {
        start.addingTimeInterval(TimeInterval(minutes) * 60)
    }
}
