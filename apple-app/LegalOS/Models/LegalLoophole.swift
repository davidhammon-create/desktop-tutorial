//
//  LegalLoophole.swift
//  Identifizierte Gesetzeslücke / legaler Hebel.
//

import Foundation
import CloudKit

public enum Nutzungspotential: String, Codable, CaseIterable, Hashable {
    case hoch
    case mittel
    case niedrig
    case theoretisch
}

public enum LoopholeRisiko: String, Codable, CaseIterable, Hashable {
    case gering
    case mittel
    case hoch
    case existenzbedrohend
}

public struct LegalLoophole: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var gesetz: String
    public var paragraph: String?
    public var rechtsgebiet: String?
    public var jurisdiction: Jurisdiction = .dach
    public var titel: String
    public var beschreibung: String
    public var nutzungspotential: Nutzungspotential = .mittel
    public var risikoBeiNutzung: LoopholeRisiko = .mittel
    public var bekannteFaelle: String?
    public var gegenstrategien: String?
    public var tags: [String] = []
    public var aktiv: Bool = true
    public var scenarioId: String?
    public var kiGenerated: Bool = false

    public init(gesetz: String, titel: String, beschreibung: String) {
        self.gesetz = gesetz
        self.titel = titel
        self.beschreibung = beschreibung
    }
}

public extension LegalLoophole {
    static let recordType = "LegalLoophole"

    init(record: CKRecord) {
        self.id              = record.recordID.recordName
        self.gesetz          = record["gesetz"] as? String ?? ""
        self.paragraph       = record["paragraph"] as? String
        self.rechtsgebiet    = record["rechtsgebiet"] as? String
        self.jurisdiction    = Jurisdiction(rawValue: record["jurisdiction"] as? String ?? "DACH") ?? .dach
        self.titel           = record["titel"] as? String ?? ""
        self.beschreibung    = record["beschreibung"] as? String ?? ""
        self.nutzungspotential = Nutzungspotential(rawValue: record["nutzungspotential"] as? String ?? "mittel") ?? .mittel
        self.risikoBeiNutzung = LoopholeRisiko(rawValue: record["risiko_bei_nutzung"] as? String ?? "mittel") ?? .mittel
        self.bekannteFaelle  = record["bekannte_faelle"] as? String
        self.gegenstrategien = record["gegenstrategien"] as? String
        self.tags            = record["tags"] as? [String] ?? []
        self.aktiv           = (record["aktiv"] as? Int ?? 1) == 1
        self.scenarioId      = record["scenario_id"] as? String
        self.kiGenerated     = (record["ki_generated"] as? Int ?? 0) == 1
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["gesetz"]            = gesetz as CKRecordValue
        r["paragraph"]         = paragraph as CKRecordValue?
        r["rechtsgebiet"]      = rechtsgebiet as CKRecordValue?
        r["jurisdiction"]      = jurisdiction.rawValue as CKRecordValue
        r["titel"]             = titel as CKRecordValue
        r["beschreibung"]      = beschreibung as CKRecordValue
        r["nutzungspotential"] = nutzungspotential.rawValue as CKRecordValue
        r["risiko_bei_nutzung"] = risikoBeiNutzung.rawValue as CKRecordValue
        r["bekannte_faelle"]   = bekannteFaelle as CKRecordValue?
        r["gegenstrategien"]   = gegenstrategien as CKRecordValue?
        r["tags"]              = tags as CKRecordValue
        r["aktiv"]             = (aktiv ? 1 : 0) as CKRecordValue
        r["scenario_id"]       = scenarioId as CKRecordValue?
        r["ki_generated"]      = (kiGenerated ? 1 : 0) as CKRecordValue
        return r
    }
}
