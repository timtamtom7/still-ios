import SwiftUI

struct ReflectionCard: View {
    let reflection: Reflection
    @State private var isHighlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(reflection.formattedDate)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Text(reflection.question)
                .font(AppTypography.displaySmall)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)

            Text(reflection.text)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHighlighted ? AppColors.amber : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        .onTapGesture {
            isHighlighted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isHighlighted = false
            }
        }
    }
}
