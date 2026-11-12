import SwiftUI
struct ArgumentationskettenView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var subView = 0
    @State private var kiLaeuft = false
    @State private var kiErgebnis: KILueckenErgebnis? = nil
    @State private var fehler: String? = nil
    struct KILueckenErgebnis {
        var gesamtbewertung: String
        var staerkeEigeneKette: Int
        var luecken: [(typ: String, beschreibung: String, empfehlung: String, schwere: String)]
        var empfehlungen: [String]
    }
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Argumentationsketten-Visualisierung")
                        .font(.title3.bold())
                    Text("\(viewModel.argumente.count) Argumente · \(viewModel.beweise.count) Beweise")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $subView) {
                    Text("Argumentkette").tag(0)
                    Text("Lücken").tag(1)
                    Text("KI-Analyse").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
            }
            if let err = fehler {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.red)
            }
            switch subView {
            case 0:
                argumentketteView
            case 1:
                lueckenView
            default:
                kiAnalyseView
            }
        }
    }
    @ViewBuilder
    private var argumentketteView: some View {
        let eigen = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        if eigen.isEmpty && gegner.isEmpty {
            InfoHinweis(titel: "Keine Argumente", nachricht: "Erfassen Sie zuerst Argumente im Tab Substanz.", symbol: "link.circle")
        } else {
            if !eigen.isEmpty {
                Text("Eigene Argumente").font(.caption.bold())
                ForEach(eigen) { a in
                    argumentZeile(a, farbe: .blue)
                }
            }
            if !gegner.isEmpty {
                Text("Gegner-Argumente").font(.caption.bold()).padding(.top, 8)
                ForEach(gegner) { a in
                    argumentZeile(a, farbe: .red)
                }
            }
        }
    }
    private func argumentZeile(_ a: Argument, farbe: Color) -> some View {
        HStack {
            Circle().fill(farbe).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(a.title).font(.caption)
                Text("Stärke \(Int(a.effectiveStrength))/10").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(farbe.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    @ViewBuilder
    private var lueckenView: some View {
        let ohneBeweis = viewModel.argumente.filter { arg in
            !viewModel.beweise.contains { ($0.linked_argument_ids ?? []).contains(arg.id ?? "") }
        }
        if ohneBeweis.isEmpty {
            Label("Keine offensichtlichen Beweislücken", systemImage: "checkmark.circle.fill")
                .font(.caption).foregroundStyle(.green)
        } else {
            Text("Argumente ohne Beweis (\(ohneBeweis.count))").font(.caption.bold())
            ForEach(ohneBeweis) { a in
                Text("• \(a.title)").font(.caption)
            }
        }
    }
    @ViewBuilder
    private var kiAnalyseView: some View {
        HStack {
            Spacer()
            if kiMode {
                Button {
                    Task { await kiLueckenAnalyse() }
                } label: {
                    if kiLaeuft { ProgressView().scaleEffect(0.7) }
                    else { Label("Analyse starten", systemImage: "wand.and.stars") }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .disabled(kiLaeuft || viewModel.argumente.count < 2)
            }
        }
        if let ergebnis = kiErgebnis {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(ergebnis.staerkeEigeneKette)/10").font(.title2.bold()).foregroundStyle(.blue)
                    Text("Stärke eigene Kette").font(.caption).foregroundStyle(.secondary)
                }
                if !ergebnis.gesamtbewertung.isEmpty {
                    Text(ergebnis.gesamtbewertung).font(.caption).lineSpacing(3)
                }
                if !ergebnis.luecken.isEmpty {
                    Text("Erkannte Lücken").font(.caption.bold())
                    ForEach(Array(ergebnis.luecken.enumerated()), id: \.offset) { _, l in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("[\(l.schwere)] \(l.typ)").font(.caption.bold())
                            Text(l.beschreibung).font(.caption2)
                            if !l.empfehlung.isEmpty {
                                Text("→ \(l.empfehlung)").font(.caption2).foregroundStyle(.blue)
                            }
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !ergebnis.empfehlungen.isEmpty {
                    Text("Empfehlungen").font(.caption.bold())
                    ForEach(ergebnis.empfehlungen, id: \.self) { e in
                        Text("• \(e)").font(.caption2)
                    }
                }
            }
        } else if !kiLaeuft {
            InfoHinweis(
                titel: "KI-Lückenanalyse",
                nachricht: "Die KI analysiert logische Lücken, ungestützte Argumente und Widersprüche in der Argumentationskette.",
                symbol: "wand.and.stars"
            )
        }
    }
    private func kiLueckenAnalyse() async {
        guard viewModel.argumente.count >= 2 else { return }
        kiLaeuft = true
        fehler = nil
        defer { kiLaeuft = false }
        let argsText = viewModel.argumente.map {
            "- [\($0.side.rawValue)] \"\($0.title)\" | Stärke: \(Int($0.effectiveStrength))/10"
        }.joined(separator: "\n")
        let evText = viewModel.beweise.map {
            "- \"\($0.title)\" → Args: \(($0.linked_argument_ids ?? []).joined(separator: ","))"
        }.joined(separator: "\n")
        let prompt = """
        Du bist ein Experte für juristische Beweisführung und Argumentationslogik. Analysiere die Argumentationskette auf logische Lücken.
        Argumente (\(viewModel.argumente.count)):
        \(argsText)
        Beweise (\(viewModel.beweise.count)):
        \(evText)
        Identifiziere: logische Lücken, ungestützte Argumente, Widersprüche, starke Gegnerargumente ohne Gegenstrategie, Empfehlungen.
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "gesamtbewertung": ["type": "string"],
                    "staerke_eigene_kette": ["type": "number"],
                    "luecken": ["type": "array", "items": ["type": "object", "properties": [
                        "typ": ["type": "string"], "beschreibung": ["type": "string"],
                        "empfehlung": ["type": "string"], "schwere": ["type": "string"]
                    ]]],
                    "empfehlungen": ["type": "array", "items": ["type": "string"]]
                ]] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Argumentationsketten — Lückenanalyse"
            )
            guard let d = result.dictValue else {
                await MainActor.run { fehler = "KI-Analyse lieferte kein Ergebnis." }
                return
            }
            let luecken = (d["luecken"] as? [[String: Any]] ?? []).map {
                (typ: $0["typ"] as? String ?? "",
                 beschreibung: $0["beschreibung"] as? String ?? "",
                 empfehlung: $0["empfehlung"] as? String ?? "",
                 schwere: $0["schwere"] as? String ?? "mittel")
            }
            let parsed = KILueckenErgebnis(
                gesamtbewertung: d["gesamtbewertung"] as? String ?? "",
                staerkeEigeneKette: Int(d["staerke_eigene_kette"] as? Double ?? 5),
                luecken: luecken,
                empfehlungen: d["empfehlungen"] as? [String] ?? []
            )
            await MainActor.run { kiErgebnis = parsed }
        } catch {
            await MainActor.run { fehler = "KI-Analyse fehlgeschlagen: \(error.localizedDescription)" }
        }
    }
}
