import Foundation
import Combine

struct WeekReviewSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let reflections: [Reflection]
}

struct WeekComparison: Equatable {
    let thisWeekCount: Int
    let lastWeekCount: Int
    let momentumScore: String
    let weekTheme: String?

    var difference: Int { thisWeekCount - lastWeekCount }

    var themeKeywords: [String] {
        ["transitions", "beginnings", "endings", "growth", "rest", "challenge", "connection", "clarity"]
    }
}

@MainActor
final class WeekReviewViewModel: ObservableObject {
    @Published var sections: [WeekReviewSection] = []
    @Published var daysUntilSunday: Int = 0
    @Published var isSunday: Bool = false
    @Published var isLoading: Bool = false
    @Published var loadError: String?
    @Published var weekComparison: WeekComparison?

    private let db = DatabaseService.shared

    init() {
        checkIfSunday()
        loadWeekReview()
    }

    func checkIfSunday() {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        isSunday = weekday == 1

        let daysUntil = (8 - calendar.component(.weekday, from: today)) % 7
        daysUntilSunday = daysUntil == 0 && !isSunday ? 7 : daysUntil
    }

    func loadWeekReview() {
        guard isSunday else {
            sections = []
            weekComparison = nil
            loadError = nil
            return
        }

        isLoading = true
        loadError = nil

        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            isLoading = false
            loadError = "Couldn't determine week boundaries"
            return
        }

        let weekReflections = db.getReflections(from: startOfWeek, to: endOfWeek)
        let thisWeekCount = db.getReflectionCountThisWeek()
        let lastWeekCount = db.getReflectionCountLastWeek()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)

            do {
                // Week comparison
                let momentum = computeMomentumScore(thisWeek: thisWeekCount, lastWeek: lastWeekCount, reflections: weekReflections)
                let theme = computeWeekTheme(from: weekReflections)

                weekComparison = WeekComparison(
                    thisWeekCount: thisWeekCount,
                    lastWeekCount: lastWeekCount,
                    momentumScore: momentum,
                    weekTheme: theme
                )

                // Section reflections
                let significant = weekReflections.filter { $0.text.count > 80 }
                let lighter = weekReflections.filter { $0.text.count <= 80 }
                let themeBased = extractPatterns(from: weekReflections)

                sections = [
                    WeekReviewSection(
                        title: "What mattered",
                        subtitle: "The reflections that carried weight",
                        reflections: significant
                    ),
                    WeekReviewSection(
                        title: "What faded",
                        subtitle: "Lighter moments, smaller observations",
                        reflections: lighter
                    ),
                    WeekReviewSection(
                        title: "What mattered that you didn't notice",
                        subtitle: "Patterns beneath the surface",
                        reflections: themeBased
                    )
                ]

                self.loadError = nil
            } catch {
                self.loadError = "Couldn't load your week"
            }

            self.isLoading = false
        }
    }

    private func computeMomentumScore(thisWeek: Int, lastWeek: Int, reflections: [Reflection]) -> String {
        let diff = thisWeek - lastWeek

        if reflections.isEmpty {
            return "Your reflection practice is quiet this week"
        }

        // Average depth from rated reflections
        let ratedReflections = reflections.compactMap { $0.questionRating }
        let avgDepth = ratedReflections.isEmpty ? 3.0 : Double(ratedReflections.reduce(0, +)) / Double(ratedReflections.count)

        if diff > 2 || avgDepth > 4.0 {
            return "Your reflection practice is deepening"
        } else if diff > 0 {
            return "Growing momentum in your practice"
        } else if diff == 0 && avgDepth >= 3.0 {
            return "Steady presence in your reflections"
        } else if diff < 0 {
            return "A lighter week, and that's okay"
        } else {
            return "Still showing up, still asking questions"
        }
    }

    private func computeWeekTheme(from reflections: [Reflection]) -> String? {
        guard reflections.count >= 2 else { return nil }

        let text = reflections.map { $0.text.lowercased() }.joined(separator: " ")

        let themes: [(keywords: [String], theme: String)] = [
            (["start", "begin", "new", "first", "again"], "beginnings and fresh starts"),
            (["end", "finish", "last", "done", "over", "closed"], "endings and completions"),
            (["tired", "exhaust", "drain", "heavy", "low", "hard"], "exhaustion and rest"),
            (["connect", "see", "heard", "talk", "people", "friend"], "connection and being seen"),
            (["learn", "realize", "notice", "understand", "figured"], "learning and discovery"),
            (["grateful", "thank", "appreciate", "good", "joy", "happy"], "gratitude and appreciation"),
            (["let go", "release", "hold", "carry", "burden", "weight"], "releasing and letting be"),
            (["change", "different", "shift", "move", "flow"], "transitions and movement"),
        ]

        var bestMatch: String?
        var bestScore = 0

        for (keywords, theme) in themes {
            let score = keywords.filter { text.contains($0) }.count
            if score > bestScore {
                bestScore = score
                bestMatch = theme
            }
        }

        if bestScore >= 2, let match = bestMatch {
            return "This week was about \(match)"
        }

        return nil
    }

    private func extractPatterns(from reflections: [Reflection]) -> [Reflection] {
        guard reflections.count >= 3 else { return [] }
        // Return middle third as "what you didn't notice mattered"
        let start = reflections.count / 3
        let end = 2 * reflections.count / 3
        return Array(reflections[start..<end])
    }

    // Sunday preview - prepare questions for the coming week
    func suggestedQuestionsForWeek() -> [String] {
        let categories = QuestionBank.shared.topCategories(limit: 3)
        return categories.compactMap { cat in
            QuestionBank.shared.suggestedQuestionForCategory(cat)
        }
    }

    // Static version for use in views without needing an instance
    static func getSuggestedQuestionsForWeek() -> [String] {
        let categories = QuestionBank.shared.topCategories(limit: 3)
        return categories.compactMap { cat in
            QuestionBank.shared.suggestedQuestionForCategory(cat)
        }
    }

    func refresh() {
        checkIfSunday()
        loadWeekReview()
    }

    func dismissError() {
        loadError = nil
    }
}
