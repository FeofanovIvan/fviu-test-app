import Combine
import SwiftUI
import UIKit

/// Tracks the on-screen keyboard's height via `UIResponder` notifications.
///
/// SwiftUI's automatic keyboard-avoidance (the system safe-area inset) turned out to be
/// unreliable for the chat input bar in this app: after navigating to Chat History and back,
/// or right when a focus change is triggered programmatically, the system inset sometimes
/// settles at zero height, leaving the input bar rendered behind/under the keyboard. Driving
/// the input bar's bottom padding manually from real keyboard-frame notifications sidesteps
/// that system-avoidance bug entirely, since it never depends on the navigation/focus timing.
@MainActor
final class KeyboardObserver: ObservableObject {
    @Published private(set) var height: CGFloat = 0

    private var cancellables: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                withAnimation(.easeOut(duration: 0.25)) {
                    self?.height = height
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    self?.height = 0
                }
            }
            .store(in: &cancellables)
    }
}
