import Foundation

@MainActor
final class HydrationScheduler {
    private let storage: WellnessSettingsStorage
    private let reminderManager: ReminderManager
    private let calendar: Calendar

    private var scheduledReminderID: UUID?

    init(
        storage: WellnessSettingsStorage,
        reminderManager: ReminderManager,
        calendar: Calendar = .current
    ) {
        self.storage = storage
        self.reminderManager = reminderManager
        self.calendar = calendar
    }

    // MARK: - Lifecycle

    func start() {
        reload()
    }

    func reload() {
        cancelCurrentReminder()

        let settings = storage.load()
        let hydration = settings.hydration

        guard hydration.isEnabled else {
            print("Hydration reminders are disabled.")
            return
        }

        scheduleNextReminder(
            using: hydration
        )
    }

    func stop() {
        cancelCurrentReminder()
    }

    // MARK: - Reminder actions

    func hydrationCompleted() {
        var settings = storage.load()
        let now = Date()

        settings.hydration.lastCompleted = now
        settings.hydration.lastHandled = now

        saveAndReschedule(settings)
    }

    func hydrationSkipped() {
        var settings = storage.load()

        // Skip does not count as completion, but the next interval
        // should begin from the time the reminder was skipped.
        settings.hydration.lastHandled = Date()

        saveAndReschedule(settings)
    }

    // Snoozing is handled by ReminderManager.
    // We deliberately do not schedule another normal reminder here.
    func hydrationSnoozed() {
        print("Hydration reminder snoozed.")
    }

    // MARK: - Scheduling

    private func scheduleNextReminder(
        using hydration: HydrationSettings
    ) {
        let delay: TimeInterval

        if SchedulerConfiguration.useFastHydrationTesting {
            delay = SchedulerConfiguration.hydrationTestInterval

            print(
                "Hydration test reminder scheduled in "
                + "\(Int(delay)) seconds."
            )
        } else {
            let now = Date()

            guard let nextDate = nextReminderDate(
                after: now,
                settings: hydration
            ) else {
                print("Unable to calculate the next hydration reminder.")
                return
            }

            delay = max(
                nextDate.timeIntervalSince(now),
                1
            )

            print(
                "Next hydration reminder scheduled for \(nextDate)."
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

    // MARK: - Persistence

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
            print(
                "Unable to save hydration state: "
                + error.localizedDescription
            )
        }
    }

    // MARK: - Production date calculation

    private func nextReminderDate(
        after now: Date,
        settings: HydrationSettings
    ) -> Date? {
        let interval = TimeInterval(
            settings.intervalMinutes * 60
        )

        let referenceDate =
            settings.lastHandled
            ?? settings.lastCompleted

        let candidate: Date

        if let referenceDate {
            candidate = max(
                referenceDate.addingTimeInterval(interval),
                now
            )
        } else {
            candidate = now.addingTimeInterval(interval)
        }

        return nextAllowedDate(
            from: candidate,
            settings: settings
        )
    }

    private func nextAllowedDate(
        from candidate: Date,
        settings: HydrationSettings
    ) -> Date? {
        var searchDate = candidate

        // Searching 14 days guarantees that we cover at least
        // two complete weeks of possible active weekdays.
        for _ in 0..<14 {
            guard
                let dayStart = calendar.date(
                    bySettingHour: settings.startHour,
                    minute: settings.startMinute,
                    second: 0,
                    of: searchDate
                ),
                let dayEnd = calendar.date(
                    bySettingHour: settings.endHour,
                    minute: settings.endMinute,
                    second: 0,
                    of: searchDate
                )
            else {
                return nil
            }

            let weekdayNumber = calendar.component(
                .weekday,
                from: searchDate
            )

            guard let weekday = Weekday(
                rawValue: weekdayNumber
            ) else {
                return nil
            }

            if settings.weekdays.contains(weekday) {
                if searchDate < dayStart {
                    return dayStart
                }

                if searchDate <= dayEnd {
                    return searchDate
                }
            }

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: dayStart
            ) else {
                return nil
            }

            searchDate = nextDay
        }

        return nil
    }
}
