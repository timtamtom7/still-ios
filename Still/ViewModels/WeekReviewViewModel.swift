import Foundation
import Combine

struct WeekReviewSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let reflections: [Reflection]
}

@MainActor
final class WeekReviewViewModel: ObservableObject {
    @Published var sections: [WeekReviewSection] = []
    @Published var daysUntilSunday: Int = 0
    @Published var isSunday: Bool = false
    @Published var isLoading: Bool = false

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
            return
        }

        isLoading = true

        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            isLoading = false
            return
        }

        let weekReflections = db.getReflections(from: startOfWeek, to: endOfWeek)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)

            let significant = weekReflections.filter { $0.text.count > 80 }
            let lighter = weekReflections.filter { $0.text.count <= 80 }
            let themeBased = extractThemes(from: weekReflections)

            self.sections = [
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

            self.isLoading = false
        }
    }

    private func extractThemes(from reflections: [Reflection]) -> [Reflection] {
        guard reflections.count >= 3 else { return [] }
        let middleThird = Array(reflections[reflections.count / 3..<(2 * reflections.count / 3)])
        return middleThird
    }

    func refresh() {
        checkIfSunday()
        loadWeekReview()
    }
}
