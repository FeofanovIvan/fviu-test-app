//
//  AppState.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var navigationPath: [AppRoute] = []
    @Published var isPaywallPresented = false
    @Published var hasPremiumAccess = false
    private var pendingPremiumRoute: AppRoute?

    func navigate(to route: AppRoute) {
        guard !route.requiresPremiumAccess || hasPremiumAccess else {
            presentPaywall(afterPurchase: route)
            return
        }

        navigationPath.append(route)
    }

    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func navigateToPremiumRoute(_ route: AppRoute) {
        navigate(to: route)
    }

    func presentPaywall(afterPurchase route: AppRoute? = nil) {
        if let route {
            pendingPremiumRoute = route
        }
        isPaywallPresented = true
    }

    func dismissPaywall() {
        isPaywallPresented = false
    }

    func updatePremiumAccess(_ isActive: Bool) {
        hasPremiumAccess = isActive
    }

    func handlePremiumAccessGranted() {
        hasPremiumAccess = true
        isPaywallPresented = false

        if let pendingPremiumRoute {
            self.pendingPremiumRoute = nil
            navigationPath.append(pendingPremiumRoute)
        }
    }

    func handlePremiumAccessRevoked() {
        hasPremiumAccess = false
        pendingPremiumRoute = nil
        navigationPath.removeAll { $0.requiresPremiumAccess }
    }
}
