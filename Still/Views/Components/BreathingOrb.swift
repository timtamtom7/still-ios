import SwiftUI
import UIKit

enum OrbState {
    case idle
    case attentive
    case recording
    case complete
}

struct BreathingOrb: View {
    let state: OrbState
    @Binding var scale: CGFloat
    var size: OrbSize = .standard

    enum OrbSize {
        case standard    // 160pt - iPhone
        case large       // 240pt - iPad
        case extraLarge  // 280pt - iPad landscape

        var dimension: CGFloat {
            switch self {
            case .standard: return 160
            case .large: return 240
            case .extraLarge: return 280
            }
        }

        var gradientRadius: CGFloat {
            switch self {
            case .standard: return 80
            case .large: return 120
            case .extraLarge: return 140
            }
        }

        var glowRadius1: CGFloat {
            switch self {
            case .standard: return 40
            case .large: return 60
            case .extraLarge: return 70
            }
        }

        var glowRadius2: CGFloat {
            switch self {
            case .standard: return 80
            case .large: return 120
            case .extraLarge: return 140
            }
        }
    }

    private var resolvedSize: OrbSize {
        // Auto-detect iPad and use larger size
        if size == .standard {
            #if targetEnvironment(simulator)
            if UIDevice.current.userInterfaceIdiom == .pad {
                return .large
            }
            #endif
        }
        return size
    }

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

    private var stateHint: String {
        switch state {
        case .idle: return "Still waiting for evening. Take your time."
        case .attentive: return "Tap to begin your reflection."
        case .recording: return "Recording your reflection."
        case .complete: return "Reflection complete. Good night."
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
                        endRadius: resolvedSize.gradientRadius
                    )
                )
                .opacity(orbOpacity)
                .scaleEffect(scale)
                .shadow(color: glowColor, radius: resolvedSize.glowRadius1, x: 0, y: 0)
                .shadow(color: glowColor, radius: resolvedSize.glowRadius2, x: 0, y: 0)
        }
        .frame(width: resolvedSize.dimension, height: resolvedSize.dimension)
        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: scale)
        .accessibilityLabel("Breathing orb")
        .accessibilityHint(stateHint)
    }
}
