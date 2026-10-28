import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var editor = MathEditor()
    @State private var selectedTab: KeyboardTab = .numbers
    @State private var isKeyboardVisible = true

    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 0) {
            MathDisplayView(onTap: showKeyboard)
                .padding(.horizontal, Theme.displayHorizontalMargin)
                .padding(.top, Theme.displayTopPadding)

            if let result = editor.resultText {
                Text(result)
                    .font(Theme.mathFont(22))
                    .foregroundStyle(Theme.resultText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.displayHorizontalMargin)
                    .padding(.top, 14)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            if isKeyboardVisible {
                MathKeyboardView(selectedTab: $selectedTab, onAction: handle)
                    .transition(.move(edge: .bottom))
            } else {
                showKeyboardButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The reference design runs the keys to the bottom edge of the screen.
        .ignoresSafeArea(.container, edges: .bottom)
        .background(Theme.background.ignoresSafeArea())
        .environmentObject(editor)
        .animation(.easeOut(duration: 0.2), value: editor.resultText)
    }

    private var showKeyboardButton: some View {
        HStack {
            Spacer()
            Button(action: showKeyboard) {
                Image(systemName: "keyboard")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.lightText)
                    .frame(width: 56, height: 44)
                    .background(Theme.controlKey, in: RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityLabel("Show keyboard")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 44)
    }

    private func showKeyboard() {
        guard !isKeyboardVisible else { return }
        withAnimation(.easeOut(duration: 0.25)) { isKeyboardVisible = true }
    }

    private func handle(_ action: KeyAction) {
        haptics.impactOccurred()

        switch action {
        case .symbol(let s):        editor.insertSymbol(s)
        case .function(let name):   editor.insertFunction(name)
        case .structure(let kind):  editor.insertStructure(kind)
        case .moveLeft:             editor.moveLeft()
        case .moveRight:            editor.moveRight()
        case .backspace:            editor.backspace()
        case .enter:                editor.submit()
        case .hideKeyboard:
            withAnimation(.easeOut(duration: 0.25)) { isKeyboardVisible = false }
        case .toggleShift:
            break // handled inside LetterKeyboardView
        }
    }
}

#Preview {
    ContentView()
}
