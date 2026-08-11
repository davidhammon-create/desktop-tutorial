import Foundation
import CoreGraphics

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// PFADGRAF -- Rechenschicht + Layout (1:1 Konzept.pdf S. 4-10)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum PfadgrafEngine {

// MARK: - Beispielgraf aus Skizze / Abb. 2 (PDF S. 4)

/// A -> B -> {D->C, C, E->H->Z}; C->FnZ; F bedingt.
static func beispielGraf() -> Pfadgraf {
  var g = Pfadgraf()
  func knoten(_ k: String, _ bez: String, _ typ: PfadgrafKnotenTyp, eigen: Double = 0) -> PfadgrafKnoten {
    PfadgrafKnoten(kennung: k, typ: typ, bezeichnung: bez, ressourcen: .init(budget: 200_000, zeitTage: 180, personal: 10), eigenwert: eigen, status: typ == .ist ? .erreicht : .offen)
  }
  let a = knoten("A", "Ausgangslage", .ist, eigen: 0)
  let b = knoten("B", "Verzweigung", .geplant, eigen: 5_000)
  let d = knoten("D", "Zwischenschritt", .geplant, eigen: 8_000)
  let c = knoten("C", "Pflichtdurchgang", .geplant, eigen: 12_000)
  let e = knoten("E", "Abkürzung", .geplant, eigen: 2_000)
  let f = knoten("F", "Bedingter Zustand", .geplant, eigen: 3_000)
  let h = knoten("H", "Vor Ziel", .geplant, eigen: 4_000)
  let z = knoten("Z", "Ziel", .ziel, eigen: 100_000)
  g.knoten = [a, b, d, c, e, f, h, z]
  g.startKnotenId = a.id
  g.zielKnotenIds = [z.id]

  func kante(_ von: UUID, _ nach: UUID, _ text: String, p: Double, kosten: Double, dauer: Int, art: PfadgrafKantenArt = .moeglich, grundlage: String = "") -> PfadgrafKante {
    PfadgrafKante(von: von, nach: nach, handlung: text, kosten: kosten, dauerMinTage: dauer, dauerMaxTage: dauer + 10, pErfolg: p, verbrauch: .init(budget: kosten * 0.8, zeitTage: Double(dauer)), grundlage: grundlage, art: art)
  }

  g.kanten = [
    kante(a.id, b.id, "Ausgang setzen", p: 0.9, kosten: 5_000, dauer: 14, art: .empfohlen),
    kante(b.id, d.id, "Über Zwischenschritt", p: 0.7, kosten: 8_000, dauer: 21),
    kante(d.id, c.id, "Zu Pflichtdurchgang", p: 0.8, kosten: 6_000, dauer: 14),
    kante(b.id, c.id, "Direkt zu C", p: 0.6, kosten: 10_000, dauer: 28),
    kante(b.id, e.id, "Abkürzung wählen", p: 0.5, kosten: 4_000, dauer: 10),
    kante(c.id, f.id, "Weiter über F", p: 0.7, kosten: 7_000, dauer: 20),
    kante(f.id, z.id, "Bedingt zum Ziel", p: 0.4, kosten: 12_000, dauer: 30, art: .bedingt, grundlage: "offenes Ereignis"),
    kante(e.id, h.id, "Über H", p: 0.75, kosten: 5_000, dauer: 15),
    kante(h.id, z.id, "Zum Ziel", p: 0.85, kosten: 8_000, dauer: 20, art: .empfohlen)
  ]

  // Früheste Daten für Zeitachse
  if let i = g.knoten.firstIndex(where: { $0.id == a.id }) { g.knoten[i].fruehestesDatum = Date() }
  let kal = Calendar.current
  func offset(_ id: UUID, _ tage: Int) {
    if let i = g.knoten.firstIndex(where: { $0.id == id }) {
      g.knoten[i].fruehestesDatum = kal.date(byAdding: .day, value: tage, to: Date())
    }
  }
  offset(b.id, 14); offset(d.id, 35); offset(c.id, 49); offset(e.id, 24)
  offset(f.id, 70); offset(h.id, 39); offset(z.id, 100)
  return g
}

/// Zwickmühlen-Beispiel (PDF Abb. 5)
static func zwickmuehleBeispiel() -> Pfadgraf {
  var g = Pfadgraf()
  let a = PfadgrafKnoten(kennung: "A", typ: .ist, bezeichnung: "Eigener Zug gesetzt", status: .erreicht)
  let b = PfadgrafKnoten(kennung: "B", typ: .fremd, bezeichnung: "Zwickmühle erzeugt")
  let r1 = PfadgrafKnoten(kennung: "Rn", typ: .fremd, bezeichnung: "Reaktion 1")
  let r2 = PfadgrafKnoten(kennung: "Rn", typ: .fremd, bezeichnung: "Reaktion 2")
  let r3 = PfadgrafKnoten(kennung: "Rn", typ: .fremd, bezeichnung: "Reaktion 3")
  let g1 = PfadgrafKnoten(kennung: "Gn", typ: .geplant, bezeichnung: "Antwort 1", eigenwert: 40_000)
  let g2 = PfadgrafKnoten(kennung: "Gn", typ: .geplant, bezeichnung: "Antwort 2", eigenwert: 55_000)
  let g3 = PfadgrafKnoten(kennung: "Gn", typ: .geplant, bezeichnung: "Antwort 3", eigenwert: 35_000)
  let z = PfadgrafKnoten(kennung: "Z", typ: .ziel, bezeichnung: "Ziel", eigenwert: 100_000)
  g.knoten = [a, b, r1, r2, r3, g1, g2, g3, z]
  g.startKnotenId = a.id
  g.zielKnotenIds = [z.id]
  func k(_ v: UUID, _ n: UUID, _ t: String, p: Double, k: Double, art: PfadgrafKantenArt = .moeglich, st: PfadgrafSteuerung = .eigen) -> PfadgrafKante {
    PfadgrafKante(von: v, nach: n, handlung: t, kosten: k, dauerMinTage: 10, dauerMaxTage: 20, pErfolg: p, steuerung: st, art: art)
  }
  g.kanten = [
    k(a.id, b.id, "Zwickmühle setzen", p: 0.8, k: 5_000, art: .empfohlen),
    k(b.id, r1.id, "Gegner wählt R1", p: 0.3, k: 0, art: .fremd, st: .fremd),
    k(b.id, r2.id, "Gegner wählt R2", p: 0.4, k: 0, art: .fremd, st: .fremd),
    k(b.id, r3.id, "Gegner wählt R3", p: 0.3, k: 0, art: .fremd, st: .fremd),
    k(r1.id, g1.id, "Antwort G1", p: 0.9, k: 3_000),
    k(r2.id, g2.id, "Antwort G2", p: 0.9, k: 4_000),
    k(r3.id, g3.id, "Antwort G3", p: 0.9, k: 3_500),
    k(g1.id, z.id, "Zum Ziel", p: 0.8, k: 5_000),
    k(g2.id, z.id, "Zum Ziel", p: 0.85, k: 5_000),
    k(g3.id, z.id, "Zum Ziel", p: 0.75, k: 5_000)
  ]
  return g
}

// MARK: - Konsistenz (PDF S. 10 -- harte Sperren)

static func validiere(_ graf: Pfadgraf) -> [PfadgrafVerstoss] {
  var v: [PfadgrafVerstoss] = []
  guard let start = graf.startKnotenId else {
    v.append(.init(schwere: .sperre, text: "Kein Startknoten A gesetzt."))
    return v
  }

 // Summe ausgehender p <= 1 (hart)
 var ausgehend: [UUID: [PfadgrafKante]] = [:]
 for k in graf.kanten { ausgehend[k.von, default: []].append(k) }
 for (knotenId, kanten) in ausgehend {
   let sum = kanten.reduce(0.0) { $0 + $1.pErfolg }
   if sum > 1.0001 {
     let name = graf.knoten.first(where: { $0.id == knotenId })?.kennung ?? "?"
     v.append(.init(schwere: .sperre, text: "Knoten \(name): Summe ausgehender p = \(String(format: "%.2f", sum)) > 1 -- Pfad-EVs ungültig."))
   }
 }

 // Jeder Knoten außer A braucht eingehende Kante
 let eingehend = Set(graf.kanten.map(\.nach))
 for kn in graf.knoten where kn.id != start && !eingehend.contains(kn.id) {
   v.append(.init(schwere: .warnung, text: "Knoten \(kn.kennung) ist verwaist (keine eingehende Kante)."))
 }

 // Ziele erreichbar von A
 let erreichbar = erreichbareKnoten(von: start, in: graf)
 for zid in graf.zielKnotenIds where !erreichbar.contains(zid) {
   let name = graf.knoten.first(where: { $0.id == zid })?.kennung ?? "?"
   v.append(.init(schwere: .sperre, text: "Zielknoten \(name) ist von A aus nicht erreichbar."))
 }

 // p in Zehnerschritten
 for k in graf.kanten {
   let gerundet = (k.pErfolg * 10).rounded() / 10
   if abs(gerundet - k.pErfolg) > 0.001 {
     v.append(.init(schwere: .warnung, text: "Kante „\(k.handlung)": p nicht in Zehnerschritten (\(k.pErfolg))."))
   }
 }
 return v
}

static func erreichbareKnoten(von start: UUID, in graf: Pfadgraf) -> Set<UUID> {
 var besucht: Set<UUID> = [start]
 var queue = [start]
 var aus: [UUID: [UUID]] = [:]
 for k in graf.kanten { aus[k.von, default: []].append(k.nach) }
 while let cur = queue.first {
   queue.removeFirst()
   for n in aus[cur, default: []] where !besucht.contains(n) {
     besucht.insert(n)
     queue.append(n)
   }
 }
 return besucht
}

// MARK: - Pfadenumeration + Kennzahlen (PDF S. 10)

static func auswerten(
 _ graf: Pfadgraf,
 fristen: [VorgangFrist] = [],
 topN: Int = 10
) -> PfadgrafAuswertung {
 var result = PfadgrafAuswertung()
 result.verstosse = validiere(graf)
 let harteSperren = result.verstosse.contains { $0.schwere == .sperre }

 guard let start = graf.startKnotenId else { return result }
 let ziele = Set(graf.zielKnotenIds.isEmpty
         ? graf.knoten.filter { $0.typ == .ziel }.map(\.id)
         : graf.zielKnotenIds)
 guard !ziele.isEmpty else {
   result.verstosse.append(.init(schwere: .warnung, text: "Kein Zielknoten markiert."))
   return result
 }

 let knotenMap = Dictionary(uniqueKeysWithValues: graf.knoten.map { ($0.id, $0) })
 let kantenMap = Dictionary(uniqueKeysWithValues: graf.kanten.map { ($0.id, $0) })
 var aus: [UUID: [PfadgrafKante]] = [:]
 for k in graf.kanten { aus[k.von, default: []].append(k) }

 // Alle einfachen Pfade A->Ziel (Schleifen begrenzt)
 var alle: [PfadgrafPfad] = []
 func dfs(knotenId: UUID, knotenPfad: [UUID], kantenPfad: [UUID], schleifenZaehler: [UUID: Int]) {
   if knotenPfad.count > 24 { return } // Sicherheitsgrenze
   if ziele.contains(knotenId), knotenPfad.count > 1 {
     alle.append(bauePfad(knotenPfad, kantenPfad, knotenMap: knotenMap, kantenMap: kantenMap, graf: graf, fristen: fristen))
     // weiterlaufen erlauben? Nein -- Ziel ist Endpunkt der Bewertung
     return
   }
   for kante in aus[knotenId, default: []] {
     if knotenPfad.contains(kante.nach) {
       if kante.istSchleife {
         let c = schleifenZaehler[kante.id, default: 0]
         if c >= kante.schleifeMax { continue }
         var nz = schleifenZaehler
         nz[kante.id] = c + 1
         dfs(knotenId: kante.nach, knotenPfad: knotenPfad + [kante.nach], kantenPfad: kantenPfad + [kante.id], schleifenZaehler: nz)
       }
       continue
     }
     dfs(knotenId: kante.nach, knotenPfad: knotenPfad + [kante.nach], kantenPfad: kantenPfad + [kante.id], schleifenZaehler: schleifenZaehler)
   }
 }
 dfs(knotenId: start, knotenPfad: [start], kantenPfad: [], schleifenZaehler: [:])
 result.allePfadAnzahl = alle.count

 // Pruning: nicht gangbare zuerst filtern, dann Top-N nach Optimierung
 let sortiert = sortiere(alle, nach: graf.optimierung)
 result.pfade = Array(sortiert.prefix(topN))

 if !harteSperren, let best = result.pfade.first(where: { $0.gangbar && !$0.kantenIds.contains(where: { kantenMap[$0]?.art == .bedingt }) }) {
   result.empfohlenerPfadId = best.id
 } else if let best = result.pfade.first(where: \.gangbar) {
   result.empfohlenerPfadId = best.id
 }

 // Engpassknoten = Artikulationspunkte auf Wegen zum Ziel
 result.engpassKnotenIds = engpassKnoten(start: start, ziele: ziele, graf: graf)

 // Redundanzgrad = kantendisjunkte Pfade (approximiert via greedy)
 result.redundanzgrad = kantendisjunktePfadAnzahl(start: start, ziele: ziele, graf: graf)

 // Optionswert je Knoten
 result.optionswerte = optionswerte(graf: graf, ziele: ziele, knotenMap: knotenMap, kantenMap: kantenMap)

 // Minimax / Max / Erwartungswert rückwärts
 result.knotenWerte = knotenwerte(graf: graf, ziele: ziele)

 return result
}

private static func bauePfad(
 _ knotenIds: [UUID],
 _ kantenIds: [UUID],
 knotenMap: [UUID: PfadgrafKnoten],
 kantenMap: [UUID: PfadgrafKante],
 graf: Pfadgraf,
 fristen: [VorgangFrist]
) -> PfadgrafPfad {
 var p = 1.0
 var kosten = 0.0
 var dauer = 0.0
 var eigen = 0.0
 var gangbar = true
 var sperr: String? = nil

 // Ressourcenbilanz entlang des Pfads
 var budget = knotenMap[knotenIds[0]]?.ressourcen.budget ?? 0
 var zeit = knotenMap[knotenIds[0]]?.ressourcen.zeitTage ?? 0
 var personal = knotenMap[knotenIds[0]]?.ressourcen.personal ?? 0

 for kid in kantenIds {
   guard let k = kantenMap[kid] else { continue }
   p *= max(0, min(1, k.pErfolg))
   kosten += k.kosten
   dauer += Double(k.dauerMinTage + k.dauerMaxTage) / 2.0
   if k.verbrauch.budget > budget + 0.01 {
     gangbar = false
     sperr = "Ressourcenbilanz: Kante verbraucht \(Int(k.verbrauch.budget)) €, verfügbar \(Int(budget)) €"
   }
   if k.verbrauch.zeitTage > zeit + 0.01 {
     gangbar = false
     sperr = sperr ?? "Ressourcenbilanz: Zeitverbrauch übersteigt verfügbare Zeit"
   }
   if k.verbrauch.personal > personal + 0.01 {
     gangbar = false
     sperr = sperr ?? "Ressourcenbilanz: Personal reicht nicht"
   }
   budget = max(0, budget - k.verbrauch.budget)
   zeit = max(0, zeit - k.verbrauch.zeitTage)
   personal = max(0, personal - k.verbrauch.personal)
   // Zustand am Zielknoten der Kante übernimmt ggf. neue Ressourcen
   if let ziel = knotenMap[k.nach], ziel.ressourcen.budget > 0 {
     budget = max(budget, ziel.ressourcen.budget - k.verbrauch.budget)
   }
 }

 for nid in knotenIds {
   eigen += knotenMap[nid]?.eigenwert ?? 0
 }
 let zielId = knotenIds.last!
 let zielWert = knotenMap[zielId]?.eigenwert ?? 0
 // EV = P · (Wert(Ziel) + S Eigenwert) - Kosten -- Ziel-Eigenwert nicht doppelt
 let eigenOhneZiel = eigen - zielWert
 let ev = p * (zielWert + eigenOhneZiel) - kosten

 // Fristenkonformität
 if let endDatum = knotenMap[zielId]?.fruehestesDatum {
   if let kritische = fristen.filter(\.kritisch).min(by: { $0.datum < $1.datum }) {
     if endDatum > kritische.datum {
       gangbar = false
       sperr = "Fristenkonformität: Endknoten nach \(kritische.art)"
     }
   }
 } else if !fristen.isEmpty {
   let krit = fristen.filter(\.kritisch).map(\.tageBisAblauf).min()
   if let krit, dauer > Double(krit) {
     gangbar = false
     sperr = "Fristenkonformität: Dauer \(Int(dauer)) Tage > kritische Frist (\(krit) Tage)"
   }
 }

 return PfadgrafPfad(
   knotenIds: knotenIds, kantenIds: kantenIds,
   p: p, kosten: kosten, dauerTage: dauer,
   eigenwerteSumme: eigenOhneZiel, zielWert: zielWert, ev: ev,
   gangbar: gangbar, sperrGrund: sperr
 )
}

private static func sortiere(_ pfade: [PfadgrafPfad], nach opt: PfadgrafOptimierung) -> [PfadgrafPfad] {
 // Gangbare zuerst
 let gangbar = pfade.filter(\.gangbar)
 let rest = pfade.filter { !$0.gangbar }
 func key(_ p: PfadgrafPfad) -> Double {
   switch opt {
   case .erwartungswert: return p.ev
   case .kosten: return -p.kosten
   case .dauer: return -p.dauerTage
   case .erfolg: return p.p
   }
 }
 return gangbar.sorted { key($0) > key($1) } + rest.sorted { key($0) > key($1) }
}

// MARK: - Engpass (Artikulationspunkt bzgl. Zielerreichung)

static func engpassKnoten(start: UUID, ziele: Set<UUID>, graf: Pfadgraf) -> [UUID] {
 let alle = erreichbareKnoten(von: start, in: graf).intersection(
   // nur Knoten, die auf irgendeinem Weg zum Ziel liegen
   knotenAufWegenZumZiel(start: start, ziele: ziele, graf: graf)
 )
 var engpasse: [UUID] = []
 for kandidat in alle where kandidat != start && !ziele.contains(kandidat) {
   // Entferne Kandidat und prüfe, ob noch ein Weg zum Ziel existiert
   let gefiltert = Pfadgraf(
     knoten: graf.knoten.filter { $0.id != kandidat },
     kanten: graf.kanten.filter { $0.von != kandidat && $0.nach != kandidat },
     startKnotenId: start,
     zielKnotenIds: Array(ziele)
   )
   let nochErreichbar = erreichbareKnoten(von: start, in: gefiltert)
   if ziele.isDisjoint(with: nochErreichbar) {
     engpasse.append(kandidat)
   }
 }
 return engpasse
}

private static func knotenAufWegenZumZiel(start: UUID, ziele: Set<UUID>, graf: Pfadgraf) -> Set<UUID> {
 // Rückwärts von Zielen
 var eingehend: [UUID: [UUID]] = [:]
 for k in graf.kanten { eingehend[k.nach, default: []].append(k.von) }
 var besucht: Set<UUID> = ziele
 var queue = Array(ziele)
 while let cur = queue.first {
   queue.removeFirst()
   for v in eingehend[cur, default: []] where !besucht.contains(v) {
     besucht.insert(v)
     queue.append(v)
   }
 }
 return besucht
}

/// Greedy: wiederholtes Finden kürzester Pfade ohne Wiederverwendung von Kanten.
static func kantendisjunktePfadAnzahl(start: UUID, ziele: Set<UUID>, graf: Pfadgraf) -> Int {
 var verfuegbar = Set(graf.kanten.map(\.id))
 var count = 0
 while count < 20 {
   guard let pfad = kuerzesterPfad(start: start, ziele: ziele, graf: graf, erlaubteKanten: verfuegbar) else { break }
   count += 1
   for kid in pfad { verfuegbar.remove(kid) }
 }
 return count
}

private static func kuerzesterPfad(start: UUID, ziele: Set<UUID>, graf: Pfadgraf, erlaubteKanten: Set<UUID>) -> [UUID]? {
 var aus: [UUID: [PfadgrafKante]] = [:]
 for k in graf.kanten where erlaubteKanten.contains(k.id) { aus[k.von, default: []].append(k) }
 var prev: [UUID: (UUID, UUID)] = [:] // knoten -> (prevKnoten, kanteId)
 var queue = [start]
 var besucht: Set<UUID> = [start]
 while let cur = queue.first {
   queue.removeFirst()
   if ziele.contains(cur), cur != start {
     var kanten: [UUID] = []
     var c = cur
     while let (p, kid) = prev[c] {
       kanten.append(kid)
       c = p
       if c == start { break }
     }
     return kanten.reversed()
   }
   for k in aus[cur, default: []] where !besucht.contains(k.nach) {
     besucht.insert(k.nach)
     prev[k.nach] = (cur, k.id)
     queue.append(k.nach)
   }
 }
 return nil
}

// MARK: - Optionswert (PDF S. 5)

/// „Zahl der von ihm aus noch erreichbaren Zielzustände, gewichtet mit deren Erwartungswert."
static func optionswerte(
 graf: Pfadgraf,
 ziele: Set<UUID>,
 knotenMap: [UUID: PfadgrafKnoten],
 kantenMap: [UUID: PfadgrafKante]
) -> [UUID: Double] {
 var result: [UUID: Double] = [:]
 for kn in graf.knoten {
   let teil = Pfadgraf(knoten: graf.knoten, kanten: graf.kanten, startKnotenId: kn.id, zielKnotenIds: Array(ziele))
   let ausw = auswertenPfadeNur(teil)
   let wert = ausw.reduce(0.0) { $0 + max(0, $1.ev) }
   result[kn.id] = wert
 }
 return result
}

private static func auswertenPfadeNur(_ graf: Pfadgraf) -> [PfadgrafPfad] {
 // Leichtgewichtige Enumeration ohne Rekursion in optionswerte
 guard let start = graf.startKnotenId else { return [] }
 let ziele = Set(graf.zielKnotenIds)
 let knotenMap = Dictionary(uniqueKeysWithValues: graf.knoten.map { ($0.id, $0) })
 let kantenMap = Dictionary(uniqueKeysWithValues: graf.kanten.map { ($0.id, $0) })
 var aus: [UUID: [PfadgrafKante]] = [:]
 for k in graf.kanten { aus[k.von, default: []].append(k) }
 var alle: [PfadgrafPfad] = []
 func dfs(_ id: UUID, _ kp: [UUID], _ ka: [UUID]) {
   if kp.count > 16 { return }
   if ziele.contains(id), kp.count > 1 {
     alle.append(bauePfad(kp, ka, knotenMap: knotenMap, kantenMap: kantenMap, graf: graf, fristen: []))
     return
   }
   for k in aus[id, default: []] where !kp.contains(k.nach) {
     dfs(k.nach, kp + [k.nach], ka + [k.id])
   }
 }
 dfs(start, [start], [])
 return alle
}

// MARK: - Minimax / Max / Erwartung (PDF S. 8)

static func knotenwerte(graf: Pfadgraf, ziele: Set<UUID>) -> [UUID: Double] {
 let knotenMap = Dictionary(uniqueKeysWithValues: graf.knoten.map { ($0.id, $0) })
 var aus: [UUID: [PfadgrafKante]] = [:]
 for k in graf.kanten { aus[k.von, default: []].append(k) }
 var memo: [UUID: Double] = [:]
 var visiting: Set<UUID> = []

 func wert(_ id: UUID) -> Double {
   if let m = memo[id] { return m }
   if visiting.contains(id) { return knotenMap[id]?.eigenwert ?? 0 }
   visiting.insert(id)
   defer { visiting.remove(id) }

   let kn = knotenMap[id]
   let eigen = kn?.eigenwert ?? 0
   let nachfolger = aus[id, default: []]
   if nachfolger.isEmpty || ziele.contains(id) {
     memo[id] = eigen
     return eigen
   }

   let werte = nachfolger.map { k -> Double in
     wert(k.nach) - k.kosten
   }

   let typ = kn?.typ ?? .geplant
   let result: Double
   if typ == .fremd || nachfolger.allSatisfy({ $0.steuerung == .fremd }) {
     // Minimum (Gegner wählt ungünstigsten)
     result = (werte.min() ?? 0)
   } else if nachfolger.allSatisfy({ $0.steuerung == .zufall }) {
     let sumP = nachfolger.reduce(0.0) { $0 + $1.pErfolg }
     if sumP <= 0 { result = werte.reduce(0, +) / Double(max(1, werte.count)) }
     else {
       result = zip(nachfolger, werte).reduce(0.0) { $0 + ($1.0.pErfolg / sumP) * $1.1 }
     }
   } else {
     // Eigene Wahl = Maximum
     result = (werte.max() ?? 0)
   }
   memo[id] = result + (ziele.contains(id) ? 0 : 0) // Eigenwert der Zwischenknoten steckt in Nachfolger-Rechnung indirekt
   // PDF: Wert(Knoten) = max/min(Wert(Nachfolger) - Kosten). Eigenwert separat über EV-Pfad.
   _ = eigen
   return memo[id]!
 }

 for kn in graf.knoten { _ = wert(kn.id) }
 return memo
}

// MARK: - Layout Sugiyama-ähnlich (PDF S. 6)

static func layout(_ graf: Pfadgraf, fristen: [VorgangFrist] = [], canvas: CGSize = CGSize(width: 900, height: 640)) -> PfadgrafLayoutErgebnis {
 var ergebnis = PfadgrafLayoutErgebnis()
 guard let start = graf.startKnotenId else { return ergebnis }

 // Ebene = längste Pfaddistanz von A
 var ebene: [UUID: Int] = [start: 0]
 var geaendert = true
 while geaendert {
   geaendert = false
   for k in graf.kanten {
     let vonE = ebene[k.von] ?? -1
     if vonE < 0 { continue }
     let neu = vonE + 1
     if ebene[k.nach] == nil || ebene[k.nach]! < neu {
       // Knoten rechts/unterhalb aller Vorgänger
       let vorgaengerMax = graf.kanten.filter { $0.nach == k.nach }.compactMap { ebene[$0.von] }.max() ?? -1
       ebene[k.nach] = max(neu, vorgaengerMax + 1)
       geaendert = true
     }
   }
 }
 // Knoten ohne Ebene ans Ende
 let maxE = (ebene.values.max() ?? 0) + 1
 for kn in graf.knoten where ebene[kn.id] == nil { ebene[kn.id] = maxE }

 // Spuren je Ebene -- Kreuzungen minimieren (barycenter-Heuristik, 2 Durchläufe)
 var spuren: [UUID: Int] = [:]
 let maxEbene = ebene.values.max() ?? 0
 for e in 0...maxEbene {
   let knotenInE = graf.knoten.filter { ebene[$0.id] == e }.sorted { $0.kennung < $1.kennung }
   for (i, kn) in knotenInE.enumerated() { spuren[kn.id] = i }
 }
 for _ in 0..<2 {
   for e in 1...max(1, maxEbene) {
     let knotenInE = graf.knoten.filter { ebene[$0.id] == e }
     let scored: [(UUID, Double)] = knotenInE.map { kn in
       let preds = graf.kanten.filter { $0.nach == kn.id }.compactMap { spuren[$0.von] }
       let bary = preds.isEmpty ? Double(spuren[kn.id] ?? 0) : preds.map(Double.init).reduce(0, +) / Double(preds.count)
       return (kn.id, bary)
     }.sorted { $0.1 < $1.1 }
     for (i, pair) in scored.enumerated() { spuren[pair.0] = i }
   }
 }

 let maxSpur = spuren.values.max() ?? 0
 let padX: CGFloat = 70
 let padY: CGFloat = 50

 switch graf.layout {
 case .vertikal:
   let dy = max(80, (canvas.height - 2 * padY) / CGFloat(max(1, maxEbene)))
   let dx = max(100, (canvas.width - 2 * padX) / CGFloat(max(1, maxSpur + 1)))
   for kn in graf.knoten {
     let e = ebene[kn.id] ?? 0
     let s = spuren[kn.id] ?? 0
     ergebnis.punkte.append(.init(knotenId: kn.id, x: padX + CGFloat(s) * dx + dx / 2, y: padY + CGFloat(e) * dy, ebene: e, spur: s))
   }
   ergebnis.breite = canvas.width
   ergebnis.hoehe = padY * 2 + CGFloat(maxEbene) * dy + 40

 case .horizontal:
   let dx = max(100, (canvas.width - 2 * padX) / CGFloat(max(1, maxEbene)))
   let dy = max(70, (canvas.height - 2 * padY) / CGFloat(max(1, maxSpur + 1)))
   for kn in graf.knoten {
     let e = ebene[kn.id] ?? 0
     let s = spuren[kn.id] ?? 0
     ergebnis.punkte.append(.init(knotenId: kn.id, x: padX + CGFloat(e) * dx, y: padY + CGFloat(s) * dy + dy / 2, ebene: e, spur: s))
   }
   ergebnis.breite = padX * 2 + CGFloat(maxEbene) * dx + 80
   ergebnis.hoehe = canvas.height

 case .zeitachse:
   let startDatum = graf.knoten.first(where: { $0.id == start })?.fruehestesDatum ?? Date()
   let tage = graf.knoten.compactMap { kn -> Double? in
     guard let d = kn.fruehestesDatum else { return nil }
     return d.timeIntervalSince(startDatum) / 86_400
   }
   let maxTage = max(120, tage.max() ?? 120)
   for kn in graf.knoten {
     let t: Double
     if let d = kn.fruehestesDatum {
       t = max(0, d.timeIntervalSince(startDatum) / 86_400)
     } else {
       t = Double(ebene[kn.id] ?? 0) * (maxTage / Double(max(1, maxEbene)))
     }
     let s = spuren[kn.id] ?? 0
     let x = padX + CGFloat(t / maxTage) * (canvas.width - 2 * padX)
     let y = padY + CGFloat(s) * max(70, (canvas.height - 2 * padY) / CGFloat(max(1, maxSpur + 1))) + 40
     ergebnis.punkte.append(.init(knotenId: kn.id, x: x, y: y, ebene: Int(t), spur: s))
   }
   ergebnis.breite = canvas.width
   ergebnis.hoehe = canvas.height
   for f in fristen {
     let t = f.datum.timeIntervalSince(startDatum) / 86_400
     if t >= 0 && t <= maxTage {
       ergebnis.fristLinien.append((tage: t / maxTage, label: "\(f.art) - Tag \(Int(t))"))
     }
   }
 }

 // Manuelle Drag-Positionen überschreiben Auto-Layout (bleiben beim Layoutwechsel erhalten)
 for i in ergebnis.punkte.indices {
   let id = ergebnis.punkte[i].knotenId
   if let kn = graf.knoten.first(where: { $0.id == id }),
    let mx = kn.manuellX, let my = kn.manuellY {
     ergebnis.punkte[i].x = CGFloat(mx)
     ergebnis.punkte[i].y = CGFloat(my)
   }
 }

 // Canvas-Größe an manuelle Ausreißer anpassen
 if let maxX = ergebnis.punkte.map(\.x).max(), let maxY = ergebnis.punkte.map(\.y).max() {
   ergebnis.breite = max(ergebnis.breite, maxX + 120)
   ergebnis.hoehe = max(ergebnis.hoehe, maxY + 80)
 }

 return ergebnis
}

/// Alle manuellen Drag-Positionen zurücksetzen -> reines Auto-Layout.
static func autoLayoutZuruecksetzen(in graf: inout Pfadgraf) {
 for i in graf.knoten.indices {
   graf.knoten[i].manuellX = nil
   graf.knoten[i].manuellY = nil
 }
}

// MARK: - Knoten auf Kante einfügen (PDF S. 12)

static func knotenEinfuegen(auf kanteId: UUID, in graf: inout Pfadgraf, kennung: String = "N", bezeichnung: String = "Zwischenschritt") {
 guard let idx = graf.kanten.firstIndex(where: { $0.id == kanteId }) else { return }
 let alt = graf.kanten[idx]
 let neu = PfadgrafKnoten(kennung: kennung, typ: .geplant, bezeichnung: bezeichnung)
 graf.knoten.append(neu)
 var k1 = alt
 k1.id = UUID()
 k1.nach = neu.id
 k1.handlung = alt.handlung.isEmpty ? "bis \(kennung)" : alt.handlung
 var k2 = alt
 k2.id = UUID()
 k2.von = neu.id
 k2.handlung = "weiter"
 graf.kanten.remove(at: idx)
 graf.kanten.append(contentsOf: [k1, k2])
}

// MARK: - Pfade -> VorgangOptionen (Schritt 3 erzeugen)

static func alsOptionen(_ auswertung: PfadgrafAuswertung, graf: Pfadgraf, topN: Int = 10) -> [VorgangOption] {
 let knotenMap = Dictionary(uniqueKeysWithValues: graf.knoten.map { ($0.id, $0) })
 let kantenMap = Dictionary(uniqueKeysWithValues: graf.kanten.map { ($0.id, $0) })
 return auswertung.pfade.prefix(topN).filter(\.gangbar).enumerated().map { i, pfad in
   let labels = pfad.knotenIds.compactMap { knotenMap[$0]?.kennung }.joined(separator: "->")
   let handlungen = pfad.kantenIds.compactMap { kantenMap[$0]?.handlung }.filter { !$0.isEmpty }.joined(separator: "; ")
   let pZehn = (pfad.p * 10).rounded() / 10
   let monateMin = max(1, Int((pfad.dauerTage / 30).rounded(.down)))
   let monateMax = max(monateMin, Int((pfad.dauerTage / 30).rounded(.up)) + 1)
   return VorgangOption(
     label: "Pfad \(i + 1): \(labels)",
     beschreibung: handlungen.isEmpty ? "Weg \(labels)" : handlungen,
     kosten: OptionKosten(anwalt: pfad.kosten * 0.5, gericht: pfad.kosten * 0.2, intern: pfad.kosten * 0.2, opportunitaet: pfad.kosten * 0.1),
     chancen: OptionChancen(
       pErfolg: .formel(pZehn, "Prod p(Kante)"),
       best: .formel(pfad.zielWert + pfad.eigenwerteSumme, "Wert(Ziel)+S Eigenwert"),
       worst: .formel(-pfad.kosten, "-Kosten(Pfad)"),
       likely: .formel(pfad.ev, "EV = P·(Wert+SEigen)-Kosten")
     ),
     zeit: OptionZeit(minMonate: monateMin, maxMonate: monateMax),
     qualitativ: OptionQualitativ(reputation: 0, beziehung: 0, medien: 0, praezedenz: 0),
     bewertung: OptionBewertung(ev: .formel((pfad.ev / 1000).rounded() * 1000, "Pfadgraf-EV gerundet"))
   )
 }
}

// MARK: - Nächste Kennung

static func naechsteKennung(_ graf: Pfadgraf) -> String {
 let belegt = Set(graf.knoten.map(\.kennung))
 let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
 for ch in alphabet {
   let s = String(ch)
   if !belegt.contains(s) { return s }
 }
 return "N\(graf.knoten.count + 1)"
}
}

