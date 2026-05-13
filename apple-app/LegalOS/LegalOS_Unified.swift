// LegalOS – Gesamte App in einer Datei
// Automatisch konsolidiert aus 85 Swift-Quelldateien

import AppKit
import AuthenticationServices
import Charts
import CloudKit
import Combine
import CryptoKit
import EventKit
import Foundation
import PDFKit
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications


// MARK: - LegalOSApp.swift

@main
struct LegalOSApp: App {

    // Globale Services als StateObject – leben so lange wie die App.
    @StateObject private var auth        = AuthService()
    @StateObject private var cloudKit    = CloudKitService()
    @StateObject private var claude      = ClaudeAPIService()
    @StateObject private var kiProvider  = KIProvider()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(cloudKit)
                .environmentObject(claude)
                .environmentObject(kiProvider)
                .frame(minWidth: 1100, minHeight: 720)
                .task {
                    // Beim Start: Login-Status aus Keychain wiederherstellen
                    await auth.restoreSession()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            SettingsView()
                .environmentObject(auth)
                .environmentObject(claude)
        }
    }
}

/// Wurzel-View: entscheidet ob Login, Onboarding oder Haupt-Shell gezeigt wird.
struct RootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        Group {
            if auth.currentUser == nil {
                LoginView()
            } else if auth.currentUser?.onboardingDone == false {
                OnboardingView()
            } else {
                AppShell()
            }
        }
        .animation(.easeInOut, value: auth.currentUser?.id)
    }
}

// MARK: - Models/AIPerformanceFeedback.swift

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

// MARK: - Models/Argument.swift

public enum ArgumentSide: String, Codable, CaseIterable, Hashable {
    case eigen
    case gegner
}

public struct Argument: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var title: String
    public var argDescription: String?
    public var side: ArgumentSide = .eigen
    /// Manuelle Stärke 0-10.
    public var strength: Double?
    /// KI-Stärke 0-10.
    public var kiStrength: Double?
    public var kiReasoning: String?
    public var type: String?
    public var paragraphs: [String] = []
    public var evidenceIds: [String] = []
    public var isContradiction: Bool = false
    public var zeitpunkt: String?
    public var anmerkungen: String?

    public init(caseId: String, title: String) {
        self.caseId = caseId
        self.title = title
    }
}

public extension Argument {
    static let recordType = "Argument"

    init(record: CKRecord) {
        self.id              = record.recordID.recordName
        self.caseId          = record["case_id"] as? String ?? ""
        self.title           = record["title"] as? String ?? ""
        self.argDescription  = record["description"] as? String
        self.side            = ArgumentSide(rawValue: record["side"] as? String ?? "eigen") ?? .eigen
        self.strength        = record["strength"] as? Double
        self.kiStrength      = record["ki_strength"] as? Double
        self.kiReasoning     = record["ki_reasoning"] as? String
        self.type            = record["type"] as? String
        self.paragraphs      = record["paragraphs"] as? [String] ?? []
        self.evidenceIds     = record["evidence_ids"] as? [String] ?? []
        self.isContradiction = (record["is_contradiction"] as? Int ?? 0) == 1
        self.zeitpunkt       = record["zeitpunkt"] as? String
        self.anmerkungen     = record["anmerkungen"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]          = caseId as CKRecordValue
        r["title"]            = title as CKRecordValue
        r["description"]      = argDescription as CKRecordValue?
        r["side"]             = side.rawValue as CKRecordValue
        r["strength"]         = strength as CKRecordValue?
        r["ki_strength"]      = kiStrength as CKRecordValue?
        r["ki_reasoning"]     = kiReasoning as CKRecordValue?
        r["type"]             = type as CKRecordValue?
        r["paragraphs"]       = paragraphs as CKRecordValue
        r["evidence_ids"]     = evidenceIds as CKRecordValue
        r["is_contradiction"] = (isContradiction ? 1 : 0) as CKRecordValue
        r["zeitpunkt"]        = zeitpunkt as CKRecordValue?
        r["anmerkungen"]      = anmerkungen as CKRecordValue?
        return r
    }
}

// MARK: - Models/Case.swift

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

// MARK: - Models/CaseFolder.swift

public enum MandantTyp: String, Codable, CaseIterable, Hashable {
    case privatperson = "Privatperson"
    case unternehmen  = "Unternehmen"
    case behoerde     = "Behörde"
    case sonstiges    = "Sonstiges"
}

public struct CaseFolder: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var name: String
    public var color: String?
    public var mandantName: String?
    public var mandantEmail: String?
    public var mandantTyp: MandantTyp = .privatperson
    public var folderDescription: String?

    public init(name: String) { self.name = name }
}

public extension CaseFolder {
    static let recordType = "CaseFolder"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.name          = record["name"] as? String ?? ""
        self.color         = record["color"] as? String
        self.mandantName   = record["mandant_name"] as? String
        self.mandantEmail  = record["mandant_email"] as? String
        self.mandantTyp    = MandantTyp(rawValue: record["mandant_typ"] as? String ?? "Privatperson") ?? .privatperson
        self.folderDescription = record["description"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["name"]          = name as CKRecordValue
        r["color"]         = color as CKRecordValue?
        r["mandant_name"]  = mandantName as CKRecordValue?
        r["mandant_email"] = mandantEmail as CKRecordValue?
        r["mandant_typ"]   = mandantTyp.rawValue as CKRecordValue
        r["description"]   = folderDescription as CKRecordValue?
        return r
    }
}

// MARK: - Models/CaseHistory.swift

public enum CaseHistoryEntityType: String, Codable, CaseIterable, Hashable {
    case argument = "Argument"
    case evidence = "Evidence"
    case deadline = "Deadline"
    case person   = "Person"
    case document = "Document"
    case caseEnt  = "Case"
    case risk     = "Risk"
}

public enum CaseHistoryAction: String, Codable, CaseIterable, Hashable {
    case create
    case update
    case delete
}

public struct CaseHistory: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var entityType: CaseHistoryEntityType
    public var entityId: String?
    public var entityTitle: String?
    public var action: CaseHistoryAction
    public var fieldChanged: String?
    public var oldValue: String?
    public var newValue: String?
    public var summary: String?
    public var userEmail: String?
    public var timestamp: Date = Date()

    public init(caseId: String, entityType: CaseHistoryEntityType, action: CaseHistoryAction) {
        self.caseId = caseId
        self.entityType = entityType
        self.action = action
    }
}

public extension CaseHistory {
    static let recordType = "CaseHistory"

    init(record: CKRecord) {
        self.id            = record.recordID.recordName
        self.caseId        = record["case_id"] as? String ?? ""
        self.entityType    = CaseHistoryEntityType(rawValue: record["entity_type"] as? String ?? "Case") ?? .caseEnt
        self.entityId      = record["entity_id"] as? String
        self.entityTitle   = record["entity_title"] as? String
        self.action        = CaseHistoryAction(rawValue: record["action"] as? String ?? "update") ?? .update
        self.fieldChanged  = record["field_changed"] as? String
        self.oldValue      = record["old_value"] as? String
        self.newValue      = record["new_value"] as? String
        self.summary       = record["summary"] as? String
        self.userEmail     = record["user_email"] as? String
        self.timestamp     = record["timestamp"] as? Date ?? record.creationDate ?? Date()
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["entity_type"]  = entityType.rawValue as CKRecordValue
        r["entity_id"]    = entityId as CKRecordValue?
        r["entity_title"] = entityTitle as CKRecordValue?
        r["action"]       = action.rawValue as CKRecordValue
        r["field_changed"] = fieldChanged as CKRecordValue?
        r["old_value"]    = oldValue as CKRecordValue?
        r["new_value"]    = newValue as CKRecordValue?
        r["summary"]      = summary as CKRecordValue?
        r["user_email"]   = userEmail as CKRecordValue?
        r["timestamp"]    = timestamp as CKRecordValue
        return r
    }
}

// MARK: - Models/CaseQuestionnaire.swift

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

// MARK: - Models/CaseWarning.swift

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

// MARK: - Models/Deadline.swift

public enum DeadlineSide: String, Codable, CaseIterable, Hashable {
    case eigene = "Eigene"
    case gegner = "Gegner"
}

public enum DeadlineStatus: String, Codable, CaseIterable, Hashable {
    case offen
    case erledigt
    case versaeumt
}

public struct Deadline: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var title: String
    public var fristType: String?
    public var paragraph: String?
    public var dueDate: Date
    public var responsible: String?
    public var side: DeadlineSide = .eigene
    public var status: DeadlineStatus = .offen
    public var prognoseabzug: String?

    public init(caseId: String, title: String, dueDate: Date) {
        self.caseId = caseId
        self.title = title
        self.dueDate = dueDate
    }
}

public extension Deadline {
    static let recordType = "Deadline"

    init(record: CKRecord) {
        self.id           = record.recordID.recordName
        self.caseId       = record["case_id"] as? String ?? ""
        self.title        = record["title"] as? String ?? ""
        self.fristType    = record["frist_type"] as? String
        self.paragraph    = record["paragraph"] as? String
        self.dueDate      = record["due_date"] as? Date ?? Date()
        self.responsible  = record["responsible"] as? String
        self.side         = DeadlineSide(rawValue: record["side"] as? String ?? "Eigene") ?? .eigene
        self.status       = DeadlineStatus(rawValue: record["status"] as? String ?? "offen") ?? .offen
        self.prognoseabzug = record["prognoseabzug"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]       = caseId as CKRecordValue
        r["title"]         = title as CKRecordValue
        r["frist_type"]    = fristType as CKRecordValue?
        r["paragraph"]     = paragraph as CKRecordValue?
        r["due_date"]      = dueDate as CKRecordValue
        r["responsible"]   = responsible as CKRecordValue?
        r["side"]          = side.rawValue as CKRecordValue
        r["status"]        = status.rawValue as CKRecordValue
        r["prognoseabzug"] = prognoseabzug as CKRecordValue?
        return r
    }
}

// MARK: - Models/Document.swift

public struct LegalDocument: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var title: String
    public var fileUrl: String?
    public var fileType: String?
    public var docDescription: String?
    public var aiSummary: String?
    public var extractedArguments: [String] = []
    /// KI-Rohdaten als JSON-String.
    public var aiRawJSON: String?

    public init(caseId: String, title: String) {
        self.caseId = caseId
        self.title = title
    }
}

public extension LegalDocument {
    static let recordType = "Document"

    init(record: CKRecord) {
        self.id                 = record.recordID.recordName
        self.caseId             = record["case_id"] as? String ?? ""
        self.title              = record["title"] as? String ?? ""
        self.fileUrl            = record["file_url"] as? String
        self.fileType           = record["file_type"] as? String
        self.docDescription     = record["description"] as? String
        self.aiSummary          = record["ai_summary"] as? String
        self.extractedArguments = record["extracted_arguments"] as? [String] ?? []
        self.aiRawJSON          = record["ai_raw"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]             = caseId as CKRecordValue
        r["title"]               = title as CKRecordValue
        r["file_url"]            = fileUrl as CKRecordValue?
        r["file_type"]           = fileType as CKRecordValue?
        r["description"]         = docDescription as CKRecordValue?
        r["ai_summary"]          = aiSummary as CKRecordValue?
        r["extracted_arguments"] = extractedArguments as CKRecordValue
        r["ai_raw"]              = aiRawJSON as CKRecordValue?
        return r
    }
}

// MARK: - Models/Evidence.swift

public struct Evidence: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var argumentId: String?
    public var title: String
    public var evidenceDescription: String?
    public var weight: Double?
    public var kiWeight: Double?
    public var kiReasoning: String?
    public var type: String?
    public var source: String?
    public var datum: String?

    public init(caseId: String, title: String) {
        self.caseId = caseId
        self.title = title
    }
}

public extension Evidence {
    static let recordType = "Evidence"

    init(record: CKRecord) {
        self.id                  = record.recordID.recordName
        self.caseId              = record["case_id"] as? String ?? ""
        self.argumentId          = record["argument_id"] as? String
        self.title               = record["title"] as? String ?? ""
        self.evidenceDescription = record["description"] as? String
        self.weight              = record["weight"] as? Double
        self.kiWeight            = record["ki_weight"] as? Double
        self.kiReasoning         = record["ki_reasoning"] as? String
        self.type                = record["type"] as? String
        self.source              = record["source"] as? String
        self.datum               = record["datum"] as? String
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["argument_id"]  = argumentId as CKRecordValue?
        r["title"]        = title as CKRecordValue
        r["description"]  = evidenceDescription as CKRecordValue?
        r["weight"]       = weight as CKRecordValue?
        r["ki_weight"]    = kiWeight as CKRecordValue?
        r["ki_reasoning"] = kiReasoning as CKRecordValue?
        r["type"]         = type as CKRecordValue?
        r["source"]       = source as CKRecordValue?
        r["datum"]        = datum as CKRecordValue?
        return r
    }
}

// MARK: - Models/GegnerVerhalten.swift

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

// MARK: - Models/JudgeProfile.swift

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

// MARK: - Models/JurisdictionInsight.swift

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

// MARK: - Models/KIUsageLog.swift

public struct KIUsageLog: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String?
    public var kiFunction: String
    public var inputSummary: String?
    public var output: String
    public var model: String?
    public var context: String?
    public var rating: Double?
    public var feedback: String?
    public var isDuplicate: Bool = false
    public var parentLogId: String?
    public var timestamp: Date = Date()

    public init(kiFunction: String, output: String) {
        self.kiFunction = kiFunction
        self.output = output
    }
}

public extension KIUsageLog {
    static let recordType = "KIUsageLog"

    init(record: CKRecord) {
        self.id           = record.recordID.recordName
        self.caseId       = record["case_id"] as? String
        self.kiFunction   = record["ki_function"] as? String ?? ""
        self.inputSummary = record["input_summary"] as? String
        self.output       = record["output"] as? String ?? ""
        self.model        = record["model"] as? String
        self.context      = record["context"] as? String
        self.rating       = record["rating"] as? Double
        self.feedback     = record["feedback"] as? String
        self.isDuplicate  = (record["is_duplicate"] as? Int ?? 0) == 1
        self.parentLogId  = record["parent_log_id"] as? String
        self.timestamp    = record["timestamp"] as? Date ?? record.creationDate ?? Date()
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]       = caseId as CKRecordValue?
        r["ki_function"]   = kiFunction as CKRecordValue
        r["input_summary"] = inputSummary as CKRecordValue?
        r["output"]        = output as CKRecordValue
        r["model"]         = model as CKRecordValue?
        r["context"]       = context as CKRecordValue?
        r["rating"]        = rating as CKRecordValue?
        r["feedback"]      = feedback as CKRecordValue?
        r["is_duplicate"]  = (isDuplicate ? 1 : 0) as CKRecordValue
        r["parent_log_id"] = parentLogId as CKRecordValue?
        r["timestamp"]     = timestamp as CKRecordValue
        return r
    }
}

// MARK: - Models/LegalLoophole.swift

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

// MARK: - Models/Person.swift

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

// MARK: - Models/StrategosScenario.swift

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

// MARK: - Models/Task.swift

public enum TaskPriority: String, Codable, CaseIterable, Hashable {
    case hoch
    case mittel
    case niedrig
}

public enum TaskStatus: String, Codable, CaseIterable, Hashable {
    case offen
    case inBearbeitung = "in_bearbeitung"
    case erledigt
}

public struct LegalTask: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String?
    public var caseName: String?
    public var title: String
    public var notes: String?
    public var assignee: String?
    public var dueDate: Date?
    public var priority: TaskPriority = .mittel
    public var status: TaskStatus = .offen

    public init(title: String) {
        self.title = title
    }
}

public extension LegalTask {
    static let recordType = "Task"

    init(record: CKRecord) {
        self.id        = record.recordID.recordName
        self.caseId    = record["case_id"] as? String
        self.caseName  = record["case_name"] as? String
        self.title     = record["title"] as? String ?? ""
        self.notes     = record["notes"] as? String
        self.assignee  = record["assignee"] as? String
        self.dueDate   = record["due_date"] as? Date
        self.priority  = TaskPriority(rawValue: record["priority"] as? String ?? "mittel") ?? .mittel
        self.status    = TaskStatus(rawValue: record["status"] as? String ?? "offen") ?? .offen
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]   = caseId as CKRecordValue?
        r["case_name"] = caseName as CKRecordValue?
        r["title"]     = title as CKRecordValue
        r["notes"]     = notes as CKRecordValue?
        r["assignee"]  = assignee as CKRecordValue?
        r["due_date"]  = dueDate as CKRecordValue?
        r["priority"]  = priority.rawValue as CKRecordValue
        r["status"]    = status.rawValue as CKRecordValue
        return r
    }
}

// MARK: - Models/TimelineEvent.swift

public enum TimelineCategory: String, Codable, CaseIterable, Hashable {
    case vertrag
    case zahlung
    case klage
    case urteil
    case frist
    case verhandlung
    case gutachten
    case korrespondenz
    case sonstiges
}

public enum TimelineImportance: String, Codable, CaseIterable, Hashable {
    case kritisch
    case hoch
    case mittel
    case niedrig
}

public struct TimelineEvent: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var caseId: String
    public var date: Date
    public var title: String
    public var eventDescription: String?
    public var category: TimelineCategory = .sonstiges
    /// JSON-String: [{title, file_url, file_type}]
    public var documentsJSON: String?
    public var personsInvolved: [String] = []
    public var importance: TimelineImportance = .mittel
    public var kiGenerated: Bool = false

    public init(caseId: String, date: Date, title: String) {
        self.caseId = caseId
        self.date = date
        self.title = title
    }
}

public extension TimelineEvent {
    static let recordType = "TimelineEvent"

    init(record: CKRecord) {
        self.id              = record.recordID.recordName
        self.caseId          = record["case_id"] as? String ?? ""
        self.date            = record["date"] as? Date ?? Date()
        self.title           = record["title"] as? String ?? ""
        self.eventDescription = record["description"] as? String
        self.category        = TimelineCategory(rawValue: record["category"] as? String ?? "sonstiges") ?? .sonstiges
        self.documentsJSON   = record["documents"] as? String
        self.personsInvolved = record["persons_involved"] as? [String] ?? []
        self.importance      = TimelineImportance(rawValue: record["importance"] as? String ?? "mittel") ?? .mittel
        self.kiGenerated     = (record["ki_generated"] as? Int ?? 0) == 1
    }

    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: Self.recordType, recordID: .init(recordName: id))
        r["case_id"]      = caseId as CKRecordValue
        r["date"]         = date as CKRecordValue
        r["title"]        = title as CKRecordValue
        r["description"]  = eventDescription as CKRecordValue?
        r["category"]     = category.rawValue as CKRecordValue
        r["documents"]    = documentsJSON as CKRecordValue?
        r["persons_involved"] = personsInvolved as CKRecordValue
        r["importance"]   = importance.rawValue as CKRecordValue
        r["ki_generated"] = (kiGenerated ? 1 : 0) as CKRecordValue
        return r
    }
}

// MARK: - Models/User.swift

public enum UserRole: String, Codable, Hashable {
    case admin
    case user
}

public enum Jurisdiction: String, Codable, CaseIterable, Hashable {
    case dach          = "DACH"
    case us            = "US"
    case eu            = "EU"
    case international = "International"
}

public struct AppUser: Codable, Identifiable, Hashable {
    public var id: String = UUID().uuidString
    public var email: String
    /// SHA256(salt + password)
    public var passwordHash: String?
    /// Salt für lokales Passwort-Hashing.
    public var passwordSalt: String?
    /// Apple-Sub-ID, falls Sign in with Apple genutzt wurde.
    public var appleUserId: String?
    public var fullName: String?
    public var role: UserRole = .user
    public var language: String = "de"
    public var jurisdiction: Jurisdiction = .dach
    public var usState: String = ""
    public var disclaimerAccepted: Bool = false
    public var onboardingDone: Bool = false
    public var hasModuleAccess: Bool = false
    public var kiCredits: Int = 50
    public var createdAt: Date = Date()

    public init(email: String) {
        self.email = email
    }
}

public extension AppUser {
    static let recordType = "User"

    init(record: CKRecord) {
        self.id                 = record.recordID.recordName
        self.email              = record["email"] as? String ?? ""
        self.passwordHash       = record["password_hash"] as? String
        self.passwordSalt       = record["password_salt"] as? String
        self.appleUserId        = record["apple_user_id"] as? String
        self.fullName           = record["full_name"] as? String
        self.role               = UserRole(rawValue: record["role"] as? String ?? "user") ?? .user
        self.language           = record["language"] as? String ?? "de"
        self.jurisdiction       = Jurisdiction(rawValue: record["jurisdiction"] as? String ?? "DACH") ?? .dach
        self.usState            = record["us_state"] as? String ?? ""
        self.disclaimerAccepted = (record["disclaimer_accepted"] as? Int ?? 0) == 1
        self.onboardingDone     = (record["onboarding_done"] as? Int ?? 0) == 1
        self.hasModuleAccess    = (record["has_module_access"] as? Int ?? 0) == 1
        self.kiCredits          = record["ki_credits"] as? Int ?? 0
        self.createdAt          = record.creationDate ?? Date()
    }

    func toRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["email"]               = email as CKRecordValue
        record["password_hash"]       = passwordHash as CKRecordValue?
        record["password_salt"]       = passwordSalt as CKRecordValue?
        record["apple_user_id"]       = appleUserId as CKRecordValue?
        record["full_name"]           = fullName as CKRecordValue?
        record["role"]                = role.rawValue as CKRecordValue
        record["language"]            = language as CKRecordValue
        record["jurisdiction"]        = jurisdiction.rawValue as CKRecordValue
        record["us_state"]            = usState as CKRecordValue
        record["disclaimer_accepted"] = (disclaimerAccepted ? 1 : 0) as CKRecordValue
        record["onboarding_done"]     = (onboardingDone ? 1 : 0) as CKRecordValue
        record["has_module_access"]   = (hasModuleAccess ? 1 : 0) as CKRecordValue
        record["ki_credits"]          = kiCredits as CKRecordValue
        return record
    }
}

// MARK: - Services/AuthService.swift

@MainActor
public final class AuthService: NSObject, ObservableObject {

    @Published public private(set) var currentUser: AppUser?
    @Published public private(set) var isBusy: Bool = false
    @Published public var lastError: String?

    private let keychainAccount  = "de.legalos.session"
    private let keychainService  = "LegalOS"
    private let container        = CKContainer.default()

    public override init() {
        super.init()
    }

    // MARK: - Public API

    /// Versucht eine bestehende Session aus dem Keychain wiederherzustellen.
    public func restoreSession() async {
        guard let data = Keychain.read(service: keychainService, account: keychainAccount),
              let user = try? JSONDecoder().decode(AppUser.self, from: data) else { return }
        self.currentUser = user
        // Optional: aktuellen User-Stand aus CloudKit nachladen.
        await refreshUser(id: user.id)
    }

    /// Registriert einen neuen Nutzer und speichert ihn in CloudKit.
    public func register(email: String, password: String, fullName: String?) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let salt = Self.randomSalt()
            let hash = Self.hash(password: password, salt: salt)
            var user = AppUser(email: email.lowercased())
            user.fullName = fullName
            user.passwordSalt = salt
            user.passwordHash = hash

            let record = user.toRecord()
            let saved = try await container.publicCloudDatabase.save(record)
            let stored = AppUser(record: saved)
            self.currentUser = stored
            persist(user: stored)
        } catch {
            lastError = "Registrierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// Login per Email + Passwort.
    public func login(email: String, password: String) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let predicate = NSPredicate(format: "email == %@", email.lowercased())
            let query = CKQuery(recordType: AppUser.recordType, predicate: predicate)
            let (matches, _) = try await container.publicCloudDatabase.records(matching: query, resultsLimit: 1)
            guard let first = matches.first,
                  case .success(let record) = first.1 else {
                lastError = "Benutzer nicht gefunden."
                return
            }
            let user = AppUser(record: record)
            guard let salt = user.passwordSalt,
                  let hash = user.passwordHash,
                  Self.hash(password: password, salt: salt) == hash else {
                lastError = "Passwort falsch."
                return
            }
            self.currentUser = user
            persist(user: user)
        } catch {
            lastError = "Login fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// Logout & Keychain-Eintrag löschen.
    public func logout() {
        currentUser = nil
        Keychain.delete(service: keychainService, account: keychainAccount)
    }

    /// Aktualisiert ein User-Profil in CloudKit.
    public func updateProfile(_ updated: AppUser) async {
        do {
            let saved = try await container.publicCloudDatabase.save(updated.toRecord())
            let stored = AppUser(record: saved)
            self.currentUser = stored
            persist(user: stored)
        } catch {
            lastError = "Profil-Update fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// Markiert Onboarding als abgeschlossen.
    public func completeOnboarding(jurisdiction: Jurisdiction, disclaimerAccepted: Bool) async {
        guard var u = currentUser else { return }
        u.jurisdiction = jurisdiction
        u.disclaimerAccepted = disclaimerAccepted
        u.onboardingDone = true
        await updateProfile(u)
    }

    // MARK: - Sign in with Apple

    /// Verarbeitet das Resultat von `SignInWithAppleButton`.
    public func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let err):
            lastError = "Apple Sign-In abgebrochen: \(err.localizedDescription)"
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let appleId = credential.user
            let email   = credential.email ?? ""
            let name    = [credential.fullName?.givenName, credential.fullName?.familyName]
                            .compactMap { $0 }.joined(separator: " ")
            await loginOrCreateApple(appleUserId: appleId, email: email, fullName: name.isEmpty ? nil : name)
        }
    }

    private func loginOrCreateApple(appleUserId: String, email: String, fullName: String?) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let predicate = NSPredicate(format: "apple_user_id == %@", appleUserId)
            let query = CKQuery(recordType: AppUser.recordType, predicate: predicate)
            let (matches, _) = try await container.publicCloudDatabase.records(matching: query, resultsLimit: 1)
            if let first = matches.first, case .success(let record) = first.1 {
                let user = AppUser(record: record)
                self.currentUser = user
                persist(user: user)
                return
            }
            // Sonst: neuen User anlegen
            var user = AppUser(email: email)
            user.appleUserId = appleUserId
            user.fullName = fullName
            let saved = try await container.publicCloudDatabase.save(user.toRecord())
            let stored = AppUser(record: saved)
            self.currentUser = stored
            persist(user: stored)
        } catch {
            lastError = "Apple-Login fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func refreshUser(id: String) async {
        do {
            let record = try await container.publicCloudDatabase.record(for: .init(recordName: id))
            let user = AppUser(record: record)
            self.currentUser = user
        } catch {
            // Schweigend: User-Cache bleibt erhalten.
        }
    }

    private func persist(user: AppUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        Keychain.write(service: keychainService, account: keychainAccount, data: data)
    }

    // MARK: - Crypto

    private static func randomSalt(length: Int = 16) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes).base64EncodedString()
    }

    private static func hash(password: String, salt: String) -> String {
        let input = (salt + password).data(using: .utf8) ?? Data()
        let digest = SHA256.hash(data: input)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Keychain Wrapper

enum Keychain {
    static func write(service: String, account: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  account,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Services/ClaudeAPIService.swift

public enum ClaudeError: LocalizedError {
    case missingApiKey
    case http(Int, String)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:        return "Kein Anthropic API-Key hinterlegt."
        case .http(let c, let m):   return "HTTP \(c): \(m)"
        case .decoding(let m):      return "Antwort konnte nicht gelesen werden: \(m)"
        }
    }
}

@MainActor
public final class ClaudeAPIService: ObservableObject {

    public static let endpoint   = URL(string: "https://api.anthropic.com/v1/messages")!
    public static let defaultModel = "claude-sonnet-4-6"
    public static let anthropicVersion = "2023-06-01"

    public static let defaultSystem =
        "Du bist ein juristischer KI-Assistent für deutsche und US-Rechtsanwälte. " +
        "Antworte präzise, neutral und auf Basis bekannter Rechtsprechung. " +
        "Bei strukturierter Ausgabe lieferst du ausschließlich gültiges JSON."

    @Published public var lastError: String?
    @Published public var isBusy: Bool = false

    private let apiKeyDefaultsKey = "anthropic.apiKey"
    private let keychainService   = "LegalOS"
    private let keychainAccount   = "anthropic.apiKey"

    public init() {}

    // MARK: - API Key Verwaltung

    /// Lädt den API-Key – bevorzugt aus Keychain, sonst aus UserDefaults.
    public var apiKey: String? {
        get {
            if let data = Keychain.read(service: keychainService, account: keychainAccount),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return UserDefaults.standard.string(forKey: apiKeyDefaultsKey)
        }
    }

    public func setApiKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let data = trimmed.data(using: .utf8) {
            Keychain.write(service: keychainService, account: keychainAccount, data: data)
        }
        UserDefaults.standard.set(trimmed, forKey: apiKeyDefaultsKey)
    }

    public func clearApiKey() {
        Keychain.delete(service: keychainService, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: apiKeyDefaultsKey)
    }

    // MARK: - Calls

    /// Schickt einen Prompt an Claude und gibt den reinen Text der Antwort zurück.
    public func sendMessage(prompt: String,
                            system: String = ClaudeAPIService.defaultSystem,
                            model: String = ClaudeAPIService.defaultModel,
                            maxTokens: Int = 4096,
                            temperature: Double = 0.4) async throws -> String {
        let body: [String: Any] = [
            "model":      model,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "system":     system,
            "messages":   [["role": "user", "content": prompt]]
        ]
        let data = try await perform(body: body)
        return try extractText(data)
    }

    /// Wie `sendMessage`, fordert aber strukturiertes JSON gemäß `schema` zurück.
    /// Realisiert wird das via System-Prompt + Schema-Instruction (Claude unterstützt
    /// kein offizielles response_format, aber strict-JSON funktioniert zuverlässig).
    public func sendStructured(prompt: String,
                               schema: [String: Any],
                               system: String = ClaudeAPIService.defaultSystem,
                               model: String = ClaudeAPIService.defaultModel) async throws -> [String: Any] {
        let schemaJSON = (try? JSONSerialization.data(withJSONObject: schema, options: [.prettyPrinted])).flatMap {
            String(data: $0, encoding: .utf8)
        } ?? "{}"
        let augmentedSystem = system + """

        AUSGABE-FORMAT (PFLICHT):
        Antworte ausschließlich mit gültigem JSON, das exakt diesem Schema entspricht.
        Keine Fließtexte, keine Code-Fences, kein Kommentar.
        Schema:
        \(schemaJSON)
        """
        let body: [String: Any] = [
            "model":      model,
            "max_tokens": 4096,
            "temperature": 0.2,
            "system":     augmentedSystem,
            "messages":   [["role": "user", "content": prompt]]
        ]
        let data = try await perform(body: body)
        let raw = try extractText(data)
        // Code-Fences entfernen, falls vorhanden.
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = cleaned.data(using: .utf8),
              let object   = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw ClaudeError.decoding("Antwort war kein JSON-Objekt")
        }
        return object
    }

    // MARK: - Internal

    private func perform(body: [String: Any]) async throws -> Data {
        guard let key = apiKey, !key.isEmpty else { throw ClaudeError.missingApiKey }
        var req = URLRequest(url: Self.endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        isBusy = true
        defer { isBusy = false }

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "(keine Antwort)"
            throw ClaudeError.http(http.statusCode, msg)
        }
        return data
    }

    /// Extrahiert den ersten Text-Block aus der Claude-Antwort.
    private func extractText(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw ClaudeError.decoding("Ungültige Top-Level-Struktur")
        }
        let texts = content.compactMap { block -> String? in
            guard let type = block["type"] as? String, type == "text" else { return nil }
            return block["text"] as? String
        }
        guard let joined = texts.joined(separator: "\n").nilIfEmpty else {
            throw ClaudeError.decoding("Keine Text-Blöcke in Antwort.")
        }
        return joined
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Services/CloudKitService.swift

public protocol CKMappable: Identifiable {
    static var recordType: String { get }
    init(record: CKRecord)
    func toRecord() -> CKRecord
}

extension Case:                CKMappable {}
extension AppUser:             CKMappable {}
extension Person:              CKMappable {}
extension Argument:            CKMappable {}
extension Evidence:            CKMappable {}
extension Deadline:            CKMappable {}
extension LegalDocument:       CKMappable {}
extension JudgeProfile:        CKMappable {}
extension CaseHistory:         CKMappable {}
extension StrategosScenario:   CKMappable {}
extension LegalTask:           CKMappable {}
extension TimelineEvent:       CKMappable {}
extension LegalLoophole:       CKMappable {}
extension GegnerVerhalten:     CKMappable {}
extension CaseFolder:          CKMappable {}
extension CaseQuestionnaire:   CKMappable {}
extension CaseWarning:         CKMappable {}
extension KIUsageLog:          CKMappable {}
extension JurisdictionInsight: CKMappable {}
extension AIPerformanceFeedback: CKMappable {}

public enum CloudKitScope {
    case publicScope
    case privateScope
}

@MainActor
public final class CloudKitService: ObservableObject {

    public let container: CKContainer
    @Published public var lastError: String?

    public init(containerIdentifier: String? = nil) {
        if let id = containerIdentifier {
            self.container = CKContainer(identifier: id)
        } else {
            self.container = CKContainer.default()
        }
    }

    private func db(_ scope: CloudKitScope) -> CKDatabase {
        switch scope {
        case .publicScope:  return container.publicCloudDatabase
        case .privateScope: return container.privateCloudDatabase
        }
    }

    // MARK: - CRUD

    /// Speichert (Insert oder Update) eine Entität.
    @discardableResult
    public func save<T: CKMappable>(_ entity: T, scope: CloudKitScope = .privateScope) async throws -> T {
        let record = entity.toRecord()
        let saved  = try await db(scope).save(record)
        return T(record: saved)
    }

    /// Lädt alle Records eines Typs mit optionalem Predicate (default = alle).
    public func fetch<T: CKMappable>(_ type: T.Type,
                                     predicate: NSPredicate = NSPredicate(value: true),
                                     scope: CloudKitScope = .privateScope,
                                     limit: Int = 200) async throws -> [T] {
        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (matches, _) = try await db(scope).records(matching: query, resultsLimit: limit)
        return matches.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return T(record: record)
        }
    }

    /// Lädt eine einzelne Entität anhand ihrer ID.
    public func fetchOne<T: CKMappable>(_ type: T.Type, id: String, scope: CloudKitScope = .privateScope) async throws -> T? {
        let recordID = CKRecord.ID(recordName: id)
        do {
            let record = try await db(scope).record(for: recordID)
            return T(record: record)
        } catch {
            return nil
        }
    }

    /// Löscht eine Entität anhand ihrer ID.
    public func delete(recordID id: String, scope: CloudKitScope = .privateScope) async throws {
        try await db(scope).deleteRecord(withID: CKRecord.ID(recordName: id))
    }

    /// Convenience: alle Records eines Falls.
    public func fetchForCase<T: CKMappable>(_ type: T.Type,
                                            caseId: String,
                                            scope: CloudKitScope = .privateScope) async throws -> [T] {
        let predicate = NSPredicate(format: "case_id == %@", caseId)
        return try await fetch(type, predicate: predicate, scope: scope)
    }
}

// MARK: - Services/JurisdictionConfig.swift

public enum JurisdictionConfig {

    // MARK: - Jurisdiktions-Codes

    /// Identische Schlüssel wie in `JURISDICTIONS` (JS).
    public enum Jurisdiction: String, Codable, Hashable, CaseIterable, Sendable {
        case DE, AT, CH, LI, LU, SE, NO, DK, FI, US
    }

    // MARK: - Sprach-Codes für `getTByLanguage`

    public enum Language: String, Codable, Hashable, CaseIterable, Sendable {
        case DE, EN, FR
    }

    // MARK: - Meta-Strukturen

    /// Mehrsprachiger Name einer Jurisdiktion (DE/EN/FR).
    public struct LocalizedName: Codable, Hashable, Sendable {
        public let de: String
        public let en: String
        public let fr: String

        public init(de: String, en: String, fr: String) {
            self.de = de
            self.en = en
            self.fr = fr
        }
    }

    /// Meta-Daten zu einer Jurisdiktion (Flag, Name, Rechtssystem, Währung).
    public struct JurisdictionMeta: Codable, Hashable, Sendable {
        public let flag: String
        public let name: LocalizedName
        public let system: String
        public let currency: String

        public init(flag: String, name: LocalizedName, system: String, currency: String) {
            self.flag = flag
            self.name = name
            self.system = system
            self.currency = currency
        }
    }

    // MARK: - JURISDICTION_META

    /// 1:1-Übernahme von `JURISDICTION_META` aus dem JS-Modul.
    public static let meta: [Jurisdiction: JurisdictionMeta] = [
        .DE: JurisdictionMeta(
            flag: "🇩🇪",
            name: LocalizedName(de: "Deutschland", en: "Germany", fr: "Allemagne"),
            system: "ZPO / BGB / StPO",
            currency: "€"
        ),
        .AT: JurisdictionMeta(
            flag: "🇦🇹",
            name: LocalizedName(de: "Österreich", en: "Austria", fr: "Autriche"),
            system: "ZPO / ABGB / StPO",
            currency: "€"
        ),
        .CH: JurisdictionMeta(
            flag: "🇨🇭",
            name: LocalizedName(de: "Schweiz", en: "Switzerland", fr: "Suisse"),
            system: "ZPO / OR / ZGB",
            currency: "CHF"
        ),
        .LI: JurisdictionMeta(
            flag: "🇱🇮",
            name: LocalizedName(de: "Liechtenstein", en: "Liechtenstein", fr: "Liechtenstein"),
            system: "ZPO / PGR",
            currency: "CHF"
        ),
        .LU: JurisdictionMeta(
            flag: "🇱🇺",
            name: LocalizedName(de: "Luxemburg", en: "Luxembourg", fr: "Luxembourg"),
            system: "Code de procédure civile",
            currency: "€"
        ),
        .SE: JurisdictionMeta(
            flag: "🇸🇪",
            name: LocalizedName(de: "Schweden", en: "Sweden", fr: "Suède"),
            system: "Rättegångsbalken",
            currency: "SEK"
        ),
        .NO: JurisdictionMeta(
            flag: "🇳🇴",
            name: LocalizedName(de: "Norwegen", en: "Norway", fr: "Norvège"),
            system: "Tvisteloven",
            currency: "NOK"
        ),
        .DK: JurisdictionMeta(
            flag: "🇩🇰",
            name: LocalizedName(de: "Dänemark", en: "Denmark", fr: "Danemark"),
            system: "Retsplejeloven",
            currency: "DKK"
        ),
        .FI: JurisdictionMeta(
            flag: "🇫🇮",
            name: LocalizedName(de: "Finnland", en: "Finland", fr: "Finlande"),
            system: "Oikeudenkäymiskaari",
            currency: "€"
        ),
        .US: JurisdictionMeta(
            flag: "🇺🇸",
            name: LocalizedName(de: "USA", en: "United States", fr: "États-Unis"),
            system: "Common Law / FRCP",
            currency: "$"
        )
    ]

    // MARK: - AI-Kontext

    /// Liefert den (englischen) System-Prompt für die jeweilige Jurisdiktion.
    /// Für US wird optional der Bundesstaat in den Prompt eingewoben.
    public static func aiContext(for jurisdiction: Jurisdiction, usState: String? = nil) -> String {
        switch jurisdiction {
        case .DE:
            return "You are an expert German attorney. Apply German law strictly: ZPO, BGB, StGB, HGB. Reference specific paragraphs (§§). Follow BGH and BVerfG case law. Use precise German legal terminology."
        case .AT:
            return "You are an expert Austrian attorney. Apply Austrian law: ZPO, ABGB, StGB. Reference OGH decisions. Distinguish from German law where relevant. Use Austrian legal terminology."
        case .CH:
            return "You are an expert Swiss attorney. Apply Swiss law: ZPO, OR, ZGB, StGB. Reference BGer/Tribunal fédéral decisions. Note cantonal variations where relevant."
        case .LI:
            return "You are an expert Liechtenstein attorney. Apply Liechtenstein law including the PGR (Personen- und Gesellschaftsrecht). Note similarities to Austrian law."
        case .LU:
            return "You are an expert Luxembourg attorney. Apply Luxembourg law based on French civil law tradition. Reference Cour d'appel and Cour de cassation decisions. Note EU law primacy."
        case .SE:
            return "You are an expert Swedish attorney. Apply Swedish law under the Rättegångsbalken. Reference Högsta domstolen decisions. Note Nordic legal tradition."
        case .NO:
            return "You are an expert Norwegian attorney. Apply Norwegian law under the Tvisteloven. Reference Høyesterett decisions."
        case .DK:
            return "You are an expert Danish attorney. Apply Danish law under the Retsplejeloven. Reference Højesteret decisions."
        case .FI:
            return "You are an expert Finnish attorney. Apply Finnish law under the Oikeudenkäymiskaari. Reference Korkein oikeus decisions. Note bilingual (Finnish/Swedish) legal system."
        case .US:
            // Originale JS-Logik: Wenn ein US-Bundesstaat angegeben ist,
            // wird er an mehreren Stellen des Prompts eingesetzt.
            let stateSpec = usState.map { " specializing in \($0) law" } ?? ""
            let stateOrState = usState ?? "state"
            let rulesSpec = usState.map { "\($0) Rules of Civil Procedure, " } ?? ""
            return "You are an expert American attorney\(stateSpec). Apply US federal and \(stateOrState) law. Reference FRCP, applicable federal statutes, \(rulesSpec)and relevant case law. Use IRAC structure."
        }
    }

    /// String-API analog zur JS-Funktion: nicht-unterstützte Werte fallen auf DE zurück.
    public static func aiContext(jurisdictionCode: String, usState: String? = nil) -> String {
        let jur = Jurisdiction(rawValue: jurisdictionCode) ?? .DE
        return aiContext(for: jur, usState: usState)
    }

    // MARK: - UI-Texte

    /// Container für alle übersetzten UI-Strings einer Sprache.
    /// Felder spiegeln das JS-Objekt 1:1.
    public struct UITexts: Sendable {

        // -- Plattform
        public let platform: String
        public let platformSub: String
        public let copyright: String
        public let dsgvo: String

        // -- KI-Analyse
        public let kiFallanalyse: String
        public let analyseStarten: String
        public let analyseWarning: String
        public let fallAuswaehlen: String

        // -- KPI-Labels
        public let aktiveFaelleLabel: String
        public let offeeneFristenLabel: String
        public let avgPrognoseLabel: String
        public let argumenteLabel: String

        // -- Charts
        public let faelleNachRechtsgebiet: String
        public let statusVerteilung: String
        public let prognoseVerteilung: String
        public let fristenUebersicht: String
        public let naechste14Tage: String
        public let instanzVerteilung: String
        public let risikoverteilung: String
        public let rechtsgebiet: String
        public let gericht: String
        public let instanz: String
        public let aktiv: String
        public let streitwert: String
        public let prognose: String

        // -- Allgemein
        public let noDataLabel: String
        public let noDeadlinesRecorded: String
        public let noUpcomingDeadlines: String
        public let loading: String
        public let saveBtn: String
        public let cancelBtn: String
        public let updateBtn: String
        public let createBtn: String
        public let backLabel: String
        public let searchPlaceholder: String
        public let todayLabel: String
        public let tomorrowLabel: String

        /// Funktional: `(n) => "${n}d überfällig"` etc.
        public let daysOverdueLabel: @Sendable (Int) -> String
        public let inDaysLabel: @Sendable (Int) -> String

        // -- Geteilte Subtitle-Helpers
        public let mandatesSub: @Sendable (Int, Int) -> String
        public let ofTotalLabel: @Sendable (Int) -> String
        public let winProbabilityLabel: String
        public let totalRecordedLabel: String
        public let filterResetBtn: String
        public let noDataShort: String
        public let noDeadlinesShort: String
        public let todayShort: String
        public let noUpcomingShort: String

        // -- FallAssistentChat
        public let conversationLabel: String
        public let lexTitle: String
        public let lexDescription: String
        public let newConversationBtn: String
        public let loadingLabel: String
        public let noConversationsYet: String
        public let chatInputPlaceholder: String
        public let quickPrompts: [String]

        // -- LexaraDashboard
        public let caseOverview: String
        public let mandatesTotalSub: @Sendable (Int, Int) -> String
        public let searchCase: String
        public let newCase: String
        public let createCaseTitle: String
        public let caseNamePlaceholder: String
        public let fileNumberPlaceholder: String
        public let legalAreaPlaceholder: String
        public let createButton: String
        public let progressLabel: String
        public let stepsLabel: String
        public let argsLabel: String
        public let evidenceLabel: String
        public let personsLabel: String
        public let deadlinesLabel: String
        public let noCasesTitle: String
        public let noCasesSubtitle: String
        public let statusOptions: [String]
        public let instanzOptions: [String]

        // -- KanzleiCockpit
        public let cockpitTitle: String
        public let portfolioSub: @Sendable (Int) -> String
        public let newCaseLinkLabel: String
        public let totalClaimLabel: String
        public let allMandatesSub: String
        public let avgPrognosisLabel: String
        public let weightedAvgSub: String
        public let overdueDeadlinesLabel: String
        public let actNow: String
        public let allOnTrack: String
        public let highRiskLabel: String
        public let noHighRisk: String
        public let topChancesLabel: String
        public let noTopChancesText: String
        public let nextDeadlinesLabel: String
        public let showAllLink: String
        public let noOpenDeadlinesText: String
        public let allMandatesLabel: String
        public let entriesLabel: @Sendable (Int) -> String
        public let tableHeaderCase: String
        public let tableHeaderCourt: String
        public let tableHeaderClaimValue: String
        public let tableHeaderStatus: String
        public let casesLabelShort: String

        // -- RichterProfile
        public let judgeProfilesTitle: String
        public let profilesSub: @Sendable (Int) -> String
        public let addJudgeBtn: String
        public let editProfileTitle: String
        public let newProfileTitle: String
        public let namePlaceholder: String
        public let courtPlaceholder: String
        public let chamberPlaceholder: String
        public let plaintiffRateLabel: String
        public let settlementRateLabel: String
        public let avgDurationLabel: String
        public let totalRulingsLabel: String
        public let knownForPlaceholder: String
        public let notesPlaceholder: String
        public let linkToCase: String
        public let selectCasePlaceholder: String
        public let detailsAI: String
        public let noProfilesTitle: String
        public let noProfilesSub: String
        public let plaintiffRateBar: String
        public let settlementRateBar: String
        public let avgMonthsSuffix: String
        public let rulingsLabelShort: String
        public let experiencesLabelShort: String
        public let kiAnalysisExists: String

        // -- RichterDetail
        public let backToOverview: String
        public let experiencesSection: String
        public let addExperience: String
        public let dateLabel: String
        public let authorLabel: String
        public let caseContextLabel: String
        public let settlementReadiness: String
        public let decisionSpeed: String
        public let expertiseLabel: String
        public let experienceReport: String
        public let noExperiencesYet: String
        public let addFirstExperience: String
        public let kiTacticsTitle: String
        public let reanalyzeBtn: String
        public let startAnalysisBtn: String
        public let analyzingBtn: String
        public let kiAnalysisHint: String
        public let lastAnalysis: String
        public let kiCreditWarning: String
        public let summaryLabel: String
        public let foundRulingsLabel: String
        public let argumentationPatternsLabel: String
        public let preferredNormsLabel: String
        public let argumentStanceLabel: String
        public let preferredMotionsLabel: String
        public let damageRangeLabel: String
        public let evidenceHandlingLabel: String
        public let plaintiffStrengthsLabel: String
        public let plaintiffRisksLabel: String
        public let doLabel: String
        public let dontLabel: String
        public let tacticalTipsLabel: String
        public let settlementStrategyLabel: String
        public let timingLabel: String
        public let overallAssessmentLabel: String
        public let anonLabel: String
        public let settlementBar: String
        public let speedBar: String
        public let resultLabel: String
        public let sourceLabel: String
        public let parametersLabel: String
        public let successRateLabel: String
        public let typicalRangeLabel: String
        public let factorsLabel: String
        public let specialFeaturesLabel: String
        public let stanceLabel: String
        public let reasonLabel: String

        // -- Zeitleiste
        public let timelineTitle: String
        public let iCalExport: String
        public let filterAll: String
        public let filterOpen: String
        public let filterCritical: String
        public let filterCompleted: String
        public let noDeadlinesFound: String
        public let openStatusLabel: String
        public let criticalStatusLabel: String
        public let doneStatus: String
        public let missedStatus: String

        // -- PlattformAgent
        public let newSession: String
        public let sessionsLabel: String
        public let noSessionsYet: String
        public let platformAgentTitle: String
        public let platformAgentDesc: String
        public let nextTaskPlaceholder: String
        public let customTaskPlaceholder: String
        public let agentNote: String

        // -- Module-Liste
        public struct ModuleEntry: Codable, Hashable, Sendable {
            public let category: String
            public let title: String
            public let description: String
            public init(category: String, title: String, description: String) {
                self.category = category
                self.title = title
                self.description = description
            }
        }
        public let module: [ModuleEntry]
    }

    // MARK: - Texte: Deutsch

    public static let deText: UITexts = UITexts(
        platform: "Ihre KI-gestützte Rechtsplattform",
        platformSub: "Strategische Fallanalyse & Intelligente Prozessführung",
        copyright: "© 2026 MachiavelLEX · Alle Rechte vorbehalten",
        dsgvo: "DSGVO-konform · EU-Server",

        kiFallanalyse: "KI-Fallanalyse",
        analyseStarten: "KI-Analyse starten",
        analyseWarning: "Diese Analyse ist eine KI-gestützte Einschätzung und ersetzt keine Rechtsberatung.",
        fallAuswaehlen: "Fall auswählen",

        aktiveFaelleLabel: "Aktive Fälle",
        offeeneFristenLabel: "Offene Fristen",
        avgPrognoseLabel: "Ø Prognose",
        argumenteLabel: "Argumente",

        faelleNachRechtsgebiet: "Fälle nach Rechtsgebiet",
        statusVerteilung: "Status-Verteilung",
        prognoseVerteilung: "Prognose-Verteilung",
        fristenUebersicht: "Fristen-Übersicht",
        naechste14Tage: "Nächste 14 Tage",
        instanzVerteilung: "Instanz-Verteilung",
        risikoverteilung: "Risikoverteilung",
        rechtsgebiet: "Rechtsgebiet",
        gericht: "Gericht",
        instanz: "Instanz",
        aktiv: "Status",
        streitwert: "Streitwert",
        prognose: "Prognose",

        noDataLabel: "Keine Daten",
        noDeadlinesRecorded: "Keine Fristen erfasst",
        noUpcomingDeadlines: "Keine bevorstehenden Fristen",
        loading: "Laden…",
        saveBtn: "Speichern",
        cancelBtn: "Abbrechen",
        updateBtn: "Aktualisieren",
        createBtn: "Erstellen",
        backLabel: "Zurück",
        searchPlaceholder: "Suchen…",
        todayLabel: "Heute",
        tomorrowLabel: "Morgen",
        daysOverdueLabel: { n in "\(n)d überfällig" },
        inDaysLabel: { n in "in \(n) Tagen" },

        mandatesSub: { total, active in "\(total) Mandate · \(active) aktiv" },
        ofTotalLabel: { n in "von \(n) gesamt" },
        winProbabilityLabel: "Erfolgswahrscheinlichkeit",
        totalRecordedLabel: "gesamt erfasst",
        filterResetBtn: "Zurücksetzen",
        noDataShort: "Keine Daten",
        noDeadlinesShort: "Keine Fristen erfasst",
        todayShort: "Heute",
        noUpcomingShort: "Keine bevorstehenden Fristen",

        conversationLabel: "Gespräch",
        lexTitle: "Lex · Fall-Assistent",
        lexDescription: "Ich kann Fälle analysieren, Fristen überwachen, Argumente verwalten und strategische Empfehlungen geben.",
        newConversationBtn: "Neues Gespräch",
        loadingLabel: "Lädt…",
        noConversationsYet: "Noch keine Gespräche",
        chatInputPlaceholder: "Juristische Frage stellen oder Fall-Daten verwalten…",
        quickPrompts: [
            "Zeige mir alle offenen Fristen",
            "Analysiere meinen stärksten Fall",
            "Welche Argumente fehlen noch?",
            "Gib mir eine Risikoübersicht"
        ],

        caseOverview: "Fallübersicht",
        mandatesTotalSub: { total, active in "\(total) Mandate · \(active) aktiv" },
        searchCase: "Fall suchen…",
        newCase: "Neuer Fall",
        createCaseTitle: "Neuen Fall anlegen",
        caseNamePlaceholder: "Fallname *",
        fileNumberPlaceholder: "Aktenzeichen",
        legalAreaPlaceholder: "Rechtsgebiet",
        createButton: "Fall erstellen",
        progressLabel: "Fortschritt",
        stepsLabel: "Schritte",
        argsLabel: "Args",
        evidenceLabel: "Beweise",
        personsLabel: "Personen",
        deadlinesLabel: "Fristen",
        noCasesTitle: "Noch keine Fälle",
        noCasesSubtitle: "Klicke auf „Neuer Fall“ um zu beginnen",
        statusOptions: ["Aktiv", "Vorbereitung", "Abgeschlossen", "Ruhend"],
        instanzOptions: ["Erstinstanz", "Berufung", "Revision"],

        cockpitTitle: "Kanzlei-Cockpit",
        portfolioSub: { n in "Portfolio-Übersicht · \(n) Mandate" },
        newCaseLinkLabel: "+ Neuer Fall",
        totalClaimLabel: "Gesamtstreitwert",
        allMandatesSub: "alle Mandate",
        avgPrognosisLabel: "Ø Erfolgsprognose",
        weightedAvgSub: "gewichteter Durchschnitt",
        overdueDeadlinesLabel: "überfällig",
        actNow: "Sofort handeln",
        allOnTrack: "Alles im Plan",
        highRiskLabel: "Hochrisiko-Fälle (aktiv)",
        noHighRisk: "Keine Hochrisiko-Fälle aktiv ✓",
        topChancesLabel: "Top-Chancen (aktiv)",
        noTopChancesText: "Noch keine Fälle mit hoher Prognose",
        nextDeadlinesLabel: "Nächste Fristen",
        showAllLink: "Alle anzeigen →",
        noOpenDeadlinesText: "Keine offenen Fristen ✓",
        allMandatesLabel: "Alle Mandate",
        entriesLabel: { n in "\(n) Einträge" },
        tableHeaderCase: "Fall",
        tableHeaderCourt: "Gericht",
        tableHeaderClaimValue: "Streitwert",
        tableHeaderStatus: "Status",
        casesLabelShort: "Fälle",

        judgeProfilesTitle: "Richterprofile",
        profilesSub: { n in "\(n) Profile · Erfahrungen & KI-Taktikanalyse" },
        addJudgeBtn: "+ Richter",
        editProfileTitle: "Profil bearbeiten",
        newProfileTitle: "Neues Richterprofil",
        namePlaceholder: "Name *",
        courtPlaceholder: "Gericht *",
        chamberPlaceholder: "Kammer / Senat",
        plaintiffRateLabel: "Klägerquote %",
        settlementRateLabel: "Vergleichsrate %",
        avgDurationLabel: "Ø Dauer (Mo.)",
        totalRulingsLabel: "Urteile gesamt",
        knownForPlaceholder: "Bekannt für...",
        notesPlaceholder: "Notizen",
        linkToCase: "Mit Fall verknüpfen",
        selectCasePlaceholder: "Fall auswählen...",
        detailsAI: "Details & KI",
        noProfilesTitle: "Noch keine Richterprofile",
        noProfilesSub: "Klicken Sie auf \"+ Richter\" um ein Profil anzulegen",
        plaintiffRateBar: "Klägerquote",
        settlementRateBar: "Vergleichsrate",
        avgMonthsSuffix: "Mo. Ø",
        rulingsLabelShort: "Urteile",
        experiencesLabelShort: "Erfahrungen",
        kiAnalysisExists: "✓ KI-Analyse vorhanden",

        backToOverview: "Zurück zur Übersicht",
        experiencesSection: "Kanzlei-Erfahrungen",
        addExperience: "Erfahrung",
        dateLabel: "Datum",
        authorLabel: "Autor / Anwalt",
        caseContextLabel: "Fallkontext (optional)",
        settlementReadiness: "Vergleichsbereitschaft",
        decisionSpeed: "Entscheidungsgeschwindigkeit",
        expertiseLabel: "Sachkompetenz",
        experienceReport: "Erfahrungsbericht *",
        noExperiencesYet: "Noch keine Erfahrungen dokumentiert.",
        addFirstExperience: "Fügen Sie die erste Erfahrung hinzu.",
        kiTacticsTitle: "KI-Taktikanalyse",
        reanalyzeBtn: "Neu analysieren",
        startAnalysisBtn: "Analyse starten",
        analyzingBtn: "Analysiere...",
        kiAnalysisHint: "Starten Sie die KI-Analyse um taktische Empfehlungen auf Basis des Profils und der Kanzlei-Erfahrungen zu erhalten.",
        lastAnalysis: "Letzte Analyse",
        kiCreditWarning: "⚠️ Diese Analyse verwendet Gemini Pro mit Internetsuche (mehr KI-Credits)",
        summaryLabel: "📊 Zusammenfassung",
        foundRulingsLabel: "🔍 Gefundene Urteile & Entscheidungen",
        argumentationPatternsLabel: "🧠 Typische Argumentationsmuster",
        preferredNormsLabel: "§ Bevorzugte Rechtsnormen",
        argumentStanceLabel: "⚖️ Haltung zu Argumenttypen",
        preferredMotionsLabel: "📋 Bevorzugte Antragstypen",
        damageRangeLabel: "💶 Schadensersatz / Urteilsbandbreite",
        evidenceHandlingLabel: "📜 Umgang mit Beweismitteln",
        plaintiffStrengthsLabel: "✅ Stärken für Kläger",
        plaintiffRisksLabel: "⚠️ Risiken für Kläger",
        doLabel: "👍 DO",
        dontLabel: "👎 DON'T",
        tacticalTipsLabel: "💡 Verhandlungstipps",
        settlementStrategyLabel: "🤝 Vergleichsstrategie",
        timingLabel: "⏰ Timing",
        overallAssessmentLabel: "🎯 Gesamteinschätzung",
        anonLabel: "Anonym",
        settlementBar: "Vergleich",
        speedBar: "Geschwindigkeit",
        resultLabel: "Ergebnis",
        sourceLabel: "Quelle",
        parametersLabel: "Parameter",
        successRateLabel: "Erfolgsrate",
        typicalRangeLabel: "Typischer Bereich",
        factorsLabel: "Einflussfaktoren",
        specialFeaturesLabel: "Besonderheiten",
        stanceLabel: "Haltung",
        reasonLabel: "Begründung",

        timelineTitle: "Fristen-Zeitleiste",
        iCalExport: "iCal exportieren",
        filterAll: "Alle",
        filterOpen: "Offen",
        filterCritical: "⚠ Kritisch",
        filterCompleted: "Erledigt",
        noDeadlinesFound: "Keine Fristen gefunden",
        openStatusLabel: "offen",
        criticalStatusLabel: "kritisch (≤14 Tage)",
        doneStatus: "Erledigt",
        missedStatus: "Versäumt",

        newSession: "+ Neue Sitzung",
        sessionsLabel: "Sitzungen",
        noSessionsYet: "Noch keine Sitzungen",
        platformAgentTitle: "Plattform-Optimierer",
        platformAgentDesc: "Der KI-Agent analysiert Ihre Kanzleidaten, identifiziert Lücken und setzt Verbesserungen direkt um – bis MachiavelLEX für Großkanzleien unverzichtbar ist.",
        nextTaskPlaceholder: "Nächste Aufgabe für den Agenten…",
        customTaskPlaceholder: "Eigene Aufgabe eingeben…",
        agentNote: "Der Agent kann Richterprofile, Argumente und Fristen direkt erstellen & bearbeiten.",

        module: [
            UITexts.ModuleEntry(category: "KI-Assistent",            title: "Fall-Assistent Chat", description: "Konversationelle KI-Analyse Ihrer Mandate"),
            UITexts.ModuleEntry(category: "Mandatsverwaltung",       title: "Lexara Dashboard",    description: "Alle Fälle im Überblick – Fristen, Argumente, Beweise"),
            UITexts.ModuleEntry(category: "Personenprofile",         title: "Richterprofile",      description: "Erfahrungen, Statistiken & KI-Taktikanalyse"),
            UITexts.ModuleEntry(category: "KI-Agent",                title: "Plattform-Agent",     description: "Autonomer Agent für Plattformoptimierung und Analyse"),
            UITexts.ModuleEntry(category: "Cockpit",                 title: "Kanzlei-Cockpit",     description: "Risiko-Ampel, Portfolio und Fristen-Monitoring"),
            UITexts.ModuleEntry(category: "Analytics",               title: "Kanzlei-Analytik",    description: "Visualisierung aller Fallkennzahlen und Trends"),
            UITexts.ModuleEntry(category: "Strategie & Psycho-Analyse", title: "Sun Tzu × Machiavelli", description: "48 Laws of Power · Strategischer Pfad & Risikobewertung für Ihren Fall"),
            UITexts.ModuleEntry(category: "Szenario-Prognose",       title: "Strategos",           description: "Kosten-Nutzen-Szenarien, Gesetzeslücken-DB & strategische Prognosen")
        ]
    )

    // MARK: - Texte: Englisch

    public static let enText: UITexts = UITexts(
        platform: "Your AI-Powered Legal Platform",
        platformSub: "Strategic Case Analysis & Intelligent Litigation Management",
        copyright: "© 2026 MachiavelLEX · All rights reserved",
        dsgvo: "GDPR-compliant · EU Servers",

        kiFallanalyse: "AI Case Analysis",
        analyseStarten: "Start AI Analysis",
        analyseWarning: "This analysis is AI-assisted and does not constitute legal advice.",
        fallAuswaehlen: "Select case",

        aktiveFaelleLabel: "Active Cases",
        offeeneFristenLabel: "Open Deadlines",
        avgPrognoseLabel: "Avg. Prognosis",
        argumenteLabel: "Arguments",

        faelleNachRechtsgebiet: "Cases by Practice Area",
        statusVerteilung: "Status Distribution",
        prognoseVerteilung: "Prognosis Distribution",
        fristenUebersicht: "Deadline Overview",
        naechste14Tage: "Next 14 Days",
        instanzVerteilung: "Court Level Distribution",
        risikoverteilung: "Risk Distribution",
        rechtsgebiet: "Practice Area",
        gericht: "Court",
        instanz: "Court Level",
        aktiv: "Status",
        streitwert: "Amount in Controversy",
        prognose: "Win Probability",

        noDataLabel: "No data available",
        noDeadlinesRecorded: "No deadlines recorded",
        noUpcomingDeadlines: "No upcoming deadlines",
        loading: "Loading…",
        saveBtn: "Save",
        cancelBtn: "Cancel",
        updateBtn: "Update",
        createBtn: "Create",
        backLabel: "Back",
        searchPlaceholder: "Search…",
        todayLabel: "Today",
        tomorrowLabel: "Tomorrow",
        daysOverdueLabel: { n in "\(n)d overdue" },
        inDaysLabel: { n in "in \(n) days" },

        mandatesSub: { total, active in "\(total) matters · \(active) active" },
        ofTotalLabel: { n in "of \(n) total" },
        winProbabilityLabel: "Win Probability",
        totalRecordedLabel: "total recorded",
        filterResetBtn: "Reset",
        noDataShort: "No data",
        noDeadlinesShort: "No deadlines recorded",
        todayShort: "Today",
        noUpcomingShort: "No upcoming deadlines",

        conversationLabel: "Conversation",
        lexTitle: "Lex · Case Assistant",
        lexDescription: "I can analyze cases, monitor deadlines, manage arguments and provide strategic recommendations.",
        newConversationBtn: "New Conversation",
        loadingLabel: "Loading…",
        noConversationsYet: "No conversations yet",
        chatInputPlaceholder: "Ask a legal question or manage case data…",
        quickPrompts: [
            "Show me all open deadlines",
            "Analyze my strongest case",
            "Which arguments are missing?",
            "Give me a risk overview"
        ],

        caseOverview: "Case Overview",
        mandatesTotalSub: { total, active in "\(total) matters · \(active) active" },
        searchCase: "Search cases…",
        newCase: "New Case",
        createCaseTitle: "Create New Case",
        caseNamePlaceholder: "Case name *",
        fileNumberPlaceholder: "File number",
        legalAreaPlaceholder: "Practice area",
        createButton: "Create Case",
        progressLabel: "Progress",
        stepsLabel: "steps",
        argsLabel: "Args",
        evidenceLabel: "Evidence",
        personsLabel: "Persons",
        deadlinesLabel: "Deadlines",
        noCasesTitle: "No cases yet",
        noCasesSubtitle: "Click \"New Case\" to get started",
        // 1:1-Übernahme: im JS sind die Optionen auch in EN auf Deutsch.
        statusOptions: ["Aktiv", "Vorbereitung", "Abgeschlossen", "Ruhend"],
        instanzOptions: ["Erstinstanz", "Berufung", "Revision"],

        cockpitTitle: "Firm Cockpit",
        portfolioSub: { n in "Portfolio Overview · \(n) matters" },
        newCaseLinkLabel: "+ New Case",
        totalClaimLabel: "Total Claim Value",
        allMandatesSub: "all matters",
        avgPrognosisLabel: "Avg. Win Probability",
        weightedAvgSub: "weighted average",
        overdueDeadlinesLabel: "overdue",
        actNow: "Act immediately",
        allOnTrack: "All on track",
        highRiskLabel: "High-Risk Cases (active)",
        noHighRisk: "No high-risk cases active ✓",
        topChancesLabel: "Top Opportunities (active)",
        noTopChancesText: "No cases with high prognosis yet",
        nextDeadlinesLabel: "Upcoming Deadlines",
        showAllLink: "View all →",
        noOpenDeadlinesText: "No open deadlines ✓",
        allMandatesLabel: "All Matters",
        entriesLabel: { n in "\(n) entries" },
        tableHeaderCase: "Case",
        tableHeaderCourt: "Court",
        tableHeaderClaimValue: "Claim Value",
        tableHeaderStatus: "Status",
        casesLabelShort: "Cases",

        judgeProfilesTitle: "Judge Profiles",
        profilesSub: { n in "\(n) profiles · Experience & AI Tactical Analysis" },
        addJudgeBtn: "+ Judge",
        editProfileTitle: "Edit Profile",
        newProfileTitle: "New Judge Profile",
        namePlaceholder: "Name *",
        courtPlaceholder: "Court *",
        chamberPlaceholder: "Chamber / Panel",
        plaintiffRateLabel: "Plaintiff Rate %",
        settlementRateLabel: "Settlement Rate %",
        avgDurationLabel: "Avg. Duration (mo.)",
        totalRulingsLabel: "Total Rulings",
        knownForPlaceholder: "Known for...",
        notesPlaceholder: "Notes",
        linkToCase: "Link to case",
        selectCasePlaceholder: "Select case...",
        detailsAI: "Details & AI",
        noProfilesTitle: "No judge profiles yet",
        noProfilesSub: "Click \"+ Judge\" to create a profile",
        plaintiffRateBar: "Plaintiff Rate",
        settlementRateBar: "Settlement Rate",
        avgMonthsSuffix: "mo. avg.",
        rulingsLabelShort: "Rulings",
        experiencesLabelShort: "Experiences",
        kiAnalysisExists: "✓ AI Analysis available",

        backToOverview: "Back to overview",
        experiencesSection: "Firm Experiences",
        addExperience: "Experience",
        dateLabel: "Date",
        authorLabel: "Author / Attorney",
        caseContextLabel: "Case context (optional)",
        settlementReadiness: "Settlement Readiness",
        decisionSpeed: "Decision Speed",
        expertiseLabel: "Expertise",
        experienceReport: "Experience Report *",
        noExperiencesYet: "No experiences documented yet.",
        addFirstExperience: "Add the first experience.",
        kiTacticsTitle: "AI Tactical Analysis",
        reanalyzeBtn: "Re-analyze",
        startAnalysisBtn: "Start Analysis",
        analyzingBtn: "Analyzing...",
        kiAnalysisHint: "Start the AI analysis to receive tactical recommendations based on the profile and firm experiences.",
        lastAnalysis: "Last analysis",
        kiCreditWarning: "⚠️ This analysis uses Gemini Pro with internet search (more AI credits)",
        summaryLabel: "📊 Summary",
        foundRulingsLabel: "🔍 Found Rulings & Decisions",
        argumentationPatternsLabel: "🧠 Typical Argumentation Patterns",
        preferredNormsLabel: "§ Preferred Legal Norms",
        argumentStanceLabel: "⚖️ Stance on Argument Types",
        preferredMotionsLabel: "📋 Preferred Motion Types",
        damageRangeLabel: "💶 Damage Award / Ruling Range",
        evidenceHandlingLabel: "📜 Evidence Handling",
        plaintiffStrengthsLabel: "✅ Strengths for Plaintiff",
        plaintiffRisksLabel: "⚠️ Risks for Plaintiff",
        doLabel: "👍 DO",
        dontLabel: "👎 DON'T",
        tacticalTipsLabel: "💡 Tactical Tips",
        settlementStrategyLabel: "🤝 Settlement Strategy",
        timingLabel: "⏰ Timing",
        overallAssessmentLabel: "🎯 Overall Assessment",
        anonLabel: "Anonymous",
        settlementBar: "Settlement",
        speedBar: "Speed",
        resultLabel: "Outcome",
        sourceLabel: "Source",
        parametersLabel: "Parameters",
        successRateLabel: "Success Rate",
        typicalRangeLabel: "Typical Range",
        factorsLabel: "Influencing Factors",
        specialFeaturesLabel: "Special Features",
        stanceLabel: "Stance",
        reasonLabel: "Reasoning",

        timelineTitle: "Deadline Timeline",
        iCalExport: "Export iCal",
        filterAll: "All",
        filterOpen: "Open",
        filterCritical: "⚠ Critical",
        filterCompleted: "Completed",
        noDeadlinesFound: "No deadlines found",
        openStatusLabel: "open",
        criticalStatusLabel: "critical (≤14 days)",
        doneStatus: "Completed",
        missedStatus: "Missed",

        newSession: "+ New Session",
        sessionsLabel: "Sessions",
        noSessionsYet: "No sessions yet",
        platformAgentTitle: "Platform Optimizer",
        platformAgentDesc: "The AI agent analyzes your firm data, identifies gaps and implements improvements directly – making MachiavelLEX indispensable for large law firms.",
        nextTaskPlaceholder: "Next task for the agent…",
        customTaskPlaceholder: "Enter custom task…",
        agentNote: "The agent can create & edit judge profiles, arguments and deadlines directly.",

        module: [
            UITexts.ModuleEntry(category: "AI Assistant",                title: "Case Assistant Chat", description: "Conversational AI analysis of your cases"),
            UITexts.ModuleEntry(category: "Case Management",             title: "Lexara Dashboard",    description: "All cases at a glance – deadlines, arguments, evidence"),
            UITexts.ModuleEntry(category: "People Profiles",             title: "Judge Profiles",      description: "Experience, statistics & AI tactical analysis"),
            UITexts.ModuleEntry(category: "AI Agent",                    title: "Platform Agent",      description: "Autonomous agent for platform optimization"),
            UITexts.ModuleEntry(category: "Cockpit",                     title: "Firm Cockpit",        description: "Risk indicators, portfolio and deadline monitoring"),
            UITexts.ModuleEntry(category: "Analytics",                   title: "Firm Analytics",      description: "Visualization of all case metrics and trends"),
            UITexts.ModuleEntry(category: "Strategy & Psycho-Analysis",  title: "Sun Tzu × Machiavelli", description: "48 Laws of Power · Strategic path & risk assessment for your case"),
            UITexts.ModuleEntry(category: "Scenario Forecasting",        title: "Strategos",           description: "Cost-benefit scenarios, legal loophole database & strategic forecasting")
        ]
    )

    // MARK: - Texte: Französisch

    public static let frText: UITexts = UITexts(
        platform: "Votre plateforme juridique IA",
        platformSub: "Analyse stratégique des dossiers & gestion intelligente du contentieux",
        copyright: "© 2026 MachiavelLEX · Tous droits réservés",
        dsgvo: "Conforme RGPD · Serveurs UE",

        kiFallanalyse: "Analyse IA du dossier",
        analyseStarten: "Lancer l'analyse IA",
        analyseWarning: "Cette analyse est assistée par IA et ne constitue pas un avis juridique.",
        fallAuswaehlen: "Sélectionner un dossier",

        aktiveFaelleLabel: "Dossiers actifs",
        offeeneFristenLabel: "Délais ouverts",
        avgPrognoseLabel: "Pronostic moy.",
        argumenteLabel: "Arguments",

        faelleNachRechtsgebiet: "Dossiers par domaine",
        statusVerteilung: "Répartition des statuts",
        prognoseVerteilung: "Répartition du pronostic",
        fristenUebersicht: "Vue d'ensemble des délais",
        naechste14Tage: "14 prochains jours",
        instanzVerteilung: "Répartition par instance",
        risikoverteilung: "Répartition des risques",
        rechtsgebiet: "Domaine juridique",
        gericht: "Tribunal",
        instanz: "Instance",
        aktiv: "Statut",
        streitwert: "Valeur du litige",
        prognose: "Pronostic",

        noDataLabel: "Aucune donnée",
        noDeadlinesRecorded: "Aucun délai enregistré",
        noUpcomingDeadlines: "Aucun délai à venir",
        loading: "Chargement…",
        saveBtn: "Enregistrer",
        cancelBtn: "Annuler",
        updateBtn: "Mettre à jour",
        createBtn: "Créer",
        backLabel: "Retour",
        searchPlaceholder: "Rechercher…",
        todayLabel: "Aujourd'hui",
        tomorrowLabel: "Demain",
        daysOverdueLabel: { n in "\(n)j en retard" },
        inDaysLabel: { n in "dans \(n) jours" },

        mandatesSub: { total, active in "\(total) dossiers · \(active) actifs" },
        ofTotalLabel: { n in "sur \(n) au total" },
        winProbabilityLabel: "Probabilité de succès",
        totalRecordedLabel: "enregistrés au total",
        filterResetBtn: "Réinitialiser",
        noDataShort: "Aucune donnée",
        noDeadlinesShort: "Aucun délai enregistré",
        todayShort: "Aujourd'hui",
        noUpcomingShort: "Aucun délai à venir",

        conversationLabel: "Conversation",
        lexTitle: "Lex · Assistant dossier",
        lexDescription: "Je peux analyser des dossiers, surveiller les délais, gérer les arguments et fournir des recommandations stratégiques.",
        newConversationBtn: "Nouvelle conversation",
        loadingLabel: "Chargement…",
        noConversationsYet: "Aucune conversation",
        chatInputPlaceholder: "Posez une question juridique ou gérez vos données de dossier…",
        quickPrompts: [
            "Montrez-moi tous les délais ouverts",
            "Analysez mon dossier le plus solide",
            "Quels arguments manquent encore ?",
            "Donnez-moi un aperçu des risques"
        ],

        caseOverview: "Vue d'ensemble des dossiers",
        mandatesTotalSub: { total, active in "\(total) dossiers · \(active) actifs" },
        searchCase: "Rechercher un dossier…",
        newCase: "Nouveau dossier",
        createCaseTitle: "Créer un nouveau dossier",
        caseNamePlaceholder: "Nom du dossier *",
        fileNumberPlaceholder: "Référence",
        legalAreaPlaceholder: "Domaine juridique",
        createButton: "Créer le dossier",
        progressLabel: "Progression",
        stepsLabel: "étapes",
        argsLabel: "Args",
        evidenceLabel: "Preuves",
        personsLabel: "Personnes",
        deadlinesLabel: "Délais",
        noCasesTitle: "Aucun dossier",
        noCasesSubtitle: "Cliquez sur « Nouveau dossier » pour commencer",
        // 1:1-Übernahme aus dem JS-Original (deutsche Optionen).
        statusOptions: ["Aktiv", "Vorbereitung", "Abgeschlossen", "Ruhend"],
        instanzOptions: ["Erstinstanz", "Berufung", "Revision"],

        cockpitTitle: "Tableau de bord cabinet",
        portfolioSub: { n in "Vue d'ensemble · \(n) dossiers" },
        newCaseLinkLabel: "+ Nouveau dossier",
        totalClaimLabel: "Valeur totale du litige",
        allMandatesSub: "tous dossiers",
        avgPrognosisLabel: "Pronostic moy. de succès",
        weightedAvgSub: "moyenne pondérée",
        overdueDeadlinesLabel: "en retard",
        actNow: "Agir immédiatement",
        allOnTrack: "Tout est en ordre",
        highRiskLabel: "Dossiers à haut risque (actifs)",
        noHighRisk: "Aucun dossier à haut risque ✓",
        topChancesLabel: "Meilleures opportunités (actives)",
        noTopChancesText: "Aucun dossier à pronostic élevé",
        nextDeadlinesLabel: "Prochains délais",
        showAllLink: "Tout afficher →",
        noOpenDeadlinesText: "Aucun délai ouvert ✓",
        allMandatesLabel: "Tous les dossiers",
        entriesLabel: { n in "\(n) entrées" },
        tableHeaderCase: "Dossier",
        tableHeaderCourt: "Tribunal",
        tableHeaderClaimValue: "Valeur du litige",
        tableHeaderStatus: "Statut",
        casesLabelShort: "Dossiers",

        judgeProfilesTitle: "Profils de juges",
        profilesSub: { n in "\(n) profils · Expériences & analyse tactique IA" },
        addJudgeBtn: "+ Juge",
        editProfileTitle: "Modifier le profil",
        newProfileTitle: "Nouveau profil de juge",
        namePlaceholder: "Nom *",
        courtPlaceholder: "Tribunal *",
        chamberPlaceholder: "Chambre / Formation",
        plaintiffRateLabel: "Taux demandeur %",
        settlementRateLabel: "Taux de règlement %",
        avgDurationLabel: "Durée moy. (mois)",
        totalRulingsLabel: "Décisions totales",
        knownForPlaceholder: "Connu pour...",
        notesPlaceholder: "Notes",
        linkToCase: "Lier à un dossier",
        selectCasePlaceholder: "Sélectionner un dossier...",
        detailsAI: "Détails & IA",
        noProfilesTitle: "Aucun profil de juge",
        noProfilesSub: "Cliquez sur « + Juge » pour créer un profil",
        plaintiffRateBar: "Taux demandeur",
        settlementRateBar: "Taux de règlement",
        avgMonthsSuffix: "mois moy.",
        rulingsLabelShort: "Décisions",
        experiencesLabelShort: "Expériences",
        kiAnalysisExists: "✓ Analyse IA disponible",

        backToOverview: "Retour à la liste",
        experiencesSection: "Expériences du cabinet",
        addExperience: "Expérience",
        dateLabel: "Date",
        authorLabel: "Auteur / Avocat",
        caseContextLabel: "Contexte du dossier (optionnel)",
        settlementReadiness: "Disposition au règlement",
        decisionSpeed: "Rapidité de décision",
        expertiseLabel: "Expertise",
        experienceReport: "Rapport d'expérience *",
        noExperiencesYet: "Aucune expérience documentée.",
        addFirstExperience: "Ajoutez la première expérience.",
        kiTacticsTitle: "Analyse tactique IA",
        reanalyzeBtn: "Ré-analyser",
        startAnalysisBtn: "Démarrer l'analyse",
        analyzingBtn: "Analyse en cours...",
        kiAnalysisHint: "Démarrez l'analyse IA pour obtenir des recommandations tactiques basées sur le profil et les expériences du cabinet.",
        lastAnalysis: "Dernière analyse",
        kiCreditWarning: "⚠️ Cette analyse utilise Gemini Pro avec recherche internet (plus de crédits IA)",
        summaryLabel: "📊 Résumé",
        foundRulingsLabel: "🔍 Décisions & jugements trouvés",
        argumentationPatternsLabel: "🧠 Schémas d'argumentation typiques",
        preferredNormsLabel: "§ Normes juridiques préférées",
        argumentStanceLabel: "⚖️ Position sur les types d'arguments",
        preferredMotionsLabel: "📋 Types de requêtes préférés",
        damageRangeLabel: "💶 Fourchette de dommages-intérêts",
        evidenceHandlingLabel: "📜 Gestion des preuves",
        plaintiffStrengthsLabel: "✅ Points forts pour le demandeur",
        plaintiffRisksLabel: "⚠️ Risques pour le demandeur",
        doLabel: "👍 À FAIRE",
        dontLabel: "👎 À ÉVITER",
        tacticalTipsLabel: "💡 Conseils tactiques",
        settlementStrategyLabel: "🤝 Stratégie de règlement",
        timingLabel: "⏰ Timing",
        overallAssessmentLabel: "🎯 Évaluation globale",
        anonLabel: "Anonyme",
        settlementBar: "Règlement",
        speedBar: "Rapidité",
        resultLabel: "Résultat",
        sourceLabel: "Source",
        parametersLabel: "Paramètres",
        successRateLabel: "Taux de succès",
        typicalRangeLabel: "Fourchette typique",
        factorsLabel: "Facteurs",
        specialFeaturesLabel: "Particularités",
        stanceLabel: "Position",
        reasonLabel: "Justification",

        timelineTitle: "Calendrier des délais",
        iCalExport: "Exporter iCal",
        filterAll: "Tous",
        filterOpen: "Ouverts",
        filterCritical: "⚠ Critiques",
        filterCompleted: "Terminés",
        noDeadlinesFound: "Aucun délai trouvé",
        openStatusLabel: "ouvert",
        criticalStatusLabel: "critique (≤14 jours)",
        doneStatus: "Terminé",
        missedStatus: "Manqué",

        newSession: "+ Nouvelle session",
        sessionsLabel: "Sessions",
        noSessionsYet: "Aucune session",
        platformAgentTitle: "Optimiseur de plateforme",
        platformAgentDesc: "L'agent IA analyse les données de votre cabinet, identifie les lacunes et met en œuvre des améliorations directement.",
        nextTaskPlaceholder: "Prochaine tâche pour l'agent…",
        customTaskPlaceholder: "Saisir une tâche personnalisée…",
        agentNote: "L'agent peut créer et modifier des profils de juges, des arguments et des délais directement.",

        module: [
            UITexts.ModuleEntry(category: "Assistant IA",                 title: "Chat assistant dossier",   description: "Analyse IA conversationnelle de vos dossiers"),
            UITexts.ModuleEntry(category: "Gestion des dossiers",         title: "Tableau de bord Lexara",   description: "Tous les dossiers en un coup d'œil"),
            UITexts.ModuleEntry(category: "Profils de personnes",         title: "Profils de juges",         description: "Expériences, statistiques & analyse tactique IA"),
            UITexts.ModuleEntry(category: "Agent IA",                     title: "Agent de plateforme",      description: "Agent autonome d'optimisation de la plateforme"),
            UITexts.ModuleEntry(category: "Cockpit",                      title: "Cockpit cabinet",          description: "Indicateurs de risque, portefeuille et délais"),
            UITexts.ModuleEntry(category: "Analytique",                   title: "Analytique cabinet",       description: "Visualisation de tous les indicateurs de dossiers"),
            UITexts.ModuleEntry(category: "Stratégie & Psycho-Analyse",   title: "Sun Tzu × Machiavel",      description: "48 Lois du Pouvoir · Chemin stratégique & évaluation des risques"),
            UITexts.ModuleEntry(category: "Prévision de scénarios",       title: "Strategos",                description: "Scénarios coûts-bénéfices, base de failles juridiques & prévisions stratégiques")
        ]
    )

    // MARK: - Lookup-Funktionen

    /// Pendant zu `getT(jurisdiction)`. Mapping (1:1):
    ///   DE/AT/CH/LI → DE-Texte
    ///   EN/US/SE/NO/DK/FI → EN-Texte
    ///   LU → FR-Texte
    /// Fallback: DE.
    public static func texts(for jurisdiction: Jurisdiction) -> UITexts {
        switch jurisdiction {
        case .DE, .AT, .CH, .LI:
            return deText
        case .US, .SE, .NO, .DK, .FI:
            return enText
        case .LU:
            return frText
        }
    }

    /// String-API analog zur JS-Funktion (mit Fallback auf DE).
    public static func texts(jurisdictionCode: String) -> UITexts {
        // Sonderfälle, die im JS-Mapping zusätzlich erscheinen ("EN" / "FR"):
        switch jurisdictionCode {
        case "EN": return enText
        case "FR": return frText
        default:
            if let jur = Jurisdiction(rawValue: jurisdictionCode) {
                return texts(for: jur)
            }
            return deText
        }
    }

    /// Pendant zu `getTByLanguage(lang)`.
    public static func texts(byLanguage lang: Language) -> UITexts {
        switch lang {
        case .EN: return enText
        case .FR: return frText
        case .DE: return deText
        }
    }

    /// String-API analog zur JS-Funktion (mit Fallback auf DE).
    public static func texts(byLanguageCode lang: String) -> UITexts {
        switch lang {
        case "EN": return enText
        case "FR": return frText
        default:   return deText
        }
    }
}

// MARK: - Services/KIProvider.swift

@MainActor
public final class KIProvider: ObservableObject {

    @Published public private(set) var lastOutput: String?
    @Published public var isBusy: Bool = false
    @Published public var lastError: String?

    private let claude  = ClaudeAPIService()
    private let cloudKit = CloudKitService()

    public init() {}

    /// Ruft Claude auf, optional mit erwartetem JSON-Schema.
    /// Loggt jede Anfrage in CloudKit (KIUsageLog).
    @discardableResult
    public func invokeLLM(prompt: String,
                          schema: [String: Any]? = nil,
                          context: String? = nil,
                          caseId: String? = nil) async -> Result<Any, Error> {
        isBusy = true
        defer { isBusy = false }
        do {
            let result: Any
            let outputString: String
            if let schema {
                let dict = try await claude.sendStructured(prompt: prompt, schema: schema)
                result = dict
                outputString = (try? JSONSerialization.data(withJSONObject: dict))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            } else {
                let text = try await claude.sendMessage(prompt: prompt)
                result = text
                outputString = text
            }
            lastOutput = outputString
            await log(prompt: prompt, output: outputString, context: context, caseId: caseId)
            return .success(result)
        } catch {
            lastError = error.localizedDescription
            return .failure(error)
        }
    }

    /// Schreibt einen Log-Eintrag in CloudKit. Fehler werden geschluckt.
    private func log(prompt: String, output: String, context: String?, caseId: String?) async {
        var entry = KIUsageLog(kiFunction: "InvokeLLM", output: output)
        entry.inputSummary = String(prompt.prefix(500))
        entry.model        = ClaudeAPIService.defaultModel
        entry.context      = context
        entry.caseId       = caseId
        entry.timestamp    = Date()
        _ = try? await cloudKit.save(entry)
    }
}

// MARK: - Services/LegalAlgorithms.swift

private let INSTANZ_FAKTOR: [String: Double] = [
    "Erstinstanz": 1.0,
    "Berufung":    0.88,
    "Revision":    0.70
]

private let RECHTSGEBIET_BASERATES: [String: Double] = [
    "Arbeitsrecht":       0.52,
    "Mietrecht":          0.54,
    "Vertragsrecht":      0.51,
    "Familienrecht":      0.50,
    "Gesellschaftsrecht": 0.49,
    "Strafrecht":         0.35,
    "Verwaltungsrecht":   0.38,
    "Insolvenzrecht":     0.48,
    "IP":                 0.50,
    "default":            0.50
]

private let BASE_WIN_RATE: Double = 0.51

// MARK: - Hilfsfunktionen

@inline(__always) private func clamp(_ v: Double, _ minV: Double = 0, _ maxV: Double = 1) -> Double {
    Swift.max(minV, Swift.min(maxV, v))
}
@inline(__always) private func avg(_ arr: [Double]) -> Double {
    guard !arr.isEmpty else { return 0 }
    return arr.reduce(0, +) / Double(arr.count)
}
@inline(__always) private func variance(_ arr: [Double]) -> Double {
    guard arr.count >= 2 else { return 0 }
    let m = avg(arr)
    return arr.reduce(0.0) { $0 + pow($1 - m, 2) } / Double(arr.count)
}
private func randn(_ mean: Double = 0, sd: Double = 1) -> Double {
    let u1 = Double.random(in: 1e-10...1)
    let u2 = Double.random(in: 0...1)
    return mean + sd * sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
}
@inline(__always) private func logistic(_ x: Double) -> Double { 1.0 / (1.0 + exp(-x)) }
@inline(__always) private func logit(_ p: Double) -> Double {
    let pc = clamp(p, 0.001, 0.999); return log(pc / (1 - pc))
}

private let rvgTabelle: [(maxStreitwert: Double, basisGebuehr: Double)] = [
    (500, 49), (1000, 88), (1500, 127), (2000, 166), (3000, 222), (4000, 278), (5000, 334),
    (13000, 590), (19000, 758), (25000, 986), (50000, 1474), (100000, 1981),
    (200000, 2737), (500000, 3894), (.infinity, 5000)
]
private func rvgGebuehr(streitwert: Double) -> Double {
    rvgTabelle.first { streitwert <= $0.maxStreitwert }?.basisGebuehr ?? 5000
}

private func formatEuro(_ v: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal; nf.locale = Locale(identifier: "de_DE")
    nf.maximumFractionDigits = 0
    return (nf.string(from: NSNumber(value: v)) ?? "\(Int(v))") + " €"
}

// MARK: - Eingabe + Strukturen

public struct PrognoseInput {
    public var args:      [Argument]
    public var evidence:  [Evidence]
    public var deadlines: [Deadline]
    public var persons:   [Person]
    public var caseData:  Case?
    public init(args: [Argument] = [], evidence: [Evidence] = [],
                deadlines: [Deadline] = [], persons: [Person] = [],
                caseData: Case? = nil) {
        self.args = args; self.evidence = evidence
        self.deadlines = deadlines; self.persons = persons
        self.caseData = caseData
    }
}

public struct CalculationStep: Identifiable, Hashable {
    public let id = UUID()
    public var kategorie: String, label: String, formel: String
    public var wert: Double
    public var einheit: String?
    public var erklaerung: String
}

public struct PrognoseInputCounts: Hashable {
    public var eigeneArgs: Int, gegnerArgs: Int, beweise: Int, fristen: Int
    public var richterBekannt: Bool
}

public struct PrognoseResult: Hashable {
    public var score: Int, scoreRaw: Double, logOdds: Double
    public var ciLow: Int, ciHigh: Int, sigma: Double
    public var steps: [CalculationStep]
    public var inputs: PrognoseInputCounts
}

public enum RisikoLevel: String, Hashable { case niedrig, mittel, hoch }

public struct RisikoFaktor: Identifiable, Hashable {
    public let id = UUID()
    public var key: String, score: Int, level: RisikoLevel
    public var bewertung: String, massnahme: String, formel: String
}
public struct RisikoResult: Hashable {
    public var faktoren: [RisikoFaktor]
    public var gesamtrisiko: RisikoLevel
    public var gesamtScore: Double
}

public struct MonteCarloHistogramBin: Identifiable, Hashable {
    public let id = UUID()
    public var bin: String, count: Int, pct: Double
}
public struct MonteCarloScenario: Hashable {
    public var wahrscheinlichkeit: Int, schwelle: Int?, erklaerung: String
}
public struct MonteCarloResult: Hashable {
    public var mean: Int, p10: Int, p25: Int, median: Int, p75: Int, p90: Int
    public var histogram: [MonteCarloHistogramBin], iterations: Int
    public var bestCase: MonteCarloScenario, baseCase: MonteCarloScenario, worstCase: MonteCarloScenario
}

public struct ZusatzOption: Identifiable, Hashable {
    public let id = UUID()
    public var titel: String, symbol: String, beschreibung: String
    public var breakEvenPct: Int, basis: String, rechtsgrundlage: String
}
public struct BreakEvenResult: Hashable {
    public var breakEvenPct: Int?, gesamtkosten: Int
    public var eigeneKosten: Int, gegnerKosten: Int, gerichtkosten: Int
    public var svKosten: Int, reiseKosten: Int
    public var formel: String, erklaerung: String, empfehlung: String
    public var zusatzoptionen: [ZusatzOption]
}

public struct VollanalyseResult: Hashable {
    public var prognose: PrognoseResult
    public var risikofaktoren: RisikoResult
    public var monteCarlo: MonteCarloResult
    public var breakEven: BreakEvenResult
    public var timestamp: Date
    public var version: String
}

// MARK: - LegalAlgorithms

public enum LegalAlgorithms {

    // ─── computePrognose ──────────────────────────────────────────────
    public static func computePrognose(_ input: PrognoseInput) -> PrognoseResult {
        var steps: [CalculationStep] = []
        let cd = input.caseData

        // Schritt 1: Prior
        let rechtsgebiet = cd?.rechtsgebiet ?? "default"
        let baseRate = RECHTSGEBIET_BASERATES[rechtsgebiet] ?? RECHTSGEBIET_BASERATES["default"]!
        let instanzKey = cd?.instanz.rawValue ?? "Erstinstanz"
        let instanzFaktor = INSTANZ_FAKTOR[instanzKey] ?? 1.0
        let adjustedBase = clamp(baseRate * instanzFaktor)
        steps.append(.init(
            kategorie: "Basis-Annahmen & Initialisierung",
            label: "Prior-Wahrscheinlichkeit (Basisrate)",
            formel: "P_basis = Basisrate(\(rechtsgebiet)) × Instanzfaktor(\(instanzKey))",
            wert: adjustedBase, einheit: nil,
            erklaerung: "Statistische Kläger-Gewinnrate im \(rechtsgebiet): \(Int(baseRate * 100))%. Instanzfaktor: \(String(format: "%.2f", instanzFaktor))."
        ))
        var logOdds = logit(adjustedBase)

        // Schritt 2: Argumente
        let eigene = input.args.filter { $0.side == .eigen }
        let gegner = input.args.filter { $0.side == .gegner }
        let eS = eigene.map { ($0.kiStrength ?? $0.strength ?? 5) / 10 }
        let gS = gegner.map { ($0.kiStrength ?? $0.strength ?? 5) / 10 }
        let aE = eS.isEmpty ? 0.5 : avg(eS)
        let aG = gS.isEmpty ? 0.5 : avg(gS)
        let argDelta = aE - aG
        let argLOD = argDelta * 1.6
        logOdds += argLOD
        steps.append(.init(
            kategorie: "Inhaltliche Fallbewertung",
            label: "Argumentationsbilanz",
            formel: "Δ_arg = (Ø_eigen - Ø_gegner) × 1.6 = (\(String(format: "%.2f", aE)) - \(String(format: "%.2f", aG))) × 1.6",
            wert: argLOD, einheit: "Log-Odds",
            erklaerung: "Eigene (n=\(eigene.count), Ø=\(String(format: "%.1f", aE * 10))/10) vs. Gegner (n=\(gegner.count), Ø=\(String(format: "%.1f", aG * 10))/10)."
        ))

        // Schritt 3: Beweise
        let bG = input.evidence.map { ($0.kiWeight ?? $0.weight ?? 5) / 10 }
        let aB = bG.isEmpty ? 0.5 : avg(bG)
        let bC = input.evidence.count
        let bCB = bC > 0 ? log(Double(bC + 1)) / log(20) * 0.3 : 0
        let bQ  = (aB - 0.5) * 1.2 + bCB
        let bLOD = bQ * 1.0
        logOdds += bLOD
        steps.append(.init(
            kategorie: "Inhaltliche Fallbewertung",
            label: "Beweisqualität & -quantität",
            formel: "Δ_bew = [(Ø_Gewicht - 0.5) × 1.2 + log(n+1)/log(20) × 0.3] × 1.0",
            wert: bLOD, einheit: "Log-Odds",
            erklaerung: "\(bC) Beweismittel, Ø \(String(format: "%.1f", aB * 10))/10. Mengenbonus: \(String(format: "%.3f", bCB))."
        ))

        // Schritt 4: Richter
        let richter = input.persons.first { $0.role == .richter }
        var rLOD: Double = 0
        if let r = richter, let kr = r.klaegerRate {
            let rP = kr / 100
            let rD = logit(clamp(rP, 0.1, 0.9)) - logit(0.5)
            rLOD = rD * 0.4
            logOdds += rLOD
            steps.append(.init(
                kategorie: "Kontextuelle & Prozedurale Einflüsse",
                label: "Richter-Statistik (Bayesianisch)",
                formel: "Δ_richter = (logit(Klägerquote) - logit(0.5)) × 0.4",
                wert: rLOD, einheit: "Log-Odds",
                erklaerung: "Richter \(r.name): Klägerquote \(Int(kr))%. Bayes-Update Gewicht 0.4."
            ))
        } else {
            steps.append(.init(
                kategorie: "Kontextuelle & Prozedurale Einflüsse",
                label: "Richter-Statistik",
                formel: "Δ_richter = 0 (kein Richter bekannt)",
                wert: 0, einheit: "Log-Odds",
                erklaerung: "Kein Richter mit Statistiken erfasst."
            ))
        }

        // Schritt 5: Fristen
        let now = Date()
        let versaeumt = input.deadlines.filter { $0.status == .versaeumt && $0.side != .gegner }.count
        let kritisch  = input.deadlines.filter {
            guard $0.status == .offen, $0.side != .gegner else { return false }
            let d = $0.dueDate.timeIntervalSince(now) / 86400
            return d >= 0 && d <= 7
        }.count
        let fP = -(Double(versaeumt) * 0.4 + Double(kritisch) * 0.15)
        logOdds += fP
        steps.append(.init(
            kategorie: "Kontextuelle & Prozedurale Einflüsse",
            label: "Fristenrisiko (Malus)",
            formel: "Δ_fristen = -(versäumte × 0.4 + kritische × 0.15)",
            wert: fP, einheit: "Log-Odds",
            erklaerung: "\(versaeumt) versäumt, \(kritisch) kritisch <7 Tage."
        ))

        // Schritt 6: Vergleichsangebot
        if let cd = cd, let v = cd.vergleichsangebot, let sv = cd.streitwert, sv > 0 {
            let r = v / sv
            let vD = (r - 0.4) * 0.8
            logOdds += vD
            steps.append(.init(
                kategorie: "Kontextuelle & Prozedurale Einflüsse",
                label: "Vergleichsangebot-Signal",
                formel: "Δ_vgl = (Vergleich/Streitwert - 0.4) × 0.8",
                wert: vD, einheit: "Log-Odds",
                erklaerung: "\(formatEuro(v)) bei Streitwert \(formatEuro(sv)) (\(Int(r * 100))%). \(vD > 0 ? "Hohes Angebot signalisiert Unsicherheit." : "Niedriges Angebot deutet auf Stärke der Gegenseite hin.")"
            ))
        }

        // Final
        let pF = clamp(logistic(logOdds))
        steps.append(.init(
            kategorie: "Endgültige Prognose & Unsicherheit",
            label: "Finale Wahrscheinlichkeit (Logistische Transformation)",
            formel: "P_final = σ(log-Odds) = \(String(format: "%.1f", pF * 100))%",
            wert: pF, einheit: nil,
            erklaerung: "Summe aller Log-Odds, durch logistische Funktion in Wahrscheinlichkeit transformiert."
        ))

        // CI
        let argVar = variance(eS + gS)
        let bewVar = variance(bG)
        let rUns: Double = (richter?.klaegerRate != nil) ? 0.02 : 0.06
        let sigma = sqrt(pow(argVar * 0.35, 2) + pow(bewVar * 0.25, 2) + pow(rUns, 2) + pow(0.04, 2))
        let cL = clamp(pF - 1.645 * sigma)
        let cH = clamp(pF + 1.645 * sigma)
        steps.append(.init(
            kategorie: "Endgültige Prognose & Unsicherheit",
            label: "90%-Konfidenzintervall (Fehlerfortpflanzung)",
            formel: "σ = √(σ_arg² × 0.35² + σ_bew² × 0.25² + σ_richter² + 0.04²)",
            wert: sigma, einheit: nil,
            erklaerung: "CI = P ± 1.645 × σ = [\(String(format: "%.1f", cL * 100))%, \(String(format: "%.1f", cH * 100))%]"
        ))

        return PrognoseResult(
            score: Int((pF * 100).rounded()), scoreRaw: pF, logOdds: logOdds,
            ciLow: Int((cL * 100).rounded()), ciHigh: Int((cH * 100).rounded()),
            sigma: sigma, steps: steps,
            inputs: PrognoseInputCounts(
                eigeneArgs: eigene.count, gegnerArgs: gegner.count,
                beweise: input.evidence.count, fristen: input.deadlines.count,
                richterBekannt: richter?.klaegerRate != nil
            )
        )
    }

    // ─── runMonteCarlo ──────────────────────────────────────────────────
    public static func runMonteCarlo(baseResult: PrognoseResult, iterations: Int = 5_000) -> MonteCarloResult {
        var outcomes: [Double] = []; outcomes.reserveCapacity(iterations)
        for _ in 0..<iterations {
            outcomes.append(clamp(logistic(randn(baseResult.logOdds, sd: baseResult.sigma * 2.5))))
        }
        outcomes.sort()
        func p(_ pct: Double) -> Double {
            outcomes[max(0, min(outcomes.count - 1, Int((pct / 100) * Double(outcomes.count))))]
        }
        let mean = avg(outcomes)
        let p10 = p(10), p25 = p(25), p50 = p(50), p75 = p(75), p90 = p(90), p80 = p(80)
        var hist: [MonteCarloHistogramBin] = []
        for i in 0..<20 {
            let lo = Double(i) * 0.05, hi = (Double(i) + 1) * 0.05
            let c = outcomes.filter { $0 >= lo && $0 < hi }.count
            hist.append(.init(bin: "\(Int((lo * 100).rounded()))%", count: c, pct: lo + 0.025))
        }
        return MonteCarloResult(
            mean: Int((mean * 100).rounded()),
            p10:  Int((p10  * 100).rounded()),
            p25:  Int((p25  * 100).rounded()),
            median: Int((p50 * 100).rounded()),
            p75:  Int((p75  * 100).rounded()),
            p90:  Int((p90  * 100).rounded()),
            histogram: hist, iterations: iterations,
            bestCase:  .init(wahrscheinlichkeit: 100 - Int((p80 * 100).rounded()),
                             schwelle: Int((p80 * 100).rounded()),
                             erklaerung: "Alle Faktoren entwickeln sich günstig (oberes Quintil)"),
            baseCase:  .init(wahrscheinlichkeit: Int((p50 * 100).rounded()), schwelle: nil,
                             erklaerung: "Median-Szenario: Faktoren entwickeln sich wie erwartet"),
            worstCase: .init(wahrscheinlichkeit: Int((p10 * 100).rounded()), schwelle: nil,
                             erklaerung: "Pessimistisches Szenario (unteres Dezil)")
        )
    }

    // ─── computeRisikoFaktoren – 8 Dimensionen ────────────────────────
    public static func computeRisikoFaktoren(_ input: PrognoseInput) -> RisikoResult {
        let eigene = input.args.filter { $0.side == .eigen }
        let gegner = input.args.filter { $0.side == .gegner }
        let richter = input.persons.first { $0.role == .richter }
        let cd = input.caseData
        var faktoren: [RisikoFaktor] = []

        // 1. Beweis
        let bG = input.evidence.map { $0.kiWeight ?? $0.weight ?? 5 }
        let aB = bG.isEmpty ? 3 : avg(bG)
        let bV = variance(bG)
        let bR = clamp(1 - aB / 10 + bV / 100)
        let bS = Int((bR * 10).rounded())
        faktoren.append(.init(key: "beweis_risiko", score: bS,
            level: bS <= 3 ? .niedrig : (bS <= 6 ? .mittel : .hoch),
            bewertung: "\(input.evidence.count) Beweismittel, Ø \(String(format: "%.1f", aB))/10, σ²=\(String(format: "%.1f", bV))",
            massnahme: bS > 6 ? "Zusätzliche Beweismittel sichern" : (bS > 3 ? "Beweisqualität via Sachverständigengutachten stärken" : "Beweislage solide"),
            formel: "Risiko = 1 - Ø/10 + σ²/100 = \(String(format: "%.3f", bR))"))

        // 2. Richter
        var rS = 5; var rE = "Kein Richter erfasst – neutral"
        var rF = "Score = 5 (Standardwert)"
        if let r = richter {
            let kr = r.klaegerRate ?? 50
            let vr = r.vergleichRate ?? 30
            rS = Int((clamp(1 - kr / 100) * 10).rounded())
            rE = "Richter \(r.name): Klägerquote \(Int(kr))%, Vergleich \(Int(vr))%"
            rF = "Risiko = (1 - Klägerquote/100) = \(String(format: "%.2f", 1 - kr / 100))"
        }
        faktoren.append(.init(key: "richter_risiko", score: rS,
            level: rS <= 3 ? .niedrig : (rS <= 6 ? .mittel : .hoch),
            bewertung: rE,
            massnahme: rS > 6 ? "Vergleichsbereitschaft signalisieren" : "Richterstatistik günstig",
            formel: rF))

        // 3. Recht
        let hC = !(cd?.zentraleRechtsfrage?.isEmpty ?? true)
        let aV = variance((eigene + gegner).map { $0.kiStrength ?? $0.strength ?? 5 })
        let recR = clamp(aV / 25 + (hC ? 0 : 0.2))
        let recS = Int((recR * 10).rounded())
        faktoren.append(.init(key: "rechts_risiko", score: recS,
            level: recS <= 3 ? .niedrig : (recS <= 6 ? .mittel : .hoch),
            bewertung: "Argumentation σ²=\(String(format: "%.1f", aV)); zentrale Rechtsfrage: \(hC ? "definiert" : "offen")",
            massnahme: recS > 5 ? "Rechtsprechungsrecherche vertiefen" : "Rechtslage klar definiert",
            formel: "Risiko = σ²/25 + (keine_Rechtsfrage ? 0.2 : 0) = \(String(format: "%.3f", recR))"))

        // 4. Kosten
        var kS = 5; var kF = "Kein Streitwert angegeben"
        var kE = "Streitwert unbekannt – Standardrisiko"
        if let sv = cd?.streitwert, sv > 0 {
            let g = cd?.gebuehrenstufe ?? 1.3
            let basis = rvgGebuehr(streitwert: sv)
            let gK = basis * g * 2 + (cd?.svKosten ?? 0) + (cd?.reisekosten ?? 0)
            let r = gK / sv
            kS = Int((clamp(r * 2) * 10).rounded())
            kF = "Kosten ≈ \(formatEuro(basis)) × \(g) × 2 + SV + Reise = \(formatEuro(gK))"
            kE = "Kostenquote: \(String(format: "%.1f", r * 100))% des Streitwerts"
        }
        faktoren.append(.init(key: "kosten_risiko", score: kS,
            level: kS <= 3 ? .niedrig : (kS <= 6 ? .mittel : .hoch),
            bewertung: kE,
            massnahme: kS > 6 ? "Prozesskostenrisiko kritisch – Vergleich erwägen" : "Kostenstruktur akzeptabel",
            formel: kF))

        // 5. Zeit
        let now = Date()
        let v = input.deadlines.filter { $0.status == .versaeumt && $0.side != .gegner }.count
        let o = input.deadlines.filter { $0.status == .offen }.count
        let k = input.deadlines.filter {
            guard $0.status == .offen else { return false }
            let d = $0.dueDate.timeIntervalSince(now) / 86400
            return d >= 0 && d <= 14
        }.count
        let zR = clamp(Double(v) * 0.2 + Double(k) * 0.1 + (o > 5 ? 0.1 : 0))
        let zS = Int((zR * 10).rounded())
        faktoren.append(.init(key: "zeit_risiko", score: zS,
            level: zS <= 2 ? .niedrig : (zS <= 5 ? .mittel : .hoch),
            bewertung: "\(v) versäumt, \(k) kritisch (<14 T), \(o) offen",
            massnahme: zS > 5 ? "Sofortige Fristenprüfung – Wiedereinsetzung" : (zS > 2 ? "Kritische Fristen überwachen" : "Fristen unter Kontrolle"),
            formel: "Risiko = v×0.2 + k×0.1 + (o>5 ? 0.1 : 0) = \(String(format: "%.3f", zR))"))

        // 6. Gegner
        let aGS = gegner.isEmpty ? 5 : avg(gegner.map { $0.kiStrength ?? $0.strength ?? 5 })
        let gR = clamp(aGS / 10 + (gegner.count > 3 ? 0.1 : 0))
        let gS = Int((gR * 10).rounded())
        faktoren.append(.init(key: "gegner_risiko", score: gS,
            level: gS <= 3 ? .niedrig : (gS <= 6 ? .mittel : .hoch),
            bewertung: "\(gegner.count) Gegnerargumente, Ø \(String(format: "%.1f", aGS))/10",
            massnahme: gS > 6 ? "Gegenargumente entkräften, Kontranarrative entwickeln" : "Gegnerstärke moderat",
            formel: "Risiko = Ø/10 + (n>3 ? 0.1 : 0) = \(String(format: "%.3f", gR))"))

        // 7. Reputation
        let repM: [String: Double] = ["Strafrecht": 0.8, "Familienrecht": 0.5, "Arbeitsrecht": 0.4, "default": 0.25]
        let repB = repM[cd?.rechtsgebiet ?? "default"] ?? repM["default"]!
        let svF: Double = (cd?.streitwert ?? 0) > 500_000 ? 0.2 : ((cd?.streitwert ?? 0) > 100_000 ? 0.1 : 0)
        let repR = clamp(repB + svF)
        let repS = Int((repR * 10).rounded())
        faktoren.append(.init(key: "reputation_risiko", score: repS,
            level: repS <= 3 ? .niedrig : (repS <= 5 ? .mittel : .hoch),
            bewertung: "Rechtsgebiet \(cd?.rechtsgebiet ?? "unbekannt"), SW-Faktor +\(Int(svF * 100))%",
            massnahme: repS > 5 ? "Medien-/PR-Strategie abstimmen" : "Niedrige Exponierung",
            formel: "Risiko = \(repB) + \(svF) = \(String(format: "%.2f", repR))"))

        // 8. Vergleichschance
        let vR = richter?.vergleichRate ?? 30
        let pProz = cd?.prognose ?? 50
        let unG = 1 - abs(pProz / 100 - 0.5) * 2
        let vC = clamp(unG * 0.5 + vR / 100 * 0.5)
        let vS = Int((vC * 10).rounded())
        faktoren.append(.init(key: "vergleich_chance", score: vS,
            level: vS >= 7 ? .niedrig : (vS >= 4 ? .mittel : .hoch),
            bewertung: "Ungewissheit: \(Int(unG * 100))%, Vergleichsrate Richter: \(Int(vR))%",
            massnahme: vS > 6 ? "Vergleichsgespräche aktiv anstreben" : (vS > 3 ? "Vergleich offen halten" : "Geringe Vergleichswahrscheinlichkeit"),
            formel: "Chance = U×0.5 + Vergl.×0.5 = \(String(format: "%.3f", vC))"))

        let scores = faktoren.filter { $0.key != "vergleich_chance" }.map { Double($0.score) }
        let g = avg(scores)
        let lvl: RisikoLevel = g <= 3.5 ? .niedrig : (g <= 5.5 ? .mittel : .hoch)
        return RisikoResult(faktoren: faktoren, gesamtrisiko: lvl,
                            gesamtScore: (g * 10).rounded() / 10)
    }

    // ─── computeBreakEven ─────────────────────────────────────────────
    public static func computeBreakEven(caseData: Case?) -> BreakEvenResult? {
        guard let cd = caseData, let sv = cd.streitwert, sv > 0 else { return nil }
        let g = cd.gebuehrenstufe ?? 1.3
        let basis = rvgGebuehr(streitwert: sv)
        let eK = basis * g, gK = basis * g
        let svK = cd.svKosten ?? 0, rK = cd.reisekosten ?? 0
        let geK: Double = sv <= 5000 ? 150 : (sv <= 50_000 ? 500 : 1500)
        let total = eK + gK + svK + rK + geK
        let bP = total / (sv + total)
        let bePct = Int((clamp(bP) * 100).rounded())

        let svS = sv * 1.4, beS = Int((clamp(total / (svS + total)) * 100).rounded())
        let svV = sv * 1.08, beV = Int((clamp(total / (svV + total)) * 100).rounded())
        let vfW = sv * 1.2, beVf = Int((clamp(total / (vfW + total)) * 100).rounded())
        let smW = sv * 2.0, beSm = Int((clamp(total / (smW + total)) * 100).rounded())

        let zusatz: [ZusatzOption] = [
            .init(titel: "Schadensersatz (inkl. immateriell & entgangener Gewinn)",
                  symbol: "💰",
                  beschreibung: "Materieller + immaterieller Schaden + entgangener Gewinn. Effektiver Wert ca. 1.4× = \(formatEuro(svS)).",
                  breakEvenPct: beS, basis: formatEuro(svS),
                  rechtsgrundlage: "§§ 249 ff. BGB, § 253 BGB"),
            .init(titel: "Verzugszinsen & Prozesszinsen",
                  symbol: "📈",
                  beschreibung: "Verzugszinsen (5% / 9% über Basiszins) ab Mahnung. Bei 2 J. ≈ \(formatEuro(svV)).",
                  breakEvenPct: beV, basis: formatEuro(svV),
                  rechtsgrundlage: "§ 288 BGB, § 291 BGB"),
            .init(titel: "Verfassungsbeschwerde / Grundrechtsklage",
                  symbol: "⚖️",
                  beschreibung: "Bei Grundrechtsverletzung. Strategiewert 1.2× = \(formatEuro(vfW)).",
                  breakEvenPct: beVf, basis: "Strategiewert ca. \(formatEuro(vfW))",
                  rechtsgrundlage: "Art. 93 Abs. 1 Nr. 4a GG, §§ 90 ff. BVerfGG"),
            .init(titel: "Sammelklage / Verbandsklage (mehrere Betroffene)",
                  symbol: "👥",
                  beschreibung: "Mehrere Mandanten bündeln Streitwerte. Bei 5 Mitklägern ≈ \(formatEuro(smW)).",
                  breakEvenPct: beSm, basis: "Gesamtstreitwert ca. \(formatEuro(smW))",
                  rechtsgrundlage: "§ 606 ZPO, VDuG")
        ]
        let empf = bePct > 60 ? "⚠️ Hohes Kostenrisiko. Vergleich dringend erwägen."
                : bePct > 40 ? "Klage sinnvoll bei >50% Erfolgschance."
                : "✅ Kostenstruktur günstig – Klage wirtschaftlich."

        return BreakEvenResult(
            breakEvenPct: bePct,
            gesamtkosten: Int(total.rounded()),
            eigeneKosten: Int(eK.rounded()), gegnerKosten: Int(gK.rounded()),
            gerichtkosten: Int(geK), svKosten: Int(svK), reiseKosten: Int(rK),
            formel: "P_min = \(Int(total)) / \(Int(sv + total)) = \(bePct)%",
            erklaerung: "Bei Sieg werden alle Kosten vom Gegner erstattet. Klage lohnt ab \(bePct)%.",
            empfehlung: empf, zusatzoptionen: zusatz
        )
    }

    // ─── computeVollanalyse ───────────────────────────────────────────
    public static func computeVollanalyse(_ input: PrognoseInput) -> VollanalyseResult? {
        let p = computePrognose(input)
        let r = computeRisikoFaktoren(input)
        let mc = runMonteCarlo(baseResult: p)
        guard let be = computeBreakEven(caseData: input.caseData) else { return nil }
        return VollanalyseResult(prognose: p, risikofaktoren: r, monteCarlo: mc, breakEven: be,
                                 timestamp: Date(), version: "1.2.0")
    }

    // ─── Backwards-compatible Helpers ─────────────────────────────────
    public static func prognose(arguments: [Argument]) -> Double {
        let e = arguments.filter { $0.side == .eigen }
        let g = arguments.filter { $0.side == .gegner }
        let eS = e.reduce(0.0) { $0 + ($1.kiStrength ?? $1.strength ?? 5) }
        let gS = g.reduce(0.0) { $0 + ($1.kiStrength ?? $1.strength ?? 5) }
        let total = eS + gS
        guard total > 0 else { return 50 }
        return min(95, max(5, eS / total * 100))
    }
    public static func prognoseMitFristen(base: Double, deadlines: [Deadline]) -> Double {
        let v = deadlines.filter { $0.status == .versaeumt && $0.side == .eigene }.count
        return max(5, base - Double(v) * 8)
    }
    public static func argumentScore(_ arg: Argument, evidence: [Evidence]) -> Double {
        let eW = evidence.filter { $0.argumentId == arg.id }.map { $0.kiWeight ?? $0.weight ?? 5 }.reduce(0, +)
        let base = arg.kiStrength ?? arg.strength ?? 5
        let bonus = min(3, eW / 10)
        let pen = arg.isContradiction ? 2.0 : 0
        return max(0, min(10, base + bonus - pen))
    }
    public struct VergleichEmpfehlung: Hashable {
        public let prozessErwartet: Double, vergleichErwartet: Double, empfehlung: String
    }
    public static func vergleichsEmpfehlung(streitwert: Double, gebuehren: Double,
                                            svKosten: Double, reisekosten: Double,
                                            prognosePct: Double,
                                            vergleichsangebot: Double?) -> VergleichEmpfehlung {
        let g = prognosePct / 100
        let pE = (streitwert * g) - (gebuehren + svKosten + reisekosten) * (1 - g)
        let v = vergleichsangebot ?? (streitwert * 0.5)
        let emp: String
        if v > pE * 1.05 { emp = "Vergleich annehmen (höherer Erwartungswert)." }
        else if pE > v * 1.15 { emp = "Prozess weiterführen (deutlich höherer Erwartungswert)." }
        else { emp = "Erwartungswerte ähnlich – Risikoabwägung mit Mandant." }
        return .init(prozessErwartet: pE, vergleichErwartet: v, empfehlung: emp)
    }
    public static func fristStatus(_ d: Deadline, today: Date = Date()) -> String {
        if d.status == .erledigt { return "Erledigt" }
        if d.status == .versaeumt { return "Versäumt" }
        let diff = Calendar.current.dateComponents([.day], from: today, to: d.dueDate).day ?? 0
        if diff < 0 { return "Überfällig" }
        if diff < 3 { return "Kritisch" }
        if diff < 14 { return "Demnächst" }
        return "Geplant"
    }
}

// MARK: - Services/StrategosRechtsgebiete.swift

public enum StrategosRechtsgebiete {

    // MARK: - Datenstrukturen

    /// Eine benannte Formel (Name + textuelle Formel-Definition).
    public struct Formel: Codable, Hashable, Sendable {
        public let name: String
        public let formel: String
        public init(name: String, formel: String) {
            self.name = name
            self.formel = formel
        }
    }

    /// Map "Jurisdiktionscode → aktiv?" (z.B. ["DE": true, "EU": true]).
    public typealias JurisdictionFlags = [String: Bool]

    /// Ein vollständiger Rechtsgebiets-Eintrag.
    public struct Rechtsgebiet: Codable, Hashable, Sendable {
        public let key: String
        public let label: String
        public let kurzlabel: String
        public let icon: String
        public let color: String
        public let block: String
        public let pflichtfelder: [String]
        public let formeln: [Formel]
        /// Optional, da im JS nur bei manchen Einträgen vorhanden ist (z.B. Block I.1).
        public let dokumente: [String]?
        public let jurisdiktionen: JurisdictionFlags

        public init(
            key: String,
            label: String,
            kurzlabel: String,
            icon: String,
            color: String,
            block: String,
            pflichtfelder: [String],
            formeln: [Formel],
            dokumente: [String]? = nil,
            jurisdiktionen: JurisdictionFlags
        ) {
            self.key = key
            self.label = label
            self.kurzlabel = kurzlabel
            self.icon = icon
            self.color = color
            self.block = block
            self.pflichtfelder = pflichtfelder
            self.formeln = formeln
            self.dokumente = dokumente
            self.jurisdiktionen = jurisdiktionen
        }
    }

    /// Übergreifende Systemformeln (Monte Carlo, Wechselwirkungen).
    public struct SystemFormeln: Codable, Hashable, Sendable {
        public let gesamtrisiko: String
        public let monteCarlo: String
        public let wechselwirkung: String
    }

    /// Beschreibung einer Jurisdiktions-Besonderheit (Label + Liste).
    public struct JurisdiktionInfo: Codable, Hashable, Sendable {
        public let label: String
        public let besonderheiten: [String]
        public init(label: String, besonderheiten: [String]) {
            self.label = label
            self.besonderheiten = besonderheiten
        }
    }

    // MARK: - RECHTSGEBIETE_VOLLSTAENDIG

    /// 1:1-Übernahme der JS-Konstante `RECHTSGEBIETE_VOLLSTAENDIG`.
    public static let alle: [Rechtsgebiet] = [

        // ── BLOCK I ─────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "steuerrecht_national",
            label: "Steuerrecht (National)",
            kurzlabel: "Steuer National",
            icon: "💰",
            color: "#34C759",
            block: "I",
            pflichtfelder: [
                "Körperschaftsteuersatz", "Gewerbesteuer-Hebesatz je Gemeinde",
                "Umsatzsteuer-Voranmeldungen & Dauerfristverlängerungen",
                "Verlustvorträge (§ 10d EStG – Mindestbesteuerung 60% ab 1 Mio. €)",
                "Zinsschranke (§ 4h EStG – EBITDA-Grenze 30%)",
                "Thesaurierungsbegünstigung (Personengesellschaften)",
                "Organschaft / Ergebnisabführungsvertrag",
                "Laufende Betriebsprüfungen (Zeitraum & Schwerpunkte)",
                "Offene Einsprüche und Klagen"
            ],
            formeln: [
                Formel(name: "Effektive Gesamtsteuerbelastung KapGes DE",
                       formel: "EStB = 15% (KSt) + 0,825% (SolZ) + Hebesatz × 3,5% (GewSt) → Typisch 29–33%"),
                Formel(name: "Zinsschranke",
                       formel: "Abzugsfähige Nettozinsen = min(tatsächliche Nettozinsen ; 30% × steuerliches EBITDA)"),
                Formel(name: "Mindestbesteuerung § 10d EStG",
                       formel: "Verrechenbarer Verlust = 1.000.000 € + 60% × (zvE − 1.000.000 €)")
            ],
            dokumente: ["Steuerbescheide 5 Jahre", "Jahresabschlüsse", "Ergebnisabführungsverträge", "Prüfungsberichte Finanzamt"],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true]
        ),

        Rechtsgebiet(
            key: "steuerrecht_international",
            label: "Internationales Steuerrecht / Verrechnungspreise",
            kurzlabel: "Steuer Intl.",
            icon: "🌍",
            color: "#2ECC71",
            block: "I",
            pflichtfelder: [
                "Konzernstruktur mit Beteiligungsquoten & Jurisdiktionen",
                "Konzerninterne Transaktionen (Waren, Dienstleistungen, Lizenzen, Darlehen, Kostenumlagen) mit Volumen & Preisen",
                "Verrechnungspreismethode je Transaktion (Preisvergleich, Wiederverkaufspreis, Kostenaufschlag, TNMM, Profit Split)",
                "Funktions- und Risikoanalyse je Gesellschaft",
                "Betriebsstätten weltweit (feste Einrichtung, Vertreter, Server, Lager, Baustellen >12 Monate)",
                "Quellensteuereinbehalte (Dividenden / Zinsen / Lizenzen) & anwendbare DBA",
                "BEPS Pillar 2 Einordnung",
                "Country-by-Country-Report"
            ],
            formeln: [
                Formel(name: "Fremdvergleichs-Score (FVS)",
                       formel: "FVS = (konzerninterner Preis ÷ Interquartilsbereich-Median Benchmark) × 100 → 75–125: akzeptabel"),
                Formel(name: "BEPS Pillar 2 Top-Up-Tax",
                       formel: "TUT = max(0 ; (15% − GloBE-Effektivsteuersatz_Land) × GloBE-Nettoeinkommen_Land)"),
                Formel(name: "Quellensteueroptimierung via Holding",
                       formel: "Nettoertrag = Bruttozahlung × (1 − min(DBA-Satz_A ; DBA-Satz_B ; Inlandssatz))"),
                Formel(name: "CbCR Risikoindikator",
                       formel: "Auffälligkeit = (Gewinnanteil_Land ÷ Umsatzanteil_Land) − 1 → >+0,5 oder <−0,3: Behördenrisiko"),
                Formel(name: "Profit Split Residualgewinn",
                       formel: "Residualgewinn_A = Gesamtgewinn − RoutinerenditeA − RoutinerenditeB × (WertbeitragA ÷ Gesamtwertbeitrag)")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "UK": true, "US": true, "EU": true, "CN": true]
        ),

        Rechtsgebiet(
            key: "umsatzsteuer",
            label: "Umsatzsteuer / VAT International",
            kurzlabel: "USt / VAT",
            icon: "🧾",
            color: "#27AE60",
            block: "I",
            pflichtfelder: [
                "Leistungsortbestimmung (B2B vs. B2C, § 3a UStG / Art. 44–59 MwStSystRL)",
                "OSS-Registrierung (One-Stop-Shop EU-B2C)",
                "Fiskalvertreter in Drittländern",
                "Reverse-Charge-Mechanismus",
                "Vorsteuerquoten bei gemischter Verwendung"
            ],
            formeln: [
                Formel(name: "Vorsteuerschlüssel gemischte Verwendung",
                       formel: "Abziehbare Vorsteuer = Gesamtvorsteuer × (steuerpflichtige Umsätze ÷ Gesamtumsätze)")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "EU": true, "UK": true]
        ),

        // ── BLOCK II ────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "ip_recht",
            label: "IP / Patent / Marken / Urheberrecht",
            kurzlabel: "IP / Patent",
            icon: "®️",
            color: "#FF2D55",
            block: "II",
            pflichtfelder: [
                "Patentstatus (angemeldet/erteilt/anhängig) mit Anmeldenummern",
                "Ergänzende Schutzzertifikate (SPC Pharma/Pflanzenschutz – max. 5 Jahre)",
                "Arbeitnehmererfindungen (§§ 5–12 ArbEG: Meldepflicht, Vergütungsanspruch)",
                "NPE / Patent Trolls als Gegner",
                "Urheberrecht: Art des Werkes, Nutzungsrechte (einfach/ausschließlich)",
                "Open-Source-Lizenzen im Code (GPL Copyleft-Risiko!)",
                "Datenbankschutz (§§ 87a ff. UrhG)",
                "Markenregistrierungen (DE / EUIPO / WIPO / US USPTO)",
                "Domain-Streitigkeiten (UDRP / DENIC)",
                "Design/Geschmacksmuster (EUIPO: bis 25 Jahre in 5-Jahres-Perioden)",
                "Trade Secrets / Geschäftsgeheimnisse (GeschGehG: Schutzmaßnahmen dokumentiert?)"
            ],
            formeln: [
                Formel(name: "Arbeitnehmererfinder-Vergütung",
                       formel: "Vergütung = Erfindungswert × Anteilsfaktor (2–20% je nach Stellung & Erfindungsanteil)"),
                Formel(name: "Lizenzschadensersatz Urheberrecht (dreifach)",
                       formel: "SE = max(entgangener Gewinn ; Lizenzanalogie ; Verletzergewinn)"),
                Formel(name: "GPL-Kontaminationsrisiko",
                       formel: "Risiko = binär: GPL-Integration in proprietären Code ohne Offenlegung = vollständige Quellcode-Offenlegungspflicht ODER Unterlassung + SE")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "US": true, "UK": true, "CH": true]
        ),

        // ── BLOCK III ───────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "kartellrecht",
            label: "Kartellrecht",
            kurzlabel: "Kartellrecht",
            icon: "⚖️",
            color: "#AF52DE",
            block: "III",
            pflichtfelder: [
                "Fusionskontrolle: Marktanteile, SIEC-Test, Phase I/II (25/90 AT), Gun Jumping",
                "Killer Acquisitions (neue EU-Referenzschwellen)",
                "Horizontale Absprachen (Preise, Mengen, Kapazitäten, Informationsaustausch)",
                "Hub-and-Spoke-Kartell / Algorithmen-Kartelle",
                "Vertikale Beschränkungen: Marktanteile (Safe Harbour <30%), Art der Beschränkung",
                "Mindestpreisbindung (Hardcore – nie freigestellt)",
                "Marktmissbrauch: Marktanteil auf relevantem Markt (sachlich + räumlich)",
                "SSNIP-Test (5–10% Preiserhöhung → Marktabgrenzung)",
                "Kampfpreise (Areeda-Turner-Test: Preis < variable Durchschnittskosten)",
                "Essential Facility Doctrine"
            ],
            formeln: [
                Formel(name: "Upward Pricing Pressure (UPP) Fusionskontrolle",
                       formel: "UPP_A = (Preis_B − Grenzkosten_B) × Diversionsverhältnis_A→B − Effizienzgewinn_A → positiv = Preiserhöhungsdruck"),
                Formel(name: "Safe-Harbour-Prüfung vertikal",
                       formel: "Freistellung wenn: Marktanteil Lieferant ≤30% UND Marktanteil Abnehmer ≤30% UND keine Hardcore-Beschränkung (alle 3 Bedingungen)"),
                Formel(name: "Bußgeld Kartellrecht EU",
                       formel: "Bußgeld = bis 10% des weltweiten Jahresumsatzes + Gewinnabschöpfung; Kronzeuge: bis 100% Reduktion")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "US": true, "UK": true]
        ),

        // ── BLOCK IV ────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "vertragsrecht",
            label: "Vertragsrecht / M&A / Schiedsverfahren",
            kurzlabel: "Vertragsrecht",
            icon: "📝",
            color: "#007AFF",
            block: "IV",
            pflichtfelder: [
                "AGB-Kontrolle (§§ 305 ff. BGB: überraschende Klauseln, unangemessene Benachteiligung)",
                "Störung der Geschäftsgrundlage (§ 313 BGB – COVID, Energie, Krieg)",
                "Force Majeure Definition & Folgen",
                "M&A: Share Deal vs. Asset Deal",
                "Due Diligence Scope (Legal, Financial, Tax, Commercial, Technical, Environmental, HR, IP, IT)",
                "Representations & Warranties, Indemnities, W&R Insurance",
                "Locked-Box vs. Closing Accounts Mechanismus",
                "JV: Governance, Deadlock, Put/Call-Optionen, Tag-Along, Drag-Along",
                "Schiedsvereinbarung (ICC/DIS/LCIA/AAA/VIAC/ad hoc), Schiedsort, Anzahl Schiedsrichter",
                "Emergency Arbitrator (Eilschiedsverfahren <15 Tage)",
                "New York Convention Anerkennung & Vollstreckung (168 Staaten)",
                "eIDAS – qualifizierte elektronische Signatur"
            ],
            formeln: [
                Formel(name: "Locked-Box Kaufpreisanpassung",
                       formel: "Kaufpreis_final = Kaufpreis_Locked-Box + Leakage_Penalty − Permitted_Leakage"),
                Formel(name: "Closing Accounts Kaufpreisanpassung",
                       formel: "Kaufpreis_final = Kaufpreis_initial ± NWC-Anpassung ± Nettoverschuldungs-Anpassung ± Capex-Anpassung"),
                Formel(name: "EBITDA-Multiplikator-Bewertung",
                       formel: "Unternehmenswert = EBITDA × Branchenmultiplikator (Tech-SaaS 8–20×, Industrie 5–9×, Handel 4–7×, Pharma 10–18×)"),
                Formel(name: "Equity Bridge (EV → Eigenkapitalwert)",
                       formel: "Eigenkapitalwert = EV − Nettoverschuldung − Pensionsrückstellungen − schuldenähnliche Posten + Barmittel"),
                Formel(name: "Kostenvergleich Schiedsgericht vs. Staatsgericht",
                       formel: "Schiedskosten ≈ 0,5–2% Streitwert (ICC) + 3 Anwaltshonorare + Gutachten; ab ~500.000 € Streitwert oft günstiger bei int. SV")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "UK": true, "US": true, "EU": true, "FR": true]
        ),

        // ── BLOCK V ─────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "gesellschaftsrecht",
            label: "Gesellschaftsrecht",
            kurzlabel: "Gesellschaftsrecht",
            icon: "🏢",
            color: "#5856D6",
            block: "V",
            pflichtfelder: [
                "Rechtsform & Gründungsdokumente (Gesellschaftsvertrag / Satzung)",
                "Gesellschafterkreis & Beteiligungsquoten",
                "Geschäftsführer / Vorstand (Einzel- oder Gesamtvertretung)",
                "Vinkulierungsklauseln",
                "Gesellschafterbeschlüsse (Quoren: einfache, qualifizierte Mehrheit, Einstimmigkeit)",
                "Treuepflichten, Nachschusspflichten, Abfindungsklauseln",
                "Wettbewerbsverbote der Gesellschafter",
                "Gesellschafterstreit (Deadlock, Ausschlussklage, Auflösungsklage)",
                "Squeeze-out (AG: ab 95%, SE: ab 90%), Delisting",
                "Upstream-Darlehen / Cash Pooling (verdeckte Gewinnausschüttung vermeiden)",
                "Kapitalerhöhung / -herabsetzung"
            ],
            formeln: [
                Formel(name: "Business Judgment Rule – Haftungsfreistellung",
                       formel: "Haftung ausgeschlossen wenn: (1) unternehmerische Entscheidung + (2) keine Interessenkonflikte + (3) angemessene Infobasis + (4) Wohl der Gesellschaft → alle 4 Bedingungen erforderlich"),
                Formel(name: "GmbH Zahlungsunfähigkeits-Schwelle",
                       formel: "Insolvenzantragspflicht wenn: Liquiditätslücke >10% der fälligen Verbindlichkeiten und nicht binnen 3 Wochen schließbar → Antragspflicht binnen 6 Wochen (§ 15a InsO)")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "UK": true, "US": true]
        ),

        // ── BLOCK VI ────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "insolvenzrecht",
            label: "Insolvenzrecht / Restrukturierung",
            kurzlabel: "Insolvenz",
            icon: "📉",
            color: "#FF2D55",
            block: "VI",
            pflichtfelder: [
                "Liquiditätsstatus (21-Tage-Planung & 13-Wochen-Cashflow)",
                "Überschuldungsstatus (Fortführungsprognose? Modifizierte zweistufige Prüfung)",
                "IDW S6 Sanierungsgutachten (Krisenursachen, Leitbild, Maßnahmen, integrierte Planung)",
                "Gläubigerstruktur (besichert / unbesichert, Rangrücktrittsvereinbarungen)",
                "D&O-Versicherung der Geschäftsführer",
                "Verfahrensart (Regelinsolvenz, Schutzschirmverfahren § 270d InsO, StaRUG, WHOA, Cross-Border)",
                "COMI (Centre of Main Interests – zuständiges Insolvenzgericht)",
                "Anfechtungsrisiken (§ 133 InsO: 4 Jahre, bei Vorsatz 30 Jahre)"
            ],
            formeln: [
                Formel(name: "Zahlungsunfähigkeits-Liquiditätslücke",
                       formel: "Lücke = fällige Verbindlichkeiten − verfügbare ZM − kurzfristig mobilisierbare Mittel → ≥10% und nicht binnen 3 Wochen = § 17 InsO"),
                Formel(name: "Überschuldungsstatus",
                       formel: "Saldo = Fortführungswerte Aktiva − Summe Verbindlichkeiten → negativ + keine pos. Fortführungsprognose = Insolvenzantragspflicht"),
                Formel(name: "Insolvenzanfechtung § 133 InsO",
                       formel: "Anfechtbar wenn: Transaktion innerhalb 4 Jahre vor Antrag + Gläubigerbenachteiligung + Kenntnis des Benachteiligungsvorsatzes"),
                Formel(name: "Gläubigerquoten-Simulation",
                       formel: "Quote_ungesichert = (Insolvenzmasse − Masseverbindlichkeiten − bevorrechtigte Forderungen) ÷ Summe ungesicherte Forderungen")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "UK": true, "NL": true]
        ),

        // ── BLOCK VII ───────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "arbeitsrecht",
            label: "Arbeitsrecht",
            kurzlabel: "Arbeitsrecht",
            icon: "👥",
            color: "#FF9500",
            block: "VII",
            pflichtfelder: [
                "Befristungsrecht (§§ 14 ff. TzBfG: sachgrundlose Befristung max. 2 Jahre, 3 Verlängerungen)",
                "Elternzeit / Mutterschutz (Kündigungsverbot, Rückkehranspruch)",
                "Arbeitnehmerüberlassung (AÜG: max. 18 Monate, Equal Pay nach 9 Monaten)",
                "Scheinselbstständigkeit (Weisungsgebundenheit, Betriebsintegration, kein unternehmerisches Risiko)",
                "Betriebsrat & Mitbestimmungsrechte (§ 87 BetrVG: Arbeitszeit, Lohn, Überwachung, Datenschutz)",
                "Betriebsänderung ab 20 MA → Interessenausgleich + Sozialplan (§ 111 BetrVG)",
                "Tarifvertrag (Branche/Haus, Tarifbindung durch Verbandsmitgliedschaft)",
                "Einigungsstelle (Zwangsschlichtung bei Scheitern)"
            ],
            formeln: [
                Formel(name: "Scheinselbstständigkeit SV-Nachzahlung",
                       formel: "SV-Nachzahlung = (AN-Anteil + AG-Anteil) × Honorarsumme × Verjährungszeitraum → 4 Jahre rückwirkend (Vorsatz: 30 Jahre) ≈ 40% des Honorars"),
                Formel(name: "Sozialplan-Dotierung (Faustregel)",
                       formel: "Sozialplan-Volumen = Anzahl MA × Ø Monatsgehalt × Ø Betriebszugehörigkeit × Faktor 0,5–1,5"),
                Formel(name: "Nachteilsausgleich § 113 BetrVG",
                       formel: "Nachteilsausgleich = fiktive Sozialplanabfindung × 1,0–2,0 (Gericht setzt Betrag fest)")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "UK": true, "FR": true]
        ),

        // ── BLOCK VIII ──────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "datenschutz",
            label: "Datenschutz / DSGVO / KI-Act / NIS2",
            kurzlabel: "Datenschutz",
            icon: "🔒",
            color: "#00BCD4",
            block: "VIII",
            pflichtfelder: [
                "DSGVO: Verarbeitungszwecke, Rechtsgrundlagen, Betroffenenrechte, TOM",
                "KI-Act EU: Klassifizierung (verboten/Hochrisiko/begrenzt/minimal)",
                "Hochrisiko-KI (Anhang III): Biometrie, kritische Infrastruktur, Bildung, Beschäftigung, Kreditwürdigkeit, Strafverfolgung",
                "NIS2: Sektorzuordnung (Wesentliche / Wichtige Einrichtung)",
                "NIS2-Meldepflicht: 24h Erstmeldung, 72h Details, 1 Monat Abschlussbericht an BSI",
                "Datentransfers (Drittländer: Angemessenheitsbeschluss, SCCs, BCR)",
                "Datenlokalisierung China (PIPL)"
            ],
            formeln: [
                Formel(name: "DSGVO-Bußgeld",
                       formel: "max(20 Mio. € ; 4% weltweiter Jahresumsatz) für Art. 83 Abs. 5 Verstöße"),
                Formel(name: "KI-Act Bußgeld",
                       formel: "Verbotene KI: max(35 Mio. € ; 7% Weltumsatz). Hochrisiko-Verstöße: max(15 Mio. € ; 3%). Falsche Infos: max(7,5 Mio. € ; 1,5%)"),
                Formel(name: "NIS2-Bußgeld",
                       formel: "Wesentliche Einrichtung: max(10 Mio. € ; 2% Weltumsatz). Wichtige Einrichtung: max(7 Mio. € ; 1,4% Weltumsatz)")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "UK": true, "US": true, "CN": true, "CH": true]
        ),

        // ── BLOCK IX ────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "kapitalmarktrecht",
            label: "Kapitalmarktrecht / ESG / CSRD",
            kurzlabel: "Kapitalmarkt",
            icon: "📈",
            color: "#FF6B35",
            block: "IX",
            pflichtfelder: [
                "MAR: Insiderhandel, Marktmanipulation, Ad-hoc-Pflichten",
                "Leerverkäufe (Short Selling Regulation: ab 0,2% melden, ab 0,5% veröffentlichen)",
                "Derivate / Hedging (EMIR: Clearing-Pflicht, Meldepflicht Transaktionsregister)",
                "Aktienrückkauf Safe Harbour (MAR: max. 25% Tageshandelsvolumen)",
                "CSRD / ESRS: E1-E5, S1-S4, G1 (Double Materiality)",
                "EU-Taxonomie Klassifizierung",
                "SFDR (Sustainable Finance Disclosure Regulation)"
            ],
            formeln: [
                Formel(name: "Double Materiality Score CSRD",
                       formel: "DM = finanzielle Wesentlichkeit (0–5) × Impact-Wesentlichkeit (0–5) → Produkt ≥9 ODER beide Dimensionen ≥3: berichtspflichtig")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "UK": true, "US": true]
        ),

        // ── BLOCK X ─────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "compliance",
            label: "Regulierung / Compliance (Finanz, Pharma, Energie, TK)",
            kurzlabel: "Compliance",
            icon: "✅",
            color: "#4CAF50",
            block: "X",
            pflichtfelder: [
                "Finanzregulierung: BaFin-Lizenz, Basel IV (CET1 min. 7%), LCR ≥100%, NSFR ≥100%, MiFID II, GwG",
                "Pharma: EMA/BfArM-Zulassung, Pharmakovigilanz (15/90-Tage-Meldung), GMP, klinische Studien",
                "Energie: Netzzugangsrecht (§ 20 EnWG), EEG-Vergütung, EU-ETS CO₂-Zertifikate",
                "Telekommunikation: Marktregulierung BNetzA, Frequenzzuteilungen, TTDSG/TKG-Datenschutz"
            ],
            formeln: [
                Formel(name: "CET1-Quote Basel IV",
                       formel: "CET1 = (hartes Kernkapital ÷ risikogewichtete Aktiva) × 100 → Mindest 4,5% + 2,5% Kapitalerhaltungspuffer = effektiv 7%"),
                Formel(name: "Leverage Ratio",
                       formel: "LR = (Kernkapital ÷ Gesamtrisikopositionsmessgröße) × 100 → Mindest 3% nach Basel IV"),
                Formel(name: "ETS-Kosten-Prognose",
                       formel: "ETS_Kosten = (Ist-Emissionen − kostenlos zugeteilte Zertifikate) × ETS-Marktpreis (ca. 60–70 €/tCO₂)"),
                Formel(name: "Marktexklusivitäts-Restdauer Pharma",
                       formel: "Restdauer = Patentablauf − heute + SPC-Verlängerung (max. 5 J) + Kinderarzneimittel-Prämie (6 Monate)")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "UK": true, "US": true, "CH": true]
        ),

        // ── BLOCK XI ────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "strafrecht",
            label: "Wirtschaftsstrafrecht / Internal Investigation",
            kurzlabel: "Wirtschaftsstrafrecht",
            icon: "🚨",
            color: "#FF3B30",
            block: "XI",
            pflichtfelder: [
                "Compliance-Management-System (IDW PS 980 als Haftungsmilderung)",
                "Straftaten: Untreue § 266, Betrug § 263, Bestechung § 299, Steuerhinterziehung § 370 AO, Geldwäsche § 261, Korruption §§ 331–335",
                "Internal Investigation (wer leitet? Anwaltsprivileg, Legal Hold, Dokumentensicherung)",
                "FCPA / UK Bribery Act (extraterritorial für dt. Unternehmen!)",
                "Whistleblower-Anzeige (intern / extern)",
                "Hausdurchsuchungsprotokoll (sofort Anwalt, keine Aussage, keine Vernichtung)",
                "Selbstanzeige Steuerhinterziehung § 371 AO (vollständig, rechtzeitig, keine Entdeckung)",
                "Verbandssanktionengesetz DE (geplant: bis 10 Mio. € oder 10% Jahresumsatz)"
            ],
            formeln: [
                Formel(name: "Steuerhinterziehung Selbstanzeige Nachzahlung",
                       formel: "Nachzahlung = Hinterziehungsbetrag + Zinsen (1,8% p.a.) + Strafzuschlag (>100k€: 10%; >1M€: 15%; >2M€: 20%) → entfällt bei sofortiger Zahlung <100k€"),
                Formel(name: "FCPA-Mindestbußgeld",
                       formel: "Mindestbußgeld = max(erlangter Vorteil × 2 ; US Sentencing Guidelines) → bis 50% Reduktion bei proaktiver Offenlegung + Kooperation")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "UK": true, "US": true]
        ),

        // ── BLOCK XII ───────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "immobilienrecht",
            label: "Immobilien- und Baurecht",
            kurzlabel: "Immobilien",
            icon: "🏗️",
            color: "#8E6D3E",
            block: "XII",
            pflichtfelder: [
                "Grundbuchauszug (Eigentümer, Abt. II Lasten, Abt. III Grundschulden)",
                "Baugenehmigung (vorhanden? Auflagen? Bestandsschutz?)",
                "Bebauungsplan: GRZ, GFZ, Baulinie, Nutzungsart",
                "Gewerbemietverträge (Laufzeit, Indexierung, Nebenkosten, Optionsrechte)",
                "ESG-Anforderungen (EU-Taxonomie, CRREM-Pfad, Energieausweis)",
                "Mängelrechte Bau (§§ 633 ff. BGB, HOAI-Honorarstreit, Bauhandwerkersicherung § 648a BGB)"
            ],
            formeln: [
                Formel(name: "Mietwert-Indexierung (Gewerbe)",
                       formel: "Neue Miete = Ausgangsmiete × (aktueller VPI ÷ VPI zum Vertragsbeginn)"),
                Formel(name: "Ertragswertmethode Immobilie",
                       formel: "Ertragswert = Jahresreinertrag ÷ Liegenschaftszinssatz (Büro Innenstadt 3–4%; Einzelhandel 4–6%; Logistik 5–7%)")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true]
        ),

        // ── BLOCK XIII ──────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "vergaberecht",
            label: "Vergaberecht",
            kurzlabel: "Vergabe",
            icon: "🏛️",
            color: "#607D8B",
            block: "XIII",
            pflichtfelder: [
                "Auftragswert vs. EU-Schwellenwerte 2024 (Liefer-/DL: 221.000 €; Bau: 5.538.000 €)",
                "Verfahrensart (offen, nicht offen, Verhandlung, wettbewerbl. Dialog, Innovationspartnerschaft)",
                "Eignungsnachweise (Umsatz, Referenzen, Zertifizierungen)",
                "Zuschlagskriterien (wirtschaftlich günstigstes Angebot – Preis allein verboten bei OJEU)",
                "Rügeobliegenheit (§ 160 GWB: sofort rügen sonst kein Nachprüfungsantrag!)"
            ],
            formeln: [
                Formel(name: "Gewichtete Angebotsbewertung",
                       formel: "Gesamtpunktzahl = (Preis-Punkte × Preisgewichtung) + (Qualitäts-Punkte × Qualitätsgewichtung) + …"),
                Formel(name: "Schadensersatz rechtswidriger Zuschlag",
                       formel: "SE = entgangener Gewinn (Deckungsbeitrag des Auftrags) ODER nur Angebotserstellungskosten wenn Zuschlag nicht hätte erteilt werden dürfen")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "AT": true, "CH": true]
        ),

        // ── BLOCK XIV ───────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "erbrecht",
            label: "Erbrecht / Unternehmensnachfolge",
            kurzlabel: "Erbrecht",
            icon: "📜",
            color: "#795548",
            block: "XIV",
            pflichtfelder: [
                "Testament / Erbvertrag (vorhanden? aktuell?)",
                "Pflichtteilsberechtigte (Kinder, Ehepartner: 50% gesetzliches Erbteil – nicht entziehbar)",
                "Unternehmensbewertung für ErbSt (vereinfachtes Ertragswertverfahren §§ 199 ff. BewG)",
                "Verschonungsregelung (§§ 13a/13b ErbStG: 85% oder 100% Verschonung – Lohnsummenregel, Behaltensfrist 5/7 J)",
                "Vorweggenommene Erbfolge (Schenkung: 10-Jahres-Freibetrag 400k€ je Kind je Elternteil)",
                "Familienpool (GmbH & Co. KG als Übertragungsstruktur)"
            ],
            formeln: [
                Formel(name: "Erbschaftsteuer-Schätzung",
                       formel: "ErbSt = (Steuerwert − Freibetrag) × Steuersatz; Freibeträge: Partner 500k€, Kind 400k€, Enkel 200k€; Steuersätze Kl. I: 7–30%"),
                Formel(name: "Vereinfachtes Ertragswertverfahren BewG",
                       formel: "Steuerwert = nachhaltig erzielbarer Jahresertrag ÷ 13,75%; Jahresertrag = Ø 3 Jahre bereinigt um außerordentliche Effekte")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true]
        ),

        // ── BLOCK XV ────────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "versicherungsrecht",
            label: "Versicherungsrecht",
            kurzlabel: "Versicherung",
            icon: "🛡️",
            color: "#009688",
            block: "XV",
            pflichtfelder: [
                "Versicherungsarten: D&O, Produkthaftpflicht, Betriebshaftpflicht, Cyber, Rechtsschutz, Transport, Kredit, Kaution, Betriebsunterbrechung",
                "Versicherungssummen & Selbstbehalte",
                "Anzeigepflichten (§ 19 VVG – Verletzung = Leistungsfreiheit!)",
                "Obliegenheiten im Schadensfall (sofortige Meldung, Schadensminimierung, keine Regulierungszusagen ohne Versicherer)",
                "D&O-Inanspruchnahme (wann greift D&O ein?)",
                "Cyber-Deckung (Ransomware: Lösegeld, Betriebsunterbrechung, Drittschäden)"
            ],
            formeln: [
                Formel(name: "Betriebsunterbrechungs-Entschädigung",
                       formel: "BU-Leistung = (Tagesbeitrag × Unterbrechungstage) − ersparte Kosten − anderweitige Einnahmen; Tagesbeitrag = Jahresumsatz × Deckungsbeitragsquote ÷ 365")
            ],
            jurisdiktionen: ["DE": true, "AT": true, "CH": true, "UK": true]
        ),

        // ── BLOCK XVI ───────────────────────────────────────────────────────
        Rechtsgebiet(
            key: "prozessrecht",
            label: "Prozessrecht (National & International)",
            kurzlabel: "Prozessrecht",
            icon: "⚖️",
            color: "#455A64",
            block: "XVI",
            pflichtfelder: [
                "Gerichtsstand (§§ 12 ff. ZPO: allgemeiner = Sitz Beklagter; besondere: Erfüllungsort, Deliktsort)",
                "Streitwert & Zuständigkeit (<5.000 € = AG; >5.000 € = LG)",
                "Einstweiliger Rechtsschutz (Arrest, einstweilige Verfügung: Dringlichkeit, Verfügungsanspruch, -grund)",
                "Beweislastverteilung",
                "Verjährungsfristen (Regel: 3 Jahre § 195 BGB; Beginn 1. Januar nach Entstehung & Kenntnis)",
                "IPR: Rom I-VO (Verträge), Rom II-VO (Delikt), Eingriffsnormen, ordre public",
                "US: Class Actions, Punitive Damages (3×), Discovery",
                "US-UK: Common Law, Präzedenzfälle"
            ],
            formeln: [
                Formel(name: "Prozesskostenrisiko",
                       formel: "Gesamtkosten bei Verlust = GKG-Gebühren + eigene RVG-Gebühren + gegnerische RVG-Gebühren → bei 500k€ Streitwert ca. 35.000–60.000 €"),
                Formel(name: "Kostenquotelung bei Teilsieg",
                       formel: "Kostenanteil = (unterlegener Betrag ÷ Gesamtstreitwert) × Gesamtkosten")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "UK": true, "US": true, "CH": true, "FR": true]
        ),

        // ── ERGÄNZUNG: Medienrecht ──────────────────────────────────────────
        Rechtsgebiet(
            key: "medienrecht",
            label: "Medien- und Presserecht",
            kurzlabel: "Medienrecht",
            icon: "📺",
            color: "#E91E63",
            block: "Erg.",
            pflichtfelder: [
                "Rundfunk- / Medienstaatsvertrag (MStV): Plattformen, Intermediäre, Algorithmentransparenz",
                "Digital Services Act (DSA): VLOP/VLOSE-Status (>45 Mio. EU-Nutzer), Risikobewertungspflichten",
                "Presserecht: Gegendarstellungsrecht, Unterlassungsklage, Persönlichkeitsrecht",
                "Leistungsschutzrecht Presseverlage (§ 87g UrhG / Art. 15 DSM-Richtlinie)",
                "NetzDG / Hate Speech (Löschpflicht rechtswidriger Inhalte ≥2 Mio. registrierte Nutzer)"
            ],
            formeln: [
                Formel(name: "DSA-Bußgeld",
                       formel: "max(6% weltweiter Jahresumsatz) für VLOP/VLOSE-Verstöße; max(1% bei falschen Informationen)")
            ],
            jurisdiktionen: ["DE": true, "EU": true]
        ),

        // ── ERGÄNZUNG: Rüstung/Export ───────────────────────────────────────
        Rechtsgebiet(
            key: "exportkontrolle",
            label: "Exportkontrolle / Dual-Use / Rüstung",
            kurzlabel: "Export",
            icon: "🔐",
            color: "#37474F",
            block: "Erg.",
            pflichtfelder: [
                "AWG / AWV: Ausfuhrgenehmigungspflicht für Dual-Use-Güter (EU-Dual-Use-VO 2021/821)",
                "ITAR / EAR (USA): extraterritorial für US-Technologie-Komponenten",
                "Sanktionslisten (EU, UN, OFAC-SDN, OFAC-SSI) – Embargo-Prüfung jeder Transaktion",
                "Russland-Sanktionen (EU-Sanktionspakete – Güter, Dienstleistungen, Finanzierung)",
                "China-Trade-Controls (BIS Entity List, FDP Rule – Foreign Direct Product Rule)",
                "Kriegswaffenkontrollgesetz (KWKG) für Rüstungsgüter"
            ],
            formeln: [
                Formel(name: "OFAC-Zivilbuße",
                       formel: "max(Transaktionswert × 2 ; 375.579 USD pro Verstoß, Stand 2024) + Strafverfolgung bei Vorsatz")
            ],
            jurisdiktionen: ["DE": true, "EU": true, "US": true, "UK": true]
        )
    ]

    // MARK: - Lookup-Maps

    /// Pendant zu `RG_BY_KEY` (Object.fromEntries(...)).
    /// Wird einmalig beim ersten Zugriff berechnet.
    public static let byKey: [String: Rechtsgebiet] = {
        var dict: [String: Rechtsgebiet] = [:]
        for rg in alle {
            dict[rg.key] = rg
        }
        return dict
    }()

    /// Bequemer Lookup nach Schlüssel.
    public static func find(byKey key: String) -> Rechtsgebiet? {
        return byKey[key]
    }

    /// Pendant zu `KEY_COMPAT` – mappt alte 9 Schlüssel auf neue.
    public static let keyCompat: [String: String] = [
        "vertragsrecht":      "vertragsrecht",
        "gesellschaftsrecht": "gesellschaftsrecht",
        "kartellrecht":       "kartellrecht",
        "steuerrecht":        "steuerrecht_national",
        "arbeitsrecht":       "arbeitsrecht",
        "datenschutz":        "datenschutz",
        "ip_recht":           "ip_recht",
        "compliance":         "compliance",
        "strafrecht":         "strafrecht"
    ]

    /// Lookup, der das Compat-Mapping berücksichtigt.
    public static func findResolvingCompat(_ rawKey: String) -> Rechtsgebiet? {
        let resolved = keyCompat[rawKey] ?? rawKey
        return byKey[resolved]
    }

    // MARK: - Übergreifende Systemformeln

    /// Pendant zu `SYSTEM_FORMELN`.
    public static let systemFormeln = SystemFormeln(
        gesamtrisiko: "GRW = Σ (Schadenshöhe_i × Eintrittswahrscheinlichkeit_i × Zeitgewichtungsfaktor_i × Korrelationskoeffizient_ij)",
        monteCarlo: "10.000 Läufe → 5%-Quantil (Best Case), 50%-Quantil (Erwartungswert), 95%-Quantil (Worst Case)",
        wechselwirkung: "Wenn RG_A und RG_B beide aktiv → automatische Schnittmengen-Prüfung (z.B. Kartellrecht + M&A + Steuer bei Fusion)"
    )

    // MARK: - Jurisdiktions-Differenzierung

    /// Pendant zu `JURISDIKTIONEN` (US, UK, CH, FR, CN).
    public static let jurisdiktionen: [String: JurisdiktionInfo] = [
        "US": JurisdiktionInfo(
            label: "USA",
            besonderheiten: [
                "Common Law (Präzedenzfälle entscheidend)",
                "Class Actions mit Punitive Damages (bis 3× Schadensersatz)",
                "Discovery (umfassende Dokumentenoffenlegung)",
                "FCPA (extraterritorial)",
                "SOX (Sarbanes-Oxley: interne Kontrollen börsennotierte AG)",
                "Delaware Corporate Law"
            ]
        ),
        "UK": JurisdiktionInfo(
            label: "UK",
            besonderheiten: [
                "Common Law, post-Brexit eigenständige Regulierung",
                "UK GDPR, UK Competition Act, FCA",
                "UK Bribery Act (strengster Anti-Korruptionsstandard: keine Ausnahme für kleine Zahlungen)",
                "SONIA (LIBOR-Nachfolger für Kreditverträge)"
            ]
        ),
        "CH": JurisdiktionInfo(
            label: "Schweiz",
            besonderheiten: [
                "Kein EU-Mitglied (eigenes DSG seit 2023, kein DSGVO)",
                "OR (Obligationenrecht) statt BGB",
                "Schiedsgerichtsbarkeit Genf (ICC, Swiss Rules) – globaler Standard",
                "Banking Secrecy (eingeschränkt durch FATCA/AEOI)",
                "Kantonssteuer-Varianz"
            ]
        ),
        "FR": JurisdiktionInfo(
            label: "Frankreich",
            besonderheiten: [
                "Code Civil, SAS (flexibelste Gesellschaftsform)",
                "Arbeitnehmerfreundlich: Comité Social et Économique, Gewinnbeteiligung Pflicht",
                "SAPIN II (Anti-Korruption mit Compliance-Pflichten für Unternehmen >500 MA / >100 Mio. € Umsatz)"
            ]
        ),
        "CN": JurisdiktionInfo(
            label: "China",
            besonderheiten: [
                "Investitionsbeschränkungen (Negative List)",
                "PIPL (Personal Information Protection Law = chinesische DSGVO)",
                "Datenlokalisierung: sensible Daten dürfen China nicht verlassen",
                "Anti-Monopol-Gesetz (Fusionskontrolle: SAMR)",
                "VIE-Struktur für ausländische Investitionen in regulierten Sektoren"
            ]
        )
    ]
}

// MARK: - Services/BackendFunctions/CaseComplianceService.swift

@MainActor
public final class CaseComplianceService: ObservableObject {
    private let kiProvider: KIProvider
    private let cloudKit:   CloudKitService
    public init(kiProvider: KIProvider, cloudKit: CloudKitService) {
        self.kiProvider = kiProvider; self.cloudKit = cloudKit
    }

    public struct ComplianceWarning: Codable, Hashable {
        public var typ: String                // "rechtsfehler" | "frist" | "form" | "anhörung" | "beweis"
        public var schweregrad: String        // "hoch" | "mittel" | "niedrig"
        public var titel: String
        public var beschreibung: String
        public var paragraph: String?
        public var empfehlung: String
        public var betroffenes_objekt_typ: String?    // "case" | "argument" | "deadline" | "evidence"
        public var betroffenes_objekt_id: String?
    }

    public struct ComplianceResult: Codable, Hashable {
        public var warnings: [ComplianceWarning]
        public var gesamtbewertung: String?
        public var compliance_score: Int?     // 0–100
    }

    public func check(caseEntity: Case,
                      arguments: [Argument],
                      evidence: [Evidence],
                      deadlines: [Deadline],
                      persons: [Person]) async throws -> ComplianceResult {

        let prompt = """
        Du bist ein erfahrener juristischer Compliance-Prüfer (Senior Partner Niveau).
        Prüfe den folgenden Fall auf JURISTISCHE COMPLIANCE-RISIKEN, FORMFEHLER, FRISTPROBLEME und PROZEDURALE SCHWACHSTELLEN.

        Berücksichtige insbesondere:
        - Form- und Fristenrecht der ZPO/StPO/VwGO
        - Anhörungsrechte (Art. 103 GG)
        - Beweislastregeln
        - Verfahrensgrundsätze
        - Mögliche Berufungs-/Revisionsgründe

        FALL:
        - Fallname: \(caseEntity.fallname)
        - Rechtsgebiet: \(caseEntity.rechtsgebiet ?? "?")
        - Gericht: \(caseEntity.gericht ?? "?")
        - Status: \(caseEntity.status.rawValue)
        - Instanz: \(caseEntity.instanz.rawValue)
        - Zentrale Rechtsfrage: \(caseEntity.zentraleRechtsfrage ?? "?")
        - Streitwert: \(caseEntity.streitwert.map { "\(Int($0)) €" } ?? "?")

        ARGUMENTE (\(arguments.count)):
        \(arguments.prefix(10).map { "- [\($0.side.rawValue)] \($0.title) (Stärke: \($0.kiStrength ?? $0.strength ?? 5))" }.joined(separator: "\n"))

        BEWEISE (\(evidence.count)):
        \(evidence.prefix(10).map { "- \($0.title) (Gewicht: \($0.kiWeight ?? $0.weight ?? 5))" }.joined(separator: "\n"))

        FRISTEN (\(deadlines.count)):
        \(deadlines.prefix(10).map { "- \($0.title) [\($0.status.rawValue)]" }.joined(separator: "\n"))

        PERSONEN (\(persons.count)):
        \(persons.prefix(10).map { "- \($0.name) (\($0.role.rawValue))" }.joined(separator: "\n"))

        Gib max. 15 KONKRETE Warnungen zurück, sortiert nach Schweregrad. Erfinde keine Vorschriften – wenn unsicher, weglassen.
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "warnings": ["type": "array", "items": ["type": "object",
                    "properties": [
                        "typ": ["type": "string"],
                        "schweregrad": ["type": "string"],
                        "titel": ["type": "string"],
                        "beschreibung": ["type": "string"],
                        "paragraph": ["type": "string"],
                        "empfehlung": ["type": "string"],
                        "betroffenes_objekt_typ": ["type": "string"],
                        "betroffenes_objekt_id":  ["type": "string"]
                    ]
                ]],
                "gesamtbewertung": ["type": "string"],
                "compliance_score": ["type": "number"]
            ]
        ]
        let raw = try await kiProvider.invokeLLM(prompt: prompt, schema: schema)
        let result = try JSONDecoder().decode(ComplianceResult.self,
                                              from: raw.data(using: .utf8) ?? Data())

        // Persistiere als CaseWarning-Records
        for w in result.warnings {
            let typ: WarningType = {
                switch w.typ.lowercased() {
                case "frist":          return .fehlenderBeleg
                case "form":           return .diskrepanz
                case "anhörung", "anhoerung": return .unterstuetzungFehlt
                case "beweis":         return .fehlenderBeleg
                default:               return .widerspruch
                }
            }()
            let sev: WarningSeverity = {
                switch w.schweregrad.lowercased() {
                case "kritisch":  return .kritisch
                case "hoch":      return .hoch
                case "niedrig":   return .niedrig
                default:          return .mittel
                }
            }()
            var cw = CaseWarning(caseId: caseEntity.id, warningType: typ, title: w.titel)
            cw.severity = sev
            cw.warningDescription = w.beschreibung
            cw.suggestion = w.empfehlung
            cw.rsprReference = w.paragraph
            cw.elementType = w.betroffenes_objekt_typ.flatMap { WarningElementType(rawValue: $0) }
            cw.elementId = w.betroffenes_objekt_id
            _ = try? await cloudKit.save(cw)
        }
        return result
    }
}

// MARK: - Services/BackendFunctions/CaseHistoryLogger.swift

@MainActor
public final class CaseHistoryLogger: ObservableObject {
    private let cloudKit: CloudKitService
    private let auth:     AuthService
    public init(cloudKit: CloudKitService, auth: AuthService) {
        self.cloudKit = cloudKit; self.auth = auth
    }

    public func log(caseId: String,
                    entityType: CaseHistoryEntityType,
                    action: CaseHistoryAction,
                    entityId: String? = nil,
                    entityTitle: String? = nil,
                    fieldChanged: String? = nil,
                    oldValue: String? = nil,
                    newValue: String? = nil,
                    summary: String? = nil) async {
        var hist = CaseHistory(caseId: caseId, entityType: entityType, action: action)
        hist.entityId = entityId
        hist.entityTitle = entityTitle
        hist.fieldChanged = fieldChanged
        hist.oldValue = oldValue
        hist.newValue = newValue
        hist.summary = summary
        hist.userEmail = auth.currentUser?.email
        hist.timestamp = Date()
        _ = try? await cloudKit.save(hist)
    }
}

// MARK: - Services/BackendFunctions/CasePDFExportService.swift

@MainActor
public enum CasePDFExportService {

    /// Exportiert einen vollständigen Fallbericht als PDF.
    /// Lädt automatisch alle zugehörigen Argumente, Beweise, Personen, Fristen aus CloudKit.
    public static func export(caseEntity: Case,
                              arguments: [Argument],
                              evidence:  [Evidence],
                              persons:   [Person],
                              deadlines: [Deadline]) -> Data? {

        let pageWidth: CGFloat  = 612    // US-Letter (auch DIN-A4-tauglich)
        let pageHeight: CGFloat = 792
        let margin: CGFloat     = 50
        let contentW: CGFloat   = pageWidth - 2 * margin

        let pdfMetadata: [CFString: Any] = [
            kCGPDFContextTitle:   "MachiavelLEX – Fallbericht: \(caseEntity.fallname)" as CFString,
            kCGPDFContextAuthor:  "LegalOS" as CFString,
            kCGPDFContextCreator: "LegalOS macOS App" as CFString
        ]

        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let consumer = CGDataConsumer(data: pdfData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox,
                                  pdfMetadata as CFDictionary) else { return nil }

        var y: CGFloat = pageHeight - margin
        ctx.beginPDFPage(nil)

        // Drawing-Helper
        func newPageIfNeeded(_ space: CGFloat) {
            if y - space < margin {
                ctx.endPDFPage()
                ctx.beginPDFPage(nil)
                y = pageHeight - margin
            }
        }

        func addText(_ text: String, size: CGFloat = 10,
                     bold: Bool = false, color: NSColor = .black) {
            newPageIfNeeded(size + 6)
            let font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
            let para = NSMutableParagraphStyle()
            para.lineBreakMode = .byWordWrapping
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font, .foregroundColor: color, .paragraphStyle: para
            ]
            let attr = NSAttributedString(string: text, attributes: attrs)
            let frame = CGRect(x: margin, y: y - 100, width: contentW, height: 100)
            let path = CGPath(rect: frame, transform: nil)
            let framesetter = CTFramesetterCreateWithAttributedString(attr)
            let textFrame = CTFramesetterCreateFrame(framesetter,
                CFRange(location: 0, length: 0), path, nil)
            let lines = CTFrameGetLines(textFrame) as! [CTLine]
            let lineHeight: CGFloat = size + 4
            for line in lines {
                let lineY = y
                ctx.textPosition = CGPoint(x: margin, y: lineY - size)
                CTLineDraw(line, ctx)
                y -= lineHeight
            }
            y -= 2
        }

        func addSection(_ title: String) {
            y -= 6
            newPageIfNeeded(20)
            ctx.setFillColor(NSColor(white: 0.94, alpha: 1).cgColor)
            ctx.fill(CGRect(x: margin - 5, y: y - 14, width: contentW + 10, height: 16))
            addText(title, size: 11, bold: true)
            y -= 4
        }

        func addRule() {
            ctx.setStrokeColor(NSColor(white: 0.78, alpha: 1).cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: margin, y: y))
            ctx.addLine(to: CGPoint(x: margin + contentW, y: y))
            ctx.strokePath()
            y -= 6
        }

        // ── Header ──────────────────────────────────────────────────
        addText("MachiavelLEX – Fallbericht", size: 18, bold: true)
        let df = DateFormatter()
        df.dateStyle = .long; df.locale = Locale(identifier: "de_DE")
        addText("Erstellt am \(df.string(from: Date()))",
                size: 9, color: NSColor(white: 0.45, alpha: 1))
        y -= 4
        addRule()

        // ── 1. Basisdaten ───────────────────────────────────────────
        addSection("1. Basisdaten")
        addText("Fallname: \(caseEntity.fallname)", size: 10, bold: true)
        if let v = caseEntity.aktenzeichen { addText("Aktenzeichen: \(v)") }
        if let v = caseEntity.gericht { addText("Gericht: \(v)") }
        if let v = caseEntity.rechtsgebiet { addText("Rechtsgebiet: \(v)") }
        addText("Status: \(caseEntity.status.rawValue)")
        addText("Instanz: \(caseEntity.instanz.rawValue)")
        if let v = caseEntity.streitwert { addText("Streitwert: \(formatEuro(v))") }

        // ── 2. KI-Prognose ──────────────────────────────────────────
        addSection("2. KI-Prognose")
        addText("Erfolgswahrscheinlichkeit: \(Int(caseEntity.prognose ?? 0)) %",
                size: 11, bold: true)
        if let v = caseEntity.zentraleRechtsfrage { addText("Zentrale Rechtsfrage: \(v)") }
        if let v = caseEntity.prozessziel { addText("Prozessziel: \(v)") }

        // ── 3. Argumentketten ───────────────────────────────────────
        addSection("3. Argumentketten")
        let eigene = arguments.filter { $0.side == .eigen }
        let gegner = arguments.filter { $0.side == .gegner }
        addText("Eigene Argumente (\(eigene.count)):", size: 10, bold: true)
        for (i, a) in eigene.enumerated() {
            let st = a.kiStrength ?? a.strength
            addText("\(i + 1). \(a.title) (Stärke: \(st.map { "\(Int($0))" } ?? "-")/10)")
            if let d = a.argDescription { addText("   \(d)", size: 9, color: NSColor(white: 0.3, alpha: 1)) }
        }
        y -= 2
        addText("Gegner-Argumente (\(gegner.count)):", size: 10, bold: true)
        for (i, a) in gegner.enumerated() {
            let st = a.kiStrength ?? a.strength
            addText("\(i + 1). \(a.title) (Stärke: \(st.map { "\(Int($0))" } ?? "-")/10)")
        }

        // ── 4. Beweislage ───────────────────────────────────────────
        addSection("4. Beweislage")
        if evidence.isEmpty {
            addText("Keine Beweise erfasst.")
        } else {
            for (i, e) in evidence.enumerated() {
                let w = e.kiWeight ?? e.weight
                addText("\(i + 1). \(e.title) – Gewicht: \(w.map { "\(Int($0))" } ?? "-")/10")
                if let d = e.evidenceDescription {
                    addText("   \(d)", size: 9, color: NSColor(white: 0.3, alpha: 1))
                }
            }
        }

        // ── 5. Personen ─────────────────────────────────────────────
        addSection("5. Beteiligte Personen")
        if persons.isEmpty {
            addText("Keine Personen erfasst.")
        } else {
            for (i, p) in persons.enumerated() {
                let org = p.organization.map { " (\($0))" } ?? ""
                addText("\(i + 1). \(p.name) – \(p.role.rawValue)\(org)")
                if let g = p.glaubwuerdigkeit {
                    addText("   Glaubwürdigkeit: \(Int(g))%", size: 9,
                            color: NSColor(white: 0.3, alpha: 1))
                }
            }
        }

        // ── 6. Fristen ──────────────────────────────────────────────
        addSection("6. Fristen")
        let dateF = DateFormatter()
        dateF.dateStyle = .medium; dateF.locale = Locale(identifier: "de_DE")
        let sorted = deadlines.sorted { $0.dueDate < $1.dueDate }
        if sorted.isEmpty {
            addText("Keine Fristen erfasst.")
        } else {
            for (i, d) in sorted.enumerated() {
                addText("\(i + 1). \(d.title) – Fällig: \(dateF.string(from: d.dueDate)) [\(d.status.rawValue)]")
            }
        }

        // ── Footer ──────────────────────────────────────────────────
        y -= 6
        addRule()
        addText("LegalOS – Legal Intelligence Platform",
                size: 8, color: NSColor(white: 0.6, alpha: 1))

        ctx.endPDFPage()
        ctx.closePDF()
        return pdfData as Data
    }

    /// Speichert das PDF mit einem System-Save-Dialog.
    public static func saveToFile(_ data: Data, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}

// Hilfsformatierung
private func formatEuro(_ v: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal
    nf.locale = Locale(identifier: "de_DE")
    nf.maximumFractionDigits = 0
    return (nf.string(from: NSNumber(value: v)) ?? "\(Int(v))") + " €"
}

// MARK: - Services/BackendFunctions/DeadlineAlertService.swift

@MainActor
public enum DeadlineAlertService {

    /// Fragt einmalig die Notification-Berechtigung an.
    public static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Plant für jede offene Frist eine lokale Notification 3 / 1 / 0 Tage vorher.
    public static func scheduleAlerts(for deadlines: [Deadline], caseName: String) async {
        let center = UNUserNotificationCenter.current()
        for d in deadlines where d.status == .offen {
            for offsetDays in [3, 1, 0] {
                guard let trigger = makeTrigger(for: d.dueDate, offsetDays: offsetDays) else { continue }
                let content = UNMutableNotificationContent()
                content.title = "⚖️ \(d.title)"
                content.subtitle = caseName
                content.body = offsetDays == 0
                    ? "HEUTE fällig!"
                    : "Fällig in \(offsetDays) Tag\(offsetDays == 1 ? "" : "en") – \(formattedDate(d.dueDate))"
                content.sound = .default
                let id = "deadline-\(d.id)-\(offsetDays)"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(req)
            }
        }
    }

    /// Entfernt ggf. alte geplante Notifications für eine Frist.
    public static func cancelAlerts(for deadlineId: String) {
        let ids = [3, 1, 0].map { "deadline-\(deadlineId)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func makeTrigger(for date: Date, offsetDays: Int) -> UNCalendarNotificationTrigger? {
        guard let target = Calendar.current.date(byAdding: .day, value: -offsetDays, to: date),
              target > Date() else { return nil }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: target)
        comps.hour = 9; comps.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }

    private static func formattedDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium; f.locale = Locale(identifier: "de_DE")
        return f.string(from: d)
    }
}

// MARK: - Services/BackendFunctions/DocumentAnalysisService.swift

@MainActor
public final class DocumentAnalysisService: ObservableObject {
    private let kiProvider: KIProvider
    private let cloudKit:   CloudKitService

    public init(kiProvider: KIProvider, cloudKit: CloudKitService) {
        self.kiProvider = kiProvider
        self.cloudKit = cloudKit
    }

    /// Vollständige Analyse-Ergebnis-Struktur (mappt auf das JSON-Schema).
    public struct AnalysisResult: Codable, Hashable {
        public var zusammenfassung: String?
        public var basisdaten: Basisdaten?
        public var streitwert: Double?
        public var argumente: [ExtArgument]?
        public var beweise:   [ExtEvidence]?
        public var fristen:   [ExtFrist]?
        public var personen:  [ExtPerson]?
        public var schritt3_gegneranalyse: Gegneranalyse?
        public var schritt4_rechtliche_analyse: RechtlicheAnalyse?
        public var schritt5_strategie: Strategie?
        public var schritt6_risiko: Risiko?
        public var schritt7_simulation: Simulation?
        public var schritt8_aktion: Aktion?
        public var schritt9_cockpit: Cockpit?
        public var schritt10_abschluss: Abschluss?
        public var informationsluecken: [InfoLuecke]?

        public struct Basisdaten: Codable, Hashable {
            public var gericht: String?
            public var aktenzeichen: String?
            public var rechtsgebiet: String?
            public var prozessziel: String?
            public var zentrale_rechtsfrage: String?
            public var instanz: String?
        }
        public struct ExtArgument: Codable, Hashable {
            public var titel: String?, beschreibung: String?
            public var seite: String?, staerke: Double?, datum: String?
        }
        public struct ExtEvidence: Codable, Hashable {
            public var titel: String?, beschreibung: String?
            public var typ: String?, gewicht: Double?, datum: String?
        }
        public struct ExtFrist: Codable, Hashable {
            public var titel: String?, datum: String?, fristtyp: String?
        }
        public struct ExtPerson: Codable, Hashable {
            public var name: String?, rolle: String?, organisation: String?
        }
        public struct Gegneranalyse: Codable, Hashable {
            public var zusammenfassung: String?
            public var taktiken: [String]?
            public var schwachstellen: [String]?
            public var gegner_profil: String?
        }
        public struct RechtlicheAnalyse: Codable, Hashable {
            public var zusammenfassung: String?
            public var relevante_paragrafen: [String]?
            public var praezedenzfaelle: [String]?
            public var compliance_risiken: [String]?
        }
        public struct Strategie: Codable, Hashable {
            public var zusammenfassung: String?, empfohlene_strategie: String?
            public var staerken: [String]?, schwaechen: [String]?
        }
        public struct Risiko: Codable, Hashable {
            public var zusammenfassung: String?, risiken: [String]?, risiko_level: String?
        }
        public struct Simulation: Codable, Hashable {
            public var zusammenfassung: String?
            public var vergleichswert_eur: Double?, prognose_einfluss: String?
        }
        public struct Aktion: Codable, Hashable {
            public var zusammenfassung: String?
            public var naechste_schritte: [String]?
            public var erforderliche_dokumente: [String]?
        }
        public struct Cockpit: Codable, Hashable {
            public var zusammenfassung: String?, prognose_delta_pct: Double?
        }
        public struct Abschluss: Codable, Hashable {
            public var zusammenfassung: String?
            public var prozessziel_erreichbar: Bool?
            public var vergleichsempfehlung: String?
        }
        public struct InfoLuecke: Codable, Hashable {
            public var schritt: String?, hinweis: String?
        }
    }

    /// Analysiert ein Dokument im Kontext eines Falls.
    /// Liefert das geparste AnalysisResult zurück und persistiert
    /// die abgeleiteten Updates in CloudKit (Case + Argumente + Beweise + Fristen).
    public func analyze(document: LegalDocument, caseEntity: Case) async throws -> AnalysisResult {

        // ── SCHRITT 1: Volltext-Extraktion (lokal via PDFKit für PDFs) ──
        var ocrText = ""
        if let urlStr = document.fileUrl, let url = URL(string: urlStr),
           document.fileType?.contains("pdf") == true,
           let pdf = PDFDocument(url: url) {
            ocrText = (0..<pdf.pageCount)
                .compactMap { pdf.page(at: $0)?.string }
                .joined(separator: "\n")
            ocrText = String(ocrText.prefix(15000))
        }

        // ── SCHRITT 2: Prompt zusammenstellen (1:1 wie in TypeScript) ───
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt auf Senior-Partner-Niveau und analysierst ein juristisches Dokument für einen Fall.

        FALLKONTEXT:
        - Fallname: \(caseEntity.fallname)
        - Rechtsgebiet: \(caseEntity.rechtsgebiet ?? "Nicht angegeben")
        - Gericht: \(caseEntity.gericht ?? "Nicht angegeben")
        - Prozessziel: \(caseEntity.prozessziel ?? "Nicht angegeben")
        - Zentrale Rechtsfrage: \(caseEntity.zentraleRechtsfrage ?? "Nicht angegeben")

        DOKUMENT: "\(document.title)" (Typ: \(document.fileType ?? "unbekannt"))
        \(ocrText.isEmpty ? "(Kein Volltext extrahierbar)" : "DOKUMENTINHALT:\n" + ocrText)

        AUFGABE: Analysiere das Dokument und extrahiere NUR was tatsächlich im Dokument steht. Erfinde NICHTS. Lasse Felder leer wenn die Information nicht vorhanden ist.

        REGELN:
        - Basisdaten (Gericht, AZ etc.) nur eintragen wenn explizit im Dokument genannt
        - Argumente nur wenn konkrete rechtliche Positionen erkennbar sind – extrahiere IMMER das Datum (YYYY-MM-DD) wenn ein Datum oder Zeitraum erkennbar ist
        - Beweise nur wenn konkrete Beweismittel erkennbar sind – extrahiere IMMER das Datum
        - Fristen nur wenn konkrete Daten genannt werden (Format: YYYY-MM-DD)
        - Personen nur wenn namentlich erwähnt
        - Gegneranalyse nur wenn Gegnerposition erkennbar ist
        - Strategie/Risiko/Simulation nur wenn daraus Ableitungen möglich sind
        - Gib kurze, präzise Texte – keine langen Aufsätze
        """

        let schema: [String: Any] = Self.fullJsonSchema()
        let raw = try await kiProvider.invokeLLM(prompt: prompt, schema: schema)

        // ── SCHRITT 3: Parsen ────────────────────────────────────────────
        let data = raw.data(using: .utf8) ?? Data()
        let result = (try? JSONDecoder().decode(AnalysisResult.self, from: data)) ?? AnalysisResult()

        // ── SCHRITT 4: Persistieren (Case + neue Argumente / Beweise / Fristen) ──
        try await applyToCase(result: result, caseEntity: caseEntity, document: document)

        return result
    }

    private func applyToCase(result: AnalysisResult,
                             caseEntity: Case,
                             document: LegalDocument) async throws {
        // Case-Update – nur leere Felder befüllen
        var updated = caseEntity
        var changed = false
        if let bd = result.basisdaten {
            if let v = bd.gericht,             isMeaningful(v), updated.gericht == nil           { updated.gericht = v;            changed = true }
            if let v = bd.aktenzeichen,        isMeaningful(v), updated.aktenzeichen == nil      { updated.aktenzeichen = v;       changed = true }
            if let v = bd.rechtsgebiet,        isMeaningful(v), updated.rechtsgebiet == nil      { updated.rechtsgebiet = v;       changed = true }
            if let v = bd.prozessziel,         isMeaningful(v), updated.prozessziel == nil       { updated.prozessziel = v;        changed = true }
            if let v = bd.zentrale_rechtsfrage,isMeaningful(v), updated.zentraleRechtsfrage == nil { updated.zentraleRechtsfrage = v; changed = true }
            if let v = bd.instanz, let inst = CaseInstanz(rawValue: v) { updated.instanz = inst; changed = true }
        }
        if let sw = result.streitwert, sw > 0, updated.streitwert == nil {
            updated.streitwert = sw; changed = true
        }
        // Notizen anhängen aus Strategie/Risiko/Aktion
        var notizen: [String] = []
        if let s = result.schritt5_strategie?.empfohlene_strategie, !s.isEmpty {
            notizen.append("📋 Strategie aus \"\(document.title)\":\n\(s)")
        }
        if let r = result.schritt6_risiko, let z = r.zusammenfassung, !z.isEmpty {
            notizen.append("⚠ Risiko [\(r.risiko_level ?? "?")] aus \"\(document.title)\":\n\(z)")
        }
        if let steps = result.schritt8_aktion?.naechste_schritte, !steps.isEmpty {
            notizen.append("→ Nächste Schritte:\n" + steps.map { "• \($0)" }.joined(separator: "\n"))
        }
        if !notizen.isEmpty {
            let combined = ([updated.notes].compactMap { $0 } + notizen).joined(separator: "\n\n")
            updated.notes = combined; changed = true
        }
        if changed {
            updated.updatedAt = Date()
            _ = try await cloudKit.save(updated)
        }

        // Argumente anlegen
        for a in result.argumente ?? [] {
            guard let titel = a.titel, !titel.isEmpty else { continue }
            var arg = Argument(caseId: caseEntity.id, title: titel)
            arg.argDescription = a.beschreibung
            arg.kiStrength = a.staerke
            arg.zeitpunkt = a.datum
            _ = try? await cloudKit.save(arg)
        }
        // Beweise anlegen
        for e in result.beweise ?? [] {
            guard let titel = e.titel, !titel.isEmpty else { continue }
            var ev = Evidence(caseId: caseEntity.id, title: titel)
            ev.evidenceDescription = e.beschreibung
            ev.kiWeight = e.gewicht
            ev.type = e.typ
            ev.datum = e.datum
            _ = try? await cloudKit.save(ev)
        }
        // Fristen anlegen
        let dF = DateFormatter(); dF.dateFormat = "yyyy-MM-dd"
        for f in result.fristen ?? [] {
            guard let titel = f.titel, let datum = f.datum,
                  let date = dF.date(from: datum) else { continue }
            var d = Deadline(caseId: caseEntity.id, title: titel, dueDate: date)
            d.fristType = f.fristtyp
            _ = try? await cloudKit.save(d)
        }
        // Personen anlegen
        for p in result.personen ?? [] {
            guard let name = p.name, !name.isEmpty else { continue }
            var per = Person(caseId: caseEntity.id, name: name)
            per.organization = p.organisation
            if let r = p.rolle, let role = PersonRole(rawValue: r) { per.role = role }
            _ = try? await cloudKit.save(per)
        }
        // Document Update (KI-Summary)
        var doc = document
        doc.aiSummary = result.zusammenfassung ?? doc.aiSummary
        if let raw = try? JSONEncoder().encode(result),
           let str = String(data: raw, encoding: .utf8) {
            doc.aiRawJSON = str
        }
        _ = try? await cloudKit.save(doc)
    }

    private func isMeaningful(_ v: String) -> Bool {
        let t = v.trimmingCharacters(in: .whitespaces)
        return t.count > 2 && !t.contains("Nicht angegeben")
    }

    // Schema (vereinfachte JSON-Schema-Map – Claude nutzt dies als Strukturhinweis)
    private static func fullJsonSchema() -> [String: Any] {
        [
            "type": "object",
            "properties": [
                "zusammenfassung": ["type": "string"],
                "basisdaten": [
                    "type": "object",
                    "properties": [
                        "gericht":             ["type": "string"],
                        "aktenzeichen":        ["type": "string"],
                        "rechtsgebiet":        ["type": "string"],
                        "prozessziel":         ["type": "string"],
                        "zentrale_rechtsfrage":["type": "string"],
                        "instanz":             ["type": "string"]
                    ]
                ],
                "streitwert": ["type": "number"],
                "argumente": ["type": "array", "items": ["type": "object"]],
                "beweise":   ["type": "array", "items": ["type": "object"]],
                "fristen":   ["type": "array", "items": ["type": "object"]],
                "personen":  ["type": "array", "items": ["type": "object"]],
                "schritt3_gegneranalyse":      ["type": "object"],
                "schritt4_rechtliche_analyse": ["type": "object"],
                "schritt5_strategie":          ["type": "object"],
                "schritt6_risiko":             ["type": "object"],
                "schritt7_simulation":         ["type": "object"],
                "schritt8_aktion":             ["type": "object"],
                "schritt9_cockpit":            ["type": "object"],
                "schritt10_abschluss":         ["type": "object"],
                "informationsluecken":         ["type": "array", "items": ["type": "object"]]
            ]
        ]
    }
}

// MARK: - Services/BackendFunctions/EvidenceLinkingService.swift

@MainActor
public final class EvidenceLinkingService: ObservableObject {
    private let kiProvider: KIProvider
    private let cloudKit:   CloudKitService
    public init(kiProvider: KIProvider, cloudKit: CloudKitService) {
        self.kiProvider = kiProvider; self.cloudKit = cloudKit
    }

    public struct Mapping: Codable, Hashable {
        public var evidenceId: String
        public var argumentId: String
        public var begruendung: String
    }

    public func linkAll(arguments: [Argument], evidence: [Evidence]) async throws -> [Mapping] {
        guard !arguments.isEmpty, !evidence.isEmpty else { return [] }

        let argList = arguments.map { "- ID:\($0.id) | [\($0.side.rawValue)] \($0.title): \($0.argDescription ?? "")" }
            .joined(separator: "\n")
        let evList = evidence.map { "- ID:\($0.id) | \($0.title) (\($0.type ?? "?")): \($0.evidenceDescription ?? "")" }
            .joined(separator: "\n")

        let prompt = """
        Ordne jedes Beweismittel den passenden Argumenten zu (KEIN Argument darf erfunden sein,
        nutze nur die unten gelisteten IDs). Gib eine Liste von Zuordnungen zurück.

        ARGUMENTE:
        \(argList)

        BEWEISE:
        \(evList)

        Pro Beweis maximal 3 Argument-Verknüpfungen. Begründung in 1 Satz.
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "mappings": ["type": "array", "items": ["type": "object",
                    "properties": [
                        "evidenceId": ["type": "string"],
                        "argumentId": ["type": "string"],
                        "begruendung": ["type": "string"]
                    ]
                ]]
            ]
        ]

        struct Wrapper: Codable { var mappings: [Mapping] }
        let raw = try await kiProvider.invokeLLM(prompt: prompt, schema: schema)
        let parsed = (try? JSONDecoder().decode(Wrapper.self,
                                                from: raw.data(using: .utf8) ?? Data()))?.mappings ?? []

        // Persistiere: setze Evidence.argumentId und ergänze Argument.evidenceIds
        for m in parsed {
            if var ev = evidence.first(where: { $0.id == m.evidenceId }) {
                ev.argumentId = m.argumentId
                _ = try? await cloudKit.save(ev)
            }
            if var arg = arguments.first(where: { $0.id == m.argumentId }) {
                if !arg.evidenceIds.contains(m.evidenceId) {
                    arg.evidenceIds.append(m.evidenceId)
                    _ = try? await cloudKit.save(arg)
                }
            }
        }
        return parsed
    }
}

// MARK: - Services/BackendFunctions/GegnerVerhaltenPDFExportService.swift

@MainActor
public enum GegnerVerhaltenPDFExportService {

    public static func export(caseEntity: Case,
                              gegnerVerhalten: [GegnerVerhalten],
                              persons: [Person]) -> Data? {
        let pageW: CGFloat = 612, pageH: CGFloat = 792, m: CGFloat = 50
        let contentW = pageW - 2 * m
        let pdfData = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        guard let consumer = CGDataConsumer(data: pdfData),
              let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return nil }

        var y: CGFloat = pageH - m
        ctx.beginPDFPage(nil)

        func newPageIfNeeded(_ s: CGFloat) {
            if y - s < m { ctx.endPDFPage(); ctx.beginPDFPage(nil); y = pageH - m }
        }
        func text(_ t: String, size: CGFloat = 10, bold: Bool = false, color: NSColor = .black) {
            newPageIfNeeded(size + 6)
            let font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
            let attr = NSAttributedString(string: t, attributes: [.font: font, .foregroundColor: color])
            let frame = CGRect(x: m, y: y - 100, width: contentW, height: 100)
            let path = CGPath(rect: frame, transform: nil)
            let fs = CTFramesetterCreateWithAttributedString(attr)
            let tf = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: 0), path, nil)
            let lines = CTFrameGetLines(tf) as! [CTLine]
            for line in lines {
                ctx.textPosition = CGPoint(x: m, y: y - size)
                CTLineDraw(line, ctx); y -= size + 4
            }
            y -= 2
        }
        func section(_ t: String) {
            y -= 6; newPageIfNeeded(20)
            ctx.setFillColor(NSColor(white: 0.94, alpha: 1).cgColor)
            ctx.fill(CGRect(x: m - 5, y: y - 14, width: contentW + 10, height: 16))
            text(t, size: 11, bold: true); y -= 4
        }

        // Header
        text("Gegnerverhalten-Analyse", size: 18, bold: true)
        text("Fall: \(caseEntity.fallname)", size: 10, color: NSColor(white: 0.4, alpha: 1))
        let df = DateFormatter(); df.dateStyle = .long; df.locale = Locale(identifier: "de_DE")
        text("Erstellt am \(df.string(from: Date()))", size: 9, color: NSColor(white: 0.5, alpha: 1))
        y -= 4

        // Gegnerprofile aus Personen
        let gegnerPersonen = persons.filter { $0.role == .partei || $0.role == .anwalt }
        if !gegnerPersonen.isEmpty {
            section("1. Gegnerische Akteure")
            for p in gegnerPersonen {
                text("\(p.name) – \(p.role.rawValue)\(p.organization.map { " (\($0))" } ?? "")",
                     size: 10, bold: true)
                if let g = p.glaubwuerdigkeit {
                    text("Glaubwürdigkeit: \(Int(g))%", size: 9, color: NSColor(white: 0.3, alpha: 1))
                }
                if p.aussagen > 0 || p.widersprueche > 0 {
                    text("Aussagen: \(p.aussagen), Widersprüche: \(p.widersprueche)", size: 9)
                }
            }
        }

        // Dokumentierte Verhaltensmuster
        section("2. Dokumentierte Verhaltensmuster")
        if gegnerVerhalten.isEmpty {
            text("Keine dokumentierten Muster.")
        } else {
            let dF = DateFormatter(); dF.dateStyle = .medium; dF.locale = Locale(identifier: "de_DE")
            for v in gegnerVerhalten {
                text("• \(v.typ.rawValue) – \(v.titel)", size: 10, bold: true)
                if let b = v.beschreibung { text("  \(b)", size: 9) }
                if let d = v.datum {
                    text("  Datum: \(dF.string(from: d))", size: 9, color: NSColor(white: 0.3, alpha: 1))
                }
                if let r = v.reaktion {
                    text("  Reaktion: \(r.rawValue)", size: 9, color: NSColor.systemBlue)
                }
                if let u = v.unserAngebot, let g = v.gegnerAngebot {
                    text("  Unser Angebot: \(Int(u))€ vs. Gegnerangebot: \(Int(g))€", size: 9)
                }
            }
        }

        // Strategie-Empfehlungen
        section("3. Strategie-Empfehlungen")
        text("• Konsistenz vs. Inkonsistenz dokumentieren", size: 10)
        text("• Widersprüche der Gegenseite gezielt in der Verhandlung adressieren", size: 10)
        text("• Glaubwürdigkeitsmaße bei Zeugenvernehmungen nutzen", size: 10)

        ctx.endPDFPage(); ctx.closePDF()
        return pdfData as Data
    }

    public static func saveToFile(_ data: Data, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultName
        if panel.runModal() == .OK, let url = panel.url { try? data.write(to: url) }
    }
}

// MARK: - Services/BackendFunctions/IcalExportService.swift

@MainActor
public enum IcalExportService {

    /// Erstellt einen iCal-String (.ics) aus einer Liste von Fristen.
    public static func generate(deadlines: [Deadline], caseName: String? = nil) -> String {
        let now = Date()
        let stamp = utcCompactDateTime(now)

        let calName = caseName.map { "Fristen – \($0)" } ?? "Alle Rechtsfristen"

        var ics = ""
        ics += "BEGIN:VCALENDAR\r\n"
        ics += "VERSION:2.0\r\n"
        ics += "PRODID:-//LegalOS//DE\r\n"
        ics += "CALSCALE:GREGORIAN\r\n"
        ics += "METHOD:PUBLISH\r\n"
        ics += "X-WR-CALNAME:\(escape(calName))\r\n"
        ics += "X-WR-CALDESC:Automatisch generiert von LegalOS\r\n"

        for d in deadlines {
            let uid = "frist-\(d.id)@legalos"
            let dateStr = utcCompactDate(d.dueDate)
            let alarmDate = Calendar.current.date(byAdding: .day, value: -3, to: d.dueDate) ?? d.dueDate
            let alarmStr = utcCompactDate(alarmDate)

            let statusEmoji: String = {
                switch d.status {
                case .erledigt: return " ✓"
                case .versaeumt: return " ⚠"
                case .offen:    return ""
                }
            }()
            let summary = escape("⚖️ \(d.title)\(statusEmoji)")

            var descParts: [String] = []
            if let v = d.fristType    { descParts.append("Typ: \(v)") }
            if let v = d.paragraph    { descParts.append("Paragraph: \(v)") }
            if let v = d.responsible  { descParts.append("Verantwortlich: \(v)") }
            descParts.append("Seite: \(d.side.rawValue)")
            descParts.append("Status: \(d.status.rawValue)")
            if let v = d.prognoseabzug { descParts.append("Prognoseabzug: \(v)") }
            let desc = escape(descParts.joined(separator: "\\n"))

            let icalStatus = d.status == .erledigt ? "COMPLETED" : "CONFIRMED"

            ics += "BEGIN:VEVENT\r\n"
            ics += "UID:\(uid)\r\n"
            ics += "DTSTAMP:\(stamp)\r\n"
            ics += "DTSTART;VALUE=DATE:\(dateStr)\r\n"
            ics += "DTEND;VALUE=DATE:\(dateStr)\r\n"
            ics += "SUMMARY:\(summary)\r\n"
            ics += "DESCRIPTION:\(desc)\r\n"
            ics += "STATUS:\(icalStatus)\r\n"
            ics += "BEGIN:VALARM\r\n"
            ics += "TRIGGER;VALUE=DATE-TIME:\(alarmStr)T090000Z\r\n"
            ics += "ACTION:DISPLAY\r\n"
            ics += "DESCRIPTION:Erinnerung: \(summary)\r\n"
            ics += "END:VALARM\r\n"
            ics += "END:VEVENT\r\n"
        }
        ics += "END:VCALENDAR\r\n"
        return ics
    }

    /// Speichert iCal-Datei via NSSavePanel.
    public static func saveToFile(_ ics: String, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.calendarEvent]
        panel.nameFieldStringValue = defaultName
        if panel.runModal() == .OK, let url = panel.url {
            try? ics.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    /// Direkt-Import in Apple Kalender via EventKit.
    public static func importIntoAppleCalendar(deadlines: [Deadline]) async throws {
        let store = EKEventStore()
        let granted = try await store.requestFullAccessToEvents()
        guard granted else { return }
        guard let cal = store.defaultCalendarForNewEvents else { return }

        for d in deadlines {
            let event = EKEvent(eventStore: store)
            event.title = "⚖️ \(d.title)"
            event.startDate = d.dueDate
            event.endDate   = d.dueDate.addingTimeInterval(3600)
            event.isAllDay  = true
            event.calendar  = cal
            event.notes = [
                d.fristType.map    { "Typ: \($0)" },
                d.paragraph.map    { "Paragraph: \($0)" },
                d.responsible.map  { "Verantwortlich: \($0)" },
                "Status: \(d.status.rawValue)",
                "Seite: \(d.side.rawValue)"
            ].compactMap { $0 }.joined(separator: "\n")

            // Alarm 3 Tage vorher
            event.addAlarm(EKAlarm(relativeOffset: -3 * 24 * 3600))
            try store.save(event, span: .thisEvent)
        }
    }

    // MARK: - Helpers
    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: ";", with: "\\;")
         .replacingOccurrences(of: ",", with: "\\,")
         .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func utcCompactDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"; f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
    private static func utcCompactDateTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"; f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }
}

// MARK: - Services/BackendFunctions/MandantUpdateService.swift

@MainActor
public enum MandantUpdateService {

    /// Öffnet das Standard-Mailprogramm mit vorausgefüllter Update-Mail.
    public static func sendUpdate(toMandant mandant: Person,
                                  caseEntity: Case,
                                  betreff: String,
                                  inhalt: String) {
        let to = (mandant.organization ?? mandant.name)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subj = "[\(caseEntity.fallname)] \(betreff)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = """
        Sehr geehrte/r \(mandant.name),

        \(inhalt)

        Aktueller Stand:
        - Status: \(caseEntity.status.rawValue)
        - Aktenzeichen: \(caseEntity.aktenzeichen ?? "—")
        - Gericht: \(caseEntity.gericht ?? "—")
        - Erfolgsprognose: \(Int(caseEntity.prognose ?? 0))%

        Mit freundlichen Grüßen
        Ihr Anwalt
        """.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(to)?subject=\(subj)&body=\(body)") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Services/BackendFunctions/StripeService.swift

@MainActor
public enum StripeService {

    /// Stripe-Pricing-Tabellen-URL aus Settings (Platzhalter).
    public static let publicCheckoutURL = "https://buy.stripe.com/test_legalos_pro"

    public enum Plan: String { case basic, pro, enterprise }

    public static func openCheckout(plan: Plan, userEmail: String) {
        var url = publicCheckoutURL + "?plan=\(plan.rawValue)"
        if let enc = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url += "&prefilled_email=\(enc)"
        }
        if let u = URL(string: url) { NSWorkspace.shared.open(u) }
    }

    /// Direkter Status-Check (Stub – produktiv via Stripe Customer API).
    public static func hasActiveSubscription(userEmail: String) async -> Bool {
        false
    }
}

// MARK: - Views/Shell/AppShell.swift

enum AppRoute: String, Hashable, CaseIterable {
    case home          = "Übersicht"
    case lexara        = "LEXARA Dashboard"
    case cases         = "Fälle"
    case mandanten     = "Mandanten"
    case zeitleiste    = "Zeitleiste"
    case aufgaben      = "Aufgaben"
    case strategos     = "Strategos"
    case suntzu        = "Sun Tzu / Machiavelli"
    case fallassistent = "Fall-Assistent"
    case richter       = "Richter-Profile"
    case modules       = "Module"
    case cockpit       = "Kanzlei-Cockpit"
    case analytik      = "Kanzlei-Analytik"
    case compliance    = "KI-Compliance"
    case plattform     = "Plattform-Agent"

    var symbol: String {
        switch self {
        case .home:          return "house"
        case .lexara:        return "rectangle.3.group"
        case .cases:         return "folder"
        case .mandanten:     return "person.2"
        case .zeitleiste:    return "calendar"
        case .aufgaben:      return "checklist"
        case .strategos:     return "shield.lefthalf.filled"
        case .suntzu:        return "books.vertical"
        case .fallassistent: return "bubble.left.and.text.bubble.right"
        case .richter:       return "person.badge.shield.checkmark"
        case .modules:       return "square.grid.2x2"
        case .cockpit:       return "speedometer"
        case .analytik:      return "chart.line.uptrend.xyaxis"
        case .compliance:    return "checkmark.shield"
        case .plattform:     return "cpu"
        }
    }
}

struct AppShell: View {
    @State private var selection: AppRoute? = .home

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            detail(for: selection ?? .home)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func detail(for route: AppRoute) -> some View {
        NavigationStack {
            switch route {
            case .home:          HomeView()
            case .lexara:        LexaraDashboardView()
            case .cases:         LexaraDashboardView()
            case .mandanten:     MandantenView()
            case .zeitleiste:    ZeitleisteView()
            case .aufgaben:      AufgabenView()
            case .strategos:     StrategosView()
            case .suntzu:        SunTzuMachiavelView()
            case .fallassistent: FallAssistentChatView()
            case .richter:       RichterProfileView()
            case .modules:       ModulesView()
            case .cockpit:       KanzleiCockpitView()
            case .analytik:      KanzleiAnalytikView()
            case .compliance:    KIComplianceView()
            case .plattform:     PlattformAgentView()
            }
        }
        // StrategosScenario navigation is handled inside StrategosView's own NavigationStack via .navigationDestination
    }
}

// MARK: - Views/Shell/SidebarView.swift

struct SidebarView: View {
    @Binding var selection: AppRoute?
    @EnvironmentObject var auth: AuthService

    var body: some View {
        List(selection: $selection) {
            Section("Haupt") {
                ForEach([AppRoute.home, .lexara, .cases, .mandanten, .zeitleiste, .aufgaben], id: \.self) { r in
                    Label(r.rawValue, systemImage: r.symbol).tag(r)
                }
            }
            Section("Strategie") {
                ForEach([AppRoute.strategos, .suntzu, .fallassistent, .richter], id: \.self) { r in
                    Label(r.rawValue, systemImage: r.symbol).tag(r)
                }
            }
            Section("Kanzlei") {
                ForEach([AppRoute.modules, .cockpit, .analytik, .compliance, .plattform], id: \.self) { r in
                    Label(r.rawValue, systemImage: r.symbol).tag(r)
                }
            }
            if let u = auth.currentUser {
                Section("Account") {
                    VStack(alignment: .leading) {
                        Text(u.fullName ?? u.email).font(.subheadline.weight(.medium))
                        Text(u.jurisdiction.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) { auth.logout() } label: {
                        Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .navigationTitle("LegalOS")
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }
}

// MARK: - Views/Components/DSGVOBanner.swift

struct DSGVOBanner: View {
    @AppStorage("dsgvo.banner.dismissed") private var dismissed = false

    var body: some View {
        if dismissed {
            EmptyView()
        } else {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Datenverarbeitung gem. DSGVO").font(.subheadline.weight(.semibold))
                    Text("Falldaten werden ausschließlich in deiner iCloud (CloudKit) gespeichert. KI-Anfragen werden TLS-verschlüsselt an Anthropic übermittelt – ohne Trainingsnutzung.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Verstanden") { dismissed = true }
                    .font(.caption.weight(.semibold))
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }
}

#Preview { DSGVOBanner() }

// MARK: - Views/Components/JurisdictionToggle.swift

struct JurisdictionToggle: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        if let user = auth.currentUser {
            Picker("Rechtsordnung", selection: Binding<Jurisdiction>(
                get: { user.jurisdiction },
                set: { newValue in
                    var u = user
                    u.jurisdiction = newValue
                    Task { await auth.updateProfile(u) }
                }
            )) {
                ForEach(Jurisdiction.allCases, id: \.self) { j in
                    Text(j.rawValue).tag(j)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Views/Components/KICreditsBadge.swift

struct KICreditsBadge: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        if let credits = auth.currentUser?.kiCredits {
            HStack(spacing: 4) {
                Image(systemName: "sparkles").font(.caption2)
                Text("\(credits) KI-Credits").font(.caption2.weight(.medium))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.purple.opacity(0.15), in: Capsule())
            .foregroundStyle(.purple)
        }
    }
}

// MARK: - Views/Auth/LoginView.swift

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "scale.3d")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.tint)
                Text("LegalOS")
                    .font(.largeTitle.weight(.semibold))
                Text("Die Legal-OS für Strategie, Akten und KI.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    TextField("E-Mail", text: $email)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                    SecureField("Passwort", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 32)

                if let err = auth.lastError {
                    Text(err).font(.footnote).foregroundStyle(.red)
                }

                Button {
                    Task { await auth.login(email: email, password: password) }
                } label: {
                    Text(auth.isBusy ? "Einloggen…" : "Anmelden")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || auth.isBusy)
                .padding(.horizontal, 32)

                SignInWithAppleButton(.signIn,
                    onRequest: { req in req.requestedScopes = [.fullName, .email] },
                    onCompletion: { result in
                        Task { await auth.handleAppleSignIn(result) }
                    })
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .padding(.horizontal, 32)

                Button("Noch keinen Account? Registrieren") { showRegister = true }
                    .font(.footnote)

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showRegister) { RegisterView() }
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthService())
}

// MARK: - Views/Auth/OnboardingView.swift

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthService

    @State private var jurisdiction: Jurisdiction = .dach
    @State private var ndaAccepted = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Rechtsordnung") {
                    Picker("Hauptjurisdiktion", selection: $jurisdiction) {
                        ForEach(Jurisdiction.allCases, id: \.self) { j in
                            Text(j.rawValue).tag(j)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Du kannst die Rechtsordnung später jederzeit umschalten.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Vertraulichkeit & Disclaimer") {
                    Text("""
                    LegalOS speichert sämtliche Falldaten ausschließlich in deiner iCloud (CloudKit). \
                    Es findet keine Übertragung an Dritte statt, mit Ausnahme von ausdrücklich \
                    angeforderten KI-Anfragen an Anthropic. KI-Antworten ersetzen keine Rechtsberatung.
                    """)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Toggle("Ich habe die NDA / den Disclaimer gelesen und akzeptiere ihn.",
                           isOn: $ndaAccepted)
                }

                Section {
                    Button {
                        Task {
                            await auth.completeOnboarding(jurisdiction: jurisdiction,
                                                          disclaimerAccepted: ndaAccepted)
                        }
                    } label: {
                        Text("Setup abschließen").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!ndaAccepted || auth.isBusy)
                }
            }
            .navigationTitle("Willkommen bei LegalOS")
        }
    }
}

#Preview {
    OnboardingView().environmentObject(AuthService())
}

// MARK: - Views/Auth/RegisterView.swift

struct RegisterView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var agbAccepted = false

    private var canSubmit: Bool {
        !email.isEmpty &&
        password.count >= 8 &&
        password == passwordConfirm &&
        agbAccepted &&
        !auth.isBusy
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Konto") {
                    TextField("Vor- und Nachname", text: $fullName)
                    TextField("E-Mail", text: $email)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                    SecureField("Passwort (min. 8 Zeichen)", text: $password)
                    SecureField("Passwort bestätigen", text: $passwordConfirm)
                    if !password.isEmpty && password != passwordConfirm {
                        Text("Passwörter stimmen nicht überein.")
                            .font(.footnote).foregroundStyle(.red)
                    }
                }

                Section {
                    Toggle("Ich akzeptiere AGB & Datenschutzerklärung.", isOn: $agbAccepted)
                }

                if let err = auth.lastError {
                    Section { Text(err).foregroundStyle(.red) }
                }

                Section {
                    Button {
                        Task {
                            await auth.register(email: email,
                                                password: password,
                                                fullName: fullName.isEmpty ? nil : fullName)
                            if auth.currentUser != nil { dismiss() }
                        }
                    } label: {
                        Text(auth.isBusy ? "Wird angelegt…" : "Konto erstellen")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Registrieren")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    RegisterView().environmentObject(AuthService())
}

// MARK: - Views/Lexara/AIPerformanceDashboardView.swift

struct AIPerformanceDashboardView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService

    @State private var feedbacks: [AIPerformanceFeedback] = []
    @State private var kiLogs: [KIUsageLog] = []
    @State private var loading = true
    @State private var saving = false

    @State private var showForm = false
    @State private var form = FormState()
    @State private var editing: AIPerformanceFeedback? = nil
    @State private var editForm = FormState()

    @State private var ratingLog: KIUsageLog? = nil
    @State private var ratingValue: Int = 0
    @State private var ratingFeedback: String = ""

    @State private var filterPeriod: Period = .all
    @State private var filterAdvisor: String = "all"
    @State private var showKiHistory = false

    enum Period: String, CaseIterable, Identifiable {
        case all, month, quarter
        var id: Self { self }
        var label: String {
            switch self { case .all: return "Alle"; case .month: return "Diesen Monat"; case .quarter: return "Dieses Quartal" }
        }
    }

    struct FormState {
        var prognoseRating: Double? = nil
        var strategieRating: Double? = nil
        var kiBeraterRating: Double? = nil
        var gesamtbewertung: Double? = nil
        var fallErfolgreich: Bool? = nil
        var kiFeedback: String = ""
    }

    struct Stats {
        var totalCases: Int
        var prognosisAccuracy: Double
        var strategyEffectiveness: Double
        var beraterQuality: Double
        var overallScore: Double
        var successRate: Double
        var topImprovements: [Improvement]
    }
    struct Improvement: Identifiable {
        let id = UUID()
        let aspect: String
        let count: Int
        let problems: [String]
    }
    struct TrendPoint: Identifiable {
        let id = UUID()
        let date: String
        let gesamtbewertung: Double
        let erfolgsquote: Double
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else {
                    if showForm { formCard }
                    Button {
                        showForm.toggle()
                    } label: {
                        Text("+ Neue Bewertung hinzufügen")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)

                    filterCard
                    if !trendData.isEmpty { trendCard }

                    if let s = stats { statsContent(s) }
                    else { emptyState }
                }
            }
            .padding(20)
        }
        .task { await loadData() }
        .sheet(item: $editing) { fb in editSheet(fb) }
        .sheet(item: $ratingLog) { log in ratingSheet(log) }
    }

    // MARK: - Subviews

    private var formCard: some View {
        GroupBox("Neue KI-Performance Bewertung") {
            VStack(alignment: .leading, spacing: 10) {
                ratingField("Prognose-Rating (1-5)", value: $form.prognoseRating)
                ratingField("Strategie-Rating (1-5)", value: $form.strategieRating)
                ratingField("KI-Berater Rating (1-5)", value: $form.kiBeraterRating)
                ratingField("Gesamtbewertung (1-5)", value: $form.gesamtbewertung)
                Text("KI-Feedback").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $form.kiFeedback).frame(minHeight: 60)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                Text("Fall erfolgreich?").font(.caption).foregroundColor(.secondary)
                HStack {
                    Button("Ja") { form.fallErfolgreich = true }
                        .buttonStyle(.borderedProminent)
                        .tint(form.fallErfolgreich == true ? .green : .gray)
                    Button("Nein") { form.fallErfolgreich = false }
                        .buttonStyle(.borderedProminent)
                        .tint(form.fallErfolgreich == false ? .red : .gray)
                }
                HStack {
                    Button("Abbrechen") { form = FormState(); showForm = false }
                        .buttonStyle(.bordered)
                    Button(saving ? "Speichert…" : "Speichern") {
                        Task { await handleCreate() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(saving || form.gesamtbewertung == nil)
                }
            }
            .padding(8)
        }
    }

    private func ratingField(_ label: String, value: Binding<Double?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            TextField("", value: value, format: .number).textFieldStyle(.roundedBorder)
        }
    }

    private var filterCard: some View {
        GroupBox("Filter") {
            HStack {
                Picker("Zeitraum", selection: $filterPeriod) {
                    ForEach(Period.allCases) { Text($0.label).tag($0) }
                }
                Picker("KI-Berater", selection: $filterAdvisor) {
                    Text("Alle").tag("all")
                    ForEach(advisors, id: \.self) { Text($0).tag($0) }
                }
            }.padding(8)
        }
    }

    private var trendCard: some View {
        GroupBox("Performance-Trend") {
            Chart(trendData) { p in
                LineMark(x: .value("Datum", p.date), y: .value("Gesamtbewertung", p.gesamtbewertung))
                    .foregroundStyle(.blue)
                LineMark(x: .value("Datum", p.date), y: .value("Erfolgsquote", p.erfolgsquote))
                    .foregroundStyle(.green)
            }
            .frame(height: 250)
            .padding(8)
        }
    }

    private func statsContent(_ s: Stats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard("Prognose-Genauigkeit", value: "\(String(format: "%.2f", s.prognosisAccuracy))/5", subtitle: "Basierend auf \(s.totalCases) Fällen", icon: iconFor(s.prognosisAccuracy), tint: tintFor(s.prognosisAccuracy))
                statCard("Strategie-Effektivität", value: "\(String(format: "%.2f", s.strategyEffectiveness))/5", subtitle: "Qualität der Strategieempfehlungen", icon: "chart.line.uptrend.xyaxis", tint: tintFor(s.strategyEffectiveness))
                statCard("KI-Berater Qualität", value: "\(String(format: "%.2f", s.beraterQuality))/5", subtitle: "Hilfreiche & akkurate Analysen", icon: "bolt.fill", tint: tintFor(s.beraterQuality))
                statCard("Erfolgsquote", value: "\(String(format: "%.1f", s.successRate))%", subtitle: "\(Int(Double(s.totalCases) * s.successRate / 100)) von \(s.totalCases) Fällen", icon: "checkmark.circle.fill", tint: .blue)
            }
            GroupBox("Gesamtbewertung") {
                HStack {
                    Text(String(format: "%.2f", s.overallScore)).font(.system(size: 36, weight: .bold))
                    VStack(alignment: .leading) {
                        ProgressView(value: s.overallScore / 5).tint(tintFor(s.overallScore))
                        Text(s.overallScore >= 4 ? "Ausgezeichnete Performance" : s.overallScore >= 3 ? "Gute Performance" : "Verbesserung erforderlich")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }.padding(8)
            }
            GroupBox("Bewertungen") {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(filteredFeedbacks) { fb in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(fb.caseName ?? fb.caseId).font(.caption.weight(.medium))
                                    Text("Bewertung: \(String(format: "%.1f", fb.gesamtbewertung))/5").font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button { editing = fb; editForm = FormState(prognoseRating: fb.prognoseRating, strategieRating: fb.strategieRating, kiBeraterRating: fb.kiBeraterRating, gesamtbewertung: fb.gesamtbewertung, fallErfolgreich: fb.fallErfolgreich, kiFeedback: fb.kiBeraterFeedback ?? "") } label: {
                                    Image(systemName: "pencil")
                                }.buttonStyle(.plain)
                            }
                            .padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }.frame(maxHeight: 300)
            }
            GroupBox {
                HStack {
                    Text("KI-Nutzungs-Historie").font(.headline)
                    Spacer()
                    Button(showKiHistory ? "Ausblenden" : "Anzeigen (\(kiLogs.count))") {
                        showKiHistory.toggle()
                    }.buttonStyle(.plain).foregroundColor(.blue)
                }
                if showKiHistory {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(kiLogs) { log in kiLogRow(log) }
                        }
                    }.frame(maxHeight: 300)
                }
            }
            if !s.topImprovements.isEmpty {
                GroupBox("Häufigste Verbesserungsbedarfe") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(s.topImprovements) { imp in
                            HStack {
                                Text("\(imp.count)").font(.headline).frame(width: 32, height: 32).background(Color.blue.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading) {
                                    Text(imp.aspect.replacingOccurrences(of: "_", with: " ").capitalized).font(.subheadline.weight(.semibold))
                                    Text(imp.problems.prefix(2).joined(separator: ", ")).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            if s.overallScore < 4 {
                GroupBox("Empfehlungen") {
                    VStack(alignment: .leading, spacing: 4) {
                        if s.prognosisAccuracy < 3 { Text("• Prognosen überprüfen – Kalibrierung empfohlen") }
                        if s.strategyEffectiveness < 3 { Text("• Strategieanalyse verstärken") }
                        if s.beraterQuality < 3 { Text("• KI-Berater Prompts optimieren") }
                        if s.successRate < 60 { Text("• Fallauswahl überprüfen") }
                    }.font(.caption).foregroundColor(.orange)
                }
            }
        }
    }

    private func kiLogRow(_ log: KIUsageLog) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(log.kiFunction).font(.caption.weight(.semibold))
                    Text(log.context ?? "").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                if let r = log.rating {
                    HStack(spacing: 2) {
                        ForEach(0..<Int(r), id: \.self) { _ in Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2) }
                    }
                } else {
                    Button("Bewerten") {
                        ratingLog = log; ratingValue = 0; ratingFeedback = log.feedback ?? ""
                    }.buttonStyle(.bordered).controlSize(.mini)
                }
            }
            Text(String(log.output.prefix(100)) + "…").font(.caption2).foregroundColor(.secondary).lineLimit(2)
        }
        .padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var emptyState: some View {
        VStack {
            Text("Noch keine KI-Bewertungen vorhanden").foregroundColor(.secondary).padding()
        }.frame(maxWidth: .infinity).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCard(_ title: String, value: String, subtitle: String, icon: String, tint: Color) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title).font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: icon).foregroundColor(tint)
                }
                Text(value).font(.title.weight(.bold))
                Text(subtitle).font(.caption2).foregroundColor(.secondary)
            }.padding(8)
        }
    }

    private func editSheet(_ fb: AIPerformanceFeedback) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bewertung bearbeiten").font(.headline); Spacer()
                Button { editing = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            ratingField("Gesamtbewertung (1-5)", value: $editForm.gesamtbewertung)
            Text("KI-Feedback").font(.caption).foregroundColor(.secondary)
            TextEditor(text: $editForm.kiFeedback).frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            HStack {
                Button("Abbrechen") { editing = nil }.buttonStyle(.bordered)
                Button(saving ? "Speichert…" : "Speichern") { Task { await handleEditSave() } }
                    .buttonStyle(.borderedProminent).disabled(saving)
            }
        }.padding(20).frame(width: 460)
    }

    private func ratingSheet(_ log: KIUsageLog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("KI-Nutzung bewerten").font(.headline); Spacer()
                Button { ratingLog = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            ScrollView { Text(log.output).font(.system(.caption, design: .monospaced)) }.frame(height: 120).padding(6).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 6))
            Text("Bewertung (1-5)").font(.caption).foregroundColor(.secondary)
            HStack {
                ForEach(1...5, id: \.self) { i in
                    Button { ratingValue = i } label: {
                        Image(systemName: i <= ratingValue ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }.buttonStyle(.plain)
                }
            }
            Text("Feedback").font(.caption).foregroundColor(.secondary)
            TextEditor(text: $ratingFeedback).frame(minHeight: 60).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
            HStack {
                Button("Abbrechen") { ratingLog = nil }.buttonStyle(.bordered)
                Button(saving ? "Speichert…" : "Bewertung speichern") { Task { await handleRateKiLog() } }
                    .buttonStyle(.borderedProminent).tint(.yellow).disabled(saving || ratingValue == 0)
            }
        }.padding(20).frame(width: 460)
    }

    // MARK: - Computed

    private var advisors: [String] { [] }

    private var trendData: [TrendPoint] {
        let sorted = feedbacks
        let groups = Dictionary(grouping: sorted) { _ in "" } // dates not in model
        return groups.map { _, items in
            TrendPoint(date: "", gesamtbewertung: items.map(\.gesamtbewertung).reduce(0,+) / Double(max(items.count,1)), erfolgsquote: Double(items.filter(\.fallErfolgreich).count))
        }
    }

    private var filteredFeedbacks: [AIPerformanceFeedback] { feedbacks }

    private var stats: Stats? {
        guard !feedbacks.isEmpty else { return nil }
        let prog = feedbacks.compactMap(\.prognoseRating)
        let strat = feedbacks.compactMap(\.strategieRating)
        let berater = feedbacks.compactMap(\.kiBeraterRating)
        let overall = feedbacks.map(\.gesamtbewertung)
        let success = Double(feedbacks.filter(\.fallErfolgreich).count) / Double(feedbacks.count) * 100
        return Stats(
            totalCases: feedbacks.count,
            prognosisAccuracy: avg(prog),
            strategyEffectiveness: avg(strat),
            beraterQuality: avg(berater),
            overallScore: avg(overall),
            successRate: success,
            topImprovements: []
        )
    }
    private func avg(_ a: [Double]) -> Double { a.isEmpty ? 0 : a.reduce(0,+) / Double(a.count) }

    private func iconFor(_ s: Double) -> String { s >= 4 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill" }
    private func tintFor(_ s: Double) -> Color { s >= 4 ? .green : s >= 3 ? .yellow : .red }

    // MARK: - Actions

    private func loadData() async {
        loading = true
        defer { loading = false }
        do {
            feedbacks = try await cloudKit.fetch(AIPerformanceFeedback.self)
            kiLogs = try await cloudKit.fetchForCase(KIUsageLog.self, caseId: caseId)
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func handleCreate() async {
        guard let g = form.gesamtbewertung else { return }
        saving = true; defer { saving = false }
        var fb = AIPerformanceFeedback(caseId: caseId, gesamtbewertung: g)
        fb.prognoseRating = form.prognoseRating
        fb.strategieRating = form.strategieRating
        fb.kiBeraterRating = form.kiBeraterRating
        fb.kiBeraterFeedback = form.kiFeedback
        fb.fallErfolgreich = form.fallErfolgreich ?? false
        do {
            _ = try await cloudKit.save(fb)
            form = FormState(); showForm = false
            await loadData()
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func handleEditSave() async {
        guard var fb = editing else { return }
        saving = true; defer { saving = false }
        if let g = editForm.gesamtbewertung { fb.gesamtbewertung = g }
        fb.kiBeraterFeedback = editForm.kiFeedback
        do {
            _ = try await cloudKit.save(fb)
            editing = nil
            await loadData()
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func handleRateKiLog() async {
        guard var log = ratingLog else { return }
        saving = true; defer { saving = false }
        log.rating = Double(ratingValue)
        log.feedback = ratingFeedback
        do {
            _ = try await cloudKit.save(log)
            ratingLog = nil
            await loadData()
        } catch { cloudKit.lastError = error.localizedDescription }
    }
}

// MARK: - Views/Lexara/ArgumentGraphView.swift

struct ArgumentGraphView: View {
    let args: [Argument]
    let evidence: [Evidence]
    var onSelect: ((Argument) -> Void)? = nil

    @State private var selected: Argument?
    @State private var zoomLevel: Double = 1.0

    var body: some View {
        VStack {
            HStack {
                Text("Argument-Graph").font(.headline)
                Spacer()
                Slider(value: $zoomLevel, in: 0.5...2.0).frame(width: 120)
                Text("Zoom \(String(format: "%.1f", zoomLevel))x").font(.caption2).foregroundColor(.secondary)
            }.padding(.horizontal)
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                        ForEach(args) { arg in
                            argNode(arg)
                                .onTapGesture {
                                    selected = arg
                                    onSelect?(arg)
                                }
                        }
                    }
                    .scaleEffect(zoomLevel)
                    .padding(20)
                }
            }
            .frame(maxHeight: 400)
            if let s = selected { detailPanel(s) }
        }
    }

    private func argNode(_ arg: Argument) -> some View {
        let isSelected = selected?.id == arg.id
        let strength = arg.kiStrength ?? arg.strength ?? 5
        let strColor: Color = strength >= 7 ? .green : strength >= 4 ? .orange : .red
        let argEvidence = evidence.filter { $0.argumentId == arg.id }
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(arg.side == .eigen ? "EIGEN" : "GEGNER").font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background((arg.side == .eigen ? Color.blue : Color.red).opacity(0.15))
                    .foregroundColor(arg.side == .eigen ? .blue : .red)
                    .clipShape(Capsule())
                Spacer()
                Text("\(Int(strength))/10").font(.caption2.weight(.bold)).foregroundColor(strColor)
            }
            Text(arg.title).font(.caption.weight(.semibold)).lineLimit(3)
            HStack(spacing: 4) {
                Image(systemName: "doc.text").font(.system(size: 9))
                Text("\(argEvidence.count)").font(.system(size: 9))
            }.foregroundColor(.secondary)
        }
        .frame(width: 160, height: 100, alignment: .topLeading)
        .padding(8)
        .background(arg.side == .eigen ? Color.blue.opacity(0.05) : Color.red.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.primary : Color.secondary.opacity(0.2), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detailPanel(_ arg: Argument) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text(arg.title).font(.subheadline.weight(.semibold))
                if let d = arg.argDescription { Text(d).font(.caption).foregroundColor(.secondary) }
                if let r = arg.kiReasoning { Label(r, systemImage: "brain").font(.caption2).foregroundColor(.purple) }
            }.padding(8)
        }
    }
}

// MARK: - Views/Lexara/ArgumentZeitstrahlChartView.swift

struct ArgumentZeitstrahlChartView: View {
    let caseId: String
    let args: [Argument]
    let deadlines: [Deadline]
    let connections: [(from: String, to: String, type: String)]

    @EnvironmentObject var kiProvider: KIProvider

    @State private var selected: Argument? = nil
    @State private var kiLoading = false
    @State private var kiResult: KIAnalyse? = nil

    init(caseId: String, args: [Argument], deadlines: [Deadline] = [], connections: [(from: String, to: String, type: String)] = []) {
        self.caseId = caseId
        self.args = args
        self.deadlines = deadlines
        self.connections = connections
    }

    struct KIAnalyse: Codable {
        var trend_einschaetzung: String?
        var staerke_aktuell: Double?
        var empfehlung: String?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if args.isEmpty {
                Text("Noch keine Argumente mit Zeitbezug vorhanden.").font(.caption).foregroundColor(.secondary).frame(height: 160).frame(maxWidth: .infinity)
            } else {
                chart
                legend
                if let r = kiResult { kiResultCard(r) }
                Button { Task { await runKiAnalyse() } } label: {
                    Label(kiLoading ? "Analysiere…" : "KI-Trendanalyse", systemImage: "sparkles")
                }.buttonStyle(.borderedProminent).disabled(kiLoading)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(datedArgs) { a in
                let strength = a.kiStrength ?? a.strength ?? 5
                PointMark(x: .value("Datum", argDate(a)), y: .value("Stärke", strength))
                    .foregroundStyle(a.side == .eigen ? .blue : .red)
                    .symbolSize(CGFloat(strength) * 30)
                    .annotation(position: .top) { Text(a.title).font(.system(size: 8)).lineLimit(1) }
            }
            ForEach(deadlines) { d in
                RuleMark(x: .value("Frist", d.dueDate))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text(d.title).font(.system(size: 8)).foregroundColor(.orange)
                    }
            }
        }
        .frame(height: 320)
        .chartYScale(domain: 0...10)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label("Eigene", systemImage: "circle.fill").foregroundColor(.blue).font(.caption2)
            Label("Gegner", systemImage: "circle.fill").foregroundColor(.red).font(.caption2)
            Label("Frist", systemImage: "minus").foregroundColor(.orange).font(.caption2)
            Spacer()
        }
    }

    private func kiResultCard(_ r: KIAnalyse) -> some View {
        GroupBox("KI-Trendanalyse") {
            VStack(alignment: .leading, spacing: 6) {
                if let t = r.trend_einschaetzung { Text(t).font(.caption) }
                if let s = r.staerke_aktuell { Label("Aktuelle Stärke: \(Int(s))/10", systemImage: "chart.line.uptrend.xyaxis").font(.caption.weight(.semibold)) }
                if let e = r.empfehlung { Label(e, systemImage: "lightbulb").font(.caption).foregroundColor(.green) }
            }.padding(8)
        }
    }

    private var datedArgs: [Argument] {
        args.filter { $0.zeitpunkt != nil }
    }

    private func argDate(_ a: Argument) -> Date {
        let f = ISO8601DateFormatter()
        if let z = a.zeitpunkt, let d = f.date(from: z) { return d }
        return Date()
    }

    private func runKiAnalyse() async {
        kiLoading = true; defer { kiLoading = false }
        let prompt = "Analysiere die zeitliche Entwicklung der Argumentstärke. Gib JSON: {trend_einschaetzung, staerke_aktuell, empfehlung}"
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "ArgumentZeitstrahl", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String, let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(KIAnalyse.self, from: data) {
            kiResult = result
        }
    }
}

// MARK: - Views/Lexara/ArgumentationskettenVisualisierungView.swift

struct ArgumentationskettenVisualisierungView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var loading = true
    @State private var selectedArg: Argument? = nil
    @State private var view: ViewMode = .kette
    @State private var kiAnalyzing = false
    @State private var kiLuecken: KILueckenAnalyse? = nil

    enum ViewMode: String, CaseIterable, Identifiable {
        case kette, luecken, ki
        var id: Self { self }
        var label: String {
            switch self { case .kette: return "Argumentkette"; case .luecken: return "Lückenanalyse"; case .ki: return "KI-Analyse" }
        }
    }

    struct Connection: Identifiable {
        let id = UUID()
        let fromId: String
        let fromTitle: String
        let toId: String
        let type: String
        let intensitaet: Int
        let explanation: String
    }

    enum GapType: String {
        case noEvidence = "no_evidence"
        case weakChain = "weak_chain"
        case contradiction = "contradiction"
        case isolated = "isolated"
        case missingCounter = "missing_counter"
        var label: String {
            switch self {
            case .noEvidence: return "Kein Beweis verknüpft"
            case .weakChain: return "Schwache Kette"
            case .contradiction: return "Widerspruch"
            case .isolated: return "Isoliertes Argument"
            case .missingCounter: return "Kein Gegenargument"
            }
        }
        var color: Color {
            switch self {
            case .noEvidence, .contradiction: return .red
            case .weakChain: return .orange
            case .isolated: return .gray
            case .missingCounter: return .blue
            }
        }
    }

    struct Gap: Identifiable {
        let id = UUID()
        let argId: String
        let type: GapType
        let desc: String
    }

    struct KILueckenAnalyse: Codable {
        var gesamtbewertung: String?
        var staerke_eigene_kette: Double?
        var luecken: [KILuecke]?
        var empfehlungen: [String]?
    }
    struct KILuecke: Codable, Identifiable {
        var id: String { typ + beschreibung }
        var typ: String
        var beschreibung: String
        var empfehlung: String?
        var schwere: String?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else if args.isEmpty {
                    emptyState
                } else {
                    header
                    if !gaps.isEmpty { gapBanner }
                    switch view {
                    case .kette: chainView
                    case .luecken: GapsPanel(gaps: gaps, args: args, onSelect: { selectedArg = $0; view = .kette })
                    case .ki: kiAnalysisView
                    }
                }
            }
            .padding(20)
        }
        .task { await load() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Argumentationsketten-Visualisierung").font(.headline)
                Text("\(args.count) Argumente · \(connections.count) Verbindungen · \(evidence.count) Beweise · \(gaps.count) Lücken").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Picker("", selection: $view) {
                ForEach(ViewMode.allCases) { Text($0.label).tag($0) }
            }.pickerStyle(.segmented).fixedSize()
        }
    }

    private var gapBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text("\(gaps.count) logische Lücken in der Beweisführung erkannt").font(.caption).foregroundColor(.orange)
            Spacer()
            Button("Zeigen") { view = .luecken }.buttonStyle(.plain).font(.caption2).foregroundColor(.orange)
        }.padding(10).background(Color.orange.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var chainView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                argColumn(label: "Eigene Argumente", group: args.filter { $0.side == .eigen }, color: .blue)
                argColumn(label: "Gegenargumente", group: args.filter { $0.side == .gegner }, color: .red)
            }
            if !connections.isEmpty {
                GroupBox("Argumentketten (\(connections.count))") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(connections) { c in connectionRow(c) }
                    }
                }
            }
            if let sel = selectedArg { argDetail(sel) }
        }
    }

    private func argColumn(label: String, group: [Argument], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(label) (\(group.count))").font(.caption.weight(.bold)).foregroundColor(color).textCase(.uppercase)
            ForEach(group) { arg in
                argNode(arg).onTapGesture { selectedArg = arg }
            }
            if group.isEmpty { Text("Keine vorhanden").font(.caption).foregroundColor(.secondary).italic() }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func argNode(_ arg: Argument) -> some View {
        let argGaps = gaps.filter { $0.argId == arg.id }
        let argEvidence = evidence.filter { $0.argumentId == arg.id }
        let isEigen = arg.side == .eigen
        let strength = arg.kiStrength ?? arg.strength ?? 5
        let strengthColor: Color = strength >= 7 ? .green : strength >= 4 ? .orange : .red
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isEigen ? "EIGEN" : "GEGNER").font(.system(size: 9, weight: .bold)).padding(.horizontal, 4).padding(.vertical, 2).background((isEigen ? Color.blue : Color.red).opacity(0.15)).foregroundColor(isEigen ? .blue : .red)
                Spacer()
                Text("\(Int(strength))/10").font(.system(size: 9, weight: .semibold)).foregroundColor(strengthColor)
            }
            Text(arg.title).font(.caption.weight(.semibold)).lineLimit(3)
            if !argEvidence.isEmpty {
                Label("\(argEvidence.count) Beweise", systemImage: "checkmark.circle").font(.system(size: 9)).foregroundColor(.green)
            } else {
                Label("Kein Beweis", systemImage: "xmark.circle").font(.system(size: 9)).foregroundColor(.red)
            }
            ForEach(argGaps) { g in
                Text(g.type.label).font(.system(size: 8)).padding(.horizontal, 4).padding(.vertical, 1).background(g.type.color.opacity(0.15)).foregroundColor(g.type.color).clipShape(Capsule())
            }
        }
        .padding(10)
        .background(isEigen ? Color.blue.opacity(0.05) : Color.red.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedArg?.id == arg.id ? Color.primary : (isEigen ? Color.blue : Color.red).opacity(0.25), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func connectionRow(_ c: Connection) -> some View {
        HStack {
            Text(args.first { $0.id == c.fromId }?.title ?? "").font(.caption).lineLimit(1)
            Text(c.type).font(.caption2.weight(.semibold)).padding(.horizontal, 6).padding(.vertical, 2).background(connectionColor(c.type).opacity(0.15)).foregroundColor(connectionColor(c.type)).clipShape(Capsule())
            Image(systemName: "arrow.right").foregroundColor(connectionColor(c.type)).font(.caption2)
            Text(args.first { $0.id == c.toId }?.title ?? "").font(.caption).lineLimit(1)
            Spacer()
            Text("Intensität \(c.intensitaet)/10").font(.caption2).foregroundColor(.secondary)
        }
        .padding(.vertical, 4).overlay(Divider(), alignment: .bottom)
    }

    private func connectionColor(_ type: String) -> Color {
        switch type {
        case "stützt", "verstärkt": return .green
        case "entkräftet": return .red
        case "widerspricht", "schwächt": return .orange
        case "schließt aus": return .gray
        default: return .blue
        }
    }

    private func argDetail(_ arg: Argument) -> some View {
        let argEvidence = evidence.filter { $0.argumentId == arg.id }
        let outgoing = connections.filter { $0.fromId == arg.id }
        let incoming = connections.filter { $0.toId == arg.id }
        return GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(arg.side == .eigen ? "Eigenes Argument" : "Gegenargument").font(.caption2.weight(.bold))
                        Text(arg.title).font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Text("Stärke \(Int(arg.kiStrength ?? arg.strength ?? 5))/10").font(.caption.weight(.bold))
                }
                if let desc = arg.argDescription { Text(desc).font(.caption).foregroundColor(.secondary) }
                Text("Verknüpfte Beweise (\(argEvidence.count))").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                if argEvidence.isEmpty { Label("Kein Beweis verknüpft – Lücke!", systemImage: "xmark.circle").font(.caption).foregroundColor(.red) }
                else {
                    ForEach(argEvidence) { ev in
                        Label(ev.title, systemImage: "checkmark.circle").font(.caption).foregroundColor(.green)
                    }
                }
                if !outgoing.isEmpty {
                    Text("Wirkt auf").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                    ForEach(outgoing) { c in
                        let target = args.first { $0.id == c.toId }
                        HStack {
                            Text(c.type).font(.caption2.weight(.semibold)).padding(.horizontal, 4).padding(.vertical, 1).background(connectionColor(c.type).opacity(0.15)).foregroundColor(connectionColor(c.type)).clipShape(Capsule())
                            Image(systemName: "arrow.right")
                            Text(target?.title ?? "").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                if !incoming.isEmpty {
                    Text("Wird beeinflusst von").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                    ForEach(incoming) { c in
                        let source = args.first { $0.id == c.fromId }
                        HStack {
                            Text(source?.title ?? "").font(.caption).foregroundColor(.secondary)
                            Image(systemName: "arrow.right")
                            Text(c.type).font(.caption2.weight(.semibold)).padding(.horizontal, 4).padding(.vertical, 1).background(connectionColor(c.type).opacity(0.15)).foregroundColor(connectionColor(c.type)).clipShape(Capsule())
                        }
                    }
                }
            }.padding(8)
        }
    }

    private var kiAnalysisView: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text("KI-Lückenanalyse der Beweisführung").font(.subheadline.weight(.semibold))
                        Text("Die KI analysiert die vollständige Argumentationskette auf logische Lücken.").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button { Task { await runKILueckenAnalyse() } } label: {
                        Label(kiAnalyzing ? "Analysiere…" : (kiLuecken != nil ? "Neu analysieren" : "Analyse starten"), systemImage: "sparkles")
                    }.buttonStyle(.borderedProminent).tint(.purple).disabled(kiAnalyzing || args.count < 2)
                }
            }
            if let r = kiLuecken {
                GroupBox {
                    HStack {
                        VStack {
                            Text(String(format: "%.0f", r.staerke_eigene_kette ?? 0)).font(.title.weight(.bold))
                            Text("Kettenstärke").font(.caption2)
                        }
                        Text(r.gesamtbewertung ?? "").font(.caption).foregroundColor(.secondary)
                    }
                }
                if let luecken = r.luecken, !luecken.isEmpty {
                    Text("Identifizierte Lücken (\(luecken.count))").font(.caption.weight(.semibold))
                    ForEach(luecken) { l in
                        GroupBox {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(l.typ).font(.caption.weight(.semibold))
                                    Spacer()
                                    if let s = l.schwere { Text(s).font(.caption2.weight(.bold)).padding(.horizontal, 4).background((s == "kritisch" ? Color.red : s == "hoch" ? Color.orange : Color.gray).opacity(0.15)).clipShape(Capsule()) }
                                }
                                Text(l.beschreibung).font(.caption)
                                if let e = l.empfehlung { Label(e, systemImage: "checkmark.circle").font(.caption2).foregroundColor(.green) }
                            }
                        }
                    }
                }
                if let emp = r.empfehlungen, !emp.isEmpty {
                    GroupBox("Empfehlungen") {
                        VStack(alignment: .leading) {
                            ForEach(emp, id: \.self) { e in Text("→ \(e)").font(.caption).foregroundColor(.green) }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle").font(.title)
            Text("Noch keine Argumente vorhanden").font(.subheadline).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(40).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed
    private var connections: [Connection] {
        // CloudKit-Modell Argument hat keine "connections" Property; abgeleitet wäre via separates Modell.
        []
    }

    private var gaps: [Gap] {
        var gaps: [Gap] = []
        for arg in args {
            let hasEvidence = evidence.contains { $0.argumentId == arg.id }
            if !hasEvidence {
                gaps.append(Gap(argId: arg.id, type: .noEvidence, desc: "Argument \"\(String(arg.title.prefix(40)))\" hat keinen Beweis verknüpft."))
            }
            let strength = arg.kiStrength ?? arg.strength ?? 5
            if strength < 4 && arg.side == .eigen {
                gaps.append(Gap(argId: arg.id, type: .weakChain, desc: "Eigenes Argument \"\(String(arg.title.prefix(40)))\" ist schwach (Stärke < 4)."))
            }
        }
        return gaps
    }

    // MARK: - Actions
    private func load() async {
        loading = true; defer { loading = false }
        do {
            args = try await cloudKit.fetchForCase(Argument.self, caseId: caseId)
            evidence = try await cloudKit.fetchForCase(Evidence.self, caseId: caseId)
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func runKILueckenAnalyse() async {
        guard args.count >= 2 else { return }
        kiAnalyzing = true; defer { kiAnalyzing = false }
        let prompt = """
        Du bist ein Experte für juristische Beweisführung. Analysiere die Argumentationskette auf logische Lücken.
        Argumente: \(args.map { "- [\($0.side.rawValue)] \"\($0.title)\" Stärke: \(Int($0.kiStrength ?? $0.strength ?? 5))/10" }.joined(separator: "\n"))
        Antworte als JSON: {gesamtbewertung, staerke_eigene_kette, luecken: [{typ, beschreibung, empfehlung, schwere}], empfehlungen}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Lückenanalyse", caseId: caseId)
        if case .success(let value) = res, let raw = value as? String,
           let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(KILueckenAnalyse.self, from: data) {
            kiLuecken = result
        }
    }
}

// MARK: - Gaps Panel

private struct GapsPanel: View {
    let gaps: [ArgumentationskettenVisualisierungView.Gap]
    let args: [Argument]
    let onSelect: (Argument) -> Void

    var body: some View {
        if gaps.isEmpty {
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text("Keine logischen Lücken erkannt").font(.subheadline.weight(.semibold)).foregroundColor(.green)
                    Text("Alle Argumente sind gestützt und verknüpft.").font(.caption).foregroundColor(.secondary)
                }
            }.padding(12).background(Color.green.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Label("\(gaps.count) logische Lücken erkannt", systemImage: "exclamationmark.triangle").font(.subheadline.weight(.semibold)).foregroundColor(.orange)
                ForEach(Dictionary(grouping: gaps, by: \.type).sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { type, items in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(type.label) (\(items.count))").font(.caption.weight(.bold)).foregroundColor(type.color).textCase(.uppercase)
                            ForEach(items) { g in
                                HStack {
                                    Circle().fill(type.color).frame(width: 4, height: 4)
                                    Text(g.desc).font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    if let arg = args.first(where: { $0.id == g.argId }) {
                                        Button("anzeigen") { onSelect(arg) }.buttonStyle(.plain).font(.caption2).foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Views/Lexara/CaseInfluenceGraphView.swift

struct CaseInfluenceGraphView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var deadlines: [Deadline] = []
    @State private var persons: [Person] = []
    @State private var loading = true
    @State private var view: ViewMode = .network
    @State private var filter: NodeType = .all
    @State private var selected: GraphNode?

    enum ViewMode: String, CaseIterable, Identifiable {
        case network, timeline, sankey
        var id: Self { self }
        var label: String { switch self { case .network: return "Netzwerk"; case .timeline: return "Zeitachse"; case .sankey: return "Sankey" } }
        var icon: String { switch self { case .network: return "circle.grid.cross"; case .timeline: return "clock"; case .sankey: return "bolt" } }
    }

    enum NodeType: String, CaseIterable, Identifiable {
        case all, argument, evidence, deadline, person
        var id: Self { self }
        var label: String {
            switch self {
            case .all: return "Alle"; case .argument: return "Argumente"
            case .evidence: return "Beweise"; case .deadline: return "Fristen"; case .person: return "Personen"
            }
        }
    }

    struct GraphNode: Identifiable, Hashable {
        let id: String
        let label: String
        let type: NodeType
        let strength: Double
        let color: Color
        let date: Date?
    }
    struct GraphEdge: Identifiable, Hashable {
        let id = UUID()
        let source: String
        let target: String
        let weight: Double
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading { ProgressView().padding() }
                else {
                    controls
                    Group {
                        switch view {
                        case .network: networkView
                        case .timeline: timelineView
                        case .sankey: sankeyView
                        }
                    }
                    if let s = selected { detailCard(s) }
                    statsCard
                }
            }.padding(20)
        }
        .task { await load() }
    }

    private var controls: some View {
        HStack {
            Picker("View", selection: $view) {
                ForEach(ViewMode.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
            }.pickerStyle(.segmented)
            Picker("Filter", selection: $filter) {
                ForEach(NodeType.allCases) { Text($0.label).tag($0) }
            }.fixedSize()
        }.padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var networkView: some View {
        GroupBox {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                ForEach(filteredNodes) { node in
                    Button {
                        selected = node
                    } label: {
                        VStack(spacing: 4) {
                            Circle().fill(node.color).frame(width: 30 + node.strength * 2, height: 30 + node.strength * 2)
                            Text(node.label).font(.caption2).lineLimit(2).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity).padding(8).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                }
            }.padding(8)
        }
    }

    private var timelineView: some View {
        GroupBox("Zeitachse") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(timelineNodes) { node in
                    HStack {
                        Circle().fill(node.color).frame(width: 12, height: 12)
                        Text(node.label).font(.caption)
                        Spacer()
                        if let d = node.date { Text(d.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundColor(.secondary) }
                    }
                }
            }.padding(8)
        }
    }

    private var sankeyView: some View {
        GroupBox("Beziehungen (Sankey)") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(filteredEdges) { e in
                    HStack {
                        Text(label(for: e.source)).font(.caption).lineLimit(1)
                        Image(systemName: "arrow.right").font(.caption)
                        Text(label(for: e.target)).font(.caption).lineLimit(1)
                        Spacer()
                        Text("Gewicht: \(Int(e.weight))").font(.caption2).foregroundColor(.secondary)
                    }.padding(.vertical, 4).overlay(Divider(), alignment: .bottom)
                }
            }.padding(8)
        }
    }

    private func detailCard(_ node: GraphNode) -> some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading) {
                    Text(node.label).font(.subheadline.weight(.semibold))
                    Text(node.type.label).font(.caption).foregroundColor(.secondary)
                    Text("Stärke: \(Int(node.strength))/10").font(.caption)
                }
                Spacer()
                Button { selected = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }.padding(8)
        }
    }

    private var statsCard: some View {
        GroupBox("Übersicht") {
            HStack(spacing: 16) {
                StatPill(label: "Argumente", count: args.count, color: .blue)
                StatPill(label: "Beweise", count: evidence.count, color: .green)
                StatPill(label: "Fristen", count: deadlines.count, color: .orange)
                StatPill(label: "Personen", count: persons.count, color: .purple)
            }.padding(8)
        }
    }

    // MARK: - Computed
    private var nodes: [GraphNode] {
        var arr: [GraphNode] = []
        for a in args {
            arr.append(GraphNode(id: a.id, label: a.title, type: .argument, strength: a.kiStrength ?? a.strength ?? 5, color: a.side == .eigen ? .blue : .red, date: nil))
        }
        for e in evidence { arr.append(GraphNode(id: e.id, label: e.title, type: .evidence, strength: e.kiWeight ?? e.weight ?? 5, color: .green, date: nil)) }
        for d in deadlines { arr.append(GraphNode(id: d.id, label: d.title, type: .deadline, strength: 7, color: .orange, date: d.dueDate)) }
        for p in persons { arr.append(GraphNode(id: p.id, label: p.name, type: .person, strength: p.glaubwuerdigkeit ?? 5, color: .purple, date: nil)) }
        return arr
    }

    private var filteredNodes: [GraphNode] { filter == .all ? nodes : nodes.filter { $0.type == filter } }
    private var timelineNodes: [GraphNode] { nodes.filter { $0.date != nil }.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) } }
    private var edges: [GraphEdge] {
        args.flatMap { a in a.evidenceIds.map { GraphEdge(source: $0, target: a.id, weight: a.kiStrength ?? a.strength ?? 5) } }
    }
    private var filteredEdges: [GraphEdge] { edges.filter { e in filteredNodes.contains(where: { $0.id == e.source }) && filteredNodes.contains(where: { $0.id == e.target }) } }

    private func label(for id: String) -> String { nodes.first { $0.id == id }?.label ?? id }

    private func load() async {
        loading = true; defer { loading = false }
        do {
            args = try await cloudKit.fetchForCase(Argument.self, caseId: caseId)
            evidence = try await cloudKit.fetchForCase(Evidence.self, caseId: caseId)
            deadlines = try await cloudKit.fetchForCase(Deadline.self, caseId: caseId)
            persons = try await cloudKit.fetchForCase(Person.self, caseId: caseId)
        } catch { cloudKit.lastError = error.localizedDescription }
    }
}

struct StatPill: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        VStack {
            Text("\(count)").font(.headline.weight(.bold)).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(8).background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Views/Lexara/PraezedenzfallSucheView.swift

struct PraezedenzfallSucheView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var query = ""
    @State private var rechtsgebietFilter = ""
    @State private var instanzFilter = ""
    @State private var loading = false
    @State private var results: [Praezedenz] = []
    @State private var saved: Set<String> = []
    @State private var error: String?

    struct Praezedenz: Codable, Identifiable {
        var id: String { aktenzeichen ?? UUID().uuidString }
        var aktenzeichen: String?
        var gericht: String?
        var datum: String?
        var leitsatz: String?
        var sachverhalt: String?
        var entscheidungsgruende: String?
        var relevanz: String?
        var anwendbarkeit: String?
        var url: String?
    }

    struct PraezedenzResponse: Codable {
        var faelle: [Praezedenz]?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchForm
                if loading { ProgressView("Suche Präzedenzfälle…").padding() }
                if let e = error { Label(e, systemImage: "exclamationmark.triangle").foregroundColor(.red).font(.caption) }
                if !results.isEmpty {
                    Text("\(results.count) Präzedenzfälle gefunden").font(.subheadline.weight(.semibold))
                    ForEach(results) { p in resultCard(p) }
                }
            }.padding(20)
        }
    }

    private var searchForm: some View {
        GroupBox("Präzedenzfall-Suche") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Suchbegriff (z. B. \"Mietrecht Eigenbedarf\")", text: $query, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2)
                HStack {
                    TextField("Rechtsgebiet", text: $rechtsgebietFilter).textFieldStyle(.roundedBorder)
                    TextField("Instanz", text: $instanzFilter).textFieldStyle(.roundedBorder)
                }
                Button {
                    Task { await search() }
                } label: {
                    Label("KI-Suche starten", systemImage: "magnifyingglass")
                }.buttonStyle(.borderedProminent).disabled(query.isEmpty || loading)
            }.padding(8)
        }
    }

    private func resultCard(_ p: Praezedenz) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(p.gericht ?? "–").font(.caption2.weight(.bold)).foregroundColor(.blue)
                        Text(p.aktenzeichen ?? "?").font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    if let d = p.datum { Text(d).font(.caption2).foregroundColor(.secondary) }
                    if let r = p.relevanz {
                        Text(r).font(.caption2.weight(.bold)).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(relevanceColor(r).opacity(0.15)).foregroundColor(relevanceColor(r)).clipShape(Capsule())
                    }
                }
                if let l = p.leitsatz { Text(l).font(.caption).italic() }
                if let s = p.sachverhalt { Text("Sachverhalt: \(s)").font(.caption2).foregroundColor(.secondary) }
                if let a = p.anwendbarkeit { Label(a, systemImage: "checkmark.circle").font(.caption2).foregroundColor(.green) }
                HStack {
                    Button(saved.contains(p.id) ? "Gespeichert ✓" : "Als Argument speichern") {
                        Task { await saveAsArgument(p) }
                    }
                    .buttonStyle(.borderedProminent).disabled(saved.contains(p.id))
                    if let url = p.url, let u = URL(string: url) { Link("Quelle", destination: u).font(.caption) }
                }
            }.padding(8)
        }
    }

    private func relevanceColor(_ r: String) -> Color {
        switch r.lowercased() {
        case "hoch": return .green
        case "mittel": return .orange
        default: return .gray
        }
    }

    private func search() async {
        loading = true; defer { loading = false }
        error = nil
        let prompt = """
        Du bist ein juristischer Researcher. Finde 5 relevante Präzedenzfälle.
        Suche: \(query)
        Rechtsgebiet: \(rechtsgebietFilter.isEmpty ? caseData?.rechtsgebiet ?? "" : rechtsgebietFilter)
        Antworte als JSON: {faelle: [{aktenzeichen, gericht, datum, leitsatz, sachverhalt, entscheidungsgruende, relevanz, anwendbarkeit, url}]}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Präzedenzsuche", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String, let data = raw.data(using: .utf8),
           let resp = try? JSONDecoder().decode(PraezedenzResponse.self, from: data) {
            results = resp.faelle ?? []
        } else {
            error = "KI-Suche fehlgeschlagen."
        }
    }

    private func saveAsArgument(_ p: Praezedenz) async {
        var arg = Argument(caseId: caseId, title: "Präzedenz: \(p.aktenzeichen ?? "")")
        arg.argDescription = p.leitsatz
        arg.type = "Präzedenz"
        arg.side = .eigen
        arg.strength = 7
        do {
            _ = try await cloudKit.save(arg)
            saved.insert(p.id)
        } catch let err { error = err.localizedDescription }
    }
}

// MARK: - Views/Lexara/StrategieChecklisteView.swift

fileprivate struct Prinzip: Identifiable, Hashable {
    let id: String
    let titel: String
    let zitat: String
    let kategorie: String
    let norm: String
}

fileprivate let SUN_TZU: [Prinzip] = [
    .init(id: "st1", titel: "Kenne deinen Feind, kenne dich selbst",
          zitat: "Wer den Feind und sich selbst kennt, wird in hundert Schlachten nicht scheitern.",
          kategorie: "Analyse",
          norm: "§ 138 ZPO (Wahrheitspflicht), § 282 ZPO (Prozessförderungspflicht)"),
    .init(id: "st2", titel: "Angriff auf Schwachstellen",
          zitat: "Greife Stärke nicht frontal an — umgehe sie und schlage bei der Schwäche.",
          kategorie: "Taktik", norm: "§ 138 ZPO, Widerklage § 33 ZPO"),
    .init(id: "st3", titel: "Überraschungsmoment",
          zitat: "Reagiere auf Veränderungen schneller als der Gegner erwartet.",
          kategorie: "Prozess", norm: "§ 296 ZPO, § 139 ZPO"),
    .init(id: "st4", titel: "Psychologische Kriegsführung",
          zitat: "Der überlegene Krieger gewinnt, bevor er kämpft.",
          kategorie: "Verhandlung", norm: "§ 278 ZPO (Güteverhandlung), § 42 ZPO (Befangenheit)"),
    .init(id: "st5", titel: "Ressourcenschonung",
          zitat: "Ein langer Krieg nützt niemandem.",
          kategorie: "Kosten", norm: "§§ 91 ff. ZPO, § 93 ZPO"),
    .init(id: "st6", titel: "Flexible Strategie (Wasser-Prinzip)",
          zitat: "Wasser hat keine feste Form — passe deine Strategie der Lage an.",
          kategorie: "Adaptiv", norm: "§ 263 ZPO (Klageänderung), § 264 ZPO"),
]

fileprivate let MACHIAVELLI: [Prinzip] = [
    .init(id: "mv1", titel: "Stärke vor Recht",
          zitat: "Der Fürst muss gleichzeitig Löwe und Fuchs sein.",
          kategorie: "Macht", norm: "§ 935 ZPO (e.V.), §§ 916 ff. ZPO (Arrest)"),
    .init(id: "mv2", titel: "Initiale Entscheidungsschnelligkeit",
          zitat: "Ein langsamer Angriff gibt dem Gegner Zeit – handle zuerst und entscheide.",
          kategorie: "Prozess", norm: "§ 688 ZPO, §§ 935 ff. ZPO"),
    .init(id: "mv3", titel: "Koalitionen schmieden",
          zitat: "Man soll niemals glauben, man könne immer sichere Entschlüsse fassen.",
          kategorie: "Netzwerk", norm: "§ 72 ZPO (Streitverkündung), § 64 ZPO"),
    .init(id: "mv4", titel: "Erschütterung des Vertrauens",
          zitat: "Der kluge Herrscher muss sein Wort nicht halten.",
          kategorie: "Psychologie", norm: "§ 138 ZPO, § 421 ZPO"),
    .init(id: "mv5", titel: "Erschöpfungstaktik",
          zitat: "Halte die Gegner in einem Kriegszustand.",
          kategorie: "Kosten", norm: "§§ 91a ZPO, § 281 ZPO"),
    .init(id: "mv6", titel: "Die Wahrheit dosiert einsetzen",
          zitat: "Täusche so viel, dass der Gegner das Echte nicht erkennt.",
          kategorie: "Taktik", norm: "§ 402 ZPO, § 373 ZPO"),
]

// MARK: - Checklisten-Item
fileprivate struct ChecklistenItem: Identifiable, Hashable {
    let id: String
    var quelle: String          // "suntzu" | "machiavelli"
    var prioritaet: String      // "kritisch" | "hoch" | "mittel"
    var titel: String
    var zitat: String
    var kategorie: String
    var empfehlung: String?
    var norm: String?
    var lit: String?
    var rspr: String?
    var risiko: String?
    var kiGenerated: Bool = false
}

// MARK: - Diagramm-Modus
fileprivate enum ChartMode: String, CaseIterable, Identifiable {
    case wave = "sin(t) Prognose"
    case linear = "f(x)=mx+b"
    case scatter3d = "3D Argument-Feld"
    case radar = "Radar-Profil"
    var id: Self { self }
}

// MARK: - Hauptansicht

struct StrategieChecklisteView: View {
    let caseId: String
    let caseData: Case?
    var kiMode: Bool = true

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var deadlines: [Deadline] = []
    @State private var persons: [Person] = []
    @State private var gegnerVerhalten: [GegnerVerhalten] = []
    @State private var loading = true
    @State private var kiLoading = false
    @State private var checklist: [ChecklistenItem] = []
    @State private var checked: Set<String> = []
    @State private var expanded: Set<String> = []
    @State private var activeFilter: String = "alle"
    @State private var chartMode: ChartMode = .wave

    private var prognose: Double { caseData?.prognose ?? 50 }
    private var eigenArgs: [Argument] { args.filter { $0.side == .eigen } }
    private var gegnerArgs: [Argument] { args.filter { $0.side == .gegner } }
    private var progress: Int {
        guard !checklist.isEmpty else { return 0 }
        return Int(Double(checked.count) / Double(checklist.count) * 100)
    }
    private var richterRate: Double { caseData?.richterKlaegerRate ?? 50 }

    var body: some View {
        ScrollView {
            if loading {
                ProgressView("Lade Falldaten…").padding(40)
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    statsChips
                    visualisierung
                    filterChips
                    checklistView
                    prinzipienReferenz
                }
                .padding()
            }
        }
        .navigationTitle("Strategie-Checkliste")
        .task { await load() }
    }

    // MARK: Sub-Views

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title2).foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text("Strategische Checkliste — Sun Tzu & Machiavelli").bold().font(.callout)
                Text("Geführte nächste Schritte basierend auf allen Fallergebnissen, Prognosen und strategischen Prinzipien.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    ProgressView(value: Double(progress), total: 100).tint(.green)
                    Text("\(progress)%").font(.caption2).bold()
                    Text("\(checked.count)/\(checklist.count) erledigt").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            Spacer()
            Button {
                Task { await runKIChecklist() }
            } label: {
                Label(kiLoading ? "KI lädt…" : "KI-Schritte ergänzen", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(kiLoading)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsChips: some View {
        let items: [(String, String, Color)] = [
            ("Prognose", "\(Int(prognose))%",
             prognose >= 55 ? .green : (prognose >= 40 ? .orange : .red)),
            ("Eigene Args", "\(eigenArgs.count)", .blue),
            ("Gegner Args", "\(gegnerArgs.count)", .red),
            ("Beweise", "\(evidence.count)", .purple),
            ("Versäumt", "\(deadlines.filter { $0.status == .versaeumt }.count)",
             deadlines.contains(where: { $0.status == .versaeumt }) ? .red : .gray),
            ("Richterquote", "\(Int(richterRate))%", .gray),
        ]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 6) {
            ForEach(items, id: \.0) { item in
                VStack {
                    Text(item.1).font(.title3).bold().foregroundStyle(item.2)
                    Text(item.0).font(.caption2).foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(item.2.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var visualisierung: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Strategische Visualisierung", systemImage: "chart.xyaxis.line").bold().font(.callout)
                Spacer()
                Picker("Modus", selection: $chartMode) {
                    ForEach(ChartMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)
            }
            Group {
                switch chartMode {
                case .wave:      prognoseWaveChart
                case .linear:    linearChart
                case .scatter3d: scatterChart
                case .radar:     radarChart
                }
            }
            .frame(height: 240)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    /// Sinuskurve y(t) = prognose + (prognose/2) * sin(t)
    private var prognoseWaveChart: some View {
        let amp = prognose / 2
        let data: [(t: Double, y: Double, lower: Double)] = (0..<40).map { i in
            let t = Double(i) * 0.4
            return (t,
                    prognose + amp * sin(t),
                    prognose - amp * 0.4 * sin(t + .pi / 3))
        }
        return Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("t", p.t), y: .value("y", p.y), series: .value("Serie", "Prognose"))
                    .foregroundStyle(.indigo)
            }
            ForEach(Array(data.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("t", p.t), y: .value("y", p.lower), series: .value("Serie", "Risiko"))
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
            RuleMark(y: .value("50%", 50)).foregroundStyle(.orange).lineStyle(StrokeStyle(dash: [4]))
        }
        .chartYScale(domain: 0...100)
    }

    /// Lineare Strategie-Funktion f(x) = m·x + b
    private var linearChart: some View {
        let m: Double = prognose > 50 ? 2.1 : 1.2
        let b: Double = max(5, prognose - Double(eigenArgs.count) * m)
        let data = (0..<15).map { x in (Double(x), m * Double(x) + b) }
        return Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("x", p.0), y: .value("f(x)", p.1)).foregroundStyle(.green)
                PointMark(x: .value("x", p.0), y: .value("f(x)", p.1)).foregroundStyle(.green)
            }
            RuleMark(y: .value("50%", 50)).foregroundStyle(.orange).lineStyle(StrokeStyle(dash: [4]))
        }
        .chartYScale(domain: 0...100)
    }

    /// 3D-ähnlicher Scatter (X=Stärke, Y=Beweis-Ø, Symbolgröße = Beweisanzahl)
    private var scatterChart: some View {
        struct ScatterPt: Identifiable {
            let id = UUID(); let x: Double; let y: Double; let size: Double
            let name: String; let side: ArgumentSide
        }
        let data: [ScatterPt] = args.prefix(12).enumerated().map { (i, a) in
            let related = evidence.filter { $0.argumentId == a.id }
            let evCount = related.count
            let yVal = evCount > 0 ? related.reduce(0.0) { $0 + ($1.weight ?? 5) } / Double(evCount) : 0
            return ScatterPt(x: a.strength ?? 5, y: yVal,
                             size: Double(evCount) * 15 + 10,
                             name: a.title.prefix(14).description, side: a.side)
        }
        return Chart {
            ForEach(data) { p in
                PointMark(x: .value("Stärke", p.x), y: .value("Ø Gewicht", p.y))
                    .symbolSize(p.size * 4)
                    .foregroundStyle(p.side == .eigen ? .green : .red)
            }
        }
        .chartXScale(domain: 0...10)
        .chartYScale(domain: 0...10)
    }

    /// Radar – wir nutzen Bar-Chart als Ersatz auf macOS, da Charts kein Radar bietet.
    private var radarChart: some View {
        struct RadarPt: Identifiable { let id = UUID(); let label: String; let value: Double }
        let pts: [RadarPt] = [
            .init(label: "Argumente",
                  value: eigenArgs.isEmpty ? 0 :
                    eigenArgs.reduce(0) { $0 + ($1.strength ?? 5) } / Double(eigenArgs.count) * 10),
            .init(label: "Beweise", value: min(100, Double(evidence.count) * 12)),
            .init(label: "Prognose", value: prognose),
            .init(label: "Fristen",
                  value: max(0, 100 - Double(deadlines.filter { $0.status == .versaeumt }.count) * 25)),
            .init(label: "Richter", value: richterRate),
            .init(label: "Gegner-Info", value: min(100, Double(gegnerVerhalten.count) * 15)),
        ]
        return Chart {
            ForEach(pts) { p in
                BarMark(x: .value("Faktor", p.label), y: .value("Wert", p.value))
                    .foregroundStyle(.indigo)
            }
        }
        .chartYScale(domain: 0...100)
    }

    private var filterChips: some View {
        HStack {
            ForEach([("alle","Alle"), ("kritisch","Kritisch"), ("hoch","Hoch"),
                     ("suntzu","Sun Tzu"), ("machiavelli","Machiavelli"), ("ki","KI-Schritte")], id: \.0) { v, l in
                Button(l) { activeFilter = v }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(activeFilter == v ? Color.black : Color.gray.opacity(0.15),
                                in: Capsule())
                    .foregroundStyle(activeFilter == v ? .white : .primary)
            }
        }
    }

    private var checklistView: some View {
        VStack(spacing: 8) {
            if filteredList.isEmpty {
                Text("Keine Einträge für diesen Filter.")
                    .font(.caption).foregroundStyle(.secondary).padding()
            } else {
                ForEach(filteredList) { item in
                    CheckItemRow(
                        item: item,
                        checked: checked.contains(item.id),
                        expanded: expanded.contains(item.id),
                        onToggle: { toggleSet(&checked, item.id) },
                        onExpand: { toggleSet(&expanded, item.id) }
                    )
                }
            }
        }
    }

    private var prinzipienReferenz: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 16) {
                column(title: "Sun Tzu — Die Kunst des Krieges", icon: "shield.lefthalf.filled", items: SUN_TZU)
                column(title: "Machiavelli — Il Principe", icon: "book.closed", items: MACHIAVELLI)
            }
        }
    }
    private func column(title: String, icon: String, items: [Prinzip]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption).bold().foregroundStyle(.secondary)
            ForEach(items) { p in
                HStack(alignment: .top) {
                    Text(p.kategorie).font(.caption2).bold()
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 3))
                    VStack(alignment: .leading) {
                        Text(p.titel).font(.caption).bold()
                        Text(p.zitat).font(.caption2).italic().foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Datenoperationen

    private func toggleSet(_ set: inout Set<String>, _ id: String) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
    }

    private var filteredList: [ChecklistenItem] {
        switch activeFilter {
        case "alle": return checklist
        case "ki":   return checklist.filter { $0.kiGenerated }
        case "suntzu": return checklist.filter { $0.quelle == "suntzu" }
        case "machiavelli": return checklist.filter { $0.quelle == "machiavelli" }
        default: return checklist.filter { $0.prioritaet == activeFilter }
        }
    }

    private func load() async {
        loading = true
        let pred = NSPredicate(format: "case_id == %@", caseId)
        async let a = cloudKit.fetch(Argument.self, predicate: pred)
        async let e = cloudKit.fetch(Evidence.self, predicate: pred)
        async let d = cloudKit.fetch(Deadline.self, predicate: pred)
        async let p = cloudKit.fetch(Person.self, predicate: pred)
        async let gv = cloudKit.fetch(GegnerVerhalten.self, predicate: pred)
        args = (try? await a) ?? []
        evidence = (try? await e) ?? []
        deadlines = (try? await d) ?? []
        persons = (try? await p) ?? []
        gegnerVerhalten = (try? await gv) ?? []
        generateAlgorithmicChecklist()
        loading = false
    }

    /// Erzeugt die Checkliste rein algorithmisch (ohne KI), basierend auf Falldaten.
    private func generateAlgorithmicChecklist() {
        let eigen = args.filter { $0.side == .eigen }
        let gegner = args.filter { $0.side == .gegner }
        let versaeumt = deadlines.filter { $0.status == .versaeumt }.count
        var items: [ChecklistenItem] = []

        // Stärkstes eigenes Argument
        if let top = eigen.max(by: { ($0.strength ?? 0) < ($1.strength ?? 0) }) {
            items.append(.init(
                id: "st_kenne_dich", quelle: "suntzu", prioritaet: "kritisch",
                titel: "Stärkstes eigenes Argument identifizieren & schärfen",
                zitat: SUN_TZU[0].zitat, kategorie: "Analyse",
                empfehlung: "„\(top.title)" + " (Stärke \(Int(top.strength ?? 5))/10) als Kernargument ausbauen.",
                norm: "§ 138 ZPO – vollständige, wahrheitsgemäße Darlegung",
                lit: "Zöller/Greger, ZPO § 138 Rn. 8 ff.",
                rspr: "BGH NJW 2008, 2047 – Substanziierungspflicht",
                risiko: "Unsubstanziiertes Vorbringen kann nach § 296 ZPO zurückgewiesen werden."
            ))
        }
        // Schwächstes Gegnerargument
        if let weak = gegner.min(by: { ($0.strength ?? 10) < ($1.strength ?? 10) }) {
            items.append(.init(
                id: "st_schwachstelle", quelle: "suntzu", prioritaet: "hoch",
                titel: "Schwächstes Gegenargument angreifen",
                zitat: SUN_TZU[1].zitat, kategorie: "Taktik",
                empfehlung: "„\(weak.title)" + " (\(Int(weak.strength ?? 5))/10) gezielt entkräften.",
                norm: "§ 138 Abs. 2 ZPO – Erklärungspflicht auf Gegenvorbringen",
                lit: "Rosenberg/Schwab/Gottwald § 65 Rn. 12",
                rspr: "BGH NJW 2011, 1965 – Bestreiten mit Nichtwissen",
                risiko: "Unsubstanziiertes Bestreiten = Zugeständnis (§ 138 Abs. 3 ZPO)."
            ))
        }
        if versaeumt > 0 {
            items.append(.init(
                id: "mv_fristen", quelle: "machiavelli", prioritaet: "kritisch",
                titel: "\(versaeumt) versäumte Fristen – Wiedereinsetzung prüfen",
                zitat: MACHIAVELLI[1].zitat, kategorie: "Prozess",
                empfehlung: "Sofort Wiedereinsetzungsantrag nach § 233 ZPO prüfen.",
                norm: "§§ 233–238 ZPO", lit: "Zöller/Greger § 233 Rn. 1 ff.",
                rspr: "BGH NJW 2012, 2048", risiko: "Präklusion (§ 296 ZPO) oder Rechtsverlust."))
        }
        if evidence.count < 3 {
            items.append(.init(
                id: "st_beweis", quelle: "suntzu", prioritaet: "hoch",
                titel: "Beweislage kritisch schwach – Beweise beschaffen",
                zitat: "Der Sieg gehört dem, der am meisten weiß.", kategorie: "Analyse",
                empfehlung: "§ 422 ZPO Urkunden, § 402 ZPO SV, § 373 ZPO Zeugen.",
                norm: "§§ 373, 402, 422 ZPO", lit: "MüKoZPO/Prütting § 286 Rn. 45 ff.",
                rspr: "BGH NJW 2020, 1234", risiko: "Beweisnotstand."))
        }
        if richterRate > 60 {
            items.append(.init(
                id: "st_richter_positiv", quelle: "suntzu", prioritaet: "mittel",
                titel: "Günstige Richterquote ausnutzen", zitat: SUN_TZU[3].zitat,
                kategorie: "Verhandlung",
                empfehlung: "Richter-Klägerquote \(Int(richterRate))% – strukturiert argumentieren.",
                norm: "§ 136 GVG, § 139 ZPO",
                lit: "Prütting/Gehrlein § 139 Rn. 2 ff.",
                rspr: "BVerfG NJW 2003, 281",
                risiko: "Richter kann wechseln – Geschäftsverteilungsplan prüfen."))
        } else if richterRate < 40 {
            items.append(.init(
                id: "mv_richter_kritisch", quelle: "machiavelli", prioritaet: "hoch",
                titel: "Kritische Richterquote – Befangenheit oder Vergleich",
                zitat: MACHIAVELLI[0].zitat, kategorie: "Macht",
                empfehlung: "Richter-Klägerquote nur \(Int(richterRate))% – § 42 ZPO prüfen.",
                norm: "§ 42 ZPO, § 278 ZPO", lit: "Zöller/Vollkommer § 42 Rn. 8 ff.",
                rspr: "BGH NJW 2018, 1412", risiko: "Kostenfolge bei Ablehnung."))
        }
        if prognose < 40 {
            items.append(.init(
                id: "mv_erschoepfung", quelle: "machiavelli", prioritaet: "kritisch",
                titel: "Niedrige Prognose – Vergleich oder Kostenanalyse",
                zitat: MACHIAVELLI[4].zitat, kategorie: "Kosten",
                empfehlung: "Prognose \(Int(prognose))% – Kostenrisiko kalkulieren.",
                norm: "§ 278 ZPO, §§ 91 ff. ZPO", lit: "Musielak/Voit § 91 Rn. 3 ff.",
                rspr: "BGH NJW 2016, 897", risiko: "Volle Kostentragung nach § 91 ZPO."))
        } else if prognose >= 65 {
            items.append(.init(
                id: "mv_angriff", quelle: "machiavelli", prioritaet: "hoch",
                titel: "Starke Prognose – Initiative ergreifen",
                zitat: MACHIAVELLI[1].zitat, kategorie: "Prozess",
                empfehlung: "Prognose \(Int(prognose))% – Verfahren beschleunigen.",
                norm: "§ 704 ZPO, §§ 803 ff. ZPO",
                lit: "Schuschke/Walker, Vollstreckung Rn. 4",
                rspr: "BGH NJW 2019, 2392",
                risiko: "Schadensersatzpflicht aus § 717 ZPO."))
        }
        if gegnerVerhalten.contains(where: { $0.patternTag == .verzoegerungstaktik }) {
            items.append(.init(
                id: "mv_verzoegerung", quelle: "machiavelli", prioritaet: "hoch",
                titel: "Gegner verzögert – prozessuale Gegenmaßnahmen",
                zitat: MACHIAVELLI[4].zitat, kategorie: "Taktik",
                empfehlung: "§ 296 ZPO-Rüge, § 231 ZPO (Säumnisurteil), § 272 ZPO.",
                norm: "§§ 272, 296, 231 ZPO",
                lit: "Prütting/Gehrlein § 272 Rn. 1 ff.",
                rspr: "BGH NJW 2014, 1881",
                risiko: "Eigenes Zuwarten = Einwilligung in Verzögerung."))
        }
        if persons.contains(where: { $0.role == .zeuge }) {
            items.append(.init(
                id: "st_zeuge", quelle: "suntzu", prioritaet: "mittel",
                titel: "Zeugen strategisch einsetzen & vorbereiten",
                zitat: SUN_TZU[2].zitat, kategorie: "Prozess",
                empfehlung: "Kernaussagen schärfen, Widersprüche herausarbeiten (§ 396 ZPO).",
                norm: "§§ 373–401 ZPO, § 396 ZPO",
                lit: "Stein/Jonas/Berger § 373 Rn. 6 ff.",
                rspr: "BGH NJW 2017, 2050",
                risiko: "Unvorbereitete Zeugen schaden."))
        }
        if eigen.contains(where: { ($0.kiStrength ?? 0) > ($0.strength ?? 0) + 3 }) {
            items.append(.init(
                id: "st_ki_diskrepanz", quelle: "suntzu", prioritaet: "mittel",
                titel: "KI bewertet eigene Argumente stärker", zitat: SUN_TZU[5].zitat,
                kategorie: "Adaptiv",
                empfehlung: "Möglicherweise unterschätzte Argumente weiter ausbauen.",
                norm: "§ 138 ZPO", lit: "Prütting/Gehrlein § 138 Rn. 3 ff.", rspr: nil, risiko: nil))
        }
        if items.count < 3 {
            items.append(.init(
                id: "mv_koalition", quelle: "machiavelli", prioritaet: "mittel",
                titel: "Streitverkündung oder Nebenintervention prüfen",
                zitat: MACHIAVELLI[2].zitat, kategorie: "Netzwerk",
                empfehlung: "§ 72 ZPO an mögliche Regress-Schuldner.",
                norm: "§ 72 ZPO, § 64 ZPO",
                lit: "Zöller/Vollkommer § 72 Rn. 4 ff.",
                rspr: "BGH NJW 2007, 1534", risiko: nil))
        }
        checklist = items
    }

    /// Ergänzt die Checkliste durch KI-generierte Schritte (Sun-Tzu/Machiavelli-Stil).
    private func runKIChecklist() async {
        kiLoading = true; defer { kiLoading = false }
        let prompt = """
        Du bist Senior-Prozessanwalt. Analysiere diesen Fall und erstelle 4 strategische
        Handlungsschritte basierend auf Sun Tzu UND Machiavelli mit ZPO/BGB-Normen, BGH-Rspr., Lit.

        Fall: \(caseData?.fallname ?? "") | Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Prognose: \(Int(prognose))% | Eigene: \(eigenArgs.count) | Gegner: \(gegnerArgs.count)
        Beweise: \(evidence.count) | Versäumte Fristen: \(deadlines.filter { $0.status == .versaeumt }.count)
        Richterquote: \(Int(richterRate))%
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "schritte": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "titel":      ["type": "string"],
                            "prinzip":    ["type": "string"],
                            "quelle":     ["type": "string", "enum": ["suntzu", "machiavelli"]],
                            "kategorie":  ["type": "string"],
                            "empfehlung": ["type": "string"],
                            "norm":       ["type": "string"],
                            "lit":        ["type": "string"],
                            "rspr":       ["type": "string"],
                            "prioritaet": ["type": "string", "enum": ["kritisch", "hoch", "mittel"]],
                            "risiko":     ["type": "string"]
                        ]
                    ]
                ]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res,
              let dict = any as? [String: Any],
              let arr  = dict["schritte"] as? [[String: Any]] else { return }
        for (i, s) in arr.enumerated() {
            let item = ChecklistenItem(
                id: "ki_\(i)",
                quelle: s["quelle"] as? String ?? "suntzu",
                prioritaet: s["prioritaet"] as? String ?? "mittel",
                titel: s["titel"] as? String ?? "Unbenannt",
                zitat: s["prinzip"] as? String ?? "",
                kategorie: s["kategorie"] as? String ?? "Strategie",
                empfehlung: s["empfehlung"] as? String,
                norm: s["norm"] as? String,
                lit: s["lit"] as? String,
                rspr: s["rspr"] as? String,
                risiko: s["risiko"] as? String,
                kiGenerated: true
            )
            checklist.append(item)
        }
    }
}

// MARK: - Check-Item-Zeile
fileprivate struct CheckItemRow: View {
    let item: ChecklistenItem
    let checked: Bool
    let expanded: Bool
    var onToggle: () -> Void
    var onExpand: () -> Void

    private var prioColor: Color {
        switch item.prioritaet {
        case "kritisch": return .red
        case "hoch":     return .orange
        default:         return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Button { onToggle() } label: {
                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(checked ? .green : .gray)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: item.quelle == "suntzu" ? "shield" : "book")
                            .foregroundStyle(.secondary)
                        Text(item.titel)
                            .font(.subheadline).bold()
                            .strikethrough(checked)
                            .foregroundStyle(checked ? .secondary : .primary)
                        Text(item.kategorie).font(.caption2).bold()
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.gray.opacity(0.15), in: Capsule())
                        Text(item.prioritaet).font(.caption2).bold()
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(prioColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(prioColor)
                        if item.kiGenerated {
                            Text("KI").font(.caption2).bold()
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Color.purple.opacity(0.15), in: Capsule())
                                .foregroundStyle(.purple)
                        }
                    }
                    Text(item.zitat).font(.caption2).italic().foregroundStyle(.secondary)
                    if let e = item.empfehlung { Text("→ \(e)").font(.caption) }
                }
                Spacer()
                Button { onExpand() } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            if expanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let n = item.norm   { row("Rechtsgrundlage", n, .indigo) }
                    if let l = item.lit    { row("Literatur", l, .gray) }
                    if let r = item.rspr   { row("Rspr.", r, .gray) }
                    if let r = item.risiko {
                        Label(r, systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }
                .padding([.horizontal, .bottom])
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(checked ? Color.gray.opacity(0.05) : Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.2)))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption2).bold().foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value).font(.caption).foregroundStyle(color)
        }
    }
}

// MARK: - Views/Lexara/TabArgumenteView.swift

struct TabArgumenteView: View {
    let caseId: String
    let caseData: Case?
    var onCountChange: (() -> Void)? = nil

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    // MARK: - State
    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var filter: SideFilter = .all
    @State private var sortBy: SortMode = .created
    @State private var showAdd = false
    @State private var newArg = NewArgumentDraft()
    @State private var extractError: String?
    @State private var batchRating = false
    @State private var kiGenerating = false
    @State private var kiGenResult: KiGenResult?
    @State private var showExtraction = false
    @State private var extractMode: ExtractMode = .ki
    @State private var dsgvo = false
    @State private var text = ""
    @State private var extracting = false
    @State private var extracted: ExtractedResult?
    @State private var detectingDuplicates = false
    @State private var duplicates: [DuplicateGroup]?
    @State private var sheetMessage: String?

    // MARK: - Lokale Hilfstypen
    enum SideFilter: String, CaseIterable, Identifiable {
        case all, eigen, gegner
        var id: Self { self }
        var label: String {
            switch self { case .all: return "Alle"; case .eigen: return "Eigene"; case .gegner: return "Gegner" }
        }
    }

    enum SortMode: String, CaseIterable, Identifiable {
        case created, date, strength
        var id: Self { self }
        var label: String {
            switch self { case .created: return "Erstellt"; case .date: return "Datum"; case .strength: return "Stärke" }
        }
    }

    enum ExtractMode: String, CaseIterable, Identifiable {
        case algo, ki
        var id: Self { self }
        var label: String { self == .algo ? "Algorithmus" : "KI" }
    }

    struct NewArgumentDraft {
        var title = ""
        var description = ""
        var side: ArgumentSide = .eigen
        var strength: Double = 5
        var type: String = "Rechtsargument"
        var zeitpunkt: Date? = nil
        var anmerkungen = ""
    }

    /// Lokales Modell für KI-Extraktionsergebnisse.
    struct ExtractedResult {
        var zusammenfassung: String?
        var beweise: [ExtractedEvidence] = []
        var eigeneArgumente: [ExtractedArgument] = []
        var gegenseiteArgumente: [ExtractedArgument] = []
        var relevantePara: [String] = []
    }
    struct ExtractedEvidence: Identifiable {
        let id = UUID()
        var titel: String
        var beschreibung: String?
        var typ: String?
        var gewicht: Double?
    }
    struct ExtractedArgument: Identifiable {
        let id = UUID()
        var titel: String
        var beschreibung: String?
        var typ: String?
        var staerke: Double?
        var datum: String?
        var paragraphen: [String] = []
        var beweise: [ExtractedEvidence] = []
    }

    struct KiGenResult {
        var eigene: [ExtractedArgument] = []
        var gegner: [ExtractedArgument] = []
    }

    struct DuplicateGroup: Identifiable {
        let id = UUID()
        var nummern: [Int]
        var grund: String
        var zuBehalten: Int
    }

    // MARK: - Computed
    private var filtered: [Argument] {
        var list = args.filter { arg in
            filter == .all
            || (filter == .eigen && arg.side == .eigen)
            || (filter == .gegner && arg.side == .gegner)
        }
        switch sortBy {
        case .date:
            list.sort { (a, b) in
                let da = parseDate(a.zeitpunkt)?.timeIntervalSince1970 ?? 0
                let db = parseDate(b.zeitpunkt)?.timeIntervalSince1970 ?? 0
                return da > db
            }
        case .strength:
            list.sort { (a, b) in
                let sa = a.kiStrength ?? a.strength ?? 0
                let sb = b.kiStrength ?? b.strength ?? 0
                return sa > sb
            }
        case .created:
            break
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                toolbar
                if let dups = duplicates { duplicatesPanel(dups) }
                if let kg = kiGenResult { kiGeneratedPanel(kg) }
                if showAdd { addPanel }
                extractionPanel
                argumentList
            }
            .padding()
        }
        .navigationTitle("Argumente")
        .task { await loadAll() }
        .alert("Hinweis", isPresented: Binding(get: { sheetMessage != nil }, set: { if !$0 { sheetMessage = nil } })) {
            Button("OK", role: .cancel) { sheetMessage = nil }
        } message: {
            Text(sheetMessage ?? "")
        }
    }

    // MARK: - Sub-Views
    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(SideFilter.allCases) { f in
                    Button { filter = f } label: {
                        Text(f.label)
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(filter == f ? Color.accentColor : Color.gray.opacity(0.15),
                                        in: Capsule())
                            .foregroundStyle(filter == f ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
                Divider().frame(height: 16)
                Text("Sortierung:").font(.caption2).foregroundStyle(.secondary)
                ForEach(SortMode.allCases) { s in
                    Button { sortBy = s } label: {
                        Text(s.label)
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(sortBy == s ? Color.blue : Color.gray.opacity(0.15),
                                        in: Capsule())
                            .foregroundStyle(sortBy == s ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            HStack {
                Button {
                    Task { await rateBatch() }
                } label: {
                    Label(batchRating ? "Bewerte…" : "Alle bewerten", systemImage: "star.fill")
                }
                .disabled(batchRating || args.isEmpty)

                Button {
                    Task { await generateKiArgumente() }
                } label: {
                    Label(kiGenerating ? "KI generiert…" : "KI-Argumente", systemImage: "sparkles")
                }
                .disabled(kiGenerating)

                Button {
                    Task { await detectDuplicates() }
                } label: {
                    Label(detectingDuplicates ? "Prüfe…" : "Duplikate", systemImage: "magnifyingglass")
                }
                .disabled(detectingDuplicates)

                Button(role: .destructive) {
                    Task { await cleanupWithoutEvidence() }
                } label: {
                    Label("Ohne Belege löschen", systemImage: "trash")
                }

                Button {
                    showAdd.toggle()
                } label: {
                    Label("Argument", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.small)
        }
    }

    private func duplicatesPanel(_ groups: [DuplicateGroup]) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Ähnliche Argumente gefunden", systemImage: "magnifyingglass")
                        .font(.callout).bold()
                    Spacer()
                    Button(role: .destructive) {
                        Task { await deleteDuplicates(groups) }
                    } label: { Label("Doppelte löschen", systemImage: "trash") }
                    Button("Schließen") { duplicates = nil }
                }
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.grund).font(.caption).bold()
                        ForEach(group.nummern, id: \.self) { idx in
                            if let arg = args[safe: idx - 1] {
                                let keep = idx == group.zuBehalten
                                HStack(alignment: .top, spacing: 8) {
                                    Text("#\(idx)").font(.caption2).monospaced()
                                        .foregroundStyle(keep ? .green : .red)
                                    VStack(alignment: .leading) {
                                        Text(arg.title).font(.caption).bold()
                                        if let d = arg.argDescription {
                                            Text(d).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if keep { Text("BEHALTEN").font(.caption2).bold().foregroundStyle(.green) }
                                }
                                .padding(6)
                                .background((keep ? Color.green : Color.red).opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func kiGeneratedPanel(_ kg: KiGenResult) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("KI-generierte Argumente", systemImage: "sparkles")
                        .font(.callout).bold()
                    Spacer()
                    Button {
                        Task { await takeAllKiArgumente() }
                    } label: { Label("Alle übernehmen", systemImage: "checkmark") }
                    Button(role: .destructive) { kiGenResult = nil } label: {
                        Label("Alle löschen", systemImage: "trash")
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    kiGenColumn(label: "EIGENE ARGUMENTE", items: kg.eigene, side: .eigen)
                    kiGenColumn(label: "GEGNERARGUMENTE", items: kg.gegner, side: .gegner)
                }
            }
        }
    }

    private func kiGenColumn(label: String, items: [ExtractedArgument], side: ArgumentSide) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label) · \(items.count)")
                .font(.caption2).bold().foregroundStyle(.secondary)
            ForEach(items) { a in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(a.titel).font(.caption).bold()
                            if let b = a.beschreibung { Text(b).font(.caption2).foregroundStyle(.secondary) }
                            if !a.paragraphen.isEmpty {
                                HStack {
                                    ForEach(a.paragraphen, id: \.self) { p in
                                        Text(p).font(.caption2).monospaced()
                                            .padding(.horizontal, 4).padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                                    }
                                }
                            }
                            if side == .eigen && !a.beweise.isEmpty {
                                ForEach(a.beweise) { ev in
                                    Label(ev.titel, systemImage: "doc.text").font(.caption2)
                                }
                            }
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            Text("\(Int(a.staerke ?? 5))/10").font(.caption2).foregroundStyle(.secondary)
                            Button("Übernehmen") {
                                Task { await takeKiArg(a, side: side) }
                            }
                            .font(.caption2)
                        }
                    }
                }
                .padding(6)
                .background(.background, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addPanel: some View {
        GroupBox("Neues Argument") {
            VStack(spacing: 8) {
                TextField("Titel *", text: $newArg.title)
                TextField("Beschreibung", text: $newArg.description, axis: .vertical)
                    .lineLimit(2...4)
                HStack {
                    DatePicker("Zeitpunkt",
                               selection: Binding(get: { newArg.zeitpunkt ?? Date() },
                                                  set: { newArg.zeitpunkt = $0 }),
                               displayedComponents: .date)
                        .labelsHidden()
                    TextField("Anmerkungen", text: $newArg.anmerkungen)
                }
                HStack {
                    Picker("Seite", selection: $newArg.side) {
                        Text("Eigen").tag(ArgumentSide.eigen)
                        Text("Gegner").tag(ArgumentSide.gegner)
                    }
                    .pickerStyle(.menu)
                    Picker("Typ", selection: $newArg.type) {
                        ForEach(["Rechtsargument","Tatsachenargument","Widerspruch","Druckmittel"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    Stepper(value: $newArg.strength, in: 0...10, step: 0.5) {
                        Text("Stärke: \(newArg.strength, specifier: "%.1f")")
                    }
                }
                HStack {
                    Spacer()
                    Button("Abbrechen") { showAdd = false }
                    Button("Hinzufügen") { Task { await addManual() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(newArg.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    private var extractionPanel: some View {
        GroupBox {
            DisclosureGroup(isExpanded: $showExtraction) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Modus:").font(.caption).foregroundStyle(.secondary)
                        Picker("Modus", selection: $extractMode) {
                            ForEach(ExtractMode.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    if extractMode == .ki {
                        GroupBox("DSGVO-Hinweis (Art. 13, 28 DSGVO)") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Dokumente werden ausschließlich zur Analyse verarbeitet").font(.caption2)
                                Text("• Keine dauerhafte Speicherung der Originaldokumente").font(.caption2)
                                Text("• Keine Weitergabe an Dritte").font(.caption2)
                                Toggle("Ich stimme der Verarbeitung zu", isOn: $dsgvo)
                                    .font(.caption)
                            }
                        }
                    }
                    TextField("Oder Text manuell einfügen…", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await handleExtract() }
                    } label: {
                        if extracting {
                            Label("Analysiere…", systemImage: "arrow.clockwise")
                        } else {
                            Label("Analysieren", systemImage: "wand.and.stars")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(extracting)
                    if let err = extractError {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if let ext = extracted {
                        extractionResults(ext)
                    }
                }
            } label: {
                Label("Argument-Extraktion – Dokumente & Texte analysieren",
                      systemImage: "doc.text.magnifyingglass")
                    .font(.callout)
            }
        }
    }

    private func extractionResults(_ ext: ExtractedResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let s = ext.zusammenfassung {
                Text(s).font(.caption).italic().foregroundStyle(.secondary)
                    .padding(.leading, 8)
                    .overlay(Rectangle().frame(width: 2).foregroundStyle(.gray), alignment: .leading)
            }
            HStack {
                Spacer()
                Button { Task { await takeAll() } } label: {
                    Label("Alle übernehmen", systemImage: "checkmark")
                }
                Button(role: .destructive) {
                    extracted = nil; text = ""
                } label: { Label("Alle löschen", systemImage: "trash") }
            }
            HStack(alignment: .top, spacing: 16) {
                extractedColumn(label: "EIGENE ARGUMENTE", items: ext.eigeneArgumente, side: .eigen)
                extractedColumn(label: "GEGENSEITE", items: ext.gegenseiteArgumente, side: .gegner)
            }
        }
    }

    private func extractedColumn(label: String, items: [ExtractedArgument], side: ArgumentSide) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label) · \(items.count)").font(.caption2).bold().foregroundStyle(.secondary)
            ForEach(items) { a in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(a.titel).font(.caption).bold()
                        Spacer()
                        Text("\(Int(a.staerke ?? 5))/10").font(.caption2).foregroundStyle(.secondary)
                        if let d = a.datum {
                            Text(d).font(.caption2)
                                .padding(.horizontal, 4)
                                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                        }
                        Button("Übernehmen") { Task { await take(a, side: side) } }
                            .font(.caption2)
                    }
                    if let typ = a.typ { Text(typ).font(.caption2).foregroundStyle(.secondary) }
                    if !a.paragraphen.isEmpty {
                        HStack {
                            ForEach(a.paragraphen.prefix(3), id: \.self) { p in
                                Text(p).font(.caption2).monospaced()
                                    .padding(.horizontal, 3).background(Color.blue.opacity(0.1),
                                                                        in: RoundedRectangle(cornerRadius: 3))
                            }
                            if a.paragraphen.count > 3 {
                                Text("+\(a.paragraphen.count - 3)").font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var argumentList: some View {
        VStack(spacing: 8) {
            ForEach(filtered) { arg in
                VStack(alignment: .leading, spacing: 6) {
                    ArgCardView(arg: arg,
                                onDelete: { Task { await del(arg.id) } },
                                onSave: { Task { await loadAll() } },
                                onKiWeight: { Task { await kiWeightFor(arg) } })
                    if let reason = arg.kiReasoning {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KI-Begründung (Stärke \(Int(arg.kiStrength ?? 0))/10):")
                                .font(.caption).bold()
                            Text(reason).font(.caption2)
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            if filtered.isEmpty {
                ContentUnavailableView("Noch keine Argumente",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Manuell hinzufügen oder aus Dokument extrahieren."))
            }
        }
    }

    // MARK: - Daten-Operationen
    @MainActor
    private func loadAll(notify: Bool = false) async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        let aLoad = (try? await cloudKit.fetch(Argument.self, predicate: pred)) ?? []
        let eLoad = (try? await cloudKit.fetch(Evidence.self, predicate: pred)) ?? []
        args = aLoad
        evidence = eLoad
        if notify { onCountChange?() }
    }

    private func addManual() async {
        guard !newArg.title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var a = Argument(caseId: caseId, title: newArg.title)
        a.argDescription = newArg.description.isEmpty ? nil : newArg.description
        a.side = newArg.side
        a.strength = newArg.strength
        a.type = newArg.type
        if let z = newArg.zeitpunkt { a.zeitpunkt = isoDate(z) }
        a.anmerkungen = newArg.anmerkungen.isEmpty ? nil : newArg.anmerkungen
        _ = try? await cloudKit.save(a)
        newArg = NewArgumentDraft()
        showAdd = false
        await loadAll(notify: true)
    }

    private func del(_ id: String) async {
        try? await cloudKit.delete(recordID: id)
        await loadAll(notify: true)
    }

    private func kiWeightFor(_ arg: Argument) async {
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Bewerte die Stärke dieses Rechtsarguments im deutschen Zivilprozess.
        Argument: "\(arg.title)"
        Beschreibung: "\(arg.argDescription ?? "")"
        Typ: \(arg.type ?? "Rechtsargument"), Seite: \(arg.side.rawValue)
        Gib eine Stärke (0-10) UND eine kurze juristische Begründung (2-3 Sätze) zurück.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "staerke": ["type": "number", "minimum": 0, "maximum": 10],
                "begruendung": ["type": "string"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res, let dict = any as? [String: Any] {
            let s = (dict["staerke"] as? Double) ?? 0
            let b = (dict["begruendung"] as? String) ?? ""
            var updated = arg
            updated.kiStrength = min(10, max(0, s))
            updated.kiReasoning = b
            _ = try? await cloudKit.save(updated)
            await loadAll()
        }
    }

    private func handleExtract() async {
        if extractMode == .ki && !dsgvo { extractError = "Bitte DSGVO-Hinweis akzeptieren"; return }
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            extractError = "Text erforderlich"; return
        }
        extracting = true; extractError = nil
        defer { extracting = false }
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Analysiere diese Eingabe gründlich und extrahiere:
        1. EIGENE ARGUMENTE (welche Klauseln unterstützen unsere Position?)
        2. GEGENSEITE-ARGUMENTE
        3. BEWEISE (Klauseln, Unterschriften, Daten)
        4. Für jedes Argument: zugehörige Beweise.
        5. DATUM: YYYY-MM-DD, falls erkennbar.

        Fall: \(caseData?.fallname ?? "") | \(caseData?.rechtsgebiet ?? "")
        Rechtsfrage: \(caseData?.zentraleRechtsfrage ?? "")
        TEXT: \(text)
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "zusammenfassung": ["type": "string"],
                "beweise": ["type": "array"],
                "eigene_argumente": ["type": "array"],
                "gegenseite_argumente": ["type": "array"],
                "relevante_paragraphen": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            extractError = "KI-Analyse fehlgeschlagen"; return
        }
        extracted = parseExtraction(dict)
        text = ""
    }

    private func parseExtraction(_ dict: [String: Any]) -> ExtractedResult {
        var r = ExtractedResult()
        r.zusammenfassung = dict["zusammenfassung"] as? String
        r.relevantePara = dict["relevante_paragraphen"] as? [String] ?? []
        r.beweise = (dict["beweise"] as? [[String: Any]] ?? []).map { parseEv($0) }
        r.eigeneArgumente = (dict["eigene_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
        r.gegenseiteArgumente = (dict["gegenseite_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
        return r
    }

    private func parseEv(_ d: [String: Any]) -> ExtractedEvidence {
        ExtractedEvidence(titel: d["titel"] as? String ?? "",
                          beschreibung: d["beschreibung"] as? String,
                          typ: d["typ"] as? String,
                          gewicht: d["gewicht"] as? Double)
    }
    private func parseArg(_ d: [String: Any]) -> ExtractedArgument {
        ExtractedArgument(
            titel: d["titel"] as? String ?? "",
            beschreibung: d["beschreibung"] as? String,
            typ: d["typ"] as? String,
            staerke: d["staerke"] as? Double,
            datum: d["datum"] as? String,
            paragraphen: d["paragraphen"] as? [String] ?? d["paragraphen"] as? [String] ?? [],
            beweise: (d["beweise"] as? [[String: Any]] ?? []).map { parseEv($0) }
        )
    }

    private func take(_ a: ExtractedArgument, side: ArgumentSide) async {
        var arg = Argument(caseId: caseId, title: a.titel)
        arg.argDescription = a.beschreibung
        arg.side = side
        arg.strength = a.staerke ?? 5
        arg.type = a.typ ?? "Rechtsargument"
        arg.paragraphs = a.paragraphen
        arg.zeitpunkt = a.datum
        _ = try? await cloudKit.save(arg)
        extracted.map { ext in
            var copy = ext
            if side == .eigen { copy.eigeneArgumente.removeAll { $0.titel == a.titel } }
            else { copy.gegenseiteArgumente.removeAll { $0.titel == a.titel } }
            extracted = copy
        }
        await loadAll(notify: true)
    }

    private func takeAll() async {
        guard let ext = extracted else { return }
        // Erst Beweise speichern und Map Titel → ID bauen
        var evMap: [String: String] = [:]
        for ev in ext.beweise where !ev.titel.isEmpty {
            var e = Evidence(caseId: caseId, title: ev.titel)
            e.evidenceDescription = ev.beschreibung
            e.type = ev.typ ?? "Dokument"
            e.source = "Extraktion"
            e.weight = ev.gewicht ?? 5
            if let saved = try? await cloudKit.save(e) { evMap[ev.titel] = saved.id }
        }
        let all: [(ExtractedArgument, ArgumentSide)] =
            ext.eigeneArgumente.map { ($0, .eigen) } +
            ext.gegenseiteArgumente.map { ($0, .gegner) }
        for (a, side) in all {
            var arg = Argument(caseId: caseId, title: a.titel)
            arg.argDescription = a.beschreibung
            arg.side = side
            arg.strength = a.staerke ?? 5
            arg.type = a.typ ?? "Rechtsargument"
            arg.paragraphs = a.paragraphen
            arg.zeitpunkt = a.datum
            _ = try? await cloudKit.save(arg)
        }
        extracted = nil
        await loadAll(notify: true)
        sheetMessage = "\(all.count) Argument(e) übernommen, \(evMap.count) Beweis(e) erstellt"
    }

    private func rateBatch() async {
        guard !args.isEmpty else { return }
        batchRating = true; defer { batchRating = false }
        let lines = args.enumerated().map { (i, a) in
            "\(i+1). [\(a.side.rawValue.uppercased())] \(a.title)\nBeschreibung: \(a.argDescription ?? "-")"
        }.joined(separator: "\n\n")
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Bewerte die Stärke dieser Argumente.
        Fall: \(caseData?.fallname ?? "")
        Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Zentrale Frage: \(caseData?.zentraleRechtsfrage ?? "")
        \(lines)
        Gib pro Argument: index, staerke (0-10), begruendung.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "bewertungen": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res,
           let dict = any as? [String: Any],
           let bews = dict["bewertungen"] as? [[String: Any]] {
            for b in bews {
                guard let idx = b["index"] as? Int, args.indices.contains(idx) else { continue }
                var a = args[idx]
                a.kiStrength = min(10, max(0, (b["staerke"] as? Double) ?? 0))
                a.kiReasoning = b["begruendung"] as? String
                _ = try? await cloudKit.save(a)
            }
            await loadAll(notify: true)
        }
    }

    private func generateKiArgumente() async {
        kiGenerating = true; defer { kiGenerating = false }
        kiGenResult = nil
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Generiere auf Basis des Fallkontexts die stärksten
        juristischen Argumente für unsere Seite UND die zu erwartenden Gegenargumente.

        Fall: \(caseData?.fallname ?? "")
        Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Zentrale Rechtsfrage: \(caseData?.zentraleRechtsfrage ?? "")
        Prozessziel: \(caseData?.prozessziel ?? "")
        Instanz: \(caseData?.instanz.rawValue ?? "")
        Gericht: \(caseData?.gericht ?? "")

        Maximal 19 Argumente. Für jedes: titel, beschreibung, staerke, paragraphen, beweise (nur eigene Argumente).
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "eigene_argumente": ["type": "array"],
                "gegner_argumente": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res, let dict = any as? [String: Any] {
            var k = KiGenResult()
            k.eigene = (dict["eigene_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
            k.gegner = (dict["gegner_argumente"] as? [[String: Any]] ?? []).map { parseArg($0) }
            kiGenResult = k
        }
    }

    private func takeKiArg(_ a: ExtractedArgument, side: ArgumentSide) async {
        // Wenn Beweise vorhanden -> als Beweise speichern, kein Argument anlegen
        if side == .eigen && !a.beweise.isEmpty {
            for ev in a.beweise {
                var e = Evidence(caseId: caseId, title: ev.titel)
                e.evidenceDescription = ev.beschreibung
                e.type = ev.typ ?? "Dokument"
                e.weight = ev.gewicht ?? 5
                _ = try? await cloudKit.save(e)
            }
            // Eventuell bestehendes gleichnamiges Argument löschen
            if let existing = args.first(where: { $0.title == a.titel }) {
                try? await cloudKit.delete(recordID: existing.id)
            }
        } else {
            var arg = Argument(caseId: caseId, title: a.titel)
            arg.argDescription = a.beschreibung
            arg.side = side
            arg.strength = a.staerke ?? 5
            arg.type = "Rechtsargument"
            arg.paragraphs = a.paragraphen
            _ = try? await cloudKit.save(arg)
        }
        kiGenResult.map { kg in
            var copy = kg
            if side == .eigen { copy.eigene.removeAll { $0.titel == a.titel } }
            else { copy.gegner.removeAll { $0.titel == a.titel } }
            kiGenResult = copy
        }
        await loadAll(notify: true)
    }

    private func takeAllKiArgumente() async {
        guard let kg = kiGenResult else { return }
        let all = kg.eigene.map { ($0, ArgumentSide.eigen) } + kg.gegner.map { ($0, ArgumentSide.gegner) }
        for (a, side) in all { await takeKiArg(a, side: side) }
        kiGenResult = nil
    }

    private func detectDuplicates() async {
        guard args.count >= 2 else {
            sheetMessage = "Zu wenige Argumente zum Vergleich."; return
        }
        detectingDuplicates = true; defer { detectingDuplicates = false }
        let argsList = args.enumerated().map { (i, a) in
            "\(i+1). \(a.title)\(a.argDescription.map { " — " + String($0.prefix(60)) } ?? "")"
        }.joined(separator: "\n")
        let prompt = """
        Finde ähnliche oder doppelte Argumente. Paraphrasierungen zählen.
        ARGUMENTE:
        \(argsList)
        Gib Gruppen ähnlicher Argumente zurück mit nummern[], grund, zu_behalten.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": ["duplikat_gruppen": ["type": "array"]]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res,
           let dict = any as? [String: Any],
           let groups = dict["duplikat_gruppen"] as? [[String: Any]], !groups.isEmpty {
            duplicates = groups.map {
                DuplicateGroup(
                    nummern: $0["nummern"] as? [Int] ?? [],
                    grund: $0["grund"] as? String ?? "",
                    zuBehalten: $0["zu_behalten"] as? Int ?? 0
                )
            }
        } else {
            sheetMessage = "Keine ähnlichen Argumente gefunden."
            duplicates = nil
        }
    }

    private func deleteDuplicates(_ groups: [DuplicateGroup]) async {
        var deleted = 0
        for group in groups {
            for idx in group.nummern where idx != group.zuBehalten {
                if let arg = args[safe: idx - 1] {
                    try? await cloudKit.delete(recordID: arg.id); deleted += 1
                }
            }
        }
        await loadAll(notify: true)
        duplicates = nil
        sheetMessage = "\(deleted) doppelte Argumente gelöscht."
    }

    private func cleanupWithoutEvidence() async {
        let withoutEv = args.filter { $0.evidenceIds.isEmpty }
        if withoutEv.isEmpty {
            sheetMessage = "Alle Argumente haben Belege."; return
        }
        if evidence.isEmpty {
            for a in withoutEv { try? await cloudKit.delete(recordID: a.id) }
            await loadAll(notify: true)
            sheetMessage = "\(withoutEv.count) Argumente gelöscht."
            return
        }
        let allEv = evidence.map { e in
            "[\(e.type ?? "Beweis")] \(e.title)\nBeschreibung: \(e.evidenceDescription ?? "")"
        }.joined(separator: "\n---\n")
        let prompt = """
        Du bist Rechtsanwalt. Prüfe sorgfältig den inhaltlichen Bezug.
        BEWEISE:
        \(allEv)
        ARGUMENTE OHNE EVIDENCE-IDS:
        \(withoutEv.map { "\($0.title)\nBeschreibung: \($0.argDescription ?? "-")" }.joined(separator: "\n==="))
        Gib zu_loeschen[] mit titel und grund zurück.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": ["zu_loeschen": ["type": "array"]]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        if case .success(let any) = res,
           let dict = any as? [String: Any],
           let toDel = dict["zu_loeschen"] as? [[String: Any]], !toDel.isEmpty {
            var n = 0
            for item in toDel {
                if let t = item["titel"] as? String,
                   let arg = withoutEv.first(where: { $0.title == t }) {
                    try? await cloudKit.delete(recordID: arg.id); n += 1
                }
            }
            await loadAll(notify: true)
            sheetMessage = "\(n) Argumente gelöscht (KI-basiert)."
        } else {
            sheetMessage = "KI: Alle Argumente haben Bezug. Keine Löschung."
        }
    }

    // MARK: - Helpers
    private func parseDate(_ s: String?) -> Date? {
        guard let s else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
    private func isoDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}

// MARK: - Argument-Kachel
private struct ArgCardView: View {
    let arg: Argument
    var onDelete: () -> Void
    var onSave: () -> Void
    var onKiWeight: () -> Void
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider
    @State private var editing = false
    @State private var form: TabArgumenteView.NewArgumentDraft = .init()
    @State private var newPara = ""
    @State private var paragraphs: [String] = []
    @State private var analyzing = false
    @State private var kiWeighting = false
    @State private var analysisExpl: String?
    @State private var analysisVorschlaege: [String] = []

    private var discrepancy: Double {
        guard let k = arg.kiStrength else { return 0 }
        return abs((arg.strength ?? 5) - k)
    }
    private var hasDiscrepancy: Bool { discrepancy >= 2 }

    var body: some View {
        GroupBox {
            if editing { editView } else { displayView }
        }
        .onAppear {
            form.title = arg.title
            form.description = arg.argDescription ?? ""
            form.side = arg.side
            form.type = arg.type ?? "Rechtsargument"
            form.strength = arg.strength ?? 5
            form.anmerkungen = arg.anmerkungen ?? ""
            paragraphs = arg.paragraphs
        }
    }

    private var displayView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(arg.side == .eigen ? "Eigen" : "Gegner")
                    .font(.caption2).bold()
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background((arg.side == .eigen ? Color.blue : Color.red).opacity(0.15),
                                in: Capsule())
                if let t = arg.type {
                    Text(t).font(.caption2).foregroundStyle(.secondary)
                }
                if hasDiscrepancy {
                    Label("Δ \(discrepancy, specifier: "%.1f")", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2).foregroundStyle(.orange)
                }
                Spacer()
                Button { editing = true } label: { Image(systemName: "pencil") }.buttonStyle(.plain)
                Button { onDelete() } label: { Image(systemName: "trash") }.buttonStyle(.plain)
            }
            Text(arg.title).font(.callout).bold()
            if let d = arg.argDescription {
                Text(d).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            }
            HStack {
                if let z = arg.zeitpunkt {
                    Label(z, systemImage: "calendar").font(.caption2).foregroundStyle(.secondary)
                }
                if let a = arg.anmerkungen {
                    Label(a, systemImage: "note.text").font(.caption2).foregroundStyle(.orange)
                }
            }
            VStack(spacing: 4) {
                scoreRow(label: "Manuell", value: arg.strength ?? 5, color: .blue)
                scoreRow(label: "KI-Stärke", value: arg.kiStrength ?? 0, color: .purple,
                         shown: arg.kiStrength != nil)
            }
            if !arg.paragraphs.isEmpty {
                HStack {
                    ForEach(arg.paragraphs, id: \.self) { p in
                        Text(p).font(.caption2).monospaced()
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                    }
                }
            }
            HStack {
                Button {
                    Task { await runKiWeight() }
                } label: {
                    Label(kiWeighting ? "Bewerte…" : "KI bewerten", systemImage: "sparkles")
                        .font(.caption2)
                }
                .disabled(kiWeighting)
                if hasDiscrepancy {
                    Button { Task { await analyzeDiscrepancy() } } label: {
                        Label(analyzing ? "Analysiere…" : "Diskrepanz analysieren",
                              systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                    }
                    .disabled(analyzing)
                }
            }
            if let expl = analysisExpl {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expl).font(.caption)
                    ForEach(Array(analysisVorschlaege.enumerated()), id: \.offset) { (i, v) in
                        HStack(alignment: .top) {
                            Text("\(i+1).").bold()
                            Text(v).font(.caption)
                        }
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var editView: some View {
        VStack(spacing: 6) {
            TextField("Titel *", text: $form.title)
            TextField("Beschreibung", text: $form.description, axis: .vertical).lineLimit(2...4)
            HStack {
                Picker("Seite", selection: $form.side) {
                    Text("Eigen").tag(ArgumentSide.eigen)
                    Text("Gegner").tag(ArgumentSide.gegner)
                }.pickerStyle(.menu)
                Picker("Typ", selection: $form.type) {
                    ForEach(["Rechtsargument","Tatsachenargument","Widerspruch","Druckmittel"], id: \.self) {
                        Text($0).tag($0)
                    }
                }.pickerStyle(.menu)
                Stepper(value: $form.strength, in: 0...10, step: 0.5) {
                    Text("Stärke \(form.strength, specifier: "%.1f")")
                }
            }
            // Paragraphen
            HStack {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { (i, p) in
                    HStack(spacing: 2) {
                        Text(p).font(.caption2).monospaced()
                        Button {
                            paragraphs.remove(at: i)
                        } label: { Image(systemName: "xmark.circle.fill").font(.caption2) }
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                }
            }
            HStack {
                TextField("z.B. § 280 BGB", text: $newPara)
                Button("+") {
                    let trimmed = newPara.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { paragraphs.append(trimmed); newPara = "" }
                }
            }
            HStack {
                Spacer()
                Button("Abbrechen") { editing = false }
                Button("Speichern") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .textFieldStyle(.roundedBorder)
    }

    private func scoreRow(label: String, value: Double, color: Color, shown: Bool = true) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
            ProgressView(value: shown ? value / 10 : 0).tint(color)
            Text(shown ? "\(Int(value))" : "–").font(.caption2).bold().foregroundStyle(color)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private func save() async {
        var a = arg
        a.title = form.title
        a.argDescription = form.description.isEmpty ? nil : form.description
        a.side = form.side
        a.type = form.type
        a.strength = form.strength
        a.anmerkungen = form.anmerkungen.isEmpty ? nil : form.anmerkungen
        a.paragraphs = paragraphs
        _ = try? await cloudKit.save(a)
        editing = false
        onSave()
    }

    private func runKiWeight() async {
        kiWeighting = true; defer { kiWeighting = false }
        onKiWeight()
    }

    private func analyzeDiscrepancy() async {
        analyzing = true; defer { analyzing = false }
        let prompt = """
        Analysiere die Diskrepanz zwischen manueller und KI-Bewertung dieses Rechtsarguments:
        Argument: "\(arg.title)"
        Beschreibung: "\(arg.argDescription ?? "")"
        Manuelle Stärke: \(arg.strength ?? 5)/10
        KI-Stärke: \(arg.kiStrength ?? 0)/10
        Diskrepanz: \(discrepancy)
        Liefere erklaerung und 3 vorschlaege.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "erklaerung": ["type": "string"],
                "vorschlaege": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema)
        if case .success(let any) = res, let dict = any as? [String: Any] {
            analysisExpl = dict["erklaerung"] as? String
            analysisVorschlaege = dict["vorschlaege"] as? [String] ?? []
        }
    }
}

// MARK: - Helfer
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Views/Lexara/TabDokumenteView.swift

struct TabDokumenteView: View {
    let caseId: String

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var documents: [LegalDocument] = []
    @State private var loading = true
    @State private var importing = false
    @State private var selectedDoc: LegalDocument? = nil
    @State private var showImporter = false
    @State private var analyzing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if loading { ProgressView().padding() }
                else if documents.isEmpty { emptyState }
                else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                        ForEach(documents) { doc in
                            documentCard(doc)
                                .onTapGesture { selectedDoc = doc }
                        }
                    }
                }
            }.padding(20)
        }
        .task { await load() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf, .text, UTType("public.composite-content") ?? .data]) { result in
            if case .success(let url) = result { Task { await importDoc(url) } }
        }
        .sheet(item: $selectedDoc) { doc in detailSheet(doc) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Dokumente").font(.headline)
                Text("\(documents.count) Dokumente").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button { showImporter = true } label: { Label("Hochladen", systemImage: "plus") }.buttonStyle(.borderedProminent).disabled(importing)
        }
    }

    private var emptyState: some View {
        VStack {
            Image(systemName: "doc.fill").font(.largeTitle).foregroundColor(.secondary)
            Text("Noch keine Dokumente").foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(40).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func documentCard(_ doc: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: iconFor(doc.fileType)).font(.largeTitle).foregroundColor(.blue)
            Text(doc.title).font(.subheadline.weight(.semibold)).lineLimit(2)
            if let s = doc.aiSummary { Text(s).font(.caption2).foregroundColor(.secondary).lineLimit(3) }
            if !doc.extractedArguments.isEmpty {
                Label("\(doc.extractedArguments.count) Argumente", systemImage: "text.bubble").font(.caption2).foregroundColor(.green)
            }
        }
        .padding(12).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func detailSheet(_ doc: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(doc.title).font(.headline)
                Spacer()
                Button { selectedDoc = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            if let s = doc.aiSummary {
                GroupBox("Zusammenfassung") { Text(s).font(.body).padding(8) }
            } else {
                Button { Task { await analyze(doc) } } label: {
                    Label(analyzing ? "Analysiere…" : "KI-Analyse starten", systemImage: "sparkles")
                }.buttonStyle(.borderedProminent).disabled(analyzing)
            }
            if !doc.extractedArguments.isEmpty {
                GroupBox("Extrahierte Argumente") {
                    VStack(alignment: .leading) {
                        ForEach(doc.extractedArguments, id: \.self) { Text("• \($0)").font(.caption) }
                    }.padding(8)
                }
            }
            HStack {
                Button("Löschen", role: .destructive) { Task { await delete(doc) } }
                Spacer()
            }
        }.padding(20).frame(width: 540, height: 480)
    }

    private func iconFor(_ type: String?) -> String {
        switch type?.lowercased() {
        case "pdf": return "doc.richtext"
        case "txt", "md": return "doc.text"
        case "docx": return "doc"
        default: return "doc.fill"
        }
    }

    private func load() async {
        loading = true; defer { loading = false }
        do { documents = try await cloudKit.fetchForCase(LegalDocument.self, caseId: caseId) }
        catch { cloudKit.lastError = error.localizedDescription }
    }

    private func importDoc(_ url: URL) async {
        importing = true; defer { importing = false }
        let title = url.deletingPathExtension().lastPathComponent
        var doc = LegalDocument(caseId: caseId, title: title)
        doc.fileType = url.pathExtension
        doc.fileUrl = url.absoluteString
        do { _ = try await cloudKit.save(doc); await load() }
        catch { cloudKit.lastError = error.localizedDescription }
    }

    private func analyze(_ doc: LegalDocument) async {
        analyzing = true; defer { analyzing = false }
        let prompt = "Fasse das Dokument \"\(doc.title)\" für einen Anwalt zusammen und extrahiere relevante Argumente (max. 10)."
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Dokumentanalyse", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String {
            var d = doc
            d.aiSummary = raw
            do { _ = try await cloudKit.save(d); await load() }
            catch { cloudKit.lastError = error.localizedDescription }
        }
    }

    private func delete(_ doc: LegalDocument) async {
        do { try await cloudKit.delete(recordID: doc.id); await load(); selectedDoc = nil }
        catch { cloudKit.lastError = error.localizedDescription }
    }
}

// MARK: - Views/Lexara/TabGesamtbewertungView.swift

fileprivate let SIMPLE_EXPLANATIONS: [String: String] = [
    "Prior-Wahrscheinlichkeit (Basisrate)":
        "💡 Bevor wir irgendetwas wissen, fragen wir: Wie oft gewinnt der Kläger statistisch in diesem Rechtsgebiet?",
    "Argumentationsbilanz":
        "💡 Wie stark sind unsere Argumente vs. die gegnerischen? Eine Waage.",
    "Beweisqualität & -quantität":
        "💡 Mehr gute Beweise = bessere Chancen, aber abnehmender Grenznutzen.",
    "Richter-Statistik (Bayesianisch)":
        "💡 Wir passen die Prognose an die Richter-Klägerquote an.",
    "Richter-Statistik":
        "💡 Kein Richter bekannt – Prognose unverändert.",
    "Fristenrisiko (Malus)":
        "💡 Versäumte Fristen schaden erheblich.",
    "Vergleichsangebot-Signal":
        "💡 Ein hohes Angebot zeigt gegnerische Unsicherheit.",
    "Finale Wahrscheinlichkeit (Logistische Transformation)":
        "💡 Logistische Funktion → Prozentzahl 0–100%.",
    "90%-Konfidenzintervall (Fehlerfortpflanzung)":
        "💡 Realistischer Korridor mit 90% Wahrscheinlichkeit.",
]

// MARK: - KI-Strategieanalyse-Modell
fileprivate struct GesamtKIAnalyse: Hashable {
    var erfolgswahrscheinlichkeit: Int = 50
    var begruendung: String?
    var unsereTaktiken: [TaktikItem] = []
    var gegnerStrategien: [GegnerItem] = []
    var gegnerAsse: [TaktikItem] = []
    var unsereSchwachstellen: [SchwachItem] = []
    var gesamtstrategie: String?
    var gegnerArgumente: [GegnerArg] = []
    var gegnerVorgehen: [VorgehenStep] = []
}
fileprivate struct TaktikItem: Identifiable, Hashable {
    let id = UUID(); var titel: String; var beschreibung: String
}
fileprivate struct GegnerItem: Identifiable, Hashable {
    let id = UUID(); var titel: String; var beschreibung: String; var gefahr: String
}
fileprivate struct SchwachItem: Identifiable, Hashable {
    let id = UUID(); var titel: String; var risiko: String?
}
fileprivate struct GegnerArg: Identifiable, Hashable {
    let id = UUID(); var argument: String; var paragraphen: String?; var staerke: String; var unsereAntwort: String?
}
fileprivate struct VorgehenStep: Identifiable, Hashable {
    let id = UUID(); var phase: String; var beschreibung: String; var risiko: String?
}

// MARK: - Hauptansicht

struct TabGesamtbewertungView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var persons: [Person] = []
    @State private var deadlines: [Deadline] = []
    @State private var loaded = false
    @State private var analyzing = false
    @State private var kiAnalyse: GesamtKIAnalyse?
    @State private var algoResult: PrognoseResult?
    @State private var breakEven: BreakEvenResult?
    @State private var showAlgoSteps = false

    var body: some View {
        ScrollView {
            if !loaded {
                ProgressView().padding(40)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    if let r = algoResult { algoStepsCard(r) }
                    scoreVergleichCard
                    kiAnalyseCard
                }
                .padding()
            }
        }
        .navigationTitle("Gesamtbewertung")
        .task { await load() }
    }

    // MARK: Sub-Views

    private var headerCard: some View {
        let score = algoResult?.score ?? 0
        let ci = algoResult.map { "[\($0.ciLow)%–\($0.ciHigh)%]" } ?? ""
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GESAMTBEWERTUNG · \(caseData?.fallname ?? "Fall")")
                    .font(.caption2).foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline) {
                    Text("\(score)%").font(.system(size: 48, weight: .bold))
                    Text("90%-CI: \(ci)").font(.caption).foregroundStyle(.secondary)
                }
                Text("\(args.count) Argumente · \(evidence.count) Beweise · \(args.filter{$0.side == .eigen}.count) eigen · \(args.filter{$0.side == .gegner}.count) Gegner")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Label("Algorithmus", systemImage: "function")
                .font(.caption)
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color.black, in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
    }

    private func algoStepsCard(_ result: PrognoseResult) -> some View {
        let grouped = Dictionary(grouping: result.steps, by: { $0.kategorie })
        return GroupBox {
            DisclosureGroup(isExpanded: $showAlgoSteps) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(grouped.keys), id: \.self) { kat in
                        VStack(alignment: .leading) {
                            Text(kat).font(.caption).bold().foregroundStyle(.secondary)
                            ForEach(grouped[kat] ?? []) { step in
                                AlgoStepRow(step: step)
                            }
                        }
                    }
                    if let be = breakEven { breakEvenSection(be) }
                }
            } label: {
                HStack {
                    Label("Berechnungsschritte (aufklappbar)", systemImage: "function").bold().font(.callout)
                    Spacer()
                    Text("σ=\(String(format: "%.1f", result.sigma * 100))% Unsicherheit").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func breakEvenSection(_ be: BreakEvenResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("Break-Even-Schwelle").font(.caption).foregroundStyle(.secondary)
                    Text(be.formel).font(.caption2).monospaced().foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(be.breakEvenPct ?? 0)%").font(.title).bold().foregroundStyle(.orange)
                    Text("Mindest-Erfolgsquote").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text("💡 \(be.empfehlung)")
                .font(.caption)
                .padding(8)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            if !be.zusatzoptionen.isEmpty {
                Text("⚡ Zusätzliche Klageoptions-Szenarien")
                    .font(.caption).bold().foregroundStyle(.secondary)
                ForEach(be.zusatzoptionen) { opt in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("\(opt.symbol) \(opt.titel)").font(.caption).bold()
                            Text(opt.beschreibung).font(.caption2).foregroundStyle(.secondary)
                            Text(opt.rechtsgrundlage).font(.caption2).monospaced().foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("\(opt.breakEvenPct)%").font(.headline).foregroundStyle(.green)
                            Text("Break-Even").font(.caption2).foregroundStyle(.secondary)
                            Text(opt.basis).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var scoreVergleichCard: some View {
        let eigene = args.filter { $0.side == .eigen }
        let gegner = args.filter { $0.side == .gegner }
        let manEigen = avg(eigene.compactMap { $0.strength })
        let manGegner = avg(gegner.compactMap { $0.strength })
        let manEv = avg(evidence.compactMap { $0.weight })
        let kiEigen = avg(eigene.compactMap { $0.kiStrength })
        let kiGegner = avg(gegner.compactMap { $0.kiStrength })
        let kiEv = avg(evidence.compactMap { $0.kiWeight })
        let hasKi = eigene.contains(where: { $0.kiStrength != nil }) || evidence.contains(where: { $0.kiWeight != nil })

        let manScore = (eigene.count + evidence.count) == 0 ? 0 :
            manEigen * 0.4 + max(0, 10 - manGegner) * 0.3 + manEv * 0.3
        let kiScore: Double? = hasKi ? (kiEigen * 0.4 + max(0, 10 - kiGegner) * 0.3 + kiEv * 0.3) : nil

        return GroupBox("Gewichtungsvergleich") {
            VStack(spacing: 12) {
                HStack {
                    scoreCard(label: "Eigene Argumente", manual: manEigen, ki: hasKi ? kiEigen : nil, icon: "scalemass")
                    scoreCard(label: "Gegner-Argumente", manual: manGegner, ki: hasKi ? kiGegner : nil, icon: "exclamationmark.shield")
                    scoreCard(label: "Beweise", manual: manEv, ki: hasKi ? kiEv : nil, icon: "doc.text")
                }
                Divider()
                HStack {
                    VStack {
                        Text("Gesamtscore manuell").font(.caption).foregroundStyle(.secondary)
                        Text("\(manScore, specifier: "%.1f")").font(.largeTitle).bold().foregroundStyle(.blue)
                        Text("von 10").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    if let ks = kiScore {
                        VStack {
                            Text("Gesamtscore KI").font(.caption).foregroundStyle(.purple)
                            Text("\(ks, specifier: "%.1f")").font(.largeTitle).bold().foregroundStyle(.purple)
                            Text("von 10").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack {
                            Text("KI-Gewichtung fehlt").font(.caption).foregroundStyle(.secondary)
                            Text("Nutze KI-Gewichtung in Tab 2 & 3").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func scoreCard(label: String, manual: Double, ki: Double?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.caption).bold()
            HStack {
                Text("Manuell").font(.caption2).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
                ProgressView(value: manual / 10).tint(.blue)
                Text("\(manual, specifier: "%.1f")/10").font(.caption2).bold().frame(width: 50, alignment: .trailing)
            }
            if let k = ki {
                HStack {
                    Text("KI").font(.caption2).foregroundStyle(.purple).frame(width: 60, alignment: .leading)
                    ProgressView(value: k / 10).tint(.purple)
                    Text("\(k, specifier: "%.1f")/10").font(.caption2).bold().foregroundStyle(.purple).frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var kiAnalyseCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Label("KI-Strategieanalyse", systemImage: "brain.head.profile").bold()
                        Text("Liefert Rspr., Taktiken & Gegnerstrategien – keine eigene Risikoberechnung")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await runKiAnalyse() }
                    } label: {
                        Label(analyzing ? "Analysiere…" : (kiAnalyse != nil ? "Neu analysieren" : "Analyse starten"),
                              systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(analyzing)
                }

                if let a = kiAnalyse {
                    kiAnalyseInhalt(a)
                } else if !analyzing {
                    Text("Starte die KI-Analyse für eine vollständige strategische Bewertung")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func kiAnalyseInhalt(_ a: GesamtKIAnalyse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("KI-Erfolgswahrscheinlichkeit").font(.caption).foregroundStyle(.secondary)
                    Text("\(a.erfolgswahrscheinlichkeit)%").font(.system(size: 40, weight: .bold))
                }
                Spacer()
                ProgressView(value: Double(a.erfolgswahrscheinlichkeit), total: 100).tint(.green).frame(width: 200)
            }
            .padding()
            .background(LinearGradient(colors: [.black, .gray], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
            if let beg = a.begruendung { Text(beg).font(.caption) }
            if let s = a.gesamtstrategie {
                VStack(alignment: .leading) {
                    Text("🎯 Empfohlene Gesamtstrategie").font(.caption).bold().foregroundStyle(.blue)
                    Text(s).font(.subheadline)
                }
                .padding()
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            if !a.unsereTaktiken.isEmpty {
                section("⚔️ Unsere Taktiken", color: .green) {
                    ForEach(a.unsereTaktiken) { t in
                        VStack(alignment: .leading) {
                            Label(t.titel, systemImage: "target").bold().font(.caption)
                            Text(t.beschreibung).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerStrategien.isEmpty {
                section("🛡️ Erwartete Gegnerstrategien", color: .red) {
                    ForEach(a.gegnerStrategien) { g in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(g.titel).bold().font(.caption)
                                Text(g.gefahr).font(.caption2).bold()
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(gefahrColor(g.gefahr).opacity(0.2), in: Capsule())
                                    .foregroundStyle(gefahrColor(g.gefahr))
                            }
                            Text(g.beschreibung).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(gefahrColor(g.gefahr).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerAsse.isEmpty {
                section("🃏 Asse im Ärmel des Gegners", color: .red) {
                    ForEach(a.gegnerAsse) { ace in
                        VStack(alignment: .leading) {
                            Label(ace.titel, systemImage: "bolt").bold().font(.caption).foregroundStyle(.red)
                            Text(ace.beschreibung).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.unsereSchwachstellen.isEmpty {
                section("⚠️ Unsere kritischen Schwachstellen", color: .orange) {
                    ForEach(a.unsereSchwachstellen) { sw in
                        VStack(alignment: .leading) {
                            Label(sw.titel, systemImage: "exclamationmark.triangle").bold().font(.caption).foregroundStyle(.orange)
                            if let r = sw.risiko { Text(r).font(.caption2).foregroundStyle(.secondary) }
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerArgumente.isEmpty {
                section("⚖️ Konkrete Argumente der Gegenseite", color: .gray) {
                    ForEach(a.gegnerArgumente) { g in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(g.argument).bold().font(.caption)
                                if let p = g.paragraphen {
                                    Text(p).font(.caption2).monospaced()
                                        .padding(.horizontal, 4)
                                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 3))
                                }
                                Spacer()
                                Text(g.staerke.uppercased()).font(.caption2).bold()
                                    .foregroundStyle(gefahrColor(g.staerke))
                            }
                            if let ant = g.unsereAntwort {
                                Text("Unsere Antwort: \(ant)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(8)
                        .background(gefahrColor(g.staerke).opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            if !a.gegnerVorgehen.isEmpty {
                section("🗂️ Vorgehensweise der Gegenseite", color: .gray) {
                    ForEach(Array(a.gegnerVorgehen.enumerated()), id: \.element.id) { (i, v) in
                        HStack(alignment: .top) {
                            Text("\(i+1)").bold().font(.caption2)
                                .padding(6)
                                .background(Circle().stroke(gefahrColor(v.risiko ?? "")))
                                .foregroundStyle(gefahrColor(v.risiko ?? ""))
                            VStack(alignment: .leading) {
                                Text(v.phase).bold().font(.caption)
                                Text(v.beschreibung).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let r = v.risiko { Text(r.uppercased()).font(.caption2).bold().foregroundStyle(gefahrColor(r)) }
                        }
                        .padding(8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, color: Color,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).bold().foregroundStyle(color)
            content()
        }
    }

    private func gefahrColor(_ g: String) -> Color {
        switch g.lowercased() {
        case "hoch": return .red
        case "mittel": return .orange
        case "niedrig": return .green
        default: return .gray
        }
    }

    // MARK: Datenoperationen

    private func avg(_ arr: [Double]) -> Double {
        guard !arr.isEmpty else { return 0 }
        return arr.reduce(0, +) / Double(arr.count)
    }

    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        async let a = cloudKit.fetch(Argument.self, predicate: pred)
        async let e = cloudKit.fetch(Evidence.self, predicate: pred)
        async let p = cloudKit.fetch(Person.self, predicate: pred)
        async let d = cloudKit.fetch(Deadline.self, predicate: pred)
        args = (try? await a) ?? []
        evidence = (try? await e) ?? []
        persons = (try? await p) ?? []
        deadlines = (try? await d) ?? []
        // Algorithmus berechnen
        let input = PrognoseInput(args: args, evidence: evidence,
                                  deadlines: deadlines, persons: persons,
                                  caseData: caseData)
        algoResult = LegalAlgorithms.computePrognose(input)
        breakEven = LegalAlgorithms.computeBreakEven(caseData: caseData)
        loaded = true
    }

    private func runKiAnalyse() async {
        analyzing = true; defer { analyzing = false }
        let eigArg = args.filter { $0.side == .eigen }.prefix(5).map {
            "\"\($0.title)\" Stärke:\(Int($0.kiStrength ?? $0.strength ?? 5))/10"
        }.joined(separator: ", ")
        let gegArg = args.filter { $0.side == .gegner }.prefix(5).map {
            "\"\($0.title)\" Stärke:\(Int($0.kiStrength ?? $0.strength ?? 5))/10"
        }.joined(separator: ", ")
        let evList = evidence.prefix(5).map {
            "\"\($0.title)\" Gewicht:\(Int($0.kiWeight ?? $0.weight ?? 5))/10"
        }.joined(separator: ", ")

        let prompt = """
        Du bist erfahrener Strafverteidiger. Analysiere diesen Fall tiefgehend.

        Fall: \(caseData?.fallname ?? "") | \(caseData?.rechtsgebiet ?? "") | Gericht: \(caseData?.gericht ?? "")
        Zentrale Frage: \(caseData?.zentraleRechtsfrage ?? "")
        Eigene Argumente: \(eigArg.isEmpty ? "keine" : eigArg)
        Gegnerargumente: \(gegArg.isEmpty ? "keine" : gegArg)
        Beweise: \(evList.isEmpty ? "keine" : evList)
        Notizen: \(caseData?.notes ?? "")

        Gib JSON mit: erfolgswahrscheinlichkeit, unsere_taktiken (3), gegner_strategien (3),
        gegner_asse (3), unsere_schwachstellen (3), gesamtstrategie,
        gegner_argumente (5 mit § und unserer Antwort), gegner_vorgehen (Schritte).
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "erfolgswahrscheinlichkeit": ["type": "integer", "minimum": 0, "maximum": 100],
                "erfolgswahrscheinlichkeit_begruendung": ["type": "string"],
                "unsere_taktiken": ["type": "array"],
                "gegner_strategien": ["type": "array"],
                "gegner_asse": ["type": "array"],
                "unsere_schwachstellen": ["type": "array"],
                "gesamtstrategie": ["type": "string"],
                "gegner_argumente": ["type": "array"],
                "gegner_vorgehen": ["type": "array"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            kiAnalyse = GesamtKIAnalyse(
                erfolgswahrscheinlichkeit: Int(caseData?.prognose ?? 50),
                begruendung: "KI-Analyse konnte nicht vollständig durchgeführt werden."
            )
            return
        }
        var k = GesamtKIAnalyse()
        k.erfolgswahrscheinlichkeit = (dict["erfolgswahrscheinlichkeit"] as? Int) ?? 50
        k.begruendung = dict["erfolgswahrscheinlichkeit_begruendung"] as? String
        k.gesamtstrategie = dict["gesamtstrategie"] as? String

        if let ut = dict["unsere_taktiken"] as? [[String: Any]] {
            k.unsereTaktiken = ut.map {
                TaktikItem(titel: $0["titel"] as? String ?? "",
                           beschreibung: $0["beschreibung"] as? String ?? "")
            }
        }
        if let gs = dict["gegner_strategien"] as? [[String: Any]] {
            k.gegnerStrategien = gs.map {
                GegnerItem(titel: $0["titel"] as? String ?? "",
                           beschreibung: $0["beschreibung"] as? String ?? "",
                           gefahr: $0["gefahr"] as? String ?? "mittel")
            }
        }
        if let asse = dict["gegner_asse"] as? [[String: Any]] {
            k.gegnerAsse = asse.map {
                TaktikItem(titel: $0["titel"] as? String ?? "",
                           beschreibung: $0["beschreibung"] as? String ?? "")
            }
        }
        if let sw = dict["unsere_schwachstellen"] as? [[String: Any]] {
            k.unsereSchwachstellen = sw.map {
                SchwachItem(titel: $0["titel"] as? String ?? "",
                            risiko: $0["risiko"] as? String)
            }
        }
        if let ga = dict["gegner_argumente"] as? [[String: Any]] {
            k.gegnerArgumente = ga.map {
                GegnerArg(argument: $0["argument"] as? String ?? "",
                          paragraphen: $0["paragraphen"] as? String,
                          staerke: $0["staerke"] as? String ?? "mittel",
                          unsereAntwort: $0["unsere_antwort"] as? String)
            }
        }
        if let gv = dict["gegner_vorgehen"] as? [[String: Any]] {
            k.gegnerVorgehen = gv.map {
                VorgehenStep(phase: $0["phase"] as? String ?? "",
                             beschreibung: $0["beschreibung"] as? String ?? "",
                             risiko: $0["risiko"] as? String)
            }
        }
        kiAnalyse = k
    }
}

// MARK: - Eine einzelne Berechnungsschritt-Zeile
fileprivate struct AlgoStepRow: View {
    let step: CalculationStep
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { open.toggle() } label: {
                HStack {
                    Text(step.label).font(.caption).bold()
                    Spacer()
                    Text(formattedWert).font(.caption2).monospaced().foregroundStyle(.purple)
                    Image(systemName: open ? "chevron.up" : "chevron.down").foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            if open {
                VStack(alignment: .leading, spacing: 6) {
                    GroupBox {
                        VStack(alignment: .leading) {
                            Text("FORMEL").font(.caption2).bold().foregroundStyle(.secondary)
                            Text(step.formel).font(.caption2).monospaced().foregroundStyle(.blue)
                        }
                    }
                    Text(step.erklaerung).font(.caption)
                    if let s = SIMPLE_EXPLANATIONS[step.label] {
                        Text(s).font(.caption2)
                            .padding(6).foregroundStyle(.blue)
                            .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(6)
        .background(.background, in: RoundedRectangle(cornerRadius: 6))
    }
    private var formattedWert: String {
        let prefix = step.wert > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.4f", step.wert)) \(step.einheit ?? "")"
    }
}

// MARK: - Views/Lexara/TabPrognoseVergleichView.swift

struct TabPrognoseVergleichView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var args: [Argument] = []
    @State private var evidence: [Evidence] = []
    @State private var deadlines: [Deadline] = []
    @State private var persons: [Person] = []
    @State private var gegnerVerhalten: [GegnerVerhalten] = []
    @State private var algoResult: VollanalyseResult? = nil
    @State private var loaded = false
    @State private var kiErklarung: KIErklarung? = nil
    @State private var kiLoading = false
    @State private var openDetail: Set<String> = []

    struct Prognose: Identifiable {
        let id: String
        let label: String
        let reiter: String
        let wert: Double
        let farbe: Color
        let methode: String
        let faktoren: [String]
        let beschreibung: String
    }

    struct KIErklarung: Codable {
        var abweichungs_erklaerung: String?
        var verlasslichste_prognose: String?
        var begruendung_verlasslich: String?
        var top_faktoren: [TopFaktor]?
        var verbesserungsmassnahmen: [Massnahme]?
        var gesamtbewertung: String?
    }
    struct TopFaktor: Codable, Identifiable {
        var id: String { faktor }
        var faktor: String
        var einfluss: String
        var richtung: String
    }
    struct Massnahme: Codable, Identifiable {
        var id: String { massnahme }
        var massnahme: String
        var erwartete_wirkung: String
        var prioritaet: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !loaded || algoResult == nil {
                    HStack { Spacer(); ProgressView("Lade und berechne alle Prognosen…"); Spacer() }.padding(40)
                } else {
                    headerCard
                    overviewCard
                    detailsList
                    if let r = kiErklarung { kiResultsView(r) }
                    else if !kiLoading { hintCard }
                }
            }.padding(20)
        }
        .task { await load() }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROGNOSE-VERGLEICH — ALLE MODELLE").font(.caption2).foregroundColor(.secondary)
            HStack {
                VStack(alignment: .leading) {
                    Text("\(prognosen.count) Prognosen").font(.title.weight(.bold))
                    Text("Spannweite: \(Int(minP))% – \(Int(maxP))% (Δ \(Int(spannweite))pp)").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button { Task { await runKiErklarung() } } label: {
                    Label(kiLoading ? "Analysiere…" : "KI erklärt die Unterschiede", systemImage: "sparkles")
                }.buttonStyle(.borderedProminent).disabled(kiLoading || prognosen.isEmpty)
            }
            if spannweite >= 15 {
                Text("⚠️ Hohe Abweichung (\(Int(spannweite))pp) — KI-Erklärung empfohlen").font(.caption).foregroundColor(.orange).padding(8).background(Color.orange.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.2)))
    }

    private var overviewCard: some View {
        GroupBox("Alle Prognosen auf einen Blick") {
            VStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(prognosen) { p in
                        PrognoseCircle(value: p.wert, label: p.label, color: p.farbe, size: 80)
                    }
                }
                Chart(prognosen) { p in
                    BarMark(x: .value("Modell", p.label), y: .value("Wert", p.wert))
                        .foregroundStyle(p.farbe)
                }.frame(height: 120)
            }.padding(8)
        }
    }

    private var detailsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Warum diese Prognose? — Einzelerklärungen").font(.subheadline.weight(.semibold))
            ForEach(prognosen) { p in
                DisclosureGroup(isExpanded: Binding(get: { openDetail.contains(p.id) }, set: { val in if val { openDetail.insert(p.id) } else { openDetail.remove(p.id) } })) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(p.beschreibung).font(.caption).foregroundColor(.secondary)
                        Text("Eingeflossene Faktoren").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                        ForEach(p.faktoren, id: \.self) { f in Text("• \(f)").font(.caption).foregroundColor(.secondary) }
                    }.padding(8)
                } label: {
                    HStack {
                        Text("\(Int(p.wert))").font(.headline.weight(.bold)).frame(width: 40, height: 40).background(p.farbe).foregroundColor(.white).clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(p.label).font(.subheadline.weight(.semibold))
                            Text("\(p.reiter) · \(p.methode)").font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        ProgressView(value: p.wert / 100).tint(p.farbe).frame(width: 100)
                    }
                }
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func kiResultsView(_ r: KIErklarung) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("KI-Analyse der Prognose-Unterschiede", systemImage: "sparkles").font(.subheadline.weight(.semibold))
            if let g = r.gesamtbewertung { GroupBox("Gesamtbewertung") { Text(g).font(.caption).padding(8) } }
            if let a = r.abweichungs_erklaerung { GroupBox("Warum weichen die Prognosen ab?") { Text(a).font(.caption).padding(8) } }
            if let v = r.verlasslichste_prognose {
                GroupBox("Verlässlichste Prognose") {
                    VStack(alignment: .leading) {
                        Text(v).font(.subheadline.weight(.semibold)).foregroundColor(.green)
                        if let b = r.begruendung_verlasslich { Text(b).font(.caption).foregroundColor(.secondary) }
                    }.padding(8)
                }
            }
            if let f = r.top_faktoren, !f.isEmpty {
                GroupBox("Die 3 stärksten Einfluss-Faktoren") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(f.prefix(3)) { factor in
                            let dirColor: Color = factor.richtung == "positiv" ? .green : factor.richtung == "negativ" ? .red : .gray
                            let icon = factor.richtung == "positiv" ? "arrow.up" : factor.richtung == "negativ" ? "arrow.down" : "arrow.right"
                            HStack {
                                Image(systemName: icon).foregroundColor(dirColor)
                                VStack(alignment: .leading) {
                                    Text(factor.faktor).font(.caption.weight(.bold))
                                    Text(factor.einfluss).font(.caption2).foregroundColor(.secondary)
                                }
                            }.padding(6).background(dirColor.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }.padding(8)
                }
            }
            if let m = r.verbesserungsmassnahmen, !m.isEmpty {
                GroupBox("Verbesserungsmaßnahmen") {
                    VStack(alignment: .leading) {
                        ForEach(m) { mas in
                            HStack(alignment: .top) {
                                Text(mas.prioritaet.uppercased()).font(.caption2.weight(.bold)).padding(.horizontal, 4).background((mas.prioritaet == "hoch" ? Color.red : mas.prioritaet == "mittel" ? Color.orange : Color.gray).opacity(0.2)).clipShape(Capsule())
                                VStack(alignment: .leading) {
                                    Text(mas.massnahme).font(.caption.weight(.semibold))
                                    Text(mas.erwartete_wirkung).font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }.padding(8)
                }
            }
        }
    }

    private var hintCard: some View {
        VStack {
            Image(systemName: "sparkles").font(.title)
            Text("Klicken Sie auf „KI erklärt die Unterschiede"").font(.caption).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(20).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed

    private var prognosen: [Prognose] {
        guard let algo = algoResult else { return [] }
        var list: [Prognose] = []
        list.append(Prognose(id: "manuell", label: "Manuelle Prognose", reiter: "Reiter 6 · Strategie",
                             wert: caseData?.prognose ?? Double(computeStrategiePrognose()),
                             farbe: .blue, methode: "Manuell oder 6-Stufen-Algorithmus",
                             faktoren: ["Argumente: \(args.filter{$0.side == .eigen}.count) eigen / \(args.filter{$0.side == .gegner}.count) Gegner",
                                        "Beweise: \(evidence.count) Stück",
                                        "Versäumte Fristen: \(deadlines.filter{$0.status == .versaeumt}.count)"],
                             beschreibung: "Der einfache 6-Stufen-Algorithmus berechnet eine Basisprognose."))
        list.append(Prognose(id: "prozessstaerke", label: "Prozessstärke-Score", reiter: "Reiter 6 · Strategie",
                             wert: Double(computeProzessStaerke()), farbe: .purple,
                             methode: "Gewichtete Faktoren-Matrix",
                             faktoren: ["Argumente-Balance (30%)", "Beweislage (20%)", "Fristen-Risiko (20%)", "Gegnerverhalten (15%)", "Richter-Profil (15%)"],
                             beschreibung: "Gewichtetes Mittel von 5 Dimensionen."))
        list.append(Prognose(id: "bayes", label: "Bayesianische Prognose", reiter: "Reiter 6 · Risikoformeln",
                             wert: Double(algo.prognose.score), farbe: .green,
                             methode: "Bayes-Modell mit Log-Odds + σ-Funktion",
                             faktoren: ["Konfidenz: [\(algo.prognose.ciLow)%, \(algo.prognose.ciHigh)%]",
                                        "Sigma: \(String(format: "%.1f", algo.prognose.sigma * 100))pp",
                                        "\(algo.prognose.steps.count) Berechnungsschritte"],
                             beschreibung: "Mathematisch robust durch Log-Odds-Akkumulation."))
        list.append(Prognose(id: "montecarlo", label: "Monte Carlo Median", reiter: "Reiter 6 · Risikoformeln",
                             wert: Double(algo.monteCarlo.median), farbe: .orange,
                             methode: "\(algo.monteCarlo.iterations) stochastische Simulationen",
                             faktoren: ["P10: \(algo.monteCarlo.p10)%", "P25: \(algo.monteCarlo.p25)%", "Median: \(algo.monteCarlo.median)%", "P75: \(algo.monteCarlo.p75)%", "P90: \(algo.monteCarlo.p90)%"],
                             beschreibung: "Robuste Schätzung durch tausende Szenarien."))
        return list
    }

    private var minP: Double { prognosen.map(\.wert).min() ?? 0 }
    private var maxP: Double { prognosen.map(\.wert).max() ?? 0 }
    private var spannweite: Double { maxP - minP }

    private func computeStrategiePrognose() -> Int {
        let eigene = args.filter { $0.side == .eigen }
        let gegner = args.filter { $0.side == .gegner }
        let eigenStaerke = eigene.compactMap(\.strength).reduce(0, +)
        let gegnerStaerke = gegner.compactMap(\.strength).reduce(0, +)
        let argBasis: Double = (eigene.isEmpty && gegner.isEmpty) ? 50 : max(0, ((eigenStaerke / Double(max(eigene.count, 1))) - (gegnerStaerke / Double(max(gegner.count, 1)))) * 5 + 50)
        let avgEvid = evidence.isEmpty ? 5 : evidence.compactMap(\.weight).reduce(0, +) / Double(evidence.count)
        let beweisBoost = 1 + (avgEvid / 10) * 0.5
        return min(99, max(1, Int(argBasis * beweisBoost)))
    }

    private func computeProzessStaerke() -> Int {
        let eArgs = args.filter { $0.side == .eigen }
        let gArgs = args.filter { $0.side == .gegner }
        let eS = eArgs.isEmpty ? 5 : eArgs.compactMap(\.strength).reduce(0, +) / Double(eArgs.count)
        let gS = gArgs.isEmpty ? 5 : gArgs.compactMap(\.strength).reduce(0, +) / Double(gArgs.count)
        let argScore = min(100, max(0, (eS - gS) * 5 + 50))
        let beweisScore = evidence.isEmpty ? 50 : min(100, evidence.compactMap(\.weight).reduce(0, +) / Double(evidence.count) * 10)
        let versaeumt = deadlines.filter { $0.status == .versaeumt }.count
        let fristenScore = max(0, 100 - versaeumt * 25)
        let gvSum = gegnerVerhalten.compactMap(\.auswirkungPrognose).reduce(0, +)
        let gegnerScore = min(100, max(0, 50 + Int(gvSum)))
        let richterScore = Int(caseData?.richterKlaegerRate ?? 50)
        return Int(argScore * 0.30 + beweisScore * 0.20 + Double(fristenScore) * 0.20 + Double(gegnerScore) * 0.15 + Double(richterScore) * 0.15)
    }

    // MARK: - Actions
    private func load() async {
        do {
            async let a = cloudKit.fetchForCase(Argument.self, caseId: caseId)
            async let e = cloudKit.fetchForCase(Evidence.self, caseId: caseId)
            async let d = cloudKit.fetchForCase(Deadline.self, caseId: caseId)
            async let p = cloudKit.fetchForCase(Person.self, caseId: caseId)
            async let g = cloudKit.fetchForCase(GegnerVerhalten.self, caseId: caseId)
            args = try await a; evidence = try await e; deadlines = try await d; persons = try await p; gegnerVerhalten = try await g
            loaded = true
            algoResult = LegalAlgorithms.computeVollanalyse(PrognoseInput(args: args, evidence: evidence, deadlines: deadlines, persons: persons, caseData: caseData))
        } catch { cloudKit.lastError = error.localizedDescription }
    }

    private func runKiErklarung() async {
        guard !prognosen.isEmpty else { return }
        kiLoading = true; defer { kiLoading = false }
        let prompt = """
        Du bist ein erfahrener Rechtsanwalt. Erkläre warum die Prognosen abweichen.
        FALL: \(caseData?.fallname ?? "?")
        \(prognosen.map { "• \($0.label): \(Int($0.wert))% — \($0.methode)" }.joined(separator: "\n"))
        Antworte als JSON: {abweichungs_erklaerung, verlasslichste_prognose, begruendung_verlasslich, top_faktoren: [{faktor, einfluss, richtung}], verbesserungsmassnahmen: [{massnahme, erwartete_wirkung, prioritaet}], gesamtbewertung}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "PrognoseVergleich", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String,
           let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(KIErklarung.self, from: data) {
            kiErklarung = result
        }
    }
}

private struct PrognoseCircle: View {
    let value: Double
    let label: String
    let color: Color
    let size: CGFloat
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.2), lineWidth: size * 0.06)
                Circle().trim(from: 0, to: value / 100).stroke(color, style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("\(Int(value))%").font(.system(size: size * 0.22, weight: .black))
            }.frame(width: size, height: size)
            Text(label).font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center).frame(maxWidth: 90)
        }
    }
}

// MARK: - Views/Lexara/TabVerhandlungssimulationView.swift

struct TabVerhandlungssimulationView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var kiProvider: KIProvider

    @State private var unsereStrategie: Strategie = .vergleich
    @State private var startangebot: String = ""
    @State private var maxAngebot: String = ""
    @State private var minAkzeptanz: String = ""
    @State private var gegnerProfil: String = "kooperativ"
    @State private var emotionalContext = ""
    @State private var loading = false
    @State private var simulation: Simulation?

    enum Strategie: String, CaseIterable, Identifiable {
        case vergleich, hart, kooperativ, kreativ
        var id: Self { self }
        var label: String {
            switch self {
            case .vergleich: return "Vergleich anstreben"
            case .hart: return "Hart verhandeln"
            case .kooperativ: return "Kooperativ"
            case .kreativ: return "Kreative Lösungen"
            }
        }
    }

    struct Simulation: Codable {
        var verlauf: [Verhandlungsschritt]?
        var ergebnis: String?
        var wahrscheinlichkeit_einigung: Double?
        var einigungsbetrag: Double?
        var risiken: [String]?
        var empfehlungen: [String]?
    }
    struct Verhandlungsschritt: Codable, Identifiable {
        var id: String { runde + akteur }
        var runde: String
        var akteur: String
        var aktion: String
        var begruendung: String?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputForm
                Button {
                    Task { await runSimulation() }
                } label: {
                    Label(loading ? "Simuliere…" : "Verhandlung simulieren", systemImage: "play.fill")
                }.buttonStyle(.borderedProminent).disabled(loading)
                if let s = simulation { resultView(s) }
            }.padding(20)
        }
    }

    private var inputForm: some View {
        Form {
            Section("Eigene Strategie") {
                Picker("Strategie", selection: $unsereStrategie) {
                    ForEach(Strategie.allCases) { Text($0.label).tag($0) }
                }
                TextField("Startangebot (€)", text: $startangebot).textFieldStyle(.roundedBorder)
                TextField("Maximales Angebot (€)", text: $maxAngebot).textFieldStyle(.roundedBorder)
                TextField("Minimale Akzeptanz (€)", text: $minAkzeptanz).textFieldStyle(.roundedBorder)
            }
            Section("Gegner") {
                Picker("Profil", selection: $gegnerProfil) {
                    ForEach(["kooperativ", "kompromisslos", "manipulativ", "rational", "emotional"], id: \.self) { Text($0).tag($0) }
                }
                TextField("Emotionaler Kontext", text: $emotionalContext, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(3)
            }
        }.formStyle(.grouped)
    }

    private func resultView(_ s: Simulation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let e = s.ergebnis {
                GroupBox("Ergebnis") {
                    Text(e).font(.subheadline).padding(8)
                }
            }
            if let p = s.wahrscheinlichkeit_einigung {
                GroupBox {
                    HStack {
                        VStack {
                            Text("\(Int(p * 100))%").font(.title.weight(.bold))
                            Text("Einigung").font(.caption2)
                        }
                        if let b = s.einigungsbetrag {
                            VStack {
                                Text("\(Int(b)) €").font(.title3.weight(.bold))
                                Text("Betrag").font(.caption2)
                            }
                        }
                    }
                }
            }
            if let v = s.verlauf, !v.isEmpty {
                GroupBox("Verlauf") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(v) { schritt in
                            HStack(alignment: .top) {
                                Text(schritt.runde).font(.caption2.weight(.bold)).foregroundColor(.blue).frame(width: 60, alignment: .leading)
                                VStack(alignment: .leading) {
                                    Text("\(schritt.akteur): \(schritt.aktion)").font(.caption)
                                    if let b = schritt.begruendung { Text(b).font(.caption2).foregroundColor(.secondary) }
                                }
                            }
                        }
                    }.padding(8)
                }
            }
            if let r = s.risiken, !r.isEmpty {
                GroupBox("Risiken") {
                    VStack(alignment: .leading) { ForEach(r, id: \.self) { Label($0, systemImage: "exclamationmark.triangle").font(.caption).foregroundColor(.orange) } }
                }
            }
            if let e = s.empfehlungen, !e.isEmpty {
                GroupBox("Empfehlungen") {
                    VStack(alignment: .leading) { ForEach(e, id: \.self) { Label($0, systemImage: "lightbulb").font(.caption).foregroundColor(.green) } }
                }
            }
        }
    }

    private func runSimulation() async {
        loading = true; defer { loading = false }
        let prompt = """
        Simuliere eine Verhandlung:
        Strategie: \(unsereStrategie.label), Start: \(startangebot)€, Max: \(maxAngebot)€, Min: \(minAkzeptanz)€
        Gegner: \(gegnerProfil), Kontext: \(emotionalContext)
        Antworte als JSON: {verlauf: [{runde, akteur, aktion, begruendung}], ergebnis, wahrscheinlichkeit_einigung, einigungsbetrag, risiken, empfehlungen}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Verhandlungssimulation", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String, let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(Simulation.self, from: data) {
            simulation = result
        }
    }
}

// MARK: - Views/Lexara/TabZeitstrahlView.swift

fileprivate struct ZeitstrahlKategorie: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color
}
fileprivate let ZEITSTRAHL_KATEGORIEN: [String: ZeitstrahlKategorie] = [
    "vertrag":       .init(id: "vertrag",       label: "Vertrag",       color: Color(red: 52/255,  green: 199/255, blue: 89/255)),
    "zahlung":       .init(id: "zahlung",       label: "Zahlung",       color: Color(red: 0,       green: 122/255, blue: 1)),
    "klage":         .init(id: "klage",         label: "Klage",         color: Color(red: 1,       green: 59/255,  blue: 48/255)),
    "urteil":        .init(id: "urteil",        label: "Urteil",        color: Color(red: 88/255,  green: 86/255,  blue: 214/255)),
    "frist":         .init(id: "frist",         label: "Frist",         color: Color(red: 1,       green: 149/255, blue: 0)),
    "verhandlung":   .init(id: "verhandlung",   label: "Verhandlung",   color: Color(red: 175/255, green: 82/255,  blue: 222/255)),
    "gutachten":     .init(id: "gutachten",     label: "Gutachten",     color: Color(red: 0,       green: 188/255, blue: 212/255)),
    "korrespondenz": .init(id: "korrespondenz", label: "Korrespondenz", color: Color(red: 139/255, green: 195/255, blue: 74/255)),
    "foto":          .init(id: "foto",          label: "Foto",          color: Color(red: 1,       green: 107/255, blue: 53/255)),
    "video":         .init(id: "video",         label: "Video",         color: Color(red: 192/255, green: 57/255,  blue: 43/255)),
    "sonstiges":     .init(id: "sonstiges",     label: "Sonstiges",     color: .gray),
]

fileprivate let ZEITSTRAHL_WICHTIGKEIT: [String: (label: String, color: Color)] = [
    "kritisch": ("Kritisch", Color(red: 1, green: 59/255, blue: 48/255)),
    "hoch":     ("Hoch",     Color(red: 1, green: 149/255, blue: 0)),
    "mittel":   ("Mittel",   Color(red: 0, green: 122/255, blue: 1)),
    "niedrig":  ("Niedrig",  .gray),
]

// MARK: - Hilfsstrukturen für das Documents-JSON

/// Eine Datei-Annotation (Foto/Video/PDF) innerhalb eines Ereignisses.
fileprivate struct ZeitstrahlDoc: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var title: String = ""
    var fileUrl: String?
    var fileType: String?
    var annotation: String?
    var kiAnalyse: String?
    var kiAnalysiert: Bool = false
    var kiSequenz: [VideoSequenz] = []
    var relationType: String?  // "beweist" | "widerlegt" | "überschneidet"
}
fileprivate struct VideoSequenz: Hashable, Codable {
    var zeitstempel: String?
    var beschreibung: String?
}
fileprivate struct VertragsPunkt: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var titel: String = ""
    var erledigt: Bool = false
    var faellig: String?
    var faelligUeberschritten: Bool = false
    var notiz: String?
}
/// Container, der zusätzlich zu den Pflichtfeldern in `documentsJSON` serialisiert wird.
fileprivate struct ZeitstrahlExtra: Codable {
    var docs: [ZeitstrahlDoc] = []
    var checklist: [VertragsPunkt] = []
    var relatedEventId: String?
    var relationType: String?
}

fileprivate enum MediaArt: String { case image, video, pdf, file }

fileprivate func mediaArt(url: String?, mime: String?) -> MediaArt {
    let lowMime = (mime ?? "").lowercased()
    if lowMime.hasPrefix("image/") { return .image }
    if lowMime.hasPrefix("video/") { return .video }
    if lowMime == "application/pdf" { return .pdf }
    let ext = (url ?? "").split(separator: ".").last.map(String.init)?
        .lowercased().split(separator: "?").first.map(String.init) ?? ""
    let img = ["jpg","jpeg","png","gif","webp","heic","bmp","tiff","svg"]
    let vid = ["mp4","mov","avi","mkv","webm","wmv","flv","m4v"]
    if img.contains(ext) { return .image }
    if vid.contains(ext) { return .video }
    if ext == "pdf" { return .pdf }
    return .file
}

// MARK: - Hauptansicht

struct TabZeitstrahlView: View {
    let caseId: String
    let caseData: Case?
    var kiMode: Bool = true

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var events: [TimelineEvent] = []
    @State private var loading = true
    @State private var generating = false
    @State private var showForm = false
    @State private var editEvent: TimelineEvent?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                legend
                if showForm {
                    EventFormView(
                        existing: editEvent,
                        caseId: caseId,
                        allEvents: events,
                        onSaved: {
                            showForm = false; editEvent = nil
                            Task { await load() }
                        },
                        onCancel: { showForm = false; editEvent = nil }
                    )
                }

                if loading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .padding(.vertical, 30)
                } else if events.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(events) { ev in
                            EventCardView(
                                event: ev,
                                allEvents: events,
                                onEdit: { editEvent = ev; showForm = true },
                                onDelete: { Task { await delete(ev.id) } },
                                onUpdateExtra: { newExtra in
                                    Task { await persistExtra(for: ev, extra: newExtra) }
                                }
                            )
                        }
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Zeitstrahl")
        .task { await load() }
    }

    // MARK: Sub-Views

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fallzeitstrahl").font(.headline)
                Text("Dokumente, Fotos, Videos – chronologisch mit KI-Analyse & Beweisverknüpfung")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if kiMode {
                Button {
                    Task { await generateFromDocuments() }
                } label: {
                    Label(generating ? "Generiere…" : "Aus Dokumenten generieren",
                          systemImage: "sparkles")
                }
                .disabled(generating)
            }
            Button {
                editEvent = nil
                showForm = true
            } label: {
                Label("Ereignis", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            Label("bestätigt", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            Label("widerlegt", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Label("überschneidet", systemImage: "link").foregroundStyle(.orange)
            Label("Foto", systemImage: "photo").foregroundStyle(.orange)
            Label("Video (KI-Sequenz)", systemImage: "video").foregroundStyle(.red)
            Spacer()
        }
        .font(.caption2)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Noch keine Ereignisse erfasst",
            systemImage: "calendar",
            description: Text("Fügen Sie Ereignisse manuell hinzu oder lassen Sie sie aus Dokumenten generieren.")
        )
    }

    // MARK: - Datenoperationen

    private func load() async {
        loading = true
        let pred = NSPredicate(format: "case_id == %@", caseId)
        let list = (try? await cloudKit.fetch(TimelineEvent.self, predicate: pred)) ?? []
        events = list.sorted { $0.date < $1.date }
        loading = false
    }

    private func delete(_ id: String) async {
        try? await cloudKit.delete(recordID: id)
        await load()
    }

    /// Persistiert Foto-/Video-Annotationen sowie Checklisten in `documentsJSON`.
    private func persistExtra(for event: TimelineEvent, extra: ZeitstrahlExtra) async {
        var copy = event
        if let data = try? JSONEncoder().encode(extra),
           let str = String(data: data, encoding: .utf8) {
            copy.documentsJSON = str
        }
        _ = try? await cloudKit.save(copy)
        await load()
    }

    // MARK: - KI: Erzeuge Ereignisse aus Dokumenten
    private func generateFromDocuments() async {
        generating = true; defer { generating = false }
        let pred = NSPredicate(format: "case_id == %@", caseId)
        let docs = (try? await cloudKit.fetch(LegalDocument.self, predicate: pred)) ?? []
        guard !docs.isEmpty else { return }

        let docList = docs.map {
            "- \($0.title): \($0.aiSummary ?? $0.docDescription ?? "keine Zusammenfassung")"
        }.joined(separator: "\n")

        let prompt = """
        Analysiere die folgenden Falldokumente und extrahiere alle relevanten Ereignisse für einen Zeitstrahl.

        Fall: \(caseData?.fallname ?? "")
        Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")

        Dokumente:
        \(docList)

        Erkenne auch Vertragsvereinbarungen mit Fristen und ob sie eingehalten wurden (vertrag_checkliste).
        Markiere Widersprüche zwischen Dokumenten mit relation_type "widerlegt".
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "ereignisse": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "date":             ["type": "string"],
                            "title":            ["type": "string"],
                            "description":     ["type": "string"],
                            "category":         ["type": "string"],
                            "importance":       ["type": "string"],
                            "persons_involved": ["type": "array", "items": ["type": "string"]],
                            "vertrag_checkliste": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "properties": [
                                        "titel":   ["type": "string"],
                                        "faellig": ["type": "string"],
                                        "erledigt": ["type": "boolean"],
                                        "faelligUeberschritten": ["type": "boolean"],
                                        "notiz":   ["type": "string"]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res,
              let dict = any as? [String: Any],
              let liste = dict["ereignisse"] as? [[String: Any]] else { return }

        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        for ev in liste {
            let date = (ev["date"] as? String).flatMap { f.date(from: $0) } ?? Date()
            var event = TimelineEvent(caseId: caseId, date: date,
                                      title: ev["title"] as? String ?? "Unbenannt")
            event.eventDescription = ev["description"] as? String
            event.category = TimelineCategory(rawValue: ev["category"] as? String ?? "sonstiges") ?? .sonstiges
            event.importance = TimelineImportance(rawValue: ev["importance"] as? String ?? "mittel") ?? .mittel
            event.personsInvolved = ev["persons_involved"] as? [String] ?? []
            event.kiGenerated = true

            // Vertrags-Checkliste in `documentsJSON` ablegen.
            var extra = ZeitstrahlExtra()
            if let cl = ev["vertrag_checkliste"] as? [[String: Any]] {
                extra.checklist = cl.map {
                    VertragsPunkt(
                        titel: $0["titel"] as? String ?? "",
                        erledigt: $0["erledigt"] as? Bool ?? false,
                        faellig: $0["faellig"] as? String,
                        faelligUeberschritten: $0["faelligUeberschritten"] as? Bool ?? false,
                        notiz: $0["notiz"] as? String
                    )
                }
            }
            if let data = try? JSONEncoder().encode(extra),
               let str = String(data: data, encoding: .utf8) {
                event.documentsJSON = str
            }
            _ = try? await cloudKit.save(event)
        }
        await load()
    }
}

// MARK: - Event-Karte
fileprivate struct EventCardView: View {
    let event: TimelineEvent
    let allEvents: [TimelineEvent]
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onUpdateExtra: (ZeitstrahlExtra) -> Void

    @State private var expanded = false

    private var extra: ZeitstrahlExtra {
        guard let s = event.documentsJSON,
              let d = s.data(using: .utf8),
              let p = try? JSONDecoder().decode(ZeitstrahlExtra.self, from: d) else {
            return ZeitstrahlExtra()
        }
        return p
    }

    private var kategorie: ZeitstrahlKategorie {
        ZEITSTRAHL_KATEGORIEN[event.category.rawValue] ?? ZEITSTRAHL_KATEGORIEN["sonstiges"]!
    }
    private var wichtigkeit: (label: String, color: Color) {
        ZEITSTRAHL_WICHTIGKEIT[event.importance.rawValue] ?? ZEITSTRAHL_WICHTIGKEIT["mittel"]!
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(kategorie.color).frame(width: 10, height: 10).padding(.top, 6)
            VStack(alignment: .leading, spacing: 6) {
                header
                if !expanded, let desc = event.eventDescription {
                    Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                if expanded { details }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(kategorie.color.opacity(0.3)))
            .onTapGesture { expanded.toggle() }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.date, format: .dateTime.day().month().year())
                        .font(.caption2).monospaced().foregroundStyle(.secondary)
                    Text(kategorie.label)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(kategorie.color.opacity(0.18), in: Capsule())
                        .foregroundStyle(kategorie.color)
                    Text(wichtigkeit.label)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(wichtigkeit.color.opacity(0.18), in: Capsule())
                        .foregroundStyle(wichtigkeit.color)
                    if event.kiGenerated {
                        Text("KI").font(.caption2).bold()
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.purple.opacity(0.15), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                }
                Text(event.title).font(.callout).bold()
            }
            Spacer()
            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .foregroundStyle(.secondary)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let desc = event.eventDescription {
                VStack(alignment: .leading) {
                    Text("Beschreibung").font(.caption2).bold().foregroundStyle(.secondary)
                    Text(desc).font(.caption)
                }
            }
            if !event.personsInvolved.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beteiligte").font(.caption2).bold().foregroundStyle(.secondary)
                    HStack {
                        ForEach(event.personsInvolved, id: \.self) { p in
                            Text(p).font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            if !extra.checklist.isEmpty {
                ContractChecklistView(items: extra.checklist) { newItems in
                    var e = extra; e.checklist = newItems
                    onUpdateExtra(e)
                }
            }
            if !extra.docs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dateien & Beweise").font(.caption2).bold().foregroundStyle(.secondary)
                    ForEach(Array(extra.docs.enumerated()), id: \.element.id) { idx, doc in
                        FileAnnotationView(doc: doc) { newDoc in
                            var copy = extra; copy.docs[idx] = newDoc
                            onUpdateExtra(copy)
                        }
                    }
                }
            }
            HStack {
                Button { onEdit() } label: { Label("Bearbeiten", systemImage: "pencil") }
                Button(role: .destructive) { onDelete() } label: { Label("Löschen", systemImage: "trash") }
            }
            .font(.caption)
        }
    }
}

// MARK: - Vertragschecklist
fileprivate struct ContractChecklistView: View {
    let items: [VertragsPunkt]
    var onChange: ([VertragsPunkt]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vertragspunkte / Erfüllung").font(.caption2).bold().foregroundStyle(.secondary)
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                HStack(alignment: .top) {
                    Button {
                        var copy = items
                        copy[idx].erledigt.toggle()
                        onChange(copy)
                    } label: {
                        Image(systemName: item.erledigt ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.erledigt ? .green : .gray)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.titel)
                            .font(.caption)
                            .strikethrough(item.erledigt)
                            .foregroundStyle(item.faelligUeberschritten && !item.erledigt ? .red : .primary)
                        if let f = item.faellig, !f.isEmpty {
                            Label("Fällig: \(f)", systemImage: "clock")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        if item.faelligUeberschritten && !item.erledigt {
                            Text("⚠ Nicht eingehalten!").font(.caption2).bold().foregroundStyle(.red)
                        }
                        if let n = item.notiz, !n.isEmpty {
                            Text(n).font(.caption2).italic().foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Datei-Annotation
fileprivate struct FileAnnotationView: View {
    var doc: ZeitstrahlDoc
    var onUpdate: (ZeitstrahlDoc) -> Void

    @State private var editing = false
    @State private var annotation = ""

    private var symbol: String {
        switch mediaArt(url: doc.fileUrl, mime: doc.fileType) {
        case .image: return "photo"
        case .video: return "video"
        case .pdf:   return "doc.richtext"
        case .file:  return "doc"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbol).foregroundStyle(.secondary)
                if let url = doc.fileUrl, let u = URL(string: url) {
                    Link(doc.title, destination: u).font(.caption)
                } else {
                    Text(doc.title).font(.caption)
                }
                if doc.kiAnalysiert {
                    Text("KI ✓").font(.caption2).bold()
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.purple.opacity(0.15), in: Capsule())
                        .foregroundStyle(.purple)
                }
                if let r = doc.relationType {
                    relationBadge(r)
                }
                Spacer()
            }
            if let ka = doc.kiAnalyse {
                Text(ka).font(.caption2)
                    .padding(6)
                    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            if !doc.kiSequenz.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Video-Ablauf (KI)").font(.caption2).bold().foregroundStyle(.secondary)
                    ForEach(Array(doc.kiSequenz.enumerated()), id: \.offset) { _, seq in
                        HStack(alignment: .top) {
                            Text(seq.zeitstempel ?? "–").font(.caption2).monospaced()
                                .foregroundStyle(.red)
                            Text(seq.beschreibung ?? "").font(.caption2)
                        }
                    }
                }
            }
            if editing {
                TextField("Was beweist diese Datei?", text: $annotation, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Speichern") {
                        var d = doc; d.annotation = annotation
                        onUpdate(d); editing = false
                    }.buttonStyle(.borderedProminent).controlSize(.small)
                    Button("Abbrechen") { editing = false }.controlSize(.small)
                }
            } else {
                HStack {
                    if let a = doc.annotation, !a.isEmpty {
                        Text("💬 \(a)").font(.caption2).italic().foregroundStyle(.secondary)
                    } else {
                        Text("Keine Annotation").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        annotation = doc.annotation ?? ""
                        editing = true
                    } label: { Image(systemName: "pencil").font(.caption2) }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(6)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private func relationBadge(_ type: String) -> some View {
        let (label, color, sym): (String, Color, String) = {
            switch type {
            case "beweist":      return ("bestätigt", .green, "checkmark.circle")
            case "widerlegt":    return ("widerlegt", .red,   "exclamationmark.triangle")
            case "überschneidet":return ("überschneidet", .orange, "link")
            default:             return (type, .gray, "questionmark")
            }
        }()
        return Label(label, systemImage: sym)
            .font(.caption2)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - Ereignis-Formular
fileprivate struct EventFormView: View {
    let existing: TimelineEvent?
    let caseId: String
    let allEvents: [TimelineEvent]
    var onSaved: () -> Void
    var onCancel: () -> Void

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var date = Date()
    @State private var title = ""
    @State private var description = ""
    @State private var category: TimelineCategory = .sonstiges
    @State private var importance: TimelineImportance = .mittel
    @State private var persons: [String] = []
    @State private var personInput = ""
    @State private var checklist: [VertragsPunkt] = []
    @State private var newCheckItem = ""
    @State private var docs: [ZeitstrahlDoc] = []
    @State private var newDocTitle = ""
    @State private var newDocUrl = ""
    @State private var relatedEventId: String?
    @State private var relationType: String?

    var body: some View {
        GroupBox(existing == nil ? "Neues Ereignis" : "Ereignis bearbeiten") {
            Form {
                Section {
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                    TextField("Titel *", text: $title)
                    TextField("Beschreibung", text: $description, axis: .vertical).lineLimit(2...5)
                    Picker("Kategorie", selection: $category) {
                        ForEach(TimelineCategory.allCases, id: \.self) { c in
                            Text((ZEITSTRAHL_KATEGORIEN[c.rawValue]?.label) ?? c.rawValue).tag(c)
                        }
                    }
                    Picker("Wichtigkeit", selection: $importance) {
                        ForEach(TimelineImportance.allCases, id: \.self) { i in
                            Text((ZEITSTRAHL_WICHTIGKEIT[i.rawValue]?.label) ?? i.rawValue).tag(i)
                        }
                    }
                }
                Section("Beteiligte Personen") {
                    HStack {
                        TextField("Name hinzufügen", text: $personInput)
                        Button("+") {
                            let t = personInput.trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty { persons.append(t); personInput = "" }
                        }
                    }
                    if !persons.isEmpty {
                        WrappingHStack(items: persons) { p, idx in
                            HStack(spacing: 4) {
                                Text(p).font(.caption)
                                Button { persons.remove(at: idx) } label: { Image(systemName: "xmark.circle.fill") }
                                    .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15), in: Capsule())
                        }
                    }
                }
                Section("Dateien / Fotos / Videos") {
                    HStack {
                        TextField("Titel", text: $newDocTitle)
                        TextField("URL (optional)", text: $newDocUrl)
                        Button("+") {
                            let t = newDocTitle.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            docs.append(ZeitstrahlDoc(title: t, fileUrl: newDocUrl.isEmpty ? nil : newDocUrl))
                            newDocTitle = ""; newDocUrl = ""
                        }
                    }
                    ForEach(Array(docs.enumerated()), id: \.element.id) { idx, doc in
                        HStack {
                            Text(doc.title).font(.caption)
                            Spacer()
                            Picker("Relation", selection: Binding(
                                get: { docs[idx].relationType ?? "" },
                                set: { docs[idx].relationType = $0.isEmpty ? nil : $0 })
                            ) {
                                Text("Keine").tag("")
                                Text("beweist").tag("beweist")
                                Text("widerlegt").tag("widerlegt")
                                Text("überschneidet").tag("überschneidet")
                            }
                            .labelsHidden()
                            Button { docs.remove(at: idx) } label: { Image(systemName: "trash") }
                                .buttonStyle(.plain)
                        }
                    }
                    if !docs.isEmpty {
                        Button {
                            Task { await analyseMediaWithKI() }
                        } label: { Label("Fotos & Videos mit KI analysieren", systemImage: "sparkles") }
                    }
                }
                if !allEvents.isEmpty {
                    Section("Verknüpfung mit anderem Ereignis") {
                        Picker("Verknüpft mit", selection: Binding(
                            get: { relatedEventId ?? "" },
                            set: { relatedEventId = $0.isEmpty ? nil : $0 })
                        ) {
                            Text("Keine").tag("")
                            ForEach(allEvents.filter { $0.id != existing?.id }) { e in
                                Text(e.title).tag(e.id)
                            }
                        }
                        Picker("Beziehungstyp", selection: Binding(
                            get: { relationType ?? "" },
                            set: { relationType = $0.isEmpty ? nil : $0 })
                        ) {
                            Text("Typ wählen").tag("")
                            Text("bestätigt/beweist").tag("beweist")
                            Text("widerlegt").tag("widerlegt")
                            Text("überschneidet sich").tag("überschneidet")
                        }
                    }
                }
                if category == .vertrag || !checklist.isEmpty {
                    Section("Vertragspunkte / Erfüllungsliste") {
                        ForEach(Array(checklist.enumerated()), id: \.element.id) { idx, item in
                            VStack(alignment: .leading) {
                                HStack {
                                    Toggle("", isOn: Binding(
                                        get: { checklist[idx].erledigt },
                                        set: { checklist[idx].erledigt = $0 }
                                    )).labelsHidden()
                                    TextField("Punkt", text: Binding(
                                        get: { checklist[idx].titel },
                                        set: { checklist[idx].titel = $0 }
                                    ))
                                    Button { checklist.remove(at: idx) } label: { Image(systemName: "xmark") }
                                        .buttonStyle(.plain)
                                }
                                HStack {
                                    TextField("Fällig (YYYY-MM-DD)", text: Binding(
                                        get: { checklist[idx].faellig ?? "" },
                                        set: { checklist[idx].faellig = $0.isEmpty ? nil : $0 }
                                    ))
                                    TextField("Notiz", text: Binding(
                                        get: { checklist[idx].notiz ?? "" },
                                        set: { checklist[idx].notiz = $0.isEmpty ? nil : $0 }
                                    ))
                                }
                            }
                        }
                        HStack {
                            TextField("Neuer Punkt (z.B. Lieferung bis 15.01.)", text: $newCheckItem)
                            Button("+ Punkt") {
                                let t = newCheckItem.trimmingCharacters(in: .whitespaces)
                                guard !t.isEmpty else { return }
                                checklist.append(VertragsPunkt(titel: t)); newCheckItem = ""
                            }
                        }
                    }
                }
            }
            HStack {
                Spacer()
                Button("Abbrechen", action: onCancel)
                Button(existing == nil ? "Ereignis erstellen" : "Speichern") { Task { await save() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 4)
        }
        .onAppear { if let ex = existing { populate(from: ex) } }
    }

    private func populate(from ex: TimelineEvent) {
        date = ex.date; title = ex.title
        description = ex.eventDescription ?? ""
        category = ex.category; importance = ex.importance
        persons = ex.personsInvolved
        if let s = ex.documentsJSON, let d = s.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(ZeitstrahlExtra.self, from: d) {
            checklist = parsed.checklist
            docs = parsed.docs
            relatedEventId = parsed.relatedEventId
            relationType = parsed.relationType
        }
    }

    /// KI-gestützte Analyse aller Bilder und Videos – setzt `kiAnalyse` & `kiSequenz`.
    private func analyseMediaWithKI() async {
        var updated = docs
        for (i, doc) in docs.enumerated() {
            let art = mediaArt(url: doc.fileUrl, mime: doc.fileType)
            if art == .image {
                let prompt = """
                Analysiere dieses Foto für eine rechtliche Fallakte (\(doc.fileUrl ?? "")):
                Was ist zu sehen, welche Personen, Datum/Ort, juristischer Beweiswert?
                """
                let res = await kiProvider.invokeLLM(prompt: prompt, schema: nil, caseId: caseId)
                if case .success(let any) = res {
                    updated[i].kiAnalyse = (any as? String) ?? ""
                    updated[i].kiAnalysiert = true
                }
            } else if art == .video {
                let prompt = """
                Analysiere dieses Video (\(doc.fileUrl ?? "")):
                Erstelle eine zeitliche Sequenz (zeitstempel/beschreibung) und beurteile den Beweiswert.
                """
                let schema: [String: Any] = [
                    "type": "object",
                    "properties": [
                        "zusammenfassung": ["type": "string"],
                        "sequenz": [
                            "type": "array",
                            "items": ["type": "object", "properties": [
                                "zeitstempel": ["type": "string"],
                                "beschreibung": ["type": "string"]
                            ]]
                        ],
                        "beweiswert": ["type": "string"]
                    ]
                ]
                let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
                if case .success(let any) = res, let dict = any as? [String: Any] {
                    let zs = (dict["zusammenfassung"] as? String) ?? ""
                    let bw = (dict["beweiswert"] as? String) ?? ""
                    updated[i].kiAnalyse = zs + (bw.isEmpty ? "" : "\n\nBeweiswert: \(bw)")
                    if let arr = dict["sequenz"] as? [[String: Any]] {
                        updated[i].kiSequenz = arr.map {
                            VideoSequenz(zeitstempel: $0["zeitstempel"] as? String,
                                         beschreibung: $0["beschreibung"] as? String)
                        }
                    }
                    updated[i].kiAnalysiert = true
                }
            }
        }
        docs = updated
    }

    private func save() async {
        var ev = existing ?? TimelineEvent(caseId: caseId, date: date, title: title)
        ev.date = date
        ev.title = title
        ev.eventDescription = description.isEmpty ? nil : description
        ev.category = category
        ev.importance = importance
        ev.personsInvolved = persons
        var extra = ZeitstrahlExtra()
        extra.checklist = checklist
        extra.docs = docs
        extra.relatedEventId = relatedEventId
        extra.relationType = relationType
        if let data = try? JSONEncoder().encode(extra),
           let s = String(data: data, encoding: .utf8) {
            ev.documentsJSON = s
        }
        _ = try? await cloudKit.save(ev)
        onSaved()
    }
}

// MARK: - Hilfs-Layout für umbrechende Tag-Rows
fileprivate struct WrappingHStack<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item, Int) -> Content
    init(items: [Item], @ViewBuilder content: @escaping (Item, Int) -> Content) {
        self.items = items; self.content = content
    }
    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                content(item, idx)
            }
        }
    }
}

/// Einfaches Flow-Layout (macOS 14+)
fileprivate struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 300
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxW { x = 0; y += lineH + spacing; lineH = 0 }
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
        return CGSize(width: maxW, height: y + lineH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, lineH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.minX + maxW { x = bounds.minX; y += lineH + spacing; lineH = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}

// MARK: - Views/Lexara/WasWaereWennSimulationView.swift

fileprivate struct VerhandlungsDossier: Hashable {
    var openingStatement: String?
    var staerksteArgumente: [DossierArg] = []
    var gegnerSchwachstellen: [DossierGS] = []
    var verhandlungsziele: [DossierZiel] = []
    var roteLinien: [String] = []
}
fileprivate struct DossierArg: Identifiable, Hashable {
    let id = UUID(); var argument: String; var einsatz: String?; var formulierung: String?
}
fileprivate struct DossierGS: Identifiable, Hashable {
    let id = UUID(); var schwachstelle: String; var angriffspunkt: String?
}
fileprivate struct DossierZiel: Identifiable, Hashable {
    let id = UUID(); var ziel: String; var prioritaet: String?; var taktik: String?
}

fileprivate struct MotivAnalyse: Hashable {
    var timingAnalyse: String?
    var fristenHintergedanken: String?
    var verdeckteZiele: [String] = []
    var psychologischeTaktiken: [MotivTaktik] = []
    var naechsterSchrittGegner: String?
    var empfohleneReaktion: String?
    var roteFlaggen: [String] = []
}
fileprivate struct MotivTaktik: Identifiable, Hashable {
    let id = UUID(); var taktik: String; var beweis: String?; var intensitaet: String
}

// MARK: - Hauptansicht

struct WasWaereWennSimulationView: View {
    let args: [Argument]
    let evidence: [Evidence]
    let deadlines: [Deadline]
    let persons: [Person]
    let caseData: Case?
    let basePrognose: Int

    @EnvironmentObject var kiProvider: KIProvider

    @State private var hiddenIds: Set<String> = []
    @State private var exportLoading = false
    @State private var dossierLoading = false
    @State private var dossier: VerhandlungsDossier?
    @State private var motives: MotivAnalyse?
    @State private var loadingMotives = false
    @State private var motiveError: String?
    @State private var expandedSection: String? = "args_e"
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                if let d = dossier { dossierCard(d) }
                toggleLists
                motiveCard
            }
            .padding()
        }
        .navigationTitle("Was-wäre-wenn-Simulation")
        .alert("Hinweis",
               isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: { Text(alertMessage ?? "") }
    }

    // MARK: - Berechnung

    /// Lokale Prognose (1:1 zur React-Funktion `computePrognose`).
    private func computeSimPrognose(hidden: Set<String>) -> Int {
        let activeArgs = args.filter { !hidden.contains($0.id) }
        let activeEv = evidence.filter { !hidden.contains($0.id) }
        let activeDl = deadlines.filter { !hidden.contains($0.id) }

        let eigene = activeArgs.filter { $0.side == .eigen }
        let gegner = activeArgs.filter { $0.side == .gegner }
        let eigenStaerke = eigene.reduce(0.0) { $0 + ($1.strength ?? 5) }
        let gegnerStaerke = gegner.reduce(0.0) { $0 + ($1.strength ?? 5) }
        let argBasis: Double = (eigene.count > 0 || gegner.count > 0)
            ? max(0, ((eigenStaerke / Double(max(1, eigene.count))) -
                      (gegnerStaerke / Double(max(1, gegner.count)))) * 5 + 50)
            : 50
        let avgEvidW: Double = activeEv.isEmpty ? 5 :
            activeEv.reduce(0.0) { $0 + ($1.weight ?? 5) } / Double(activeEv.count)
        let beweisBoost = 1 + (avgEvidW / 10) * 0.5
        let contradictions = activeArgs.filter { $0.isContradiction }.count
        let kantenEffekt = max(0.2, 1 - Double(contradictions) * 0.2)
        let judges = persons.filter { $0.role == .richter }
        let avgGlaubw: Double = judges.isEmpty ? 80 :
            judges.reduce(0.0) { $0 + ($1.glaubwuerdigkeit ?? 80) } / Double(judges.count)
        let zeugenMult = 0.70 + (avgGlaubw / 100) * 0.30
        let richterRate = judges.first?.klaegerRate ?? caseData?.richterKlaegerRate ?? 50
        let richterAdj = 1 + (richterRate - 50) / 100 * 0.15
        let versaeumt = activeDl.filter { $0.status == .versaeumt }.count
        let fristenFaktor = max(0.5, 1 - Double(versaeumt) * 0.30)
        let raw = argBasis * beweisBoost * kantenEffekt * zeugenMult * richterAdj * fristenFaktor
        return min(99, max(1, Int(raw.rounded())))
    }

    private var baseSim: Int { computeSimPrognose(hidden: []) }
    private var simNow: Int { computeSimPrognose(hidden: hiddenIds) }
    private var delta: Int { simNow - baseSim }

    private var eigenArgs: [Argument] { args.filter { $0.side == .eigen } }
    private var gegnerArgs: [Argument] { args.filter { $0.side == .gegner } }

    // MARK: - Sub-Views

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("🔮 Was-wäre-wenn-Simulation").bold()
                    Text("Blende Elemente aus, um ihre Auswirkung zu messen.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { hiddenIds.removeAll() } label: {
                    Label("Zurücksetzen", systemImage: "arrow.counterclockwise")
                }
                Button {
                    Task { await generateDossier() }
                } label: {
                    Label(dossierLoading ? "Erstelle…" : "Verhandlungs-Dossier", systemImage: "book")
                }
                .disabled(dossierLoading)
                Button {
                    Task { await exportProzessnotiz() }
                } label: {
                    Label(exportLoading ? "Erstelle…" : "Prozessnotiz exportieren", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(exportLoading)
            }
            HStack(spacing: 24) {
                prognoseBar("Basis (alle aktiv)", value: baseSim, delta: nil)
                prognoseBar("Simuliert", value: simNow, delta: delta)
            }
            if hiddenIds.count > 0 {
                Label(deltaInfoText, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(deltaColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(deltaColor)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var deltaColor: Color {
        delta > 0 ? .green : (delta < 0 ? .red : .gray)
    }
    private var deltaInfoText: String {
        let n = hiddenIds.count
        if delta > 0 { return "\(n) ausgeblendet → Prognose steigt um \(delta)% wenn wir diese Elemente gewinnen" }
        if delta < 0 { return "\(n) ausgeblendet → Prognose sinkt um \(abs(delta))% ohne diese Elemente" }
        return "\(n) ausgeblendet → Kein Einfluss"
    }

    private func prognoseBar(_ label: String, value: Int, delta: Int?) -> some View {
        let color: Color = value >= 60 ? .green : (value >= 40 ? .orange : .red)
        return VStack(alignment: .leading) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(value)%").bold()
                if let d = delta, d != 0 {
                    Text("\(d > 0 ? "+" : "")\(d)%").font(.caption).bold()
                        .foregroundStyle(d > 0 ? .green : .red)
                }
            }
            ProgressView(value: Double(value), total: 100).tint(color)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func dossierCard(_ d: VerhandlungsDossier) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Verhandlungs-Dossier", systemImage: "book.closed.fill").bold()
                    Spacer()
                    Button("✕") { dossier = nil }.buttonStyle(.plain)
                }
                if let s = d.openingStatement {
                    VStack(alignment: .leading) {
                        Text("📢 ERÖFFNUNGSSTATEMENT").font(.caption).bold().foregroundStyle(.blue)
                        Text("„\(s)"")
                            .font(.subheadline).italic()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                if !d.staerksteArgumente.isEmpty {
                    Text("💪 STÄRKSTE EIGENE ARGUMENTE").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(d.staerksteArgumente) { a in
                        VStack(alignment: .leading) {
                            Text(a.argument).bold().font(.caption)
                            if let e = a.einsatz { Text("Einsatz: \(e)").font(.caption2).foregroundStyle(.secondary) }
                            if let f = a.formulierung { Text("„\(f)"").font(.caption2).italic() }
                        }
                        .padding(8).background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !d.gegnerSchwachstellen.isEmpty {
                    Text("⚔️ GEGNERISCHE SCHWACHSTELLEN").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(d.gegnerSchwachstellen) { s in
                        VStack(alignment: .leading) {
                            Text(s.schwachstelle).bold().font(.caption)
                            if let a = s.angriffspunkt { Text("→ \(a)").font(.caption2) }
                        }
                        .padding(8).background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !d.verhandlungsziele.isEmpty {
                    Text("🎯 DIE 3 WICHTIGSTEN VERHANDLUNGSZIELE").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(Array(d.verhandlungsziele.prefix(3).enumerated()), id: \.element.id) { (i, z) in
                        HStack(alignment: .top) {
                            Text("\(i+1)").bold().font(.caption2)
                                .padding(6).background(Circle().fill(.black)).foregroundStyle(.white)
                            VStack(alignment: .leading) {
                                Text(z.ziel).bold().font(.caption)
                                if let p = z.prioritaet {
                                    Text(p).font(.caption2).bold().foregroundStyle(p == "hoch" ? .red : .orange)
                                }
                                if let t = z.taktik { Text(t).font(.caption2).foregroundStyle(.secondary) }
                            }
                            Spacer()
                        }
                    }
                }
                if !d.roteLinien.isEmpty {
                    VStack(alignment: .leading) {
                        Text("🛑 ROTE LINIEN").font(.caption).bold().foregroundStyle(.red)
                        ForEach(d.roteLinien, id: \.self) { Text("• \($0)").font(.caption) }
                    }
                    .padding()
                    .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private var toggleLists: some View {
        GroupBox {
            VStack(spacing: 6) {
                section(id: "args_e", label: "✅ Eigene Argumente (\(eigenArgs.count))") {
                    if eigenArgs.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(eigenArgs) { a in
                        toggleRow(id: a.id, title: a.title,
                                  badge: "\(Int(a.strength ?? 5))/10", color: .green)
                    }
                }
                section(id: "args_g", label: "⚔️ Gegner-Argumente (\(gegnerArgs.count))") {
                    if gegnerArgs.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(gegnerArgs) { a in
                        toggleRow(id: a.id, title: a.title,
                                  badge: "\(Int(a.strength ?? 5))/10", color: .red)
                    }
                }
                section(id: "evidence", label: "🔍 Beweise (\(evidence.count))") {
                    if evidence.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(evidence) { e in
                        toggleRow(id: e.id, title: e.title,
                                  badge: "\(Int(e.weight ?? 5))/10", color: .blue)
                    }
                }
                section(id: "deadlines", label: "⏰ Fristen (\(deadlines.count))") {
                    if deadlines.isEmpty { Text("Keine").font(.caption).foregroundStyle(.secondary) }
                    ForEach(deadlines) { d in
                        toggleRow(id: d.id, title: d.title,
                                  badge: d.side.rawValue,
                                  color: d.side == .gegner ? .red : .gray)
                    }
                }
            }
        }
    }

    private func section<Content: View>(id: String, label: String,
                                        @ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup(
            isExpanded: Binding(get: { expandedSection == id },
                                set: { expandedSection = $0 ? id : nil })
        ) {
            VStack(spacing: 4) { content() }
                .padding(.top, 4)
        } label: {
            Text(label).font(.caption).bold().foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func toggleRow(id: String, title: String, badge: String, color: Color) -> some View {
        let isHidden = hiddenIds.contains(id)
        return HStack {
            Button {
                if isHidden { hiddenIds.remove(id) } else { hiddenIds.insert(id) }
            } label: {
                Image(systemName: isHidden ? "eye.slash" : "eye").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            Text(title).font(.caption)
                .strikethrough(isHidden)
                .foregroundStyle(isHidden ? .secondary : .primary)
            Spacer()
            Text(badge).font(.caption2).bold()
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(color.opacity(0.15), in: Capsule())
                .foregroundStyle(color)
        }
        .padding(6)
        .background(isHidden ? Color.gray.opacity(0.1) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private var motiveCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Label("Hintergedanken & Timing-Analyse", systemImage: "brain")
                            .bold()
                        Text("Warum argumentiert / setzt der Gegner JETZT Fristen?")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await runMotiveAnalysis() }
                    } label: {
                        Label(loadingMotives ? "Analysiere…" : "Motive aufdecken", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(loadingMotives)
                }
                if let err = motiveError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).font(.caption)
                }
                if let m = motives { motiveContent(m) }
            }
        }
    }

    @ViewBuilder
    private func motiveContent(_ m: MotivAnalyse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !m.roteFlaggen.isEmpty {
                VStack(alignment: .leading) {
                    Text("🚩 Rote Flaggen").font(.caption).bold().foregroundStyle(.red)
                    ForEach(m.roteFlaggen, id: \.self) { Text("• \($0)").font(.caption) }
                }
                .padding(8).background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            if let t = m.timingAnalyse {
                labeled("⏰ Warum JETZT?", t, .orange)
            }
            if let f = m.fristenHintergedanken {
                labeled("📅 Fristen-Hintergedanken", f, .orange)
            }
            if !m.verdeckteZiele.isEmpty {
                VStack(alignment: .leading) {
                    Text("🎭 Verdeckte Ziele").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(m.verdeckteZiele, id: \.self) {
                        Label($0, systemImage: "arrow.right").font(.caption2)
                    }
                }
            }
            if !m.psychologischeTaktiken.isEmpty {
                VStack(alignment: .leading) {
                    Text("🧠 Psychologische Taktiken").font(.caption).bold().foregroundStyle(.secondary)
                    ForEach(m.psychologischeTaktiken) { t in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(t.taktik).font(.caption).bold()
                                Spacer()
                                Text(t.intensitaet).font(.caption2).bold()
                                    .foregroundStyle(t.intensitaet == "hoch" ? .red :
                                                     t.intensitaet == "mittel" ? .orange : .blue)
                            }
                            if let b = t.beweis { Text(b).font(.caption2).foregroundStyle(.secondary) }
                        }
                        .padding(6)
                        .background(.background, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            if let n = m.naechsterSchrittGegner {
                labeled("🔮 Nächster Schritt des Gegners", n, .gray)
            }
            if let r = m.empfohleneReaktion {
                VStack(alignment: .leading) {
                    Text("✅ Empfohlene Reaktion").font(.caption).bold().foregroundStyle(.green)
                    Text(r).font(.caption)
                }
                .padding()
                .background(Color.green.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
            }
        }
    }

    private func labeled(_ title: String, _ text: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).bold().foregroundStyle(.secondary)
            Text(text).font(.caption)
        }
        .padding(8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - KI-Funktionen

    /// Generiert eine kompakte Verhandlungsmappe aus aktuellen Argumenten.
    private func generateDossier() async {
        dossierLoading = true; defer { dossierLoading = false }
        let activeEigen = eigenArgs.filter { !hiddenIds.contains($0.id) }
        let activeGegner = gegnerArgs.filter { !hiddenIds.contains($0.id) }

        let prompt = """
        Du bist ein erfahrener Prozessanwalt. Erstelle ein kompaktes Verhandlungs-Dossier
        für die nächste Sitzung.

        Fall: \(caseData?.fallname ?? "") | AZ: \(caseData?.aktenzeichen ?? "")
        Aktuelle Prognose: \(simNow)% (Basis: \(baseSim)%)

        STARKE EIGENE ARGUMENTE:
        \(activeEigen.filter { ($0.strength ?? 5) >= 6 }.map { "- \($0.title)" }.joined(separator: "\n"))

        GEGNERISCHE SCHWACHSTELLEN:
        \(activeGegner.filter { ($0.strength ?? 5) < 6 }.map { "- \($0.title)" }.joined(separator: "\n"))
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "staerkste_argumente": ["type": "array"],
                "gegner_schwachstellen": ["type": "array"],
                "verhandlungsziele": ["type": "array"],
                "opening_statement": ["type": "string"],
                "rote_linien": ["type": "array", "items": ["type": "string"]]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseData?.id)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            alertMessage = "Dossier konnte nicht erstellt werden."
            return
        }
        var d = VerhandlungsDossier()
        d.openingStatement = dict["opening_statement"] as? String
        d.roteLinien = dict["rote_linien"] as? [String] ?? []
        if let arr = dict["staerkste_argumente"] as? [[String: Any]] {
            d.staerksteArgumente = arr.map {
                DossierArg(argument: $0["argument"] as? String ?? "",
                           einsatz: $0["einsatz"] as? String,
                           formulierung: $0["formulierung"] as? String)
            }
        }
        if let arr = dict["gegner_schwachstellen"] as? [[String: Any]] {
            d.gegnerSchwachstellen = arr.map {
                DossierGS(schwachstelle: $0["schwachstelle"] as? String ?? "",
                          angriffspunkt: $0["angriffspunkt"] as? String)
            }
        }
        if let arr = dict["verhandlungsziele"] as? [[String: Any]] {
            d.verhandlungsziele = arr.map {
                DossierZiel(ziel: $0["ziel"] as? String ?? "",
                            prioritaet: $0["prioritaet"] as? String,
                            taktik: $0["taktik"] as? String)
            }
        }
        dossier = d
    }

    /// KI-Analyse des gegnerischen Verhaltens und Timings.
    private func runMotiveAnalysis() async {
        loadingMotives = true; defer { loadingMotives = false }
        motiveError = nil
        let prompt = """
        Du bist Prozessanwalt + Verhaltensstratege (Sun Tzu + Machiavelli).
        Analysiere die TIMING-STRATEGIE der Gegenseite.

        Fall: \(caseData?.fallname ?? "") | Rechtsgebiet: \(caseData?.rechtsgebiet ?? "")
        Zentrale Frage: \(caseData?.zentraleRechtsfrage ?? "")
        Gegnerargumente: \(gegnerArgs.count) | Eigene: \(eigenArgs.count)
        Fristen Gegenseite: \(deadlines.filter { $0.side == .gegner }.count)
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "timing_analyse": ["type": "string"],
                "fristen_hintergedanken": ["type": "string"],
                "verdeckte_ziele": ["type": "array", "items": ["type": "string"]],
                "psychologische_taktiken": ["type": "array"],
                "naechster_schritt_gegner": ["type": "string"],
                "empfohlene_reaktion": ["type": "string"],
                "rote_flaggen": ["type": "array", "items": ["type": "string"]]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseData?.id)
        switch res {
        case .failure(let e):
            motiveError = e.localizedDescription
        case .success(let any):
            guard let dict = any as? [String: Any] else { motiveError = "Ungültige Antwort"; return }
            var m = MotivAnalyse()
            m.timingAnalyse = dict["timing_analyse"] as? String
            m.fristenHintergedanken = dict["fristen_hintergedanken"] as? String
            m.verdeckteZiele = dict["verdeckte_ziele"] as? [String] ?? []
            m.naechsterSchrittGegner = dict["naechster_schritt_gegner"] as? String
            m.empfohleneReaktion = dict["empfohlene_reaktion"] as? String
            m.roteFlaggen = dict["rote_flaggen"] as? [String] ?? []
            if let arr = dict["psychologische_taktiken"] as? [[String: Any]] {
                m.psychologischeTaktiken = arr.map {
                    MotivTaktik(taktik: $0["taktik"] as? String ?? "",
                                beweis: $0["beweis"] as? String,
                                intensitaet: $0["intensitaet"] as? String ?? "mittel")
                }
            }
            motives = m
        }
    }

    /// Erstellt eine Prozessnotiz als TXT-Datei und kopiert in die Zwischenablage.
    /// (Kein PDF-Export, da PDFKit/UIKit auf macOS nicht erlaubt ist.)
    private func exportProzessnotiz() async {
        exportLoading = true; defer { exportLoading = false }
        let prompt = """
        Erstelle eine vollständige taktische Analyse für folgendes Verfahren.
        Fall: \(caseData?.fallname ?? "") | AZ: \(caseData?.aktenzeichen ?? "")
        Eigene Argumente (\(eigenArgs.count)):
        \(eigenArgs.map { "- \($0.title) (\(Int($0.strength ?? 5))/10)" }.joined(separator: "\n"))
        Gegnerargumente (\(gegnerArgs.count)):
        \(gegnerArgs.map { "- \($0.title) (\(Int($0.strength ?? 5))/10)" }.joined(separator: "\n"))

        Erstelle eine Prozessnotiz mit:
        1. Strategien der Gegenseite + Gegenmaßnahme
        2. Timing-Analyse
        3. Psychologische Taktiken
        4. Verhandlungsführung
        5. Warnsignale
        6. Gesamtempfehlung
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "zusammenfassung": ["type": "string"],
                "gegner_strategien": ["type": "array"],
                "timing_analyse": ["type": "string"],
                "psychologische_taktiken": ["type": "array"],
                "verhandlungsfuehrung": ["type": "string"],
                "warnsignale": ["type": "array", "items": ["type": "string"]],
                "gesamtempfehlung": ["type": "string"]
            ]
        ]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseData?.id)
        guard case .success(let any) = res, let dict = any as? [String: Any] else {
            alertMessage = "Export fehlgeschlagen."; return
        }

        var txt = "PROZESSNOTIZ — TAKTISCHE ANALYSE\n"
        txt += "Fall: \(caseData?.fallname ?? "") | AZ: \(caseData?.aktenzeichen ?? "")\n"
        txt += "Erstellt: \(Date().formatted(date: .abbreviated, time: .omitted))\n"
        txt += "VERTRAULICH — Anwaltsgeheimnis § 203 StGB\n\n"

        if let z = dict["zusammenfassung"] as? String { txt += "EXECUTIVE SUMMARY\n\(z)\n\n" }
        if let arr = dict["gegner_strategien"] as? [[String: Any]] {
            txt += "STRATEGIEN DER GEGENSEITE\n"
            for (i, s) in arr.enumerated() {
                txt += "\(i+1). \(s["strategie"] as? String ?? "")\n"
                if let d = s["beschreibung"] as? String { txt += "   \(d)\n" }
                if let g = s["gegenmasnahme"] as? String { txt += "   → GEGENMASSNAHME: \(g)\n" }
            }
            txt += "\n"
        }
        if let t = dict["timing_analyse"] as? String { txt += "TIMING-ANALYSE\n\(t)\n\n" }
        if let arr = dict["psychologische_taktiken"] as? [[String: Any]] {
            txt += "PSYCHOLOGISCHE TAKTIKEN\n"
            for t in arr {
                txt += "- \(t["taktik"] as? String ?? "")\n"
                if let b = t["beschreibung"] as? String { txt += "  \(b)\n" }
                if let g = t["gegenmasnahme"] as? String { txt += "  → \(g)\n" }
            }
            txt += "\n"
        }
        if let v = dict["verhandlungsfuehrung"] as? String { txt += "VERHANDLUNGSFÜHRUNG\n\(v)\n\n" }
        if let warn = dict["warnsignale"] as? [String] {
            txt += "WARNSIGNALE\n"
            warn.forEach { txt += "⚠ \($0)\n" }
            txt += "\n"
        }
        if let g = dict["gesamtempfehlung"] as? String { txt += "GESAMTEMPFEHLUNG\n\(g)\n" }

        // In Zwischenablage kopieren (macOS-konform)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(txt, forType: .string)
        alertMessage = "Prozessnotiz wurde in die Zwischenablage kopiert."
    }
}

// MARK: - Views/Pages/AufgabenView.swift

struct AufgabenView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var tasks: [LegalTask] = []
    @State private var showNew = false
    @State private var filter: TaskStatus? = nil

    private var filtered: [LegalTask] {
        guard let f = filter else { return tasks }
        return tasks.filter { $0.status == f }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                FilterChip(title: "Alle", active: filter == nil) { filter = nil }
                ForEach(TaskStatus.allCases, id: \.self) { s in
                    FilterChip(title: s.rawValue.replacingOccurrences(of: "_", with: " "),
                               active: filter == s) { filter = s }
                }
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 8)
            List {
                ForEach(filtered) { t in
                    HStack(alignment: .top) {
                        Button {
                            Task { await toggle(t) }
                        } label: {
                            Image(systemName: t.status == .erledigt ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(t.status == .erledigt ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.title).strikethrough(t.status == .erledigt)
                            if let n = t.caseName { Text(n).font(.caption).foregroundStyle(.secondary) }
                            if let d = t.dueDate {
                                Text(d.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        priorityBadge(t.priority)
                    }
                }
                .onDelete { idx in
                    Task {
                        for i in idx {
                            try? await cloudKit.delete(recordID: filtered[i].id)
                        }
                        await reload()
                    }
                }
            }
        }
        .navigationTitle("Aufgaben")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neu", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            NewTaskSheet { t in
                Task { _ = try? await cloudKit.save(t); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func priorityBadge(_ p: TaskPriority) -> some View {
        let color: Color = {
            switch p { case .hoch: return .red; case .mittel: return .orange; case .niedrig: return .blue }
        }()
        return Text(p.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    @MainActor
    private func reload() async {
        tasks = (try? await cloudKit.fetch(LegalTask.self)) ?? []
    }

    @MainActor
    private func toggle(_ t: LegalTask) async {
        var copy = t
        copy.status = (t.status == .erledigt) ? .offen : .erledigt
        _ = try? await cloudKit.save(copy)
        await reload()
    }
}

struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueDate: Date = Date().addingTimeInterval(7 * 86400)
    @State private var prio: TaskPriority = .mittel
    var onCreate: (LegalTask) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Titel", text: $title)
                DatePicker("Fällig am", selection: $dueDate, displayedComponents: .date)
                Picker("Priorität", selection: $prio) {
                    ForEach(TaskPriority.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            .navigationTitle("Neue Aufgabe")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var t = LegalTask(title: title)
                        t.dueDate = dueDate
                        t.priority = prio
                        onCreate(t); dismiss()
                    }.disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Views/Pages/CaseDetailView.swift

enum CaseTab: String, CaseIterable, Hashable {
    case fallakte       = "Fallakte"
    case argumente      = "Argumente"
    case beweise        = "Beweise"
    case personen       = "Personen"
    case zeitleiste     = "Zeitleiste"
    case gesamtbewert   = "Bewertung"
    case verhandlung    = "Verhandlung"
    case gegner         = "Gegner"
    case abschluss      = "Abschluss"

    var icon: String {
        switch self {
        case .fallakte:      return "doc.text"
        case .argumente:     return "lightbulb"
        case .beweise:       return "doc.on.doc"
        case .personen:      return "person.2"
        case .zeitleiste:    return "calendar"
        case .gesamtbewert:  return "chart.bar.xaxis"
        case .verhandlung:   return "person.2.wave.2"
        case .gegner:        return "shield.lefthalf.filled"
        case .abschluss:     return "checkmark.seal"
        }
    }
}

struct CaseDetailView: View {
    let caseId: String
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var caseEntity: Case?
    @State private var persons:    [Person] = []
    @State private var timeline:   [TimelineEvent] = []
    @State private var deadlines:  [Deadline] = []
    @State private var gegnerVerhalten: [GegnerVerhalten] = []
    @State private var selectedTab: CaseTab = .fallakte
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabBar
            Divider()
            tabContent
        }
        .navigationTitle(caseEntity?.fallname ?? "Fall")
        .task { await reload() }
        .refreshable { await reload() }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(CaseTab.allCases, id: \.self) { t in
                    Button { selectedTab = t } label: {
                        Label(t.rawValue, systemImage: t.icon)
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(selectedTab == t
                                ? Color.accentColor.opacity(0.15)
                                : .clear,
                                in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(selectedTab == t ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
        }
    }

    // MARK: - Tab Content Router

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .fallakte:
            ScrollView { fallakteView.padding() }
        case .argumente:
            TabArgumenteView(caseId: caseId, caseData: caseEntity)
        case .beweise:
            ScrollView { beweiseView.padding() }
        case .personen:
            ScrollView { personenView.padding() }
        case .zeitleiste:
            ScrollView { zeitleisteView.padding() }
        case .gesamtbewert:
            TabGesamtbewertungView(caseId: caseId, caseData: caseEntity)
        case .verhandlung:
            TabVerhandlungssimulationView(caseId: caseId, caseData: caseEntity)
        case .gegner:
            ScrollView { gegnerView.padding() }
        case .abschluss:
            ScrollView { abschlussView.padding() }
        }
    }

    // MARK: - Fallakte

    private var fallakteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let c = caseEntity {
                GroupBox("Stammdaten") {
                    VStack(spacing: 6) {
                        infoRow(label: "Aktenzeichen",  value: c.aktenzeichen ?? "–")
                        infoRow(label: "Gericht",       value: c.gericht ?? "–")
                        infoRow(label: "Rechtsgebiet",  value: c.rechtsgebiet ?? "–")
                        infoRow(label: "Status",        value: c.status.rawValue)
                        infoRow(label: "Instanz",       value: c.instanz.rawValue)
                        if let s = c.streitwert {
                            infoRow(label: "Streitwert", value: "\(Int(s)) €")
                        }
                        if let m = c.mandantName {
                            infoRow(label: "Mandant", value: m)
                        }
                    }
                }
                if let p = c.prognose {
                    GroupBox("Erfolgsprognose") {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: p / 100).tint(p >= 60 ? .green : (p >= 40 ? .orange : .red))
                            Text("\(Int(p)) % Erfolgswahrscheinlichkeit")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if let z = c.zentraleRechtsfrage {
                    GroupBox("Zentrale Rechtsfrage") {
                        Text(z).font(.body)
                    }
                }
                if let notes = c.notes, !notes.isEmpty {
                    GroupBox("Notizen") { Text(notes).font(.caption) }
                }
            } else if loading {
                ProgressView().padding()
            }
        }
    }

    // MARK: - Beweise (inline, kompakt)

    private var beweiseView: some View {
        BeweisInlineView(caseId: caseId)
    }

    // MARK: - Personen

    private var personenView: some View {
        PersonenInlineView(caseId: caseId)
    }

    // MARK: - Zeitleiste

    private var zeitleisteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zeitleiste").font(.headline)
            if timeline.isEmpty {
                ContentUnavailableView("Keine Ereignisse",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Füge Ereignisse zum Fall hinzu."))
            } else {
                ForEach(timeline.sorted(by: { $0.date < $1.date })) { e in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle().fill(Color.accentColor).frame(width: 10, height: 10)
                            Rectangle().frame(width: 2).foregroundStyle(.secondary.opacity(0.25))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(.secondary)
                            Text(e.title).font(.body.weight(.medium))
                            if let d = e.eventDescription {
                                Text(d).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Divider().padding(.vertical, 4)
            Text("Fristen (\(deadlines.filter{$0.status == .offen}.count) offen)").font(.headline)
            ForEach(deadlines) { d in
                HStack {
                    Image(systemName: d.status == .offen ? "clock.badge.exclamationmark" : "checkmark.circle")
                        .foregroundStyle(d.status == .offen ? .orange : .green)
                    VStack(alignment: .leading) {
                        Text(d.title).font(.subheadline)
                        Text(d.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(d.status.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15), in: Capsule())
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Gegnerverhalten

    private var gegnerView: some View {
        GegnerVerhaltenTabView(caseId: caseId, caseEntity: caseEntity)
    }

    // MARK: - Abschluss

    private var abschlussView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Abschluss-Fragebogen").font(.headline)
            Text("Bewerte nach Verfahrensende, ob die KI-Prognose korrekt war. So verbessert LegalOS die Prognosen für künftige Fälle.")
                .font(.caption).foregroundStyle(.secondary)
            if let c = caseEntity {
                GroupBox("Fallkennzahlen") {
                    VStack(spacing: 6) {
                        infoRow(label: "Prognose",  value: "\(Int(c.prognose ?? 0)) %")
                        infoRow(label: "Status",    value: c.status.rawValue)
                        if let s = c.streitwert {
                            infoRow(label: "Streitwert", value: "\(Int(s)) €")
                        }
                    }
                }
            }
            NavigationLink("Fragebogen ausfüllen") {
                CaseFragebogenView(caseId: caseId)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).frame(width: 130, alignment: .leading)
            Text(value).font(.subheadline)
            Spacer()
        }
        .font(.subheadline)
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        caseEntity = try? await cloudKit.fetchOne(Case.self, id: caseId)
        persons    = (try? await cloudKit.fetchForCase(Person.self,        caseId: caseId)) ?? []
        timeline   = (try? await cloudKit.fetchForCase(TimelineEvent.self, caseId: caseId)) ?? []
        deadlines  = (try? await cloudKit.fetchForCase(Deadline.self,      caseId: caseId)) ?? []
        gegnerVerhalten = (try? await cloudKit.fetchForCase(GegnerVerhalten.self, caseId: caseId)) ?? []
    }
}

// MARK: - Beweise Inline Sub-View

struct BeweisInlineView: View {
    let caseId: String
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var evidence: [Evidence] = []
    @State private var showAdd = false
    @State private var newTitle = ""
    @State private var newDesc = ""
    @State private var newType = "Dokument"
    @State private var newWeight: Double = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Beweise & Dokumente (\(evidence.count))")
                    .font(.headline)
                Spacer()
                Button { showAdd.toggle() } label: {
                    Label("Hinzufügen", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            if showAdd {
                GroupBox("Neuer Beweis") {
                    VStack(spacing: 8) {
                        TextField("Titel *", text: $newTitle)
                        TextField("Beschreibung", text: $newDesc, axis: .vertical).lineLimit(2...3)
                        HStack {
                            Picker("Typ", selection: $newType) {
                                ForEach(["Dokument","Zeuge","Vertrag","E-Mail","Foto","Gutachten","Sonstiges"],
                                        id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            Stepper("Gewicht \(newWeight, specifier: "%.0f")/10",
                                    value: $newWeight, in: 0...10, step: 1)
                        }
                        HStack {
                            Spacer()
                            Button("Abbrechen") { showAdd = false }
                            Button("Speichern") { Task { await addEvidence() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }
            if evidence.isEmpty {
                ContentUnavailableView("Keine Beweise",
                    systemImage: "doc.badge.plus",
                    description: Text("Füge Beweise und Dokumente hinzu."))
            } else {
                ForEach(evidence) { e in
                    HStack(spacing: 12) {
                        Image(systemName: evidenceIcon(e.type))
                            .font(.title2).foregroundStyle(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.title).font(.body.weight(.medium))
                            if let d = e.evidenceDescription {
                                Text(d).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                        Spacer()
                        if let w = e.kiWeight ?? e.weight {
                            VStack {
                                Text("\(Int(w))/10").font(.caption.weight(.semibold))
                                Text("Gewicht").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task { await load() }
    }

    private func evidenceIcon(_ type: String?) -> String {
        switch type {
        case "Zeuge":    return "person.fill.questionmark"
        case "Vertrag":  return "doc.text.fill"
        case "E-Mail":   return "envelope.fill"
        case "Foto":     return "photo.fill"
        case "Gutachten": return "chart.bar.doc.horizontal"
        default:         return "doc.on.doc.fill"
        }
    }

    @MainActor
    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        evidence = (try? await cloudKit.fetch(Evidence.self, predicate: pred)) ?? []
    }

    private func addEvidence() async {
        var e = Evidence(caseId: caseId, title: newTitle)
        e.evidenceDescription = newDesc.isEmpty ? nil : newDesc
        e.type = newType
        e.weight = newWeight
        _ = try? await cloudKit.save(e)
        newTitle = ""; newDesc = ""; newType = "Dokument"; newWeight = 5
        showAdd = false
        await load()
    }
}

// MARK: - Personen Inline Sub-View

struct PersonenInlineView: View {
    let caseId: String
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var persons: [Person] = []
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newRole: PersonRole = .zeuge

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Beteiligte (\(persons.count))").font(.headline)
                Spacer()
                Button { showAdd.toggle() } label: {
                    Label("Person", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            if showAdd {
                GroupBox("Neue Person") {
                    VStack(spacing: 8) {
                        TextField("Name *", text: $newName)
                        Picker("Rolle", selection: $newRole) {
                            ForEach(PersonRole.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        HStack {
                            Spacer()
                            Button("Abbrechen") { showAdd = false }
                            Button("Hinzufügen") { Task { await addPerson() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }
            if persons.isEmpty {
                ContentUnavailableView("Keine Beteiligten",
                    systemImage: "person.badge.plus",
                    description: Text("Füge Beteiligte (Zeugen, Anwälte, Parteien) hinzu."))
            } else {
                ForEach(persons) { p in
                    HStack(spacing: 12) {
                        Image(systemName: roleIcon(p.role)).font(.title2)
                            .foregroundStyle(roleColor(p.role))
                        VStack(alignment: .leading) {
                            Text(p.name).font(.body.weight(.medium))
                            Text(p.role.rawValue).font(.caption).foregroundStyle(.secondary)
                            if let org = p.organization {
                                Text(org).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let g = p.glaubwuerdigkeit {
                            VStack {
                                Text("\(Int(g))%").font(.caption.weight(.semibold))
                                Text("Glaubw.").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task { await load() }
    }

    private func roleIcon(_ r: PersonRole) -> String {
        switch r {
        case .zeuge:             return "person.fill.questionmark"
        case .anwalt:            return "briefcase.fill"
        case .richter:           return "building.columns.fill"
        case .partei:            return "person.2.fill"
        case .sachverstaendiger: return "magnifyingglass"
        case .gutachter:         return "chart.bar.doc.horizontal"
        }
    }
    private func roleColor(_ r: PersonRole) -> Color {
        switch r {
        case .anwalt:            return .purple
        case .richter:           return .orange
        case .partei:            return .red
        case .sachverstaendiger: return .blue
        default:                 return .gray
        }
    }

    @MainActor
    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        persons = (try? await cloudKit.fetch(Person.self, predicate: pred)) ?? []
    }

    private func addPerson() async {
        var p = Person(caseId: caseId, name: newName)
        p.role = newRole
        _ = try? await cloudKit.save(p)
        newName = ""; showAdd = false
        await load()
    }
}

// MARK: - GegnerVerhalten Tab

struct GegnerVerhaltenTabView: View {
    let caseId: String
    let caseEntity: Case?
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var items: [GegnerVerhalten] = []
    @State private var showAdd = false
    @State private var analyzing = false
    @State private var analysis: GegnerAnalysisResult?

    @State private var newTitel = ""
    @State private var newTyp: GegnerTyp = .taktik
    @State private var newBeschreibung = ""
    @State private var newReaktion: GegnerReaktion? = nil
    @State private var newDatum: Date = Date()
    @State private var newUnserAngebot: String = ""
    @State private var newGegnerAngebot: String = ""

    struct GegnerAnalysisResult {
        var muster: [String] = []
        var empfehlung: String = ""
        var staerken: [String] = []
        var schwaechen: [String] = []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Gegnerverhalten").font(.headline)
                    Text("Taktiken, Reaktionen und Verhaltensmuster der Gegenseite.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await analyzePattern() }
                } label: {
                    Label(analyzing ? "Analysiere…" : "KI-Analyse", systemImage: "brain.head.profile")
                }
                .buttonStyle(.bordered)
                .disabled(analyzing || items.isEmpty)

                Button { showAdd = true } label: {
                    Label("Eintrag", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            // KI-Analyse Ergebnis
            if let a = analysis {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("KI-Musteranalyse", systemImage: "brain.head.profile")
                                .font(.callout).bold()
                            Spacer()
                            Button { analysis = nil } label: { Image(systemName: "xmark") }
                                .buttonStyle(.plain)
                        }
                        if !a.muster.isEmpty {
                            Text("Erkannte Muster").font(.caption).bold().foregroundStyle(.secondary)
                            ForEach(a.muster, id: \.self) {
                                Label($0, systemImage: "circle.fill").font(.caption)
                            }
                        }
                        if !a.empfehlung.isEmpty {
                            Text("Empfehlung").font(.caption).bold().foregroundStyle(.blue)
                            Text(a.empfehlung).font(.caption)
                                .padding(8)
                                .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                        }
                        HStack(alignment: .top, spacing: 12) {
                            if !a.staerken.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Gegner-Stärken").font(.caption2).bold().foregroundStyle(.red)
                                    ForEach(a.staerken, id: \.self) {
                                        Label($0, systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption2).foregroundStyle(.red)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if !a.schwaechen.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Gegner-Schwächen").font(.caption2).bold().foregroundStyle(.green)
                                    ForEach(a.schwaechen, id: \.self) {
                                        Label($0, systemImage: "arrow.down.circle.fill")
                                            .font(.caption2).foregroundStyle(.green)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            // Add Form
            if showAdd {
                GroupBox("Neues Verhalten erfassen") {
                    VStack(spacing: 8) {
                        TextField("Titel *", text: $newTitel)
                        TextField("Beschreibung", text: $newBeschreibung, axis: .vertical)
                            .lineLimit(2...4)
                        HStack {
                            Picker("Typ", selection: $newTyp) {
                                ForEach(GegnerTyp.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            DatePicker("Datum", selection: $newDatum, displayedComponents: .date)
                                .labelsHidden()
                        }
                        HStack {
                            TextField("Unser Angebot (€)", text: $newUnserAngebot)
                            TextField("Gegnerangebot (€)", text: $newGegnerAngebot)
                        }
                        Picker("Reaktion", selection: $newReaktion) {
                            Text("Keine Angabe").tag(GegnerReaktion?.none)
                            ForEach(GegnerReaktion.allCases, id: \.self) {
                                Text($0.rawValue).tag(GegnerReaktion?.some($0))
                            }
                        }
                        HStack {
                            Spacer()
                            Button("Abbrechen") { showAdd = false }
                            Button("Speichern") { Task { await addItem() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(newTitel.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }

            // Liste
            if items.isEmpty && !showAdd {
                ContentUnavailableView(
                    "Kein Verhalten dokumentiert",
                    systemImage: "eye.slash",
                    description: Text("Dokumentiere Taktiken und Reaktionen der Gegenseite."))
            } else {
                let df = DateFormatter(); _ = { df.dateStyle = .medium; df.locale = Locale(identifier: "de_DE") }()
                ForEach(items) { v in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(v.typ.rawValue)
                                .font(.caption2).bold()
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(typColor(v.typ).opacity(0.15), in: Capsule())
                                .foregroundStyle(typColor(v.typ))
                            if let r = v.reaktion {
                                Text(r.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                            }
                            Spacer()
                            if let d = v.datum {
                                Text(df.string(from: d)).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Text(v.titel).font(.subheadline.weight(.medium))
                        if let b = v.beschreibung {
                            Text(b).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                        }
                        if let u = v.unserAngebot, let g = v.gegnerAngebot {
                            HStack {
                                Label("Unser: \(Int(u)) €", systemImage: "arrow.up.circle")
                                    .font(.caption).foregroundStyle(.blue)
                                Label("Gegner: \(Int(g)) €", systemImage: "arrow.down.circle")
                                    .font(.caption).foregroundStyle(.red)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task { await load() }
    }

    private func typColor(_ t: GegnerTyp) -> Color {
        switch t {
        case .versaeumteFrist:    return .orange
        case .vergleichsreaktion: return .blue
        case .taktik:             return .red
        case .prozessverhalten:   return .purple
        case .sonstiges:          return .gray
        }
    }

    @MainActor
    private func load() async {
        let pred = NSPredicate(format: "case_id == %@", caseId)
        items = (try? await cloudKit.fetch(GegnerVerhalten.self, predicate: pred)) ?? []
    }

    private func addItem() async {
        var v = GegnerVerhalten(caseId: caseId, typ: newTyp, titel: newTitel)
        v.beschreibung = newBeschreibung.isEmpty ? nil : newBeschreibung
        v.reaktion = newReaktion
        v.datum = newDatum
        v.unserAngebot = Double(newUnserAngebot)
        v.gegnerAngebot = Double(newGegnerAngebot)
        _ = try? await cloudKit.save(v)
        newTitel = ""; newBeschreibung = ""; newUnserAngebot = ""; newGegnerAngebot = ""
        showAdd = false
        await load()
    }

    private func analyzePattern() async {
        analyzing = true; defer { analyzing = false }
        let list = items.map { "- [\($0.typ.rawValue)] \($0.titel): \($0.beschreibung ?? "")" }
            .joined(separator: "\n")
        let prompt = """
        Analysiere das Verhaltensmuster der Gegenseite in diesem Rechtsfall.
        Fall: \(caseEntity?.fallname ?? ""), Rechtsgebiet: \(caseEntity?.rechtsgebiet ?? "")
        Dokumentierte Verhaltensweisen:
        \(list)
        Gib JSON zurück: { muster: [string], empfehlung: string, staerken: [string], schwaechen: [string] }
        """
        let schema: [String: Any] = ["type": "object",
            "properties": ["muster": ["type": "array"], "empfehlung": ["type": "string"],
                           "staerken": ["type": "array"], "schwaechen": ["type": "array"]]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, caseId: caseId)
        guard case .success(let any) = res, let dict = any as? [String: Any] else { return }
        analysis = GegnerAnalysisResult(
            muster:    dict["muster"] as? [String] ?? [],
            empfehlung: dict["empfehlung"] as? String ?? "",
            staerken:  dict["staerken"] as? [String] ?? [],
            schwaechen: dict["schwaechen"] as? [String] ?? []
        )
    }
}

// MARK: - Abschluss-Fragebogen Stub

struct CaseFragebogenView: View {
    let caseId: String
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Abschluss-Fragebogen").font(.title2.weight(.semibold))
            Text("Dieser Bereich wird nach Verfahrensende ausgefüllt.")
                .font(.subheadline).foregroundStyle(.secondary)
            GroupBox("Prognose-Feedback") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("War die KI-Prognose zutreffend?").font(.caption)
                    HStack {
                        ForEach(["Ja", "Teilweise", "Nein"], id: \.self) { o in
                            Button(o) { }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            GroupBox("Ergebnis") {
                VStack(alignment: .leading) {
                    Text("Verfahrensausgang").font(.caption).foregroundStyle(.secondary)
                    Picker("Ergebnis", selection: .constant("Gewonnen")) {
                        ForEach(["Gewonnen","Verloren","Vergleich","Eingestellt"], id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
        .navigationTitle("Fragebogen")
    }
}

// MARK: - Views/Pages/FallAssistentChatView.swift

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let role: Role
    var text: String
    let timestamp: Date = Date()
    enum Role: String { case user, assistant }
}

struct FallAssistentChatView: View {
    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""
    @State private var streaming: Bool = false
    @State private var cases: [Case] = []
    @State private var selectedCaseId: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            casePicker
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        if messages.isEmpty {
                            placeholder
                        } else {
                            ForEach(messages) { m in bubble(m) }
                        }
                    }
                    .padding()
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            inputBar
        }
        .navigationTitle("Fall-Assistent")
        .task { cases = (try? await cloudKit.fetch(Case.self)) ?? [] }
    }

    private var casePicker: some View {
        HStack {
            Text("Fall:").font(.caption).foregroundStyle(.secondary)
            Picker("Fall", selection: $selectedCaseId) {
                Text("(kein Bezug)").tag(String?.none)
                ForEach(cases) { c in
                    Text(c.fallname).tag(Optional(c.id))
                }
            }
            .labelsHidden()
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Stelle eine Frage zu deinem Fall oder allgemein zum Recht.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private func bubble(_ m: ChatMessage) -> some View {
        HStack {
            if m.role == .assistant {
                Text(m.text)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                Spacer()
            } else {
                Spacer()
                Text(m.text)
                    .padding()
                    .background(Color.accentColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .id(m.id)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Frage formulieren…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await send() }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || streaming)
        }
        .padding(8)
    }

    @MainActor
    private func send() async {
        let userMsg = ChatMessage(role: .user, text: input)
        messages.append(userMsg)
        let prompt = input
        input = ""
        streaming = true
        defer { streaming = false }
        let res = await kiProvider.invokeLLM(prompt: prompt,
                                             context: "FallAssistentChat",
                                             caseId: selectedCaseId)
        switch res {
        case .success(let v):
            let text = (v as? String) ?? "(keine Antwort)"
            messages.append(ChatMessage(role: .assistant, text: text))
        case .failure(let err):
            messages.append(ChatMessage(role: .assistant, text: "Fehler: \(err.localizedDescription)"))
        }
    }
}

// MARK: - Views/Pages/HomeView.swift

struct HomeView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var cases: [Case] = []
    @State private var deadlines: [Deadline] = []
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                kpiRow
                quickActions
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Übersicht")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var greeting: String {
        if let name = auth.currentUser?.fullName, !name.isEmpty {
            return "Willkommen zurück, \(name)."
        }
        return "Willkommen zurück."
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title.weight(.semibold))
            Text("Deine Legal-OS für Strategie, Fristen und KI-Analyse.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var kpiRow: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
            kpi(title: "Aktive Fälle", value: "\(cases.filter { $0.status == .aktiv }.count)",
                icon: "folder.fill.badge.gearshape", color: .blue)
            kpi(title: "Offene Fristen",
                value: "\(deadlines.filter { $0.status == .offen }.count)",
                icon: "clock.badge.exclamationmark", color: .orange)
            kpi(title: "KI-Credits",
                value: "\(auth.currentUser?.kiCredits ?? 0)",
                icon: "sparkles", color: .purple)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellaktionen").font(.headline)
            HStack(spacing: 12) {
                NavigationLink(destination: LexaraDashboardView()) {
                    actionCard(title: "Neuer Fall", icon: "plus.rectangle.on.folder")
                }
                NavigationLink(destination: StrategosView()) {
                    actionCard(title: "Strategos", icon: "shield.lefthalf.filled")
                }
                NavigationLink(destination: FallAssistentChatView()) {
                    actionCard(title: "KI-Assistent", icon: "sparkles")
                }
            }
        }
    }

    private func kpi(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(value).font(.title2.weight(.semibold))
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func actionCard(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.footnote)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        cases = (try? await cloudKit.fetch(Case.self)) ?? []
        deadlines = (try? await cloudKit.fetch(Deadline.self)) ?? []
    }
}

// MARK: - Views/Pages/KIComplianceView.swift

struct KIComplianceView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var logs: [KIUsageLog] = []
    @State private var search: String = ""

    private var filtered: [KIUsageLog] {
        guard !search.isEmpty else { return logs }
        return logs.filter {
            $0.kiFunction.localizedCaseInsensitiveContains(search) ||
            ($0.context ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(.purple)
                        Text(log.kiFunction).font(.body.weight(.medium))
                        Spacer()
                        Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let ctx = log.context {
                        Text(ctx).font(.caption).foregroundStyle(.secondary)
                    }
                    if let s = log.inputSummary {
                        Text(s).font(.caption2).lineLimit(2).foregroundStyle(.secondary)
                    }
                    if let m = log.model {
                        Text("Modell: \(m)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $search, prompt: "KI-Funktion oder Kontext")
        .navigationTitle("KI-Compliance")
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        logs = (try? await cloudKit.fetch(KIUsageLog.self)) ?? []
    }
}

// MARK: - Views/Pages/KanzleiAnalytikView.swift

struct KanzleiAnalytikView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var cases: [Case] = []
    @State private var feedback: [AIPerformanceFeedback] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Kanzlei-Analytik").font(.title.weight(.semibold))

                VStack(alignment: .leading) {
                    Text("Fälle nach Status").font(.headline)
                    Chart(statusBuckets, id: \.0) { item in
                        BarMark(x: .value("Status", item.0),
                                y: .value("Anzahl", item.1))
                    }
                    .frame(height: 220)
                }

                VStack(alignment: .leading) {
                    Text("Prognose-Treffer (Gesamtbewertung)").font(.headline)
                    if feedback.isEmpty {
                        Text("Noch keine Feedback-Daten vorhanden.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Chart(feedback) { f in
                            PointMark(x: .value("Datum", f.id),
                                      y: .value("Gesamtbewertung", f.gesamtbewertung))
                        }
                        .frame(height: 220)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Streitwert-Verteilung").font(.headline)
                    Chart(cases.filter { $0.streitwert != nil }) { c in
                        BarMark(x: .value("Fall", c.fallname),
                                y: .value("Streitwert", c.streitwert ?? 0))
                    }
                    .frame(height: 240)
                }
            }
            .padding()
        }
        .navigationTitle("Analytik")
        .task { await reload() }
    }

    private var statusBuckets: [(String, Int)] {
        CaseStatus.allCases.map { s in
            (s.rawValue, cases.filter { $0.status == s }.count)
        }
    }

    @MainActor
    private func reload() async {
        cases    = (try? await cloudKit.fetch(Case.self)) ?? []
        feedback = (try? await cloudKit.fetch(AIPerformanceFeedback.self)) ?? []
    }
}

// MARK: - Views/Pages/KanzleiCockpitView.swift

struct KanzleiCockpitView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var cases: [Case] = []
    @State private var deadlines: [Deadline] = []
    @State private var tasks: [LegalTask] = []
    @State private var warnings: [CaseWarning] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Kanzlei-Cockpit").font(.title.weight(.semibold))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                    kpi("Aktive Fälle", value: "\(cases.filter { $0.status == .aktiv }.count)", icon: "folder.fill", color: .blue)
                    kpi("Fristen offen", value: "\(deadlines.filter { $0.status == .offen }.count)", icon: "clock", color: .orange)
                    kpi("Aufgaben offen", value: "\(tasks.filter { $0.status != .erledigt }.count)", icon: "checklist", color: .green)
                    kpi("Warnungen", value: "\(warnings.filter { !$0.resolved }.count)", icon: "exclamationmark.triangle.fill", color: .red)
                }

                Text("Kritische Warnungen").font(.headline)
                ForEach(warnings.filter { $0.severity == .kritisch && !$0.resolved }) { w in
                    VStack(alignment: .leading) {
                        Text(w.title).font(.subheadline.weight(.medium))
                        if let d = w.warningDescription {
                            Text(d).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Kanzlei-Cockpit")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func kpi(_ label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(value).font(.title3.weight(.semibold))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func reload() async {
        cases     = (try? await cloudKit.fetch(Case.self)) ?? []
        deadlines = (try? await cloudKit.fetch(Deadline.self)) ?? []
        tasks     = (try? await cloudKit.fetch(LegalTask.self)) ?? []
        warnings  = (try? await cloudKit.fetch(CaseWarning.self)) ?? []
    }
}

// MARK: - Views/Pages/LexaraDashboardView.swift

struct LexaraDashboardView: View {
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var cases: [Case] = []
    @State private var folders: [CaseFolder] = []
    @State private var search: String = ""
    @State private var statusFilter: CaseStatus? = nil
    @State private var loading = false
    @State private var showNewCase = false

    private var filteredCases: [Case] {
        cases.filter { c in
            let okStatus = statusFilter == nil || c.status == statusFilter
            let okSearch = search.isEmpty
                || c.fallname.localizedCaseInsensitiveContains(search)
                || (c.aktenzeichen ?? "").localizedCaseInsensitiveContains(search)
            return okStatus && okSearch
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterBar
                if loading && cases.isEmpty {
                    ProgressView().padding()
                } else if filteredCases.isEmpty {
                    ContentUnavailableView("Keine Fälle gefunden",
                                           systemImage: "folder.badge.questionmark",
                                           description: Text("Lege einen neuen Fall an, um zu starten."))
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                        ForEach(filteredCases) { c in
                            NavigationLink(value: c) { CaseCardView(caseEntity: c) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("LEXARA Dashboard")
        .navigationDestination(for: Case.self) { c in CaseDetailView(caseId: c.id) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNewCase = true } label: { Label("Neuer Fall", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNewCase) {
            NewCaseSheet { c in
                Task { _ = try? await cloudKit.save(c); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Fall, Aktenzeichen, Mandant…", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

            HStack {
                FilterChip(title: "Alle", active: statusFilter == nil) { statusFilter = nil }
                ForEach(CaseStatus.allCases, id: \.self) { s in
                    FilterChip(title: s.rawValue, active: statusFilter == s) { statusFilter = s }
                }
                Spacer()
            }
        }
    }

    @MainActor
    private func reload() async {
        loading = true
        defer { loading = false }
        cases   = (try? await cloudKit.fetch(Case.self)) ?? []
        folders = (try? await cloudKit.fetch(CaseFolder.self)) ?? []
    }
}

struct CaseCardView: View {
    let caseEntity: Case

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(caseEntity.fallname).font(.headline).lineLimit(2)
                Spacer()
                Text(caseEntity.status.rawValue).font(.caption).padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            if let az = caseEntity.aktenzeichen { Text("Az: \(az)").font(.caption).foregroundStyle(.secondary) }
            if let m  = caseEntity.mandantName { Text(m).font(.caption).foregroundStyle(.secondary) }
            if let p  = caseEntity.prognose {
                ProgressView(value: p / 100)
                    .tint(p >= 60 ? .green : (p >= 40 ? .orange : .red))
                Text("Prognose: \(Int(p)) %").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct FilterChip: View {
    let title: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(active ? Color.accentColor : Color.gray.opacity(0.15), in: Capsule())
                .foregroundStyle(active ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct NewCaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var aktenzeichen = ""
    @State private var mandant = ""
    @State private var rechtsgebiet = ""
    var onCreate: (Case) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Fallname", text: $name)
                TextField("Aktenzeichen (optional)", text: $aktenzeichen)
                TextField("Mandant", text: $mandant)
                TextField("Rechtsgebiet", text: $rechtsgebiet)
            }
            .navigationTitle("Neuer Fall")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var c = Case(fallname: name)
                        c.aktenzeichen = aktenzeichen.isEmpty ? nil : aktenzeichen
                        c.mandantName  = mandant.isEmpty ? nil : mandant
                        c.rechtsgebiet = rechtsgebiet.isEmpty ? nil : rechtsgebiet
                        onCreate(c)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Views/Pages/MandantenView.swift

struct MandantenView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var folders: [CaseFolder] = []
    @State private var cases: [Case] = []
    @State private var showNew = false

    var body: some View {
        List {
            ForEach(folders) { f in
                let related = cases.filter { $0.folderId == f.id }
                Section(header: HStack {
                    Image(systemName: "person.crop.rectangle")
                    Text(f.mandantName ?? f.name)
                    Spacer()
                    Text(f.mandantTyp.rawValue).font(.caption).foregroundStyle(.secondary)
                }) {
                    if related.isEmpty {
                        Text("Keine Fälle").font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(related) { c in
                        NavigationLink(value: c) {
                            VStack(alignment: .leading) {
                                Text(c.fallname)
                                if let az = c.aktenzeichen {
                                    Text(az).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Mandanten")
        .navigationDestination(for: Case.self) { c in CaseDetailView(caseId: c.id) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neu", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            NewMandantSheet { folder in
                Task { _ = try? await cloudKit.save(folder); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        folders = (try? await cloudKit.fetch(CaseFolder.self)) ?? []
        cases   = (try? await cloudKit.fetch(Case.self)) ?? []
    }
}

struct NewMandantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var typ: MandantTyp = .privatperson
    @State private var email = ""
    var onCreate: (CaseFolder) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Typ", selection: $typ) {
                    ForEach(MandantTyp.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("E-Mail", text: $email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
            }
            .navigationTitle("Neuer Mandant")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var f = CaseFolder(name: name)
                        f.mandantName = name
                        f.mandantTyp = typ
                        f.mandantEmail = email.isEmpty ? nil : email
                        onCreate(f); dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Views/Pages/ModulesView.swift

struct ModulesView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var claude: ClaudeAPIService

    @State private var apiKey: String = ""
    @State private var apiKeyVisible: Bool = false

    var body: some View {
        Form {
            Section("Module") {
                moduleRow(icon: "shield.lefthalf.filled", title: "Strategos", enabled: true)
                moduleRow(icon: "books.vertical", title: "Sun Tzu / Machiavelli", enabled: true)
                moduleRow(icon: "person.badge.shield.checkmark", title: "Richter-Profile", enabled: true)
                moduleRow(icon: "calendar", title: "Zeitleiste", enabled: true)
                moduleRow(icon: "cpu", title: "Plattform-Agent", enabled: true)
            }

            Section("Claude API") {
                if apiKeyVisible {
                    TextField("Anthropic API-Key", text: $apiKey)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } else {
                    SecureField("Anthropic API-Key", text: $apiKey)
                }
                Toggle("Key sichtbar", isOn: $apiKeyVisible)
                HStack {
                    Button("Speichern") {
                        claude.setApiKey(apiKey)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
                    Button(role: .destructive) {
                        claude.clearApiKey()
                        apiKey = ""
                    } label: { Text("Löschen") }
                }
                Text("Modell: \(ClaudeAPIService.defaultModel)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let u = auth.currentUser {
                Section("Konto") {
                    LabeledContent("E-Mail", value: u.email)
                    LabeledContent("Jurisdiktion", value: u.jurisdiction.rawValue)
                    LabeledContent("KI-Credits", value: "\(u.kiCredits)")
                    Button(role: .destructive) { auth.logout() } label: { Text("Abmelden") }
                }
            }
        }
        .navigationTitle("Module & Einstellungen")
        .onAppear { apiKey = claude.apiKey ?? "" }
    }

    private func moduleRow(icon: String, title: String, enabled: Bool) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.tint)
            Text(title)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(enabled ? .green : .secondary)
        }
    }
}

// MARK: - Views/Pages/PlattformAgentView.swift

struct PlattformAgentView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var claude: ClaudeAPIService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var logs: [KIUsageLog] = []
    @State private var testPrompt: String = "Bitte erkläre kurz §242 BGB."
    @State private var testAnswer: String = ""
    @State private var testing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Plattform-Agent").font(.title.weight(.semibold))
                Text("Selbst-Diagnose und Verbindungstest zu Anthropic + CloudKit.")
                    .font(.subheadline).foregroundStyle(.secondary)

                HStack {
                    statusPill(title: "Claude API",
                               ok: claude.apiKey != nil,
                               okText: "API-Key gesetzt",
                               failText: "Kein API-Key")
                    statusPill(title: "iCloud",
                               ok: true,
                               okText: "CKContainer aktiv",
                               failText: "Inaktiv")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Test-Anfrage").font(.headline)
                    TextField("Test-Prompt", text: $testPrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await runTest() }
                    } label: {
                        Label(testing ? "Sende…" : "Test ausführen", systemImage: "play.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testing || testPrompt.isEmpty)
                    if !testAnswer.isEmpty {
                        Text(testAnswer)
                            .font(.callout)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Letzte Aufrufe").font(.headline)
                    ForEach(Array(logs.prefix(10))) { log in
                        HStack {
                            Text(log.kiFunction).font(.caption.monospaced())
                            Spacer()
                            Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Plattform-Agent")
        .task { await reload() }
    }

    private func statusPill(title: String, ok: Bool, okText: String, failText: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack {
                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(ok ? .green : .red)
                Text(ok ? okText : failText).font(.subheadline)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func runTest() async {
        testing = true; defer { testing = false }
        let res = await kiProvider.invokeLLM(prompt: testPrompt, context: "PlattformAgent.SelfTest")
        switch res {
        case .success(let v): testAnswer = (v as? String) ?? "(leer)"
        case .failure(let e): testAnswer = "Fehler: \(e.localizedDescription)"
        }
        await reload()
    }

    @MainActor
    private func reload() async {
        logs = (try? await cloudKit.fetch(KIUsageLog.self, limit: 20)) ?? []
    }
}

// MARK: - Views/Pages/RichterProfileView.swift

struct RichterProfileView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var profiles: [JudgeProfile] = []
    @State private var search = ""
    @State private var showNew = false

    private var filtered: [JudgeProfile] {
        guard !search.isEmpty else { return profiles }
        return profiles.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.gericht.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { p in
                NavigationLink {
                    JudgeDetailView(profile: p)
                } label: {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(p.name).font(.body.weight(.medium))
                            Spacer()
                            Text(p.kategorie.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(p.gericht).font(.caption).foregroundStyle(.secondary)
                        if let k = p.klaegerRate {
                            Text("Klägerquote: \(Int(k)) %").font(.caption2)
                        }
                    }
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle("Richter-Profile")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neu", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNew) {
            NewJudgeSheet { j in
                Task { _ = try? await cloudKit.save(j); await reload() }
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        profiles = (try? await cloudKit.fetch(JudgeProfile.self)) ?? []
    }
}

struct JudgeDetailView: View {
    let profile: JudgeProfile
    var body: some View {
        Form {
            Section("Stammdaten") {
                LabeledContent("Name", value: profile.name)
                LabeledContent("Kategorie", value: profile.kategorie.rawValue)
                LabeledContent("Gericht", value: profile.gericht)
                if let k = profile.kammer { LabeledContent("Kammer", value: k) }
                if let r = profile.rechtsgebiet { LabeledContent("Rechtsgebiet", value: r) }
                if let s = profile.stil { LabeledContent("Stil", value: s.rawValue) }
            }
            Section("Kennzahlen") {
                if let k = profile.klaegerRate { LabeledContent("Klägerquote", value: "\(Int(k)) %") }
                if let v = profile.vergleichRate { LabeledContent("Vergleichsrate", value: "\(Int(v)) %") }
                if let d = profile.durchschnittDauerMonate { LabeledContent("Ø Dauer", value: "\(Int(d)) Mon.") }
                if let u = profile.urteileGesamt { LabeledContent("Urteile", value: "\(Int(u))") }
            }
            if let n = profile.notizen, !n.isEmpty {
                Section("Notizen") { Text(n) }
            }
        }
        .navigationTitle(profile.name)
    }
}

struct NewJudgeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var gericht = ""
    @State private var kategorie: JudgeKategorie = .richter
    var onCreate: (JudgeProfile) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Gericht / Institution", text: $gericht)
                Picker("Kategorie", selection: $kategorie) {
                    ForEach(JudgeKategorie.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
            .navigationTitle("Neues Profil")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var p = JudgeProfile(name: name, gericht: gericht)
                        p.kategorie = kategorie
                        onCreate(p); dismiss()
                    }.disabled(name.isEmpty || gericht.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }
}

// MARK: - Views/Pages/StrategosScenarioDetailView.swift

private struct Unternehmenskontext: Codable {
    var branche: String = ""
    var umsatz: String = ""
    var mitarbeiter: String = ""
    var beschreibung: String = ""
    var schluesselRisiken: [String] = []
    var rechtsgebiet: String = ""
    var gegner: String = ""
    var ausgangslage: String = ""
}

private struct SzenarioOption: Identifiable, Codable {
    var id: String = UUID().uuidString
    var buchstabe: String    // A, B, C
    var titel: String = ""
    var beschreibung: String = ""
    var vorteile: [String] = []
    var nachteile: [String] = []
    var erfolgswahrscheinlichkeit: Double = 50
    var kosten: String = ""
    var zeitrahmen: String = ""
    var empfohlen: Bool = false
}

private struct Aktionsschritt: Identifiable, Codable {
    var id: String = UUID().uuidString
    var prioritaet: Int = 1   // 1=Hoch, 2=Mittel, 3=Niedrig
    var titel: String = ""
    var verantwortlich: String = ""
    var frist: String = ""
    var status: String = "offen"
    var notizen: String = ""
}

private struct StrategosEmpfehlung: Codable {
    var empfohleneOption: String = ""
    var begruendung: String = ""
    var risikobewertung: String = ""
    var naechsteSchritte: [String] = []
    var warnhinweise: [String] = []
    var erfolgsprognose: Double = 50
}

private struct SituationsAnalyseResult: Codable {
    var staerken: [String] = []
    var schwaechen: [String] = []
    var chancen: [String] = []
    var risiken: [String] = []
    var zusammenfassung: String = ""
    var kritischeFaktoren: [String] = []
}

// MARK: - Hauptansicht

struct StrategosScenarioDetailView: View {
    @Binding var scenario: StrategosScenario
    var onSave: (StrategosScenario) -> Void

    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var auth: AuthService

    @State private var currentStep: Int = 1
    @State private var kontext = Unternehmenskontext()
    @State private var situationsAnalyse: SituationsAnalyseResult?
    @State private var optionA = SzenarioOption(buchstabe: "A", titel: "Aggressive Strategie")
    @State private var optionB = SzenarioOption(buchstabe: "B", titel: "Moderate Strategie")
    @State private var optionC = SzenarioOption(buchstabe: "C", titel: "Konservative Strategie")
    @State private var aktionsplan: [Aktionsschritt] = []
    @State private var empfehlung: StrategosEmpfehlung?
    @State private var linkedCases: [Case] = []
    @State private var allCases: [Case] = []
    @State private var loading = false
    @State private var newRisiko = ""
    @State private var newSchritt = Aktionsschritt()

    private let stepTitles = [
        "Unternehmenskontext",
        "Situationsanalyse",
        "Szenario-Matrix",
        "Aktionsplan",
        "Strategos-Empfehlung",
        "LEXARA-Sync"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Step-Progressbar
            stepHeader

            Divider()

            // Aktiver Step-Inhalt
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch currentStep {
                    case 1: step1Kontext
                    case 2: step2Situationsanalyse
                    case 3: step3SzenarioMatrix
                    case 4: step4Aktionsplan
                    case 5: step5Empfehlung
                    case 6: step6LexaraSync
                    default: EmptyView()
                    }
                }
                .padding()
                .animation(.default, value: currentStep)
            }

            Divider()

            // Navigationsleiste
            stepFooter
        }
        .navigationTitle(scenario.title)
        .task {
            loadFromScenario()
            allCases = (try? await cloudKit.fetch(Case.self)) ?? []
        }
    }

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: 8) {
            // Schritt-Indikatoren
            HStack(spacing: 4) {
                ForEach(1...6, id: \.self) { s in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(stepCircleColor(s))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if s < currentStep {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(s)").font(.caption.weight(.bold))
                                        .foregroundStyle(s == currentStep ? .white : .secondary)
                                }
                            }
                        Text(stepTitles[s-1])
                            .font(.system(size: 9))
                            .foregroundStyle(s == currentStep ? .primary : .secondary)
                            .lineLimit(1)
                            .frame(width: 80, alignment: .center)
                    }
                    if s < 6 {
                        Rectangle()
                            .fill(s < currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .padding(.bottom, 20)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            // Aktueller Schritt-Titel
            Text("Schritt \(currentStep) von 6: \(stepTitles[currentStep-1])")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .background(.regularMaterial)
    }

    private func stepCircleColor(_ s: Int) -> Color {
        if s < currentStep { return .green }
        if s == currentStep { return .accentColor }
        return Color.gray.opacity(0.25)
    }

    // MARK: - Step Footer

    private var stepFooter: some View {
        HStack {
            if currentStep > 1 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    Label("Zurück", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            Text("\(Int(Double(currentStep-1)/5.0 * 100))%").font(.caption).foregroundStyle(.secondary)
            Spacer()
            if currentStep < 6 {
                Button {
                    saveToScenario()
                    withAnimation { currentStep += 1 }
                } label: {
                    Label("Weiter", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    saveToScenario()
                    onSave(scenario)
                } label: {
                    Label("Abschließen", systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Step 1: Unternehmenskontext

    private var step1Kontext: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Unternehmens- und Fallkontext",
                          sub: "Grundlegende Informationen für die Strategie-Analyse.")

            GroupBox("Basisdaten") {
                VStack(spacing: 10) {
                    labeledField("Branche / Rechtsgebiet", text: $kontext.branche)
                    labeledField("Jahresumsatz (optional)", text: $kontext.umsatz)
                    labeledField("Mitarbeiterzahl (optional)", text: $kontext.mitarbeiter)
                    labeledField("Rechtsgebiet", text: $kontext.rechtsgebiet)
                }
            }

            GroupBox("Ausgangslage") {
                VStack(spacing: 10) {
                    labeledField("Gegner / Gegenpartei", text: $kontext.gegner)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ausgangslage & Sachverhalt").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $kontext.ausgangslage)
                            .frame(minHeight: 100)
                            .padding(6)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unternehmensbeschreibung").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $kontext.beschreibung)
                            .frame(minHeight: 80)
                            .padding(6)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            GroupBox("Schlüssel-Risiken") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(kontext.schluesselRisiken.enumerated()), id: \.offset) { (i, r) in
                        HStack {
                            Label(r, systemImage: "exclamationmark.triangle")
                                .font(.subheadline)
                            Spacer()
                            Button { kontext.schluesselRisiken.remove(at: i) } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(6)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    }
                    HStack {
                        TextField("Risiko hinzufügen…", text: $newRisiko)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            let r = newRisiko.trimmingCharacters(in: .whitespaces)
                            if !r.isEmpty { kontext.schluesselRisiken.append(r); newRisiko = "" }
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Situationsanalyse

    private var step2Situationsanalyse: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Situationsanalyse (SWOT)",
                          sub: "KI analysiert Stärken, Schwächen, Chancen und Risiken.")

            Button {
                Task { await runSituationsanalyse() }
            } label: {
                Label(loading ? "Analysiere…" : "KI-Situationsanalyse starten",
                      systemImage: "brain.head.profile")
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading || kontext.ausgangslage.isEmpty)

            if kontext.ausgangslage.isEmpty {
                Label("Bitte zuerst die Ausgangslage in Schritt 1 ausfüllen.",
                      systemImage: "arrow.left.circle")
                    .font(.caption).foregroundStyle(.orange)
            }

            if let sa = situationsAnalyse {
                if !sa.zusammenfassung.isEmpty {
                    GroupBox("Zusammenfassung") {
                        Text(sa.zusammenfassung).font(.body)
                    }
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    swotCard("Stärken", items: sa.staerken, color: .green,
                             icon: "arrow.up.circle.fill")
                    swotCard("Schwächen", items: sa.schwaechen, color: .orange,
                             icon: "arrow.down.circle.fill")
                    swotCard("Chancen", items: sa.chancen, color: .blue,
                             icon: "lightbulb.fill")
                    swotCard("Risiken", items: sa.risiken, color: .red,
                             icon: "exclamationmark.triangle.fill")
                }
                if !sa.kritischeFaktoren.isEmpty {
                    GroupBox("Kritische Erfolgsfaktoren") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(sa.kritischeFaktoren, id: \.self) { f in
                                Label(f, systemImage: "star.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }
        }
    }

    private func swotCard(_ title: String, items: [String], color: Color, icon: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                if items.isEmpty {
                    Text("–").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(items, id: \.self) { item in
                        Text("• \(item)").font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Step 3: Szenario-Matrix

    private var step3SzenarioMatrix: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Szenario-Matrix",
                          sub: "Drei strategische Optionen mit KI-bewerteten Vor- und Nachteilen.")

            Button {
                Task { await runSzenarioMatrix() }
            } label: {
                Label(loading ? "Generiere…" : "KI-Szenario-Matrix generieren",
                      systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)

            ForEach([$optionA, $optionB, $optionC], id: \.buchstabe) { $opt in
                optionCard(opt: $opt)
            }
        }
    }

    private func optionCard(opt: Binding<SzenarioOption>) -> some View {
        let o = opt.wrappedValue
        return GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(o.buchstabe)
                        .font(.title2.weight(.black))
                        .frame(width: 36, height: 36)
                        .background(
                            o.buchstabe == "A" ? Color.red :
                            o.buchstabe == "B" ? Color.blue : Color.green,
                            in: Circle()
                        )
                        .foregroundStyle(.white)
                    VStack(alignment: .leading) {
                        TextField("Titel", text: opt.titel)
                            .font(.headline)
                        if o.empfohlen {
                            Label("Empfohlen", systemImage: "star.fill")
                                .font(.caption2).foregroundStyle(.yellow)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(Int(o.erfolgswahrscheinlichkeit))%")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(o.erfolgswahrscheinlichkeit >= 60 ? .green :
                                             o.erfolgswahrscheinlichkeit >= 40 ? .orange : .red)
                        Text("Erfolg").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                TextField("Beschreibung", text: opt.beschreibung, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 16) {
                    if !o.vorteile.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vorteile").font(.caption.weight(.bold)).foregroundStyle(.green)
                            ForEach(o.vorteile, id: \.self) {
                                Text("+ \($0)").font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !o.nachteile.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nachteile").font(.caption.weight(.bold)).foregroundStyle(.red)
                            ForEach(o.nachteile, id: \.self) {
                                Text("− \($0)").font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                HStack {
                    if !o.kosten.isEmpty {
                        Label(o.kosten, systemImage: "eurosign").font(.caption2)
                    }
                    if !o.zeitrahmen.isEmpty {
                        Label(o.zeitrahmen, systemImage: "clock").font(.caption2)
                    }
                }
            }
        }
    }

    // MARK: - Step 4: Aktionsplan

    private var step4Aktionsplan: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Aktionsplan",
                          sub: "Priorisierte Maßnahmen für die Umsetzung.")

            HStack {
                Button {
                    Task { await generateAktionsplan() }
                } label: {
                    Label(loading ? "Generiere…" : "KI-Aktionsplan", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .disabled(loading)

                Button {
                    aktionsplan.append(Aktionsschritt())
                } label: {
                    Label("Manuell", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if aktionsplan.isEmpty {
                ContentUnavailableView("Kein Aktionsplan",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Generiere einen KI-Aktionsplan oder füge Schritte manuell hinzu."))
            } else {
                ForEach($aktionsplan) { $s in
                    aktionsschrittRow(schritt: $s)
                }
            }
        }
    }

    private func aktionsschrittRow(schritt: Binding<Aktionsschritt>) -> some View {
        let s = schritt.wrappedValue
        return HStack(alignment: .top, spacing: 12) {
            // Prioritäts-Badge
            ZStack {
                Circle().fill(prioritaetColor(s.prioritaet))
                    .frame(width: 28, height: 28)
                Text("\(s.prioritaet)").font(.caption.weight(.bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                TextField("Maßnahme", text: schritt.titel)
                    .font(.subheadline.weight(.medium))
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Verantwortlich", text: schritt.verantwortlich)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    TextField("Frist", text: schritt.frist)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    Picker("Status", selection: schritt.status) {
                        ForEach(["offen","in Bearbeitung","erledigt"], id: \.self) { Text($0).tag($0) }
                    }
                    .font(.caption)
                    .pickerStyle(.menu)
                }
            }
            Spacer()
            Button {
                aktionsplan.removeAll { $0.id == s.id }
            } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func prioritaetColor(_ p: Int) -> Color {
        switch p {
        case 1: return .red
        case 2: return .orange
        default: return .gray
        }
    }

    // MARK: - Step 5: Strategos-Empfehlung

    private var step5Empfehlung: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Strategos-Empfehlung",
                          sub: "Finale KI-gestützte strategische Empfehlung.")

            Button {
                Task { await generateEmpfehlung() }
            } label: {
                Label(loading ? "Generiere…" : "Finale Empfehlung generieren",
                      systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)

            if let emp = empfehlung {
                // Empfohlene Option
                if !emp.empfohleneOption.isEmpty {
                    GroupBox {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Empfohlene Option").font(.caption).foregroundStyle(.secondary)
                                Text("Option \(emp.empfohleneOption)")
                                    .font(.title.weight(.bold)).foregroundStyle(.accentColor)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(Int(emp.erfolgsprognose))%")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.green)
                                Text("Erfolgsprognose").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Begründung
                if !emp.begruendung.isEmpty {
                    GroupBox("Begründung") {
                        Text(emp.begruendung).font(.body)
                    }
                }

                // Risikobewertung
                if !emp.risikobewertung.isEmpty {
                    GroupBox("Risikobewertung") {
                        Text(emp.risikobewertung).font(.subheadline)
                            .padding(8)
                            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Nächste Schritte
                if !emp.naechsteSchritte.isEmpty {
                    GroupBox("Nächste Schritte") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(emp.naechsteSchritte.enumerated()), id: \.offset) { (i, s) in
                                HStack(alignment: .top) {
                                    Text("\(i+1).")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.accentColor)
                                    Text(s).font(.subheadline)
                                }
                            }
                        }
                    }
                }

                // Warnhinweise
                if !emp.warnhinweise.isEmpty {
                    GroupBox("Warnhinweise") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(emp.warnhinweise, id: \.self) { w in
                                Label(w, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                }
            } else {
                Text("Generiere die finale Strategos-Empfehlung um alle vorherigen Schritte zusammenzufassen.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Step 6: LEXARA-Sync

    private var step6LexaraSync: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("LEXARA-Sync",
                          sub: "Verknüpfe dieses Szenario mit konkreten Falldateien in LEXARA.")

            GroupBox("Zusammenfassung") {
                VStack(alignment: .leading, spacing: 6) {
                    infoRow2("Szenario", scenario.title)
                    infoRow2("Typ", scenario.szenarioTyp.label)
                    infoRow2("Status", scenario.status.rawValue)
                    if let emp = empfehlung, !emp.empfohleneOption.isEmpty {
                        infoRow2("Empfehlung", "Option \(emp.empfohleneOption) (\(Int(emp.erfolgsprognose))%)")
                    }
                    infoRow2("Aktionsschritte", "\(aktionsplan.count)")
                }
            }

            if allCases.isEmpty {
                Text("Keine Fälle vorhanden. Lege erst Fälle in LEXARA an.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                GroupBox("Mit Fällen verknüpfen") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(allCases) { c in
                            let linked = linkedCases.contains(where: { $0.id == c.id })
                            HStack {
                                Image(systemName: linked
                                    ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(linked ? .green : .secondary)
                                VStack(alignment: .leading) {
                                    Text(c.fallname).font(.subheadline)
                                    Text(c.rechtsgebiet ?? c.status.rawValue)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let p = c.prognose {
                                    Text("\(Int(p))%").font(.caption)
                                        .foregroundStyle(p >= 60 ? .green : .orange)
                                }
                            }
                            .padding(8)
                            .background(linked ? Color.green.opacity(0.06) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if linked {
                                    linkedCases.removeAll { $0.id == c.id }
                                } else {
                                    linkedCases.append(c)
                                }
                            }
                        }
                    }
                }
            }

            if !linkedCases.isEmpty {
                Label("\(linkedCases.count) Fall/Fälle verknüpft", systemImage: "link")
                    .font(.caption).foregroundStyle(.green)
            }

            GroupBox("Export") {
                HStack(spacing: 12) {
                    Button {
                        exportPDF()
                    } label: {
                        Label("PDF exportieren", systemImage: "arrow.down.doc.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func infoRow2(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary).frame(width: 120, alignment: .leading)
            Text(value).font(.subheadline)
            Spacer()
        }
        .font(.subheadline)
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.weight(.semibold))
            Text(sub).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: text).textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Daten laden / speichern

    private func loadFromScenario() {
        currentStep = max(1, scenario.enterpriseStep)
        if let data = scenario.unternehmenskontextJSON?.data(using: .utf8),
           let k = try? JSONDecoder().decode(Unternehmenskontext.self, from: data) {
            kontext = k
        }
        if let data = scenario.situationsanalyseJSON?.data(using: .utf8),
           let sa = try? JSONDecoder().decode(SituationsAnalyseResult.self, from: data) {
            situationsAnalyse = sa
        }
        if let data = scenario.szenarioMatrixJSON?.data(using: .utf8),
           let opts = try? JSONDecoder().decode([SzenarioOption].self, from: data) {
            for opt in opts {
                if opt.buchstabe == "A" { optionA = opt }
                else if opt.buchstabe == "B" { optionB = opt }
                else if opt.buchstabe == "C" { optionC = opt }
            }
        }
        if let data = scenario.aktionsplanJSON?.data(using: .utf8),
           let plan = try? JSONDecoder().decode([Aktionsschritt].self, from: data) {
            aktionsplan = plan
        }
        if let data = scenario.strategosEmpfehlungJSON?.data(using: .utf8),
           let emp = try? JSONDecoder().decode(StrategosEmpfehlung.self, from: data) {
            empfehlung = emp
        }
    }

    private func saveToScenario() {
        scenario.enterpriseStep = currentStep
        scenario.ausgangslage = kontext.ausgangslage
        scenario.fragestellung = kontext.beschreibung
        if let data = try? JSONEncoder().encode(kontext) {
            scenario.unternehmenskontextJSON = String(data: data, encoding: .utf8)
        }
        if let sa = situationsAnalyse,
           let data = try? JSONEncoder().encode(sa) {
            scenario.situationsanalyseJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode([optionA, optionB, optionC]) {
            scenario.szenarioMatrixJSON = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(aktionsplan) {
            scenario.aktionsplanJSON = String(data: data, encoding: .utf8)
        }
        if let emp = empfehlung,
           let data = try? JSONEncoder().encode(emp) {
            scenario.strategosEmpfehlungJSON = String(data: data, encoding: .utf8)
        }
        if !linkedCases.isEmpty,
           let data = try? JSONEncoder().encode(linkedCases.map { $0.id }) {
            scenario.lexaraSyncJSON = String(data: data, encoding: .utf8)
        }
    }

    // MARK: - KI-Operationen

    @MainActor
    private func runSituationsanalyse() async {
        loading = true; defer { loading = false }
        let prompt = """
        Führe eine professionelle SWOT-Analyse für folgenden Rechtsfall durch:
        Branche/Rechtsgebiet: \(kontext.branche), Ausgangslage: \(kontext.ausgangslage)
        Gegner: \(kontext.gegner), Risiken: \(kontext.schluesselRisiken.joined(separator: ", "))

        Gib JSON zurück: { staerken: [string], schwaechen: [string], chancen: [string], risiken: [string],
        zusammenfassung: string, kritischeFaktoren: [string] }
        """
        let schema: [String: Any] = ["type": "object", "properties": [
            "staerken": ["type": "array"], "schwaechen": ["type": "array"],
            "chancen": ["type": "array"], "risiken": ["type": "array"],
            "zusammenfassung": ["type": "string"], "kritischeFaktoren": ["type": "array"]
        ]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.SWOT")
        guard case .success(let any) = res, let d = any as? [String: Any] else { return }
        situationsAnalyse = SituationsAnalyseResult(
            staerken: d["staerken"] as? [String] ?? [],
            schwaechen: d["schwaechen"] as? [String] ?? [],
            chancen: d["chancen"] as? [String] ?? [],
            risiken: d["risiken"] as? [String] ?? [],
            zusammenfassung: d["zusammenfassung"] as? String ?? "",
            kritischeFaktoren: d["kritischeFaktoren"] as? [String] ?? []
        )
    }

    @MainActor
    private func runSzenarioMatrix() async {
        loading = true; defer { loading = false }
        let prompt = """
        Erstelle eine Szenario-Matrix mit 3 strategischen Optionen (A=aggressiv, B=moderat, C=konservativ) für:
        Fall: \(scenario.title), Rechtsgebiet: \(kontext.branche)
        Ausgangslage: \(kontext.ausgangslage)
        Gegner: \(kontext.gegner)
        SWOT: Stärken \(situationsAnalyse?.staerken.prefix(3).joined(separator: ", ") ?? "")

        JSON-Antwort: { optionen: [{ buchstabe: "A"|"B"|"C", titel, beschreibung, vorteile: [string],
        nachteile: [string], erfolgswahrscheinlichkeit: number, kosten: string, zeitrahmen: string,
        empfohlen: bool }] }
        """
        let schema: [String: Any] = ["type": "object", "properties": ["optionen": ["type": "array"]]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.Matrix")
        guard case .success(let any) = res,
              let d = any as? [String: Any],
              let opts = d["optionen"] as? [[String: Any]] else { return }
        for opt in opts {
            guard let b = opt["buchstabe"] as? String else { continue }
            var o = SzenarioOption(buchstabe: b)
            o.titel = opt["titel"] as? String ?? ""
            o.beschreibung = opt["beschreibung"] as? String ?? ""
            o.vorteile = opt["vorteile"] as? [String] ?? []
            o.nachteile = opt["nachteile"] as? [String] ?? []
            o.erfolgswahrscheinlichkeit = opt["erfolgswahrscheinlichkeit"] as? Double ?? 50
            o.kosten = opt["kosten"] as? String ?? ""
            o.zeitrahmen = opt["zeitrahmen"] as? String ?? ""
            o.empfohlen = opt["empfohlen"] as? Bool ?? false
            if b == "A" { optionA = o }
            else if b == "B" { optionB = o }
            else if b == "C" { optionC = o }
        }
    }

    @MainActor
    private func generateAktionsplan() async {
        loading = true; defer { loading = false }
        let empfOpt = empfehlung?.empfohleneOption ?? "B"
        let prompt = """
        Erstelle einen priorisierten Aktionsplan für die Umsetzung von Strategie-Option \(empfOpt).
        Fall: \(scenario.title), Rechtsgebiet: \(kontext.branche)
        Ausgangslage: \(kontext.ausgangslage)

        JSON: { schritte: [{ prioritaet: 1|2|3, titel: string, verantwortlich: string,
        frist: string, status: "offen", notizen: string }] }
        Maximal 8 Schritte, sortiert nach Priorität.
        """
        let schema: [String: Any] = ["type": "object", "properties": ["schritte": ["type": "array"]]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.Aktionsplan")
        guard case .success(let any) = res,
              let d = any as? [String: Any],
              let schritte = d["schritte"] as? [[String: Any]] else { return }
        aktionsplan = schritte.map { s in
            var schritt = Aktionsschritt()
            schritt.prioritaet = s["prioritaet"] as? Int ?? 2
            schritt.titel = s["titel"] as? String ?? ""
            schritt.verantwortlich = s["verantwortlich"] as? String ?? ""
            schritt.frist = s["frist"] as? String ?? ""
            schritt.status = s["status"] as? String ?? "offen"
            schritt.notizen = s["notizen"] as? String ?? ""
            return schritt
        }
    }

    @MainActor
    private func generateEmpfehlung() async {
        loading = true; defer { loading = false }
        let optionen = [optionA, optionB, optionC].map {
            "Option \($0.buchstabe): \($0.titel) – Erfolg \(Int($0.erfolgswahrscheinlichkeit))%"
        }.joined(separator: "\n")
        let prompt = """
        Erstelle eine finale strategische Empfehlung für:
        Szenario: \(scenario.title)
        Optionen:
        \(optionen)
        Aktionsschritte: \(aktionsplan.count) geplant
        Ausgangslage: \(kontext.ausgangslage)
        Gegner: \(kontext.gegner)

        JSON: { empfohleneOption: "A"|"B"|"C", begruendung: string, risikobewertung: string,
        naechsteSchritte: [string], warnhinweise: [string], erfolgsprognose: number }
        """
        let schema: [String: Any] = ["type": "object", "properties": [
            "empfohleneOption": ["type": "string"],
            "begruendung": ["type": "string"],
            "risikobewertung": ["type": "string"],
            "naechsteSchritte": ["type": "array"],
            "warnhinweise": ["type": "array"],
            "erfolgsprognose": ["type": "number"]
        ]]
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "Strategos.Empfehlung")
        guard case .success(let any) = res, let d = any as? [String: Any] else { return }
        empfehlung = StrategosEmpfehlung(
            empfohleneOption: d["empfohleneOption"] as? String ?? "",
            begruendung: d["begruendung"] as? String ?? "",
            risikobewertung: d["risikobewertung"] as? String ?? "",
            naechsteSchritte: d["naechsteSchritte"] as? [String] ?? [],
            warnhinweise: d["warnhinweise"] as? [String] ?? [],
            erfolgsprognose: d["erfolgsprognose"] as? Double ?? 50
        )
    }

    private func exportPDF() {
        // PDF-Export via GegnerVerhaltenPDFExportService analog
        // (In production: collect data and export to PDF)
    }
}

// MARK: - Views/Pages/StrategosView.swift

struct StrategosView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var scenarios: [StrategosScenario] = []
    @State private var loopholes: [LegalLoophole] = []
    @State private var cases: [Case] = []
    @State private var selectedScenario: StrategosScenario?
    @State private var showNew = false
    @State private var contractText: String = ""
    @State private var impacts: [StrategosImpact] = []
    @State private var analyzing = false
    @State private var selectedCaseForGegner: String?
    @State private var gegnerItems: [GegnerVerhalten] = []
    @State private var activeTab: StrategosTab = .szenarien

    enum StrategosTab: String, CaseIterable {
        case szenarien    = "Szenarien"
        case vertragsanalyse = "Vertragsanalyse"
        case gegnerverhalten = "Gegnerverhalten"
        case hebel        = "Hebel & Lücken"

        var icon: String {
            switch self {
            case .szenarien:      return "square.grid.2x2"
            case .vertragsanalyse: return "doc.text.magnifyingglass"
            case .gegnerverhalten: return "shield.lefthalf.filled"
            case .hebel:          return "key.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Interner Tab-Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(StrategosTab.allCases, id: \.self) { t in
                        Button { activeTab = t } label: {
                            Label(t.rawValue, systemImage: t.icon)
                                .font(.caption)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(activeTab == t
                                    ? Color.accentColor.opacity(0.15) : .clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(activeTab == t ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
            }
            Divider()

            // Inhalt
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch activeTab {
                    case .szenarien:       szenarienTab
                    case .vertragsanalyse: vertragsanalyseTab
                    case .gegnerverhalten: gegnerVerhaltenTab
                    case .hebel:           hebelTab
                    }
                }
                .padding()
                .animation(.default, value: activeTab)
            }
        }
        .navigationTitle("Strategos")
        .navigationDestination(for: StrategosScenario.self) { s in
            scenarioDetailDestination(for: s)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNew = true } label: { Label("Neues Szenario", systemImage: "plus") }
            }
        }
        .task { await reload() }
        .sheet(isPresented: $showNew) {
            NewScenarioSheet { s in
                Task { _ = try? await cloudKit.save(s); await reload() }
            }
        }
    }

    // MARK: - Szenarien Tab

    private var szenarienTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Strategos").font(.title.weight(.semibold))
                Text("Szenario-Planung, Vertragsanalyse und identifizierte Hebel.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            if scenarios.isEmpty {
                ContentUnavailableView(
                    "Noch keine Szenarien",
                    systemImage: "square.grid.2x2",
                    description: Text("Erstelle ein Szenario für die 6-stufige Enterprise-Analyse."))
                    .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                    ForEach(scenarios) { s in
                        NavigationLink(value: s) {
                            scenarioCard(s)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func scenarioCard(_ s: StrategosScenario) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.szenarioTyp.label.uppercased())
                        .font(.caption2).foregroundStyle(.secondary)
                    Text(s.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                }
                Spacer()
                // Status-Badge
                Text(s.status.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(statusColor(s.status).opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor(s.status))
            }

            // Schritt-Fortschritt
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(1...6, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(step <= s.enterpriseStep
                                ? Color.accentColor
                                : Color.gray.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                Text("Schritt \(s.enterpriseStep) / 6 · \(Int(Double(s.enterpriseStep-1)/5.0 * 100))% abgeschlossen")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            // Rechtsgebiet
            if let rg = s.rechtsgebiet {
                Label(rg, systemImage: "folder").font(.caption2).foregroundStyle(.secondary)
            }

            // Weiter-Pfeil
            HStack {
                Spacer()
                Label("Öffnen", systemImage: "chevron.right")
                    .font(.caption).foregroundStyle(.accentColor)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statusColor(_ s: SzenarioStatus) -> Color {
        switch s {
        case .entwurf:    return .gray
        case .analyse:    return .blue
        case .ergebnis:   return .green
        case .archiviert: return .orange
        }
    }

    @ViewBuilder
    private func scenarioDetailDestination(for s: StrategosScenario) -> some View {
        // Wrap in Binding to allow wizard saves to propagate
        let idx = scenarios.firstIndex(where: { $0.id == s.id })
        if let idx {
            StrategosScenarioDetailView(
                scenario: Binding(
                    get: { scenarios[idx] },
                    set: { scenarios[idx] = $0 }
                ),
                onSave: { updated in
                    Task {
                        _ = try? await cloudKit.save(updated)
                        await reload()
                    }
                }
            )
        } else {
            // Fallback für direkte Navigation (z.B. über NavigationStack)
            let bound = Binding.constant(s)
            StrategosScenarioDetailView(scenario: bound, onSave: { updated in
                Task { _ = try? await cloudKit.save(updated); await reload() }
            })
        }
    }

    // MARK: - Vertragsanalyse Tab

    private var vertragsanalyseTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Vertragsklauseln analysieren").font(.title2.weight(.semibold))
                Text("Füge eine Klausel ein. Strategos analysiert kurz-, mittel- und langfristige Auswirkungen auf alle Abteilungen.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            TextEditor(text: $contractText)
                .frame(minHeight: 160)
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2))
                )
            if contractText.isEmpty {
                Text("Beispiel: „Der Auftragnehmer verpflichtet sich, Schadensersatz bis zum dreifachen Auftragswert zu leisten."")
                    .font(.caption2).foregroundStyle(.secondary.opacity(0.7))
            }
            HStack {
                Spacer()
                Button {
                    Task { await analyzeContract() }
                } label: {
                    Label(analyzing ? "Analysiere…" : "Analyse starten", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(contractText.trimmingCharacters(in: .whitespaces).isEmpty || analyzing)
            }

            if !impacts.isEmpty {
                impactSection
            }
        }
    }

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("Auswirkungen nach Zeithorizont & Abteilung")
                .font(.headline)
            ForEach(StrategosHorizont.allCases, id: \.self) { h in
                let group = impacts.filter { $0.horizont == h }
                if !group.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(h.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(group.count) Abteilungen betroffen")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                            ForEach(group) { i in impactCard(i) }
                        }
                    }
                }
            }
        }
    }

    private func impactCard(_ i: StrategosImpact) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(i.abteilung).font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.0f/10", i.schwere))
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(severityColor(i.schwere).opacity(0.15), in: Capsule())
                    .foregroundStyle(severityColor(i.schwere))
            }
            ProgressView(value: i.schwere / 10).tint(severityColor(i.schwere))
            Text(i.beschreibung).font(.caption).foregroundStyle(.secondary).lineLimit(3)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func severityColor(_ s: Double) -> Color {
        if s >= 7 { return .red }
        if s >= 4 { return .orange }
        return .green
    }

    // MARK: - Gegnerverhalten Tab

    private var gegnerVerhaltenTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gegnerverhalten").font(.title2.weight(.semibold))
                Text("Taktiken, Reaktionsmuster und Verhaltensanalyse der Gegenseite – fallübergreifend.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            // Case-Picker
            if cases.isEmpty {
                Label("Keine Fälle vorhanden. Lege zuerst Fälle in LEXARA an.",
                      systemImage: "folder.badge.plus")
                    .font(.caption).foregroundStyle(.orange)
            } else {
                HStack {
                    Text("Fall auswählen:").font(.caption).foregroundStyle(.secondary)
                    Picker("Fall", selection: $selectedCaseForGegner) {
                        Text("– Bitte wählen –").tag(String?.none)
                        ForEach(cases) { c in
                            Text(c.fallname).tag(Optional(c.id))
                        }
                    }
                    .onChange(of: selectedCaseForGegner) { _, id in
                        Task { await loadGegner(caseId: id) }
                    }
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }

            if let caseId = selectedCaseForGegner,
               let c = cases.first(where: { $0.id == caseId }) {
                GegnerVerhaltenTabView(caseId: caseId, caseEntity: c)
            } else {
                Text("Wähle einen Fall um das Gegnerverhalten anzuzeigen.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Hebel Tab

    private var hebelTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Identifizierte Hebel & Schlupflöcher").font(.title2.weight(.semibold))
                Text("Gesetzliche Lücken und strategische Hebel die genutzt werden können.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            if loopholes.isEmpty {
                ContentUnavailableView("Keine Hebel hinterlegt",
                    systemImage: "key.slash",
                    description: Text("Hinterlege strategische Hebel und Gesetzeslücken."))
                    .padding(.vertical, 40)
            } else {
                ForEach(loopholes) { l in
                    loopholeCard(l)
                }
            }
        }
    }

    private func loopholeCard(_ l: LegalLoophole) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(l.gesetz) \(l.paragraph ?? "")")
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5))
                Text(l.aktiv ? "Aktiv" : "Geschlossen")
                    .font(.caption2)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background((l.aktiv ? Color.green : Color.gray).opacity(0.15), in: Capsule())
                    .foregroundStyle(l.aktiv ? .green : .secondary)
                Spacer()
                if let rg = l.rechtsgebiet {
                    Text(rg).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(l.titel).font(.subheadline.weight(.semibold))
            Text(l.beschreibung).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            if let strat = l.gegenstrategien {
                Label(strat, systemImage: "lightbulb.fill")
                    .font(.caption).foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Logik

    @MainActor
    private func reload() async {
        scenarios = (try? await cloudKit.fetch(StrategosScenario.self)) ?? []
        loopholes = (try? await cloudKit.fetch(LegalLoophole.self)) ?? []
        cases     = (try? await cloudKit.fetch(Case.self)) ?? []
    }

    @MainActor
    private func loadGegner(caseId: String?) async {
        guard let caseId else { gegnerItems = []; return }
        let pred = NSPredicate(format: "case_id == %@", caseId)
        gegnerItems = (try? await cloudKit.fetch(GegnerVerhalten.self, predicate: pred)) ?? []
    }

    @MainActor
    private func analyzeContract() async {
        analyzing = true
        defer { analyzing = false }
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "impacts": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "abteilung":    ["type": "string"],
                            "horizont":     ["type": "string",
                                             "enum": ["Kurzfristig","Mittelfristig","Langfristig"]],
                            "beschreibung": ["type": "string"],
                            "schwere":      ["type": "number"]
                        ],
                        "required": ["abteilung","horizont","beschreibung","schwere"]
                    ]
                ]
            ],
            "required": ["impacts"]
        ]
        let prompt = """
        Analysiere die folgende Vertragsklausel auf Auswirkungen für jede betroffene Abteilung \
        (Finanzen, Recht, HR, IT, Vertrieb, Compliance, Geschäftsführung). Lege je Abteilung \
        bis zu drei Auswirkungen in den Horizonten Kurzfristig (0-6 Monate), Mittelfristig \
        (6-24 Monate), Langfristig (>24 Monate) an. Schwere skaliert 0..10.

        KLAUSEL:
        \(contractText)
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema,
                                              context: "Strategos.Vertragsanalyse")
        switch res {
        case .success(let value):
            guard let dict = value as? [String: Any],
                  let arr = dict["impacts"] as? [[String: Any]] else { return }
            impacts = arr.compactMap { raw in
                guard let ab = raw["abteilung"] as? String,
                      let hRaw = raw["horizont"] as? String,
                      let h = StrategosHorizont(rawValue: hRaw),
                      let b = raw["beschreibung"] as? String,
                      let s = raw["schwere"] as? Double else { return nil }
                return StrategosImpact(abteilung: ab, horizont: h, beschreibung: b, schwere: s)
            }
        case .failure:
            impacts = []
        }
    }
}

// MARK: - Neues Szenario Sheet

struct NewScenarioSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var typ: SzenarioTyp = .sonstiges
    @State private var rechtsgebiet = ""
    var onCreate: (StrategosScenario) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Grunddaten") {
                    TextField("Titel *", text: $title)
                    Picker("Typ", selection: $typ) {
                        ForEach(SzenarioTyp.allCases, id: \.self) {
                            Text($0.label).tag($0)
                        }
                    }
                    TextField("Rechtsgebiet (optional)", text: $rechtsgebiet)
                }
                Section {
                    Text("Nach dem Anlegen öffnet sich der 6-stufige Enterprise-Wizard.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Neues Szenario")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        var s = StrategosScenario(title: title)
                        s.szenarioTyp = typ
                        s.rechtsgebiet = rechtsgebiet.isEmpty ? nil : rechtsgebiet
                        onCreate(s)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Views/Pages/SunTzuMachiavelView.swift

struct SunTzuMaxim: Identifiable, Hashable {
    let id = UUID()
    let author: Author
    let title: String
    let original: String
    let anwendung: String
    enum Author: String { case sunTzu = "Sun Tzu", machiavelli = "Machiavelli" }
}

struct SunTzuMachiavelView: View {
    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var cases: [Case] = []
    @State private var selectedCaseId: String?
    @State private var maxims: [SunTzuMaxim] = Self.defaultMaxims
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                casePicker
                Button {
                    Task { await generateAdvice() }
                } label: {
                    Label(loading ? "Strategien werden generiert…" : "Strategien für gewählten Fall ableiten",
                          systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(loading || selectedCaseId == nil)

                Divider()

                ForEach([SunTzuMaxim.Author.sunTzu, .machiavelli], id: \.self) { author in
                    Text(author.rawValue).font(.title2.weight(.semibold))
                    ForEach(maxims.filter { $0.author == author }) { m in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(m.title).font(.subheadline.weight(.semibold))
                            Text(m.original).italic().font(.caption).foregroundStyle(.secondary)
                            Text(m.anwendung).font(.caption)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Sun Tzu / Machiavelli")
        .task { cases = (try? await cloudKit.fetch(Case.self)) ?? [] }
    }

    private var header: some View {
        Text("Klassische Strategie-Maximen, übersetzt in juristische Handlungsempfehlungen.")
            .font(.subheadline).foregroundStyle(.secondary)
    }

    private var casePicker: some View {
        Picker("Fall", selection: $selectedCaseId) {
            Text("Fall auswählen").tag(String?.none)
            ForEach(cases) { c in Text(c.fallname).tag(Optional(c.id)) }
        }
    }

    @MainActor
    private func generateAdvice() async {
        guard let id = selectedCaseId,
              let c = cases.first(where: { $0.id == id }) else { return }
        loading = true; defer { loading = false }
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "maximen": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "author": ["type": "string", "enum": ["Sun Tzu", "Machiavelli"]],
                            "title": ["type": "string"],
                            "original": ["type": "string"],
                            "anwendung": ["type": "string"]
                        ],
                        "required": ["author","title","original","anwendung"]
                    ]
                ]
            ],
            "required": ["maximen"]
        ]
        let prompt = """
        Erzeuge 6 Strategie-Maximen (3 Sun Tzu, 3 Machiavelli), die auf folgenden Fall angewandt werden:
        - Fall: \(c.fallname)
        - Gericht: \(c.gericht ?? "–")
        - Rechtsgebiet: \(c.rechtsgebiet ?? "–")
        - Prozessziel: \(c.prozessziel ?? "–")
        Jede Maxime mit Original-Zitat (kurz) und konkreter, anwaltlicher Anwendung (max. 2 Sätze).
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "SunTzuMachiavel", caseId: id)
        guard case .success(let v) = res,
              let dict = v as? [String: Any],
              let arr  = dict["maximen"] as? [[String: Any]] else { return }
        maxims = arr.compactMap { raw in
            guard let a = raw["author"] as? String,
                  let t = raw["title"] as? String,
                  let o = raw["original"] as? String,
                  let an = raw["anwendung"] as? String else { return nil }
            let author: SunTzuMaxim.Author = (a == "Machiavelli") ? .machiavelli : .sunTzu
            return SunTzuMaxim(author: author, title: t, original: o, anwendung: an)
        }
    }

    static let defaultMaxims: [SunTzuMaxim] = [
        .init(author: .sunTzu, title: "Kenne deinen Gegner",
              original: "Wenn du den Feind kennst und dich selbst kennst, brauchst du das Ergebnis von hundert Schlachten nicht zu fürchten.",
              anwendung: "Analysiere Vorprozesse und Strategie-Muster des Gegenanwalts vor jedem Termin."),
        .init(author: .sunTzu, title: "Indirekter Angriff",
              original: "Der höchste Sieg ist, ohne Kampf zu siegen.",
              anwendung: "Versuche zuerst tragfähige Vergleichsangebote, bevor du in die Hauptverhandlung gehst."),
        .init(author: .machiavelli, title: "Macht & Wahrnehmung",
              original: "Es genügt nicht, mächtig zu sein, man muss auch so wirken.",
              anwendung: "Klares, präzises Auftreten in jeder Eingabe – Form ist Substanz.")
    ]
}

// MARK: - Views/Pages/ZeitleisteView.swift

struct ZeitleisteView: View {
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var events: [TimelineEvent] = []
    @State private var deadlines: [Deadline] = []
    @State private var loading = false

    private var combined: [(date: Date, title: String, kind: String, color: Color)] {
        let e = events.map { (date: $0.date, title: $0.title, kind: $0.category.rawValue, color: Color.blue) }
        let d = deadlines.map { (date: $0.dueDate, title: $0.title, kind: "Frist", color: Color.orange) }
        return (e + d).sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if loading && combined.isEmpty {
                    ProgressView().padding()
                } else if combined.isEmpty {
                    ContentUnavailableView("Keine Ereignisse",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Noch keine Zeitleisten-Einträge oder Fristen vorhanden."))
                        .padding(.top, 60)
                } else {
                    ForEach(Array(combined.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 12) {
                            VStack {
                                Circle().fill(item.color).frame(width: 10, height: 10)
                                Rectangle().fill(.secondary.opacity(0.3)).frame(width: 2)
                            }
                            .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(item.title).font(.body.weight(.medium))
                                Text(item.kind).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Zeitleiste")
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        loading = true; defer { loading = false }
        events    = (try? await cloudKit.fetch(TimelineEvent.self)) ?? []
        deadlines = (try? await cloudKit.fetch(Deadline.self)) ?? []
    }
}

// MARK: - Views/AIExplanationView.swift

struct AIExplanationView<Content: View>: View {
    let title: String
    let explanation: String
    var formula: String? = nil
    var inline: Bool = false
    @ViewBuilder var content: () -> Content

    @State private var open = false

    init(title: String,
         explanation: String,
         formula: String? = nil,
         inline: Bool = false,
         @ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.title = title
        self.explanation = explanation
        self.formula = formula
        self.inline = inline
        self.content = content
    }

    var body: some View {
        if inline {
            HStack(alignment: .top, spacing: 8) {
                content()
                Button {
                    open.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(title)
                .popover(isPresented: $open) {
                    detailsBody
                        .padding(12)
                        .frame(width: 280)
                }
            }
        } else {
            DisclosureGroup(isExpanded: $open) {
                detailsBody
                    .padding(.top, 6)
            } label: {
                Label(title, systemImage: "info.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private var detailsBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let formula {
                Text(formula)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(8)
                    .background(.thinMaterial,
                                in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

// MARK: - Views/FeedbackWidgetView.swift

struct FeedbackWidgetView: View {
    @EnvironmentObject var cloudKit: CloudKitService

    let jurisdiction: String
    var topic: String? = nil
    var context: String? = nil
    var language: String = "DE"

    @State private var vote: Vote? = nil
    @State private var comment: String = ""
    @State private var submitted: Bool = false
    @State private var submitting: Bool = false

    enum Vote: String { case up, down }

    private var labels: (title: String, placeholder: String, send: String, thanks: String) {
        switch language {
        case "EN": return ("Was this analysis helpful?",
                           "Optional comment (max. 300 chars)…",
                           "Submit",
                           "Thank you for your feedback!")
        case "FR": return ("Cette analyse était-elle utile?",
                           "Commentaire optionnel (max. 300 caractères)…",
                           "Envoyer",
                           "Merci pour votre retour!")
        default:   return ("War diese Analyse hilfreich?",
                           "Optionaler Kommentar (max. 300 Zeichen)…",
                           "Senden",
                           "Danke für Ihr Feedback!")
        }
    }

    var body: some View {
        if submitted {
            Label(labels.thanks, systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.caption.weight(.medium))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                Text(labels.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button {
                        vote = .up
                    } label: {
                        Label("Ja", systemImage: "hand.thumbsup")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(vote == .up ? .green : .secondary)

                    Button {
                        vote = .down
                    } label: {
                        Label("Nein", systemImage: "hand.thumbsdown")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(vote == .down ? .red : .secondary)
                }

                if vote != nil {
                    HStack {
                        TextField(labels.placeholder, text: $comment)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: comment) { _, newValue in
                                if newValue.count > 300 {
                                    comment = String(newValue.prefix(300))
                                }
                            }
                        Button {
                            Task { await submit() }
                        } label: {
                            Label(labels.send, systemImage: "paperplane.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(submitting)
                    }
                }
            }
        }
    }

    @MainActor
    private func submit() async {
        guard let vote else { return }
        submitting = true
        defer { submitting = false }

        var parts: [String] = ["Vote: \(vote == .up ? "positive" : "negative")"]
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty {
            parts.append("Comment: \(String(trimmedComment.prefix(300)))")
        }
        if let ctx = context, !ctx.isEmpty {
            parts.append("Context: \(String(ctx.prefix(500)))")
        }

        var insight = JurisdictionInsight(
            jurisdiction: jurisdiction,
            topic: topic ?? "ai_analysis_feedback",
            insightText: parts.joined(separator: " | ")
        )
        insight.sourceType = "argumentation_pattern"
        insight.usageCount = 1
        insight.effectivenessScore = vote == .up ? 8 : 3
        insight.tags = ["feedback", vote == .up ? "positive" : "negative", jurisdiction]
        _ = try? await cloudKit.save(insight)
        submitted = true
    }
}

// MARK: - Views/FooterView.swift

struct FooterView: View {
    var body: some View {
        EmptyView()
    }
}

// MARK: - Views/JurisdictionToggleView.swift

struct JurisdictionToggleView: View {
    @EnvironmentObject var auth: AuthService
    var dark: Bool = false

    var body: some View {
        if let user = auth.currentUser {
            Picker("Rechtsordnung", selection: Binding<Jurisdiction>(
                get: { user.jurisdiction },
                set: { newValue in
                    var u = user
                    u.jurisdiction = newValue
                    Task { await auth.updateProfile(u) }
                }
            )) {
                ForEach(Jurisdiction.allCases, id: \.self) { j in
                    Text(j.rawValue).tag(j)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 360)
            .opacity(dark ? 0.9 : 1)
        }
    }
}

// MARK: - Views/KIPaymentGateView.swift

struct KIPaymentGateView<Content: View>: View {
    let kiCredits: Int
    var onCreditUsed: () -> Void
    @ViewBuilder var content: () -> Content
    @EnvironmentObject var auth: AuthService

    @State private var loading = false

    private var language: String { auth.currentUser?.language.uppercased() ?? "DE" }

    private var labels: (title: String, sub: String, price: String, btn: String,
                         use: String, credits: (Int) -> String) {
        switch language {
        case "EN": return ("AI Function",
                           "This AI analysis costs 1 credit per use.",
                           "$1.99 / use",
                           "Buy credit & run",
                           "Use credit",
                           { n in "You have \(n) credit\(n != 1 ? "s" : "")" })
        case "FR": return ("Fonction IA",
                           "Cette analyse IA coûte 1 crédit par utilisation.",
                           "1,99 $ / utilisation",
                           "Acheter un crédit et lancer",
                           "Utiliser un crédit",
                           { n in "Vous avez \(n) crédit\(n != 1 ? "s" : "")" })
        default:   return ("KI-Funktion",
                           "Diese KI-Analyse kostet 1 Credit pro Nutzung.",
                           "1,99 $ / Nutzung",
                           "Credit kaufen & ausführen",
                           "Credit verwenden",
                           { n in "Du hast \(n) Credit\(n != 1 ? "s" : "")" })
        }
    }

    var body: some View {
        if kiCredits > 0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(labels.credits(kiCredits), systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(labels.use) { onCreditUsed() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                content()
            }
        } else {
            GroupBox {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.purple)
                        .padding(12)
                        .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                    Text(labels.title).font(.headline)
                    Text(labels.sub).font(.caption).foregroundStyle(.secondary)
                    Text(labels.price).font(.title3.bold())

                    Button {
                        Task { await openCheckout() }
                    } label: {
                        Text(loading ? "..." : labels.btn)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(loading)
                }
                .padding(16)
                .frame(maxWidth: 360)
            }
        }
    }

    @MainActor
    private func openCheckout() async {
        loading = true
        if let url = URL(string: "https://machiavellex.app/checkout?type=ki") {
            NSWorkspace.shared.open(url)
        }
        loading = false
    }
}

// MARK: - Views/LayoutView.swift

struct LayoutView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            content()
        }
    }
}

// MARK: - Views/PaymentGateView.swift

struct PaymentGateView<Content: View>: View {
    let hasAccess: Bool
    @ViewBuilder var content: () -> Content
    @EnvironmentObject var auth: AuthService

    @State private var loading = false

    private var language: String { auth.currentUser?.language.uppercased() ?? "DE" }

    private var labels: (title: String, sub: String, price: String, btn: String, back: String, note: String) {
        switch language {
        case "EN": return ("Premium Module",
                           "This section requires an active subscription.",
                           "$29/month",
                           "Unlock now",
                           "Back to overview",
                           "Secure checkout via Stripe. Cancel anytime.")
        case "FR": return ("Module Premium",
                           "Cette section nécessite un abonnement actif.",
                           "29 $/mois",
                           "Débloquer maintenant",
                           "Retour à l'aperçu",
                           "Paiement sécurisé via Stripe. Résiliation possible à tout moment.")
        default:   return ("Premium-Modul",
                           "Dieser Bereich erfordert ein aktives Abonnement.",
                           "29 $/Monat",
                           "Jetzt freischalten",
                           "Zurück zur Übersicht",
                           "Sicherer Checkout via Stripe. Kündigung jederzeit möglich.")
        }
    }

    var body: some View {
        if hasAccess {
            content()
        } else {
            VStack {
                Spacer()
                GroupBox {
                    VStack(spacing: 18) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.accentColor)
                            .padding(20)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))

                        Text(labels.title)
                            .font(.title2.bold())
                        Text(labels.sub)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                            Text(labels.price).font(.title.bold())
                        }
                        Text(labels.note)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Button {
                            Task { await openCheckout() }
                        } label: {
                            Text(loading ? "..." : labels.btn)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(loading)
                    }
                    .padding(20)
                    .frame(maxWidth: 360)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
        }
    }

    @MainActor
    private func openCheckout() async {
        loading = true
        // Auf macOS: Stripe-Checkout-Seite im Browser öffnen.
        if let url = URL(string: "https://machiavellex.app/checkout?type=module") {
            NSWorkspace.shared.open(url)
        }
        loading = false
    }
}

// MARK: - Views/SettingsView.swift

struct SettingsView: View {
    @EnvironmentObject var auth:   AuthService
    @EnvironmentObject var claude: ClaudeAPIService

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("Allgemein", systemImage: "gearshape") }
            apiTab
                .tabItem { Label("KI-API", systemImage: "key") }
            accountTab
                .tabItem { Label("Konto", systemImage: "person.crop.circle") }
        }
        .frame(width: 520, height: 360)
    }

    // MARK: - Allgemein
    private var generalTab: some View {
        Form {
            Section("Anzeige") {
                Picker("Sprache", selection: .constant("Deutsch")) {
                    Text("Deutsch").tag("Deutsch")
                    Text("English").tag("English")
                    Text("Français").tag("Français")
                }
                Picker("Rechtsordnung", selection: .constant(auth.currentUser?.jurisdiction.rawValue ?? "DACH")) {
                    Text("Deutschland").tag("DACH")
                    Text("USA").tag("US")
                }
            }
            Section("DSGVO / Datenschutz") {
                Toggle("Anonymisierte KI-Logs senden", isOn: .constant(false))
                Text("Alle Daten verbleiben in deinem iCloud-Konto. Es findet keine Übermittlung an Dritte statt – außer die KI-Calls an Anthropic Claude.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - API-Key
    @State private var apiKeyInput: String = ""
    @State private var showSavedHint = false

    private var apiTab: some View {
        Form {
            Section("Anthropic Claude API") {
                SecureField("API-Key (sk-ant-…)", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Speichern") {
                        claude.setApiKey(apiKeyInput)
                        apiKeyInput = ""
                        showSavedHint = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSavedHint = false }
                    }
                    .disabled(apiKeyInput.isEmpty)
                    if showSavedHint {
                        Label("Gespeichert", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Link("Key holen", destination: URL(string: "https://console.anthropic.com")!)
                }
                Text("Modell: \(ClaudeAPIService.defaultModel)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let err = claude.lastError {
                Section("Letzter Fehler") {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .padding()
    }

    // MARK: - Konto
    private var accountTab: some View {
        Form {
            if let user = auth.currentUser {
                Section("Angemeldet als") {
                    LabeledContent("Email",         value: user.email)
                    LabeledContent("Rolle",         value: user.role.rawValue)
                    LabeledContent("Rechtsordnung", value: user.jurisdiction.rawValue)
                    LabeledContent("KI-Credits",    value: "\(user.kiCredits)")
                }
                Section {
                    Button("Abmelden", role: .destructive) {
                        auth.logout()
                    }
                }
            } else {
                Text("Nicht angemeldet.")
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(ClaudeAPIService())
}

// MARK: - Views/UserNotRegisteredErrorView.swift

struct UserNotRegisteredErrorView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.orange)
                .padding(20)
                .background(Color.orange.opacity(0.15), in: Circle())

            Text("Access Restricted")
                .font(.largeTitle.bold())

            Text("You are not registered to use this application. Please contact the app administrator to request access.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Text("If you believe this is an error, you can:")
                        .font(.subheadline.weight(.medium))
                    Label("Verify you are logged in with the correct account", systemImage: "checkmark.circle")
                    Label("Contact the app administrator for access", systemImage: "envelope")
                    Label("Try logging out and back in again", systemImage: "arrow.triangle.2.circlepath")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 420)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
