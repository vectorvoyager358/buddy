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
            return .default
        }

        do {
            let data = try Data(
                contentsOf: fileURL
            )

            return try decoder.decode(
                WellnessSettings.self,
                from: data
            )
        } catch {
            print(
                "Unable to load wellness settings: \(error.localizedDescription)"
            )

            return .default
        }
    }

    func save(
        _ settings: WellnessSettings
    ) throws {
        let directoryURL = applicationSupportDirectoryURL()

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
    }

    func reset() throws {
        let fileURL = settingsFileURL()

        guard fileManager.fileExists(
            atPath: fileURL.path
        ) else {
            return
        }

        try fileManager.removeItem(
            at: fileURL
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