import Foundation
import ServiceManagement
import os

/// Registriert HaltungApp als Login Item, damit die App optional automatisch
/// beim Anmelden am Mac startet. Nutzt `SMAppService.mainApp` (ServiceManagement),
/// analog zu track und menubar-social.
@MainActor
enum LoginItemService {
    private static let logger = Logger(subsystem: "de.andreclaassen.haltungs-app", category: "LoginItem")

    /// Aktueller Ist-Zustand des Login Items.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Aktiviert oder deaktiviert den Autostart. Bei der ersten Aktivierung kann
    /// macOS eine Bestätigung in den Systemeinstellungen verlangen; in dem Fall
    /// werden die Anmeldeobjekte direkt geöffnet.
    static func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status == .requiresApproval {
                    logger.info("Login Item requires approval – opening System Settings")
                    SMAppService.openSystemSettingsLoginItems()
                }
                try service.register()
                logger.info("Login Item registered")
            } else {
                try service.unregister()
                logger.info("Login Item unregistered")
            }
        } catch {
            logger.error("Login Item toggle failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
