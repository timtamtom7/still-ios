import SwiftUI

struct LegacyView: View {
    @State private var selectedTab: LegacyTab = .document
    @State private var legacyDocument: LegacyDocument?
    @State private var isGenerating: Bool = false
    @State private var showGiftComposer: Bool = false
    @State private var giftRecipient: String = ""
    @State private var giftNote: String = ""
    @State private var showShareSheet: Bool = false
    @State private var exportedGiftText: String = ""

    private let db = DatabaseService.shared
    private let legacyService = LegacyService.shared

    enum LegacyTab: String, CaseIterable {
        case document = "My Story"
        case gift = "Gift"
        case memorial = "Memorial"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    tabPicker
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    tabContent
                }
            }
            .navigationTitle("Legacy")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == .document {
                        Button {
                            generateDocument()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.amber)
                        }
                        .disabled(isGenerating)
                    }
                }
            }
            .sheet(isPresented: $showGiftComposer) {
                giftComposerSheet
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [exportedGiftText])
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(LegacyTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(selectedTab == tab ? AppColors.textPrimary : AppColors.textSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedTab == tab ? AppColors.surface : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(AppColors.surface.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .document:
            documentView
        case .gift:
            giftView
        case .memorial:
            memorialView
        }
    }

    // MARK: - Document View

    private var documentView: some View {
        Group {
            if isGenerating {
                generatingView
            } else if let doc = legacyDocument {
                documentContent(doc)
            } else {
                emptyDocumentView
            }
        }
    }

    private var generatingView: some View {
        VStack(spacing: 24) {
            Spacer()
            BreathingOrb(state: .attentive, scale: .constant(1.0), size: .standard)
                .scaleEffect(0.7)

            Text("Gathering your reflections...")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
    }

    private var emptyDocumentView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 56))
                .foregroundColor(AppColors.textSecondary.opacity(0.4))

            VStack(spacing: 8) {
                Text("Your legacy document")
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)

                Text("Still is holding space for your story.\nReflect often, and your story will emerge.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                generateDocument()
            } label: {
                Text("Generate Document")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.amber)
                    .cornerRadius(20)
            }

            Spacer()
        }
        .padding(32)
    }

    private func documentContent(_ doc: LegacyDocument) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text(doc.title)
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)

                Text("A distillation of your Still practice")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Divider()
                    .background(AppColors.separator)

                // Introduction
                Text(doc.introduction)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(6)

                // Growth narrative
                if !doc.growthNarrative.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.amber)
                            Text("Growth Narrative")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.amber)
                        }

                        Text(doc.growthNarrative)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .italic()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                }

                // Life themes
                if !doc.lifeThemes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.amber)
                            Text("Life Themes")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.amber)
                        }

                        ForEach(doc.lifeThemes) { theme in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(theme.name)
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text("\(theme.frequency)×")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }

                                Text(theme.description)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(12)
                            .background(AppColors.background)
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                }

                // Chapters (months)
                ForEach(doc.chapters) { chapter in
                    LegacyChapterCard(chapter: chapter)
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
    }

    private func generateDocument() {
        isGenerating = true
        let reflections = db.getAllReflections()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            legacyDocument = legacyService.generateLegacyDocument(reflections: reflections)
            isGenerating = false
        }
    }

    // MARK: - Gift View

    private var giftView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "gift")
                .font(.system(size: 56))
                .foregroundColor(AppColors.amber.opacity(0.6))

            VStack(spacing: 8) {
                Text("Gift a reflection")
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)

                Text("Share a moment of your inner life\nwith someone who matters")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showGiftComposer = true
            } label: {
                Text("Create a Gift")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.amber)
                    .cornerRadius(20)
            }

            Spacer()
        }
        .padding(32)
    }

    private var giftComposerSheet: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipient's name")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)

                            TextField("Who is this gift for?", text: $giftRecipient)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(12)
                                .background(AppColors.surface)
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal note (optional)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)

                            TextEditor(text: $giftNote)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(height: 80)
                                .padding(8)
                                .background(AppColors.surface)
                                .cornerRadius(8)
                        }

                        let reflectionCount = db.getAllReflections().count
                        Text("\(reflectionCount) reflections available")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Create a Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showGiftComposer = false
                        giftRecipient = ""
                        giftNote = ""
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        createAndShareGift()
                    }
                    .foregroundColor(AppColors.amber)
                    .disabled(giftRecipient.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func createAndShareGift() {
        let reflections = db.getAllReflections()
        let gift = legacyService.createGiftPackage(
            reflections: reflections,
            recipient: giftRecipient,
            personalNote: giftNote.isEmpty ? nil : giftNote
        )
        exportedGiftText = legacyService.exportGiftPackage(gift)
        showGiftComposer = false
        showShareSheet = true
        giftRecipient = ""
        giftNote = ""
    }

    // MARK: - Memorial View

    private var memorialView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let person = legacyService.getMemorialPerson() {
                memorialActiveView(person: person)
            } else {
                memorialSetupView
            }

            Spacer()
        }
        .padding(32)
    }

    private func memorialActiveView(person: MemorialPerson) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.amber.opacity(0.6))

            VStack(spacing: 8) {
                Text("Memorial Mode Active")
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)

                Text("Remembering \(person.name)")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                Text(person.relationship)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }

            VStack(spacing: 12) {
                let reflections = db.getAllReflections()
                let memorialReflections = legacyService.generateMemorialReflections(for: person, allReflections: reflections)

                if memorialReflections.isEmpty {
                    Text("Reflections connected to \(person.name) will appear here")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(memorialReflections.count) connected reflection(s)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    ForEach(memorialReflections.prefix(3), id: \.reflection.id) { memorial in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memorial.reflection.formattedDate)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)

                            Text(memorial.reflection.previewText)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface)
                        .cornerRadius(8)
                    }
                }
            }

            Button {
                legacyService.deactivateMemorialMode()
            } label: {
                Text("End Memorial Mode")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var memorialSetupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart")
                .font(.system(size: 56))
                .foregroundColor(AppColors.textSecondary.opacity(0.4))

            VStack(spacing: 8) {
                Text("Memorial Mode")
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)

                Text("Still can hold a space for\nsomeone you've lost")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                // For now, activate with a default person
                // Full implementation would have a form
                let person = MemorialPerson(
                    name: "Someone remembered",
                    relationship: "Loved one"
                )
                legacyService.activateMemorialMode(for: person)
            } label: {
                Text("Set Up Memorial Mode")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.amber)
                    .cornerRadius(20)
            }
        }
    }
}

// MARK: - Legacy Chapter Card

struct LegacyChapterCard: View {
    let chapter: LegacyChapter
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.title)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textPrimary)

                        Text("\(chapter.reflections.count) reflection(s)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            if isExpanded {
                ForEach(chapter.reflections.prefix(3)) { reflection in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reflection.formattedDate)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Text(reflection.previewText)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(3)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.background)
                    .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
