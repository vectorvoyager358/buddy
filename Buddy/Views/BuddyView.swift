import SwiftUI

struct BuddyView: View {
    @ObservedObject var viewModel: BuddyViewModel
    @ObservedObject var animationEngine: AnimationEngine

    let reminderManager: ReminderManager

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 10) {
            messageBubble
            buddyCharacter
        }
        .frame(
            width: 280,
            height: 300
        )
        .contentShape(Rectangle())
        .animation(
            .spring(response: 0.35),
            value: viewModel.state
        )
    }

    @ViewBuilder
    private var messageBubble: some View {
        switch viewModel.state {
        case .idle:
            if isHovering {
                idleBubble
            }

        case .reminder(let reminder):
            reminderBubble(reminder)

        case .happy(let message):
            happyBubble(message)
        }
    }

    private var idleBubble: some View {
        Text("Hi! I'm Buddy 👋")
            .font(
                .system(
                    size: 14,
                    weight: .medium
                )
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.regularMaterial)
            )
            .transition(
                .move(edge: .bottom)
                    .combined(with: .opacity)
            )
    }

    private func reminderBubble(
        _ reminder: Reminder
    ) -> some View {
        VStack(spacing: 10) {
            HStack(
                alignment: .top,
                spacing: 8
            ) {
                Text(reminder.type.icon)
                    .font(.title2)

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(reminder.title)
                        .font(.headline)

                    Text(reminder.message)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }

            HStack(spacing: 8) {
                Button("Done") {
                    reminderManager.complete(reminder)
                }
                .buttonStyle(.borderedProminent)

                Button("Snooze") {
                    reminderManager.snooze(
                        reminder,
                        for: 10
                    )
                }
                .buttonStyle(.bordered)

                Button("Skip") {
                    reminderManager.skip(reminder)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 8,
                    y: 4
                )
        )
        .transition(
            .move(edge: .bottom)
                .combined(with: .opacity)
        )
    }

    private func happyBubble(
        _ message: String
    ) -> some View {
        Text(message)
            .font(
                .system(
                    size: 14,
                    weight: .medium
                )
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 240)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
            .transition(
                .scale
                    .combined(with: .opacity)
            )
    }

    private var buddyCharacter: some View {
        ZStack {
            Circle()
                .fill(
                    animationEngine
                        .currentAnimation
                        .color
                        .gradient
                )
                .frame(
                    width: 130,
                    height: 130
                )
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 8,
                    y: 5
                )

            VStack(spacing: 8) {
                Text(
                    animationEngine
                        .currentAnimation
                        .emoji
                )
                .font(.system(size: 58))

                Text("Buddy")
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
            }
        }
        .scaleEffect(
            animationEngine.currentAnimation.scale
            * (isHovering ? 1.04 : 1)
        )
        .rotationEffect(
            .degrees(
                animationEngine
                    .currentAnimation
                    .rotation
            )
        )
        .animation(
            .spring(
                response: 0.35,
                dampingFraction: 0.6
            ),
            value: animationEngine.currentAnimation
        )
        .onHover { hovering in
            withAnimation {
                isHovering = hovering
            }
        }
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
        width: 280,
        height: 300
    )
    .background(
        .gray.opacity(0.3)
    )
}
