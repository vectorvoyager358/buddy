import SwiftUI

enum BuddyAnimation: String, Equatable {
    case idle
    case wave
    case celebrate
    case thinking
    case sleeping

    var emoji: String {
        switch self {
        case .idle:
            return "🤖"

        case .wave:
            return "👋"

        case .celebrate:
            return "🥳"

        case .thinking:
            return "🤔"

        case .sleeping:
            return "😴"
        }
    }

    var color: Color {
        switch self {
        case .idle:
            return .blue

        case .wave:
            return .orange

        case .celebrate:
            return .green

        case .thinking:
            return .purple

        case .sleeping:
            return .indigo
        }
    }

    var scale: CGFloat {
        switch self {
        case .idle:
            return 1.0

        case .wave:
            return 1.08

        case .celebrate:
            return 1.15

        case .thinking:
            return 1.03

        case .sleeping:
            return 0.94
        }
    }

    var rotation: Double {
        switch self {
        case .wave:
            return 8

        default:
            return 0
        }
    }
}
