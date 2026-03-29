import SwiftUI

struct MeditationPlayerView: View {
    @State private var selectedDuration: Int = 10
    @State private var isPlaying: Bool = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer? = nil

    let durations = [3, 5, 10, 15, 20]

    var body: some View {
        ZStack {
            // Ambient gradient background
            AmbientBackground()

            VStack(spacing: 32) {
                Spacer()

                // Breathing circle
                BreathingCircle(isPlaying: isPlaying)

                // Session info
                VStack(spacing: 8) {
                    Text("Evening Calm")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(Theme.deepNavy)

                    Text("Sarah Chen")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.calmBlue.opacity(0.8))
                }

                // Timer display
                if isPlaying || elapsedSeconds > 0 {
                    Text(formatTime(elapsedSeconds) + " / " + formatTime(selectedDuration * 60))
                        .font(.system(size: 16, weight: .light, design: .monospaced))
                        .foregroundColor(Theme.deepNavy.opacity(0.6))
                }

                // Duration selector
                DurationSelector(selectedDuration: $selectedDuration, durations: durations, isDisabled: isPlaying)

                // Play/Pause button
                PlayPauseButton(isPlaying: $isPlaying) {
                    togglePlayback()
                }

                Spacer()
            }
            .padding(32)
        }
    }

    private func togglePlayback() {
        if isPlaying {
            stopTimer()
            isPlaying = false
        } else {
            if elapsedSeconds >= selectedDuration * 60 {
                elapsedSeconds = 0
            }
            startTimer()
            isPlaying = true
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
            if elapsedSeconds >= selectedDuration * 60 {
                stopTimer()
                isPlaying = false
                elapsedSeconds = 0
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct AmbientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Theme.softWhite,
                Theme.surface,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [
                    Theme.calmBlue.opacity(0.08),
                    .clear,
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
        )
        .ignoresSafeArea()
    }
}

struct BreathingCircle: View {
    let isPlaying: Bool
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.calmBlue.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
                .opacity(opacity)

            // Main orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.calmBlue, Theme.calmBlue.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(scale)
                .shadow(color: Theme.calmBlue.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            startBreathing()
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                opacity = 0.8
            } else {
                opacity = 0.6
            }
        }
    }

    private func startBreathing() {
        withAnimation(
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.08
        }
        withAnimation(
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
            .delay(0.5)
        ) {
            opacity = 0.75
        }
    }
}

struct DurationSelector: View {
    @Binding var selectedDuration: Int
    let durations: [Int]
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            ForEach(durations, id: \.self) { duration in
                Button {
                    selectedDuration = duration
                } label: {
                    Text("\(duration)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedDuration == duration ? .white : Theme.deepNavy.opacity(0.6))
                        .frame(width: 44, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedDuration == duration ? Theme.calmBlue : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .opacity(isDisabled && selectedDuration != duration ? 0.4 : 1.0)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct PlayPauseButton: View {
    @Binding var isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Theme.calmBlue)
                    .frame(width: 72, height: 72)
                    .shadow(color: Theme.calmBlue.opacity(0.4), radius: 12, y: 6)

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .offset(x: isPlaying ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPlaying ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPlaying)
    }
}
