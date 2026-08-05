import Foundation

struct Reminder: Identifiable, Equatable {
    let id: UUID

    /// Links the displayed reminder to its saved generic definition.
    let definitionID: UUID?

    /// Identifies one scheduled occurrence in the reminder queue.
    let occurrenceKey: String?

    let title: String
    let message: String
    let type: ReminderType
    let actions: ReminderActionConfiguration

    init(
        id: UUID = UUID(),
        definitionID: UUID? = nil,
        occurrenceKey: String? = nil,
        title: String,
        message: String,
        type: ReminderType,
        actions: ReminderActionConfiguration? = nil
    ) {
        self.id = id
        self.definitionID = definitionID
        self.occurrenceKey = occurrenceKey
        self.title = title
        self.message = message
        self.type = type
        self.actions = actions ?? type.defaultActions
    }

    init(
        queuedReminder: QueuedReminder
    ) {
        let definition =
            queuedReminder.definition

        self.init(
            definitionID: definition.id,
            occurrenceKey: queuedReminder.occurrenceKey,
            title: definition.title,
            message: definition.message,
            type: ReminderType(
                category: definition.category
            ),
            actions: definition.actions
        )
    }
}

enum ReminderType:
    String,
    Codable,
    Equatable {

    case water
    case stretch
    case supplement
    case eyeBreak
    case walk
    case custom

    init(
        category: ReminderCategory
    ) {
        switch category {
        case .hydration:
            self = .water

        case .supplement:
            self = .supplement

        case .stretch:
            self = .stretch

        case .eyeBreak:
            self = .eyeBreak

        case .walk:
            self = .walk

        case .custom:
            self = .custom
        }
    }

    var category: ReminderCategory {
        switch self {
        case .water:
            return .hydration

        case .supplement:
            return .supplement

        case .stretch:
            return .stretch

        case .eyeBreak:
            return .eyeBreak

        case .walk:
            return .walk

        case .custom:
            return .custom
        }
    }

    /// Emoji used by macOS notification content.
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

        case .custom:
            return "🔔"
        }
    }

    /// SF Symbol used by Buddy's SwiftUI reminder card.
    var systemImage: String {
        category.systemImage
    }

    var headerTitle: String {
        switch self {
        case .water:
            return "Time to hydrate"

        case .supplement:
            return "Supplement reminder"

        case .stretch:
            return "Time to stretch"

        case .eyeBreak:
            return "Rest your eyes"

        case .walk:
            return "Take a walking break"

        case .custom:
            return "Reminder"
        }
    }

    var subtitle: String {
        switch self {
        case .water:
            return "A quick wellness break"

        case .supplement:
            return "Scheduled supplement"

        case .stretch:
            return "Release some tension"

        case .eyeBreak:
            return "Step away from the screen"

        case .walk:
            return "Move for a few minutes"

        case .custom:
            return "Your scheduled reminder"
        }
    }

    var defaultActions:
        ReminderActionConfiguration {
        switch self {
        case .water:
            return .hydration

        case .supplement:
            return .supplement

        case .stretch,
             .eyeBreak,
             .walk,
             .custom:
            return .standardWellness
        }
    }
}
