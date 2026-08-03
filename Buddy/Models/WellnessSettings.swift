import Foundation

struct WellnessSettings: Codable {
    var hydration: HydrationSettings

    static let `default` = WellnessSettings(
        hydration: .default
    )
}