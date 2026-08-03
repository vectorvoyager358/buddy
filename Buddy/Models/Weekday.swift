import Foundation

enum Weekday: Int,
              Codable,
              CaseIterable,
              Hashable {

    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var shortName: String {

        switch self {

        case .sunday:
            return "Sun"

        case .monday:
            return "Mon"

        case .tuesday:
            return "Tue"

        case .wednesday:
            return "Wed"

        case .thursday:
            return "Thu"

        case .friday:
            return "Fri"

        case .saturday:
            return "Sat"
        }
    }
}