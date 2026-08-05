import Foundation

final class ReminderRuntimeStore {
    private enum Keys {
        static let remindersPaused =
            "buddy.runtime.remindersPaused"

        static let nextHydrationReminderDate =
            "buddy.runtime.nextHydrationReminderDate"

        static let buddyVisible =
            "buddy.runtime.buddyVisible"
    }

    private let defaults: UserDefaults

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
    }

    var remindersPaused: Bool {
        get {
            defaults.bool(
                forKey: Keys.remindersPaused
            )
        }

        set {
            defaults.set(
                newValue,
                forKey: Keys.remindersPaused
            )
        }
    }

    var nextHydrationReminderDate: Date? {
        get {
            defaults.object(
                forKey: Keys.nextHydrationReminderDate
            ) as? Date
        }

        set {
            if let newValue {
                defaults.set(
                    newValue,
                    forKey: Keys.nextHydrationReminderDate
                )
            } else {
                defaults.removeObject(
                    forKey: Keys.nextHydrationReminderDate
                )
            }
        }
    }

    var buddyVisible: Bool {
        get {
            guard defaults.object(
                forKey: Keys.buddyVisible
            ) != nil else {
                return true
            }

            return defaults.bool(
                forKey: Keys.buddyVisible
            )
        }

        set {
            defaults.set(
                newValue,
                forKey: Keys.buddyVisible
            )
        }
    }
}
