import Foundation

/// Liefert Versions- und Build-Informationen fuer die Fusszeile des
/// Menubar-Popups. Build-Datum = Aenderungsdatum der Executable.
enum BuildInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    static var configuration: String {
        #if DEBUG
        "Debug"
        #else
        "Release"
        #endif
    }

    static var buildDate: String {
        guard let executableURL = Bundle.main.executableURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: executableURL.path),
              let date = attrs[.modificationDate] as? Date else {
            return "?"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    /// Komplette Fusszeilen-Beschreibung links (App, Version, Build, Typ).
    static var summary: String {
        "Haltung \(version) (\(buildNumber)) \u{2022} \(configuration)"
    }
}
