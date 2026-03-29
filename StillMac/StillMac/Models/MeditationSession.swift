import Foundation

struct MeditationSession: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let duration: Int
    let instructor: String
    let description: String
    let category: SessionCategory
}

enum SessionCategory: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case sleep = "Sleep"
    case focus = "Focus"
    case anxiety = "Anxiety"
    case bodyScan = "Body Scan"
    case breathing = "Breathing"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .sleep: return "moon.stars"
        case .focus: return "target"
        case .anxiety: return "heart"
        case .bodyScan: return "figure.stand"
        case .breathing: return "wind"
        }
    }
}

struct SessionLibrary {
    static let sessions: [MeditationSession] = [
        // Morning
        MeditationSession(name: "Morning Light", duration: 5, instructor: "Sarah Chen", description: "Greet the day with intention and warmth.", category: .morning),
        MeditationSession(name: "Sunrise Awakening", duration: 10, instructor: "Sarah Chen", description: "Ease into consciousness with gentle breath.", category: .morning),
        MeditationSession(name: "Daily Intentions", duration: 3, instructor: "Marcus Webb", description: "Set your tone for the day ahead.", category: .morning),

        // Sleep
        MeditationSession(name: "Drift Away", duration: 20, instructor: "Luna Martinez", description: "Let go of the day and sink into rest.", category: .sleep),
        MeditationSession(name: "Deep Rest", duration: 15, instructor: "Luna Martinez", description: "Progressive relaxation for deep sleep.", category: .sleep),
        MeditationSession(name: "Bedtime Wind Down", duration: 10, instructor: "James Park", description: "Gentle stretches and calm breath.", category: .sleep),

        // Focus
        MeditationSession(name: "Clear Mind", duration: 10, instructor: "Marcus Webb", description: "Sharpen awareness and find calm focus.", category: .focus),
        MeditationSession(name: "Deep Work Prep", duration: 5, instructor: "Marcus Webb", description: "Prepare your mind for concentrated effort.", category: .focus),
        MeditationSession(name: "Creative Flow", duration: 15, instructor: "Sarah Chen", description: "Open space for inspiration and ideas.", category: .focus),

        // Anxiety
        MeditationSession(name: "Calm Ground", duration: 10, instructor: "Luna Martinez", description: "Soothe anxious thoughts with gentle presence.", category: .anxiety),
        MeditationSession(name: "Release Tension", duration: 5, instructor: "Luna Martinez", description: "Let physical tension melt away.", category: .anxiety),
        MeditationSession(name: "Worry Release", duration: 20, instructor: "James Park", description: "A longer practice for persistent worry.", category: .anxiety),

        // Body Scan
        MeditationSession(name: "Full Body Scan", duration: 15, instructor: "James Park", description: "Journey through the body with awareness.", category: .bodyScan),
        MeditationSession(name: "Evening Unwind", duration: 10, instructor: "James Park", description: "Release the day's held sensations.", category: .bodyScan),
        MeditationSession(name: "Quick Reset", duration: 5, instructor: "Sarah Chen", description: "A brief body check-in anywhere.", category: .bodyScan),

        // Breathing
        MeditationSession(name: "Box Breathing", duration: 5, instructor: "Marcus Webb", description: "Navy SEAL technique for calm control.", category: .breathing),
        MeditationSession(name: "4-7-8 Relaxation", duration: 5, instructor: "Luna Martinez", description: "Dr. Weil's breathing for deep calm.", category: .breathing),
        MeditationSession(name: "Energizing Breath", duration: 3, instructor: "Sarah Chen", description: "Invigorate without caffeine.", category: .breathing),
    ]

    static func sessions(for category: SessionCategory) -> [MeditationSession] {
        sessions.filter { $0.category == category }
    }
}
