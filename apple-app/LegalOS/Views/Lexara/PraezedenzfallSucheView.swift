//
//  PraezedenzfallSucheView.swift
//  Konversion von src/components/lexara/PraezedenzfallSuche.jsx
//  KI-basierte Suche nach Präzedenzfällen, Speichern und Übernahme als Argumente.
//

import SwiftUI

struct PraezedenzfallSucheView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var query = ""
    @State private var rechtsgebietFilter = ""
    @State private var instanzFilter = ""
    @State private var loading = false
    @State private var results: [Praezedenz] = []
    @State private var saved: Set<String> = []
    @State private var error: String?

    struct Praezedenz: Codable, Identifiable {
        var id: String { aktenzeichen ?? UUID().uuidString }
        var aktenzeichen: String?
        var gericht: String?
        var datum: String?
        var leitsatz: String?
        var sachverhalt: String?
        var entscheidungsgruende: String?
        var relevanz: String?
        var anwendbarkeit: String?
        var url: String?
    }

    struct PraezedenzResponse: Codable {
        var faelle: [Praezedenz]?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchForm
                if loading { ProgressView("Suche Präzedenzfälle…").padding() }
                if let e = error { Label(e, systemImage: "exclamationmark.triangle").foregroundColor(.red).font(.caption) }
                if !results.isEmpty {
                    Text("\(results.count) Präzedenzfälle gefunden").font(.subheadline.weight(.semibold))
                    ForEach(results) { p in resultCard(p) }
                }
            }.padding(20)
        }
    }

    private var searchForm: some View {
        GroupBox("Präzedenzfall-Suche") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Suchbegriff (z. B. \"Mietrecht Eigenbedarf\")", text: $query, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2)
                HStack {
                    TextField("Rechtsgebiet", text: $rechtsgebietFilter).textFieldStyle(.roundedBorder)
                    TextField("Instanz", text: $instanzFilter).textFieldStyle(.roundedBorder)
                }
                Button {
                    Task { await search() }
                } label: {
                    Label("KI-Suche starten", systemImage: "magnifyingglass")
                }.buttonStyle(.borderedProminent).disabled(query.isEmpty || loading)
            }.padding(8)
        }
    }

    private func resultCard(_ p: Praezedenz) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(p.gericht ?? "–").font(.caption2.weight(.bold)).foregroundColor(.blue)
                        Text(p.aktenzeichen ?? "?").font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    if let d = p.datum { Text(d).font(.caption2).foregroundColor(.secondary) }
                    if let r = p.relevanz {
                        Text(r).font(.caption2.weight(.bold)).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(relevanceColor(r).opacity(0.15)).foregroundColor(relevanceColor(r)).clipShape(Capsule())
                    }
                }
                if let l = p.leitsatz { Text(l).font(.caption).italic() }
                if let s = p.sachverhalt { Text("Sachverhalt: \(s)").font(.caption2).foregroundColor(.secondary) }
                if let a = p.anwendbarkeit { Label(a, systemImage: "checkmark.circle").font(.caption2).foregroundColor(.green) }
                HStack {
                    Button(saved.contains(p.id) ? "Gespeichert ✓" : "Als Argument speichern") {
                        Task { await saveAsArgument(p) }
                    }
                    .buttonStyle(.borderedProminent).disabled(saved.contains(p.id))
                    if let url = p.url, let u = URL(string: url) { Link("Quelle", destination: u).font(.caption) }
                }
            }.padding(8)
        }
    }

    private func relevanceColor(_ r: String) -> Color {
        switch r.lowercased() {
        case "hoch": return .green
        case "mittel": return .orange
        default: return .gray
        }
    }

    private func search() async {
        loading = true; defer { loading = false }
        error = nil
        let prompt = """
        Du bist ein juristischer Researcher. Finde 5 relevante Präzedenzfälle.
        Suche: \(query)
        Rechtsgebiet: \(rechtsgebietFilter.isEmpty ? caseData?.rechtsgebiet ?? "" : rechtsgebietFilter)
        Antworte als JSON: {faelle: [{aktenzeichen, gericht, datum, leitsatz, sachverhalt, entscheidungsgruende, relevanz, anwendbarkeit, url}]}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Präzedenzsuche", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String, let data = raw.data(using: .utf8),
           let resp = try? JSONDecoder().decode(PraezedenzResponse.self, from: data) {
            results = resp.faelle ?? []
        } else {
            error = "KI-Suche fehlgeschlagen."
        }
    }

    private func saveAsArgument(_ p: Praezedenz) async {
        var arg = Argument(caseId: caseId, title: "Präzedenz: \(p.aktenzeichen ?? "")")
        arg.argDescription = p.leitsatz
        arg.type = "Präzedenz"
        arg.side = .eigen
        arg.strength = 7
        do {
            _ = try await cloudKit.save(arg)
            saved.insert(p.id)
        } catch let err { error = err.localizedDescription }
    }
}
