import Foundation

final class QuestionBank {
    static nonisolated(unsafe) let shared = QuestionBank()

    private var allQuestions: [QuestionItem] = []
    private var usedQuestionIndices: Set<Int> = []
    private let cycleLength: Int

    private let categoryMap: [String: QuestionCategory] = [
        "exhausted": .exhaustion, "drained": .exhaustion, "energy": .exhaustion,
        "surprised": .surprise, "unexpected": .surprise, "showed up": .surprise,
        "almost say": .honesty, "didn't say": .honesty, "wish i had said": .honesty,
        "avoid": .avoidance, "pretending": .avoidance, "fine": .avoidance, "truth": .avoidance,
        "grateful": .gratitude, "thankful": .gratitude, "appreciate": .gratitude,
        "learned about yourself": .selfDiscovery, "about yourself": .selfDiscovery,
        "connection": .connection, "seen": .connection, "unseen": .connection,
        "let go": .lettingGo, "release": .lettingGo, "holding": .lettingGo,
        "meaning": .meaning, "mattered": .meaning, "life": .meaning,
    ]

    struct QuestionItem {
        let text: String
        var category: QuestionCategory
        var averageRating: Double
        var timesAsked: Int
    }

    private init() {
        let rawQuestions: [(String, QuestionCategory)] = [
            ("What exhausted you today?", .exhaustion),
            ("What surprised you?", .surprise),
            ("What did you almost say?", .honesty),
            ("What did you learn about yourself?", .selfDiscovery),
            ("What are you carrying that isn't yours?", .lettingGo),
            ("What felt most true?", .selfDiscovery),
            ("What did you avoid?", .avoidance),
            ("What are you pretending is fine?", .avoidance),
            ("What made you laugh today?", .gratitude),
            ("What do you need to let go of?", .lettingGo),
            ("What showed up that you didn't expect?", .surprise),
            ("What are you grateful for tonight?", .gratitude),
            ("What conversation stayed with you?", .connection),
            ("What did you do for yourself?", .gratitude),
            ("What drained you?", .exhaustion),
            ("What filled you?", .gratitude),
            ("What did you notice that others missed?", .selfDiscovery),
            ("What do you wish you had said?", .honesty),
            ("What are you proud of?", .gratitude),
            ("What surprised you about yourself?", .surprise),
            ("What felt heavy today?", .exhaustion),
            ("What felt light?", .gratitude),
            ("What do you need tomorrow?", .meaning),
            ("What are you looking forward to?", .meaning),
            ("What worried you today?", .avoidance),
            ("What brought you peace?", .gratitude),
            ("What challenged your thinking?", .selfDiscovery),
            ("What made you feel seen?", .connection),
            ("What made you feel unseen?", .connection),
            ("What would you do differently if you could?", .selfDiscovery),
            ("What truth are you avoiding?", .avoidance),
            ("What boundary do you need?", .selfDiscovery),
            ("What connection mattered?", .connection),
            ("What are you overthinking?", .avoidance),
            ("What are you underestimating?", .surprise),
            ("What story are you telling yourself?", .selfDiscovery),
            ("What do you need to forgive?", .lettingGo),
            ("What made you feel alive?", .meaning),
            ("What drained your energy?", .exhaustion),
            ("What gave you energy?", .gratitude),
            ("What are you holding tightly?", .lettingGo),
            ("What would you release if you could?", .lettingGo),
            ("What made you feel proud today?", .gratitude),
            ("What made you feel small?", .avoidance),
            ("What did you learn about someone else?", .selfDiscovery),
            ("What are you curious about?", .meaning),
            ("What would make tomorrow meaningful?", .meaning),
            ("What are you proving to yourself?", .selfDiscovery),
            ("What are you proving to others?", .selfDiscovery),
            ("What do you know now that you didn't this morning?", .selfDiscovery),
            ("What stayed unfinished?", .avoidance),
            ("What felt complete?", .gratitude),
            ("What do you wish you had known?", .surprise),
            ("What would you tell your morning self?", .connection),
            ("What question is living in you tonight?", .meaning),
            ("What do you want to remember about today?", .meaning),
            ("What needs your attention?", .avoidance),
            ("What can wait until tomorrow?", .lettingGo),
            ("What are you learning to feel?", .selfDiscovery),
            ("What are you practicing?", .selfDiscovery),
            ("What would silence sound like?", .meaning),
            ("What would stillness feel like?", .meaning),
            ("What are you becoming?", .meaning),
        ]

        allQuestions = rawQuestions.map { QuestionItem(text: $0.0, category: $0.1, averageRating: 3.0, timesAsked: 0) }
        cycleLength = allQuestions.count
        loadUsedIndices()
        loadRatings()
    }

    func category(for question: String) -> QuestionCategory {
        if let existing = allQuestions.first(where: { $0.text == question }) {
            return existing.category
        }
        for (key, cat) in categoryMap {
            if question.lowercased().contains(key) {
                return cat
            }
        }
        return .other
    }

    private func loadUsedIndices() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "usedQuestionIndices"),
           let indices = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            usedQuestionIndices = indices
        }
    }

    private func saveUsedIndices() {
        if let data = try? JSONEncoder().encode(usedQuestionIndices) {
            UserDefaults.standard.set(data, forKey: "usedQuestionIndices")
        }
    }

    private func loadRatings() {
        guard let data = UserDefaults.standard.data(forKey: "questionRatings"),
              let ratings = try? JSONDecoder().decode([Int: Double].self, from: data) else { return }
        for (idx, rating) in ratings {
            if idx < allQuestions.count {
                allQuestions[idx].averageRating = rating
            }
        }
    }

    func recordRating(for question: String, rating: Int) {
        guard let idx = allQuestions.firstIndex(where: { $0.text == question }) else { return }
        let oldCount = allQuestions[idx].timesAsked
        let oldRating = allQuestions[idx].averageRating
        allQuestions[idx].timesAsked += 1
        allQuestions[idx].averageRating = (oldRating * Double(oldCount) + Double(rating)) / Double(allQuestions[idx].timesAsked)

        var ratings: [Int: Double] = [:]
        if let data = UserDefaults.standard.data(forKey: "questionRatings"),
           let existing = try? JSONDecoder().decode([Int: Double].self, from: data) {
            ratings = existing
        }
        ratings[idx] = allQuestions[idx].averageRating
        if let data = try? JSONEncoder().encode(ratings) {
            UserDefaults.standard.set(data, forKey: "questionRatings")
        }
    }

    func todaysQuestion(excluding: String? = nil) -> String {
        // Check for AI-generated seasonal or day-of-week questions
        if let aiQuestion = todaysPersonalizedQuestion() {
            return aiQuestion
        }

        var availableIndices = Set(0..<cycleLength)
        availableIndices.subtract(usedQuestionIndices)

        if availableIndices.isEmpty {
            usedQuestionIndices.removeAll()
            availableIndices = Set(0..<cycleLength)
        }

        // Prefer higher-rated questions that haven't been used recently
        let sorted = availableIndices.sorted { a, b in
            let ratingA = allQuestions[a].averageRating
            let ratingB = allQuestions[b].averageRating
            if abs(ratingA - ratingB) < 0.5 {
                return allQuestions[a].timesAsked < allQuestions[b].timesAsked
            }
            return ratingA > ratingB
        }

        let selectedIndex = sorted.first ?? Array(availableIndices).randomElement() ?? 0
        usedQuestionIndices.insert(selectedIndex)
        saveUsedIndices()

        let question = allQuestions[selectedIndex].text
        if let excluding = excluding, question == excluding {
            return todaysQuestion(excluding: excluding)
        }
        return question
    }

    /// Returns an AI-personalized question if patterns are detected
    func todaysPersonalizedQuestion() -> String? {
        // Use seasonal question once per season (roughly)
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let seasonKey = dayOfYear / 90 // ~4 seasons

        let lastSeasonKey = UserDefaults.standard.integer(forKey: "lastUsedSeasonKey")
        if seasonKey != lastSeasonKey || UserDefaults.standard.string(forKey: "todaySeasonalQuestion") == nil {
            if let seasonal = AIService.shared.seasonalQuestion() {
                UserDefaults.standard.set(seasonal, forKey: "todaySeasonalQuestion")
                UserDefaults.standard.set(seasonKey, forKey: "lastUsedSeasonKey")
                return seasonal
            }
        }

        // Use day-of-week question (different each day)
        let todayKey = calendar.isDateInToday(Date()) ? "today" : "yesterday"
        if let dayQuestion = AIService.shared.dayOfWeekQuestion() {
            let stored = UserDefaults.standard.string(forKey: "lastDayQuestion") ?? ""
            if stored != dayQuestion {
                UserDefaults.standard.set(dayQuestion, forKey: "lastDayQuestion")
                return dayQuestion
            }
        }

        // Use AI-generated follow-up if we have a recent reflection
        let recentReflections = DatabaseService.shared.getAllReflections().prefix(3)
        if let lastReflection = recentReflections.first,
           let followUp = AIService.shared.personalizedFollowUp(for: lastReflection) {
            return followUp
        }

        return UserDefaults.standard.string(forKey: "todaySeasonalQuestion")
    }

    func questionForDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear + usedQuestionIndices.hashValue) % cycleLength
        return allQuestions[index].text
    }

    func topCategories(limit: Int = 3) -> [QuestionCategory] {
        var categoryScores: [QuestionCategory: (total: Double, count: Int)] = [:]
        for q in allQuestions {
            let current = categoryScores[q.category] ?? (0, 0)
            categoryScores[q.category] = (current.total + q.averageRating, current.count + 1)
        }
        return categoryScores
            .filter { $0.value.count >= 1 }
            .sorted { a, b in
                let avgA = a.value.total / Double(a.value.count)
                let avgB = b.value.total / Double(b.value.count)
                return avgA > avgB
            }
            .prefix(limit)
            .map { $0.key }
    }

    func suggestedQuestionForCategory(_ category: QuestionCategory) -> String? {
        allQuestions
            .filter { $0.category == category && $0.averageRating >= 3.5 }
            .sorted { $0.averageRating > $1.averageRating }
            .first?.text
    }
}
