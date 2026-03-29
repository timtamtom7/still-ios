import SwiftUI

// MARK: - Teacher Model

struct Teacher: Identifiable, Hashable {
    let id: UUID
    let name: String
    let title: String
    let bio: String
    let specialties: [SessionCategory]
    let courseIds: [UUID]
    let imageName: String
    let yearsExperience: Int
    let sessionsCount: Int
}

extension Teacher {
    var courses: [MeditationCourse] {
        courseIds.compactMap { CourseService.shared.getCourse(byId: $0) }
    }

    var specialtiesText: String {
        specialties.map { $0.rawValue }.joined(separator: " • ")
    }
}

// MARK: - Teacher Library

struct TeacherLibrary {
    static let teachers: [Teacher] = [
        Teacher(
            id: UUID(),
            name: "Sarah Chen",
            title: "Mindfulness Guide",
            bio: "Sarah discovered meditation during a challenging period in her life and has been sharing its transformative power for over a decade. Her teaching blends Western mindfulness with contemplative traditions, creating a warm and approachable practice for modern life.",
            specialties: [.morning, .breathing, .bodyScan],
            courseIds: CourseLibrary.courses.filter { $0.instructor == "Sarah Chen" }.map { $0.id },
            imageName: "person.crop.circle.fill",
            yearsExperience: 12,
            sessionsCount: 847
        ),

        Teacher(
            id: UUID(),
            name: "Luna Martinez",
            title: "Sleep & Anxiety Specialist",
            bio: "Luna brings a gentle, compassionate presence to her teaching. Trained in sleep science and somatic therapy, she specializes in guiding people through anxiety and into rest. Her voice is a trusted companion for many at the end of difficult days.",
            specialties: [.sleep, .anxiety, .breathing],
            courseIds: CourseLibrary.courses.filter { $0.instructor == "Luna Martinez" }.map { $0.id },
            imageName: "person.crop.circle.fill",
            yearsExperience: 8,
            sessionsCount: 612
        ),

        Teacher(
            id: UUID(),
            name: "Marcus Webb",
            title: "Focus & Performance Coach",
            bio: "A former competitive athlete, Marcus discovered meditation as a tool for enhancing performance under pressure. His sessions are structured and practical, drawing from Buddhist concentration practices and modern neuroscience to help you achieve peak focus.",
            specialties: [.focus, .morning, .breathing],
            courseIds: CourseLibrary.courses.filter { $0.instructor == "Marcus Webb" }.map { $0.id },
            imageName: "person.crop.circle.fill",
            yearsExperience: 10,
            sessionsCount: 734
        ),

        Teacher(
            id: UUID(),
            name: "James Park",
            title: "Contemplative Teacher",
            bio: "James spent three years in silent retreat before returning to teach. His explorations into non-dual awareness and the nature of consciousness offer a profound depth rarely found in app-based meditation. Best suited for those ready to go deeper.",
            specialties: [.focus, .bodyScan, .anxiety],
            courseIds: CourseLibrary.courses.filter { $0.instructor == "James Park" }.map { $0.id },
            imageName: "person.crop.circle.fill",
            yearsExperience: 15,
            sessionsCount: 423
        )
    ]
}

// MARK: - TeachersView

struct TeachersView: View {
    @State private var teachers: [Teacher] = TeacherLibrary.teachers
    @State private var selectedTeacher: Teacher?
    @State private var searchText = ""

    var filteredTeachers: [Teacher] {
        if searchText.isEmpty {
            return teachers
        }
        return teachers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.specialtiesText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if !teachers.isEmpty {
                    teachersGrid
                }
            }
            .padding(24)
        }
        .background(Theme.deepNavy)
        .sheet(item: $selectedTeacher) { teacher in
            TeacherDetailSheet(teacher: teacher)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Teachers")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Theme.softWhite)

            Text("Learn from experienced guides")
                .font(.system(size: 15))
                .foregroundColor(Theme.calmBlue)
        }
    }

    // MARK: - Teachers Grid

    private var teachersGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredTeachers) { teacher in
                TeacherCard(teacher: teacher)
                    .onTapGesture {
                        selectedTeacher = teacher
                    }
            }
        }
    }
}

// MARK: - Teacher Card

struct TeacherCard: View {
    let teacher: Teacher

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.calmBlue.opacity(0.2))
                    .frame(width: 72, height: 72)

                Image(systemName: teacher.imageName)
                    .font(.system(size: 32))
                    .foregroundColor(Theme.calmBlue)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(teacher.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.softWhite)

                Text(teacher.title)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.calmBlue)

                HStack(spacing: 4) {
                    ForEach(teacher.specialties.prefix(3), id: \.self) { specialty in
                        Text(specialty.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.softWhite.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.surface.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.3))
        }
        .padding(16)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Teacher Detail Sheet

struct TeacherDetailSheet: View {
    let teacher: Teacher
    @Environment(\.dismiss) private var dismiss
    @State private var showingCourses = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    bioSection
                    statsSection
                    specialtiesSection
                    coursesSection
                }
                .padding(24)
            }
            .background(Theme.deepNavy)
            .navigationTitle(teacher.name)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.softWhite.opacity(0.5))
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.calmBlue.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: teacher.imageName)
                    .font(.system(size: 48))
                    .foregroundColor(Theme.calmBlue)
            }

            Text(teacher.name)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.softWhite)

            Text(teacher.title)
                .font(.system(size: 15))
                .foregroundColor(Theme.calmBlue)
        }
        .padding(.top, 8)
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.7))

            Text(teacher.bio)
                .font(.system(size: 14))
                .foregroundColor(Theme.softWhite.opacity(0.8))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        HStack(spacing: 0) {
            StatPill(value: "\(teacher.yearsExperience)", label: "Years")
            Divider().frame(height: 40).background(Theme.surface.opacity(0.2))
            StatPill(value: "\(teacher.sessionsCount)", label: "Sessions")
            Divider().frame(height: 40).background(Theme.surface.opacity(0.2))
            StatPill(value: "\(teacher.courses.count)", label: "Courses")
        }
        .padding(.vertical, 8)
        .background(Theme.surface.opacity(0.1))
        .cornerRadius(12)
    }

    private var specialtiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specialties")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.7))

            FlowLayout(spacing: 8) {
                ForEach(teacher.specialties, id: \.self) { specialty in
                    HStack(spacing: 6) {
                        Image(systemName: specialty.icon)
                            .font(.system(size: 12))
                        Text(specialty.rawValue)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Theme.softWhite)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.calmBlue.opacity(0.15))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Courses")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.softWhite.opacity(0.7))

            ForEach(teacher.courses) { course in
                CourseRowCompact(course: course)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.softWhite)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.softWhite.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CourseRowCompact: View {
    let course: MeditationCourse

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.calmBlue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: course.imageName)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.calmBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(course.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.softWhite)

                Text("\(course.totalSessions) sessions • \(course.duration) min")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.softWhite.opacity(0.5))
            }

            Spacer()

            Text(course.level.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.calmBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.calmBlue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Theme.surface.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    TeachersView()
        .frame(width: 420, height: 800)
}
