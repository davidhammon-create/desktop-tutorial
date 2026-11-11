import SwiftUI
import AppKit
@Observable
final class OrganonViewModel {
    private let store = OrganonStore.shared
    var ausgewaehlterKnoten: OrganonKnoten?
    var suchFilter = OrganonSuchFilter()
    var aktiveOverlays: Set<OrganonOverlay> = []
    var sichtbareKantenTypen: Set<OrganonKantenTyp> = [.disziplinarisch]
    var zoomStufe: OrganonZoomStufe = .bereich
    var canvasZoom: CGFloat = 1.0
    var canvasOffset: CGSize = .zero
    var canvasGroesse: CGSize = CGSize(width: 1100, height: 700)
    var suchTreffer: [OrganonKnoten] = []
    var flugZuKnoten: OrganonKnoten?
    var bearbeitenModus = false
    var neueKanteVonId: String?
    var statusMeldung = ""
    var ebenenKategorie: OrganonEbenenKategorie = .alles
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
            if zoomStufe != .person {
                liste = knoten.filter { $0.typ != .person || $0.istVakanz }
                    .filter { typenFuerZoom.contains($0.typ) || $0.istVakanz }
            }
        }
        return liste
    }
    func sichtbareKanten() -> [OrganonKante] {
        let ids = Set(knotenFuerZoom().map(\.id))
        var typen = sichtbareKantenTypen.intersection([.disziplinarisch])
        if zoomStufe == .person {
            typen = sichtbareKantenTypen
        }
        return kanten.filter {
            ids.contains($0.vonId) && ids.contains($0.zuId) && typen.contains($0.typ)
        }
    }
    func legeHierarchieAn(startY: Double = 70, ebenenAbstand: Double = 150, still: Bool = false) {
        var arbeit = store.knoten
        guard !arbeit.isEmpty else { return }
        func idx(_ id: String) -> Int? { arbeit.firstIndex(where: { $0.id == id }) }
        func setze(_ id: String, x: Double, y: Double) {
            guard let i = idx(id) else { return }
            arbeit[i].posX = x
            arbeit[i].posY = y
        }
        func nachName(_ liste: [OrganonKnoten]) -> [OrganonKnoten] {
            liste.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        let zeigeTeams = typenFuerZoom.contains(.team)
        let zeigePersonen = typenFuerZoom.contains(.person)
        let personPitch = 148.0
        let teamPitch = 188.0
        let abtMin = 200.0
        let spaltenLuecke = 44.0
        let gesellschaften = arbeit.filter { $0.typ == .gesellschaft }
        let abteilungen = arbeit.filter { $0.typ == .bereich }
        let teams = arbeit.filter { $0.typ == .team }
        let personen = arbeit.filter { $0.typ == .person }
        let abteilungIds = Set(abteilungen.map(\.id))
        let teamIds = Set(teams.map(\.id))
        let gesellschaftIds = Set(gesellschaften.map(\.id))
        struct TeamBlock {
            var id: String
            var breite: Double
            var mitglieder: [OrganonKnoten]
        }
        struct Spalte {
            var abtId: String
            var breite: Double
            var leitung: [OrganonKnoten]
            var teams: [TeamBlock]
        }
        var spalten: [Spalte] = []
        for a in abteilungen {
            let leitung = nachName(personen.filter { $0.parentId == a.id })
            let bloecke: [TeamBlock] = nachName(teams.filter { $0.parentId == a.id }).map { team in
                let mitglieder = nachName(personen.filter { $0.parentId == team.id })
                let breite = (zeigePersonen && !mitglieder.isEmpty)
                    ? max(teamPitch, Double(mitglieder.count) * personPitch)
                    : teamPitch
                return TeamBlock(id: team.id, breite: breite, mitglieder: mitglieder)
            }
            let teamSumme = bloecke.map(\.breite).reduce(0, +)
            let leitungBreite = (zeigePersonen && !leitung.isEmpty) ? Double(leitung.count) * personPitch : 0
            let breiteSpalte = max(abtMin, zeigeTeams ? teamSumme : 0, leitungBreite)
            spalten.append(Spalte(abtId: a.id, breite: breiteSpalte, leitung: leitung, teams: bloecke))
        }
        let hatLeitung = zeigePersonen && spalten.contains { !$0.leitung.isEmpty }
        let hatTeams = zeigeTeams && (spalten.contains { !$0.teams.isEmpty } || teams.contains { team in
            guard let p = team.parentId else { return true }
            return !abteilungIds.contains(p)
        })
        let hatDirekt = zeigePersonen && personen.contains { person in
            guard let id = person.parentId else { return false }
            return gesellschaftIds.contains(id)
        }
        let yKanzlei = startY
        let yAbteilung = yKanzlei + (hatDirekt ? ebenenAbstand * 2 : ebenenAbstand)
        let yLeitung = yAbteilung + ebenenAbstand
        let yTeam = (hatLeitung ? yLeitung : yAbteilung) + ebenenAbstand
        let yPerson = yTeam + ebenenAbstand
        func verteile(_ gruppe: [OrganonKnoten], links: Double, rechts: Double, y: Double) {
            guard !gruppe.isEmpty else { return }
            let step = (rechts - links) / Double(gruppe.count)
            for (i, p) in gruppe.enumerated() {
                setze(p.id, x: links + step * (Double(i) + 0.5), y: y)
            }
        }
        let rand = 180.0
        var cursor = rand
        var platziert = Set<String>()
        for spalte in spalten {
            let links = cursor
            let rechts = cursor + spalte.breite
            let mitteAbt = (links + rechts) / 2
            setze(spalte.abtId, x: mitteAbt, y: yAbteilung)
            if zeigePersonen, !spalte.leitung.isEmpty {
                verteile(spalte.leitung, links: links, rechts: rechts, y: yLeitung)
                platziert.formUnion(spalte.leitung.map(\.id))
            }
            if zeigeTeams, !spalte.teams.isEmpty {
                let summe = spalte.teams.map(\.breite).reduce(0, +)
                var teamCursor = mitteAbt - summe / 2
                for block in spalte.teams {
                    let teamLinks = teamCursor
                    let teamRechts = teamCursor + block.breite
                    setze(block.id, x: (teamLinks + teamRechts) / 2, y: yTeam)
                    if zeigePersonen {
                        verteile(block.mitglieder, links: teamLinks, rechts: teamRechts, y: yPerson)
                        platziert.formUnion(block.mitglieder.map(\.id))
                    }
                    teamCursor = teamRechts
                }
            }
            cursor = rechts + spaltenLuecke
        }
        let graphLinks = rand
        let graphRechts = spalten.isEmpty ? rand + abtMin : cursor - spaltenLuecke
        let graphMitte = (graphLinks + graphRechts) / 2
        if gesellschaften.count <= 1 {
            for g in gesellschaften { setze(g.id, x: graphMitte, y: yKanzlei) }
        } else {
            let schritt = 240.0
            let start = graphMitte - schritt * Double(gesellschaften.count - 1) / 2
            for (i, g) in gesellschaften.enumerated() {
                setze(g.id, x: start + Double(i) * schritt, y: yKanzlei)
            }
        }
        let loseTeams = nachName(teams.filter { team in
            guard let p = team.parentId else { return true }
            return !abteilungIds.contains(p)
        })
        if zeigeTeams, !loseTeams.isEmpty {
            var teamCursor = graphRechts + spaltenLuecke
            for team in loseTeams {
                let mitglieder = nachName(personen.filter { $0.parentId == team.id })
                let breiteBlock = (zeigePersonen && !mitglieder.isEmpty)
                    ? max(teamPitch, Double(mitglieder.count) * personPitch)
                    : teamPitch
                setze(team.id, x: teamCursor + breiteBlock / 2, y: hatTeams ? yTeam : yAbteilung + ebenenAbstand)
                if zeigePersonen {
                    verteile(mitglieder, links: teamCursor, rechts: teamCursor + breiteBlock, y: yPerson)
                    platziert.formUnion(mitglieder.map(\.id))
                }
                teamCursor += breiteBlock
            }
        }
        if zeigePersonen {
            let rest = nachName(personen.filter { person in
                if platziert.contains(person.id) { return false }
                guard let p = person.parentId else { return true }
                return !teamIds.contains(p) && !abteilungIds.contains(p) && !gesellschaftIds.contains(p)
            })
            if !rest.isEmpty {
                let breiteRest = Double(rest.count) * personPitch
                verteile(rest, links: graphMitte - breiteRest / 2, rechts: graphMitte + breiteRest / 2, y: yPerson + ebenenAbstand)
            }
            for g in gesellschaften {
                let direkt = nachName(personen.filter { $0.parentId == g.id })
                guard !direkt.isEmpty else { continue }
                let breiteDirekt = Double(direkt.count) * personPitch
                verteile(direkt, links: graphMitte - breiteDirekt / 2, rechts: graphMitte + breiteDirekt / 2, y: yKanzlei + ebenenAbstand)
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
        let maxX = sichtbare.map(\.posX).max() ?? 0
        let minY = sichtbare.map(\.posY).min() ?? 0
        let inhaltBreite = (maxX - minX) * canvasZoom
        let viewB = max(canvasGroesse.width, 640)
        let offsetX: CGFloat = inhaltBreite + 120 < viewB
            ? viewB / 2 - (minX + maxX) / 2 * canvasZoom
            : 72 - minX * canvasZoom
        canvasOffset = CGSize(width: offsetX, height: 78 - minY * canvasZoom)
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
    func projektlastNormiert(fuer bereichId: String) -> Double {
        min(1, Double(projektlast(fuer: bereichId)) / 12.0)
    }
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
    func elternIdFuerNeuanlage(typ: OrganonKnotenTyp, auswahl: OrganonKnoten?) -> String? {
        guard let a = auswahl else {
            return typ == .bereich ? knoten.first(where: { $0.typ == .gesellschaft })?.id : nil
        }
        if typ.erlaubteElternTypen.contains(a.typ) { return a.id }
        return store.pfad(zu: a.id).reversed().first { typ.erlaubteElternTypen.contains($0.typ) }?.id
            ?? knoten.first(where: { typ.erlaubteElternTypen.contains($0.typ) })?.id
    }
    func neuePerson(unter parentId: String?) {
        let effektiveParent = parentId ?? elternIdFuerNeuanlage(typ: .person, auswahl: ausgewaehlterKnoten)
        let parent = effektiveParent.flatMap { knoten($0) }
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
               ? "Person unter \(parent?.name ?? "—") angelegt"
               : "Person angelegt — bitte einer Abteilung/einem Team zuordnen")
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
        status("Abteilung angelegt — Name und Standort festlegen")
    }
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
        status("Verschoben: \(kn.name) → \(knoten(neuerElternId ?? "")?.name ?? "Wurzel")")
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
        return all.filter {
            ($0.fallname).localizedCaseInsensitiveContains(kn.name)
                || ($0.mandant_name ?? "").localizedCaseInsensitiveContains(kn.name)
        }.prefix(8).map { $0 }
    }
    func aktualisiereKapazitaetAusLast(fuer knotenId: String) {
        guard var kn = knoten(knotenId), kn.typ == .person, kn.kapazitaet != .abwesend else { return }
        let last = (kn.vorgangIds?.count ?? 0) + (kn.caseIds?.count ?? 0) + (kn.projekte?.count ?? 0)
        kn.kapazitaet = last >= 5 ? .ausgelastet : .verfuegbar
        store.setzeKnoten(kn)
        if ausgewaehlterKnoten?.id == knotenId { ausgewaehlterKnoten = kn }
    }
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
