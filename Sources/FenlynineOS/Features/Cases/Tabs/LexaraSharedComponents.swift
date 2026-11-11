#if false
import SwiftUI
struct InfoHinweis: View {
    let titel: String
    let nachricht: String
    let symbol: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(titel).font(.subheadline.bold())
                Text(nachricht).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}
struct PlatzhalterView: View {
    let nachricht: String
    var body: some View {
        Text(nachricht)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}
struct KIProfilKarte: View {
    let titel: String
    let inhalt: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(titel, systemImage: "brain")
                .font(.system(size: 12, weight: .semibold))
            Text(inhalt)
                .font(.system(size: 12))
                .lineSpacing(4)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}
struct LexaraRadarChartView: View {
    let data: [(label: String, value: Double)]
    let maxValue: Double
    let fillColor: Color
    let strokeColor: Color
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) * 0.35
            let count = max(data.count, 3)
            ZStack {
                ForEach(1...4, id: \.self) { ring in
                    radarPolygon(count: count, center: center, radius: radius * Double(ring) / 4)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                }
                radarPolygon(count: count, center: center, radius: radius, values: data.map(\.value))
                    .fill(fillColor.opacity(0.2))
                radarPolygon(count: count, center: center, radius: radius, values: data.map(\.value))
                    .stroke(strokeColor, lineWidth: 2)
            }
        }
    }
    private func radarPolygon(count: Int, center: CGPoint, radius: Double, values: [Double]? = nil) -> Path {
        var path = Path()
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * .pi - .pi / 2
            let norm = values.map { min(maxValue, max(0, $0[i % $0.count])) / maxValue } ?? 1
            let r = radius * norm
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
struct DokumentKiBeraterPanel: View {
    let ki: [String: Any]
    var body: some View {
        if let emp = ki["empfehlung"] as? String, !emp.isEmpty {
            KIProfilKarte(titel: "KI-Berater — Empfehlung", inhalt: emp)
        }
    }
}
struct DokumentGegnerProfilPanel: View {
    let profil: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let summary = profil["ki_zusammenfassung"] as? String, !summary.isEmpty {
                KIProfilKarte(titel: "Gegner-Profil (KI)", inhalt: summary)
            }
            if let taktiken = profil["taktiken"] as? [[String: Any]], !taktiken.isEmpty {
                Text("Bekannte Taktiken").font(.caption.bold())
                ForEach(Array(taktiken.enumerated()), id: \.offset) { _, t in
                    Text("• \(t["name"] as? String ?? "") — \(t["beschreibung"] as? String ?? "")")
                        .font(.caption2)
                }
            }
        }
    }
}
#endif
