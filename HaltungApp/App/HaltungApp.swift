import SwiftUI
import SwiftData
import HaltungCore

@main
struct HaltungApp: App {
    /// Feste Fenster-ID der Einstellungen, geteilt mit dem Menubar-Button.
    static let settingsWindowID = "settings"

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    static let modelContainer: ModelContainer = {
        let schema = Schema([ReminderTypeModel.self, EventLogModel.self])
        let config = ModelConfiguration(schema: schema, url: StoreLocation.url, cloudKitDatabase: .none)
        // Bei inkompatiblem Altbestand auf eine frische, fluechtige Datenbank ausweichen.
        if let container = try? ModelContainer(for: schema, configurations: config) {
            return container
        }
        let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: fallback)
    }()

    @State private var engine: ReminderEngine

    init() {
        AppSettings.registerDefaults()
        let context = Self.modelContainer.mainContext
        let engine = ReminderEngine(
            context: context,
            notifications: NotificationService(),
            overlay: OverlayController()
        )
        engine.start()
        _engine = State(initialValue: engine)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(engine: engine)
                .modelContainer(Self.modelContainer)
        } label: {
            // Stummschaltung schlaegt die Phase im Icon: dass gerade nichts kommt,
            // ist die wichtigere Information als Sitzen oder Stehen.
            Image(systemName: engine.mutedUntil != nil ? "bell.slash" : engine.currentPhase.systemImageName)
        }
        .menuBarExtraStyle(.window)

        Window("Einstellungen", id: Self.settingsWindowID) {
            SettingsView(engine: engine)
                .modelContainer(Self.modelContainer)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
