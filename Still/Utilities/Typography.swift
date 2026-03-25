import SwiftUI

enum AppTypography {
    // New York is an Apple serif font available on iOS 17+/macOS 14+
    // Use design: .serif as the reliable cross-platform fallback
    static let display = Font.system(size: 24, weight: .medium, design: .serif)
        .width(.standard)

    static let displaySmall = Font.system(size: 22, weight: .medium, design: .serif)
        .width(.standard)

    static let body = Font.system(size: 18, weight: .regular, design: .serif)
        .width(.standard)

    static let bodySmall = Font.system(size: 15, weight: .regular, design: .serif)
        .width(.standard)

    static let caption = Font.system(size: 13, weight: .regular, design: .default)

    static let button = Font.system(size: 15, weight: .medium, design: .default)
}
