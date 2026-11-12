import SwiftUI
struct KIFeedbackPanelView: View {
    let caseId: String
    @State private var logs: [String: KIUsageLog] = [:]
    @State private var aufgeklappt = true
    private let categories: [FeedbackKategorie] = [
        FeedbackKategorie(key: "ki_strategie", label: "KI-Strategieanalyse (Tab 3 — KI-Berater)", desc: "War die strategische Empfehlung zutreffend?", type: .ki),
        FeedbackKategorie(key: "ki_prognose", label: "KI-Prognose (Monte Carlo / Tab 10)", desc: "Wie treffend war die Erfolgswahrscheinlichkeit?", type: .ki),
        FeedbackKategorie(key: "ki_risiko", label: "KI-Risikoanalyse (Tab 6)", desc: "Wurden Risiken korrekt erkannt?", type: .ki),
        FeedbackKategorie(key: "ki_gegner", label: "KI-Gegneranalyse (Tab 3)", desc: "Hat die KI das Verhalten richtig eingeschätzt?", type: .ki),
        FeedbackKategorie(key: "ki_dokumente", label: "KI-Dokumentenanalyse (Tab 1)", desc: "Wurden Argumente/Fristen korrekt extrahiert?", type: .ki),
        FeedbackKategorie(key: "human_argumente", label: "Menschliche Argumentgewichtung", desc: "Lagen Ihre Gewichtungen richtig?", type: .human),
        FeedbackKategorie(key: "human_strategie", label: "Eigene strategische Entscheidungen", desc: "Waren Vergleichsangebote/Verhandlungslinie korrekt?", type: .human)
    ]
    struct FeedbackKategorie: Identifiable {
        let key: String
        let label: String
        let desc: String
        let type: FeedbackTyp
        var id: String { key }
        enum FeedbackTyp { case ki, human }
    }
    private var ratedCount: Int { logs.values.filter { $0.rating != nil }.count }
    private var avgKiRating: Double? {
        let ratings = categories.filter { $0.type == .ki }.compactMap { logs[$0.key]?.rating }
        guard !ratings.isEmpty else { return nil }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { withAnimation { aufgeklappt.toggle() } } label: {
                HStack {
                    Text("KI- & Eigeneinschätzung bewerten").font(.subheadline.bold())
                    Text("\(ratedCount)/\(categories.count) bewertet")
                        .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1), in: Capsule())
                    Spacer()
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.plain)
            Text("Bewerte jede KI-Analyse auf 1–10. Die Bewertungen fließen in die Monte-Carlo-Treffsicherheit ein.")
                .font(.caption2).foregroundStyle(.secondary)
            if let avg = avgKiRating {
                HStack(spacing: 8) {
                    Text(avg >= 7 ? "✅" : avg >= 5 ? "⚠️" : "❌")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ø KI-Bewertung: \(String(format: "%.1f", avg))/10").font(.caption.bold())
                        Text(avg >= 7 ? "Treffsicherheit wird erhöht." : avg >= 5 ? "Mittlere Treffsicherheit." : "Treffsicherheit wird gesenkt.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((avg >= 7 ? Color.green : avg >= 5 ? Color.orange : Color.red).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            if aufgeklappt {
                Text("KI-Analysen").font(.caption2.bold()).foregroundStyle(.purple)
                ForEach(categories.filter { $0.type == .ki }) { cat in
                    FeedbackKarteView(caseId: caseId, kategorie: cat, existing: logs[cat.key]) {
                        Task { await laden() }
                    }
                }
                Text("Menschliche Einschätzung").font(.caption2.bold()).foregroundStyle(.blue).padding(.top, 8)
                ForEach(categories.filter { $0.type == .human }) { cat in
                    FeedbackKarteView(caseId: caseId, kategorie: cat, existing: logs[cat.key]) {
                        Task { await laden() }
                    }
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
        .task { await laden() }
    }
    private func laden() async {
        do {
            let all = try await Services.kiUsageLogs.listForCase(caseId: caseId)
            var map: [String: KIUsageLog] = [:]
            for log in all {
                if let ctx = log.context { map[ctx] = log }
            }
            await MainActor.run { logs = map }
        } catch {}
    }
    static func feedbackLogsForCase(_ caseId: String) async -> [KIUsageLog] {
        (try? await Services.kiUsageLogs.listForCase(caseId: caseId)) ?? []
    }
}
private struct FeedbackKarteView: View {
    let caseId: String
    let kategorie: KIFeedbackPanelView.FeedbackKategorie
    let existing: KIUsageLog?
    let onSaved: () -> Void
    @State private var rating: Int?
    @State private var feedback = ""
    @State private var showText = false
    @State private var speichert = false
    @State private var gespeichert = false
    @State private var fehler: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kategorie.label).font(.caption.bold())
            Text(kategorie.desc).font(.caption2).foregroundStyle(.secondary)
            SternZeileView(rating: $rating)
            Button(showText ? "Text ausblenden" : "Detailliertes Feedback (optional)") {
                showText.toggle()
            }
            .font(.caption2).buttonStyle(.plain)
            if showText {
                TextField("Feedback…", text: $feedback, axis: .vertical)
                    .lineLimit(2...4).textFieldStyle(.roundedBorder).font(.caption)
            }
            if rating != nil {
                Button(gespeichert ? "✓ Gespeichert" : "Bewertung speichern") {
                    Task { await speichern() }
                }
                .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                .controlSize(.small)
                .disabled(speichert)
            }
            if let fehler {
                Text(fehler)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(10)
        .background((kategorie.type == .ki ? Color.purple : Color.blue).opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .onAppear {
            rating = existing?.rating
            feedback = existing?.feedback ?? ""
        }
    }
    private func speichern() async {
        guard let rating else { return }
        speichert = true
        defer { speichert = false }
        do {
            if var log = existing, let id = log.id {
                log.rating = rating
                log.feedback = feedback.isEmpty ? nil : feedback
                log.timestamp = ISO8601DateFormatter().string(from: Date())
                _ = try await Services.kiUsageLogs.update(id: id, entity: log)
            } else {
                var log = KIUsageLog(
                    case_id: caseId,
                    ki_function: kategorie.type == .ki ? "KI-Analyse" : "Manuelle Einschätzung",
                    input_summary: kategorie.label,
                    output: kategorie.desc
                )
                log.context = kategorie.key
                log.rating = rating
                log.feedback = feedback.isEmpty ? nil : feedback
                log.timestamp = ISO8601DateFormatter().string(from: Date())
                _ = try await Services.kiUsageLogs.create(log)
            }
            await MainActor.run {
                fehler = nil
                gespeichert = true
            }
            onSaved()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { gespeichert = false }
        } catch {
            await MainActor.run {
                gespeichert = false
                fehler = "Bewertung nicht gespeichert: \(error.localizedDescription)"
            }
        }
    }
}
private struct SternZeileView: View {
    @Binding var rating: Int?
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...10, id: \.self) { n in
                Button("\(n)") {
                    rating = n
                }
                .font(.caption2.bold())
                .frame(width: 24, height: 24)
                .background(sternFarbe(n).opacity((rating ?? 0) >= n ? 1 : 0.15), in: RoundedRectangle(cornerRadius: 4))
                .foregroundStyle((rating ?? 0) >= n ? .white : .secondary)
                .buttonStyle(.plain)
            }
        }
    }
    private func sternFarbe(_ n: Int) -> Color {
        if n <= 3 { return .red }
        if n <= 6 { return .orange }
        return .green
    }
}
