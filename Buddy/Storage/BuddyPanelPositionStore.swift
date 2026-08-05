import AppKit
import Foundation

final class BuddyPanelPositionStore {
    private enum Keys {
        static let originX = "buddy.panel.originX"
        static let originY = "buddy.panel.originY"
        static let hasSavedPosition = "buddy.panel.hasSavedPosition"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(origin: NSPoint) {
        defaults.set(origin.x, forKey: Keys.originX)
        defaults.set(origin.y, forKey: Keys.originY)
        defaults.set(true, forKey: Keys.hasSavedPosition)
    }

    func loadOrigin() -> NSPoint? {
        guard defaults.bool(forKey: Keys.hasSavedPosition) else {
            return nil
        }

        return NSPoint(
            x: defaults.double(forKey: Keys.originX),
            y: defaults.double(forKey: Keys.originY)
        )
    }

    func reset() {
        defaults.removeObject(forKey: Keys.originX)
        defaults.removeObject(forKey: Keys.originY)
        defaults.removeObject(forKey: Keys.hasSavedPosition)
    }
}
