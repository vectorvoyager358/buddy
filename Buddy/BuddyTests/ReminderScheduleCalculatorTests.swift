import Foundation
import Testing

@testable import Buddy

@Suite("Reminder Schedule Calculator")
struct ReminderScheduleCalculatorTests {
    private let calendar: Calendar
    private let calculator: ReminderScheduleCalculator

    init() {
        var calendar = Calendar(
            identifier: .gregorian
        )

        calendar.timeZone =
            TimeZone(
                identifier: "America/Chicago"
            )!

        self.calendar = calendar

        calculator =
            ReminderScheduleCalculator(
                calendar: calendar
            )
    }

    @Test(
        "Interval reminder before active hours starts at opening time"
    )
    func intervalBeforeActiveHours() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 9,
            minute: 30
        )

        let result =
            calculator.nextIntervalReminderDate(
                after: now,
                intervalMinutes: 60,
                lastHandled: nil,
                weekdays: workWeek,
                startHour: 11,
                startMinute: 0,
                endHour: 16,
                endMinute: 0
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 11,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Interval reminder inside active hours uses the interval"
    )
    func intervalInsideActiveHours() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 12,
            minute: 0
        )

        let result =
            calculator.nextIntervalReminderDate(
                after: now,
                intervalMinutes: 60,
                lastHandled: nil,
                weekdays: workWeek,
                startHour: 11,
                startMinute: 0,
                endHour: 16,
                endMinute: 0
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 13,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Interval reminder after active hours moves to the next active day"
    )
    func intervalAfterActiveHours() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 17,
            minute: 0
        )

        let result =
            calculator.nextIntervalReminderDate(
                after: now,
                intervalMinutes: 60,
                lastHandled: nil,
                weekdays: workWeek,
                startHour: 11,
                startMinute: 0,
                endHour: 16,
                endMinute: 0
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 4,
            hour: 11,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Friday after hours moves to Monday"
    )
    func fridayMovesToMonday() throws {
        let friday = try date(
            year: 2026,
            month: 8,
            day: 7,
            hour: 17,
            minute: 0
        )

        let result =
            calculator.nextIntervalReminderDate(
                after: friday,
                intervalMinutes: 60,
                lastHandled: nil,
                weekdays: workWeek,
                startHour: 11,
                startMinute: 0,
                endHour: 16,
                endMinute: 0
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 10,
            hour: 11,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Overdue interval reminder returns immediately"
    )
    func overdueIntervalReturnsImmediately() throws {
        let lastHandled = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 11,
            minute: 0
        )

        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 13,
            minute: 0
        )

        let result =
            calculator.nextIntervalReminderDate(
                after: now,
                intervalMinutes: 60,
                lastHandled: lastHandled,
                weekdays: workWeek,
                startHour: 11,
                startMinute: 0,
                endHour: 16,
                endMinute: 0
            )

        #expect(result == now)
    }

    @Test(
        "Interval crossing the closing time moves to the next day"
    )
    func intervalCrossingClosingTime() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 15,
            minute: 30
        )

        let result =
            calculator.nextIntervalReminderDate(
                after: now,
                intervalMinutes: 60,
                lastHandled: nil,
                weekdays: workWeek,
                startHour: 11,
                startMinute: 0,
                endHour: 16,
                endMinute: 0
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 4,
            hour: 11,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Fixed-time schedule chooses the next time today"
    )
    func fixedTimeChoosesNextTimeToday() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 10,
            minute: 0
        )

        let result =
            calculator.nextFixedTimeReminderDate(
                after: now,
                times: [
                    ReminderTime(
                        hour: 9,
                        minute: 0
                    ),
                    ReminderTime(
                        hour: 14,
                        minute: 0
                    )
                ],
                weekdays: workWeek
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 14,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Fixed-time schedule uses the earliest configured time"
    )
    func fixedTimeUsesEarliestTime() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 8,
            minute: 0
        )

        let result =
            calculator.nextFixedTimeReminderDate(
                after: now,
                times: [
                    ReminderTime(
                        hour: 14,
                        minute: 0
                    ),
                    ReminderTime(
                        hour: 9,
                        minute: 0
                    )
                ],
                weekdays: workWeek
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 9,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Fixed-time schedule moves to tomorrow after the final time"
    )
    func fixedTimeMovesToTomorrow() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 15,
            minute: 0
        )

        let result =
            calculator.nextFixedTimeReminderDate(
                after: now,
                times: [
                    ReminderTime(
                        hour: 9,
                        minute: 0
                    ),
                    ReminderTime(
                        hour: 14,
                        minute: 0
                    )
                ],
                weekdays: workWeek
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 4,
            hour: 9,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Fixed-time schedule skips inactive weekends"
    )
    func fixedTimeSkipsWeekend() throws {
        let friday = try date(
            year: 2026,
            month: 8,
            day: 7,
            hour: 15,
            minute: 0
        )

        let result =
            calculator.nextFixedTimeReminderDate(
                after: friday,
                times: [
                    ReminderTime(
                        hour: 9,
                        minute: 0
                    )
                ],
                weekdays: workWeek
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 10,
            hour: 9,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Generic calculator supports an interval definition"
    )
    func genericIntervalDefinition() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 12,
            minute: 0
        )

        let reminder =
            ReminderTemplate.hydration.definition

        let result =
            calculator.nextReminderDate(
                after: now,
                for: reminder
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 13,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Generic calculator supports a fixed-time definition"
    )
    func genericFixedTimeDefinition() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 8,
            minute: 0
        )

        var reminder =
            ReminderTemplate.supplement.definition

        reminder.schedule = .fixedTimes(
            FixedTimeReminderSchedule(
                times: [
                    ReminderTime(
                        hour: 9,
                        minute: 0
                    ),
                    ReminderTime(
                        hour: 14,
                        minute: 0
                    )
                ]
            )
        )

        let result =
            calculator.nextReminderDate(
                after: now,
                for: reminder
            )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 9,
            minute: 0
        )

        #expect(result == expected)
    }

    @Test(
        "Disabled reminder has no next date"
    )
    func disabledReminderHasNoDate() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 8,
            minute: 0
        )

        var reminder =
            ReminderTemplate.supplement.definition

        reminder.isEnabled = false

        let result =
            calculator.nextReminderDate(
                after: now,
                for: reminder
            )

        #expect(result == nil)
    }

    @Test(
        "Reminder with no active weekdays has no next date"
    )
    func noActiveWeekdaysHasNoDate() throws {
        let now = try date(
            year: 2026,
            month: 8,
            day: 3,
            hour: 8,
            minute: 0
        )

        var reminder =
            ReminderTemplate.supplement.definition

        reminder.weekdays = []

        let result =
            calculator.nextReminderDate(
                after: now,
                for: reminder
            )

        #expect(result == nil)
    }

    private var workWeek: Set<Weekday> {
        [
            .monday,
            .tuesday,
            .wednesday,
            .thursday,
            .friday
        ]
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) throws -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )

        return try #require(
            calendar.date(
                from: components
            )
        )
    }
}
