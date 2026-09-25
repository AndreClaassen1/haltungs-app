import Foundation
import UserNotifications
import HaltungCore

/// Huelle um UNUserNotificationCenter. Sendet Notifications und meldet Klicks
/// darauf zurueck, damit das Info-Panel der jeweiligen Haltung geoeffnet wird.
@MainActor
final class NotificationService: NSObject {

    /// Aufgerufen, wenn der Nutzer auf eine Notification tippt. Liefert die ID
    /// der zugehoerigen Erinnerung.
    var onTap: ((UUID) -> Void)?

    /// Registriert sich als Delegate, damit Klicks und Vordergrund-Anzeige
    /// behandelt werden.
    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Sendet eine sofortige Notification fuer die Erinnerung. Der Body kann
    /// richtungsabhaengig sein (z.B. Hinsetzen statt Aufstehen). Die Reminder-ID
    /// reist im userInfo mit, damit der Klick die richtige Haltung oeffnet.
    func notify(_ config: ReminderConfig, body: String, playSound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = config.name
        content.body = body
        content.userInfo = ["reminderID": config.id.uuidString]
        if playSound {
            content.sound = .default
        }
        let request = UNNotificationRequest(
            identifier: config.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Notifications auch anzeigen, wenn die App im Vordergrund ist.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Klick auf die Notification: zugehoerige Erinnerung melden.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let idString = response.notification.request.content.userInfo["reminderID"] as? String
        if let idString, let id = UUID(uuidString: idString) {
            Task { @MainActor [weak self] in
                self?.onTap?(id)
            }
        }
        completionHandler()
    }
}
