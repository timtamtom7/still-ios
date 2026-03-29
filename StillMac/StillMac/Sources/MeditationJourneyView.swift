import SwiftUI
import Charts

/// "Your meditation journey" - personalized progress view
struct MeditationJourneyView: View {
    @StateObject private var viewModel = MeditationJourneyViewModel()
    @State private var selectedTimeRange: TimeRange = .week

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection

                // Stats Cards
                statsCardsSection

                // Streak Calendar
                streakCalendarSection

                // Weekly/Monthly Trends
                trendsSection

                // Achievements
                achievementsSection
            }
            .padding(24)
        }
        .background(Theme.deepNavy)
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Journey")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Theme.softWhite)

            Text("Every session matters")
                .font(.system(size: 15))
                .foregroundColor(Theme.calmBlue)
        }
    }

    // MARK: - Stats Cards

    private var statsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Minutes",
                value: "\(viewModel.totalMinutes)",
                subtitle: "of meditation",
                icon: "clock.fill",
                color: Theme.calmBlue
            )

            StatCard(
                title: "Sessions",
                value: "\(viewModel.totalSessions)",
                subtitle: "completed",
                icon: "checkmark.circle.fill",
                color: Theme.sage
            )

            StatCard(
                title: "Current Streak",
                value: "\(viewModel.currentStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: Theme.accent
            )

            StatCard(
                title: "Longest Streak",
                value: "\(viewModel.longestStreak)",
                subtitle: "days",
                icon: "trophy.fill",
                color: Theme.orbGlow
            )
        }
    }

    // MARK: - Streak Calendar

    private var streakCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.softWhite)

            HStack(spacing: 8) {
                ForEach(viewModel.weekDays, id: \.date) { day in
                    DayCell(
                        day: day,
                        isToday: Calendar.current.isDateInToday(day.date)
                    )
                }
            }

            if viewModel.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Theme.accent)
                    Text("\(viewModel.currentStreak)-day streak!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.softWhite)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trends")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.softWhite)

                Spacer()

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if viewModel.sessionsByDay.isEmpty {
                emptyTrendsView
            } else {
                trendChart
            }

            // Category breakdown
            categoryBreakdown
        }
        .padding(20)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(16)
    }

    private var trendChart: some View {
        Chart(viewModel.chartData) { item in
            BarMark(
                x: .value("Day", item.day),
                y: .value("Minutes", item.minutes)
            )
            .foregroundStyle(Theme.calmBlue.gradient)
            .cornerRadius(4)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(Theme.softWhite.opacity(0.6))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(Theme.softWhite.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(Theme.softWhite.opacity(0.6))
            }
        }
    }

    private var emptyTrendsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(Theme.calmBlue.opacity(0.5))

            Text("Complete sessions to see your trends")
                .font(.system(size: 14))
                .foregroundColor(Theme.softWhite.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.8))

            ForEach(viewModel.categoryBreakdown, id: \.category) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundColor(Theme.calmBlue)
                        .frame(width: 24)

                    Text(item.category.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.softWhite)

                    Spacer()

                    Text("\(item.count) sessions")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.softWhite.opacity(0.6))
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.softWhite)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AchievementBadge(
                    title: "First Step",
                    description: "Complete 1 session",
                    isUnlocked: viewModel.totalSessions >= 1,
                    icon: "figure.walk"
                )

                AchievementBadge(
                    title: "Week Warrior",
                    description: "7-day streak",
                    isUnlocked: viewModel.longestStreak >= 7,
                    icon: "flame.fill"
                )

                AchievementBadge(
                    title: "Hour Hero",
                    description: "60 total minutes",
                    isUnlocked: viewModel.totalMinutes >= 60,
                    icon: "clock.fill"
                )

                AchievementBadge(
                    title: "Century",
                    description: "100 total minutes",
                    isUnlocked: viewModel.totalMinutes >= 100,
                    icon: "star.fill"
                )

                AchievementBadge(
                    title: "Dedicated",
                    description: "14-day streak",
                    isUnlocked: viewModel.longestStreak >= 14,
                    icon: "trophy.fill"
                )

                AchievementBadge(
                    title: "Mind Master",
                    description: "500 total minutes",
                    isUnlocked: viewModel.totalMinutes >= 500,
                    icon: "brain.head.profile"
                )
            }
        }
        .padding(20)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.softWhite)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.softWhite.opacity(0.7))

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.softWhite.opacity(0.4))
            }
        }
        .padding(16)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DayCell: View {
    let day: DayData
    let isToday: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(day.dayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.5))

            Circle()
                .fill(day.completed ? Theme.sage : Theme.surface.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay {
                    if day.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(day.dayNumber)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.softWhite.opacity(0.5))
                    }
                }
                .overlay {
                    if isToday {
                        Circle()
                            .strokeBorder(Theme.accent, lineWidth: 2)
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementBadge: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Theme.accent.opacity(0.2) : Theme.surface.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isUnlocked ? Theme.accent : Theme.softWhite.opacity(0.3))
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isUnlocked ? Theme.softWhite : Theme.softWhite.opacity(0.5))
                .lineLimit(1)

            Text(description)
                .font(.system(size: 10))
                .foregroundColor(Theme.softWhite.opacity(0.4))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.05))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - ViewModel

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let dayNumber: Int
    let completed: Bool
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Int
}

struct CategoryCount: Identifiable {
    var id: SessionCategory { category }
    let category: SessionCategory
    let count: Int
}

class MeditationJourneyViewModel: ObservableObject {
    @Published var totalMinutes: Int = 0
    @Published var totalSessions: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var weekDays: [DayData] = []
    @Published var chartData: [ChartDataPoint] = []
    @Published var categoryBreakdown: [CategoryCount] = []
    @Published var sessionsByDay: [Date: Int] = [:]

    private let userDefaults = UserDefaults.standard
    private let historyKey = "MeditationJourney.history"

    struct SessionRecord: Codable {
        let date: Date
        let duration: Int
        let category: String
        let completed: Bool
    }

    func loadData() {
        let history = loadHistory()

        // Calculate totals
        totalSessions = history.filter { $0.completed }.count
        totalMinutes = history.filter { $0.completed }.reduce(0) { $0 + $1.duration }

        // Calculate streaks
        calculateStreaks(from: history)

        // Build week calendar
        buildWeekCalendar(from: history)

        // Build chart data
        buildChartData(from: history)

        // Build category breakdown
        buildCategoryBreakdown(from: history)
    }

    private func loadHistory() -> [SessionRecord] {
        guard let data = userDefaults.data(forKey: historyKey),
              let records = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
            return []
        }
        return records
    }

    func saveSession(duration: Int, category: SessionCategory, completed: Bool) {
        var history = loadHistory()

        let record = SessionRecord(
            date: Date(),
            duration: duration,
            category: category.rawValue,
            completed: completed
        )

        history.append(record)

        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: historyKey)
        }

        // Refresh data
        loadData()
    }

    private func calculateStreaks(from history: [SessionRecord]) {
        let completedSessions = history
            .filter { $0.completed }
            .sorted { $0.date > $1.date }

        guard !completedSessions.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            return
        }

        // Current streak calculation
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        var foundToday = false

        for session in completedSessions {
            let sessionDay = Calendar.current.startOfDay(for: session.date)

            if sessionDay == currentDate {
                if !foundToday {
                    foundToday = true
                    streak = 1
                }
            } else if sessionDay == Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                streak += 1
                currentDate = sessionDay
            } else if sessionDay < Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                break
            }
        }

        currentStreak = streak

        // Longest streak calculation
        var longest = 0
        var tempStreak = 0
        var lastDay: Date?

        let sortedAscending = completedSessions.sorted { $0.date < $1.date }

        for session in sortedAscending {
            let sessionDay = Calendar.current.startOfDay(for: session.date)

            if let last = lastDay {
                let daysDiff = Calendar.current.dateComponents([.day], from: last, to: sessionDay).day ?? 0

                if daysDiff == 1 {
                    tempStreak += 1
                } else if daysDiff > 1 {
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }

            longest = max(longest, tempStreak)
            lastDay = sessionDay
        }

        longestStreak = longest
    }

    private func buildWeekCalendar(from history: [SessionRecord]) {
        let calendar = Calendar.current
        let today = Date()

        var days: [DayData] = []

        // Get the start of the current week (Sunday or Monday based on locale)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // Adjust for Monday start

        let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today))!

        let completedDates = Set(history.filter { $0.completed }.map { calendar.startOfDay(for: $0.date) })

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: weekStart) else { continue }

            let dayName = date.formatted(.dateTime.weekday(.abbreviated))
            let dayNumber = calendar.component(.day, from: date)
            let completed = completedDates.contains(calendar.startOfDay(for: date))

            days.append(DayData(
                date: date,
                dayName: String(dayName.prefix(1)),
                dayNumber: dayNumber,
                completed: completed
            ))
        }

        weekDays = days
    }

    private func buildChartData(from history: [SessionRecord]) {
        let calendar = Calendar.current
        let today = Date()

        // Group by day
        var byDay: [Date: Int] = [:]

        for session in history where session.completed {
            let day = calendar.startOfDay(for: session.date)
            byDay[day, default: 0] += session.duration
        }

        sessionsByDay = byDay

        // Build chart data for selected range
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        var data: [ChartDataPoint] = []

        // Last 7 days
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let day = calendar.startOfDay(for: date)
            let minutes = byDay[day] ?? 0

            data.append(ChartDataPoint(
                day: dayFormatter.string(from: date),
                minutes: minutes
            ))
        }

        chartData = data
    }

    private func buildCategoryBreakdown(from history: [SessionRecord]) {
        var counts: [SessionCategory: Int] = [:]

        for session in history where session.completed {
            if let category = SessionCategory(rawValue: session.category) {
                counts[category, default: 0] += 1
            }
        }

        categoryBreakdown = counts
            .map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Preview

#Preview {
    MeditationJourneyView()
        .frame(width: 400, height: 800)
}
