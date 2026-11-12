import Foundation
import SwiftUI

// MARK: - Zentraler Graph-Store (PDF: ein Datenmodell, Live-Sync)

@Observable
final class FenlynineOSKernStore {
static let shared = FenlynineOSKernStore()

var basisSituation = ""
var ziel = ""
var knoten: [FenlynineOSKernKnoten] = []
var kanten: [FenlynineOSKernKante] = []
var ausgewaehlterId: String?
var verknuepfungsModus = false
var verknuepfungQuelleId: String?
var phase: FenlynineOSKernPhase = .planung
var verhandlungsSituation = ""
var laedt = false
var fehler: String?
var letzteAnalyse: String?
var graphRevision = 0
var letzteNeuberechnung: Date = Date()

private let persistKey = "fenlynineos_kern_graph_v1"
private var speicherTask: Task<Void, Never>?

init() { laden() }

var ausgewaehlterKnoten: FenlynineOSKernKnoten? {
  guard let id = ausgewaehlterId else { return nil }
  return knoten.first { $0.id == id }
}

var aktiveKnoten: [FenlynineOSKernKnoten] { knoten.filter { $0.status == .aktiv } }

var fortschritt: Double {
  guard !knoten.isEmpty else { return 0 }
  return Double(knoten.filter { $0.status == .erledigt }.count) / Double(knoten.count)
}

var hatNetz: Bool { !knoten.isEmpty }

var hoechsteOption: FenlynineOSKernKnoten? {
  knoten.filter { $0.typ == .option && $0.ev != nil }
    .max(by: { ($0.ev ?? 0) < ($1.ev ?? 0) })
}

// MARK: - Verknüpfungs-Modus (PDF Teil 3)

func verknuepfungStarten(mit knotenId: String) {
  verknuepfungsModus = true
  verknuepfungQuelleId = knotenId
  ausgewaehlterId = knotenId
}

func verknuepfungBeenden() {
  verknuepfungsModus = false
  verknuepfungQuelleId = nil
}

func kanteErstellen(zuId: String, typ: FenlynineOSKernKantenTyp, payload: [String: String] = [:], kausalitaet: String, origin: String) {
  guard let vonId = verknuepfungQuelleId, vonId != zuId else { return }
  let kante = FenlynineOSKernKante(
    id: "k_\(UUID().uuidString.prefix(8))",
    vonId: vonId, zuId: zuId, typ: typ,
    kausalitaet: kausalitaet, payload: payload, origin: origin
  )
  kanten.append(kante)
  graphNeuBerechnen()
  verknuepfungBeenden()
  scheduleSpeichern()
}

func graphNeuBerechnen() {
  guard let idxMap = Dictionary(uniqueKeysWithValues: knoten.enumerated().map { ($1.id, $0) }) as [String: Int]? else { return }
  for kante in kanten {
    guard let zIdx = idxMap[kante.zuId], let qIdx = idxMap[kante.vonId] else { continue }
    FenlynineOSRechenkern.wendeKanteAn(knoten: &knoten[zIdx], kante: kante, quell: knoten[qIdx])
  }
  for i in knoten.indices { FenlynineOSRechenkern.neuBerechnen(&knoten[i]) }
  graphRevision += 1
  letzteNeuberechnung = Date()
}

// MARK: - Automatisierung

func initialisiereArbeitskette() {
  guard !knoten.isEmpty else { return }
  for i in knoten.indices {
    knoten[i].status = knoten[i].tiefe == 0 ? .erledigt : .wartend
  }
  for k in knoten where k.tiefe == 1 { aktiviere(k.id) }
  aktualisierePhase()
  scheduleSpeichern()
}

func naechsterSchrittAusfuehren() -> FenlynineOSKernKnoten? {
  guard let aktiv = aktiveKnoten.sorted(by: { $0.tiefe < $1.tiefe }).first else { return nil }
 markiereErledigt(aktiv.id)
 scheduleSpeichern()
 return aktiv
}

func markiereErledigt(_ id: String) {
 guard let idx = knoten.firstIndex(where: { $0.id == id }) else { return }
 knoten[idx].status = .erledigt
 for kind in kanten.filter({ $0.vonId == id }).map(\.zuId) { aktiviere(kind) }
 aktualisierePhase()
}

func aktiviere(_ id: String) {
 guard let idx = knoten.firstIndex(where: { $0.id == id }) else { return }
 let eltern = kanten.filter { $0.zuId == id }.map(\.vonId)
 if eltern.isEmpty || eltern.allSatisfy({ elternId in
   knoten.first(where: { $0.id == elternId })?.status == .erledigt
 }) {
   knoten[idx].status = .aktiv
 }
}

func aktualisierePhase() {
 if knoten.contains(where: { $0.typ == .ereignis && $0.status == .aktiv }) { phase = .live }
 else if knoten.contains(where: { $0.modul == .advocatus && $0.status == .aktiv }) { phase = .verhandlung }
 else if aktiveKnoten.contains(where: { $0.tiefe > 2 }) { phase = .umsetzung }
 else { phase = .planung }
}

func uebernehmeNetz(knoten neu: [FenlynineOSKernKnoten], kanten neuK: [FenlynineOSKernKante], analyse: String?) {
 knoten = neu; kanten = neuK; letzteAnalyse = analyse; fehler = nil
 initialisiereArbeitskette()
 graphNeuBerechnen()
 ausgewaehlterId = knoten.first(where: { $0.tiefe == 1 })?.id ?? knoten.first?.id
 speichern()
}

func fuegeKnotenHinzu(_ neu: FenlynineOSKernKnoten, kanten neuK: [FenlynineOSKernKante] = []) {
 fuegeKnotenHinzuBatch([neu], kanten: neuK)
}

/// Mehrere Knoten/Kanten in einem Rechen- und Speicherdurchlauf (Performance).
func fuegeKnotenHinzuBatch(_ neuKnoten: [FenlynineOSKernKnoten], kanten neuK: [FenlynineOSKernKante] = []) {
 for neu in neuKnoten where !knoten.contains(where: { $0.id == neu.id }) {
   knoten.append(neu)
 }
 for k in neuK where !kanten.contains(where: { $0.id == k.id }) {
   kanten.append(k)
 }
 for neu in neuKnoten where neu.status == .aktiv {
   aktiviere(neu.id)
 }
 graphNeuBerechnen()
 aktualisierePhase()
 scheduleSpeichern()
}

func zuruecksetzen() {
 knoten = []; kanten = []; ausgewaehlterId = nil
 phase = .planung; verhandlungsSituation = ""; letzteAnalyse = nil; fehler = nil
 verknuepfungBeenden()
 speichern()
}

// MARK: - Persistenz

func scheduleSpeichern() {
 speicherTask?.cancel()
 speicherTask = Task { @MainActor in
   try? await Task.sleep(for: .milliseconds(450))
   guard !Task.isCancelled else { return }
   speichern()
 }
}

func speichern() {
 let snap = FenlynineOSKernSnapshot(
   basisSituation: basisSituation, ziel: ziel,
   knoten: knoten, kanten: kanten,
   phase: phase.rawValue, letzteAnalyse: letzteAnalyse
 )
 if let data = try? JSONEncoder().encode(snap) {
   UserDefaults.standard.set(data, forKey: persistKey)
 }
}

private func laden() {
 guard let data = UserDefaults.standard.data(forKey: persistKey),
    let snap = try? JSONDecoder().decode(FenlynineOSKernSnapshot.self, from: data) else { return }
 basisSituation = snap.basisSituation; ziel = snap.ziel
 knoten = snap.knoten; kanten = snap.kanten
 phase = FenlynineOSKernPhase(rawValue: snap.phase) ?? .planung
 letzteAnalyse = snap.letzteAnalyse
}
}

