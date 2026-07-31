import Foundation
import Combine

@MainActor
final class BuddyViewModel: ObservableObject {
    @Published private(set) var state: BuddyState = .idle

    func showReminder(_ reminder: Reminder) {
        state = .reminder(reminder)
    }

    func completeReminder() {
        state = .happy(
            message: "Nice work! Keep taking care of yourself 🎉"
        )

        returnToIdle(after: 3)
    }

    func snoozeReminder(
        _ reminder: Reminder,
        for seconds: TimeInterval
    ) {
        state = .happy(
            message: "No problem. I'll remind you again soon!"
        )

        returnToIdle(after: 2)

        Task {
            try? await Task.sleep(
                for: .seconds(seconds)
            )

            guard !Task.isCancelled else {
                return
            }

            showReminder(reminder)

            NotificationManager.shared.sendReminder(
                reminder,
                after: 1
            )
        }
    }

    func skipReminder() {
        state = .happy(
            message: "Okay, we'll skip this one."
        )

        returnToIdle(after: 2)
    }

    private func returnToIdle(after seconds: TimeInterval) {
        Task {
            try? await Task.sleep(
                for: .seconds(seconds)
            )

            guard !Task.isCancelled else {
                return
            }

            state = .idle
        }
    }
}
