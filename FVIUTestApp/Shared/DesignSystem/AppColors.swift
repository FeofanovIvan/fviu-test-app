//
//  AppColors.swift
//  FVIUTestApp
//
//  Created by Ivan Feofanov on 20/06/26.
//
import SwiftUI

enum AppColors {
    static let screenBackground = Color(red: 0.04, green: 0.03, blue: 0.06)
    static let cardBackground = Color.white.opacity(0.08)
    static let elevatedBackground = Color.white.opacity(0.12)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.68)
    static let mutedText = Color.white.opacity(0.42)
    static let accent = Color(red: 1.0, green: 0.22, blue: 0.78)
    static let success = Color(red: 0.33, green: 0.86, blue: 0.52)
    static let warning = Color(red: 1.0, green: 0.76, blue: 0.28)
    static let error = Color(red: 1.0, green: 0.32, blue: 0.38)
    static let border = Color.white.opacity(0.14)

    // Figma "glass" surfaces used on Home/Paywall cards.
    static let glassDark = Color(red: 0x1F / 255.0, green: 0x19 / 255.0, blue: 0x1F / 255.0)
    static let glassDarkLight = Color(red: 0.122, green: 0.098, blue: 0.122).opacity(0.4)
    static let glassWhite = Color.white.opacity(0.15)
    static let glassWhiteLight = Color.white.opacity(0.05)
    static let gradientBlue = Color(red: 0.596, green: 0.776, blue: 0.969)
    static let gradientPink = Color(red: 0.922, green: 0.357, blue: 0.573)

    static let chatHighlight = Color(red: 0.73, green: 0.65, blue: 0.95)

    static let chatAssistantBubble = Color(red: 0x1F / 255.0, green: 0x19 / 255.0, blue: 0x1F / 255.0).opacity(0.5)

    static let historyCardBackground = Color(red: 0x1F / 255.0, green: 0x19 / 255.0, blue: 0x1F / 255.0).opacity(0x66 / 255.0)
}
