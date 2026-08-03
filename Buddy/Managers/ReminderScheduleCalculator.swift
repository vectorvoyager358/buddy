import Foundation

struct ReminderScheduleCalculator {
    private let calendar: Calendar

    init(
        calendar: Calendar = .current
    ) {
        self.calendar = calendar
    }

    func nextIntervalReminderDate(
        after now: Date,
        intervalMinutes: Int,
        lastHandled: Date?,
        weekdays: Set<Weekday>,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> Date? {
        guard intervalMinutes > 0 else {
            BuddyLogger.warning(
                "Reminder interval must be greater than zero.",
                category: .scheduler
            )

            return nil
        }

        guard !weekdays.isEmpty else {
            BuddyLogger.warning(
                "At least one active weekday is required.",
                category: .scheduler
            )

            return nil
        }

        guard isValidTimeRange(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        ) else {
            BuddyLogger.warning(
                "The reminder active-time range is invalid.",
                category: .scheduler
            )

            return nil
        }

        let interval = TimeInterval(
            intervalMinutes * 60
        )

        let candidate: Date

        if let lastHandled {
            candidate = max(
                lastHandled.addingTimeInterval(interval),
                now
            )
        } else if let todayStart = activeStartDate(
            for: now,
            startHour: startHour,
            startMinute: startMinute
        ),
        isActiveWeekday(
            now,
            weekdays: weekdays
        ),
        now < todayStart {
            // When Buddy launches before active hours,
            // the first reminder occurs at the start of the window.
            candidate = todayStart
        } else {
            candidate = now.addingTimeInterval(interval)
        }

        BuddyLogger.debug(
            "Initial reminder candidate is \(candidate).",
            category: .scheduler
        )

        return nextAllowedDate(
            from: candidate,
            weekdays: weekdays,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        )
    }

    private func nextAllowedDate(
        from candidate: Date,
        weekdays: Set<Weekday>,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> Date? {
        var searchDate = candidate

        // Two complete weeks are enough to find an enabled weekday.
        for _ in 0..<14 {
            guard
                let dayStart = calendar.date(
                    bySettingHour: startHour,
                    minute: startMinute,
                    second: 0,
                    of: searchDate
                ),
                let dayEnd = calendar.date(
                    bySettingHour: endHour,
                    minute: endMinute,
                    second: 0,
                    of: searchDate
                )
            else {
                BuddyLogger.error(
                    "Unable to construct the active-time window.",
                    category: .scheduler
                )

                return nil
            }

            let weekdayNumber = calendar.component(
                .weekday,
                from: searchDate
            )

            guard let weekday = Weekday(
                rawValue: weekdayNumber
            ) else {
                BuddyLogger.error(
                    "Unable to convert the calendar weekday.",
                    category: .scheduler
                )

                return nil
            }

            if weekdays.contains(weekday) {
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
                BuddyLogger.error(
                    "Unable to advance to the next day.",
                    category: .scheduler
                )

                return nil
            }

            searchDate = nextDay
        }

        BuddyLogger.warning(
            "No valid reminder date was found within fourteen days.",
            category: .scheduler
        )

        return nil
    }

    private func activeStartDate(
        for date: Date,
        startHour: Int,
        startMinute: Int
    ) -> Date? {
        calendar.date(
            bySettingHour: startHour,
            minute: startMinute,
            second: 0,
            of: date
        )
    }

    private func isActiveWeekday(
        _ date: Date,
        weekdays: Set<Weekday>
    ) -> Bool {
        let weekdayNumber = calendar.component(
            .weekday,
            from: date
        )

        guard let weekday = Weekday(
            rawValue: weekdayNumber
        ) else {
            return false
        }

        return weekdays.contains(weekday)
    }

    private func isValidTimeRange(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> Bool {
        guard
            (0...23).contains(startHour),
            (0...59).contains(startMinute),
            (0...23).contains(endHour),
            (0...59).contains(endMinute)
        else {
            return false
        }

        let startTotalMinutes =
            startHour * 60 + startMinute

        let endTotalMinutes =
            endHour * 60 + endMinute

        return endTotalMinutes > startTotalMinutes
    }
}
