import Foundation

@MainActor
final class ReminderManager {
    private let notificationManager: NotificationManager
    private let buddyViewModel: BuddyViewModel

    private var scheduledTasks: [
        UUID: Task<Void, Never>
    ] = [:]

    var onReminderTriggered: (() -> Void)?
    var onReminderCompleted: ((Reminder) -> Void)?
    var onReminderSnoozed: ((Reminder) -> Void)?
    var onReminderSkipped: ((Reminder) -> Void)?

    init(
        notificationManager: NotificationManager,
        buddyViewModel: BuddyViewModel
    ) {
        self.notificationManager = notificationManager
        self.buddyViewModel = buddyViewModel
    }

    convenience init(
        buddyViewModel: BuddyViewModel
    ) {
        self.init(
            notificationManager: .shared,
            buddyViewModel: buddyViewModel
        )
    }

    func schedule(
        _ reminder: Reminder,
        after seconds: TimeInterval
    ) {
        cancel(
            reminderID: reminder.id
        )

        BuddyLogger.info(
            "Scheduling reminder '\(reminder.title)' "
            + "after \(Int(seconds)) seconds.",
            category: .reminders
        )

        notificationManager.sendReminder(
            reminder,
            after: seconds
        )

        let task = Task { [weak self] in
            try? await Task.sleep(
                for: .seconds(seconds)
            )

            guard !Task.isCancelled else {
                BuddyLogger.debug(
                    "Reminder task was cancelled: \(reminder.title).",
                    category: .reminders
                )

                return
            }

            guard let self else {
                return
            }

            BuddyLogger.notice(
                "Reminder triggered: \(reminder.title).",
                category: .reminders
            )

            self.onReminderTriggered?()
            self.buddyViewModel.showReminder(reminder)
            self.scheduledTasks[reminder.id] = nil
        }

        scheduledTasks[reminder.id] = task
    }

    func complete(
        _ reminder: Reminder
    ) {
        BuddyLogger.notice(
            "Reminder completed: \(reminder.title).",
            category: .reminders
        )

        buddyViewModel.completeReminder()
        onReminderCompleted?(reminder)
    }

    func snooze(
        _ reminder: Reminder,
        for seconds: TimeInterval
    ) {
        BuddyLogger.info(
            "Reminder snoozed: \(reminder.title) "
            + "for \(Int(seconds)) seconds.",
            category: .reminders
        )

        buddyViewModel.showSnoozeConfirmation()
        onReminderSnoozed?(reminder)

        schedule(
            reminder,
            after: seconds
        )
    }

    func skip(
        _ reminder: Reminder
    ) {
        BuddyLogger.info(
            "Reminder skipped: \(reminder.title).",
            category: .reminders
        )

        buddyViewModel.skipReminder()
        onReminderSkipped?(reminder)
    }

    func cancel(
        reminderID: UUID
    ) {
        scheduledTasks[reminderID]?.cancel()
        scheduledTasks[reminderID] = nil

        notificationManager.cancel(
            reminderID: reminderID
        )

        BuddyLogger.debug(
            "Cancelled reminder with ID "
            + reminderID.uuidString,
            category: .reminders
        )
    }

    func cancelAll() {
        for task in scheduledTasks.values {
            task.cancel()
        }

        scheduledTasks.removeAll()
        notificationManager.cancelAll()

        BuddyLogger.info(
            "All scheduled reminders were cancelled.",
            category: .reminders
        )
    }
}
