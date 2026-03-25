import CloudKit
import Foundation

final class CloudKitService {
    static nonisolated(unsafe) let shared = CloudKitService()

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let recordType = "Reflection"

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cloudKitEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cloudKitEnabled") }
    }

    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }

    func checkAccountStatus(completion: @escaping (Bool) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                let available = status == .available
                if !available {
                    print("CloudKit account unavailable: \(status.rawValue)")
                }
                completion(available)
            }
        }
    }

    func saveReflection(_ reflection: Reflection, completion: @escaping (Bool) -> Void) {
        guard isEnabled else {
            completion(false)
            return
        }

        let record = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: reflection.id.uuidString))
        record["date"] = reflection.date as CKRecordValue
        record["question"] = reflection.question as CKRecordValue
        record["text"] = reflection.text as CKRecordValue
        record["createdAt"] = reflection.createdAt as CKRecordValue

        privateDatabase.save(record) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKit save failed: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    func fetchAllReflections(completion: @escaping ([Reflection]) -> Void) {
        guard isEnabled else {
            completion([])
            return
        }

        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKit fetch failed: \(error)")
                    completion([])
                    return
                }

                let reflections = (records ?? []).compactMap { record -> Reflection? in
                    guard let uuid = UUID(uuidString: record.recordID.recordName),
                          let date = record["date"] as? Date,
                          let question = record["question"] as? String,
                          let text = record["text"] as? String,
                          let createdAt = record["createdAt"] as? Date else {
                        return nil
                    }
                    return Reflection(id: uuid, date: date, question: question, text: text, createdAt: createdAt)
                }
                completion(reflections)
            }
        }
    }

    func deleteReflection(id: UUID, completion: @escaping (Bool) -> Void) {
        guard isEnabled else {
            completion(false)
            return
        }

        let recordID = CKRecord.ID(recordName: id.uuidString)
        privateDatabase.delete(withRecordID: recordID) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKit delete failed: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
}
