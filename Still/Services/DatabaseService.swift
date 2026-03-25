import Foundation
import SQLite

final class DatabaseService {
    static nonisolated(unsafe) let shared = DatabaseService()

    private var db: Connection?

    private let reflections = Table("reflections")
    private let id = Expression<String>("id")
    private let dateTimestamp = Expression<Double>("date")
    private let question = Expression<String>("question")
    private let text = Expression<String>("text")
    private let createdAtTimestamp = Expression<Double>("created_at")

    private let questions = Table("questions")
    private let questionId = Expression<String>("id")
    private let questionText = Expression<String>("text")
    private let lastAskedTimestamp = Expression<Double?>("last_asked")

    private let settings = Table("settings")
    private let settingKey = Expression<String>("key")
    private let settingValue = Expression<String>("value")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("still.sqlite3").path
            db = try Connection(path)
            try createTables()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(reflections.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(dateTimestamp)
            t.column(question)
            t.column(text)
            t.column(createdAtTimestamp)
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
        let insert = reflections.insert(
            id <- reflection.id.uuidString,
            dateTimestamp <- reflection.date.timeIntervalSince1970,
            question <- reflection.question,
            text <- reflection.text,
            createdAtTimestamp <- reflection.createdAt.timeIntervalSince1970
        )
        try db?.run(insert)
    }

    private func rowToReflection(_ row: Row) -> Reflection? {
        guard let uuid = UUID(uuidString: row[id]) else { return nil }
        return Reflection(
            id: uuid,
            date: Date(timeIntervalSince1970: row[dateTimestamp]),
            question: row[question],
            text: row[text],
            createdAt: Date(timeIntervalSince1970: row[createdAtTimestamp])
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
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
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
