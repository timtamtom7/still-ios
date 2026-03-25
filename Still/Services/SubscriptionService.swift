import Foundation

/// Subscription tier and limits management
@MainActor
final class SubscriptionService {
    static let shared = SubscriptionService()

    private init() {}

    // MARK: - Subscription Tiers

    enum SubscriptionTier: String, Codable {
        case free
        case pro

        var displayName: String {
            switch self {
            case .free: return "Free"
            case .pro: return "Pro"
            }
        }

        var weeklyLimit: Int? {
            switch self {
            case .free: return 3
            case .pro: return nil // Unlimited
            }
        }

        var canExportLegacy: Bool {
            switch self {
            case .free: return false
            case .pro: return true
            }
        }

        var canGiftReflections: Bool {
            switch self {
            case .free: return false
            case .pro: return true
            }
        }

        var canUseMemorialMode: Bool {
            switch self {
            case .free: return false
            case .pro: return true
            }
        }

        var description: String {
            switch self {
            case .free: return "3 reflections per week"
            case .pro: return "Unlimited reflections"
            }
        }
    }

    // MARK: - State

    var currentTier: SubscriptionTier {
        get {
            if UserDefaults.standard.string(forKey: "subscriptionTier") == "pro" {
                return .pro
            }
            return .free
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "subscriptionTier")
        }
    }

    var isPro: Bool {
        currentTier == .pro
    }

    var proExpiresAt: Date? {
        get {
            guard let timestamp = UserDefaults.standard.object(forKey: "proExpiresAt") as? TimeInterval else {
                return nil
            }
            return Date(timeIntervalSince1970: timestamp)
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "proExpiresAt")
            } else {
                UserDefaults.standard.removeObject(forKey: "proExpiresAt")
            }
        }
    }

    var proPurchaseDate: Date? {
        get {
            guard let timestamp = UserDefaults.standard.object(forKey: "proPurchaseDate") as? TimeInterval else {
                return nil
            }
            return Date(timeIntervalSince1970: timestamp)
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "proPurchaseDate")
            } else {
                UserDefaults.standard.removeObject(forKey: "proPurchaseDate")
            }
        }
    }

    var isProActive: Bool {
        if currentTier == .free { return false }
        if let expires = proExpiresAt, expires < Date() { return false }
        return true
    }

    // MARK: - Weekly Limit Enforcement

    private var weeklyReflectionCountKey: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.year, from: Date())
        return "weeklyReflectionCount_\(year)_\(weekOfYear)"
    }

    var reflectionsThisWeek: Int {
        UserDefaults.standard.integer(forKey: weeklyReflectionCountKey)
    }

    func incrementWeeklyCount() {
        let newCount = reflectionsThisWeek + 1
        UserDefaults.standard.set(newCount, forKey: weeklyReflectionCountKey)
    }

    var weeklyLimitReached: Bool {
        guard !isProActive else { return false }
        guard let limit = currentTier.weeklyLimit else { return false }
        return reflectionsThisWeek >= limit
    }

    var remainingReflectionsThisWeek: Int {
        guard let limit = currentTier.weeklyLimit else { return Int.max }
        return max(0, limit - reflectionsThisWeek)
    }

    var daysUntilWeekReset: Int {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // Sunday is weekday 1. We reset on Monday (weekday 2), so:
        // Sunday (1) -> 1 day until reset
        // Monday (2) -> 7 days until reset
        // ...
        // Saturday (7) -> 2 days until reset
        if weekday == 1 { return 1 }
        return 8 - weekday
    }

    // MARK: - Subscription Actions

    func activatePro(subscriptionId: String? = nil, expiresAt: Date? = nil) {
        currentTier = .pro
        proPurchaseDate = Date()
        proExpiresAt = expiresAt ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())
        UserDefaults.standard.set(subscriptionId, forKey: "proSubscriptionId")
    }

    func restorePurchases() async -> Bool {
        // In a real implementation, this would check with the App Store
        // For now, simulate a restore check
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Check if we have any stored purchase info
        return UserDefaults.standard.string(forKey: "proSubscriptionId") != nil
    }

    func cancelSubscription() {
        currentTier = .free
        proExpiresAt = nil
        UserDefaults.standard.removeObject(forKey: "proSubscriptionId")
    }

    // MARK: - Feature Access

    func canAccessFeature(_ feature: Feature) -> Bool {
        switch feature {
        case .unlimitedReflections:
            return isProActive
        case .legacyExport:
            return isProActive
        case .giftReflections:
            return isProActive
        case .memorialMode:
            return isProActive
        case .extendedArchive:
            return isProActive
        case .customSounds:
            return isProActive
        }
    }

    enum Feature: String {
        case unlimitedReflections
        case legacyExport
        case giftReflections
        case memorialMode
        case extendedArchive
        case customSounds
    }
}

// MARK: - App Store Product IDs

extension SubscriptionService {
    struct AppStoreProduct {
        static let proYearly = "com.still.app.pro.yearly"
        static let proMonthly = "com.still.app.pro.monthly"
    }
}
