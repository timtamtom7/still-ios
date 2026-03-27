import SwiftUI

struct WeekReviewCard: View {
    let section: WeekReviewSection
    @State private var selectedReflection: Reflection?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)

                Text(section.subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 4)

            if section.reflections.isEmpty {
                Text("Nothing recorded in this category this week")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(section.reflections) { reflection in
                        WeekReviewReflectionRow(reflection: reflection)
                            .onTapGesture {
                                selectedReflection = reflection
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusCard)
        .sheet(item: $selectedReflection) { reflection in
            ReflectionDetailSheet(reflection: reflection)
        }
    }
}

struct WeekReviewReflectionRow: View {
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
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .cornerRadius(Theme.cornerRadiusSmall)
        .contentShape(Rectangle())
        .accessibilityLabel("Reflection: \(reflection.question)")
        .accessibilityHint("Tap to view the full reflection from \(reflection.formattedDate).")
    }
}

struct ReflectionDetailSheet: View {
    let reflection: Reflection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(reflection.formattedDate)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(reflection.question)
                        .font(AppTypography.display)
                        .foregroundColor(AppColors.textPrimary)

                    Text(reflection.text)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineSpacing(8)
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.amber)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
