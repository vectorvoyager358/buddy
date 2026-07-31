import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var buddyPanel: BuddyPanel?
    private var statusItem: NSStatusItem?
    private let buddyViewModel = BuddyViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        createBuddyPanel()
        createMenuBarItem()
        NotificationManager.shared.requestPermission()
    }

    private func createBuddyPanel() {
        let panel = BuddyPanel(
            contentRect: NSRect(
                x: 100,
                y: 100,
                width: 280,
                height: 300
            )
        )

        panel.contentView = NSHostingView(
            rootView: BuddyView(
                viewModel: buddyViewModel
            )
        )

        panel.center()
        panel.orderFrontRegardless()

        buddyPanel = panel
    }

    private func createMenuBarItem() {
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )

        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "pawprint.fill",
                accessibilityDescription: "Buddy"
            )
        }

        let menu = NSMenu()
        
        let reminderItem = NSMenuItem(
            title: "Test Reminder (10 sec)",
            action: #selector(testReminder),
            keyEquivalent: ""
        )

        reminderItem.target = self

        menu.addItem(reminderItem)

        menu.addItem(.separator())

        let showItem = NSMenuItem(
            title: "Show Buddy",
            action: #selector(showBuddy),
            keyEquivalent: ""
        )
        showItem.target = self
        menu.addItem(showItem)

        let hideItem = NSMenuItem(
            title: "Hide Buddy",
            action: #selector(hideBuddy),
            keyEquivalent: ""
        )
        hideItem.target = self
        menu.addItem(hideItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Buddy",
            action: #selector(quitBuddy),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func showBuddy() {
        buddyPanel?.orderFrontRegardless()
    }

    @objc private func hideBuddy() {
        buddyPanel?.orderOut(nil)
    }

    @objc
    private func testReminder() {
        let reminder = Reminder(
            title: "Drink Water",
            message: "You've been coding for a while. Let's grab some water!",
            type: .water
        )

        NotificationManager.shared.sendReminder(
            reminder,
            after: 10
        )

        Task {
            try? await Task.sleep(
                for: .seconds(10)
            )

            guard !Task.isCancelled else {
                return
            }

            buddyPanel?.orderFrontRegardless()
            buddyViewModel.showReminder(reminder)
        }
    }
    
    @objc private func quitBuddy() {
        NSApplication.shared.terminate(nil)
    }
}
