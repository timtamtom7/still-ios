import Foundation

struct MeditationStats {
    var streakDays: Int
    var totalMinutes: Int
    var sessionsThisWeek: Int
    var sessionsThisMonth: Int
    var averageLength: Int
    var completedDates: Set<Date>

    static var empty: MeditationStats {
        MeditationStats(
            streakDays: 0,
            totalMinutes: 0,
            sessionsThisWeek: 0,
            sessionsThisMonth: 0,
            averageLength: 0,
            completedDates: []
        )
    }

    init(streakDays: Int, totalMinutes: Int, sessionsThisWeek: Int, sessionsThisMonth: Int, averageLength: Int, completedDates: Set<Date>) {
        self.streakDays = streakDays
        self.totalMinutes = totalMinutes
        self.sessionsThisWeek = sessionsThisWeek
        self.sessionsThisMonth = sessionsThisMonth
        self.averageLength = averageLength
        self.completedDates = completedDates
    }
}
