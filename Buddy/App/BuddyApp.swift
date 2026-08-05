import SwiftUI

@main
struct BuddyApp: App {
    @NSApplicationDelegateAdaptor(
        AppDelegate.self
    )
    private var appDelegate

    var body: some Scene {
        MenuBarExtra(
            "Buddy",
            systemImage: "circle.dotted"
        ) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
        .windowLevel(.floating)
        .defaultSize(
            width: 620,
            height: 700
        )
    }
}
