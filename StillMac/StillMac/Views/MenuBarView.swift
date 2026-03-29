import SwiftUI

struct MenuBarView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab: AppState.Tab = .breathe

    var body: some View {
        VStack(spacing: 0) {
            // Header with mini player context
            MiniPlayerHeader()

            Divider()
                .background(Theme.deepNavy.opacity(0.2))

            // Tab content
            TabView(selection: $selectedTab) {
                MeditationPlayerView()
                    .tag(AppState.Tab.breathe)

                SessionLibraryView()
                    .tag(AppState.Tab.library)

                StatsView()
                    .tag(AppState.Tab.stats)

                SettingsView()
                    .tag(AppState.Tab.settings)
            }
            .tabViewStyle(.automatic)

            // Bottom tab bar
            TabBar(selectedTab: $selectedTab)
        }
        .frame(width: 480, height: 600)
        .background(Theme.surface)
    }
}

struct MiniPlayerHeader: View {
    @State private var currentSessionName = "Evening Calm"
    @State private var currentDuration = "10 min"

    var body: some View {
        HStack(spacing: 16) {
            BreathingOrbMini()

            VStack(alignment: .leading, spacing: 2) {
                Text(currentSessionName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.deepNavy)

                Text(currentDuration)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.calmBlue)
            }

            Spacer()

            Text("Day 7")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.sage)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Theme.cardBg)
    }
}

struct TabBar: View {
    @Binding var selectedTab: AppState.Tab

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "brain.head.profile", title: "Breathe", isSelected: selectedTab == .breathe) {
                selectedTab = .breathe
            }

            TabBarItem(icon: "books.vertical", title: "Library", isSelected: selectedTab == .library) {
                selectedTab = .library
            }

            TabBarItem(icon: "chart.bar.xaxis", title: "Stats", isSelected: selectedTab == .stats) {
                selectedTab = .stats
            }

            TabBarItem(icon: "gearshape", title: "Settings", isSelected: selectedTab == .settings) {
                selectedTab = .settings
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Theme.cardBg)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))

                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? Theme.calmBlue : Theme.deepNavy.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
