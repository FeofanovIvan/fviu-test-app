import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var restoreState: LoadableState<Bool> = .idle

    private let subscriptionManager: SubscriptionManaging
    private weak var appState: AppState?

    init(subscriptionManager: SubscriptionManaging, appState: AppState) {
        self.subscriptionManager = subscriptionManager
        self.appState = appState
    }

    var hasPremiumAccess: Bool {
        appState?.hasPremiumAccess ?? false
    }

    func openPaywall() {
        appState?.presentPaywall()
    }

    func restorePurchases() async {
        restoreState = .loading

        do {
            let hasAccess = try await subscriptionManager.restorePurchases()
            appState?.updatePremiumAccess(hasAccess)
            restoreState = .success(hasAccess)

            if hasAccess {
                appState?.handlePremiumAccessGranted()
            }
        } catch {
            restoreState = .error(AppError(title: L10n.restoreErrorTitle, message: L10n.restoreErrorMessage))
        }
    }
}
