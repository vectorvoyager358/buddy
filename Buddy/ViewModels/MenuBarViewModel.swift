import Foundation
import Combine

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set)
    var settings: WellnessSettings

    @Published private(set)
    var nextReminderDate: Date?

    @Published private(set)
    var isBuddyVisible: Bool

    @Published
    var remindersPaused: Bool

    private let settingsStorage:
        WellnessSettingsStorage

    private let runtimeStore:
        ReminderRuntimeStore

    private var observers: [NSObjectProtocol] = []

    init(
        settingsStorage:
            WellnessSettingsStorage =
                WellnessSettingsStorage(),
        runtimeStore:
            ReminderRuntimeStore =
                ReminderRuntimeStore()
    ) {
        self.settingsStorage = settingsStorage
        self.runtimeStore = runtimeStore

        settings = settingsStorage.load()

        remindersPaused =
            runtimeStore.remindersPaused

        nextReminderDate =
            runtimeStore.nextHydrationReminderDate

        isBuddyVisible =
            runtimeStore.buddyVisible

        beginObservingChanges()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default
                .removeObserver(observer)
        }
    }

    func toggleBuddyVisibility() {
        let notificationName: Notification.Name =
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
            runtimeStore
                .nextHydrationReminderDate = nil

            nextReminderDate = nil
        }

        NotificationCenter.default.post(
            name: .reminderPauseStateDidChange,
            object: nil
        )

        NotificationCenter.default.post(
            name: .reminderRuntimeDidChange,
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

    var scheduleSummary: String {
        let hydration = settings.hydration

        return "Every "
            + "\(hydration.intervalMinutes) min · "
            + activeHoursText
    }

    var nextReminderText: String {
        guard !remindersPaused else {
            return "Reminders are paused"
        }

        guard settings.hydration.isEnabled else {
            return "Hydration reminders are off"
        }

        guard let nextReminderDate else {
            return "Calculating next reminder…"
        }

        return "Next reminder "
            + nextReminderDate.formatted(
                date: .omitted,
                time: .shortened
            )
    }

    private var activeHoursText: String {
        let hydration = settings.hydration

        return timeString(
            hour: hydration.startHour,
            minute: hydration.startMinute
        )
        + "–"
        + timeString(
            hour: hydration.endHour,
            minute: hydration.endMinute
        )
    }

    private func timeString(
        hour: Int,
        minute: Int
    ) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let date =
            Calendar.current.date(
                from: components
            )
        else {
            return String(
                format: "%02d:%02d",
                hour,
                minute
            )
        }

        return date.formatted(
            date: .omitted,
            time: .shortened
        )
    }

    private func beginObservingChanges() {
        let settingsObserver =
            NotificationCenter.default.addObserver(
                forName:
                    .wellnessSettingsDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.reload()
                }
            }

        let runtimeObserver =
            NotificationCenter.default.addObserver(
                forName:
                    .reminderRuntimeDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.reload()
                }
            }

        let visibilityObserver =
            NotificationCenter.default.addObserver(
                forName:
                    .buddyVisibilityDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.reloadVisibility()
                }
            }

        observers = [
            settingsObserver,
            runtimeObserver,
            visibilityObserver
        ]
    }

    private func reload() {
        settings = settingsStorage.load()

        remindersPaused =
            runtimeStore.remindersPaused

        nextReminderDate =
            runtimeStore.nextHydrationReminderDate

        reloadVisibility()
    }

    private func reloadVisibility() {
        isBuddyVisible =
            runtimeStore.buddyVisible
    }
}
