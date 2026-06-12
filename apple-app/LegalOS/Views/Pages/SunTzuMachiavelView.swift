//
//  SunTzuMachiavelView.swift
//  Strategische Maximen aus "Die Kunst des Krieges" und "Der Fürst",
//  anwendbar auf einen Fall. Entspricht src/pages/SunTzuMachiavel.jsx.
//

import SwiftUI

struct SunTzuMaxim: Identifiable, Hashable {
    let id = UUID()
    let author: Author
    let title: String
    let original: String
    let anwendung: String
    enum Author: String { case sunTzu = "Sun Tzu", machiavelli = "Machiavelli" }
}

struct SunTzuMachiavelView: View {
    @EnvironmentObject var kiProvider: KIProvider
    @EnvironmentObject var cloudKit: CloudKitService

    @State private var cases: [Case] = []
    @State private var selectedCaseId: String?
    @State private var maxims: [SunTzuMaxim] = Self.defaultMaxims
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                casePicker
                Button {
                    Task { await generateAdvice() }
                } label: {
                    Label(loading ? "Strategien werden generiert…" : "Strategien für gewählten Fall ableiten",
                          systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(loading || selectedCaseId == nil)

                Divider()

                ForEach([SunTzuMaxim.Author.sunTzu, .machiavelli], id: \.self) { author in
                    Text(author.rawValue).font(.title2.weight(.semibold))
                    ForEach(maxims.filter { $0.author == author }) { m in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(m.title).font(.subheadline.weight(.semibold))
                            Text(m.original).italic().font(.caption).foregroundStyle(.secondary)
                            Text(m.anwendung).font(.caption)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Sun Tzu / Machiavelli")
        .task { cases = (try? await cloudKit.fetch(Case.self)) ?? [] }
    }

    private var header: some View {
        Text("Klassische Strategie-Maximen, übersetzt in juristische Handlungsempfehlungen.")
            .font(.subheadline).foregroundStyle(.secondary)
    }

    private var casePicker: some View {
        Picker("Fall", selection: $selectedCaseId) {
            Text("Fall auswählen").tag(String?.none)
            ForEach(cases) { c in Text(c.fallname).tag(Optional(c.id)) }
        }
    }

    @MainActor
    private func generateAdvice() async {
        guard let id = selectedCaseId,
              let c = cases.first(where: { $0.id == id }) else { return }
        loading = true; defer { loading = false }
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "maximen": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "author": ["type": "string", "enum": ["Sun Tzu", "Machiavelli"]],
                            "title": ["type": "string"],
                            "original": ["type": "string"],
                            "anwendung": ["type": "string"]
                        ],
                        "required": ["author","title","original","anwendung"]
                    ]
                ]
            ],
            "required": ["maximen"]
        ]
        let prompt = """
        Erzeuge 6 Strategie-Maximen (3 Sun Tzu, 3 Machiavelli), die auf folgenden Fall angewandt werden:
        - Fall: \(c.fallname)
        - Gericht: \(c.gericht ?? "–")
        - Rechtsgebiet: \(c.rechtsgebiet ?? "–")
        - Prozessziel: \(c.prozessziel ?? "–")
        Jede Maxime mit Original-Zitat (kurz) und konkreter, anwaltlicher Anwendung (max. 2 Sätze).
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, schema: schema, context: "SunTzuMachiavel", caseId: id)
        guard case .success(let v) = res,
              let dict = v as? [String: Any],
              let arr  = dict["maximen"] as? [[String: Any]] else { return }
        maxims = arr.compactMap { raw in
            guard let a = raw["author"] as? String,
                  let t = raw["title"] as? String,
                  let o = raw["original"] as? String,
                  let an = raw["anwendung"] as? String else { return nil }
            let author: SunTzuMaxim.Author = (a == "Machiavelli") ? .machiavelli : .sunTzu
            return SunTzuMaxim(author: author, title: t, original: o, anwendung: an)
        }
    }

    static let defaultMaxims: [SunTzuMaxim] = [
        .init(author: .sunTzu, title: "Kenne deinen Gegner",
              original: "Wenn du den Feind kennst und dich selbst kennst, brauchst du das Ergebnis von hundert Schlachten nicht zu fürchten.",
              anwendung: "Analysiere Vorprozesse und Strategie-Muster des Gegenanwalts vor jedem Termin."),
        .init(author: .sunTzu, title: "Indirekter Angriff",
              original: "Der höchste Sieg ist, ohne Kampf zu siegen.",
              anwendung: "Versuche zuerst tragfähige Vergleichsangebote, bevor du in die Hauptverhandlung gehst."),
        .init(author: .machiavelli, title: "Macht & Wahrnehmung",
              original: "Es genügt nicht, mächtig zu sein, man muss auch so wirken.",
              anwendung: "Klares, präzises Auftreten in jeder Eingabe – Form ist Substanz.")
    ]
}
