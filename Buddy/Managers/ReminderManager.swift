import Foundation

@MainActor
final class ReminderManager {
    private let notificationManager:
        NotificationManager

    private let soundPlayer:
        ReminderSoundPlayer

    private let buddyViewModel:
        BuddyViewModel

    private var scheduledTasks:
        [UUID: Task<Void, Never>] = [:]

    var onReminderTriggered:
        (() -> Void)?

    var onReminderCompleted:
        ((Reminder) -> Void)?

    var onReminderSnoozed:
        ((Reminder, TimeInterval) -> Void)?

    var onReminderSkipped:
        ((Reminder) -> Void)?

    init(
        notificationManager: NotificationManager,
        soundPlayer: ReminderSoundPlayer,
        buddyViewModel: BuddyViewModel
    ) {
        self.notificationManager =
            notificationManager

        self.soundPlayer =
            soundPlayer

        self.buddyViewModel =
            buddyViewModel
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

    /// Immediately presents a reminder that has become due.
    func present(
        _ reminder: Reminder
    ) {
        BuddyLogger.notice(
            "Reminder triggered: \(reminder.title).",
            category: .reminders
        )

        soundPlayer.play()

        buddyViewModel.showReminder(
            reminder
        )

        onReminderTriggered?()
    }

    /// Schedules a standalone reminder after a delay.
    ///
    /// The generic scheduler normally handles primary scheduling.
    /// This method remains available for isolated delayed reminders.
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

        let task = Task {
            [weak self] in

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

            scheduledTasks[
                reminder.id
            ] = nil

            present(reminder)
        }

        scheduledTasks[
            reminder.id
        ] = task
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
            "Reminder postponed: \(reminder.title) for \(Int(safeDelay)) seconds.",
            category: .reminders
        )

        buddyViewModel.showSnoozeConfirmation()

        onReminderSnoozed?(
            reminder,
            safeDelay
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

        onReminderSkipped?(
            reminder
        )
    }

    func cancel(
        reminderID: UUID
    ) {
        scheduledTasks[
            reminderID
        ]?.cancel()

        scheduledTasks[
            reminderID
        ] = nil

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
