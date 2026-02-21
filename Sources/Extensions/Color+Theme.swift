//
//  Color+Theme.swift
//  habla-ios
//

import SwiftUI
import UIKit

extension Color {
    static let appBackground = Color.dynamic(
        light: UIColor(red: 247/255, green: 248/255, blue: 250/255, alpha: 1.0),
        dark: UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1.0)
    )
    static let appSurface = Color.dynamic(
        light: UIColor.white,
        dark: UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1.0)
    )
    static let appAccent = Color(red: 74/255, green: 222/255, blue: 128/255)
    static let appAgentAccent = Color(red: 129/255, green: 140/255, blue: 248/255)
    static let appDestructive = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let appTextPrimary = Color.dynamic(
        light: UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1.0),
        dark: UIColor.white
    )
    static let appTextSecondary = Color.dynamic(
        light: UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1.0),
        dark: UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1.0)
    )
    static let appKeypad = Color.dynamic(
        light: UIColor.white,
        dark: UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1.0)
    )
}

private extension Color {
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
