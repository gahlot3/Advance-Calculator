import Foundation

/// The kinds of element that can appear in an expression.
enum MathNodeKind: Equatable {
    /// A single glyph: digit, letter, operator, constant (π, θ, °, ∠ …).
    case symbol(String)
    /// A named function such as `sin`. `rows[0]` is the argument.
    case function(String)
    /// `rows[0]` = numerator, `rows[1]` = denominator.
    case fraction
    /// Exponent attached to whatever precedes it. `rows[0]` = exponent.
    case superscript
    /// Subscript attached to whatever precedes it. `rows[0]` = subscript.
    case subscripted
    /// `rows[0]` = radicand.
    case squareRoot
    /// `rows[0]` = index, `rows[1]` = radicand.
    case nthRoot
    /// `rows[0]` = base, `rows[1]` = argument.
    case logBase
    /// `rows[0]` = content.
    case absoluteValue

    /// Number of editable slots this kind owns.
    var slotCount: Int {
        switch self {
        case .symbol: return 0
        case .function, .superscript, .subscripted, .squareRoot, .absoluteValue: return 1
        case .fraction, .nthRoot, .logBase: return 2
        }
    }
}

/// A horizontal sequence of nodes — the whole expression, or one slot of a structure
/// (e.g. a numerator).
final class MathRow: Identifiable {
    let id = UUID()
    private(set) var nodes: [MathNode] = []
    /// The structure that owns this row, or `nil` for the root row.
    weak var parent: MathNode?

    init() {}

    var isEmpty: Bool { nodes.isEmpty }
    var count: Int { nodes.count }

    func insert(_ node: MathNode, at index: Int) {
        node.parentRow = self
        nodes.insert(node, at: index)
    }

    @discardableResult
    func remove(at index: Int) -> MathNode {
        let node = nodes.remove(at: index)
        node.parentRow = nil
        return node
    }

    func removeAll() {
        nodes.forEach { $0.parentRow = nil }
        nodes.removeAll()
    }

    func index(of node: MathNode) -> Int? {
        nodes.firstIndex { $0 === node }
    }
}

/// One element of the expression tree.
final class MathNode: Identifiable {
    let id = UUID()
    let kind: MathNodeKind
    /// Editable slots, in cursor-navigation order.
    let rows: [MathRow]
    weak var parentRow: MathRow?

    init(_ kind: MathNodeKind) {
        self.kind = kind
        self.rows = (0..<kind.slotCount).map { _ in MathRow() }
        for row in rows { row.parent = self }
    }

    var isLeaf: Bool { rows.isEmpty }
    var isEmptyStructure: Bool { !rows.isEmpty && rows.allSatisfy(\.isEmpty) }

    /// Symbols that act as binary/relational operators (used for spacing and
    /// for deciding whether a superscript has a base).
    static let operatorSymbols: Set<String> = [
        "+", "−", "-", "×", "÷", "=", "<", ">", "≤", "≥", "≠", ","
    ]

    var isOperator: Bool {
        if case .symbol(let s) = kind { return MathNode.operatorSymbols.contains(s) }
        return false
    }
}
