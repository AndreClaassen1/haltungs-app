import Foundation

/// Orthopaedisch begruendete Standard-Erinnerungen gemaess Konzept. Werden beim
/// ersten Start als Seed angelegt und durch "Auf Standard zuruecksetzen"
/// wiederhergestellt. Die Intervalle orientieren sich an der 60-30-10-Faustregel
/// und den DGUV/BAuA-Hinweisen (siehe RecommendationSource).
public enum DefaultReminders {

    /// Liefert einen frischen Satz Default-Erinnerungen mit neuen IDs.
    public static func makeAll() -> [ReminderConfig] {
        [
            ReminderConfig(
                name: ReminderKind.sitStand.displayName,
                kind: .sitStand,
                intervalMinutes: 60,
                modality: .overlay,
                cueText: "Zeit zum Aufstehen. Tisch hochfahren und im Stehen weiterarbeiten.",
                priority: 0,
                order: 0
            ),
            ReminderConfig(
                name: ReminderKind.microBreak.displayName,
                kind: .microBreak,
                intervalMinutes: 50,
                modality: .overlay,
                cueText: "Kurz aufstehen, Schultern kreisen, ein paar Schritte gehen.",
                priority: 1,
                order: 1
            ),
            ReminderConfig(
                name: ReminderKind.mobility.displayName,
                kind: .mobility,
                intervalMinutes: 90,
                modality: .overlay,
                cueText: "Mobilisation: Kinn zurücknehmen (Chin-Tuck), Brustkorb öffnen, Schultern kreisen.",
                priority: 2,
                order: 2,
                videoURL: URL(string: "https://youtu.be/7rnlAVhAK-8")
            ),
            ReminderConfig(
                name: ReminderKind.postureCue.displayName,
                kind: .postureCue,
                intervalMinutes: 30,
                modality: .silent,
                cueText: "Brustbein heben, Schultern locker nach hinten und unten, Kinn leicht zurück.",
                priority: 3,
                order: 3
            ),
            ReminderConfig(
                name: ReminderKind.eyeBreak.displayName,
                kind: .eyeBreak,
                intervalMinutes: 40,
                modality: .silent,
                cueText: "Blick für 20 Sekunden in die Ferne, etwa 6 Meter weg (20-20-20-Regel).",
                priority: 4,
                order: 4
            )
        ]
    }
}
