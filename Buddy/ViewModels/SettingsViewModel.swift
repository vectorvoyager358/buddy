import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: WellnessSettings

    @Published private(set) var statusMessage: String?
    @Published private(set) var hasError = false

    private let storage: WellnessSettingsStorage
    private var clearStatusTask: Task<Void, Never>?

    init(storage: WellnessSettingsStorage) {
        self.storage = storage
        self.settings = storage.load()
    }

    convenience init() {
        self.init(
            storage: WellnessSettingsStorage()
        )
    }

    func save() {
        guard validateSettings() else {
            return
        }

        do {
            try storage.save(settings)

            hasError = false
            statusMessage = "Settings saved successfully."

            NotificationCenter.default.post(
                name: .wellnessSettingsDidChange,
                object: nil
            )

            clearStatusMessage(after: 3)
        } catch {
            hasError = true
            statusMessage =
                "Unable to save settings: \(error.localizedDescription)"
        }
    }

    func resetToDefaults() {
        settings = .default

        do {
            try storage.save(settings)

            hasError = false
            statusMessage = "Default settings restored."

            NotificationCenter.default.post(
                name: .wellnessSettingsDidChange,
                object: nil
            )

            clearStatusMessage(after: 3)
        } catch {
            hasError = true
            statusMessage =
                "Unable to reset settings: \(error.localizedDescription)"
        }
    }

    private func validateSettings() -> Bool {
        guard !settings.hydration.weekdays.isEmpty else {
            hasError = true
            statusMessage = "Select at least one active day."
            return false
        }

        guard settings.hydration.intervalMinutes > 0 else {
            hasError = true
            statusMessage =
                "The reminder interval must be greater than zero."
            return false
        }

        let startMinutes =
            settings.hydration.startHour * 60
            + settings.hydration.startMinute

        let endMinutes =
            settings.hydration.endHour * 60
            + settings.hydration.endMinute

        guard endMinutes > startMinutes else {
            hasError = true
            statusMessage =
                "The end time must be later than the start time."
            return false
        }

        return true
    }

    private func clearStatusMessage(
        after seconds: TimeInterval
    ) {
        clearStatusTask?.cancel()

        clearStatusTask = Task { [weak self] in
            try? await Task.sleep(
                for: .seconds(seconds)
            )

            guard !Task.isCancelled else {
                return
            }

            self?.statusMessage = nil
        }
    }
}
