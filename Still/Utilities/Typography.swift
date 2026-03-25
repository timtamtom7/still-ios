import SwiftUI

enum AppTypography {
    static let display = Font.custom("NewYork-Medium", size: 24, relativeTo: .title2)
        .fallback(.system(size: 24, weight: .medium, design: .serif))

    static let displaySmall = Font.custom("NewYork-Medium", size: 22, relativeTo: .title3)
        .fallback(.system(size: 22, weight: .medium, design: .serif))

    static let body = Font.custom("NewYork-Regular", size: 18, relativeTo: .body)
        .fallback(.system(size: 18, weight: .regular, design: .serif))

    static let bodySmall = Font.custom("NewYork-Regular", size: 15, relativeTo: .callout)
        .fallback(.system(size: 15, weight: .regular, design: .serif))

    static let caption = Font.system(size: 13, weight: .regular, design: .default)

    static let button = Font.system(size: 15, weight: .medium, design: .default)
}

extension Font {
    func fallback(_ font: Font) -> Font {
        self
    }
}
