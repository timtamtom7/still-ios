import Foundation
import NaturalLanguage

/// AI-powered question personalization service
/// Uses on-device NLP to analyze reflection patterns and suggest relevant questions
final class AIService {
    static nonisolated(unsafe) let shared = AIService()

    private init() {}

    // MARK: - Reflection Pattern Analysis

    /// Analyzes recent reflections to identify themes and patterns
    func analyzeReflectionPatterns(_ reflections: [Reflection]) -> ReflectionPatterns {
        guard reflections.count >= 2 else {
            return ReflectionPatterns(
                dominantEmotion: nil,
                recurringThemes: [],
                interpersonalTopics: false,
                selfDiscoveryTopics: false,
                stressIndicators: false,
                growthIndicators: false
            )
        }

        let texts = reflections.map { $0.text.lowercased() }
        let combinedText = texts.joined(separator: " ")

        let emotionIndicators = detectEmotionIndicators(combinedText)
        let themes = detectThemes(combinedText)
        let hasInterpersonal = containsInterpersonal(combinedText)
        let hasSelfDiscovery = containsSelfDiscovery(combinedText)
        let hasStress = containsStressIndicators(combinedText)
        let hasGrowth = containsGrowthIndicators(combinedText)

        return ReflectionPatterns(
            dominantEmotion: emotionIndicators,
            recurringThemes: themes,
            interpersonalTopics: hasInterpersonal,
            selfDiscoveryTopics: hasSelfDiscovery,
            stressIndicators: hasStress,
            growthIndicators: hasGrowth
        )
    }

    /// Generates a personalized follow-up question based on the last reflection
    func personalizedFollowUp(for reflection: Reflection) -> String? {
        let text = reflection.text.lowercased()
        let patterns = analyzeReflectionPatterns([reflection])

        // Stress/burden patterns → letting go questions
        if text.contains("carrying") || text.contains("weight") || text.contains("burden") {
            return "What would it feel like to set this down, even just for tonight?"
        }

        // Connection patterns → deeper connection questions
        if text.contains("missed") || text.contains("wish i") || text.contains("almost said") {
            return "What kept you from speaking what was living in you?"
        }

        // Exhaustion patterns → rest and renewal questions
        if text.contains("tired") || text.contains("drain") || text.contains("exhaust") {
            return "What would rest look like if you gave yourself permission?"
        }

        // Avoidance patterns → truth questions
        if text.contains("fine") || text.contains("pretending") || text.contains("avoid") {
            return "What's true that you've been moving away from?"
        }

        // Surprise patterns → integration questions
        if text.contains("surprise") || text.contains("didn't expect") {
            return "How are you making room for this unexpected thing?"
        }

        // Growth patterns
        if text.contains("learned") || text.contains("realized") || text.contains("noticed") {
            return "What does this awareness want from you?"
        }

        // Gratitude patterns
        if text.contains("grateful") || text.contains("thankful") || text.contains("appreciate") {
            return "What would it mean to let this feeling linger a little longer?"
        }

        return nil
    }

    /// Suggests questions for the coming week based on past reflections
    func suggestWeeklyQuestions(reflectingOn recentReflections: [Reflection]) -> [String] {
        guard !recentReflections.isEmpty else { return [] }

        let patterns = analyzeReflectionPatterns(recentReflections)
        var suggestions: [String] = []

        // Theme-based suggestions
        if patterns.stressIndicators {
            suggestions.append("What part of your day needs gentleness tonight?")
        }

        if patterns.interpersonalTopics {
            suggestions.append("What connection are you longing for?")
        }

        if patterns.selfDiscoveryTopics {
            suggestions.append("What are you learning about how you show up in the world?")
        }

        if patterns.growthIndicators {
            suggestions.append("What feels newly possible since last week?")
        }

        // Add category-based suggestions
        let topCategories = QuestionBank.shared.topCategories(limit: 2)
        for category in topCategories {
            if let question = QuestionBank.shared.suggestedQuestionForCategory(category) {
                suggestions.append(question)
            }
        }

        return Array(suggestions.prefix(4))
    }

    /// Analyzes a reflection and extracts key sentiment/mood
    func extractMood(from reflection: Reflection) -> ReflectionMood {
        let text = reflection.text.lowercased()

        if text.contains("grateful") || text.contains("thankful") || text.contains("joy") || text.contains("happy") {
            return .grateful
        }

        if text.contains("sad") || text.contains("lonely") || text.contains("miss") || text.contains("alone") {
            return .melancholic
        }

        if text.contains("anxious") || text.contains("worried") || text.contains("stress") || text.contains("overwhelm") {
            return .anxious
        }

        if text.contains("peaceful") || text.contains("calm") || text.contains("settled") || text.contains("still") {
            return .peaceful
        }

        if text.contains("energized") || text.contains("excited") || text.contains("alive") || text.contains("inspired") {
            return .energized
        }

        if text.contains("confused") || text.contains("uncertain") || text.contains("lost") || text.contains("unclear") {
            return .confused
        }

        return .neutral
    }

    /// Computes a seasonal question suggestion based on time of year
    func seasonalQuestion() -> String? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let day = calendar.component(.day, from: Date())

        // Spring (March-May)
        if month >= 3 && month <= 5 {
            return "What is ready to bloom in your life right now?"
        }

        // Summer (June-August)
        if month >= 6 && month <= 8 {
            return "What are you fully present for this season?"
        }

        // Fall (September-November)
        if month >= 9 && month <= 11 {
            return "What is ready to be gathered from these months?"
        }

        // Winter (December-February)
        if month == 12 || month <= 2 {
            return "What do you need to let rest during these quiet months?"
        }

        return nil
    }

    /// Generates a contextual question based on day of week
    func dayOfWeekQuestion() -> String? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())

        switch weekday {
        case 2: // Monday
            return "How do you want to meet this week?"
        case 3: // Tuesday
            return "What showed up unexpectedly today?"
        case 4: // Wednesday
            return "What's in the middle of becoming?"
        case 5: // Thursday
            return "What are you moving toward without realizing it?"
        case 6: // Friday
            return "What are you ready to release as this week closes?"
        case 7: // Saturday
            return "What does your body need today?"
        case 1: // Sunday
            return "What threads from this week do you want to weave forward?"
        default:
            return nil
        }
    }

    // MARK: - Private Helpers

    private func detectEmotionIndicators(_ text: String) -> String? {
        let emotionKeywords: [(keywords: [String], emotion: String)] = [
            (["grateful", "thankful", "appreciate", "blessed"], "gratitude"),
            (["tired", "exhaust", "drain", "heavy", "worn"], "exhaustion"),
            (["connect", "seen", "heard", "miss", "alone", "lonely"], "connection"),
            (["learn", "realize", "notice", "discover", "understand"], "discovery"),
            (["peace", "calm", "still", "settle", "rest"], "peace"),
            (["anxious", "worry", "stress", "overwhelm", "fear"], "anxiety"),
            (["happy", "joy", "laugh", "smile", "light"], "joy"),
            (["sad", "heavy", "low", "grief", "loss"], "sadness"),
        ]

        var bestMatch: String?
        var bestCount = 0

        for (keywords, emotion) in emotionKeywords {
            let count = keywords.filter { text.contains($0) }.count
            if count > bestCount {
                bestCount = count
                bestMatch = emotion
            }
        }

        return bestCount >= 1 ? bestMatch : nil
    }

    private func detectThemes(_ text: String) -> [String] {
        let themeKeywords: [(keywords: [String], theme: String)] = [
            (["start", "begin", "new", "first"], "beginnings"),
            (["end", "finish", "last", "done", "close"], "endings"),
            (["work", "job", "career", "professional"], "work"),
            (["home", "family", "kids", "partner", "spouse"], "family"),
            (["friend", "friends", "social", "community"], "friendship"),
            (["health", "body", "exercise", "sleep", "rest"], "health"),
            (["future", "hope", "plan", "dream", "goal"], "future"),
            (["past", "remember", "memory", "when", "used to"], "past"),
            (["change", "different", "shift", "grow", "become"], "growth"),
        ]

        var themes: [String] = []
        for (keywords, theme) in themeKeywords {
            if keywords.contains(where: { text.contains($0) }) {
                themes.append(theme)
            }
        }

        return themes
    }

    private func containsInterpersonal(_ text: String) -> Bool {
        let keywords = ["friend", "talk", "say", "people", "connect", "miss", "lonely", "seen", "heard", "alone", "together", "family", "partner", "wife", "husband", "mom", "dad", "child", "son", "daughter"]
        return keywords.contains { text.contains($0) }
    }

    private func containsSelfDiscovery(_ text: String) -> Bool {
        let keywords = ["learn", "realize", "notice", "understand", "figured", "thought", "wonder", "discover", "become", "pattern", "habit", "why", "reason"]
        return keywords.contains { text.contains($0) }
    }

    private func containsStressIndicators(_ text: String) -> Bool {
        let keywords = ["stress", "overwhelm", "anxious", "worry", "pressure", "deadline", "busy", "hectic", "exhaust", "drain", "tired", "burned out"]
        return keywords.contains { text.contains($0) }
    }

    private func containsGrowthIndicators(_ text: String) -> Bool {
        let keywords = ["learn", "grow", "change", "realize", "notice", "figured", "discover", "become", "progress", "better", "improved"]
        return keywords.contains { text.contains($0) }
    }
}

// MARK: - Supporting Types

struct ReflectionPatterns {
    let dominantEmotion: String?
    let recurringThemes: [String]
    let interpersonalTopics: Bool
    let selfDiscoveryTopics: Bool
    let stressIndicators: Bool
    let growthIndicators: Bool

    var hasSignificantPatterns: Bool {
        dominantEmotion != nil || !recurringThemes.isEmpty || interpersonalTopics || selfDiscoveryTopics
    }
}

enum ReflectionMood: String {
    case grateful
    case melancholic
    case anxious
    case peaceful
    case energized
    case confused
    case neutral

    var emoji: String {
        switch self {
        case .grateful: return "✨"
        case .melancholic: return "🌙"
        case .anxious: return "🌊"
        case .peaceful: return "🕯️"
        case .energized: return "⚡"
        case .confused: return "🌫️"
        case .neutral: return "🌿"
        }
    }

    var description: String {
        switch self {
        case .grateful: return "gratitude"
        case .melancholic: return "melancholy"
        case .anxious: return "anxiety"
        case .peaceful: return "peace"
        case .energized: return "energy"
        case .confused: return "confusion"
        case .neutral: return "neutral"
        }
    }
}
