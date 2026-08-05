import Foundation

struct ReminderTime:
    Codable,
    Equatable,
    Hashable,
    Identifiable,
    Comparable {

    var id: String {
        String(
            format: "%02d:%02d",
            hour,
            minute
        )
    }

    var hour: Int
    var minute: Int

    init(
        hour: Int,
        minute: Int
    ) {
        self.hour = min(
            max(hour, 0),
            23
        )

        self.minute = min(
            max(minute, 0),
            59
        )
    }

    static func < (
        lhs: ReminderTime,
        rhs: ReminderTime
    ) -> Bool {
        if lhs.hour == rhs.hour {
            return lhs.minute < rhs.minute
        }

        return lhs.hour < rhs.hour
    }

    var totalMinutes: Int {
        hour * 60 + minute
    }

    var formatted: String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let date = Calendar.current.date(
            from: components
        ) else {
            return String(
                format: "%02d:%02d",
                hour,
                minute
            )
        }

        return date.formatted(
            date: .omitted,
            time: .shortened
        )
    }
}
