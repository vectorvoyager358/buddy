import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var buddyPanel: BuddyPanel?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        createBuddyPanel()
        createMenuBarItem()
    }

    private func createBuddyPanel() {
        let panel = BuddyPanel(
            contentRect: NSRect(
                x: 100,
                y: 100,
                width: 220,
                height: 220
            )
        )

        panel.contentView = NSHostingView(
            rootView: BuddyView()
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

    @objc private func quitBuddy() {
        NSApplication.shared.terminate(nil)
    }
}
