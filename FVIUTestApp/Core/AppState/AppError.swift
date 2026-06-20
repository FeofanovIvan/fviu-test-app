import Foundation

struct AppError: Error, Equatable, Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoveryActionTitle: String?

    init(title: String, message: String, recoveryActionTitle: String? = L10n.tryAgain) {
        self.title = title
        self.message = message
        self.recoveryActionTitle = recoveryActionTitle
    }

    static let subscriptionRequired = AppError(
        title: L10n.premiumRequiredTitle,
        message: L10n.premiumRequiredMessage,
        recoveryActionTitle: L10n.openPaywall
    )

    static let unknown = AppError(
        title: L10n.genericErrorTitle,
        message: L10n.genericErrorMessage
    )
}
