import SwiftUI

// MARK: - Theme — iOS 26 Liquid Glass Design Tokens

enum Theme {
    // MARK: - Corner Radius

    /// 8pt — small elements: tags, chips, tiny containers
    static let cornerRadiusTiny: CGFloat = 8

    /// 12pt — compact elements: search bar, nudge banner, inner containers
    static let cornerRadiusSmall: CGFloat = 12

    /// 16pt — cards, sheets, modal content (HIG-recommended for cards: 16-20pt)
    static let cornerRadiusCard: CGFloat = 16

    /// 24pt — primary buttons, pill shapes
    static let cornerRadiusButton: CGFloat = 24

    // MARK: - Spacing (8pt Grid)

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing48: CGFloat = 48

    // MARK: - Screen Margins

    /// 16pt — iPhone horizontal margin
    static let screenMarginHorizontal: CGFloat = 16

    /// 32pt — iPhone horizontal margin (large screens / generous spacing)
    static let screenMarginHorizontalLarge: CGFloat = 32

    // MARK: - Touch Targets

    /// 44pt — minimum touch target per HIG
    static let minTouchTarget: CGFloat = 44

    // MARK: - Shadows

    static let shadowRadiusSmall: CGFloat = 4
    static let shadowRadiusMedium: CGFloat = 8
    static let shadowRadiusLarge: CGFloat = 12

    static let shadowYSmall: CGFloat = 2
    static let shadowYMedium: CGFloat = 4
}

// MARK: - Liquid Glass Surface Modifier

/// Liquid Glass material for iOS 26 — translucent surface with subtle blur.
/// Falls back to solid surface color when blur is unavailable.
struct LiquidGlassSurface: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    AppColors.surface.opacity(0.72)
                    Color.clear
                        .background(.ultraThinMaterial)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusCard)
                    .stroke(
                        AppColors.separator.opacity(0.5),
                        lineWidth: 0.5
                    )
            )
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = Theme.cornerRadiusCard
    var showBorder: Bool = false

    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        showBorder ? AppColors.amber.opacity(0.2) : AppColors.separator.opacity(0.3),
                        lineWidth: showBorder ? 1 : 0.5
                    )
            )
    }
}

// MARK: - Glass Card Style Modifier (iOS 26 Liquid Glass)

struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(LiquidGlassSurface())
    }
}

// MARK: - View Extensions

extension View {
    /// Apply card style with Theme corner radius tokens
    func cardStyle(cornerRadius: CGFloat = Theme.cornerRadiusCard, showBorder: Bool = false) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, showBorder: showBorder))
    }

    /// Apply Liquid Glass surface (iOS 26)
    func liquidGlass() -> some View {
        modifier(LiquidGlassSurface())
    }

    /// Apply glass card style (iOS 26 Liquid Glass)
    func glassCard() -> some View {
        modifier(GlassCardStyle())
    }
}
