import Foundation

struct Paywall: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let products: [PaywallProduct]
}
