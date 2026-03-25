import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var viewModel: ArchiveViewModel
    @State private var selectedReflection: Reflection?
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if viewModel.reflections.isEmpty && viewModel.searchQuery.isEmpty {
                    emptyState
                } else {
                    archiveList
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSearching.toggle()
                        }
                    } label: {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .sheet(item: $selectedReflection) { reflection in
                ReflectionDetailSheet(reflection: reflection)
            }
        }
        .onAppear {
            viewModel.loadReflections()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("Your reflections will live here")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var archiveList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Search bar
                if isSearching {
                    SearchBar(text: $viewModel.searchQuery, placeholder: "Search reflections...")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Memory Lane preview in archive
                MemoryLanePreview()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                // Week groups with book-like layout
                ForEach(viewModel.weekGroups) { group in
                    BookLikeWeekSection(group: group, onSelect: { reflection in
                        selectedReflection = reflection
                    })
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Book-Like Week Section

struct BookLikeWeekSection: View {
    let group: WeekGroup
    let onSelect: (Reflection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book spine / section header
            HStack {
                Rectangle()
                    .fill(AppColors.amber.opacity(0.3))
                    .frame(width: 3, height: 16)

                Text(group.title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Spacer()

                Text("\(group.reflections.count)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // Cards arranged like pages
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(group.reflections) { reflection in
                        ArchiveReflectionCard(reflection: reflection)
                            .onTapGesture {
                                onSelect(reflection)
                            }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Archive Reflection Card

struct ArchiveReflectionCard: View {
    let reflection: Reflection
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Page tab / date
            HStack {
                Text(reflection.formattedDate)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                if reflection.questionRating != nil {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(AppColors.amber)
                }
            }

            // Question
            Text(reflection.question)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            // Preview text
            Text(reflection.previewText)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(width: 200, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.surface)
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 4,
                    x: 2,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.separator, lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Memory Lane Preview in Archive

struct MemoryLanePreview: View {
    @State private var oneYearAgo: Reflection?
    @State private var oneMonthAgo: Reflection?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if oneYearAgo != nil || oneMonthAgo != nil {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.amber)

                    Text("Memories")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.amber)

                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if let yearAgo = oneYearAgo {
                            MemoryPreviewCard(reflection: yearAgo, label: "1 year ago")
                        }
                        if let monthAgo = oneMonthAgo {
                            MemoryPreviewCard(reflection: monthAgo, label: "1 month ago")
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surface.opacity(0.5))
        .cornerRadius(12)
        .onAppear {
            loadMemoryLane()
        }
    }

    private func loadMemoryLane() {
        oneYearAgo = DatabaseService.shared.getReflectionOneYearAgo()
        oneMonthAgo = DatabaseService.shared.getReflectionOneMonthAgo()
    }
}

struct MemoryPreviewCard: View {
    let reflection: Reflection
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.amber)
                .textCase(.uppercase)

            Text(reflection.question)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)

            Text(reflection.previewText)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 160)
        .background(AppColors.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.amber.opacity(0.3), lineWidth: 1)
        )
    }
}
