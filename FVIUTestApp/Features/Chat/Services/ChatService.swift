//
//  ChatService.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

final class ChatService: ChatServicing {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func sendMessage(_ text: String, chatID: String, userID: String) async throws -> ChatMessage {
        let endpoint = Endpoint(
            baseURL: AppConfig.chatBaseURL,
            path: "/dola/chats/\(chatID)/messages",
            method: .post,
            headers: [
                "Accept-Language": "en"
            ],
            queryItems: [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "app_id", value: AppConfig.apiApplicationID),
                URLQueryItem(name: "locale", value: "en")
            ],
            body: ChatRequest(message: text)
        )

        do {
            let response = try await networkClient.request(endpoint, as: ChatResponse.self)
            return ChatMessage(role: .assistant, text: response.displayText)
        } catch let error as NetworkError {
            throw error.appError
        } catch {
            throw AppError.unknown
        }
    }
}
