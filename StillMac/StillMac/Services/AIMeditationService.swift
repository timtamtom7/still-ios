import Foundation
import NaturalLanguage

// MARK: - Sendable Conformance

extension AIMeditationService: @unchecked Sendable {}

/// Meditation goal/intent for AI recommendations
enum MeditationGoal: String, CaseIterable, Identifiable {
    case relax = "Relax"
    case sleep = "Sleep"
    case focus = "Focus"
    case anxiety = "Anxiety Relief"
    case morning = "Morning Energy"
    case stress = "Stress Relief"
    case bodyScan = "Body Scan"
    case breathing = "Breathing Exercise"

    var id: String { rawValue }
}

/// Represents a completed meditation session for history analysis
struct Session: Identifiable {
    let id = UUID()
    let date: Date
    let duration: Int
    let category: SessionCategory
    let completed: Bool
}

/// AI-powered meditation session recommendation service
final class AIMeditationService {
    static let shared = AIMeditationService()

    private let userDefaults = UserDefaults.standard
    private let sentimentAnalyzer = NLTagger(tagSchemes: [.sentimentScore])

    // MARK: - Recommendation History Keys

    private enum Keys {
        static let skipHistory = "AIMeditationService.skipHistory"
        static let preferenceHistory = "AIMeditationService.preferenceHistory"
        static let lastRecommendation = "AIMeditationService.lastRecommendation"
    }

    private init() {}

    // MARK: - Public API

    /// Recommend a session based on user's goal and meditation history
    func recommendSession(goal: MeditationGoal, history: [Session]) -> SessionRecommendation {
        let sessions = SessionLibrary.sessions(for: goalToCategory(goal))

        // Filter to available sessions
        let availableSessions = sessions.filter { session in
            !isRecentlySkipped(session)
        }

        // Score each session based on multiple factors
        let scoredSessions = availableSessions.map { session -> (MeditationSession, Int) in
            var score = 100

            // Time of day bonus
            score += timeOfDayBonus(for: session, goal: goal)

            // History-based scoring
            score += historyBonus(for: session, from: history)

            // Streak preservation bonus (prefer variety if on a streak)
            if let streak = getCurrentStreak(from: history), streak > 3 {
                score += varietyBonus(for: session, from: history)
            }

            // Goal alignment
            score += goalAlignmentBonus(for: session, goal: goal)

            return (session, score)
        }

        // Sort by score descending and pick the best
        let sorted = scoredSessions.sorted { $0.1 > $1.1 }
        guard let best = sorted.first else {
            // Fallback if all sessions were skipped
            return SessionRecommendation(
                session: SessionLibrary.sessions.randomElement()!,
                reason: "A calming session for you."
            )
        }

        // Generate human-readable reason
        let reason = generateReason(for: best.0, goal: goal, history: history)

        // Track this recommendation
        trackRecommendation(best.0)

        return SessionRecommendation(session: best.0, reason: reason)
    }

    /// Recommend a quick session "perfect for right now"
    func recommendForNow(history: [Session]) -> SessionRecommendation {
        let hour = Calendar.current.component(.hour, from: Date())

        // Determine implicit goal based on time
        let goal: MeditationGoal
        switch hour {
        case 5..<9:
            goal = .morning
        case 9..<17:
            goal = .focus
        case 17..<21:
            goal = .relax
        default:
            goal = .sleep
        }

        return recommendSession(goal: goal, history: history)
    }

    /// Get weekly suggested path based on patterns
    func weeklyPath(history: [Session]) -> [SessionRecommendation] {
        let patterns = analyzePatterns(history: history)
        var recommendations: [SessionRecommendation] = []

        // Suggest based on detected patterns
        if patterns.stressWeek {
            recommendations.append(recommendSession(goal: .stress, history: history))
        }

        if patterns.lowEngagement {
            recommendations.append(recommendSession(goal: .breathing, history: history))
        }

        if patterns.eveningsSkipped > 2 {
            recommendations.append(recommendSession(goal: .sleep, history: history))
        }

        // Always add a variety recommendation
        let varietyGoal = MeditationGoal.allCases.randomElement()!
        recommendations.append(recommendSession(goal: varietyGoal, history: history))

        return recommendations
    }

    /// Mark a session as skipped so we don't recommend it again soon
    func markSkipped(_ session: MeditationSession) {
        var skipped = getSkipHistory()
        skipped.append(SkipRecord(sessionId: session.id.uuidString, date: Date()))
        saveSkipHistory(skipped)
    }

    /// Get a simple nudge based on state
    func getNudge(goal: MeditationGoal?, history: [Session]) -> String {
        if let goal = goal {
            return "Ready for \(goal.rawValue.lowercased())?"
        }

        // Infer from history
        if history.isEmpty {
            return "Start your meditation journey today."
        }

        let lastSession = history.max(by: { $0.date < $1.date })
        if let last = lastSession {
            let hoursSince = Calendar.current.dateComponents([.hour], from: last.date, to: Date()).hour ?? 0
            if hoursSince > 48 {
                return "Stillness awaits when you're ready."
            } else if hoursSince > 24 {
                return "Your streak is waiting."
            }
        }

        return "Take a moment for yourself."
    }

    // MARK: - Private Helpers

    private func goalToCategory(_ goal: MeditationGoal) -> SessionCategory {
        switch goal {
        case .relax, .stress:
            return .breathing
        case .sleep:
            return .sleep
        case .focus:
            return .focus
        case .anxiety:
            return .anxiety
        case .morning:
            return .morning
        case .bodyScan:
            return .bodyScan
        case .breathing:
            return .breathing
        }
    }

    private func isRecentlySkipped(_ session: MeditationSession) -> Bool {
        let skipped = getSkipHistory()
        let recentCutoff = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
        return skipped.contains { $0.sessionId == session.id.uuidString && $0.date > recentCutoff }
    }

    private func timeOfDayBonus(for session: MeditationSession, goal: MeditationGoal) -> Int {
        let hour = Calendar.current.component(.hour, from: Date())

        // Morning sessions in morning hours
        if session.category == .morning && hour >= 5 && hour < 10 {
            return 20
        }

        // Sleep sessions in evening/night
        if session.category == .sleep && hour >= 20 || hour < 2 {
            return 20
        }

        // Short sessions during work hours
        if session.category == .focus && hour >= 9 && hour < 17 && session.duration <= 10 {
            return 15
        }

        return 0
    }

    private func historyBonus(for session: MeditationSession, from history: [Session]) -> Int {
        let categorySessions = history.filter { $0.category == session.category && $0.completed }

        if categorySessions.isEmpty {
            return 10 // Fresh category, try it
        }

        let avgDuration = categorySessions.reduce(0) { $0 + $1.duration } / categorySessions.count

        // Prefer similar length sessions if they've been completing them
        if abs(session.duration - avgDuration) < 5 {
            return 5
        }

        return 0
    }

    private func getCurrentStreak(from history: [Session]) -> Int? {
        let completedSessions = history.filter { $0.completed }.sorted { $0.date > $1.date }

        guard !completedSessions.isEmpty else { return nil }

        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for session in completedSessions {
            let sessionDay = Calendar.current.startOfDay(for: session.date)

            if sessionDay == currentDate || sessionDay == Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                if sessionDay != currentDate {
                    streak += 1
                    currentDate = sessionDay
                } else {
                    streak += 1
                }
            } else {
                break
            }
        }

        return streak > 0 ? streak : nil
    }

    private func varietyBonus(for session: MeditationSession, from history: [Session]) -> Int {
        let recentCategories = Set(history.suffix(10).map { $0.category })

        if !recentCategories.contains(session.category) {
            return 15 // Encourage variety
        }

        return 0
    }

    private func goalAlignmentBonus(for session: MeditationSession, goal: MeditationGoal) -> Int {
        switch goal {
        case .anxiety:
            if session.category == .anxiety { return 30 }
            if session.category == .breathing { return 20 }
        case .sleep:
            if session.category == .sleep { return 30 }
        case .focus:
            if session.category == .focus { return 30 }
        case .breathing:
            if session.category == .breathing { return 30 }
        default:
            break
        }
        return 0
    }

    private func generateReason(for session: MeditationSession, goal: MeditationGoal, history: [Session]) -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        // Time-based reasons
        if hour >= 20 || hour < 2 {
            return "Perfect for winding down tonight."
        } else if hour >= 5 && hour < 9 {
            return "A gentle way to start your morning."
        } else if hour >= 9 && hour < 17 {
            return "Ideal for a midday reset."
        }

        // Streak-based reasons
        if let streak = getCurrentStreak(from: history), streak > 5 {
            return "Keep your \(streak)-day streak going!"
        }

        // History-based reasons
        let categoryHistory = history.filter { $0.category == session.category }
        if categoryHistory.count >= 3 {
            return "You've been enjoying \(session.category.rawValue.lowercased()) sessions."
        }

        // Goal-based reasons
        switch goal {
        case .anxiety:
            return "You've been feeling tense — this can help."
        case .sleep:
            return "Drift into restful sleep."
        case .focus:
            return "Clear your mind for what comes next."
        case .stress:
            return "Release the day's tension."
        default:
            return "A calming session for you."
        }
    }

    private func analyzePatterns(history: [Session]) -> WeeklyPatterns {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentSessions = history.filter { $0.date > weekAgo }

        let stressIndicators = recentSessions.filter {
            $0.category == .anxiety || $0.category == .breathing
        }

        let shortSessions = recentSessions.filter { $0.duration <= 5 }

        let eveningSessions = recentSessions.filter {
            let hour = Calendar.current.component(.hour, from: $0.date)
            return hour >= 19 || hour < 2
        }

        return WeeklyPatterns(
            stressWeek: stressIndicators.count > 3,
            lowEngagement: recentSessions.count < 3,
            eveningsSkipped: max(0, 7 - eveningSessions.count)
        )
    }

    private struct WeeklyPatterns {
        let stressWeek: Bool
        let lowEngagement: Bool
        let eveningsSkipped: Int
    }

    // MARK: - Skip History Management

    private struct SkipRecord: Codable {
        let sessionId: String
        let date: Date
    }

    private func getSkipHistory() -> [SkipRecord] {
        guard let data = userDefaults.data(forKey: Keys.skipHistory),
              let records = try? JSONDecoder().decode([SkipRecord].self, from: data) else {
            return []
        }

        // Filter out old records (older than 48 hours)
        let cutoff = Calendar.current.date(byAdding: .hour, value: -48, to: Date())!
        return records.filter { $0.date > cutoff }
    }

    private func saveSkipHistory(_ records: [SkipRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            userDefaults.set(data, forKey: Keys.skipHistory)
        }
    }

    private func trackRecommendation(_ session: MeditationSession) {
        userDefaults.set(session.id.uuidString, forKey: Keys.lastRecommendation)
    }
}

// MARK: - SessionRecommendation

extension AIMeditationService {
    struct SessionRecommendation: Identifiable {
        let id = UUID()
        let session: MeditationSession
        let reason: String

        var sessionName: String { session.name }
        var sessionDuration: Int { session.duration }
        var sessionCategory: SessionCategory { session.category }
    }
}
