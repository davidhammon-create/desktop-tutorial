#if false
import SwiftUI
struct TabArgumenteBeweiseView: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var zeigeNeuesArgument = false
    @State private var zeigeNeuerBeweis = false
    @State private var kiLaeuft = false
    @State private var kiFehler: String?
    var body: some View {
        VStack(spacing: 20) {
            if let err = kiFehler {
                Text(err).font(.caption).foregroundStyle(.red)
            }
            ArgumentBilanzView(argumente: viewModel.argumente)
            HStack {
                Label("Argumente (\(viewModel.argumente.count))", systemImage: "text.bubble.fill")
                    .font(.headline)
                Spacer()
                if kiMode {
                    Button {
                        Task { await alleArgumenteBewerten() }
                    } label: {
                        if kiLaeuft {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Label("Alle bewerten (KI)", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                    .disabled(kiLaeuft || viewModel.argumente.isEmpty)
                }
                Button {
                    zeigeNeuesArgument = true
                } label: {
                    Label("Argument", systemImage: "plus")
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .controlSize(.small)
            }
            if viewModel.argumente.isEmpty {
                InfoHinweis(titel: "Keine Argumente", nachricht: "Erfassen Sie eigene und gegnerische Argumente für Prognose und KI-Analysen.", symbol: "text.bubble")
            } else {
                ForEach(viewModel.argumente) { arg in
                    ArgumentKarte(argument: arg, viewModel: viewModel)
                }
            }
            Divider()
            HStack {
                Label("Beweise (\(viewModel.beweise.count))", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                Spacer()
                Button {
                    zeigeNeuerBeweis = true
                } label: {
                    Label("Beweis", systemImage: "plus")
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .controlSize(.small)
            }
            if !viewModel.beweise.isEmpty {
                BeweisQualitaetsView(beweise: viewModel.beweise)
                ForEach(viewModel.beweise) { ev in
                    BeweisKarte(beweis: ev, viewModel: viewModel)
                }
            } else {
                InfoHinweis(titel: "Keine Beweise", nachricht: "Dokumente, Zeugen und Urkunden stärken die Prognose-Berechnung.", symbol: "doc.text.magnifyingglass")
            }
        }
        .sheet(isPresented: $zeigeNeuesArgument) {
            NeuesArgumentSheet(caseId: viewModel.caseId) { created in
                viewModel.argumente.append(created)
                viewModel.vollanalyseBerechnen()
            }
        }
        .sheet(isPresented: $zeigeNeuerBeweis) {
            NeuerBeweisSheet(caseId: viewModel.caseId) { created in
                viewModel.beweise.append(created)
                viewModel.vollanalyseBerechnen()
            }
        }
    }
    private func alleArgumenteBewerten() async {
        guard let fall = viewModel.fall else { return }
        kiLaeuft = true
        kiFehler = nil
        defer { kiLaeuft = false }
        let liste = viewModel.argumente.map {
            "\($0.side.rawValue): \($0.title) — \($0.description ?? "")"
        }.joined(separator: "\n")
        let prompt = """
        Bewerte alle Argumente im Fall \(fall.fallname) (\(fall.rechtsgebiet ?? "")):
        \(liste)
        Für jedes Argument: ki_strength (0-10), ki_reasoning (kurz), type (Form/Sach/Rechts/Indiz).
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: [
                    "type": "object",
                    "properties": [
                        "argumente": ["type": "array", "items": ["type": "object", "properties": [
                            "title": ["type": "string"],
                            "ki_strength": ["type": "number"],
                            "ki_reasoning": ["type": "string"],
                            "type": ["type": "string"]
                        ]]]
                    ] as [String: Any]
                ] as [String: Any],
                model: "claude_sonnet_4_6",
                logCaseId: viewModel.caseId,
                logKiName: "Argumente — Alle bewerten"
            )
            let dict = try KIJson.requireObject(result, kontext: "Argumente")
            let bewertungen = dict["argumente"] as? [[String: Any]] ?? []
            for arg in viewModel.argumente {
                guard let id = arg.id,
                      let match = bewertungen.first(where: {
                          KITitleMatcher.matchId(title: $0["title"] as? String ?? "", candidates: [(id, arg.title)]) == id
                              || ($0["title"] as? String ?? "").lowercased().contains(arg.title.lowercased().prefix(12))
                      }) else { continue }
                var updated = arg
                if let s = KIJson.numberValue(match["ki_strength"]) {
                    updated.ki_strength = s
                }
                updated.ki_reasoning = match["ki_reasoning"] as? String ?? updated.ki_reasoning
                updated.type = match["type"] as? String ?? updated.type
                if let saved = try? await Services.arguments.update(id: id, entity: updated),
                   let idx = viewModel.argumente.firstIndex(where: { $0.id == id }) {
                    await MainActor.run { viewModel.argumente[idx] = saved }
                }
            }
            await MainActor.run { viewModel.vollanalyseBerechnen() }
        } catch {
            await MainActor.run { kiFehler = error.localizedDescription }
        }
    }
}
#endif
