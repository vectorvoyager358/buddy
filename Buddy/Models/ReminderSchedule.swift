import Foundation

enum ReminderSchedule: Codable, Equatable {
    case interval(IntervalReminderSchedule)
    case fixedTimes(FixedTimeReminderSchedule)

    private enum CodingKeys: String, CodingKey {
        case type
        case interval
        case fixedTimes
    }

    private enum ScheduleType: String, Codable {
        case interval
        case fixedTimes
    }

    init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let type = try container.decode(
            ScheduleType.self,
            forKey: .type
        )

        switch type {
        case .interval:
            let schedule = try container.decode(
                IntervalReminderSchedule.self,
                forKey: .interval
            )

            self = .interval(schedule)

        case .fixedTimes:
            let schedule = try container.decode(
                FixedTimeReminderSchedule.self,
                forKey: .fixedTimes
            )

            self = .fixedTimes(schedule)
        }
    }

    func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        switch self {
        case .interval(let schedule):
            try container.encode(
                ScheduleType.interval,
                forKey: .type
            )

            try container.encode(
                schedule,
                forKey: .interval
            )

        case .fixedTimes(let schedule):
            try container.encode(
                ScheduleType.fixedTimes,
                forKey: .type
            )

            try container.encode(
                schedule,
                forKey: .fixedTimes
            )
        }
    }
}

struct IntervalReminderSchedule: Codable, Equatable {
    var intervalMinutes: Int
    var startTime: ReminderTime
    var endTime: ReminderTime

    init(
        intervalMinutes: Int,
        startTime: ReminderTime,
        endTime: ReminderTime
    ) {
        self.intervalMinutes = max(
            intervalMinutes,
            1
        )

        self.startTime = startTime
        self.endTime = endTime
    }
}

struct FixedTimeReminderSchedule: Codable, Equatable {
    var times: [ReminderTime]

    init(
        times: [ReminderTime]
    ) {
        self.times = Array(
            Set(times)
        )
        .sorted()
    }
}
