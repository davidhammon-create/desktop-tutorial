import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// VORGANG-STORE -- beobachtbar, mit Schreibrechten und Ereignis-Log
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Umsetzt Teil VI (Übergabeverträge) der Prozessarchitektur:
// (cid:127) bewertung wird NUR vom Formelmotor geschrieben
// (cid:127) ereignisse[] ist nur anhängbar (nie ändern, nie löschen)
// (cid:127) entscheidung / ergebnis: nur Mensch
// (cid:127) organon_ref darf null sein
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

@Observable
final class VorgangStore {
static let shared = VorgangStore()

private let speicherKey = "fenlynineos_vorgaenge_v1"
private(set) var vorgaenge: [Vorgang] = []

/// Optionale Verbindung zum bestehenden Kausalgraph (Kern-Store).
/// Wenn gesetzt, werden Vorgänge auch als Knoten im Kern gespiegelt
/// -- additive Verknüpfung, ändert die bestehenden Knoten NICHT.
weak var kernStore: FenlynineOSKernStore?

/// Debounced Persistenz.
private var speicherTask: Task<Void, Never>?

private init() {
  laden()
  if vorgaenge.isEmpty {
    seed()
  }
}

// MARK: - Anlegen

@discardableResult
func neu(typ: VorgangTyp, titel: String, wer: String = "System") -> Vorgang {
  let kurz = naechsteKurzId()
  var v = Vorgang(kurzId: kurz, typ: typ, titel: titel)
  v.ereignisse.append(.init(was: "angelegt", wer: wer, alt: nil, neu: titel))
  vorgaenge.append(v)
  spiegleImKernStore(v)
  scheduleSpeichern()
  return v
}

private func naechsteKurzId() -> String {
  let jahr = Calendar.current.component(.year, from: .init())
  let nummer = vorgaenge.count + 1
  return String(format: "V-%d-%04d", jahr, nummer)
}

// MARK: - Zustandsmaschine

/// Prüft, ob der Übergang möglich ist (PDF Teil V).
func kannWechseln(vorgang v: Vorgang, zu: VorgangZustand) -> Bool {
  // Rücksprung ist immer erlaubt (PDF: "Rücksprung immer erlaubt, wird protokolliert").
  if zu.reihenfolge < v.zustand.reihenfolge { return true }

  switch zu {
  case .erfasst: return !v.titel.isEmpty
  case .strukturiert: return v.optionen.count >= 2
  case .bewertet: return v.optionen.allSatisfy { $0.bewertung.ev != nil && $0.bewertung.rav != nil }
  case .entschieden: return v.entscheidung != nil
  case .laufend: return v.entscheidung != nil
  case .abgeschlossen: return v.ergebnis != nil
  }
}

/// Führt einen Zustandsübergang durch (mit Ereignis-Log).
func setzeZustand(_ id: UUID, _ neu: VorgangZustand, wer: String = "Nutzer") {
  mutate(id) { v in
    let alt = v.zustand.rawValue
    v.zustand = neu
    v.ereignisse.append(.init(was: "zustandswechsel", wer: wer, alt: alt, neu: neu.rawValue))
  }
}

// MARK: - Typwechsel (DER KAUFMOMENT -- PDF Abb. 18)

/// Ein Feld ändert sich. Alles andere bleibt.
/// Alte Optionen werden zu Vorgeschichte.
func typWechseln(_ id: UUID, zu: VorgangTyp, wer: String = "Nutzer") {
  mutate(id) { v in
    let alt = v.typ.rawValue
    for i in v.optionen.indices { v.optionen[i].istVorgeschichte = true }
    v.typ = zu
    v.zustand = .strukturiert // zurück, neu bewerten
    v.ereignisse.append(.init(was: "typwechsel", wer: wer, alt: alt, neu: zu.rawValue))
  }
}

// MARK: - Optionen (Schreibrechte: Motor + Nutzer + KI)

func fuegeOptionHinzu(_ id: UUID, _ option: VorgangOption, wer: String = "Nutzer") {
  mutate(id) { v in
    v.optionen.append(option)
   v.ereignisse.append(.init(was: "option_hinzugefuegt", wer: wer, alt: nil, neu: option.label))
 }
}

/// NUR HIER darf die Bewertung geschrieben werden -- via Formelmotor.
func bewerteAlleOptionen(_ id: UUID) {
 mutate(id) { v in
   for i in v.optionen.indices {
     Formelkaskade.bewerte(&v.optionen[i])
   }
   v.ereignisse.append(.init(was: "bewertung_neu", wer: "Motor", alt: nil, neu: "Formelkaskade"))
 }
}

// MARK: - Entscheidung (nur Mensch -- Art. 22 DSGVO)

func entscheide(_ id: UUID, optionId: UUID, wer: String, abweichungGrund: String? = nil) {
 mutate(id) { v in
   v.entscheidung = .init(optionId: optionId, wer: wer, wann: .init(), abweichungGrund: abweichungGrund)
   v.zustand = .entschieden
   v.ereignisse.append(.init(was: "entscheidung", wer: wer, alt: nil, neu: optionId.uuidString))
 }
}

// MARK: - Advocatus-Protokolleintrag (Advocatus schreibt keine Bewertung, nur Ereignis)

func protokolliereAdvocatus(_ id: UUID, was: String, betrag: Double) {
 mutate(id) { v in
   v.ereignisse.append(.init(was: was, wer: "Advocatus", alt: nil, neu: InterfaceZahl.waehrung(betrag)))
 }
}

// MARK: - Ergebnis (nur Mensch -- wertvollster Datensatz)

func schliesseAb(_ id: UUID, ergebnis: Ergebnis, wer: String) {
 mutate(id) { v in
   v.ergebnis = ergebnis
   v.zustand = .abgeschlossen
   v.ereignisse.append(.init(was: "abgeschlossen", wer: wer, alt: nil, neu: ergebnis.realAusgang))
 }
}

// MARK: - Fristen

func fuegeFristHinzu(_ id: UUID, _ frist: VorgangFrist) {
 mutate(id) { v in
   v.fristen.append(frist)
   v.ereignisse.append(.init(was: "frist_hinzugefuegt", wer: frist.quelle, alt: nil, neu: frist.art))
 }
}

// MARK: - Empfehlung (nur Motor)

func setzeEmpfehlung(_ id: UUID) {
 mutate(id) { v in
   guard let best = v.optionen.filter({ !$0.istVorgeschichte })
     .max(by: { ($0.bewertung.rav?.wert ?? 0) < ($1.bewertung.rav?.wert ?? 0) })
   else { return }
   v.empfehlung = .init(
     optionId: best.id,
     score: best.bewertung.rav?.wert ?? 0,
     prognose: "Auf Basis RAV-Ranking",
     begruendung: "Höchster risikoadjustierter Wert bei Kosten \(Int(best.kosten.summe)) €"
   )
   if v.zustand.reihenfolge < VorgangZustand.bewertet.reihenfolge {
     v.zustand = .bewertet
   }
   v.ereignisse.append(.init(was: "empfehlung", wer: "Motor", alt: nil, neu: best.label))
 }
}

// MARK: - Portfolio-Zuordnung (Oportun)

func nimmInsPortfolio(_ id: UUID, programmId: UUID) {
 mutate(id) { v in
   guard v.zustand.reihenfolge >= VorgangZustand.bewertet.reihenfolge else { return }
   v.programmId = programmId
   v.ereignisse.append(.init(was: "portfolio_aufnahme", wer: "Oportun", alt: nil, neu: programmId.uuidString))
 }
}

// MARK: - Löschen

func loesche(_ id: UUID) {
 vorgaenge.removeAll { $0.id == id }
 scheduleSpeichern()
}

// MARK: - Zugriff

func vorgang(_ id: UUID) -> Vorgang? {
 vorgaenge.first { $0.id == id }
}

/// Alle Vorgänge, die in ein bestimmtes Programm gehören.
func imProgramm(_ programmId: UUID) -> [Vorgang] {
 vorgaenge.filter { $0.programmId == programmId }
}

/// Volltextsuche für das Kommandofeld nK.
func suche(_ q: String) -> [Vorgang] {
 let s = q.lowercased()
 guard !s.isEmpty else { return vorgaenge }
 return vorgaenge.filter {
   $0.titel.lowercased().contains(s)
     || $0.beschreibung.lowercased().contains(s)
     || $0.kurzId.lowercased().contains(s)
     || $0.parteien.contains { p in p.name.lowercased().contains(s) }
     || $0.rechtsgebiet.lowercased().contains(s)
 }
}

func mutate(_ id: UUID, _ block: (inout Vorgang) -> Void) {
 guard let idx = vorgaenge.firstIndex(where: { $0.id == id }) else { return }
 var v = vorgaenge[idx]
 block(&v)
 v.geaendert = .init()
 vorgaenge[idx] = v
 spiegleImKernStore(v)
 scheduleSpeichern()
}

// MARK: - Persistenz (debounced)

private func scheduleSpeichern() {
 speicherTask?.cancel()
 speicherTask = Task { [weak self] in
   try? await Task.sleep(for: .milliseconds(450))
   guard !Task.isCancelled else { return }
   await MainActor.run { self?.speichern() }
 }
}

private func speichern() {
 do {
   let data = try JSONEncoder().encode(vorgaenge)
   UserDefaults.standard.set(data, forKey: speicherKey)
 } catch {
   print("[VorgangStore] speichern fehlgeschlagen: \(error)")
 }
}

private func laden() {
 guard let data = UserDefaults.standard.data(forKey: speicherKey) else { return }
 do {
   vorgaenge = try JSONDecoder().decode([Vorgang].self, from: data)
 } catch {
   print("[VorgangStore] laden fehlgeschlagen: \(error)")
   vorgaenge = []
 }
}

// MARK: - Kausale Verknüpfung zum Kern-Store (additiv)

/// Spiegelt den Vorgang als Knoten im bestehenden Kern-Store --
/// ohne dessen bestehende Struktur zu verändern.
private func spiegleImKernStore(_ v: Vorgang) {
 guard let store = kernStore else { return }
 Task { @MainActor in
   VorgangKausalBrucke.spiegleAlsEreignis(v, in: store)
 }
}

// MARK: - Seed (Demo-Vorgänge -- helfen dem Nutzer beim Erst-Erlebnis)

private func seed() {
 let alpha = beispielAlpha()
 let beta = beispielBeta()
 let gamma = beispielGamma()
 vorgaenge = [alpha, beta, gamma]
 speichern()
}

private func beispielAlpha() -> Vorgang {
 var v = Vorgang(kurzId: "V-2026-0001", typ: .gestaltung, titel: "Alpha Holdings -- Steuerstruktur")
 v.parteien = [.init(rolle: "Mandant", name: "Alpha Holdings AG")]
 v.rechtsgebiet = "Steuerrecht"
 v.volumen = 8_000_000
 v.beschreibung = "Steueroptimierung vs. Steuerhinterziehung -- drei Wege durch die Struktur."
 v.zustand = .bewertet
 v.optionen = [
   demoOption("A · Legale Optimierung", p: 0.95, best: 2_000_000, worst: 500_000, kosten: 120_000),
   demoOption("B · Aggressive Vermeidung", p: 0.60, best: 5_000_000, worst: -1_500_000, kosten: 310_000),
   demoOption("C · Hinterziehung", p: 0.40, best: 7_000_000, worst: -12_000_000, kosten: 400_000)
 ]
 for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
 v.ereignisse = [
   .init(was: "angelegt", wer: "System", alt: nil, neu: v.titel),
   .init(was: "bewertung_neu", wer: "Motor", alt: nil, neu: "Formelkaskade")
 ]
 return v
}

private func beispielBeta() -> Vorgang {
 var v = Vorgang(kurzId: "V-2026-0002", typ: .streit, titel: "Beta GmbH ./. Schmidt -- Kündigungsschutz")
 v.parteien = [
   .init(rolle: "Mandant", name: "Beta GmbH"),
   .init(rolle: "Gegner", name: "Herr Schmidt")
 ]
 v.rechtsgebiet = "Arbeitsrecht"
 v.volumen = 42_000
 v.beschreibung = "Kündigungsschutzklage -- Zugang am 26.06.2026."
 v.zustand = .bewertet
 v.fristen = [Formelkaskade.klageFristKSchG(zugang: Date().addingTimeInterval(-15*24*3600))]
 v.optionen = [
   demoOption("A · Vergleich anbieten", p: 0.78, best: 24_000, worst: 3_200, kosten: 3_200),
   demoOption("B · Klage volle Instanz", p: 0.61, best: 42_000, worst: -9_800, kosten: 9_800),
   demoOption("C · Abfindung fordern", p: 0.70, best: 21_000, worst: 4_100, kosten: 4_100),
   demoOption("D · Nichts tun (Frist verstreicht)", p: 0.00, best: 0, worst: -42_000, kosten: 0)
 ]
 for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
 v.ereignisse = [
   .init(was: "angelegt", wer: "System", alt: nil, neu: v.titel)
 ]
 return v
}

private func beispielGamma() -> Vorgang {
 var v = Vorgang(kurzId: "V-2026-0003", typ: .streit, titel: "Gamma AG -- Lizenzstreit")
 v.parteien = [
   .init(rolle: "Mandant", name: "Gamma AG"),
   .init(rolle: "Gegner", name: "Delta Ltd.")
 ]
 v.rechtsgebiet = "IP-Recht"
 v.volumen = 620_000
 v.beschreibung = "Lizenzverletzung Softwarepatent -- Vergleich oder Klage."
 v.zustand = .bewertet
 v.optionen = [
   demoOption("A · Vergleich 420k €", p: 0.85, best: 420_000, worst: 100_000, kosten: 25_000),
   demoOption("B · Klage LG Frankfurt", p: 0.55, best: 620_000, worst: -80_000, kosten: 45_000)
 ]
 for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
 v.ereignisse = [.init(was: "angelegt", wer: "System", alt: nil, neu: v.titel)]
 return v
}

private func demoOption(_ label: String, p: Double, best: Double, worst: Double, kosten: Double) -> VorgangOption {
 VorgangOption(
   label: label,
   beschreibung: "",
   kosten: .init(anwalt: kosten * 0.6, gericht: kosten * 0.3, intern: kosten * 0.05, opportunitaet: kosten * 0.05),
   chancen: .init(
     pErfolg: .ki(p, modell: "Claude"),
     best: .mensch(best, name: "RA Dr. M."),
     worst: .mensch(worst, name: "RA Dr. M."),
     likely: .formel(best * p + worst * (1 - p), "P x best + (1-P) x worst")
   ),
   zeit: .init(minMonate: 2, maxMonate: 14),
   qualitativ: .init(reputation: 0, beziehung: 0, medien: 0, praezedenz: 0)
 )
}
}

