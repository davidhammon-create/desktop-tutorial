//
//  Case.swift
//  LegalOS Datenmodell – Hauptfall-Entität.
//  Entspricht der BASE44-Entität "Case" in base44/entities/Case.jsonc.
//

import Foundation
import CloudKit

/// Status-Werte für einen Fall.
public enum CaseStatus: String, Codable, CaseIterable, Hashable {
    case aktiv          = "Aktiv"
    case vorbereitung   = "Vorbereitung"
    case abgeschlossen  = "Abgeschlossen"
    case ruhend         = "Ruhend"
}

/// Instanz eines Falls.
public enum CaseInstanz: String, Codable, CaseIterable, Hashable {
    case erstinstanz = "Erstinstanz"
    case berufung    = "Berufung"
    case revision    = "Revision"
}

/// Haupt-Fall-Entität. Wird in CloudKit als "Case"-Record gespeichert.
public struct Case: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var fallname: String
    public var aktenzeichen: String?
    public var gericht: String?
    public var rechtsgebiet: String?
    public var prozessziel: String?
    public var status: CaseStatus = .vorbereitung
    public var instanz: CaseInstanz = .erstinstanz
    public var zentraleRechtsfrage: String?
    public var prognose: Double?
    public var streitwert: Double?
    public var gebuehrenstufe: Double?
    public var svKosten: Double?
    public var reisekosten: Double?
    public var vergleichsangebot: Double?
    public var richterName: String?
    public var richterKlaegerRate: Double?
    /// KI-Berater-Ergebnis als JSON-String (CloudKit-kompatibel).
    public var kiBeraterResultJSON: String?
    public var gegnerProfilJSON: String?
    public var notes: String?
    public var folderId: String?
    public var mandantName: String?
    public var createdBy: String?
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(fallname: String) {
        self.fallname = fallname
    }
}

// MARK: - CloudKit Mapping
public extension Case {
    static let recordType = "Case"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.fallname      = record["fallname"] as? String ?? "Unbenannt"
        self.aktenzeichen  = record["aktenzeichen"] as? String
        self.gericht       = record["gericht"] as? String
        self.rechtsgebiet  = record["rechtsgebiet"] as? String
        self.prozessziel   = record["prozessziel"] as? String
        self.status        = CaseStatus(rawValue: record["status"] as? String ?? "") ?? .vorbereitung
        self.instanz       = CaseInstanz(rawValue: record["instanz"] as? String ?? "") ?? .erstinstanz
        self.zentraleRechtsfrage = record["zentrale_rechtsfrage"] as? String
        self.prognose      = record["prognose"] as? Double
        self.streitwert    = record["streitwert"] as? Double
        self.gebuehrenstufe = record["gebuehrenstufe"] as? Double
        self.svKosten      = record["sv_kosten"] as? Double
        self.reisekosten   = record["reisekosten"] as? Double
        self.vergleichsangebot = record["vergleichsangebot"] as? Double
        self.richterName   = record["richter_name"] as? String
        self.richterKlaegerRate = record["richter_klaeger_rate"] as? Double
        self.kiBeraterResultJSON = record["ki_berater_result"] as? String
        self.gegnerProfilJSON    = record["gegner_profil"] as? String
        self.notes         = record["notes"] as? String
        self.folderId      = record["folder_id"] as? String
        self.mandantName   = record["mandant_name"] as? String
        self.createdBy     = record["created_by"] as? String
        self.createdAt     = record.creationDate ?? Date()
        self.updatedAt     = record.modificationDate ?? Date()
    }

    func toRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["fallname"]            = fallname as CKRecordValue
        record["aktenzeichen"]        = aktenzeichen as CKRecordValue?
        record["gericht"]             = gericht as CKRecordValue?
        record["rechtsgebiet"]        = rechtsgebiet as CKRecordValue?
        record["prozessziel"]         = prozessziel as CKRecordValue?
        record["status"]              = status.rawValue as CKRecordValue
        record["instanz"]             = instanz.rawValue as CKRecordValue
        record["zentrale_rechtsfrage"] = zentraleRechtsfrage as CKRecordValue?
        record["prognose"]            = prognose as CKRecordValue?
        record["streitwert"]          = streitwert as CKRecordValue?
        record["gebuehrenstufe"]      = gebuehrenstufe as CKRecordValue?
        record["sv_kosten"]           = svKosten as CKRecordValue?
        record["reisekosten"]         = reisekosten as CKRecordValue?
        record["vergleichsangebot"]   = vergleichsangebot as CKRecordValue?
        record["richter_name"]        = richterName as CKRecordValue?
        record["richter_klaeger_rate"] = richterKlaegerRate as CKRecordValue?
        record["ki_berater_result"]   = kiBeraterResultJSON as CKRecordValue?
        record["gegner_profil"]       = gegnerProfilJSON as CKRecordValue?
        record["notes"]               = notes as CKRecordValue?
        record["folder_id"]           = folderId as CKRecordValue?
        record["mandant_name"]        = mandantName as CKRecordValue?
        record["created_by"]          = createdBy as CKRecordValue?
        return record
    }
}
