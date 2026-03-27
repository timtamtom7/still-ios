import SwiftUI

enum MemoryLaneType {
    case oneYearAgo
    case oneMonthAgo
    case thisDayInHistory

    var title: String {
        switch self {
        case .oneYearAgo: return "One year ago tonight"
        case .oneMonthAgo: return "A month ago"
        case .thisDayInHistory: return "This day in history"
        }
    }

    var subtitle: String {
        switch self {
        case .oneYearAgo: return "An anniversary reflection"
        case .oneMonthAgo: return "Has anything changed?"
        case .thisDayInHistory: return "Same date, different years"
        }
    }

    var icon: String {
        switch self {
        case .oneYearAgo: return "clock.arrow.circlepath"
        case .oneMonthAgo: return "calendar.badge.clock"
        case .thisDayInHistory: return "calendar"
        }
    }
}

struct MemoryLaneCard: View {
    let memoryType: MemoryLaneType
    let reflection: Reflection?
    let onTap: ((Reflection) -> Void)?

    init(memoryType: MemoryLaneType, reflection: Reflection?, onTap: ((Reflection) -> Void)? = nil) {
        self.memoryType = memoryType
        self.reflection = reflection
        self.onTap = onTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: memoryType.icon)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.amber)

                Text(memoryType.title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.amber)

                Spacer()
            }

            if let reflection = reflection {
                VStack(alignment: .leading, spacing: 8) {
                    Text(reflection.formattedDate)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(reflection.question)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)

                    Text(reflection.text)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(3)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?(reflection)
                }
                .accessibilityLabel("View reflection from \(reflection.formattedDate)")
                .accessibilityHint("Opens the full reflection.")
            } else {
                Text("Nothing recorded")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    .italic()
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                .stroke(AppColors.amber.opacity(0.2), lineWidth: 1)
        )
    }
}
