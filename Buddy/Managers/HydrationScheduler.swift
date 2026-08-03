import Foundation

@MainActor
final class HydrationScheduler {
    private let storage: WellnessSettingsStorage
    private let reminderManager: ReminderManager
    private let scheduleCalculator: ReminderScheduleCalculator

    private var scheduledReminderID: UUID?

    init(
        storage: WellnessSettingsStorage,
        reminderManager: ReminderManager,
        scheduleCalculator: ReminderScheduleCalculator =
            ReminderScheduleCalculator()
    ) {
        self.storage = storage
        self.reminderManager = reminderManager
        self.scheduleCalculator = scheduleCalculator
    }

    // MARK: - Lifecycle

    func start() {
        BuddyLogger.info(
            "Hydration scheduler is starting.",
            category: .scheduler
        )

        reload()
    }

    func reload() {
        BuddyLogger.debug(
            "Reloading hydration scheduler.",
            category: .scheduler
        )

        cancelCurrentReminder()

        let settings = storage.load()
        let hydration = settings.hydration

        guard hydration.isEnabled else {
            BuddyLogger.info(
                "Hydration reminders are disabled.",
                category: .scheduler
            )

            return
        }

        scheduleNextReminder(
            using: hydration
        )
    }

    func stop() {
        BuddyLogger.info(
            "Hydration scheduler is stopping.",
            category: .scheduler
        )

        cancelCurrentReminder()
    }

    // MARK: - User actions

    func hydrationCompleted() {
        var settings = storage.load()
        let now = Date()

        settings.hydration.lastCompleted = now
        settings.hydration.lastHandled = now

        BuddyLogger.notice(
            "Hydration reminder was completed.",
            category: .reminders
        )

        saveAndReschedule(settings)
    }

    func hydrationSkipped() {
        var settings = storage.load()

        settings.hydration.lastHandled = Date()

        BuddyLogger.info(
            "Hydration reminder was skipped.",
            category: .reminders
        )

        saveAndReschedule(settings)
    }

    func hydrationSnoozed() {
        BuddyLogger.notice(
            "Hydration reminder was snoozed.",
            category: .reminders
        )
    }

    // MARK: - Scheduling

    private func scheduleNextReminder(
        using hydration: HydrationSettings
    ) {
        let delay: TimeInterval

        if SchedulerConfiguration.useFastHydrationTesting {
            delay =
                SchedulerConfiguration.hydrationTestInterval

            BuddyLogger.debug(
                "Hydration test reminder scheduled in "
                + "\(Int(delay)) seconds.",
                category: .scheduler
            )
        } else {
            let now = Date()

            guard let nextDate =
                scheduleCalculator.nextIntervalReminderDate(
                    after: now,
                    intervalMinutes: hydration.intervalMinutes,
                    lastHandled:
                        hydration.lastHandled
                        ?? hydration.lastCompleted,
                    weekdays: hydration.weekdays,
                    startHour: hydration.startHour,
                    startMinute: hydration.startMinute,
                    endHour: hydration.endHour,
                    endMinute: hydration.endMinute
                )
            else {
                BuddyLogger.error(
                    "Unable to calculate the next hydration reminder.",
                    category: .scheduler
                )

                return
            }

            delay = max(
                nextDate.timeIntervalSince(now),
                1
            )

            BuddyLogger.info(
                "Next hydration reminder scheduled for \(nextDate).",
                category: .scheduler
            )
        }

        scheduleReminder(
            after: delay
        )
    }

    private func scheduleReminder(
        after delay: TimeInterval
    ) {
        let reminder = Reminder(
            title: "Drink Water",
            message: """
            You've been focused for a while. \
            Let's drink some water!
            """,
            type: .water
        )

        scheduledReminderID = reminder.id

        BuddyLogger.info(
            "Scheduling hydration reminder with ID "
            + reminder.id.uuidString
            + " after \(Int(delay)) seconds.",
            category: .scheduler
        )

        reminderManager.schedule(
            reminder,
            after: delay
        )
    }

    private func cancelCurrentReminder() {
        guard let scheduledReminderID else {
            return
        }

        BuddyLogger.debug(
            "Cancelling scheduled hydration reminder "
            + scheduledReminderID.uuidString,
            category: .scheduler
        )

        reminderManager.cancel(
            reminderID: scheduledReminderID
        )

        self.scheduledReminderID = nil
    }

    // MARK: - Persistence

    private func saveAndReschedule(
        _ settings: WellnessSettings
    ) {
        do {
            try storage.save(settings)

            cancelCurrentReminder()

            guard settings.hydration.isEnabled else {
                BuddyLogger.info(
                    "Hydration reminders are disabled after saving state.",
                    category: .scheduler
                )

                return
            }

            scheduleNextReminder(
                using: settings.hydration
            )
        } catch {
            BuddyLogger.error(
                "Unable to save hydration state: "
                + error.localizedDescription,
                category: .storage
            )
        }
    }
}
