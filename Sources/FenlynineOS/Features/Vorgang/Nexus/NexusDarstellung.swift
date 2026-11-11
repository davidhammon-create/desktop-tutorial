import SwiftUI
enum NexusPapier {
    static var grund: Color { Premium.void }
    static var karte: Color { Premium.panel }
    static var leiste: Color { Premium.ink }
    static var text: Color { Premium.text }
    static var leise: Color { Premium.textSoft }
    static var linie: Color { Premium.hairline }
    static var banner: Color { Premium.well }
    static var pAkzent: Color { Premium.critical }
    static func seite(_ typ: NexusKnotenTyp) -> Color {
        switch typ {
        case .argEigen: return Premium.computed
        case .argGegner: return Premium.critical
        case .autoritaet, .beleg: return Premium.textSoft
        case .klausel: return Premium.proposed
        case .norm: return Premium.action
        case .merkmal: return Premium.text
        }
    }
}
struct NexusKnotenKartePDF: View {
    let knoten: NexusKnoten
    let graph: NexusGraph
    var dichte: NexusDichte = .karte
    var istWurzel: Bool = false
    var onTap: () -> Void
    private var ki: Bool { knoten.status == .kiVorschlag }
    private var fehlt: Bool { knoten.kern.localizedCaseInsensitiveContains("fehlt") }
    private var seite: Color { NexusPapier.seite(knoten.typ) }
    private var kante: NexusKante? { graph.kanteVon(knoten.id) }
    private var typZeile: String {
        if knoten.typ == .merkmal, let n = graph.merkmalIndex(knoten.id) {
            return "MERKMAL \(n)"
        }
        return knoten.typ.kartenLabel
    }
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(seite)
                    .frame(width: 3)
                inhalt
                    .padding(.horizontal, 10)
                    .padding(.vertical, dichte == .punkt ? 8 : 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(NexusPapier.karte))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        ki ? seite.opacity(0.7) : InterfacePalette.trennlinie,
                        style: StrokeStyle(lineWidth: istWurzel ? 1.5 : 1, dash: ki ? [5, 3] : [])
                    )
            )
        }
        .buttonStyle(.plain)
        .help(ki ? "KI-Vorschlag — gestrichelt, geht nicht in den Export" : knoten.kern)
    }
    @ViewBuilder
    private var inhalt: some View {
        switch dichte {
        case .punkt:
            VStack(alignment: .leading, spacing: 3) {
                Text(typZeile)
                    .font(.system(size: 8, weight: .bold))
                    .kerning(0.4)
                    .foregroundStyle(seite)
                Text(knoten.kern)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Premium.text)
                    .lineLimit(2)
                Text(kennzahl)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
        case .karte, .voll:
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(knoten.typ.kuerzel)  \(typZeile)")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(seite)
                    if fehlt {
                        Text("FEHLT")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(InterfacePalette.kritisch)
                    }
                    if ki {
                        Text("KI")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(InterfacePalette.vorgeschlagen)
                    }
                    Spacer(minLength: 4)
                    Text(kennzahl)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle((knoten.typ == .norm || knoten.typ == .merkmal) ? InterfacePalette.berechnet : Premium.text)
                }
                Text(knoten.kern)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Premium.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if let neben = nebenzeile {
                    Text(neben)
                        .font(.system(size: 10))
                        .foregroundStyle(InterfacePalette.sekundaer)
                        .lineLimit(2)
                }
            }
        }
    }
    private var kennzahl: String {
        switch knoten.typ {
        case .norm:
            return NexusAnzeige.band(graph.pErfolg)
        case .merkmal:
            return knoten.pMerkmal.map { NexusAnzeige.band($0) } ?? "—"
        case .autoritaet:
            return "Q \(NexusAnzeige.faktor(knoten.qRang.q))"
        case .beleg, .klausel, .argEigen, .argGegner:
            return NexusAnzeige.faktor(knoten.sNetto)
        }
    }
    private var nebenzeile: String? {
        switch knoten.typ {
        case .norm:
            let n = graph.merkmale().count
            guard n > 0 else { return knoten.volltext.isEmpty ? nil : knoten.volltext }
            return "UND · \(n) Merkmale"
        case .merkmal:
            var teile = [knoten.beweislast.titel]
            if knoten.vermutung { teile.append("vermutet") }
            let stuetzen = graph.kinder(von: knoten.id).filter { $0.status != .verworfen }.count
            if stuetzen == 1 { teile.append("1 Stütze") }
            else if stuetzen > 1 { teile.append("\(stuetzen) Stützen") }
            else { teile.append("offene Flanke") }
            return teile.joined(separator: " · ")
        case .beleg:
            var teile = [knoten.nachweis.titel]
            if let z = knoten.fundstelle?.zitat, !z.isEmpty { teile.append(z) }
            return teile.joined(separator: " · ")
        case .klausel:
            if let z = knoten.fundstelle?.zitat, !z.isEmpty { return z }
            return knoten.volltext.isEmpty ? nil : knoten.volltext
        case .argGegner, .argEigen:
            return kante?.typ.label
        case .autoritaet:
            var teile = [knoten.qRang.kurz]
            if let z = knoten.fundstelle?.zitat, !z.isEmpty { teile.append(z) }
            return teile.joined(separator: " · ")
        }
    }
}
struct NexusChip: View {
    let titel: String
    let aktiv: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(titel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(aktiv ? Color.white : InterfacePalette.sekundaer)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(aktiv ? InterfacePalette.aktion.opacity(0.28) : InterfacePalette.Material.l3.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(aktiv ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
struct NexusHinzufuegenKarte: View {
    let titel: String
    let untertitel: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(InterfacePalette.sekundaer)
                Text(untertitel)
                    .font(.system(size: 10))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(InterfacePalette.trennlinie, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
    }
}
struct NexusFormelBanner: View {
    let graph: NexusGraph
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(graph.aggregationZeile())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Premium.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("Anzeige \(NexusAnzeige.band(graph.pErfolg)) · intern \(NexusAnzeige.punkt(graph.pErfolg)) · \(NexusAnzeige.betaHinweis)")
                .font(.system(size: 10))
                .foregroundStyle(InterfacePalette.sekundaer)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(NexusPapier.banner))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(InterfacePalette.trennlinie, lineWidth: 1))
    }
}
struct NexusVollSpalte: View {
    let knoten: NexusKnoten
    let graph: NexusGraph
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(knoten.typ.kuerzel) · \(knoten.typ.kartenLabel)")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.4)
                    .foregroundStyle(NexusPapier.seite(knoten.typ))
                Text(knoten.kern)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Premium.text)
                Text(knoten.volltext.isEmpty ? knoten.kern : knoten.volltext)
                    .font(.system(size: 12))
                    .foregroundStyle(InterfacePalette.sekundaer)
                if let f = knoten.fundstelle {
                    Text("Fundstelle \(f.zitat) · S. \(f.seite)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(InterfacePalette.sekundaer)
                }
                gruppe("Stärke", [
                    "roh \(NexusAnzeige.netto(knoten.sRoh))",
                    "netto \(NexusAnzeige.netto(knoten.sNetto))",
                    knoten.pMerkmal.map { "P(m) \(NexusAnzeige.band($0))" }
                ].compactMap { $0 })
                gruppe("Quellen", [
                    "Q \(knoten.qRang.titel)",
                    "N \(knoten.nachweis.titel)",
                    "Passgenauigkeit \(NexusAnzeige.faktor(knoten.passgenauigkeit)) — einzige Schätzung",
                    knoten.passBegruendung
                ].filter { !$0.isEmpty })
                if knoten.status == .kiVorschlag {
                    Text("Gestrichelt: KI-Vorschlag. Geht nicht in den Export.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(InterfacePalette.vorgeschlagen)
                }
            }
            .padding(14)
        }
        .frame(minWidth: 260, maxWidth: 320)
        .background(NexusPapier.leiste)
        .overlay(Rectangle().fill(InterfacePalette.trennlinie).frame(width: 1), alignment: .leading)
    }
    private func gruppe(_ titel: String, _ zeilen: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel.uppercased())
                .font(.system(size: 9, weight: .bold))
                .kerning(0.4)
                .foregroundStyle(InterfacePalette.sekundaer)
            ForEach(zeilen, id: \.self) { z in
                Text(z).font(.system(size: 11)).foregroundStyle(Premium.text)
            }
        }
    }
}
struct NexusKonterKarteView: View {
    let karte: NexusKonterKarte
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ERKANNT · GEGNER")
                .font(.system(size: 10, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(InterfacePalette.kritisch)
            Text(karte.gegnerKern)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Premium.text)
            Text("STÄRKSTER KONTER · NETTO \(NexusAnzeige.faktor(karte.hauptNetto)) · \(karte.hauptTyp.label.uppercased())")
                .font(.system(size: 10, weight: .bold))
                .kerning(0.3)
                .foregroundStyle(InterfacePalette.berechnet)
            Text(karte.hauptKern)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Premium.text)
            if let f = karte.fundstelle {
                Text("Fundstelle: \(f)")
                    .font(.system(size: 11))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            if karte.selbstAngegriffen {
                Text("Achtung: wird angegriffen")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(InterfacePalette.vorgeschlagen)
            }
            ForEach(karte.alternative, id: \.kern) { alt in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alternative · \(NexusAnzeige.faktor(alt.netto))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(InterfacePalette.sekundaer)
                    Text(alt.kern)
                        .font(.system(size: 12))
                        .foregroundStyle(Premium.text)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(InterfacePalette.Material.l3))
            }
            Text("Kein Mikrofon. Nichts wird als Wortlaut gespeichert.")
                .font(.system(size: 10))
                .foregroundStyle(InterfacePalette.sekundaer)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 8).fill(NexusPapier.karte))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.trennlinie, lineWidth: 1))
    }
}
