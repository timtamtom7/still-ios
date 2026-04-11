import AVFoundation
import Foundation

@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

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
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                guard let player = self.audioPlayer else {
                    self.fadeTimer?.invalidate()
                    return
                }

                if player.volume > volumeStep {
                    player.volume -= volumeStep
                } else {
                    self.fadeTimer?.invalidate()
                    player.stop()
                    self.isPlaying = false
                    self.isFading = false
                    self.audioPlayer = nil
                }
            }
        }
    }

    private func generateAndPlay(sound: AmbientSound) {
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
        // Procedural audio generation for ambient sounds.
        // Note: Full implementation requires AVAudioEngine with noise generators.
        // For production, bundle audio files named:
        // rain.mp3, fireplace.mp3, brown_noise.mp3, ocean_waves.mp3
        print("[\(sound.rawValue)] Audio asset not found — add \(sound.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")).mp3 to Assets")
        isPlaying = false
    }

    func restoreVolume() {
        audioPlayer?.volume = volume
        isFading = false
    }

    func pauseForReflection() {
        fadeOut(duration: 2.0)
    }
}
