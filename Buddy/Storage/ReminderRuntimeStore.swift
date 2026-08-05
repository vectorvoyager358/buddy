import Foundation

final class ReminderRuntimeStore {
    private enum Keys {
        static let remindersPaused =
            "buddy.runtime.remindersPaused"

        // Legacy key retained temporarily for compatibility.
        static let nextHydrationReminderDate =
            "buddy.runtime.nextHydrationReminderDate"

        static let nextReminderDate =
            "buddy.runtime.nextReminderDate"

        static let nextReminderDefinitionID =
            "buddy.runtime.nextReminderDefinitionID"

        static let nextReminderTitle =
            "buddy.runtime.nextReminderTitle"

        static let nextReminderCategory =
            "buddy.runtime.nextReminderCategory"

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

    /// Legacy hydration-only runtime value.
    ///
    /// Keep this property until the old HydrationScheduler and any
    /// remaining hydration-specific menu code are removed.
    var nextHydrationReminderDate: Date? {
        get {
            defaults.object(
                forKey:
                    Keys.nextHydrationReminderDate
            ) as? Date
        }

        set {
            setOptionalDate(
                newValue,
                forKey:
                    Keys.nextHydrationReminderDate
            )
        }
    }

    var nextReminderDate: Date? {
        get {
            defaults.object(
                forKey: Keys.nextReminderDate
            ) as? Date
        }

        set {
            setOptionalDate(
                newValue,
                forKey:
                    Keys.nextReminderDate
            )
        }
    }

    var nextReminderDefinitionID: UUID? {
        get {
            guard let rawValue =
                defaults.string(
                    forKey:
                        Keys.nextReminderDefinitionID
                )
            else {
                return nil
            }

            return UUID(
                uuidString: rawValue
            )
        }

        set {
            if let newValue {
                defaults.set(
                    newValue.uuidString,
                    forKey:
                        Keys.nextReminderDefinitionID
                )
            } else {
                defaults.removeObject(
                    forKey:
                        Keys.nextReminderDefinitionID
                )
            }
        }
    }

    var nextReminderTitle: String? {
        get {
            defaults.string(
                forKey:
                    Keys.nextReminderTitle
            )
        }

        set {
            setOptionalString(
                newValue,
                forKey:
                    Keys.nextReminderTitle
            )
        }
    }

    var nextReminderCategory:
        ReminderCategory? {
        get {
            guard let rawValue =
                defaults.string(
                    forKey:
                        Keys.nextReminderCategory
                )
            else {
                return nil
            }

            return ReminderCategory(
                rawValue: rawValue
            )
        }

        set {
            setOptionalString(
                newValue?.rawValue,
                forKey:
                    Keys.nextReminderCategory
            )
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

    func saveNextReminder(
        definition: ReminderDefinition,
        date: Date
    ) {
        nextReminderDefinitionID =
            definition.id

        nextReminderTitle =
            definition.title

        nextReminderCategory =
            definition.category

        nextReminderDate =
            date
    }

    func clearNextReminder() {
        nextReminderDefinitionID = nil
        nextReminderTitle = nil
        nextReminderCategory = nil
        nextReminderDate = nil
    }

    private func setOptionalDate(
        _ value: Date?,
        forKey key: String
    ) {
        if let value {
            defaults.set(
                value,
                forKey: key
            )
        } else {
            defaults.removeObject(
                forKey: key
            )
        }
    }

    private func setOptionalString(
        _ value: String?,
        forKey key: String
    ) {
        if let value {
            defaults.set(
                value,
                forKey: key
            )
        } else {
            defaults.removeObject(
                forKey: key
            )
        }
    }
}
