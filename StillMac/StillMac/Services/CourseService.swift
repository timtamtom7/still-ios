import Foundation

// MARK: - Course Models

struct MeditationCourse: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let sessions: [MeditationSession]
    let duration: Int
    let instructor: String
    let level: CourseLevel
    let imageName: String

    var totalSessions: Int { sessions.count }
}

enum CourseLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var color: String {
        switch self {
        case .beginner: return "sage"
        case .intermediate: return "calmBlue"
        case .advanced: return "orbGlow"
        }
    }
}

struct Enrollment: Identifiable {
    let id: UUID
    let course: MeditationCourse
    let enrolledAt: Date
    var completedSessions: Int
    var lastAccessedAt: Date?
    var isCompleted: Bool

    var progress: Double {
        guard course.totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(course.totalSessions)
    }
}

// MARK: - Course Library

struct CourseLibrary {
    static let courses: [MeditationCourse] = [
        // Beginner
        MeditationCourse(
            id: UUID(),
            name: "Foundations of Calm",
            description: "Build a solid meditation practice from the ground up. Learn breath awareness and gentle focus techniques.",
            sessions: [
                MeditationSession(name: "First Breath", duration: 5, instructor: "Sarah Chen", description: "Your very first meditation. Just breathe.", category: .breathing),
                MeditationSession(name: "Body Awareness", duration: 7, instructor: "Sarah Chen", description: "Notice sensations without judgment.", category: .bodyScan),
                MeditationSession(name: "Sounds & Thoughts", duration: 8, instructor: "Sarah Chen", description: "Observe thoughts as passing clouds.", category: .morning),
            ],
            duration: 20,
            instructor: "Sarah Chen",
            level: .beginner,
            imageName: "leaf.fill"
        ),

        MeditationCourse(
            id: UUID(),
            name: "Sleep Better",
            description: "A gentle 3-session series designed to ease you into restful sleep naturally.",
            sessions: [
                MeditationSession(name: "Wind Down", duration: 10, instructor: "Luna Martinez", description: "Release the day before bed.", category: .sleep),
                MeditationSession(name: "Progressive Relaxation", duration: 15, instructor: "Luna Martinez", description: "Tense and release, layer by layer.", category: .sleep),
                MeditationSession(name: "Drift Off", duration: 20, instructor: "Luna Martinez", description: "Guided imagery for deep rest.", category: .sleep),
            ],
            duration: 45,
            instructor: "Luna Martinez",
            level: .beginner,
            imageName: "moon.stars.fill"
        ),

        // Intermediate
        MeditationCourse(
            id: UUID(),
            name: "Focus & Flow",
            description: "Sharpen your attention and enter states of deep, effortless concentration.",
            sessions: [
                MeditationSession(name: "Focused Attention", duration: 10, instructor: "Marcus Webb", description: "Return again and again to your anchor.", category: .focus),
                MeditationSession(name: "Expanded Awareness", duration: 12, instructor: "Marcus Webb", description: "Widen the lens of your attention.", category: .focus),
                MeditationSession(name: "Deep Concentration", duration: 15, instructor: "Marcus Webb", description: "Sustained focus for real depth.", category: .focus),
                MeditationSession(name: "Flow State", duration: 15, instructor: "Marcus Webb", description: "Let concentration become effortless.", category: .focus),
            ],
            duration: 52,
            instructor: "Marcus Webb",
            level: .intermediate,
            imageName: "target"
        ),

        MeditationCourse(
            id: UUID(),
            name: "Anxiety Relief",
            description: "Practical tools to calm anxious patterns and find your ground in stressful moments.",
            sessions: [
                MeditationSession(name: "Grounding", duration: 8, instructor: "Luna Martinez", description: "Come back to the present moment.", category: .anxiety),
                MeditationSession(name: "Breath as Anchor", duration: 10, instructor: "Luna Martinez", description: "Your breath is always there for you.", category: .anxiety),
                MeditationSession(name: "Compassionate Presence", duration: 12, instructor: "Luna Martinez", description: "Meet difficult feelings with kindness.", category: .anxiety),
                MeditationSession(name: "Release & Restore", duration: 10, instructor: "James Park", description: "Let go of what you can't control.", category: .anxiety),
            ],
            duration: 40,
            instructor: "Luna Martinez",
            level: .intermediate,
            imageName: "heart.fill"
        ),

        // Advanced
        MeditationCourse(
            id: UUID(),
            name: "Deep Self",
            description: "An immersive journey into non-dual awareness and the nature of consciousness itself.",
            sessions: [
                MeditationSession(name: "Beyond the Mind", duration: 15, instructor: "James Park", description: "Notice the awareness behind thoughts.", category: .focus),
                MeditationSession(name: "Open Space", duration: 20, instructor: "James Park", description: "Rest in bare, spacious presence.", category: .focus),
                MeditationSession(name: "No-Self", duration: 20, instructor: "James Park", description: "Investigate the sense of a separate self.", category: .focus),
                MeditationSession(name: "Pure Awareness", duration: 25, instructor: "James Park", description: "Rest as consciousness itself.", category: .focus),
            ],
            duration: 80,
            instructor: "James Park",
            level: .advanced,
            imageName: "brain.head.profile"
        ),
    ]
}

// MARK: - CourseService

final class CourseService: @unchecked Sendable {
    static let shared = CourseService()

    private let userDefaults = UserDefaults.standard
    private let enrollmentsKey = "CourseService.enrollments"

    private init() {}

    // MARK: - Course Access

    func getCourses() -> [MeditationCourse] {
        CourseLibrary.courses
    }

    func getCourses(for level: CourseLevel) -> [MeditationCourse] {
        CourseLibrary.courses.filter { $0.level == level }
    }

    func getCourses(byInstructor instructor: String) -> [MeditationCourse] {
        CourseLibrary.courses.filter { $0.instructor == instructor }
    }

    func getCourse(byId id: UUID) -> MeditationCourse? {
        CourseLibrary.courses.first { $0.id == id }
    }

    // MARK: - Enrollment

    func enrollInCourse(_ course: MeditationCourse) -> Enrollment {
        var enrollments = loadEnrollments()

        // Check if already enrolled
        if let existing = enrollments.first(where: { $0.course.id == course.id }) {
            return existing
        }

        let enrollment = Enrollment(
            id: UUID(),
            course: course,
            enrolledAt: Date(),
            completedSessions: 0,
            lastAccessedAt: nil,
            isCompleted: false
        )

        enrollments.append(enrollment)
        saveEnrollments(enrollments)

        NotificationCenter.default.post(name: .courseEnrollmentChanged, object: nil)

        return enrollment
    }

    func unenroll(from course: MeditationCourse) {
        var enrollments = loadEnrollments()
        enrollments.removeAll { $0.course.id == course.id }
        saveEnrollments(enrollments)

        NotificationCenter.default.post(name: .courseEnrollmentChanged, object: nil)
    }

    func isEnrolled(in course: MeditationCourse) -> Bool {
        loadEnrollments().contains { $0.course.id == course.id }
    }

    func getEnrollments() -> [Enrollment] {
        loadEnrollments()
    }

    func getActiveEnrollments() -> [Enrollment] {
        loadEnrollments().filter { !$0.isCompleted }
    }

    // MARK: - Progress

    func updateProgress(for courseId: UUID, completedSessions: Int, isCompleted: Bool) {
        var enrollments = loadEnrollments()

        guard let index = enrollments.firstIndex(where: { $0.course.id == courseId }) else { return }

        enrollments[index].completedSessions = completedSessions
        enrollments[index].isCompleted = isCompleted
        enrollments[index].lastAccessedAt = Date()

        saveEnrollments(enrollments)
        NotificationCenter.default.post(name: .courseProgressUpdated, object: courseId)
    }

    func markSessionCompleted(courseId: UUID, sessionId: UUID) {
        var enrollments = loadEnrollments()

        guard let index = enrollments.firstIndex(where: { $0.course.id == courseId }) else { return }

        enrollments[index].completedSessions += 1
        enrollments[index].lastAccessedAt = Date()

        let course = enrollments[index].course
        if enrollments[index].completedSessions >= course.totalSessions {
            enrollments[index].isCompleted = true
        }

        saveEnrollments(enrollments)
        NotificationCenter.default.post(name: .courseProgressUpdated, object: courseId)
    }

    // MARK: - Persistence

    private struct StoredEnrollment: Codable {
        let id: UUID
        let courseId: UUID
        let enrolledAt: Date
        var completedSessions: Int
        var lastAccessedAt: Date?
        var isCompleted: Bool
    }

    private func loadEnrollments() -> [Enrollment] {
        guard let data = userDefaults.data(forKey: enrollmentsKey),
              let stored = try? JSONDecoder().decode([StoredEnrollment].self, from: data) else {
            return []
        }

        return stored.compactMap { stored -> Enrollment? in
            guard let course = getCourse(byId: stored.courseId) else { return nil }

            return Enrollment(
                id: stored.id,
                course: course,
                enrolledAt: stored.enrolledAt,
                completedSessions: stored.completedSessions,
                lastAccessedAt: stored.lastAccessedAt,
                isCompleted: stored.isCompleted
            )
        }
    }

    private func saveEnrollments(_ enrollments: [Enrollment]) {
        let stored = enrollments.map { enrollment in
            StoredEnrollment(
                id: enrollment.id,
                courseId: enrollment.course.id,
                enrolledAt: enrollment.enrolledAt,
                completedSessions: enrollment.completedSessions,
                lastAccessedAt: enrollment.lastAccessedAt,
                isCompleted: enrollment.isCompleted
            )
        }

        if let data = try? JSONEncoder().encode(stored) {
            userDefaults.set(data, forKey: enrollmentsKey)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let courseEnrollmentChanged = Notification.Name("courseEnrollmentChanged")
    static let courseProgressUpdated = Notification.Name("courseProgressUpdated")
}
