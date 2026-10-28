import SwiftUI

/// The four pages selectable from the keyboard's tab bar.
enum KeyboardTab: String, CaseIterable, Identifiable {
    case numbers  = "123"
    case symbols  = "( )%<"
    case functions = "f(x)"
    case letters  = "abc"

    var id: String { rawValue }

    /// Highlight colour of the selected tab chip — matches the page's key colour.
    var selectedChipColor: Color {
        switch self {
        case .numbers, .symbols, .letters: return Theme.numberKey
        case .functions: return Theme.functionKey
        }
    }
}

/// What a key does when pressed.
enum KeyAction {
    case symbol(String)
    case function(String)
    case structure(MathNodeKind)
    case moveLeft
    case moveRight
    case backspace
    case enter
    case hideKeyboard
    case toggleShift
}

/// Custom-drawn key glyphs.
enum KeyIcon {
    case fraction, power, subscripted, squareRoot, nthRoot, logBase, absoluteValue
    case backspace, hideKeyboard, shift, arrowLeft, arrowRight
}

/// How a key's label is rendered.
enum KeyLabel {
    /// Thin sans-serif text (digits, function names).
    case text(String)
    /// Serif math glyph (θ, π, °).
    case math(String)
    /// Bold italic serif variable (x, y).
    case variable(String)
    case icon(KeyIcon)
}

/// Background colour family of a key.
enum KeyStyle {
    case variable, number, operation, function, control

    var background: Color {
        switch self {
        case .variable:  return Theme.variableKey
        case .number:    return Theme.numberKey
        case .operation: return Theme.operatorKey
        case .function:  return Theme.functionKey
        case .control:   return Theme.controlKey
        }
    }

    var foreground: Color {
        switch self {
        case .variable, .control: return Theme.lightText
        case .number, .operation, .function: return Theme.darkText
        }
    }
}

struct KeyDefinition: Identifiable {
    let id: String
    let label: KeyLabel
    let action: KeyAction
    let style: KeyStyle

    init(_ id: String, _ label: KeyLabel, _ action: KeyAction, _ style: KeyStyle) {
        self.id = id
        self.label = label
        self.action = action
        self.style = style
    }
}

// MARK: - Layouts

enum KeyLayouts {

    /// Left column — identical on the 123, ( )%< and f(x) pages.
    static let leftColumn: [KeyDefinition] = [
        .init("x", .variable("x"), .symbol("x"), .variable),
        .init("y", .variable("y"), .symbol("y"), .variable),
        .init("frac", .icon(.fraction), .structure(.fraction), .variable),
        .init("pow", .icon(.power), .structure(.superscript), .variable),
    ]

    /// Centre 4×4 block for each page, row by row.
    static func centerRows(for tab: KeyboardTab) -> [[KeyDefinition]] {
        switch tab {
        case .numbers:   return numberRows
        case .symbols:   return symbolRows
        case .functions: return functionRows
        case .letters:   return [] // letters use their own full-width layout
        }
    }

    private static func digit(_ d: String) -> KeyDefinition {
        .init("d\(d)", .text(d), .symbol(d), .number)
    }

    private static func op(_ id: String, _ glyph: String, _ insert: String) -> KeyDefinition {
        .init(id, .text(glyph), .symbol(insert), .operation)
    }

    static let numberRows: [[KeyDefinition]] = [
        [digit("7"), digit("8"), digit("9"), op("div", "÷", "÷")],
        [digit("4"), digit("5"), digit("6"), op("mul", "×", "×")],
        [digit("1"), digit("2"), digit("3"), op("sub", "-", "−")],
        [digit("0"), digit("."), .init("eq", .text("="), .symbol("="), .number), op("add", "+", "+")],
    ]

    private static func fn(_ name: String) -> KeyDefinition {
        .init("fn-\(name)", .text(name), .function(name), .function)
    }

    static let functionRows: [[KeyDefinition]] = [
        [fn("sin"), fn("cos"), fn("tan"), .init("theta", .math("θ"), .symbol("θ"), .function)],
        [fn("sec"), fn("csc"), fn("cot"), .init("pi", .math("π"), .symbol("π"), .function)],
        [fn("log"), fn("ln"),
         .init("logb", .icon(.logBase), .structure(.logBase), .function),
         .init("angle", .text("∠"), .symbol("∠"), .function)],
        [.init("subscript", .icon(.subscripted), .structure(.subscripted), .function),
         .init("sqrt", .icon(.squareRoot), .structure(.squareRoot), .function),
         .init("nroot", .icon(.nthRoot), .structure(.nthRoot), .function),
         .init("deg", .math("°"), .symbol("°"), .function)],
    ]

    private static func sym(_ s: String) -> KeyDefinition {
        .init("sym-\(s)", .text(s), .symbol(s), .number)
    }

    /// The ( )%< page wasn't in the reference screens — this is a sensible layout
    /// with brackets, comparisons, percent/factorial, absolute value and cursor arrows.
    static let symbolRows: [[KeyDefinition]] = [
        [sym("("), sym(")"), sym("<"), sym(">")],
        [sym("["), sym("]"), sym("≤"), sym("≥")],
        [sym("%"), sym("!"), .init("abs", .icon(.absoluteValue), .structure(.absoluteValue), .number), sym("≠")],
        [.init("left", .icon(.arrowLeft), .moveLeft, .operation),
         .init("right", .icon(.arrowRight), .moveRight, .operation),
         sym(","), sym("∞")],
    ]

    /// QWERTY rows for the abc page.
    static let letterRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]
}
