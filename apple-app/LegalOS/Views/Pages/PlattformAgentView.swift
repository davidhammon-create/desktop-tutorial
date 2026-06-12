//
//  PlattformAgentView.swift
//  System-Status, KI-Throughput, Quota & globaler Agent-Healthcheck.
//

import SwiftUI

struct PlattformAgentView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @EnvironmentObject var claude: ClaudeAPIService
    @EnvironmentObject var kiProvider: KIProvider

    @State private var logs: [KIUsageLog] = []
    @State private var testPrompt: String = "Bitte erkläre kurz §242 BGB."
    @State private var testAnswer: String = ""
    @State private var testing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Plattform-Agent").font(.title.weight(.semibold))
                Text("Selbst-Diagnose und Verbindungstest zu Anthropic + CloudKit.")
                    .font(.subheadline).foregroundStyle(.secondary)

                HStack {
                    statusPill(title: "Claude API",
                               ok: claude.apiKey != nil,
                               okText: "API-Key gesetzt",
                               failText: "Kein API-Key")
                    statusPill(title: "iCloud",
                               ok: true,
                               okText: "CKContainer aktiv",
                               failText: "Inaktiv")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Test-Anfrage").font(.headline)
                    TextField("Test-Prompt", text: $testPrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await runTest() }
                    } label: {
                        Label(testing ? "Sende…" : "Test ausführen", systemImage: "play.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testing || testPrompt.isEmpty)
                    if !testAnswer.isEmpty {
                        Text(testAnswer)
                            .font(.callout)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Letzte Aufrufe").font(.headline)
                    ForEach(Array(logs.prefix(10))) { log in
                        HStack {
                            Text(log.kiFunction).font(.caption.monospaced())
                            Spacer()
                            Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Plattform-Agent")
        .task { await reload() }
    }

    private func statusPill(title: String, ok: Bool, okText: String, failText: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack {
                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(ok ? .green : .red)
                Text(ok ? okText : failText).font(.subheadline)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func runTest() async {
        testing = true; defer { testing = false }
        let res = await kiProvider.invokeLLM(prompt: testPrompt, context: "PlattformAgent.SelfTest")
        switch res {
        case .success(let v): testAnswer = (v as? String) ?? "(leer)"
        case .failure(let e): testAnswer = "Fehler: \(e.localizedDescription)"
        }
        await reload()
    }

    @MainActor
    private func reload() async {
        logs = (try? await cloudKit.fetch(KIUsageLog.self, limit: 20)) ?? []
    }
}
