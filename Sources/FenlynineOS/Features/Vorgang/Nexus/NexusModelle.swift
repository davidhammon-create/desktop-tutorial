import Foundation
enum NexusKnotenTyp: String, Codable, CaseIterable, Identifiable {
    case norm, merkmal, beleg, klausel, argEigen, argGegner, autoritaet
    var id: String { rawValue }
    var ebene: Int {
        switch self {
        case .norm: return 0
        case .merkmal: return 1
        case .beleg: return 2
        case .klausel: return 3
        case .argGegner, .argEigen: return 4
        case .autoritaet: return 5
        }
    }
    var rolle: String {
        switch self {
        case .norm: return "Ziel / Anspruchsgrundlage"
        case .merkmal: return "Tatbestandsmerkmal"
        case .beleg: return "Beleg"
        case .klausel: return "Klausel / Fundstelle"
        case .argEigen: return "Verteidigung"
        case .argGegner: return "Angriff"
        case .autoritaet: return "Autorität"
        }
    }
    var kuerzel: String {
        switch self {
        case .norm: return "E0"
        case .merkmal: return "E1"
        case .beleg: return "E2"
        case .klausel: return "E3"
        case .argGegner: return "E4a"
        case .argEigen: return "E4b"
        case .autoritaet: return "E5"
        }
    }
    var kartenLabel: String {
        switch self {
        case .norm: return "ZIEL"
        case .merkmal: return "MERKMAL"
        case .beleg: return "BELEG"
        case .klausel: return "KLAUSEL"
        case .argGegner: return "GEGNER"
        case .argEigen: return "KONTER"
        case .autoritaet: return "AUTORITÄT"
        }
    }
    var seitenFarbe: String {
        switch self {
        case .argEigen: return "gruen"
        case .argGegner: return "rot"
        case .autoritaet, .beleg: return "grau"
        case .klausel: return "ocker"
        case .norm: return "blau"
        case .merkmal: return "schwarz"
        }
    }
}
enum NexusKantenTyp: String, Codable, CaseIterable, Identifiable {
    case stuetzt, greiftAn, entkraeftet, schliesstAus, setztVoraus, alternativ
    var id: String { rawValue }
    var wirkung: Double {
        switch self {
        case .stuetzt: return 1.00
        case .greiftAn: return 0.60
        case .entkraeftet: return 0.85
        case .schliesstAus: return 1.00
        case .setztVoraus: return 1.00
        case .alternativ: return 1.00
        }
    }
    var label: String {
        switch self {
        case .stuetzt: return "stützt"
        case .greiftAn: return "greift an"
        case .entkraeftet: return "entkräftet"
        case .schliesstAus: return "schließt aus"
        case .setztVoraus: return "setzt voraus"
        case .alternativ: return "alternativ zu"
        }
    }
    var strichDicke: Double {
        switch self {
        case .stuetzt, .greiftAn, .alternativ: return 1.0
        case .entkraeftet, .schliesstAus: return 2.4
        case .setztVoraus: return 0.8
        }
    }
    var strichMuster: [Double] {
        switch self {
        case .stuetzt, .schliesstAus, .alternativ: return []
        case .greiftAn, .entkraeftet: return [6, 4]
        case .setztVoraus: return [1.5, 3]
        }
    }
}
enum NexusQuellenrang: String, Codable, CaseIterable, Identifiable {
    case gesetz, bghStaendig, bghEinzel, olg, lg, literatur, mindermeinung, analogie, unbelegt
    var id: String { rawValue }
    var q: Double {
        switch self {
        case .gesetz: return 1.00
        case .bghStaendig: return 0.90
        case .bghEinzel: return 0.80
        case .olg: return 0.65
        case .lg: return 0.45
        case .literatur: return 0.40
        case .mindermeinung: return 0.20
        case .analogie: return 0.15
        case .unbelegt: return 0.10
        }
    }
    var titel: String {
        switch self {
        case .gesetz: return "Gesetzestext, unmittelbar"
        case .bghStaendig: return "BGH / BAG / BFH, ständig"
        case .bghEinzel: return "BGH, Einzelentscheidung"
        case .olg: return "OLG / LAG"
        case .lg: return "LG / AG"
        case .literatur: return "Herrschende Literatur"
        case .mindermeinung: return "Mindermeinung"
        case .analogie: return "Analogie / Billigkeit"
        case .unbelegt: return "unbelegt (KI-Vorschlag, max. 0,10)"
        }
    }
    var kurz: String {
        switch self {
        case .gesetz: return "Gesetz"
        case .bghStaendig: return "BGH ständig"
        case .bghEinzel: return "BGH einzeln"
        case .olg: return "OLG"
        case .lg: return "LG"
        case .literatur: return "Literatur"
        case .mindermeinung: return "Mindermeinung"
        case .analogie: return "Analogie"
        case .unbelegt: return "unbelegt"
        }
    }
}
enum NexusNachweis: String, Codable, CaseIterable, Identifiable {
    case urkundeUnstreitig, urkundeBestritten, gutachten, zeugeNeutral, zeugeLager
    case indiz, vortragUnbestritten, behauptung
    var id: String { rawValue }
    var n: Double {
        switch self {
        case .urkundeUnstreitig: return 1.00
        case .urkundeBestritten: return 0.80
        case .gutachten: return 0.75
        case .zeugeNeutral: return 0.60
        case .zeugeLager: return 0.35
        case .indiz: return 0.30
        case .vortragUnbestritten: return 0.55
        case .behauptung: return 0.10
        }
    }
    var titel: String {
        switch self {
        case .urkundeUnstreitig: return "Urkunde, unstreitig"
        case .urkundeBestritten: return "Urkunde, bestritten"
        case .gutachten: return "Sachverständigengutachten"
        case .zeugeNeutral: return "Zeuge, neutral"
        case .zeugeLager: return "Zeuge, im Lager der Partei"
        case .indiz: return "Indiz / Anscheinsbeweis"
        case .vortragUnbestritten: return "Parteivortrag, unbestritten"
        case .behauptung: return "Behauptung ohne Beleg"
        }
    }
}
enum NexusStatus: String, Codable {
    case belegt, kiVorschlag, verworfen
}
enum NexusBeweislast: String, Codable {
    case glaeubiger, schuldner
    var titel: String {
        switch self {
        case .glaeubiger: return "Beweislast Gläubiger"
        case .schuldner: return "Beweislast Schuldner"
        }
    }
}
struct NexusFundstelle: Codable, Hashable {
    var dokId: String
    var seite: Int
    var zitat: String
}
struct NexusKnoten: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var parentId: UUID?
    var typ: NexusKnotenTyp
    var kern: String
    var volltext: String = ""
    var fundstelle: NexusFundstelle? = nil
    var qRang: NexusQuellenrang = .unbelegt
    var passgenauigkeit: Double = 0.70
    var passBegruendung: String = ""
    var nachweis: NexusNachweis = .behauptung
    var status: NexusStatus = .belegt
    var beweislast: NexusBeweislast = .glaeubiger
    var vermutung: Bool = false
    var sRoh: Double = 0
    var sNetto: Double = 0
    var pMerkmal: Double? = nil
    var autor: String = "nutzer"
    mutating func setzeKern(_ text: String) {
        kern = NexusAnzeige.zwoelfWoerter(text)
    }
}
struct NexusKante: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var von: UUID
    var nach: UUID
    var typ: NexusKantenTyp
    var w: Double
    var zielKanteId: UUID? = nil
    init(von: UUID, nach: UUID, typ: NexusKantenTyp, w: Double? = nil, zielKanteId: UUID? = nil) {
        self.von = von
        self.nach = nach
        self.typ = typ
        self.w = w ?? typ.wirkung
        self.zielKanteId = zielKanteId
    }
}
struct NexusGraph: Codable, Hashable {
    var optionId: UUID
    var vorgangId: UUID
    var knoten: [NexusKnoten] = []
    var kanten: [NexusKante] = []
    var pZulaessig: Double = 1
    var pNichtVerjaehrt: Double = 1
    var pDurchsetzbar: Double = 1
    var beta: Double = NexusPropagation.betaStart
    var betaKalibriert: Bool = false
    var pErfolg: Double = 0.5
    var pAnsprueche: [UUID: Double] = [:]
    var geaendert: Date = .init()
    static var leer: NexusGraph {
        NexusGraph(optionId: UUID(), vorgangId: UUID())
    }
    func knoten(_ id: UUID) -> NexusKnoten? { knoten.first { $0.id == id } }
    func kinder(von id: UUID) -> [NexusKnoten] {
        knoten.filter { $0.parentId == id }
    }
    func wuerzel() -> [NexusKnoten] { knoten.filter { $0.typ == .norm } }
    var belegtheit: Double {
        let relevant = knoten.filter { $0.typ != .norm }
        guard !relevant.isEmpty else { return 0 }
        let belegt = relevant.filter { $0.status == .belegt && $0.qRang != .unbelegt }.count
        return Double(belegt) / Double(relevant.count)
    }
    var offeneFlanken: [NexusKnoten] {
        knoten.filter { $0.typ == .merkmal && kinder(von: $0.id).filter { $0.typ == .beleg || $0.typ == .klausel }.isEmpty }
    }
    func sichtbar(von parent: UUID?, limit: Int = 7) -> (sichtbar: [NexusKnoten], weitere: Int) {
        let kinder = knoten.filter { $0.parentId == parent }
            .sorted { $0.sNetto > $1.sNetto }
        if kinder.count <= limit { return (kinder, 0) }
        return (Array(kinder.prefix(limit)), kinder.count - limit)
    }
    func tiefe(von id: UUID) -> Int {
        var t = 0
        var p = knoten(id)?.parentId
        while let pid = p, t < 20 {
            t += 1
            p = knoten(pid)?.parentId
        }
        return t
    }
    func merkmale() -> [NexusKnoten] {
        guard let w = wuerzel().first else { return knoten.filter { $0.typ == .merkmal } }
        return kinder(von: w.id).filter { $0.typ == .merkmal }
    }
    func kante(von: UUID, nach: UUID) -> NexusKante? {
        kanten.first { $0.von == von && $0.nach == nach }
    }
    func konter(zu id: UUID) -> [NexusKnoten] {
        kinder(von: id).filter { $0.typ == .argEigen && $0.status != .verworfen }
    }
    func gegenangriffe(zu id: UUID) -> [NexusKnoten] {
        kinder(von: id).filter { $0.typ == .argGegner && $0.status != .verworfen }
    }
    func sichtbareKinder(von id: UUID, limit: Int = 7) -> (sichtbar: [NexusKnoten], weitere: Int) {
        let roh = knoten.filter { $0.parentId == id && $0.status != .verworfen }
        let merkmaleNur = roh.allSatisfy { $0.typ == .merkmal } && !roh.isEmpty
        let rang: [NexusKnotenTyp: Int] = [
            .merkmal: 0, .beleg: 1, .klausel: 2, .autoritaet: 3,
            .argGegner: 4, .argEigen: 5, .norm: 6
        ]
        let gefiltert: [NexusKnoten]
        if merkmaleNur {
            gefiltert = roh
        } else {
            gefiltert = roh.filter { k in
                k.typ == .merkmal || k.typ == .beleg || k.typ == .klausel
                    || k.typ == .argEigen || k.typ == .argGegner || k.typ == .autoritaet
                    || k.sNetto >= 0.05
                    || k.kern.localizedCaseInsensitiveContains("fehlt")
            }
            .sorted { a, b in
                (rang[a.typ] ?? 9) < (rang[b.typ] ?? 9)
            }
        }
        if gefiltert.count <= limit { return (gefiltert, 0) }
        return (Array(gefiltert.prefix(limit)), gefiltert.count - limit)
    }
    func kanteVon(_ knotenId: UUID) -> NexusKante? {
        kanten.first { $0.von == knotenId }
    }
    func merkmalIndex(_ id: UUID) -> Int? {
        merkmale().firstIndex(where: { $0.id == id }).map { $0 + 1 }
    }
    func aggregationFaktoren() -> [Double] {
        merkmale().map { $0.pMerkmal ?? 0.5 }
    }
    func aggregationZeile() -> String {
        let f = aggregationFaktoren()
        guard !f.isEmpty else { return "Keine Merkmale — kein P(Erfolg)." }
        let teile = f.map { NexusAnzeige.faktor($0) }
        let intern = NexusAnzeige.netto(f.reduce(1.0, *))
        return "Aggregation über alle \(f.count) Merkmale → P(Erfolg) = \(teile.joined(separator: " × ")) = \(intern)"
    }
}
enum NexusAnzeige {
    static let betaHinweis = "β = 1,7 — nicht kalibriert. Konsistenz, keine Präzision."
    static func zwoelfWoerter(_ text: String) -> String {
        let teile = text.split { $0.isWhitespace || $0.isNewline }.prefix(12)
        return teile.joined(separator: " ")
    }
    static func band(_ p: Double) -> String {
        let pct = Int((min(0.98, max(0.02, p)) * 100 / 5).rounded() * 5)
        let lo = max(0, pct - 5)
        let hi = min(100, pct + 5)
        return "\(lo)–\(hi) %"
    }
    static func punkt(_ p: Double) -> String {
        String(format: "%.1f %%", min(0.98, max(0.02, p)) * 100).replacingOccurrences(of: ".", with: ",")
    }
    static func netto(_ x: Double) -> String {
        String(format: "%.3f", x).replacingOccurrences(of: ".", with: ",")
    }
    static func faktor(_ x: Double) -> String {
        String(format: "%.2f", x).replacingOccurrences(of: ".", with: ",")
    }
}
enum OptionLegalitaet: String, Codable, CaseIterable, Identifiable {
    case legal, grenzwertig, rechtswidrig
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .legal: return "legal"
        case .grenzwertig: return "grenzwertig"
        case .rechtswidrig: return "rechtswidrig"
        }
    }
}
enum FristTyp: String, Codable, CaseIterable, Identifiable {
    case frist, termin, ereignis
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .frist: return "Frist"
        case .termin: return "Termin"
        case .ereignis: return "erwartetes Ereignis"
        }
    }
}
enum MandantenProfil: String, Codable, CaseIterable, Identifiable {
    case risikoavers, ausgewogen, chancenorientiert
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .risikoavers: return "Risikoavers"
        case .ausgewogen: return "Ausgewogen"
        case .chancenorientiert: return "Chancenorientiert"
        }
    }
    var evGewicht: Double {
        switch self {
        case .risikoavers: return 0.30
        case .ausgewogen: return 0.50
        case .chancenorientiert: return 0.75
        }
    }
}
