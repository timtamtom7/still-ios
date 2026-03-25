import SwiftUI

struct RitualView: View {
    @EnvironmentObject var viewModel: RitualViewModel
    @State private var animationPhase: CGFloat = 1.0

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

            VStack(spacing: 0) {
                if viewModel.showNudge {
                    NudgeBanner(message: viewModel.nudgeMessage) {
                        viewModel.dismissNudge()
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                orbSection

                Spacer()

                bottomSection
            }
            .animation(.easeInOut(duration: 0.6), value: viewModel.state)
        }
        .onAppear {
            if viewModel.state == .ready || viewModel.state == .waiting {
                startBreathingAnimation()
            }
        }
    }

    private var orbSection: some View {
        VStack(spacing: 48) {
            ZStack {
                BreathingOrb(state: orbState, scale: $animationPhase)
                    .onTapGesture {
                        viewModel.tapOrb()
                    }
                    .scaleEffect(viewModel.breathingScale)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: viewModel.breathingScale)
            }
            .frame(width: 160, height: 160)

            questionView
                .opacity(viewModel.state == .ready || viewModel.state == .reflecting ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: viewModel.state)
        }
    }

    @ViewBuilder
    private var questionView: some View {
        VStack(spacing: 32) {
            Text(viewModel.todaysQuestion)
                .font(AppTypography.display)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if viewModel.state == .reflecting {
                reflectionInputSection
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: viewModel.state)
    }

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

    private var bottomSection: some View {
        VStack(spacing: 16) {
            switch viewModel.state {
            case .waiting:
                Text("Still will be here tonight")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

            case .ready:
                Text("Tap the orb when you're ready")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

            case .reflecting:
                EmptyView()

            case .completed:
                VStack(spacing: 8) {
                    Text("Good night")
                        .font(AppTypography.display)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Your reflection has been held")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.bottom, 40)

            case .skipped:
                Text("Still is here when you're ready")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
    }

    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            animationPhase = 1.08
        }
    }
}
