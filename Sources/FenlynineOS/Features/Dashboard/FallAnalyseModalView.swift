import SwiftUI
struct FallAnalyseModalView: View {
    let faelle: [LegalCase]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCaseId = ""
    @State private var result: String?
    @State private var laeuft = false
    @State private var fehler: String?
    private var selectedCase: LegalCase? {
        faelle.first { $0.id == selectedCaseId }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Fall-Analyse", systemImage: "scalemass.fill").font(.headline)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
            }
            .padding()
            Divider()
            Form {
                Picker("Fall wählen", selection: $selectedCaseId) {
                    Text("– Fall wählen –").tag("")
                    ForEach(faelle.filter { $0.id != nil }) { f in
                        Text(f.fallname).tag(f.id ?? "")
                    }
                }
                Button {
                    Task { await analyse() }
                } label: {
                    if laeuft {
                        ProgressView().scaleEffect(0.7)
                        Text("Analyse wird generiert…")
                    } else {
                        Label("Analyse starten", systemImage: "brain.fill")
                    }
                }
                .disabled(selectedCase == nil || laeuft)
            }
            .formStyle(.grouped)
            .frame(maxHeight: 140)
            if let err = fehler {
                Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
            }
            if let text = result {
                ScrollView {
                    Text(text)
                        .font(.system(size: 12))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            } else if !laeuft {
                InfoHinweis(titel: "KI-Fallanalyse", nachricht: "Wählen Sie einen Fall und starten Sie eine umfassende rechtliche Ersteinschätzung.", symbol: "brain")
                    .padding()
            }
            Divider()
            HStack {
                Spacer()
                Button("Schließen") { dismiss() }
                if result != nil {
                    Button("Neue Analyse") { result = nil; fehler = nil }
                }
            }
            .padding()
        }
        .frame(width: 640, height: 520)
    }
    private func analyse() async {
        guard let fall = selectedCase, let caseId = fall.id else { return }
        laeuft = true
        fehler = nil
        result = nil
        defer { laeuft = false }
        do {
            async let args = Services.arguments.listForCase(caseId: caseId)
            async let evs = Services.evidence.listForCase(caseId: caseId)
            async let dead = Services.deadlines.listForCase(caseId: caseId)
            let (argumente, beweise, fristen) = try await (args, evs, dead)
            let argLines = argumente.map {
                "- [\($0.side == .eigen ? "EIGEN" : "GEGNER")] \($0.title): \($0.description ?? "") (Stärke: \($0.strength)/10)"
            }.joined(separator: "\n")
            let evLines = beweise.map {
                "- \($0.title): \($0.description ?? "") (Gewicht: \($0.weight)/10)"
            }.joined(separator: "\n")
            let dlLines = fristen.filter { $0.status == .offen }.map {
                "- \($0.title) (fällig: \($0.due_date.formatted(date: .numeric, time: .omitted)))"
            }.joined(separator: "\n")
            let prompt = """
            Analysiere den folgenden Fall und erstelle:
            1. Eine präzise Zusammenfassung des Falls (2–3 Absätze)
            2. Eine rechtliche Ersteinschätzung der Erfolgsaussichten mit konkreter Begründung
            3. Die wichtigsten Stärken und Schwächen der eigenen Position
            4. Empfehlungen für die weitere Strategie
            **Fall:** \(fall.fallname)
            **Aktenzeichen:** \(fall.aktenzeichen ?? "–")
            **Rechtsgebiet:** \(fall.rechtsgebiet ?? "–")
            **Gericht:** \(fall.gericht ?? "–")
            **Instanz:** \(fall.instanz.rawValue)
            **Status:** \(fall.status.rawValue)
            **Streitwert:** \(fall.streitwert.map { "\(Int($0)) €" } ?? "–")
            **Prozessziel:** \(fall.prozessziel ?? "–")
            **Zentrale Rechtsfrage:** \(fall.zentrale_rechtsfrage ?? "–")
            **Bisherige Prognose:** \(fall.prognose.map { "\(Int($0))%" } ?? "–")
            **Argumente (\(argumente.count)):**
            \(argLines.isEmpty ? "Keine erfasst" : argLines)
            **Beweise (\(beweise.count)):**
            \(evLines.isEmpty ? "Keine erfasst" : evLines)
            **Offene Fristen (\(fristen.filter { $0.status == .offen }.count)):**
            \(dlLines.isEmpty ? "Keine offenen Fristen" : dlLines)
            **Notizen:** \(fall.notes ?? "–")
            Antworte strukturiert mit Markdown-Überschriften. Zitiere konkrete §§ und einschlägige Rechtsprechung. Sei präzise und praxisorientiert.
            """
            let text = try await LLMService.shared.invokeText(
                prompt: prompt,
                model: "claude_sonnet_4_6",
                logCaseId: caseId,
                logKiName: "Dashboard — Fall-Analyse"
            )
            await MainActor.run { result = text }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
