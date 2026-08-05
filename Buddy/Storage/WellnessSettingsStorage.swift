import Foundation

final class WellnessSettingsStorage {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        decoder = JSONDecoder()
    }

    func load() -> WellnessSettings {
        let fileURL = settingsFileURL()

        guard fileManager.fileExists(
            atPath: fileURL.path
        ) else {
            BuddyLogger.info(
                "No saved wellness settings were found. Using defaults.",
                category: .storage
            )

            let defaultSettings =
                WellnessSettings.default

            try? save(defaultSettings)

            return defaultSettings
        }

        do {
            let data = try Data(
                contentsOf: fileURL
            )

            var settings = try decoder.decode(
                WellnessSettings.self,
                from: data
            )

            let didMigrate =
                migrateIfNeeded(
                    settings: &settings
                )

            if didMigrate {
                try save(settings)

                BuddyLogger.notice(
                    "Wellness settings migrated to schema version \(WellnessSettings.currentSchemaVersion).",
                    category: .storage
                )
            }

            BuddyLogger.info(
                "Wellness settings loaded successfully.",
                category: .storage
            )

            return settings
        } catch {
            BuddyLogger.error(
                "Unable to load wellness settings: \(error.localizedDescription). Using defaults.",
                category: .storage
            )

            return WellnessSettings.default
        }
    }

    func save(
        _ settings: WellnessSettings
    ) throws {
        let directoryURL =
            applicationSupportDirectoryURL()

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        var settingsToSave = settings
        settingsToSave.schemaVersion =
            WellnessSettings.currentSchemaVersion

        let data = try encoder.encode(
            settingsToSave
        )

        try data.write(
            to: settingsFileURL(),
            options: .atomic
        )

        BuddyLogger.info(
            "Wellness settings saved successfully.",
            category: .storage
        )
    }

    func settingsFileURL() -> URL {
        applicationSupportDirectoryURL()
            .appendingPathComponent(
                "wellness-settings.json",
                isDirectory: false
            )
    }

    private func applicationSupportDirectoryURL()
        -> URL {
        let applicationSupportURL =
            fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]

        return applicationSupportURL
            .appendingPathComponent(
                "Buddy",
                isDirectory: true
            )
    }

    private func migrateIfNeeded(
        settings: inout WellnessSettings
    ) -> Bool {
        var didMigrate = false

        if settings.schemaVersion
            < WellnessSettings.currentSchemaVersion {
            settings.schemaVersion =
                WellnessSettings.currentSchemaVersion

            didMigrate = true
        }

        if settings.hydrationReminder == nil {
            settings.synchronizeLegacyHydrationReminder()
            didMigrate = true
        }

        return didMigrate
    }
}
