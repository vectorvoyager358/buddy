import Foundation

final class DeveloperSettingsStore {
    private enum Keys {
        static let fastTestingEnabled =
            "developer.fastTestingEnabled"

        static let testIntervalSeconds =
            "developer.testIntervalSeconds"
    }

    private let defaults: UserDefaults

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
    }

    var fastTestingEnabled: Bool {
        get {
            defaults.object(
                forKey: Keys.fastTestingEnabled
            ) as? Bool ?? true
        }

        set {
            defaults.set(
                newValue,
                forKey: Keys.fastTestingEnabled
            )
        }
    }

    var testIntervalSeconds: Int {
        get {
            let storedValue = defaults.integer(
                forKey: Keys.testIntervalSeconds
            )

            return storedValue > 0
                ? storedValue
                : 10
        }

        set {
            defaults.set(
                max(newValue, 1),
                forKey: Keys.testIntervalSeconds
            )
        }
    }

    func reset() {
        defaults.removeObject(
            forKey: Keys.fastTestingEnabled
        )

        defaults.removeObject(
            forKey: Keys.testIntervalSeconds
        )

        BuddyLogger.notice(
            "Developer settings were reset.",
            category: .settings
        )
    }
}
