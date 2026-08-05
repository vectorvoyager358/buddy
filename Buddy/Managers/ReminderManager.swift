import Foundation

@MainActor
final class ReminderManager {
    private let notificationManager: NotificationManager
    private let soundPlayer: ReminderSoundPlayer
    private let buddyViewModel: BuddyViewModel

    private var scheduledTasks: [
        UUID: Task<Void, Never>
    ] = [:]

    var onReminderTriggered: (() -> Void)?
    var onReminderCompleted: ((Reminder) -> Void)?
    var onReminderSnoozed: ((Reminder) -> Void)?
    var onReminderSkipped: ((Reminder) -> Void)?
    var onReminderResolved: (() -> Void)?

    init(
        notificationManager: NotificationManager,
        soundPlayer: ReminderSoundPlayer,
        buddyViewModel: BuddyViewModel
    ) {
        self.notificationManager = notificationManager
        self.soundPlayer = soundPlayer
        self.buddyViewModel = buddyViewModel
    }

    convenience init(
        buddyViewModel: BuddyViewModel
    ) {
        self.init(
            notificationManager: .shared,
            soundPlayer: .shared,
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

        let safeDelay = max(
            seconds,
            1
        )

        BuddyLogger.info(
            "Scheduling reminder '\(reminder.title)' after \(Int(safeDelay)) seconds.",
            category: .reminders
        )

        notificationManager.sendReminder(
            reminder,
            after: safeDelay
        )

        let task = Task { [weak self] in
            do {
                try await Task.sleep(
                    for: .seconds(safeDelay)
                )
            } catch {
                BuddyLogger.debug(
                    "Reminder task was cancelled: \(reminder.title).",
                    category: .reminders
                )

                return
            }

            guard !Task.isCancelled,
                  let self
            else {
                return
            }

            BuddyLogger.notice(
                "Reminder triggered: \(reminder.title).",
                category: .reminders
            )

            // The alert sound is mandatory for every Buddy reminder.
            soundPlayer.play()

            buddyViewModel.showReminder(
                reminder
            )

            onReminderTriggered?()

            scheduledTasks[reminder.id] = nil
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

        onReminderCompleted?(
            reminder
        )

        onReminderResolved?()
    }

    func snooze(
        _ reminder: Reminder,
        for seconds: TimeInterval
    ) {
        let safeDelay = max(
            seconds,
            1
        )

        BuddyLogger.info(
            "Reminder snoozed: \(reminder.title) for \(Int(safeDelay)) seconds.",
            category: .reminders
        )

        buddyViewModel.showSnoozeConfirmation()

        onReminderSnoozed?(
            reminder
        )

        schedule(
            reminder,
            after: safeDelay
        )

        onReminderResolved?()
    }

    func skip(
        _ reminder: Reminder
    ) {
        BuddyLogger.info(
            "Reminder skipped: \(reminder.title).",
            category: .reminders
        )

        buddyViewModel.skipReminder()

        onReminderSkipped?(
            reminder
        )

        onReminderResolved?()
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
            "Cancelled reminder with ID \(reminderID.uuidString).",
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
