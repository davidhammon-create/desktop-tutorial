import SwiftUI

// MARK: - Wiederverwendbare Opportunisma-Widgets (Mockup-Stil)

struct PragWidgetCard<Content: View>: View {
let titel: String
var transparenz: TransparenzInhalt? = nil
@Environment(\.opportunismaProMode) private var proMode
@ViewBuilder let content: () -> Content

var body: some View {
  VStack(alignment: .leading, spacing: 10) {
    HStack(spacing: 6) {
      Text(proMode ? titel : titel.uppercased())
        .font(proMode ? OpportunismaPro.section : OpportunismaTheme.widgetTitle)
        .foregroundStyle(proMode ? OpportunismaPro.text : OpportunismaTheme.ink)
        .tracking(proMode ? 0.3 : 0)
      Spacer()
      if let t = transparenz {
        FenlynineOSTransparenzInfoButton(inhalt: t)
      }
    }
    content()
  }
  .padding(proMode ? 14 : 12)
  .background(
    proMode ? OpportunismaPro.raised : (OpportunismaTheme.card),
    in: RoundedRectangle(cornerRadius: proMode ? OpportunismaPro.radius : OpportunismaTheme.cornerRadius, style: .continuous)
  )
  .overlay(
    RoundedRectangle(cornerRadius: proMode ? OpportunismaPro.radius : OpportunismaTheme.cornerRadius, style: .continuous)
      .stroke(proMode ? OpportunismaPro.hairline : OpportunismaTheme.line, lineWidth: 1)
  )
}
}

struct PragHorizontalBars: View {
let items: [PragBarItem]
var maxWert: Int = 100
var barColor: Color = OpportunismaTheme.red

var body: some View {
  VStack(alignment: .leading, spacing: 8) {
    ForEach(items) { item in
      HStack(spacing: 8) {
        Text(item.name)
          .font(OpportunismaTheme.captionFont)
          .foregroundStyle(OpportunismaTheme.gray)
          .frame(width: 110, alignment: .leading)
          .lineLimit(2)
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule().fill(OpportunismaTheme.grayLight)
            Capsule()
              .fill(barColor)
              .frame(width: geo.size.width * CGFloat(item.wert) / CGFloat(maxWert))
          }
        }
        .frame(height: 8)
        Text("\(item.wert)%")
          .font(.system(size: 9, weight: .bold, design: .monospaced))
          .foregroundStyle(OpportunismaTheme.ink)
          .frame(width: 32, alignment: .trailing)
      }
    }
  }
}
}

struct PragDominanzGauge: View {
let wert: Int
var label: String = "POSITION"

var body: some View {
  VStack(spacing: 8) {
    ZStack {
      Circle()
        .stroke(OpportunismaTheme.grayLight, lineWidth: 10)
        .frame(width: 100, height: 100)
      Circle()
        .trim(from: 0, to: CGFloat(wert) / 100)
        .stroke(OpportunismaTheme.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
        .frame(width: 100, height: 100)
        .rotationEffect(.degrees(-90))
      VStack(spacing: 0) {
        Text("\(wert)%")
          .font(.system(size: 22, weight: .black, design: .rounded))
          .foregroundStyle(OpportunismaTheme.red)
        Text(label)
          .font(.system(size: 8, weight: .bold))
          .foregroundStyle(OpportunismaTheme.gray)
      }
    }
  }
}
}

struct PragRadarPanel: View {
let data: [(label: String, value: Double)]
var maxValue: Double = 10

var body: some View {
 LexaraRadarChartView(
   data: data,
   maxValue: maxValue,
   fillColor: OpportunismaTheme.red,
   strokeColor: OpportunismaTheme.redDark
 )
 .frame(height: 180)
}
}

struct PragDualRadarPanel: View {
let data: [(label: String, ist: Double, soll: Double)]

var body: some View {
 GeometryReader { geo in
   let size = min(geo.size.width, geo.size.height)
   let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
   let radius = size * 0.32
   let count = max(data.count, 3)

   ZStack {
     ForEach(1...4, id: \.self) { level in
       pragPolygon(center: center, radius: radius * Double(level) / 4, count: count, values: nil)
         .stroke(OpportunismaTheme.line, lineWidth: 1)
     }
     pragPolygon(center: center, radius: radius, count: count, values: data.map(\.soll))
       .stroke(OpportunismaTheme.ink, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
     pragPolygon(center: center, radius: radius, count: count, values: data.map(\.ist))
       .fill(OpportunismaTheme.red.opacity(0.2))
     pragPolygon(center: center, radius: radius, count: count, values: data.map(\.ist))
       .stroke(OpportunismaTheme.red, lineWidth: 2)
   }
 }
}

private func pragPolygon(center: CGPoint, radius: Double, count: Int, values: [Double]?) -> Path {
 Path { path in
   for i in 0..<count {
     let v = values?[safe: i] ?? 10
     let scaled = radius * min(1, v / 10)
     let angle = -.pi / 2 + (2 * .pi * Double(i) / Double(count))
     let pt = CGPoint(x: center.x + scaled * cos(angle), y: center.y + scaled * sin(angle))
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

struct PragRisikoHeatmap: View {
let matrix: [[Int]]

var body: some View {
 VStack(spacing: 2) {
   HStack {
     Spacer()
     Text("Auswirkung ->").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
   }
   ForEach(0..<matrix.count, id: \.self) { row in
     HStack(spacing: 2) {
       ForEach(0..<matrix[row].count, id: \.self) { col in
         let val = matrix[row][col]
         ZStack {
           RoundedRectangle(cornerRadius: 4, style: .continuous)
             .fill(OpportunismaTheme.red.opacity(val == 0 ? 0.05 : Double(val) / 8.0))
           if val > 0 {
             Text("\(val)")
               .font(.system(size: 9, weight: .bold))
               .foregroundStyle(val >= 4 ? .white : OpportunismaTheme.ink)
           }
         }
         .frame(height: 28)
       }
     }
   }
   Text("› Eintrittswahrscheinlichkeit").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
 }
}
}

struct PragPyramid: View {
let stufen: [String]

var body: some View {
 VStack(spacing: 0) {
   ForEach(Array(stufen.enumerated()), id: \.offset) { idx, stufe in
     let widthFrac = 0.35 + Double(idx) * 0.13
     Text(stufe)
       .font(.system(size: 8, weight: .bold))
       .foregroundStyle(.white)
       .frame(maxWidth: .infinity)
       .padding(.vertical, 6)
       .background(
         OpportunismaTheme.red.opacity(0.45 + Double(idx) * 0.11),
         in: RoundedRectangle(cornerRadius: 6, style: .continuous)
       )
       .scaleEffect(x: widthFrac, y: 1, anchor: .center)
   }
 }
 .frame(maxWidth: .infinity)
}
}

struct PragNetzwerkGraph: View {
let knoten: [PragNetzKnoten]
let kanten: [PragNetzKante]

var body: some View {
 GeometryReader { geo in
   let map = Dictionary(uniqueKeysWithValues: knoten.map { ($0.label, $0) })
   ZStack {
     ForEach(kanten) { k in
       if let a = map[k.von], let b = map[k.zu] {
         Path { path in
           path.move(to: pt(a, geo.size))
           path.addLine(to: pt(b, geo.size))
         }
         .stroke(OpportunismaTheme.line, lineWidth: 1)
       }
     }
     ForEach(knoten) { n in
       Circle()
         .fill(farbe(n.typ))
         .frame(width: n.label == "UNTERNEHMEN" ? 28 : 20, height: n.label == "UNTERNEHMEN" ? 28 : 20)
         .overlay(Circle().stroke(OpportunismaTheme.ink, lineWidth: n.label == "UNTERNEHMEN" ? 2 : 0))
         .position(pt(n, geo.size))
       Text(n.label)
         .font(.system(size: 7, weight: .bold))
         .position(x: pt(n, geo.size).x, y: pt(n, geo.size).y + 16)
     }
   }
 }
}

private func pt(_ n: PragNetzKnoten, _ size: CGSize) -> CGPoint {
 CGPoint(x: n.x * size.width, y: n.y * size.height)
}

private func farbe(_ typ: String) -> Color {
 switch typ {
 case "kontrolliert": return OpportunismaTheme.red
 case "verbündet": return OpportunismaTheme.ink
 case "feindlich": return OpportunismaTheme.red.opacity(0.4)
 default: return OpportunismaTheme.grayLight
 }
}
}

struct PragGantt: View {
let meilensteine: [PragMeilenstein]
var gesamtMonate: Int = 10

var body: some View {
 VStack(alignment: .leading, spacing: 6) {
   ForEach(meilensteine) { m in
     HStack(spacing: 8) {
       Text(m.titel)
         .font(.system(size: 8))
         .foregroundStyle(OpportunismaTheme.gray)
         .frame(width: 100, alignment: .leading)
         .lineLimit(1)
       GeometryReader { geo in
         let w = geo.size.width / CGFloat(gesamtMonate)
         RoundedRectangle(cornerRadius: 3, style: .continuous)
           .fill(OpportunismaTheme.red)
           .frame(width: w * CGFloat(m.dauer), height: 10)
           .offset(x: w * CGFloat(m.start))
       }
       .frame(height: 10)
     }
   }
   HStack {
     ForEach(0..<gesamtMonate, id: \.self) { i in
       Text("M\(i + 1)")
         .font(.system(size: 7))
         .foregroundStyle(OpportunismaTheme.gray)
         .frame(maxWidth: .infinity)
     }
   }
 }
}
}

struct PragZieleTabelle: View {
let zeilen: [PragZielZeile]

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Text("ZIEL").font(.system(size: 8, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
     Text("STATUS").font(.system(size: 8, weight: .bold)).frame(width: 70)
     Text("FORTSCHRITT").font(.system(size: 8, weight: .bold)).frame(width: 60)
   }
   .foregroundStyle(OpportunismaTheme.gray)
   .padding(.bottom, 6)
   Divider()
   ForEach(zeilen) { z in
     HStack(spacing: 6) {
       Text(z.ziel).font(.system(size: 9)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
       Text(z.status).font(.system(size: 8)).foregroundStyle(OpportunismaTheme.red).frame(width: 70)
       HStack(spacing: 4) {
         Capsule().fill(OpportunismaTheme.grayLight).frame(width: 40, height: 4)
           .overlay(alignment: .leading) {
             Capsule().fill(OpportunismaTheme.red).frame(width: 40 * CGFloat(z.fortschritt) / 100, height: 4)
           }
         Text("\(z.fortschritt)%").font(.system(size: 8, weight: .bold))
       }
       .frame(width: 60)
     }
     .padding(.vertical, 5)
     Divider()
   }
 }
}
}

struct PragGegnerTabelle: View {
let zeilen: [PragGegnerZeile]

var body: some View {
 VStack(spacing: 0) {
   HStack {
     ForEach(["AKTEUR", "EINFLUSS", "BEDROHUNG", "KONTROLLE"], id: \.self) { h in
       Text(h).font(.system(size: 7, weight: .bold)).frame(maxWidth: .infinity)
     }
   }
   .foregroundStyle(OpportunismaTheme.gray)
   ForEach(zeilen) { g in
     HStack {
       Text(g.name).font(.system(size: 8)).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
       Text(g.einfluss).font(.system(size: 8)).frame(maxWidth: .infinity)
       Text(g.bedrohung).font(.system(size: 8)).foregroundStyle(g.bedrohung == "Hoch" ? OpportunismaTheme.red : OpportunismaTheme.ink).frame(maxWidth: .infinity)
       Text(g.kontrolle).font(.system(size: 8)).frame(maxWidth: .infinity)
     }
     .padding(.vertical, 4)
     Divider()
   }
 }
}
}

struct PragSzenarioTabelle: View {
let zeilen: [PragSzenarioZeile]

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Text("SZENARIO").font(.system(size: 7, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
     Text("WAHRSCHEINL.").font(.system(size: 7, weight: .bold)).frame(width: 55)
     Text("KONTROLLE").font(.system(size: 7, weight: .bold)).frame(width: 55)
     Text("ERGEBNIS").font(.system(size: 7, weight: .bold)).frame(width: 50)
   }
   .foregroundStyle(OpportunismaTheme.gray)
   ForEach(zeilen) { s in
     HStack {
       Text(s.name).font(.system(size: 8)).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
       Text("\(s.wahrscheinlichkeit)%").font(.system(size: 8, design: .monospaced)).frame(width: 55)
       Text("\(s.kontrolle)%").font(.system(size: 8, design: .monospaced)).frame(width: 55)
       Text(s.ergebnis)
         .font(.system(size: 7, weight: .bold))
         .foregroundStyle(s.ergebnis == "ERFOLG" ? OpportunismaTheme.red : OpportunismaTheme.ink)
         .frame(width: 50)
     }
     .padding(.vertical, 4)
     Divider()
   }
 }
}
}

struct PragFooterMottos: View {
var body: some View {
 HStack(spacing: 0) {
   ForEach(Array(OpportunismaDemo.footerMottos.enumerated()), id: \.offset) { _, m in
     VStack(spacing: 4) {
       Image(systemName: m.symbol)
         .font(.system(size: 14))
         .foregroundStyle(OpportunismaTheme.red)
       Text(m.text)
         .font(.system(size: 6, weight: .bold))
         .multilineTextAlignment(.center)
         .foregroundStyle(OpportunismaTheme.gray)
         .lineLimit(3)
     }
     .frame(maxWidth: .infinity)
   }
 }
 .padding(.vertical, 12)
 .background(OpportunismaTheme.sidebarBg)
 .overlay(OpportunismaTheme.line.frame(height: 1), alignment: .top)
}
}

struct PragKIButton: View {
let titel: String
let laeuft: Bool
let action: () -> Void

var body: some View {
 Button(action: action) {
   HStack(spacing: 6) {
     if laeuft { ProgressView().scaleEffect(0.6).tint(.white) }
     else { Image(systemName: "wand.and.stars").font(.caption) }
     Text(titel).font(.system(size: 10, weight: .bold))
   }
   .foregroundStyle(.white)
   .padding(.horizontal, 14)
   .padding(.vertical, 8)
   .background(OpportunismaTheme.red, in: OpportunismaTheme.buttonShape)
 }
 .buttonStyle(.plain)
 .disabled(laeuft)
}
}

