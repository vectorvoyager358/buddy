import Foundation

struct WellnessSettings: Codable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int

    // Temporary compatibility model.
    // Keep this until the legacy hydration model is fully removed.
    var hydration: HydrationSettings

    // Generic reminder definitions.
    var reminders: [ReminderDefinition]

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        hydration: HydrationSettings,
        reminders: [ReminderDefinition]
    ) {
        self.schemaVersion = schemaVersion
        self.hydration = hydration
        self.reminders = reminders
    }

    static var `default`: WellnessSettings {
        let hydration = HydrationSettings.default

        return WellnessSettings(
            hydration: hydration,
            reminders: [
                ReminderDefinition.fromHydrationSettings(
                    hydration
                ),
                ReminderTemplate.supplement.definition
            ]
        )
    }

    private enum CodingKeys:
        String,
        CodingKey {

        case schemaVersion
        case hydration
        case reminders
    }

    init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        schemaVersion =
            try container.decodeIfPresent(
                Int.self,
                forKey: .schemaVersion
            ) ?? 1

        hydration =
            try container.decodeIfPresent(
                HydrationSettings.self,
                forKey: .hydration
            ) ?? .default

        reminders =
            try container.decodeIfPresent(
                [ReminderDefinition].self,
                forKey: .reminders
            ) ?? []

        ensureRequiredTemplates()
    }

    func encode(
        to encoder: Encoder
    ) throws {
        var container =
            encoder.container(
                keyedBy: CodingKeys.self
            )

        try container.encode(
            schemaVersion,
            forKey: .schemaVersion
        )

        try container.encode(
            hydration,
            forKey: .hydration
        )

        try container.encode(
            reminders,
            forKey: .reminders
        )
    }

    var hydrationReminder:
        ReminderDefinition? {
        reminders.first {
            $0.category == .hydration
        }
    }

    var supplementReminder:
        ReminderDefinition? {
        reminders.first {
            $0.category == .supplement
        }
    }

    mutating func ensureRequiredTemplates() {
        if hydrationReminder == nil {
            reminders.insert(
                ReminderDefinition
                    .fromHydrationSettings(
                        hydration
                    ),
                at: 0
            )
        }

        if supplementReminder == nil {
            reminders.append(
                ReminderTemplate
                    .supplement
                    .definition
            )
        }

        schemaVersion =
            Self.currentSchemaVersion
    }

    mutating func synchronizeLegacyHydrationReminder() {
        let migratedReminder =
            ReminderDefinition
                .fromHydrationSettings(
                    hydration
                )

        if let index =
            reminders.firstIndex(
                where: {
                    $0.category
                        == .hydration
                }
            ) {
            let existingID =
                reminders[index].id

            var updatedReminder =
                migratedReminder

            updatedReminder.id =
                existingID

            reminders[index] =
                updatedReminder
        } else {
            reminders.insert(
                migratedReminder,
                at: 0
            )
        }

        ensureRequiredTemplates()
    }

    mutating func updateSupplementReminder(
        _ reminder:
            ReminderDefinition
    ) {
        guard reminder.category
            == .supplement else {
            return
        }

        if let index =
            reminders.firstIndex(
                where: {
                    $0.category
                        == .supplement
                }
            ) {
            reminders[index] =
                reminder
        } else {
            reminders.append(
                reminder
            )
        }

        schemaVersion =
            Self.currentSchemaVersion
    }
}
