import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// IMPERIUM -- Macht-, Einfluss- & Steuerungsanalyse (Engine)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Eigenständiges Rechen- und Simulationsmodell (KEINE Opportunisma-Kopie):
// · Machtprofil über 7 Dimensionen (eigen vs. Gegner) -> Macht-Index
// · Handlungsoptionen mit Eintritts-Wk, Beeinflussbarkeit, Nutzbarkeit,
// Folgen-Handhabbarkeit, Reversibilität, Rechtsgrundlage
// · Ressourcen & Hebel (vorhanden vs. aktivierbar) inkl. Rechtsgrundlagen
// · Deterministische Formelkaskade (transparent, nachvollziehbar)
// · Monte-Carlo-Zugfolgen-Simulation (seeded, reproduzierbar) -> Szenario-Fächer
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Machtdimensionen

enum MachtDimension: String, Codable, CaseIterable, Identifiable {
case information = "Information"
case recht = "Rechtliche Hebel"
case prozessual = "Prozessuale Kontrolle"
case ressourcen = "Ressourcen"
case reputation = "Reputation & Druck"
case netzwerk = "Netzwerk & Allianzen"
case zeit = "Zeit & Fristenhoheit"

var id: String { rawValue }

var symbol: String {
  switch self {
  case .information: return "doc.text.magnifyingglass"
  case .recht: return "scale.3d"
  case .prozessual: return "arrow.triangle.branch"
  case .ressourcen: return "banknote"
  case .reputation: return "megaphone"
  case .netzwerk: return "point.3.connected.trianglepath.dotted"
  case .zeit: return "clock.badge.exclamationmark"
  }
}

var kurz: String {
  switch self {
  case .information: return "Info"
  case .recht: return "Recht"
  case .prozessual: return "Prozess"
  case .ressourcen: return "Mittel"
  case .reputation: return "Druck"
  case .netzwerk: return "Netz"
  case .zeit: return "Zeit"
  }
}
}

struct MachtDimensionWert: Codable, Identifiable, Hashable {
var dimension: MachtDimension
var eigen: Double = 0.5 // 0…1
var gegner: Double = 0.5 // 0…1
var gewicht: Double = 1.0 // relative Bedeutung im Fall

var id: String { dimension.rawValue }
var netto: Double { eigen - gegner } // -1…+1
}

// MARK: - Wirkungstyp

enum MachtWirkung: String, Codable, CaseIterable, Identifiable {
case herbeifuehren = "Herbeiführen"
case verhindern = "Verhindern"
case beeinflussen = "Beeinflussen"

var id: String { rawValue }

var symbol: String {
  switch self {
  case .herbeifuehren: return "arrow.up.forward.circle.fill"
  case .verhindern: return "hand.raised.circle.fill"
  case .beeinflussen: return "slider.horizontal.2.arrow.trianglehead.counterclockwise"
  }
}

var farbe: Color {
  switch self {
  case .herbeifuehren: return Color(red: 0.19, green: 0.72, blue: 0.42)
  case .verhindern: return Color(red: 0.92, green: 0.34, blue: 0.30)
  case .beeinflussen: return Color(red: 0.30, green: 0.56, blue: 0.98)
  }
}
}

// MARK: - Handlungsoption

struct MachtOption: Codable, Identifiable, Hashable {
var id: UUID = UUID()
var titel: String
var beschreibung: String = ""
var rechtsgrundlage: String = "" // z. B. "§ 935 ZPO"
var wirkung: MachtWirkung = .herbeifuehren
var eintrittsWk: Double = 0.5 // Wk., dass das Zielereignis eintritt, wenn Option gespielt wird
var beeinflussbarkeit: Double = 0.5 // wie stark man Verlauf/Ergebnis steuern kann
var nutzbarkeit: Double = 0.5 // wie gut die Option praktisch nutzbar ist (Zugang, Beweise, Timing)
var folgenHandhabbarkeit: Double = 0.5 // wie gut Konsequenzen/Folgen händelbar sind
var reversibilitaet: Double = 0.5 // Rückholbarkeit, falls es schiefgeht
var aufwand: Double = 0.3 // Kosten/Aufwand/Exponierung 0…1
var dimensionen: [MachtDimension] = [] // welche Machtquellen die Option nutzt
var aktiv: Bool = true // fließt in Simulation ein
var herkunft: MachtHerkunft = .manuell

// Abgeleitete Kennzahlen (Formelkaskade)
var hebelwirkung: Double { eintrittsWk * beeinflussbarkeit }
var steuerbarkeit: Double { beeinflussbarkeit * nutzbarkeit }
var erwarteterNutzen: Double { eintrittsWk * nutzbarkeit * (0.5 + 0.5 * beeinflussbarkeit) }
var restrisiko: Double {
 let folgen = (1 - folgenHandhabbarkeit) * 0.6 + (1 - reversibilitaet) * 0.4
 return min(1, folgen * (0.4 + 0.6 * aufwand))
}
var nettoScore: Double { erwarteterNutzen - 0.5 * restrisiko } // -0.5…+1
}

enum MachtHerkunft: String, Codable {
case manuell = "Manuell"
case formel = "Formel"
case ki = "KI"
}

// MARK: - Ressourcen & Hebel

enum MachtRessourcenArt: String, Codable, CaseIterable, Identifiable {
case rechtsgrundlage = "Rechtsgrundlage"
case information = "Information/Beweis"
case finanziell = "Finanziell"
case personell = "Personell"
case reputational = "Reputational"
case zeitlich = "Zeitlich/Frist"
case netzwerk = "Netzwerk/Allianz"

var id: String { rawValue }

var symbol: String {
 switch self {
 case .rechtsgrundlage: return "book.closed.fill"
 case .information: return "doc.text.fill"
 case .finanziell: return "eurosign.circle.fill"
 case .personell: return "person.2.fill"
 case .reputational: return "megaphone.fill"
 case .zeitlich: return "clock.fill"
 case .netzwerk: return "point.3.filled.connected.trianglepath.dotted"
 }
}
}

struct MachtRessource: Codable, Identifiable, Hashable {
var id: UUID = UUID()
var titel: String
var art: MachtRessourcenArt = .rechtsgrundlage
var rechtsgrundlage: String = ""
var zweck: MachtWirkung = .beeinflussen
var verfuegbarkeit: Double = 0.5 // hat man heute (0…1)
var potenzial: Double = 0.5 // könnte man aktivieren/beschaffen (0…1)
var hebelwirkung: Double = 0.5 // Wirkung, wenn eingesetzt (0…1)
var notiz: String = ""
var herkunft: MachtHerkunft = .manuell

/// Effektive Schlagkraft heute + halbes aktivierbares Potenzial.
var effektiveKraft: Double { min(1, (verfuegbarkeit + 0.5 * max(0, potenzial - verfuegbarkeit)) * hebelwirkung) }
}

// MARK: - Gesamtzustand (pro Fall persistiert)

struct MachtAnalyseZustand: Codable {
var ziel: String = ""
var baseline: Double = 0.5 // Ausgangs-Wk. Zielerreichung ohne Züge
var dimensionen: [MachtDimensionWert] = MachtDimension.allCases.map { MachtDimensionWert(dimension: $0) }
var optionen: [MachtOption] = []
var ressourcen: [MachtRessource] = []
var kiZusammenfassung: String = ""
var kiZeitpunkt: Date? = nil
var version: Int = 1
}

// MARK: - Kennzahlen (Ergebnis der Formelkaskade)

struct MachtKennzahlen {
var machtIndex: Double // 0…100 -- Machtbalance eigen vs. Gegner
var steuerbarkeit: Double // 0…100 -- wie stark Verlauf kontrollierbar
var einflussReichweite: Double // 0…100 -- Ressourcen-/Hebel-Abdeckung
var folgenSicherheit: Double // 0…100 -- Handhabbarkeit der Konsequenzen
var zielWahrscheinlichkeit: Double // 0…100 -- aus Monte-Carlo
var dominanteDimension: MachtDimension?
var schwaechsteDimension: MachtDimension?
}

// MARK: - Simulation

struct MachtSimulationsErgebnis {
/// Fächer: pro Schritt (0 = Ausgangslage, dann je gespielter Zug) Perzentile des Ziel-Scores.
struct Schritt: Identifiable {
 var id: Int { index }
 var index: Int
 var label: String // Optionstitel oder "Start"
 var p10: Double
 var p25: Double
 var p50: Double
 var p75: Double
 var p90: Double
}
var schritte: [Schritt] = []
var zielWk: Double = 0 // Anteil Läufe mit End-Score >= 0.5
var eskalationsWk: Double = 0 // Anteil Läufe mit unbeherrschter Folge
var endVerteilung: [Double] = [] // End-Scores aller Läufe (Histogramm)
var iterationen: Int = 0
}

// MARK: - Seeded RNG (SplitMix64 -- reproduzierbar & transparent)

struct MachtZufall: RandomNumberGenerator {
private var state: UInt64
init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
mutating func next() -> UInt64 {
 state &+= 0x9E3779B97F4A7C15
 var z = state
 z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
 z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
 return z ^ (z >> 31)
}
mutating func double01() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
}

// MARK: - Engine

enum MachtEinflussEngine {

// nn Formelkaskade nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

/// Macht-Index 0…100: gewichtete Netto-Balance aller Dimensionen.
/// Formel: 50 + 50 · S(gewichtn · (eigenn - gegnern)) / S gewichtn
static func machtIndex(_ dims: [MachtDimensionWert]) -> Double {
 let gw = dims.reduce(0) { $0 + $1.gewicht }
 guard gw > 0 else { return 50 }
 let netto = dims.reduce(0) { $0 + $1.gewicht * $1.netto } / gw
 return max(0, min(100, 50 + 50 * netto))
}

/// Steuerbarkeits-Index 0…100: Ø(beeinflussbarkeit · nutzbarkeit) aktiver Optionen,
/// verstärkt/gedämpft durch die Machtbalance (±20 %).
static func steuerbarkeit(optionen: [MachtOption], machtIndex: Double) -> Double {
 let aktive = optionen.filter(\.aktiv)
 guard !aktive.isEmpty else { return 0 }
 let basis = aktive.reduce(0) { $0 + $1.steuerbarkeit } / Double(aktive.count)
 let machtFaktor = 0.8 + 0.4 * (machtIndex / 100) // 0.8…1.2
 return max(0, min(100, basis * machtFaktor * 100))
}

/// Einfluss-Reichweite 0…100: sättigende Summe der effektiven Ressourcenkraft.
/// Formel: 100 · (1 - Pi(1 - kraftn · 0.6)) -- jede Ressource schließt einen Teil der Lücke.
static func einflussReichweite(_ ressourcen: [MachtRessource]) -> Double {
 guard !ressourcen.isEmpty else { return 0 }
 let rest = ressourcen.reduce(1.0) { $0 * (1 - $1.effektiveKraft * 0.6) }
 return max(0, min(100, (1 - rest) * 100))
}

/// Folgen-Sicherheit 0…100: Ø Handhabbarkeit · Reversibilität aktiver Optionen.
static func folgenSicherheit(_ optionen: [MachtOption]) -> Double {
 let aktive = optionen.filter(\.aktiv)
 guard !aktive.isEmpty else { return 50 }
 let s = aktive.reduce(0) { $0 + ($1.folgenHandhabbarkeit * 0.7 + $1.reversibilitaet * 0.3) }
 return max(0, min(100, s / Double(aktive.count) * 100))
}

static func kennzahlen(zustand: MachtAnalyseZustand, simulation: MachtSimulationsErgebnis) -> MachtKennzahlen {
 let mi = machtIndex(zustand.dimensionen)
 let sortiert = zustand.dimensionen.sorted { $0.netto > $1.netto }
 return MachtKennzahlen(
   machtIndex: mi,
   steuerbarkeit: steuerbarkeit(optionen: zustand.optionen, machtIndex: mi),
   einflussReichweite: einflussReichweite(zustand.ressourcen),
   folgenSicherheit: folgenSicherheit(zustand.optionen),
   zielWahrscheinlichkeit: simulation.zielWk * 100,
   dominanteDimension: sortiert.first?.dimension,
   schwaechsteDimension: sortiert.last?.dimension
 )
}

// nn Monte-Carlo-Zugfolgen-Simulation nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
//
// Modell: Der Fall startet bei `baseline` (Ziel-Score 0…1). Aktive Optionen
// werden in Netto-Score-Reihenfolge als "Züge" gespielt. Pro Lauf:
// · Zug greift mit p = eintrittsWk · machtFaktor (Bernoulli)
// · Wirkungshöhe = nutzbarkeit · beeinflussbarkeit · 0.28 (± Rauschen)
// · "Verhindern" wirkt gegen Abwärtsrisiko, "Herbeiführen" hebt den Score,
// "Beeinflussen" zieht den Score Richtung Kontrolle (dämpft Varianz)
// · Misslingt ein Zug, droht eine Folge: mit p = (1 - folgenHandhabbarkeit)
// Rückschlag -(0.05…0.18), nicht reversibel (cid:222) zusätzlich Eskalation
// Ergebnis: Perzentil-Fächer pro Zug, Ziel-Wk. (End-Score >= 0.5), Eskalations-Wk.

static func simuliere(zustand: MachtAnalyseZustand, iterationen: Int = 600, seed: UInt64 = 0xF9A7) -> MachtSimulationsErgebnis {
 let mi = machtIndex(zustand.dimensionen) / 100 // 0…1
 let machtFaktor = 0.75 + 0.5 * mi // 0.75…1.25
 let zuege = zustand.optionen.filter(\.aktiv).sorted { $0.nettoScore > $1.nettoScore }
 var ergebnis = MachtSimulationsErgebnis()
 ergebnis.iterationen = iterationen

 guard iterationen > 0 else { return ergebnis }
 var rng = MachtZufall(seed: seed)

 // scores[schritt][lauf]
 var scores: [[Double]] = Array(repeating: [], count: zuege.count + 1)
 var eskalationen = 0

 for _ in 0..<iterationen {
   var s = zustand.baseline + (rng.double01() - 0.5) * 0.06
   s = min(1, max(0, s))
   scores[0].append(s)
   var eskaliert = false

   for (i, zug) in zuege.enumerated() {
     let p = min(0.98, max(0.02, zug.eintrittsWk * machtFaktor))
     let greift = rng.double01() < p
     let staerke = zug.nutzbarkeit * zug.beeinflussbarkeit * 0.28 * (0.8 + 0.4 * rng.double01())

     if greift {
       switch zug.wirkung {
       case .herbeifuehren:
         s += staerke
       case .verhindern:
         s += staerke * 0.7 + 0.03
       case .beeinflussen:
         // zieht Richtung kontrollierten Zielkorridor (0.75)
         s += (0.75 - s) * zug.beeinflussbarkeit * 0.35
       }
     } else {
       // Zug misslungen -> mögliche Folge
       if rng.double01() < (1 - zug.folgenHandhabbarkeit) {
         let rueckschlag = 0.05 + 0.13 * rng.double01()
         s -= rueckschlag
         if rng.double01() < (1 - zug.reversibilitaet) * 0.5 {
           eskaliert = true
           s -= 0.05
         }
       }
     }
     s = min(1, max(0, s))
     scores[i + 1].append(s)
   }
   if eskaliert { eskalationen += 1 }
 }

 func perzentil(_ sorted: [Double], _ q: Double) -> Double {
   guard !sorted.isEmpty else { return 0 }
   let pos = q * Double(sorted.count - 1)
   let lo = Int(pos), hi = min(lo + 1, sorted.count - 1)
   let frac = pos - Double(lo)
   return sorted[lo] * (1 - frac) + sorted[hi] * frac
 }

 for (i, arr) in scores.enumerated() {
   let sortiert = arr.sorted()
   ergebnis.schritte.append(.init(
     index: i,
     label: i == 0 ? "Start" : zuege[i - 1].titel,
     p10: perzentil(sortiert, 0.10),
     p25: perzentil(sortiert, 0.25),
     p50: perzentil(sortiert, 0.50),
     p75: perzentil(sortiert, 0.75),
     p90: perzentil(sortiert, 0.90)
   ))
 }

 let endScores = scores.last ?? []
 ergebnis.endVerteilung = endScores
 ergebnis.zielWk = endScores.isEmpty ? 0 : Double(endScores.filter { $0 >= 0.5 }.count) / Double(endScores.count)
 ergebnis.eskalationsWk = Double(eskalationen) / Double(iterationen)
 return ergebnis
}

// nn Automatische Ableitung aus Falldaten (deterministisch, ohne KI) nnnnn

/// Leitet ein Start-Machtprofil und Basisoptionen aus den vorhandenen
/// Falldaten ab (Argumente, Beweise, Fristen, Warnungen, Lücken, Prognose).
static func ableitenAusFall(viewModel: CaseDetailViewModel) -> MachtAnalyseZustand {
 var z = MachtAnalyseZustand()
 let fall = viewModel.fall
 z.ziel = fall?.prozessziel ?? ""
 z.baseline = min(0.95, max(0.05, (fall?.prognose ?? 50) / 100))

 let eigenArgs = viewModel.argumente.filter { $0.side == .eigen }
 let gegnerArgs = viewModel.argumente.filter { $0.side == .gegner }
 let eigenStaerke = eigenArgs.isEmpty ? 0.5 : min(1, eigenArgs.reduce(0) { $0 + Double($1.strength) } / Double(eigenArgs.count) / 10)
 let gegnerStaerke = gegnerArgs.isEmpty ? 0.5 : min(1, gegnerArgs.reduce(0) { $0 + Double($1.strength) } / Double(gegnerArgs.count) / 10)
 let beweisKraft = viewModel.beweise.isEmpty ? 0.4 : min(1, viewModel.beweise.reduce(0) { $0 + Double($1.weight) } / Double(viewModel.beweise.count) / 10)
 let fristenGesamt = viewModel.fristen.count
 let fristenVersaeumt = viewModel.fristen.filter { $0.status == .versaeumt }.count
 let fristenQuote = fristenGesamt == 0 ? 0.6 : max(0, 1 - Double(fristenVersaeumt) / Double(max(1, fristenGesamt)) * 2)
 let kritWarnungen = viewModel.warnungen.filter { $0.severity == .kritisch && !$0.resolved }.count

 for i in z.dimensionen.indices {
   switch z.dimensionen[i].dimension {
   case .information:
     z.dimensionen[i].eigen = beweisKraft
     z.dimensionen[i].gegner = gegnerStaerke * 0.8
     z.dimensionen[i].gewicht = 1.2
   case .recht:
     z.dimensionen[i].eigen = eigenStaerke
     z.dimensionen[i].gegner = gegnerStaerke
     z.dimensionen[i].gewicht = 1.4
   case .prozessual:
     z.dimensionen[i].eigen = fristenQuote
     z.dimensionen[i].gegner = 0.5 + Double(min(3, kritWarnungen)) * 0.1
     z.dimensionen[i].gewicht = 1.1
   case .ressourcen:
     z.dimensionen[i].eigen = 0.55
     z.dimensionen[i].gegner = 0.55
   case .reputation:
     z.dimensionen[i].eigen = 0.5
     z.dimensionen[i].gegner = 0.5
     z.dimensionen[i].gewicht = 0.8
   case .netzwerk:
     z.dimensionen[i].eigen = min(1, 0.4 + Double(viewModel.personen.count) * 0.05)
     z.dimensionen[i].gegner = 0.5
     z.dimensionen[i].gewicht = 0.7
   case .zeit:
     z.dimensionen[i].eigen = fristenQuote
     z.dimensionen[i].gegner = 0.5
   }
 }

 // Basisoptionen aus starken eigenen Argumenten und Rechtslücken
 for arg in eigenArgs.sorted(by: { $0.strength > $1.strength }).prefix(4) {
   z.optionen.append(MachtOption(
     titel: arg.title,
     beschreibung: arg.description ?? "",
     rechtsgrundlage: "",
     wirkung: .herbeifuehren,
     eintrittsWk: min(0.9, Double(arg.strength) / 10),
     beeinflussbarkeit: 0.6,
     nutzbarkeit: min(0.9, 0.3 + beweisKraft * 0.6),
     folgenHandhabbarkeit: 0.6,
     reversibilitaet: 0.7,
     aufwand: 0.3,
     dimensionen: [.recht, .information],
     herkunft: .formel
   ))
 }
 for luecke in viewModel.luecken.prefix(3) {
   z.optionen.append(MachtOption(
     titel: luecke.beschreibung.count > 60 ? String(luecke.beschreibung.prefix(57)) + "…" : luecke.beschreibung,
     beschreibung: luecke.beschreibung,
     rechtsgrundlage: luecke.rechtsgrundlage ?? "",
     wirkung: .beeinflussen,
     eintrittsWk: min(0.85, Double(luecke.nutzbarkeit) / 10),
     beeinflussbarkeit: min(0.9, Double(luecke.nutzbarkeit) / 10),
     nutzbarkeit: min(0.9, Double(luecke.nutzbarkeit) / 10),
     folgenHandhabbarkeit: 0.5,
     reversibilitaet: 0.5,
     aufwand: 0.4,
     dimensionen: [.recht, .prozessual],
     herkunft: .formel
   ))
 }

 // Ressourcen aus Beweisen (Top 3) und Fristenhoheit
 for b in viewModel.beweise.sorted(by: { $0.weight > $1.weight }).prefix(3) {
   z.ressourcen.append(MachtRessource(
     titel: b.title,
     art: .information,
     zweck: .herbeifuehren,
     verfuegbarkeit: min(1, Double(b.weight) / 10),
     potenzial: min(1, Double(b.weight) / 10 + 0.15),
     hebelwirkung: min(1, Double(b.weight) / 10),
     herkunft: .formel
   ))
 }
 if fristenGesamt > 0 {
   z.ressourcen.append(MachtRessource(
     titel: "Fristen- & Terminshoheit (\(fristenGesamt) Fristen)",
     art: .zeitlich,
     zweck: .beeinflussen,
     verfuegbarkeit: fristenQuote,
     potenzial: min(1, fristenQuote + 0.2),
     hebelwirkung: 0.6,
     herkunft: .formel
   ))
 }
 return z
}
}

// MARK: - Persistenz + Store (pro Fall)

@Observable
final class MachtEinflussStore {
var zustand: MachtAnalyseZustand
var kausal: KausalPersistenz
var simulation: MachtSimulationsErgebnis = MachtSimulationsErgebnis()
var kiLaeuft = false
var kiFehler: String? = nil
private let caseId: String

private var schluessel: String { "lexara_machtanalyse_\(caseId)" }
private var kausalSchluessel: String { "lexara_kausalstrang_\(caseId)" }

init(caseId: String) {
 self.caseId = caseId
 if let data = UserDefaults.standard.data(forKey: "lexara_machtanalyse_\(caseId)"),
  let geladen = try? JSONDecoder().decode(MachtAnalyseZustand.self, from: data) {
   zustand = geladen
 } else {
   zustand = MachtAnalyseZustand()
 }
 if let data = UserDefaults.standard.data(forKey: "lexara_kausalstrang_\(caseId)"),
  let geladen = try? JSONDecoder().decode(KausalPersistenz.self, from: data) {
   kausal = geladen
 } else {
   kausal = KausalPersistenz()
 }
 simuliere()
}

func speichern() {
 if let data = try? JSONEncoder().encode(zustand) {
   UserDefaults.standard.set(data, forKey: schluessel)
 }
 if let data = try? JSONEncoder().encode(kausal) {
   UserDefaults.standard.set(data, forKey: kausalSchluessel)
 }
}

func simuliere() {
 simulation = MachtEinflussEngine.simuliere(zustand: zustand)
}

var kennzahlen: MachtKennzahlen {
 MachtEinflussEngine.kennzahlen(zustand: zustand, simulation: simulation)
}

func uebernehmeFalldaten(viewModel: CaseDetailViewModel) {
 let abgeleitet = MachtEinflussEngine.ableitenAusFall(viewModel: viewModel)
 // Manuelle/KI-Einträge behalten, Formel-Einträge ersetzen
 let manuelleOptionen = zustand.optionen.filter { $0.herkunft != .formel }
 let manuelleRessourcen = zustand.ressourcen.filter { $0.herkunft != .formel }
 zustand.dimensionen = abgeleitet.dimensionen
 zustand.baseline = abgeleitet.baseline
 if zustand.ziel.isEmpty { zustand.ziel = abgeleitet.ziel }
 zustand.optionen = abgeleitet.optionen + manuelleOptionen
 zustand.ressourcen = abgeleitet.ressourcen + manuelleRessourcen
 kausalAbleiten(viewModel: viewModel)
 simuliere()
 speichern()
}

// nn KI-Tiefenanalyse nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

@MainActor
func kiAnalyse(viewModel: CaseDetailViewModel) async {
 guard let fall = viewModel.fall else { return }
 kiLaeuft = true
 kiFehler = nil
 defer { kiLaeuft = false }

 let eigenA = viewModel.argumente.filter { $0.side == .eigen }
 let gegnerA = viewModel.argumente.filter { $0.side == .gegner }

 let prompt = """
 Du bist strategischer Chefberater einer Top-Kanzlei (Macht-, Einfluss- und Verhandlungsanalyse auf Senior-Partner-Niveau). \
 Analysiere NÜCHTERN und PRÄZISE, wie viel Macht, Einfluss und Steuerungsmöglichkeiten die eigene Seite in diesem Fall besitzt -- \
 und mit welchen legalen Hebeln (Rechtsgrundlagen, Anträge, Fristen, Beweisen, Verhandlungszügen) sich Ereignisse herbeiführen, verhindern oder beeinflussen lassen.

 FALL: \(fall.fallname)
 Rechtsgebiet: \(fall.rechtsgebiet ?? "unbekannt") | Instanz: \(fall.instanz.rawValue) | Streitwert: \(fall.streitwert.map { String(format: "%.0f €", $0) } ?? "n/a")
 Prozessziel: \(fall.prozessziel ?? zustand.ziel)
 Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")

 EIGENE ARGUMENTE:
 \(eigenA.prefix(6).map { "- \($0.title) (Stärke \($0.strength)/10)" }.joined(separator: "\n"))
 GEGNERARGUMENTE:
 \(gegnerA.prefix(6).map { "- \($0.title) (Stärke \($0.strength)/10)" }.joined(separator: "\n"))
 BEWEISE: \(viewModel.beweise.prefix(8).map { "\($0.title) (\($0.weight)/10)" }.joined(separator: ", "))
 RECHTSLÜCKEN: \(viewModel.luecken.prefix(4).map { $0.beschreibung }.joined(separator: " | "))

 LIEFERE:
 1) machtprofil: je Dimension (Information, Rechtliche Hebel, Prozessuale Kontrolle, Ressourcen, Reputation & Druck, Netzwerk & Allianzen, Zeit & Fristenhoheit) eigen/gegner als 0-100.
 2) handlungsoptionen (max 6): titel, beschreibung, rechtsgrundlage (konkrete §§!), wirkung (Herbeiführen|Verhindern|Beeinflussen), eintritts_wk, beeinflussbarkeit, nutzbarkeit, folgen_handhabbarkeit, reversibilitaet, aufwand -- alles 0-100.
 3) ressourcen (max 6): titel, art (Rechtsgrundlage|Information/Beweis|Finanziell|Personell|Reputational|Zeitlich/Frist|Netzwerk/Allianz), rechtsgrundlage, zweck (Herbeiführen|Verhindern|Beeinflussen), verfuegbarkeit, potenzial, hebelwirkung -- 0-100. Auch Ressourcen, die man BESCHAFFEN könnte.
 4) zusammenfassung: 3-5 Sätze Machtlage + wichtigste Manipulations-/Steuerungshebel (streng legal).
 Alle Angaben realistisch und juristisch fundiert, KEINE Fantasie-Paragraphen.
 """

 let schema: [String: Any] = ["type": "object", "properties": [
   "machtprofil": ["type": "array", "items": ["type": "object", "properties": [
     "dimension": ["type": "string"], "eigen": ["type": "number"], "gegner": ["type": "number"]
   ]]],
   "handlungsoptionen": ["type": "array", "items": ["type": "object", "properties": [
     "titel": ["type": "string"], "beschreibung": ["type": "string"], "rechtsgrundlage": ["type": "string"],
     "wirkung": ["type": "string"], "eintritts_wk": ["type": "number"], "beeinflussbarkeit": ["type": "number"],
     "nutzbarkeit": ["type": "number"], "folgen_handhabbarkeit": ["type": "number"],
     "reversibilitaet": ["type": "number"], "aufwand": ["type": "number"]
   ]]],
   "ressourcen": ["type": "array", "items": ["type": "object", "properties": [
     "titel": ["type": "string"], "art": ["type": "string"], "rechtsgrundlage": ["type": "string"],
     "zweck": ["type": "string"], "verfuegbarkeit": ["type": "number"],
     "potenzial": ["type": "number"], "hebelwirkung": ["type": "number"]
   ]]],
   "zusammenfassung": ["type": "string"]
 ]]

 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: schema,
     model: "claude_sonnet_4_6",
     logCaseId: fall.id,
     logKiName: "Imperium -- Macht- & Einflussanalyse"
   )

   // Machtprofil übernehmen
   let profil = KIJson.array(in: d, keys: "machtprofil")
   for eintrag in profil {
     guard let name = KIJson.string(in: eintrag, keys: "dimension") else { continue }
     if let idx = zustand.dimensionen.firstIndex(where: {
       $0.dimension.rawValue.lowercased().hasPrefix(name.lowercased().prefix(5))
       || name.lowercased().contains($0.dimension.kurz.lowercased())
     }) {
       if let e = KIJson.number(in: eintrag, keys: "eigen") { zustand.dimensionen[idx].eigen = min(1, max(0, e / 100)) }
       if let g = KIJson.number(in: eintrag, keys: "gegner") { zustand.dimensionen[idx].gegner = min(1, max(0, g / 100)) }
     }
   }

   func wirkung(_ s: String?) -> MachtWirkung {
     let l = (s ?? "").lowercased()
     if l.contains("verhind") { return .verhindern }
     if l.contains("beeinfl") { return .beeinflussen }
     return .herbeifuehren
   }
   func anteil(_ dict: [String: Any], _ keys: String...) -> Double {
     for k in keys { if let n = KIJson.number(in: dict, keys: k) { return min(1, max(0, n / 100)) } }
     return 0.5
   }

   // KI-Optionen ersetzen alte KI-Optionen, manuelle/Formel bleiben
   var neueOptionen = zustand.optionen.filter { $0.herkunft != .ki }
   for o in KIJson.array(in: d, keys: "handlungsoptionen").prefix(6) {
     guard let titel = KIJson.string(in: o, keys: "titel") else { continue }
     neueOptionen.append(MachtOption(
       titel: titel,
       beschreibung: KIJson.string(in: o, keys: "beschreibung") ?? "",
       rechtsgrundlage: KIJson.string(in: o, keys: "rechtsgrundlage") ?? "",
       wirkung: wirkung(KIJson.string(in: o, keys: "wirkung")),
       eintrittsWk: anteil(o, "eintritts_wk", "eintrittswk"),
       beeinflussbarkeit: anteil(o, "beeinflussbarkeit"),
       nutzbarkeit: anteil(o, "nutzbarkeit"),
       folgenHandhabbarkeit: anteil(o, "folgen_handhabbarkeit", "folgenhandhabbarkeit"),
       reversibilitaet: anteil(o, "reversibilitaet"),
       aufwand: anteil(o, "aufwand"),
       dimensionen: [.recht],
       herkunft: .ki
     ))
   }
   zustand.optionen = neueOptionen

   func art(_ s: String?) -> MachtRessourcenArt {
     let l = (s ?? "").lowercased()
     if l.contains("info") || l.contains("beweis") { return .information }
     if l.contains("finanz") { return .finanziell }
     if l.contains("person") { return .personell }
     if l.contains("reputat") { return .reputational }
     if l.contains("zeit") || l.contains("frist") { return .zeitlich }
     if l.contains("netz") || l.contains("allianz") { return .netzwerk }
     return .rechtsgrundlage
   }

   var neueRessourcen = zustand.ressourcen.filter { $0.herkunft != .ki }
   for r in KIJson.array(in: d, keys: "ressourcen").prefix(6) {
     guard let titel = KIJson.string(in: r, keys: "titel") else { continue }
     neueRessourcen.append(MachtRessource(
       titel: titel,
       art: art(KIJson.string(in: r, keys: "art")),
       rechtsgrundlage: KIJson.string(in: r, keys: "rechtsgrundlage") ?? "",
       zweck: wirkung(KIJson.string(in: r, keys: "zweck")),
       verfuegbarkeit: anteil(r, "verfuegbarkeit"),
       potenzial: anteil(r, "potenzial"),
       hebelwirkung: anteil(r, "hebelwirkung"),
       herkunft: .ki
     ))
   }
   zustand.ressourcen = neueRessourcen

   zustand.kiZusammenfassung = KIJson.string(in: d, keys: "zusammenfassung") ?? ""
   zustand.kiZeitpunkt = Date()
   simuliere()
   speichern()
 } catch {
   kiFehler = "KI-Analyse fehlgeschlagen: \(error.localizedDescription)"
 }
}
}

