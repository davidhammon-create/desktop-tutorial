//
//  ArgumentZeitstrahlChartView.swift
//  Konversion von src/components/lexara/ArgumentZeitstrahlChart.jsx
//  Stellt Argumente und Fristen auf einer Zeitachse dar mit KI-Analyse.
//

import SwiftUI
import Charts

struct ArgumentZeitstrahlChartView: View {
    let caseId: String
    let args: [Argument]
    let deadlines: [Deadline]
    let connections: [(from: String, to: String, type: String)]

    @EnvironmentObject var kiProvider: KIProvider

    @State private var selected: Argument? = nil
    @State private var kiLoading = false
    @State private var kiResult: KIAnalyse? = nil

    init(caseId: String, args: [Argument], deadlines: [Deadline] = [], connections: [(from: String, to: String, type: String)] = []) {
        self.caseId = caseId
        self.args = args
        self.deadlines = deadlines
        self.connections = connections
    }

    struct KIAnalyse: Codable {
        var trend_einschaetzung: String?
        var staerke_aktuell: Double?
        var empfehlung: String?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if args.isEmpty {
                Text("Noch keine Argumente mit Zeitbezug vorhanden.").font(.caption).foregroundColor(.secondary).frame(height: 160).frame(maxWidth: .infinity)
            } else {
                chart
                legend
                if let r = kiResult { kiResultCard(r) }
                Button { Task { await runKiAnalyse() } } label: {
                    Label(kiLoading ? "Analysiere…" : "KI-Trendanalyse", systemImage: "sparkles")
                }.buttonStyle(.borderedProminent).disabled(kiLoading)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(datedArgs) { a in
                let strength = a.kiStrength ?? a.strength ?? 5
                PointMark(x: .value("Datum", argDate(a)), y: .value("Stärke", strength))
                    .foregroundStyle(a.side == .eigen ? .blue : .red)
                    .symbolSize(CGFloat(strength) * 30)
                    .annotation(position: .top) { Text(a.title).font(.system(size: 8)).lineLimit(1) }
            }
            ForEach(deadlines) { d in
                RuleMark(x: .value("Frist", d.dueDate))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text(d.title).font(.system(size: 8)).foregroundColor(.orange)
                    }
            }
        }
        .frame(height: 320)
        .chartYScale(domain: 0...10)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label("Eigene", systemImage: "circle.fill").foregroundColor(.blue).font(.caption2)
            Label("Gegner", systemImage: "circle.fill").foregroundColor(.red).font(.caption2)
            Label("Frist", systemImage: "minus").foregroundColor(.orange).font(.caption2)
            Spacer()
        }
    }

    private func kiResultCard(_ r: KIAnalyse) -> some View {
        GroupBox("KI-Trendanalyse") {
            VStack(alignment: .leading, spacing: 6) {
                if let t = r.trend_einschaetzung { Text(t).font(.caption) }
                if let s = r.staerke_aktuell { Label("Aktuelle Stärke: \(Int(s))/10", systemImage: "chart.line.uptrend.xyaxis").font(.caption.weight(.semibold)) }
                if let e = r.empfehlung { Label(e, systemImage: "lightbulb").font(.caption).foregroundColor(.green) }
            }.padding(8)
        }
    }

    private var datedArgs: [Argument] {
        args.filter { $0.zeitpunkt != nil }
    }

    private func argDate(_ a: Argument) -> Date {
        let f = ISO8601DateFormatter()
        if let z = a.zeitpunkt, let d = f.date(from: z) { return d }
        return Date()
    }

    private func runKiAnalyse() async {
        kiLoading = true; defer { kiLoading = false }
        let prompt = "Analysiere die zeitliche Entwicklung der Argumentstärke. Gib JSON: {trend_einschaetzung, staerke_aktuell, empfehlung}"
        let res = await kiProvider.invokeLLM(prompt: prompt, context: "ArgumentZeitstrahl", caseId: caseId)
        if case .success(let v) = res, let raw = v as? String, let data = raw.data(using: .utf8),
           let result = try? JSONDecoder().decode(KIAnalyse.self, from: data) {
            kiResult = result
        }
    }
}
