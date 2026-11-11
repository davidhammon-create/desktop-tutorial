import Foundation
import CryptoKit
import CommonCrypto
import SwiftUI
enum AboPlan: String, Codable, CaseIterable, Identifiable {
    case frei
    case kanzlei
    case imperium
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .frei:     return "Basis"
        case .kanzlei:  return "Kanzlei Pro"
        case .imperium: return "Imperium"
        }
    }
    var monatsPreis: Double {
        switch self {
        case .frei:     return 0
        case .kanzlei:  return 49
        case .imperium: return 99
        }
    }
    var preisText: String {
        monatsPreis == 0 ? "kostenlos" : String(format: "%.0f € / Monat", monatsPreis)
    }
    var untertitel: String {
        switch self {
        case .frei:     return "Vorgänge, Aufgaben, Fristen — der tägliche Kern."
        case .kanzlei:  return "Mandatsarbeit komplett: Lexara, Organon, Honorare, KI nach Verbrauch."
        case .imperium: return "Volle strategische Tiefe: Strategos, Opportunisma, Lagezentrale, Berufspflicht."
        }
    }
    var leistungen: [String] {
        switch self {
        case .frei:
            return ["Vorgänge & Schreibtisch", "Aufgaben & Zeitleiste", "Dokumente & Übersicht", "Einstellungen & Wartung", "Keine KI-Funktionen"]
        case .kanzlei:
            return ["Alles aus Basis", "Lexara — Fälle, Macht & Pfadgraf", "Organon & Mandantenportal", "Honorare, Pipeline, beA-Check", "Cockpit & Analytik", "KI-Assistent (nach Verbrauch)"]
        case .imperium:
            return ["Alles aus Kanzlei Pro", "Strategos & Fenylaw Strategies", "Opportunisma — Strategy Desk", "Lagezentrale & KonfliktRadar", "Berufspflicht & Entscheidungsjournal", "Praxisprofil & Plattform-Agent — alle Fenster"]
        }
    }
    func erlaubt(_ eintrag: SeitenleistenEintrag) -> Bool {
        if Self.basisModule.contains(eintrag) { return true }
        switch self {
        case .frei:
            return false
        case .kanzlei:
            return Self.kanzleiModule.contains(eintrag)
        case .imperium:
            return Self.kanzleiModule.contains(eintrag) || Self.imperiumModule.contains(eintrag)
        }
    }
    static let basisModule: Set<SeitenleistenEintrag> = [
        .dashboard, .schreibtisch, .vorgaenge, .durchlauf, .aufgaben, .zeitleiste, .dokumente, .einstellungen,
        .selbstreparatur   // Wartung & Beschwerden für alle Konten
    ]
    static let kanzleiModule: Set<SeitenleistenEintrag> = [
        .lexara, .organon, .richterprofile, .honorare, .mandatsPipeline,
        .beaCheck, .mandanten, .cockpit, .analytik, .kiChat, .compliance,
        .jurisdiktionen
    ]
    static let imperiumModule: Set<SeitenleistenEintrag> = [
        .strategos, .opportunisma, .sunTzu, .enterpriseRadar, .lageZentrale, .berufspflicht,
        .konfliktRadar, .praxisProfil, .entscheidungsjournal, .plattformAgent
    ]
    static func benoetigteStufe(fuer eintrag: SeitenleistenEintrag) -> AboPlan {
        if basisModule.contains(eintrag) { return .frei }
        if kanzleiModule.contains(eintrag) { return .kanzlei }
        return .imperium
    }
}
struct Konto: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var passwortHash: String
    var salt: String
    var rolle: KontoRolle = .nutzer
    var plan: AboPlan = .frei
    var aktiv: Bool = true
    var gesperrt: Bool = false
    var erstellt: Date = Date()
    var letzteAnmeldung: Date? = nil
    var notizen: String = ""
    var kiBudgetMonat: Double? = nil
    var istAdmin: Bool { rolle == .admin }
}
enum KontoRolle: String, Codable, CaseIterable, Identifiable {
    case admin
    case nutzer
    var id: String { rawValue }
    var titel: String { self == .admin ? "Administrator" : "Nutzer" }
}
struct KIVerbrauchEintrag: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var kontoId: UUID
    var datum: Date = Date()
    var modul: String
    var aktion: String
    var modell: String
    var tokensEin: Int
    var tokensAus: Int
    var kosten: Double
}
struct KIPreise: Codable, Hashable {
    var eingabeJe1000: Double = 0.004
    var ausgabeJe1000: Double = 0.016
    var mindestJeAufruf: Double = 0.01
    var dokumentAnalyse: Double = 0.05
    func kosten(tokensEin: Int, tokensAus: Int) -> Double {
        let k = Double(tokensEin) / 1000 * eingabeJe1000
              + Double(tokensAus) / 1000 * ausgabeJe1000
        return max(mindestJeAufruf, (k * 100).rounded() / 100)
    }
}
struct AdminAuditEintrag: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var datum: Date = Date()
    var admin: String
    var aktion: String
    var betroffen: String
}
struct UpgradeAnfrage: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var kontoId: UUID
    var gewuenschterPlan: AboPlan
    var datum: Date = Date()
    var status: Status = .offen
    enum Status: String, Codable {
        case offen, genehmigt, abgelehnt
    }
}
private struct KontoSystemSnapshot: Codable {
    var konten: [Konto] = []
    var verbrauch: [KIVerbrauchEintrag] = []
    var audit: [AdminAuditEintrag] = []
    var upgradeAnfragen: [UpgradeAnfrage] = []
    var preise: KIPreise = KIPreise()
}
@MainActor
final class KontoStore: ObservableObject {
    static let shared = KontoStore()
    @Published private(set) var konten: [Konto] = []
    @Published private(set) var verbrauch: [KIVerbrauchEintrag] = []
    @Published private(set) var audit: [AdminAuditEintrag] = []
    @Published private(set) var upgradeAnfragen: [UpgradeAnfrage] = []
    @Published var preise: KIPreise = KIPreise() {
        didSet { speichern() }
    }
    @Published private(set) var aktuellesKontoId: UUID? = nil
    @Published var fehler: String? = nil
    private static let sessionKey = "fenlynineos_konto_session_v1"
    private static let legacySessionKey = "legalos_konto_session_v1"
    private static let permanentKey = "fenlynineos_konto_permanent_login"
    var permanentLogin: Bool {
        get {
            let d = UserDefaults.standard
            if d.object(forKey: Self.permanentKey) == nil { return true }
            return d.bool(forKey: Self.permanentKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.permanentKey) }
    }
    private init() {
        laden()
        stelleSessionWiederHer()
    }
    private func stelleSessionWiederHer() {
        let d = UserDefaults.standard
        if d.string(forKey: Self.sessionKey) == nil,
           let legacy = d.string(forKey: Self.legacySessionKey) {
            d.set(legacy, forKey: Self.sessionKey)
        }
        if let raw = d.string(forKey: Self.sessionKey),
           let id = UUID(uuidString: raw),
           let konto = konten.first(where: { $0.id == id && $0.aktiv && !$0.gesperrt }) {
            aktuellesKontoId = konto.id
            d.set(konto.id.uuidString, forKey: Self.sessionKey)
            if permanentLogin { d.set(true, forKey: Self.permanentKey) }
            return
        }
        guard permanentLogin,
              let admin = konten.first(where: { $0.rolle == .admin && $0.aktiv && !$0.gesperrt })
        else { return }
        anmeldenIntern(admin)
    }
    var aktuellesKonto: Konto? {
        guard let id = aktuellesKontoId else { return nil }
        return konten.first(where: { $0.id == id })
    }
    var istAngemeldet: Bool { aktuellesKonto != nil }
    var istAdmin: Bool { aktuellesKonto?.istAdmin ?? false }
    var ersteinrichtungNoetig: Bool { konten.isEmpty }
    func darf(_ eintrag: SeitenleistenEintrag) -> Bool {
        guard let konto = aktuellesKonto else { return false }
        if eintrag == .adminZentrale { return konto.istAdmin }
        if konto.istAdmin { return true }
        return konto.plan.erlaubt(eintrag)
    }
    var kiErlaubt: Bool {
        guard let konto = aktuellesKonto else { return false }
        if konto.istAdmin { return true }
        guard konto.plan != .frei else { return false }
        if let budget = konto.kiBudgetMonat {
            return monatsKosten(kontoId: konto.id) < budget
        }
        return true
    }
    @discardableResult
    func registrieren(name: String, email: String, passwort: String) -> Bool {
        fehler = nil
        let mail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            fehler = "Bitte einen Namen angeben."; return false
        }
        guard mail.contains("@"), mail.contains(".") else {
            fehler = "Bitte eine gültige E-Mail-Adresse angeben."; return false
        }
        guard passwort.count >= 8 else {
            fehler = "Das Passwort braucht mindestens 8 Zeichen."; return false
        }
        guard !konten.contains(where: { $0.email == mail }) else {
            fehler = "Für diese E-Mail existiert bereits ein Konto."; return false
        }
        let salt = Self.neuerSalt()
        var konto = Konto(
            name: name.trimmingCharacters(in: .whitespaces),
            email: mail,
            passwortHash: Self.hash(passwort: passwort, salt: salt),
            salt: salt
        )
        if konten.isEmpty {
            konto.rolle = .admin
            konto.plan = .imperium
        }
        konten.append(konto)
        speichern()
        anmeldenIntern(konto)
        return true
    }
    @discardableResult
    func anmelden(email: String, passwort: String) -> Bool {
        fehler = nil
        let mail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard let konto = konten.first(where: { $0.email == mail }) else {
            fehler = "Kein Konto mit dieser E-Mail gefunden."; return false
        }
        guard konto.aktiv else {
            fehler = "Dieses Konto ist deaktiviert. Bitte an den Administrator wenden."; return false
        }
        guard !konto.gesperrt else {
            fehler = "Dieses Konto ist gesperrt. Bitte an den Administrator wenden."; return false
        }
        guard Self.passt(passwort: passwort, salt: konto.salt, gespeichert: konto.passwortHash) else {
            fehler = "Passwort falsch."; return false
        }
        // Alte Konten tragen noch den einfachen SHA-256-Hash. Beim ersten
        // erfolgreichen Anmelden wird er durch PBKDF2 ersetzt.
        if !konto.passwortHash.hasPrefix(Self.pbkdf2Praefix),
           let idx = konten.firstIndex(where: { $0.id == konto.id }) {
            konten[idx].passwortHash = Self.hash(passwort: passwort, salt: konto.salt)
            speichern()
        }
        anmeldenIntern(konto)
        return true
    }
    private func anmeldenIntern(_ konto: Konto) {
        aktuellesKontoId = konto.id
        let d = UserDefaults.standard
        d.set(konto.id.uuidString, forKey: Self.sessionKey)
        d.set(konto.id.uuidString, forKey: Self.legacySessionKey) // Kompatibilität
        if konto.istAdmin { d.set(true, forKey: Self.permanentKey) }
        if let idx = konten.firstIndex(where: { $0.id == konto.id }) {
            konten[idx].letzteAnmeldung = Date()
            speichern()
        }
    }
    func abmelden() {
        aktuellesKontoId = nil
        let d = UserDefaults.standard
        d.removeObject(forKey: Self.sessionKey)
        d.removeObject(forKey: Self.legacySessionKey)
    }
    @discardableResult
    func permanentAdminAnmelden() -> Bool {
        permanentLogin = true
        if let aktuell = aktuellesKonto, aktuell.istAdmin { return true }
        guard let admin = konten.first(where: { $0.rolle == .admin && $0.aktiv && !$0.gesperrt }) else {
            fehler = "Kein Administrator-Konto vorhanden."
            return false
        }
        anmeldenIntern(admin)
        return true
    }
    func passwortAendern(alt: String, neu: String) -> Bool {
        fehler = nil
        guard var konto = aktuellesKonto,
              let idx = konten.firstIndex(where: { $0.id == konto.id }) else { return false }
        guard Self.passt(passwort: alt, salt: konto.salt, gespeichert: konto.passwortHash) else {
            fehler = "Aktuelles Passwort falsch."; return false
        }
        guard neu.count >= 8 else {
            fehler = "Das neue Passwort braucht mindestens 8 Zeichen."; return false
        }
        konto.salt = Self.neuerSalt()
        konto.passwortHash = Self.hash(passwort: neu, salt: konto.salt)
        konten[idx] = konto
        speichern()
        return true
    }
    func upgradeAnfordern(_ plan: AboPlan) {
        guard let konto = aktuellesKonto else { return }
        guard !upgradeAnfragen.contains(where: { $0.kontoId == konto.id && $0.status == .offen }) else { return }
        upgradeAnfragen.append(UpgradeAnfrage(kontoId: konto.id, gewuenschterPlan: plan))
        speichern()
    }
    var offeneAnfragen: [UpgradeAnfrage] {
        upgradeAnfragen.filter { $0.status == .offen }
    }
    func hatOffeneAnfrage(kontoId: UUID) -> Bool {
        upgradeAnfragen.contains(where: { $0.kontoId == kontoId && $0.status == .offen })
    }
    func verbucheKI(modul: String, aktion: String, modell: String, tokensEin: Int, tokensAus: Int, pauschale: Double? = nil) {
        guard let konto = aktuellesKonto else { return }
        let kosten: Double
        if konto.istAdmin {
            kosten = 0
        } else if let pauschale {
            kosten = pauschale
        } else {
            kosten = preise.kosten(tokensEin: tokensEin, tokensAus: tokensAus)
        }
        verbrauch.append(KIVerbrauchEintrag(
            kontoId: konto.id, modul: modul, aktion: aktion, modell: modell,
            tokensEin: tokensEin, tokensAus: tokensAus, kosten: kosten
        ))
        if verbrauch.count > 5000 {
            verbrauch.removeFirst(verbrauch.count - 5000)
        }
        speichern()
    }
    func verbrauch(kontoId: UUID) -> [KIVerbrauchEintrag] {
        verbrauch.filter { $0.kontoId == kontoId }.sorted { $0.datum > $1.datum }
    }
    func monatsKosten(kontoId: UUID, monat: Date = Date()) -> Double {
        let cal = Calendar.current
        return verbrauch
            .filter { $0.kontoId == kontoId && cal.isDate($0.datum, equalTo: monat, toGranularity: .month) }
            .reduce(0) { $0 + $1.kosten }
    }
    func monatsAufrufe(kontoId: UUID, monat: Date = Date()) -> Int {
        let cal = Calendar.current
        return verbrauch
            .filter { $0.kontoId == kontoId && cal.isDate($0.datum, equalTo: monat, toGranularity: .month) }
            .count
    }
    var monatsKostenGesamt: Double {
        let cal = Calendar.current
        return verbrauch
            .filter { cal.isDate($0.datum, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.kosten }
    }
    private func auditieren(_ aktion: String, betroffen: String) {
        let admin = aktuellesKonto?.email ?? "system"
        audit.append(AdminAuditEintrag(admin: admin, aktion: aktion, betroffen: betroffen))
        if audit.count > 2000 { audit.removeFirst(audit.count - 2000) }
    }
    func adminSetzePlan(kontoId: UUID, plan: AboPlan) {
        guard istAdmin, let idx = konten.firstIndex(where: { $0.id == kontoId }) else { return }
        konten[idx].plan = plan
        for i in upgradeAnfragen.indices where upgradeAnfragen[i].kontoId == kontoId && upgradeAnfragen[i].status == .offen {
            upgradeAnfragen[i].status = .genehmigt
        }
        auditieren("Abo geändert auf \(plan.titel)", betroffen: konten[idx].email)
        speichern()
    }
    func adminSetzeRolle(kontoId: UUID, rolle: KontoRolle) {
        guard istAdmin, let idx = konten.firstIndex(where: { $0.id == kontoId }) else { return }
        if rolle == .nutzer, konten[idx].rolle == .admin,
           konten.filter({ $0.rolle == .admin }).count <= 1 {
            fehler = "Der letzte Administrator kann nicht herabgestuft werden."
            return
        }
        konten[idx].rolle = rolle
        auditieren("Rolle geändert auf \(rolle.titel)", betroffen: konten[idx].email)
        speichern()
    }
    func adminSetzeAktiv(kontoId: UUID, aktiv: Bool) {
        guard istAdmin, let idx = konten.firstIndex(where: { $0.id == kontoId }) else { return }
        konten[idx].aktiv = aktiv
        auditieren(aktiv ? "Konto aktiviert" : "Konto deaktiviert", betroffen: konten[idx].email)
        speichern()
    }
    func adminSetzeGesperrt(kontoId: UUID, gesperrt: Bool) {
        guard istAdmin, let idx = konten.firstIndex(where: { $0.id == kontoId }) else { return }
        konten[idx].gesperrt = gesperrt
        auditieren(gesperrt ? "Konto gesperrt" : "Konto entsperrt", betroffen: konten[idx].email)
        speichern()
    }
    func adminSetzeBudget(kontoId: UUID, budget: Double?) {
        guard istAdmin, let idx = konten.firstIndex(where: { $0.id == kontoId }) else { return }
        konten[idx].kiBudgetMonat = budget
        auditieren("KI-Budget: \(budget.map { String(format: "%.2f €", $0) } ?? "unbegrenzt")", betroffen: konten[idx].email)
        speichern()
    }
    func adminSetzeNotizen(kontoId: UUID, notizen: String) {
        guard istAdmin, let idx = konten.firstIndex(where: { $0.id == kontoId }) else { return }
        konten[idx].notizen = notizen
        speichern()
    }
    func adminPasswortZuruecksetzen(kontoId: UUID) -> String? {
        guard istAdmin, let idx = konten.firstIndex(where: { $0.id == kontoId }) else { return nil }
        let neu = Self.zufallsPasswort()
        konten[idx].salt = Self.neuerSalt()
        konten[idx].passwortHash = Self.hash(passwort: neu, salt: konten[idx].salt)
        auditieren("Passwort zurückgesetzt", betroffen: konten[idx].email)
        speichern()
        return neu
    }
    func adminAnfrageAblehnen(_ anfrageId: UUID) {
        guard istAdmin, let idx = upgradeAnfragen.firstIndex(where: { $0.id == anfrageId }) else { return }
        upgradeAnfragen[idx].status = .abgelehnt
        if let konto = konten.first(where: { $0.id == upgradeAnfragen[idx].kontoId }) {
            auditieren("Upgrade-Anfrage abgelehnt (\(upgradeAnfragen[idx].gewuenschterPlan.titel))", betroffen: konto.email)
        }
        speichern()
    }
    func datenExport(kontoId: UUID) -> String? {
        guard istAdmin || aktuellesKontoId == kontoId else { return nil }
        guard let konto = konten.first(where: { $0.id == kontoId }) else { return nil }
        struct Export: Codable {
            let hinweis: String
            let konto: KontoExport
            let kiNutzung: [KIVerbrauchEintrag]
        }
        struct KontoExport: Codable {
            let id: UUID; let name: String; let email: String
            let rolle: String; let plan: String
            let aktiv: Bool; let gesperrt: Bool
            let erstellt: Date; let letzteAnmeldung: Date?
        }
        let export = Export(
            hinweis: "Datenauskunft nach Art. 15/20 DSGVO — FenlynineOS Legal Suite. Passwörter werden nur als Hash gespeichert und sind nicht Teil des Exports.",
            konto: KontoExport(
                id: konto.id, name: konto.name, email: konto.email,
                rolle: konto.rolle.titel, plan: konto.plan.titel,
                aktiv: konto.aktiv, gesperrt: konto.gesperrt,
                erstellt: konto.erstellt, letzteAnmeldung: konto.letzteAnmeldung
            ),
            kiNutzung: verbrauch(kontoId: kontoId)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(export) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    func kontoLoeschen(kontoId: UUID) {
        guard istAdmin || aktuellesKontoId == kontoId else { return }
        guard let konto = konten.first(where: { $0.id == kontoId }) else { return }
        if konto.istAdmin, konten.filter({ $0.istAdmin }).count <= 1 {
            fehler = "Der letzte Administrator kann nicht gelöscht werden."
            return
        }
        auditieren("Konto gelöscht (Art. 17 DSGVO)", betroffen: konto.email)
        konten.removeAll { $0.id == kontoId }
        verbrauch.removeAll { $0.kontoId == kontoId }
        upgradeAnfragen.removeAll { $0.kontoId == kontoId }
        if aktuellesKontoId == kontoId { abmelden() }
        speichern()
    }
    func verbrauchAlsCSV(kontoId: UUID? = nil) -> String {
        let eintraege = kontoId.map { verbrauch(kontoId: $0) } ?? verbrauch.sorted { $0.datum > $1.datum }
        let df = ISO8601DateFormatter()
        var zeilen = ["Datum;Konto;Modul;Aktion;Modell;Tokens Ein;Tokens Aus;Kosten EUR"]
        for e in eintraege {
            let mail = konten.first(where: { $0.id == e.kontoId })?.email ?? e.kontoId.uuidString
            zeilen.append("\(df.string(from: e.datum));\(mail);\(e.modul);\(e.aktion);\(e.modell);\(e.tokensEin);\(e.tokensAus);\(String(format: "%.2f", e.kosten))")
        }
        return zeilen.joined(separator: "\n")
    }
    private static var speicherURL: URL {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FenlynineOS", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("konto-system.json")
    }
    private func speichern() {
        let snapshot = KontoSystemSnapshot(
            konten: konten, verbrauch: verbrauch, audit: audit,
            upgradeAnfragen: upgradeAnfragen, preise: preise
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: Self.speicherURL, options: [.atomic])
    }
    private func laden() {
        guard let data = try? Data(contentsOf: Self.speicherURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(KontoSystemSnapshot.self, from: data) else { return }
        konten = snapshot.konten
        verbrauch = snapshot.verbrauch
        audit = snapshot.audit
        upgradeAnfragen = snapshot.upgradeAnfragen
        preise = snapshot.preise
    }
    private static func neuerSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    // Passwort-Hashing: PBKDF2-HMAC-SHA256 mit 600.000 Runden (OWASP-Empfehlung).
    // Ein einzelner SHA-256-Durchlauf lässt sich auf einer Grafikkarte
    // milliardenfach pro Sekunde durchprobieren; PBKDF2 macht jeden Versuch teuer.
    // Format: "pbkdf2$<Runden>$<Hex>". Hashes ohne dieses Präfix sind alte
    // SHA-256-Hashes und werden beim nächsten Anmelden ersetzt.
    static let pbkdf2Praefix = "pbkdf2$"
    private static let pbkdf2Runden = 600_000
    private static func hash(passwort: String, salt: String) -> String {
        guard let hex = pbkdf2(passwort: passwort, salt: salt, runden: pbkdf2Runden) else {
            // Sollte die Systemfunktion ausfallen, lieber den alten Hash als gar keinen.
            return altHash(passwort: passwort, salt: salt)
        }
        return "\(pbkdf2Praefix)\(pbkdf2Runden)$\(hex)"
    }
    private static func passt(passwort: String, salt: String, gespeichert: String) -> Bool {
        if gespeichert.hasPrefix(pbkdf2Praefix) {
            let teile = gespeichert.split(separator: "$")
            guard teile.count == 3, let runden = Int(teile[1]), runden > 0,
                  let hex = pbkdf2(passwort: passwort, salt: salt, runden: runden) else { return false }
            return zeitkonstantGleich(hex, String(teile[2]))
        }
        return zeitkonstantGleich(altHash(passwort: passwort, salt: salt), gespeichert)
    }
    private static func altHash(passwort: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + passwort).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    private static func pbkdf2(passwort: String, salt: String, runden: Int) -> String? {
        let pw = Array(passwort.utf8).map { Int8(bitPattern: $0) }
        let s = Array(salt.utf8)
        var aus = [UInt8](repeating: 0, count: 32)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2), pw, pw.count, s, s.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), UInt32(runden), &aus, aus.count)
        guard status == Int32(kCCSuccess) else { return nil }
        return aus.map { String(format: "%02x", $0) }.joined()
    }
    /// Vergleich ohne vorzeitigen Abbruch, damit die Laufzeit nichts über die
    /// Zahl der übereinstimmenden Zeichen verrät.
    private static func zeitkonstantGleich(_ a: String, _ b: String) -> Bool {
        let x = Array(a.utf8), y = Array(b.utf8)
        guard x.count == y.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<x.count { diff |= x[i] ^ y[i] }
        return diff == 0
    }
    private static func zufallsPasswort() -> String {
        let zeichen = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789"
        return String((0..<12).compactMap { _ in zeichen.randomElement() })
    }
}
enum KontoAbrechnung {
    static let sperrHinweis = "KI-Funktionen erfordern das Abo „Kanzlei Pro“ oder „Imperium“. Upgrade unter Einstellungen → Konto & Abo anfordern."
    static let budgetHinweis = "Das monatliche KI-Budget dieses Kontos ist ausgeschöpft. Der Administrator kann es unter Admin-Zentrale anpassen."
    static func geschaetzteTokens(zeichen: Int) -> Int {
        max(1, zeichen / 4)
    }
    static func kiErlaubt() async -> Bool {
        await MainActor.run { KontoStore.shared.kiErlaubt }
    }
    static func verbuche(modul: String, aktion: String, modell: String, tokensEin: Int, tokensAus: Int, pauschale: Double? = nil) async {
        await MainActor.run {
            KontoStore.shared.verbucheKI(
                modul: modul, aktion: aktion, modell: modell,
                tokensEin: tokensEin, tokensAus: tokensAus, pauschale: pauschale
            )
        }
    }
}
