import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// KAUSALSTRANG -- Vertikaler Ereignis-Zeitstrahl mit Interventions-Labor
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Eigenes System (keine Kopie): Ein Fall wird als Kette von Ereignissen
// modelliert. Jedes Ereignis ist STEUERBAR, TEILWEISE STEUERBAR oder NICHT
// STEUERBAR und trägt Eintritts-Wk, Zielwirkung, Machtbedarf und Kopplung
// (wie stark es Folgeereignisse mitzieht).
//
// Interventions-Labor: Pro Ereignis kann man eingreifen --
// · BEEINFLUSSEN -- Eintritts-Wk verstärken/dämpfen (proportional zur
//       Machtdeckung und Steuerbarkeit)
// · VERHINDERN -- Eintritts-Wk drücken
// · ERSETZEN -- Ereignis durch ein Alternativereignis austauschen,
//       NUR wenn die eigene Macht den Bedarf deckt
//
// Kaskaden-Modell mit MOMENTUM: Jeder realisierte Beitrag erzeugt Verlaufs-
// dynamik, die (gewichtet mit der Kopplung) auf Folgeereignisse ausstrahlt --
// Erfolge machen günstige Folgeereignisse wahrscheinlicher und ungünstige
// unwahrscheinlicher. IST-Verlauf und PLAN-Verlauf (mit Eingriffen) werden
// parallel berechnet und als vertikaler Doppel-Zielpfad visualisiert,
// zusätzlich Monte-Carlo (seeded) für die Ziel-Wahrscheinlichkeit.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Modelle

enum KausalSteuerbarkeit: String, Codable, CaseIterable, Identifiable {
case steuerbar = "Steuerbar"
case teilweise = "Teilweise steuerbar"
case nicht = "Nicht steuerbar"

var id: String { rawValue }

/// Wie viel der Eingriffskraft tatsächlich durchschlägt.
var faktor: Double {
  switch self {
  case .steuerbar: return 1.0
  case .teilweise: return 0.45
  case .nicht: return 0.0
  }
}

var farbe: Color {
  switch self {
  case .steuerbar: return Color(red: 0.20, green: 0.74, blue: 0.44)
  case .teilweise: return Color(red: 0.95, green: 0.66, blue: 0.15)
  case .nicht: return Color(red: 0.95, green: 0.36, blue: 0.32)
  }
}

var symbol: String {
  switch self {
  case .steuerbar: return "dial.high.fill"
  case .teilweise: return "dial.medium.fill"
  case .nicht: return "lock.fill"
  }
}

var kurz: String {
  switch self {
  case .steuerbar: return "steuerbar"
  case .teilweise: return "teilweise"
  case .nicht: return "nicht steuerbar"
  }
}
}

struct KausalAlternative: Codable, Identifiable, Hashable {
var id: UUID = UUID()
var titel: String
var wk: Double = 0.5 // Eintritts-Wk des Ersatzereignisses
var wirkung: Double = 0.0 // -1…+1 auf das Ziel
var machtbedarf: Double = 50 // 0…100
var rechtsgrundlage: String = ""
}

enum KausalEingriffArt: String, Codable, CaseIterable, Identifiable {
case keiner = "Kein Eingriff"
case beeinflussen = "Beeinflussen"
case verhindern = "Verhindern"
case ersetzen = "Ersetzen"

var id: String { rawValue }

var symbol: String {
  switch self {
  case .keiner: return "minus.circle"
  case .beeinflussen: return "slider.horizontal.2.arrow.trianglehead.counterclockwise"
  case .verhindern: return "hand.raised.fill"
  case .ersetzen: return "arrow.triangle.2.circlepath"
  }
}
}

struct KausalEingriff: Codable, Hashable {
var art: KausalEingriffArt = .keiner
/// -1…+1 -- nur für „Beeinflussen": negativ dämpft, positiv verstärkt die Eintritts-Wk.
var staerke: Double = 0.5
var alternativeId: UUID? = nil
}

struct KausalEreignis: Codable, Identifiable, Hashable {
var id: UUID = UUID()
var titel: String
var beschreibung: String = ""
var zeitLabel: String = "" // z. B. "12.09." oder "KW 40"
var steuerbarkeit: KausalSteuerbarkeit = .teilweise
var wk: Double = 0.5    // Basis-Eintritts-Wk
var wirkung: Double = 0.0 // -1…+1 auf das Ziel, wenn es eintritt
var machtbedarf: Double = 40 // 0…100 nötige Macht für Eingriffe
var kopplung: Double = 0.5 // 0…1 -- Ausstrahlung auf Folgeereignisse
var rechtsgrundlage: String = ""
var alternativen: [KausalAlternative] = []
var eingriff: KausalEingriff = KausalEingriff()
var herkunft: MachtHerkunft = .manuell
}

struct KausalStrang: Codable, Identifiable, Hashable {
var id: UUID = UUID()
var name: String = "Hauptverlauf"
var ereignisse: [KausalEreignis] = []
}

struct KausalPersistenz: Codable {
var straenge: [KausalStrang] = []
var aktiverStrangId: UUID? = nil
}

// MARK: - Ergebnis

struct KausalErgebnis {
struct Knoten: Identifiable {
 var id: UUID
 var titelPlan: String
 var ersetzt: Bool
 var wkIst: Double
 var wkPlan: Double
 var wirkungIst: Double
 var wirkungPlan: Double
 var zielIst: Double // kumulativer Zielpfad NACH diesem Ereignis
 var zielPlan: Double
 var momentum: Double // Verlaufsdynamik nach diesem Ereignis (Plan)
 var eingriffAktiv: Bool
 var eingriffWirksam: Bool
 var eingriffHinweis: String
}
var knoten: [Knoten] = []
var start: Double = 0.5
var endeIst: Double = 0.5
var endePlan: Double = 0.5
var mcIst: Double = 0 // Monte-Carlo: P(Endzustand >= 50 %) ohne Eingriffe
var mcPlan: Double = 0 // … mit Eingriffen
var iterationen: Int = 0
}

// MARK: - Engine

enum KausalEngine {

/// Effektiver Zustand eines Ereignisses (ggf. mit angewendetem Eingriff).
/// Rückgabe: (wk, wirkung, titel, ersetzt, wirksam, hinweis)
static func effektiv(
 _ e: KausalEreignis,
 mitEingriff: Bool,
 machtIndex: Double
) -> (wk: Double, wirkung: Double, titel: String, ersetzt: Bool, wirksam: Bool, hinweis: String) {
 let basis = (e.wk, e.wirkung, e.titel, false, false, "")
 guard mitEingriff, e.eingriff.art != .keiner else { return basis }

 let steuerF = e.steuerbarkeit.faktor
 if steuerF == 0 {
   return (e.wk, e.wirkung, e.titel, false, false, "Nicht steuerbar -- Eingriff verpufft")
 }

 // Machtdeckung: proportional bis zum Bedarf, darüber volle Kraft
 let deckung = min(1, machtIndex / max(1, e.machtbedarf))
 let kraft = steuerF * deckung

 switch e.eingriff.art {
 case .keiner:
   return basis

 case .beeinflussen:
   let neueWk = min(1, max(0, e.wk + e.eingriff.staerke * 0.6 * kraft))
   let hinweis = deckung < 1
     ? "Teilwirkung -- Macht \(Int(machtIndex)) / Bedarf \(Int(e.machtbedarf))"
     : (e.steuerbarkeit == .teilweise ? "Wirksam (teilweise steuerbar, x0,45)" : "Voll wirksam")
   return (neueWk, e.wirkung, e.titel, false, true, hinweis)

 case .verhindern:
   let neueWk = e.wk * (1 - 0.85 * kraft)
   let hinweis = deckung < 1
     ? "Teilwirkung -- Macht \(Int(machtIndex)) / Bedarf \(Int(e.machtbedarf))"
     : "Eintritts-Wk um \(Int(0.85 * kraft * 100)) % gedrückt"
   return (neueWk, e.wirkung, e.titel, false, true, hinweis)

 case .ersetzen:
   guard let alt = e.alternativen.first(where: { $0.id == e.eingriff.alternativeId }) ?? e.alternativen.first else {
     return (e.wk, e.wirkung, e.titel, false, false, "Keine Alternative definiert")
   }
   let bedarf = max(e.machtbedarf, alt.machtbedarf)
   guard machtIndex >= bedarf else {
     return (e.wk, e.wirkung, e.titel, false, false, "Macht \(Int(machtIndex)) < Bedarf \(Int(bedarf)) -- Ersetzen blockiert")
   }
   // Bei teilweiser Steuerbarkeit greift die Alternative nur anteilig (Mischverlauf)
   let neueWk = e.wk + (alt.wk - e.wk) * steuerF
   let neueWirkung = e.wirkung + (alt.wirkung - e.wirkung) * steuerF
   let hinweis = e.steuerbarkeit == .teilweise
     ? "Teilersetzung (45 %) -- Rest folgt dem Ursprungsereignis"
     : "Vollständig ersetzt"
   return (neueWk, neueWirkung, alt.titel, true, true, hinweis)
 }
}

/// Deterministische Doppel-Kaskade (IST ohne, PLAN mit Eingriffen) + Monte-Carlo.
///
/// Kaskade pro Variante:
/// wkM = clamp(wk + Momentum · 0,25 · sign(Wirkung))
/// Beitrag = wkM · Wirkung · 0,22
/// Ziel = clamp(Ziel + Beitrag)
/// Momentum = clamp(Momentum · 0,65 + Beitrag · Kopplung · 2,2)
static func berechne(
 strang: KausalStrang,
 baseline: Double,
 machtIndex: Double,
 mcIterationen: Int = 500,
 seed: UInt64 = 0xC0DE
) -> KausalErgebnis {
 var ergebnis = KausalErgebnis()
 ergebnis.start = baseline
 ergebnis.iterationen = mcIterationen
 guard !strang.ereignisse.isEmpty else {
   ergebnis.endeIst = baseline
   ergebnis.endePlan = baseline
   return ergebnis
 }

 func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
 func clamp1(_ v: Double) -> Double { min(1, max(-1, v)) }

 // nn Deterministische Kaskade nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 var zielIst = baseline, momIst = 0.0
 var zielPlan = baseline, momPlan = 0.0

 for e in strang.ereignisse {
   let ist = effektiv(e, mitEingriff: false, machtIndex: machtIndex)
   let plan = effektiv(e, mitEingriff: true, machtIndex: machtIndex)

   // IST
   let richtungIst: Double = ist.wirkung >= 0 ? 1 : -1
   let wkMIst = clamp01(ist.wk + momIst * 0.25 * richtungIst)
   let beitragIst = wkMIst * ist.wirkung * 0.22
   zielIst = clamp01(zielIst + beitragIst)
   momIst = clamp1(momIst * 0.65 + beitragIst * e.kopplung * 2.2)

   // PLAN
   let richtungPlan: Double = plan.wirkung >= 0 ? 1 : -1
   let wkMPlan = clamp01(plan.wk + momPlan * 0.25 * richtungPlan)
   let beitragPlan = wkMPlan * plan.wirkung * 0.22
   zielPlan = clamp01(zielPlan + beitragPlan)
   momPlan = clamp1(momPlan * 0.65 + beitragPlan * e.kopplung * 2.2)

   ergebnis.knoten.append(.init(
     id: e.id,
     titelPlan: plan.titel,
     ersetzt: plan.ersetzt,
     wkIst: wkMIst,
     wkPlan: wkMPlan,
     wirkungIst: ist.wirkung,
     wirkungPlan: plan.wirkung,
     zielIst: zielIst,
     zielPlan: zielPlan,
     momentum: momPlan,
     eingriffAktiv: e.eingriff.art != .keiner,
     eingriffWirksam: plan.wirksam,
     eingriffHinweis: plan.hinweis
   ))
 }
 ergebnis.endeIst = zielIst
 ergebnis.endePlan = zielPlan

 // nn Monte-Carlo (seeded) nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 guard mcIterationen > 0 else { return ergebnis }
 var rng = MachtZufall(seed: seed)
 var trefferIst = 0, trefferPlan = 0

 for _ in 0..<mcIterationen {
   var zI = baseline + (rng.double01() - 0.5) * 0.05
   var zP = zI
   var mI = 0.0, mP = 0.0

   for e in strang.ereignisse {
     let ist = effektiv(e, mitEingriff: false, machtIndex: machtIndex)
     let plan = effektiv(e, mitEingriff: true, machtIndex: machtIndex)

     let rI: Double = ist.wirkung >= 0 ? 1 : -1
     let wkI = clamp01(ist.wk + mI * 0.25 * rI)
     let zufall = rng.double01()
     if zufall < wkI {
       let b = ist.wirkung * 0.22 * (0.8 + 0.4 * rng.double01())
       zI = clamp01(zI + b)
       mI = clamp1(mI * 0.65 + b * e.kopplung * 2.2)
     } else {
       mI *= 0.8
     }

     let rP: Double = plan.wirkung >= 0 ? 1 : -1
     let wkP = clamp01(plan.wk + mP * 0.25 * rP)
     // gleicher Zufallswert (cid:222) paarige Läufe, Differenz kommt nur vom Eingriff
     if zufall < wkP {
       let b = plan.wirkung * 0.22 * (0.8 + 0.4 * rng.double01())
       zP = clamp01(zP + b)
       mP = clamp1(mP * 0.65 + b * e.kopplung * 2.2)
     } else {
       mP *= 0.8
     }
   }
   if zI >= 0.5 { trefferIst += 1 }
   if zP >= 0.5 { trefferPlan += 1 }
 }
 ergebnis.mcIst = Double(trefferIst) / Double(mcIterationen)
 ergebnis.mcPlan = Double(trefferPlan) / Double(mcIterationen)
 return ergebnis
}
}

// MARK: - Store-Erweiterung (Ableitung + KI)

extension MachtEinflussStore {

var aktiverStrang: KausalStrang? {
 if let id = kausal.aktiverStrangId, let s = kausal.straenge.first(where: { $0.id == id }) { return s }
 return kausal.straenge.first
}

func kausalErgebnis() -> KausalErgebnis {
 guard let strang = aktiverStrang else { return KausalErgebnis() }
 return KausalEngine.berechne(
   strang: strang,
   baseline: zustand.baseline,
   machtIndex: kennzahlen.machtIndex
 )
}

func kausalStrangAktualisieren(_ strang: KausalStrang) {
 if let idx = kausal.straenge.firstIndex(where: { $0.id == strang.id }) {
   kausal.straenge[idx] = strang
 } else {
   kausal.straenge.append(strang)
 }
 speichern()
}

/// Deterministische Ableitung des Ereignis-Zeitstrahls aus den Falldaten
/// (Fristen, Gegnerverhalten, Prognose). Manuelle/KI-Ereignisse bleiben.
func kausalAbleiten(viewModel: CaseDetailViewModel) {
 var strang: KausalStrang
 if let vorhanden = aktiverStrang {
   strang = vorhanden
   strang.ereignisse.removeAll { $0.herkunft == .formel }
 } else {
   strang = KausalStrang(name: "Hauptverlauf")
 }

 let df = DateFormatter()
 df.dateFormat = "dd.MM."
 var neue: [KausalEreignis] = []

 for frist in viewModel.fristen.sorted(by: { $0.due_date < $1.due_date }).prefix(5) {
   let eigene = frist.side == "Wir"
   let versaeumt = frist.status == .versaeumt
   neue.append(KausalEreignis(
     titel: "Frist: \(frist.title)",
     beschreibung: frist.description ?? "",
     zeitLabel: df.string(from: frist.due_date),
     steuerbarkeit: eigene ? .steuerbar : .teilweise,
     wk: versaeumt ? 1.0 : 0.85,
     wirkung: versaeumt ? -0.5 : (eigene ? 0.3 : -0.2),
     machtbedarf: eigene ? 30 : 55,
     kopplung: 0.55,
     rechtsgrundlage: frist.paragraph ?? "",
     alternativen: eigene ? [] : [
       KausalAlternative(
         titel: "Fristverlängerung erwirken",
         wk: 0.65, wirkung: 0.2, machtbedarf: 45,
         rechtsgrundlage: "§ 224 ZPO"
       )
     ],
     herkunft: .formel
   ))
 }

 for gv in viewModel.gegnerVerhalten.prefix(2) {
   neue.append(KausalEreignis(
     titel: "Gegnerzug: \(gv.titel)",
     beschreibung: gv.beschreibung ?? "",
     zeitLabel: String(gv.datum.prefix(10)),
     steuerbarkeit: .teilweise,
     wk: 0.6,
     wirkung: -0.35,
     machtbedarf: 65,
     kopplung: 0.6,
     alternativen: [
       KausalAlternative(
         titel: "Durch Vergleichsinitiative entschärfen",
         wk: 0.5, wirkung: 0.25, machtbedarf: 60,
         rechtsgrundlage: "§ 278 ZPO"
       )
     ],
     herkunft: .formel
   ))
 }

 let prognose = (viewModel.fall?.prognose ?? 50) / 100
 neue.append(KausalEreignis(
   titel: "Gerichtliche Entscheidung",
   beschreibung: "Finale Entscheidung -- nicht direkt steuerbar, nur über vorgelagerte Züge.",
   zeitLabel: "Ende",
   steuerbarkeit: .nicht,
   wk: 0.95,
   wirkung: (prognose - 0.5) * 1.2,
   machtbedarf: 95,
   kopplung: 0,
   herkunft: .formel
 ))

 strang.ereignisse = neue + strang.ereignisse.filter { $0.herkunft != .formel }
 kausalStrangAktualisieren(strang)
 if kausal.aktiverStrangId == nil { kausal.aktiverStrangId = strang.id }
 speichern()
}

/// KI-generierter Ereignis-Zeitstrahl mit Steuerbarkeit, Machtbedarf und Alternativen.
@MainActor
func kiKausalstrang(viewModel: CaseDetailViewModel) async {
 guard let fall = viewModel.fall else { return }
 kiLaeuft = true
 kiFehler = nil
 defer { kiLaeuft = false }

 let prompt = """
 Du bist strategischer Chefberater (Prozess- und Verhandlungsführung, Senior-Partner-Niveau). \
 Modelliere den wahrscheinlichen VERLAUF dieses Falls als Kette von 5-8 chronologischen Ereignissen (Zeitstrahl), \
 inklusive der Frage, welche Ereignisse wir STEUERN, TEILWEISE STEUERN oder NICHT STEUERN können -- \
 und durch welche legalen Alternativereignisse (mit Rechtsgrundlage!) sich einzelne Ereignisse ERSETZEN ließen, wenn genug Macht/Einfluss vorhanden ist.

 FALL: \(fall.fallname)
 Rechtsgebiet: \(fall.rechtsgebiet ?? "unbekannt") | Instanz: \(fall.instanz.rawValue)
 Prozessziel: \(fall.prozessziel ?? zustand.ziel)
 Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")
 Fristen: \(viewModel.fristen.prefix(5).map { "\($0.title) (\($0.status.rawValue))" }.joined(separator: ", "))
 Gegnerverhalten: \(viewModel.gegnerVerhalten.prefix(3).map { $0.titel }.joined(separator: ", "))
 Aktueller Macht-Index (0-100, >50 = eigene Übermacht): \(Int(kennzahlen.machtIndex))

 JE EREIGNIS:
 titel, beschreibung (1 Satz), zeit_label (z. B. "KW 38" oder "+2 Mon."), steuerbarkeit (Steuerbar|Teilweise steuerbar|Nicht steuerbar),
 wk (Eintritts-Wk 0-100), wirkung (-100…+100 auf unser Ziel), machtbedarf (0-100 nötige Macht für Eingriffe),
 kopplung (0-100, wie stark es Folgeereignisse mitzieht), rechtsgrundlage,
 alternativen (0-2 Ersatzereignisse): titel, wk, wirkung, machtbedarf, rechtsgrundlage -- nur realistische, legale Alternativen mit echten §§.
 Chronologische Reihenfolge, realistisch, juristisch fundiert.
 """

 let schema: [String: Any] = ["type": "object", "properties": [
   "ereignisse": ["type": "array", "items": ["type": "object", "properties": [
     "titel": ["type": "string"], "beschreibung": ["type": "string"], "zeit_label": ["type": "string"],
     "steuerbarkeit": ["type": "string"], "wk": ["type": "number"], "wirkung": ["type": "number"],
     "machtbedarf": ["type": "number"], "kopplung": ["type": "number"], "rechtsgrundlage": ["type": "string"],
     "alternativen": ["type": "array", "items": ["type": "object", "properties": [
       "titel": ["type": "string"], "wk": ["type": "number"], "wirkung": ["type": "number"],
       "machtbedarf": ["type": "number"], "rechtsgrundlage": ["type": "string"]
     ]]]
   ]]]
 ]]

 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: schema,
     model: "claude_sonnet_4_6",
     logCaseId: fall.id,
     logKiName: "Imperium -- Kausalstrang (Ereignis-Zeitstrahl)"
   )

   func steuerbarkeit(_ s: String?) -> KausalSteuerbarkeit {
     let l = (s ?? "").lowercased()
     if l.contains("nicht") { return .nicht }
     if l.contains("teil") { return .teilweise }
     return .steuerbar
   }
   func anteil01(_ dict: [String: Any], _ key: String, standard: Double = 0.5) -> Double {
     guard let n = KIJson.number(in: dict, keys: key) else { return standard }
     return min(1, max(0, n / 100))
   }
   func wirkungWert(_ dict: [String: Any]) -> Double {
     guard let n = KIJson.number(in: dict, keys: "wirkung") else { return 0 }
     return min(1, max(-1, n / 100))
   }

   var ereignisse: [KausalEreignis] = []
   for e in KIJson.array(in: d, keys: "ereignisse").prefix(8) {
     guard let titel = KIJson.string(in: e, keys: "titel") else { continue }
     var alternativen: [KausalAlternative] = []
     for a in KIJson.array(in: e, keys: "alternativen").prefix(2) {
       guard let at = KIJson.string(in: a, keys: "titel") else { continue }
       alternativen.append(KausalAlternative(
         titel: at,
         wk: anteil01(a, "wk"),
         wirkung: wirkungWert(a),
         machtbedarf: KIJson.number(in: a, keys: "machtbedarf") ?? 50,
         rechtsgrundlage: KIJson.string(in: a, keys: "rechtsgrundlage") ?? ""
       ))
     }
     ereignisse.append(KausalEreignis(
       titel: titel,
       beschreibung: KIJson.string(in: e, keys: "beschreibung") ?? "",
       zeitLabel: KIJson.string(in: e, keys: "zeit_label", "zeitLabel") ?? "",
       steuerbarkeit: steuerbarkeit(KIJson.string(in: e, keys: "steuerbarkeit")),
       wk: anteil01(e, "wk"),
       wirkung: wirkungWert(e),
       machtbedarf: KIJson.number(in: e, keys: "machtbedarf") ?? 40,
       kopplung: anteil01(e, "kopplung"),
       rechtsgrundlage: KIJson.string(in: e, keys: "rechtsgrundlage") ?? "",
       alternativen: alternativen,
       herkunft: .ki
     ))
   }

   guard !ereignisse.isEmpty else {
     kiFehler = "KI lieferte keinen Ereignisstrang."
     return
   }

   var strang: KausalStrang
   if let vorhanden = aktiverStrang {
     strang = vorhanden
     strang.ereignisse.removeAll { $0.herkunft == .ki }
     strang.ereignisse = ereignisse + strang.ereignisse.filter { $0.herkunft != .ki }
   } else {
     strang = KausalStrang(name: "Hauptverlauf", ereignisse: ereignisse)
   }
   kausalStrangAktualisieren(strang)
   if kausal.aktiverStrangId == nil { kausal.aktiverStrangId = strang.id }
   speichern()
 } catch {
   kiFehler = "KI-Kausalstrang fehlgeschlagen: \(error.localizedDescription)"
 }
}
}

// MARK: - Sektion (UI)

struct KausalstrangSektion: View {
let store: MachtEinflussStore
let viewModel: CaseDetailViewModel
let kiMode: Bool

@State private var ereignisInBearbeitung: KausalEreignis? = nil
@State private var strangUmbenennen: KausalStrang? = nil

private static let zeilenHoehe: CGFloat = 96

var body: some View {
 ImperiumSektion(
   titel: "Kausalstrang -- Ereignis-Zeitstrahl & Interventions-Labor",
   symbol: "arrow.trianglehead.branch",
   untertitel: "Was passiert, wenn ich ein Ereignis beeinflusse, verhindere oder ersetze -- sofern die Macht dafür reicht?",
   formel: """
   Kaskaden-Modell mit Momentum (Verlaufsdynamik):
   wkn = clamp(wk + Momentum · 0,25 · sign(Wirkung))
   Beitrag = wkn · Wirkung · 0,22 -> Ziel += Beitrag
   Momentum = clamp(Momentum · 0,65 + Beitrag · Kopplung · 2,2)

   Eingriffe (nur PLAN-Verlauf):
   Kraft = Steuerbarkeitsfaktor (1 / 0,45 / 0) · min(1, Macht-Index / Machtbedarf)
   · Beeinflussen: wk¢ = wk + Stärke · 0,6 · Kraft
   · Verhindern: wk¢ = wk · (1 - 0,85 · Kraft)
   · Ersetzen: nur wenn Macht >= max(Bedarf, Alt-Bedarf); bei „teilweise" Mischverlauf (45 %)
   Monte-Carlo: 500 paarige Läufe (gleicher Zufall für IST/PLAN) -> Ziel-Wk.
   """,
   aktion: {
     HStack(spacing: 8) {
       Button {
         var strang = store.aktiverStrang ?? {
           let neu = KausalStrang(name: "Hauptverlauf")
           store.kausal.straenge.append(neu)
           store.kausal.aktiverStrangId = neu.id
           return neu
         }()
         let neu = KausalEreignis(titel: "")
         strang.ereignisse.append(neu)
         store.kausalStrangAktualisieren(strang)
         ereignisInBearbeitung = neu
       } label: {
         Label("Ereignis", systemImage: "plus")
       }
       if kiMode {
         Button {
           Task { await store.kiKausalstrang(viewModel: viewModel) }
         } label: {
           Label("KI-Zeitstrahl", systemImage: "brain.filled.head.profile")
         }
         .disabled(store.kiLaeuft)
       }
     }
   }
 ) {
   VStack(alignment: .leading, spacing: 12) {
     strangLeiste
     legende
     if let strang = store.aktiverStrang, !strang.ereignisse.isEmpty {
       let ergebnis = store.kausalErgebnis()
       bilanzZeile(ergebnis)
       zeitstrahl(strang: strang, ergebnis: ergebnis)
     } else {
       VStack(spacing: 8) {
         Image(systemName: "arrow.trianglehead.branch")
           .font(.system(size: 22, weight: .light))
           .foregroundStyle(.tertiary)
         Text("Noch kein Ereignisstrang. „Aus Falldaten ableiten" (oben) erzeugt ihn automatisch aus Fristen, Gegnerzügen und Prognose -- oder nutze „KI-Zeitstrahl" / „+ Ereignis".")
           .font(.system(size: 11))
           .foregroundStyle(.secondary)
           .multilineTextAlignment(.center)
           .frame(maxWidth: 480)
       }
       .frame(maxWidth: .infinity)
       .padding(.vertical, 24)
     }
   }
 }
 .sheet(item: $ereignisInBearbeitung) { ereignis in
   KausalEreignisEditor(
     ereignis: ereignis,
     machtIndex: store.kennzahlen.machtIndex
   ) { neu in
     guard var strang = store.aktiverStrang else { return }
     if let idx = strang.ereignisse.firstIndex(where: { $0.id == neu.id }) {
       strang.ereignisse[idx] = neu
     } else {
       strang.ereignisse.append(neu)
     }
     store.kausalStrangAktualisieren(strang)
   } onDelete: { id in
     guard var strang = store.aktiverStrang else { return }
     strang.ereignisse.removeAll { $0.id == id }
     store.kausalStrangAktualisieren(strang)
   }
 }
}

// nn Strang-Verwaltung nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

private var strangLeiste: some View {
 ScrollView(.horizontal, showsIndicators: false) {
   HStack(spacing: 8) {
     ForEach(store.kausal.straenge) { strang in
       let aktiv = store.aktiverStrang?.id == strang.id
       Button {
         store.kausal.aktiverStrangId = strang.id
         store.speichern()
       } label: {
         HStack(spacing: 5) {
           Image(systemName: "arrow.down")
             .font(.system(size: 8, weight: .bold))
           Text(strang.name)
             .font(.system(size: 11, weight: aktiv ? .semibold : .regular))
           Text("\(strang.ereignisse.count)")
             .font(.system(size: 9, weight: .bold).monospacedDigit())
             .foregroundStyle(.secondary)
         }
         .padding(.horizontal, 10)
         .padding(.vertical, 5)
         .background(
           Capsule().fill(aktiv ? FenlynineOSTheme.accent.opacity(0.15) : FenlynineOSTheme.surfaceElevated)
         )
         .overlay(
           Capsule().stroke(aktiv ? FenlynineOSTheme.accent.opacity(0.5) : FenlynineOSTheme.border, lineWidth: 1)
         )
       }
       .buttonStyle(.plain)
       .contextMenu {
         Button("Umbenennen") { strangUmbenennen = strang }
         Button("Duplizieren (Was-wäre-wenn)") {
           var kopie = strang
           kopie.id = UUID()
           kopie.name = strang.name + " (Variante)"
           kopie.ereignisse = strang.ereignisse.map { e in
             var n = e; n.id = UUID(); return n
           }
           store.kausal.straenge.append(kopie)
           store.kausal.aktiverStrangId = kopie.id
           store.speichern()
         }
         Button("Löschen", role: .destructive) {
           store.kausal.straenge.removeAll { $0.id == strang.id }
           if store.kausal.aktiverStrangId == strang.id {
             store.kausal.aktiverStrangId = store.kausal.straenge.first?.id
           }
           store.speichern()
         }
       }
     }
     Button {
       let neu = KausalStrang(name: "Strang \(store.kausal.straenge.count + 1)")
       store.kausal.straenge.append(neu)
       store.kausal.aktiverStrangId = neu.id
       store.speichern()
     } label: {
       Image(systemName: "plus")
         .font(.system(size: 10, weight: .semibold))
         .padding(.horizontal, 8)
         .padding(.vertical, 5)
     }
     .buttonStyle(.plain)
     .help("Neuen Zeitstrahl anlegen (z. B. Eskalationsszenario)")
   }
 }
 .popover(item: $strangUmbenennen) { strang in
   StrangNameEditor(name: strang.name) { neuerName in
     if let idx = store.kausal.straenge.firstIndex(where: { $0.id == strang.id }) {
       store.kausal.straenge[idx].name = neuerName
       store.speichern()
     }
   }
 }
}

private var legende: some View {
 HStack(spacing: 14) {
   ForEach(KausalSteuerbarkeit.allCases) { s in
     HStack(spacing: 4) {
       Circle().fill(s.farbe).frame(width: 8, height: 8)
       Text(s.rawValue).font(.system(size: 9.5)).foregroundStyle(.secondary)
     }
   }
   Divider().frame(height: 10)
   HStack(spacing: 4) {
     Rectangle().fill(Color.secondary.opacity(0.5)).frame(width: 14, height: 1.5)
     Text("IST-Verlauf").font(.system(size: 9.5)).foregroundStyle(.secondary)
   }
   HStack(spacing: 4) {
     Rectangle().fill(FenlynineOSTheme.accent).frame(width: 14, height: 2.5)
     Text("PLAN mit Eingriffen").font(.system(size: 9.5)).foregroundStyle(.secondary)
   }
   Spacer()
 }
}

private func bilanzZeile(_ ergebnis: KausalErgebnis) -> some View {
 let delta = ergebnis.endePlan - ergebnis.endeIst
 let mcDelta = ergebnis.mcPlan - ergebnis.mcIst
 return HStack(spacing: 10) {
   ImperiumChip(
     text: "Zielpfad IST \(Int(ergebnis.endeIst * 100)) % -> PLAN \(Int(ergebnis.endePlan * 100)) %",
     farbe: delta >= 0 ? Color(red: 0.20, green: 0.74, blue: 0.44) : Color(red: 0.95, green: 0.36, blue: 0.32)
   )
   ImperiumChip(
     text: String(format: "Eingriffs-Effekt %+.0f Pkt.", delta * 100),
     farbe: delta >= 0.001 ? Color(red: 0.20, green: 0.74, blue: 0.44) : (delta <= -0.001 ? Color(red: 0.95, green: 0.36, blue: 0.32) : .secondary)
   )
   ImperiumChip(
     text: "Monte-Carlo Ziel-Wk \(Int(ergebnis.mcIst * 100)) % -> \(Int(ergebnis.mcPlan * 100)) % (\(String(format: "%+.0f", mcDelta * 100)))",
     farbe: FenlynineOSTheme.accent
   )
   Spacer()
 }
}

// nn Vertikaler Zeitstrahl nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

private func zeitstrahl(strang: KausalStrang, ergebnis: KausalErgebnis) -> some View {
 HStack(alignment: .top, spacing: 12) {
   VStack(spacing: 0) {
     ForEach(Array(strang.ereignisse.enumerated()), id: \.element.id) { index, ereignis in
       KausalEreignisZeile(
         ereignis: ereignis,
         knoten: index < ergebnis.knoten.count ? ergebnis.knoten[index] : nil,
         istErstes: index == 0,
         istLetztes: index == strang.ereignisse.count - 1,
         hoehe: Self.zeilenHoehe,
         onEdit: { ereignisInBearbeitung = ereignis },
         onMove: { richtung in
           var s = strang
           let neuerIndex = index + richtung
           guard neuerIndex >= 0, neuerIndex < s.ereignisse.count else { return }
           s.ereignisse.swapAt(index, neuerIndex)
           store.kausalStrangAktualisieren(s)
         },
         onDelete: {
           var s = strang
           s.ereignisse.removeAll { $0.id == ereignis.id }
           store.kausalStrangAktualisieren(s)
         }
       )
     }
   }
   KausalZielpfadView(
     ergebnis: ergebnis,
     zeilenHoehe: Self.zeilenHoehe
   )
   .frame(width: 130, height: Self.zeilenHoehe * CGFloat(strang.ereignisse.count))
 }
}
}

// MARK: - Ereignis-Zeile (Zeitstrahl-Knoten)

struct KausalEreignisZeile: View {
let ereignis: KausalEreignis
let knoten: KausalErgebnis.Knoten?
let istErstes: Bool
let istLetztes: Bool
let hoehe: CGFloat
let onEdit: () -> Void
let onMove: (Int) -> Void
let onDelete: () -> Void

var body: some View {
 HStack(alignment: .center, spacing: 10) {
   // Zeit-Label
   Text(ereignis.zeitLabel.isEmpty ? "·" : ereignis.zeitLabel)
     .font(.system(size: 9.5, weight: .medium).monospacedDigit())
     .foregroundStyle(.secondary)
     .frame(width: 44, alignment: .trailing)
     .lineLimit(2)

   // Wirbelsäule: Verbinder + Knoten
   ZStack {
     VStack(spacing: 0) {
       Rectangle()
         .fill(istErstes ? Color.clear : verbinderFarbe)
         .frame(width: 2)
       Rectangle()
         .fill(istLetztes ? Color.clear : verbinderFarbe)
         .frame(width: 2)
     }
     ZStack {
       Circle()
         .fill(ereignis.steuerbarkeit.farbe)
         .frame(width: 15, height: 15)
       if let knoten, knoten.eingriffAktiv {
         Circle()
           .stroke(knoten.eingriffWirksam ? FenlynineOSTheme.accent : Color(red: 0.95, green: 0.36, blue: 0.32), lineWidth: 2)
           .frame(width: 23, height: 23)
         if !knoten.eingriffWirksam {
           Image(systemName: "lock.fill")
             .font(.system(size: 7, weight: .bold))
             .foregroundStyle(.white)
         }
       }
     }
   }
   .frame(width: 26)
   .frame(maxHeight: .infinity)

   // Ereignis-Karte
   karte
 }
 .frame(height: hoehe)
 .contentShape(Rectangle())
 .contextMenu {
   Button("Bearbeiten & eingreifen") { onEdit() }
   Button("Nach oben") { onMove(-1) }
   Button("Nach unten") { onMove(1) }
   Button("Löschen", role: .destructive) { onDelete() }
 }
 .onTapGesture { onEdit() }
}

private var verbinderFarbe: Color {
 let kopplung = ereignis.kopplung
 return FenlynineOSTheme.accent.opacity(0.15 + 0.5 * kopplung)
}

private var karte: some View {
 VStack(alignment: .leading, spacing: 5) {
   HStack(spacing: 6) {
     if let knoten, knoten.ersetzt {
       VStack(alignment: .leading, spacing: 1) {
         Text(ereignis.titel)
           .font(.system(size: 10))
           .strikethrough()
           .foregroundStyle(.tertiary)
           .lineLimit(1)
         HStack(spacing: 4) {
           Image(systemName: "arrow.triangle.2.circlepath")
             .font(.system(size: 9, weight: .bold))
             .foregroundStyle(FenlynineOSTheme.accent)
           Text(knoten.titelPlan)
             .font(.system(size: 12, weight: .semibold))
             .foregroundStyle(FenlynineOSTheme.accent)
             .lineLimit(1)
         }
       }
     } else {
       Text(ereignis.titel)
         .font(.system(size: 12, weight: .semibold))
         .lineLimit(1)
     }
     Spacer()
     if ereignis.herkunft == .ki {
       Text("KI")
         .font(.system(size: 8, weight: .bold))
         .padding(.horizontal, 4).padding(.vertical, 1.5)
         .background(Premium.proposed.opacity(0.15), in: Capsule())
         .foregroundStyle(Premium.proposed)
     }
     Image(systemName: "slider.horizontal.3")
       .font(.system(size: 9))
       .foregroundStyle(.tertiary)
   }

   HStack(spacing: 6) {
     // Steuerbarkeit
     Label(ereignis.steuerbarkeit.kurz, systemImage: ereignis.steuerbarkeit.symbol)
       .font(.system(size: 9, weight: .semibold))
       .foregroundStyle(ereignis.steuerbarkeit.farbe)

     // Wk IST -> PLAN
     if let knoten {
       HStack(spacing: 3) {
         Text("Wk \(Int(knoten.wkIst * 100))%")
           .font(.system(size: 9).monospacedDigit())
           .foregroundStyle(.secondary)
         if abs(knoten.wkPlan - knoten.wkIst) >= 0.005 {
           Image(systemName: "arrow.right")
             .font(.system(size: 7, weight: .bold))
             .foregroundStyle(FenlynineOSTheme.accent)
           Text("\(Int(knoten.wkPlan * 100))%")
             .font(.system(size: 9, weight: .bold).monospacedDigit())
             .foregroundStyle(FenlynineOSTheme.accent)
         }
       }
       // Wirkung
       Text(String(format: "Wirkung %+.0f", (knoten.ersetzt ? knoten.wirkungPlan : ereignis.wirkung) * 100))
         .font(.system(size: 9, weight: .semibold).monospacedDigit())
         .foregroundStyle((knoten.ersetzt ? knoten.wirkungPlan : ereignis.wirkung) >= 0
                  ? Color(red: 0.20, green: 0.74, blue: 0.44)
                  : Color(red: 0.95, green: 0.36, blue: 0.32))
     }

     // Machtbedarf
     Text("Macht >= \(Int(ereignis.machtbedarf))")
       .font(.system(size: 9).monospacedDigit())
       .foregroundStyle(.tertiary)

     if !ereignis.rechtsgrundlage.isEmpty {
       Text(ereignis.rechtsgrundlage)
         .font(.system(size: 8.5, weight: .medium).monospaced())
         .padding(.horizontal, 4).padding(.vertical, 1)
         .background(FenlynineOSTheme.accent.opacity(0.1), in: Capsule())
         .foregroundStyle(FenlynineOSTheme.accent)
     }
     Spacer()
   }

   // Eingriffs-Status
   if let knoten, knoten.eingriffAktiv {
     HStack(spacing: 4) {
       Image(systemName: ereignis.eingriff.art.symbol)
         .font(.system(size: 8.5, weight: .bold))
       Text("\(ereignis.eingriff.art.rawValue): \(knoten.eingriffHinweis)")
         .font(.system(size: 9))
         .lineLimit(1)
     }
     .foregroundStyle(knoten.eingriffWirksam ? FenlynineOSTheme.accent : Color(red: 0.95, green: 0.36, blue: 0.32))
   } else if !ereignis.alternativen.isEmpty {
     Text("\(ereignis.alternativen.count) Alternativereignis(se) verfügbar -- klicken zum Eingreifen")
       .font(.system(size: 9))
       .foregroundStyle(.tertiary)
   }
 }
 .padding(.horizontal, 10)
 .padding(.vertical, 8)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(FenlynineOSTheme.surfaceElevated, in: RoundedRectangle(cornerRadius: 9))
 .overlay(
   RoundedRectangle(cornerRadius: 9)
     .stroke(
       (knoten?.eingriffAktiv ?? false)
       ? ((knoten?.eingriffWirksam ?? false) ? FenlynineOSTheme.accent.opacity(0.4) : Color(red: 0.95, green: 0.36, blue: 0.32).opacity(0.4))
       : FenlynineOSTheme.border,
       lineWidth: 1
     )
 )
 .padding(.vertical, 6)
}
}

// MARK: - Vertikaler Doppel-Zielpfad

struct KausalZielpfadView: View {
let ergebnis: KausalErgebnis
let zeilenHoehe: CGFloat

var body: some View {
 Canvas { context, size in
   let knoten = ergebnis.knoten
   guard !knoten.isEmpty else { return }

   let links: CGFloat = 6
   let rechts: CGFloat = 30
   let breite = size.width - links - rechts

   func x(_ wert: Double) -> CGFloat { links + breite * CGFloat(wert) }
   func y(_ index: Int) -> CGFloat { zeilenHoehe * CGFloat(index) + zeilenHoehe / 2 }

   // 50 %-Ziellinie (vertikal)
   var ziellinie = Path()
   ziellinie.move(to: CGPoint(x: x(0.5), y: 0))
   ziellinie.addLine(to: CGPoint(x: x(0.5), y: size.height))
   context.stroke(ziellinie, with: .color(ImperiumFarbe.gold.opacity(0.55)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

   // Skala 0/50/100 oben
   for (wert, label) in [(0.0, "0"), (0.5, "50"), (1.0, "100")] {
     context.draw(
       Text(label).font(.system(size: 7.5)).foregroundStyle(.tertiary),
       at: CGPoint(x: x(wert), y: 6)
     )
   }

   func pfad(_ werte: [Double]) -> Path {
     var p = Path()
     // Startpunkt (Baseline) leicht über der ersten Zeile
     p.move(to: CGPoint(x: x(ergebnis.start), y: max(10, y(0) - zeilenHoehe * 0.45)))
     for (i, wert) in werte.enumerated() {
       p.addLine(to: CGPoint(x: x(wert), y: y(i)))
     }
     return p
   }

   // IST (grau, gestrichelt)
   context.stroke(
     pfad(knoten.map(\.zielIst)),
     with: .color(.secondary.opacity(0.65)),
     style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [4, 3])
   )
   // PLAN (Akzent, kräftig)
   context.stroke(
     pfad(knoten.map(\.zielPlan)),
     with: .color(FenlynineOSTheme.accent),
     style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
   )

   // Delta-Flächen + Punktwerte je Zeile
   for (i, k) in knoten.enumerated() {
     // Verbindungsbalken IST«PLAN
     if abs(k.zielPlan - k.zielIst) > 0.005 {
       let von = min(k.zielIst, k.zielPlan)
       let bis = max(k.zielIst, k.zielPlan)
       let rect = CGRect(x: x(von), y: y(i) - 1.5, width: x(bis) - x(von), height: 3)
       let besser = k.zielPlan >= k.zielIst
       context.fill(
         Path(roundedRect: rect, cornerRadius: 1.5),
         with: .color((besser ? ImperiumFarbe.gruen : ImperiumFarbe.gegner).opacity(0.35))
       )
     }
     context.fill(
       Path(ellipseIn: CGRect(x: x(k.zielIst) - 2.5, y: y(i) - 2.5, width: 5, height: 5)),
       with: .color(.secondary)
     )
     context.fill(
       Path(ellipseIn: CGRect(x: x(k.zielPlan) - 3, y: y(i) - 3, width: 6, height: 6)),
       with: .color(FenlynineOSTheme.accent)
     )
     context.draw(
       Text("\(Int(k.zielPlan * 100))%")
         .font(.system(size: 8, weight: .bold).monospacedDigit())
         .foregroundStyle(FenlynineOSTheme.accent),
       at: CGPoint(x: size.width - 14, y: y(i))
     )
   }
 }
 .overlay(alignment: .topTrailing) {
   Text("Zielpfad")
     .font(.system(size: 8, weight: .semibold))
     .foregroundStyle(.tertiary)
     .padding(.trailing, 2)
 }
}
}

// MARK: - Ereignis-Editor (inkl. Interventions-Labor)

struct KausalEreignisEditor: View {
@State var ereignis: KausalEreignis
let machtIndex: Double
let onSave: (KausalEreignis) -> Void
let onDelete: (UUID) -> Void
@Environment(\.dismiss) private var dismiss

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   ScrollView {
     VStack(alignment: .leading, spacing: 14) {
       Label(ereignis.titel.isEmpty ? "Neues Ereignis" : "Ereignis & Intervention", systemImage: "arrow.trianglehead.branch")
         .font(.system(size: 13, weight: .bold))

       HStack(spacing: 10) {
         TextField("Titel (z. B. „Beweisbeschluss ergeht")", text: $ereignis.titel)
           .textFieldStyle(.roundedBorder)
         TextField("Zeit (z. B. „KW 40")", text: $ereignis.zeitLabel)
           .textFieldStyle(.roundedBorder)
           .frame(width: 110)
       }
       TextField("Beschreibung", text: $ereignis.beschreibung, axis: .vertical)
         .textFieldStyle(.roundedBorder)
         .lineLimit(1...3)
       HStack(spacing: 10) {
         TextField("Rechtsgrundlage", text: $ereignis.rechtsgrundlage)
           .textFieldStyle(.roundedBorder)
         Picker("Steuerbarkeit", selection: $ereignis.steuerbarkeit) {
           ForEach(KausalSteuerbarkeit.allCases) { s in
             Label(s.rawValue, systemImage: s.symbol).tag(s)
           }
         }
         .frame(width: 220)
       }

       Divider()

       ImperiumProzentSlider(label: "Eintritts-Wk.", wert: $ereignis.wk)
       HStack(spacing: 8) {
         Text("Zielwirkung")
           .font(.system(size: 11))
           .frame(width: 130, alignment: .leading)
         Slider(value: $ereignis.wirkung, in: -1...1)
           .tint(ereignis.wirkung >= 0 ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
         Text(String(format: "%+.0f", ereignis.wirkung * 100))
           .font(.system(size: 11, weight: .semibold).monospacedDigit())
           .foregroundStyle(ereignis.wirkung >= 0 ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
           .frame(width: 40, alignment: .trailing)
       }
       HStack(spacing: 8) {
         Text("Machtbedarf")
           .font(.system(size: 11))
           .frame(width: 130, alignment: .leading)
         Slider(value: $ereignis.machtbedarf, in: 0...100)
         Text("\(Int(ereignis.machtbedarf))")
           .font(.system(size: 11, weight: .semibold).monospacedDigit())
           .frame(width: 40, alignment: .trailing)
       }
       ImperiumProzentSlider(label: "Kopplung (Folgewirkung)", wert: $ereignis.kopplung)

       Divider()

       // nn Interventions-Labor nn
       interventionsLabor

       Divider()

       alternativenBereich
     }
     .padding(18)
   }

   Divider()
   HStack {
     Button(role: .destructive) {
       onDelete(ereignis.id)
       dismiss()
     } label: {
       Label("Löschen", systemImage: "trash")
     }
     Spacer()
     Button("Abbrechen") { dismiss() }
     Button("Speichern") {
       var gespeichert = ereignis
       if gespeichert.herkunft == .ki { gespeichert.herkunft = .manuell }
       onSave(gespeichert)
       dismiss()
     }
     .buttonStyle(.borderedProminent)
     .disabled(ereignis.titel.trimmingCharacters(in: .whitespaces).isEmpty)
   }
   .padding(14)
 }
 .frame(width: 560, height: 660)
}

// Live-Vorschau des Eingriffs
private var vorschau: (wk: Double, wirkung: Double, titel: String, ersetzt: Bool, wirksam: Bool, hinweis: String) {
 KausalEngine.effektiv(ereignis, mitEingriff: true, machtIndex: machtIndex)
}

private var interventionsLabor: some View {
 VStack(alignment: .leading, spacing: 10) {
   HStack(spacing: 6) {
     Image(systemName: "wand.and.rays")
       .foregroundStyle(ImperiumFarbe.gold)
     Text("Interventions-Labor")
       .font(.system(size: 12, weight: .bold))
     Spacer()
     Text("Verfügbare Macht: \(Int(machtIndex)) / Bedarf: \(Int(ereignis.machtbedarf))")
       .font(.system(size: 10).monospacedDigit())
       .foregroundStyle(machtIndex >= ereignis.machtbedarf ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
   }

   Picker("", selection: $ereignis.eingriff.art) {
     ForEach(KausalEingriffArt.allCases) { art in
       Text(art.rawValue).tag(art)
     }
   }
   .pickerStyle(.segmented)
   .labelsHidden()

   if ereignis.eingriff.art == .beeinflussen {
     HStack(spacing: 8) {
       Text("Richtung & Stärke")
         .font(.system(size: 11))
         .frame(width: 130, alignment: .leading)
       Slider(value: $ereignis.eingriff.staerke, in: -1...1)
         .tint(ereignis.eingriff.staerke >= 0 ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
       Text(String(format: "%+.0f %%", ereignis.eingriff.staerke * 100))
         .font(.system(size: 11, weight: .semibold).monospacedDigit())
         .frame(width: 48, alignment: .trailing)
     }
     Text("Negativ = Eintritt dämpfen, positiv = Eintritt fördern. Wirkt proportional zu Steuerbarkeit x Machtdeckung.")
       .font(.system(size: 9.5))
       .foregroundStyle(.tertiary)
   }

   if ereignis.eingriff.art == .ersetzen {
     if ereignis.alternativen.isEmpty {
       Label("Erst unten ein Alternativereignis anlegen.", systemImage: "exclamationmark.triangle")
         .font(.system(size: 10.5))
         .foregroundStyle(ImperiumFarbe.gold)
     } else {
       Picker("Ersetzen durch", selection: Binding(
         get: { ereignis.eingriff.alternativeId ?? ereignis.alternativen.first?.id },
         set: { ereignis.eingriff.alternativeId = $0 }
       )) {
         ForEach(ereignis.alternativen) { alt in
           Text("\(alt.titel) (Macht >= \(Int(alt.machtbedarf)))").tag(Optional(alt.id))
         }
       }
     }
   }

   // Live-Ergebnis
   if ereignis.eingriff.art != .keiner {
     let v = vorschau
     HStack(spacing: 8) {
       Image(systemName: v.wirksam ? "checkmark.circle.fill" : "lock.fill")
         .foregroundStyle(v.wirksam ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
       VStack(alignment: .leading, spacing: 2) {
         Text(v.hinweis)
           .font(.system(size: 10.5, weight: .semibold))
           .foregroundStyle(v.wirksam ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
         HStack(spacing: 10) {
           Text("Wk: \(Int(ereignis.wk * 100)) % -> \(Int(v.wk * 100)) %")
           Text(String(format: "Wirkung: %+.0f -> %+.0f", ereignis.wirkung * 100, v.wirkung * 100))
           if v.ersetzt { Text("Ereignis: -> \(v.titel)").lineLimit(1) }
         }
         .font(.system(size: 10).monospacedDigit())
         .foregroundStyle(.secondary)
       }
       Spacer()
     }
     .padding(10)
     .background(
       (v.wirksam ? ImperiumFarbe.gruen : ImperiumFarbe.gegner).opacity(0.07),
       in: RoundedRectangle(cornerRadius: 8)
     )
   }
 }
}

private var alternativenBereich: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Text("Alternativereignisse (für „Ersetzen")")
       .font(.system(size: 12, weight: .bold))
     Spacer()
     Button {
       ereignis.alternativen.append(KausalAlternative(titel: "Alternative \(ereignis.alternativen.count + 1)"))
     } label: {
       Label("Alternative", systemImage: "plus")
     }
     .controlSize(.small)
   }
   ForEach($ereignis.alternativen) { $alt in
     VStack(alignment: .leading, spacing: 6) {
       HStack(spacing: 8) {
         TextField("Titel des Ersatzereignisses", text: $alt.titel)
           .textFieldStyle(.roundedBorder)
         TextField("§ Rechtsgrundlage", text: $alt.rechtsgrundlage)
           .textFieldStyle(.roundedBorder)
           .frame(width: 150)
         Button {
           ereignis.alternativen.removeAll { $0.id == alt.id }
           if ereignis.eingriff.alternativeId == alt.id { ereignis.eingriff.alternativeId = nil }
         } label: {
           Image(systemName: "trash")
             .font(.system(size: 10))
         }
         .buttonStyle(.plain)
         .foregroundStyle(ImperiumFarbe.gegner)
       }
       HStack(spacing: 12) {
         kompaktSlider("Wk", wert: $alt.wk, bereich: 0...1, anzeige: "\(Int(alt.wk * 100)) %")
         kompaktSlider("Wirkung", wert: $alt.wirkung, bereich: -1...1, anzeige: String(format: "%+.0f", alt.wirkung * 100))
         kompaktSlider("Macht >=", wert: $alt.machtbedarf, bereich: 0...100, anzeige: "\(Int(alt.machtbedarf))")
       }
     }
     .padding(8)
     .background(FenlynineOSTheme.surfaceElevated, in: RoundedRectangle(cornerRadius: 8))
   }
   if ereignis.alternativen.isEmpty {
     Text("Keine Alternativen definiert. Lege Ersatzereignisse an (z. B. „Vergleich statt Urteil, § 278 ZPO"), um das Ereignis bei ausreichender Macht zu ersetzen.")
       .font(.system(size: 10))
       .foregroundStyle(.tertiary)
   }
 }
}

private func kompaktSlider(_ label: String, wert: Binding<Double>, bereich: ClosedRange<Double>, anzeige: String) -> some View {
 HStack(spacing: 5) {
   Text(label).font(.system(size: 9.5)).foregroundStyle(.secondary)
   Slider(value: wert, in: bereich)
   Text(anzeige)
     .font(.system(size: 9.5, weight: .semibold).monospacedDigit())
     .frame(width: 36, alignment: .trailing)
 }
}
}

// MARK: - Strang-Umbenennung

struct StrangNameEditor: View {
@State var name: String
let onSave: (String) -> Void
@Environment(\.dismiss) private var dismiss

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   Text("Zeitstrahl umbenennen")
     .font(.system(size: 12, weight: .bold))
   TextField("Name", text: $name)
     .textFieldStyle(.roundedBorder)
     .onSubmit { onSave(name); dismiss() }
   HStack {
     Spacer()
     Button("Übernehmen") { onSave(name); dismiss() }
       .buttonStyle(.borderedProminent)
       .controlSize(.small)
   }
 }
 .padding(14)
 .frame(width: 260)
}
}

