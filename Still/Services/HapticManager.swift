import CoreHaptics
import UIKit

final class HapticManager {
    static nonisolated(unsafe) let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var isEngineRunning = false
    private var breathingPlayer: CHHapticAdvancedPatternPlayer?

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }
            engine?.stoppedHandler = { [weak self] _ in
                self?.isEngineRunning = false
            }
            engine?.isAutoShutdownEnabled = true
            try engine?.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine failed: \(error)")
        }
    }

    private func restartEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            try engine?.start()
            isEngineRunning = true
        } catch {
            print("Failed to restart haptic engine: \(error)")
        }
    }

    func breathingPulse() {
        guard isEngineRunning, let engine = engine else {
            fallbackImpact(.light)
            return
        }

        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.3)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallbackImpact(.light)
        }
    }

    func startBreathingHaptics() {
        guard isEngineRunning, let engine = engine else { return }

        do {
            // Create a subtle continuous pulse pattern
            // 8-second cycle: inhale (4s scale up) + exhale (4s scale down)
            // Gentle pulse at peak of inhale
            var events: [CHHapticEvent] = []

            // Subtle pulse at inhale peak (4 seconds in)
            let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25)
            let sharpness1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness1], relativeTime: 3.8, duration: 0.4)
            events.append(event1)

            let pattern = try CHHapticPattern(events: events, parameters: [])
            breathingPlayer = try engine.makeAdvancedPlayer(with: pattern)
            try breathingPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Breathing haptics failed: \(error)")
        }
    }

    func stopBreathingHaptics() {
        try? breathingPlayer?.stop(atTime: CHHapticTimeImmediate)
        breathingPlayer = nil
    }

    func submitTap() {
        guard isEngineRunning, let engine = engine else {
            fallbackImpact(.medium)
            return
        }

        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.15)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallbackImpact(.medium)
        }
    }

    func completionPulse() {
        guard isEngineRunning, let engine = engine else {
            fallbackImpact(.rigid)
            return
        }

        do {
            // Warm, affirming double pulse
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.3)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.2, duration: 0.3)
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallbackImpact(.rigid)
        }
    }

    private func fallbackImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
