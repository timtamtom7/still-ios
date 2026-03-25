import SwiftUI

/// A candlelit, meditative illustration for Still's empty states.
struct StillEmptyIllustration: View {
    let size: CGFloat

    private let background = Color(hex: "0D0B09")
    private let surface = Color(hex: "1A1714")
    private let amber = Color(hex: "E8A46A")
    private let amberGlow = Color(hex: "F4C594")
    private let amberDeep = Color(hex: "C47D3E")
    private let textSecondary = Color(hex: "9B9385")
    private let separator = Color(hex: "2A2520")

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let scale = size / 300

            // Soft amber glow
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - 100 * scale,
                    y: center.y - 120 * scale,
                    width: 200 * scale,
                    height: 200 * scale
                )),
                with: .radialGradient(
                    Gradient(colors: [amber.opacity(0.1), Color.clear]),
                    center: center,
                    startRadius: 0,
                    endRadius: 100 * scale
                )
            )

            // Decorative circles
            let circles: [(CGPoint, CGFloat, Color)] = [
                (CGPoint(x: center.x, y: center.y - 10 * scale), 60 * scale, amber.opacity(0.05)),
                (CGPoint(x: center.x, y: center.y - 10 * scale), 40 * scale, amber.opacity(0.08)),
                (CGPoint(x: center.x, y: center.y - 10 * scale), 20 * scale, amber.opacity(0.12)),
            ]
            for (pos, radius, color) in circles {
                var path = Path()
                path.addEllipse(in: CGRect(
                    x: pos.x - radius,
                    y: pos.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(path, with: .color(color))
            }

            // Flame
            let flameCenter = CGPoint(x: center.x, y: center.y - 10 * scale)
            let flameScale = 40 * scale

            // Outer flame glow
            context.fill(
                Path(ellipseIn: CGRect(
                    x: flameCenter.x - flameScale * 2,
                    y: flameCenter.y - flameScale * 2.5,
                    width: flameScale * 4,
                    height: flameScale * 4
                )),
                with: .radialGradient(
                    Gradient(colors: [amberGlow.opacity(0.2), amber.opacity(0.05), Color.clear]),
                    center: flameCenter,
                    startRadius: 0,
                    endRadius: flameScale * 2
                )
            )

            // Flame shape
            var flamePath = Path()
            flamePath.move(to: CGPoint(x: flameCenter.x, y: flameCenter.y + flameScale * 0.5))
            flamePath.addCurve(
                to: CGPoint(x: flameCenter.x - flameScale * 0.4, y: flameCenter.y - flameScale * 0.1),
                control1: CGPoint(x: flameCenter.x - flameScale * 0.5, y: flameCenter.y + flameScale * 0.2),
                control2: CGPoint(x: flameCenter.x - flameScale * 0.4, y: flameCenter.y + flameScale * 0.1)
            )
            flamePath.addCurve(
                to: CGPoint(x: flameCenter.x, y: flameCenter.y - flameScale * 0.9),
                control1: CGPoint(x: flameCenter.x - flameScale * 0.3, y: flameCenter.y - flameScale * 0.5),
                control2: CGPoint(x: flameCenter.x - flameScale * 0.1, y: flameCenter.y - flameScale * 0.8)
            )
            flamePath.addCurve(
                to: CGPoint(x: flameCenter.x + flameScale * 0.4, y: flameCenter.y - flameScale * 0.1),
                control1: CGPoint(x: flameCenter.x + flameScale * 0.1, y: flameCenter.y - flameScale * 0.8),
                control2: CGPoint(x: flameCenter.x + flameScale * 0.3, y: flameCenter.y - flameScale * 0.5)
            )
            flamePath.addCurve(
                to: CGPoint(x: flameCenter.x, y: flameCenter.y + flameScale * 0.5),
                control1: CGPoint(x: flameCenter.x + flameScale * 0.4, y: flameCenter.y + flameScale * 0.1),
                control2: CGPoint(x: flameCenter.x + flameScale * 0.5, y: flameCenter.y + flameScale * 0.2)
            )
            flamePath.closeSubpath()

            context.fill(flamePath, with: .linearGradient(
                Gradient(colors: [amber.opacity(0.8), amberGlow.opacity(0.5), amber.opacity(0.3)]),
                startPoint: CGPoint(x: flameCenter.x, y: flameCenter.y + flameScale * 0.5),
                endPoint: CGPoint(x: flameCenter.x, y: flameCenter.y - flameScale)
            ))

            // Candle body
            let candleTop = flameCenter.y + flameScale * 0.7
            let candleBottom = candleTop + 80 * scale
            let candleWidth: CGFloat = 35 * scale

            // Candle body (simple rectangle)
            var candlePath = Path()
            candlePath.addRect(CGRect(
                x: flameCenter.x - candleWidth / 2,
                y: candleTop,
                width: candleWidth,
                height: candleBottom - candleTop
            ))
            context.fill(candlePath, with: .color(surface))

            // Candle top rim
            var rimPath = Path()
            rimPath.addEllipse(in: CGRect(
                x: flameCenter.x - candleWidth / 2,
                y: candleTop - 3 * scale,
                width: candleWidth,
                height: 6 * scale
            ))
            context.fill(rimPath, with: .color(amber.opacity(0.3)))

            // Base
            var basePath = Path()
            basePath.addEllipse(in: CGRect(
                x: flameCenter.x - candleWidth * 0.7,
                y: candleBottom,
                width: candleWidth * 1.4,
                height: 12 * scale
            ))
            context.fill(basePath, with: .color(surface))

            // Small decorative elements
            let dots: [(CGPoint, CGFloat)] = [
                (CGPoint(x: 50 * scale, y: 80 * scale), 2 * scale),
                (CGPoint(x: 250 * scale, y: 60 * scale), 1.5 * scale),
                (CGPoint(x: 40 * scale, y: 220 * scale), 1.5 * scale),
                (CGPoint(x: 260 * scale, y: 200 * scale), 2 * scale),
            ]
            for (pos, r) in dots {
                var dotPath = Path()
                dotPath.addEllipse(in: CGRect(
                    x: pos.x - r,
                    y: pos.y - r,
                    width: r * 2,
                    height: r * 2
                ))
                context.fill(dotPath, with: .color(textSecondary.opacity(0.15)))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color(hex: "0D0B09").ignoresSafeArea()
        StillEmptyIllustration(size: 220)
    }
}
