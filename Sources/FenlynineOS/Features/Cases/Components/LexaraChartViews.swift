import SwiftUI
import Charts

// MARK: - Radar-Diagramm (Polar, wie Recharts RadarChart)

struct LexaraRadarChartView: View {
let data: [(label: String, value: Double)]
var maxValue: Double = 10
var fillColor: Color = Color(red: 0.31, green: 0.53, blue: 0.78)
var strokeColor: Color = Color(red: 0.31, green: 0.53, blue: 0.78)

var body: some View {
  GeometryReader { geo in
    let size = min(geo.size.width, geo.size.height)
    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
    let radius = size * 0.32
    let count = max(data.count, 3)

    ZStack {
      ForEach(1...5, id: \.self) { level in
        radarPolygon(center: center, radius: radius * Double(level) / 5.0, count: count)
          .stroke(Color.gray.opacity(0.15), lineWidth: 1)
      }

      ForEach(0..<count, id: \.self) { i in
        let angle = angleFor(index: i, count: count)
        Path { path in
          path.move(to: center)
          path.addLine(to: point(center: center, radius: radius, angle: angle))
        }
        .stroke(Color.gray.opacity(0.12), lineWidth: 1)
      }

      radarPolygon(center: center, radius: radius, count: count, values: data.map(\.value))
        .fill(fillColor.opacity(0.22))
      radarPolygon(center: center, radius: radius, count: count, values: data.map(\.value))
        .stroke(strokeColor, lineWidth: 2)

      ForEach(Array(data.enumerated()), id: \.offset) { index, item in
        let angle = angleFor(index: index, count: count)
        let labelPoint = point(center: center, radius: radius + 18, angle: angle)
        Text(item.label)
          .font(.system(size: 9))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(width: 70)
          .position(labelPoint)
      }
    }
  }
}

private func angleFor(index: Int, count: Int) -> Double {
  -.pi / 2 + (2 * .pi * Double(index) / Double(count))
}

private func point(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
  CGPoint(
    x: center.x + radius * cos(angle),
    y: center.y + radius * sin(angle)
  )
}

private func radarPolygon(center: CGPoint, radius: Double, count: Int, values: [Double]? = nil) -> Path {
  Path { path in
    for i in 0..<count {
      let value = values?[safe: i] ?? maxValue
      let scaled = radius * min(1, value / maxValue)
      let pt = point(center: center, radius: scaled, angle: angleFor(index: i, count: count))
      if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
  }
}
}

private extension Array {
subscript(safe index: Int) -> Element? {
  indices.contains(index) ? self[index] : nil
}
}

// MARK: - Dual-Radar (Urteil vs. Vergleich, wie ErfolgsMatrix.jsx)

struct LexaraDualRadarChartView: View {
let labels: [String]
let seriesA: [Double]
let seriesB: [Double]
var maxValue: Double = 100
var colorA: Color = .blue
var colorB: Color = .purple

var body: some View {
  GeometryReader { geo in
    let size = min(geo.size.width, geo.size.height)
    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
    let radius = size * 0.30
    let count = max(labels.count, 3)

   ZStack {
     ForEach(1...5, id: \.self) { level in
       dualRadarPolygon(center: center, radius: radius * Double(level) / 5.0, count: count, values: nil)
         .stroke(Color.gray.opacity(0.15), lineWidth: 1)
     }

     dualRadarPolygon(center: center, radius: radius, count: count, values: seriesA)
       .fill(colorA.opacity(0.18))
     dualRadarPolygon(center: center, radius: radius, count: count, values: seriesA)
       .stroke(colorA, lineWidth: 2)

     dualRadarPolygon(center: center, radius: radius, count: count, values: seriesB)
       .fill(colorB.opacity(0.15))
     dualRadarPolygon(center: center, radius: radius, count: count, values: seriesB)
       .stroke(colorB, lineWidth: 2)

     ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
       let angle = dualAngleFor(index: index, count: count)
       Text(label)
         .font(.system(size: 9))
         .foregroundStyle(.secondary)
         .frame(width: 64)
         .position(dualPoint(center: center, radius: radius + 16, angle: angle))
     }

     HStack(spacing: 12) {
       legendDot("Urteil", colorA)
       legendDot("Vergleich", colorB)
     }
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
     .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
   }
 }
}

private func legendDot(_ text: String, _ color: Color) -> some View {
 HStack(spacing: 4) {
   Circle().fill(color).frame(width: 8, height: 8)
   Text(text)
 }
}

private func dualAngleFor(index: Int, count: Int) -> Double {
 -.pi / 2 + (2 * .pi * Double(index) / Double(count))
}

private func dualPoint(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
 CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
}

private func dualRadarPolygon(center: CGPoint, radius: Double, count: Int, values: [Double]?) -> Path {
 Path { path in
   for i in 0..<count {
     let scaled: Double
     if let values {
       let value = values[safe: i] ?? 0
       scaled = radius * min(1, value / maxValue)
     } else {
       scaled = radius
     }
     let pt = dualPoint(center: center, radius: scaled, angle: dualAngleFor(index: i, count: count))
     if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
   }
   path.closeSubpath()
 }
}
}

// MARK: - Strategie-Checkliste Charts (sin, linear, scatter)

struct LexaraPrognoseWaveChart: View {
let prognose: Double

private var data: [(t: Double, y: Double, yLower: Double)] {
 let amp = prognose / 2
 let baseline = prognose
 return (0..<40).map { i in
   let t = Double(i) * 0.4
   let y = baseline + amp * sin(Double(i) * 0.4)
   let yLower = baseline - amp * 0.4 * sin(Double(i) * 0.4 + .pi / 3)
   return (t, y, yLower)
 }
}

var body: some View {
 VStack(spacing: 6) {
   Text("Prognose-Kurve: y(t) = \(Int(prognose)) + \(Int(prognose / 2)) · sin(t)")
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
   Chart {
     ForEach(Array(data.enumerated()), id: \.offset) { _, p in
       LineMark(x: .value("t", p.t), y: .value("P", p.y))
         .foregroundStyle(.indigo)
       LineMark(x: .value("t", p.t), y: .value("Risiko", p.yLower))
         .foregroundStyle(.red.opacity(0.6))
         .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
     }
     RuleMark(y: .value("50%", 50))
       .foregroundStyle(.orange.opacity(0.5))
       .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
     RuleMark(y: .value("Prognose", prognose))
       .foregroundStyle(.green.opacity(0.6))
       .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
   }
   .chartYScale(domain: 0...100)
   .chartXAxisLabel("Zeitachse t")
   .chartYAxisLabel("P(%)")
   .frame(height: 200)
 }
}
}

struct LexaraLinearStrategieChart: View {
let argCount: Int
let prognose: Double

private var slope: Double { prognose > 50 ? 2.1 : 1.2 }
private var intercept: Double { max(5, prognose - Double(argCount) * (prognose > 50 ? 2.1 : 1.2)) }

private var data: [(x: Int, y: Double)] {
 (0..<15).map { x in (x, slope * Double(x) + intercept) }
}

var body: some View {
 VStack(spacing: 6) {
   Text("Strategische Steigung: f(x) = \(String(format: "%.1f", slope))·x + \(Int(intercept))")
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
   Chart(data, id: \.x) { p in
     LineMark(x: .value("x", p.x), y: .value("f(x)", p.y))
       .foregroundStyle(.blue)
   }
   .chartYScale(domain: 0...100)
   .chartXAxisLabel("Argumente (x)")
   .chartYAxisLabel("Strategiewert")
   .frame(height: 200)
 }
}
}

struct LexaraArgumentScatterChart: View {
let argumente: [Argument]
let beweise: [Evidence]

struct ScatterPunkt: Identifiable {
 let id = UUID()
 let name: String
 let x: Double
 let y: Double
 let z: CGFloat
 let isEigen: Bool
}

private var punkte: [ScatterPunkt] {
 argumente.prefix(12).enumerated().map { i, arg in
   let linked = beweise.filter { ($0.linked_argument_ids ?? []).contains(arg.id ?? "") }
   let evCount = linked.count
   let avgWeight = evCount > 0
     ? linked.reduce(0.0) { $0 + Double($1.weight) } / Double(evCount)
     : 0.0
   return ScatterPunkt(
     name: String(arg.title.prefix(14)),
     x: Double(arg.strength),
     y: avgWeight,
     z: CGFloat(evCount * 15 + 10),
     isEigen: arg.side == .eigen
   )
 }
}

var body: some View {
 VStack(spacing: 6) {
   Text("X = Argumentstärke · Y = Ø Beweisgewicht · Blasengröße = Beweisanzahl")
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
   Chart {
     ForEach(punkte.filter(\.isEigen)) { p in
       PointMark(x: .value("Stärke", p.x), y: .value("Beweis-Ø", p.y))
         .foregroundStyle(.green)
         .symbolSize(p.z)
     }
     ForEach(punkte.filter { !$0.isEigen }) { p in
       PointMark(x: .value("Stärke", p.x), y: .value("Beweis-Ø", p.y))
         .foregroundStyle(.red)
         .symbolSize(p.z)
     }
   }
   .chartXScale(domain: 0...10)
   .chartYScale(domain: 0...10)
   .chartXAxisLabel("Arg-Stärke")
   .chartYAxisLabel("Beweis-Ø")
   .frame(height: 260)
   HStack(spacing: 16) {
     Label("Eigene", systemImage: "circle.fill").font(.caption).foregroundStyle(.green)
     Label("Gegner", systemImage: "circle.fill").font(.caption).foregroundStyle(.red)
   }
 }
}
}

// MARK: - Beweis-Matrix (wie BeweismatrixChart.jsx)

struct BeweismatrixChartView: View {
let argumente: [Argument]
let beweise: [Evidence]

private var eigenArgs: [Argument] { argumente.filter { $0.side == .eigen } }
private var gegnerArgs: [Argument] { argumente.filter { $0.side == .gegner } }

var body: some View {
 if argumente.isEmpty || beweise.isEmpty { EmptyView() }
 else {
   VStack(alignment: .leading, spacing: 12) {
     HStack {
       Label("Beweis-Matrix", systemImage: "chart.bar.doc.horizontal")
         .font(.system(size: 13, weight: .semibold))
       Spacer()
       HStack(spacing: 12) {
         legendChip("Eigene: \(totalEigen) Beweise", .blue)
         legendChip("Gegner: \(totalGegner) Beweise", .red)
         if unlinked > 0 {
           Text("nn \(unlinked) unverknüpft")
             .font(.system(size: 10, weight: .semibold))
             .foregroundStyle(.orange)
         }
       }
     }

     if !eigenArgs.isEmpty {
       Text("EIGENE ARGUMENTE")
         .font(.system(size: 9, weight: .bold))
         .foregroundStyle(.blue.opacity(0.7))
       ForEach(eigenArgs) { arg in
         matrixRow(arg)
       }
     }

     if !gegnerArgs.isEmpty {
       Text("GEGNER-ARGUMENTE")
         .font(.system(size: 9, weight: .bold))
         .foregroundStyle(.red.opacity(0.7))
         .padding(.top, 4)
       ForEach(gegnerArgs) { arg in
         matrixRow(arg)
       }
     }

     Text("Balkenbreite = relative Beweisdichte · n = einzelner Beweis")
       .font(.system(size: 9))
       .foregroundStyle(.tertiary)
       .padding(.top, 4)
   }
   .padding(14)
   .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
   .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1)))
 }
}

private var maxEv: Int {
 max(argumente.map { beweiseFuer(arg: $0).count }.max() ?? 1, 1)
}

private var totalEigen: Int {
 eigenArgs.reduce(0) { $0 + beweiseFuer(arg: $1).count }
}

private var totalGegner: Int {
 gegnerArgs.reduce(0) { $0 + beweiseFuer(arg: $1).count }
}

private var unlinked: Int {
 beweise.filter { ev in
   let linkedToArg = (ev.linked_argument_ids ?? []).isEmpty == false
   let inArgList = argumente.contains { ($0.linked_evidence_ids ?? []).contains(ev.id ?? "") }
   return !linkedToArg && !inArgList
 }.count
}

private func beweiseFuer(arg: Argument) -> [Evidence] {
 let byId = (arg.linked_evidence_ids ?? []).compactMap { id in
   beweise.first { $0.id == id }
 }
 let byRef = beweise.filter { ev in
   (ev.linked_argument_ids ?? []).contains(arg.id ?? "")
     && !byId.contains(where: { $0.id == ev.id })
 }
 return byId + byRef
}

@ViewBuilder
private func matrixRow(_ arg: Argument) -> some View {
 let evs = beweiseFuer(arg: arg)
 let density = Double(evs.count) / Double(maxEv)
 let isEigen = arg.side == .eigen
 let barColor: Color = isEigen ? .blue : .red

 HStack(spacing: 10) {
   Text(arg.title)
     .font(.system(size: 11, weight: .medium))
     .foregroundStyle(isEigen ? .blue : .red)
     .multilineTextAlignment(.trailing)
     .lineLimit(2)
     .frame(width: 130, alignment: .trailing)

   GeometryReader { geo in
     ZStack(alignment: .leading) {
       Capsule().fill(Color.gray.opacity(0.12))
       Capsule()
         .fill(barColor)
         .frame(width: max(evs.isEmpty ? 0 : 8, geo.size.width * density))
     }
   }
   .frame(height: 10)

   Text("\(evs.count)")
     .font(.system(size: 11, weight: .bold))
     .foregroundStyle(isEigen ? .blue : .red)
     .frame(width: 16, alignment: .trailing)

   HStack(spacing: 2) {
     ForEach(Array(evs.prefix(5).enumerated()), id: \.offset) { _, ev in
       RoundedRectangle(cornerRadius: 2)
         .fill(isEigen ? Color.blue.opacity(0.25) : Color.red.opacity(0.2))
         .frame(width: 10, height: 10)
         .overlay(RoundedRectangle(cornerRadius: 2).stroke(isEigen ? Color.blue : Color.red.opacity(0.5), lineWidth: 0.5))
         .help(ev.title)
     }
     if evs.count > 5 {
       Text("+\(evs.count - 5)").font(.system(size: 8)).foregroundStyle(.secondary)
     }
     if evs.isEmpty {
       Text("kein Beweis").font(.system(size: 8)).foregroundStyle(.tertiary).italic()
     }
   }
   .frame(maxWidth: 90, alignment: .leading)
 }
 .padding(.vertical, 3)
}

private func legendChip(_ text: String, _ color: Color) -> some View {
 HStack(spacing: 4) {
   Circle().fill(color).frame(width: 8, height: 8)
   Text(text).font(.system(size: 10, weight: .semibold)).foregroundStyle(color)
 }
}
}

// MARK: - Scatter-Quadrant (Chancen/Risiko, wie Recharts ScatterChart)

struct LexaraScatterQuadrantView: View {
struct Punkt: Identifiable {
 let id = UUID()
 let name: String
 let x: Double
 let y: Double
 let color: Color
}

let title: String
let subtitle: String
let punkte: [Pkt]
var xLabel: String = "Wahrscheinlichkeit ->"
var yLabel: String = "Wirkungstiefe ›"
var xDomain: ClosedRange<Double> = 0...100
var yDomain: ClosedRange<Double> = 0...10
var xMid: Double = 50
var yMid: Double = 5
var topLeftLabel: String = "TAIL-RISK"
var topRightLabel: String = "VERMEIDEN"
var bottomLeftLabel: String = "VERNACHL."
var bottomRightLabel: String = "MONITOREN"
var fazit: String? = nil
var prioritaet: String? = nil

typealias Pkt = Punkt

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   VStack(alignment: .leading, spacing: 2) {
     Text(title.uppercased())
       .font(.system(size: 10, weight: .bold))
       .foregroundStyle(.blue)
     Text(subtitle)
       .font(.system(size: 11))
       .foregroundStyle(.secondary)
   }

   HStack {
     Text(topLeftLabel).font(.system(size: 9, weight: .heavy)).foregroundStyle(.orange)
     Spacer()
     Text(topRightLabel).font(.system(size: 9, weight: .heavy)).foregroundStyle(.red)
   }
   .padding(.horizontal, 8)

   Chart {
     ForEach(punkte) { p in
       PointMark(
         x: .value("X", p.x),
         y: .value("Y", p.y)
       )
       .foregroundStyle(p.color)
       .symbolSize(punkte.count == 1 ? 180 : 120)
       .annotation(position: .top, spacing: 2) {
         Text(p.name)
           .font(.system(size: 8, weight: .semibold))
           .foregroundStyle(.secondary)
           .lineLimit(1)
       }
     }
     RuleMark(x: .value("Mitte X", xMid))
       .foregroundStyle(Color.gray.opacity(0.25))
       .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
     RuleMark(y: .value("Mitte Y", yMid))
       .foregroundStyle(Color.gray.opacity(0.25))
       .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
   }
   .chartXScale(domain: xDomain)
   .chartYScale(domain: yDomain)
   .chartXAxisLabel(xLabel, position: .bottom)
   .chartYAxisLabel(yLabel, position: .leading)
   .frame(height: 240)

   HStack {
     Text(bottomLeftLabel).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
     Spacer()
     Text(bottomRightLabel).font(.system(size: 9, weight: .bold)).foregroundStyle(.blue)
   }
   .padding(.horizontal, 8)

   if !punkte.isEmpty {
     FlowLayout(spacing: 10) {
       ForEach(punkte) { p in
         HStack(spacing: 4) {
           Circle().fill(p.color).frame(width: 8, height: 8)
           Text(p.name).font(.system(size: 10)).foregroundStyle(.secondary)
         }
       }
     }
   }

   if let fazit {
     Text("n \(fazit)")
       .font(.system(size: 10))
       .foregroundStyle(.blue)
       .padding(10)
       .frame(maxWidth: .infinity, alignment: .leading)
       .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
   }
   if let prioritaet {
     Text("n \(prioritaet)")
       .font(.system(size: 10, weight: .semibold))
       .foregroundStyle(.red)
       .padding(10)
       .frame(maxWidth: .infinity, alignment: .leading)
       .background(Color.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
   }
 }
 .padding(14)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
}
}

// MARK: - Akteurs-Analytik (wie AkteureAnalytik.jsx)

struct AkteureAnalytikView: View {
@State private var profile: [JudgeProfile] = []
@State private var laden = true
@State private var katFilter = "Alle"
@State private var sortBy = "klaeger_rate"

private let kategorien = ["Alle", "Richter", "Anwalt", "Kanzlei", "Sachverstaendiger", "Partei"]

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   HStack {
     Label("Akteurs-Erfolgsraten", systemImage: "person.2.fill")
       .font(.headline)
     Spacer()
     Text("\(profile.count) Profile")
       .font(.caption)
       .foregroundStyle(.secondary)
   }

   if laden {
     ProgressView().frame(maxWidth: .infinity).padding(.vertical, 24)
   } else if profile.isEmpty {
     InfoHinweis(
       titel: "Noch keine Akteur-Profile",
       nachricht: "Legen Sie Profile unter Prozessbeteiligte an.",
       symbol: "person.2"
     )
   } else {
     topCards

     HStack {
       Picker("Kategorie", selection: $katFilter) {
         ForEach(kategorien, id: \.self) { Text($0).tag($0) }
       }
       .pickerStyle(.menu)
       Picker("Sortierung", selection: $sortBy) {
         Text("Klägerquote").tag("klaeger_rate")
         Text("Vergleichsrate").tag("vergleich_rate")
       }
       .pickerStyle(.menu)
     }

     if !chartData.isEmpty {
       DashboardCard(titel: "Erfolgsraten (Balken)", symbol: "chart.bar.fill") {
         Chart(chartData) { row in
           BarMark(x: .value("Klägerquote", row.klaeger), y: .value("Name", row.name))
             .foregroundStyle(row.color)
           BarMark(x: .value("Vergleich", row.vergleich), y: .value("Name", row.name))
             .foregroundStyle(Color.purple.opacity(0.55))
         }
         .frame(height: CGFloat(chartData.count * 28 + 40))
       }
     }

     if !scatterData.isEmpty {
       DashboardCard(titel: "Klägerquote vs. Vergleichsrate (Scatter)", symbol: "chart.xyaxis.line") {
         Chart(scatterData) { row in
           PointMark(
             x: .value("Klägerquote", row.x),
             y: .value("Vergleichsrate", row.y)
           )
           .foregroundStyle(row.color)
           .symbolSize(max(40, row.z))
         }
         .chartXScale(domain: 0...100)
         .chartYScale(domain: 0...100)
         .chartXAxisLabel("Klägerquote (%)")
         .chartYAxisLabel("Vergleichsrate (%)")
         .frame(height: 220)
       }
     }
   }
 }
 .task { await ladenDaten() }
}

private var gefiltert: [JudgeProfile] {
 profile
   .filter { katFilter == "Alle" || ($0.kategorie ?? "Richter") == katFilter }
   .filter { $0.klaeger_rate != nil || $0.vergleich_rate != nil }
   .sorted { ($0.value(for: sortBy) ?? 0) > ($1.value(for: sortBy) ?? 0) }
   .prefix(15)
   .map { $0 }
}

private struct ChartRow: Identifiable {
 let id = UUID()
 let name: String
 let klaeger: Double
 let vergleich: Double
 let color: Color
}

private var chartData: [ChartRow] {
 gefiltert.map { p in
   ChartRow(
     name: String(p.name.prefix(14)),
     klaeger: p.klaeger_rate ?? 0,
     vergleich: p.vergleich_rate ?? 0,
     color: kategorieFarbe(p.kategorie)
   )
 }
}

private struct ScatterRow: Identifiable {
 let id = UUID()
 let x: Double
 let y: Double
 let z: CGFloat
 let color: Color
}

private var scatterData: [ScatterRow] {
 profile
   .filter { $0.klaeger_rate != nil && $0.vergleich_rate != nil }
   .map { p in
     ScatterRow(
       x: p.klaeger_rate ?? 0,
       y: p.vergleich_rate ?? 0,
       z: CGFloat((p.urteile_gesamt ?? 1) * 8),
       color: kategorieFarbe(p.kategorie)
     )
   }
}

@ViewBuilder
private var topCards: some View {
 let topKlaeger = profile.filter { ($0.klaeger_rate ?? 0) > 0 }.sorted { ($0.klaeger_rate ?? 0) > ($1.klaeger_rate ?? 0) }.prefix(3)
 let topVergleich = profile.filter { ($0.vergleich_rate ?? 0) > 0 }.sorted { ($0.vergleich_rate ?? 0) > ($1.vergleich_rate ?? 0) }.prefix(3)
 let risk = profile.filter { ($0.klaeger_rate ?? 100) < 35 }.prefix(3)

 LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
   akteurKarte("Top Klägerquote", topKlaeger.map { ($0.name, Int($0.klaeger_rate ?? 0)) }, .green)
   akteurKarte("Top Vergleichsrate", topVergleich.map { ($0.name, Int($0.vergleich_rate ?? 0)) }, .purple)
   akteurKarte("Risiko-Akteure", risk.map { ($0.name, Int($0.klaeger_rate ?? 0)) }, .red)
 }
}

private func akteurKarte(_ titel: String, _ rows: [(String, Int)], _ farbe: Color) -> some View {
 VStack(alignment: .leading, spacing: 6) {
   Text(titel.uppercased())
     .font(.system(size: 9, weight: .bold))
     .foregroundStyle(farbe)
   if rows.isEmpty {
     Text("--").font(.caption).foregroundStyle(.secondary)
   } else {
     ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
       HStack {
         Text(row.0).font(.caption).lineLimit(1)
         Spacer()
         Text("\(row.1)%").font(.caption.bold()).foregroundStyle(farbe)
       }
     }
   }
 }
 .padding(10)
 .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
}

private func kategorieFarbe(_ kat: String?) -> Color {
 switch kat ?? "Richter" {
 case "Richter": return Color(red: 0.10, green: 0.21, blue: 0.38)
 case "Anwalt": return .blue
 case "Kanzlei": return .purple
 case "Zeuge": return .orange
 case "Sachverstaendiger": return .green
 case "Partei": return .red
 default: return .gray
 }
}

private func ladenDaten() async {
 laden = true
 profile = (try? await Services.judgeProfiles.list()) ?? []
 laden = false
}
}

private extension JudgeProfile {
func value(for key: String) -> Double? {
 key == "vergleich_rate" ? vergleich_rate : klaeger_rate
}
}

