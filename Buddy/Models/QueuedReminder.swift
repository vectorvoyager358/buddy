import Foundation

struct QueuedReminder:
    Identifiable,
    Equatable {

    let id: UUID

    let definition: ReminderDefinition

    /// The exact scheduled occurrence represented by this item.
    let scheduledDate: Date

    let priority: ReminderPriority

    /// Preserves stable ordering when time and priority match.
    let insertionOrder: UInt64

    init(
        id: UUID = UUID(),
        definition: ReminderDefinition,
        scheduledDate: Date,
        insertionOrder: UInt64
    ) {
        self.id = id
        self.definition = definition
        self.scheduledDate = scheduledDate

        self.priority =
            ReminderPriority.priority(
                for: definition
            )

        self.insertionOrder = insertionOrder
    }

    /// Identifies one specific occurrence of one reminder.
    ///
    /// This prevents the same scheduled dose or interval occurrence
    /// from being inserted into the queue more than once.
    var occurrenceKey: String {
        definition.id.uuidString
            + "-"
            + String(
                Int(
                    scheduledDate.timeIntervalSince1970
                )
            )
    }
}
