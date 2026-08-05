import Foundation

@MainActor
final class HydrationScheduler {
    private let storage: WellnessSettingsStorage
    private let developerSettingsStore: DeveloperSettingsStore
    private let runtimeStore: ReminderRuntimeStore
    private let reminderManager: ReminderManager
    private let scheduleCalculator: ReminderScheduleCalculator

    private var scheduledReminderID: UUID?

    init(
        storage: WellnessSettingsStorage,
        developerSettingsStore: DeveloperSettingsStore,
        runtimeStore: ReminderRuntimeStore,
        reminderManager: ReminderManager,
        scheduleCalculator: ReminderScheduleCalculator
    ) {
        self.storage = storage
        self.developerSettingsStore = developerSettingsStore
        self.runtimeStore = runtimeStore
        self.reminderManager = reminderManager
        self.scheduleCalculator = scheduleCalculator
    }

    convenience init(
        storage: WellnessSettingsStorage,
        developerSettingsStore: DeveloperSettingsStore,
        runtimeStore: ReminderRuntimeStore,
        reminderManager: ReminderManager
    ) {
        self.init(
            storage: storage,
            developerSettingsStore: developerSettingsStore,
            runtimeStore: runtimeStore,
            reminderManager: reminderManager,
            scheduleCalculator: ReminderScheduleCalculator()
        )
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

        guard !runtimeStore.remindersPaused else {
            BuddyLogger.info(
                "Hydration scheduling is paused.",
                category: .scheduler
            )

            publishRuntimeChange()
            return
        }

        let settings = storage.load()
        let hydration = settings.hydration

        guard hydration.isEnabled else {
            BuddyLogger.info(
                "Hydration reminders are disabled.",
                category: .scheduler
            )

            publishRuntimeChange()
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

        BuddyLogger.notice(
            "Hydration reminder was completed.",
            category: .reminders
        )

        saveAndReschedule(settings)
    }

    func hydrationSkipped() {
        var settings = storage.load()

        settings.hydration.lastHandled = Date()

        BuddyLogger.notice(
            "Hydration reminder was skipped.",
            category: .reminders
        )

        saveAndReschedule(settings)
    }

    func hydrationSnoozed() {
        runtimeStore.nextHydrationReminderDate = nil
        publishRuntimeChange()

        BuddyLogger.notice(
            "Hydration reminder was snoozed.",
            category: .reminders
        )
    }

    private func scheduleNextReminder(
        using hydration: HydrationSettings
    ) {
        if developerSettingsStore.fastTestingEnabled {
            scheduleFastTestingReminder()
            return
        }

        scheduleNormalReminder(
            using: hydration
        )
    }

    private func scheduleFastTestingReminder() {
        let delay = TimeInterval(
            max(
                developerSettingsStore.testIntervalSeconds,
                1
            )
        )

        let nextDate = Date().addingTimeInterval(delay)

        runtimeStore.nextHydrationReminderDate = nextDate
        publishRuntimeChange()

        BuddyLogger.notice(
            "Fast testing enabled. Hydration reminder scheduled for \(nextDate).",
            category: .scheduler
        )

        scheduleReminder(
            after: delay
        )
    }

    private func scheduleNormalReminder(
        using hydration: HydrationSettings
    ) {
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
            runtimeStore.nextHydrationReminderDate = nil
            publishRuntimeChange()

            BuddyLogger.error(
                "Unable to calculate the next hydration reminder.",
                category: .scheduler
            )

            return
        }

        let delay = max(
            nextDate.timeIntervalSince(now),
            1
        )

        runtimeStore.nextHydrationReminderDate = nextDate
        publishRuntimeChange()

        BuddyLogger.info(
            "Next hydration reminder scheduled for \(nextDate).",
            category: .scheduler
        )

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
            Take a moment to drink some water.
            """,
            type: .water
        )

        scheduledReminderID = reminder.id

        BuddyLogger.info(
            "Scheduling hydration reminder with ID \(reminder.id.uuidString) after \(Int(delay)) seconds.",
            category: .scheduler
        )

        reminderManager.schedule(
            reminder,
            after: delay
        )
    }

    private func cancelCurrentReminder() {
        if let scheduledReminderID {
            BuddyLogger.debug(
                "Cancelling scheduled hydration reminder \(scheduledReminderID.uuidString).",
                category: .scheduler
            )

            reminderManager.cancel(
                reminderID: scheduledReminderID
            )

            self.scheduledReminderID = nil
        }

        runtimeStore.nextHydrationReminderDate = nil
        publishRuntimeChange()
    }

    private func saveAndReschedule(
        _ settings: WellnessSettings
    ) {
        do {
            try storage.save(settings)

            cancelCurrentReminder()

            guard !runtimeStore.remindersPaused else {
                BuddyLogger.info(
                    "Hydration state saved, but reminders remain paused.",
                    category: .scheduler
                )

                return
            }

            guard settings.hydration.isEnabled else {
                BuddyLogger.info(
                    "Hydration state saved, but hydration reminders are disabled.",
                    category: .scheduler
                )

                return
            }

            scheduleNextReminder(
                using: settings.hydration
            )
        } catch {
            BuddyLogger.error(
                "Unable to save hydration state: \(error.localizedDescription)",
                category: .storage
            )
        }
    }

    private func publishRuntimeChange() {
        NotificationCenter.default.post(
            name: .reminderRuntimeDidChange,
            object: nil
        )
    }
}
