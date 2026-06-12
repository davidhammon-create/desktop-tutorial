//
//  Evidence.swift
//  Beweis-Entität – verknüpft mit einem Fall und optional mit einem Argument.
//

import Foundation
import CloudKit

public struct Evidence: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var argumentId: String?
    public var title: String
    public var evidenceDescription: String?
    public var weight: Double?
    public var kiWeight: Double?
    public var kiReasoning: String?
    public var type: String?
    public var source: String?
    public var datum: String?

    public init(caseId: String, title: String) {
        self.caseId = caseId
        self.title = title
    }
}

public extension Evidence {
    static let recordType = "Evidence"

    init(record: CKRecord) {
        self.id                  = record.recordID.recordName
        self.caseId              = record["case_id"] as? String ?? ""
        self.argumentId          = record["argument_id"] as? String
        self.title               = record["title"] as? String ?? ""
        self.evidenceDescription = record["description"] as? String
        self.weight              = record["weight"] as? Double
        self.kiWeight            = record["ki_weight"] as? Double
        self.kiReasoning         = record["ki_reasoning"] as? String
        self.type                = record["type"] as? String
        self.source              = record["source"] as? String
        self.datum               = record["datum"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["argument_id"]  = argumentId as CKRecordValue?
        r["title"]        = title as CKRecordValue
        r["description"]  = evidenceDescription as CKRecordValue?
        r["weight"]       = weight as CKRecordValue?
        r["ki_weight"]    = kiWeight as CKRecordValue?
        r["ki_reasoning"] = kiReasoning as CKRecordValue?
        r["type"]         = type as CKRecordValue?
        r["source"]       = source as CKRecordValue?
        r["datum"]        = datum as CKRecordValue?
        return r
    }
}
