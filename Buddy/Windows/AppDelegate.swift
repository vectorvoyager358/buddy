import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Window

    private var buddyPanel: BuddyPanel?

    // MARK: - Dependencies

    private let animationEngine = AnimationEngine()
    private let settingsStorage = WellnessSettingsStorage()

    private lazy var buddyViewModel = BuddyViewModel(
        animationEngine: animationEngine
    )

    private var reminderManager: ReminderManager!
    private var hydrationScheduler: HydrationScheduler!

    // MARK: - Application lifecycle

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        createDependencies()
        connectCallbacks()
        createBuddyPanel()

        NotificationManager.shared.requestPermission()

        observeSettingsChanges()
        hydrationScheduler.start()
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        hydrationScheduler.stop()

        NotificationCenter.default.removeObserver(
            self,
            name: .wellnessSettingsDidChange,
            object: nil
        )
    }

    // MARK: - Dependency setup

    private func createDependencies() {
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

    // MARK: - Settings changes

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

    // MARK: - Floating panel

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
    }

    // MARK: - Menu-bar actions

    func showBuddy() {
        buddyPanel?.orderFrontRegardless()
    }

    func hideBuddy() {
        buddyPanel?.orderOut(nil)
    }

    func quitBuddy() {
        NSApplication.shared.terminate(nil)
    }
}
