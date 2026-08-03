import SwiftUI
import AppKit

@main
struct BuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        MenuBarExtra(
            "Buddy",
            systemImage: "pawprint.fill"
        ) {
            SettingsLink {
                Label(
                    "Settings…",
                    systemImage: "gearshape"
                )
            }
            .keyboardShortcut(
                ",",
                modifiers: [.command]
            )

            Divider()

            Button {
                appDelegate.showBuddy()
            } label: {
                Label(
                    "Show Buddy",
                    systemImage: "eye"
                )
            }

            Button {
                appDelegate.hideBuddy()
            } label: {
                Label(
                    "Hide Buddy",
                    systemImage: "eye.slash"
                )
            }

            Divider()

            Button {
                appDelegate.quitBuddy()
            } label: {
                Label(
                    "Quit Buddy",
                    systemImage: "power"
                )
            }
            .keyboardShortcut(
                "q",
                modifiers: [.command]
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
        .windowLevel(.floating)
    }
}
