import Foundation
import Testing

@testable import Buddy

@Suite("Reminder Queue")
@MainActor
struct ReminderQueueTests {
    @Test(
        "Earlier scheduled reminder is presented first"
    )
    func earlierReminderFirst() throws {
        let queue = ReminderQueue()

        let laterDate = Date(
            timeIntervalSince1970: 2_000
        )

        let earlierDate = Date(
            timeIntervalSince1970: 1_000
        )

        queue.enqueue(
            definition:
                ReminderTemplate.hydration.definition,
            scheduledDate: laterDate
        )

        queue.enqueue(
            definition:
                ReminderTemplate.stretch.definition,
            scheduledDate: earlierDate
        )

        let next =
            queue.presentNextIfAvailable()

        #expect(
            next?.definition.category
                == .stretch
        )
    }

    @Test(
        "Supplement wins when scheduled time matches"
    )
    func supplementPriority() throws {
        let queue = ReminderQueue()

        let scheduledDate = Date(
            timeIntervalSince1970: 1_000
        )

        queue.enqueue(
            definition:
                ReminderTemplate.hydration.definition,
            scheduledDate: scheduledDate
        )

        queue.enqueue(
            definition:
                ReminderTemplate.supplement.definition,
            scheduledDate: scheduledDate
        )

        let next =
            queue.presentNextIfAvailable()

        #expect(
            next?.definition.category
                == .supplement
        )
    }

    @Test(
        "Custom fixed-time reminder wins over hydration"
    )
    func customFixedTimePriority() throws {
        let queue = ReminderQueue()

        let scheduledDate = Date(
            timeIntervalSince1970: 1_000
        )

        let custom =
            ReminderTemplate.custom.definition

        queue.enqueue(
            definition:
                ReminderTemplate.hydration.definition,
            scheduledDate: scheduledDate
        )

        queue.enqueue(
            definition: custom,
            scheduledDate: scheduledDate
        )

        let next =
            queue.presentNextIfAvailable()

        #expect(
            next?.definition.category
                == .custom
        )
    }

    @Test(
        "Current reminder remains active until resolved"
    )
    func currentReminderRemainsActive()
        throws {
        let queue = ReminderQueue()

        queue.enqueue(
            definition:
                ReminderTemplate.hydration.definition,
            scheduledDate: Date(
                timeIntervalSince1970: 1_000
            )
        )

        queue.enqueue(
            definition:
                ReminderTemplate.supplement.definition,
            scheduledDate: Date(
                timeIntervalSince1970: 2_000
            )
        )

        let first =
            queue.presentNextIfAvailable()

        let repeatedCall =
            queue.presentNextIfAvailable()

        #expect(first?.id == repeatedCall?.id)
        #expect(queue.pendingCount == 1)
    }

    @Test(
        "Resolving current reminder presents next item"
    )
    func resolvePresentsNext() throws {
        let queue = ReminderQueue()

        queue.enqueue(
            definition:
                ReminderTemplate.hydration.definition,
            scheduledDate: Date(
                timeIntervalSince1970: 1_000
            )
        )

        queue.enqueue(
            definition:
                ReminderTemplate.supplement.definition,
            scheduledDate: Date(
                timeIntervalSince1970: 2_000
            )
        )

        let first =
            queue.presentNextIfAvailable()

        let second =
            queue.resolveCurrentAndPresentNext()

        #expect(
            first?.definition.category
                == .hydration
        )

        #expect(
            second?.definition.category
                == .supplement
        )

        #expect(queue.pendingCount == 0)
    }

    @Test(
        "Duplicate occurrence is ignored"
    )
    func duplicateOccurrenceIgnored()
        throws {
        let queue = ReminderQueue()

        let definition =
            ReminderTemplate.hydration.definition

        let scheduledDate = Date(
            timeIntervalSince1970: 1_000
        )

        let firstResult = queue.enqueue(
            definition: definition,
            scheduledDate: scheduledDate
        )

        let secondResult = queue.enqueue(
            definition: definition,
            scheduledDate: scheduledDate
        )

        #expect(firstResult)
        #expect(!secondResult)
        #expect(queue.pendingCount == 1)
    }

    @Test(
        "Different occurrences of the same definition are allowed"
    )
    func separateOccurrencesAllowed()
        throws {
        let queue = ReminderQueue()

        let definition =
            ReminderTemplate.supplement.definition

        queue.enqueue(
            definition: definition,
            scheduledDate: Date(
                timeIntervalSince1970: 1_000
            )
        )

        queue.enqueue(
            definition: definition,
            scheduledDate: Date(
                timeIntervalSince1970: 2_000
            )
        )

        #expect(queue.pendingCount == 2)
    }

    @Test(
        "Insertion order is stable when time and priority match"
    )
    func stableInsertionOrder() throws {
        let queue = ReminderQueue()

        let scheduledDate = Date(
            timeIntervalSince1970: 1_000
        )

        var first =
            ReminderTemplate.stretch.definition

        first.title = "First Stretch"

        var second =
            ReminderTemplate.eyeBreak.definition

        second.title = "Second Eye Break"

        queue.enqueue(
            definition: first,
            scheduledDate: scheduledDate
        )

        queue.enqueue(
            definition: second,
            scheduledDate: scheduledDate
        )

        let next =
            queue.presentNextIfAvailable()

        #expect(
            next?.definition.title
                == "First Stretch"
        )
    }

    @Test(
        "Removing a definition clears all of its occurrences"
    )
    func removeDefinitionOccurrences()
        throws {
        let queue = ReminderQueue()

        let supplement =
            ReminderTemplate.supplement.definition

        queue.enqueue(
            definition: supplement,
            scheduledDate: Date(
                timeIntervalSince1970: 1_000
            )
        )

        queue.enqueue(
            definition: supplement,
            scheduledDate: Date(
                timeIntervalSince1970: 2_000
            )
        )

        queue.removeOccurrences(
            for: supplement.id
        )

        #expect(queue.totalCount == 0)
    }
}
