import Foundation
import Combine
import FenlynineOSKern

// MARK: - KI-Veredelung
//
// Alles, was JEDE KI-Anfrage der App besser und sicherer macht, an einer Stelle.
// `LLMService` ruft diese Bausteine für alle Module auf:
//
//   vor dem Versand   1. Rechenkern-Fakten (Kosten, Fristen, heutiges Datum)
//                     2. passendes Rechtswissen (Relevanzsuche statt Textvergleich)
//                     3. Arbeitsmethode des Moduls
//                     4. Pseudonymisierung -- nur wenn die Anfrage das Gerät verlässt
//   nach der Antwort  5. Klarnamen wieder einsetzen
//                     6. Normzitate, Beträge und zitierte Entscheidungen prüfen
//
// Der Grundsatz: Der Rechenkern rechnet, die KI begründet, die Prüfung zeigt,
// was davon belegt ist.

enum KIVeredelung {

    static let pseudonymisierungKey = "ki_pseudonymisierung_aktiv"
    static let antwortpruefungKey = "ki_antwortpruefung_aktiv"

    /// Voreinstellung AN: Wer Klarnamen an eine Cloud-KI senden will, muss das
    /// bewusst abschalten.
    static var pseudonymisierungAktiv: Bool {
        UserDefaults.standard.object(forKey: pseudonymisierungKey) as? Bool ?? true
    }

    static var antwortpruefungAktiv: Bool {
        UserDefaults.standard.object(forKey: antwortpruefungKey) as? Bool ?? true
    }

    // MARK: 1 · Rechenkern-Fakten

    /// Verbindliche Zahlen für das Modell. Ohne diesen Block schätzt ein
    /// Sprachmodell Gebühren und rechnet Fristen im Kopf -- beides geht schief.
    static func rechenkernFakten(caseId: String?) async -> String {
        var zeilen: [String] = ["- Heutiges Datum: \(datum(Date()))"]
        if let caseId, !caseId.isEmpty {
            if let fall = try? await Services.cases.get(id: caseId) {
                if let sw = fall.streitwert, sw > 0 {
                    let d = Decimal(string: String(format: "%.2f", sw)) ?? Decimal(sw)
                    zeilen.append("- Streitwert: \(euro(d))")
                    if let k = Kostenrisiko.erstinstanz(streitwert: d, gerichtsgebuehr: 0) {
                        zeilen.append("- Anwaltskosten je Partei, 1. Instanz "
                            + "(1,3 Verfahrens- und 1,2 Terminsgebühr, Auslagenpauschale, 19 % USt): "
                            + euro(k.eigeneAnwaltskosten))
                    } else {
                        zeilen.append("- Anwaltskosten: nicht berechnet (Streitwert außerhalb der hinterlegten Tabelle)")
                    }
                }
                if let v = fall.vergleichsangebot, v > 0 {
                    zeilen.append("- Vorliegendes Vergleichsangebot: \(euro(Decimal(v)))")
                }
            }
            if let fristen = try? await Services.deadlines.listForCase(caseId: caseId) {
                let offen = fristen.filter { $0.status == .offen }
                    .sorted { $0.due_date < $1.due_date }.prefix(8)
                for f in offen {
                    let norm = (f.paragraph?.isEmpty == false) ? " (\(f.paragraph!))" : ""
                    let tage = Calendar.current.dateComponents(
                        [.day], from: Calendar.current.startOfDay(for: Date()),
                        to: Calendar.current.startOfDay(for: f.due_date)).day ?? 0
                    let lage = tage < 0 ? "seit \(-tage) Tagen abgelaufen"
                             : tage == 0 ? "läuft heute ab" : "noch \(tage) Tage"
                    zeilen.append("- Offene Frist: \(f.frist_type.rawValue)\(norm), fällig \(datum(f.due_date)), \(lage)")
                }
            }
        }
        let akte = await aktenlage(caseId: caseId)
        return akte + """
        # RECHENKERN-FAKTEN (deterministisch berechnet, verbindlich)
        \(zeilen.joined(separator: "\n"))
        Diese Werte nicht neu berechnen und nicht abändern. Fehlt eine Zahl, schreibe \
        „nicht berechnet“, statt zu schätzen.
        """
    }

    /// Gemeinsame Sicht aller Module auf die Akte. Egal welches Modul die KI
    /// fragt -- Strategie, Prognose, Verhandlung --, es sieht denselben Stand:
    /// die stärksten Argumente beider Seiten, die Beweislage, die Beteiligten
    /// nach Rolle. So widersprechen sich die Module nicht.
    static func aktenlage(caseId: String?) async -> String {
        guard let caseId, !caseId.isEmpty,
              let fall = try? await Services.cases.get(id: caseId) else { return "" }
        var zeilen: [String] = []
        func feld(_ name: String, _ wert: String?) {
            if let w = wert?.trimmingCharacters(in: .whitespacesAndNewlines), !w.isEmpty {
                zeilen.append("- \(name): \(w)")
            }
        }
        feld("Rechtsgebiet", fall.rechtsgebiet)
        feld("Gericht", fall.gericht)
        zeilen.append("- Instanz: \(fall.instanz.rawValue) · Status: \(fall.status.rawValue)")
        feld("Prozessziel", fall.prozessziel)
        feld("Zentrale Rechtsfrage", fall.zentrale_rechtsfrage)
        if let argumente = try? await Services.arguments.listForCase(caseId: caseId), !argumente.isEmpty {
            let eigene = argumente.filter { $0.side == .eigen }.sorted { $0.strength > $1.strength }
            let fremde = argumente.filter { $0.side != .eigen }.sorted { $0.strength > $1.strength }
            zeilen.append("- Argumente: \(eigene.count) eigene, \(fremde.count) der Gegenseite")
            for a in eigene.prefix(4) {
                let norm = (a.rechtsgrundlage?.isEmpty == false) ? " [\(a.rechtsgrundlage!)]" : ""
                zeilen.append("  · eigen, Stärke \(a.strength)/10: \(a.title)\(norm)")
            }
            for a in fremde.prefix(4) {
                let norm = (a.rechtsgrundlage?.isEmpty == false) ? " [\(a.rechtsgrundlage!)]" : ""
                zeilen.append("  · Gegenseite, Stärke \(a.strength)/10: \(a.title)\(norm)")
            }
            let ohneBeweis = eigene.filter { ($0.linked_evidence_ids ?? []).isEmpty }.count
            if ohneBeweis > 0 {
                zeilen.append("  · \(ohneBeweis) eigene Argumente ohne verknüpftes Beweismittel")
            }
        }
        if let beweise = try? await Services.evidence.listForCase(caseId: caseId), !beweise.isEmpty {
            zeilen.append("- Beweismittel: \(beweise.count)")
            for b in beweise.sorted(by: { $0.weight > $1.weight }).prefix(5) {
                zeilen.append("  · \(b.type.rawValue), Gewicht \(b.weight)/10: \(b.title)")
            }
        }
        if let personen = try? await Services.persons.listForCase(caseId: caseId), !personen.isEmpty {
            let nachRolle = Dictionary(grouping: personen, by: { $0.role.rawValue })
            let teile = nachRolle.keys.sorted().map { "\(nachRolle[$0]?.count ?? 0)× \($0)" }
            zeilen.append("- Beteiligte: " + teile.joined(separator: ", "))
        }
        guard !zeilen.isEmpty else { return "" }
        return """
        # AKTENLAGE (gemeinsamer Stand aller Module zu dieser Akte)
        \(zeilen.joined(separator: "\n"))

        """
    }

    // MARK: 2 · Rechtswissen

    static func rechtswissen(fuer prompt: String, limit: Int) async -> String {
        await MainActor.run {
            RechtswissenStore.shared.relevanterKontext(fuer: prompt, limit: limit)
        }
    }

    // MARK: 4 · Pseudonymisierung

    /// Liefert einen Pseudonymisierer, wenn die Anfrage das Gerät verlässt und
    /// die Funktion eingeschaltet ist; sonst `nil` (lokale KI sieht Klartext).
    static func pseudonymisierer(fuer modus: KIModus) async -> Pseudonymisierer? {
        guard modus == .base44, pseudonymisierungAktiv else { return nil }
        let register = await KIPersonenregister.shared.aktuell()
        return Pseudonymisierer(bekannteNamen: register.namen,
                                eigeneAktenzeichen: register.aktenzeichen)
    }

    // MARK: 5 · Rückweg

    /// Setzt die Klarnamen in der rohen Server-Antwort wieder ein.
    static func wiederhergestellt(_ data: Data, mit pseudo: Pseudonymisierer?) -> Data {
        guard let pseudo, pseudo.anzahl > 0,
              let text = String(data: data, encoding: .utf8) else { return data }
        return Data(pseudo.wiederherstellenInJSON(text).utf8)
    }

    // MARK: 6 · Antwortprüfung

    /// Prüft die Antwort und legt den Bericht im Store ab. Wirft nie und
    /// verändert die Antwort nicht -- die Prüfung zeigt an, sie zensiert nicht.
    static func pruefe<T>(_ ergebnis: T, quellen: String, modul: String, modell: String,
                          pseudonymisierteAngaben: Int) async {
        guard antwortpruefungAktiv, let text = antworttext(ergebnis), !text.isEmpty else { return }
        let bericht = KIAntwortPruefer.pruefe(
            antwort: text, quellen: quellen, modul: modul, modell: modell,
            pseudonymisierteAngaben: pseudonymisierteAngaben)
        await MainActor.run { KIPruefberichtStore.shared.aufnehmen(bericht) }
    }

    /// Alle Textfelder einer Antwort als ein Text.
    static func antworttext<T>(_ ergebnis: T) -> String? {
        if let s = ergebnis as? String { return s }
        if let a = ergebnis as? AnyCodable { return textfelder(a.value) }
        if let e = ergebnis as? any Encodable,
           let d = try? JSONEncoder().encode(e),
           let o = try? JSONSerialization.jsonObject(with: d, options: [.fragmentsAllowed]) {
            return textfelder(o)
        }
        return nil
    }

    private static func textfelder(_ wert: Any) -> String {
        if let s = wert as? String { return s }
        if let a = wert as? AnyCodable { return textfelder(a.value) }
        if let liste = wert as? [Any] {
            return liste.map(textfelder).filter { !$0.isEmpty }.joined(separator: "\n")
        }
        if let dict = wert as? [String: Any] {
            return dict.keys.sorted().map { textfelder(dict[$0] as Any) }
                .filter { !$0.isEmpty }.joined(separator: "\n")
        }
        return ""
    }

    // MARK: Formatierung

    private static func datum(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: d)
    }

    private static func euro(_ d: Decimal) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return (f.string(from: NSDecimalNumber(decimal: d)) ?? "\(d)") + " €"
    }
}

// MARK: - Personenregister

/// Sammelt die Namen und Aktenzeichen aus den lokalen Akten, damit der
/// Pseudonymisierer sie kennt. Liest nur, speichert nichts, sendet nichts.
actor KIPersonenregister {
    static let shared = KIPersonenregister()

    private var namen: [String] = []
    private var aktenzeichen: [String] = []
    private var geladenAm: Date?

    func aktuell() async -> (namen: [String], aktenzeichen: [String]) {
        if let g = geladenAm, Date().timeIntervalSince(g) < 120 {
            return (namen, aktenzeichen)
        }
        var n = Set<String>()
        var az = Set<String>()
        func merke(_ s: String?) {
            guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), s.count >= 3 else { return }
            n.insert(s)
        }
        if let faelle = try? await Services.cases.list() {
            for f in faelle {
                merke(f.mandant_name)
                merke(f.richter_name)
                // "Müller ./. Bau GmbH" enthält beide Parteien.
                let einheitlich = f.fallname
                    .replacingOccurrences(of: " gegen ", with: "./.")
                    .replacingOccurrences(of: " vs. ", with: "./.")
                    .replacingOccurrences(of: " vs ", with: "./.")
                if einheitlich.contains("./.") {
                    for teil in einheitlich.components(separatedBy: "./.") { merke(teil) }
                }
                if let a = f.aktenzeichen?.trimmingCharacters(in: .whitespaces), a.count >= 4 {
                    az.insert(a)
                }
            }
        }
        if let mandanten = try? await Services.mandanten.list() {
            for m in mandanten {
                merke(m.anzeigename)
                merke(m.firma)
                merke(m.ansprechpartner)
            }
        }
        if let personen = try? await Services.persons.list() {
            for p in personen {
                merke(p.name)
                merke(p.organisation)
            }
        }
        namen = Array(n)
        aktenzeichen = Array(az)
        geladenAm = Date()
        return (namen, aktenzeichen)
    }

    /// Nach dem Anlegen oder Umbenennen einer Akte aufrufen.
    func verwerfen() { geladenAm = nil }
}

// MARK: - Prüfberichte

/// Die letzten Prüfberichte, nur im Arbeitsspeicher. Bewusst nicht auf der
/// Platte: Ein Bericht nennt Beträge und Aktenzeichen aus einer Antwort.
@MainActor
final class KIPruefberichtStore: ObservableObject {
    static let shared = KIPruefberichtStore()

    @Published private(set) var berichte: [KIPruefbericht] = []

    var letzter: KIPruefbericht? { berichte.first }

    func aufnehmen(_ bericht: KIPruefbericht) {
        berichte.insert(bericht, at: 0)
        if berichte.count > 60 { berichte.removeLast(berichte.count - 60) }
    }

    func leeren() { berichte.removeAll() }

    /// Zahl der Berichte, die sich ein Mensch ansehen sollte.
    var offeneHinweise: Int { berichte.filter { $0.stufe != .sauber }.count }
}

// MARK: - Rechtswissen: Relevanzsuche

extension RechtswissenStore {
    /// Die zum Prompt passendsten Einträge als Kontextblock. Leer, wenn nichts
    /// passt -- dann wird auch nichts mitgeschickt (spart Token und vermeidet,
    /// dass das Modell unpassendes Wissen einbaut).
    func relevanterKontext(fuer prompt: String, limit: Int) -> String {
        let aktiv = Set(Rechtsordnung.aktiveAusDefaults.map(\.rawValue))
        let pool = eintraege.filter { $0.rechtsordnung == nil || aktiv.contains($0.rechtsordnung ?? "") }
        guard !pool.isEmpty, limit > 0 else { return "" }
        let dokumente = pool.map {
            Suchdokument(id: $0.id.uuidString, titel: $0.titel,
                         text: $0.zusammenfassung + " " + $0.tags.joined(separator: " "),
                         norm: $0.norm)
        }
        let treffer = Relevanzsuche.suche(String(prompt.prefix(4000)), in: dokumente, limit: limit)
        guard !treffer.isEmpty else { return "" }
        let nachId = Dictionary(pool.map { ($0.id.uuidString, $0) }, uniquingKeysWith: { erster, _ in erster })
        let bloecke = treffer.compactMap { nachId[$0.id]?.kontextBlock }
        return """
        # LOKALES RECHTSWISSEN (aus Ihrem Rechtsradar; nach Relevanz zur Frage ausgewählt)
        \(bloecke.joined(separator: "\n\n"))
        Stütze dich auf diese Einträge, wo sie passen, und nenne sie dann als Quelle.
        """
    }
}
