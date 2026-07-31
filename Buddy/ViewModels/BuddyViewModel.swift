import Foundation
import Combine

@MainActor
final class BuddyViewModel: ObservableObject {
    @Published private(set) var state: BuddyState = .idle

    private var returnToIdleTask: Task<Void, Never>?

    func showReminder(_ reminder: Reminder) {
        cancelReturnToIdle()
        state = .reminder(reminder)
    }

    func completeReminder() {
        showTemporaryMessage(
            "Nice work! Keep taking care of yourself 🎉",
            duration: 3
        )
    }

    func showSnoozeConfirmation() {
        showTemporaryMessage(
            "No problem. I'll remind you again soon!",
            duration: 2
        )
    }

    func skipReminder() {
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
