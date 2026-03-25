import SwiftUI

struct ArchiveRow: View {
    let reflection: Reflection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reflection.formattedDate)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Text(reflection.question)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            Text(reflection.previewText)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
    }
}
