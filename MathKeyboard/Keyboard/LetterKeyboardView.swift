import SwiftUI

/// QWERTY page shown for the "abc" tab. Not part of the reference screens —
/// styled to match the rest of the keyboard and kept the same height.
struct LetterKeyboardView: View {
    let onAction: (KeyAction) -> Void
    @State private var isShifted = false

    private let spacing = Theme.gridSpacing
    private let keyHeight = Theme.keyHeight

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let unit = max(0, (width - spacing * 9) / 10)
            let sideKey = max(0, (width - unit * 7 - spacing * 8) / 2)

            VStack(spacing: spacing) {
                letterRow(KeyLayouts.letterRows[0], unit: unit)
                letterRow(KeyLayouts.letterRows[1], unit: unit)

                HStack(spacing: spacing) {
                    KeyButton(key: shiftKey, height: keyHeight) { _ in isShifted.toggle() }
                        .frame(width: sideKey)
                    letterKeys(KeyLayouts.letterRows[2], unit: unit)
                    KeyButton(key: .init("backspace", .icon(.backspace), .backspace, .control),
                              height: keyHeight, onPress: onAction)
                        .frame(width: sideKey)
                }

                HStack(spacing: spacing) {
                    KeyButton(key: .init("hide", .icon(.hideKeyboard), .hideKeyboard, .control),
                              height: keyHeight, onPress: onAction)
                        .frame(width: sideKey)
                    KeyButton(key: .init("space", .text("space"), .symbol(" "), .number),
                              height: keyHeight, onPress: onAction)
                    KeyButton(key: .init("enter", .text("Enter"), .enter, .control),
                              height: keyHeight, onPress: onAction)
                        .frame(width: sideKey * 1.6)
                }
            }
            .frame(width: width)
        }
        .frame(height: keyHeight * 4 + spacing * 3)
    }

    private var shiftKey: KeyDefinition {
        .init("shift", .icon(.shift), .toggleShift, isShifted ? .number : .control)
    }

    private func letterRow(_ letters: [String], unit: CGFloat) -> some View {
        HStack(spacing: spacing) {
            letterKeys(letters, unit: unit)
        }
        .frame(maxWidth: .infinity)
    }

    private func letterKeys(_ letters: [String], unit: CGFloat) -> some View {
        ForEach(letters, id: \.self) { letter in
            let glyph = isShifted ? letter.uppercased() : letter
            KeyButton(key: .init("l-\(letter)", .text(glyph), .symbol(glyph), .number),
                      height: keyHeight) { action in
                onAction(action)
                isShifted = false
            }
            .frame(width: unit)
        }
    }
}
