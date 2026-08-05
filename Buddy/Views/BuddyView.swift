import SwiftUI

struct BuddyView: View {
    @ObservedObject var viewModel: BuddyViewModel
    @ObservedObject var animationEngine: AnimationEngine

    let reminderManager: ReminderManager

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 14) {
            messageArea
            buddyOrb
        }
        .frame(
            width: 340,
            height: 390
        )
        .contentShape(Rectangle())
        .animation(
            .spring(
                response: 0.38,
                dampingFraction: 0.82
            ),
            value: viewModel.state
        )
    }

    @ViewBuilder
    private var messageArea: some View {
        switch viewModel.state {
        case .idle:
            if isHovering {
                idleBubble
            }

        case .reminder(let reminder):
            reminderCard(reminder)

        case .happy(let message):
            feedbackBubble(message)
        }
    }

    private var idleBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.dotted")
                .foregroundStyle(.blue)

            Text("Buddy is active")
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(0.10),
                    radius: 8,
                    y: 3
                )
        )
        .transition(
            .move(edge: .bottom)
                .combined(with: .opacity)
        )
    }

    private func reminderCard(
        _ reminder: Reminder
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack(
                alignment: .center,
                spacing: 12
            ) {
                ZStack {
                    Circle()
                        .fill(
                            Color.blue.opacity(0.14)
                        )
                        .frame(
                            width: 46,
                            height: 46
                        )

                    Image(systemName: "drop.fill")
                        .font(.system(size: 21))
                        .foregroundStyle(.blue)
                }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text("Time to hydrate")
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )

                    Text("A quick wellness break")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(
                "You've been focused for a while. "
                + "Take a moment to drink some water."
            )
            .font(.system(size: 14))
            .foregroundStyle(
                .primary.opacity(0.88)
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .lineSpacing(3)

            HStack(spacing: 9) {
                Button {
                    reminderManager.complete(reminder)
                } label: {
                    Label(
                        "Done",
                        systemImage: "checkmark"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    reminderManager.snooze(
                        reminder,
                        for: snoozeDuration
                    )
                } label: {
                    Label(
                        "Snooze",
                        systemImage: "clock"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    reminderManager.skip(reminder)
                } label: {
                    Image(
                        systemName: "forward.end"
                    )
                }
                .buttonStyle(.borderless)
                .help("Skip this reminder")
            }
        }
        .padding(18)
        .frame(width: 310)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.22),
                    lineWidth: 1
                )
            }
            .shadow(
                color: .black.opacity(0.16),
                radius: 18,
                y: 8
            )
        )
        .transition(
            .move(edge: .bottom)
                .combined(with: .opacity)
                .combined(
                    with: .scale(scale: 0.96)
                )
        )
    }

    private func feedbackBubble(
        _ message: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: feedbackIcon)
                .foregroundStyle(feedbackColor)

            Text(message)
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: 285)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(.regularMaterial)
            .shadow(
                color: .black.opacity(0.10),
                radius: 10,
                y: 4
            )
        )
        .transition(
            .scale(scale: 0.96)
                .combined(with: .opacity)
        )
    }

    private var buddyOrb: some View {
        BuddyOrbView(
            state: visualState,
            isHovering: isHovering
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var visualState: BuddyVisualState {
        switch viewModel.state {
        case .idle:
            return stateFromAnimation

        case .reminder:
            return .reminder

        case .happy:
            return stateFromAnimation
        }
    }

    private var stateFromAnimation: BuddyVisualState {
        switch animationEngine.currentAnimation {
        case .idle, .wave:
            return .idle

        case .celebrate:
            return .completed

        case .thinking:
            return .skipped

        case .sleeping:
            return .snoozed
        }
    }

    private var feedbackIcon: String {
        switch visualState {
        case .completed:
            return "checkmark.circle.fill"

        case .snoozed, .sleeping:
            return "clock.fill"

        case .skipped:
            return "forward.end.circle.fill"

        case .idle, .reminder:
            return "circle.dotted"
        }
    }

    private var feedbackColor: Color {
        switch visualState {
        case .completed:
            return .green

        case .snoozed, .sleeping:
            return .indigo

        case .skipped:
            return .secondary

        case .idle, .reminder:
            return .blue
        }
    }

    private var snoozeDuration: TimeInterval {
        let developerSettings =
            DeveloperSettingsStore()

        if developerSettings.fastTestingEnabled {
            return TimeInterval(
                developerSettings.testIntervalSeconds
            )
        }

        return 10 * 60
    }
}

#Preview {
    let animationEngine = AnimationEngine()

    let viewModel = BuddyViewModel(
        animationEngine: animationEngine
    )

    BuddyView(
        viewModel: viewModel,
        animationEngine: animationEngine,
        reminderManager: ReminderManager(
            buddyViewModel: viewModel
        )
    )
    .frame(
        width: 340,
        height: 390
    )
    .background(
        Color.gray.opacity(0.22)
    )
}
