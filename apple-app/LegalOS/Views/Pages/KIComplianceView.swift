//
//  KIComplianceView.swift
//  Auditierung sämtlicher KI-Aufrufe – Modell, Input-Hash, Output, Bewertung.
//

import SwiftUI

struct KIComplianceView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var logs: [KIUsageLog] = []
    @State private var search: String = ""

    private var filtered: [KIUsageLog] {
        guard !search.isEmpty else { return logs }
        return logs.filter {
            $0.kiFunction.localizedCaseInsensitiveContains(search) ||
            ($0.context ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(.purple)
                        Text(log.kiFunction).font(.body.weight(.medium))
                        Spacer()
                        Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let ctx = log.context {
                        Text(ctx).font(.caption).foregroundStyle(.secondary)
                    }
                    if let s = log.inputSummary {
                        Text(s).font(.caption2).lineLimit(2).foregroundStyle(.secondary)
                    }
                    if let m = log.model {
                        Text("Modell: \(m)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $search, prompt: "KI-Funktion oder Kontext")
        .navigationTitle("KI-Compliance")
        .task { await reload() }
        .refreshable { await reload() }
    }

    @MainActor
    private func reload() async {
        logs = (try? await cloudKit.fetch(KIUsageLog.self)) ?? []
    }
}
