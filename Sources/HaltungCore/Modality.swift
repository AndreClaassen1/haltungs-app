import Foundation

/// Wie aufdringlich eine Erinnerung praesentiert wird. Aufsteigend von leise
/// bis zum Glass-Overlay.
public enum Modality: String, Codable, CaseIterable, Sendable {
    /// Nur eine stille System-Notification, kein Ton, kein Overlay.
    case silent
    /// Notification mit dezentem Ton.
    case sound
    /// Notification mit Ton plus schwebendes Liquid-Glass-Overlay-Panel.
    case overlay

    public var displayName: String {
        switch self {
        case .silent: return "Leise"
        case .sound: return "Ton"
        case .overlay: return "Overlay"
        }
    }

    /// Soll bei dieser Modalitaet ein Ton abgespielt werden?
    public var playsSound: Bool {
        self != .silent
    }

    /// Soll ein Glass-Overlay-Panel angezeigt werden?
    public var showsOverlay: Bool {
        self == .overlay
    }
}
