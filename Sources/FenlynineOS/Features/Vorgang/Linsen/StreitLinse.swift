import SwiftUI
struct StreitLinse: View {
    let vorgangId: UUID
    @Bindable var store: VorgangStore = .shared
    @State private var filter: Herkunft? = nil
    @State private var risikoAversion: Double = 0.5
    private var vorgang: Vorgang? { store.vorgang(vorgangId) }
    var body: some View {
        if let v = vorgang {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    kopfInfo(v)
                    optionenReihe(v)
                    HStack(alignment: .top, spacing: 14) {
                        rvgBlock(v)
                        fristBlock(v)
                    }
                    rechenwerkBlock(v)
                    if let g = v.empfehlung?.gegenprobe {
                        InterfaceKarte(ebene: 2) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("GEGENPROBE — DIE APP GEGEN SICH SELBST")
                                    .font(.system(size: 10, weight: .semibold))
                                    .kerning(0.4)
                                    .foregroundStyle(InterfacePalette.sekundaer)
                                Text(g)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Premium.text)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                        }
                    }
                    GewichtungsPanel(vorgangId: v.id, optionen: v.optionen.filter { !$0.istVorgeschichte })
                }
                .padding(16)
            }
        } else {
            Text("Vorgang nicht gefunden").foregroundStyle(Premium.text)
        }
    }
    private func leitOption(_ v: Vorgang) -> VorgangOption? {
        let aktive = v.optionen.filter { !$0.istVorgeschichte }
        if let empf = v.empfehlung?.optionId, let o = aktive.first(where: { $0.id == empf }) {
            return o
        }
        return aktive.max(by: { ($0.bewertung.ev?.wert ?? -.infinity) < ($1.bewertung.ev?.wert ?? -.infinity) })
    }
    @ViewBuilder
    private func rechenwerkBlock(_ v: Vorgang) -> some View {
        if let o = leitOption(v), o.bewertung.ev != nil {
            let mc = Rechenwerk.monteCarlo(o, risikoAversion: risikoAversion)
            let korridor = Rechenwerk.vergleichskorridor(o, risikoAversion: risikoAversion)
            InterfaceKarte(ebene: 2) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Herkunftsmarke(herkunft: .formel, groesse: 8)
                        Text("RECHENWERK · MONTE-CARLO · 100 % FORMEL")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(0.4)
                            .foregroundStyle(InterfacePalette.berechnet)
                        Spacer()
                        QuellenInfo(auskunft: .formel(
                            "Ergebnisverteilung der Option „\(o.label)\u{201C}",
                            formel: mc.modell,
                            datenbasis: "Ihre Optionswerte (P, best, worst, Kosten) — keine KI"
                        ))
                    }
                    HStack(spacing: 14) {
                        rwKennzahl("P10 (pessimistisch)", mc.p10, kritischWennNegativ: true)
                        rwKennzahl("Median", mc.median, kritischWennNegativ: true)
                        rwKennzahl("P90 (optimistisch)", mc.p90, kritischWennNegativ: false)
                        rwKennzahl("P(Gewinn)", mc.gewinnQuote, prozent: true)
                        rwKennzahl("Zertitätsäquivalent", mc.zertitaet, kritischWennNegativ: true)
                    }
                    HStack(spacing: 10) {
                        Text("Risikoaversion")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(InterfacePalette.sekundaer)
                        Slider(value: $risikoAversion, in: 0.05...1.0)
                            .frame(maxWidth: 220)
                        Text(risikoAversion < 0.35 ? "risikofreudig" : (risikoAversion > 0.65 ? "vorsichtig" : "neutral"))
                            .font(.system(size: 10.5))
                            .foregroundStyle(Premium.textFaint)
                        QuellenInfo(auskunft: .formel(
                            "Wirkung des Reglers",
                            formel: "λ = Aversion / Spannweite → CE = −(1/λ)·ln E[e^(−λX)]",
                            datenbasis: "Exponentieller Nutzen (Standardmodell der Entscheidungstheorie)"
                        ))
                    }
                    Divider().overlay(InterfacePalette.trennlinie)
                    HStack(spacing: 6) {
                        Text("VERGLEICHSKORRIDOR (BATNA / ZOPA)")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(0.4)
                            .foregroundStyle(InterfacePalette.berechnet)
                        Spacer()
                        QuellenInfo(auskunft: .formel(
                            "Verhandlungsbereich zwischen unserem BATNA und der Schmerzgrenze der Gegenseite",
                            formel: "Unten = CE (BATNA) · Oben = P × best + Kostenersparnis · Anker = ZOPA-Mitte",
                            datenbasis: "Ihre Optionswerte; Gegnerseite konservativ gespiegelt — kein 70-%-Anker"
                        ))
                    }
                    if korridor.existiert {
                        HStack(spacing: 14) {
                            rwKennzahl("BATNA (unten)", korridor.untergrenze, kritischWennNegativ: true)
                            rwKennzahl("ZOPA-Mitte", korridor.anker, hervor: true)
                            rwKennzahl("Schmerzgrenze Gegner", korridor.obergrenze)
                        }
                    } else {
                        Text("Kein Einigungsbereich: Beide Seiten fahren mit dem Verfahren besser. Ein Vergleich setzt voraus, dass eine Annahme falsch ist.")
                            .font(.system(size: 11))
                            .foregroundStyle(InterfacePalette.kritisch)
                    }
                }
                .padding(12)
            }
        }
    }
    private func rwKennzahl(_ label: String, _ w: WertMitHerkunft, prozent: Bool = false, kritischWennNegativ: Bool = false, hervor: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .kerning(0.4)
                .foregroundStyle(InterfacePalette.sekundaer)
                .lineLimit(1)
            HStack(spacing: 5) {
                Herkunftsmarke(herkunft: w.herkunft, groesse: 6)
                Text(prozent ? InterfaceZahl.prozent(w.wert) : InterfaceZahl.waehrung(w.wert))
                    .font(.system(size: hervor ? 15 : 13, weight: hervor ? .bold : .semibold))
                    .monospacedDigit()
                    .foregroundStyle(
                        hervor ? InterfacePalette.berechnet
                        : (kritischWennNegativ && w.wert < 0 ? InterfacePalette.kritisch : Premium.text)
                    )
            }
        }
        .help(w.quelle)
    }
    private func kopfInfo(_ v: Vorgang) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Streitwert")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.4)
                    .foregroundStyle(InterfacePalette.sekundaer)
                Text(InterfaceZahl.waehrung(v.volumen, mitVorzeichen: false))
                    .font(.system(size: 20, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Premium.text)
            }
            if let frist = v.fristen.filter(\.erzeugtAlarm).min(by: { $0.tageBisAblauf < $1.tageBisAblauf }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nächste Frist")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(InterfacePalette.sekundaer)
                    HStack(spacing: 6) {
                        Herkunftsmarke(herkunft: .formel, groesse: 8)
                        Text("\(frist.art) · \(frist.tageBisAblauf) Tage")
                            .font(.system(size: 16, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(frist.kritisch ? InterfacePalette.kritisch : .white)
                    }
                }
            }
            Spacer()
            HerkunftsFilter(aktiv: $filter, zaehler: zaehlerHerkunft(v))
        }
    }
    private func optionenReihe(_ v: Vorgang) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEGE DURCH DEN KONFLIKT")
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(InterfacePalette.sekundaer)
            let rang = Formelkaskade.rangListe(v.optionen, profil: v.profil)
            let verworfen = Formelkaskade.verworfene(v.optionen)
            HStack {
                Text("Rangfolge nach Profil \(v.profil.titel) — identisch mit der Empfehlung")
                    .font(.system(size: 11))
                    .foregroundStyle(InterfacePalette.sekundaer)
                Spacer()
                Button("NEXUS öffnen") {
                    NotificationCenter.default.post(name: .oeffneNexusLinse, object: nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(InterfacePalette.aktion)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 10)], spacing: 10) {
                ForEach(Array(rang.enumerated()), id: \.element.id) { idx, o in
                    optionKarte(o, rang: idx + 1, empfohlen: v.empfehlung?.optionId == o.id)
                }
            }
            if !verworfen.isEmpty {
                Text("GEPRÜFT UND VERWORFEN — RECHTSWIDRIG, NICHT IM RANKING")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.4)
                    .foregroundStyle(InterfacePalette.kritisch)
                    .padding(.top, 8)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 10)], spacing: 10) {
                    ForEach(verworfen) { o in
                        optionKarte(o, rang: nil, empfohlen: false)
                    }
                }
            }
        }
    }
    private func optionKarte(_ o: VorgangOption, rang: Int?, empfohlen: Bool) -> some View {
        let graph = NexusStore.shared.graph(optionId: o.id)
        return InterfaceKarte(ebene: 2) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let rang {
                        Text("#\(rang)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(InterfacePalette.sekundaer)
                    }
                    if empfohlen {
                        Text("EMPFOHLEN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(InterfacePalette.berechnet)
                    }
                    if o.legalitaetsStatus == .rechtswidrig {
                        Text("VERWORFEN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(InterfacePalette.kritisch)
                    } else if o.legalitaetsStatus == .grenzwertig {
                        Text("GRENZWERTIG")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(InterfacePalette.vorgeschlagen)
                    }
                    Text(o.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Premium.text)
                }
                if let ev = o.bewertung.ev {
                    WertBohrer(
                        wert: ev,
                        label: "Erwartungswert",
                        kinder: [
                            ("P(Erfolg)", o.chancen.pErfolg),
                            ("Best", o.chancen.best),
                            ("Worst", o.chancen.worst)
                        ]
                    )
                }
                VStack(spacing: 4) {
                    HStack {
                        Text("P(Erfolg)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(InterfacePalette.sekundaer)
                        Spacer()
                        Herkunftsmarke(herkunft: o.chancen.pErfolg.herkunft, groesse: 6)
                        Text(NexusAnzeige.band(o.chancen.pErfolg.wert))
                            .font(.system(size: 13, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(InterfacePalette.berechnet)
                    }
                    .help(o.chancen.pErfolg.quelle)
                    if let g = graph {
                        HStack {
                            Text("Belegtheit")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(InterfacePalette.sekundaer)
                            Spacer()
                            Text("\(Int((g.belegtheit * 100).rounded())) %")
                                .font(.system(size: 13, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(Premium.text)
                        }
                        let zuege = NexusEngine.zuege(g).prefix(3)
                        if !zuege.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("NÄCHSTE ZÜGE · NEXUS")
                                    .font(.system(size: 9, weight: .bold))
                                    .kerning(0.4)
                                    .foregroundStyle(InterfacePalette.sekundaer)
                                ForEach(Array(zuege.enumerated()), id: \.element.id) { i, zug in
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text("\(i + 1).")
                                            .font(.system(size: 10))
                                            .foregroundStyle(InterfacePalette.sekundaer)
                                        Text(zug.titel)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Premium.text)
                                            .lineLimit(2)
                                        Spacer(minLength: 4)
                                        Text(zug.deltaPText)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(InterfacePalette.berechnet)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    if let rav = o.bewertung.rav {
                        WertZeile(label: "RAV", wert: rav)
                    }
                    if let kelly = o.bewertung.kelly {
                        WertZeile(label: "½ Kelly", wert: kelly, format: { InterfaceZahl.prozent($0) })
                    }
                    HStack {
                        Text("Kosten")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(InterfacePalette.sekundaer)
                        Spacer()
                        Text(InterfaceZahl.waehrung(o.kosten.summe, mitVorzeichen: false))
                            .font(.system(size: 13, weight: .medium))
                            .monospacedDigit()
                            .foregroundStyle(Premium.text)
                    }
                    HStack {
                        Text("Dauer")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(InterfacePalette.sekundaer)
                        Spacer()
                        Text("\(o.zeit.minMonate)–\(o.zeit.maxMonate) Mon.")
                            .font(.system(size: 13, weight: .medium))
                            .monospacedDigit()
                            .foregroundStyle(Premium.text)
                    }
                    Picker("Legalität", selection: Binding(
                        get: { o.legalitaetsStatus },
                        set: { store.setzeLegalitaet(vorgangId, optionId: o.id, $0) }
                    )) {
                        ForEach(OptionLegalitaet.allCases) { s in
                            Text(s.titel).tag(s)
                        }
                    }
                    .labelsHidden()
                    if store.vorgang(vorgangId)?.zustand.reihenfolge ?? 0 >= VorgangZustand.bewertet.reihenfolge,
                       store.vorgang(vorgangId)?.entscheidung == nil,
                       o.legalitaetsStatus != .rechtswidrig {
                        Button("Diese wählen") {
                            store.entscheide(vorgangId, optionId: o.id, wer: "Nutzer")
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(InterfacePalette.aktion)
                    }
                }
            }
            .padding(12)
        }
    }
    private func rvgBlock(_ v: Vorgang) -> some View {
        let rvg = Formelkaskade.rvg(streitwert: v.volumen)
        return InterfaceKarte(ebene: 2) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Herkunftsmarke(herkunft: .formel, groesse: 8)
                    Text("RVG-RECHNER · 100 % FORMEL")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(InterfacePalette.berechnet)
                }
                Text("Streitwert \(InterfaceZahl.waehrung(v.volumen, mitVorzeichen: false)) → Anlage 2 RVG KostBRÄG 2025 (\(InterfaceZahl.waehrung(rvg.einfach, mitVorzeichen: false)) einfache Gebühr)")
                    .font(.system(size: 11))
                    .foregroundStyle(InterfacePalette.sekundaer)
                rvgZeile("1,3 Verfahrensgebühr", rvg.verfahren)
                rvgZeile("1,2 Terminsgebühr", rvg.termin)
                rvgZeile("Nr. 7002 Auslagen (max. 20 €)", rvg.auslagen)
                rvgZeile("USt 19 %", rvg.ust)
                Divider().overlay(InterfacePalette.trennlinie)
                rvgZeile("Gesamt", rvg.gesamt, fett: true)
            }
            .padding(12)
        }
    }
    private func rvgZeile(_ label: String, _ wert: Double, fett: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: fett ? .semibold : .regular))
                .foregroundStyle(fett ? .white : InterfacePalette.sekundaer)
            Spacer()
            Text(InterfaceZahl.waehrung(wert, mitVorzeichen: false))
                .font(.system(size: 12, weight: fett ? .bold : .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(fett ? InterfacePalette.berechnet : .white)
        }
    }
    private func fristBlock(_ v: Vorgang) -> some View {
        InterfaceKarte(ebene: 2) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Herkunftsmarke(herkunft: .formel, groesse: 8)
                    Text("FRIST · 100 % FORMEL")
                        .font(.system(size: 10, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(InterfacePalette.berechnet)
                }
                ForEach(v.fristen) { f in
                    Text("\(f.art) · \(f.fristTyp.titel)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Premium.text)
                    Text("Fällig: \(fristDatum(f.datum)) · noch \(f.tageBisAblauf) Tage")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(f.erzeugtAlarm && f.kritisch ? InterfacePalette.kritisch : .white)
                    Text(f.quelle)
                        .font(.system(size: 10))
                        .foregroundStyle(InterfacePalette.sekundaer)
                    if !f.erzeugtAlarm {
                        Text("Kein Alarm — \(f.fristTyp.titel), keine echte Frist.")
                            .font(.system(size: 10))
                            .foregroundStyle(InterfacePalette.sekundaer)
                    }
                }
                if v.fristen.isEmpty {
                    Text("Keine Frist hinterlegt.").font(.system(size: 11)).foregroundStyle(InterfacePalette.sekundaer)
                }
                HStack(spacing: 8) {
                    Button("§ 4 KSchG") {
                        store.fuegeFristHinzu(v.id, Formelkaskade.klageFristKSchG(zugang: Date()))
                    }
                    Button("§§ 195, 199") {
                        store.fuegeFristHinzu(v.id, Formelkaskade.verjaehrungBGB(entstehung: Date()))
                    }
                }
                .font(.system(size: 10, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(InterfacePalette.aktion)
            }
            .padding(12)
        }
    }
    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()
    private func fristDatum(_ d: Date) -> String { StreitLinse.df.string(from: d) }
    private func zaehlerHerkunft(_ v: Vorgang) -> [Herkunft: Int] {
        var z: [Herkunft: Int] = [:]
        for o in v.optionen where !o.istVorgeschichte {
            for w in [o.chancen.pErfolg, o.chancen.best, o.chancen.worst, o.chancen.likely] {
                z[w.herkunft, default: 0] += 1
            }
        }
        return z
    }
}
