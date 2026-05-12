//
//  CaseHistory.swift
//  Audit-Log Eintrag für Änderungen an Fall-Entitäten.
//

import Foundation
import CloudKit

public enum CaseHistoryEntityType: String, Codable, CaseIterable, Hashable {
    case argument = "Argument"
    case evidence = "Evidence"
    case deadline = "Deadline"
    case person   = "Person"
    case document = "Document"
    case caseEnt  = "Case"
    case risk     = "Risk"
}

public enum CaseHistoryAction: String, Codable, CaseIterable, Hashable {
    case create
    case update
    case delete
}

public struct CaseHistory: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var entityType: CaseHistoryEntityType
    public var entityId: String?
    public var entityTitle: String?
    public var action: CaseHistoryAction
    public var fieldChanged: String?
    public var oldValue: String?
    public var newValue: String?
    public var summary: String?
    public var userEmail: String?
    public var timestamp: Date = Date()

    public init(caseId: String, entityType: CaseHistoryEntityType, action: CaseHistoryAction) {
        self.caseId = caseId
        self.entityType = entityType
        self.action = action
    }
}

public extension CaseHistory {
    static let recordType = "CaseHistory"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.caseId        = record["case_id"] as? String ?? ""
        self.entityType    = CaseHistoryEntityType(rawValue: record["entity_type"] as? String ?? "Case") ?? .caseEnt
        self.entityId      = record["entity_id"] as? String
        self.entityTitle   = record["entity_title"] as? String
        self.action        = CaseHistoryAction(rawValue: record["action"] as? String ?? "update") ?? .update
        self.fieldChanged  = record["field_changed"] as? String
        self.oldValue      = record["old_value"] as? String
        self.newValue      = record["new_value"] as? String
        self.summary       = record["summary"] as? String
        self.userEmail     = record["user_email"] as? String
        self.timestamp     = record["timestamp"] as? Date ?? record.creationDate ?? Date()
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["entity_type"]  = entityType.rawValue as CKRecordValue
        r["entity_id"]    = entityId as CKRecordValue?
        r["entity_title"] = entityTitle as CKRecordValue?
        r["action"]       = action.rawValue as CKRecordValue
        r["field_changed"] = fieldChanged as CKRecordValue?
        r["old_value"]    = oldValue as CKRecordValue?
        r["new_value"]    = newValue as CKRecordValue?
        r["summary"]      = summary as CKRecordValue?
        r["user_email"]   = userEmail as CKRecordValue?
        r["timestamp"]    = timestamp as CKRecordValue
        return r
    }
}
