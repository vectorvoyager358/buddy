import AppKit
import SwiftUI

@MainActor
final class AppDelegate:
    NSObject,
    NSApplicationDelegate,
    NSWindowDelegate {

    private var buddyPanel: BuddyPanel?

    private let animationEngine = AnimationEngine()

    private let settingsStorage =
        WellnessSettingsStorage()

    private let developerSettingsStore =
        DeveloperSettingsStore()

    private let panelPositionStore =
        BuddyPanelPositionStore()

    private lazy var buddyViewModel =
        BuddyViewModel(
            animationEngine: animationEngine
        )

    private var reminderManager:
        ReminderManager!

    private var hydrationScheduler:
        HydrationScheduler!

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        BuddyLogger.info(
            "Buddy is starting.",
            category: .app
        )

        createDependencies()
        connectCallbacks()
        createBuddyPanel()
        observeSettingsChanges()

        NotificationManager.shared
            .requestPermission()

        hydrationScheduler.start()

        BuddyLogger.info(
            "Buddy started in reminder-only mode.",
            category: .app
        )
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        saveCurrentPanelPosition()

        hydrationScheduler.stop()

        NotificationCenter.default.removeObserver(
            self,
            name: .wellnessSettingsDidChange,
            object: nil
        )

        BuddyLogger.info(
            "Buddy terminated.",
            category: .app
        )
    }

    private func createDependencies() {
        reminderManager =
            ReminderManager(
                buddyViewModel: buddyViewModel
            )

        hydrationScheduler =
            HydrationScheduler(
                storage: settingsStorage,
                developerSettingsStore:
                    developerSettingsStore,
                reminderManager:
                    reminderManager
            )
    }

    private func connectCallbacks() {
        reminderManager.onReminderTriggered = {
            [weak self] in

            BuddyLogger.notice(
                "Showing Buddy for a reminder.",
                category: .reminders
            )

            self?.showBuddyForReminder()
        }

        reminderManager.onReminderResolved = {
            [weak self] in

            self?.hideBuddyAfterAction()
        }

        reminderManager.onReminderCompleted = {
            [weak self] reminder in

            guard reminder.type == .water else {
                return
            }

            self?.hydrationScheduler
                .hydrationCompleted()
        }

        reminderManager.onReminderSnoozed = {
            [weak self] reminder in

            guard reminder.type == .water else {
                return
            }

            self?.hydrationScheduler
                .hydrationSnoozed()
        }

        reminderManager.onReminderSkipped = {
            [weak self] reminder in

            guard reminder.type == .water else {
                return
            }

            self?.hydrationScheduler
                .hydrationSkipped()
        }
    }

    private func observeSettingsChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                wellnessSettingsDidChange(_:)
            ),
            name: .wellnessSettingsDidChange,
            object: nil
        )
    }

    @objc
    private func wellnessSettingsDidChange(
        _ notification: Notification
    ) {
        hydrationScheduler.reload()
    }

    private func createBuddyPanel() {
        let panelSize = NSSize(
            width: 340,
            height: 390
        )

        let panel = BuddyPanel(
            contentRect: NSRect(
                origin: .zero,
                size: panelSize
            )
        )

        panel.delegate = self

        panel.contentView = NSHostingView(
            rootView: BuddyView(
                viewModel: buddyViewModel,
                animationEngine: animationEngine,
                reminderManager: reminderManager
            )
        )

        positionPanel(panel)

        panel.alphaValue = 1
        panel.orderFrontRegardless()

        buddyPanel = panel

        BuddyLogger.info(
            "Buddy panel was created and shown.",
            category: .app
        )
    }

    private func positionPanel(
        _ panel: BuddyPanel
    ) {
        let proposedOrigin =
            panelPositionStore.loadOrigin()
            ?? defaultPanelOrigin(
                for: panel.frame.size
            )

        let safeOrigin = clampedOrigin(
            proposedOrigin,
            panelSize: panel.frame.size
        )

        panel.setFrameOrigin(safeOrigin)
    }

    private func defaultPanelOrigin(
        for panelSize: NSSize
    ) -> NSPoint {
        let margin: CGFloat = 24

        guard let screen =
            NSScreen.main
            ?? NSScreen.screens.first
        else {
            return NSPoint(
                x: 100,
                y: 100
            )
        }

        let visibleFrame = screen.visibleFrame

        return NSPoint(
            x:
                visibleFrame.maxX
                - panelSize.width
                - margin,
            y:
                visibleFrame.minY
                + margin
        )
    }

    private func clampedOrigin(
        _ proposedOrigin: NSPoint,
        panelSize: NSSize
    ) -> NSPoint {
        let proposedFrame = NSRect(
            origin: proposedOrigin,
            size: panelSize
        )

        let targetScreen =
            NSScreen.screens.first {
                $0.visibleFrame.intersects(
                    proposedFrame
                )
            }
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let targetScreen else {
            return proposedOrigin
        }

        let visibleFrame =
            targetScreen.visibleFrame

        let maximumX =
            visibleFrame.maxX
            - panelSize.width

        let maximumY =
            visibleFrame.maxY
            - panelSize.height

        return NSPoint(
            x: min(
                max(
                    proposedOrigin.x,
                    visibleFrame.minX
                ),
                maximumX
            ),
            y: min(
                max(
                    proposedOrigin.y,
                    visibleFrame.minY
                ),
                maximumY
            )
        )
    }

    private func showBuddyForReminder() {
        guard let buddyPanel else {
            return
        }

        let safeOrigin = clampedOrigin(
            buddyPanel.frame.origin,
            panelSize: buddyPanel.frame.size
        )

        buddyPanel.setFrameOrigin(safeOrigin)
        buddyPanel.alphaValue = 0
        buddyPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup {
            context in

            context.duration = 0.20
            buddyPanel.animator().alphaValue = 1
        }
    }

    private func hideBuddyAfterAction() {
        guard let buddyPanel else {
            return
        }

        saveCurrentPanelPosition()

        NSAnimationContext.runAnimationGroup {
            context in

            context.duration = 0.18
            buddyPanel.animator().alphaValue = 0
        } completionHandler: {
            [weak self] in

            Task { @MainActor in
                self?.buddyPanel?.orderOut(nil)
                self?.buddyPanel?.alphaValue = 1
            }
        }
    }

    private func saveCurrentPanelPosition() {
        guard let buddyPanel else {
            return
        }

        panelPositionStore.save(
            origin: buddyPanel.frame.origin
        )
    }

    func windowDidMove(
        _ notification: Notification
    ) {
        saveCurrentPanelPosition()
    }

    func windowDidChangeScreen(
        _ notification: Notification
    ) {
        guard let buddyPanel else {
            return
        }

        let safeOrigin = clampedOrigin(
            buddyPanel.frame.origin,
            panelSize: buddyPanel.frame.size
        )

        buddyPanel.setFrameOrigin(safeOrigin)
        saveCurrentPanelPosition()
    }

    func showBuddy() {
        guard let buddyPanel else {
            return
        }

        let safeOrigin = clampedOrigin(
            buddyPanel.frame.origin,
            panelSize: buddyPanel.frame.size
        )

        buddyPanel.setFrameOrigin(safeOrigin)
        buddyPanel.alphaValue = 1
        buddyPanel.orderFrontRegardless()
    }

    func hideBuddy() {
        saveCurrentPanelPosition()
        buddyPanel?.orderOut(nil)
    }

    func quitBuddy() {
        NSApplication.shared.terminate(nil)
    }
}
