import Foundation

/// Aktuelle Koerperhaltung am Schreibtisch. Wird bei jedem bestaetigten
/// Sitz-Steh-Wechsel umgeschaltet.
public enum Phase: String, Codable, CaseIterable, Sendable {
    case sitting
    case standing

    /// Die jeweils andere Phase.
    public var toggled: Phase {
        self == .sitting ? .standing : .sitting
    }

    public var displayName: String {
        switch self {
        case .sitting: return "Sitzen"
        case .standing: return "Stehen"
        }
    }

    public var systemImageName: String {
        switch self {
        case .sitting: return "figure.seated.side"
        case .standing: return "figure.stand"
        }
    }
}
