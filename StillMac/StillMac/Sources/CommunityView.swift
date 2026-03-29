import SwiftUI
import Combine

// MARK: - Community Meditation Session

struct CommunityMeditation: Identifiable {
    let id: UUID
    let theme: String
    let instructor: String
    let participantCount: Int
    let startedAt: Date
    let duration: Int
    let category: SessionCategory
    let isActive: Bool

    var elapsedSeconds: Int {
        Int(Date().timeIntervalSince(startedAt))
    }

    var remainingSeconds: Int {
        max(0, duration * 60 - elapsedSeconds)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(duration * 60))
    }
}

// MARK: - Community Member

struct CommunityMember: Identifiable {
    let id: UUID
    let name: String
    let avatarInitial: String
    let streak: Int
    let totalMinutes: Int
}

// MARK: - CommunityView

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedSession: CommunityMeditation?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                liveNowSection

                if !viewModel.upcomingSessions.isEmpty {
                    upcomingSection
                }

                communityStatsSection

                recentMeditatorsSection
            }
            .padding(24)
        }
        .background(Theme.deepNavy)
        .onAppear {
            viewModel.startLiveUpdates()
        }
        .onDisappear {
            viewModel.stopLiveUpdates()
        }
    }

    // MARK: - Live Now Section

    private var liveNowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Now")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.softWhite)

                    HStack(spacing: 6) {
                        LiveDot()
                        Text("Join \(viewModel.totalLiveMeditators) people meditating right now")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.calmBlue)
                    }
                }

                Spacer()
            }

            if viewModel.activeSessions.isEmpty {
                emptyLiveView
            } else {
                ForEach(viewModel.activeSessions) { session in
                    LiveSessionCard(session: session, viewModel: viewModel)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
            }
        }
    }

    private var emptyLiveView: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 40))
                .foregroundColor(Theme.calmBlue.opacity(0.4))

            Text("No live sessions right now")
                .font(.system(size: 14))
                .foregroundColor(Theme.softWhite.opacity(0.5))

            Text("Start one and invite the community")
                .font(.system(size: 12))
                .foregroundColor(Theme.softWhite.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Theme.surface.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming Up")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.8))

            ForEach(viewModel.upcomingSessions) { session in
                UpcomingSessionRow(session: session)
            }
        }
        .padding(16)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Community Stats

    private var communityStatsSection: some View {
        HStack(spacing: 0) {
            CommunityStat(value: formatNumber(viewModel.totalCommunityMinutes), label: "Minutes meditated")
            Divider().frame(height: 50).background(Theme.surface.opacity(0.2))
            CommunityStat(value: "\(viewModel.totalCommunitySessions)", label: "Sessions today")
            Divider().frame(height: 50).background(Theme.surface.opacity(0.2))
            CommunityStat(value: "\(viewModel.activeCommunityMembers)", label: "Online now")
        }
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(16)
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000.0)
        }
        return "\(num)"
    }

    // MARK: - Recent Meditators

    private var recentMeditatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Meditated")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.8))

            FlowLayout(spacing: 8) {
                ForEach(viewModel.recentMembers) { member in
                    MemberBubble(member: member)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Live Dot

struct LiveDot: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Theme.accent)
            .frame(width: 8, height: 8)
            .opacity(isAnimating ? 0.4 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Live Session Card

struct LiveSessionCard: View {
    let session: CommunityMeditation
    @ObservedObject var viewModel: CommunityViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.theme)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.softWhite)

                    Text("with \(session.instructor)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.calmBlue)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        Text("\(session.participantCount)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Theme.sage)

                    Text(session.category.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.softWhite.opacity(0.5))
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surface.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.calmBlue)
                        .frame(width: geometry.size.width * session.progress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text(viewModel.formatTime(session.remainingSeconds))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.softWhite.opacity(0.6))

                Spacer()

                Button {
                    // Join action
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text("Join")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Theme.sage)
                    .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.sage.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Upcoming Session Row

struct UpcomingSessionRow: View {
    let session: CommunityMeditation

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Theme.calmBlue.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: session.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.calmBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.theme)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.softWhite)

                Text("with \(session.instructor) • \(session.duration) min")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.softWhite.opacity(0.5))
            }

            Spacer()

            Text(session.startedAt, style: .time)
                .font(.system(size: 12))
                .foregroundColor(Theme.calmBlue)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Community Stat

struct CommunityStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.softWhite)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.softWhite.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Member Bubble

struct MemberBubble: View {
    let member: CommunityMember

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.calmBlue.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay {
                    Text(member.avatarInitial)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.calmBlue)
                }

            Text(member.name)
                .font(.system(size: 12))
                .foregroundColor(Theme.softWhite.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.surface.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - CommunityViewModel

class CommunityViewModel: ObservableObject {
    @Published var activeSessions: [CommunityMeditation] = []
    @Published var upcomingSessions: [CommunityMeditation] = []
    @Published var recentMembers: [CommunityMember] = []
    @Published var totalLiveMeditators: Int = 0
    @Published var totalCommunityMinutes: Int = 0
    @Published var totalCommunitySessions: Int = 0
    @Published var activeCommunityMembers: Int = 0

    private var timer: AnyCancellable?
    private let courseService = CourseService.shared

    init() {
        loadData()
    }

    func startLiveUpdates() {
        loadData()

        // Simulate live updates every 5 seconds
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.simulateLiveUpdate()
            }
    }

    func stopLiveUpdates() {
        timer?.cancel()
        timer = nil
    }

    func loadData() {
        // Active live sessions
        activeSessions = [
            CommunityMeditation(
                id: UUID(),
                theme: "Morning Calm",
                instructor: "Sarah Chen",
                participantCount: 47,
                startedAt: Date().addingTimeInterval(-300),
                duration: 10,
                category: .morning,
                isActive: true
            ),
            CommunityMeditation(
                id: UUID(),
                theme: "Letting Go",
                instructor: "Luna Martinez",
                participantCount: 38,
                startedAt: Date().addingTimeInterval(-600),
                duration: 15,
                category: .anxiety,
                isActive: true
            ),
            CommunityMeditation(
                id: UUID(),
                theme: "Deep Focus",
                instructor: "Marcus Webb",
                participantCount: 22,
                startedAt: Date().addingTimeInterval(-120),
                duration: 20,
                category: .focus,
                isActive: true
            )
        ]

        // Upcoming sessions
        upcomingSessions = [
            CommunityMeditation(
                id: UUID(),
                theme: "Evening Wind Down",
                instructor: "James Park",
                participantCount: 0,
                startedAt: Date().addingTimeInterval(1800),
                duration: 15,
                category: .sleep,
                isActive: false
            ),
            CommunityMeditation(
                id: UUID(),
                theme: "Breath & Balance",
                instructor: "Sarah Chen",
                participantCount: 0,
                startedAt: Date().addingTimeInterval(3600),
                duration: 10,
                category: .breathing,
                isActive: false
            )
        ]

        totalLiveMeditators = activeSessions.reduce(0) { $0 + $1.participantCount }

        // Recent members
        recentMembers = [
            CommunityMember(id: UUID(), name: "Alex", avatarInitial: "A", streak: 12, totalMinutes: 840),
            CommunityMember(id: UUID(), name: "Jordan", avatarInitial: "J", streak: 5, totalMinutes: 320),
            CommunityMember(id: UUID(), name: "Sam", avatarInitial: "S", streak: 28, totalMinutes: 2100),
            CommunityMember(id: UUID(), name: "Riley", avatarInitial: "R", streak: 8, totalMinutes: 560),
            CommunityMember(id: UUID(), name: "Casey", avatarInitial: "C", streak: 3, totalMinutes: 180),
            CommunityMember(id: UUID(), name: "Morgan", avatarInitial: "M", streak: 21, totalMinutes: 1450),
            CommunityMember(id: UUID(), name: "Taylor", avatarInitial: "T", streak: 7, totalMinutes: 490),
            CommunityMember(id: UUID(), name: "Quinn", avatarInitial: "Q", streak: 14, totalMinutes: 980),
        ]

        // Community stats (simulated)
        totalCommunityMinutes = 284750
        totalCommunitySessions = 12847
        activeCommunityMembers = 127
    }

    private func simulateLiveUpdate() {
        // Simulate fluctuating participant counts
        for i in 0..<activeSessions.count {
            let delta = Int.random(in: -3...3)
            let newCount = max(1, activeSessions[i].participantCount + delta)

            activeSessions[i] = CommunityMeditation(
                id: activeSessions[i].id,
                theme: activeSessions[i].theme,
                instructor: activeSessions[i].instructor,
                participantCount: newCount,
                startedAt: activeSessions[i].startedAt,
                duration: activeSessions[i].duration,
                category: activeSessions[i].category,
                isActive: true
            )
        }

        totalLiveMeditators = activeSessions.reduce(0) { $0 + $1.participantCount }
        activeCommunityMembers = totalLiveMeditators + Int.random(in: 10...30)
    }

    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview {
    CommunityView()
        .frame(width: 420, height: 800)
}
