import SwiftUI
import Charts
struct SubstanzDiagrammeView: View {
    let viewModel: CaseDetailViewModel
    @State private var viewMode = "bar"
    private var args: [Argument] { viewModel.argumente }
    private var evidence: [Evidence] { viewModel.beweise }
    private var eigenArgs: [Argument] { args.filter { $0.side == .eigen } }
    private var gegnerArgs: [Argument] { args.filter { $0.side == .gegner } }
    private let matteEigen = Color(red: 0.31, green: 0.53, blue: 0.78)
    private let matteGegner = Color(red: 0.75, green: 0.40, blue: 0.42)
    private let matteKi = Color(red: 0.36, green: 0.67, blue: 0.49)
    private let matteManual = Color(red: 0.69, green: 0.49, blue: 0.78)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Stärken-Analyse", systemImage: "chart.bar.fill")
                .font(.title2.bold())
            Text("Argumente & Beweise als interaktive Diagramme")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                SubstanzStatChip(label: "Ø eigene Args", wert: avgText(eigenArgs), farbe: matteEigen)
                SubstanzStatChip(label: "Ø Gegner Args", wert: avgText(gegnerArgs), farbe: matteGegner)
                SubstanzStatChip(label: "Ø Beweis-Gewicht", wert: avgEvidenceText(), farbe: matteKi)
                SubstanzStatChip(label: "Widersprüche", wert: "0", farbe: .gray)
            }
            Picker("Ansicht", selection: $viewMode) {
                Text("Stärken-Balken").tag("bar")
                Text("Typen-Radar").tag("radar")
                Text("KI-Abweichung").tag("discrepancy")
            }
            .pickerStyle(.segmented)
            switch viewMode {
            case "radar": radarSection
            case "discrepancy": discrepancySection
            default: barSection
            }
            if args.isEmpty && evidence.isEmpty {
                InfoHinweis(titel: "Keine Substanz-Daten", nachricht: "Erfassen Sie Argumente und Beweise im Reiter Substanz.", symbol: "chart.bar")
            }
        }
    }
    @ViewBuilder
    private var barSection: some View {
        if !argBarData.isEmpty {
            chartCard(titel: "Argumente — Stärke (manuell vs. KI)", symbol: "scalemass.fill", symbolColor: .blue) {
                Chart(argBarData) { row in
                    BarMark(x: .value("Manuell", row.manuell), y: .value("Arg", row.name))
                        .foregroundStyle(row.side == .eigen ? matteEigen : matteGegner)
                    if let ki = row.ki {
                        BarMark(x: .value("KI", ki), y: .value("Arg", row.name))
                            .foregroundStyle(matteKi)
                    }
                }
                .frame(height: CGFloat(argBarData.count * 34 + 20))
            }
        }
        if !evBarData.isEmpty {
            chartCard(titel: "Beweise — Gewicht (manuell vs. KI)", symbol: "shield.fill", symbolColor: .purple) {
                Chart(evBarData) { row in
                    BarMark(x: .value("Manuell", row.manuell), y: .value("Beweis", row.name))
                        .foregroundStyle(matteManual)
                    if let ki = row.ki {
                        BarMark(x: .value("KI", ki), y: .value("Beweis", row.name))
                            .foregroundStyle(matteKi)
                    }
                }
                .frame(height: CGFloat(evBarData.count * 34 + 20))
            }
        }
    }
    @ViewBuilder
    private var radarSection: some View {
        chartCard(titel: "Durchschnittsstärke nach Argumenttyp", symbol: "chart.line.uptrend.xyaxis", symbolColor: matteKi) {
            if radarData.count >= 3 {
                LexaraRadarChartView(
                    data: radarData,
                    maxValue: 10,
                    fillColor: matteEigen,
                    strokeColor: matteEigen
                )
                .frame(height: 320)
            } else {
                Text("Mindestens 3 verschiedene Argumenttypen benötigt für Radar-Ansicht.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            }
        }
    }
    @ViewBuilder
    private var discrepancySection: some View {
        chartCard(titel: "Größte Abweichungen: Manuell vs. KI-Bewertung", symbol: "exclamationmark.triangle.fill", symbolColor: .orange) {
            if discrepancyData.isEmpty {
                Text("Keine KI-bewerteten Argumente vorhanden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(discrepancyData) { row in
                    BarMark(x: .value("Manuell", row.manuell), y: .value("Arg", row.name))
                        .foregroundStyle(row.side == .eigen ? matteEigen : matteGegner)
                    BarMark(x: .value("KI", row.ki), y: .value("Arg", row.name))
                        .foregroundStyle(matteKi)
                }
                .frame(height: CGFloat(discrepancyData.count * 38 + 20))
                Text("Sortiert nach größter Abweichung (Top 10). Abweichungen ≥ 4 gelten als Compliance-Hinweis.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }
    private struct BarRow: Identifiable {
        let id = UUID()
        let name: String
        let manuell: Double
        let ki: Double?
        let side: Argument.ArgumentSeite?
    }
    private struct DiscRow: Identifiable {
        let id = UUID()
        let name: String
        let manuell: Double
        let ki: Double
        let side: Argument.ArgumentSeite
    }
    private var argBarData: [BarRow] {
        args.prefix(12).map { a in
            BarRow(
                name: truncate(a.title, max: 18),
                manuell: Double(a.strength),
                ki: a.ki_strength,
                side: a.side
            )
        }
    }
    private var evBarData: [BarRow] {
        evidence.prefix(10).map { e in
            BarRow(
                name: truncate(e.title, max: 18),
                manuell: Double(e.weight),
                ki: e.ki_weight,
                side: nil
            )
        }
    }
    private var radarData: [(label: String, value: Double)] {
        var typeMap: [String: (count: Int, total: Double)] = [:]
        for a in args {
            let t = a.type ?? "Sonstig"
            var entry = typeMap[t] ?? (0, 0)
            entry.count += 1
            entry.total += a.ki_strength ?? Double(a.strength)
            typeMap[t] = entry
        }
        return typeMap.map { key, val in
            (truncate(key, max: 14), val.total / Double(val.count))
        }
    }
    private var discrepancyData: [DiscRow] {
        args
            .filter { $0.ki_strength != nil }
            .map { a in
                DiscRow(
                    name: truncate(a.title, max: 20),
                    manuell: Double(a.strength),
                    ki: a.ki_strength ?? 0,
                    side: a.side
                )
            }
            .sorted { abs($0.manuell - $0.ki) > abs($1.manuell - $1.ki) }
            .prefix(10)
            .map { $0 }
    }
    private func avgText(_ list: [Argument]) -> String {
        guard !list.isEmpty else { return "–" }
        let avg = list.reduce(0.0) { $0 + ($1.ki_strength ?? Double($1.strength)) } / Double(list.count)
        return String(format: "%.1f", avg)
    }
    private func avgEvidenceText() -> String {
        guard !evidence.isEmpty else { return "–" }
        let avg = evidence.reduce(0.0) { $0 + ($1.ki_weight ?? Double($1.weight)) } / Double(evidence.count)
        return String(format: "%.1f", avg)
    }
    private func truncate(_ text: String, max: Int) -> String {
        text.count > max ? String(text.prefix(max)) + "…" : text
    }
    @ViewBuilder
    private func chartCard<Content: View>(titel: String, symbol: String, symbolColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(titel, systemImage: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.multicolor)
            content()
        }
        .padding(14)
        .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1)))
    }
}
private struct SubstanzStatChip: View {
    let label: String
    let wert: String
    let farbe: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(wert).font(.headline.bold()).foregroundStyle(farbe)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(farbe.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
