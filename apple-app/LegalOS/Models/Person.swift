//
//  Person.swift
//  Beteiligte Person (Richter, Zeuge, Sachverständiger, Anwalt, Partei …).
//

import Foundation
import CloudKit

public enum PersonRole: String, Codable, CaseIterable, Hashable {
    case richter           = "Richter"
    case zeuge             = "Zeuge"
    case sachverstaendiger = "Sachverständiger"
    case partei            = "Partei"
    case anwalt            = "Anwalt"
    case gutachter         = "Gutachter"
}

public struct Person: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var name: String
    public var role: PersonRole = .zeuge
    public var organization: String?
    public var aussagen: Int = 0
    public var widersprueche: Int = 0
    public var glaubwuerdigkeit: Double?
    public var klaegerRate: Double?
    public var vergleichRate: Double?
    public var dauerMonate: Double?
    public var notizen: String?

    public init(caseId: String, name: String) {
        self.caseId = caseId
        self.name = name
    }
}

public extension Person {
    static let recordType = "Person"

    init(record: CKRecord) {
        self.id              = record.recordID.recordName
        self.caseId          = record["case_id"] as? String ?? ""
        self.name            = record["name"] as? String ?? ""
        self.role            = PersonRole(rawValue: record["role"] as? String ?? "Zeuge") ?? .zeuge
        self.organization    = record["organization"] as? String
        self.aussagen        = record["aussagen"] as? Int ?? 0
        self.widersprueche   = record["widersprueche"] as? Int ?? 0
        self.glaubwuerdigkeit = record["glaubwuerdigkeit"] as? Double
        self.klaegerRate     = record["klaeger_rate"] as? Double
        self.vergleichRate   = record["vergleich_rate"] as? Double
        self.dauerMonate     = record["dauer_monate"] as? Double
        self.notizen         = record["notizen"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]          = caseId as CKRecordValue
        r["name"]             = name as CKRecordValue
        r["role"]             = role.rawValue as CKRecordValue
        r["organization"]     = organization as CKRecordValue?
        r["aussagen"]         = aussagen as CKRecordValue
        r["widersprueche"]    = widersprueche as CKRecordValue
        r["glaubwuerdigkeit"] = glaubwuerdigkeit as CKRecordValue?
        r["klaeger_rate"]     = klaegerRate as CKRecordValue?
        r["vergleich_rate"]   = vergleichRate as CKRecordValue?
        r["dauer_monate"]     = dauerMonate as CKRecordValue?
        r["notizen"]          = notizen as CKRecordValue?
        return r
    }
}
