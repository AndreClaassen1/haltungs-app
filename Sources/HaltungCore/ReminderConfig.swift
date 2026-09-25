import Foundation

/// Eine konfigurierbare Zeile der Erinnerungstypen-Tabelle. Reiner Wert-Typ,
/// damit die Logik vollstaendig ohne SwiftData oder UI testbar bleibt. Die App
/// haelt diese Werte in SwiftData vor und konvertiert hin und her.
public struct ReminderConfig: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    /// Anzeigename, frei editierbar.
    public var name: String
    public var kind: ReminderKind
    /// Aktiv oder pausiert.
    public var isEnabled: Bool
    /// Intervall in Minuten zwischen zwei Ausloesungen.
    public var intervalMinutes: Int
    public var modality: Modality
    /// Hinweistext, der in Notification und Overlay erscheint.
    public var cueText: String
    /// Prioritaet bei Kollision. Kleinere Zahl bedeutet hoehere Prioritaet.
    public var priority: Int
    /// Reihenfolge in der Tabelle.
    public var order: Int
    /// Optionales Erklaer-Video (YouTube). Wird im Overlay als Play-Button angeboten.
    public var videoURL: URL?

    public init(
        id: UUID = UUID(),
        name: String,
        kind: ReminderKind,
        isEnabled: Bool = true,
        intervalMinutes: Int,
        modality: Modality,
        cueText: String,
        priority: Int,
        order: Int,
        videoURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.isEnabled = isEnabled
        self.intervalMinutes = max(1, intervalMinutes)
        self.modality = modality
        self.cueText = cueText
        self.priority = priority
        self.order = order
        self.videoURL = videoURL
    }

    /// Intervall in Sekunden.
    public var intervalSeconds: TimeInterval {
        TimeInterval(max(1, intervalMinutes)) * 60
    }
}
