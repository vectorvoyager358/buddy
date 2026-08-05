import Foundation

extension Notification.Name {
    static let wellnessSettingsDidChange =
        Notification.Name(
            "wellnessSettingsDidChange"
        )

    static let reminderPauseStateDidChange =
        Notification.Name(
            "reminderPauseStateDidChange"
        )

    static let reminderRuntimeDidChange =
        Notification.Name(
            "reminderRuntimeDidChange"
        )

    static let buddyVisibilityDidChange =
        Notification.Name(
            "buddyVisibilityDidChange"
        )

    static let showBuddyRequested =
        Notification.Name(
            "showBuddyRequested"
        )

    static let hideBuddyRequested =
        Notification.Name(
            "hideBuddyRequested"
        )

    static let quitBuddyRequested =
        Notification.Name(
            "quitBuddyRequested"
        )
}
