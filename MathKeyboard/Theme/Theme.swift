import SwiftUI

/// Colors, fonts and metrics sampled from the reference screens.
enum Theme {
    // MARK: Colors
    static let background      = Color.white
    static let displayFill     = Color(hex: 0xF0F0F2)
    static let tabBar          = Color(hex: 0xC3C3C3)
    static let gridLine        = Color.white

    static let variableKey     = Color(hex: 0x2E4A8B) // navy  – x, y, fraction, power
    static let numberKey       = Color(hex: 0xEAEAEA) // light – digits
    static let operatorKey     = Color(hex: 0xEBD18A) // yellow – ÷ × − +
    static let functionKey     = Color(hex: 0x9DD18F) // green  – sin cos …
    static let controlKey      = Color(hex: 0x96A1AA) // slate  – ⌫ Enter hide

    static let darkText        = Color.black
    static let lightText       = Color.white
    static let resultText      = Color(hex: 0x6B6B70)
    static let cursor          = Color(hex: 0x2E6BE6)
    static let placeholder     = Color(hex: 0x8E8E93)

    // MARK: Metrics
    static let keyHeight: CGFloat = 56
    static let tabBarHeight: CGFloat = 57
    static let gridSpacing: CGFloat = 1.2
    static let displayHeight: CGFloat = 48
    static let displayHorizontalMargin: CGFloat = 19
    static let displayTopPadding: CGFloat = 70
    static let expressionFontSize: CGFloat = 30

    // MARK: Fonts
    /// Thin sans-serif used for key and tab labels (matches the screenshots).
    static func keyFont(_ size: CGFloat = 24) -> Font {
        .custom("HelveticaNeue-Light", size: size)
    }

    /// Serif face used for the expression and for math glyphs on keys.
    static func mathFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
