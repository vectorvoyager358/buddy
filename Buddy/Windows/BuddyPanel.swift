import AppKit

final class BuddyPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .borderless,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        configurePanel()
    }

    private func configurePanel() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        level = .floating

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]

        isMovable = true
        isMovableByWindowBackground = true

        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true

        animationBehavior = .none

        titleVisibility = .hidden
        titlebarAppearsTransparent = true
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}
