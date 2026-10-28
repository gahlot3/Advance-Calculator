import SwiftUI

/// Renders one row of the expression tree, including the cursor and empty-slot placeholder.
struct MathRowView: View {
    @EnvironmentObject private var editor: MathEditor

    let row: MathRow
    let fontSize: CGFloat
    /// Draw a □ when the row is empty (off for function arguments and the root row).
    var showsPlaceholder = true

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(row.nodes.enumerated()), id: \.element.id) { index, node in
                HStack(spacing: 0) {
                    if editor.isCursor(in: row, at: index) {
                        BlinkingCursor(height: fontSize * 1.1)
                    }
                    MathNodeView(
                        node: node,
                        previous: index > 0 ? row.nodes[index - 1] : nil,
                        fontSize: fontSize
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { editor.setCursor(row: row, index: index + 1) }
                }
            }

            if row.isEmpty {
                if showsPlaceholder {
                    SlotBox(size: fontSize * 0.62, color: Theme.placeholder, lineWidth: 1)
                        .padding(.horizontal, 2)
                        .overlay(alignment: .leading) {
                            if editor.isCursor(in: row) {
                                BlinkingCursor(height: fontSize * 0.9)
                            }
                        }
                } else if editor.isCursor(in: row) {
                    BlinkingCursor(height: fontSize * 1.1)
                }
            } else if editor.isCursor(in: row, at: row.count) {
                BlinkingCursor(height: fontSize * 1.1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editor.setCursor(row: row, index: row.count) }
    }
}

/// Renders a single node (symbol or structure).
struct MathNodeView: View {
    let node: MathNode
    /// The node immediately to the left — a superscript/subscript without one shows a □ base.
    let previous: MathNode?
    let fontSize: CGFloat

    private var lineWidth: CGFloat { max(1, fontSize * 0.045) }
    private var ink: Color { Theme.darkText }

    var body: some View {
        switch node.kind {
        case .symbol(let symbol):
            SymbolView(symbol: symbol, fontSize: fontSize)

        case .function(let name):
            HStack(spacing: 0) {
                Text(name).font(Theme.mathFont(fontSize)).foregroundStyle(ink)
                parenthesized(node.rows[0], showsPlaceholder: false)
            }

        case .fraction:
            Grid(horizontalSpacing: 0, verticalSpacing: fontSize * 0.1) {
                GridRow { MathRowView(row: node.rows[0], fontSize: nested(0.8)) }
                Rectangle()
                    .fill(ink)
                    .frame(height: lineWidth)
                    .gridCellUnsizedAxes(.horizontal)
                GridRow { MathRowView(row: node.rows[1], fontSize: nested(0.8)) }
            }
            .padding(.horizontal, fontSize * 0.1)

        case .superscript:
            HStack(alignment: .center, spacing: 0) {
                if needsBase { basePlaceholderBox }
                VStack(spacing: 0) {
                    MathRowView(row: node.rows[0], fontSize: nested(0.6))
                    Color.clear.frame(width: 0, height: fontSize * 0.5)
                }
                .padding(.leading, 1)
            }

        case .subscripted:
            HStack(alignment: .center, spacing: 0) {
                if needsBase { basePlaceholderBox }
                VStack(spacing: 0) {
                    Color.clear.frame(width: 0, height: fontSize * 0.5)
                    MathRowView(row: node.rows[0], fontSize: nested(0.6))
                }
                .padding(.leading, 1)
            }

        case .squareRoot:
            radical(node.rows[0])

        case .nthRoot:
            HStack(alignment: .center, spacing: -fontSize * 0.18) {
                VStack(spacing: 0) {
                    MathRowView(row: node.rows[0], fontSize: nested(0.55))
                    Color.clear.frame(width: 0, height: fontSize * 0.45)
                }
                radical(node.rows[1])
            }

        case .logBase:
            HStack(spacing: 0) {
                Text("log").font(Theme.mathFont(fontSize)).foregroundStyle(ink)
                VStack(spacing: 0) {
                    Color.clear.frame(width: 0, height: fontSize * 0.5)
                    MathRowView(row: node.rows[0], fontSize: nested(0.6))
                }
                parenthesized(node.rows[1], showsPlaceholder: true)
            }

        case .absoluteValue:
            HStack(spacing: 0) {
                verticalBar
                MathRowView(row: node.rows[0], fontSize: fontSize)
                verticalBar
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Pieces

    private func nested(_ scale: CGFloat) -> CGFloat {
        max(12, fontSize * scale)
    }

    private var needsBase: Bool {
        guard let previous else { return true }
        return previous.isOperator
    }

    private var basePlaceholderBox: some View {
        SlotBox(size: fontSize * 0.62, color: Theme.placeholder, lineWidth: 1)
            .padding(.horizontal, 2)
    }

    /// `( row )` with parentheses that stretch to the content's height.
    private func parenthesized(_ row: MathRow, showsPlaceholder: Bool) -> some View {
        HStack(spacing: 0) {
            paren(opening: true)
            MathRowView(row: row, fontSize: fontSize, showsPlaceholder: showsPlaceholder)
            paren(opening: false)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func paren(opening: Bool) -> some View {
        ParenShape(isOpening: opening)
            .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: fontSize * 0.3)
            .frame(minHeight: fontSize * 1.1, maxHeight: .infinity)
            .padding(.horizontal, fontSize * 0.03)
    }

    /// √ with a vinculum spanning the radicand.
    private func radical(_ row: MathRow) -> some View {
        HStack(spacing: 0) {
            RadicalShape()
                .stroke(ink, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                .frame(width: fontSize * 0.5)
                .frame(minHeight: fontSize, maxHeight: .infinity)
            MathRowView(row: row, fontSize: fontSize)
                .padding(.top, fontSize * 0.14)
                .padding(.horizontal, fontSize * 0.06)
                .overlay(alignment: .top) {
                    Rectangle().fill(ink).frame(height: lineWidth)
                }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var verticalBar: some View {
        Rectangle()
            .fill(ink)
            .frame(width: lineWidth)
            .frame(minHeight: fontSize, maxHeight: .infinity)
            .padding(.horizontal, fontSize * 0.08)
    }
}

/// A single glyph with TeX-like styling: italic variables, spaced operators.
struct SymbolView: View {
    let symbol: String
    let fontSize: CGFloat

    private var isVariable: Bool {
        guard symbol.count == 1, let c = symbol.first else { return false }
        return c.isLetter && symbol != "π"
    }

    private var isOperator: Bool {
        MathNode.operatorSymbols.contains(symbol) && symbol != ","
    }

    var body: some View {
        Text(symbol)
            .font(Theme.mathFont(fontSize))
            .italic(isVariable)
            .foregroundStyle(Theme.darkText)
            .padding(.horizontal, isOperator ? fontSize * 0.16 : (isVariable ? 1 : 0))
    }
}

/// The text cursor, blinking at the standard iOS rate.
struct BlinkingCursor: View {
    let height: CGFloat
    private let interval: TimeInterval = 0.53

    var body: some View {
        TimelineView(.periodic(from: .now, by: interval)) { context in
            let isVisible = Int(context.date.timeIntervalSinceReferenceDate / interval) % 2 == 0
            Rectangle()
                .fill(Theme.cursor)
                .frame(width: 2, height: height)
                .opacity(isVisible ? 1 : 0)
        }
        .frame(width: 2, height: height)
        .padding(.horizontal, 0.5)
        .accessibilityHidden(true)
    }
}
