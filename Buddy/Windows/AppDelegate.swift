import AppKit
import SwiftUI

@MainActor
final class AppDelegate:
    NSObject,
    NSApplicationDelegate {
    private var buddyPanel: BuddyPanel?

    private let animationEngine =
        AnimationEngine()

    private let settingsStorage =
        WellnessSettingsStorage()

    private let developerSettingsStore =
        DeveloperSettingsStore()

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

        NotificationManager.shared
            .requestPermission()

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
        hydrationScheduler.stop()

        NotificationCenter.default
            .removeObserver(
                self,
                name:
                    .wellnessSettingsDidChange,
                object: nil
            )
    }

    private func createDependencies() {
        reminderManager =
            ReminderManager(
                buddyViewModel:
                    buddyViewModel
            )

        hydrationScheduler =
            HydrationScheduler(
                storage:
                    settingsStorage,
                developerSettingsStore:
                    developerSettingsStore,
                reminderManager:
                    reminderManager
            )
    }

    private func connectCallbacks() {
        reminderManager
            .onReminderTriggered = {
                [weak self] in

                self?.buddyPanel?
                    .orderFrontRegardless()
            }

        reminderManager
            .onReminderResolved = {
                [weak self] in

                self?.hideBuddyAfterAction()
            }

        reminderManager
            .onReminderCompleted = {
                [weak self] reminder in

                guard reminder.type == .water
                else {
                    return
                }

                self?.hydrationScheduler
                    .hydrationCompleted()
            }

        reminderManager
            .onReminderSnoozed = {
                [weak self] reminder in

                guard reminder.type == .water
                else {
                    return
                }

                self?.hydrationScheduler
                    .hydrationSnoozed()
            }

        reminderManager
            .onReminderSkipped = {
                [weak self] reminder in

                guard reminder.type == .water
                else {
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
        let panel = BuddyPanel(
            contentRect: NSRect(
                x: 100,
                y: 100,
                width: 340,
                height: 390
            )
        )

        panel.contentView = NSHostingView(
            rootView: BuddyView(
                viewModel: buddyViewModel,
                animationEngine:
                    animationEngine,
                reminderManager:
                    reminderManager
            )
        )

        panel.center()
        panel.orderFrontRegardless()

        buddyPanel = panel
    }

    private func hideBuddyAfterAction() {
        guard let buddyPanel else {
            return
        }

        NSAnimationContext
            .runAnimationGroup { context in
                context.duration = 0.18

                buddyPanel
                    .animator()
                    .alphaValue = 0
            } completionHandler: {
                [weak self] in

                Task { @MainActor in
                    self?.buddyPanel?
                        .orderOut(nil)

                    self?.buddyPanel?
                        .alphaValue = 1
                }
            }
    }

    func showBuddy() {
        buddyPanel?.alphaValue = 1
        buddyPanel?.orderFrontRegardless()
    }

    func hideBuddy() {
        buddyPanel?.orderOut(nil)
    }

    func quitBuddy() {
        NSApplication.shared.terminate(nil)
    }
}
