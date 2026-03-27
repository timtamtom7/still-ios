import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)

            TextField(placeholder, text: $text)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel("Search")
                .accessibilityHint("Enter keywords to search your reflections.")

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                }
                .accessibilityLabel("Clear search")
                .accessibilityHint("Removes all search text.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusSmall)
    }
}
