import SwiftUI
import HaltungCore

/// Info-Panel einer Haltung im dunklen HUD-Stil (analog zur track-Pausenerinnerung).
/// Zeigt Piktogramm, Name, Kurz-Cue und die Schritt-für-Schritt-Anleitung plus
/// zwei Aktionen.
struct OverlayView: View {
    let config: ReminderConfig
    let phase: Phase
    let onComplete: () -> Void
    let onSnooze: () -> Void
    let onIgnore: () -> Void

    /// Eingeblendeter Inline-Player, sobald der Nutzer auf Abspielen tippt.
    @State private var showVideo = false

    /// Hinterlegte Video-URL, falls daraus eine gueltige YouTube-ID erkennbar ist.
    private var videoURL: URL? {
        config.videoURL.flatMap { url in YouTubeEmbed.videoID(from: url) == nil ? nil : url }
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: config.kind.systemImageName)
                .font(.system(size: 40))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)

            Text(config.name)
                .font(.title2.weight(.semibold))

            Text(config.kind.directionalCue(for: phase) ?? config.cueText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            let howTo = config.kind.howTo(for: phase)
            if !howTo.isEmpty {
                Text(howTo)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let videoURL {
                if showVideo {
                    YouTubePlayerView(videoURL: videoURL)
                        .frame(width: 312, height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Button {
                        showVideo = true
                    } label: {
                        Label("Video abspielen", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .tint(.red)
                }
            }

            VStack(spacing: 10) {
                Button {
                    onComplete()
                } label: {
                    Label("Erledigt", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)

                HStack(spacing: 10) {
                    secondaryButton("Später erinnern", icon: "clock.arrow.circlepath", action: onSnooze)
                    secondaryButton("Ignorieren", icon: "xmark.circle", action: onIgnore)
                }
            }
            .padding(.top, 4)

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
        .padding(24)
        .frame(width: 360)
        .environment(\.colorScheme, .dark)
    }

    /// Gleichförmiger Sekundär-Button für die nebeneinander stehenden Aktionen
    /// "Später erinnern" und "Ignorieren".
    private func secondaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }
}
