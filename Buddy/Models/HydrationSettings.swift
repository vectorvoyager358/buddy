import Foundation

struct HydrationSettings: Codable, Equatable {
    var isEnabled: Bool
    var intervalMinutes: Int

    var startHour: Int
    var startMinute: Int

    var endHour: Int
    var endMinute: Int

    var weekdays: Set<Weekday>

    var lastCompleted: Date?
    var lastHandled: Date?

    init(
        isEnabled: Bool,
        intervalMinutes: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        weekdays: Set<Weekday>,
        lastCompleted: Date? = nil,
        lastHandled: Date? = nil
    ) {
        self.isEnabled = isEnabled

        self.intervalMinutes = max(
            intervalMinutes,
            1
        )

        self.startHour = min(
            max(startHour, 0),
            23
        )

        self.startMinute = min(
            max(startMinute, 0),
            59
        )

        self.endHour = min(
            max(endHour, 0),
            23
        )

        self.endMinute = min(
            max(endMinute, 0),
            59
        )

        self.weekdays = weekdays
        self.lastCompleted = lastCompleted
        self.lastHandled = lastHandled
    }

    static var `default`: HydrationSettings {
        HydrationSettings(
            isEnabled: true,
            intervalMinutes: 60,
            startHour: 11,
            startMinute: 0,
            endHour: 16,
            endMinute: 0,
            weekdays: [
                .monday,
                .tuesday,
                .wednesday,
                .thursday,
                .friday
            ]
        )
    }
}
