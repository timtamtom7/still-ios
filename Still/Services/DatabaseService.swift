import Foundation
import SQLite

@MainActor
final class DatabaseService {
    static let shared = DatabaseService()

    private let db: Connection?

    private let reflections = Table("reflections")
    private let id = Expression<String>("id")
    private let dateTimestamp = Expression<Double>("date")
    private let question = Expression<String>("question")
    private let text = Expression<String>("text")
    private let createdAtTimestamp = Expression<Double>("created_at")
    private let questionRating = Expression<Int?>("question_rating")
    private let soundUsed = Expression<String?>("sound_used")
    private let questionCategory = Expression<String?>("question_category")

    private let questions = Table("questions")
    private let questionId = Expression<String>("id")
    private let questionText = Expression<String>("text")
    private let lastAskedTimestamp = Expression<Double?>("last_asked")

    private let settings = Table("settings")
    private let settingKey = Expression<String>("key")
    private let settingValue = Expression<String>("value")

    private init() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("still.sqlite3").path
        db = try? Connection(path)
        try? createTables()
    }

    private func createTables() throws {
        try db?.run(reflections.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(dateTimestamp)
            t.column(question)
            t.column(text)
            t.column(createdAtTimestamp)
            t.column(questionRating)
            t.column(soundUsed)
            t.column(questionCategory)
        })

        try db?.run(questions.create(ifNotExists: true) { t in
            t.column(questionId, primaryKey: true)
            t.column(questionText)
            t.column(lastAskedTimestamp)
        })

        try db?.run(settings.create(ifNotExists: true) { t in
            t.column(settingKey, primaryKey: true)
            t.column(settingValue)
        })
    }

    // MARK: - Reflections

    func saveReflection(_ reflection: Reflection) throws {
        guard let db = db else {
            let nsError = NSError(domain: "DatabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"])
            throw nsError
        }
        let soundStr = reflection.soundUsed?.rawValue
        let catStr = reflection.questionCategory?.rawValue
        let insert = reflections.insert(
            id <- reflection.id.uuidString,
            dateTimestamp <- reflection.date.timeIntervalSince1970,
            question <- reflection.question,
            text <- reflection.text,
            createdAtTimestamp <- reflection.createdAt.timeIntervalSince1970,
            questionRating <- reflection.questionRating,
            soundUsed <- soundStr,
            questionCategory <- catStr
        )
        try db.run(insert)
    }

    func updateReflection(_ reflection: Reflection) throws {
        guard let db = db else {
            let nsError = NSError(domain: "DatabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not available"])
            throw nsError
        }
        let record = reflections.filter(id == reflection.id.uuidString)
        let soundStr = reflection.soundUsed?.rawValue
        let catStr = reflection.questionCategory?.rawValue
        try db.run(record.update(
            questionRating <- reflection.questionRating,
            soundUsed <- soundStr,
            questionCategory <- catStr
        ))
    }

    private func rowToReflection(_ row: Row) -> Reflection? {
        guard let uuid = UUID(uuidString: row[id]) else { return nil }
        let sound: AmbientSound? = row[soundUsed].flatMap { AmbientSound(rawValue: $0) }
        let cat: QuestionCategory? = row[questionCategory].flatMap { QuestionCategory(rawValue: $0) }
        return Reflection(
            id: uuid,
            date: Date(timeIntervalSince1970: row[dateTimestamp]),
            question: row[question],
            text: row[text],
            createdAt: Date(timeIntervalSince1970: row[createdAtTimestamp]),
            questionRating: row[questionRating],
            soundUsed: sound,
            questionCategory: cat
        )
    }

    func getAllReflections() -> [Reflection] {
        guard let db = db else { return [] }
        var result: [Reflection] = []
        do {
            for row in try db.prepare(reflections.order(dateTimestamp.desc)) {
                if let reflection = rowToReflection(row) {
                    result.append(reflection)
                }
            }
        } catch {
            print("Failed to fetch reflections: \(error)")
        }
        return result
    }

    func getReflections(for targetDate: Date) -> [Reflection] {
        guard let db = db else { return [] }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        let startTs = startOfDay.timeIntervalSince1970
        let endTs = endOfDay.timeIntervalSince1970

        var result: [Reflection] = []
        do {
            let query = reflections.filter(dateTimestamp >= startTs && dateTimestamp < endTs)
            for row in try db.prepare(query) {
                if let reflection = rowToReflection(row) {
                    result.append(reflection)
                }
            }
        } catch {
            print("Failed to fetch reflections for date: \(error)")
        }
        return result
    }

    func hasReflection(for targetDate: Date) -> Bool {
        return !getReflections(for: targetDate).isEmpty
    }

    func searchReflections(query searchQuery: String) -> [Reflection] {
        guard let db = db, !searchQuery.isEmpty else { return getAllReflections() }
        var result: [Reflection] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = reflections.filter(question.like(pattern) || text.like(pattern)).order(dateTimestamp.desc)
            for row in try db.prepare(query) {
                if let reflection = rowToReflection(row) {
                    result.append(reflection)
                }
            }
        } catch {
            print("Search failed: \(error)")
        }
        return result
    }

    func getReflections(from startDate: Date, to endDate: Date) -> [Reflection] {
        guard let db = db else { return [] }
        let startTs = startDate.timeIntervalSince1970
        let endTs = endDate.timeIntervalSince1970

        var result: [Reflection] = []
        do {
            let query = reflections.filter(dateTimestamp >= startTs && dateTimestamp <= endTs).order(dateTimestamp.desc)
            for row in try db.prepare(query) {
                if let reflection = rowToReflection(row) {
                    result.append(reflection)
                }
            }
        } catch {
            print("Failed to fetch range: \(error)")
        }
        return result
    }

    // MARK: - Memory Lane

    func getReflectionOneYearAgo() -> Reflection? {
        guard let db = db else { return nil }
        let calendar = Calendar.current
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) else { return nil }
        let startOfDay = calendar.startOfDay(for: oneYearAgo)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        let startTs = startOfDay.timeIntervalSince1970
        let endTs = endOfDay.timeIntervalSince1970

        do {
            let query = reflections.filter(dateTimestamp >= startTs && dateTimestamp < endTs)
            for row in try db.prepare(query) {
                if let reflection = rowToReflection(row) {
                    return reflection
                }
            }
        } catch {
            print("Failed to fetch one-year-ago reflection: \(error)")
        }
        return nil
    }

    func getReflectionOneMonthAgo() -> Reflection? {
        guard let db = db else { return nil }
        let calendar = Calendar.current
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) else { return nil }
        let startOfDay = calendar.startOfDay(for: oneMonthAgo)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        let startTs = startOfDay.timeIntervalSince1970
        let endTs = endOfDay.timeIntervalSince1970

        do {
            let query = reflections.filter(dateTimestamp >= startTs && dateTimestamp < endTs)
            for row in try db.prepare(query) {
                if let reflection = rowToReflection(row) {
                    return reflection
                }
            }
        } catch {
            print("Failed to fetch one-month-ago reflection: \(error)")
        }
        return nil
    }

    func getReflectionsOnThisDay() -> [Reflection] {
        guard let db = db else { return [] }
        let calendar = Calendar.current
        let today = Date()
        let day = calendar.component(.day, from: today)
        let month = calendar.component(.month, from: today)

        var result: [Reflection] = []
        do {
            for row in try db.prepare(reflections.order(dateTimestamp.desc)) {
                if let reflection = rowToReflection(row) {
                    let refDay = calendar.component(.day, from: reflection.date)
                    let refMonth = calendar.component(.month, from: reflection.date)
                    let refYear = calendar.component(.year, from: reflection.date)
                    let thisYear = calendar.component(.year, from: today)
                    if refDay == day && refMonth == month && refYear != thisYear {
                        result.append(reflection)
                    }
                }
            }
        } catch {
            print("Failed to fetch this-day reflections: \(error)")
        }
        return result
    }

    // MARK: - Week Comparison

    func getReflectionCountThisWeek() -> Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { return 0 }
        return getReflections(from: startOfWeek, to: endOfWeek).count
    }

    func getReflectionCountLastWeek() -> Int {
        let calendar = Calendar.current
        guard let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek),
              let endOfLastWeek = calendar.date(byAdding: .day, value: 7, to: startOfLastWeek) else { return 0 }
        return getReflections(from: startOfLastWeek, to: endOfLastWeek).count
    }

    // MARK: - Settings

    func getSetting(_ key: String) -> String? {
        guard let db = db else { return nil }
        do {
            let query = settings.filter(settingKey == key)
            if let row = try db.pluck(query) {
                return row[settingValue]
            }
        } catch {
            print("Failed to get setting: \(error)")
        }
        return nil
    }

    func setSetting(_ key: String, value: String) {
        guard let db = db else { return }
        do {
            try db.run(settings.insert(or: .replace, settingKey <- key, settingValue <- value))
        } catch {
            print("Failed to set setting: \(error)")
        }
    }
}
