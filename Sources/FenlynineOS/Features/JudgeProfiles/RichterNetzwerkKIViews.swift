import SwiftUI
struct AkteureBeziehungenView: View {
    @Binding var profil: JudgeProfile
    let allProfiles: [JudgeProfile]
    let cases: [LegalCase]
    let onUpdate: (JudgeProfile) -> Void
    @State private var laeuft = false
    @State private var fehler: String?
    @State private var result: [String: Any]?
    @State private var expanded: Int?
    private var relevantActors: [JudgeProfile] {
        var map: [String: JudgeProfile] = [:]
        let eigeneFallIds = Set(
            cases
                .filter { ($0.richter_name ?? "").caseInsensitiveCompare(profil.name) == .orderedSame }
                .compactMap(\.id)
        )
        let expTexts = (profil.erfahrungen ?? [])
            .map { ($0.text ?? "") + " " + ($0.fall_kontext ?? "") }
            .joined(separator: " ")
            .lowercased()
        for p in allProfiles where p.id != profil.id {
            let andereFallIds = Set(
                cases
                    .filter {
                        let rn = ($0.richter_name ?? "").lowercased()
                        let mn = ($0.mandant_name ?? "").lowercased()
                        let nt = ($0.notes ?? "").lowercased()
                        let fn = $0.fallname.lowercased()
                        let n = p.name.lowercased()
                        return rn.contains(n) || mn.contains(n) || nt.contains(n) || fn.contains(n)
                    }
                    .compactMap(\.id)
            )
            let shared = !eigeneFallIds.isDisjoint(with: andereFallIds)
            let inErfahrung = !p.name.isEmpty && expTexts.contains(p.name.lowercased())
            let gleichesGericht = (profil.gericht != nil && profil.gericht == p.gericht)
            if shared || inErfahrung || gleichesGericht {
                if let id = p.id { map[id] = p }
            }
        }
        return Array(map.values)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Beziehungsnetz & Taktische Dynamiken", systemImage: "person.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("KI erkennt Verbindungen zwischen Akteuren und Verhaltensmustern")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await analyse() }
                } label: {
                    if laeuft {
                        ProgressView().scaleEffect(0.7)
                        Text("Analysiere…")
                    } else {
                        Label(result == nil ? "Beziehungen analysieren" : "Neu analysieren", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(laeuft)
            }
            if let fehler {
                Text(fehler).font(.caption).foregroundStyle(.red)
            }
            if !relevantActors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ERKANNTE DIREKTE VERBINDUNGEN")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(relevantActors, id: \.id) { a in
                            Text("\(kategorieIcon(a.kategorie)) \(a.name)")
                                .font(.caption2)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.indigo.opacity(0.08), in: Capsule())
                        }
                    }
                }
            }
            if result == nil && !laeuft {
                Text(allProfiles.count <= 1
                     ? "Legen Sie weitere Akteure an, damit die KI Beziehungen analysieren kann."
                     : "Klicken Sie auf Beziehungen analysieren, um Dynamiken zu erkennen.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 24)
            }
            if let beziehungen = result?["beziehungen"] as? [[String: Any]] {
                ForEach(Array(beziehungen.enumerated()), id: \.offset) { i, b in
                    beziehungKarte(b, index: i)
                }
            }
            if let netz = result?["netzwerk_einschaetzung"] as? String, !netz.isEmpty {
                infoBlock(titel: "Netzwerk-Einschätzung", text: netz, farbe: .indigo)
            }
            if let krit = result?["kritische_konstellationen"] as? [String], !krit.isEmpty {
                listBlock(titel: "Kritische Konstellationen", items: krit, farbe: .red)
            }
            if let emp = result?["strategische_empfehlungen"] as? [String], !emp.isEmpty {
                listBlock(titel: "Strategische Empfehlungen", items: emp, farbe: .green)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
        .onAppear {
            result = profil.beziehungsanalyse?.dictValue
        }
    }
    @ViewBuilder
    private func beziehungKarte(_ b: [String: Any], index: Int) -> some View {
        let dynamik = b["dynamik"] as? String ?? "neutral"
        let farbe = dynamikFarbe(dynamik)
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { expanded = expanded == index ? nil : index }
            } label: {
                HStack {
                    Text(kategorieIcon(b["akteur_kategorie"] as? String))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b["akteur_name"] as? String ?? "—").font(.caption.bold())
                        Text(b["verbindungstyp"] as? String ?? "").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(dynamik).font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(farbe.opacity(0.15), in: Capsule())
                    Image(systemName: expanded == index ? "chevron.down" : "chevron.right")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            if expanded == index {
                if let desc = b["beschreibung"] as? String { Text(desc).font(.caption) }
                if let rel = b["taktische_relevanz"] as? String {
                    Text("Taktik: \(rel)").font(.caption2).foregroundStyle(.secondary)
                }
                if let faelle = b["gemeinsame_faelle"] as? [String], !faelle.isEmpty {
                    FlowLayout(spacing: 4) {
                        ForEach(faelle, id: \.self) { f in
                            Text(f).font(.system(size: 9)).padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.08), in: Capsule())
                        }
                    }
                }
                if let emp = b["empfehlung"] as? String, !emp.isEmpty {
                    Text("→ \(emp)").font(.caption2).foregroundStyle(.green)
                }
            }
        }
        .padding(10)
        .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.2)))
    }
    private func analyse() async {
        laeuft = true
        fehler = nil
        defer { laeuft = false }
        let allActorsInfo = allProfiles
            .filter { $0.id != profil.id }
            .map { p in
                let exp = (p.erfahrungen ?? []).count
                return "- \(p.name) (\(p.kategorie ?? "Richter"), \(p.gericht ?? ""))\(exp > 0 ? " | \(exp) Erfahrungen" : "")"
            }
            .joined(separator: "\n")
        let sharedCasesInfo = cases
            .filter { $0.richter_name == profil.name }
            .map { c in
                "Fall: \"\(c.fallname)\" (\(c.rechtsgebiet ?? "-")) - Prognose: \(c.prognose.map { "\(Int($0))%" } ?? "?") - Status: \(c.status.rawValue)"
            }
            .joined(separator: "\n")
        let expText = (profil.erfahrungen ?? [])
            .map { e in
                "[\(e.datum ?? "")] \(e.autor ?? "Anonym"): \(e.text ?? "") (Vergleichsbereitschaft: \(e.vergleichsbereitschaft ?? 0)/10)"
            }
            .joined(separator: "\n")
        let prompt = """
        Du bist ein juristischer Strategie- und Netzwerkanalyst. Analysiere die Beziehungsdynamiken zwischen dem folgenden Akteur und anderen bekannten Prozessbeteiligten.
        HAUPTAKTEUR:
        Name: \(profil.name)
        Kategorie: \(profil.kategorie ?? "Richter")
        Institution: \(profil.gericht ?? "")
        Stil: \(profil.stil?.rawValue ?? "Neutral")
        Klägerquote: \(profil.klaeger_rate.map { "\(Int($0))%" } ?? "0%")
        Vergleichsrate: \(profil.vergleich_rate.map { "\(Int($0))%" } ?? "0%")
        Bekannt für: \(profil.bekannt_fuer ?? "-")
        KANZLEI-ERFAHRUNGEN:
        \(expText.isEmpty ? "Keine Erfahrungen dokumentiert." : expText)
        VERKNÜPFTE FÄLLE:
        \(sharedCasesInfo.isEmpty ? "Keine direkt verknüpften Fälle." : sharedCasesInfo)
        ANDERE AKTEURE IM SYSTEM:
        \(allActorsInfo.isEmpty ? "Noch keine anderen Akteure erfasst." : allActorsInfo)
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "beziehungen": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "akteur_name": ["type": "string"],
                            "akteur_kategorie": ["type": "string"],
                            "dynamik": ["type": "string"],
                            "verbindungstyp": ["type": "string"],
                            "beschreibung": ["type": "string"],
                            "taktische_relevanz": ["type": "string"],
                            "gemeinsame_faelle": ["type": "array", "items": ["type": "string"]],
                            "empfehlung": ["type": "string"]
                        ]
                    ]
                ],
                "netzwerk_einschaetzung": ["type": "string"],
                "kritische_konstellationen": ["type": "array", "items": ["type": "string"]],
                "strategische_empfehlungen": ["type": "array", "items": ["type": "string"]]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt, schema: schema, model: "claude_sonnet_4_6"
            )
            var dict = response.dictValue ?? [:]
            dict["berechnet"] = ISO8601DateFormatter().string(from: Date())
            await MainActor.run { result = dict }
            profil.beziehungsanalyse = AnyCodable(dict)
            if let id = profil.id {
                let updated = try await Services.judgeProfiles.update(id: id, entity: profil)
                await MainActor.run { onUpdate(updated) }
            }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func kategorieIcon(_ kat: String?) -> String {
        switch kat {
        case "Richter": return "⚖️"
        case "Anwalt": return "👔"
        case "Kanzlei": return "🏛️"
        case "Zeuge": return "👁️"
        case "Sachverstaendiger": return "🔬"
        case "Partei": return "🏢"
        default: return "📋"
        }
    }
    private func dynamikFarbe(_ d: String) -> Color {
        switch d {
        case "positiv": return .green
        case "angespannt": return .orange
        case "konfliktiv": return .red
        default: return .gray
        }
    }
    private func infoBlock(titel: String, text: String, farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.caption.bold()).foregroundStyle(farbe)
            Text(text).font(.caption)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
    private func listBlock(titel: String, items: [String], farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titel).font(.caption.bold()).foregroundStyle(farbe)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(farbe)
                    Text(item).font(.caption)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(farbe.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}
struct RichterNetzwerkGlobalView: View {
    let profiles: [JudgeProfile]
    let cases: [LegalCase]
    @State private var aiResult: [String: Any]?
    @State private var laeuft = false
    @State private var fehler: String?
    @State private var selectedId: String?
    @State private var zeigeKI = false
    private var edges: [(String, String, Int, String)] {
        var edgeMap: [String: (Int, [String])] = [:]
        func addEdge(_ a: String, _ b: String, weight: Int = 1, label: String = "") {
            let key = [a, b].sorted().joined(separator: "|")
            var entry = edgeMap[key] ?? (0, [])
            entry.0 += weight
            if !label.isEmpty { entry.1.append(label) }
            edgeMap[key] = entry
        }
        for c in cases {
            guard let richter = profiles.first(where: { $0.name == c.richter_name }),
                  let rid = richter.id else { continue }
            for p in profiles where p.id != rid {
                let expTexts = (p.erfahrungen ?? [])
                    .map { ($0.text ?? "") + " " + ($0.fall_kontext ?? "") }
                    .joined(separator: " ")
                    .lowercased()
                if expTexts.contains(richter.name.lowercased()), let pid = p.id {
                    addEdge(rid, pid, weight: 2, label: c.fallname)
                }
            }
        }
        for i in profiles.indices {
            for j in (i + 1)..<profiles.count {
                let a = profiles[i], b = profiles[j]
                if let ga = a.gericht, let gb = b.gericht, ga == gb,
                   let ida = a.id, let idb = b.id {
                    addEdge(ida, idb, weight: 1, label: ga)
                }
            }
        }
        return edgeMap.compactMap { key, val in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            return (parts[0], parts[1], val.0, val.1.first ?? "")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Taktisches Akteursnetzwerk").font(.system(size: 14, weight: .bold))
                    Text("\(profiles.count) Akteure · \(edges.count) Verbindungen")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await kiAnalyse() }
                } label: {
                    if laeuft {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Label("KI-Netzwerkanalyse", systemImage: "brain.fill")
                    }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(laeuft || profiles.isEmpty)
            }
            if let fehler { Text(fehler).font(.caption).foregroundStyle(.red) }
            GlobalNetzwerkCanvasView(
                profiles: profiles,
                edges: edges.map { ($0.0, $0.1, $0.2) },
                selectedId: $selectedId
            )
            .frame(height: 420)
            .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1)))
            if zeigeKI, let ai = aiResult {
                kiErgebnisView(ai)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.12)))
    }
    @ViewBuilder
    private func kiErgebnisView(_ ai: [String: Any]) -> some View {
        if let fazit = ai["netzwerk_fazit"] as? String {
            infoBlock("Netzwerk-Fazit", fazit, .blue)
        }
        if let spieler = ai["schluesselspieler"] as? [String] {
            listBlock("Schlüsselspieler", spieler, .purple)
        }
        if let risiko = ai["risikokonstellationen"] as? [String] {
            listBlock("Risikokonstellationen", risiko, .red)
        }
        if let emp = ai["taktische_empfehlungen"] as? [String] {
            listBlock("Taktische Empfehlungen", emp, .green)
        }
        if let verbindungen = ai["verbindungen"] as? [[String: Any]] {
            ForEach(Array(verbindungen.prefix(8).enumerated()), id: \.offset) { _, v in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(v["richter"] as? String ?? "?") ↔ \(v["akteur"] as? String ?? "?")")
                        .font(.caption.bold())
                    if let m = v["muster"] as? String { Text(m).font(.caption2) }
                    if let e = v["empfehlung"] as? String {
                        Text("→ \(e)").font(.caption2).foregroundStyle(.green)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    private func kiAnalyse() async {
        laeuft = true
        fehler = nil
        zeigeKI = true
        defer { laeuft = false }
        let profileContext = profiles.map { p in
            "\(p.kategorie ?? "Richter"): \(p.name) | Klägerquote: \(p.klaeger_rate.map { "\(Int($0))%" } ?? "?") | Vergleichsrate: \(p.vergleich_rate.map { "\(Int($0))%" } ?? "?") | Erfahrungen: \((p.erfahrungen ?? []).count)"
        }.joined(separator: "\n")
        let caseContext = cases.map { c in
            "Fall: \"\(c.fallname)\" | Richter: \(c.richter_name ?? "?") | Rechtsgebiet: \(c.rechtsgebiet ?? "?") | Prognose: \(c.prognose.map { "\(Int($0))%" } ?? "?")"
        }.joined(separator: "\n")
        let prompt = """
        Du bist ein juristischer Netzwerkanalyst. Analysiere Verbindungen zwischen Richtern und Anwälten/Kanzleien.
        PROFILE (\(profiles.count) Akteure):
        \(profileContext)
        FÄLLE (\(cases.count)):
        \(caseContext.isEmpty ? "Keine Fälle verknüpft." : caseContext)
        Identifiziere Erfolgs-/Misserfolgsmuster, Schlüsselspieler, Risikokonstellationen und taktische Empfehlungen.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "verbindungen": ["type": "array", "items": ["type": "object"]],
                "schluesselspieler": ["type": "array", "items": ["type": "string"]],
                "risikokonstellationen": ["type": "array", "items": ["type": "string"]],
                "taktische_empfehlungen": ["type": "array", "items": ["type": "string"]],
                "netzwerk_fazit": ["type": "string"]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt, schema: schema, model: "claude_sonnet_4_6"
            )
            await MainActor.run { aiResult = response.dictValue }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
    private func infoBlock(_ titel: String, _ text: String, _ farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.caption.bold()).foregroundStyle(farbe)
            Text(text).font(.caption)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
    private func listBlock(_ titel: String, _ items: [String], _ farbe: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.caption.bold()).foregroundStyle(farbe)
            ForEach(items, id: \.self) { item in
                Text("• \(item)").font(.caption)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(farbe.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}
struct GlobalNetzwerkCanvasView: View {
    let profiles: [JudgeProfile]
    let edges: [(String, String, Int)]
    @Binding var selectedId: String?
    var body: some View {
        Canvas { context, size in
            let positions = knotenPositionen(in: size)
            for (von, zu, _) in edges {
                guard let p1 = positions[von], let p2 = positions[zu] else { continue }
                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                context.stroke(path, with: .color(.gray.opacity(0.25)), lineWidth: 1.5)
            }
            for profil in profiles {
                guard let id = profil.id, let pos = positions[id] else { continue }
                let sel = selectedId == id
                let radius: CGFloat = sel ? 28 : 22
                let farbe = kategorieFarbe(profil.kategorie)
                let circle = Path(ellipseIn: CGRect(x: pos.x - radius, y: pos.y - radius, width: radius * 2, height: radius * 2))
                context.fill(circle, with: .color(farbe.opacity(sel ? 1 : 0.75)))
                let label = profil.name.components(separatedBy: " ").last ?? profil.name
                context.draw(
                    Text(label).font(.system(size: sel ? 10 : 8, weight: .semibold)).foregroundStyle(.white),
                    at: pos
                )
            }
        }
        .onTapGesture { location in
            let positions = knotenPositionen(in: CGSize(width: 700, height: 420))
            selectedId = positions.min(by: {
                hypot($0.value.x - location.x, $0.value.y - location.y) <
                hypot($1.value.x - location.x, $1.value.y - location.y)
            })?.key
        }
    }
    private func knotenPositionen(in size: CGSize) -> [String: CGPoint] {
        var result: [String: CGPoint] = [:]
        let n = max(profiles.count, 1)
        let cx = size.width / 2, cy = size.height / 2
        let r = min(size.width, size.height) * 0.35
        for (i, p) in profiles.enumerated() {
            guard let id = p.id else { continue }
            let angle = (Double(i) / Double(n)) * 2 * .pi
            result[id] = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
        }
        return result
    }
    private func kategorieFarbe(_ kat: String?) -> Color {
        switch kat {
        case "Anwalt": return .blue
        case "Kanzlei": return .purple
        case "Partei": return .red
        case "Zeuge": return .orange
        default: return Color(red: 0.1, green: 0.21, blue: 0.38)
        }
    }
}
