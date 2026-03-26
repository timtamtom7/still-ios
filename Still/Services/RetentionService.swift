import Foundation
import SwiftUI

/// R13: Retention tracking for Still
/// Day 1: first session
/// Day 3: first biometric feedback
/// Day 7: first program
@MainActor
final class RetentionService: ObservableObject {
    static let shared = RetentionService()

    private let installDateKey = "still_install_date"
    private let day1SessionKey = "day1_session_completed"
    private let day3BiometricKey = "day3_biometric_completed"
    private let day7ProgramKey = "day7_program_completed"
    private let lastActiveKey = "still_last_active"

    @Published var daysSinceInstall: Int = 0
    @Published var day1Completed: Bool = false
    @Published var day3Completed: Bool = false
    @Published var day7Completed: Bool = false

    var currentMilestone: RetentionMilestone {
        if day7Completed { return .completed }
        else if day3Completed { return .day7 }
        else if day1Completed { return .day3 }
        else { return .day1 }
    }

    enum RetentionMilestone: String {
        case day1 = "Complete your first breathing session"
        case day3 = "Get your first biometric feedback"
        case day7 = "Complete your first program"
        case completed = "Stillness achieved!"
    }

    init() {
        loadRetentionData()
    }

    func loadRetentionData() {
        if let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        } else {
            UserDefaults.standard.set(Date(), forKey: installDateKey)
            daysSinceInstall = 0
        }

        day1Completed = UserDefaults.standard.bool(forKey: day1SessionKey)
        day3Completed = UserDefaults.standard.bool(forKey: day3BiometricKey)
        day7Completed = UserDefaults.standard.bool(forKey: day7ProgramKey)
        UserDefaults.standard.set(Date(), forKey: lastActiveKey)
    }

    func recordSessionCompleted() {
        guard !day1Completed else { return }
        day1Completed = true
        UserDefaults.standard.set(true, forKey: day1SessionKey)
        trackMilestone(.day1)
    }

    func recordBiometricFeedback() {
        guard !day3Completed else { return }
        day3Completed = true
        UserDefaults.standard.set(true, forKey: day3BiometricKey)
        trackMilestone(.day3)
    }

    func recordProgramCompleted() {
        guard !day7Completed else { return }
        day7Completed = true
        UserDefaults.standard.set(true, forKey: day7ProgramKey)
        trackMilestone(.day7)
    }

    private func trackMilestone(_ milestone: RetentionMilestone) {
        print("[Retention] Milestone completed: \(milestone.rawValue)")
    }
}
