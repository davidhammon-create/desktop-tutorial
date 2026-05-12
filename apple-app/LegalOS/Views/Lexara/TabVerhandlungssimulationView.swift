//
//  TabVerhandlungssimulationView.swift
//  Konversion von src/components/lexara/TabVerhandlungssimulation.jsx
//  Simuliert Verhandlungsszenarien mit verschiedenen Strategien und Reaktionen.
//

import SwiftUI

struct TabVerhandlungssimulationView: View {
    let caseId: String
    let caseData: Case?

    @EnvironmentObject var kiProvider: KIProvider

    @State private var unsereStrategie: Strategie = .vergleich
    @State private var startangebot: String = ""
    @State private var maxAngebot: String = ""
    @State private var minAkzeptanz: String = ""
    @State private var gegnerProfil: String = "kooperativ"
    @State private var emotionalContext = ""
    @State private var loading = false
    @State private var simulation: Simulation?

    enum Strategie: String, CaseIterable, Identifiable {
        case vergleich, hart, kooperativ, kreativ
        var id: Self { self }
        var label: String {
            switch self {
            case .vergleich: return "Vergleich anstreben"
            case .hart: return "Hart verhandeln"
            case .kooperativ: return "Kooperativ"
            case .kreativ: return "Kreative Lösungen"
            }
        }
    }

    struct Simulation: Codable {
        var verlauf: [Verhandlungsschritt]?
        var ergebnis: String?
        var wahrscheinlichkeit_einigung: Double?
        var einigungsbetrag: Double?
        var risiken: [String]?
        var empfehlungen: [String]?
    }
    struct Verhandlungsschritt: Codable, Identifiable {
        var id: String { runde + akteur }
        var runde: String
        var akteur: String
        var aktion: String
        var begruendung: String?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputForm
                Button {
                    Task { await runSimulation() }
                } label: {
                    Label(loading ? "Simuliere…" : "Verhandlung simulieren", systemImage: "play.fill")
                }.buttonStyle(.borderedProminent).disabled(loading)
                if let s = simulation { resultView(s) }
            }.padding(20)
        }
    }

    private var inputForm: some View {
        Form {
            Section("Eigene Strategie") {
                Picker("Strategie", selection: $unsereStrategie) {
                    ForEach(Strategie.allCases) { Text($0.label).tag($0) }
                }
                TextField("Startangebot (€)", text: $startangebot).textFieldStyle(.roundedBorder)
                TextField("Maximales Angebot (€)", text: $maxAngebot).textFieldStyle(.roundedBorder)
                TextField("Minimale Akzeptanz (€)", text: $minAkzeptanz).textFieldStyle(.roundedBorder)
            }
            Section("Gegner") {
                Picker("Profil", selection: $gegnerProfil) {
                    ForEach(["kooperativ", "kompromisslos", "manipulativ", "rational", "emotional"], id: \.self) { Text($0).tag($0) }
                }
                TextField("Emotionaler Kontext", text: $emotionalContext, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(3)
            }
        }.formStyle(.grouped)
    }

    private func resultView(_ s: Simulation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let e = s.ergebnis {
                GroupBox("Ergebnis") {
                    Text(e).font(.subheadline).padding(8)
                }
            }
            if let p = s.wahrscheinlichkeit_einigung {
                GroupBox {
                    HStack {
                        VStack {
                            Text("\(Int(p * 100))%").font(.title.weight(.bold))
                            Text("Einigung").font(.caption2)
                        }
                        if let b = s.einigungsbetrag {
                            VStack {
                                Text("\(Int(b)) €").font(.title3.weight(.bold))
                                Text("Betrag").font(.caption2)
                            }
                        }
                    }
                }
            }
            if let v = s.verlauf, !v.isEmpty {
                GroupBox("Verlauf") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(v) { schritt in
                            HStack(alignment: .top) {
                                Text(schritt.runde).font(.caption2.weight(.bold)).foregroundColor(.blue).frame(width: 60, alignment: .leading)
                                VStack(alignment: .leading) {
                                    Text("\(schritt.akteur): \(schritt.aktion)").font(.caption)
                                    if let b = schritt.begruendung { Text(b).font(.caption2).foregroundColor(.secondary) }
                                }
                            }
                        }
                    }.padding(8)
                }
            }
            if let r = s.risiken, !r.isEmpty {
                GroupBox("Risiken") {
                    VStack(alignment: .leading) { ForEach(r, id: \.self) { Label($0, systemImage: "exclamationmark.triangle").font(.caption).foregroundColor(.orange) } }
                }
            }
            if let e = s.empfehlungen, !e.isEmpty {
                GroupBox("Empfehlungen") {
                    VStack(alignment: .leading) { ForEach(e, id: \.self) { Label($0, systemImage: "lightbulb").font(.caption).foregroundColor(.green) } }
                }
            }
        }
    }

    private func runSimulation() async {
        loading = true; defer { loading = false }
        let prompt = """
        Simuliere eine Verhandlung:
        Strategie: \(unsereStrategie.label), Start: \(startangebot)€, Max: \(maxAngebot)€, Min: \(minAkzeptanz)€
        Gegner: \(gegnerProfil), Kontext: \(emotionalContext)
        Antworte als JSON: {verlauf: [{runde, akteur, aktion, begruendung}], ergebnis, wahrscheinlichkeit_einigung, einigungsbetrag, risiken, empfehlungen}
        """
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "Verhandlungssimulation", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String, let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(Simulation.self, from: data) {
            simulation = result
        }
    }
}
