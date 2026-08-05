import Foundation

struct WellnessSettings: Codable, Equatable {
    var hydration: HydrationSettings

    static let `default` = WellnessSettings(
        hydration: .default
    )
}
