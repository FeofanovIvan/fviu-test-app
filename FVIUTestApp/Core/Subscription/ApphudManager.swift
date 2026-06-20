import Foundation
import StoreKit

#if canImport(ApphudSDK)
import ApphudSDK
#endif

@MainActor
final class ApphudManager: ApphudManaging {
    private var isConfigured = false
    #if canImport(ApphudSDK)
    private var cachedProducts: [String: ApphudProduct] = [:]
    private var cachedPaywalls: [String: ApphudPaywall] = [:]
    #endif

    var subscriptionUpdates: AsyncStream<Bool> {
        AsyncStream { continuation in
            #if canImport(ApphudSDK)
            let observer = NotificationCenter.default.addObserver(
                forName: Apphud.didUpdateNotification(),
                object: nil,
                queue: .main
            ) { _ in
                continuation.yield(Apphud.hasPremiumAccess() || Apphud.hasActiveSubscription())
            }

            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
            #else
            continuation.finish()
            #endif
        }
    }

    func configure(apiKey: String) async {
        guard !isConfigured else { return }

        #if canImport(ApphudSDK)
        Apphud.start(apiKey: apiKey)
        #endif

        isConfigured = true
    }

    func fetchPaywall(identifier: String) async throws -> Paywall {
        #if canImport(ApphudSDK)
        let apphudPaywall = try await loadApphudPaywall(identifier: identifier)
        cachedPaywalls[identifier] = apphudPaywall
        apphudPaywall.products.forEach { product in
            cachedProducts[product.productId] = product
        }
        Apphud.paywallShown(apphudPaywall)

        let products = apphudPaywall.products.prefix(2).enumerated().map { index, product in
            mapProduct(product, index: index)
        }

        if !products.isEmpty {
            return Paywall(
                id: apphudPaywall.identifier,
                title: L10n.paywallTitle,
                subtitle: L10n.paywallSubtitle,
                products: products
            )
        }
        #endif

        return Paywall(
            id: identifier,
            title: L10n.paywallTitle,
            subtitle: L10n.paywallSubtitle,
            products: PaywallProduct.defaultProducts
        )
    }

    func hasActiveSubscription() async -> Bool {
        #if canImport(ApphudSDK)
        return Apphud.hasPremiumAccess() || Apphud.hasActiveSubscription()
        #else
        return false
        #endif
    }

    func purchase(product: PaywallProduct) async throws -> Bool {
        #if canImport(ApphudSDK)
        guard let apphudProduct = cachedProducts[product.id] else {
            throw AppError(title: L10n.purchaseErrorTitle, message: L10n.purchaseErrorMessage)
        }

        let result = await Apphud.purchase(apphudProduct)
        if let error = result.error {
            throw error
        }

        return await hasActiveSubscription()
        #else
        try await Task.sleep(nanoseconds: 700_000_000)
        return true
        #endif
    }

    func restorePurchases() async throws -> Bool {
        #if canImport(ApphudSDK)
        if let error = await Apphud.restorePurchases() {
            throw error
        }

        return await hasActiveSubscription()
        #else
        try await Task.sleep(nanoseconds: 500_000_000)
        return await hasActiveSubscription()
        #endif
    }
}

#if canImport(ApphudSDK)
private extension ApphudManager {
    func loadApphudPaywall(identifier: String) async throws -> ApphudPaywall {
        try await withCheckedThrowingContinuation { continuation in
            Apphud.fetchPlacements { placements, error in
                let placementPaywall = placements.first(where: { $0.identifier == identifier })?.paywall
                let matchingPaywall = placements.compactMap(\.paywall).first(where: { $0.identifier == identifier })

                if let paywall = placementPaywall ?? matchingPaywall {
                    continuation.resume(returning: paywall)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(
                        throwing: AppError(
                            title: L10n.paywallLoadErrorTitle,
                            message: L10n.paywallLoadErrorMessage
                        )
                    )
                }
            }
        }
    }

    func mapProduct(_ product: ApphudProduct, index: Int) -> PaywallProduct {
        let displayPlan = displayPlan(for: product.productId, index: index)
        let title = displayPlan.title
        let price = displayPlan.priceText
        let subtitle = displayPlan.subtitle
        let badge = index == 0 ? L10n.bestValue : nil

        return PaywallProduct(
            id: product.productId,
            title: title,
            subtitle: subtitle,
            priceText: price,
            badgeText: badge
        )
    }

    func displayPlan(for productID: String, index: Int) -> PaywallProduct {
        return index == 0
            ? PaywallProduct(id: productID, title: L10n.annualPlan, subtitle: L10n.annualPlanSubtitle, priceText: "$1.27 / week", badgeText: nil)
            : PaywallProduct(id: productID, title: L10n.monthlyPlan, subtitle: L10n.monthlyPlanSubtitle, priceText: "$1.99 / week", badgeText: nil)
    }

    func billingDescription(for product: SKProduct) -> String {
        guard let period = product.subscriptionPeriod else {
            return product.localizedDescription
        }

        let unit: String
        switch period.unit {
        case .day:
            unit = period.numberOfUnits == 1 ? "day" : "days"
        case .week:
            unit = period.numberOfUnits == 1 ? "week" : "weeks"
        case .month:
            unit = period.numberOfUnits == 1 ? "month" : "months"
        case .year:
            unit = period.numberOfUnits == 1 ? "year" : "years"
        @unknown default:
            unit = "period"
        }

        return "Billed every \(period.numberOfUnits) \(unit)"
    }
}
#endif
