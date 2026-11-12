import Foundation
import SwiftUI
enum StrategosOpportunismaVertragsMapper {
    @MainActor
    static func anwenden(
        auf vm: OpportunismaViewModel,
        vertrag: [String: Any],
        szenario: StrategosScenario? = nil
    ) {
        let mapped = StrategosOpportunismaVertragsService.opportunismaDaten(aus: vertrag)
        if !mapped.kausalitaeten.isEmpty { vm.kausalitaeten = mapped.kausalitaeten }
        if !mapped.prognosen.isEmpty { vm.prognosen = mapped.prognosen }
        if let ctx = szenario?.unternehmenskontext?.dictValue {
            let name = ctx["unternehmen_name"] as? String ?? "Unternehmen"
            let gegner = ctx["gegner_name"] as? String ?? "Vertragspartner"
            let sach = ctx["sachverhalt_lang"] as? String ?? ""
            vm.situationText = "Vertrag: \(name) ↔ \(gegner). \(sach)"
        }
        if let ziel = szenario?.fragestellung, !ziel.isEmpty { vm.zielText = ziel }
        if let risiko = vertrag["gesamtrisiko"] as? String {
            vm.fragebogenZusammenfassung = "Vertragslage (Strategos): \(risiko)"
            vm.machtIndex = risikoIndex(aus: risiko)
        }
        vm.hebel = hebelAusKlauseln(vertrag)
        vm.dimensionen = dimensionenAusKlauseln(vertrag)
        vm.strategischeZiele = zieleAusHypothesen(vertrag)
        vm.szenarien = szenarioZeilenAusAnalyse(vertrag)
        vm.ressourcen = ressourcenAusSteuer(vertrag)
        vm.risikoMatrix = risikoMatrixAusKlauseln(vertrag)
        vm.netzKnoten = netzAusPolitikUndKontext(vertrag, szenario: szenario)
        vm.netzKanten = kantenFuerNetz(vm.netzKnoten)
        vm.meilensteine = meilensteineAusTerminen(vertrag)
        vm.narrativ = narrativAusPolitik(vertrag)
        vm.influence = influenceAusLobby(vertrag)
        vm.hegemonogramm = hegemonogrammAusKlauseln(vertrag)
        vm.gegner = gegnerAusKontext(szenario)
        let vertragsBaum = baumAusVertragsanalyse(vertrag)
        let vertragsSzenario = PragSzenario(
            id: "vertrag",
            label: "Vertragsanalyse",
            situation: vm.situationText,
            ziel: vm.zielText,
            akteure: akteureAusAnalyse(vertrag, szenario: szenario),
            root: vertragsBaum
        )
        vm.szenarienBaum["vertrag"] = vertragsSzenario
        if var unternehmen = vm.szenarienBaum["unternehmen"] {
            unternehmen.situation = vm.situationText
            unternehmen.ziel = vm.zielText
            unternehmen.root = mergeBaumWurzel(unternehmen.root, vertragsBaum: vertragsBaum)
            vm.szenarienBaum["unternehmen"] = unternehmen
        }
        vm.szenarioKey = "vertrag"
        vm.selectedNodeId = vertragsBaum.id
    }
    @MainActor
    static func fuegeWasWennSzenarioHinzu(
        auf vm: OpportunismaViewModel,
        verletzer: String,
        klausel: String,
        folge: String,
        rechtlicheOptionen: [String],
        unternehmenswirkung: String
    ) {
        let situation = "\(verletzer) hält Klausel nicht ein: \(klausel)"
        let optionenText = rechtlicheOptionen.isEmpty ? "—" : rechtlicheOptionen.joined(separator: "; ")
        let prognose = PragPrognoseZeile(
            situation: situation,
            option: optionenText,
            fuehrt_zu: folge,
            vorteile: unternehmenswirkung.contains("+") || unternehmenswirkung.lowercased().contains("vorteil")
                ? [unternehmenswirkung] : [],
            risiken: unternehmenswirkung.lowercased().contains("risiko") || unternehmenswirkung.lowercased().contains("schaden")
                ? [unternehmenswirkung] : [folge],
            wahrscheinlichkeit: 55,
            kontrolle: verletzer.contains("Eigen") ? 70 : 35,
            beeinflussbar: verletzer.contains("Eigen"),
            mittel: rechtlicheOptionen,
            dimension: "Recht & Unternehmen"
        )
        vm.prognosen.insert(prognose, at: 0)
        let kausal = PragKausalitaet(
            ursache: situation,
            wirkung: folge,
            beeinflussbar: verletzer.contains("Eigen"),
            bewertung: unternehmenswirkung.lowercased().contains("schaden") ? "risiko" : "neutral",
            betroffene: [verletzer, klausel],
            empfehlung: optionenText,
            strategosBezug: "Vertragsanalyse · Was-wenn"
        )
        vm.kausalitaeten.insert(kausal, at: 0)
        let knoten = PragTreeNode(
            id: "ww_\(UUID().uuidString.prefix(8))",
            typ: .move,
            label: "Was-wenn: \(verletzer)",
            detail: klausel,
            scores: .init(efficacy: 50, risk: 60, reversibility: 40, harm: 55),
            children: [
                PragTreeNode(
                    id: "ww_out_\(UUID().uuidString.prefix(8))",
                    typ: .outcome,
                    label: folge,
                    detail: unternehmenswirkung,
                    scores: nil,
                    children: rechtlicheOptionen.map { opt in
                        PragTreeNode(
                            id: "ww_goal_\(UUID().uuidString.prefix(8))",
                            typ: .goal,
                            label: opt,
                            detail: unternehmenswirkung,
                            scores: .init(efficacy: 55, risk: 45, reversibility: 50, harm: 30),
                            children: []
                        )
                    }
                )
            ]
        )
        vm.fuegeBaumKnoten(parentId: vm.aktivesSzenario.root.id, knoten: knoten)
    }
    static func baumAusVertragsanalyse(_ vertrag: [String: Any]) -> PragTreeNode {
        var kinder: [PragTreeNode] = []
        let klauseln = KIJson.array(in: vertrag, keys: "klauseln")
        for (ki, k) in klauseln.prefix(8).enumerated() {
            let typ = k["klausel_typ"] as? String ?? "Klausel"
            let risiko = risikoWert(k["risiko_level"] as? String)
            kinder.append(PragTreeNode(
                id: "vk_\(ki)",
                typ: .move,
                label: typ,
                detail: k["kurzbeschreibung"] as? String ?? "",
                scores: .init(efficacy: 100 - risiko, risk: risiko, reversibility: 55, harm: risiko / 2),
                children: [
                    PragTreeNode(
                        id: "vo_k_\(ki)",
                        typ: .outcome,
                        label: "Wirkung auf Unternehmen",
                        detail: k["wirkung_unternehmen"] as? String ?? k["wirkung_gesamt"] as? String ?? "—",
                        scores: nil,
                        children: [
                            PragTreeNode(
                                id: "vg_k_\(ki)",
                                typ: .goal,
                                label: k["empfehlung"] as? String ?? "Handlungsoption",
                                detail: (k["betroffene_bereiche"] as? [String])?.joined(separator: ", ") ?? "",
                                scores: nil,
                                children: []
                            )
                        ]
                    )
                ]
            ))
        }
        let baeume = KIJson.array(in: vertrag, keys: "entscheidungsbaeume")
        for (bi, baum) in baeume.enumerated() {
            let optionen = baum["optionen"] as? [[String: Any]] ?? []
            for (oi, opt) in optionen.enumerated() {
                kinder.append(baumKnotenAusOption(opt, prefix: "vd_\(bi)_\(oi)"))
            }
        }
        if let eig = vertrag["eigene_pflichtverletzung"] as? [String: Any] {
            kinder.append(PragTreeNode(
                id: "veig",
                typ: .move,
                label: "Eigene Pflichtverletzung",
                detail: eig["szenario"] as? String ?? "",
                scores: .init(efficacy: 40, risk: 75, reversibility: 30, harm: 60),
                children: (eig["risiken"] as? [String] ?? []).enumerated().map { i, r in
                    PragTreeNode(
                        id: "veig_r_\(i)",
                        typ: .outcome,
                        label: r,
                        detail: eig["kostenersparnis"] as? String ?? "",
                        scores: nil,
                        children: [
                            PragTreeNode(
                                id: "veig_g_\(i)",
                                typ: .goal,
                                label: eig["empfehlung"] as? String ?? "Empfehlung",
                                detail: "",
                                scores: nil,
                                children: []
                            )
                        ]
                    )
                }
            ))
        }
        let wurzelLabel = baeume.first?["wurzel"] as? String ?? "Vertragslage & Zukunftspfad"
        return PragTreeNode(
            id: "vroot",
            typ: .position,
            label: wurzelLabel,
            detail: vertrag["methodik"] as? String ?? "Klauseln · Entscheidungen · Folgen",
            scores: nil,
            children: kinder
        )
    }
    private static func baumKnotenAusOption(_ opt: [String: Any], prefix: String) -> PragTreeNode {
        let wahr = KIJson.intValue(opt["wahrscheinlichkeit_pct"]) ?? 50
        let folgen = opt["folge_optionen"] as? [String] ?? []
        var outcomeKinder: [PragTreeNode] = folgen.enumerated().map { fi, folge in
            PragTreeNode(
                id: "\(prefix)_f_\(fi)",
                typ: .outcome,
                label: folge,
                detail: opt["wirkung_unternehmen"] as? String ?? "",
                scores: .init(efficacy: 100 - wahr, risk: wahr, reversibility: 50, harm: wahr / 2),
                children: [
                    PragTreeNode(
                        id: "\(prefix)_g_\(fi)",
                        typ: .goal,
                        label: opt["ziel"] as? String ?? "Ziel",
                        detail: opt["wirkung_unternehmen"] as? String ?? "",
                        scores: nil,
                        children: []
                    )
                ]
            )
        }
        if outcomeKinder.isEmpty {
            outcomeKinder = [
                PragTreeNode(
                    id: "\(prefix)_g",
                    typ: .goal,
                    label: opt["ziel"] as? String ?? "Folge",
                    detail: opt["wirkung_unternehmen"] as? String ?? "",
                    scores: nil,
                    children: []
                )
            ]
        }
        return PragTreeNode(
            id: "\(prefix)_m",
            typ: .move,
            label: opt["label"] as? String ?? "Entscheidung",
            detail: opt["wirkung_unternehmen"] as? String ?? "",
            scores: .init(efficacy: 100 - wahr, risk: wahr, reversibility: 60, harm: wahr / 3),
            children: outcomeKinder
        )
    }
    private static func mergeBaumWurzel(_ root: PragTreeNode, vertragsBaum: PragTreeNode) -> PragTreeNode {
        var n = root
        let vertragsZweig = PragTreeNode(
            id: "vbranch",
            typ: .move,
            label: "Vertragsanalyse (Strategos)",
            detail: vertragsBaum.label,
            scores: nil,
            children: vertragsBaum.children
        )
        if !n.children.contains(where: { $0.id == "vbranch" }) {
            n.children.insert(vertragsZweig, at: 0)
        }
        return n
    }
    private static func hebelAusKlauseln(_ v: [String: Any]) -> [PragBarItem] {
        KIJson.array(in: v, keys: "klauseln").prefix(6).map { k in
            PragBarItem(
                name: k["klausel_typ"] as? String ?? "Klausel",
                wert: 100 - risikoWert(k["risiko_level"] as? String)
            )
        }
    }
    private static func dimensionenAusKlauseln(_ v: [String: Any]) -> [PragBarItem] {
        var dims: [String: Int] = [:]
        for k in KIJson.array(in: v, keys: "klauseln") {
            let r = risikoWert(k["risiko_level"] as? String)
            for bereich in k["betroffene_bereiche"] as? [String] ?? ["Vertrag"] {
                dims[bereich, default: 0] += (100 - r) / max(1, (k["betroffene_bereiche"] as? [String])?.count ?? 1)
            }
        }
        if dims.isEmpty {
            return OpportunismaDemo.dimensionen
        }
        return dims.map { PragBarItem(name: $0.key, wert: min(100, $0.value)) }
    }
    private static func zieleAusHypothesen(_ v: [String: Any]) -> [PragZielZeile] {
        KIJson.array(in: v, keys: "zielhypothesen").map { z in
            PragZielZeile(
                ziel: z["ziel"] as? String ?? "Ziel",
                status: z["typ"] as? String ?? "Hypothese",
                fortschritt: KIJson.intValue(z["wahrscheinlichkeit_pct"]) ?? 50
            )
        }
    }
    private static func szenarioZeilenAusAnalyse(_ v: [String: Any]) -> [PragSzenarioZeile] {
        var zeilen: [PragSzenarioZeile] = []
        for z in KIJson.array(in: v, keys: "zielhypothesen") {
            zeilen.append(PragSzenarioZeile(
                name: z["ziel"] as? String ?? "Szenario",
                wahrscheinlichkeit: KIJson.intValue(z["wahrscheinlichkeit_pct"]) ?? 50,
                kontrolle: 55,
                ergebnis: z["typ"] as? String ?? "OPTION"
            ))
        }
        for t in KIJson.array(in: v, keys: "liefertermine") {
            let p = KIJson.intValue(t["wahrscheinlichkeit_verzug_pct"]) ?? 30
            zeilen.append(PragSzenarioZeile(
                name: "Verzug: \(t["termin"] as? String ?? "Termin")",
                wahrscheinlichkeit: p,
                kontrolle: (t["durchsetzung_sinnvoll"] as? Bool ?? false) ? 65 : 35,
                ergebnis: p > 50 ? "RISIKO" : "OPTION"
            ))
        }
        return zeilen.isEmpty ? OpportunismaDemo.szenarioZeilen : zeilen
    }
    private static func ressourcenAusSteuer(_ v: [String: Any]) -> [PragBarItem] {
        let steuer = KIJson.array(in: v, keys: "steuer_ressourcen")
        if steuer.isEmpty { return OpportunismaDemo.ressourcen }
        return steuer.map { s in
            let kosten = KIJson.numberValue(s["kosten_eur"]) ?? 0
            let strafe = KIJson.numberValue(s["strafe_risiko_eur"]) ?? 0
            let wert = max(10, min(100, Int(100 - (kosten + strafe) / 10000)))
            return PragBarItem(name: s["option"] as? String ?? "Option", wert: wert)
        }
    }
    private static func risikoMatrixAusKlauseln(_ v: [String: Any]) -> [[Int]] {
        let klauseln = KIJson.array(in: v, keys: "klauseln")
        guard !klauseln.isEmpty else { return OpportunismaDemo.risikoMatrix }
        var matrix = OpportunismaDemo.risikoMatrix
        for (i, k) in klauseln.prefix(5).enumerated() {
            let r = risikoWert(k["risiko_level"] as? String)
            let row = min(4, i)
            let col = min(4, r / 20)
            matrix[row][col] = max(matrix[row][col], min(6, r / 15 + 1))
        }
        return matrix
    }
    private static func netzAusPolitikUndKontext(
        _ v: [String: Any],
        szenario: StrategosScenario?
    ) -> [PragNetzKnoten] {
        var knoten: [PragNetzKnoten] = [
            .init(label: "UNTERNEHMEN", typ: "kontrolliert", x: 0.5, y: 0.45)
        ]
        let ctx = szenario?.unternehmenskontext?.dictValue ?? [:]
        if let gegner = ctx["gegner_name"] as? String, !gegner.isEmpty {
            knoten.append(.init(label: gegner, typ: "feindlich", x: 0.78, y: 0.62))
        }
        let lobby = KIJson.array(in: v, keys: "politik_lobby")
        for (i, l) in lobby.prefix(4).enumerated() {
            let x = 0.2 + CGFloat(i) * 0.18
            knoten.append(.init(
                label: l["akteur"] as? String ?? "Akteur",
                typ: i % 2 == 0 ? "verbündet" : "neutral",
                x: min(0.85, x),
                y: 0.22 + CGFloat(i % 2) * 0.15
            ))
        }
        return knoten.count > 1 ? knoten : OpportunismaDemo.netzKnoten
    }
    private static func kantenFuerNetz(_ knoten: [PragNetzKnoten]) -> [PragNetzKante] {
        guard let root = knoten.first?.label else { return OpportunismaDemo.netzKanten }
        return knoten.dropFirst().map { PragNetzKante(von: root, zu: $0.label) }
    }
    private static func meilensteineAusTerminen(_ v: [String: Any]) -> [PragMeilenstein] {
        let termine = KIJson.array(in: v, keys: "liefertermine")
        if termine.isEmpty { return OpportunismaDemo.meilensteine }
        return termine.enumerated().map { i, t in
            PragMeilenstein(
                titel: t["termin"] as? String ?? "Termin \(i + 1)",
                start: i * 2,
                dauer: max(1, (KIJson.intValue(t["wahrscheinlichkeit_verzug_pct"]) ?? 30) / 20)
            )
        }
    }
    private static func narrativAusPolitik(_ v: [String: Any]) -> [(label: String, value: Double)] {
        let lobby = KIJson.array(in: v, keys: "politik_lobby")
        if lobby.isEmpty { return OpportunismaDemo.narrativ }
        return lobby.map { l in
            (l["akteur"] as? String ?? "Politik", 5.0 + Double((KIJson.string(in: l, keys: "massnahme", "maßnahme") ?? "").count % 30) / 10)
        }
    }
    private static func influenceAusLobby(_ v: [String: Any]) -> [PragBarItem] {
        KIJson.array(in: v, keys: "politik_lobby").map { l in
            PragBarItem(
                name: KIJson.string(in: l, keys: "massnahme", "maßnahme") ?? "Maßnahme",
                wert: min(95, 40 + (l["folge"] as? String ?? "").count % 55)
            )
        }
    }
    private static func hegemonogrammAusKlauseln(_ v: [String: Any]) -> [(label: String, ist: Double, soll: Double)] {
        let klauseln = KIJson.array(in: v, keys: "klauseln")
        if klauseln.isEmpty { return OpportunismaDemo.hegemonogramm }
        return klauseln.prefix(8).map { k in
            let ist = Double(100 - risikoWert(k["risiko_level"] as? String)) / 10
            return (k["klausel_typ"] as? String ?? "Klausel", ist, min(9.5, ist + 2.0))
        }
    }
    private static func gegnerAusKontext(_ szenario: StrategosScenario?) -> [PragGegnerZeile] {
        guard let ctx = szenario?.unternehmenskontext?.dictValue,
              let name = ctx["gegner_name"] as? String, !name.isEmpty else {
            return OpportunismaDemo.gegner
        }
        return [
            PragGegnerZeile(
                name: name,
                einfluss: ctx["gegner_rolle"] as? String ?? "Vertragspartner",
                bedrohung: "Vertragsrisiko",
                kontrolle: "Verhandlung & Compliance"
            )
        ] + OpportunismaDemo.gegner.prefix(2)
    }
    private static func akteureAusAnalyse(
        _ v: [String: Any],
        szenario: StrategosScenario?
    ) -> [String] {
        var akteure = ["Eigenes Unternehmen"]
        if let g = szenario?.unternehmenskontext?.dictValue?["gegner_name"] as? String {
            akteure.append(g)
        }
        for k in KIJson.array(in: v, keys: "klauseln") {
            akteure.append(contentsOf: k["betroffene_personen_rollen"] as? [String] ?? [])
        }
        return Array(Set(akteure))
    }
    private static func risikoWert(_ level: String?) -> Int {
        switch level?.lowercased() {
        case "kritisch": return 90
        case "hoch": return 75
        case "mittel": return 50
        case "niedrig": return 25
        default: return 40
        }
    }
    private static func risikoIndex(aus text: String) -> Int {
        let t = text.lowercased()
        if t.contains("kritisch") || t.contains("hoch") { return 72 }
        if t.contains("mittel") { return 55 }
        return 42
    }
}
