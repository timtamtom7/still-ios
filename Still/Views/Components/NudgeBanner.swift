import SwiftUI

struct NudgeBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppColors.amber)
                .frame(width: 4)

            Text(message)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            .accessibilityLabel("Dismiss banner")
            .accessibilityHint("Dismisses the nudge message.")
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusSmall)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
