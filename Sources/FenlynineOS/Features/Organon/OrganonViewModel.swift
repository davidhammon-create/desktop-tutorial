import SwiftUI
import AppKit

@Observable
final class OrganonViewModel {
private let store = OrganonStore.shared

var ausgewaehlterKnoten: OrganonKnoten?
var suchFilter = OrganonSuchFilter()
var aktiveOverlays: Set<OrganonOverlay> = []
/// Standard: nur Berichtslinien -- Querkanten machen die Personen-Stufe unlesbar.
var sichtbareKantenTypen: Set<OrganonKantenTyp> = [.disziplinarisch]
var zoomStufe: OrganonZoomStufe = .bereich
var canvasZoom: CGFloat = 1.0
var canvasOffset: CGSize = .zero
var suchTreffer: [OrganonKnoten] = []
var flugZuKnoten: OrganonKnoten?
var bearbeitenModus = false
var neueKanteVonId: String?
var statusMeldung = ""
/// Filter: Abteilungen / Personen / Alles
var ebenenKategorie: OrganonEbenenKategorie = .alles
/// Aufgeklappte Knoten in der Hierarchie-Ansicht
var aufgeklappt: Set<String> = ["org"]

var knoten: [OrganonKnoten] {
  get { store.knoten }
  set { store.knoten = newValue; store.scheduleSpeichern() }
}

var kanten: [OrganonKante] {
  get { store.kanten }
  set { store.kanten = newValue; store.scheduleSpeichern() }
}

var audit: [OrganonAuditEintrag] { store.audit }

var alleSkills: [String] {
  Array(Set(knoten.flatMap(\.effektiveSkills))).sorted()
}

var alleStandorte: [String] {
  Array(Set(knoten.compactMap(\.standort))).sorted()
}

var alleTags: [String] {
  Array(Set(knoten.flatMap { $0.tags ?? [] })).sorted()
}

var personen: [OrganonKnoten] {
  knoten.filter { $0.typ == .person }
}

var organisationseinheiten: [OrganonKnoten] {
  knoten.filter(\.istOrganisationseinheit)
}

var abteilungen: [OrganonKnoten] {
  knoten.filter { $0.typ == .bereich }
}

var teams: [OrganonKnoten] {
  knoten.filter { $0.typ == .team }
}

var vakanzen: [OrganonKnoten] {
  knoten.filter(\.istVakanz)
}

/// Brotkrumen-Pfad zur Auswahl (Gesellschaft -> Abteilung -> Team -> Person).
var hierarchiePfad: [OrganonKnoten] {
  guard let id = ausgewaehlterKnoten?.id else { return [] }
  return store.pfad(zu: id)
}

func pfadText(fuer kn: OrganonKnoten) -> String {
  store.pfad(zu: kn.id).map(\.name).joined(separator: " › ")
}

func elternName(fuer kn: OrganonKnoten) -> String? {
  kn.parentId.flatMap { knoten($0)?.name }
}

// MARK: Zoom / Sichtbarkeit

/// Welche Knotentypen die aktuelle Zoom-Stufe zeigt.
var typenFuerZoom: Set<OrganonKnotenTyp> {
  switch zoomStufe {
  case .konzern: return [.gesellschaft]
  case .bereich: return [.gesellschaft, .bereich]
  case .team: return [.gesellschaft, .bereich, .team]
  case .person: return [.gesellschaft, .bereich, .team, .person]
  }
}

func knotenFuerZoom() -> [OrganonKnoten] {
  var erlaubt = typenFuerZoom
  if aktiveOverlays.contains(.vakanz) { erlaubt.insert(.person) }
  var liste = knoten.filter { erlaubt.contains($0.typ) }
 if aktiveOverlays.contains(.vakanz) {
   // Bei Vakanz-Overlay: nur Vakanzen zusätzlich, wenn Personen sonst ausgeblendet
   if zoomStufe != .person {
     liste = knoten.filter { $0.typ != .person || $0.istVakanz }
       .filter { typenFuerZoom.contains($0.typ) || $0.istVakanz }
   }
 }
 return liste
}

func sichtbareKanten() -> [OrganonKante] {
 let ids = Set(knotenFuerZoom().map(\.id))
 // Immer Berichtslinien priorisieren; Querkanten nur wenn explizit aktiv
 // und nur auf Personen-Stufe (sonst unlesbar).
 var typen = sichtbareKantenTypen.intersection([.disziplinarisch])
 if zoomStufe == .person {
   typen = sichtbareKantenTypen
 }
 return kanten.filter {
   ids.contains($0.vonId) && ids.contains($0.zuId) && typen.contains($0.typ)
 }
}

// MARK: Hierarchie-Layout (geordnete Karte)

/// Feste Ebenen nach TYP -- nicht nach Baumtiefe.
/// So landen Partner und Associates nie auf Team-Höhe:
/// Zeile 0 Kanzlei · 1 Abteilungen · 2 Teams · 3 Personen
func legeHierarchieAn(breite: Double = 1400, startY: Double = 70, ebenenAbstand: Double = 145, still: Bool = false) {
 var arbeit = store.knoten
 guard !arbeit.isEmpty else { return }

 func idx(_ id: String) -> Int? { arbeit.firstIndex(where: { $0.id == id }) }
 func setze(_ id: String, x: Double, y: Double) {
   guard let i = idx(id) else { return }
   arbeit[i].posX = x
   arbeit[i].posY = y
 }
 func sortiert(_ liste: [OrganonKnoten]) -> [OrganonKnoten] {
   liste.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
 }

 let gesellschaften = sortiert(arbeit.filter { $0.typ == .gesellschaft })
 let abteilungen = sortiert(arbeit.filter { $0.typ == .bereich })
 let teams = sortiert(arbeit.filter { $0.typ == .team })
 let personen = sortiert(arbeit.filter { $0.typ == .person })

 let yKanzlei = startY
 let yAbteilung = startY + ebenenAbstand
 let yTeam = startY + ebenenAbstand * 2
 let yPerson = startY + ebenenAbstand * 3

 // nn 1) Kanzlei zentriert nn
 let mitte = breite / 2
 for g in gesellschaften { setze(g.id, x: mitte, y: yKanzlei) }

 // nn 2) Abteilungen gleichmäßig in einer Zeile nn
 let abtListe = abteilungen.isEmpty ? gesellschaften : abteilungen
 let abtSpan = max(breite - 80, Double(max(abtListe.count, 1)) * 220)
 let abtStart = mitte - abtSpan / 2
 var abtSpalten: [String: (links: Double, rechts: Double, x: Double)] = [:]
 if abteilungen.isEmpty {
   // Keine Abteilungen -> ganze Breite als eine Spalte
   if let g = gesellschaften.first {
     abtSpalten[g.id] = (80, breite - 80, mitte)
   }
 } else {
   let slot = abtSpan / Double(abteilungen.count)
   for (i, a) in abteilungen.enumerated() {
     let links = abtStart + Double(i) * slot
     let rechts = links + slot
     let x = (links + rechts) / 2
     setze(a.id, x: x, y: yAbteilung)
     abtSpalten[a.id] = (links + 12, rechts - 12, x)
   }
 }

 // nn 3) Teams unter ihrer Abteilung (eigene Zeile) nn
 // Bei Personen-Stufe: Spaltenbreite proportional zur Personenzahl (Partner + Team-Mitglieder),
 // damit niemand übereinander liegt.
 var teamSpalten: [String: (links: Double, rechts: Double, x: Double)] = [:]

 func personenUnterTeam(_ teamId: String) -> Int {
   personen.filter { $0.parentId == teamId }.count
 }
 func partnerUnterAbteilung(_ abtId: String) -> Int {
   personen.filter { $0.parentId == abtId }.count
 }

 for (abtId, spalte) in abtSpalten {
   let meineTeams = sortiert(teams.filter { $0.parentId == abtId })
   let partnerCount = typenFuerZoom.contains(.person) ? partnerUnterAbteilung(abtId) : 0

   // Gewichte: optional Partner-Block links, dann Teams
   struct Slot {
     var id: String // "partner:abt" oder teamId
     var gewicht: Double
   }
   var slots: [Slot] = []
   if partnerCount > 0 {
     slots.append(Slot(id: "partner:\(abtId)", gewicht: Double(partnerCount)))
   }
   for t in meineTeams {
     let g = typenFuerZoom.contains(.person)
       ? max(1.0, Double(personenUnterTeam(t.id)))
       : 1.0
     slots.append(Slot(id: t.id, gewicht: g))
   }
   guard !slots.isEmpty else { continue }

   let summe = slots.map(\.gewicht).reduce(0, +)
   let nutzbreite = max(spalte.rechts - spalte.links, Double(slots.count) * 120)
   let origin = (spalte.links + spalte.rechts) / 2 - nutzbreite / 2
   var cursor = origin
   for slot in slots {
     let w = max(100, nutzbreite * (slot.gewicht / summe))
     let links = cursor
     let rechts = cursor + w
     let x = (links + rechts) / 2
     if slot.id.hasPrefix("partner:") {
       // Partner-Block: Personen werden in Schritt 4 gesetzt; X-Bereich merken
       teamSpalten[slot.id] = (links + 4, rechts - 4, x)
     } else {
       setze(slot.id, x: x, y: yTeam)
       teamSpalten[slot.id] = (links + 4, rechts - 4, x)
     }
     cursor = rechts
   }
 }

 // Orphan-Teams
 let orphanTeams = teams.filter { t in
   guard let p = t.parentId else { return true }
   return abtSpalten[p] == nil
 }
 if !orphanTeams.isEmpty {
   let slotW = breite / Double(orphanTeams.count)
   for (i, t) in orphanTeams.enumerated() {
     let x = Double(i) * slotW + slotW / 2
     setze(t.id, x: x, y: yTeam)
     teamSpalten[t.id] = (Double(i) * slotW + 10, Double(i + 1) * slotW - 10, x)
   }
 }

 // nn 4) Personen: eine unterste Zeile, Gruppen ohne Überlappung nn
 if typenFuerZoom.contains(.person) {
   let minAbstand = 100.0

   func verteile(_ gruppe: [OrganonKnoten], in bereich: (links: Double, rechts: Double, x: Double)) {
     let g = sortiert(gruppe)
     guard !g.isEmpty else { return }
     let n = Double(g.count)
     let noetig = n * minAbstand
     let links: Double
     let rechts: Double
     if noetig <= (bereich.rechts - bereich.links) {
       // Zentriert im Slot
       let pad = ((bereich.rechts - bereich.links) - noetig) / 2
       links = bereich.links + pad
       rechts = bereich.rechts - pad
     } else {
       links = bereich.x - noetig / 2
       rechts = bereich.x + noetig / 2
     }
     let step = (rechts - links) / n
     for (i, p) in g.enumerated() {
       setze(p.id, x: links + step * (Double(i) + 0.5), y: yPerson)
     }
   }

   // Pro Abteilung: Partner-Block + je Team-Gruppe
   for a in abteilungen {
     let partner = personen.filter { $0.parentId == a.id }
     if !partner.isEmpty, let bereich = teamSpalten["partner:\(a.id)"] {
       verteile(partner, in: bereich)
     } else if !partner.isEmpty, let spalte = abtSpalten[a.id] {
       // Fallback falls kein Partner-Slot
       verteile(partner, in: spalte)
     }
     for t in sortiert(teams.filter { $0.parentId == a.id }) {
       let mitglieder = personen.filter { $0.parentId == t.id }
       if let bereich = teamSpalten[t.id] {
         verteile(mitglieder, in: bereich)
       }
     }
   }

   // Personen ohne Zuordnung (verwaist)
   let platziert = Set(arbeit.filter { $0.typ == .person && abs($0.posY - yPerson) < 1 }.map(\.id))
   let rest = personen.filter { !platziert.contains($0.id) }
   if !rest.isEmpty {
     verteile(rest, in: (80, breite - 80, mitte))
   }
 }

 store.knoten = arbeit
 store.scheduleSpeichern()
 zentriereAufSichtbareKnoten()
 if !still { status("Karte · \(zoomStufe.bezeichnung)") }
}

func zentriereAufSichtbareKnoten() {
 let sichtbare = knotenFuerZoom()
 guard !sichtbare.isEmpty else { return }
 let minX = sichtbare.map(\.posX).min() ?? 0
 let maxX = sichtbare.map(\.posX).max() ?? 800
 let minY = sichtbare.map(\.posY).min() ?? 0
 let midX = (minX + maxX) / 2
 let midY = (minY + (sichtbare.map(\.posY).max() ?? minY)) / 2
 canvasOffset = CGSize(
   width: -midX * canvasZoom + 200,
   height: -midY * canvasZoom + 120
 )
}

func sucheAusfuehren() {
 let q = suchFilter.query.trimmingCharacters(in: .whitespaces).lowercased()
 suchTreffer = knoten.filter { kn in
   switch ebenenKategorie {
   case .struktur: if kn.istPerson { return false }
   case .personen: if kn.istOrganisationseinheit { return false }
   case .alles: break
   }
   let textMatch = q.isEmpty || kn.suchText.contains(q)
   let skillMatch = suchFilter.skills.isEmpty || !suchFilter.skills.isDisjoint(with: Set(kn.effektiveSkills))
   let ortMatch = suchFilter.standorte.isEmpty || suchFilter.standorte.contains(kn.standort ?? "")
   let tagMatch = suchFilter.tags.isEmpty || !suchFilter.tags.isDisjoint(with: Set(kn.tags ?? []))
   let kapMatch = !suchFilter.nurVerfuegbar || kn.kapazitaet == .verfuegbar
   let vakMatch = !suchFilter.nurVakanzen || kn.istVakanz
   return textMatch && skillMatch && ortMatch && tagMatch && kapMatch && vakMatch
 }
}

func zuKnotenFliegen(_ kn: OrganonKnoten) {
 ausgewaehlterKnoten = kn
 flugZuKnoten = kn
 if kn.typ == .person { zoomStufe = .person }
 else if kn.typ == .team { zoomStufe = .team }
 else if kn.typ == .bereich { zoomStufe = .bereich }
 else { zoomStufe = .konzern }
}

func knoten(_ id: String) -> OrganonKnoten? {
 store.knoten.first { $0.id == id }
}

func kinder(von parentId: String) -> [OrganonKnoten] {
 store.kinder(von: parentId)
}

/// Alle Personen unter einer Organisationseinheit (rekursiv) -- inkl. direkt unter Abteilung.
func personenUnter(einheitId: String) -> [OrganonKnoten] {
 var result: [OrganonKnoten] = []
 var queue = [einheitId]
 var gesehen = Set<String>()
 while let id = queue.first {
   queue.removeFirst()
   guard gesehen.insert(id).inserted else { continue }
   for kind in kinder(von: id) {
     if kind.typ == .person { result.append(kind) }
     else if kind.istOrganisationseinheit { queue.append(kind.id) }
   }
 }
 return result
}

func projektlast(fuer bereichId: String) -> Int {
 personenUnter(einheitId: bereichId).reduce(0) { sum, p in
   sum + (p.projekte?.count ?? 0) + (p.caseIds?.count ?? 0) + (p.vorgangIds?.count ?? 0)
 }
}

/// Projektlast 0…1 für Overlay-Färbung
func projektlastNormiert(fuer bereichId: String) -> Double {
 min(1, Double(projektlast(fuer: bereichId)) / 12.0)
}

// MARK: CRUD

func speichereKnoten(_ kn: OrganonKnoten) {
 store.setzeKnoten(kn)
 if ausgewaehlterKnoten?.id == kn.id { ausgewaehlterKnoten = kn }
 sucheAusfuehren()
 status("Gespeichert: \(kn.name)")
}

func loescheAusgewaehlten() {
 guard let id = ausgewaehlterKnoten?.id else { return }
 store.loescheKnoten(id)
 ausgewaehlterKnoten = nil
 sucheAusfuehren()
 status("Knoten gelöscht")
}

/// Bestimmt den korrekten Eltern-Knoten für einen neuen Typ aus der Auswahl.
func elternIdFuerNeuanlage(typ: OrganonKnotenTyp, auswahl: OrganonKnoten?) -> String? {
 guard let a = auswahl else {
   return typ == .bereich ? knoten.first(where: { $0.typ == .gesellschaft })?.id : nil
 }
 if typ.erlaubteElternTypen.contains(a.typ) { return a.id }
 // Aufwärts suchen
 return store.pfad(zu: a.id).reversed().first { typ.erlaubteElternTypen.contains($0.typ) }?.id
   ?? knoten.first(where: { typ.erlaubteElternTypen.contains($0.typ) })?.id
}

func neuePerson(unter parentId: String?) {
 let effektiveParent = parentId ?? elternIdFuerNeuanlage(typ: .person, auswahl: ausgewaehlterKnoten)
 let parent = effektiveParent.flatMap { knoten($0) }
 // Person nur unter Team oder Abteilung
 let parentOk = parent.map { OrganonKnotenTyp.person.erlaubteElternTypen.contains($0.typ) } ?? false
 let px = (parent?.posX ?? 400) + Double.random(in: -40...40)
 let py = (parent?.posY ?? 300) + 80
 let kn = OrganonKnoten(
   id: "p-\(UUID().uuidString.prefix(8))",
   typ: .person,
   name: "Neue Person",
   untertitel: "Rolle festlegen",
   parentId: parentOk ? effektiveParent : nil,
   posX: px,
   posY: py,
   rolle: "Associate",
   skillMatrix: [],
   kapazitaet: .verfuegbar,
   tags: ["neu"]
 )
 store.setzeKnoten(kn)
 if let pid = kn.parentId { aufgeklappt.insert(pid) }
 ausgewaehlterKnoten = kn
 zoomStufe = .person
 bearbeitenModus = true
 legeHierarchieAn(still: true)
 status(parentOk
    ? "Person unter \(parent?.name ?? "--") angelegt"
    : "Person angelegt -- bitte einer Abteilung/einem Team zuordnen")
}

func neuesTeam(unter bereichId: String?) {
 let pid = bereichId ?? elternIdFuerNeuanlage(typ: .team, auswahl: ausgewaehlterKnoten)
 let parent = pid.flatMap { knoten($0) }
 let kn = OrganonKnoten(
   id: "t-\(UUID().uuidString.prefix(8))",
   typ: .team,
   name: "Neues Team",
   untertitel: "0 Berufsträger",
   parentId: pid,
   posX: (parent?.posX ?? 400) + 60,
   posY: (parent?.posY ?? 220) + 70,
   mitarbeiterAnzahl: 0,
   standort: parent?.standort
 )
 store.setzeKnoten(kn)
 if let pid { aufgeklappt.insert(pid) }
 ausgewaehlterKnoten = kn
 zoomStufe = .team
 bearbeitenModus = true
 legeHierarchieAn(still: true)
 status("Team unter \(parent?.name ?? "Abteilung") angelegt")
}

func neueAbteilung(unter gesellschaftId: String? = nil) {
 let pid = gesellschaftId
   ?? elternIdFuerNeuanlage(typ: .bereich, auswahl: ausgewaehlterKnoten)
   ?? knoten.first(where: { $0.typ == .gesellschaft })?.id
 let parent = pid.flatMap { knoten($0) }
 let kn = OrganonKnoten(
   id: "dz-\(UUID().uuidString.prefix(8))",
   typ: .bereich,
   name: "Neue Abteilung",
   untertitel: "0 Berufsträger",
   parentId: pid,
   posX: (parent?.posX ?? 400) + Double.random(in: -120...120),
   posY: (parent?.posY ?? 80) + 140,
   mitarbeiterAnzahl: 0,
   standort: parent?.standort
 )
 store.setzeKnoten(kn)
 if let pid { aufgeklappt.insert(pid) }
 ausgewaehlterKnoten = kn
 zoomStufe = .bereich
 bearbeitenModus = true
 legeHierarchieAn(still: true)
 status("Abteilung angelegt -- Name und Standort festlegen")
}

/// Person oder Einheit einer anderen Abteilung/Team zuordnen.
func verschiebe(_ knotenId: String, unter neuerElternId: String?) {
 guard var kn = knoten(knotenId) else { return }
 if let neuerElternId, let eltern = knoten(neuerElternId) {
   guard kn.typ.erlaubteElternTypen.contains(eltern.typ) else {
     status("Ungültig: \(kn.typ.kurz) kann nicht unter \(eltern.typ.kurz) hängen")
     return
   }
   kn.parentId = neuerElternId
 } else {
   kn.parentId = nil
 }
 store.setzeKnoten(kn)
 ausgewaehlterKnoten = kn
 status("Verschoben: \(kn.name) -> \(knoten(neuerElternId ?? "")?.name ?? "Wurzel")")
}

func repariereHierarchie() {
 store.repariereHierarchie(still: false)
 status("Hierarchie geprüft und synchronisiert")
}

func starteKantenModus(von id: String) {
 neueKanteVonId = id
 status("Zielknoten wählen für neue Beziehung")
}

func schliesseKante(zu zielId: String, typ: OrganonKantenTyp = .fachlich) {
 guard let von = neueKanteVonId, von != zielId else { return }
 if typ == .disziplinarisch {
   // Berichtslinie = Hierarchie-Verschiebung
   verschiebe(zielId, unter: von)
   neueKanteVonId = nil
   return
 }
 let k = OrganonKante(
   id: "e-\(UUID().uuidString.prefix(8))",
   vonId: von,
   zuId: zielId,
   typ: typ
 )
 store.setzeKante(k)
 neueKanteVonId = nil
 status("Beziehung \(typ.bezeichnung) angelegt")
}

func setzePosition(id: String, x: Double, y: Double) {
 guard var kn = knoten(id) else { return }
 kn.posX = x
 kn.posY = y
 store.setzeKnoten(kn)
 if ausgewaehlterKnoten?.id == id { ausgewaehlterKnoten = kn }
}

// MARK: Verknüpfungen

func verknuepfeVorgang(_ vorgangId: UUID, an knotenId: String) {
 guard var kn = knoten(knotenId) else { return }
 var ids = kn.vorgangIds ?? []
 let sid = vorgangId.uuidString
 if !ids.contains(sid) { ids.append(sid) }
 kn.vorgangIds = ids
 store.setzeKnoten(kn)

 VorgangStore.shared.mutate(vorgangId) { v in
   v.organonKnotenId = knotenId
   if v.verantwortlich == nil || v.verantwortlich?.isEmpty == true {
     v.verantwortlich = kn.name
   }
 }
 ausgewaehlterKnoten = kn
 status("Vorgang verknüpft")
}

func verknuepfeCase(_ caseId: String, an knotenId: String) {
 guard var kn = knoten(knotenId) else { return }
 var ids = kn.caseIds ?? []
 if !ids.contains(caseId) { ids.append(caseId) }
 kn.caseIds = ids
 store.setzeKnoten(kn)
 ausgewaehlterKnoten = kn
 status("Lexara-Fall verknüpft")
}

func verknuepfeMandant(_ mandantId: String, an knotenId: String) {
 guard var kn = knoten(knotenId) else { return }
 var ids = kn.mandantIds ?? []
 if !ids.contains(mandantId) { ids.append(mandantId) }
 kn.mandantIds = ids
 store.setzeKnoten(kn)
 ausgewaehlterKnoten = kn
 status("Mandant verknüpft")
}

func verknuepfteVorgaenge(fuer kn: OrganonKnoten) -> [Vorgang] {
 let ids = Set(kn.vorgangIds ?? [])
 let byId = VorgangStore.shared.vorgaenge.filter { ids.contains($0.id.uuidString) || $0.organonKnotenId == kn.id }
 let byName = VorgangStore.shared.vorgaenge.filter {
   ($0.verantwortlich ?? "").localizedCaseInsensitiveContains(kn.name)
 }
 var map: [UUID: Vorgang] = [:]
 for v in byId + byName { map[v.id] = v }
 return Array(map.values).sorted { $0.titel < $1.titel }
}

func verknuepfteCases(fuer kn: OrganonKnoten) async -> [LegalCase] {
 let all = (try? await Services.cases.list()) ?? []
 let ids = Set(kn.caseIds ?? [])
 if !ids.isEmpty {
   return all.filter { ids.contains($0.id ?? "") }
 }
 // Heuristik: Name in Beschreibung / Mandant
 return all.filter {
   ($0.fallname).localizedCaseInsensitiveContains(kn.name)
     || ($0.mandant_name ?? "").localizedCaseInsensitiveContains(kn.name)
 }.prefix(8).map { $0 }
}

/// Kapazität aus Arbeitslast ableiten (wenn nicht manuell abwesend)
func aktualisiereKapazitaetAusLast(fuer knotenId: String) {
 guard var kn = knoten(knotenId), kn.typ == .person, kn.kapazitaet != .abwesend else { return }
 let last = (kn.vorgangIds?.count ?? 0) + (kn.caseIds?.count ?? 0) + (kn.projekte?.count ?? 0)
 kn.kapazitaet = last >= 5 ? .ausgelastet : .verfuegbar
 store.setzeKnoten(kn)
 if ausgewaehlterKnoten?.id == knotenId { ausgewaehlterKnoten = kn }
}

// MARK: Skills Matrix

var skillMatrixZeilen: [(skill: String, personen: [(OrganonKnoten, OrganonSkillLevel)])] {
 var map: [String: [(OrganonKnoten, OrganonSkillLevel)]] = [:]
 for p in personen where !p.istVakanz {
   if let matrix = p.skillMatrix, !matrix.isEmpty {
     for s in matrix {
       map[s.name, default: []].append((p, s.level))
     }
   } else {
     for name in p.skills ?? [] {
       map[name, default: []].append((p, .praxis))
     }
   }
 }
 return map.keys.sorted().map { key in
   (skill: key, personen: map[key]!.sorted { $0.1 > $1.1 })
 }
}

// MARK: Export / Reset

func kopiereExport(_ art: String) {
 let text: String
 switch art {
 case "json": text = store.exportJSON()
 default: text = store.exportMarkdown()
 }
 NSPasteboard.general.clearContents()
 NSPasteboard.general.setString(text, forType: .string)
 status("Export kopiert (\(art))")
}

func resetDemo() {
 store.resetAufDemo()
 ausgewaehlterKnoten = nil
 suchTreffer = []
 status("Demo wiederhergestellt")
}

private func status(_ s: String) {
 statusMeldung = s
 DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
   if self?.statusMeldung == s { self?.statusMeldung = "" }
 }
}
}

