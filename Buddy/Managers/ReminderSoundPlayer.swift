import AppKit

@MainActor
final class ReminderSoundPlayer {
    static let shared = ReminderSoundPlayer()

    private let preferredSoundName = NSSound.Name("Glass")

    private init() {}

    func play() {
        if let sound = NSSound(named: preferredSoundName) {
            sound.stop()
            sound.play()

            BuddyLogger.debug(
                "Played mandatory reminder sound.",
                category: .reminders
            )
        } else {
            NSSound.beep()

            BuddyLogger.warning(
                "Preferred reminder sound was unavailable. Played system beep.",
                category: .reminders
            )
        }
    }
}
