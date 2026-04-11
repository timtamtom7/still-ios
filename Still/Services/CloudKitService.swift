import Foundation
import CloudKit

@MainActor
final class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    private let privateDatabase: CKDatabase?
    private(set) var isEnabled: Bool = false

    init() {
        do {
            let container = try CKContainer(identifier: "iCloud.com.still.app")
            privateDatabase = container.privateCloudDatabase
            isEnabled = true
        } catch {
            print("CloudKit container not available: \(error)")
            privateDatabase = nil
            isEnabled = false
        }
    }

    /// Checks if the user is signed into iCloud
    func checkAccountStatus() async -> Bool {
        guard privateDatabase != nil, isEnabled else { return false }
        do {
            let status = try await CKContainer(identifier: "iCloud.com.still.app").accountStatus()
            return status == .available
        } catch {
            print("CloudKit account status check failed: \(error)")
            return false
        }
    }

    func saveReflection(_ reflection: Reflection) async -> Bool {
        guard let db = privateDatabase, isEnabled else { return false }

        let record = CKRecord(recordType: "Reflection")
        record["id"] = reflection.id.uuidString
        record["date"] = reflection.date
        record["question"] = reflection.question
        record["text"] = reflection.text
        record["createdAt"] = reflection.createdAt
        if let rating = reflection.questionRating {
            record["questionRating"] = rating
        }
        if let sound = reflection.soundUsed {
            record["soundUsed"] = sound.rawValue
        }

        do {
            _ = try await db.save(record)
            return true
        } catch {
            print("CloudKit save failed: \(error)")
            return false
        }
    }

    func fetchAllReflections() async -> [CKRecord] {
        guard let db = privateDatabase, isEnabled else { return [] }

        let query = CKQuery(recordType: "Reflection", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let (results, _) = try await db.records(matching: query)
            return results.compactMap { try? $0.1.get() }
        } catch {
            print("CloudKit fetch failed: \(error)")
            return []
        }
    }

    func deleteReflection(_ reflection: Reflection) async -> Bool {
        guard let db = privateDatabase, isEnabled else { return false }

        let recordID = CKRecord.ID(recordName: reflection.id.uuidString)
        do {
            try await db.deleteRecord(withID: recordID)
            return true
        } catch {
            print("CloudKit delete failed: \(error)")
            return false
        }
    }
}
