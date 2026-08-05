import Foundation

struct ReminderScheduleCalculator {
    private let calendar: Calendar

    init(
        calendar: Calendar = .current
    ) {
        self.calendar = calendar
    }

    func nextReminderDate(
        after date: Date,
        for reminder: ReminderDefinition,
        lastHandled: Date? = nil
    ) -> Date? {
        guard reminder.isEnabled,
              !reminder.weekdays.isEmpty
        else {
            return nil
        }

        switch reminder.schedule {
        case .interval(let schedule):
            return nextIntervalReminderDate(
                after: date,
                intervalMinutes: schedule.intervalMinutes,
                lastHandled: lastHandled,
                weekdays: reminder.weekdays,
                startHour: schedule.startTime.hour,
                startMinute: schedule.startTime.minute,
                endHour: schedule.endTime.hour,
                endMinute: schedule.endTime.minute
            )

        case .fixedTimes(let schedule):
            return nextFixedTimeReminderDate(
                after: date,
                times: schedule.times,
                weekdays: reminder.weekdays
            )
        }
    }

    func nextIntervalReminderDate(
        after date: Date,
        intervalMinutes: Int,
        lastHandled: Date?,
        weekdays: Set<Weekday>,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> Date? {
        guard intervalMinutes > 0,
              !weekdays.isEmpty,
              isValidTime(
                hour: startHour,
                minute: startMinute
              ),
              isValidTime(
                hour: endHour,
                minute: endMinute
              )
        else {
            return nil
        }

        let startTotalMinutes =
            startHour * 60 + startMinute

        let endTotalMinutes =
            endHour * 60 + endMinute

        guard endTotalMinutes > startTotalMinutes else {
            return nil
        }

        guard let weekday = weekday(for: date) else {
            return nil
        }

        let isActiveDay =
            weekdays.contains(weekday)

        guard isActiveDay else {
            return nextActiveDayStart(
                after: date,
                weekdays: weekdays,
                startHour: startHour,
                startMinute: startMinute
            )
        }

        guard let activeWindowStart =
            dateOnSameDay(
                as: date,
                hour: startHour,
                minute: startMinute
            ),
              let activeWindowEnd =
            dateOnSameDay(
                as: date,
                hour: endHour,
                minute: endMinute
            )
        else {
            return nil
        }

        if date < activeWindowStart {
            return activeWindowStart
        }

        if date >= activeWindowEnd {
            return nextActiveDayStart(
                after: date,
                weekdays: weekdays,
                startHour: startHour,
                startMinute: startMinute
            )
        }

        let interval =
            TimeInterval(intervalMinutes * 60)

        guard let lastHandled else {
            let candidate =
                date.addingTimeInterval(interval)

            if candidate < activeWindowEnd {
                return candidate
            }

            return nextActiveDayStart(
                after: date,
                weekdays: weekdays,
                startHour: startHour,
                startMinute: startMinute
            )
        }

        let handledOnCurrentDay =
            calendar.isDate(
                lastHandled,
                inSameDayAs: date
            )

        guard handledOnCurrentDay,
              lastHandled >= activeWindowStart,
              lastHandled < activeWindowEnd
        else {
            return date
        }

        let candidate =
            lastHandled.addingTimeInterval(interval)

        if candidate <= date {
            return date
        }

        if candidate < activeWindowEnd {
            return candidate
        }

        return nextActiveDayStart(
            after: date,
            weekdays: weekdays,
            startHour: startHour,
            startMinute: startMinute
        )
    }

    func nextFixedTimeReminderDate(
        after date: Date,
        times: [ReminderTime],
        weekdays: Set<Weekday>
    ) -> Date? {
        guard !times.isEmpty,
              !weekdays.isEmpty
        else {
            return nil
        }

        let sortedTimes =
            Array(Set(times)).sorted()

        /*
         Seven days are sufficient to inspect every weekday.
         We include day zero so today's remaining times are checked.
         */
        for dayOffset in 0...7 {
            guard let candidateDay =
                calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: date
                ),
                  let weekday =
                weekday(for: candidateDay),
                  weekdays.contains(weekday)
            else {
                continue
            }

            for time in sortedTimes {
                guard let candidateDate =
                    dateOnSameDay(
                        as: candidateDay,
                        hour: time.hour,
                        minute: time.minute
                    )
                else {
                    continue
                }

                if candidateDate >= date {
                    return candidateDate
                }
            }
        }

        return nil
    }

    private func nextActiveDayStart(
        after date: Date,
        weekdays: Set<Weekday>,
        startHour: Int,
        startMinute: Int
    ) -> Date? {
        guard !weekdays.isEmpty else {
            return nil
        }

        for dayOffset in 1...7 {
            guard let candidateDay =
                calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: date
                ),
                  let candidateWeekday =
                weekday(for: candidateDay),
                  weekdays.contains(candidateWeekday)
            else {
                continue
            }

            return dateOnSameDay(
                as: candidateDay,
                hour: startHour,
                minute: startMinute
            )
        }

        return nil
    }

    private func weekday(
        for date: Date
    ) -> Weekday? {
        let rawValue =
            calendar.component(
                .weekday,
                from: date
            )

        return Weekday(
            rawValue: rawValue
        )
    }

    private func dateOnSameDay(
        as date: Date,
        hour: Int,
        minute: Int
    ) -> Date? {
        guard isValidTime(
            hour: hour,
            minute: minute
        ) else {
            return nil
        }

        var components =
            calendar.dateComponents(
                [
                    .era,
                    .year,
                    .month,
                    .day
                ],
                from: date
            )

        components.hour = hour
        components.minute = minute
        components.second = 0
        components.nanosecond = 0

        return calendar.date(
            from: components
        )
    }

    private func isValidTime(
        hour: Int,
        minute: Int
    ) -> Bool {
        (0...23).contains(hour)
            && (0...59).contains(minute)
    }
}
