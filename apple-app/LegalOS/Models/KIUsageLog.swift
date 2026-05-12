//
//  KIUsageLog.swift
//  Log-Eintrag jeder KI-Anfrage – wird für Compliance + Analytik genutzt.
//

import Foundation
import CloudKit

public struct KIUsageLog: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String?
    public var kiFunction: String
    public var inputSummary: String?
    public var output: String
    public var model: String?
    public var context: String?
    public var rating: Double?
    public var feedback: String?
    public var isDuplicate: Bool = false
    public var parentLogId: String?
    public var timestamp: Date = Date()

    public init(kiFunction: String, output: String) {
        self.kiFunction = kiFunction
        self.output = output
    }
}

public extension KIUsageLog {
    static let recordType = "KIUsageLog"

    init(record: CKRecord) {
        self.id           = record.recordID.recordName
        self.caseId       = record["case_id"] as? String
        self.kiFunction   = record["ki_function"] as? String ?? ""
        self.inputSummary = record["input_summary"] as? String
        self.output       = record["output"] as? String ?? ""
        self.model        = record["model"] as? String
        self.context      = record["context"] as? String
        self.rating       = record["rating"] as? Double
        self.feedback     = record["feedback"] as? String
        self.isDuplicate  = (record["is_duplicate"] as? Int ?? 0) == 1
        self.parentLogId  = record["parent_log_id"] as? String
        self.timestamp    = record["timestamp"] as? Date ?? record.creationDate ?? Date()
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]       = caseId as CKRecordValue?
        r["ki_function"]   = kiFunction as CKRecordValue
        r["input_summary"] = inputSummary as CKRecordValue?
        r["output"]        = output as CKRecordValue
        r["model"]         = model as CKRecordValue?
        r["context"]       = context as CKRecordValue?
        r["rating"]        = rating as CKRecordValue?
        r["feedback"]      = feedback as CKRecordValue?
        r["is_duplicate"]  = (isDuplicate ? 1 : 0) as CKRecordValue
        r["parent_log_id"] = parentLogId as CKRecordValue?
        r["timestamp"]     = timestamp as CKRecordValue
        return r
    }
}
