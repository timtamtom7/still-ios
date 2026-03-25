import Foundation

struct Question: Identifiable, Equatable {
    let id: UUID
    let text: String
    var lastAsked: Date?

    init(id: UUID = UUID(), text: String, lastAsked: Date? = nil) {
        self.id = id
        self.text = text
        self.lastAsked = lastAsked
    }
}
