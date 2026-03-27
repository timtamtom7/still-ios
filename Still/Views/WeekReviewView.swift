import SwiftUI

struct WeekReviewView: View {
    @EnvironmentObject var viewModel: WeekReviewViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if viewModel.isSunday {
                    if viewModel.isLoading {
                        loadingState
                    } else if viewModel.loadError != nil {
                        errorState
                    } else {
                        reviewContent
                    }
                } else {
                    countdownState
                }
            }
            .navigationTitle("Week")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 24) {
            BreathingOrb(state: .idle, scale: .constant(1.0))
                .scaleEffect(0.8)

            Text("Gathering your week...")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    @ViewBuilder
    private var errorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(AppColors.amber.opacity(0.7))

            Text(viewModel.loadError ?? "Something went wrong")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                viewModel.refresh()
            }
            .font(AppTypography.button)
            .foregroundColor(AppColors.amber)
        }
        .padding(48)
    }

    private var reviewContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if viewModel.sections.isEmpty && viewModel.weekComparison == nil {
                    emptyWeekState
                } else {
                    // Week comparison header
                    if let comparison = viewModel.weekComparison {
                        WeekComparisonView(
                            thisWeekCount: comparison.thisWeekCount,
                            lastWeekCount: comparison.lastWeekCount,
                            momentumScore: comparison.momentumScore,
                            weekTheme: comparison.weekTheme
                        )
                    }

                    // Seasonal theme
                    SeasonalThemeCard()

                    // Reflection sections
                    ForEach(viewModel.sections) { section in
                        WeekReviewCard(section: section)
                    }

                    // Sunday preview - questions for the coming week
                    SundayPreviewCard()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyWeekState: some View {
        VStack(spacing: 16) {
            StillEmptyIllustration(size: 160)

            Text("Your week will reveal itself Sunday night")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text("Keep reflecting — the threads will gather")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(48)
    }

    private var countdownState: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "moon.stars")
                .font(.system(size: 64))
                .foregroundColor(AppColors.amber)

            VStack(spacing: 12) {
                Text("\(viewModel.daysUntilSunday) days")
                    .font(.system(size: 48, weight: .light, design: .serif))
                    .foregroundColor(AppColors.textPrimary)

                Text("until your week in review")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            VStack(spacing: 8) {
                Text("Sunday night")
                    .font(AppTypography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)

                Text("Still will gather the threads of your week")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 60)
        }
        .padding(32)
    }
}

// MARK: - Seasonal Theme Card

struct SeasonalThemeCard: View {
    @State private var seasonalQuestion: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: seasonIcon)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.amber)

                Text("This season in Still")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.amber)

                Spacer()
            }

            if let question = seasonalQuestion {
                Text(question)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .italic()
            } else {
                Text("Continue reflecting to uncover seasonal patterns")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusCard)
                .stroke(AppColors.amber.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            loadSeasonalQuestion()
        }
    }

    private var seasonIcon: String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())

        if month >= 3 && month <= 5 { return "leaf.fill" }
        if month >= 6 && month <= 8 { return "sun.max.fill" }
        if month >= 9 && month <= 11 { return "wind" }
        return "snowflake"
    }

    private func loadSeasonalQuestion() {
        seasonalQuestion = AIService.shared.seasonalQuestion()
    }
}

// MARK: - Sunday Preview Card

struct SundayPreviewCard: View {
    @State private var suggestedQuestions: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.amber)

                Text("Questions for the week ahead")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.amber)

                Spacer()
            }

            Text("Based on your reflection patterns, these questions may resonate with you soon:")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            if suggestedQuestions.isEmpty {
                Text("Start reflecting to unlock personalized questions")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(suggestedQuestions, id: \.self) { question in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(AppColors.amber.opacity(0.5))
                                .frame(width: 6, height: 6)

                            Text(question)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textPrimary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusCard)
                .stroke(AppColors.amber.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            loadSuggestions()
        }
    }

    private func loadSuggestions() {
        suggestedQuestions = WeekReviewViewModel.getSuggestedQuestionsForWeek()
    }
}
