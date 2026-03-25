import SwiftUI

enum AppColors {
    static let background = Color(hex: "0D0B09")
    static let surface = Color(hex: "1A1714")
    static let amber = Color(hex: "E8A46A")
    static let amberGlow = Color(hex: "F4C594")
    static let amberDeep = Color(hex: "C47D3E")
    static let textPrimary = Color(hex: "F5F0E8")
    static let textSecondary = Color(hex: "9B9385")
    static let separator = Color(hex: "2A2520")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
