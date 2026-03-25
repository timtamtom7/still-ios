import SwiftUI

enum OrbState {
    case idle
    case attentive
    case recording
    case complete
}

struct BreathingOrb: View {
    let state: OrbState
    @Binding var scale: CGFloat

    private var glowColor: Color {
        switch state {
        case .idle: return AppColors.amberGlow.opacity(0.3)
        case .attentive: return AppColors.amberGlow.opacity(0.5)
        case .recording: return AppColors.amberGlow.opacity(0.7)
        case .complete: return AppColors.amber.opacity(0.2)
        }
    }

    private var orbOpacity: Double {
        switch state {
        case .idle: return 0.7
        case .attentive: return 0.85
        case .recording: return 1.0
        case .complete: return 0.4
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.amberGlow,
                            AppColors.amber,
                            AppColors.amber.opacity(0.6),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .opacity(orbOpacity)
                .scaleEffect(scale)
                .shadow(color: glowColor, radius: 40, x: 0, y: 0)
                .shadow(color: glowColor, radius: 80, x: 0, y: 0)
        }
        .frame(width: 160, height: 160)
        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: scale)
    }
}
