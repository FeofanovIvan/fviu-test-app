//
//  AppRoute.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import Foundation

enum AppRoute: Hashable {
    case chat
    case chatSession(UUID)
    case chatHistory
    case videoGenerator
    case videoHistory
    case videoTemplateDetail(UUID)
    case paywall
    case settings

    var requiresPremiumAccess: Bool {
        switch self {
        case .chat, .chatSession, .chatHistory, .videoGenerator, .videoHistory, .videoTemplateDetail:
            return true
        case .paywall, .settings:
            return false
        }
    }
}
