import Foundation

struct Reflection: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let question: String
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), date: Date = Date(), question: String, text: String, createdAt: Date = Date()) {
        self.id = id
        self.date = date
        self.question = question
        self.text = text
        self.createdAt = createdAt
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: date)
    }

    var previewText: String {
        let lines = text.components(separatedBy: .newlines)
        let firstLine = lines.first ?? text
        if firstLine.count > 60 {
            return String(firstLine.prefix(60)) + "…"
        }
        return firstLine
    }
}
