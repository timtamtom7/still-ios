import SwiftUI

struct BreathingOrbMini: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.orbGlow.opacity(0.6), Theme.orbCenter.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .scaleEffect(scale)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.orbCenter, Theme.calmBlue],
                        center: .center,
                        startRadius: 0,
                        endRadius: 16
                    )
                )
                .frame(width: 32, height: 32)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.1
            }
        }
    }
}
