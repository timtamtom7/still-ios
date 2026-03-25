import SwiftUI
import Combine

struct TypewriterText: View {
    let text: String
    let font: Font
    let color: Color
    let speed: Double // characters per second

    @State private var displayedText: String = ""
    @State private var charIndex: Int = 0
    @State private var timer: AnyCancellable?

    var body: some View {
        Text(displayedText)
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .onAppear {
                startTyping()
            }
            .onDisappear {
                timer?.cancel()
            }
    }

    private func startTyping() {
        guard !text.isEmpty else {
            displayedText = ""
            return
        }
        let interval = 1.0 / speed
        var count = 0

        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if count < text.count {
                    let index = text.index(text.startIndex, offsetBy: count + 1)
                    displayedText = String(text[..<index])
                    count += 1
                } else {
                    timer?.cancel()
                }
            }
    }
}
