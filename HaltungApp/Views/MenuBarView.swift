import SwiftUI
import AppKit
import HaltungCore

/// Inhalt des Menubar-Fensters. Zeigt aktuelle Phase, Zeit bis zur naechsten
/// Erinnerung und schnelle Aktionen.
struct MenuBarView: View {
    @Bindable var engine: ReminderEngine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: engine.currentPhase.systemImageName)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aktuell: \(engine.currentPhase.displayName)")
                        .font(.headline)
                    countdownLine
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 2) {
                Button {
                    engine.manualSwitch()
                } label: {
                    Label("Jetzt zu \(engine.currentPhase.toggled.displayName) wechseln", systemImage: "arrow.up.arrow.down")
                }
                .buttonStyle(.borderless)
                Text("Bestätigt, dass du den Tisch umgestellt hast. Zählt Wechsel und Stehzeit.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            muteControls

            let stats = engine.todayStats()
            VStack(alignment: .leading, spacing: 6) {
                Text("Heute")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    statBadge(value: "\(stats.sitStandSwitches)", label: "Wechsel")
                    statBadge(value: minutesString(stats.standingSeconds), label: "Stehzeit")
                    statBadge(value: "\(stats.completed)", label: "Erledigt")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Haltungen & Übungen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(engine.infoList()) { config in
                        GridRow {
                            Image(systemName: config.kind.systemImageName)
                                .gridColumnAlignment(.center)
                                .foregroundStyle(.secondary)
                            Text(config.name)
                            Text(dueText(for: config))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .gridColumnAlignment(.trailing)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { engine.showInfo(config) }
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    openSettings()
                } label: {
                    Label("Einstellungen", systemImage: "gearshape")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Beenden") {
                    NSApplication.shared.terminate(nil)
                }
            }

            HStack(spacing: 6) {
                Text(BuildInfo.summary)
                Spacer()
                Text(BuildInfo.buildDate)
            }
            .font(.caption2)
            .foregroundStyle(.quaternary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(width: 300)
    }

    /// Stummschaltung: entweder die Dauer-Auswahl oder, wenn schon still, der
    /// Weg zurueck. Der Endzeitpunkt steht in der Kopfzeile (countdownLine) und
    /// wird hier nicht wiederholt.
    private var muteControls: some View {
        VStack(alignment: .leading, spacing: 2) {
            if engine.mutedUntil != nil {
                Button {
                    engine.unmute()
                } label: {
                    Label("Stummschaltung beenden", systemImage: "bell")
                }
                .buttonStyle(.borderless)
            } else {
                Menu {
                    ForEach(MuteDuration.allCases, id: \.self) { duration in
                        Button(duration.displayName) { engine.mute(for: duration) }
                    }
                } label: {
                    Label("Stumm schalten", systemImage: "bell.slash")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            Text(engine.mutedUntil != nil
                 ? "Erinnerungen melden sich sofort wieder."
                 : "Ruhe für Meetings oder Fokusarbeit. Danach geht es normal weiter.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// Sekundengenauer Countdown zur naechsten Erinnerung. Aktualisiert sich nur,
    /// solange das Popup offen ist (TimelineView pausiert sonst).
    @ViewBuilder
    private var countdownLine: some View {
        if let muted = engine.mutedUntil {
            Text("Stumm bis \(clockTime(muted))")
        } else if let next = engine.nextDueDate {
            let name = engine.nextReminderName ?? "Erinnerung"
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = Int(next.timeIntervalSince(context.date).rounded(.up))
                if remaining <= 0 {
                    Text("\(name): jetzt fällig")
                } else if remaining >= Self.clockThreshold {
                    Text("\(name) um \(clockTime(next))")
                } else {
                    Text("\(name) in \(remaining / 60):\(String(format: "%02d", remaining % 60)) min")
                }
            }
        } else {
            Text("Keine aktive Erinnerung")
        }
    }

    /// Ab dieser Restzeit wird die Uhrzeit statt eines Countdowns gezeigt.
    /// Ausserhalb der Arbeitszeit liegen Stunden bis zur naechsten Erinnerung —
    /// ein Sekunden-Countdown waere dort unlesbar ("in 720:34 min").
    private static let clockThreshold = 3600

    private func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// Oeffnet das Einstellungsfenster und bringt die Accessory-App in den Vordergrund.
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: HaltungApp.settingsWindowID)
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func minutesString(_ seconds: TimeInterval) -> String {
        "\(Int(seconds) / 60) min"
    }

    /// Restzeit bis zur naechsten Faelligkeit einer Erinnerung fuer die Liste.
    private func dueText(for config: ReminderConfig) -> String {
        if engine.mutedUntil != nil { return "stumm" }
        guard let due = engine.nextDue(for: config) else { return "aus" }
        let remaining = Int(due.timeIntervalSinceNow)
        if remaining <= 0 { return "jetzt" }
        if remaining >= Self.clockThreshold { return "um \(clockTime(due))" }
        return "in \(remaining / 60) min"
    }
}
