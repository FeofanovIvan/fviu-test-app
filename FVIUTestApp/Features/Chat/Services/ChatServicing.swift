import Foundation

protocol ChatServicing {
    func sendMessage(_ text: String, chatID: String, userID: String) async throws -> ChatMessage
}
