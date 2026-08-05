import Foundation

enum ReminderCategory: String, Codable, CaseIterable, Hashable {
    case hydration
    case supplement
    case stretch
    case eyeBreak
    case walk
    case custom

    var displayName: String {
        switch self {
        case .hydration:
            return "Hydration"

        case .supplement:
            return "Supplement"

        case .stretch:
            return "Stretch"

        case .eyeBreak:
            return "Eye Break"

        case .walk:
            return "Walk"

        case .custom:
            return "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .hydration:
            return "drop.fill"

        case .supplement:
            return "pill.fill"

        case .stretch:
            return "figure.flexibility"

        case .eyeBreak:
            return "eye.fill"

        case .walk:
            return "figure.walk"

        case .custom:
            return "bell.fill"
        }
    }
}
