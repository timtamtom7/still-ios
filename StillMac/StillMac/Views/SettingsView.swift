import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = true
    @AppStorage("reminderTime") private var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @AppStorage("ambientSounds") private var ambientSounds: Bool = true
    @AppStorage("completionHaptics") private var completionHaptics: Bool = true
    @AppStorage("backgroundBlur") private var backgroundBlur: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Notifications section
                SettingsSection(title: "Reminders") {
                    SettingsToggle(
                        title: "Daily Reminder",
                        subtitle: "Get a gentle nudge to meditate",
                        icon: "bell",
                        isOn: $reminderEnabled
                    )

                    if reminderEnabled {
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.calmBlue)
                                .frame(width: 24)

                            Text("Reminder Time")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.deepNavy)

                            Spacer()

                            DatePicker(
                                "",
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .colorScheme(.light)
                        }
                        .padding(12)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Sound section
                SettingsSection(title: "Sound") {
                    SettingsToggle(
                        title: "Ambient Sounds",
                        subtitle: "Background audio during sessions",
                        icon: "waveform",
                        isOn: $ambientSounds
                    )
                }

                // Haptics section
                SettingsSection(title: "Feedback") {
                    SettingsToggle(
                        title: "Completion Haptics",
                        subtitle: "Vibrate when session completes",
                        icon: "hand.tap",
                        isOn: $completionHaptics
                    )
                }

                // Display section
                SettingsSection(title: "Display") {
                    SettingsToggle(
                        title: "Background Blur",
                        subtitle: "Add blur behind player controls",
                        icon: "rectangle.on.rectangle",
                        isOn: $backgroundBlur
                    )
                }

                // About section
                SettingsSection(title: "About") {
                    HStack {
                        Text("Version")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.deepNavy)

                        Spacer()

                        Text("1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.deepNavy.opacity(0.5))
                    }
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
        }
        .background(Theme.surface)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.deepNavy.opacity(0.5))
                .textCase(.uppercase)

            VStack(spacing: 2) {
                content
            }
            .padding(12)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.calmBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.deepNavy)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.deepNavy.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.calmBlue)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
