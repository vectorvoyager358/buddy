import Foundation
import Combine

@MainActor
final class AnimationEngine: ObservableObject {
    @Published private(set) var currentAnimation: BuddyAnimation = .idle

    private var returnToIdleTask: Task<Void, Never>?

    func play(_ animation: BuddyAnimation) {
        cancelPendingReturn()

        currentAnimation = animation
    }

    func play(
        _ animation: BuddyAnimation,
        for duration: TimeInterval
    ) {
        play(animation)

        returnToIdleTask = Task { [weak self] in
            try? await Task.sleep(
                for: .seconds(duration)
            )

            guard !Task.isCancelled else {
                return
            }

            self?.currentAnimation = .idle
        }
    }

    func stop() {
        cancelPendingReturn()

        currentAnimation = .idle
    }

    private func cancelPendingReturn() {
        returnToIdleTask?.cancel()
        returnToIdleTask = nil
    }
}
