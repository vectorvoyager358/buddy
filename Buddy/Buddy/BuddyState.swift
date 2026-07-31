import Foundation

enum BuddyState: Equatable {
    case idle
    case reminder(Reminder)
    case happy(message: String)
}
