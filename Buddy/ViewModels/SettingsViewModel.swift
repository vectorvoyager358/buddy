import Combine
import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel:
    ObservableObject {

    @Published var settings:
        WellnessSettings

    @Published var fastTestingEnabled:
        Bool

    @Published var testIntervalSeconds:
        Int

    @Published private(set)
    var statusMessage: String?

    @Published private(set)
    var hasError = false

    private let storage:
        WellnessSettingsStorage

    private let developerSettingsStore:
        DeveloperSettingsStore

    private var savedSettings:
        WellnessSettings

    private var savedFastTestingEnabled:
        Bool

    private var savedTestIntervalSeconds:
        Int

    private var clearStatusTask:
        Task<Void, Never>?

    init(
        storage:
            WellnessSettingsStorage,
        developerSettingsStore:
            DeveloperSettingsStore
    ) {
        self.storage =
            storage

        self.developerSettingsStore =
            developerSettingsStore

        var loadedSettings =
            storage.load()

        loadedSettings
            .ensureRequiredTemplates()

        let loadedFastTestingEnabled =
            developerSettingsStore
                .fastTestingEnabled

        let loadedTestIntervalSeconds =
            developerSettingsStore
                .testIntervalSeconds

        settings =
            loadedSettings

        fastTestingEnabled =
            loadedFastTestingEnabled

        testIntervalSeconds =
            loadedTestIntervalSeconds

        savedSettings =
            loadedSettings

        savedFastTestingEnabled =
            loadedFastTestingEnabled

        savedTestIntervalSeconds =
            loadedTestIntervalSeconds
    }

    convenience init() {
        self.init(
            storage:
                WellnessSettingsStorage(),
            developerSettingsStore:
                DeveloperSettingsStore()
        )
    }

    var supplementReminder:
        ReminderDefinition {
        get {
            settings.supplementReminder
                ?? ReminderTemplate
                    .supplement
                    .definition
        }

        set {
            settings.updateSupplementReminder(
                newValue
            )
        }
    }

    var supplementReminderBinding:
        Binding<ReminderDefinition> {
        Binding(
            get: {
                self.supplementReminder
            },
            set: {
                self.supplementReminder =
                    $0
            }
        )
    }

    var hasUnsavedChanges: Bool {
        settings != savedSettings
            || fastTestingEnabled
                != savedFastTestingEnabled
            || testIntervalSeconds
                != savedTestIntervalSeconds
    }

    func reloadFromStorage() {
        clearStatusTask?.cancel()

        var loadedSettings =
            storage.load()

        loadedSettings
            .ensureRequiredTemplates()

        let loadedFastTestingEnabled =
            developerSettingsStore
                .fastTestingEnabled

        let loadedTestIntervalSeconds =
            developerSettingsStore
                .testIntervalSeconds

        settings =
            loadedSettings

        fastTestingEnabled =
            loadedFastTestingEnabled

        testIntervalSeconds =
            loadedTestIntervalSeconds

        savedSettings =
            loadedSettings

        savedFastTestingEnabled =
            loadedFastTestingEnabled

        savedTestIntervalSeconds =
            loadedTestIntervalSeconds

        hasError = false
        statusMessage = nil

        BuddyLogger.debug(
            "Settings reloaded from saved storage.",
            category: .settings
        )
    }

    func save() {
        guard hasUnsavedChanges else {
            return
        }

        guard validateSettings() else {
            return
        }

        do {
            settings
                .synchronizeLegacyHydrationReminder()

            settings
                .ensureRequiredTemplates()

            try storage.save(
                settings
            )

            developerSettingsStore
                .fastTestingEnabled =
                    fastTestingEnabled

            developerSettingsStore
                .testIntervalSeconds =
                    testIntervalSeconds

            updateSavedSnapshot()

            hasError = false

            statusMessage =
                "Settings saved successfully."

            BuddyLogger.info(
                "Settings and developer options were saved.",
                category: .settings
            )

            notifySchedulerOfChanges()
            clearStatusMessage(
                after: 3
            )
        } catch {
            hasError = true

            statusMessage =
                "Unable to save settings: "
                + error.localizedDescription

            BuddyLogger.error(
                "Unable to save settings: "
                + error.localizedDescription,
                category: .settings
            )
        }
    }

    func resetToDefaults() {
        settings = .default

        developerSettingsStore.reset()

        fastTestingEnabled =
            developerSettingsStore
                .fastTestingEnabled

        testIntervalSeconds =
            developerSettingsStore
                .testIntervalSeconds

        do {
            try storage.save(
                settings
            )

            updateSavedSnapshot()

            hasError = false

            statusMessage =
                "Default settings restored."

            BuddyLogger.notice(
                "Default settings were restored.",
                category: .settings
            )

            notifySchedulerOfChanges()
            clearStatusMessage(
                after: 3
            )
        } catch {
            hasError = true

            statusMessage =
                "Unable to restore defaults: "
                + error.localizedDescription

            BuddyLogger.error(
                "Unable to restore defaults: "
                + error.localizedDescription,
                category: .settings
            )
        }
    }

    private func updateSavedSnapshot() {
        savedSettings =
            settings

        savedFastTestingEnabled =
            fastTestingEnabled

        savedTestIntervalSeconds =
            testIntervalSeconds
    }

    private func validateSettings()
        -> Bool {
        guard settings.hydration
            .intervalMinutes > 0 else {
            showValidationError(
                "The hydration interval must be greater than zero."
            )

            return false
        }

        guard !settings.hydration
            .weekdays.isEmpty else {
            showValidationError(
                "Select at least one active hydration day."
            )

            return false
        }

        let startMinutes =
            settings.hydration.startHour
            * 60
            + settings.hydration
                .startMinute

        let endMinutes =
            settings.hydration.endHour
            * 60
            + settings.hydration
                .endMinute

        guard endMinutes
            > startMinutes else {
            showValidationError(
                "The hydration end time must be later than the start time."
            )

            return false
        }

        let supplement =
            supplementReminder

        if supplement.isEnabled {
            let trimmedName =
                supplement.title
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard !trimmedName.isEmpty else {
                showValidationError(
                    "Enter a supplement name."
                )

                return false
            }

            guard !supplement.weekdays
                .isEmpty else {
                showValidationError(
                    "Select at least one active supplement day."
                )

                return false
            }

            guard case .fixedTimes(
                let fixedSchedule
            ) = supplement.schedule else {
                showValidationError(
                    "The supplement reminder must use exact daily times."
                )

                return false
            }

            guard !fixedSchedule
                .times.isEmpty else {
                showValidationError(
                    "Add at least one supplement reminder time."
                )

                return false
            }
        }

        guard testIntervalSeconds
            >= 1 else {
            showValidationError(
                "The test interval must be at least one second."
            )

            return false
        }

        return true
    }

    private func showValidationError(
        _ message: String
    ) {
        hasError = true
        statusMessage = message

        BuddyLogger.warning(
            message,
            category: .settings
        )
    }

    private func notifySchedulerOfChanges() {
        NotificationCenter.default.post(
            name:
                .wellnessSettingsDidChange,
            object: nil
        )
    }

    private func clearStatusMessage(
        after seconds:
            TimeInterval
    ) {
        clearStatusTask?.cancel()

        clearStatusTask =
            Task {
                [weak self] in

                do {
                    try await Task.sleep(
                        for:
                            .seconds(
                                seconds
                            )
                    )
                } catch {
                    return
                }

                guard !Task.isCancelled
                else {
                    return
                }

                self?.statusMessage =
                    nil
            }
    }
}
