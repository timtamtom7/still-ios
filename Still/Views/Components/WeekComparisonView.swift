import SwiftUI

struct WeekComparisonView: View {
    let thisWeekCount: Int
    let lastWeekCount: Int
    let momentumScore: String
    let weekTheme: String?

    private var difference: Int {
        thisWeekCount - lastWeekCount
    }

    private var differenceText: String {
        if difference > 0 {
            return "+\(difference) from last week"
        } else if difference < 0 {
            return "\(difference) from last week"
        } else {
            return "Same as last week"
        }
    }

    private var trendIcon: String {
        if difference > 0 { return "arrow.up.right" }
        else if difference < 0 { return "arrow.down.right" }
        else { return "arrow.right" }
    }

    private var trendColor: Color {
        if difference > 0 { return AppColors.amber }
        else if difference < 0 { return AppColors.textSecondary }
        else { return AppColors.textSecondary }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Count comparison
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("This week")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(thisWeekCount)")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(AppColors.textPrimary)
                    Text("reflections")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Image(systemName: trendIcon)
                    .font(.system(size: 20))
                    .foregroundColor(trendColor)

                VStack(spacing: 4) {
                    Text("Last week")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(lastWeekCount)")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                    Text("reflections")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Divider()
                .background(AppColors.separator)

            // Momentum score
            HStack(spacing: 8) {
                Image(systemName: "flame")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.amber)

                Text(momentumScore)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Text(differenceText)
                    .font(AppTypography.caption)
                    .foregroundColor(trendColor)
            }

            // Week theme
            if let theme = weekTheme, !theme.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.amber)

                    Text(theme)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusCard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week comparison: \(thisWeekCount) reflections this week, \(lastWeekCount) last week. \(differenceText). \(momentumScore)")
    }
}
