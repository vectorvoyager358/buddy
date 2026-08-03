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

        calendar.timeZone = TimeZone(
            identifier: "America/Chicago"
        )!

        calendar.locale = Locale(
            identifier: "en_US_POSIX"
        )

        self.calendar = calendar

        self.calculator = ReminderScheduleCalculator(
            calendar: calendar
        )
    }

    @Test("Before active hours schedules at the start time")
    func beforeActiveHoursSchedulesAtStart() throws {
        let now = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 10,
            minute: 30
        )

        let expected = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 11,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: now,
            intervalMinutes: 60,
            lastHandled: nil,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == expected)
    }

    @Test("Inside active hours adds the configured interval")
    func insideActiveHoursAddsInterval() throws {
        let now = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 12,
            minute: 0
        )

        let expected = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 13,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: now,
            intervalMinutes: 60,
            lastHandled: nil,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == expected)
    }

    @Test("After active hours advances to the next weekday")
    func afterActiveHoursAdvancesToNextDay() throws {
        let now = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 17,
            minute: 30
        )

        let expected = try makeDate(
            year: 2026,
            month: 8,
            day: 4,
            hour: 11,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: now,
            intervalMinutes: 60,
            lastHandled: nil,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == expected)
    }

    @Test("Friday after hours advances to Monday")
    func fridayAfterHoursAdvancesToMonday() throws {
        let friday = try makeDate(
            year: 2026,
            month: 8,
            day: 7,
            hour: 17,
            minute: 30
        )

        let monday = try makeDate(
            year: 2026,
            month: 8,
            day: 10,
            hour: 11,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: friday,
            intervalMinutes: 60,
            lastHandled: nil,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == monday)
    }

    @Test("Empty weekdays returns nil")
    func emptyWeekdaysReturnsNil() throws {
        let now = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 12,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: now,
            intervalMinutes: 60,
            lastHandled: nil,
            weekdays: [],
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == nil)
    }

    @Test("Invalid active-hour range returns nil")
    func invalidActiveHoursReturnsNil() throws {
        let now = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 12,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: now,
            intervalMinutes: 60,
            lastHandled: nil,
            weekdays: workWeek,
            startHour: 16,
            startMinute: 0,
            endHour: 11,
            endMinute: 0
        )

        #expect(result == nil)
    }

    @Test("Zero interval returns nil")
    func zeroIntervalReturnsNil() throws {
        let now = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 12,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: now,
            intervalMinutes: 0,
            lastHandled: nil,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == nil)
    }

    @Test("Last handled time preserves the interval")
    func lastHandledPreservesInterval() throws {
        let lastHandled = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 14,
            minute: 15
        )

        let appRestartedAt = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 14,
            minute: 45
        )

        let expected = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 15,
            minute: 15
        )

        let result = calculator.nextIntervalReminderDate(
            after: appRestartedAt,
            intervalMinutes: 60,
            lastHandled: lastHandled,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == expected)
    }

    @Test("Overdue reminder is scheduled immediately")
    func overdueReminderSchedulesImmediately() throws {
        let lastHandled = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 12,
            minute: 0
        )

        let appRestartedAt = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 14,
            minute: 30
        )

        let result = calculator.nextIntervalReminderDate(
            after: appRestartedAt,
            intervalMinutes: 60,
            lastHandled: lastHandled,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == appRestartedAt)
    }

    @Test("Candidate after end time moves to next active day")
    func intervalCrossingEndMovesToNextDay() throws {
        let now = try makeDate(
            year: 2026,
            month: 8,
            day: 3,
            hour: 15,
            minute: 30
        )

        let expected = try makeDate(
            year: 2026,
            month: 8,
            day: 4,
            hour: 11,
            minute: 0
        )

        let result = calculator.nextIntervalReminderDate(
            after: now,
            intervalMinutes: 60,
            lastHandled: nil,
            weekdays: workWeek,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0
        )

        #expect(result == expected)
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

    private func makeDate(
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
            minute: minute,
            second: 0
        )

        return try #require(
            calendar.date(
                from: components
            )
        )
    }
}
