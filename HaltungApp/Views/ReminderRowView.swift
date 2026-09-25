import SwiftUI
import HaltungCore

/// Editierbare Zeile der Erinnerungstypen-Tabelle.
struct ReminderRowView: View {
    @Bindable var model: ReminderTypeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("", isOn: $model.isEnabled)
                    .labelsHidden()
                Image(systemName: model.kind.systemImageName)
                    .foregroundStyle(.secondary)
                TextField("Name", text: $model.name)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                Stepper(value: $model.intervalMinutes, in: 1...240) {
                    Text("Intervall: \(model.intervalMinutes) min")
                        .font(.caption)
                }

                Picker("Modus", selection: $model.modality) {
                    ForEach(Modality.allCases, id: \.self) { modality in
                        Text(modality.displayName).tag(modality)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()

                Stepper(value: $model.priority, in: 0...9) {
                    Text("Prio: \(model.priority)")
                        .font(.caption)
                }
            }

            TextField("Hinweistext", text: $model.cueText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
                .font(.caption)

            HStack(spacing: 6) {
                Image(systemName: "play.rectangle")
                    .foregroundStyle(.secondary)
                TextField("YouTube-Link (optional)", text: videoURLBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    /// Brueckt das optionale `videoURLString` auf ein nicht-optionales TextField:
    /// leere Eingabe wird zu nil, damit kein Leerstring persistiert wird.
    private var videoURLBinding: Binding<String> {
        Binding(
            get: { model.videoURLString ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                model.videoURLString = trimmed.isEmpty ? nil : trimmed
            }
        )
    }
}
