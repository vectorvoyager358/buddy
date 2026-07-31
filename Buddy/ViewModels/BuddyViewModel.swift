import Foundation
import Combine

@MainActor
final class BuddyViewModel: ObservableObject {
    @Published private(set) var state: BuddyState = .idle

    let animationEngine: AnimationEngine

    private var returnToIdleTask: Task<Void, Never>?

    init(animationEngine: AnimationEngine) {
        self.animationEngine = animationEngine
    }

    func showReminder(_ reminder: Reminder) {
        cancelReturnToIdle()

        state = .reminder(reminder)

        animationEngine.play(.wave)
    }

    func completeReminder() {
        animationEngine.play(
            .celebrate,
            for: 3
        )

        showTemporaryMessage(
            "Nice work! Keep taking care of yourself 🎉",
            duration: 3
        )
    }

    func showSnoozeConfirmation() {
        animationEngine.play(
            .thinking,
            for: 2
        )

        showTemporaryMessage(
            "No problem. I'll remind you again soon!",
            duration: 2
        )
    }

    func skipReminder() {
        animationEngine.play(.idle)

        showTemporaryMessage(
            "Okay, we'll skip this one.",
            duration: 2
        )
    }

    private func showTemporaryMessage(
        _ message: String,
        duration: TimeInterval
    ) {
        cancelReturnToIdle()

        state = .happy(
            message: message
        )

        returnToIdleTask = Task { [weak self] in
            try? await Task.sleep(
                for: .seconds(duration)
            )

            guard !Task.isCancelled else {
                return
            }

            self?.state = .idle
        }
    }

    private func cancelReturnToIdle() {
        returnToIdleTask?.cancel()
        returnToIdleTask = nil
    }
}
