import SwiftUI
import UIKit

struct RitualView: View {
    @EnvironmentObject var viewModel: RitualViewModel
    @ObservedObject var soundManager = SoundManager.shared

    private var orbState: OrbState {
        switch viewModel.state {
        case .waiting: return .idle
        case .ready: return .attentive
        case .reflecting: return .recording
        case .completed: return .complete
        case .skipped: return .idle
        }
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        topBar

                        Spacer(minLength: 32)

                        orbSection

                        Spacer(minLength: 32)

                        bottomSection
                    }
                    .frame(minHeight: geometry.size.height - 120)
                }
            }

            // Rating overlay
            if viewModel.showRating {
                ratingOverlay
            }
        }
        .alert("Couldn't Save", isPresented: $viewModel.showSaveError) {
            if viewModel.showUpgradePrompt {
                Button("Upgrade to Pro") {
                    viewModel.dismissSaveError()
                    viewModel.showUpgradePrompt = false
                    // Navigate to subscription - handled by parent
                }
            } else {
                Button("Try Again") {
                    viewModel.dismissSaveError()
                    viewModel.submitReflection()
                }
            }
            Button("Dismiss", role: .cancel) {
                viewModel.dismissSaveError()
                viewModel.showUpgradePrompt = false
            }
        } message: {
            Text(viewModel.saveErrorMessage)
        }
        .onAppear {
            if viewModel.state == .ready || viewModel.state == .waiting {
                viewModel.startBreathing()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 8) {
            // Offline banner
            if viewModel.showOfflineBanner {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 12))
                    Text("Offline — reflections saved locally")
                        .font(AppTypography.caption)
                    Spacer()
                    Button {
                        withAnimation { viewModel.showOfflineBanner = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                    }
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.surface)
                .cornerRadius(8)
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack {
                if viewModel.state == .reflecting {
                    AmbientSoundPicker()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()

                // Memory lane button
                if hasMemoryLane {
                    NavigationLink {
                        MemoryLaneView(
                            oneYearAgo: viewModel.oneYearAgoReflection,
                            oneMonthAgo: viewModel.oneMonthAgoReflection,
                            thisDayInHistory: viewModel.thisDayInHistoryReflections
                        )
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                            Text("Memories")
                                .font(AppTypography.caption)
                        }
                        .foregroundColor(AppColors.amber.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.surface)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.state)
    }

    private var hasMemoryLane: Bool {
        viewModel.oneYearAgoReflection != nil ||
        viewModel.oneMonthAgoReflection != nil ||
        !viewModel.thisDayInHistoryReflections.isEmpty
    }

    private var orbSize: BreathingOrb.OrbSize {
        #if targetEnvironment(simulator)
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        #else
        let isIPad = false
        #endif
        if isIPad {
            return .large
        }
        return .standard
    }

    // MARK: - Orb Section

    private var orbSection: some View {
        VStack(spacing: 48) {
            ZStack {
                BreathingOrb(state: orbState, scale: $viewModel.breathingScale, size: orbSize)
                    .onTapGesture {
                        viewModel.tapOrb()
                    }
            }
            .frame(width: orbSize.dimension, height: orbSize.dimension)

            questionView
                .opacity(viewModel.state == .ready || viewModel.state == .reflecting ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: viewModel.state)
        }
    }

    // MARK: - Question View

    @ViewBuilder
    private var questionView: some View {
        VStack(spacing: 32) {
            if viewModel.showTypewriter && viewModel.state == .reflecting {
                TypewriterText(
                    text: viewModel.todaysQuestion,
                    font: AppTypography.display,
                    color: AppColors.textPrimary,
                    speed: 25
                )
                .padding(.horizontal, 32)
            } else {
                Text(viewModel.todaysQuestion)
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if viewModel.state == .reflecting {
                reflectionInputSection
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: viewModel.state)
    }

    // MARK: - Reflection Input

    private var reflectionInputSection: some View {
        VStack(spacing: 24) {
            ReflectionInput(
                text: $viewModel.reflectionText,
                placeholder: "Take your time...",
                characterLimit: 500
            )
            .padding(.horizontal, 32)

            SubmitButton(
                title: "Release to the night",
                action: { viewModel.submitReflection() },
                isEnabled: !viewModel.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 16) {
            switch viewModel.state {
            case .waiting:
                waitingView

            case .ready:
                readyView

            case .reflecting:
                reflectingView

            case .completed:
                completedView

            case .skipped:
                skippedView
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
    }

    @ViewBuilder
    private var waitingView: some View {
        VStack(spacing: 16) {
            if viewModel.showNudge {
                NudgeBanner(message: viewModel.nudgeMessage) {
                    viewModel.dismissNudge()
                }
            }

            Text("Still will be here tonight")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var readyView: some View {
        VStack(spacing: 8) {
            if let yearAgo = viewModel.oneYearAgoReflection {
                MemoryLaneCard(memoryType: .oneYearAgo, reflection: yearAgo)
            }

            Text("Tap the orb when you're ready")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    @ViewBuilder
    private var reflectingView: some View {
        EmptyView()
    }

    @ViewBuilder
    private var completedView: some View {
        VStack(spacing: 8) {
            Text("Good night")
                .font(AppTypography.display)
                .foregroundColor(AppColors.textPrimary)

            Text("Your reflection has been held")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private var skippedView: some View {
        Text("Still is here when you're ready")
            .font(AppTypography.body)
            .foregroundColor(AppColors.textSecondary)
    }

    // MARK: - Rating Overlay

    private var ratingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap - require rating or skip
                }

            QuestionRatingView(
                question: viewModel.todaysQuestion,
                onRate: { rating in
                    viewModel.rateQuestion(rating)
                }
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }

}

// MARK: - Memory Lane View

struct MemoryLaneView: View {
    let oneYearAgo: Reflection?
    let oneMonthAgo: Reflection?
    let thisDayInHistory: [Reflection]
    @State private var selectedReflection: Reflection?

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let yearAgo = oneYearAgo {
                        MemoryLaneCard(memoryType: .oneYearAgo, reflection: yearAgo) { ref in
                            selectedReflection = ref
                        }
                    }

                    if let monthAgo = oneMonthAgo {
                        MemoryLaneCard(memoryType: .oneMonthAgo, reflection: monthAgo) { ref in
                            selectedReflection = ref
                        }
                    }

                    if !thisDayInHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.amber)
                                Text("This day in history")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.amber)
                                Spacer()
                            }

                            ForEach(thisDayInHistory) { reflection in
                                MemoryLaneCard(memoryType: .thisDayInHistory, reflection: reflection) { ref in
                                    selectedReflection = ref
                                }
                            }
                        }
                    }

                    if oneYearAgo == nil && oneMonthAgo == nil && thisDayInHistory.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textSecondary)

                            Text("No memories yet")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)

                            Text("Your past reflections will appear here on their anniversaries")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(48)
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Memory Lane")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedReflection) { reflection in
            ReflectionDetailSheet(reflection: reflection)
        }
    }
}
