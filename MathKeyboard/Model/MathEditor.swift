import Foundation
import Combine

/// Insertion point inside the expression tree.
struct MathCursor {
    var row: MathRow
    var index: Int
}

/// Owns the expression tree and the cursor, and applies keyboard actions to them.
final class MathEditor: ObservableObject {
    let root: MathRow
    @Published private(set) var cursor: MathCursor
    /// Bumped on every mutation so SwiftUI re-renders the (class-based) tree.
    @Published private(set) var revision = 0
    /// Text shown under the display after pressing Enter.
    @Published private(set) var resultText: String?

    init() {
        let row = MathRow()
        root = row
        cursor = MathCursor(row: row, index: 0)
    }

    var isEmpty: Bool { root.isEmpty }

    func isCursor(in row: MathRow, at index: Int) -> Bool {
        cursor.row === row && cursor.index == index
    }

    func isCursor(in row: MathRow) -> Bool {
        cursor.row === row
    }

    // MARK: - Insertion

    func insertSymbol(_ symbol: String) {
        insert(MathNode(.symbol(symbol)))
    }

    func insertFunction(_ name: String) {
        insert(MathNode(.function(name)))
    }

    func insertStructure(_ kind: MathNodeKind) {
        insert(MathNode(kind))
    }

    private func insert(_ node: MathNode) {
        let row = cursor.row
        let index = min(cursor.index, row.count)
        row.insert(node, at: index)
        if let firstSlot = node.rows.first {
            cursor = MathCursor(row: firstSlot, index: 0)
        } else {
            cursor = MathCursor(row: row, index: index + 1)
        }
        didMutate()
    }

    // MARK: - Navigation

    func moveLeft() {
        let row = cursor.row
        if cursor.index > 0 {
            let node = row.nodes[cursor.index - 1]
            if let lastSlot = node.rows.last {
                cursor = MathCursor(row: lastSlot, index: lastSlot.count)
            } else {
                cursor.index -= 1
            }
        } else if let ctx = context(of: row) {
            let (parent, parentRow, slot) = (ctx.parent, ctx.parentRow, ctx.slot)
            if slot > 0 {
                let previous = parent.rows[slot - 1]
                cursor = MathCursor(row: previous, index: previous.count)
            } else if let i = parentRow.index(of: parent) {
                cursor = MathCursor(row: parentRow, index: i)
            }
        }
        didMoveCursor()
    }

    func moveRight() {
        let row = cursor.row
        if cursor.index < row.count {
            let node = row.nodes[cursor.index]
            if let firstSlot = node.rows.first {
                cursor = MathCursor(row: firstSlot, index: 0)
            } else {
                cursor.index += 1
            }
        } else if let ctx = context(of: row) {
            let (parent, parentRow, slot) = (ctx.parent, ctx.parentRow, ctx.slot)
            if slot + 1 < parent.rows.count {
                cursor = MathCursor(row: parent.rows[slot + 1], index: 0)
            } else if let i = parentRow.index(of: parent) {
                cursor = MathCursor(row: parentRow, index: i + 1)
            }
        }
        didMoveCursor()
    }

    /// Places the cursor explicitly (used when the user taps the display).
    func setCursor(row: MathRow, index: Int) {
        cursor = MathCursor(row: row, index: max(0, min(index, row.count)))
        didMoveCursor()
    }

    // MARK: - Deletion

    func backspace() {
        let row = cursor.row
        if cursor.index > 0 {
            let node = row.nodes[cursor.index - 1]
            if node.isLeaf || node.isEmptyStructure {
                row.remove(at: cursor.index - 1)
                cursor.index -= 1
            } else if let lastSlot = node.rows.last {
                // Step inside a filled structure instead of deleting it wholesale.
                cursor = MathCursor(row: lastSlot, index: lastSlot.count)
                didMoveCursor()
                return
            }
        } else if let ctx = context(of: row),
                  let i = ctx.parentRow.index(of: ctx.parent) {
            let (parent, parentRow, slot) = (ctx.parent, ctx.parentRow, ctx.slot)
            if slot > 0 {
                let previous = parent.rows[slot - 1]
                cursor = MathCursor(row: previous, index: previous.count)
                didMoveCursor()
                return
            } else if parent.rows.dropFirst().allSatisfy(\.isEmpty) {
                // At the start of the first slot and nothing else is filled:
                // unwrap the structure, keeping the first slot's contents (√2 → 2).
                let contents = parent.rows[0].nodes
                parentRow.remove(at: i)
                for (offset, node) in contents.enumerated() {
                    parentRow.insert(node, at: i + offset)
                }
                cursor = MathCursor(row: parentRow, index: i)
            } else {
                // Other slots hold content — just step out rather than merge them.
                cursor = MathCursor(row: parentRow, index: i)
                didMoveCursor()
                return
            }
        } else {
            return // Nothing to delete.
        }
        didMutate()
    }

    func clear() {
        root.removeAll()
        cursor = MathCursor(row: root, index: 0)
        didMutate()
    }

    // MARK: - Evaluation

    /// Evaluates the expression and publishes the result text.
    func submit() {
        guard !root.isEmpty else {
            resultText = nil
            return
        }
        do {
            resultText = "= " + (try MathEvaluator().evaluate(root))
        } catch let error as MathEvaluator.EvaluationError {
            resultText = error.message
        } catch {
            resultText = "Unable to evaluate"
        }
    }

    // MARK: - Helpers

    /// For a nested row returns the structure owning it, the row containing that
    /// structure, and which slot of the structure the row is.
    private struct SlotContext {
        let parent: MathNode
        let parentRow: MathRow
        let slot: Int
    }

    private func context(of row: MathRow) -> SlotContext? {
        guard let parent = row.parent,
              let parentRow = parent.parentRow,
              let slot = parent.rows.firstIndex(where: { $0 === row }) else { return nil }
        return SlotContext(parent: parent, parentRow: parentRow, slot: slot)
    }

    private func didMutate() {
        resultText = nil
        revision &+= 1
    }

    private func didMoveCursor() {
        revision &+= 1
    }
}
