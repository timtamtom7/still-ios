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
    @State private var totalSeconds: Int = 0
    @State private var sessionTimer: Timer?

    private let amberColor = Color(red: 0.980, green: 0.745, blue: 0.286)
    private let breatheDuration = 4  // 4 seconds inhale, 4 seconds exhale
    private let holdDuration = 4      // 4 second hold

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Phase label
                    Text(phase.label)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(amberColor)
                        .animation(.easeInOut(duration: 0.5), value: phase)

                    // Orb
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [amberColor.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .scaleEffect(orbScale * 1.1)
                            .opacity(orbOpacity * 0.5)

                        // Main orb
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [amberColor, amberColor.opacity(0.7), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 45
                                )
                            )
                            .scaleEffect(orbScale)
                            .opacity(orbOpacity)

                        // Ring
                        Circle()
                            .stroke(amberColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 70, height: 70)
                            .scaleEffect(orbScale * 0.9)
                    }
                    .frame(width: 80, height: 80)

                    // Countdown or session info
                    if isBreathing {
                        VStack(spacing: 2) {
                            Text("\(countdown)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("seconds")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else if cycleCount > 0 || totalSeconds > 0 {
                        VStack(spacing: 2) {
                            if cycleCount > 0 {
                                Text("\(cycleCount) cycles")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if totalSeconds > 0 {
                                Text(formattedTime(totalSeconds))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
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
                        Text(isBreathing ? "End Session" : "Begin")
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var orbOpacity: Double {
        switch phase {
        case .idle: return 0.5
        case .inhale: return Double(countdown) / Double(breatheDuration) * 0.3 + 0.5
        case .hold: return 0.8
        case .exhale: return 0.8 - Double(breatheDuration - countdown) / Double(breatheDuration) * 0.3
        }
    }

    private var orbScale: CGFloat {
        switch phase {
        case .idle: return 1.0
        case .inhale: return 0.85 + CGFloat(countdown) / CGFloat(breatheDuration) * 0.15
        case .hold: return 1.0
        case .exhale: return 1.0 - CGFloat(breatheDuration - countdown) / CGFloat(breatheDuration) * 0.15
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }

    private func startBreathing() {
        isBreathing = true
        cycleCount = 0
        totalSeconds = 0
        phase = .inhale
        WKInterfaceDevice.current().play(.start)

        // Start session timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            totalSeconds += 1
        }

        runBreathingCycle()
    }

    private func stopBreathing() {
        isBreathing = false
        breatheTimer?.invalidate()
        breatheTimer = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
        phase = .idle
        countdown = breatheDuration
        WKInterfaceDevice.current().play(.stop)
    }

    private func runBreathingCycle() {
        guard isBreathing else { return }

        // Inhale phase: 4 seconds
        phase = .inhale
        countdown = breatheDuration
        runCountdown { [self] in
            guard self.isBreathing else { return }

            // Hold phase: 4 seconds
            self.phase = .hold
            self.countdown = self.holdDuration
            self.runCountdown {
                guard self.isBreathing else { return }

                // Exhale phase: 4 seconds
                self.phase = .exhale
                self.countdown = self.breatheDuration
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
            self.countdown = max(0, remaining)
            if remaining <= 0 {
                timer.invalidate()
                onComplete()
            }
        }
    }
}

enum BreathingPhase {
    case idle
    case inhale
    case hold
    case exhale

    var label: String {
        switch self {
        case .idle: return "Ready"
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        }
    }
}
