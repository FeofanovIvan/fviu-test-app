import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<Paywall> = .idle
    @Published var selectedProduct: PaywallProduct?
    @Published private(set) var purchaseState: LoadableState<Bool> = .idle

    private let subscriptionManager: SubscriptionManaging
    private weak var appState: AppState?

    init(subscriptionManager: SubscriptionManaging, appState: AppState) {
        self.subscriptionManager = subscriptionManager
        self.appState = appState
    }

    func load() async {
        state = .loading

        do {
            let paywall = try await subscriptionManager.loadPaywall()
            let displayPaywall = paywall.products.isEmpty
                ? Paywall(id: paywall.id, title: paywall.title, subtitle: paywall.subtitle, products: PaywallProduct.defaultProducts)
                : paywall
            selectedProduct = displayPaywall.products.first(where: { $0.badgeText != nil }) ?? displayPaywall.products.first
            state = .success(displayPaywall)
        } catch {
            #if DEBUG
            debugPrint("Paywall loading failed. Showing fallback products. Error:", error)
            #endif

            let fallbackPaywall = Paywall(
                id: AppConfig.apphudPaywallID,
                title: L10n.paywallTitle,
                subtitle: L10n.paywallSubtitle,
                products: PaywallProduct.defaultProducts
            )
            selectedProduct = fallbackPaywall.products.first(where: { $0.badgeText != nil }) ?? fallbackPaywall.products.first
            state = .success(fallbackPaywall)
        }
    }

    func select(_ product: PaywallProduct) {
        selectedProduct = product
    }

    func purchaseSelectedProduct() async {
        guard let selectedProduct else { return }
        purchaseState = .loading

        do {
            let hasAccess = try await subscriptionManager.purchase(selectedProduct)
            appState?.updatePremiumAccess(hasAccess)
            purchaseState = .success(hasAccess)

            if hasAccess {
                appState?.handlePremiumAccessGranted()
            }
        } catch {
            purchaseState = .error(AppError(title: L10n.purchaseErrorTitle, message: L10n.purchaseErrorMessage))
        }
    }

    func restorePurchases() async {
        purchaseState = .loading

        do {
            let hasAccess = try await subscriptionManager.restorePurchases()
            appState?.updatePremiumAccess(hasAccess)
            purchaseState = .success(hasAccess)

            if hasAccess {
                appState?.handlePremiumAccessGranted()
            }
        } catch {
            purchaseState = .error(AppError(title: L10n.restoreErrorTitle, message: L10n.restoreErrorMessage))
        }
    }

    func close() {
        appState?.dismissPaywall()
    }
}
