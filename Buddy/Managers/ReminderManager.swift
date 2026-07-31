import Foundation

@MainActor
final class ReminderManager {
    private let notificationManager: NotificationManager
    private let buddyViewModel: BuddyViewModel

    private var scheduledTasks: [UUID: Task<Void, Never>] = [:]
    var onReminderTriggered: (() -> Void)?

    init(
        notificationManager: NotificationManager = .shared,
        buddyViewModel: BuddyViewModel
    ) {
        self.notificationManager = notificationManager
        self.buddyViewModel = buddyViewModel
    }

    func schedule(
        _ reminder: Reminder,
        after seconds: TimeInterval
    ) {
        cancel(reminderID: reminder.id)

        notificationManager.sendReminder(
            reminder,
            after: seconds
        )

        let task = Task { [weak self] in
            try? await Task.sleep(
                for: .seconds(seconds)
            )

            guard !Task.isCancelled else {
                return
            }

            guard let self else {
                return
            }

            self.buddyViewModel.showReminder(reminder)
            self.onReminderTriggered?()
            self.scheduledTasks[reminder.id] = nil
        }

        scheduledTasks[reminder.id] = task
    }

    func snooze(
        _ reminder: Reminder,
        for seconds: TimeInterval
    ) {
        buddyViewModel.showSnoozeConfirmation()

        schedule(
            reminder,
            after: seconds
        )
    }

    func cancel(reminderID: UUID) {
        scheduledTasks[reminderID]?.cancel()
        scheduledTasks[reminderID] = nil

        notificationManager.cancel(
            reminderID: reminderID
        )
    }

    func cancelAll() {
        for task in scheduledTasks.values {
            task.cancel()
        }

        scheduledTasks.removeAll()
        notificationManager.cancelAll()
    }
}
