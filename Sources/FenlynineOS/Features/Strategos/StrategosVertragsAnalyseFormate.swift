import SwiftUI
struct StrategosKlauselDetail: Identifiable {
    struct Projektion {
        let zeithorizont: String
        let trigger: String
        let entwicklung: String
        let reaktion: String
    }
    struct Option: Identifiable {
        let id: Int
        let label: String
        let typ: String
        let beschreibung: String
        let wahrscheinlichkeit: Int
        let kosten: String
        let strategischerWert: String
        let empfohlen: Bool
    }
    struct WirkungsKnoten {
        let typ: String        // rechtliche_folge / rechtlicher_vorteil / betrieb
        let zeithorizont: String
        let text: String
    }
    let id: Int
    let typ: String
    let kurzbeschreibung: String
    let risikoLevel: String
    let risikoScore: Double
    let paragraf: String?
    let normen: [String]
    let mechanik: String?
    let vorteile: [String]
    let nachteile: [String]
    let projektionen: [Projektion]
    let verhandlungsempfehlung: String?
    let istFormulierung: String?
    let sollFormulierung: String?
    let durchsetzbarkeit: String?
    let optionen: [Option]
    let wirkungsbaum: [WirkungsKnoten]
    let wirkungUnternehmen: String?
    let empfehlung: String?
    var anzeigeName: String {
        if let p = paragraf, !p.isEmpty { return "\(typ) (\(p))" }
        return typ
    }
    var farbe: Color {
        if risikoScore >= 8.5 { return .red }
        if risikoScore >= 7 { return .orange }
        if risikoScore >= 4 { return .yellow }
        return .green
    }
    var levelText: String {
        if risikoScore >= 8.5 { return "kritisch" }
        if risikoScore >= 7 { return "hoch" }
        if risikoScore >= 4 { return "mittel" }
        return "niedrig"
    }
    static func alle(aus vertrag: [String: Any]) -> [StrategosKlauselDetail] {
        KIJson.array(in: vertrag, keys: "klauseln").enumerated().map { i, k in
            let level = (k["risiko_level"] as? String ?? "mittel").lowercased()
            let fallbackScore: Double = {
                switch level {
                case "kritisch": return 9.0
                case "hoch": return 7.5
                case "mittel": return 5.0
                default: return 2.5
                }
            }()
            let projektionen = (k["szenario_projektionen"] as? [[String: Any]] ?? []).map { p in
                Projektion(
                    zeithorizont: p["zeithorizont"] as? String ?? "kurzfristig",
                    trigger: p["trigger"] as? String ?? "",
                    entwicklung: p["entwicklung"] as? String ?? "",
                    reaktion: p["empfohlene_reaktion"] as? String ?? ""
                )
            }
            let optionen = (k["handlungsoptionen"] as? [[String: Any]] ?? []).enumerated().map { oi, o in
                Option(
                    id: oi,
                    label: o["label"] as? String ?? "Option",
                    typ: o["typ"] as? String ?? "",
                    beschreibung: o["beschreibung"] as? String ?? "",
                    wahrscheinlichkeit: KIJson.intValue(o["wahrscheinlichkeit_pct"]) ?? 50,
                    kosten: o["kosten"] as? String ?? "—",
                    strategischerWert: o["strategischer_wert"] as? String ?? "—",
                    empfohlen: o["empfohlen"] as? Bool ?? false
                )
            }
            let baum = (k["wirkungsbaum"] as? [[String: Any]] ?? []).map { w in
                WirkungsKnoten(
                    typ: w["typ"] as? String ?? "rechtliche_folge",
                    zeithorizont: w["zeithorizont"] as? String ?? "",
                    text: w["text"] as? String ?? ""
                )
            }
            return StrategosKlauselDetail(
                id: i,
                typ: k["klausel_typ"] as? String ?? "Klausel",
                kurzbeschreibung: k["kurzbeschreibung"] as? String ?? "",
                risikoLevel: level,
                risikoScore: KIJson.numberValue(k["risiko_score"]) ?? fallbackScore,
                paragraf: k["paragraf_referenz"] as? String,
                normen: k["norm_referenzen"] as? [String] ?? [],
                mechanik: k["rechtliche_mechanik"] as? String,
                vorteile: k["juristische_vorteile"] as? [String] ?? [],
                nachteile: k["juristische_nachteile"] as? [String] ?? [],
                projektionen: projektionen,
                verhandlungsempfehlung: k["verhandlungsempfehlung"] as? String,
                istFormulierung: k["ist_formulierung"] as? String,
                sollFormulierung: k["soll_formulierung"] as? String,
                durchsetzbarkeit: k["durchsetzbarkeit"] as? String,
                optionen: optionen,
                wirkungsbaum: baum,
                wirkungUnternehmen: k["wirkung_unternehmen"] as? String,
                empfehlung: k["empfehlung"] as? String
            )
        }
    }
    var hatTiefenanalyse: Bool {
        mechanik != nil || !vorteile.isEmpty || !nachteile.isEmpty
            || !projektionen.isEmpty || !optionen.isEmpty || sollFormulierung != nil
    }
}
struct StrategosVertragsAnalyseFormateView: View {
    let vertrag: [String: Any]
    @State private var aufgeklappteKlausel: Int?
    @State private var formatKlauselId: Int = 0
    private var klauseln: [StrategosKlauselDetail] {
        StrategosKlauselDetail.alle(aus: vertrag)
    }
    var body: some View {
        let alle = klauseln
        if !alle.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                kopfzeile(alle)
                klauselKarten(alle)
                gesamtProjektion
                verhandlungsPrioritaeten
                kritischeFristen
                formateBereich(alle)
            }
            .padding(14)
            .background(Color.blue.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.12)))
        }
    }
    private func kopfzeile(_ alle: [StrategosKlauselDetail]) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Klausel-Analyse (\(alle.count))").font(.subheadline.bold())
                Text("Mechanik · Projektion · Verhandlungsposition")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            zaehler("kritisch", alle.filter { $0.levelText == "kritisch" }.count, .red)
            zaehler("hoch", alle.filter { $0.levelText == "hoch" }.count, .orange)
            zaehler("mittel", alle.filter { $0.levelText == "mittel" }.count, .yellow)
            zaehler("positiv", alle.filter { $0.levelText == "niedrig" }.count, .green)
        }
    }
    private func zaehler(_ label: String, _ n: Int, _ farbe: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(n)").font(.callout.bold()).foregroundStyle(n > 0 ? farbe : .secondary)
            Text(label.uppercased()).font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary)
        }
    }
    @ViewBuilder
    private func klauselKarten(_ alle: [StrategosKlauselDetail]) -> some View {
        VStack(spacing: 8) {
            ForEach(alle) { k in
                StrategosKlauselTiefenKarte(
                    klausel: k,
                    aufgeklappt: aufgeklappteKlausel == k.id,
                    toggle: {
                        withAnimation(.spring(duration: 0.25)) {
                            aufgeklappteKlausel = aufgeklappteKlausel == k.id ? nil : k.id
                        }
                    }
                )
            }
        }
    }
    @ViewBuilder
    private var gesamtProjektion: some View {
        if let proj = vertrag["szenario_projektion"] as? [String: Any] {
            let faelle: [(String, String?, Color)] = [
                ("BEST CASE", proj["best_case"] as? String, .green),
                ("BASE CASE", proj["base_case"] as? String, .blue),
                ("WORST CASE", proj["worst_case"] as? String, .red)
            ]
            if faelle.contains(where: { $0.1?.isEmpty == false }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Szenario-Projektion").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(faelle, id: \.0) { titel, text, farbe in
                        if let text, !text.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(titel).font(.system(size: 9, weight: .black)).foregroundStyle(farbe)
                                Text(text).font(.caption2)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(farbe.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    private var verhandlungsPrioritaeten: some View {
        let prios = KIJson.array(in: vertrag, keys: "verhandlungsprioritaeten")
        if !prios.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Verhandlungsprioritäten (vor Unterzeichnung)")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                ForEach(Array(prios.enumerated()), id: \.offset) { i, p in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(KIJson.intValue(p["rang"]) ?? i + 1)")
                            .font(.caption.bold()).foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(prioFarbe(i), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p["titel"] as? String ?? "—").font(.caption.bold())
                            Text(p["beschreibung"] as? String ?? "")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 3)
                }
            }
            .padding(10)
            .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    private func prioFarbe(_ i: Int) -> Color {
        [Color.red, .orange, .blue, .purple, .gray][min(i, 4)]
    }
    @ViewBuilder
    private var kritischeFristen: some View {
        let fristen = KIJson.array(in: vertrag, keys: "kritische_fristen")
        if !fristen.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kritische Fristen").font(.caption.bold()).foregroundStyle(.secondary)
                ForEach(Array(fristen.enumerated()), id: \.offset) { _, f in
                    HStack(alignment: .top, spacing: 10) {
                        Label(f["datum"] as? String ?? "—", systemImage: "calendar")
                            .font(.caption2.bold()).foregroundStyle(.orange)
                            .frame(width: 110, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(f["titel"] as? String ?? "—").font(.caption2.bold())
                            if let k = f["konsequenz"] as? String, !k.isEmpty {
                                Text(k).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(10)
            .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    @ViewBuilder
    private func formateBereich(_ alle: [StrategosKlauselDetail]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Analyse-Formate").font(.caption.bold()).foregroundStyle(.secondary)
            StrategosFormatHeatmap(klauseln: alle) { id in
                withAnimation(.spring(duration: 0.25)) {
                    aufgeklappteKlausel = id
                    formatKlauselId = id
                }
            }
            if alle.contains(where: { !$0.wirkungsbaum.isEmpty }) {
                StrategosFormatWirkungsbaum(klauseln: alle, auswahlId: $formatKlauselId)
            }
            if alle.contains(where: { !$0.projektionen.isEmpty }) {
                StrategosFormatZeitachse(klauseln: alle, auswahlId: $formatKlauselId)
            }
            if alle.contains(where: { !$0.optionen.isEmpty }) {
                StrategosFormatOptionenCards(klauseln: alle, auswahlId: $formatKlauselId)
            }
            if alle.count >= 2 {
                StrategosFormatQuadrant(klauseln: alle)
            }
            if alle.contains(where: { $0.istFormulierung != nil || $0.sollFormulierung != nil }) {
                StrategosFormatVorherNachher(klauseln: alle, auswahlId: $formatKlauselId)
            }
        }
        .padding(.top, 4)
    }
}
struct StrategosKlauselTiefenKarte: View {
    let klausel: StrategosKlauselDetail
    let aufgeklappt: Bool
    let toggle: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(klausel.farbe)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(klausel.anzeigeName).font(.caption.bold())
                        if !klausel.normen.isEmpty {
                            Text(klausel.normen.joined(separator: " / "))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.blue)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Text(klausel.levelText)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(klausel.farbe.opacity(0.14), in: Capsule())
                        .foregroundStyle(klausel.farbe)
                    Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if aufgeklappt {
                VStack(alignment: .leading, spacing: 12) {
                    if !klausel.kurzbeschreibung.isEmpty {
                        Text(klausel.kurzbeschreibung).font(.caption2)
                    }
                    if let mechanik = klausel.mechanik, !mechanik.isEmpty {
                        abschnitt("RECHTLICHE MECHANIK") {
                            Text(mechanik).font(.caption2)
                        }
                    }
                    if !klausel.vorteile.isEmpty || !klausel.nachteile.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            if !klausel.vorteile.isEmpty {
                                vorNachSpalte("JURISTISCHE VORTEILE", klausel.vorteile, .green, "plus.circle")
                            }
                            if !klausel.nachteile.isEmpty {
                                vorNachSpalte("JURISTISCHE NACHTEILE", klausel.nachteile, .red, "minus.circle")
                            }
                        }
                    }
                    if !klausel.projektionen.isEmpty {
                        abschnitt("SZENARIO-PROJEKTIONEN & REAKTIONSEMPFEHLUNGEN") {
                            ForEach(Array(klausel.projektionen.enumerated()), id: \.offset) { _, p in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(p.zeithorizont.uppercased())
                                            .font(.system(size: 8, weight: .black))
                                            .foregroundStyle(zeitFarbe(p.zeithorizont))
                                        if !p.trigger.isEmpty {
                                            Text("→ wenn: \(p.trigger)")
                                                .font(.caption2).foregroundStyle(.secondary)
                                        }
                                    }
                                    if !p.entwicklung.isEmpty {
                                        Text(p.entwicklung).font(.caption2)
                                    }
                                    if !p.reaktion.isEmpty {
                                        Text("Empfohlene Reaktion: \(p.reaktion)")
                                            .font(.caption2.bold()).foregroundStyle(.blue)
                                    }
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(zeitFarbe(p.zeithorizont).opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    if let v = klausel.verhandlungsempfehlung, !v.isEmpty {
                        abschnitt("VERHANDLUNGSEMPFEHLUNG") {
                            Text(v)
                                .font(.system(size: 10, design: .monospaced))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    if let d = klausel.durchsetzbarkeit, !d.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "hammer").font(.system(size: 9)).foregroundStyle(.secondary)
                            Text("Durchsetzbarkeit: \(d)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .background(klausel.farbe.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(klausel.farbe.opacity(0.18)))
    }
    @ViewBuilder
    private func abschnitt(_ titel: String, @ViewBuilder inhalt: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titel).font(.system(size: 8, weight: .black)).foregroundStyle(.tertiary)
            inhalt()
        }
    }
    private func vorNachSpalte(_ titel: String, _ punkte: [String], _ farbe: Color, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.system(size: 8, weight: .black)).foregroundStyle(farbe)
            ForEach(punkte, id: \.self) { p in
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: symbol).font(.system(size: 8)).foregroundStyle(farbe)
                        .padding(.top, 2)
                    Text(p).font(.caption2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(8)
        .background(farbe.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
    private func zeitFarbe(_ zeit: String) -> Color {
        let z = zeit.lowercased()
        if z.contains("kurz") { return .red }
        if z.contains("mittel") { return .orange }
        return .blue
    }
}
struct StrategosFormatHeatmap: View {
    let klauseln: [StrategosKlauselDetail]
    var onSelect: (Int) -> Void
    var body: some View {
        StrategosFormatRahmen(
            nummer: "01",
            titel: "Klausel-Risiko-Heatmap",
            untertitel: "Alle Klauseln nach Risikostufe — klicken für Detailansicht"
        ) {
            VStack(spacing: 6) {
                ForEach(klauseln.sorted { $0.risikoScore > $1.risikoScore }) { k in
                    Button {
                        onSelect(k.id)
                    } label: {
                        HStack(spacing: 10) {
                            Text(k.paragraf ?? "§")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 44, alignment: .leading)
                            Text(k.typ).font(.caption2.bold()).lineLimit(1)
                                .frame(width: 190, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.gray.opacity(0.12))
                                    Capsule()
                                        .fill(k.farbe.gradient)
                                        .frame(width: geo.size.width * k.risikoScore / 10)
                                }
                            }
                            .frame(height: 8)
                            Text(String(format: "%.1f", k.risikoScore))
                                .font(.caption2.bold()).foregroundStyle(k.farbe)
                                .frame(width: 28, alignment: .trailing)
                            Text(k.levelText.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(k.farbe)
                                .frame(width: 52, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
struct StrategosFormatWirkungsbaum: View {
    let klauseln: [StrategosKlauselDetail]
    @Binding var auswahlId: Int
    private var auswahl: StrategosKlauselDetail? {
        klauseln.first { $0.id == auswahlId && !$0.wirkungsbaum.isEmpty }
            ?? klauseln.first { !$0.wirkungsbaum.isEmpty }
    }
    var body: some View {
        StrategosFormatRahmen(
            nummer: "02",
            titel: "Wirkungsbaum",
            untertitel: "Wie eine Klausel ins Unternehmen hineinwirkt"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                StrategosKlauselAuswahlChips(klauseln: klauseln, auswahlId: $auswahlId)
                if let k = auswahl {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("QUELLE").font(.system(size: 7, weight: .black)).foregroundStyle(.gray)
                                Text(k.normen.isEmpty ? k.anzeigeName : k.normen.joined(separator: " / "))
                                    .font(.caption2.bold())
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                            Spacer()
                        }
                        ForEach(Array(k.wirkungsbaum.enumerated()), id: \.offset) { _, w in
                            HStack(alignment: .top, spacing: 8) {
                                Rectangle()
                                    .fill(baumFarbe(w.typ).opacity(0.5))
                                    .frame(width: 2)
                                    .padding(.leading, 14)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Circle().fill(baumFarbe(w.typ)).frame(width: 6, height: 6)
                                        Text(baumLabel(w.typ)).font(.system(size: 8, weight: .black))
                                            .foregroundStyle(baumFarbe(w.typ))
                                        if !w.zeithorizont.isEmpty {
                                            Text(w.zeithorizont).font(.system(size: 8)).foregroundStyle(.tertiary)
                                        }
                                    }
                                    Text(w.text).font(.caption2)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private func baumFarbe(_ typ: String) -> Color {
        switch typ {
        case "rechtlicher_vorteil": return .green
        case "betrieb": return .orange
        default: return .red
        }
    }
    private func baumLabel(_ typ: String) -> String {
        switch typ {
        case "rechtlicher_vorteil": return "RECHTLICHER VORTEIL"
        case "betrieb": return "BETRIEB"
        default: return "RECHTLICHE FOLGE"
        }
    }
}
struct StrategosFormatZeitachse: View {
    let klauseln: [StrategosKlauselDetail]
    @Binding var auswahlId: Int
    private var auswahl: StrategosKlauselDetail? {
        klauseln.first { $0.id == auswahlId && !$0.projektionen.isEmpty }
            ?? klauseln.first { !$0.projektionen.isEmpty }
    }
    var body: some View {
        StrategosFormatRahmen(
            nummer: "03",
            titel: "Zeitachse mit Eintrittsszenarien",
            untertitel: "Wann wird eine Klausel scharf?"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                StrategosKlauselAuswahlChips(klauseln: klauseln, auswahlId: $auswahlId)
                if let k = auswahl {
                    GeometryReader { geo in
                        let sortiert = sortierteProjektionen(k)
                        let breite = geo.size.width
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.25))
                                .frame(height: 1.5)
                                .offset(y: 58)
                            ForEach(Array(sortiert.enumerated()), id: \.offset) { i, p in
                                let x = breite * (0.08 + CGFloat(i) / CGFloat(max(1, sortiert.count)) * 0.8)
                                VStack(spacing: 4) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(p.trigger.isEmpty ? p.entwicklung : p.trigger)
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(.white)
                                            .lineLimit(3)
                                    }
                                    .padding(6)
                                    .frame(width: min(150, breite / CGFloat(max(2, sortiert.count)) - 8))
                                    .background(zeitFarbe(p.zeithorizont), in: RoundedRectangle(cornerRadius: 6))
                                    Circle()
                                        .fill(zeitFarbe(p.zeithorizont))
                                        .frame(width: 8, height: 8)
                                    Text(p.zeithorizont)
                                        .font(.system(size: 8)).foregroundStyle(.secondary)
                                }
                                .position(x: x, y: 40)
                            }
                            HStack {
                                Text("HEUTE").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                Spacer()
                                Text("SPÄTER").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary)
                            }
                            .offset(y: 72)
                        }
                    }
                    .frame(height: 96)
                }
            }
        }
    }
    private func sortierteProjektionen(_ k: StrategosKlauselDetail) -> [StrategosKlauselDetail.Projektion] {
        k.projektionen.sorted { rang($0.zeithorizont) < rang($1.zeithorizont) }
    }
    private func rang(_ z: String) -> Int {
        let s = z.lowercased()
        if s.contains("kurz") { return 0 }
        if s.contains("mittel") { return 1 }
        return 2
    }
    private func zeitFarbe(_ zeit: String) -> Color {
        let z = zeit.lowercased()
        if z.contains("kurz") { return .orange }
        if z.contains("mittel") { return .red }
        return .purple
    }
}
struct StrategosFormatOptionenCards: View {
    let klauseln: [StrategosKlauselDetail]
    @Binding var auswahlId: Int
    private var auswahl: StrategosKlauselDetail? {
        klauseln.first { $0.id == auswahlId && !$0.optionen.isEmpty }
            ?? klauseln.first { !$0.optionen.isEmpty }
    }
    var body: some View {
        StrategosFormatRahmen(
            nummer: "04",
            titel: "Optionen als Card-Layout",
            untertitel: "Handlungsmöglichkeiten — von Akzeptanz bis Klauselangriff"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                StrategosKlauselAuswahlChips(klauseln: klauseln, auswahlId: $auswahlId)
                if let k = auswahl {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], alignment: .leading, spacing: 10) {
                        ForEach(k.optionen) { o in
                            optionKarte(o)
                        }
                    }
                }
            }
        }
    }
    private func optionKarte(_ o: StrategosKlauselDetail.Option) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if o.empfohlen {
                Text("EMPFOHLEN")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.green, in: Capsule())
            }
            Text(o.label).font(.caption.bold())
                .foregroundStyle(o.empfohlen ? .white : .primary)
            if !o.beschreibung.isEmpty {
                Text(o.beschreibung).font(.system(size: 9))
                    .foregroundStyle(o.empfohlen ? .white.opacity(0.85) : .secondary)
                    .lineLimit(4)
            }
            Spacer(minLength: 2)
            VStack(alignment: .leading, spacing: 3) {
                metrik("WAHRSCHEINLICHKEIT", "\(o.wahrscheinlichkeit)%", hell: o.empfohlen)
                metrik("KOSTEN", o.kosten, hell: o.empfohlen)
                metrik("STRAT. WERT", o.strategischerWert, hell: o.empfohlen)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(
            o.empfohlen ? Color.green.opacity(0.85) : Color.gray.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(
            o.empfohlen ? Color.green : Color.gray.opacity(0.2)
        ))
    }
    private func metrik(_ label: String, _ wert: String, hell: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.system(size: 7, weight: .bold))
                .foregroundStyle(hell ? AnyShapeStyle(.white.opacity(0.7)) : AnyShapeStyle(.tertiary))
            Text(wert).font(.caption2.bold())
                .foregroundStyle(hell ? .white : wertFarbe(wert))
        }
    }
    private func wertFarbe(_ wert: String) -> Color {
        let w = wert.lowercased()
        if w.contains("negativ") { return .red }
        if w.contains("hoch") { return .green }
        return .primary
    }
}
struct StrategosFormatQuadrant: View {
    let klauseln: [StrategosKlauselDetail]
    var body: some View {
        StrategosFormatRahmen(
            nummer: "05",
            titel: "Chancen-Risiken-Quadrant",
            untertitel: "Portfolio-Sicht aller Klauseln — Wahrscheinlichkeit vs. Wirkungstiefe"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    let b = geo.size.width
                    let h = geo.size.height
                    ZStack {
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: h / 2))
                            p.addLine(to: CGPoint(x: b, y: h / 2))
                            p.move(to: CGPoint(x: b / 2, y: 0))
                            p.addLine(to: CGPoint(x: b / 2, y: h))
                        }
                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        Text("VERMEIDEN")
                            .font(.system(size: 8, weight: .black)).foregroundStyle(.red.opacity(0.6))
                            .position(x: b * 0.85, y: h * 0.08)
                        Text("MONITOREN")
                            .font(.system(size: 8, weight: .black)).foregroundStyle(.orange.opacity(0.6))
                            .position(x: b * 0.85, y: h * 0.92)
                        ForEach(klauseln) { k in
                            let px = b * (0.1 + 0.8 * eintritt(k))
                            let py = h * (1 - (0.1 + 0.8 * k.risikoScore / 10))
                            Circle()
                                .fill(k.farbe)
                                .frame(width: 9, height: 9)
                                .position(x: px, y: py)
                                .help("\(k.anzeigeName) · Score \(String(format: "%.1f", k.risikoScore))")
                        }
                    }
                }
                .frame(height: 170)
                .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                HStack {
                    Text("Wahrscheinlichkeit →").font(.system(size: 8)).foregroundStyle(.tertiary)
                    Spacer()
                    Text("↑ Wirkungstiefe / Tail-Risk").font(.system(size: 8)).foregroundStyle(.tertiary)
                }
                HStack(spacing: 10) {
                    ForEach(klauseln) { k in
                        HStack(spacing: 3) {
                            Circle().fill(k.farbe).frame(width: 6, height: 6)
                            Text(k.typ).font(.system(size: 8)).lineLimit(1)
                        }
                    }
                }
            }
        }
    }
    private func eintritt(_ k: StrategosKlauselDetail) -> CGFloat {
        if let empfohlen = k.optionen.first(where: { $0.empfohlen }) {
            return CGFloat(empfohlen.wahrscheinlichkeit) / 100
        }
        return CGFloat(min(0.95, k.risikoScore / 11 + 0.1))
    }
}
struct StrategosFormatVorherNachher: View {
    let klauseln: [StrategosKlauselDetail]
    @Binding var auswahlId: Int
    private var auswahl: StrategosKlauselDetail? {
        klauseln.first { $0.id == auswahlId && ($0.istFormulierung != nil || $0.sollFormulierung != nil) }
            ?? klauseln.first { $0.istFormulierung != nil || $0.sollFormulierung != nil }
    }
    var body: some View {
        StrategosFormatRahmen(
            nummer: "10",
            titel: "Klausel-Vergleich (Vorher / Nachher)",
            untertitel: "IST-Formulierung vs. empfohlene SOLL-Formulierung"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                StrategosKlauselAuswahlChips(klauseln: klauseln, auswahlId: $auswahlId)
                if let k = auswahl {
                    HStack(alignment: .top, spacing: 10) {
                        if let ist = k.istFormulierung, !ist.isEmpty {
                            formulierung("IST-FORMULIERUNG", ist, .red, punkte: k.nachteile)
                        }
                        if let soll = k.sollFormulierung, !soll.isEmpty {
                            formulierung("SOLL-FORMULIERUNG", soll, .green, punkte: k.vorteile)
                        }
                    }
                }
            }
        }
    }
    private func formulierung(_ titel: String, _ text: String, _ farbe: Color, punkte: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titel).font(.system(size: 8, weight: .black)).foregroundStyle(.white)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(farbe, in: Capsule())
            Text("„\(text)“")
                .font(.system(size: 10))
                .italic()
            ForEach(punkte.prefix(3), id: \.self) { p in
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: farbe == .red ? "xmark.square.fill" : "checkmark.square.fill")
                        .font(.system(size: 8)).foregroundStyle(farbe)
                        .padding(.top, 2)
                    Text(p).font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(10)
        .background(farbe.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(farbe.opacity(0.25)))
    }
}
struct StrategosFormatRahmen<Inhalt: View>: View {
    let nummer: String
    let titel: String
    let untertitel: String
    @ViewBuilder let inhalt: Inhalt
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(nummer)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.blue.opacity(0.75), in: RoundedRectangle(cornerRadius: 5))
                VStack(alignment: .leading, spacing: 1) {
                    Text("FORMAT \(nummer) · \(titel.uppercased())")
                        .font(.system(size: 9, weight: .black))
                    Text(untertitel).font(.system(size: 9)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            inhalt
        }
        .padding(12)
        .background(Color.gray.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.12)))
    }
}
struct StrategosKlauselAuswahlChips: View {
    let klauseln: [StrategosKlauselDetail]
    @Binding var auswahlId: Int
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text("KLAUSEL:").font(.system(size: 8, weight: .black)).foregroundStyle(.tertiary)
                ForEach(klauseln) { k in
                    Button {
                        auswahlId = k.id
                    } label: {
                        Text(k.typ)
                            .font(.system(size: 9, weight: auswahlId == k.id ? .bold : .regular))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(
                                auswahlId == k.id ? k.farbe.opacity(0.18) : Color.gray.opacity(0.07),
                                in: Capsule()
                            )
                            .overlay(Capsule().stroke(
                                auswahlId == k.id ? k.farbe.opacity(0.5) : Color.clear
                            ))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
