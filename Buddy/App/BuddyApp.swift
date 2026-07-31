import SwiftUI
import AppKit

@main
struct BuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
