import SwiftUI

/// A single rectangular key in the grid.
struct KeyButton: View {
    let key: KeyDefinition
    var height: CGFloat = Theme.keyHeight
    let onPress: (KeyAction) -> Void

    var body: some View {
        Button {
            onPress(key.action)
        } label: {
            KeyLabelView(label: key.label, color: key.style.foreground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(KeyPressStyle(background: key.style.background))
        .frame(height: height)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch key.label {
        case .text(let s), .math(let s), .variable(let s): return s
        case .icon(let icon):
            switch icon {
            case .fraction: return "Fraction"
            case .power: return "Power"
            case .subscripted: return "Subscript"
            case .squareRoot: return "Square root"
            case .nthRoot: return "Nth root"
            case .logBase: return "Log with base"
            case .absoluteValue: return "Absolute value"
            case .backspace: return "Delete"
            case .hideKeyboard: return "Hide keyboard"
            case .shift: return "Shift"
            case .arrowLeft: return "Move cursor left"
            case .arrowRight: return "Move cursor right"
            }
        }
    }
}

/// Renders a key's label in the right typeface.
struct KeyLabelView: View {
    let label: KeyLabel
    let color: Color

    var body: some View {
        switch label {
        case .text(let s):
            Text(s)
                .font(Theme.keyFont(24))
                .foregroundStyle(color)
        case .math(let s):
            Text(s)
                .font(Theme.mathFont(24, weight: .semibold))
                .foregroundStyle(color)
        case .variable(let s):
            Text(s)
                .font(Theme.mathFont(25, weight: .bold))
                .italic()
                .foregroundStyle(color)
        case .icon(let icon):
            KeyIconView(icon: icon, color: color)
        }
    }
}

/// Flat key background that darkens slightly while pressed.
struct KeyPressStyle: ButtonStyle {
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(background)
            .overlay(Color.black.opacity(configuration.isPressed ? 0.14 : 0))
    }
}
