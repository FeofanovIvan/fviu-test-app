//
//  ChatHistoryStoring.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

@MainActor
protocol ChatHistoryStoring {
    var sessions: [ChatSession] { get }
    func session(id: UUID) -> ChatSession?
    func upsert(_ session: ChatSession)
    func deleteSession(id: UUID)
}
