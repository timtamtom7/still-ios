import SwiftUI

@main
struct StillApp: App {
    @StateObject private var ritualViewModel = RitualViewModel()
    @StateObject private var archiveViewModel = ArchiveViewModel()
    @StateObject private var weekReviewViewModel = WeekReviewViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ritualViewModel)
                .environmentObject(archiveViewModel)
                .environmentObject(weekReviewViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var ritualViewModel: RitualViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RitualView()
                .tabItem {
                    Image(systemName: "moon.stars")
                    Text("Tonight")
                }
                .tag(0)

            ArchiveView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Archive")
                }
                .tag(1)

            WeekReviewView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Week")
                }
                .tag(2)
        }
        .tint(AppColors.amber)
    }
}
