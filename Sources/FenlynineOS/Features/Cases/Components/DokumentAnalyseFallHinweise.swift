import SwiftUI
struct DokumentGegnerProfilPanel: View {
    let profil: [String: Any]
    private var zusammenfassung: String? {
        (profil["ki_zusammenfassung"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty ?? (profil["profil_text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
    private var taktiken: [String] { profil["taktiken"] as? [String] ?? [] }
    private var schwachstellen: [String] { profil["schwachstellen"] as? [String] ?? [] }
    var body: some View {
        if zusammenfassung != nil || !taktiken.isEmpty || !schwachstellen.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Aus Dokumenten-Analyse", systemImage: "doc.text.magnifyingglass")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                if let z = zusammenfassung {
                    Text(z).font(.system(size: 12)).lineSpacing(3)
                }
                if !taktiken.isEmpty {
                    Text("Erkannte Taktiken").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(taktiken.prefix(8), id: \.self) { t in
                        Text("⚔ \(t)").font(.caption)
                    }
                }
                if !schwachstellen.isEmpty {
                    Text("Schwachstellen Gegner").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(schwachstellen.prefix(8), id: \.self) { s in
                        Text("⚠ \(s)").font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.15), lineWidth: 1))
        }
    }
}
struct DokumentKiBeraterPanel: View {
    let ki: [String: Any]
    private var paragrafen: [String] { ki["relevante_paragrafen"] as? [String] ?? [] }
    private var praezedenz: [String] { ki["praezedenzfaelle"] as? [String] ?? [] }
    private var risikoLevel: String? { ki["risiko_aus_dokument"] as? String }
    private var simulationHinweis: String? { (ki["simulation_hinweis"] as? String)?.nilIfEmpty }
    private var vergleichswert: Double? { ki["vergleichswert_eur"] as? Double }
    private var prognoseDelta: Double? { ki["prognose_delta"] as? Double }
    private var vergleichsempfehlung: String? { (ki["vergleichsempfehlung"] as? String)?.nilIfEmpty }
    private var hatInhalt: Bool {
        !paragrafen.isEmpty || !praezedenz.isEmpty || risikoLevel != nil
            || simulationHinweis != nil || vergleichswert != nil
            || prognoseDelta != nil || vergleichsempfehlung != nil
    }
    var body: some View {
        if hatInhalt {
            VStack(alignment: .leading, spacing: 10) {
                Label("KI-Erkenntnisse aus Dokumenten", systemImage: "doc.richtext.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                if !paragrafen.isEmpty {
                    Text("Relevante Paragrafen: \(paragrafen.prefix(6).joined(separator: ", "))")
                        .font(.caption)
                }
                if !praezedenz.isEmpty {
                    Text("Präzedenzfälle").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(praezedenz.prefix(4), id: \.self) { p in
                        Text("⚖ \(p)").font(.caption2)
                    }
                }
                if let r = risikoLevel {
                    Text("Risiko aus Dokument: \(r.capitalized)").font(.caption).foregroundStyle(.orange)
                }
                if let s = simulationHinweis {
                    Text("Simulation: \(s)").font(.caption)
                }
                if let v = vergleichswert, v > 0 {
                    Text("Vergleichswert: \(formatEuro(v))").font(.caption.bold())
                }
                if let d = prognoseDelta, d != 0 {
                    Text("Prognose-Einfluss: \(d > 0 ? "+" : "")\(Int(d))%")
                        .font(.caption)
                        .foregroundStyle(d > 0 ? .green : .red)
                }
                if let v = vergleichsempfehlung {
                    Text("Vergleichsempfehlung: \(v)").font(.caption)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.15), lineWidth: 1))
        }
    }
    private func formatEuro(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value)) €"
    }
}
private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
