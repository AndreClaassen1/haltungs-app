import SwiftUI
import HaltungCore

/// Einstellungen: konfigurierbare Erinnerungstypen-Tabelle, allgemeine
/// Parameter, Quellen-Link und Tagesstatistik.
struct SettingsView: View {
    @Bindable var engine: ReminderEngine

    @AppStorage(SettingsKeys.workStartMinute) private var workStartMinute = WorkWindow.standard.startMinute
    @AppStorage(SettingsKeys.workEndMinute) private var workEndMinute = WorkWindow.standard.endMinute
    @AppStorage(SettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKeys.overlayEnabled) private var overlayEnabled = true
    @AppStorage(SettingsKeys.standingMinutes) private var standingMinutes = 10
    @AppStorage(SettingsKeys.restMinutes) private var restMinutes = 10
    @AppStorage(SettingsKeys.snoozeMinutes) private var snoozeMinutes = 5

    @State private var launchAtLogin = LoginItemService.isEnabled

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("Allgemein", systemImage: "gearshape") }

            reminderTab
                .tabItem { Label("Erinnerungen", systemImage: "bell.badge") }

            infoTab
                .tabItem { Label("Quelle & Statistik", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 560)
        .padding()
    }

    // MARK: - Erinnerungen

    private var reminderTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Erinnerungstypen")
                .font(.title3.weight(.semibold))
            Text("Jede Erinnerung läuft in ihrem eigenen Takt: sie meldet sich jeweils nach ihrer eingestellten Wartezeit (Intervall). Fallen mehrere gleichzeitig an, kommt zuerst die mit der höheren Priorität, die übrigen folgen nach der Ruhephase. Der Sitz-Steh-Wechsel nutzt im Stehen die Stehdauer statt seines Intervalls.")
                .font(.caption)
                .foregroundStyle(.secondary)

            List {
                ForEach(engine.reminderModels) { reminder in
                    ReminderRowView(model: reminder)
                }
                .onDelete { engine.deleteReminders(at: $0) }
            }

            HStack {
                Button {
                    engine.addReminder()
                } label: {
                    Label("Hinzufügen", systemImage: "plus")
                }

                Spacer()

                Button(role: .destructive) {
                    engine.resetToDefaults()
                } label: {
                    Label("Auf Standard zurücksetzen", systemImage: "arrow.counterclockwise")
                }
            }
        }
    }

    // MARK: - Allgemein

    private var generalTab: some View {
        Form {
            Section("Arbeitszeitfenster") {
                // Die Grenzen haengen voneinander ab: bei Start == Ende waere das
                // Fenster leer, es koennte nie etwas feuern, und der Countdown
                // wuerde eine Uhrzeit versprechen, zu der nichts passiert.
                Stepper(value: $workStartMinute, in: 0...(workEndMinute - 30), step: 30) {
                    Text("Start: \(timeString(workStartMinute))")
                }
                Stepper(value: $workEndMinute, in: (workStartMinute + 30)...1440, step: 30) {
                    Text("Ende: \(timeString(workEndMinute))")
                }
            }

            Section("Verhalten") {
                Stepper(value: $standingMinutes, in: 1...60) {
                    Text("Stehdauer: \(standingMinutes) min")
                }
                Text("Nach dieser Zeit im Stehen erinnert die App ans Hinsetzen. Das Sitz-Intervall stellst du in der Erinnerung Sitz-Steh-Wechsel ein.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper(value: $restMinutes, in: 0...30) {
                    Text(restMinutes == 0 ? "Ruhephase: aus" : "Ruhephase: \(restMinutes) min")
                }
                Text("Nach jeder Erinnerung bleibt es für diese Zeit ruhig. Fallen mehrere Erinnerungen gleichzeitig an, kommen sie nacheinander statt auf einmal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper(value: $snoozeMinutes, in: 1...30) {
                    Text("Später erinnern: \(snoozeMinutes) min")
                }
                Text("Drückst du im Popup „Später erinnern“, meldet sich derselbe Cue nach dieser kurzen Zeit erneut. „Ignorieren“ überspringt ihn dagegen bis zum nächsten regulären Intervall.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Ton abspielen", isOn: $soundEnabled)
                Toggle("Glass-Overlay anzeigen", isOn: $overlayEnabled)
            }

            Section("Start") {
                Toggle("HaltungApp beim Anmelden starten", isOn: $launchAtLogin)
                    .help("Registriert HaltungApp als Login Item. Bei der ersten Aktivierung musst du den Eintrag in den Systemeinstellungen unter \u{201E}Allgemein → Anmeldeobjekte\u{201C} bestätigen.")
                    .onChange(of: launchAtLogin) { _, newValue in
                        LoginItemService.setEnabled(newValue)
                        launchAtLogin = LoginItemService.isEnabled
                    }
            }
        }
        .formStyle(.grouped)
    }

    private func timeString(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    // MARK: - Quelle & Statistik

    private var infoTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quelle der Empfehlungen")
                    .font(.headline)
                Text(RecommendationSource.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link(RecommendationSource.title, destination: RecommendationSource.dguvURL)
                Link("BAuA: Bewegung am Arbeitsplatz", destination: RecommendationSource.bauaURL)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Heute")
                    .font(.headline)
                let stats = engine.todayStats()
                Label("\(stats.sitStandSwitches) Sitz-Steh-Wechsel", systemImage: "arrow.up.arrow.down")
                Label("\(Int(stats.standingSeconds) / 60) min Stehzeit", systemImage: "figure.stand")
                Label("\(stats.completed) erledigt, \(stats.snoozed) verschoben", systemImage: "checkmark.circle")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
