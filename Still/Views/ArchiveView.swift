import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var viewModel: ArchiveViewModel
    @State private var selectedReflection: Reflection?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if viewModel.reflections.isEmpty {
                    emptyState
                } else {
                    archiveList
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                SearchBar(text: $viewModel.searchQuery, placeholder: "Search reflections...")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                ForEach(viewModel.weekGroups) { group in
                    Section {
                        ForEach(group.reflections) { reflection in
                            ArchiveRow(reflection: reflection)
                                .onTapGesture {
                                    selectedReflection = reflection
                                }
                                .padding(.horizontal, 24)

                            if reflection.id != group.reflections.last?.id {
                                Rectangle()
                                    .fill(AppColors.separator)
                                    .frame(height: 1)
                                    .padding(.leading, 24)
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.title)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.background)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}
