//
//  ChatViewModel.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var draft = ""
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var state: LoadableState<[ChatMessage]> = .idle

    private let chatService: ChatServicing
    private weak var appState: AppState?
    private let subscriptionManager: SubscriptionManaging
    private let historyStore: ChatHistoryStoring
    private let userID: String
    private var sessionID: UUID
    private var sessionTitle: String?

    init(
        chatService: ChatServicing,
        appState: AppState,
        subscriptionManager: SubscriptionManaging,
        historyStore: ChatHistoryStoring,
        sessionID: UUID? = nil,
        userID: String = UUID().uuidString
    ) {
        self.chatService = chatService
        self.appState = appState
        self.subscriptionManager = subscriptionManager
        self.historyStore = historyStore
        self.userID = userID

        if let sessionID, let session = historyStore.session(id: sessionID) {
            self.sessionID = session.id
            self.sessionTitle = session.title
            self.messages = session.messages
        } else {
            self.sessionID = UUID()
            self.messages = [
                ChatMessage(role: .assistant, text: L10n.chatWelcomeMessage)
            ]
        }

        self.state = .success(messages)
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !state.isLoading
    }

    func openHistory() {
        appState?.navigateToPremiumRoute(.chatHistory)
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let hasAccess = await subscriptionManager.refreshSubscriptionStatus() || (appState?.hasPremiumAccess ?? false)
        guard hasAccess else {
            appState?.presentPaywall()
            return
        }

        draft = ""
        messages.append(ChatMessage(role: .user, text: text))
        state = .loading
        persistSession()

        do {
            let answer = try await chatService.sendMessage(text, chatID: sessionID.uuidString, userID: userID)
            messages.append(answer)
            state = .success(messages)
            persistSession()
        } catch let error as AppError {
            state = .error(error)
            persistSession()
        } catch {
            state = .error(.unknown)
            persistSession()
        }
    }

    private func persistSession() {
        let userMessages = messages.filter { $0.role == .user }
        guard !userMessages.isEmpty else { return }

        let title = sessionTitle ?? makeTitle(from: userMessages[0].text)
        sessionTitle = title

        historyStore.upsert(
            ChatSession(
                id: sessionID,
                title: title,
                messages: messages,
                createdAt: messages.first?.createdAt ?? .now,
                updatedAt: .now
            )
        )
    }

    private func makeTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 42 else { return trimmed }
        return String(trimmed.prefix(39)) + "..."
    }
}
