import SwiftUI
import Charts
enum LexaraKIZusatzQuelle: String {
    case berater, gesamtbewertung, personen, manuell
}
actor LexaraKIZusatzAnalyseCoordinator {
    static let shared = LexaraKIZusatzAnalyseCoordinator()
    private var laeuft = false
    func tryBegin() -> Bool {
        guard !laeuft else { return false }
        laeuft = true
        return true
    }
    func end() { laeuft = false }
}
enum LexaraKIZusatzAnalyseService {
    static let speicherKey = "ki_zusatz_analyse"
    @MainActor
    @discardableResult
    static func ergaenzeAnalyse(
        viewModel: CaseDetailViewModel,
        quelle: LexaraKIZusatzQuelle,
        kiMode: Bool = true
    ) async -> String? {
        guard kiMode else { return nil }
        guard await LexaraKIZusatzAnalyseCoordinator.shared.tryBegin() else { return nil }
        defer { Task { await LexaraKIZusatzAnalyseCoordinator.shared.end() } }
        guard var fall = viewModel.fall else { return "Kein Fall geladen." }
        let personen = viewModel.personen
        let eigene = viewModel.argumente.filter { $0.side == .eigen }
        let gegnerArgs = viewModel.argumente.filter { $0.side == .gegner }
        let personenKontext = personen.map {
            "\($0.role.rawValue): \($0.name) | \($0.organization ?? "") | Kläger:\($0.klaeger_rate ?? 0)% Vergleich:\($0.vergleich_rate ?? 0)% Dauer:\($0.dauer_monate ?? 0)Mo | Notiz:\($0.notizen ?? "")"
        }.joined(separator: "\n")
        let berater = fall.ki_berater_result?.dictValue ?? [:]
        let prompt = KIPromptKit.wrap("""
        Erstelle eine ERWEITERTE strategisch-psychologische Tiefenanalyse für einen deutschen Rechtsstreit.
        Quelle: \(quelle.rawValue). Liefere den vollen Umfang wie in einer professionellen Prozessvorbereitung.
        Fall: \(fall.fallname)
        Rechtsgebiet: \(fall.rechtsgebiet ?? "—") | Gericht: \(fall.gericht ?? "—") | Instanz: \(fall.instanz.rawValue)
        Prognose gespeichert: \(Int(fall.prognose ?? 50))%
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "—")
        Eigene Argumente: \(eigene.prefix(8).map { "\($0.title) (\($0.strength)/10)" }.joined(separator: "; "))
        Gegner-Argumente: \(gegnerArgs.prefix(8).map { "\($0.title) (\($0.strength)/10)" }.joined(separator: "; "))
        PERSONEN IM FALL:
        \(personenKontext.isEmpty ? "Noch keine Personen erfasst — schätze typische Akteure ab." : personenKontext)
        BEREITS VORHANDENE KI-MODULE (nicht wiederholen, sondern vertiefen):
        Psychologie: \(String(describing: berater["psychologisches_profil"] != nil))
        Gesamtbewertung: \(String(describing: berater["gesamtbewertung"] != nil))
        Liefere:
        1) personen_analyse — pro Person (name, rolle, organisation, statistiken, psychologisches_profil, verhaltenstaktik, prognose_einfluss, handlungsempfehlung)
        2) erfolgsaussichten — erfolgswahrscheinlichkeit, staerken[], schwaechen[], chancen_risiken_balken[] (name, wert 0-100, typ chance|risiko)
        3) wahrscheinlichkeits_verteilung — titel, punkte[{x,y}], median, konfidenzintervall[low,high]
        4) verfahrensprognose — phasen[{phase, datum_schaetzung, wahrscheinlichkeit, beschreibung}], gesamt_dauer_monate
        5) prognose_zeitverlauf — punkte[{monat, prognose_pct, szenario}]
        6) strategie_taktik_detail — psychologische_analyse (Fließtext), prognose_text, handlungsvorschlaege[], taktiken_matrix[]
        """, modul: .berater)
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "personen_analyse": ["type": "array", "items": ["type": "object"]],
                "erfolgsaussichten": ["type": "object"],
                "wahrscheinlichkeits_verteilung": ["type": "object"],
                "verfahrensprognose": ["type": "object"],
                "prognose_zeitverlauf": ["type": "object"],
                "strategie_taktik_detail": ["type": "object"]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt, schema: schema, model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "KI-Zusatzanalyse (\(quelle.rawValue))"
            )
            guard let dict = response.dictValue else { return KIResultStore.parseFehler }
            var payload = dict
            payload["quelle"] = quelle.rawValue
            payload["erstellt_am"] = ISO8601DateFormatter().string(from: Date())
            let saved = try await KIResultStore.mergeBeraterSubKey(
                caseId: viewModel.caseId, fall: &fall, key: speicherKey, value: payload
            )
            let syncFehler = await syncPersonenProfile(viewModel: viewModel, analyse: dict, fall: saved)
            await MainActor.run { viewModel.fall = saved }
            return syncFehler
        } catch {
            return error.localizedDescription
        }
    }
    @MainActor
    private static func syncPersonenProfile(viewModel: CaseDetailViewModel, analyse: [String: Any], fall: LegalCase) async -> String? {
        guard let arr = analyse["personen_analyse"] as? [[String: Any]] else { return nil }
        var speicherFehler: [String] = []
        for eintrag in arr {
            let name = (eintrag["name"] as? String ?? "").lowercased()
            guard !name.isEmpty,
                  let idx = viewModel.personen.firstIndex(where: { $0.name.lowercased().contains(name) || name.contains($0.name.lowercased()) })
            else { continue }
            var person = viewModel.personen[idx]
            if let psycho = eintrag["psychologisches_profil"] as? String, !psycho.isEmpty {
                person.ki_profil = psycho
            }
            if let stats = eintrag["statistiken"] as? [String: Any] {
                if let k = KIJson.intValue(stats["klaeger_pct"]) { person.klaeger_rate = k }
                if let v = KIJson.intValue(stats["vergleich_pct"]) { person.vergleich_rate = v }
                if let d = KIJson.intValue(stats["dauer_monate"]) { person.dauer_monate = d }
            }
            if let taktik = eintrag["verhaltenstaktik"] as? String, !taktik.isEmpty {
                if person.notizen?.isEmpty != false {
                    person.notizen = "KI-Taktik: \(taktik)"
                }
            }
            guard let pid = person.id else { continue }
            do {
                let gespeichert = try await Services.persons.update(id: pid, entity: person)
                viewModel.personen[idx] = gespeichert
            } catch {
                speicherFehler.append("\(person.name): \(error.localizedDescription)")
            }
        }
        _ = fall // Fall bereits via merge gespeichert
        guard let erster = speicherFehler.first else { return nil }
        let mehr = speicherFehler.count > 1 ? " (+\(speicherFehler.count - 1) weitere)" : ""
        return "Personen-Profile nicht vollständig gespeichert: \(erster)\(mehr)"
    }
}
struct LexaraPersonenKIZusatzPanel: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var laeuft = false
    @State private var fehler: String?
    private var zusatz: [String: Any]? {
        viewModel.fall?.ki_berater_result?.dictValue?[LexaraKIZusatzAnalyseService.speicherKey] as? [String: Any]
    }
    private var personenAnalyse: [[String: Any]] {
        zusatz?["personen_analyse"] as? [[String: Any]] ?? []
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("KI-Personenanalyse", systemImage: "person.3.sequence")
                        .font(.subheadline.bold())
                    Text("Psychologische & statistische Vertiefung pro Richter, Partei und Zeuge")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if kiMode {
                    Button { Task { await starten() } } label: {
                        if laeuft { ProgressView().scaleEffect(0.7) }
                        else { Label("KI analysieren", systemImage: "sparkles") }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .controlSize(.small)
                    .disabled(laeuft)
                }
            }
            if let fehler {
                Text(fehler).font(.caption).foregroundStyle(.red)
            }
            if personenAnalyse.isEmpty {
                LexaraIntelligenceLeerHinweis(
                    titel: "Noch keine KI-Personenanalyse",
                    text: "Starten Sie die KI-Analyse oder den KI-Berater — die erweiterten Personenprofile erscheinen hier automatisch."
                )
            } else {
                ForEach(gruppiertNachRolle(), id: \.rolle) { gruppe in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(gruppe.rolle)
                            .font(.caption.bold())
                            .foregroundStyle(rolleFarbe(gruppe.rolle))
                            .textCase(.uppercase)
                        ForEach(Array(gruppe.eintraege.enumerated()), id: \.offset) { _, p in
                            LexaraPersonenKIZusatzKarte(eintrag: p)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    private func gruppiertNachRolle() -> [(rolle: String, eintraege: [[String: Any]])] {
        let rollen = ["Richter", "Partei", "Gegner", "Anwalt", "Zeuge", "Mandant", "Sachverständiger", "Gutachter"]
        var result: [(String, [[String: Any]])] = []
        for r in rollen {
            let items = personenAnalyse.filter { ($0["rolle"] as? String ?? "").localizedCaseInsensitiveContains(r) }
            if !items.isEmpty { result.append((r, items)) }
        }
        let rest = personenAnalyse.filter { p in
            !rollen.contains { (p["rolle"] as? String ?? "").localizedCaseInsensitiveContains($0) }
        }
        if !rest.isEmpty { result.append(("Weitere", rest)) }
        return result
    }
    private func rolleFarbe(_ rolle: String) -> Color {
        switch rolle.lowercased() {
        case "richter": return .purple
        case "partei", "gegner": return .orange
        case "zeuge": return .blue
        default: return .secondary
        }
    }
    private func starten() async {
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        if let err = await LexaraKIZusatzAnalyseService.ergaenzeAnalyse(viewModel: viewModel, quelle: .personen, kiMode: kiMode) {
            fehler = err
        } else if viewModel.fall?.ki_berater_result?.dictValue?[LexaraKIZusatzAnalyseService.speicherKey] == nil {
            fehler = "Zusatzanalyse konnte nicht erstellt werden."
        }
    }
}
struct LexaraPersonenKIZusatzKarte: View {
    let eintrag: [String: Any]
    var body: some View {
        FenlynineOSCard(elevated: false) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(eintrag["name"] as? String ?? "—")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    if let org = eintrag["organisation"] as? String, !org.isEmpty {
                        Text(org).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if let stats = eintrag["statistiken"] as? [String: Any] {
                    HStack(spacing: 16) {
                        if let k = KIJson.intValue(stats["klaeger_pct"]) {
                            LexaraStatMini(label: "Kläger", wert: "\(k)%", farbe: .blue)
                        }
                        if let v = KIJson.intValue(stats["vergleich_pct"]) {
                            LexaraStatMini(label: "Vergleich", wert: "\(v)%", farbe: .green)
                        }
                        if let d = KIJson.intValue(stats["dauer_monate"]) {
                            LexaraStatMini(label: "Ø Dauer", wert: "\(d) Mo.", farbe: .secondary)
                        }
                    }
                }
                if let psycho = eintrag["psychologisches_profil"] as? String, !psycho.isEmpty {
                    Label(psycho, systemImage: "brain.head.profile")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let taktik = eintrag["verhaltenstaktik"] as? String, !taktik.isEmpty {
                    Text(taktik).font(.caption2).italic()
                }
                if let emp = eintrag["handlungsempfehlung"] as? String, !emp.isEmpty {
                    Text("→ \(emp)").font(.caption2).foregroundStyle(.blue)
                }
                if let einfluss = eintrag["prognose_einfluss"] as? String, !einfluss.isEmpty {
                    Text("Prognose-Einfluss: \(einfluss)")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
struct LexaraStatMini: View {
    let label: String
    let wert: String
    var farbe: Color = .secondary
    var body: some View {
        VStack(spacing: 2) {
            Text(wert).font(.caption.bold()).foregroundStyle(farbe)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
struct LexaraErfolgsaussichtenZusatzPanel: View {
    let viewModel: CaseDetailViewModel
    private var zusatz: [String: Any]? {
        viewModel.fall?.ki_berater_result?.dictValue?[LexaraKIZusatzAnalyseService.speicherKey] as? [String: Any]
    }
    var body: some View {
        let ea = zusatz?["erfolgsaussichten"] as? [String: Any]
        if ea != nil || zusatz?["wahrscheinlichkeits_verteilung"] != nil || zusatz?["prognose_zeitverlauf"] != nil {
            VStack(spacing: 14) {
                if let ea {
                    erfolgsaussichtenKarte(ea)
                }
                if let verteilung = zusatz?["wahrscheinlichkeits_verteilung"] as? [String: Any] {
                    verteilungsKarte(verteilung)
                }
                if let zeit = zusatz?["prognose_zeitverlauf"] as? [String: Any] {
                    zeitverlaufKarte(zeit)
                }
                if let verf = zusatz?["verfahrensprognose"] as? [String: Any] {
                    verfahrensTimelineKarte(verf)
                }
            }
        }
    }
    @ViewBuilder
    private func erfolgsaussichtenKarte(_ ea: [String: Any]) -> some View {
        LexaraIntelligenceErgaenzungKarte(titel: "Erfolgsaussichten — Wirkung einschätzen", symbol: "gauge.with.dots.needle.67percent") {
            let pct = KIJson.intValue(ea["erfolgswahrscheinlichkeit"])
                ?? KIJson.intValue((viewModel.fall?.ki_berater_result?.dictValue?["gesamtbewertung"] as? [String: Any])?["erfolgswahrscheinlichkeit"])
                ?? Int(viewModel.fall?.prognose ?? 50)
            HStack(alignment: .top, spacing: 20) {
                FenlynineOSPrognoseRing(wert: pct, groesse: 88)
                VStack(alignment: .leading, spacing: 10) {
                    if let staerken = ea["staerken"] as? [[String: Any]], !staerken.isEmpty {
                        Text("Stärken").font(.caption.bold()).foregroundStyle(.green)
                        ForEach(Array(staerken.enumerated()), id: \.offset) { _, s in
                            LexaraStaerkeSchwaecheZeile(
                                titel: s["titel"] as? String ?? "",
                                text: s["beschreibung"] as? String,
                                gewicht: KIJson.intValue(s["gewicht"]),
                                positiv: true
                            )
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    if let schw = ea["schwaechen"] as? [[String: Any]], !schw.isEmpty {
                        Text("Schwächen").font(.caption.bold()).foregroundStyle(.red)
                        ForEach(Array(schw.enumerated()), id: \.offset) { _, s in
                            LexaraStaerkeSchwaecheZeile(
                                titel: s["titel"] as? String ?? "",
                                text: s["beschreibung"] as? String,
                                gewicht: KIJson.intValue(s["gewicht"]),
                                positiv: false
                            )
                        }
                    }
                }
            }
            if let balken = ea["chancen_risiken_balken"] as? [[String: Any]], !balken.isEmpty {
                Divider().padding(.vertical, 4)
                Chart(balken.indices, id: \.self) { i in
                    let b = balken[i]
                    let typ = (b["typ"] as? String ?? "").lowercased()
                    BarMark(
                        x: .value("Faktor", b["name"] as? String ?? "?"),
                        y: .value("%", KIJson.intValue(b["wert"]) ?? 0)
                    )
                    .foregroundStyle(typ == "risiko" ? Color.red : Color.green)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 140)
            }
        }
    }
    @ViewBuilder
    private func verteilungsKarte(_ v: [String: Any]) -> some View {
        LexaraIntelligenceErgaenzungKarte(titel: v["titel"] as? String ?? "Wahrscheinlichkeitsverteilung", symbol: "chart.xyaxis.line") {
            if let punkte = v["punkte"] as? [[String: Any]], !punkte.isEmpty {
                Chart(punkte.indices, id: \.self) { i in
                    let p = punkte[i]
                    let x = KIJson.numberValue(p["x"]) ?? Double(i)
                    let y = KIJson.numberValue(p["y"]) ?? 0
                    AreaMark(x: .value("X", x), y: .value("Y", y))
                        .foregroundStyle(Color.blue.opacity(0.25))
                    LineMark(x: .value("X", x), y: .value("Y", y))
                        .foregroundStyle(.blue)
                }
                .frame(height: 120)
            }
            HStack(spacing: 16) {
                if let med = KIJson.intValue(v["median"]) {
                    Text("Median: \(med.formatted()) €").font(.caption2)
                }
                if let ki = v["konfidenzintervall"] as? [Any], ki.count >= 2 {
                    Text("KI: \(KIJson.intValue(ki[0]) ?? 0)–\(KIJson.intValue(ki[1]) ?? 0) €")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
    @ViewBuilder
    private func zeitverlaufKarte(_ z: [String: Any]) -> some View {
        LexaraIntelligenceErgaenzungKarte(titel: "Prognose-Zeitverlauf", symbol: "chart.line.uptrend.xyaxis") {
            if let punkte = z["punkte"] as? [[String: Any]], !punkte.isEmpty {
                Chart(punkte.indices, id: \.self) { i in
                    let p = punkte[i]
                    LineMark(
                        x: .value("Monat", KIJson.intValue(p["monat"]) ?? i),
                        y: .value("%", KIJson.intValue(p["prognose_pct"]) ?? 0)
                    )
                    .foregroundStyle(by: .value("Szenario", p["szenario"] as? String ?? "aktuell"))
                }
                .chartYScale(domain: 0...100)
                .frame(height: 130)
            }
        }
    }
    @ViewBuilder
    private func verfahrensTimelineKarte(_ v: [String: Any]) -> some View {
        LexaraIntelligenceErgaenzungKarte(titel: "Verfahrensprognose & Timeline", symbol: "timeline.selection") {
            if let phasen = v["phasen"] as? [[String: Any]] {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(Array(phasen.enumerated()), id: \.offset) { idx, ph in
                            VStack(spacing: 4) {
                                Text(ph["datum_schaetzung"] as? String ?? "")
                                    .font(.system(size: 9)).foregroundStyle(.secondary)
                                Circle()
                                    .fill(Color.blue.opacity(0.8))
                                    .frame(width: 10, height: 10)
                                Text(ph["phase"] as? String ?? "")
                                    .font(.system(size: 9, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 72)
                                if let w = KIJson.intValue(ph["wahrscheinlichkeit"]) {
                                    Text("\(w)%").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                            .frame(width: 80)
                            if idx < phasen.count - 1 {
                                Rectangle().fill(Color.gray.opacity(0.25)).frame(width: 12, height: 1).padding(.top, 18)
                            }
                        }
                    }
                }
                ForEach(Array(phasen.enumerated()), id: \.offset) { _, ph in
                    if let b = ph["beschreibung"] as? String, !b.isEmpty {
                        Text("• \(ph["phase"] as? String ?? ""): \(b)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            if let d = KIJson.intValue(v["gesamt_dauer_monate"]) {
                Text("Geschätzte Gesamtdauer: \(d) Monate").font(.caption).padding(.top, 4)
            }
        }
    }
}
struct LexaraStaerkeSchwaecheZeile: View {
    let titel: String
    let text: String?
    let gewicht: Int?
    var positiv: Bool = true
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: positiv ? "plus.circle.fill" : "minus.circle.fill")
                .font(.caption2)
                .foregroundStyle(positiv ? .green : .red)
            VStack(alignment: .leading, spacing: 1) {
                Text(titel).font(.caption2.bold())
                if let text, !text.isEmpty {
                    Text(text).font(.caption2).foregroundStyle(.secondary)
                }
            }
            if let g = gewicht {
                Text("\(g)/10").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
    }
}
struct LexaraStrategieTaktikZusatzPanel: View {
    let viewModel: CaseDetailViewModel
    private var detail: [String: Any]? {
        let root = viewModel.fall?.ki_berater_result?.dictValue?[LexaraKIZusatzAnalyseService.speicherKey] as? [String: Any]
        return root?["strategie_taktik_detail"] as? [String: Any]
    }
    var body: some View {
        if let detail {
            VStack(spacing: 14) {
                if let psycho = detail["psychologische_analyse"] as? String, !psycho.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Psychologische Gesamtanalyse", symbol: "brain") {
                        Text(psycho).font(.caption).textSelection(.enabled)
                    }
                }
                if let prog = detail["prognose_text"] as? String, !prog.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Prognose & Wahrscheinlichkeiten", symbol: "percent") {
                        Text(prog).font(.caption).textSelection(.enabled)
                    }
                }
                if let handlungen = detail["handlungsvorschlaege"] as? [[String: Any]], !handlungen.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Handlungsvorschläge & Verfahrenstaktik", symbol: "list.bullet.clipboard") {
                        ForEach(Array(handlungen.enumerated()), id: \.offset) { _, h in
                            LexaraHandlungsKarte(
                                titel: h["titel"] as? String ?? "—",
                                typ: KIJson.string(in: h, keys: "prioritaet", "priorität"),
                                beschreibung: h["beschreibung"] as? String,
                                timing: nil,
                                erfolg: KIJson.intValue(h["erfolgsaussicht_pct"]),
                                meta: nil
                            )
                        }
                    }
                }
                if let matrix = detail["taktiken_matrix"] as? [[String: Any]], !matrix.isEmpty {
                    LexaraIntelligenceErgaenzungKarte(titel: "Taktiken-Matrix — Wirkung vs. Risiko", symbol: "square.grid.3x3") {
                        Chart(matrix.indices, id: \.self) { i in
                            let m = matrix[i]
                            BarMark(
                                x: .value("Wirkung", KIJson.intValue(m["wirkung"]) ?? 0),
                                y: .value("Taktik", m["taktik"] as? String ?? "—")
                            )
                            .foregroundStyle(.blue.opacity(0.8))
                        }
                        .chartXScale(domain: 0...10)
                        .frame(height: CGFloat(matrix.count * 32 + 16))
                    }
                }
            }
        }
    }
}
struct LexaraKIZusatzErgebnisBanner: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var laeuft = false
    @State private var fehler: String?
    private var hatZusatz: Bool {
        viewModel.fall?.ki_berater_result?.dictValue?[LexaraKIZusatzAnalyseService.speicherKey] != nil
    }
    var body: some View {
        FenlynineOSCard(elevated: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("KI-Tiefenanalyse (erweiterter Umfang)", systemImage: "sparkles.rectangle.stack")
                        .font(.subheadline.bold())
                    Spacer()
                    if kiMode && !hatZusatz {
                        Button { Task { await laden() } } label: {
                            if laeuft { ProgressView().scaleEffect(0.7) }
                            else { Text("Erzeugen") }
                        }
                        .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                        .controlSize(.small)
                        .disabled(laeuft)
                    } else if hatZusatz {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    }
                }
                if let fehler {
                    Text(fehler).font(.caption).foregroundStyle(.red)
                }
                if hatZusatz {
                    LexaraErfolgsaussichtenZusatzPanel(viewModel: viewModel)
                    LexaraStrategieTaktikZusatzPanel(viewModel: viewModel)
                } else if !laeuft {
                    Text("Nach KI-Berater oder Gesamtbewertung werden hier zusätzlich Stärken/Schwächen, Wahrscheinlichkeitsverteilungen, Verfahrens-Timeline und ausführliche Strategie-/Psycho-Texte angezeigt.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
    private func laden() async {
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        if let err = await LexaraKIZusatzAnalyseService.ergaenzeAnalyse(viewModel: viewModel, quelle: .manuell, kiMode: kiMode) {
            fehler = err
        }
    }
}
