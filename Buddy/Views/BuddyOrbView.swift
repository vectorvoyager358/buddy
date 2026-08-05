import SwiftUI

enum BuddyVisualState: Equatable {
    case idle
    case reminder
    case completed
    case snoozed
    case skipped
    case sleeping
}

struct BuddyOrbView: View {
    let state: BuddyVisualState
    let isHovering: Bool

    @State private var isBreathing = false
    @State private var isPulsing = false
    @State private var isBlinking = false
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        ZStack {
            groundShadow
            outerGlow
            orbSurface
            face
            statusDecoration
        }
        .frame(width: 176, height: 176)
        .scaleEffect(overallScale)
        .offset(y: verticalOffset)
        .animation(
            .easeInOut(duration: 2.4)
                .repeatForever(autoreverses: true),
            value: isBreathing
        )
        .animation(
            .easeInOut(duration: 0.85)
                .repeatForever(autoreverses: true),
            value: isPulsing
        )
        .animation(
            .spring(
                response: 0.32,
                dampingFraction: 0.76
            ),
            value: isHovering
        )
        .animation(
            .easeInOut(duration: 0.14),
            value: isBlinking
        )
        .task(id: state) {
            configureAnimation()
            await runBlinkLoop()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var groundShadow: some View {
        Ellipse()
            .fill(.black.opacity(0.15))
            .frame(width: 104, height: 18)
            .blur(radius: 7)
            .offset(y: 70)
            .scaleEffect(
                x: isBreathing ? 0.94 : 1,
                y: 1
            )
    }

    private var outerGlow: some View {
        Circle()
            .fill(glowColor.opacity(glowOpacity))
            .frame(width: 154, height: 154)
            .blur(radius: glowRadius)
            .scaleEffect(
                isPulsing ? 1.08 : 0.96
            )
    }

    private var orbSurface: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)

            Circle()
                .fill(surfaceGradient)

            Circle()
                .strokeBorder(
                    borderGradient,
                    lineWidth: 1.2
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.26),
                            .clear
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 76
                    )
                )

            Ellipse()
                .fill(.white.opacity(0.14))
                .frame(width: 82, height: 38)
                .blur(radius: 3)
                .offset(x: -18, y: -39)
        }
        .frame(width: 136, height: 136)
        .shadow(
            color: .black.opacity(0.18),
            radius: 18,
            y: 9
        )
        .overlay {
            completionRing
        }
    }

    private var face: some View {
        HStack(spacing: eyeSpacing) {
            eye
            eye
        }
        .offset(y: -2)
        .opacity(faceOpacity)
    }

    private var eye: some View {
        Capsule()
            .fill(eyeColor)
            .frame(
                width: eyeWidth,
                height: isBlinking ? 2 : eyeHeight
            )
    }

    @ViewBuilder
    private var statusDecoration: some View {
        switch state {
        case .reminder:
            reminderIndicator

        case .completed:
            completionIndicator

        case .snoozed:
            snoozeIndicator

        case .skipped:
            skipIndicator

        case .sleeping:
            sleepingIndicator

        case .idle:
            EmptyView()
        }
    }

    private var reminderIndicator: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.blue)
            .frame(width: 38, height: 38)
            .background(
                Circle()
                    .fill(.regularMaterial)
            )
            .overlay {
                Circle()
                    .stroke(
                        .white.opacity(0.28),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .black.opacity(0.12),
                radius: 7,
                y: 3
            )
            .offset(x: 56, y: -51)
            .scaleEffect(
                isPulsing ? 1.06 : 0.94
            )
    }

    private var completionIndicator: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(.green)
            )
            .shadow(
                color: .green.opacity(0.3),
                radius: 9,
                y: 3
            )
            .offset(x: 55, y: -51)
    }

    private var snoozeIndicator: some View {
        Image(systemName: "clock.fill")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.indigo)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(.regularMaterial)
            )
            .overlay {
                Circle()
                    .stroke(
                        .indigo.opacity(0.22),
                        lineWidth: 1
                    )
            }
            .offset(x: 55, y: -51)
    }

    private var skipIndicator: some View {
        Image(systemName: "forward.end.fill")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(.regularMaterial)
            )
            .offset(x: 54, y: -50)
    }

    private var sleepingIndicator: some View {
        VStack(
            alignment: .leading,
            spacing: -4
        ) {
            Text("Z")
                .font(.system(size: 18, weight: .semibold))

            Text("z")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.indigo.opacity(0.7))
        .offset(x: 57, y: -51)
    }

    @ViewBuilder
    private var completionRing: some View {
        if state == .completed {
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    Color.green,
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .padding(3)
        }
    }

    private var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: surfaceColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.52),
                .white.opacity(0.10),
                .black.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var surfaceColors: [Color] {
        switch state {
        case .idle:
            return [
                Color(
                    red: 0.36,
                    green: 0.43,
                    blue: 0.52
                ).opacity(0.72),
                Color(
                    red: 0.18,
                    green: 0.23,
                    blue: 0.31
                ).opacity(0.80)
            ]

        case .reminder:
            return [
                Color.blue.opacity(0.75),
                Color.indigo.opacity(0.82)
            ]

        case .completed:
            return [
                Color.green.opacity(0.68),
                Color.teal.opacity(0.78)
            ]

        case .snoozed, .sleeping:
            return [
                Color.indigo.opacity(0.66),
                Color.purple.opacity(0.76)
            ]

        case .skipped:
            return [
                Color.gray.opacity(0.58),
                Color(
                    red: 0.24,
                    green: 0.27,
                    blue: 0.32
                ).opacity(0.78)
            ]
        }
    }

    private var glowColor: Color {
        switch state {
        case .idle:
            return .blue

        case .reminder:
            return .cyan

        case .completed:
            return .green

        case .snoozed, .sleeping:
            return .indigo

        case .skipped:
            return .gray
        }
    }

    private var glowOpacity: Double {
        switch state {
        case .reminder:
            return 0.34

        case .completed:
            return 0.30

        case .idle:
            return 0.18

        case .snoozed, .sleeping:
            return 0.20

        case .skipped:
            return 0.12
        }
    }

    private var glowRadius: CGFloat {
        state == .reminder ? 24 : 20
    }

    private var eyeColor: Color {
        switch state {
        case .completed:
            return .white.opacity(0.94)

        case .skipped:
            return .white.opacity(0.42)

        default:
            return .white.opacity(0.82)
        }
    }

    private var eyeWidth: CGFloat {
        switch state {
        case .reminder:
            return 7

        case .snoozed, .sleeping:
            return 18

        default:
            return 8
        }
    }

    private var eyeHeight: CGFloat {
        switch state {
        case .reminder:
            return 18

        case .snoozed, .sleeping:
            return 2

        case .skipped:
            return 5

        default:
            return 13
        }
    }

    private var eyeSpacing: CGFloat {
        state == .reminder ? 26 : 24
    }

    private var faceOpacity: Double {
        state == .skipped ? 0.68 : 1
    }

    private var overallScale: CGFloat {
        let breathingScale: CGFloat =
            isBreathing ? 1.012 : 0.992

        let hoverScale: CGFloat =
            isHovering ? 1.03 : 1

        let pulseScale: CGFloat =
            state == .reminder && isPulsing
                ? 1.025
                : 1

        return breathingScale
            * hoverScale
            * pulseScale
    }

    private var verticalOffset: CGFloat {
        switch state {
        case .completed:
            return -4

        case .reminder:
            return isPulsing ? -2 : 0

        default:
            return 0
        }
    }

    private var accessibilityDescription: String {
        switch state {
        case .idle:
            return "Buddy is idle."

        case .reminder:
            return "Buddy is showing a wellness reminder."

        case .completed:
            return "Buddy confirms the reminder was completed."

        case .snoozed:
            return "Buddy confirms the reminder was snoozed."

        case .skipped:
            return "Buddy confirms the reminder was skipped."

        case .sleeping:
            return "Buddy is sleeping."
        }
    }

    private func configureAnimation() {
        isPulsing = false
        ringProgress = 0

        DispatchQueue.main.async {
            isBreathing = true
        }

        switch state {
        case .reminder:
            DispatchQueue.main.async {
                isPulsing = true
            }

        case .completed:
            withAnimation(
                .easeOut(duration: 0.55)
            ) {
                ringProgress = 1
            }

        case .idle,
             .snoozed,
             .skipped,
             .sleeping:
            break
        }
    }

    private func runBlinkLoop() async {
        while !Task.isCancelled {
            let delay = Double.random(
                in: 3.5...6.5
            )

            try? await Task.sleep(
                for: .seconds(delay)
            )

            guard !Task.isCancelled else {
                return
            }

            guard state != .snoozed,
                  state != .sleeping
            else {
                continue
            }

            isBlinking = true

            try? await Task.sleep(
                for: .milliseconds(110)
            )

            isBlinking = false
        }
    }
}

#Preview("Idle") {
    BuddyOrbView(
        state: .idle,
        isHovering: false
    )
    .padding(40)
    .background(Color.black.opacity(0.12))
}

#Preview("Reminder") {
    BuddyOrbView(
        state: .reminder,
        isHovering: false
    )
    .padding(40)
    .background(Color.black.opacity(0.12))
}

#Preview("Completed") {
    BuddyOrbView(
        state: .completed,
        isHovering: false
    )
    .padding(40)
    .background(Color.black.opacity(0.12))
}
