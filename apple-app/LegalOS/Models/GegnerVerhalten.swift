//
//  GegnerVerhalten.swift
//  Beobachtetes Verhalten der Gegenseite – wird für Pattern-Analyse genutzt.
//

import Foundation
import CloudKit

public enum GegnerTyp: String, Codable, CaseIterable, Hashable {
    case versaeumteFrist     = "versaeumte_frist"
    case vergleichsreaktion  = "vergleichsreaktion"
    case taktik              = "taktik"
    case prozessverhalten    = "prozessverhalten"
    case sonstiges           = "sonstiges"
}

public enum GegnerReaktion: String, Codable, CaseIterable, Hashable {
    case abgelehnt
    case angenommen
    case ignoriert
    case verzoegert
    case gegenvorschlag
    case keineReaktion = "keine_reaktion"
}

public enum GegnerPatternTag: String, Codable, CaseIterable, Hashable {
    case verzoegerungstaktik
    case druckmittel
    case konzessionsbereit
    case konfrontativ
    case kooperativ
    case unberechenbar
}

public struct GegnerVerhalten: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var typ: GegnerTyp
    public var datum: Date?
    public var titel: String
    public var beschreibung: String?
    public var reaktion: GegnerReaktion?
    public var unserAngebot: Double?
    public var gegnerAngebot: Double?
    public var verzoegerungTage: Double?
    public var ergebnis: String?
    public var patternTag: GegnerPatternTag?
    public var auswirkungPrognose: Double?

    public init(caseId: String, typ: GegnerTyp, titel: String) {
        self.caseId = caseId
        self.typ = typ
        self.titel = titel
    }
}

public extension GegnerVerhalten {
    static let recordType = "GegnerVerhalten"

    init(record: CKRecord) {
        self.id           = record.recordID.recordName
        self.caseId       = record["case_id"] as? String ?? ""
        self.typ          = GegnerTyp(rawValue: record["typ"] as? String ?? "sonstiges") ?? .sonstiges
        self.datum        = record["datum"] as? Date
        self.titel        = record["titel"] as? String ?? ""
        self.beschreibung = record["beschreibung"] as? String
        if let r = record["reaktion"] as? String { self.reaktion = GegnerReaktion(rawValue: r) }
        self.unserAngebot   = record["unser_angebot"] as? Double
        self.gegnerAngebot  = record["gegner_angebot"] as? Double
        self.verzoegerungTage = record["verzoegerung_tage"] as? Double
        self.ergebnis     = record["ergebnis"] as? String
        if let p = record["pattern_tag"] as? String { self.patternTag = GegnerPatternTag(rawValue: p) }
        self.auswirkungPrognose = record["auswirkung_prognose"] as? Double
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]       = caseId as CKRecordValue
        r["typ"]           = typ.rawValue as CKRecordValue
        r["datum"]         = datum as CKRecordValue?
        r["titel"]         = titel as CKRecordValue
        r["beschreibung"]  = beschreibung as CKRecordValue?
        r["reaktion"]      = reaktion?.rawValue as CKRecordValue?
        r["unser_angebot"] = unserAngebot as CKRecordValue?
        r["gegner_angebot"] = gegnerAngebot as CKRecordValue?
        r["verzoegerung_tage"] = verzoegerungTage as CKRecordValue?
        r["ergebnis"]      = ergebnis as CKRecordValue?
        r["pattern_tag"]   = patternTag?.rawValue as CKRecordValue?
        r["auswirkung_prognose"] = auswirkungPrognose as CKRecordValue?
        return r
    }
}
