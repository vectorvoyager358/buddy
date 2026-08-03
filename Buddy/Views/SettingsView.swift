import SwiftUI

@MainActor
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init() {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel()
        )
    }

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Form {
                HydrationSettingsSection(
                    hydration: $viewModel.settings.hydration
                )
            }
            .formStyle(.grouped)

            Divider()

            footer
        }
        .frame(
            minWidth: 520,
            idealWidth: 560,
            minHeight: 520,
            idealHeight: 560
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 28))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 3) {
                Text("Buddy Settings")
                    .font(.title2.bold())

                Text("Configure your wellness reminders.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let statusMessage = viewModel.statusMessage {
                Label(
                    statusMessage,
                    systemImage: viewModel.hasError
                        ? "exclamationmark.triangle.fill"
                        : "checkmark.circle.fill"
                )
                .font(.callout)
                .foregroundStyle(
                    viewModel.hasError
                        ? Color.red
                        : Color.green
                )
                .lineLimit(2)
            }

            Spacer()

            Button("Restore Defaults") {
                viewModel.resetToDefaults()
            }

            Button("Save") {
                viewModel.save()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("s", modifiers: [.command])
        }
        .padding(16)
    }
}

#Preview {
    SettingsView()
}
