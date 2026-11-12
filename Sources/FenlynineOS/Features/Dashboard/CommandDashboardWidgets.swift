import SwiftUI

// MARK: - Widget-Hintergrund (dezent auf Glas-Panel)

private struct LagebildWidgetHintergrund: View {
var cornerRadius: CGFloat = LagebildHRTokens.widgetRadius

var body: some View {
  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    .fill(MacOSSettingsTokens.groupFill)
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(MacOSSettingsTokens.groupStroke, lineWidth: 0.5)
    )
}
}

// MARK: - HR-Dashboard Widgets (Vision Pro Referenz -- Bild 3)

struct LagebildHRWidget<Content: View>: View {
let titel: String
var minHoehe: CGFloat? = nil
@ViewBuilder let content: () -> Content

var body: some View {
  VStack(alignment: .leading, spacing: 8) {
    Text(titel.uppercased())
      .font(LagebildHRTokens.widgetTitle)
      .foregroundStyle(LagebildHRTokens.textSecondary)
      .tracking(0.8)
    content()
  }
  .padding(LagebildHRTokens.widgetPadding)
  .frame(maxWidth: .infinity, minHeight: minHoehe, alignment: .topLeading)
  .background { LagebildWidgetHintergrund() }
}
}

struct LagebildHRKPIMiniCard: View {
let titel: String
let wert: String
let trend: Double?
var trendLabel: String = ""
var action: (() -> Void)? = nil

var body: some View {
  let card = VStack(alignment: .leading, spacing: 6) {
    Text(titel.uppercased())
      .font(LagebildHRTokens.kpiLabel)
      .foregroundStyle(LagebildHRTokens.textSecondary)
      .lineLimit(2)
      .fixedSize(horizontal: false, vertical: true)
    Text(wert)
      .font(LagebildHRTokens.kpiValue)
      .foregroundStyle(LagebildHRTokens.textPrimary)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
    if let trend {
      HStack(spacing: 3) {
        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
          .font(.system(size: 8, weight: .bold))
        Text(trendLabel.isEmpty ? String(format: "%.1f%%", abs(trend)) : trendLabel)
          .font(LagebildHRTokens.trendLabel)
      }
      .foregroundStyle(trend >= 0 ? LagebildHRTokens.successGreen : LagebildHRTokens.alertRed)
    }
  }
  .padding(10)
  .frame(maxWidth: .infinity, alignment: .leading)
  .background { LagebildWidgetHintergrund(cornerRadius: 16) }

  if let action {
    Button(action: action) { card }.buttonStyle(.plain)
  } else {
    card
  }
}
}

struct LagebildHRProgressRow: View {
let label: String
let wert: Double
var farbe: Color = LagebildHRTokens.primaryBlue
var suffix: String? = nil

var body: some View {
  VStack(alignment: .leading, spacing: 4) {
    HStack {
      Text(label)
        .font(LagebildHRTokens.widgetMeta)
        .foregroundStyle(LagebildHRTokens.textSecondary)
        .lineLimit(1)
      Spacer()
      if let suffix {
        Text(suffix)
          .font(LagebildHRTokens.widgetMeta)
          .foregroundStyle(LagebildHRTokens.textPrimary)
      }
    }
   GeometryReader { geo in
     ZStack(alignment: .leading) {
       Capsule().fill(LagebildHRTokens.trackFill)
       Capsule()
         .fill(farbe)
         .frame(width: geo.size.width * CGFloat(min(max(wert, 0), 100) / 100))
     }
   }
   .frame(height: 5)
 }
}
}

struct LagebildHRSchrittZeile: View {
let titel: String
let meta: String
let quelle: String
var onOeffnen: (() -> Void)?

var body: some View {
 HStack(spacing: 8) {
   Circle()
     .fill(LagebildHRTokens.primaryBlue.opacity(0.25))
     .frame(width: 28, height: 28)
     .overlay {
       Image(systemName: quelle == "Strategos" ? "chart.line.uptrend.xyaxis" : "folder.fill")
         .font(.system(size: 11, weight: .semibold))
         .foregroundStyle(LagebildHRTokens.primaryBlue)
     }
   VStack(alignment: .leading, spacing: 1) {
     Text(titel)
       .font(LagebildHRTokens.listTitle)
       .foregroundStyle(LagebildHRTokens.textPrimary)
       .lineLimit(2)
       .fixedSize(horizontal: false, vertical: true)
     Text(meta)
       .font(LagebildHRTokens.listMeta)
       .foregroundStyle(LagebildHRTokens.textSecondary)
       .lineLimit(1)
   }
   Spacer(minLength: 4)
   if let onOeffnen {
     Button("Öffnen", action: onOeffnen)
       .font(.system(size: 9, weight: .semibold))
       .foregroundStyle(LagebildHRTokens.primaryBlue)
       .buttonStyle(.plain)
   }
 }
 .padding(.vertical, 4)
}
}

// MARK: - Command Dashboard Widgets (FENLYNINEOS MOBIL Layout)

struct MachtbalanceRadarChart: View {
let values: [String: Double]
private var axes: [String] {
 let keys = Array(values.keys)
 return keys.isEmpty
   ? ["Recht", "Beweise", "Argumente", "Ressourcen", "Timing", "Öffentliche Wahrnehmung"]
   : keys
}
private var axisCount: Int { max(3, axes.count) }

var body: some View {
 GeometryReader { geo in
   let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
   let radius = min(geo.size.width, geo.size.height) * 0.38

   ZStack {
     ForEach(1...4, id: \.self) { ring in
       radarPolygon(center: center, radius: radius * Double(ring) / 4, values: Array(repeating: 1.0, count: axisCount))
         .stroke(FenlynineOSTheme.border, lineWidth: 1)
     }
     ForEach(0..<axisCount, id: \.self) { i in
       let angle = angleFor(index: i)
       Path { p in
         p.move(to: center)
         p.addLine(to: point(center: center, radius: radius, angle: angle))
       }
       .stroke(FenlynineOSTheme.border, lineWidth: 0.5)
     }
     radarPolygon(center: center, radius: radius, values: axes.map { min(1, (values[$0] ?? 50) / 100) })
       .fill(LagebildHRTokens.primaryBlue.opacity(0.22))
     radarPolygon(center: center, radius: radius, values: axes.map { min(1, (values[$0] ?? 50) / 100) })
       .stroke(LagebildHRTokens.primaryBlue, lineWidth: 1.5)

     ForEach(Array(axes.enumerated()), id: \.offset) { i, label in
       let pt = point(center: center, radius: radius + 16, angle: angleFor(index: i))
       Text(label)
         .font(.system(size: 8, weight: .medium))
         .foregroundStyle(FenlynineOSTheme.textSecondary)
         .position(pt)
     }
   }
 }
 .frame(height: 148)
}

private func angleFor(index: Int) -> Double {
 Double(index) * (.pi * 2 / Double(axisCount)) - .pi / 2
}

private func point(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
 CGPoint(x: center.x + CGFloat(cos(angle) * radius), y: center.y + CGFloat(sin(angle) * radius))
}

private func radarPolygon(center: CGPoint, radius: Double, values: [Double]) -> Path {
 Path { path in
   for (i, v) in values.enumerated() {
     let pt = point(center: center, radius: radius * v, angle: angleFor(index: i))
     if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
   }
   path.closeSubpath()
 }
}
}

struct ZeitplanGanttChart: View {
let phasen: [(name: String, start: Date, end: Date)]

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   if let range = dateRange {
     HStack {
       ForEach(monthLabels(in: range), id: \.self) { m in
         Text(m)
           .font(.system(size: 8, weight: .medium))
           .foregroundStyle(FenlynineOSTheme.textTertiary)
           .frame(maxWidth: .infinity)
       }
     }
     ForEach(Array(phasen.prefix(5).enumerated()), id: \.offset) { _, phase in
       HStack(spacing: 8) {
         Text(phase.name)
           .font(.system(size: 9))
           .foregroundStyle(FenlynineOSTheme.textSecondary)
           .frame(width: 70, alignment: .leading)
         GeometryReader { geo in
           let x = offsetX(phase.start, in: range, width: geo.size.width)
           let w = max(8, width(phase.start, phase.end, in: range, total: geo.size.width))
           RoundedRectangle(cornerRadius: 3)
             .fill(
               LinearGradient(
                 colors: [LagebildHRTokens.primaryBlue, LagebildHRTokens.primaryBlue.opacity(0.65)],
                 startPoint: .leading,
                 endPoint: .trailing
               )
             )
             .frame(width: w, height: 10)
             .offset(x: x)
         }
         .frame(height: 12)
       }
     }
   } else {
     Text("Keine Fristen für Zeitplan")
       .font(.caption2)
       .foregroundStyle(FenlynineOSTheme.textTertiary)
   }
 }
 .frame(height: 96)
}

private var dateRange: (start: Date, end: Date)? {
 guard !phasen.isEmpty else { return nil }
 let starts = phasen.map(\.start)
 let ends = phasen.map(\.end)
 guard let s = starts.min(), let e = ends.max() else { return nil }
 return (s, e)
}

private func offsetX(_ date: Date, in range: (start: Date, end: Date), width: CGFloat) -> CGFloat {
 let total = range.end.timeIntervalSince(range.start)
 guard total > 0 else { return 0 }
 return width * CGFloat(date.timeIntervalSince(range.start) / total)
}

private func width(_ start: Date, _ end: Date, in range: (start: Date, end: Date), total: CGFloat) -> CGFloat {
 let span = range.end.timeIntervalSince(range.start)
 guard span > 0 else { return total * 0.2 }
 return total * CGFloat(end.timeIntervalSince(start) / span)
}

private func monthLabels(in range: (start: Date, end: Date)) -> [String] {
 let fmt = DateFormatter()
 fmt.dateFormat = "MMM"
 var labels: [String] = []
 var d = range.start
 let cal = Calendar.current
 while d <= range.end {
   labels.append(fmt.string(from: d))
   guard let next = cal.date(byAdding: .month, value: 1, to: d) else { break }
   d = next
   if labels.count >= 4 { break }
 }
 return labels
}
}

struct CommandDashboardFooter: View {
let intelligenceCount: Int
let dokumentCount: Int
let freigegebenCount: Int
let simulationCount: Int
var onIntelligence: (() -> Void)?
var onDokumente: (() -> Void)?
var onSimulationen: (() -> Void)?

var body: some View {
 HStack(spacing: 12) {
   footerTile(
     "INTELLIGENCE FEED",
     symbol: "trophy.fill",
     subtitle: intelligenceCount > 0 ? "Neue Erkenntnisse verfügbar" : "Keine neuen Erkenntnisse",
     badge: intelligenceCount > 0 ? "\(intelligenceCount)" : nil,
     action: onIntelligence
   )
   footerTile(
     "DOKUMENTE",
     symbol: "doc.text.fill",
     subtitle: "\(dokumentCount) Dateien | \(freigegebenCount) freigegeben",
     badge: nil,
     action: onDokumente
   )
   footerTile(
     "SIMULATIONEN",
     symbol: "figure.chess",
     subtitle: "\(simulationCount) Szenarien bereit",
     badge: nil,
     action: onSimulationen
   )
 }
}

private func footerTile(_ titel: String, symbol: String, subtitle: String, badge: String?, action: (() -> Void)?) -> some View {
 let content = HStack(spacing: 10) {
   Image(systemName: symbol)
     .font(.system(size: 16, weight: .semibold))
     .foregroundStyle(LagebildHRTokens.primaryBlue)
     .frame(width: 24)
   VStack(alignment: .leading, spacing: 3) {
     Text(titel.uppercased())
       .font(LagebildHRTokens.widgetTitle)
       .foregroundStyle(LagebildHRTokens.textSecondary)
       .tracking(0.6)
     Text(subtitle)
       .font(LagebildHRTokens.listMeta)
       .foregroundStyle(LagebildHRTokens.textPrimary)
       .lineLimit(2)
       .fixedSize(horizontal: false, vertical: true)
   }
   Spacer(minLength: 4)
   if let badge {
     Text(badge)
       .font(.system(size: 10, weight: .bold))
       .foregroundStyle(.white)
       .padding(.horizontal, 7)
       .padding(.vertical, 3)
       .background { VisionOSGlasFlaeche.button(stil: .primaerBlau) }
   }
   if action != nil {
     Image(systemName: "chevron.right")
       .font(.system(size: 9))
       .foregroundStyle(LagebildHRTokens.textTertiary)
   }
 }
 .padding(LagebildHRTokens.widgetPadding)
 .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
 .background { LagebildWidgetHintergrund() }

 if let action {
   return AnyView(Button(action: action) { content }.buttonStyle(.plain))
 }
 return AnyView(content)
}
}

