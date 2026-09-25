import Foundation
import HaltungCore

/// Zentrale Keys und Defaults fuer die in UserDefaults gehaltenen Einstellungen.
/// Die SettingsView bindet ueber @AppStorage an dieselben Keys, die Engine liest
/// sie hier aus.
enum SettingsKeys {
    static let workStartMinute = "workStartMinute"
    static let workEndMinute = "workEndMinute"
    static let soundEnabled = "soundEnabled"
    static let overlayEnabled = "overlayEnabled"
    static let sourceURLString = "sourceURLString"
    static let standingMinutes = "standingMinutes"
    static let restMinutes = "restMinutes"
    static let snoozeMinutes = "snoozeMinutes"
    static let muteUntil = "muteUntil"
}

/// Liest die aktuellen Einstellungen aus UserDefaults mit sinnvollen Defaults.
struct AppSettings {
    var workWindow: WorkWindow
    var soundEnabled: Bool
    var overlayEnabled: Bool
    var sourceURL: URL
    /// Dauer im Stehen, nach der ans Hinsetzen erinnert wird.
    var standingMinutes: Int
    /// Ruhephase zwischen zwei Unterbrechungen. 0 bedeutet keine Ruhephase.
    var restMinutes: Int
    /// Dauer des Kurz-Snooze ("Später erinnern") im Overlay.
    var snoozeMinutes: Int
    /// Ende der globalen Stummschaltung. nil heisst: nicht stummgeschaltet.
    /// Bewusst persistiert (anders als der Snooze), damit ein Neustart waehrend
    /// eines Meetings die Stille nicht aufhebt.
    var muteUntil: Date?

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            SettingsKeys.workStartMinute: WorkWindow.standard.startMinute,
            SettingsKeys.workEndMinute: WorkWindow.standard.endMinute,
            SettingsKeys.soundEnabled: true,
            SettingsKeys.overlayEnabled: true,
            SettingsKeys.sourceURLString: RecommendationSource.defaultURL.absoluteString,
            SettingsKeys.standingMinutes: 10,
            SettingsKeys.restMinutes: 10,
            SettingsKeys.snoozeMinutes: 5
        ])
    }

    static func current() -> AppSettings {
        let defaults = UserDefaults.standard
        let start = defaults.integer(forKey: SettingsKeys.workStartMinute)
        let end = defaults.integer(forKey: SettingsKeys.workEndMinute)
        let urlString = defaults.string(forKey: SettingsKeys.sourceURLString) ?? RecommendationSource.defaultURL.absoluteString
        return AppSettings(
            workWindow: WorkWindow(startMinute: start, endMinute: end),
            soundEnabled: defaults.bool(forKey: SettingsKeys.soundEnabled),
            overlayEnabled: defaults.bool(forKey: SettingsKeys.overlayEnabled),
            sourceURL: URL(string: urlString) ?? RecommendationSource.defaultURL,
            standingMinutes: max(1, defaults.integer(forKey: SettingsKeys.standingMinutes)),
            restMinutes: max(0, defaults.integer(forKey: SettingsKeys.restMinutes)),
            snoozeMinutes: max(1, defaults.integer(forKey: SettingsKeys.snoozeMinutes)),
            muteUntil: muteUntil()
        )
    }

    /// Liest das Mute-Ende aus UserDefaults. Ein abgelaufener Wert gilt als
    /// "nicht stummgeschaltet", damit weder Engine noch UI ihn pruefen muessen.
    /// 0 ist der Default und bedeutet: nie stummgeschaltet.
    private static func muteUntil() -> Date? {
        let raw = UserDefaults.standard.double(forKey: SettingsKeys.muteUntil)
        guard raw > 0 else { return nil }
        let date = Date(timeIntervalSince1970: raw)
        return date > Date() ? date : nil
    }

    /// Setzt oder loescht (nil) das Mute-Ende.
    static func setMuteUntil(_ date: Date?) {
        if let date {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: SettingsKeys.muteUntil)
        } else {
            UserDefaults.standard.removeObject(forKey: SettingsKeys.muteUntil)
        }
    }
}
