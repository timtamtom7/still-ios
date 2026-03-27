import SwiftUI

struct SubmitButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.button)
                .foregroundColor(AppColors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusButton)
                        .fill(isEnabled ? AppColors.amberDeep : AppColors.amberDeep.opacity(0.3))
                )
                .shadow(
                    color: isEnabled ? AppColors.amber.opacity(0.3) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "Submits your reflection." : "Write something first to submit.")
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
