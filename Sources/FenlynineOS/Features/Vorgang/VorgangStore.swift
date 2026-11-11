import Foundation
import SwiftUI
@Observable
final class VorgangStore {
    static let shared = VorgangStore()
    private let speicherKey = "fenlynineos_vorgaenge_v2"
    private(set) var vorgaenge: [Vorgang] = []
    weak var kernStore: FenlynineOSKernStore?
    private var speicherTask: Task<Void, Never>?
    private init() {
        laden()
        if vorgaenge.isEmpty {
            seed()
        } else {
            erneuereNexusDemoAst()
        }
    }
    private func erneuereNexusDemoAst() {
        let flag = "fenlynineos_nexus_kap06_v6"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        if let v = vorgaenge.first(where: { $0.kurzId == "V-2026-0004" }),
           let klage = v.optionen.first {
            NexusStore.shared.setze(NexusDemo.werklohnSalvatorisch(optionId: klage.id, vorgangId: v.id))
        }
        UserDefaults.standard.set(true, forKey: flag)
    }
    @discardableResult
    func neu(typ: VorgangTyp, titel: String, wer: String = "System") -> Vorgang {
        let kurz = naechsteKurzId()
        var v = Vorgang(kurzId: kurz, typ: typ, titel: titel)
        v.ereignisse.append(.init(was: "angelegt", wer: wer, alt: nil, neu: titel))
        if typ == .streit {
            var leer = Formelkaskade.nichtsTun(streitwert: 0)
            Formelkaskade.bewerte(&leer)
            v.optionen = [leer]
        }
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
    func kannWechseln(vorgang v: Vorgang, zu: VorgangZustand) -> Bool {
        if zu.reihenfolge < v.zustand.reihenfolge { return true }
        switch zu {
        case .erfasst:       return !v.titel.isEmpty
        case .strukturiert:  return v.aktiveOptionen.count >= 2
        case .bewertet:      return v.aktiveOptionen.count >= 2 && v.aktiveOptionen.allSatisfy { $0.bewertung.ev != nil && $0.bewertung.rav != nil }
        case .entschieden:   return v.entscheidung != nil
        case .laufend:       return v.entscheidung != nil
        case .abgeschlossen: return v.ergebnis != nil
        }
    }
    @discardableResult
    func setzeZustand(_ id: UUID, _ neu: VorgangZustand, wer: String = "Nutzer") -> Bool {
        guard let aktuell = vorgang(id) else { return false }
        guard kannWechseln(vorgang: aktuell, zu: neu) else { return false }
        mutate(id) { v in
            let alt = v.zustand.rawValue
            v.zustand = neu
            v.ereignisse.append(.init(was: "zustandswechsel", wer: wer, alt: alt, neu: neu.rawValue))
        }
        return true
    }
    func typWechseln(_ id: UUID, zu: VorgangTyp, wer: String = "Nutzer") {
        mutate(id) { v in
            let alt = v.typ.rawValue
            let aktive = v.optionen.filter { !$0.istVorgeschichte }
            for i in v.optionen.indices { v.optionen[i].istVorgeschichte = true }
            let klone: [VorgangOption] = aktive.map { o in
                var n = o
                n.id = UUID()
                n.istVorgeschichte = false
                n.bewertung = .init()
                return n
            }
            v.optionen.append(contentsOf: klone)
            if zu == .streit && !v.optionen.contains(where: { !$0.istVorgeschichte && $0.label.lowercased().contains("nichts tun") }) {
                v.optionen.append(Formelkaskade.nichtsTun(streitwert: v.volumen))
            }
            v.typ = zu
            v.zustand = .strukturiert
            v.empfehlung = nil
            v.entscheidung = nil
            v.ereignisse.append(.init(was: "typwechsel", wer: wer, alt: alt, neu: zu.rawValue))
        }
    }
    func fuegeOptionHinzu(_ id: UUID, _ option: VorgangOption, wer: String = "Nutzer") {
        mutate(id) { v in
            v.optionen.append(option)
            v.ereignisse.append(.init(was: "option_hinzugefuegt", wer: wer, alt: nil, neu: option.label))
        }
    }
    func bewerteAlleOptionen(_ id: UUID) {
        mutate(id) { v in
            if v.typ == .streit && !v.optionen.contains(where: { !$0.istVorgeschichte && $0.label.lowercased().contains("nichts tun") }) {
                v.optionen.append(Formelkaskade.nichtsTun(streitwert: v.volumen))
            }
            for i in v.optionen.indices where !v.optionen[i].istVorgeschichte {
                Formelkaskade.bewerte(&v.optionen[i])
            }
            if v.optionen.filter({ !$0.istVorgeschichte }).count >= 2,
               v.zustand.reihenfolge < VorgangZustand.strukturiert.reihenfolge {
                v.zustand = .strukturiert
            }
            v.ereignisse.append(.init(was: "bewertung_neu", wer: "Motor", alt: nil, neu: "Formelkaskade"))
        }
    }
    func entscheide(_ id: UUID, optionId: UUID, wer: String, abweichungGrund: String? = nil) {
        mutate(id) { v in
            var grund = abweichungGrund
            if grund == nil, let emp = v.empfehlung, emp.optionId != optionId {
                grund = "Abweichung von der Empfehlung"
            }
            v.entscheidung = .init(optionId: optionId, wer: wer, wann: .init(), abweichungGrund: grund)
            v.zustand = .entschieden
            v.ereignisse.append(.init(was: "entscheidung", wer: wer, alt: nil, neu: optionId.uuidString))
        }
    }
    func protokolliereAdvocatus(_ id: UUID, was: String, betrag: Double) {
        mutate(id) { v in
            v.ereignisse.append(.init(was: was, wer: "Advocatus", alt: nil, neu: InterfaceZahl.waehrung(betrag)))
        }
    }
    func schliesseAb(_ id: UUID, ergebnis: Ergebnis, wer: String) {
        mutate(id) { v in
            v.ergebnis = ergebnis
            v.zustand = .abgeschlossen
            v.ereignisse.append(.init(was: "abgeschlossen", wer: wer, alt: nil, neu: ergebnis.realAusgang))
        }
    }
    func fuegeFristHinzu(_ id: UUID, _ frist: VorgangFrist) {
        mutate(id) { v in
            v.fristen.append(frist)
            v.ereignisse.append(.init(was: "frist_hinzugefuegt", wer: frist.quelle, alt: nil, neu: frist.art))
        }
    }
    func setzeEmpfehlung(_ id: UUID) {
        mutate(id) { v in
            let profil = v.profil
            let rang = Formelkaskade.rangListe(v.optionen, profil: profil)
            guard let best = rang.first else { return }
            var begruendung = "Profil \(profil.titel) · Score \(InterfaceZahl.dezimal(Formelkaskade.rangScore(best, profil: profil))) — identisch mit Vergleich (A1)."
            if best.legalitaetsStatus == .grenzwertig {
                begruendung += " Option ist grenzwertig und bleibt im Ranking."
            }
            if let g = NexusStore.shared.graph(optionId: best.id) {
                begruendung += " P(Erfolg) \(NexusAnzeige.band(g.pErfolg))."
                let zuege = NexusEngine.zuege(g)
                if !zuege.isEmpty {
                    begruendung += " Nächste Züge: " + zuege.prefix(3).map { "\($0.hebel.titel) \($0.deltaPText)" }.joined(separator: " · ") + "."
                }
            } else {
                begruendung += " Höchster Score bei Kosten \(Int(best.kosten.summe)) €."
            }
            let verworfen = Formelkaskade.verworfene(v.optionen)
            if !verworfen.isEmpty {
                begruendung += " Geprüft und verworfen: " + verworfen.map(\.label).joined(separator: ", ") + "."
            }
            v.empfehlung = .init(
                optionId: best.id,
                score: Formelkaskade.rangScore(best, profil: profil),
                prognose: "Auf Basis Profil \(profil.titel) — P als Band \(NexusAnzeige.band(best.chancen.pErfolg.wert))",
                begruendung: begruendung,
                gegenprobe: Formelkaskade.gegenprobe(optionen: rang)
            )
            if v.zustand.reihenfolge < VorgangZustand.bewertet.reihenfolge {
                v.zustand = .bewertet
            }
            v.ereignisse.append(.init(was: "empfehlung", wer: "Motor", alt: nil, neu: best.label))
        }
    }
    func setzeProfil(_ id: UUID, _ profil: MandantenProfil) {
        mutate(id) { v in
            v.mandantenProfil = profil
            v.ereignisse.append(.init(was: "mandantenprofil", wer: "Nutzer", alt: nil, neu: profil.titel))
        }
        setzeEmpfehlung(id)
    }
    func setzeLegalitaet(_ id: UUID, optionId: UUID, _ status: OptionLegalitaet) {
        mutate(id) { v in
            guard let i = v.optionen.firstIndex(where: { $0.id == optionId }) else { return }
            v.optionen[i].legalitaet = status
            v.ereignisse.append(.init(was: "legalitaet", wer: "Nutzer", alt: v.optionen[i].label, neu: status.titel))
        }
        setzeEmpfehlung(id)
    }
    func hinterlegeBetriebsvereinbarung(_ id: UUID, titel: String) {
        mutate(id) { v in
            v.betriebsvereinbarungTitel = titel
            v.dokumente.append(.init(typ: "Betriebsvereinbarung", titel: titel, text: ""))
            v.ereignisse.append(.init(was: "betriebsvereinbarung", wer: "Nutzer", alt: nil, neu: titel))
        }
    }
    func setzeKontext(_ id: UUID, titel: String? = nil, beschreibung: String? = nil,
                      rechtsgebiet: String? = nil, volumen: Double? = nil) {
        mutate(id) { v in
            if let titel { v.titel = titel }
            if let beschreibung { v.beschreibung = beschreibung }
            if let rechtsgebiet { v.rechtsgebiet = rechtsgebiet }
            if let volumen { v.volumen = volumen }
            v.ereignisse.append(.init(was: "kontext", wer: "Nutzer", alt: nil, neu: v.titel))
        }
    }
    func fuegeParteiHinzu(_ id: UUID, rolle: String, name: String) {
        mutate(id) { v in
            v.parteien.append(.init(rolle: rolle, name: name))
            v.ereignisse.append(.init(was: "partei", wer: "Nutzer", alt: rolle, neu: name))
        }
    }
    func fuegeOptionAusEingabe(_ id: UUID, label: String, p: Double, best: Double, worst: Double, kosten: Double) {
        var o = VorgangOption(
            label: label,
            beschreibung: "",
            kosten: .init(anwalt: kosten * 0.6, gericht: kosten * 0.3, intern: kosten * 0.05, opportunitaet: kosten * 0.05),
            chancen: .init(
                pErfolg: .mensch(min(1, max(0, p)), name: "Nutzer"),
                best: .mensch(best, name: "Nutzer"),
                worst: .mensch(worst, name: "Nutzer"),
                likely: .formel(best * p + worst * (1 - p), "P × best + (1−P) × worst")
            ),
            zeit: .init(minMonate: 2, maxMonate: 14),
            qualitativ: .init(reputation: 0, beziehung: 0, medien: 0, praezedenz: 0),
            pManuellUebersteuert: true
        )
        Formelkaskade.bewerte(&o)
        fuegeOptionHinzu(id, o, wer: "Nutzer")
    }
    func nimmInsPortfolio(_ id: UUID, programmId: UUID) {
        mutate(id) { v in
            guard v.zustand.reihenfolge >= VorgangZustand.bewertet.reihenfolge else { return }
            v.programmId = programmId
            v.ereignisse.append(.init(was: "portfolio_aufnahme", wer: "Oportun", alt: nil, neu: programmId.uuidString))
        }
    }
    func loesche(_ id: UUID) {
        vorgaenge.removeAll { $0.id == id }
        scheduleSpeichern()
    }
    func vorgang(_ id: UUID) -> Vorgang? {
        vorgaenge.first { $0.id == id }
    }
    func imProgramm(_ programmId: UUID) -> [Vorgang] {
        vorgaenge.filter { $0.programmId == programmId }
    }
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
    private func scheduleSpeichern() {
        speicherTask?.cancel()
        speicherTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled, let self else { return }
            await MainActor.run { self.speichern() }
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
    private func spiegleImKernStore(_ v: Vorgang) {
        guard let store = kernStore else { return }
        Task { @MainActor in
            VorgangKausalBrucke.spiegleAlsEreignis(v, in: store)
        }
    }
    private func seed() {
        let werklohn = beispielWerklohn()
        let kschg = beispielBeta()
        let gamma = beispielGamma()
        let alpha = beispielAlpha()
        vorgaenge = [werklohn, kschg, gamma, alpha]
        speichern()
    }
    private func beispielWerklohn() -> Vorgang {
        var v = Vorgang(kurzId: "V-2026-0004", typ: .streit, titel: "Epsilon GmbH — Werklohn Softwarelieferung")
        v.parteien = [
            .init(rolle: "Mandant", name: "Epsilon GmbH"),
            .init(rolle: "Gegner", name: "Zeta Software AG")
        ]
        v.rechtsgebiet = "Werkvertragsrecht"
        v.volumen = 480_000
        v.beschreibung = "Softwarehaus liefert nicht. Klage auf Schadensersatz statt der Leistung, 480.000 €, §§ 280 I, III, 281 I BGB. Der Gegner greift die Wirksamkeit des Rahmenvertrags an (fehlende salvatorische Klausel)."
        v.zustand = .bewertet
        v.mandantenProfil = .ausgewogen
        var klage = demoOption("A · Klage §§ 280, 281 BGB", p: 0.50, best: 480_000, worst: -40_000, kosten: 28_000)
        klage.pManuellUebersteuert = false
        klage.legalitaet = .legal
        var vergleich = demoOption("B · Vergleich 310k €", p: 0.82, best: 310_000, worst: 80_000, kosten: 12_000)
        vergleich.legalitaet = .legal
        vergleich.pManuellUebersteuert = true
        var nichts = Formelkaskade.nichtsTun(streitwert: 480_000)
        nichts.legalitaet = .legal
        v.optionen = [klage, vergleich, nichts]
        var g = NexusDemo.werklohnSalvatorisch(optionId: klage.id, vorgangId: v.id)
        NexusStore.shared.setze(g)
        g = NexusStore.shared.graph(optionId: klage.id) ?? g
        if let i = v.optionen.firstIndex(where: { $0.id == klage.id }) {
            v.optionen[i].chancen.pErfolg = .formel(g.pErfolg, NexusDemo.herleitung(g))
            v.optionen[i].chancen.likely = .formel(
                v.optionen[i].chancen.best.wert * g.pErfolg + v.optionen[i].chancen.worst.wert * (1 - g.pErfolg),
                "P × best + (1−P) × worst"
            )
            for flanke in g.offeneFlanken {
                v.optionen[i].risiken.append(.init(titel: "Offene Flanke: \(flanke.kern)", eintrittWahrscheinlichkeit: 8, auswirkung: 8, entdeckung: 5))
            }
        }
        for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
        v.ereignisse = [
            .init(was: "angelegt", wer: "System", alt: nil, neu: v.titel),
            .init(was: "nexus_p_uebernommen", wer: "NEXUS", alt: nil, neu: NexusAnzeige.band(g.pErfolg))
        ]
        return v
    }
    private func beispielAlpha() -> Vorgang {
        var v = Vorgang(kurzId: "V-2026-0001", typ: .gestaltung, titel: "Alpha Holdings — Steuerstruktur")
        v.parteien = [.init(rolle: "Mandant", name: "Alpha Holdings AG")]
        v.rechtsgebiet = "Steuerrecht"
        v.volumen = 8_000_000
        v.beschreibung = "Steueroptimierung vs. Steuerhinterziehung — drei Wege durch die Struktur."
        v.zustand = .bewertet
        v.optionen = [
            demoOption("A · Legale Optimierung", p: 0.95, best: 2_000_000, worst: 500_000, kosten: 120_000, legalitaet: .legal),
            demoOption("B · Aggressive Vermeidung", p: 0.60, best: 5_000_000, worst: -1_500_000, kosten: 310_000, legalitaet: .grenzwertig),
            demoOption("C · Hinterziehung", p: 0.40, best: 7_000_000, worst: -12_000_000, kosten: 400_000, legalitaet: .rechtswidrig)
        ]
        for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
        v.ereignisse = [
            .init(was: "angelegt", wer: "System", alt: nil, neu: v.titel),
            .init(was: "bewertung_neu", wer: "Motor", alt: nil, neu: "Formelkaskade")
        ]
        return v
    }
    private func beispielBeta() -> Vorgang {
        var v = Vorgang(kurzId: "V-2026-0002", typ: .streit, titel: "Beta GmbH ./. Schmidt — Kündigungsschutz")
        v.parteien = [
            .init(rolle: "Mandant", name: "Beta GmbH"),
            .init(rolle: "Gegner", name: "Herr Schmidt")
        ]
        v.rechtsgebiet = "Arbeitsrecht"
        v.volumen = 42_000
        v.beschreibung = "Kündigungsschutzklage — Zugang am 26.06.2026."
        v.zustand = .bewertet
        v.fristen = [Formelkaskade.klageFristKSchG(zugang: Date().addingTimeInterval(-15*24*3600))]
        v.optionen = [
            demoOption("A · Vergleich anbieten", p: 0.78, best: 24_000, worst: 3_200, kosten: 3_200),
            demoOption("B · Klage volle Instanz", p: 0.61, best: 42_000, worst: -9_800, kosten: 9_800),
            demoOption("C · Abfindung fordern", p: 0.70, best: 21_000, worst: 4_100, kosten: 4_100),
            demoOption("D · Nichts tun (Frist verstreicht)", p: 0.00, best: 0, worst: -42_000, kosten: 0)
        ]
        if let klage = v.optionen.first(where: { $0.label.contains("Klage") }) {
            NexusStore.shared.setze(NexusDemo.kschgSkelett(optionId: klage.id, vorgangId: v.id))
        }
        for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
        v.ereignisse = [
            .init(was: "angelegt", wer: "System", alt: nil, neu: v.titel)
        ]
        return v
    }
    private func beispielGamma() -> Vorgang {
        var v = Vorgang(kurzId: "V-2026-0003", typ: .streit, titel: "Gamma AG — Lizenzstreit")
        v.parteien = [
            .init(rolle: "Mandant", name: "Gamma AG"),
            .init(rolle: "Gegner", name: "Delta Ltd.")
        ]
        v.rechtsgebiet = "IP-Recht"
        v.volumen = 620_000
        v.beschreibung = "Lizenzverletzung Softwarepatent — Vergleich oder Klage."
        v.zustand = .bewertet
        v.optionen = [
            demoOption("A · Vergleich 420k €", p: 0.85, best: 420_000, worst: 100_000, kosten: 25_000),
            demoOption("B · Klage LG Frankfurt", p: 0.55, best: 620_000, worst: -80_000, kosten: 45_000)
        ]
        for i in v.optionen.indices { Formelkaskade.bewerte(&v.optionen[i]) }
        v.ereignisse = [.init(was: "angelegt", wer: "System", alt: nil, neu: v.titel)]
        return v
    }
    private func demoOption(_ label: String, p: Double, best: Double, worst: Double, kosten: Double, legalitaet: OptionLegalitaet = .legal) -> VorgangOption {
        var o = VorgangOption(
            label: label,
            beschreibung: "",
            kosten: .init(anwalt: kosten * 0.6, gericht: kosten * 0.3, intern: kosten * 0.05, opportunitaet: kosten * 0.05),
            chancen: .init(
                pErfolg: .ki(p, modell: "Claude"),
                best: .mensch(best, name: "RA Dr. M."),
                worst: .mensch(worst, name: "RA Dr. M."),
                likely: .formel(best * p + worst * (1 - p), "P × best + (1−P) × worst")
            ),
            zeit: .init(minMonate: 2, maxMonate: 14),
            qualitativ: .init(reputation: 0, beziehung: 0, medien: 0, praezedenz: 0)
        )
        o.legalitaet = legalitaet
        return o
    }
}
