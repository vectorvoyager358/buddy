import Foundation

struct HydrationSettings: Codable, Equatable {
    var isEnabled: Bool
    var intervalMinutes: Int

    var startHour: Int
    var startMinute: Int

    var endHour: Int
    var endMinute: Int

    var weekdays: Set<Weekday>

    /// The most recent time the user selected Done.
    var lastCompleted: Date?

    /// The most recent time the reminder was resolved through Done or Skip.
    /// This prevents the interval from resetting after Buddy restarts.
    var lastHandled: Date?

    static let `default` = HydrationSettings(
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
        ],
        lastCompleted: nil,
        lastHandled: nil
    )
}
