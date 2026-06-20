import Foundation

struct PaywallProduct: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let priceText: String
    let badgeText: String?

    static let defaultProducts = [
        PaywallProduct(
            id: "annual",
            title: L10n.annualPlan,
            subtitle: L10n.annualPlanSubtitle,
            priceText: "$1.27 / week",
            badgeText: L10n.bestValue
        ),
        PaywallProduct(
            id: "monthly",
            title: L10n.monthlyPlan,
            subtitle: L10n.monthlyPlanSubtitle,
            priceText: "$1.99 / week",
            badgeText: nil
        )
    ]
}
