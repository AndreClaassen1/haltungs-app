import Foundation

/// Eigener, app-spezifischer Speicherort fuer den SwiftData-Store. Wichtig, weil
/// nicht-sandboxed Apps sonst den geteilten Default-Store
/// (~/Library/Application Support/default.store) verwenden und sich dort mit
/// anderen Apps (z.B. track) das Schema gegenseitig ueberschreiben.
enum StoreLocation {
    static var url: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let directory = base.appendingPathComponent("HaltungApp", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Haltung.store")
    }
}
