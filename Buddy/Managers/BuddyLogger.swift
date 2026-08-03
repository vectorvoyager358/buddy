import Foundation
import OSLog

enum BuddyLogCategory: String {
    case app
    case scheduler
    case reminders
    case notifications
    case settings
    case storage
    case animation
}

enum BuddyLogger {
    private static let subsystem =
        Bundle.main.bundleIdentifier ?? "com.buddy.app"

    static func debug(
        _ message: String,
        category: BuddyLogCategory = .app
    ) {
        logger(for: category).debug(
            "\(message, privacy: .public)"
        )
    }

    static func info(
        _ message: String,
        category: BuddyLogCategory = .app
    ) {
        logger(for: category).info(
            "\(message, privacy: .public)"
        )
    }

    static func notice(
        _ message: String,
        category: BuddyLogCategory = .app
    ) {
        logger(for: category).notice(
            "\(message, privacy: .public)"
        )
    }

    static func warning(
        _ message: String,
        category: BuddyLogCategory = .app
    ) {
        logger(for: category).warning(
            "\(message, privacy: .public)"
        )
    }

    static func error(
        _ message: String,
        category: BuddyLogCategory = .app
    ) {
        logger(for: category).error(
            "\(message, privacy: .public)"
        )
    }

    static func fault(
        _ message: String,
        category: BuddyLogCategory = .app
    ) {
        logger(for: category).fault(
            "\(message, privacy: .public)"
        )
    }

    private static func logger(
        for category: BuddyLogCategory
    ) -> Logger {
        Logger(
            subsystem: subsystem,
            category: category.rawValue
        )
    }
}
