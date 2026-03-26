import Foundation

// R11: Legacy, Guided Sessions, Community for Still
@MainActor
final class StillR11Service: ObservableObject {
    static let shared = StillR11Service()

    @Published var guidedSessions: [GuidedSession] = []
    @Published var reflectionArchive: [ArchivedReflection] = []

    private init() {}

    // MARK: - Guided Sessions

    struct GuidedSession: Identifiable {
        let id = UUID()
        var title: String
        var theme: SessionTheme
        var duration: Int // minutes
        var audioURL: URL?
        var isBundled: Bool

        enum SessionTheme: String {
            case grief, gratitude, transition, renewal, sleep, anxiety
        }
    }

    static let bundledSessions: [GuidedSession] = [
        GuidedSession(id: UUID(), title: "Finding Peace", theme: .grief, duration: 10, audioURL: nil, isBundled: true),
        GuidedSession(id: UUID(), title: "Gratitude Practice", theme: .gratitude, duration: 5, audioURL: nil, isBundled: true),
        GuidedSession(id: UUID(), title: "New Beginnings", theme: .transition, duration: 15, audioURL: nil, isBundled: true),
        GuidedSession(id: UUID(), title: "Morning Renewal", theme: .renewal, duration: 10, audioURL: nil, isBundled: true)
    ]

    // MARK: - Legacy Planning

    struct ArchivedReflection: Identifiable {
        let id = UUID()
        var content: String
        var date: Date
        var mood: String?
        var tags: [String]
    }

    struct LegacyDocument {
        var reflections: [ArchivedReflection]
        var lifeSummary: String
        var designatedRecipient: String?
    }

    func generateLifeSummary(reflections: [ArchivedReflection]) -> String {
        // AI-generated summary from all reflections
        return "Your life journey, as told through your reflections..."
    }

    func scheduleLetterToFutureSelf(content: String, deliveryDate: Date) {
        // Schedule delivery
    }

    // MARK: - Community

    struct CommunityMoment: Identifiable {
        let id = UUID()
        var content: String
        var authorName: String
        var theme: GuidedSession.SessionTheme
        var timestamp: Date
    }

    func shareAnonymously(reflection: ArchivedReflection) -> CommunityMoment {
        CommunityMoment(
            id: UUID(),
            content: reflection.content,
            authorName: "Anonymous",
            theme: .gratitude,
            timestamp: Date()
        )
    }

    // MARK: - Reflection Tools

    func analyzeReflectionStreak(reflections: [ArchivedReflection]) -> Int {
        guard !reflections.isEmpty else { return 0 }

        let sorted = reflections.sorted { $0.date > $1.date }
        var streak = 1

        for i in 1..<sorted.count {
            let diff = Calendar.current.dateComponents([.day], from: sorted[i].date, to: sorted[i-1].date).day ?? 0
            if diff == 1 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }
}
