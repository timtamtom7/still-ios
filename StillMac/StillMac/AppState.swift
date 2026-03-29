import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .breathe
    @Published var currentSession: MeditationSession?
    @Published var streak: Int = 0
    @Published var todayCompleted: Bool = false

    enum Tab: Hashable {
        case breathe
        case library
        case stats
        case settings
    }

    init() {
        loadStats()
    }

    func loadStats() {
        streak = UserDefaults.standard.integer(forKey: "streak")
        todayCompleted = UserDefaults.standard.bool(forKey: "todayCompleted")
    }

    func saveStats() {
        UserDefaults.standard.set(streak, forKey: "streak")
        UserDefaults.standard.set(todayCompleted, forKey: "todayCompleted")
    }
}
