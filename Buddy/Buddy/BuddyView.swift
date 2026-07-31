import SwiftUI

struct BuddyView: View {
    @ObservedObject var viewModel: BuddyViewModel

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 10) {
            messageBubble

            buddyCharacter
        }
        .frame(width: 260, height: 280)
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
            .font(.system(size: 14, weight: .medium))
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
            HStack(alignment: .top, spacing: 8) {
                Text(reminder.type.icon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
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
                    viewModel.completeReminder()
                }
                .buttonStyle(.borderedProminent)

                Button("Snooze") {
                    viewModel.snoozeReminder(
                        reminder,
                        for: 10
                    )
                }
                .buttonStyle(.bordered)

                Button("Skip") {
                    viewModel.skipReminder()
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
            .font(.system(size: 14, weight: .medium))
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
                .fill(characterColor.gradient)
                .frame(width: 130, height: 130)
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 8,
                    y: 5
                )

            VStack(spacing: 8) {
                Text(characterEmoji)
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
        .scaleEffect(characterScale)
        .onHover { hovering in
            withAnimation {
                isHovering = hovering
            }
        }
    }

    private var characterEmoji: String {
        switch viewModel.state {
        case .idle:
            return "🤖"

        case .reminder:
            return "👋"

        case .happy:
            return "🥳"
        }
    }

    private var characterColor: Color {
        switch viewModel.state {
        case .idle:
            return .blue

        case .reminder:
            return .orange

        case .happy:
            return .green
        }
    }

    private var characterScale: CGFloat {
        switch viewModel.state {
        case .idle:
            return isHovering ? 1.06 : 1

        case .reminder:
            return 1.08

        case .happy:
            return 1.14
        }
    }
}

#Preview {
    BuddyView(
        viewModel: BuddyViewModel()
    )
    .frame(width: 260, height: 280)
    .background(.gray.opacity(0.3))
}
