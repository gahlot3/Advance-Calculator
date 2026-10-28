import SwiftUI

/// The "check-mark" part of a radical sign. Its top-right corner is where the
/// vinculum (overline) starts, so place it flush against an overlined view.
struct RadicalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.58))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// A parenthesis that stretches to the height it is given.
struct ParenShape: Shape {
    let isOpening: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inner = isOpening ? rect.maxX - rect.width * 0.15 : rect.minX + rect.width * 0.15
        let bulge = isOpening ? rect.minX - rect.width * 0.35 : rect.maxX + rect.width * 0.35
        path.move(to: CGPoint(x: inner, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: inner, y: rect.maxY),
            control: CGPoint(x: bulge, y: rect.midY)
        )
        return path
    }
}

/// An empty square slot (□) used both on keys and as a placeholder in the display.
struct SlotBox: View {
    let size: CGFloat
    var color: Color = .primary
    var lineWidth: CGFloat = 1.5

    var body: some View {
        Rectangle()
            .stroke(color, lineWidth: lineWidth)
            .frame(width: size, height: size)
    }
}
