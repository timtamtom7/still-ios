import Foundation
import Combine
import SwiftUI

enum RitualState {
    case waiting
    case ready
    case reflecting
    case completed
    case skipped
}

final class RitualViewModel: ObservableObject {
    @Published var state: RitualState = .waiting
    @Published var todaysQuestion: String = ""
    @Published var reflectionText: String = ""
    @Published var showNudge: Bool = false
    @Published var nudgeMessage: String = ""

    private let db = DatabaseService.shared
    private let questionBank = QuestionBank.shared
    private let haptics = HapticManager.shared
    private let cloudKit = CloudKitService.shared

    private var breathingTimer: Timer?
    @Published var breathingScale: CGFloat = 1.0

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
    }

    func loadState() {
        let today = Date()

        if hasReflectedTonight {
            state = .completed
            return
        }

        if !isEvening {
            if db.getReflections(for: Calendar.current.date(byAdding: .day, value: -1, to: today)!).isEmpty {
                showNudge = true
                nudgeMessage = "Still held yesterday's question for you"
            }
            state = .waiting
            return
        }

        todaysQuestion = questionBank.todaysQuestion()
        state = .ready
    }

    func startBreathing() {
        breathingTimer?.invalidate()
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                self?.breathingScale = 1.08
            }
        }
    }

    func stopBreathing() {
        breathingTimer?.invalidate()
        breathingTimer = nil
    }

    func tapOrb() {
        guard state == .ready else { return }
        haptics.breathingPulse()
        withAnimation(.easeInOut(duration: 0.6)) {
            state = .reflecting
        }
    }

    func submitReflection() {
        guard !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        haptics.submitTap()

        let reflection = Reflection(
            question: todaysQuestion,
            text: reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try db.saveReflection(reflection)
            cloudKit.saveReflection(reflection) { _ in }

            withAnimation(.easeInOut(duration: 1.2)) {
                state = .completed
            }
        } catch {
            print("Failed to save reflection: \(error)")
        }
    }

    func dismissNudge() {
        withAnimation(.easeInOut(duration: 0.4)) {
            showNudge = false
        }
    }

    func resetForTesting() {
        state = .ready
        reflectionText = ""
        todaysQuestion = questionBank.todaysQuestion()
    }
}
