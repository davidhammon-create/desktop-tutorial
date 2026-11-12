import Foundation
enum NexusDemo {
    static func werklohnSalvatorisch(optionId: UUID, vorgangId: UUID) -> NexusGraph {
        var g = NexusRegelwerk.skelett(vorlage: NexusRegelwerk.bgb280, optionId: optionId, vorgangId: vorgangId)
        let merkmale = g.knoten.filter { $0.typ == .merkmal }
        guard merkmale.count >= 5 else { return g }
        let m1 = merkmale[0]
        let m2 = merkmale[1]
        let m3 = merkmale[2]
        let m4 = merkmale[3]
        let m5 = merkmale[4]
        func add(_ k: NexusKnoten, parent: UUID, kante: NexusKantenTyp) {
            var knoten = k
            knoten.parentId = parent
            knoten.setzeKern(knoten.kern)
            g.knoten.append(knoten)
            g.kanten.append(.init(von: knoten.id, nach: parent, typ: kante))
        }
        if let i = g.knoten.firstIndex(where: { $0.typ == .norm }) {
            g.knoten[i].kern = NexusAnzeige.zwoelfWoerter("§§ 280 I, III, 281 I BGB · 480.000 €")
            g.knoten[i].volltext = "Schadensersatz statt der Leistung"
        }
        let rahmen = NexusKnoten(
            parentId: m1.id, typ: .beleg,
            kern: "Rahmenvertrag v. 12.03.2024",
            volltext: "Urkunde, unstreitig unterzeichnet.",
            fundstelle: .init(dokId: "rahmen", seite: 1, zitat: "Rahmenvertrag 12.03.2024"),
            qRang: .gesetz, passgenauigkeit: 1, nachweis: .urkundeUnstreitig, status: .belegt
        )
        g.knoten.append(rahmen)
        g.kanten.append(.init(von: rahmen.id, nach: m1.id, typ: .stuetzt))
        add(NexusKnoten(
            typ: .klausel, kern: "§ 14.2 Schriftform",
            volltext: "geschlossen",
            fundstelle: .init(dokId: "rahmen", seite: 12, zitat: "§ 14.2 Rahmenvertrag"),
            qRang: .gesetz, passgenauigkeit: 1, nachweis: .urkundeUnstreitig, status: .belegt
        ), parent: rahmen.id, kante: .stuetzt)
        let fehlt = NexusKnoten(
            parentId: rahmen.id, typ: .klausel,
            kern: "Salvatorische Klausel FEHLT",
            volltext: "offene Flanke — Folgeknoten unter § 139 BGB",
            qRang: .unbelegt, passgenauigkeit: 1, nachweis: .behauptung, status: .belegt
        )
        g.knoten.append(fehlt)
        g.kanten.append(.init(von: fehlt.id, nach: rahmen.id, typ: .stuetzt))
        let email = NexusKnoten(
            parentId: m2.id, typ: .beleg,
            kern: "E-Mail-Verkehr zur Pflichtverletzung",
            volltext: "Nur Parteikorrespondenz, kein Abnahmeprotokoll.",
            fundstelle: .init(dokId: "mail", seite: 1, zitat: "E-Mail 04.2024"),
            qRang: .lg, passgenauigkeit: 0.89, nachweis: .urkundeBestritten, status: .belegt
        )
        g.knoten.append(email)
        g.kanten.append(.init(von: email.id, nach: m2.id, typ: .stuetzt))
        add(NexusKnoten(
            typ: .klausel, kern: "§ 9 Abnahme",
            fundstelle: .init(dokId: "rahmen", seite: 8, zitat: "§ 9 Rahmenvertrag"),
            qRang: .gesetz, passgenauigkeit: 0.80, nachweis: .urkundeUnstreitig, status: .belegt
        ), parent: m2.id, kante: .stuetzt)
        let nachfrist = NexusKnoten(
            parentId: m3.id, typ: .beleg,
            kern: "Nachfrist 14.04.2024 erfolglos",
            fundstelle: .init(dokId: "frist", seite: 1, zitat: "Nachfristschreiben"),
            qRang: .gesetz, passgenauigkeit: 0.88, nachweis: .urkundeUnstreitig, status: .belegt
        )
        g.knoten.append(nachfrist)
        g.kanten.append(.init(von: nachfrist.id, nach: m3.id, typ: .stuetzt))
        add(NexusKnoten(
            typ: .autoritaet, kern: "§ 280 I 2 BGB — Vertretenmüssen vermutet",
            volltext: "Beweislast beim Schuldner.",
            fundstelle: .init(dokId: "bgb", seite: 0, zitat: "§ 280 Abs. 1 S. 2 BGB"),
            qRang: .gesetz, passgenauigkeit: 0.95, nachweis: .urkundeUnstreitig, status: .belegt
        ), parent: m4.id, kante: .stuetzt)
        let schaden = NexusKnoten(
            parentId: m5.id, typ: .beleg,
            kern: "Differenzkalkulation 480.000 €",
            fundstelle: .init(dokId: "schaden", seite: 1, zitat: "Schadensberechnung"),
            qRang: .gesetz, passgenauigkeit: 0.90, nachweis: .urkundeUnstreitig, status: .belegt
        )
        g.knoten.append(schaden)
        g.kanten.append(.init(von: schaden.id, nach: m5.id, typ: .stuetzt))
        let gegner = NexusKnoten(
            parentId: fehlt.id, typ: .argGegner,
            kern: "Gesamtnichtigkeit nach § 139 BGB",
            volltext: "§ 7.3 ist unwirksam; ohne Erhaltungsklausel entfällt der ganze Vertrag.",
            qRang: .olg, passgenauigkeit: 0.846, nachweis: .urkundeUnstreitig, status: .belegt
        )
        g.knoten.append(gegner)
        g.kanten.append(.init(von: gegner.id, nach: m1.id, typ: .greiftAn))
        let konter1 = NexusKnoten(
            parentId: gegner.id, typ: .argEigen,
            kern: "§ 306 I BGB verdrängt § 139",
            volltext: "Der Vertrag ist AGB-Vertrag. Bei AGB bleibt der Restvertrag kraft Gesetzes wirksam.",
            qRang: .gesetz, passgenauigkeit: 0.90, nachweis: .urkundeUnstreitig, status: .belegt
        )
        g.knoten.append(konter1)
        g.kanten.append(.init(von: konter1.id, nach: gegner.id, typ: .schliesstAus))
        add(NexusKnoten(
            typ: .autoritaet, kern: "§ 306 I BGB — Gesetzestext unmittelbar",
            fundstelle: .init(dokId: "bgb", seite: 0, zitat: "§ 306 Abs. 1 BGB"),
            qRang: .gesetz, passgenauigkeit: 0.90, nachweis: .urkundeUnstreitig, status: .belegt
        ), parent: konter1.id, kante: .stuetzt)
        let konter2 = NexusKnoten(
            parentId: gegner.id, typ: .argEigen,
            kern: "favor contractus — hypothetischer Parteiwille",
            volltext: "§ 139 kehrt die Vermutung nur um.",
            qRang: .bghStaendig, passgenauigkeit: 0.65, nachweis: .urkundeUnstreitig, status: .belegt
        )
        g.knoten.append(konter2)
        g.kanten.append(.init(von: konter2.id, nach: gegner.id, typ: .greiftAn))
        add(NexusKnoten(
            typ: .autoritaet, kern: "BGH Erhaltungsgrundsatz — anderer Vertragstyp",
            fundstelle: .init(dokId: "bgh", seite: 0, zitat: "BGH NJW 2005, 2225"),
            qRang: .bghStaendig, passgenauigkeit: 0.65, nachweis: .urkundeUnstreitig, status: .belegt
        ), parent: konter2.id, kante: .stuetzt)
        let gegen = NexusKnoten(
            parentId: konter2.id, typ: .argGegner,
            kern: "Hypothetischer Parteiwille nicht feststellbar",
            volltext: "Beweislast trägt, wer sich auf Teilnichtigkeit beruft.",
            qRang: .lg, passgenauigkeit: 0.89, nachweis: .urkundeUnstreitig, status: .belegt
        )
        g.knoten.append(gegen)
        g.kanten.append(.init(von: gegen.id, nach: konter2.id, typ: .greiftAn))
        NexusPropagation.auswerten(&g)
        return g
    }
    static func kschgSkelett(optionId: UUID, vorgangId: UUID) -> NexusGraph {
        NexusRegelwerk.skelett(vorlage: NexusRegelwerk.kschg, optionId: optionId, vorgangId: vorgangId)
    }
    static func herleitung(_ g: NexusGraph) -> String {
        var z: [String] = [
            "NEXUS-HERLEITUNG",
            "β = \(String(format: "%.1f", g.beta).replacingOccurrences(of: ".", with: ",")) — \(g.betaKalibriert ? "kalibriert" : "nicht kalibriert")",
            "Belegtheit: \(Int((g.belegtheit * 100).rounded())) %",
            "P(Erfolg) intern \(NexusAnzeige.punkt(g.pErfolg)) · Anzeige \(NexusAnzeige.band(g.pErfolg))",
            "Filter: zulässig \(NexusAnzeige.punkt(g.pZulaessig)) · nicht verjährt \(NexusAnzeige.punkt(g.pNichtVerjaehrt)) · durchsetzbar \(NexusAnzeige.punkt(g.pDurchsetzbar))",
            ""
        ]
        for w in g.wuerzel() {
            z.append("Anspruch \(w.kern): \(NexusAnzeige.punkt(g.pAnsprueche[w.id] ?? 0))")
            for m in g.kinder(von: w.id).filter({ $0.typ == .merkmal }) {
                z.append("  \(m.kern): P(m) = \(NexusAnzeige.punkt(m.pMerkmal ?? 0))  Sroh \(String(format: "%.3f", m.sRoh)) → Snetto \(String(format: "%.3f", m.sNetto))")
            }
        }
        if !g.offeneFlanken.isEmpty {
            z.append("")
            z.append("OFFENE FLANKEN")
            for f in g.offeneFlanken { z.append("  · \(f.kern)") }
        }
        return z.joined(separator: "\n")
    }
    static func schriftsatz(_ g: NexusGraph) -> String {
        var z: [String] = [
            "SCHRIFTSATZGLIEDERUNG (aus NEXUS — keine KI-Vorschläge)",
            g.wuerzel().first.map { $0.kern } ?? "Anspruch",
            ""
        ]
        for w in g.wuerzel() {
            z.append("Antrag / Ziel: \(w.kern)")
            z.append("")
            for m in g.kinder(von: w.id).filter({ $0.typ == .merkmal }) {
                z.append("I. \(m.kern)")
                z.append("   P(m) = \(NexusAnzeige.punkt(m.pMerkmal ?? 0))")
                let vortrag = g.kinder(von: m.id).filter { ($0.typ == .beleg || $0.typ == .klausel || $0.typ == .argEigen) && $0.status != .kiVorschlag }
                if vortrag.isEmpty {
                    z.append("   Vortrag: — (offene Flanke)")
                    z.append("   Beweisantritt: —")
                } else {
                    z.append("   Vortrag:")
                    for v in vortrag {
                        z.append("     · \(v.kern)")
                        if let f = v.fundstelle { z.append("       Fundstelle: \(f.zitat), S. \(f.seite)") }
                    }
                    let beweise = vortrag.filter { $0.typ == .beleg }
                    z.append("   Beweisantritt:")
                    if beweise.isEmpty {
                        z.append("     · (kein Belegknoten)")
                    } else {
                        for b in beweise where b.status != .kiVorschlag {
                            z.append("     · \(b.nachweis.titel): \(b.kern)")
                        }
                    }
                }
                let angriffe = g.kinder(von: m.id).filter { $0.typ == .argGegner && $0.status != .kiVorschlag }
                if !angriffe.isEmpty {
                    z.append("   Erwiderung auf gegnerischen Vortrag:")
                    for a in angriffe {
                        z.append("     · Gegner: \(a.kern) (netto \(String(format: "%.2f", a.sNetto).replacingOccurrences(of: ".", with: ",")))")
                        let konter = g.kinder(von: a.id).filter { $0.typ == .argEigen && $0.status != .kiVorschlag }
                        for k in konter {
                            z.append("       Konter: \(k.kern)")
                        }
                    }
                }
                z.append("")
            }
        }
        z.append("P(Erfolg) \(NexusAnzeige.band(g.pErfolg)) — \(NexusAnzeige.betaHinweis)")
        z.append("NEXUS gibt Wahrscheinlichkeiten aus, keine Handlungsempfehlung.")
        return z.joined(separator: "\n")
    }
}
