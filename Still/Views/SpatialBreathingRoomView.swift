import SwiftUI

/// R14: Vision Pro spatial breathing room
/// Immersive breathing environments
struct SpatialBreathingRoomView: View {
    @State private var selectedEnvironment: BreathingEnvironment = .ocean
    @State private var isSessionActive = false
    @State private var currentPhase: BreathPhase = .inhale
    @State private var cycleCount = 0

    enum BreathingEnvironment: String, CaseIterable {
        case ocean = "Ocean"
        case forest = "Forest"
        case mountain = "Mountain"
        case space = "Space"

        var icon: String {
            switch self {
            case .ocean: return "water.waves"
            case .forest: return "leaf.fill"
            case .mountain: return "mountain.2.fill"
            case .space: return "moon.stars.fill"
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .ocean:
                return [Color(hex: "0A1628"), Color(hex: "1A3A5C"), Color(hex: "2A5A8C")]
            case .forest:
                return [Color(hex: "0A2818"), Color(hex: "1A4A2C"), Color(hex: "2A6A40")]
            case .mountain:
                return [Color(hex: "1A1A28"), Color(hex: "2A2A4C"), Color(hex: "3A3A70")]
            case .space:
                return [Color(hex: "050510"), Color(hex: "0A0A20"), Color(hex: "151540")]
            }
        }
    }

    enum BreathPhase: String {
        case inhale = "Breathe In"
        case hold = "Hold"
        case exhale = "Breathe Out"
        case rest = "Rest"

        var duration: Double {
            switch self {
            case .inhale: return 4.0
            case .hold: return 4.0
            case .exhale: return 6.0
            case .rest: return 2.0
            }
        }
    }

    var body: some View {
        ZStack {
            // Environment background
            LinearGradient(
                colors: selectedEnvironment.gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: selectedEnvironment)

            VStack(spacing: 32) {
                // Environment selector
                environmentSelector

                Spacer()

                // Breathing orb
                breathingOrb

                // Phase instruction
                phaseText

                // Cycle counter
                if isSessionActive {
                    cycleCounter
                }

                Spacer()

                // Control buttons
                controlButtons
            }
            .padding()
        }
    }

    private var environmentSelector: some View {
        HStack(spacing: 16) {
            ForEach(BreathingEnvironment.allCases, id: \.self) { env in
                Button {
                    withAnimation {
                        selectedEnvironment = env
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: env.icon)
                            .font(.title2)
                        Text(env.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(selectedEnvironment == env ? .white : .white.opacity(0.4))
                    .padding()
                    .background(selectedEnvironment == env ? Color.white.opacity(0.2) : Color.clear)
                    .cornerRadius(12)
                }
            }
        }
    }

    private var breathingOrb: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(isSessionActive ? 0.3 : 0.1), Color.clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: isSessionActive ? 30 : 10)

            // Main orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.white.opacity(0.5), Color.white.opacity(0.1)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: orbSize, height: orbSize)
                .animation(.easeInOut(duration: currentPhase.duration), value: currentPhase)

            // Inner glow when active
            if isSessionActive {
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: orbSize + 20, height: orbSize + 20)
                    .blur(radius: 5)
            }
        }
    }

    private var orbSize: CGFloat {
        guard isSessionActive else { return 120 }
        switch currentPhase {
        case .inhale: return 80
        case .hold: return 120
        case .exhale: return 160
        case .rest: return 120
        }
    }

    private var phaseText: some View {
        Group {
            if isSessionActive {
                Text(currentPhase.rawValue)
                    .font(.title)
                    .fontWeight(.light)
                    .foregroundColor(.white)
                    .opacity(0.8)
            } else {
                Text("Ready to breathe")
                    .font(.title)
                    .fontWeight(.light)
                    .foregroundColor(.white)
                    .opacity(0.6)
            }
        }
        .animation(.easeInOut, value: isSessionActive)
    }

    private var cycleCounter: some View {
        Text("Cycle \(cycleCount)")
            .font(.caption)
            .foregroundColor(.white)
            .opacity(0.5)
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            if isSessionActive {
                Button {
                    stopSession()
                } label: {
                    Label("End", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.6))
                        .cornerRadius(12)
                }
            } else {
                Button {
                    startSession()
                } label: {
                    Label("Begin", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.6))
                        .cornerRadius(12)
                }
            }
        }
    }

    private func startSession() {
        isSessionActive = true
        cycleCount = 1
        currentPhase = .inhale

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isSessionActive {
                timer.invalidate()
                return
            }

            // Phase transition
            DispatchQueue.main.asyncAfter(deadline: .now() + currentPhase.duration) {
                guard isSessionActive else { return }
                withAnimation {
                    switch currentPhase {
                    case .inhale:
                        currentPhase = .hold
                    case .hold:
                        currentPhase = .exhale
                    case .exhale:
                        currentPhase = .rest
                    case .rest:
                        currentPhase = .inhale
                        cycleCount += 1
                    }
                }
            }
        }
    }

    private func stopSession() {
        isSessionActive = false
        currentPhase = .inhale
    }
}
