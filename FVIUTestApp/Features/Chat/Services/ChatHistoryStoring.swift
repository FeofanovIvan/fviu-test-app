import Foundation

@MainActor
protocol ChatHistoryStoring {
    var sessions: [ChatSession] { get }
    func session(id: UUID) -> ChatSession?
    func upsert(_ session: ChatSession)
    func deleteSession(id: UUID)
}
