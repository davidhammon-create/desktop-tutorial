//
//  CaseQuestionnaire.swift
//  Abschluss-Fragebogen für einen Fall (zur Bewertung der KI-Prognose).
//

import Foundation
import CloudKit

public struct CaseQuestionnaire: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var caseName: String?
    public var zielErreicht: Bool = false
    public var mandantZufrieden: Bool = false
    public var vergleichGeschlossen: Bool = false
    public var kostenImRahmen: Bool = false
    public var fristenEingehalten: Bool = false
    public var kiPrognoseKorrekt: Bool = false
    public var ergebnisUrteil: String?
    public var abweichungPrognose: String?
    public var lernpunkte: String?
    public var mandantenFeedback: String?
    public var gesamtbewertung: Double?
    public var dauerMonate: Double?
    public var endkosten: Double?

    public init(caseId: String) { self.caseId = caseId }
}

public extension CaseQuestionnaire {
    static let recordType = "CaseQuestionnaire"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.caseId        = record["case_id"] as? String ?? ""
        self.caseName      = record["case_name"] as? String
        self.zielErreicht  = (record["ziel_erreicht"] as? Int ?? 0) == 1
        self.mandantZufrieden = (record["mandant_zufrieden"] as? Int ?? 0) == 1
        self.vergleichGeschlossen = (record["vergleich_geschlossen"] as? Int ?? 0) == 1
        self.kostenImRahmen = (record["kosten_im_rahmen"] as? Int ?? 0) == 1
        self.fristenEingehalten = (record["fristen_eingehalten"] as? Int ?? 0) == 1
        self.kiPrognoseKorrekt  = (record["ki_prognose_korrekt"] as? Int ?? 0) == 1
        self.ergebnisUrteil = record["ergebnis_urteil"] as? String
        self.abweichungPrognose = record["abweichung_prognose"] as? String
        self.lernpunkte    = record["lernpunkte"] as? String
        self.mandantenFeedback = record["mandanten_feedback"] as? String
        self.gesamtbewertung = record["gesamtbewertung"] as? Double
        self.dauerMonate     = record["dauer_monate"] as? Double
        self.endkosten       = record["endkosten"] as? Double
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]   = caseId as CKRecordValue
        r["case_name"] = caseName as CKRecordValue?
        r["ziel_erreicht"]        = (zielErreicht ? 1 : 0) as CKRecordValue
        r["mandant_zufrieden"]    = (mandantZufrieden ? 1 : 0) as CKRecordValue
        r["vergleich_geschlossen"] = (vergleichGeschlossen ? 1 : 0) as CKRecordValue
        r["kosten_im_rahmen"]     = (kostenImRahmen ? 1 : 0) as CKRecordValue
        r["fristen_eingehalten"]  = (fristenEingehalten ? 1 : 0) as CKRecordValue
        r["ki_prognose_korrekt"]  = (kiPrognoseKorrekt ? 1 : 0) as CKRecordValue
        r["ergebnis_urteil"]      = ergebnisUrteil as CKRecordValue?
        r["abweichung_prognose"]  = abweichungPrognose as CKRecordValue?
        r["lernpunkte"]    = lernpunkte as CKRecordValue?
        r["mandanten_feedback"] = mandantenFeedback as CKRecordValue?
        r["gesamtbewertung"] = gesamtbewertung as CKRecordValue?
        r["dauer_monate"]    = dauerMonate as CKRecordValue?
        r["endkosten"]       = endkosten as CKRecordValue?
        return r
    }
}
