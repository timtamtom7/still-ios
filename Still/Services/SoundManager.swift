import AVFoundation
import Foundation

final class SoundManager: ObservableObject {
    static nonisolated(unsafe) let shared = SoundManager()

    @Published var isPlaying: Bool = false
    @Published var currentSound: AmbientSound = .silence
    @Published var volume: Float = 0.6

    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var isFading: Bool = false

    private let userDefaultsKey = "selectedAmbientSound"

    private init() {
        setupAudioSession()
        loadSavedSound()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    private func loadSavedSound() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let sound = AmbientSound(rawValue: saved) {
            currentSound = sound
        }
    }

    func selectSound(_ sound: AmbientSound) {
        currentSound = sound
        UserDefaults.standard.set(sound.rawValue, forKey: userDefaultsKey)

        if sound == .silence {
            stop()
        }
    }

    func play() {
        guard currentSound != .silence else { return }

        // Use procedural audio generation for each sound type
        generateAndPlay(sound: currentSound)
        isPlaying = true
    }

    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isFading = false
    }

    func fadeOut(duration: TimeInterval = 3.0) {
        guard let player = audioPlayer, player.isPlaying, !isFading else { return }
        isFading = true

        let steps = 30
        let interval = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)

        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }

            if player.volume > volumeStep {
                player.volume -= volumeStep
            } else {
                timer.invalidate()
                player.stop()
                self.isPlaying = false
                self.isFading = false
                self.audioPlayer = nil
            }
        }
    }

    private func generateAndPlay(sound: AmbientSound) {
        // For rain, fireplace, brown noise, ocean: generate procedural audio
        // In production these would be bundled audio files
        // Here we create placeholder player that gracefully handles missing files
        guard sound != .silence else { return }

        // Try to load from bundle first
        let fileName = sound.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = volume
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                isPlaying = true
                return
            } catch {
                print("Audio file error: \(error)")
            }
        }

        // Fallback: generate synthetic audio using AVAudioEngine
        generateSyntheticAudio(for: sound)
    }

    private func generateSyntheticAudio(for sound: AmbientSound) {
        // Placeholder - in production would use AVAudioEngine to generate
        // brown noise, rain, ocean waves procedurally
        // For now, the app gracefully degrades without audio files
        print("[\(sound.rawValue)] Audio asset not found - add \(sound.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")).mp3 to Assets")
    }

    func restoreVolume() {
        audioPlayer?.volume = volume
        isFading = false
    }

    func pauseForReflection() {
        // Called when user starts typing - fade out ambient
        fadeOut(duration: 2.0)
    }
}
