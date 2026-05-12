//
//  Task.swift
//  Aufgabe / To-Do, optional einem Fall zugeordnet.
//  ACHTUNG: Klassennamen-Konflikt mit Swift Concurrency `Task` –
//  daher heißt unsere Entität `LegalTask`.
//

import Foundation
import CloudKit

public enum TaskPriority: String, Codable, CaseIterable, Hashable {
    case hoch
    case mittel
    case niedrig
}

public enum TaskStatus: String, Codable, CaseIterable, Hashable {
    case offen
    case inBearbeitung = "in_bearbeitung"
    case erledigt
}

public struct LegalTask: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String?
    public var caseName: String?
    public var title: String
    public var notes: String?
    public var assignee: String?
    public var dueDate: Date?
    public var priority: TaskPriority = .mittel
    public var status: TaskStatus = .offen

    public init(title: String) {
        self.title = title
    }
}

public extension LegalTask {
    static let recordType = "Task"

    init(record: CKRecord) {
        self.id        = record.recordID.recordName
        self.caseId    = record["case_id"] as? String
        self.caseName  = record["case_name"] as? String
        self.title     = record["title"] as? String ?? ""
        self.notes     = record["notes"] as? String
        self.assignee  = record["assignee"] as? String
        self.dueDate   = record["due_date"] as? Date
        self.priority  = TaskPriority(rawValue: record["priority"] as? String ?? "mittel") ?? .mittel
        self.status    = TaskStatus(rawValue: record["status"] as? String ?? "offen") ?? .offen
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]   = caseId as CKRecordValue?
        r["case_name"] = caseName as CKRecordValue?
        r["title"]     = title as CKRecordValue
        r["notes"]     = notes as CKRecordValue?
        r["assignee"]  = assignee as CKRecordValue?
        r["due_date"]  = dueDate as CKRecordValue?
        r["priority"]  = priority.rawValue as CKRecordValue
        r["status"]    = status.rawValue as CKRecordValue
        return r
    }
}
