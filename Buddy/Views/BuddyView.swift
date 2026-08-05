import SwiftUI

struct BuddyView: View {
    @ObservedObject var viewModel:
        BuddyViewModel

    @ObservedObject var animationEngine:
        AnimationEngine

    let reminderManager:
        ReminderManager

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
            Image(
                systemName: "circle.dotted"
            )
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
                    color:
                        .black.opacity(0.10),
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
            reminderHeader(reminder)

            Text(reminder.message)
                .font(.system(size: 14))
                .foregroundStyle(
                    .primary.opacity(0.88)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .lineSpacing(3)

            reminderActions(reminder)
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
                    with:
                        .scale(scale: 0.96)
                )
        )
    }

    private func reminderHeader(
        _ reminder: Reminder
    ) -> some View {
        HStack(
            alignment: .center,
            spacing: 12
        ) {
            ZStack {
                Circle()
                    .fill(
                        reminderColor(
                            for: reminder
                        )
                        .opacity(0.14)
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName:
                        reminder.type.systemImage
                )
                .font(.system(size: 21))
                .foregroundStyle(
                    reminderColor(
                        for: reminder
                    )
                )
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    reminder.type.headerTitle
                )
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )

                Text(
                    reminder.type.subtitle
                )
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func reminderActions(
        _ reminder: Reminder
    ) -> some View {
        HStack(spacing: 9) {
            if reminder.actions.allowsDone {
                Button {
                    reminderManager.complete(
                        reminder
                    )
                } label: {
                    Label(
                        "Done",
                        systemImage: "checkmark"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(
                    reminderColor(
                        for: reminder
                    )
                )
            }

            if let remindLaterMinutes =
                reminder.actions
                    .remindLaterMinutes {
                Button {
                    reminderManager.snooze(
                        reminder,
                        for:
                            remindLaterDuration(
                                minutes:
                                    remindLaterMinutes
                            )
                    )
                } label: {
                    Label(
                        remindLaterTitle(
                            for: reminder,
                            minutes:
                                remindLaterMinutes
                        ),
                        systemImage: "clock"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if reminder.actions.allowsSkip {
                Button {
                    reminderManager.skip(
                        reminder
                    )
                } label: {
                    Image(
                        systemName:
                            "forward.end"
                    )
                }
                .buttonStyle(.borderless)
                .help("Skip this reminder")
            }
        }
    }

    private func feedbackBubble(
        _ message: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(
                systemName: feedbackIcon
            )
            .foregroundStyle(
                feedbackColor
            )

            Text(message)
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .multilineTextAlignment(
                    .leading
                )
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
                color:
                    .black.opacity(0.10),
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

    private var visualState:
        BuddyVisualState {
        switch viewModel.state {
        case .idle:
            return stateFromAnimation

        case .reminder:
            return .reminder

        case .happy:
            return stateFromAnimation
        }
    }

    private var stateFromAnimation:
        BuddyVisualState {
        switch animationEngine
            .currentAnimation {
        case .idle,
             .wave:
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
            return
                "checkmark.circle.fill"

        case .snoozed,
             .sleeping:
            return "clock.fill"

        case .skipped:
            return
                "forward.end.circle.fill"

        case .idle,
             .reminder:
            return "circle.dotted"
        }
    }

    private var feedbackColor: Color {
        switch visualState {
        case .completed:
            return .green

        case .snoozed,
             .sleeping:
            return .indigo

        case .skipped:
            return .secondary

        case .idle,
             .reminder:
            return .blue
        }
    }

    private func remindLaterTitle(
        for reminder: Reminder,
        minutes: Int
    ) -> String {
        switch reminder.type {
        case .water:
            return "Snooze"

        case .supplement:
            return
                "Remind in \(minutes) min"

        case .stretch,
             .eyeBreak,
             .walk,
             .custom:
            return
                "Remind in \(minutes) min"
        }
    }

    private func remindLaterDuration(
        minutes: Int
    ) -> TimeInterval {
        let developerSettings =
            DeveloperSettingsStore()

        if developerSettings
            .fastTestingEnabled {
            return TimeInterval(
                developerSettings
                    .testIntervalSeconds
            )
        }

        return TimeInterval(
            minutes * 60
        )
    }

    private func reminderColor(
        for reminder: Reminder
    ) -> Color {
        switch reminder.type {
        case .water:
            return .blue

        case .supplement:
            return .purple

        case .stretch:
            return .orange

        case .eyeBreak:
            return .indigo

        case .walk:
            return .green

        case .custom:
            return .blue
        }
    }
}

#Preview("Hydration") {
    makeBuddyPreview(
        reminder: Reminder(
            title: "Drink Water",
            message:
                "Take a moment to drink some water.",
            type: .water
        )
    )
}

#Preview("Supplement") {
    makeBuddyPreview(
        reminder: Reminder(
            title: "Vitamin D",
            message:
                "It is time to take Vitamin D.",
            type: .supplement,
            actions: .supplement
        )
    )
}

@MainActor
private func makeBuddyPreview(
    reminder: Reminder
) -> some View {
    let animationEngine =
        AnimationEngine()

    let viewModel =
        BuddyViewModel(
            animationEngine:
                animationEngine
        )

    let manager =
        ReminderManager(
            buddyViewModel: viewModel
        )

    viewModel.showReminder(reminder)

    return BuddyView(
        viewModel: viewModel,
        animationEngine:
            animationEngine,
        reminderManager: manager
    )
    .frame(
        width: 340,
        height: 390
    )
    .background(
        Color.gray.opacity(0.22)
    )
}
