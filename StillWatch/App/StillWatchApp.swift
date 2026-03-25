import SwiftUI
import WatchKit

@main
struct StillWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchBreathingView()
        }
    }
}

struct WatchBreathingView: View {
    @State private var phase: BreathingPhase = .idle
    @State private var isBreathing = false
    @State private var breatheTimer: Timer?
    @State private var countdown: Int = 4
    @State private var cycleCount = 0

    private let amberColor = Color(red: 0.980, green: 0.745, blue: 0.286)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Phase label
                    Text(phase.rawValue)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(amberColor)

                    // Orb
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [amberColor, amberColor.opacity(0.6), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                            .opacity(orbOpacity)
                            .scaleEffect(orbScale)

                        Circle()
                            .stroke(amberColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 80, height: 80)
                    }
                    .frame(width: 80, height: 80)

                    // Countdown or cycle
                    if isBreathing {
                        Text("\(countdown)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else if cycleCount > 0 {
                        Text("\(cycleCount) cycles")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Start/Stop button
                    Button {
                        if isBreathing {
                            stopBreathing()
                        } else {
                            startBreathing()
                        }
                    } label: {
                        Text(isBreathing ? "Stop" : "Begin")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(amberColor)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Still")
        }
    }

    private var orbOpacity: Double {
        switch phase {
        case .inhale: return 0.6
        case .hold: return 0.8
        case .exhale: return 0.4
        default: return 0.5
        }
    }

    private var orbScale: CGFloat {
        switch phase {
        case .inhale: return 1.15
        case .hold: return 1.15
        case .exhale: return 0.85
        default: return 1.0
        }
    }

    private func startBreathing() {
        isBreathing = true
        phase = .inhale
        WKInterfaceDevice.current().play(.start)
        runBreathingCycle()
    }

    private func stopBreathing() {
        isBreathing = false
        breatheTimer?.invalidate()
        breatheTimer = nil
        phase = .idle
        WKInterfaceDevice.current().play(.stop)
    }

    private func runBreathingCycle() {
        guard isBreathing else { return }

        // Inhale: 4 seconds
        phase = .inhale
        countdown = 4
        runCountdown {
            guard self.isBreathing else { return }

            // Hold: 4 seconds
            self.phase = .hold
            self.countdown = 4
            WKInterfaceDevice.current().play(.click)
            self.runCountdown {
                guard self.isBreathing else { return }

                // Exhale: 4 seconds
                self.phase = .exhale
                self.countdown = 4
                self.runCountdown {
                    guard self.isBreathing else { return }

                    self.cycleCount += 1
                    WKInterfaceDevice.current().play(.success)
                    // Start next cycle
                    self.runBreathingCycle()
                }
            }
        }
    }

    private func runCountdown(onComplete: @escaping () -> Void) {
        var remaining = countdown
        breatheTimer?.invalidate()
        breatheTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            remaining -= 1
            self.countdown = remaining
            if remaining <= 0 {
                timer.invalidate()
                onComplete()
            }
        }
    }
}

enum BreathingPhase: String {
    case idle = "Ready"
    case inhale = "Breathe In"
    case hold = "Hold"
    case exhale = "Breathe Out"
}
