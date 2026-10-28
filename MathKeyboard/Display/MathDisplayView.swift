import SwiftUI

/// The grey input box at the top of the screen.
struct MathDisplayView: View {
    @EnvironmentObject private var editor: MathEditor
    var onTap: () -> Void = {}

    @State private var boxWidth: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            MathRowView(row: editor.root, fontSize: Theme.expressionFontSize, showsPlaceholder: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(minWidth: boxWidth, minHeight: Theme.displayHeight)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.displayFill)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { boxWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newWidth in boxWidth = newWidth }
            }
        )
        .simultaneousGesture(TapGesture().onEnded { onTap() })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Expression")
        .accessibilityValue(editor.isEmpty ? "Empty" : "Editing")
    }
}
