import Foundation

struct ReminderDefinition:
    Codable,
    Identifiable,
    Equatable {

    var id: UUID

    var title: String
    var message: String

    var category: ReminderCategory
    var isEnabled: Bool

    var weekdays: Set<Weekday>
    var schedule: ReminderSchedule
    var actions: ReminderActionConfiguration

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        category: ReminderCategory,
        isEnabled: Bool = true,
        weekdays: Set<Weekday>,
        schedule: ReminderSchedule,
        actions: ReminderActionConfiguration
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.category = category
        self.isEnabled = isEnabled
        self.weekdays = weekdays
        self.schedule = schedule
        self.actions = actions
    }

    var numberOfTimesPerDay: Int {
        switch schedule {
        case .interval:
            return 0

        case .fixedTimes(let fixedSchedule):
            return fixedSchedule.times.count
        }
    }
}
