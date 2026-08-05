import Foundation

enum ReminderPriority: Int, Codable, Comparable {
    case supplement = 500
    case customFixedTime = 400
    case hydration = 300
    case standardWellness = 200

    static func < (
        lhs: ReminderPriority,
        rhs: ReminderPriority
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func priority(
        for reminder: ReminderDefinition
    ) -> ReminderPriority {
        switch reminder.category {
        case .supplement:
            return .supplement

        case .custom:
            switch reminder.schedule {
            case .fixedTimes:
                return .customFixedTime

            case .interval:
                return .standardWellness
            }

        case .hydration:
            return .hydration

        case .stretch,
             .eyeBreak,
             .walk:
            return .standardWellness
        }
    }
}
