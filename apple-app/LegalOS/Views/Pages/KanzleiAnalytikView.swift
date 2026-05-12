//
//  KanzleiAnalytikView.swift
//  Statistiken über Fallerfolg, Prognose-Treffer, Vergleich vs. Urteil.
//

import SwiftUI
import Charts

struct KanzleiAnalytikView: View {
    @EnvironmentObject var cloudKit: CloudKitService
    @State private var cases: [Case] = []
    @State private var feedback: [AIPerformanceFeedback] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Kanzlei-Analytik").font(.title.weight(.semibold))

                VStack(alignment: .leading) {
                    Text("Fälle nach Status").font(.headline)
                    Chart(statusBuckets, id: \.0) { item in
                        BarMark(x: .value("Status", item.0),
                                y: .value("Anzahl", item.1))
                    }
                    .frame(height: 220)
                }

                VStack(alignment: .leading) {
                    Text("Prognose-Treffer (Gesamtbewertung)").font(.headline)
                    if feedback.isEmpty {
                        Text("Noch keine Feedback-Daten vorhanden.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Chart(feedback) { f in
                            PointMark(x: .value("Datum", f.id),
                                      y: .value("Gesamtbewertung", f.gesamtbewertung))
                        }
                        .frame(height: 220)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Streitwert-Verteilung").font(.headline)
                    Chart(cases.filter { $0.streitwert != nil }) { c in
                        BarMark(x: .value("Fall", c.fallname),
                                y: .value("Streitwert", c.streitwert ?? 0))
                    }
                    .frame(height: 240)
                }
            }
            .padding()
        }
        .navigationTitle("Analytik")
        .task { await reload() }
    }

    private var statusBuckets: [(String, Int)] {
        CaseStatus.allCases.map { s in
            (s.rawValue, cases.filter { $0.status == s }.count)
        }
    }

    @MainActor
    private func reload() async {
        cases    = (try? await cloudKit.fetch(Case.self)) ?? []
        feedback = (try? await cloudKit.fetch(AIPerformanceFeedback.self)) ?? []
    }
}
