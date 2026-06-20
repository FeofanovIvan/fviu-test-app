import Foundation

enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(statusCode: Int)
    case decodingFailed
    case transport(String)

    var appError: AppError {
        switch self {
        case .unauthorized:
            return AppError(title: L10n.networkAuthErrorTitle, message: L10n.networkAuthErrorMessage)
        case .server:
            return AppError(title: L10n.networkServerErrorTitle, message: L10n.networkServerErrorMessage)
        case .transport:
            return AppError(title: L10n.networkConnectionErrorTitle, message: L10n.networkConnectionErrorMessage)
        case .decodingFailed, .invalidResponse, .invalidURL:
            return AppError(title: L10n.genericErrorTitle, message: L10n.genericErrorMessage)
        }
    }
}
