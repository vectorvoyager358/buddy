import Foundation

final class WellnessSettingsStorage {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        self.decoder = JSONDecoder()
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

            return .default
        }

        do {
            let data = try Data(
                contentsOf: fileURL
            )

            let settings = try decoder.decode(
                WellnessSettings.self,
                from: data
            )

            BuddyLogger.info(
                "Wellness settings loaded successfully.",
                category: .storage
            )

            return settings
        } catch {
            BuddyLogger.error(
                "Unable to load wellness settings: "
                + error.localizedDescription,
                category: .storage
            )

            return .default
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

        let data = try encoder.encode(
            settings
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

    func reset() throws {
        let fileURL = settingsFileURL()

        guard fileManager.fileExists(
            atPath: fileURL.path
        ) else {
            BuddyLogger.info(
                "No wellness settings file existed to reset.",
                category: .storage
            )

            return
        }

        try fileManager.removeItem(
            at: fileURL
        )

        BuddyLogger.notice(
            "Wellness settings were reset.",
            category: .storage
        )
    }

    private func applicationSupportDirectoryURL() -> URL {
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

    private func settingsFileURL() -> URL {
        applicationSupportDirectoryURL()
            .appendingPathComponent(
                "wellness-settings.json",
                isDirectory: false
            )
    }
}
