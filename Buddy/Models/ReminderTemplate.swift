import Foundation

enum ReminderTemplate:
    String,
    CaseIterable,
    Identifiable {

    case hydration
    case supplement
    case stretch
    case eyeBreak
    case walk
    case custom

    var id: String {
        rawValue
    }

    var displayName: String {
        definition.title
    }

    var category: ReminderCategory {
        definition.category
    }

    var systemImage: String {
        category.systemImage
    }

    var definition: ReminderDefinition {
        switch self {
        case .hydration:
            return ReminderDefinition(
                title: "Drink Water",
                message: "Take a moment to drink some water.",
                category: .hydration,
                weekdays: Self.workWeek,
                schedule: .interval(
                    IntervalReminderSchedule(
                        intervalMinutes: 60,
                        startTime: ReminderTime(
                            hour: 11,
                            minute: 0
                        ),
                        endTime: ReminderTime(
                            hour: 16,
                            minute: 0
                        )
                    )
                ),
                actions: .hydration
            )

        case .supplement:
            return ReminderDefinition(
                title: "Take Supplement",
                message: "It is time to take your supplement.",
                category: .supplement,
                weekdays: Self.workWeek,
                schedule: .fixedTimes(
                    FixedTimeReminderSchedule(
                        times: [
                            ReminderTime(
                                hour: 9,
                                minute: 0
                            )
                        ]
                    )
                ),
                actions: .supplement
            )

        case .stretch:
            return ReminderDefinition(
                title: "Stretch",
                message: "Take a short break and stretch.",
                category: .stretch,
                weekdays: Self.workWeek,
                schedule: .interval(
                    IntervalReminderSchedule(
                        intervalMinutes: 60,
                        startTime: ReminderTime(
                            hour: 9,
                            minute: 0
                        ),
                        endTime: ReminderTime(
                            hour: 17,
                            minute: 0
                        )
                    )
                ),
                actions: .standardWellness
            )

        case .eyeBreak:
            return ReminderDefinition(
                title: "Rest Your Eyes",
                message: "Look away from the screen for a moment.",
                category: .eyeBreak,
                weekdays: Self.workWeek,
                schedule: .interval(
                    IntervalReminderSchedule(
                        intervalMinutes: 20,
                        startTime: ReminderTime(
                            hour: 9,
                            minute: 0
                        ),
                        endTime: ReminderTime(
                            hour: 17,
                            minute: 0
                        )
                    )
                ),
                actions: .standardWellness
            )

        case .walk:
            return ReminderDefinition(
                title: "Take a Walk",
                message: "Take a short walking break.",
                category: .walk,
                weekdays: Self.workWeek,
                schedule: .fixedTimes(
                    FixedTimeReminderSchedule(
                        times: [
                            ReminderTime(
                                hour: 12,
                                minute: 30
                            ),
                            ReminderTime(
                                hour: 15,
                                minute: 30
                            )
                        ]
                    )
                ),
                actions: .standardWellness
            )

        case .custom:
            return ReminderDefinition(
                title: "New Reminder",
                message: "It is time for your reminder.",
                category: .custom,
                weekdays: Self.workWeek,
                schedule: .fixedTimes(
                    FixedTimeReminderSchedule(
                        times: [
                            ReminderTime(
                                hour: 9,
                                minute: 0
                            )
                        ]
                    )
                ),
                actions: .standardWellness
            )
        }
    }

    private static let workWeek: Set<Weekday> = [
        .monday,
        .tuesday,
        .wednesday,
        .thursday,
        .friday
    ]
}
