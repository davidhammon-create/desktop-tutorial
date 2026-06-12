//
//  Deadline.swift
//  Frist-Entität – mit Fälligkeitsdatum und Status.
//

import Foundation
import CloudKit

public enum DeadlineSide: String, Codable, CaseIterable, Hashable {
    case eigene = "Eigene"
    case gegner = "Gegner"
}

public enum DeadlineStatus: String, Codable, CaseIterable, Hashable {
    case offen
    case erledigt
    case versaeumt
}

public struct Deadline: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var title: String
    public var fristType: String?
    public var paragraph: String?
    public var dueDate: Date
    public var responsible: String?
    public var side: DeadlineSide = .eigene
    public var status: DeadlineStatus = .offen
    public var prognoseabzug: String?

    public init(caseId: String, title: String, dueDate: Date) {
        self.caseId = caseId
        self.title = title
        self.dueDate = dueDate
    }
}

public extension Deadline {
    static let recordType = "Deadline"

    init(record: CKRecord) {
        self.id           = record.recordID.recordName
        self.caseId       = record["case_id"] as? String ?? ""
        self.title        = record["title"] as? String ?? ""
        self.fristType    = record["frist_type"] as? String
        self.paragraph    = record["paragraph"] as? String
        self.dueDate      = record["due_date"] as? Date ?? Date()
        self.responsible  = record["responsible"] as? String
        self.side         = DeadlineSide(rawValue: record["side"] as? String ?? "Eigene") ?? .eigene
        self.status       = DeadlineStatus(rawValue: record["status"] as? String ?? "offen") ?? .offen
        self.prognoseabzug = record["prognoseabzug"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]       = caseId as CKRecordValue
        r["title"]         = title as CKRecordValue
        r["frist_type"]    = fristType as CKRecordValue?
        r["paragraph"]     = paragraph as CKRecordValue?
        r["due_date"]      = dueDate as CKRecordValue
        r["responsible"]   = responsible as CKRecordValue?
        r["side"]          = side.rawValue as CKRecordValue
        r["status"]        = status.rawValue as CKRecordValue
        r["prognoseabzug"] = prognoseabzug as CKRecordValue?
        return r
    }
}
