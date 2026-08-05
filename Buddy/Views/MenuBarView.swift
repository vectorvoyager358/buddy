import AppKit
import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel =
        MenuBarViewModel()

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.openSettings)
    private var openSettings

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            header

            Divider()
                .padding(.vertical, 10)

            reminderStatus

            Divider()
                .padding(.vertical, 10)

            actions
        }
        .padding(14)
        .frame(width: 290)
    }

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.85),
                                Color.indigo.opacity(0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: 38,
                        height: 38
                    )

                Image(
                    systemName: "circle.dotted"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Buddy")
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )

                Label(
                    viewModel.statusTitle,
                    systemImage:
                        viewModel.statusSystemImage
                )
                .font(.caption)
                .foregroundStyle(
                    viewModel.remindersPaused
                        ? Color.orange
                        : Color.green
                )
            }

            Spacer()
        }
    }

    private var reminderStatus: some View {
        VStack(
            alignment: .leading,
            spacing: 9
        ) {
            Label(
                viewModel.reminderSectionTitle,
                systemImage:
                    viewModel
                        .reminderSectionSystemImage
            )
            .font(
                .system(
                    size: 13,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                reminderColor
            )

            Text(
                viewModel.nextReminderText
            )
            .font(.system(size: 13))

            Text(
                viewModel.scheduleSummary
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private var reminderColor: Color {
        switch viewModel
            .reminderSectionColor {
        case .blue:
            return .blue

        case .purple:
            return .purple

        case .orange:
            return .orange

        case .indigo:
            return .indigo

        case .green:
            return .green
        }
    }

    private var actions: some View {
        VStack(spacing: 3) {
            MenuActionButton(
                title:
                    viewModel
                        .buddyActionTitle,
                systemImage:
                    viewModel
                        .buddyActionSystemImage
            ) {
                viewModel
                    .toggleBuddyVisibility()

                dismissMenuBar()
            }

            MenuActionButton(
                title:
                    viewModel.remindersPaused
                    ? "Resume Reminders"
                    : "Pause Reminders",
                systemImage:
                    viewModel.remindersPaused
                    ? "play.fill"
                    : "pause.fill"
            ) {
                viewModel.togglePause()
                dismissMenuBar()
            }

            MenuActionButton(
                title: "Settings…",
                systemImage: "gearshape"
            ) {
                openSettings()
                dismissMenuBar()
            }

            MenuActionButton(
                title: "Quit Buddy",
                systemImage: "power",
                role: .destructive
            ) {
                dismissMenuBar()
                viewModel.quitBuddy()
            }
        }
    }

    private func dismissMenuBar() {
        DispatchQueue.main.async {
            dismiss()
        }
    }
}

private struct MenuActionButton: View {
    let title: String
    let systemImage: String
    var role: ButtonRole?
    let action: () -> Void

    @State private var isHovering = false

    init(
        title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(
            role: role,
            action: action
        ) {
            HStack(spacing: 10) {
                Image(
                    systemName:
                        systemImage
                )
                .frame(width: 18)
                .foregroundStyle(
                    iconColor
                )

                Text(title)
                    .foregroundStyle(
                        textColor
                    )

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
        }
        .buttonStyle(
            MenuActionButtonStyle(
                isHovering:
                    isHovering,
                isDestructive:
                    role == .destructive
            )
        )
        .onHover { hovering in
            isHovering = hovering

            if hovering {
                NSCursor
                    .pointingHand
                    .push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var iconColor: Color {
        if role == .destructive
            && isHovering {
            return .red
        }

        return isHovering
            ? .primary
            : .secondary
    }

    private var textColor: Color {
        if role == .destructive
            && isHovering {
            return .red
        }

        return .primary
    }
}

private struct MenuActionButtonStyle:
    ButtonStyle {

    let isHovering: Bool
    let isDestructive: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .background(
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(
                    backgroundColor(
                        isPressed:
                            configuration
                                .isPressed
                    )
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .stroke(
                    borderColor(
                        isPressed:
                            configuration
                                .isPressed
                    ),
                    lineWidth: 1
                )
            }
            .scaleEffect(
                configuration.isPressed
                    ? 0.975
                    : 1
            )
            .animation(
                .easeOut(
                    duration: 0.10
                ),
                value:
                    configuration
                        .isPressed
            )
            .animation(
                .easeOut(
                    duration: 0.14
                ),
                value: isHovering
            )
    }

    private func backgroundColor(
        isPressed: Bool
    ) -> Color {
        if isPressed {
            return isDestructive
                ? Color.red.opacity(0.16)
                : Color.accentColor
                    .opacity(0.22)
        }

        if isHovering {
            return isDestructive
                ? Color.red.opacity(0.09)
                : Color.primary
                    .opacity(0.08)
        }

        return .clear
    }

    private func borderColor(
        isPressed: Bool
    ) -> Color {
        if isPressed {
            return isDestructive
                ? Color.red.opacity(0.30)
                : Color.accentColor
                    .opacity(0.35)
        }

        if isHovering {
            return Color.primary
                .opacity(0.08)
        }

        return .clear
    }
}
