import Foundation

struct Reminder: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let type: ReminderType

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        type: ReminderType
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
    }
}

enum ReminderType: String, Equatable {
    case water
    case stretch
    case supplement
    case eyeBreak
    case walk

    var icon: String {
        switch self {
        case .water:
            return "💧"

        case .stretch:
            return "🧘"

        case .supplement:
            return "💊"

        case .eyeBreak:
            return "👀"

        case .walk:
            return "🚶"
        }
    }
}
