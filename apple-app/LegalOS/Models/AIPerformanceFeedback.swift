//
//  AIPerformanceFeedback.swift
//  Strukturiertes Feedback zu einer KI-gestützten Fallbearbeitung.
//

import Foundation
import CloudKit

public struct AIPerformanceFeedback: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var caseName: String?
    public var prognoseRating: Double?
    public var prognoseAbweichung: Double?
    public var strategieRating: Double?
    public var strategieFeedback: String?
    public var kiBeraterRating: Double?
    public var kiBeraterFeedback: String?
    /// JSON-String: [{aspekt, problem, loesung, prioritaet}]
    public var verbesserungsvorschlaegeJSON: String?
    public var gesamtbewertung: Double
    public var fallErfolgreich: Bool = false

    public init(caseId: String, gesamtbewertung: Double) {
        self.caseId = caseId
        self.gesamtbewertung = gesamtbewertung
    }
}

public extension AIPerformanceFeedback {
    static let recordType = "AIPerformanceFeedback"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.caseId        = record["case_id"] as? String ?? ""
        self.caseName      = record["case_name"] as? String
        self.prognoseRating = record["prognose_rating"] as? Double
        self.prognoseAbweichung = record["prognose_abweichung"] as? Double
        self.strategieRating = record["strategie_rating"] as? Double
        self.strategieFeedback = record["strategie_feedback"] as? String
        self.kiBeraterRating  = record["ki_berater_rating"] as? Double
        self.kiBeraterFeedback = record["ki_berater_feedback"] as? String
        self.verbesserungsvorschlaegeJSON = record["verbesserungsvorschlaege"] as? String
        self.gesamtbewertung = record["gesamtbewertung"] as? Double ?? 0
        self.fallErfolgreich = (record["fall_erfolgreich"] as? Int ?? 0) == 1
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["case_name"]    = caseName as CKRecordValue?
        r["prognose_rating"] = prognoseRating as CKRecordValue?
        r["prognose_abweichung"] = prognoseAbweichung as CKRecordValue?
        r["strategie_rating"] = strategieRating as CKRecordValue?
        r["strategie_feedback"] = strategieFeedback as CKRecordValue?
        r["ki_berater_rating"] = kiBeraterRating as CKRecordValue?
        r["ki_berater_feedback"] = kiBeraterFeedback as CKRecordValue?
        r["verbesserungsvorschlaege"] = verbesserungsvorschlaegeJSON as CKRecordValue?
        r["gesamtbewertung"] = gesamtbewertung as CKRecordValue
        r["fall_erfolgreich"] = (fallErfolgreich ? 1 : 0) as CKRecordValue
        return r
    }
}
