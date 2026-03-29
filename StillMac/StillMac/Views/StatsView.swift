import SwiftUI

struct StatsView: View {
    @State private var stats = MeditationStats.empty
    @State private var streakDays: Int = 7
    @State private var totalMinutes: Int = 243
    @State private var sessionsThisWeek: Int = 12
    @State private var sessionsThisMonth: Int = 34
    @State private var averageLength: Int = 12

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak hero
                StreakHeroCard(streakDays: streakDays)

                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 12) {
                    StatCard(title: "Total Minutes", value: "\(totalMinutes)", icon: "clock", color: Theme.calmBlue)
                    StatCard(title: "This Week", value: "\(sessionsThisWeek)", icon: "calendar", color: Theme.sage)
                    StatCard(title: "This Month", value: "\(sessionsThisMonth)", icon: "calendar.badge.clock", color: Theme.accent)
                    StatCard(title: "Avg Length", value: "\(averageLength)m", icon: "chart.line.uptrend.xyaxis", color: Theme.deepNavy)
                }

                // Calendar strip
                WeekCalendarStrip()
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Theme.surface)
    }
}

struct StreakHeroCard: View {
    let streakDays: Int

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.sage.opacity(0.2), Theme.sage.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                VStack(spacing: 4) {
                    Text("\(streakDays)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.sage)

                    Text("day streak")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.deepNavy.opacity(0.6))
                }
            }

            Text("You're building a peaceful habit")
                .font(.system(size: 14))
                .foregroundColor(Theme.deepNavy.opacity(0.6))

            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(i < streakDays % 7 ? Theme.sage : Theme.deepNavy.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.deepNavy)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.deepNavy.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct WeekCalendarStrip: View {
    let calendar = Calendar.current
    let today = Date()

    var weekDays: [Date] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.deepNavy)

            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { date in
                    DayCircle(date: date, isCompleted: Bool.random())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct DayCircle: View {
    let date: Date
    let isCompleted: Bool

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.deepNavy.opacity(0.5))

            ZStack {
                Circle()
                    .fill(isCompleted ? Theme.sage : (isToday ? Theme.calmBlue.opacity(0.2) : Theme.deepNavy.opacity(0.05)))
                    .frame(width: 36, height: 36)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else if isToday {
                    Circle()
                        .fill(Theme.calmBlue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
