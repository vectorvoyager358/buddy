import Foundation
import Testing

@testable import Buddy

@Suite("Generic Reminder Scheduler")
@MainActor
struct GenericReminderSchedulerTests {
    private let calendar: Calendar
    private let fixedNow: Date

    init() {
        var calendar =
            Calendar(
                identifier: .gregorian
            )

        calendar.timeZone =
            TimeZone(
                identifier:
                    "America/Chicago"
            )!

        self.calendar =
            calendar

        fixedNow =
            calendar.date(
                from:
                    DateComponents(
                        year: 2026,
                        month: 8,
                        day: 5,
                        hour: 8,
                        minute: 0
                    )
            )!
    }

    @Test(
        "Scheduler creates dates for multiple definitions"
    )
    func schedulesMultipleDefinitions() {
        let scheduler =
            makeScheduler()

        let hydration =
            ReminderTemplate
                .hydration
                .definition

        let supplement =
            ReminderTemplate
                .supplement
                .definition

        scheduler.start(
            definitions: [
                hydration,
                supplement
            ]
        )

        #expect(
            scheduler.nextScheduledDates[
                hydration.id
            ] != nil
        )

        #expect(
            scheduler.nextScheduledDates[
                supplement.id
            ] != nil
        )
    }

    @Test(
        "Disabled definitions are not scheduled"
    )
    func ignoresDisabledDefinitions() {
        let scheduler =
            makeScheduler()

        var supplement =
            ReminderTemplate
                .supplement
                .definition

        supplement.isEnabled =
            false

        scheduler.start(
            definitions: [
                supplement
            ]
        )

        #expect(
            scheduler.nextScheduledDates[
                supplement.id
            ] == nil
        )
    }

    @Test(
        "Definitions without weekdays are not scheduled normally"
    )
    func ignoresDefinitionsWithoutDays() {
        let scheduler =
            makeScheduler()

        var reminder =
            ReminderTemplate
                .stretch
                .definition

        reminder.weekdays = []

        scheduler.start(
            definitions: [
                reminder
            ]
        )

        #expect(
            scheduler.nextScheduledDates[
                reminder.id
            ] == nil
        )
    }

    @Test(
        "Earlier fixed-time occurrence is calculated correctly"
    )
    func calculatesFixedTimeOccurrence() {
        let scheduler =
            makeScheduler()

        var supplement =
            ReminderTemplate
                .supplement
                .definition

        supplement.schedule =
            .fixedTimes(
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

        scheduler.start(
            definitions: [
                supplement
            ]
        )

        let expected =
            calendar.date(
                from:
                    DateComponents(
                        year: 2026,
                        month: 8,
                        day: 5,
                        hour: 9,
                        minute: 0
                    )
            )

        #expect(
            scheduler.nextScheduledDates[
                supplement.id
            ] == expected
        )
    }

    @Test(
        "Interval occurrence is calculated correctly"
    )
    func calculatesIntervalOccurrence() {
        let scheduler =
            makeScheduler()

        var hydration =
            ReminderTemplate
                .hydration
                .definition

        hydration.schedule =
            .interval(
                IntervalReminderSchedule(
                    intervalMinutes: 60,
                    startTime:
                        ReminderTime(
                            hour: 7,
                            minute: 0
                        ),
                    endTime:
                        ReminderTime(
                            hour: 17,
                            minute: 0
                        )
                )
            )

        scheduler.start(
            definitions: [
                hydration
            ]
        )

        let expected =
            calendar.date(
                from:
                    DateComponents(
                        year: 2026,
                        month: 8,
                        day: 5,
                        hour: 9,
                        minute: 0
                    )
            )

        #expect(
            scheduler.nextScheduledDates[
                hydration.id
            ] == expected
        )
    }

    @Test(
        "Paused scheduler does not create dates"
    )
    func pausedSchedulerDoesNotSchedule() {
        let defaults =
            temporaryDefaults()

        let runtimeStore =
            ReminderRuntimeStore(
                defaults: defaults
            )

        runtimeStore.remindersPaused =
            true

        let developerStore =
            DeveloperSettingsStore(
                defaults: defaults
            )

        let scheduler =
            GenericReminderScheduler(
                scheduleCalculator:
                    ReminderScheduleCalculator(
                        calendar:
                            calendar
                    ),
                reminderQueue:
                    ReminderQueue(),
                runtimeStore:
                    runtimeStore,
                developerSettingsStore:
                    developerStore,
                nowProvider: {
                    fixedNow
                }
            )

        let hydration =
            ReminderTemplate
                .hydration
                .definition

        scheduler.start(
            definitions: [
                hydration
            ]
        )

        #expect(
            scheduler.nextScheduledDates
                .isEmpty
        )
    }

    @Test(
        "Reload removes schedules that no longer exist"
    )
    func reloadRemovesOldDefinitions() {
        let scheduler =
            makeScheduler()

        let hydration =
            ReminderTemplate
                .hydration
                .definition

        scheduler.start(
            definitions: [
                hydration
            ]
        )

        #expect(
            scheduler.nextScheduledDates[
                hydration.id
            ] != nil
        )

        scheduler.reload(
            definitions: []
        )

        #expect(
            scheduler.nextScheduledDates
                .isEmpty
        )
    }

    @Test(
        "Fast testing uses the configured test interval"
    )
    func fastTestingUsesConfiguredInterval() {
        let scheduler =
            makeScheduler(
                fastTestingEnabled: true,
                testIntervalSeconds: 10
            )

        let hydration =
            ReminderTemplate
                .hydration
                .definition

        scheduler.start(
            definitions: [
                hydration
            ]
        )

        let expected =
            fixedNow
                .addingTimeInterval(10)

        #expect(
            scheduler.nextScheduledDates[
                hydration.id
            ] == expected
        )
    }

    @Test(
        "Fast testing ignores empty weekdays"
    )
    func fastTestingIgnoresEmptyWeekdays() {
        let scheduler =
            makeScheduler(
                fastTestingEnabled: true,
                testIntervalSeconds: 10
            )

        var reminder =
            ReminderTemplate
                .supplement
                .definition

        reminder.weekdays = []

        scheduler.start(
            definitions: [
                reminder
            ]
        )

        #expect(
            scheduler.nextScheduledDates[
                reminder.id
            ] != nil
        )
    }

    @Test(
        "Fast testing still ignores disabled reminders"
    )
    func fastTestingIgnoresDisabledReminder() {
        let scheduler =
            makeScheduler(
                fastTestingEnabled: true,
                testIntervalSeconds: 10
            )

        var reminder =
            ReminderTemplate
                .supplement
                .definition

        reminder.isEnabled =
            false

        scheduler.start(
            definitions: [
                reminder
            ]
        )

        #expect(
            scheduler.nextScheduledDates[
                reminder.id
            ] == nil
        )
    }

    private func makeScheduler(
        fastTestingEnabled: Bool = false,
        testIntervalSeconds: Int = 10
    ) -> GenericReminderScheduler {
        let defaults =
            temporaryDefaults()

        let runtimeStore =
            ReminderRuntimeStore(
                defaults: defaults
            )

        let developerStore =
            DeveloperSettingsStore(
                defaults: defaults
            )

        developerStore.fastTestingEnabled =
            fastTestingEnabled

        developerStore.testIntervalSeconds =
            testIntervalSeconds

        return GenericReminderScheduler(
            scheduleCalculator:
                ReminderScheduleCalculator(
                    calendar:
                        calendar
                ),
            reminderQueue:
                ReminderQueue(),
            runtimeStore:
                runtimeStore,
            developerSettingsStore:
                developerStore,
            nowProvider: {
                fixedNow
            }
        )
    }

    private func temporaryDefaults()
        -> UserDefaults {
        let suiteName =
            "GenericReminderSchedulerTests."
            + UUID().uuidString

        let defaults =
            UserDefaults(
                suiteName: suiteName
            )!

        defaults.removePersistentDomain(
            forName: suiteName
        )

        return defaults
    }
}
