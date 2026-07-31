import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error {
                print(
                    "Notification permission error: \(error.localizedDescription)"
                )
                return
            }

            print(
                "Notification permission granted: \(granted)"
            )
        }
    }

    func sendReminder(
        _ reminder: Reminder,
        after seconds: TimeInterval
    ) {
        let content = UNMutableNotificationContent()

        content.title =
            "\(reminder.type.icon) \(reminder.title)"

        content.body = reminder.message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(seconds, 1),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current()
            .add(request) { error in
                if let error {
                    print(
                        "Unable to schedule notification: \(error.localizedDescription)"
                    )
                }
            }
    }

    func cancel(reminderID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    reminderID.uuidString
                ]
            )
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }
}
