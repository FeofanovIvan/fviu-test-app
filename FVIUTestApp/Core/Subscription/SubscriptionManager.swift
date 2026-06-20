import Foundation

final class SubscriptionManager: SubscriptionManaging {
    private let apphudManager: ApphudManaging

    var subscriptionUpdates: AsyncStream<Bool> {
        apphudManager.subscriptionUpdates
    }

    init(apphudManager: ApphudManaging) {
        self.apphudManager = apphudManager
    }

    func refreshSubscriptionStatus() async -> Bool {
        await apphudManager.hasActiveSubscription()
    }

    func loadPaywall() async throws -> Paywall {
        try await apphudManager.fetchPaywall(identifier: AppConfig.apphudPaywallID)
    }

    func purchase(_ product: PaywallProduct) async throws -> Bool {
        try await apphudManager.purchase(product: product)
    }

    func restorePurchases() async throws -> Bool {
        try await apphudManager.restorePurchases()
    }
}
