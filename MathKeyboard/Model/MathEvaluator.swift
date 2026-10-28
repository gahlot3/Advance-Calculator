import Foundation

/// Numerically evaluates an expression tree.
///
/// - Trigonometric functions use radians; append `°` to work in degrees, e.g. `sin(30°)`.
/// - A single top-level comparison (`=`, `<`, `>`, `≤`, `≥`, `≠`) returns `true` / `false`.
/// - Expressions containing variables (x, y, θ, letters) cannot be evaluated.
struct MathEvaluator {

    struct EvaluationError: Error, Equatable {
        let message: String
        init(_ message: String) { self.message = message }
    }

    private static let relations: Set<String> = ["=", "<", ">", "≤", "≥", "≠"]

    // MARK: - Public

    func evaluate(_ row: MathRow) throws -> String {
        let nodes = row.nodes
        let relationIndices = nodes.indices.filter { index in
            if case .symbol(let s) = nodes[index].kind { return Self.relations.contains(s) }
            return false
        }

        guard relationIndices.count <= 1 else {
            throw EvaluationError("Only one comparison is supported")
        }

        if let r = relationIndices.first, case .symbol(let op) = nodes[r].kind {
            let lhs = try value(of: Array(nodes[..<r]))
            let rhs = try value(of: Array(nodes[(r + 1)...]))
            let tolerance = 1e-12 * max(abs(lhs), abs(rhs))
            let isEqual = lhs == rhs || abs(lhs - rhs) <= tolerance
            let holds: Bool
            switch op {
            case "=": holds = isEqual
            case "≠": holds = !isEqual
            case "<": holds = lhs < rhs && !isEqual
            case ">": holds = lhs > rhs && !isEqual
            case "≤": holds = lhs < rhs || isEqual
            case "≥": holds = lhs > rhs || isEqual
            default: throw EvaluationError("Unsupported comparison")
            }
            return holds ? "true" : "false"
        }

        return Self.format(try value(of: nodes))
    }

    static func format(_ value: Double) -> String {
        var v = value
        if abs(v) < 1e-12 { v = 0 }
        if v == v.rounded(), abs(v) < 1e15 {
            return String(Int64(v))
        }
        return String(format: "%.10g", v)
    }

    // MARK: - Tokens

    private enum Token: Equatable {
        case number(Double)
        case plus, minus, times, divide
        case leftParen, rightParen
        case postfix(String)      // ! % °
        case power(Double)        // evaluated superscript
    }

    private func value(of nodes: [MathNode]) throws -> Double {
        guard !nodes.isEmpty else { throw EvaluationError("Fill in the empty boxes") }
        var parser = Parser(tokens: try tokenize(nodes))
        let result = try parser.parseExpression()
        guard parser.isAtEnd else { throw EvaluationError("Incomplete expression") }
        guard !result.isNaN else { throw EvaluationError("Undefined") }
        return result
    }

    private func tokenize(_ nodes: [MathNode]) throws -> [Token] {
        var tokens: [Token] = []
        var digits = ""

        func flushDigits() throws {
            guard !digits.isEmpty else { return }
            guard let number = Double(digits) else {
                throw EvaluationError("Invalid number “\(digits)”")
            }
            tokens.append(.number(number))
            digits = ""
        }

        for node in nodes {
            if case .symbol(let s) = node.kind, s.count == 1, "0123456789.".contains(s) {
                digits += s
                continue
            }
            try flushDigits()

            if case .symbol(" ") = node.kind { continue } // spaces are cosmetic

            switch node.kind {
            case .symbol(let s):
                tokens.append(try token(for: s))

            case .function(let name):
                let argument = try value(of: node.rows[0].nodes)
                tokens.append(.number(try apply(name, to: argument)))

            case .fraction:
                let numerator = try value(of: node.rows[0].nodes)
                let denominator = try value(of: node.rows[1].nodes)
                guard denominator != 0 else { throw EvaluationError("Division by zero") }
                tokens.append(.number(numerator / denominator))

            case .superscript:
                tokens.append(.power(try value(of: node.rows[0].nodes)))

            case .subscripted:
                throw EvaluationError("Subscripts can't be evaluated")

            case .squareRoot:
                let radicand = try value(of: node.rows[0].nodes)
                guard radicand >= 0 else { throw EvaluationError("Square root of a negative number") }
                tokens.append(.number(radicand.squareRoot()))

            case .nthRoot:
                let n = try value(of: node.rows[0].nodes)
                let radicand = try value(of: node.rows[1].nodes)
                guard n != 0 else { throw EvaluationError("Root index can't be zero") }
                if radicand < 0 {
                    let isOddInteger = n == n.rounded() && abs(n) < 1e15 && Int64(n) % 2 != 0
                    guard isOddInteger else { throw EvaluationError("Even root of a negative number") }
                    tokens.append(.number(-pow(-radicand, 1 / n)))
                } else {
                    tokens.append(.number(pow(radicand, 1 / n)))
                }

            case .logBase:
                let base = try value(of: node.rows[0].nodes)
                let argument = try value(of: node.rows[1].nodes)
                guard base > 0, base != 1, argument > 0 else {
                    throw EvaluationError("Logarithm is undefined for these values")
                }
                tokens.append(.number(log(argument) / log(base)))

            case .absoluteValue:
                tokens.append(.number(abs(try value(of: node.rows[0].nodes))))
            }
        }
        try flushDigits()
        return tokens
    }

    private func token(for symbol: String) throws -> Token {
        switch symbol {
        case "+": return .plus
        case "−", "-": return .minus
        case "×", "*": return .times
        case "÷", "/": return .divide
        case "(", "[": return .leftParen
        case ")", "]": return .rightParen
        case "!", "%", "°": return .postfix(symbol)
        case "π": return .number(.pi)
        case "∞": return .number(.infinity)
        default:
            if symbol.first?.isLetter == true {
                throw EvaluationError("Contains variables — can't evaluate")
            }
            throw EvaluationError("“\(symbol)” can't be evaluated")
        }
    }

    private func apply(_ function: String, to x: Double) throws -> Double {
        switch function {
        case "sin": return sin(x)
        case "cos": return cos(x)
        case "tan":
            guard abs(cos(x)) > 1e-12 else { throw EvaluationError("tan is undefined here") }
            return tan(x)
        case "sec":
            guard abs(cos(x)) > 1e-12 else { throw EvaluationError("sec is undefined here") }
            return 1 / cos(x)
        case "csc":
            guard abs(sin(x)) > 1e-12 else { throw EvaluationError("csc is undefined here") }
            return 1 / sin(x)
        case "cot":
            guard abs(sin(x)) > 1e-12 else { throw EvaluationError("cot is undefined here") }
            return cos(x) / sin(x)
        case "log":
            guard x > 0 else { throw EvaluationError("log needs a positive value") }
            return log10(x)
        case "ln":
            guard x > 0 else { throw EvaluationError("ln needs a positive value") }
            return log(x)
        default:
            throw EvaluationError("Unknown function \(function)")
        }
    }

    // MARK: - Recursive-descent parser

    private struct Parser {
        let tokens: [Token]
        var position = 0

        init(tokens: [Token]) { self.tokens = tokens }

        var isAtEnd: Bool { position >= tokens.count }
        private var current: Token? { isAtEnd ? nil : tokens[position] }

        // expression := term (('+' | '−') term)*
        mutating func parseExpression() throws -> Double {
            var value = try parseTerm()
            while let token = current {
                if token == .plus {
                    position += 1
                    value += try parseTerm()
                } else if token == .minus {
                    position += 1
                    value -= try parseTerm()
                } else {
                    break
                }
            }
            return value
        }

        // term := unary (('×' | '÷') unary | implicit-multiplication unary)*
        private mutating func parseTerm() throws -> Double {
            var value = try parseUnary()
            while let token = current {
                switch token {
                case .times:
                    position += 1
                    value *= try parseUnary()
                case .divide:
                    position += 1
                    let divisor = try parseUnary()
                    guard divisor != 0 else { throw EvaluationError("Division by zero") }
                    value /= divisor
                case .number, .leftParen:
                    value *= try parsePostfix() // implicit: 2π, 3(4), 2sin(x)
                default:
                    return value
                }
            }
            return value
        }

        // unary := ('−' | '+') unary | postfix
        private mutating func parseUnary() throws -> Double {
            if current == .minus {
                position += 1
                return -(try parseUnary())
            }
            if current == .plus {
                position += 1
                return try parseUnary()
            }
            return try parsePostfix()
        }

        // postfix := primary ( '!' | '%' | '°' | superscript )*
        private mutating func parsePostfix() throws -> Double {
            var value = try parsePrimary()
            while let token = current {
                switch token {
                case .postfix("!"):
                    position += 1
                    value = try factorial(value)
                case .postfix("%"):
                    position += 1
                    value /= 100
                case .postfix("°"):
                    position += 1
                    value *= .pi / 180
                case .power(let exponent):
                    position += 1
                    value = pow(value, exponent)
                default:
                    return value
                }
            }
            return value
        }

        private mutating func parsePrimary() throws -> Double {
            guard let token = current else { throw EvaluationError("Incomplete expression") }
            switch token {
            case .number(let n):
                position += 1
                return n
            case .leftParen:
                position += 1
                let value = try parseExpression()
                guard current == .rightParen else {
                    throw EvaluationError("Missing closing parenthesis")
                }
                position += 1
                return value
            case .power:
                throw EvaluationError("Exponent needs a base")
            default:
                throw EvaluationError("Incomplete expression")
            }
        }

        private func factorial(_ n: Double) throws -> Double {
            if n == n.rounded() {
                guard n >= 0 else { throw EvaluationError("Factorial of a negative integer") }
                guard n <= 170 else { return .infinity }
                return (1...max(1, Int(n))).reduce(1.0) { $0 * Double($1) }
            }
            return tgamma(n + 1)
        }
    }
}
