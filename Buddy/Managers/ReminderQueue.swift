import Foundation

@MainActor
final class ReminderQueue {
    private(set) var currentReminder:
        QueuedReminder?

    private(set) var pendingReminders:
        [QueuedReminder] = []

    private var insertionCounter:
        UInt64 = 0

    var hasCurrentReminder: Bool {
        currentReminder != nil
    }

    var pendingCount: Int {
        pendingReminders.count
    }

    var totalCount: Int {
        pendingReminders.count
            + (currentReminder == nil ? 0 : 1)
    }

    /// Adds a reminder occurrence to the queue.
    ///
    /// Returns `true` when the occurrence was inserted and `false`
    /// when the same occurrence was already current or pending.
    @discardableResult
    func enqueue(
        definition: ReminderDefinition,
        scheduledDate: Date
    ) -> Bool {
        let candidate = QueuedReminder(
            definition: definition,
            scheduledDate: scheduledDate,
            insertionOrder: nextInsertionOrder()
        )

        guard !containsOccurrence(
            candidate.occurrenceKey
        ) else {
            BuddyLogger.debug(
                "Ignored duplicate queued reminder occurrence for \(definition.title).",
                category: .reminders
            )

            return false
        }

        pendingReminders.append(candidate)
        sortPendingReminders()

        BuddyLogger.info(
            "Queued reminder '\(definition.title)' for \(scheduledDate).",
            category: .reminders
        )

        return true
    }

    /// Promotes the next pending item when no reminder is currently
    /// being displayed.
    ///
    /// Returns the current item. Calling it repeatedly without
    /// resolving the current item returns the same reminder.
    @discardableResult
    func presentNextIfAvailable()
        -> QueuedReminder? {
        if let currentReminder {
            return currentReminder
        }

        guard !pendingReminders.isEmpty else {
            return nil
        }

        let nextReminder =
            pendingReminders.removeFirst()

        currentReminder = nextReminder

        BuddyLogger.notice(
            "Presenting queued reminder '\(nextReminder.definition.title)'.",
            category: .reminders
        )

        return nextReminder
    }

    /// Resolves the reminder currently being displayed and returns
    /// the next queued reminder, when one exists.
    @discardableResult
    func resolveCurrentAndPresentNext()
        -> QueuedReminder? {
        if let currentReminder {
            BuddyLogger.debug(
                "Resolved queued reminder '\(currentReminder.definition.title)'.",
                category: .reminders
            )
        }

        currentReminder = nil

        return presentNextIfAvailable()
    }

    /// Removes the current reminder without presenting another item.
    ///
    /// Useful while pausing or shutting down Buddy.
    func clearCurrent() {
        currentReminder = nil
    }

    /// Removes all occurrences belonging to one reminder definition.
    func removeOccurrences(
        for definitionID: UUID
    ) {
        if currentReminder?.definition.id
            == definitionID {
            currentReminder = nil
        }

        pendingReminders.removeAll {
            $0.definition.id == definitionID
        }

        BuddyLogger.debug(
            "Removed queued occurrences for reminder definition \(definitionID.uuidString).",
            category: .reminders
        )
    }

    func removeOccurrence(
        occurrenceKey: String
    ) {
        if currentReminder?.occurrenceKey
            == occurrenceKey {
            currentReminder = nil
        }

        pendingReminders.removeAll {
            $0.occurrenceKey
                == occurrenceKey
        }
    }

    func removeAll() {
        currentReminder = nil
        pendingReminders.removeAll()

        BuddyLogger.info(
            "Cleared the reminder queue.",
            category: .reminders
        )
    }

    func containsOccurrence(
        _ occurrenceKey: String
    ) -> Bool {
        if currentReminder?.occurrenceKey
            == occurrenceKey {
            return true
        }

        return pendingReminders.contains {
            $0.occurrenceKey == occurrenceKey
        }
    }

    private func sortPendingReminders() {
        pendingReminders.sort {
            lhs,
            rhs in

            if lhs.scheduledDate
                != rhs.scheduledDate {
                return lhs.scheduledDate
                    < rhs.scheduledDate
            }

            if lhs.priority
                != rhs.priority {
                return lhs.priority
                    > rhs.priority
            }

            return lhs.insertionOrder
                < rhs.insertionOrder
        }
    }

    private func nextInsertionOrder()
        -> UInt64 {
        defer {
            insertionCounter &+= 1
        }

        return insertionCounter
    }
}
