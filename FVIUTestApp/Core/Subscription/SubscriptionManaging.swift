//
//  SubscriptionManaging.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
protocol SubscriptionManaging {
    var subscriptionUpdates: AsyncStream<Bool> { get }
    func refreshSubscriptionStatus() async -> Bool
    func loadPaywall() async throws -> Paywall
    func purchase(_ product: PaywallProduct) async throws -> Bool
    func restorePurchases() async throws -> Bool
}
