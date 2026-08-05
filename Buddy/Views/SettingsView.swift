import SwiftUI

@MainActor
struct SettingsView: View {
    @StateObject private var viewModel:
        SettingsViewModel

    init() {
        _viewModel =
            StateObject(
                wrappedValue:
                    SettingsViewModel()
            )
    }

    init(
        viewModel:
            SettingsViewModel
    ) {
        _viewModel =
            StateObject(
                wrappedValue:
                    viewModel
            )
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(spacing: 18) {
                    scheduleOverviewCard
                    hydrationCard
                    supplementCard
                    developerCard
                }
                .padding(20)
            }

            Divider()

            footer
        }
        .frame(
            minWidth: 590,
            idealWidth: 620,
            minHeight: 720,
            idealHeight: 780
        )
        .background(
            Color(
                nsColor:
                    .windowBackgroundColor
            )
        )
        .animation(
            .easeOut(
                duration: 0.16
            ),
            value:
                viewModel
                    .hasUnsavedChanges
        )
        .onAppear {
            viewModel
                .reloadFromStorage()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 13,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue,
                            Color.indigo
                        ],
                        startPoint:
                            .topLeading,
                        endPoint:
                            .bottomTrailing
                    )
                )
                .frame(
                    width: 48,
                    height: 48
                )

                Image(
                    systemName:
                        "circle.dotted"
                )
                .font(
                    .system(size: 23)
                )
                .foregroundStyle(.white)
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("Buddy Settings")
                    .font(.title2.bold())

                Text(
                    "Configure how Buddy supports your workday wellness."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(
            EdgeInsets(
                top: 18,
                leading: 20,
                bottom: 18,
                trailing: 20
            )
        )
    }

    private var scheduleOverviewCard:
        some View {
        SettingsCard(
            title: "Current Schedule",
            systemImage:
                "calendar.badge.clock"
        ) {
            HStack(spacing: 16) {
                scheduleMetric(
                    title: "Hydration",
                    value:
                        "\(viewModel.settings.hydration.intervalMinutes) min",
                    systemImage:
                        "drop.fill"
                )

                Divider()
                    .frame(height: 42)

                scheduleMetric(
                    title: "Supplements",
                    value:
                        supplementScheduleSummary,
                    systemImage:
                        "pill.fill"
                )

                Divider()
                    .frame(height: 42)

                scheduleMetric(
                    title: "Active reminders",
                    value:
                        "\(enabledReminderCount)",
                    systemImage:
                        "bell.fill"
                )
            }

            if viewModel
                .fastTestingEnabled {
                Label(
                    "Developer testing is active. Reminders fire every \(viewModel.testIntervalSeconds) seconds.",
                    systemImage:
                        "hammer.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.top, 6)
            }
        }
    }

    private var hydrationCard:
        some View {
        SettingsCard(
            title: "Hydration",
            systemImage: "drop.fill"
        ) {
            HydrationSettingsSection(
                hydration:
                    $viewModel
                        .settings
                        .hydration
            )
        }
    }

    private var supplementCard:
        some View {
        SettingsCard(
            title: "Supplement",
            systemImage: "pill.fill"
        ) {
            SupplementSettingsSection(
                reminder:
                    viewModel
                        .supplementReminderBinding
            )
        }
    }

    private var developerCard:
        some View {
        SettingsCard(
            title: "Developer Testing",
            systemImage: "hammer.fill"
        ) {
            Toggle(
                "Enable fast reminder testing",
                isOn:
                    $viewModel
                        .fastTestingEnabled
            )
            .toggleStyle(.switch)

            Text(
                "Fast testing ignores normal intervals, active days, and configured times."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if viewModel
                .fastTestingEnabled {
                Divider()

                HStack {
                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(
                            "Test reminder interval"
                        )

                        Text(
                            "Use a short interval while developing Buddy."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Stepper(
                        value:
                            $viewModel
                                .testIntervalSeconds,
                        in: 1...60,
                        step: 1
                    ) {
                        Text(
                            "\(viewModel.testIntervalSeconds) sec"
                        )
                        .monospacedDigit()
                        .frame(
                            minWidth: 65,
                            alignment:
                                .trailing
                        )
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            statusArea

            Spacer()

            Button(
                "Restore Defaults"
            ) {
                viewModel
                    .resetToDefaults()
            }

            saveButton
        }
        .padding(16)
    }

    @ViewBuilder
    private var statusArea:
        some View {
        if let statusMessage =
            viewModel.statusMessage {
            Label(
                statusMessage,
                systemImage:
                    viewModel.hasError
                    ? "exclamationmark.triangle.fill"
                    : "checkmark.circle.fill"
            )
            .font(.callout)
            .foregroundStyle(
                viewModel.hasError
                ? Color.red
                : Color.green
            )
            .transition(.opacity)
        } else if viewModel
            .hasUnsavedChanges {
            Label(
                "Unsaved changes",
                systemImage:
                    "circle.fill"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .transition(.opacity)
        }
    }

    private var saveButton:
        some View {
        Button {
            viewModel.save()
        } label: {
            Text("Save Changes")
                .foregroundStyle(
                    viewModel
                        .hasUnsavedChanges
                    ? Color.white
                    : Color.primary
                        .opacity(0.72)
                )
                .frame(
                    minWidth: 105
                )
        }
        .buttonStyle(
            .borderedProminent
        )
        .controlSize(.large)
        .tint(
            viewModel.hasUnsavedChanges
            ? Color.accentColor
            : Color.gray.opacity(0.45)
        )
        .disabled(
            !viewModel
                .hasUnsavedChanges
        )
        .keyboardShortcut(
            "s",
            modifiers: [.command]
        )
        .help(
            viewModel.hasUnsavedChanges
            ? "Save your changes"
            : "No unsaved changes"
        )
        .animation(
            .easeOut(
                duration: 0.16
            ),
            value:
                viewModel
                    .hasUnsavedChanges
        )
    }

    private func scheduleMetric(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(
                systemName:
                    systemImage
            )
            .foregroundStyle(.blue)
            .frame(width: 18)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Text(value)
                    .font(
                        .system(
                            size: 13,
                            weight:
                                .semibold
                        )
                    )
                    .lineLimit(1)
            }
        }
        .frame(
            maxWidth: .infinity
        )
    }

    private var enabledReminderCount:
        Int {
        viewModel.settings.reminders
            .filter {
                $0.isEnabled
            }
            .count
    }

    private var supplementScheduleSummary:
        String {
        let supplement =
            viewModel.supplementReminder

        guard supplement.isEnabled
        else {
            return "Off"
        }

        guard case .fixedTimes(
            let schedule
        ) = supplement.schedule
        else {
            return "Not configured"
        }

        let count =
            schedule.times.count

        if count == 1 {
            return "1 time daily"
        }

        return "\(count) times daily"
    }
}

private struct SettingsCard<
    Content: View
>: View {

    let title: String
    let systemImage: String
    let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder
        content: () -> Content
    ) {
        self.title = title
        self.systemImage =
            systemImage
        self.content = content()
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Label(
                title,
                systemImage:
                    systemImage
            )
            .font(
                .system(
                    size: 15,
                    weight: .semibold
                )
            )
            .foregroundStyle(.primary)

            content
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color(
                    nsColor:
                        .controlBackgroundColor
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    Color.primary
                        .opacity(0.08),
                    lineWidth: 1
                )
            }
            .shadow(
                color:
                    .black.opacity(0.05),
                radius: 10,
                y: 4
            )
        )
    }
}

#Preview {
    SettingsView()
}
