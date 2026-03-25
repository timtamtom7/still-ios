import Foundation
import Combine
import SwiftUI

@MainActor
final class RitualViewModel: ObservableObject {
    @Published var state: RitualState = .waiting
    @Published var todaysQuestion: String = ""
    @Published var reflectionText: String = ""
    @Published var showNudge: Bool = false
    @Published var nudgeMessage: String = ""
    @Published var selectedSound: AmbientSound = .silence
    @Published var showRating: Bool = false
    @Published var showTypewriter: Bool = false

    // Memory lane
    @Published var oneYearAgoReflection: Reflection?
    @Published var oneMonthAgoReflection: Reflection?
    @Published var thisDayInHistoryReflections: [Reflection] = []

    private let db = DatabaseService.shared
    private let questionBank = QuestionBank.shared
    private let haptics = HapticManager.shared
    private let cloudKit = CloudKitService.shared
    private let soundManager = SoundManager.shared
    private let subscription = SubscriptionService.shared

    private var breathingTimer: Timer?
    private var typewriterTimer: Timer?
    private var typingDebounce: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    @Published var breathingScale: CGFloat = 1.0
    @Published var showSaveError: Bool = false
    @Published var saveErrorMessage: String = "Your reflection couldn't be saved. Please try again."
    @Published var showUpgradePrompt: Bool = false
    @Published var showOfflineBanner: Bool = false

    var isEvening: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 21 || hour < 6
    }

    var isSundayNight: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let hour = calendar.component(.hour, from: Date())
        return weekday == 1 && hour >= 21
    }

    var hasReflectedTonight: Bool {
        let today = Date()
        return db.hasReflection(for: today)
    }

    init() {
        loadState()
        setupTypingDetection()
        checkCloudKitStatus()
    }

    private func checkCloudKitStatus() {
        cloudKit.checkAccountStatus { available in
            DispatchQueue.main.async {
                self.showOfflineBanner = !available && self.cloudKit.isEnabled
            }
        }
    }

    private func setupTypingDetection() {
        $reflectionText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                if text.count > 10 && self?.state == .reflecting {
                    // User is actively typing - fade ambient sound
                    self?.soundManager.pauseForReflection()
                }
            }
            .store(in: &cancellables)
    }

    func loadState() {
        let today = Date()

        if hasReflectedTonight {
            state = .completed
            checkMemoryLane()
            return
        }

        if !isEvening {
            if db.getReflections(for: Calendar.current.date(byAdding: .day, value: -1, to: today)!).isEmpty == false {
                showNudge = true
                nudgeMessage = "Still held yesterday's question for you"
            }
            state = .waiting
            checkMemoryLane()
            return
        }

        todaysQuestion = questionBank.todaysQuestion()
        selectedSound = soundManager.currentSound
        state = .ready
        checkMemoryLane()
    }

    private func checkMemoryLane() {
        oneYearAgoReflection = db.getReflectionOneYearAgo()
        oneMonthAgoReflection = db.getReflectionOneMonthAgo()
        thisDayInHistoryReflections = db.getReflectionsOnThisDay()
    }

    func startBreathing() {
        breathingTimer?.invalidate()
        // 8-second breathing cycle: scale 1.0 → 1.08 over 4s, then back over 4s
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathingScale = 1.08
        }
        // Haptic pulses are handled by HapticManager.startBreathingHaptics()
        // which fires a gentle pulse at the inhale peak (4s mark) each cycle
        haptics.startBreathingHaptics()
    }

    func stopBreathing() {
        breathingTimer?.invalidate()
        breathingTimer = nil
        haptics.stopBreathingHaptics()
    }

    func tapOrb() {
        guard state == .ready else { return }
        haptics.breathingPulse()
        withAnimation(.easeInOut(duration: 0.6)) {
            state = .reflecting
        }

        // Start ambient sound for reflecting
        if selectedSound != .silence {
            soundManager.restoreVolume()
            soundManager.play()
        }

        // Trigger typewriter effect for question
        showTypewriter = true
    }

    func submitReflection() {
        guard !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Check weekly limit for free users
        if !subscription.isProActive && subscription.weeklyLimitReached {
            showSaveError = true
            showUpgradePrompt = true
            saveErrorMessage = "You've reached your \(subscription.currentTier.weeklyLimit ?? 3) reflections per week. Upgrade to Pro for unlimited reflections."
            return
        }

        haptics.submitTap()

        // Determine question category
        let category = questionBank.category(for: todaysQuestion)

        let reflection = Reflection(
            question: todaysQuestion,
            text: reflectionText.trimmingCharacters(in: .whitespacesAndNewlines),
            soundUsed: selectedSound,
            questionCategory: category
        )

        do {
            try db.saveReflection(reflection)
            subscription.incrementWeeklyCount()
            cloudKit.saveReflection(reflection) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.showSaveError = true
                    }
                }
            }

            withAnimation(.easeInOut(duration: 1.2)) {
                state = .completed
            }

            // Stop ambient sound
            soundManager.stop()

            // Show rating after a brief moment
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                self.showRating = true
            }
        } catch {
            print("Failed to save reflection: \(error)")
            showSaveError = true
            saveErrorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func rateQuestion(_ rating: Int) {
        questionBank.recordRating(for: todaysQuestion, rating: rating)
        showRating = false

        // Update the reflection with rating
        let today = Date()
        let todaysReflections = db.getReflections(for: today)
        if var lastReflection = todaysReflections.first {
            lastReflection.questionRating = rating
            try? db.updateReflection(lastReflection)
        }
    }

    func dismissNudge() {
        withAnimation(.easeInOut(duration: 0.4)) {
            showNudge = false
        }
    }

    func dismissSaveError() {
        showSaveError = false
    }

    func resetForTesting() {
        state = .ready
        reflectionText = ""
        todaysQuestion = questionBank.todaysQuestion()
        showRating = false
        showTypewriter = false
    }

    func selectSound(_ sound: AmbientSound) {
        selectedSound = sound
        soundManager.selectSound(sound)
        if sound != .silence && state == .reflecting {
            soundManager.play()
        } else {
            soundManager.stop()
        }
    }

}
