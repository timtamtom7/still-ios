import SwiftUI

enum RitualState {
    case waiting
    case ready
    case reflecting
    case completed
    case skipped
}

@main
struct StillMacApp: App {
    var body: some Scene {
        WindowGroup {
            StillMacView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 600, height: 800)
    }
}

struct StillMacView: View {
    @State private var state: RitualState = .waiting
    @State private var todaysQuestion: String = ""
    @State private var reflectionText: String = ""
    @State private var showRating: Bool = false
    @State private var breathingScale: CGFloat = 1.0

    private let db = DatabaseService.shared
    private let questionBank = QuestionBank.shared

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 20)

                Spacer()

                orbSection

                Spacer()

                bottomSection
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, idealWidth: 600, maxWidth: .infinity, minHeight: 600, idealHeight: 800)
        .onAppear { loadState() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("Still")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(formattedDate)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 40)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Orb Section

    private var orbSection: some View {
        VStack(spacing: 40) {
            // Large orb for macOS
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.amberGlow,
                                AppColors.amber,
                                AppColors.amber.opacity(0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .opacity(orbOpacity)
                    .scaleEffect(breathingScale)
                    .shadow(color: AppColors.amberGlow.opacity(orbGlowOpacity), radius: 60, x: 0, y: 0)
                    .shadow(color: AppColors.amberGlow.opacity(orbGlowOpacity * 0.5), radius: 120, x: 0, y: 0)
                    .frame(width: 240, height: 240)
                    .onTapGesture { tapOrb() }
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathingScale)
            }

            questionView
                .opacity(showQuestion ? 1 : 0)
                .animation(.easeOut(duration: 0.8), value: showQuestion)
        }
    }

    private var showQuestion: Bool {
        state == .ready || state == .reflecting
    }

    private var orbOpacity: Double {
        switch state {
        case .waiting: return 0.5
        case .ready: return 0.7
        case .reflecting: return 0.9
        case .completed: return 0.3
        case .skipped: return 0.5
        }
    }

    private var orbGlowOpacity: Double {
        switch state {
        case .waiting: return 0.2
        case .ready: return 0.4
        case .reflecting: return 0.6
        case .completed: return 0.15
        case .skipped: return 0.2
        }
    }

    // MARK: - Question View

    @ViewBuilder
    private var questionView: some View {
        VStack(spacing: 24) {
            Text(todaysQuestion)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .frame(maxWidth: 500)

            if state == .reflecting {
                reflectionInputSection
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: state)
    }

    private var reflectionInputSection: some View {
        VStack(spacing: 20) {
            TextEditor(text: $reflectionText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 100)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(AppColors.textPrimary)
                .padding(16)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.separator, lineWidth: 1)
                )

            Button(action: submitReflection) {
                Text("Release to the night")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.amber)
                    .cornerRadius(24)
            }
            .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: 500)
    }

    // MARK: - Bottom Section

    @ViewBuilder
    private var bottomSection: some View {
        VStack(spacing: 12) {
            switch state {
            case .waiting:
                Text("Still will be here tonight")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)

            case .ready:
                Text("Click the orb when you're ready")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))

            case .reflecting:
                EmptyView()

            case .completed:
                VStack(spacing: 4) {
                    Text("Good night")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Your reflection has been held")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }

            case .skipped:
                Text("Still is here when you're ready")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Actions

    private func loadState() {
        let today = Date()
        if db.hasReflection(for: today) {
            state = .completed
        } else if !isEvening {
            state = .waiting
        } else {
            todaysQuestion = questionBank.todaysQuestion()
            state = .ready
            startBreathing()
        }
    }

    private var isEvening: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 21 || hour < 6
    }

    private func startBreathing() {
        breathingScale = 1.08
    }

    private func tapOrb() {
        guard state == .ready else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            state = .reflecting
        }
    }

    private func submitReflection() {
        guard !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let reflection = Reflection(
            question: todaysQuestion,
            text: reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try db.saveReflection(reflection)
            withAnimation(.easeInOut(duration: 1.2)) {
                state = .completed
            }
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
