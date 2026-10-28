import SwiftUI

/// Draws the custom glyphs used on keys (fraction, powers, roots …).
struct KeyIconView: View {
    let icon: KeyIcon
    let color: Color

    var body: some View {
        Group {
            switch icon {
            case .fraction:
                VStack(spacing: 4) {
                    box(14)
                    Rectangle().fill(color).frame(width: 30, height: 1.5)
                    box(14)
                }

            case .power:
                HStack(alignment: .top, spacing: 4) {
                    box(24).padding(.top, 10)
                    box(13)
                }

            case .subscripted:
                HStack(alignment: .bottom, spacing: 4) {
                    box(24).padding(.bottom, 10)
                    box(13)
                }

            case .squareRoot:
                radical(boxSize: 20)

            case .nthRoot:
                HStack(alignment: .top, spacing: -5) {
                    box(12)
                    radical(boxSize: 20).padding(.top, 7)
                }

            case .logBase:
                HStack(alignment: .bottom, spacing: 1) {
                    Text("log")
                        .font(Theme.keyFont(20))
                        .padding(.bottom, 6)
                    box(11)
                }

            case .absoluteValue:
                HStack(spacing: 3) {
                    Rectangle().fill(color).frame(width: 1.5, height: 26)
                    box(16)
                    Rectangle().fill(color).frame(width: 1.5, height: 26)
                }

            case .backspace:
                Image(systemName: "delete.left.fill")
                    .font(.system(size: 26, weight: .regular))

            case .hideKeyboard:
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 26, weight: .regular))

            case .shift:
                Image(systemName: "shift")
                    .font(.system(size: 20, weight: .regular))

            case .arrowLeft:
                Image(systemName: "arrow.left")
                    .font(.system(size: 22, weight: .light))

            case .arrowRight:
                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .light))
            }
        }
        .foregroundStyle(color)
        .accessibilityHidden(true)
    }

    private func box(_ size: CGFloat) -> some View {
        SlotBox(size: size, color: color, lineWidth: 1.5)
    }

    private func radical(boxSize: CGFloat) -> some View {
        HStack(spacing: 0) {
            RadicalShape()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .frame(width: boxSize * 0.55, height: boxSize + 6)
            box(boxSize)
                .padding(.top, 6)
                .padding(.horizontal, 3)
                .overlay(alignment: .top) {
                    Rectangle().fill(color).frame(height: 1.5)
                }
        }
    }
}
