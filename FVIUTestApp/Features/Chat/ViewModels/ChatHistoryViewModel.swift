import Foundation

@MainActor
final class ChatHistoryViewModel: ObservableObject {
    @Published private(set) var sessions: [ChatSession] = []

    private let historyStore: ChatHistoryStoring
    private weak var appState: AppState?

    init(historyStore: ChatHistoryStoring, appState: AppState) {
        self.historyStore = historyStore
        self.appState = appState
        reload()
    }

    var hasSessions: Bool {
        !sessions.isEmpty
    }

    func reload() {
        sessions = historyStore.sessions
    }

    func open(_ session: ChatSession) {
        appState?.navigateToPremiumRoute(.chatSession(session.id))
    }

    func delete(_ session: ChatSession) {
        historyStore.deleteSession(id: session.id)
        reload()
    }
}
