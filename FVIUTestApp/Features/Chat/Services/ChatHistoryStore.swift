//
//  ChatHistoryStore.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
final class ChatHistoryStore: ObservableObject, ChatHistoryStoring {
    @Published private(set) var sessions: [ChatSession] = []

    private let storageKey = "chat.history.sessions.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    func session(id: UUID) -> ChatSession? {
        sessions.first(where: { $0.id == id })
    }

    func upsert(_ session: ChatSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }

        sessions.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        sessions = (try? decoder.decode([ChatSession].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? encoder.encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
