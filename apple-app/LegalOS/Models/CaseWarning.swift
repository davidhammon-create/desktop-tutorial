//
//  CaseWarning.swift
//  Fall-Warnung (z.B. Diskrepanz, fehlender Beleg, veraltete Rspr.).
//

import Foundation
import CloudKit

public enum WarningType: String, Codable, CaseIterable, Hashable {
    case diskrepanz
    case fehlenderBeleg = "fehlender_beleg"
    case veralteteRspr  = "veraltete_rspr"
    case unterstuetzungFehlt = "unterstuetzung_fehlt"
    case widerspruch
}

public enum WarningSeverity: String, Codable, CaseIterable, Hashable {
    case kritisch
    case hoch
    case mittel
    case niedrig
}

public enum WarningElementType: String, Codable, CaseIterable, Hashable {
    case argument
    case beweis
    case frist
    case person
}

public struct CaseWarning: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var warningType: WarningType
    public var severity: WarningSeverity = .mittel
    public var elementType: WarningElementType?
    public var elementId: String?
    public var elementTitle: String?
    public var title: String
    public var warningDescription: String?
    public var suggestion: String?
    public var rsprReference: String?
    public var resolved: Bool = false
    public var resolvedDate: Date?
    public var resolvedBy: String?

    public init(caseId: String, warningType: WarningType, title: String) {
        self.caseId = caseId
        self.warningType = warningType
        self.title = title
    }
}

public extension CaseWarning {
    static let recordType = "CaseWarning"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.caseId        = record["case_id"] as? String ?? ""
        self.warningType   = WarningType(rawValue: record["warning_type"] as? String ?? "diskrepanz") ?? .diskrepanz
        self.severity      = WarningSeverity(rawValue: record["severity"] as? String ?? "mittel") ?? .mittel
        if let e = record["element_type"] as? String { self.elementType = WarningElementType(rawValue: e) }
        self.elementId     = record["element_id"] as? String
        self.elementTitle  = record["element_title"] as? String
        self.title         = record["title"] as? String ?? ""
        self.warningDescription = record["description"] as? String
        self.suggestion    = record["suggestion"] as? String
        self.rsprReference = record["rspr_reference"] as? String
        self.resolved      = (record["resolved"] as? Int ?? 0) == 1
        self.resolvedDate  = record["resolved_date"] as? Date
        self.resolvedBy    = record["resolved_by"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["warning_type"] = warningType.rawValue as CKRecordValue
        r["severity"]     = severity.rawValue as CKRecordValue
        r["element_type"] = elementType?.rawValue as CKRecordValue?
        r["element_id"]   = elementId as CKRecordValue?
        r["element_title"] = elementTitle as CKRecordValue?
        r["title"]        = title as CKRecordValue
        r["description"]  = warningDescription as CKRecordValue?
        r["suggestion"]   = suggestion as CKRecordValue?
        r["rspr_reference"] = rsprReference as CKRecordValue?
        r["resolved"]     = (resolved ? 1 : 0) as CKRecordValue
        r["resolved_date"] = resolvedDate as CKRecordValue?
        r["resolved_by"]  = resolvedBy as CKRecordValue?
        return r
    }
}
