import Foundation

enum AmbientSound: String, Codable, CaseIterable, Identifiable {
    case silence = "Silence"
    case rain = "Rain"
    case fireplace = "Fireplace"
    case brownNoise = "Brown Noise"
    case ocean = "Ocean"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .silence: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .fireplace: return "flame"
        case .brownNoise: return "waveform"
        case .ocean: return "water.waves"
        }
    }
}

enum QuestionCategory: String, Codable, CaseIterable {
    case exhaustion = "exhaustion"
    case surprise = "surprise"
    case honesty = "honesty"
    case avoidance = "avoidance"
    case gratitude = "gratitude"
    case selfDiscovery = "self-discovery"
    case connection = "connection"
    case lettingGo = "letting-go"
    case meaning = "meaning"
    case other = "other"

    var displayName: String {
        switch self {
        case .exhaustion: return "What exhausted you?"
        case .surprise: return "What surprised you?"
        case .honesty: return "What did you almost say?"
        case .avoidance: return "What are you avoiding?"
        case .gratitude: return "What are you grateful for?"
        case .selfDiscovery: return "What did you learn about yourself?"
        case .connection: return "What connection mattered?"
        case .lettingGo: return "What do you need to let go of?"
        case .meaning: return "What gave your day meaning?"
        case .other: return "Other"
        }
    }
}

struct Reflection: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let question: String
    let text: String
    let createdAt: Date
    var questionRating: Int?
    var soundUsed: AmbientSound?
    var questionCategory: QuestionCategory?

    init(id: UUID = UUID(), date: Date = Date(), question: String, text: String, createdAt: Date = Date(), questionRating: Int? = nil, soundUsed: AmbientSound? = nil, questionCategory: QuestionCategory? = nil) {
        self.id = id
        self.date = date
        self.question = question
        self.text = text
        self.createdAt = createdAt
        self.questionRating = questionRating
        self.soundUsed = soundUsed
        self.questionCategory = questionCategory
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
