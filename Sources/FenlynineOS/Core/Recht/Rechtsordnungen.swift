import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// RECHTSORDNUNGEN -- die gesamte App arbeitet mehrrechtsordnungsfähig
//
// Deutschland · Schweiz · Norwegen · Japan · China
//
// FUNKTIONS-UNION-PRINZIP: Jede Funktion, die in einer Rechtsordnung existiert
// (z. B. RVG-Gebührenrechnung in DE, Forliksråd-Schlichtung in NO, nnnn in JP),
// steht in ALLEN aktiven Rechtsordnungen zur Verfügung -- fehlt sie im Zielland,
// wird sie als übertragbares Werkzeug mit Herkunftskennzeichnung ergänzt.
//
// Der Rechtsradar, die KI-Prompts und der Rechtsdaten-Ordner arbeiten
// automatisch über alle aktiven Rechtsordnungen hinweg.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum Rechtsordnung: String, CaseIterable, Identifiable, Codable {
case de, ch, no, jp, cn

var id: String { rawValue }

var name: String {
  switch self {
  case .de: return "Deutschland"
  case .ch: return "Schweiz"
  case .no: return "Norwegen"
  case .jp: return "Japan"
  case .cn: return "China"
  }
}

var flagge: String {
  switch self {
  case .de: return "nn"
  case .ch: return "nn"
  case .no: return "nn"
  case .jp: return "nn"
  case .cn: return "nn"
  }
}

var rechtstradition: String {
  switch self {
  case .de: return "Civil Law (germanisch) -- BGB/ZPO"
  case .ch: return "Civil Law -- OR/ZGB, kantonale Vielfalt"
  case .no: return "Skandinavisches Civil Law -- pragmatisch, Schlichtung zuerst"
  case .jp: return "Civil Law (dt./frz. geprägt) -- nn, konsensorientiert"
  case .cn: return "Sozialistisches Recht -- nnn (2021), staatlich gelenkt"
  }
}

var gerichtsaufbau: [String] {
  switch self {
  case .de: return ["Amtsgericht / Landgericht", "Oberlandesgericht", "Bundesgerichtshof (BGH)"]
  case .ch: return ["Bezirks-/Kantonsgericht", "Obergericht (Kanton)", "Bundesgericht (Lausanne)"]
  case .no: return ["Forliksråd (Schlichtung)", "Tingrett", "Lagmannsrett", "Høyesterett"]
  case .jp: return ["nn/nnnnn (Chihn)", "nnnnn (Kntn)", "nnnnn (Saikn)"]
  case .cn: return ["nnnnnn", "nn/nnnnnn", "nnnnnn (SPC)"]
  }
}

var amtlicheQuellen: [String] {
  switch self {
  case .de: return ["gesetze-im-internet.de", "rechtsprechung-im-internet.de", "BGH/BVerfG"]
  case .ch: return ["fedlex.admin.ch", "bger.ch (Bundesgericht)", "entscheidsuche.ch"]
  case .no: return ["lovdata.no", "domstol.no", "Norges Høyesterett"]
  case .jp: return ["e-gov.go.jp (nnnn)", "courts.go.jp (nnn)", "nnn"]
  case .cn: return ["npc.gov.cn (nnnn)", "court.gov.cn", "pkulaw / nnnn"]
  }
}

var kiSprachHinweis: String {
  switch self {
  case .de: return "Deutsches Recht: zitiere Normen als § + Gesetz (z. B. § 626 BGB)."
  case .ch: return "Schweizer Recht: zitiere Art. + Gesetz (z. B. Art. 336 OR); kantonale Zuständigkeiten beachten."
  case .no: return "Norwegisches Recht: zitiere Gesetz + § (z. B. arbeidsmiljøloven § 15-7); Forliksråd-Pflicht beachten."
  case .jp: return "Japanisches Recht: zitiere nn + n (z. B. nn709n); Namen in Original + Umschrift."
  case .cn: return "Chinesisches Recht: zitiere nn + n (z. B. nnn188n); SPC-Justizauslegungen (nnnn) einbeziehen."
  }
}

// MARK: Fristen-Pakete (Kernfristen je Rechtsordnung)

struct FristPaket {
  let titel: String
  let norm: String
  let beschreibung: String
  let tage: Int?
}

var fristenPakete: [FristPaket] {
  switch self {
  case .de: return [
    .init(titel: "Kündigungsschutzklage", norm: "§ 4 KSchG", beschreibung: "3 Wochen ab Zugang der Kündigung.", tage: 21),
    .init(titel: "Regelverjährung", norm: "§ 195 BGB", beschreibung: "3 Jahre ab Ende des Entstehungsjahres.", tage: 1095),
    .init(titel: "Berufung", norm: "§ 517 ZPO", beschreibung: "1 Monat ab Zustellung des Urteils.", tage: 30),
    .init(titel: "Mängelrüge Handelskauf", norm: "§ 377 HGB", beschreibung: "Unverzüglich nach Ablieferung.", tage: 3)
  ]
 case .ch: return [
   .init(titel: "Anfechtung Kündigung", norm: "Art. 336b OR", beschreibung: "Einsprache bis Ende Kündigungsfrist; Klage 180 Tage nach Vertragsende.", tage: 180),
   .init(titel: "Verjährung Forderungen", norm: "Art. 127 OR", beschreibung: "10 Jahre (Grundsatz), 5 Jahre für periodische Leistungen (Art. 128).", tage: 3650),
   .init(titel: "Berufung ZPO", norm: "Art. 311 ZPO-CH", beschreibung: "30 Tage ab Eröffnung des Entscheids.", tage: 30),
   .init(titel: "Betreibungsrechtlicher Rechtsvorschlag", norm: "Art. 74 SchKG", beschreibung: "10 Tage nach Zustellung des Zahlungsbefehls.", tage: 10)
 ]
 case .no: return [
   .init(titel: "Søksmål etter oppsigelse", norm: "arbeidsmiljøloven § 17-4", beschreibung: "8 Wochen Klagefrist (Kündigungsstreit), 6 Monate für Entschädigung.", tage: 56),
   .init(titel: "Foreldelse (Verjährung)", norm: "foreldelsesloven § 2", beschreibung: "3 Jahre Grundfrist ab Fälligkeit.", tage: 1095),
   .init(titel: "Anke (Berufung)", norm: "tvisteloven § 29-5", beschreibung: "1 Monat ab Zustellung.", tage: 30),
   .init(titel: "Forliksråd-Pflicht", norm: "tvisteloven § 6-2", beschreibung: "Schlichtung vor Klage grundsätzlich obligatorisch.", tage: nil)
 ]
 case .jp: return [
   .init(titel: "nnnnnnn (Kündigung)", norm: "nnnnn16n", beschreibung: "Keine starre Frist -- aber nnnn (Arbeitsschnellverfahren) früh einleiten.", tage: nil),
   .init(titel: "nnnn (Verjährung)", norm: "nn166n", beschreibung: "5 Jahre ab Kenntnis / 10 Jahre objektiv (seit Reform 2020).", tage: 1825),
   .init(titel: "nn (Berufung)", norm: "nnn285n", beschreibung: "2 Wochen ab Zustellung des Urteils.", tage: 14),
   .init(titel: "nnnnnn", norm: "nnn", beschreibung: "Beweissicheres Mahnschreiben -- Standard vor jeder Klage.", tage: nil)
 ]
 case .cn: return [
   .init(titel: "nnnn (Arbeitsschiedsverfahren)", norm: "nnnnnnnnn27n", beschreibung: "1 Jahr ab Kenntnis der Rechtsverletzung -- zwingend VOR Klage.", tage: 365),
   .init(titel: "nnnn (Verjährung)", norm: "nnn188n", beschreibung: "3 Jahre ab Kenntnis von Schaden und Schuldner.", tage: 1095),
   .init(titel: "nn (Berufung)", norm: "nnnnn171n", beschreibung: "15 Tage ab Zustellung des Urteils (Beschluss: 10 Tage).", tage: 15),
   .init(titel: "nnnn", norm: "nnnnn20n", beschreibung: "60 Tage für Verwaltungswiderspruch.", tage: 60)
 ]
 }
}

// MARK: Gebühren-/Kostenmodell

var gebuehrenModell: (titel: String, norm: String, beschreibung: String) {
 switch self {
 case .de: return ("RVG-Wertgebühren", "§ 13 RVG",
          "Gesetzliche Gebühren nach Gegenstandswert; Honorarvereinbarung nach § 3a RVG möglich.")
 case .ch: return ("Kantonale Anwaltstarife", "z. B. AnwGebV ZH",
          "Kantonal geregelte Tarife + freie Honorarvereinbarung; Erfolgshonorar (pactum de quota litis) unzulässig, pactum de palmario begrenzt zulässig.")
 case .no: return ("Salærforskrift / freie Vereinbarung", "salærforskriften § 2",
          "Öffentlicher Stundensatz für Pflichtmandate; sonst freie Vereinbarung mit Angemessenheitskontrolle (RGA pkt. 3.3).")
 case .jp: return ("nnnnn (frei seit 2004)", "nnnnnnnnn",
          "Freie Vereinbarung -- üblich: nnn (Startgebühr) + nnn (Erfolgsgebühr) nach altem nnn-Tarif als Marktreferenz.")
 case .cn: return ("nnnn (reguliert)", "nnnnnnnnnn",
          "Staatlich regulierte Rahmen + Verhandlungsspielraum; Erfolgshonorar (nnnn) bis max. 30 % -- verboten in Straf-/Familiensachen.")
 }
}

// MARK: Funktions-Pakete (Union-Prinzip: Werkzeuge wandern über Grenzen)

struct FunktionsPaket {
 let funktion: String
 let ursprung: Rechtsordnung
 let beschreibung: String
 let uebertragbar: String // Nutzen in anderen Rechtsordnungen
}

static let funktionsUnion: [FunktionsPaket] = [
 .init(funktion: "RVG-Wertgebühren-Rechner", ursprung: .de,
    beschreibung: "Gebühren nach Streitwert-Tabelle (§ 13 RVG).",
    uebertragbar: "Als Kostenschätzungs-Referenz auch für CH/NO/JP/CN-Mandate nutzbar (Honorar-Benchmark)."),
 .init(funktion: "Güte-/Schlichtungs-Gate", ursprung: .no,
    beschreibung: "Forliksråd-Pflichtprüfung vor Klage (tvisteloven § 6-2).",
    uebertragbar: "Als Vergleichs-/Mediations-Check für alle Rechtsordnungen -- DE: § 278 ZPO Güteverhandlung, JP: nn, CN: nnnn."),
 .init(funktion: "Beweissicheres Mahnschreiben", ursprung: .jp,
    beschreibung: "nnnnnn -- Post zertifiziert Inhalt und Zugang.",
    uebertragbar: "Übertragbar als Zustellungs-/Zugangsbeweis-Checkliste (DE: Einwurfeinschreiben + Zeuge, CH: Gerichtsurkunde, NO: rekommandert brev)."),
 .init(funktion: "Zwingendes Vorschaltverfahren Arbeitsrecht", ursprung: .cn,
    beschreibung: "nnnn -- Arbeitsschiedsverfahren zwingend vor Gericht (1-Jahres-Frist).",
    uebertragbar: "Als Verfahrensweichen-Check: prüft in jeder Rechtsordnung, ob ein obligatorisches Vorverfahren existiert (DE: keins, NO: Forliksråd, JP: nnnn optional)."),
 .init(funktion: "Betreibungs-Schnellverfahren", ursprung: .ch,
    beschreibung: "SchKG-Betreibung: Zahlungsbefehl ohne Gericht, Rechtsvorschlag in 10 Tagen.",
    uebertragbar: "Als Forderungs-Durchsetzungs-Vergleich: DE Mahnbescheid (§ 688 ZPO), NO forliksklage, CN nnn (nnn216n)."),
 .init(funktion: "Fristen-Kaskadenrechner", ursprung: .de,
    beschreibung: "Notfristen-Logik (ZPO) mit Wiedereinsetzungs-Prüfung (§ 233 ZPO).",
    uebertragbar: "Kaskade rechnet in jeder aktiven Rechtsordnung mit deren Fristen-Paket -- inkl. Warnung bei kürzester Frist (CN Berufung nur 15 Tage, JP nur 2 Wochen).")
]

// MARK: Radar-Impulse (Kern-Rechtswissen je Rechtsordnung)

var radarImpulse: [(norm: String, titel: String, text: String)] {
 switch self {
 case .de: return [
   ("§ 626 BGB", "Fristlose Kündigung", "Außerordentliche Kündigung nur aus wichtigem Grund; 2-Wochen-Erklärungsfrist ab Kenntnis (Abs. 2)."),
   ("§ 138 ZPO", "Wahrheitspflicht", "Parteien haben vollständig und der Wahrheit gemäß vorzutragen."),
   ("Art. 22 DSGVO", "Automatisierte Entscheidung", "Anspruch auf menschliche Intervention bei automatisierten Einzelentscheidungen.")
 ]
 case .ch: return [
   ("Art. 336 OR", "Missbräuchliche Kündigung", "Entschädigung bis 6 Monatslöhne; Kündigungsschutz schwächer als DE -- keine Weiterbeschäftigung."),
   ("Art. 2 ZGB", "Treu und Glauben", "Offenbarer Rechtsmissbrauch findet keinen Rechtsschutz -- zentrale Generalklausel."),
   ("Art. 257 ZPO-CH", "Rechtsschutz in klaren Fällen", "Schnellverfahren bei liquidem Sachverhalt und klarer Rechtslage.")
 ]
 case .no: return [
   ("arbeidsmiljøloven § 15-7", "Saklig grunn", "Kündigung nur mit sachlichem Grund; Interessenabwägung zwingend -- Standard ähnlich DE."),
   ("tvisteloven § 6-2", "Forliksråd", "Schlichtungsrat grundsätzlich obligatorische erste Instanz für Zivilklagen."),
   ("avtaleloven § 36", "Generalklausel", "Unbillige Verträge können angepasst oder aufgehoben werden -- sehr weitgehende richterliche Eingriffsbefugnis.")
 ]
 case .jp: return [
   ("nnnnn16n", "nnnnnnn", "Kündigung ohne objektiv vernünftigen Grund ist missbräuchlich und nichtig -- strengster Kündigungsschutz der 5 Rechtsordnungen."),
   ("nn709n", "nnnn (Delikt)", "Generalklausel: Vorsatz/Fahrlässigkeit + Rechtsverletzung + Schaden + Kausalität."),
   ("nnn248n", "Schadensschätzung", "Gericht darf Schadenshöhe nach freier Überzeugung schätzen, wenn Nachweis extrem schwierig.")
 ]
 case .cn: return [
   ("nnnnn39n", "Fristlose Kündigung AG", "Arbeitgeber-Kündigung nur bei gesetzlich aufgezählten Gründen -- keine Generalklausel; nnnn (Abfindung) nach 47n."),
   ("nnn577n", "Vertragsbruch", "Verschuldensunabhängige Haftung für Vertragsverletzung -- anders als DE (§ 280 BGB: Vertretenmüssen)."),
   ("nnnnnnnnnn", "SPC-Auslegungen", "Justizauslegungen des Obersten Volksgerichts wirken quasi-normativ und sind zwingend mitzuprüfen.")
 ]
 }
}
}

// MARK: - Nonisolierte Helfer (für Stores außerhalb des MainActors)

extension Rechtsordnung {
/// Aktive Rechtsordnungen direkt aus den Defaults -- ohne MainActor-Bindung.
static var aktiveAusDefaults: [Rechtsordnung] {
 let roh = UserDefaults.standard.stringArray(forKey: "fenlynineos_rechtsordnungen") ?? ["de"]
 let set = Set(roh.compactMap(Rechtsordnung.init(rawValue:)))
 let liste = Rechtsordnung.allCases.filter { set.contains($0) }
 return liste.isEmpty ? [.de] : liste
}

/// Prompt-Kopf für KI-Aufrufe aus beliebigem Kontext.
static var promptKopf: String {
 let laender = aktiveAusDefaults
 var zeilen = ["# Aktive Rechtsordnungen: " + laender.map { "\($0.flagge) \($0.name)" }.joined(separator: " · ")]
 for l in laender { zeilen.append("- \(l.name): \(l.kiSprachHinweis)") }
 if laender.count > 1 {
   zeilen.append("Rechtsvergleichend antworten, Unterschiede der Rechtsordnungen ausdrücklich benennen.")
 }
 return zeilen.joined(separator: "\n")
}
}

// MARK: - Manager (App-weit aktive Rechtsordnungen)

@MainActor
final class RechtsordnungManager: ObservableObject {
static let shared = RechtsordnungManager()

@Published var aktive: Set<Rechtsordnung> {
 didSet {
   UserDefaults.standard.set(aktive.map(\.rawValue).sorted(), forKey: "fenlynineos_rechtsordnungen")
 }
}

private init() {
 let roh = UserDefaults.standard.stringArray(forKey: "fenlynineos_rechtsordnungen") ?? ["de"]
 var set = Set(roh.compactMap(Rechtsordnung.init(rawValue:)))
 if set.isEmpty { set = [.de] }
 aktive = set
}

var aktiveSortiert: [Rechtsordnung] {
 Rechtsordnung.allCases.filter { aktive.contains($0) }
}

func umschalten(_ r: Rechtsordnung) {
 if aktive.contains(r) {
   if aktive.count > 1 { aktive.remove(r) } // mindestens eine bleibt aktiv
 } else {
   aktive.insert(r)
 }
}

/// KI-Kontextkopf: aktive Rechtsordnungen + Zitierregeln + Funktions-Union.
var kontextFuerPrompt: String {
 let laender = aktiveSortiert
 guard !laender.isEmpty else { return "" }
 var zeilen = ["# Aktive Rechtsordnungen: " + laender.map { "\($0.flagge) \($0.name)" }.joined(separator: " · ")]
 for l in laender {
   zeilen.append("- \(l.name): \(l.kiSprachHinweis)")
 }
 if laender.count > 1 {
   zeilen.append("Rechtsvergleichend antworten, Unterschiede der Rechtsordnungen ausdrücklich benennen.")
 }
 return zeilen.joined(separator: "\n")
}

/// Funktions-Union: alle Werkzeuge aller Rechtsordnungen -- in jeder verfügbar.
var verfuegbareFunktionen: [Rechtsordnung.FunktionsPaket] {
 Rechtsordnung.funktionsUnion
}
}

