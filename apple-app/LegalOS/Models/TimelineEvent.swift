//
//  TimelineEvent.swift
//  Ereignis auf einer Fall-Zeitleiste.
//

import Foundation
import CloudKit

public enum TimelineCategory: String, Codable, CaseIterable, Hashable {
    case vertrag
    case zahlung
    case klage
    case urteil
    case frist
    case verhandlung
    case gutachten
    case korrespondenz
    case sonstiges
}

public enum TimelineImportance: String, Codable, CaseIterable, Hashable {
    case kritisch
    case hoch
    case mittel
    case niedrig
}

public struct TimelineEvent: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var date: Date
    public var title: String
    public var eventDescription: String?
    public var category: TimelineCategory = .sonstiges
    /// JSON-String: [{title, file_url, file_type}]
    public var documentsJSON: String?
    public var personsInvolved: [String] = []
    public var importance: TimelineImportance = .mittel
    public var kiGenerated: Bool = false

    public init(caseId: String, date: Date, title: String) {
        self.caseId = caseId
        self.date = date
        self.title = title
    }
}

public extension TimelineEvent {
    static let recordType = "TimelineEvent"

    init(record: CKRecord) {
        self.id              = record.recordID.recordName
        self.caseId          = record["case_id"] as? String ?? ""
        self.date            = record["date"] as? Date ?? Date()
        self.title           = record["title"] as? String ?? ""
        self.eventDescription = record["description"] as? String
        self.category        = TimelineCategory(rawValue: record["category"] as? String ?? "sonstiges") ?? .sonstiges
        self.documentsJSON   = record["documents"] as? String
        self.personsInvolved = record["persons_involved"] as? [String] ?? []
        self.importance      = TimelineImportance(rawValue: record["importance"] as? String ?? "mittel") ?? .mittel
        self.kiGenerated     = (record["ki_generated"] as? Int ?? 0) == 1
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["date"]         = date as CKRecordValue
        r["title"]        = title as CKRecordValue
        r["description"]  = eventDescription as CKRecordValue?
        r["category"]     = category.rawValue as CKRecordValue
        r["documents"]    = documentsJSON as CKRecordValue?
        r["persons_involved"] = personsInvolved as CKRecordValue
        r["importance"]   = importance.rawValue as CKRecordValue
        r["ki_generated"] = (kiGenerated ? 1 : 0) as CKRecordValue
        return r
    }
}
