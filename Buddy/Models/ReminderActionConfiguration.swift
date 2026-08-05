import Foundation

struct ReminderActionConfiguration: Codable, Equatable {
    var allowsDone: Bool
    var remindLaterMinutes: Int?
    var allowsSkip: Bool

    init(
        allowsDone: Bool = true,
        remindLaterMinutes: Int? = nil,
        allowsSkip: Bool = false
    ) {
        self.allowsDone = allowsDone
        self.remindLaterMinutes = remindLaterMinutes
        self.allowsSkip = allowsSkip
    }

    static let hydration = ReminderActionConfiguration(
        allowsDone: true,
        remindLaterMinutes: 10,
        allowsSkip: true
    )

    static let supplement = ReminderActionConfiguration(
        allowsDone: true,
        remindLaterMinutes: 10,
        allowsSkip: false
    )

    static let standardWellness = ReminderActionConfiguration(
        allowsDone: true,
        remindLaterMinutes: 10,
        allowsSkip: true
    )
}
