import Foundation

/// Service for generating legacy documents from reflections
final class LegacyService {
    static nonisolated(unsafe) let shared = LegacyService()

    private init() {}

    // MARK: - Legacy Document Generation

    /// Generates a comprehensive legacy document from all reflections
    func generateLegacyDocument(reflections: [Reflection], includeMemories: Bool = true) -> LegacyDocument {
        let sortedReflections = reflections.sorted { $0.date < $1.date }

        let title = generateTitle(from: sortedReflections)
        let introduction = generateIntroduction(from: sortedReflections)
        let chapters = generateChapters(from: sortedReflections, includeMemories: includeMemories)
        let themes = extractLifeThemes(from: sortedReflections)
        let growthNarrative = generateGrowthNarrative(from: sortedReflections)

        return LegacyDocument(
            title: title,
            introduction: introduction,
            chapters: chapters,
            lifeThemes: themes,
            growthNarrative: growthNarrative,
            createdAt: Date()
        )
    }

    /// Generates a condensed "distilled reflections" document
    func generateDistilledDocument(reflections: [Reflection]) -> String {
        guard !reflections.isEmpty else {
            return "Your story is still being written. Keep reflecting."
        }

        let sorted = reflections.sorted { $0.date > $1.date }
        let last30Days = sorted.prefix(30)
        let last90Days = sorted.prefix(90)

        var document = ""

        // Title
        document += "═══ YOUR REFLECTIONS, DISTILLED ═══\n\n"
        document += "A meditation on \(reflections.count) evenings of Still\n"
        document += "From \(formatDate(reflections.last?.date ?? Date())) to \(formatDate(reflections.first?.date ?? Date()))\n\n"

        // Pattern overview
        let patterns = AIService.shared.analyzeReflectionPatterns(Array(last90Days))
        if let emotion = patterns.dominantEmotion {
            document += "─── Your dominant emotional landscape ───\n"
            document += "This period was marked by \(emotion). Your reflections return to this theme again and again, revealing what lives at the center of your inner life.\n\n"
        }

        // Key reflections - the ones that mattered most
        let significantReflections = sorted.filter { $0.text.count > 100 }
        if let keyReflection = significantReflections.first {
            document += "─── A reflection that held weight ───\n"
            document += "[\(formatDate(keyReflection.date))]\n"
            document += "Q: \(keyReflection.question)\n"
            document += "\(keyReflection.text)\n\n"
        }

        // Growth narrative
        document += "─── Your growth narrative ───\n"
        document += generateGrowthNarrative(from: sorted) + "\n\n"

        // Most asked questions
        let questionCounts = Dictionary(grouping: sorted, by: { $0.question })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)

        document += "─── Questions that return ───\n"
        for (question, count) in questionCounts {
            document += "• \"\(question)\" (asked \(count) times)\n"
        }

        document += "\n─── Closing ───\n"
        document += "These reflections are a map of your inner world. They show where you've been, what you've carried, and what you've discovered. This document is yours to keep, to share, or to let fade. The reflections themselves live in Still, held with care."

        return document
    }

    // MARK: - Gift Reflections

    /// Creates a gift package of selected reflections to share with someone
    func createGiftPackage(reflections: [Reflection], recipient: String, personalNote: String?) -> GiftPackage {
        let sortedReflections = reflections.sorted { $0.date > $1.date }

        let selectedReflections: [Reflection]
        if reflections.count <= 5 {
            selectedReflections = Array(sortedReflections)
        } else {
            // Pick varied reflections - most recent, most significant, and a random selection
            var chosen = Set<UUID>()
            chosen.insert(sortedReflections.first!.id) // Most recent

            let significant = sortedReflections.filter { $0.text.count > 80 }
            if let sig = significant.randomElement() {
                chosen.insert(sig.id)
            }

            while chosen.count < min(5, reflections.count) {
                if let random = sortedReflections.randomElement() {
                    chosen.insert(random.id)
                }
            }

            selectedReflections = sortedReflections.filter { chosen.contains($0.id) }
        }

        let giftTitle = "Reflections for \(recipient)"
        let giftIntroduction = personalNote ?? "These reflections were chosen from the heart of someone's Still practice."

        return GiftPackage(
            title: giftTitle,
            introduction: giftIntroduction,
            reflections: selectedReflections,
            recipient: recipient,
            createdAt: Date()
        )
    }

    /// Exports a gift package as shareable text
    func exportGiftPackage(_ gift: GiftPackage) -> String {
        var text = ""

        text += "═══ \(gift.title) ═══\n\n"
        text += "\(gift.introduction)\n\n"
        text += "Shared via Still\n\n"

        for (index, reflection) in gift.reflections.enumerated() {
            text += "─────────────────────\n"
            text += "[\(formatDate(reflection.date))]\n"
            text += "\(reflection.question)\n\n"
            text += "\(reflection.text)\n\n"
        }

        text += "─────────────────────\n"
        text += "Created with Still — evening reflection practice\n"

        return text
    }

    // MARK: - Memorial Mode

    /// Checks if memorial mode should be active based on settings
    func isMemorialModeActive() -> Bool {
        return UserDefaults.standard.bool(forKey: "memorialModeEnabled")
    }

    /// Activates memorial mode for a departed loved one
    func activateMemorialMode(for person: MemorialPerson) {
        UserDefaults.standard.set(true, forKey: "memorialModeEnabled")
        if let data = try? JSONEncoder().encode(person) {
            UserDefaults.standard.set(data, forKey: "memorialPerson")
        }
    }

    /// Deactivates memorial mode
    func deactivateMemorialMode() {
        UserDefaults.standard.set(false, forKey: "memorialModeEnabled")
        UserDefaults.standard.removeObject(forKey: "memorialPerson")
    }

    /// Returns the memorial person if in memorial mode
    func getMemorialPerson() -> MemorialPerson? {
        guard isMemorialModeActive(),
              let data = UserDefaults.standard.data(forKey: "memorialPerson"),
              let person = try? JSONDecoder().decode(MemorialPerson.self, from: data) else {
            return nil
        }
        return person
    }

    /// Generates memorial reflections for a person
    func generateMemorialReflections(for person: MemorialPerson, allReflections: [Reflection]) -> [MemorialReflection] {
        // Find reflections that might relate to this person
        let personKeywords = person.name.lowercased().components(separatedBy: " ")
        let relatedReflections = allReflections.filter { reflection in
            let text = reflection.text.lowercased()
            let question = reflection.question.lowercased()
            return personKeywords.contains { keyword in
                text.contains(keyword) || question.contains(keyword)
            }
        }

        return relatedReflections.map { reflection in
            MemorialReflection(
                reflection: reflection,
                connection: .indirect, // We can't know the exact connection
                note: "This reflection may have connection to \(person.name)"
            )
        }
    }

    // MARK: - Private Helpers

    private func generateTitle(from reflections: [Reflection]) -> String {
        if reflections.isEmpty { return "A Life in Reflections" }

        let patterns = AIService.shared.analyzeReflectionPatterns(reflections)

        if let theme = patterns.recurringThemes.first {
            return "Themes of \(theme.capitalized)"
        }

        if let emotion = patterns.dominantEmotion {
            return "A Journey Through \(emotion.capitalized)"
        }

        return "An Evening Portrait"
    }

    private func generateIntroduction(from reflections: [Reflection]) -> String {
        let count = reflections.count
        let firstDate = reflections.first?.date ?? Date()
        let lastDate = reflections.last?.date ?? Date()

        let intro = """
        This document is a distillation of \(count) evenings spent in reflection. \
        Together, they form a portrait of a life in motion — the questions asked, \
        the truths named, and the silences held.

        From \(formatDate(firstDate)) to \(formatDate(lastDate)), \
        these pages hold what mattered.
        """

        return intro
    }

    private func generateChapters(from reflections: [Reflection], includeMemories: Bool) -> [LegacyChapter] {
        var chapters: [LegacyChapter] = []

        // Group by month
        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: reflections) { reflection in
            calendar.date(from: calendar.dateComponents([.year, .month], from: reflection.date)) ?? reflection.date
        }

        let sortedMonths = groupedByMonth.keys.sorted()

        for monthDate in sortedMonths {
            guard let monthReflections = groupedByMonth[monthDate] else { continue }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let title = formatter.string(from: monthDate)

            let patterns = AIService.shared.analyzeReflectionPatterns(monthReflections)
            let dominantMood = patterns.dominantEmotion ?? "mixed"

            let chapterReflections = monthReflections.sorted { $0.date > $1.date }
            let preview = chapterReflections.first?.previewText ?? ""

            chapters.append(LegacyChapter(
                title: title,
                dateRange: monthDate,
                reflections: chapterReflections,
                mood: dominantMood,
                preview: preview
            ))
        }

        return chapters.reversed()
    }

    private func extractLifeThemes(from reflections: [Reflection]) -> [LifeTheme] {
        guard reflections.count >= 5 else { return [] }

        let patterns = AIService.shared.analyzeReflectionPatterns(reflections)
        var themes: [LifeTheme] = []

        if let emotion = patterns.dominantEmotion {
            let relevantReflections = reflections.filter { $0.text.lowercased().contains(emotion) }
            themes.append(LifeTheme(
                name: emotion.capitalized,
                description: "A recurring presence in your reflections",
                evidence: relevantReflections.prefix(3).map { $0.previewText },
                frequency: relevantReflections.count
            ))
        }

        for theme in patterns.recurringThemes.prefix(3) {
            let relevant = reflections.filter { $0.text.lowercased().contains(theme) }
            if !relevant.isEmpty {
                themes.append(LifeTheme(
                    name: theme.capitalized,
                    description: "A thread woven through your inner life",
                    evidence: relevant.prefix(3).map { $0.previewText },
                    frequency: relevant.count
                ))
            }
        }

        return themes
    }

    private func generateGrowthNarrative(from reflections: [Reflection]) -> String {
        guard reflections.count >= 3 else {
            return "Your reflection practice is still finding its form."
        }

        let sorted = reflections.sorted { $0.date < $1.date }
        let firstHalf = Array(sorted.prefix(sorted.count / 2))
        let secondHalf = Array(sorted.suffix(sorted.count / 2))

        let firstPatterns = AIService.shared.analyzeReflectionPatterns(firstHalf)
        let secondPatterns = AIService.shared.analyzeReflectionPatterns(secondHalf)

        let firstMood = firstPatterns.dominantEmotion ?? "varied"
        let secondMood = secondPatterns.dominantEmotion ?? "varied"

        if firstMood == secondMood {
            return "Across your reflections, \(firstMood) has remained a constant companion. Your inner landscape shows continuity — some things stay with you across seasons."
        } else {
            return "Something has shifted between the beginning and now. Where your reflections once spoke of \(firstMood), they now carry \(secondMood). This is the shape of change."
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct LegacyDocument {
    let title: String
    let introduction: String
    let chapters: [LegacyChapter]
    let lifeThemes: [LifeTheme]
    let growthNarrative: String
    let createdAt: Date
}

struct LegacyChapter: Identifiable {
    let id = UUID()
    let title: String
    let dateRange: Date
    let reflections: [Reflection]
    let mood: String
    let preview: String
}

struct LifeTheme: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let evidence: [String]
    let frequency: Int
}

struct GiftPackage {
    let id = UUID()
    let title: String
    let introduction: String
    let reflections: [Reflection]
    let recipient: String
    let createdAt: Date
}

struct MemorialPerson: Codable {
    let id: UUID
    let name: String
    let relationship: String
    let dateOfDeath: Date?
    let notes: String?

    init(id: UUID = UUID(), name: String, relationship: String, dateOfDeath: Date? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.dateOfDeath = dateOfDeath
        self.notes = notes
    }
}

struct MemorialReflection {
    let reflection: Reflection
    let connection: MemorialConnection
    let note: String
}

enum MemorialConnection {
    case direct
    case indirect
    case possible
}
