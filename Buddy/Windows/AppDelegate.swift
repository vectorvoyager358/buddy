import AppKit
import SwiftUI

@MainActor
final class AppDelegate:
    NSObject,
    NSApplicationDelegate,
    NSWindowDelegate {

    private var buddyPanel: BuddyPanel?

    private let animationEngine =
        AnimationEngine()

    private let settingsStorage =
        WellnessSettingsStorage()

    private let developerSettingsStore =
        DeveloperSettingsStore()

    private let runtimeStore =
        ReminderRuntimeStore()

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

    private var hideAfterActionTask:
        Task<Void, Never>?

    private var isMovingPanelProgrammatically =
        false

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
        observeNotifications()

        NotificationManager.shared
            .requestPermission()

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

        hideAfterActionTask?.cancel()

        saveCurrentPanelPosition()
        hydrationScheduler.stop()

        NotificationCenter.default.removeObserver(
            self
        )
    }

    private func createDependencies() {
        BuddyLogger.debug(
            "Creating Buddy dependencies.",
            category: .app
        )

        reminderManager =
            ReminderManager(
                buddyViewModel: buddyViewModel
            )

        hydrationScheduler =
            HydrationScheduler(
                storage: settingsStorage,
                developerSettingsStore:
                    developerSettingsStore,
                runtimeStore: runtimeStore,
                reminderManager: reminderManager
            )
    }

    private func connectCallbacks() {
        reminderManager.onReminderTriggered = {
            [weak self] in

            BuddyLogger.notice(
                "Showing Buddy because a reminder triggered.",
                category: .reminders
            )

            self?.showBuddyForReminder()
        }

        reminderManager.onReminderResolved = {
            [weak self] in

            BuddyLogger.debug(
                "Preparing to hide Buddy after reminder feedback.",
                category: .reminders
            )

            self?.hideBuddyAfterFeedbackDelay()
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

    private func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                wellnessSettingsDidChange(_:)
            ),
            name: .wellnessSettingsDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                reminderPauseStateDidChange(_:)
            ),
            name: .reminderPauseStateDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                showBuddyRequested(_:)
            ),
            name: .showBuddyRequested,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                hideBuddyRequested(_:)
            ),
            name: .hideBuddyRequested,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                quitBuddyRequested(_:)
            ),
            name: .quitBuddyRequested,
            object: nil
        )

        BuddyLogger.debug(
            "Started observing Buddy notifications.",
            category: .app
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

    @objc
    private func reminderPauseStateDidChange(
        _ notification: Notification
    ) {
        BuddyLogger.info(
            runtimeStore.remindersPaused
                ? "Reminder pause state changed to paused."
                : "Reminder pause state changed to active.",
            category: .scheduler
        )

        hydrationScheduler.reload()
    }

    @objc
    private func showBuddyRequested(
        _ notification: Notification
    ) {
        showBuddy()
    }

    @objc
    private func hideBuddyRequested(
        _ notification: Notification
    ) {
        hideBuddy()
    }

    @objc
    private func quitBuddyRequested(
        _ notification: Notification
    ) {
        quitBuddy()
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

        panel.contentView =
            NSHostingView(
                rootView: BuddyView(
                    viewModel: buddyViewModel,
                    animationEngine:
                        animationEngine,
                    reminderManager:
                        reminderManager
                )
            )

        positionPanelAtSavedLocation(
            panel
        )

        panel.alphaValue = 1
        panel.orderFrontRegardless()

        buddyPanel = panel

        updateBuddyVisibility(
            true
        )

        BuddyLogger.info(
            "Buddy panel was created and shown.",
            category: .app
        )
    }

    private func positionPanelAtSavedLocation(
        _ panel: BuddyPanel
    ) {
        let proposedOrigin =
            panelPositionStore.loadOrigin()
            ?? defaultPanelOrigin(
                for: panel.frame.size
            )

        setPanelOrigin(
            clampedOrigin(
                proposedOrigin,
                panelSize: panel.frame.size
            ),
            for: panel
        )
    }

    private func defaultPanelOrigin(
        for panelSize: NSSize
    ) -> NSPoint {
        let margin: CGFloat = 24

        guard let screen =
            activeScreen()
        else {
            return NSPoint(
                x: 100,
                y: 100
            )
        }

        let visibleFrame =
            screen.visibleFrame

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

    private func reminderPanelOrigin(
        for panelSize: NSSize
    ) -> NSPoint {
        let horizontalMargin: CGFloat = 24
        let verticalMargin: CGFloat = 24

        guard let screen =
            activeScreen()
        else {
            return defaultPanelOrigin(
                for: panelSize
            )
        }

        let visibleFrame =
            screen.visibleFrame

        return NSPoint(
            x:
                visibleFrame.maxX
                - panelSize.width
                - horizontalMargin,
            y:
                visibleFrame.maxY
                - panelSize.height
                - verticalMargin
        )
    }

    private func activeScreen() -> NSScreen? {
        let mouseLocation =
            NSEvent.mouseLocation

        return NSScreen.screens.first {
            NSMouseInRect(
                mouseLocation,
                $0.frame,
                false
            )
        }
        ?? NSScreen.main
        ?? NSScreen.screens.first
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
            ?? activeScreen()

        guard let targetScreen else {
            return proposedOrigin
        }

        let visibleFrame =
            targetScreen.visibleFrame

        let maximumX = max(
            visibleFrame.minX,
            visibleFrame.maxX
                - panelSize.width
        )

        let maximumY = max(
            visibleFrame.minY,
            visibleFrame.maxY
                - panelSize.height
        )

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
        hideAfterActionTask?.cancel()

        guard let buddyPanel else {
            return
        }

        let finalOrigin =
            reminderPanelOrigin(
                for: buddyPanel.frame.size
            )

        let startingOrigin = NSPoint(
            x: finalOrigin.x + 22,
            y: finalOrigin.y
        )

        buddyPanel.alphaValue = 0

        setPanelOrigin(
            startingOrigin,
            for: buddyPanel
        )

        buddyPanel.orderFrontRegardless()

        updateBuddyVisibility(
            true
        )

        NSAnimationContext.runAnimationGroup {
            context in

            context.duration = 0.26
            context.timingFunction =
                CAMediaTimingFunction(
                    name: .easeOut
                )

            buddyPanel
                .animator()
                .alphaValue = 1

            buddyPanel
                .animator()
                .setFrameOrigin(
                    finalOrigin
                )
        }

        BuddyLogger.debug(
            "Buddy reminder entered at the top-right of the active screen.",
            category: .app
        )
    }

    private func hideBuddyAfterFeedbackDelay() {
        hideAfterActionTask?.cancel()

        hideAfterActionTask =
            Task { [weak self] in
                do {
                    try await Task.sleep(
                        for: .milliseconds(1_500)
                    )
                } catch {
                    return
                }

                guard !Task.isCancelled else {
                    return
                }

                self?.hideBuddyAfterAction()
            }
    }

    private func hideBuddyAfterAction() {
        guard let buddyPanel else {
            return
        }

        NSAnimationContext.runAnimationGroup {
            context in

            context.duration = 0.20
            context.timingFunction =
                CAMediaTimingFunction(
                    name: .easeIn
                )

            buddyPanel
                .animator()
                .alphaValue = 0

            buddyPanel
                .animator()
                .setFrameOrigin(
                    NSPoint(
                        x:
                            buddyPanel.frame.origin.x
                            + 16,
                        y:
                            buddyPanel.frame.origin.y
                    )
                )
        } completionHandler: {
            [weak self] in

            Task { @MainActor in
                guard let self else {
                    return
                }

                buddyPanel.orderOut(nil)
                buddyPanel.alphaValue = 1

                self.updateBuddyVisibility(
                    false
                )
            }
        }
    }

    private func movePanelIntoVisibleScreen(
        _ panel: BuddyPanel
    ) {
        let safeOrigin =
            clampedOrigin(
                panel.frame.origin,
                panelSize: panel.frame.size
            )

        setPanelOrigin(
            safeOrigin,
            for: panel
        )
    }

    private func setPanelOrigin(
        _ origin: NSPoint,
        for panel: BuddyPanel
    ) {
        isMovingPanelProgrammatically =
            true

        panel.setFrameOrigin(
            origin
        )

        DispatchQueue.main.async {
            [weak self] in

            self?.isMovingPanelProgrammatically =
                false
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

    private func updateBuddyVisibility(
        _ isVisible: Bool
    ) {
        runtimeStore.buddyVisible =
            isVisible

        NotificationCenter.default.post(
            name: .buddyVisibilityDidChange,
            object: nil
        )
    }

    func windowDidMove(
        _ notification: Notification
    ) {
        guard !isMovingPanelProgrammatically else {
            return
        }

        saveCurrentPanelPosition()
    }

    func windowDidChangeScreen(
        _ notification: Notification
    ) {
        guard let buddyPanel else {
            return
        }

        movePanelIntoVisibleScreen(
            buddyPanel
        )

        guard !isMovingPanelProgrammatically else {
            return
        }

        saveCurrentPanelPosition()
    }

    func showBuddy() {
        hideAfterActionTask?.cancel()

        guard let buddyPanel else {
            return
        }

        positionPanelAtSavedLocation(
            buddyPanel
        )

        buddyPanel.alphaValue = 1
        buddyPanel.orderFrontRegardless()

        updateBuddyVisibility(
            true
        )

        BuddyLogger.debug(
            "Buddy was shown at its saved location.",
            category: .app
        )
    }

    func hideBuddy() {
        hideAfterActionTask?.cancel()

        saveCurrentPanelPosition()

        buddyPanel?.orderOut(nil)

        updateBuddyVisibility(
            false
        )

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

        NSApplication.shared.terminate(
            nil
        )
    }
}
