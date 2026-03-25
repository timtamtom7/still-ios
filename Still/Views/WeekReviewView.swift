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

    private var reviewContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if viewModel.sections.isEmpty {
                    emptyWeekState
                } else {
                    ForEach(viewModel.sections) { section in
                        WeekReviewCard(section: section)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyWeekState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("Your week will reveal itself Sunday night")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
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
