import Foundation

final class QuestionBank {
    static nonisolated(unsafe) let shared = QuestionBank()

    private let allQuestions: [String] = [
        "What exhausted you today?",
        "What surprised you?",
        "What did you almost say?",
        "What did you learn about yourself?",
        "What are you carrying that isn't yours?",
        "What felt most true?",
        "What did you avoid?",
        "What are you pretending is fine?",
        "What made you laugh today?",
        "What do you need to let go of?",
        "What showed up that you didn't expect?",
        "What are you grateful for tonight?",
        "What conversation stayed with you?",
        "What did you do for yourself?",
        "What drained you?",
        "What filled you?",
        "What did you notice that others missed?",
        "What do you wish you had said?",
        "What are you proud of?",
        "What surprised you about yourself?",
        "What felt heavy today?",
        "What felt light?",
        "What do you need tomorrow?",
        "What are you looking forward to?",
        "What worried you today?",
        "What brought you peace?",
        "What challenged your thinking?",
        "What made you feel seen?",
        "What made you feel unseen?",
        "What would you do differently if you could?",
        "What truth are you avoiding?",
        "What boundary do you need?",
        "What connection mattered?",
        "What are you overthinking?",
        "What are you underestimating?",
        "What story are you telling yourself?",
        "What do you need to forgive?",
        "What made you feel alive?",
        "What drained your energy?",
        "What gave you energy?",
        "What are you holding tightly?",
        "What would you release if you could?",
        "What made you feel proud today?",
        "What made you feel small?",
        "What did you learn about someone else?",
        "What are you curious about?",
        "What would make tomorrow meaningful?",
        "What are you proving to yourself?",
        "What are you proving to others?",
        "What do you know now that you didn't this morning?",
        "What stayed unfinished?",
        "What felt complete?",
        "What do you wish you had known?",
        "What would you tell your morning self?",
        "What question is living in you tonight?",
        "What do you want to remember about today?",
        "What needs your attention?",
        "What can wait until tomorrow?",
        "What are you learning to feel?",
        "What are you practicing?",
        "What would silence sound like?",
        "What would stillness feel like?",
        "What are you becoming?"
    ]

    private var usedQuestionIndices: Set<Int> = []
    private let cycleLength: Int

    private init() {
        cycleLength = allQuestions.count
        loadUsedIndices()
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

    func todaysQuestion(excluding: String? = nil) -> String {
        var availableIndices = Set(0..<cycleLength)
        availableIndices.subtract(usedQuestionIndices)

        if availableIndices.isEmpty {
            usedQuestionIndices.removeAll()
            availableIndices = Set(0..<cycleLength)
        }

        let selectedIndex = availableIndices.randomElement() ?? 0
        usedQuestionIndices.insert(selectedIndex)
        saveUsedIndices()

        let question = allQuestions[selectedIndex]
        if let excluding = excluding, question == excluding {
            return todaysQuestion(excluding: excluding)
        }
        return question
    }

    func questionForDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear + usedQuestionIndices.hashValue) % cycleLength
        return allQuestions[index]
    }
}
