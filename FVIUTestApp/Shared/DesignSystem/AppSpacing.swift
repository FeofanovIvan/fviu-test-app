import UIKit

enum AppSpacing {
    static let tiny: CGFloat = 4
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let screen: CGFloat = 20
}

enum ScreenScale {
    static let referenceWidth: CGFloat = 390
    static let referenceHeight: CGFloat = 844

    static var width: CGFloat {
        UIScreen.main.bounds.width / referenceWidth
    }

    static var bounded: CGFloat {
        min(width, UIScreen.main.bounds.height / referenceHeight, 1)
    }
}
