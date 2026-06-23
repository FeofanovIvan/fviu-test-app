//
//  ApphudManaging.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
protocol ApphudManaging {
    var subscriptionUpdates: AsyncStream<Bool> { get }
    func configure(apiKey: String) async
    func fetchPaywall(identifier: String) async throws -> Paywall
    func hasActiveSubscription() async -> Bool
    func purchase(product: PaywallProduct) async throws -> Bool
    func restorePurchases() async throws -> Bool
}
