//
//  JudgeProfile.swift
//  Profil eines Richters, Anwalts oder einer Kanzlei.
//  Entspricht BASE44-Entität "JudgeProfile".
//

import Foundation
import CloudKit

public enum JudgeKategorie: String, Codable, CaseIterable, Hashable {
    case richter            = "Richter"
    case anwalt             = "Anwalt"
    case kanzlei            = "Kanzlei"
    case zeuge              = "Zeuge"
    case sachverstaendiger  = "Sachverständiger"
    case partei             = "Partei"
    case sonstiges          = "Sonstiges"
}

public enum VerhandlungsStil: String, Codable, CaseIterable, Hashable {
    case kooperativ              = "Kooperativ"
    case streng                  = "Streng"
    case neutral                 = "Neutral"
    case prozessaktiv            = "Prozessaktiv"
    case vergleichsorientiert    = "Vergleichsorientiert"
}

public struct JudgeProfile: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var name: String
    public var kategorie: JudgeKategorie = .richter
    public var gericht: String
    public var kammer: String?
    public var rechtsgebiet: String?
    public var klaegerRate: Double?
    public var vergleichRate: Double?
    public var durchschnittDauerMonate: Double?
    public var urteileGesamt: Double?
    public var stil: VerhandlungsStil?
    public var bekanntFuer: String?
    public var schwerpunkte: [String] = []
    public var notizen: String?
    /// JSON-String-Repräsentation komplexer Strukturen.
    public var erfahrungenJSON: String?
    public var kiAnalyseJSON: String?
    public var erfolgsMatrixJSON: String?
    public var beziehungsanalyseJSON: String?

    public init(name: String, gericht: String) {
        self.name = name
        self.gericht = gericht
    }
}

public extension JudgeProfile {
    static let recordType = "JudgeProfile"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.name          = record["name"] as? String ?? ""
        self.kategorie     = JudgeKategorie(rawValue: record["kategorie"] as? String ?? "Richter") ?? .richter
        self.gericht       = record["gericht"] as? String ?? ""
        self.kammer        = record["kammer"] as? String
        self.rechtsgebiet  = record["rechtsgebiet"] as? String
        self.klaegerRate   = record["klaeger_rate"] as? Double
        self.vergleichRate = record["vergleich_rate"] as? Double
        self.durchschnittDauerMonate = record["durchschnitt_dauer_monate"] as? Double
        self.urteileGesamt = record["urteile_gesamt"] as? Double
        if let s = record["stil"] as? String { self.stil = VerhandlungsStil(rawValue: s) }
        self.bekanntFuer   = record["bekannt_fuer"] as? String
        self.schwerpunkte  = record["schwerpunkte"] as? [String] ?? []
        self.notizen       = record["notizen"] as? String
        self.erfahrungenJSON = record["erfahrungen"] as? String
        self.kiAnalyseJSON   = record["ki_analyse"] as? String
        self.erfolgsMatrixJSON = record["erfolgs_matrix"] as? String
        self.beziehungsanalyseJSON = record["beziehungsanalyse"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["name"]          = name as CKRecordValue
        r["kategorie"]     = kategorie.rawValue as CKRecordValue
        r["gericht"]       = gericht as CKRecordValue
        r["kammer"]        = kammer as CKRecordValue?
        r["rechtsgebiet"]  = rechtsgebiet as CKRecordValue?
        r["klaeger_rate"]  = klaegerRate as CKRecordValue?
        r["vergleich_rate"] = vergleichRate as CKRecordValue?
        r["durchschnitt_dauer_monate"] = durchschnittDauerMonate as CKRecordValue?
        r["urteile_gesamt"] = urteileGesamt as CKRecordValue?
        r["stil"]          = stil?.rawValue as CKRecordValue?
        r["bekannt_fuer"]  = bekanntFuer as CKRecordValue?
        r["schwerpunkte"]  = schwerpunkte as CKRecordValue
        r["notizen"]       = notizen as CKRecordValue?
        r["erfahrungen"]   = erfahrungenJSON as CKRecordValue?
        r["ki_analyse"]    = kiAnalyseJSON as CKRecordValue?
        r["erfolgs_matrix"] = erfolgsMatrixJSON as CKRecordValue?
        r["beziehungsanalyse"] = beziehungsanalyseJSON as CKRecordValue?
        return r
    }
}
