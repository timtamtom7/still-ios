import SwiftUI

struct SessionLibraryView: View {
    @State private var selectedCategory: SessionCategory? = nil
    @State private var searchText = ""

    var filteredSessions: [MeditationSession] {
        var sessions = SessionLibrary.sessions

        if let category = selectedCategory {
            sessions = sessions.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            sessions = sessions.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.instructor.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return sessions
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            // Category filter
            CategoryScrollView(selectedCategory: $selectedCategory)
                .padding(.top, 12)

            Divider()
                .padding(.top, 12)

            // Session list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredSessions) { session in
                        SessionCard(session: session)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Theme.surface)
    }
}

struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Theme.deepNavy.opacity(0.4))

            TextField("Search meditations...", text: $text)
                .font(.system(size: 14))
                .foregroundColor(Theme.deepNavy)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.deepNavy.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}

struct CategoryScrollView: View {
    @Binding var selectedCategory: SessionCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryPill(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(SessionCategory.allCases) { category in
                    CategoryPill(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.deepNavy.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Theme.calmBlue : Theme.cardBg)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(isSelected ? 0.1 : 0.03), radius: 2, y: 1)
    }
}

struct SessionCard: View {
    let session: MeditationSession

    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Theme.calmBlue.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: session.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.calmBlue)
            }

            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.deepNavy)

                Text(session.instructor)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.calmBlue.opacity(0.8))

                Text(session.description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.deepNavy.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer()

            // Duration
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.duration) min")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.deepNavy.opacity(0.7))

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.sage)
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
