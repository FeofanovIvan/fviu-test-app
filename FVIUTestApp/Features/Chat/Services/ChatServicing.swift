//
//  ChatServicing.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

protocol ChatServicing {
    func sendMessage(_ text: String, chatID: String, userID: String) async throws -> ChatMessage
}
