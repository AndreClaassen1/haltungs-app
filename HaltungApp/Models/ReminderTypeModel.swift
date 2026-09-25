import Foundation
import SwiftData
import HaltungCore

/// Persistente, editierbare Zeile der Erinnerungstypen-Tabelle. Spiegelt den
/// reinen Wert-Typ `ReminderConfig` aus HaltungCore und konvertiert hin und her,
/// damit die Scheduling-Logik dependency-frei bleibt.
@Model
final class ReminderTypeModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var isEnabled: Bool
    var intervalMinutes: Int
    var modalityRaw: String
    var cueText: String
    var priority: Int
    var order: Int
    /// Optionales Erklaer-Video (YouTube-URL als String, da SwiftData URL? nicht
    /// direkt persistiert). nil bedeutet kein Video.
    var videoURLString: String?
    /// Letzter Ausloese-Zeitpunkt. Persistiert, damit Timer und Countdown einen
    /// App-Neustart ueberstehen. nil bedeutet seit Sitzungsstart nie gefeuert.
    var lastFired: Date?

    init(config: ReminderConfig) {
        self.id = config.id
        self.name = config.name
        self.kindRaw = config.kind.rawValue
        self.isEnabled = config.isEnabled
        self.intervalMinutes = config.intervalMinutes
        self.modalityRaw = config.modality.rawValue
        self.cueText = config.cueText
        self.priority = config.priority
        self.order = config.order
        self.videoURLString = config.videoURL?.absoluteString
        self.lastFired = nil
    }

    /// Konvertiert das Modell in den reinen Wert-Typ fuer die Engine.
    var config: ReminderConfig {
        ReminderConfig(
            id: id,
            name: name,
            kind: ReminderKind(rawValue: kindRaw) ?? .custom,
            isEnabled: isEnabled,
            intervalMinutes: intervalMinutes,
            modality: Modality(rawValue: modalityRaw) ?? .sound,
            cueText: cueText,
            priority: priority,
            order: order,
            videoURL: videoURLString.flatMap(URL.init(string:))
        )
    }

    /// Komfort-Zugriff auf das Enum mit Persistenz im Raw-String.
    var kind: ReminderKind {
        get { ReminderKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }

    var modality: Modality {
        get { Modality(rawValue: modalityRaw) ?? .sound }
        set { modalityRaw = newValue.rawValue }
    }
}
