//
//  StrategosScenario.swift
//  Strategos-Szenario: Vertragsanalyse + Optionen + KI-Analyse.
//  Komplexe verschachtelte Daten werden als JSON-Strings serialisiert,
//  damit sie 1:1 in CloudKit gespeichert werden können.
//

import Foundation
import CloudKit

public enum SzenarioTyp: String, Codable, CaseIterable, Hashable {
    case fusionUebernahme   = "fusion_uebernahme"
    case patentverletzung   = "patentverletzung"
    case steueroptimierung  = "steueroptimierung"
    case complianceRisiko   = "compliance_risiko"
    case kartellrecht       = "kartellrecht"
    case arbeitsrecht       = "arbeitsrecht"
    case strafrecht         = "strafrecht"
    case vertragsbruch      = "vertragsbruch"
    case insolvenz          = "insolvenz"
    case markenrecht        = "markenrecht"
    case datenschutz        = "datenschutz"
    case sonstiges          = "sonstiges"

    public var label: String {
        switch self {
        case .fusionUebernahme:  return "Fusion / Übernahme"
        case .patentverletzung:  return "Patentverletzung"
        case .steueroptimierung: return "Steueroptimierung"
        case .complianceRisiko:  return "Compliance-Risiko"
        case .kartellrecht:      return "Kartellrecht"
        case .arbeitsrecht:      return "Arbeitsrecht"
        case .strafrecht:        return "Strafrecht"
        case .vertragsbruch:     return "Vertragsbruch"
        case .insolvenz:         return "Insolvenz"
        case .markenrecht:       return "Markenrecht"
        case .datenschutz:       return "Datenschutz"
        case .sonstiges:         return "Sonstiges"
        }
    }
}

public enum SzenarioStatus: String, Codable, CaseIterable, Hashable {
    case entwurf
    case analyse
    case ergebnis
    case archiviert
}

public struct StrategosScenario: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var title: String
    public var rechtsgebiet: String?
    public var szenarioTyp: SzenarioTyp = .sonstiges
    public var status: SzenarioStatus = .entwurf
    public var ausgangslage: String?
    public var fragestellung: String?
    /// Komplexe Optionen-Strukturen als JSON.
    public var optionAJSON: String?
    public var optionBJSON: String?
    public var optionCJSON: String?
    public var kiAnalyseJSON: String?
    public var gesetzesluecken: [String] = []
    public var finanzdatenJSON: String?
    public var empfehlung: String?
    public var notes: String?
    public var stepCompleted: Int = 1
    public var enterpriseStep: Int = 1
    public var unternehmenskontextJSON: String?
    public var situationsanalyseJSON: String?
    public var szenarioMatrixJSON: String?
    public var aktionsplanJSON: String?
    public var strategosEmpfehlungJSON: String?
    public var lexaraSyncJSON: String?

    public init(title: String) {
        self.title = title
    }
}

public extension StrategosScenario {
    static let recordType = "StrategosScenario"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.title         = record["title"] as? String ?? ""
        self.rechtsgebiet  = record["rechtsgebiet"] as? String
        self.szenarioTyp   = SzenarioTyp(rawValue: record["szenario_typ"] as? String ?? "sonstiges") ?? .sonstiges
        self.status        = SzenarioStatus(rawValue: record["status"] as? String ?? "entwurf") ?? .entwurf
        self.ausgangslage  = record["ausgangslage"] as? String
        self.fragestellung = record["fragestellung"] as? String
        self.optionAJSON   = record["option_a"] as? String
        self.optionBJSON   = record["option_b"] as? String
        self.optionCJSON   = record["option_c"] as? String
        self.kiAnalyseJSON = record["ki_analyse"] as? String
        self.gesetzesluecken = record["gesetzesluecken"] as? [String] ?? []
        self.finanzdatenJSON = record["finanzdaten"] as? String
        self.empfehlung    = record["empfehlung"] as? String
        self.notes         = record["notes"] as? String
        self.stepCompleted = record["step_completed"] as? Int ?? 1
        self.enterpriseStep = record["enterprise_step"] as? Int ?? 1
        self.unternehmenskontextJSON = record["unternehmenskontext"] as? String
        self.situationsanalyseJSON   = record["situationsanalyse"] as? String
        self.szenarioMatrixJSON      = record["szenario_matrix"] as? String
        self.aktionsplanJSON         = record["aktionsplan"] as? String
        self.strategosEmpfehlungJSON = record["strategos_empfehlung"] as? String
        self.lexaraSyncJSON          = record["lexara_sync"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["title"]          = title as CKRecordValue
        r["rechtsgebiet"]   = rechtsgebiet as CKRecordValue?
        r["szenario_typ"]   = szenarioTyp.rawValue as CKRecordValue
        r["status"]         = status.rawValue as CKRecordValue
        r["ausgangslage"]   = ausgangslage as CKRecordValue?
        r["fragestellung"]  = fragestellung as CKRecordValue?
        r["option_a"]       = optionAJSON as CKRecordValue?
        r["option_b"]       = optionBJSON as CKRecordValue?
        r["option_c"]       = optionCJSON as CKRecordValue?
        r["ki_analyse"]     = kiAnalyseJSON as CKRecordValue?
        r["gesetzesluecken"] = gesetzesluecken as CKRecordValue
        r["finanzdaten"]    = finanzdatenJSON as CKRecordValue?
        r["empfehlung"]     = empfehlung as CKRecordValue?
        r["notes"]          = notes as CKRecordValue?
        r["step_completed"] = stepCompleted as CKRecordValue
        r["enterprise_step"] = enterpriseStep as CKRecordValue
        r["unternehmenskontext"] = unternehmenskontextJSON as CKRecordValue?
        r["situationsanalyse"]   = situationsanalyseJSON as CKRecordValue?
        r["szenario_matrix"]     = szenarioMatrixJSON as CKRecordValue?
        r["aktionsplan"]         = aktionsplanJSON as CKRecordValue?
        r["strategos_empfehlung"] = strategosEmpfehlungJSON as CKRecordValue?
        r["lexara_sync"]    = lexaraSyncJSON as CKRecordValue?
        return r
    }
}

// MARK: - Hilfsstrukturen für Vertrags-Auswirkungsanalyse (Strategos UI)

/// Eine Auswirkung einer Vertragsklausel auf eine Abteilung in einem Zeithorizont.
public struct StrategosImpact: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var abteilung: String
    public var horizont: StrategosHorizont
    public var beschreibung: String
    public var schwere: Double  // 0..10
    public init(abteilung: String, horizont: StrategosHorizont, beschreibung: String, schwere: Double) {
        self.abteilung = abteilung
        self.horizont = horizont
        self.beschreibung = beschreibung
        self.schwere = schwere
    }
}

public enum StrategosHorizont: String, Codable, CaseIterable, Hashable {
    case kurz   = "Kurzfristig"
    case mittel = "Mittelfristig"
    case lang   = "Langfristig"
}
