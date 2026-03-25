import SwiftUI

struct ReflectionInput: View {
    @Binding var text: String
    let placeholder: String
    let characterLimit: Int

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $text)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .frame(minHeight: 120)
                    .accessibilityLabel("Reflection text")
                    .accessibilityHint("Write your reflection here. \(characterLimit) characters maximum.")
                    .onChange(of: text) { _, newValue in
                        if newValue.count > characterLimit {
                            text = String(newValue.prefix(characterLimit))
                        }
                    }
            }

            HStack {
                if text.count > characterLimit - 100 {
                    Text("\(text.count)/\(characterLimit)")
                        .font(AppTypography.caption)
                        .foregroundColor(text.count >= characterLimit ? AppColors.amber : AppColors.textSecondary)
                }
                Spacer()
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}
