import Foundation
import SwiftUI

// MARK: - FenlynineOS Kern -- ein Datenmodell, ein Graph (PDF Teil 2 & 10)

enum FenlynineOSKernKnotenTyp: String, Codable, CaseIterable {
case option, risiko, frist, kosten, argument, klausel, ereignis

var bezeichnung: String {
  switch self {
  case .option: return "OPTION"
  case .risiko: return "RISIKO"
  case .frist: return "FRIST"
  case .kosten: return "KOSTEN"
  case .argument: return "ARGUMENT"
  case .klausel: return "KLAUSEL"
  case .ereignis: return "EREIGNIS"
  }
}

var symbol: String {
  switch self {
  case .option: return "arrow.triangle.branch"
  case .risiko: return "exclamationmark.triangle.fill"
  case .frist: return "calendar.badge.clock"
  case .kosten: return "eurosign.circle.fill"
  case .argument: return "quote.bubble.fill"
  case .klausel: return "doc.text.fill"
  case .ereignis: return "waveform.circle.fill"
  }
}

var farbe: Color {
  switch self {
  case .option: return FenlynineOSTheme.accent
  case .risiko: return FenlynineOSTheme.danger
  case .frist: return FenlynineOSTheme.warning
  case .kosten: return .teal
  case .argument: return .purple
  case .klausel: return .blue
  case .ereignis: return FenlynineOSTheme.success
  }
}
}

enum FenlynineOSKernKantenTyp: String, Codable, CaseIterable {
case begruendet, widerlegt, bedingt
case erhoeht_risiko, senkt_risiko
case aendert_p_erfolg, verschiebt_frist, uebergibt

var bezeichnung: String {
  switch self {
  case .begruendet: return "begründet"
  case .widerlegt: return "widerlegt"
  case .bedingt: return "bedingt (WENN->DANN)"
  case .erhoeht_risiko: return "erhöht Risiko"
  case .senkt_risiko: return "senkt Risiko"
  case .aendert_p_erfolg: return "ändert P(Erfolg)"
  case .verschiebt_frist: return "verschiebt Frist"
  case .uebergibt: return "übergibt (Sync)"
  }
}

var farbe: Color {
  switch self {
  case .begruendet: return FenlynineOSTheme.success.opacity(0.7)
  case .widerlegt: return FenlynineOSTheme.danger.opacity(0.7)
  case .bedingt: return FenlynineOSTheme.warning.opacity(0.7)
  case .erhoeht_risiko: return FenlynineOSTheme.danger
  case .senkt_risiko: return FenlynineOSTheme.success
  case .aendert_p_erfolg: return FenlynineOSTheme.accent
  case .verschiebt_frist: return FenlynineOSTheme.warning
  case .uebergibt: return Color(red: 0.45, green: 0.62, blue: 0.95)
  }
}
}

enum FenlynineOSKernModul: String, Codable, CaseIterable {
case oportun, strategos, lexara, advocatus, koordination

var bezeichnung: String {
  switch self {
  case .oportun: return "Oportun"
  case .strategos: return "Strategos"
  case .lexara: return "Lexara"
  case .advocatus: return "Advocatus"
  case .koordination: return "Koordination"
  }
}

var zeitrichtung: String {
  switch self {
  case .lexara: return "reaktiv · Vergangenheit -> jetzt"
  case .strategos: return "prospektiv · jetzt -> Zukunft"
  case .oportun: return "meta · Optionsraum"
  case .advocatus: return "live · Echtzeit-Protokoll"
  case .koordination: return "Lagebild · Steuerung"
  }
}

var leitfrage: String {
 switch self {
 case .lexara: return "Es ist passiert. Was ist jetzt mein bester Zug?"
 case .strategos: return "Wenn ich X tue -- was folgt?"
 case .oportun: return "Welche Optionen habe ich überhaupt?"
 case .advocatus: return "Was passiert gerade -- und wie reagiere ich?"
 case .koordination: return "Wo stehen wir insgesamt?"
 }
}

var schreibtischModul: SchreibtischModul? {
 switch self {
 case .strategos: return .strategos
 case .oportun: return .opportunisma
 case .lexara: return .lexara
 case .koordination: return .lagebild
 case .advocatus: return nil
 }
}

var seitenEintrag: SeitenleistenEintrag? {
 switch self {
 case .strategos: return .strategos
 case .oportun: return .opportunisma
 case .lexara: return .lexara
 case .koordination: return .dashboard
 case .advocatus: return nil
 }
}
}

enum FenlynineOSKernSchrittStatus: String, Codable {
case wartend, aktiv, erledigt, blockiert
}

struct FenlynineOSKernKnoten: Identifiable, Codable, Hashable {
var id: String
var typ: FenlynineOSKernKnotenTyp
var titel: String
var beschreibung: String
var modul: FenlynineOSKernModul
var modulAktion: String
var herkunft: String
var tiefe: Int
var status: FenlynineOSKernSchrittStatus
var automatisiert: Bool

// Zahlenfelder (Rechenkern)
var pErfolg: Double?
var gewinn: Double?
var verlust: Double?
var kosten: Double?
var rav: Double?
var ev: Double?
var rpn: Double?
var a: Int?
var b: Int?
var e: Int?
var fristDatum: String?
var fristKritisch: Bool?
var tageRestlauf: Int?

var kausalTrigger: String?

static func basis(id: String, titel: String) -> FenlynineOSKernKnoten {
 FenlynineOSKernKnoten(
   id: id, typ: .option, titel: titel,
   beschreibung: "Ausgangslage", modul: .koordination,
   modulAktion: "Lage erfassen", herkunft: "koordination.basis",
   tiefe: 0, status: .erledigt, automatisiert: false,
   pErfolg: nil, gewinn: nil, verlust: nil, kosten: nil,
   rav: nil, ev: nil, rpn: nil, a: nil, b: nil, e: nil,
   fristDatum: nil, fristKritisch: nil, tageRestlauf: nil,
   kausalTrigger: nil
 )
}
}

struct FenlynineOSKernKante: Identifiable, Codable, Hashable {
var id: String
var vonId: String
var zuId: String
var typ: FenlynineOSKernKantenTyp
var kausalitaet: String
var payload: [String: String]
var origin: String
var zeitstempel: Date

init(
 id: String, vonId: String, zuId: String, typ: FenlynineOSKernKantenTyp,
 kausalitaet: String, payload: [String: String] = [:],
 origin: String, zeitstempel: Date = Date()
) {
 self.id = id; self.vonId = vonId; self.zuId = zuId; self.typ = typ
 self.kausalitaet = kausalitaet; self.payload = payload
 self.origin = origin; self.zeitstempel = zeitstempel
}
}

struct FenlynineOSKernSnapshot: Codable {
var basisSituation: String
var ziel: String
var knoten: [FenlynineOSKernKnoten]
var kanten: [FenlynineOSKernKante]
var phase: String
var letzteAnalyse: String?
}

enum FenlynineOSKernPhase: String, CaseIterable, Codable {
case planung, umsetzung, verhandlung, gericht, live

var bezeichnung: String {
 switch self {
 case .planung: return "Planung"
 case .umsetzung: return "Umsetzung"
 case .verhandlung: return "Verhandlung"
 case .gericht: return "Gericht"
 case .live: return "Live"
 }
}
}

// MARK: - Radiales Layout (Spinnennetz)

enum FenlynineOSKernLayout {
static let knotenRadius: CGFloat = 34

static func positionen(knoten: [FenlynineOSKernKnoten], in groesse: CGSize) -> [String: CGPoint] {
 guard !knoten.isEmpty else { return [:] }
 let cx = groesse.width / 2, cy = groesse.height / 2
 let basisR = min(groesse.width, groesse.height) * 0.14
 let ring = min(groesse.width, groesse.height) * 0.11
 var byDepth: [Int: [FenlynineOSKernKnoten]] = [:]
 for k in knoten { byDepth[k.tiefe, default: []].append(k) }
 for d in byDepth.keys { byDepth[d]?.sort { $0.titel < $1.titel } }
 var result: [String: CGPoint] = [:]
 for (tiefe, gruppe) in byDepth {
   let n = max(gruppe.count, 1)
   let radius = tiefe == 0 ? 0 : basisR + CGFloat(tiefe) * ring
   for (i, k) in gruppe.enumerated() {
     if tiefe == 0 { result[k.id] = CGPoint(x: cx, y: cy) }
     else {
       let w = (Double(i) / Double(n)) * 2 * .pi - .pi / 2
       result[k.id] = CGPoint(x: cx + radius * CGFloat(cos(w)), y: cy + radius * CGFloat(sin(w)))
     }
   }
 }
 return result
}
}

