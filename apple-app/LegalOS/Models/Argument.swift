//
//  Argument.swift
//  Juristisches Argument – kann eigene oder gegnerische Seite sein.
//

import Foundation
import CloudKit

public enum ArgumentSide: String, Codable, CaseIterable, Hashable {
    case eigen
    case gegner
}

public struct Argument: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var title: String
    public var argDescription: String?
    public var side: ArgumentSide = .eigen
    /// Manuelle Stärke 0-10.
    public var strength: Double?
    /// KI-Stärke 0-10.
    public var kiStrength: Double?
    public var kiReasoning: String?
    public var type: String?
    public var paragraphs: [String] = []
    public var evidenceIds: [String] = []
    public var isContradiction: Bool = false
    public var zeitpunkt: String?
    public var anmerkungen: String?

    public init(caseId: String, title: String) {
        self.caseId = caseId
        self.title = title
    }
}

public extension Argument {
    static let recordType = "Argument"

    init(record: CKRecord) {
        self.id              = record.recordID.recordName
        self.caseId          = record["case_id"] as? String ?? ""
        self.title           = record["title"] as? String ?? ""
        self.argDescription  = record["description"] as? String
        self.side            = ArgumentSide(rawValue: record["side"] as? String ?? "eigen") ?? .eigen
        self.strength        = record["strength"] as? Double
        self.kiStrength      = record["ki_strength"] as? Double
        self.kiReasoning     = record["ki_reasoning"] as? String
        self.type            = record["type"] as? String
        self.paragraphs      = record["paragraphs"] as? [String] ?? []
        self.evidenceIds     = record["evidence_ids"] as? [String] ?? []
        self.isContradiction = (record["is_contradiction"] as? Int ?? 0) == 1
        self.zeitpunkt       = record["zeitpunkt"] as? String
        self.anmerkungen     = record["anmerkungen"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]          = caseId as CKRecordValue
        r["title"]            = title as CKRecordValue
        r["description"]      = argDescription as CKRecordValue?
        r["side"]             = side.rawValue as CKRecordValue
        r["strength"]         = strength as CKRecordValue?
        r["ki_strength"]      = kiStrength as CKRecordValue?
        r["ki_reasoning"]     = kiReasoning as CKRecordValue?
        r["type"]             = type as CKRecordValue?
        r["paragraphs"]       = paragraphs as CKRecordValue
        r["evidence_ids"]     = evidenceIds as CKRecordValue
        r["is_contradiction"] = (isContradiction ? 1 : 0) as CKRecordValue
        r["zeitpunkt"]        = zeitpunkt as CKRecordValue?
        r["anmerkungen"]      = anmerkungen as CKRecordValue?
        return r
    }
}
