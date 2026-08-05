import Foundation
import Combine

@MainActor
final class MenuBarViewModel:
    ObservableObject {

    @Published private(set)
    var settings: WellnessSettings

    @Published private(set)
    var nextReminderDate: Date?

    @Published private(set)
    var nextReminderTitle: String?

    @Published private(set)
    var nextReminderCategory:
        ReminderCategory?

    @Published private(set)
    var isBuddyVisible: Bool

    @Published
    var remindersPaused: Bool

    private let settingsStorage:
        WellnessSettingsStorage

    private let runtimeStore:
        ReminderRuntimeStore

    private var observers:
        [NSObjectProtocol] = []

    init(
        settingsStorage:
            WellnessSettingsStorage =
                WellnessSettingsStorage(),
        runtimeStore:
            ReminderRuntimeStore =
                ReminderRuntimeStore()
    ) {
        self.settingsStorage =
            settingsStorage

        self.runtimeStore =
            runtimeStore

        settings =
            settingsStorage.load()

        remindersPaused =
            runtimeStore.remindersPaused

        isBuddyVisible =
            runtimeStore.buddyVisible

        nextReminderDate =
            runtimeStore.nextReminderDate

        nextReminderTitle =
            runtimeStore.nextReminderTitle

        nextReminderCategory =
            runtimeStore.nextReminderCategory

        if remindersPaused {
            nextReminderDate = nil
            nextReminderTitle = nil
            nextReminderCategory = nil
        }

        beginObservingChanges()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default
                .removeObserver(observer)
        }
    }

    func toggleBuddyVisibility() {
        let notificationName:
            Notification.Name =
                isBuddyVisible
                ? .hideBuddyRequested
                : .showBuddyRequested

        NotificationCenter.default.post(
            name: notificationName,
            object: nil
        )
    }

    func togglePause() {
        remindersPaused.toggle()

        runtimeStore.remindersPaused =
            remindersPaused

        if remindersPaused {
            runtimeStore.clearNextReminder()
            clearNextReminder()
        }

        NotificationCenter.default.post(
            name:
                .reminderPauseStateDidChange,
            object: nil
        )

        NotificationCenter.default.post(
            name:
                .reminderRuntimeDidChange,
            object: nil
        )

        BuddyLogger.notice(
            remindersPaused
                ? "Reminders were paused."
                : "Reminders were resumed.",
            category: .scheduler
        )
    }

    func quitBuddy() {
        NotificationCenter.default.post(
            name: .quitBuddyRequested,
            object: nil
        )
    }

    var buddyActionTitle: String {
        isBuddyVisible
            ? "Hide Buddy"
            : "Show Buddy"
    }

    var buddyActionSystemImage: String {
        isBuddyVisible
            ? "eye.slash"
            : "eye"
    }

    var statusTitle: String {
        remindersPaused
            ? "Paused"
            : "Active"
    }

    var statusSystemImage: String {
        remindersPaused
            ? "pause.circle.fill"
            : "checkmark.circle.fill"
    }

    var reminderSectionTitle: String {
        nextReminderTitle
            ?? defaultReminderTitle
    }

    var reminderSectionSystemImage: String {
        activeCategory.systemImage
    }

    var reminderSectionColor:
        MenuBarReminderColor {
        switch activeCategory {
        case .hydration:
            return .blue

        case .supplement:
            return .purple

        case .stretch:
            return .orange

        case .eyeBreak:
            return .indigo

        case .walk:
            return .green

        case .custom:
            return .blue
        }
    }

    var scheduleSummary: String {
        guard let definition =
            activeReminderDefinition
        else {
            return "No enabled reminders"
        }

        switch definition.schedule {
        case .interval(let schedule):
            return intervalSummary(
                schedule
            )

        case .fixedTimes(let schedule):
            return fixedTimesSummary(
                schedule
            )
        }
    }

    var nextReminderText: String {
        guard !remindersPaused else {
            return "Reminders are paused"
        }

        guard hasEnabledReminders else {
            return "No reminders are enabled"
        }

        guard let nextReminderDate else {
            return "Calculating next reminder…"
        }

        if Calendar.current.isDateInToday(
            nextReminderDate
        ) {
            return "Next reminder "
                + nextReminderDate.formatted(
                    date: .omitted,
                    time: .shortened
                )
        }

        return "Next reminder "
            + nextReminderDate.formatted(
                .dateTime
                    .weekday(.abbreviated)
                    .hour()
                    .minute()
            )
    }

    private var hasEnabledReminders: Bool {
        settings.reminders.contains {
            $0.isEnabled
                && !$0.weekdays.isEmpty
        }
    }

    private var activeCategory:
        ReminderCategory {
        nextReminderCategory
            ?? activeReminderDefinition?
                .category
            ?? .hydration
    }

    private var defaultReminderTitle: String {
        activeReminderDefinition?
            .title
            ?? "Reminders"
    }

    private var activeReminderDefinition:
        ReminderDefinition? {
        if let definitionID =
            runtimeStore
                .nextReminderDefinitionID,
           let matchingDefinition =
            settings.reminders.first(
                where: {
                    $0.id == definitionID
                }
            ) {
            return matchingDefinition
        }

        if let nextReminderCategory,
           let matchingDefinition =
            settings.reminders.first(
                where: {
                    $0.category
                        == nextReminderCategory
                        && $0.isEnabled
                }
            ) {
            return matchingDefinition
        }

        return settings.reminders.first {
            $0.isEnabled
                && !$0.weekdays.isEmpty
        }
    }

    private func intervalSummary(
        _ schedule:
            IntervalReminderSchedule
    ) -> String {
        "Every "
            + "\(schedule.intervalMinutes) min · "
            + schedule.startTime.formatted
            + "–"
            + schedule.endTime.formatted
    }

    private func fixedTimesSummary(
        _ schedule:
            FixedTimeReminderSchedule
    ) -> String {
        guard !schedule.times.isEmpty else {
            return "No times configured"
        }

        return schedule.times
            .sorted()
            .map(\.formatted)
            .joined(separator: ", ")
    }

    private func beginObservingChanges() {
        let settingsObserver =
            NotificationCenter.default
                .addObserver(
                    forName:
                        .wellnessSettingsDidChange,
                    object: nil,
                    queue: .main
                ) {
                    [weak self] _ in

                    Task { @MainActor in
                        self?.reloadSettings()
                    }
                }

        let runtimeObserver =
            NotificationCenter.default
                .addObserver(
                    forName:
                        .reminderRuntimeDidChange,
                    object: nil,
                    queue: .main
                ) {
                    [weak self] _ in

                    Task { @MainActor in
                        self?.reloadRuntime()
                    }
                }

        let scheduleObserver =
            NotificationCenter.default
                .addObserver(
                    forName:
                        .genericReminderScheduleDidChange,
                    object: nil,
                    queue: .main
                ) {
                    [weak self] _ in

                    Task { @MainActor in
                        self?.reloadSchedule()
                    }
                }

        let visibilityObserver =
            NotificationCenter.default
                .addObserver(
                    forName:
                        .buddyVisibilityDidChange,
                    object: nil,
                    queue: .main
                ) {
                    [weak self] _ in

                    Task { @MainActor in
                        self?.reloadVisibility()
                    }
                }

        observers = [
            settingsObserver,
            runtimeObserver,
            scheduleObserver,
            visibilityObserver
        ]
    }

    private func reloadSettings() {
        settings =
            settingsStorage.load()

        reloadRuntime()
        reloadSchedule()
    }

    private func reloadRuntime() {
        remindersPaused =
            runtimeStore.remindersPaused

        if remindersPaused {
            clearNextReminder()
        } else {
            reloadSchedule()
        }

        reloadVisibility()
    }

    private func reloadSchedule() {
        guard !runtimeStore.remindersPaused else {
            clearNextReminder()
            return
        }

        nextReminderDate =
            runtimeStore.nextReminderDate

        nextReminderTitle =
            runtimeStore.nextReminderTitle

        nextReminderCategory =
            runtimeStore.nextReminderCategory
    }

    private func reloadVisibility() {
        isBuddyVisible =
            runtimeStore.buddyVisible
    }

    private func clearNextReminder() {
        nextReminderDate = nil
        nextReminderTitle = nil
        nextReminderCategory = nil
    }
}

enum MenuBarReminderColor {
    case blue
    case purple
    case orange
    case indigo
    case green
}
