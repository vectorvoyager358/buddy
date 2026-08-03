import Foundation

enum SchedulerConfiguration {
    #if DEBUG
    static let useFastHydrationTesting = false
    static let hydrationTestInterval: TimeInterval = 10
    #else
    static let useFastHydrationTesting = false
    static let hydrationTestInterval: TimeInterval = 10
    #endif
}
