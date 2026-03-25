import CoreHaptics
import UIKit

final class HapticManager {
    static nonisolated(unsafe) let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var isEngineRunning = false

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

    private func fallbackImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
