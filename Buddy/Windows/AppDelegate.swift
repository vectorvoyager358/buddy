import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var buddyPanel: BuddyPanel?

    private let animationEngine = AnimationEngine()
    private let settingsStorage = WellnessSettingsStorage()

    private lazy var buddyViewModel = BuddyViewModel(
        animationEngine: animationEngine
    )

    private var reminderManager: ReminderManager!
    private var hydrationScheduler: HydrationScheduler!

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

        NotificationManager.shared.requestPermission()

        observeSettingsChanges()
        hydrationScheduler.start()

        BuddyLogger.info(
            "Buddy started successfully.",
            category: .app
        )
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        BuddyLogger.info(
            "Buddy is terminating.",
            category: .app
        )

        hydrationScheduler.stop()

        NotificationCenter.default.removeObserver(
            self,
            name: .wellnessSettingsDidChange,
            object: nil
        )
    }

    private func createDependencies() {
        BuddyLogger.debug(
            "Creating Buddy dependencies.",
            category: .app
        )

        reminderManager = ReminderManager(
            buddyViewModel: buddyViewModel
        )

        hydrationScheduler = HydrationScheduler(
            storage: settingsStorage,
            reminderManager: reminderManager
        )
    }

    private func connectCallbacks() {
        reminderManager.onReminderTriggered = {
            [weak self] in

            BuddyLogger.debug(
                "Showing Buddy because a reminder triggered.",
                category: .reminders
            )

            self?.buddyPanel?.orderFrontRegardless()
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

        BuddyLogger.debug(
            "Started observing wellness settings changes.",
            category: .settings
        )
    }

    @objc
    private func wellnessSettingsDidChange(
        _ notification: Notification
    ) {
        BuddyLogger.info(
            "Wellness settings changed. Reloading scheduler.",
            category: .settings
        )

        hydrationScheduler.reload()
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
                viewModel: buddyViewModel,
                animationEngine: animationEngine,
                reminderManager: reminderManager
            )
        )

        panel.center()
        panel.orderFrontRegardless()

        buddyPanel = panel

        BuddyLogger.info(
            "Buddy floating panel was created.",
            category: .app
        )
    }

    func showBuddy() {
        buddyPanel?.orderFrontRegardless()

        BuddyLogger.debug(
            "Buddy was shown.",
            category: .app
        )
    }

    func hideBuddy() {
        buddyPanel?.orderOut(nil)

        BuddyLogger.debug(
            "Buddy was hidden.",
            category: .app
        )
    }

    func quitBuddy() {
        BuddyLogger.info(
            "Quit Buddy was selected.",
            category: .app
        )

        NSApplication.shared.terminate(nil)
    }
}
