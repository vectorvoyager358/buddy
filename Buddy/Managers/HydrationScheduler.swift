import Foundation

@MainActor
final class HydrationScheduler {
    private let storage: WellnessSettingsStorage
    private let developerSettingsStore:
        DeveloperSettingsStore

    private let reminderManager: ReminderManager
    private let scheduleCalculator:
        ReminderScheduleCalculator

    private var scheduledReminderID: UUID?

    init(
        storage: WellnessSettingsStorage,
        developerSettingsStore:
            DeveloperSettingsStore,
        reminderManager: ReminderManager,
        scheduleCalculator:
            ReminderScheduleCalculator =
                ReminderScheduleCalculator()
    ) {
        self.storage = storage
        self.developerSettingsStore =
            developerSettingsStore

        self.reminderManager = reminderManager
        self.scheduleCalculator =
            scheduleCalculator
    }

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

    func hydrationCompleted() {
        var settings = storage.load()
        let now = Date()

        settings.hydration.lastCompleted = now
        settings.hydration.lastHandled = now

        saveAndReschedule(settings)
    }

    func hydrationSkipped() {
        var settings = storage.load()

        settings.hydration.lastHandled = Date()

        saveAndReschedule(settings)
    }

    func hydrationSnoozed() {
        BuddyLogger.notice(
            "Hydration reminder was snoozed.",
            category: .reminders
        )
    }

    private func scheduleNextReminder(
        using hydration: HydrationSettings
    ) {
        let delay: TimeInterval

        if developerSettingsStore
            .fastTestingEnabled {
            delay = TimeInterval(
                developerSettingsStore
                    .testIntervalSeconds
            )

            BuddyLogger.notice(
                "Fast testing enabled. "
                + "Hydration reminder scheduled "
                + "in \(Int(delay)) seconds.",
                category: .scheduler
            )
        } else {
            let now = Date()

            guard let nextDate =
                scheduleCalculator
                    .nextIntervalReminderDate(
                        after: now,
                        intervalMinutes:
                            hydration.intervalMinutes,
                        lastHandled:
                            hydration.lastHandled
                            ?? hydration.lastCompleted,
                        weekdays:
                            hydration.weekdays,
                        startHour:
                            hydration.startHour,
                        startMinute:
                            hydration.startMinute,
                        endHour:
                            hydration.endHour,
                        endMinute:
                            hydration.endMinute
                    )
            else {
                BuddyLogger.error(
                    "Unable to calculate the next "
                    + "hydration reminder.",
                    category: .scheduler
                )

                return
            }

            delay = max(
                nextDate.timeIntervalSince(now),
                1
            )

            BuddyLogger.info(
                "Next hydration reminder "
                + "scheduled for \(nextDate).",
                category: .scheduler
            )
        }

        scheduleReminder(after: delay)
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

        reminderManager.schedule(
            reminder,
            after: delay
        )
    }

    private func cancelCurrentReminder() {
        guard let scheduledReminderID else {
            return
        }

        reminderManager.cancel(
            reminderID: scheduledReminderID
        )

        self.scheduledReminderID = nil
    }

    private func saveAndReschedule(
        _ settings: WellnessSettings
    ) {
        do {
            try storage.save(settings)

            cancelCurrentReminder()

            guard settings.hydration.isEnabled else {
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
