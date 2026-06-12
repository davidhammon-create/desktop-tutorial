//
//  JurisdictionInsight.swift
//  Anonymisierte Erkenntnisse pro Rechtsordnung – speist Wissens-Pool.
//

import Foundation
import CloudKit

public enum InsightSourceType: String, Codable, CaseIterable, Hashable {
    case procedure
    case courtPractice          = "court_practice"
    case argumentationPattern   = "argumentation_pattern"
    case deadlinePattern        = "deadline_pattern"
    case strategicApproach      = "strategic_approach"
}

public struct JurisdictionInsight: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var jurisdiction: String
    public var topic: String
    public var sourceType: InsightSourceType = .procedure
    public var insightText: String
    public var usageCount: Int = 0
    public var effectivenessScore: Double?
    public var tags: [String] = []

    public init(jurisdiction: String, topic: String, insightText: String) {
        self.jurisdiction = jurisdiction
        self.topic = topic
        self.insightText = insightText
    }
}

public extension JurisdictionInsight {
    static let recordType = "JurisdictionInsight"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.jurisdiction  = record["jurisdiction"] as? String ?? ""
        self.topic         = record["topic"] as? String ?? ""
        self.sourceType    = InsightSourceType(rawValue: record["source_type"] as? String ?? "procedure") ?? .procedure
        self.insightText   = record["insight_text"] as? String ?? ""
        self.usageCount    = record["usage_count"] as? Int ?? 0
        self.effectivenessScore = record["effectiveness_score"] as? Double
        self.tags          = record["tags"] as? [String] ?? []
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["jurisdiction"]   = jurisdiction as CKRecordValue
        r["topic"]          = topic as CKRecordValue
        r["source_type"]    = sourceType.rawValue as CKRecordValue
        r["insight_text"]   = insightText as CKRecordValue
        r["usage_count"]    = usageCount as CKRecordValue
        r["effectiveness_score"] = effectivenessScore as CKRecordValue?
        r["tags"]           = tags as CKRecordValue
        return r
    }
}
