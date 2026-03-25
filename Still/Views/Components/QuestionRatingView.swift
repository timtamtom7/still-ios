import SwiftUI

struct QuestionRatingView: View {
    let question: String
    let onRate: (Int) -> Void

    @State private var selectedRating: Int?
    @State private var animateIn = false

    private let depthLabels = ["Surface", "Getting there", "Deep", "Very deep", "Profound"]

    var body: some View {
        VStack(spacing: 24) {
            Text("How deep was this question for you?")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRating = rating
                        }
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            onRate(rating)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(selectedRating == nil || selectedRating == rating ? AppColors.amber : AppColors.surface)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("\(rating)")
                                        .font(AppTypography.caption)
                                        .foregroundColor(selectedRating == rating ? AppColors.background : AppColors.textSecondary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(selectedRating == rating ? AppColors.amberGlow : Color.clear, lineWidth: 2)
                                )

                            Text(depthLabels[rating - 1])
                                .font(.system(size: 10))
                                .foregroundColor(selectedRating == rating ? AppColors.amber : AppColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if selectedRating == nil {
                Text("Tap to skip")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
        }
        .padding(24)
        .background(AppColors.surface)
        .cornerRadius(16)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
}
