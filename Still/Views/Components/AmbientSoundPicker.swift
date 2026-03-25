import SwiftUI

struct AmbientSoundPicker: View {
    @ObservedObject var soundManager = SoundManager.shared
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                showPicker.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: soundManager.currentSound.icon)
                        .font(.system(size: 14))
                    Text(soundManager.currentSound.rawValue)
                        .font(AppTypography.caption)
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.surface)
                .cornerRadius(16)
            }

            if showPicker {
                VStack(spacing: 4) {
                    ForEach(AmbientSound.allCases) { sound in
                        Button {
                            soundManager.selectSound(sound)
                            if sound != .silence {
                                soundManager.play()
                            } else {
                                soundManager.stop()
                            }
                            showPicker = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: sound.icon)
                                    .font(.system(size: 14))
                                    .frame(width: 20)
                                Text(sound.rawValue)
                                    .font(AppTypography.caption)
                                Spacer()
                                if soundManager.currentSound == sound {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColors.amber)
                                }
                            }
                            .foregroundColor(soundManager.currentSound == sound ? AppColors.textPrimary : AppColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(AppColors.surface)
                    }
                }
                .cornerRadius(12)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPicker)
    }
}
