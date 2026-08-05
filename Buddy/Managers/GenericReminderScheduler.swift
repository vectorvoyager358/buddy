import Foundation

@MainActor
final class GenericReminderScheduler {
    typealias ReminderReadyHandler =
        (QueuedReminder) -> Void

    private let scheduleCalculator:
        ReminderScheduleCalculator

    private let reminderQueue:
        ReminderQueue

    private let runtimeStore:
        ReminderRuntimeStore

    private let developerSettingsStore:
        DeveloperSettingsStore

    private let nowProvider:
        () -> Date

    private var scheduledTasks:
        [UUID: Task<Void, Never>] = [:]

    private var postponedTasks:
        [UUID: Task<Void, Never>] = [:]

    private var activeDefinitions:
        [UUID: ReminderDefinition] = [:]

    private(set) var nextScheduledDates:
        [UUID: Date] = [:]

    var onReminderReady:
        ReminderReadyHandler?

    init(
        scheduleCalculator:
            ReminderScheduleCalculator,
        reminderQueue:
            ReminderQueue,
        runtimeStore:
            ReminderRuntimeStore,
        developerSettingsStore:
            DeveloperSettingsStore,
        nowProvider:
            @escaping () -> Date
    ) {
        self.scheduleCalculator =
            scheduleCalculator

        self.reminderQueue =
            reminderQueue

        self.runtimeStore =
            runtimeStore

        self.developerSettingsStore =
            developerSettingsStore

        self.nowProvider =
            nowProvider
    }

    convenience init(
        scheduleCalculator:
            ReminderScheduleCalculator,
        reminderQueue:
            ReminderQueue,
        runtimeStore:
            ReminderRuntimeStore,
        developerSettingsStore:
            DeveloperSettingsStore
    ) {
        self.init(
            scheduleCalculator:
                scheduleCalculator,
            reminderQueue:
                reminderQueue,
            runtimeStore:
                runtimeStore,
            developerSettingsStore:
                developerSettingsStore,
            nowProvider:
                Date.init
        )
    }

    convenience init(
        scheduleCalculator:
            ReminderScheduleCalculator,
        reminderQueue:
            ReminderQueue,
        runtimeStore:
            ReminderRuntimeStore
    ) {
        self.init(
            scheduleCalculator:
                scheduleCalculator,
            reminderQueue:
                reminderQueue,
            runtimeStore:
                runtimeStore,
            developerSettingsStore:
                DeveloperSettingsStore(),
            nowProvider:
                Date.init
        )
    }

    convenience init() {
        self.init(
            scheduleCalculator:
                ReminderScheduleCalculator(),
            reminderQueue:
                ReminderQueue(),
            runtimeStore:
                ReminderRuntimeStore(),
            developerSettingsStore:
                DeveloperSettingsStore(),
            nowProvider:
                Date.init
        )
    }

    var currentReminder:
        QueuedReminder? {
        reminderQueue.currentReminder
    }

    var pendingReminderCount: Int {
        reminderQueue.pendingCount
    }

    func start(
        definitions: [ReminderDefinition]
    ) {
        BuddyLogger.info(
            "Generic reminder scheduler is starting.",
            category: .scheduler
        )

        reload(
            definitions: definitions
        )
    }

    func reload(
        definitions: [ReminderDefinition]
    ) {
        BuddyLogger.debug(
            "Reloading generic reminder scheduler.",
            category: .scheduler
        )

        cancelScheduledTasks(
            publishUpdate: false
        )

        cancelPostponedTasks()
        reminderQueue.removeAll()

        guard !runtimeStore.remindersPaused else {
            activeDefinitions.removeAll()
            publishEarliestScheduledReminder()

            BuddyLogger.info(
                "Generic reminder scheduling is paused.",
                category: .scheduler
            )

            return
        }

        let enabledDefinitions =
            definitions.filter {
                guard $0.isEnabled else {
                    return false
                }

                if developerSettingsStore
                    .fastTestingEnabled {
                    return true
                }

                return !$0.weekdays.isEmpty
            }

        activeDefinitions =
            Dictionary(
                uniqueKeysWithValues:
                    enabledDefinitions.map {
                        ($0.id, $0)
                    }
            )

        let now =
            nowProvider()

        for definition in enabledDefinitions {
            scheduleNextOccurrence(
                for: definition,
                after: now,
                lastHandled: nil
            )
        }

        publishEarliestScheduledReminder()

        if developerSettingsStore
            .fastTestingEnabled {
            BuddyLogger.notice(
                "Fast reminder testing is enabled at \(developerSettingsStore.testIntervalSeconds) seconds.",
                category: .scheduler
            )
        }

        BuddyLogger.info(
            "Scheduled \(enabledDefinitions.count) generic reminder definitions.",
            category: .scheduler
        )
    }

    func stop() {
        BuddyLogger.info(
            "Generic reminder scheduler is stopping.",
            category: .scheduler
        )

        cancelScheduledTasks(
            publishUpdate: false
        )

        cancelPostponedTasks()
        reminderQueue.removeAll()
        activeDefinitions.removeAll()

        publishEarliestScheduledReminder()
    }

    func dismissCurrentReminder() {
        reminderQueue.clearCurrent()
    }

    @discardableResult
    func presentNextReminderIfAvailable()
        -> QueuedReminder? {
        guard let reminder =
            reminderQueue
                .presentNextIfAvailable()
        else {
            return nil
        }

        onReminderReady?(
            reminder
        )

        return reminder
    }

    func postponeCurrentReminder(
        for seconds: TimeInterval
    ) {
        guard let currentReminder =
            reminderQueue.currentReminder
        else {
            BuddyLogger.error(
                "Unable to postpone because no reminder is currently active.",
                category: .reminders
            )

            return
        }

        let safeDelay =
            max(seconds, 1)

        let definition =
            currentReminder.definition

        reminderQueue.clearCurrent()

        postponedTasks[
            definition.id
        ]?.cancel()

        BuddyLogger.info(
            "Postponed '\(definition.title)' for \(Int(safeDelay)) seconds.",
            category: .reminders
        )

        let task = Task {
            [weak self] in

            do {
                try await Task.sleep(
                    for: .seconds(
                        safeDelay
                    )
                )
            } catch {
                return
            }

            guard !Task.isCancelled,
                  let self,
                  !runtimeStore.remindersPaused
            else {
                return
            }

            postponedTasks[
                definition.id
            ] = nil

            guard activeDefinitions[
                definition.id
            ] != nil else {
                BuddyLogger.debug(
                    "Ignored postponed reminder because its definition is no longer active: \(definition.title).",
                    category: .reminders
                )

                return
            }

            let wasAlreadyPresenting =
                reminderQueue
                    .hasCurrentReminder

            let inserted =
                reminderQueue.enqueue(
                    definition: definition,
                    scheduledDate:
                        nowProvider()
                )

            guard inserted else {
                return
            }

            BuddyLogger.notice(
                "Postponed reminder became due again: '\(definition.title)'.",
                category: .reminders
            )

            if !wasAlreadyPresenting {
                presentNextReminderIfAvailable()
            }
        }

        postponedTasks[
            definition.id
        ] = task
    }

    func removeReminder(
        definitionID: UUID
    ) {
        cancelScheduledTask(
            definitionID: definitionID,
            publishUpdate: false
        )

        postponedTasks[
            definitionID
        ]?.cancel()

        postponedTasks[
            definitionID
        ] = nil

        reminderQueue.removeOccurrences(
            for: definitionID
        )

        activeDefinitions[
            definitionID
        ] = nil

        publishEarliestScheduledReminder()
    }

    func pause() {
        runtimeStore.remindersPaused =
            true

        cancelScheduledTasks(
            publishUpdate: false
        )

        cancelPostponedTasks()
        reminderQueue.removeAll()
        activeDefinitions.removeAll()

        publishEarliestScheduledReminder()

        BuddyLogger.notice(
            "Generic reminders were paused.",
            category: .scheduler
        )
    }

    func resume(
        definitions: [ReminderDefinition]
    ) {
        runtimeStore.remindersPaused =
            false

        reload(
            definitions: definitions
        )

        BuddyLogger.notice(
            "Generic reminders were resumed.",
            category: .scheduler
        )
    }

    private func scheduleNextOccurrence(
        for definition: ReminderDefinition,
        after referenceDate: Date,
        lastHandled: Date?
    ) {
        guard !runtimeStore.remindersPaused,
              definition.isEnabled
        else {
            return
        }

        if !developerSettingsStore
            .fastTestingEnabled,
           definition.weekdays.isEmpty {
            return
        }

        activeDefinitions[
            definition.id
        ] = definition

        let nextDate: Date?

        if developerSettingsStore
            .fastTestingEnabled {
            let testInterval =
                max(
                    developerSettingsStore
                        .testIntervalSeconds,
                    1
                )

            nextDate =
                nowProvider()
                    .addingTimeInterval(
                        TimeInterval(
                            testInterval
                        )
                    )
        } else {
            nextDate =
                scheduleCalculator
                    .nextReminderDate(
                        after: referenceDate,
                        for: definition,
                        lastHandled:
                            lastHandled
                    )
        }

        guard let nextDate else {
            nextScheduledDates[
                definition.id
            ] = nil

            publishEarliestScheduledReminder()

            BuddyLogger.debug(
                "No future occurrence found for '\(definition.title)'.",
                category: .scheduler
            )

            return
        }

        cancelScheduledTask(
            definitionID:
                definition.id,
            publishUpdate: false
        )

        nextScheduledDates[
            definition.id
        ] = nextDate

        let delay =
            max(
                nextDate.timeIntervalSince(
                    nowProvider()
                ),
                0.1
            )

        BuddyLogger.info(
            "Scheduled '\(definition.title)' for \(nextDate).",
            category: .scheduler
        )

        let task = Task {
            [weak self] in

            do {
                try await Task.sleep(
                    for: .seconds(delay)
                )
            } catch {
                return
            }

            guard !Task.isCancelled,
                  let self
            else {
                return
            }

            handleOccurrence(
                definition: definition,
                scheduledDate: nextDate
            )
        }

        scheduledTasks[
            definition.id
        ] = task

        publishEarliestScheduledReminder()
    }

    private func handleOccurrence(
        definition: ReminderDefinition,
        scheduledDate: Date
    ) {
        scheduledTasks[
            definition.id
        ] = nil

        nextScheduledDates[
            definition.id
        ] = nil

        publishEarliestScheduledReminder()

        guard !runtimeStore.remindersPaused else {
            return
        }

        guard activeDefinitions[
            definition.id
        ] != nil else {
            BuddyLogger.debug(
                "Ignored due occurrence because its definition is no longer active: \(definition.title).",
                category: .scheduler
            )

            return
        }

        let wasAlreadyPresenting =
            reminderQueue
                .hasCurrentReminder

        let inserted =
            reminderQueue.enqueue(
                definition: definition,
                scheduledDate: scheduledDate
            )

        guard inserted else {
            scheduleFollowingOccurrence(
                for: definition
            )

            return
        }

        BuddyLogger.notice(
            "Generic reminder became due: '\(definition.title)'.",
            category: .reminders
        )

        if !wasAlreadyPresenting {
            presentNextReminderIfAvailable()
        }

        scheduleFollowingOccurrence(
            for: definition
        )
    }

    private func scheduleFollowingOccurrence(
        for definition: ReminderDefinition
    ) {
        let now =
            nowProvider()

        let referenceDate =
            now.addingTimeInterval(1)

        let lastHandled: Date?

        if developerSettingsStore
            .fastTestingEnabled {
            lastHandled = nil
        } else {
            switch definition.schedule {
            case .interval:
                lastHandled = now

            case .fixedTimes:
                lastHandled = nil
            }
        }

        scheduleNextOccurrence(
            for: definition,
            after: referenceDate,
            lastHandled: lastHandled
        )
    }

    private func cancelScheduledTask(
        definitionID: UUID,
        publishUpdate: Bool = true
    ) {
        scheduledTasks[
            definitionID
        ]?.cancel()

        scheduledTasks[
            definitionID
        ] = nil

        nextScheduledDates[
            definitionID
        ] = nil

        if publishUpdate {
            publishEarliestScheduledReminder()
        }
    }

    private func cancelScheduledTasks(
        publishUpdate: Bool = true
    ) {
        for task in scheduledTasks.values {
            task.cancel()
        }

        scheduledTasks.removeAll()
        nextScheduledDates.removeAll()

        if publishUpdate {
            publishEarliestScheduledReminder()
        }
    }

    private func cancelPostponedTasks() {
        for task in postponedTasks.values {
            task.cancel()
        }

        postponedTasks.removeAll()
    }

    private func publishEarliestScheduledReminder() {
        guard !runtimeStore.remindersPaused else {
            clearPublishedSchedule()
            return
        }

        guard let earliestEntry =
            nextScheduledDates.min(
                by: {
                    $0.value < $1.value
                }
            )
        else {
            clearPublishedSchedule()
            return
        }

        guard let definition =
            activeDefinitions[
                earliestEntry.key
            ]
        else {
            clearPublishedSchedule()
            return
        }

        runtimeStore.saveNextReminder(
            definition: definition,
            date: earliestEntry.value
        )

        NotificationCenter.default.post(
            name:
                .genericReminderScheduleDidChange,
            object: nil,
            userInfo: [
                ReminderScheduleNotificationKey
                    .definitionID:
                    definition.id.uuidString,

                ReminderScheduleNotificationKey
                    .title:
                    definition.title,

                ReminderScheduleNotificationKey
                    .category:
                    definition.category.rawValue,

                ReminderScheduleNotificationKey
                    .nextDate:
                    earliestEntry.value
            ]
        )

        BuddyLogger.debug(
            "Published next generic reminder '\(definition.title)' for \(earliestEntry.value).",
            category: .scheduler
        )
    }

    private func clearPublishedSchedule() {
        runtimeStore.clearNextReminder()

        NotificationCenter.default.post(
            name:
                .genericReminderScheduleDidChange,
            object: nil,
            userInfo: [:]
        )
    }
}
