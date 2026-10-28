import SwiftUI

/// The custom keyboard: tab bar + key grid (or QWERTY on the abc page).
struct MathKeyboardView: View {
    @Binding var selectedTab: KeyboardTab
    let onAction: (KeyAction) -> Void

    private let spacing = Theme.gridSpacing
    private let keyHeight = Theme.keyHeight

    private let backspaceKey = KeyDefinition("backspace", .icon(.backspace), .backspace, .control)
    private let enterKey = KeyDefinition("enter", .text("Enter"), .enter, .control)
    private let hideKey = KeyDefinition("hide", .icon(.hideKeyboard), .hideKeyboard, .control)

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            Group {
                if selectedTab == .letters {
                    LetterKeyboardView(onAction: onAction)
                } else {
                    keyGrid
                }
            }
            .padding(.top, spacing)
            .padding(.horizontal, spacing)
            .background(Theme.gridLine)
        }
    }

    // MARK: Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(KeyboardTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(Theme.keyFont(25))
                        .foregroundStyle(Theme.darkText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(selectedTab == tab ? tab.selectedChipColor : Color.clear)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .frame(height: Theme.tabBarHeight)
        .background(Theme.tabBar)
    }

    // MARK: 6-column grid (x/y column · 4×4 page · control column)

    private var keyGrid: some View {
        let rows = KeyLayouts.centerRows(for: selectedTab)

        return HStack(spacing: spacing) {
            column(KeyLayouts.leftColumn)

            ForEach(0..<4, id: \.self) { col in
                column(rows.map { $0[col] })
            }

            VStack(spacing: spacing) {
                KeyButton(key: backspaceKey, height: keyHeight, onPress: onAction)
                KeyButton(key: enterKey, height: keyHeight * 2 + spacing, onPress: onAction)
                KeyButton(key: hideKey, height: keyHeight, onPress: onAction)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: keyHeight * 4 + spacing * 3)
    }

    private func column(_ keys: [KeyDefinition]) -> some View {
        VStack(spacing: spacing) {
            ForEach(keys) { key in
                KeyButton(key: key, height: keyHeight, onPress: onAction)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    struct Wrapper: View {
        @State var tab: KeyboardTab = .functions
        var body: some View {
            VStack {
                Spacer()
                MathKeyboardView(selectedTab: $tab) { _ in }
            }
        }
    }
    return Wrapper()
}
