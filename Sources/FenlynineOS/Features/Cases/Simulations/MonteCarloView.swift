import SwiftUI
import Charts
struct TabSimulation: View {
    let viewModel: CaseDetailViewModel
    var kiMode: Bool = true
    @State private var simulationLaeuft = false
    @State private var ergebnis: MonteCarloErgebnis?
    @State private var prognoseErgebnis: PrognoseErgebnis?
    @State private var iterationen = 10000
    @State private var zeigeTransparenz = false
    @State private var rsprLaeuft = false
    @State private var rsprErgebnis: RsprKIResult? = nil
    @State private var rsprFehler: String? = nil
    struct RsprKIResult {
        var rechtsprechung: [(gericht: String, aktenzeichen: String, datum: String, leitsatz: String, relevanz: String)]
        var literatur: [(titel: String, autor: String, relevanz: String)]
        var gegnerTaktiken: [String]
        var zusammenfassung: String
    }
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stochastische Simulation")
                        .font(.title2.bold())
                    Text("Monte-Carlo & Prognose-Berechnung (algorithmisch, ohne KI)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Iterationen")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $iterationen) {
                            Text("1.000").tag(1000)
                            Text("5.000").tag(5000)
                            Text("10.000").tag(10000)
                            Text("100.000").tag(100000)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                    Button {
                        starten()
                    } label: {
                        if simulationLaeuft {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Label("Simulation starten", systemImage: "play.fill")
                        }
                    }
                    .buttonStyle(FenlynineOSGlassProminentButtonStyle())
                    .disabled(simulationLaeuft || viewModel.fall == nil)
                    if kiMode {
                        Button {
                            Task { await rechtsprechungLaden() }
                        } label: {
                            if rsprLaeuft { ProgressView().scaleEffect(0.7) }
                            else { Label(rsprErgebnis == nil ? "Rechtsprechung laden" : "Rspr. aktualisieren", systemImage: "book.fill") }
                        }
                        .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                        .controlSize(.small)
                        .disabled(rsprLaeuft)
                    }
                }
            }
            if let err = rsprFehler {
                Label(err, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.red)
            }
            if let rspr = rsprErgebnis {
                if !rspr.zusammenfassung.isEmpty {
                    Text(rspr.zusammenfassung).font(.caption).lineSpacing(3)
                        .padding(10).background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
                if !rspr.rechtsprechung.isEmpty {
                    Text("Relevante Rechtsprechung").font(.caption.bold())
                    ForEach(Array(rspr.rechtsprechung.enumerated()), id: \.offset) { _, r in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(r.gericht) — \(r.aktenzeichen)").font(.caption.bold())
                            Text(r.leitsatz).font(.caption2)
                        }
                        .padding(8).background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !rspr.gegnerTaktiken.isEmpty {
                    Text("Typische Gegner-Taktiken").font(.caption.bold())
                    ForEach(rspr.gegnerTaktiken, id: \.self) { t in Text("• \(t)").font(.caption2) }
                }
            }
            if let prognose = prognoseErgebnis {
                PrognoseHauptErgebnis(prognose: prognose)
                DisclosureGroup(isExpanded: $zeigeTransparenz) {
                    BerechnungsTransparenzView(schritte: prognose.schritte)
                } label: {
                    Label("Berechnungsschritte anzeigen (\(prognose.schritte.count) Schritte)", systemImage: "function")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.purple)
                }
                .padding(12)
                .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
            if let mc = ergebnis {
                MonteCarloErgebnisView(ergebnis: mc, iterationen: iterationen)
            }
            if ergebnis == nil && prognoseErgebnis == nil {
                PlatzhalterView(
                    nachricht: "Klicken Sie auf 'Simulation starten' um die stochastische Analyse zu berechnen.",
                    symbol: "function"
                )
                .frame(minHeight: 200)
            }
        }
    }
    private func rechtsprechungLaden() async {
        guard let fall = viewModel.fall else { return }
        rsprLaeuft = true
        rsprFehler = nil
        defer { rsprLaeuft = false }
        let eigen = viewModel.argumente.filter { $0.side == .eigen }
        let gegner = viewModel.argumente.filter { $0.side == .gegner }
        let richter = viewModel.personen.first { $0.role == .richter }
        let prompt = """
        Du bist Rechtsprechungsexperte. Liefere NUR Rechtsprechung, Literatur und Taktikhinweise — KEINE Risikoberechnung.
        Fall: \(fall.fallname) | \(fall.rechtsgebiet ?? "") | Streitwert: \(fall.streitwert.map { "\(Int($0))€" } ?? "unbekannt")
        Zentrale Rechtsfrage: \(fall.zentrale_rechtsfrage ?? "")
        Eigene Argumente: \(eigen.map(\.title).joined(separator: ", "))
        Gegner-Argumente: \(gegner.map(\.title).joined(separator: ", "))
        Richter: \(richter.map { "\($0.name) (Klägerquote: \($0.klaeger_rate.map { "\($0)%" } ?? "?"))" } ?? "unbekannt")
        """
        do {
            let result: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt,
                schema: ["type": "object", "properties": [
                    "rechtsprechung": ["type": "array", "items": ["type": "object", "properties": [
                        "gericht": ["type": "string"], "aktenzeichen": ["type": "string"],
                        "datum": ["type": "string"], "leitsatz": ["type": "string"], "relevanz": ["type": "string"]
                    ]]],
                    "literatur": ["type": "array", "items": ["type": "object", "properties": [
                        "titel": ["type": "string"], "autor": ["type": "string"], "relevanz": ["type": "string"]
                    ]]],
                    "gegner_taktiken": ["type": "array", "items": ["type": "string"]],
                    "zusammenfassung": ["type": "string"]
                ]] as [String: Any],
                webContext: true,
                model: "gpt_5"
            )
            guard let d = result.dictValue else {
                await MainActor.run { rsprFehler = "Keine Rechtsprechung erhalten." }
                return
            }
            let rspr = (d["rechtsprechung"] as? [[String: Any]] ?? []).map {
                (gericht: $0["gericht"] as? String ?? "", aktenzeichen: $0["aktenzeichen"] as? String ?? "",
                 datum: $0["datum"] as? String ?? "", leitsatz: $0["leitsatz"] as? String ?? "",
                 relevanz: $0["relevanz"] as? String ?? "")
            }
            let lit = (d["literatur"] as? [[String: Any]] ?? []).map {
                (titel: $0["titel"] as? String ?? "", autor: $0["autor"] as? String ?? "",
                 relevanz: $0["relevanz"] as? String ?? "")
            }
            let parsed = RsprKIResult(
                rechtsprechung: rspr,
                literatur: lit,
                gegnerTaktiken: d["gegner_taktiken"] as? [String] ?? [],
                zusammenfassung: d["zusammenfassung"] as? String ?? ""
            )
            await MainActor.run { rsprErgebnis = parsed }
            await KIProtokollService.logResult(
                caseId: viewModel.caseId,
                kiName: "Monte Carlo Rechtsprechung",
                eingabe: prompt,
                result: result,
                modell: "gpt_5"
            )
        } catch {
            await MainActor.run { rsprFehler = error.localizedDescription }
        }
    }
    private func starten() {
        guard let fall = viewModel.fall else { return }
        simulationLaeuft = true
        Task.detached {
            let prognose = LegalAlgorithmsService.computePrognose(
                args: await viewModel.argumente,
                evidence: await viewModel.beweise,
                deadlines: await viewModel.fristen,
                persons: await viewModel.personen,
                caseData: fall
            )
            let mc = LegalAlgorithmsService.runMonteCarlo(
                baseResult: prognose,
                iterationen: await self.iterationen
            )
            await MainActor.run {
                self.prognoseErgebnis = prognose
                self.ergebnis = mc
                self.simulationLaeuft = false
            }
        }
    }
}
struct PrognoseHauptErgebnis: View {
    let prognose: PrognoseErgebnis
    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(prognose.score)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(prognoseColor(prognose.score))
                Text("Erfolgsprognose")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("90%-CI: [\(prognose.ciLow)%, \(prognose.ciHigh)%]")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 160)
            Divider().frame(height: 80)
            VStack(alignment: .leading, spacing: 8) {
                Text("Konfidenzintervall (90%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 24)
                        let low = CGFloat(prognose.ciLow) / 100
                        let high = CGFloat(prognose.ciHigh) / 100
                        RoundedRectangle(cornerRadius: 4)
                            .fill(prognoseColor(prognose.score).opacity(0.2))
                            .frame(
                                width: (high - low) * proxy.size.width,
                                height: 24
                            )
                            .offset(x: low * proxy.size.width)
                        let score = CGFloat(prognose.score) / 100
                        Rectangle()
                            .fill(prognoseColor(prognose.score))
                            .frame(width: 3, height: 32)
                            .offset(x: score * proxy.size.width - 1.5)
                    }
                }
                .frame(height: 32)
                HStack {
                    Text("0%")
                    Spacer()
                    Text("50%")
                    Spacer()
                    Text("100%")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            Divider().frame(height: 80)
            VStack(alignment: .leading, spacing: 4) {
                Text("Eingaben")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                InputZeile(label: "Eigene Argumente", wert: "\(prognose.inputs.eigeneArgs)")
                InputZeile(label: "Gegner-Argumente", wert: "\(prognose.inputs.gegnerArgs)")
                InputZeile(label: "Beweismittel", wert: "\(prognose.inputs.beweise)")
                InputZeile(label: "Fristen", wert: "\(prognose.inputs.fristen)")
                InputZeile(label: "Richter bekannt", wert: prognose.inputs.richterBekannt ? "Ja" : "Nein")
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(prognoseColor(prognose.score).opacity(0.2), lineWidth: 1.5))
    }
    private func prognoseColor(_ score: Int) -> Color {
        if score >= 65 { return .green }
        else if score >= 45 { return .orange }
        else { return .red }
    }
}
struct InputZeile: View {
    let label: String
    let wert: String
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(wert)
                .font(.system(size: 11, weight: .semibold))
        }
    }
}
struct MonteCarloErgebnisView: View {
    let ergebnis: MonteCarloErgebnis
    let iterationen: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Monte-Carlo-Simulation")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(iterationen.formatted()) Iterationen • Box-Muller-Transform (SIMD)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            let pie = outcomeVerteilung
            if pie.sieg + pie.vergleich + pie.niederlage > 0 {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    outcomeKarte("Sieg", pie.sieg, .green)
                    outcomeKarte("Vergleich", pie.vergleich, .orange)
                    outcomeKarte("Niederlage", pie.niederlage, .red)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("VERTEILUNG").font(.caption2.bold()).foregroundStyle(.secondary)
                    Chart(outcomePieData, id: \.name) { seg in
                        SectorMark(angle: .value("Anteil", seg.value), innerRadius: .ratio(0.45))
                            .foregroundStyle(seg.color)
                            .annotation(position: .overlay) {
                                if seg.value >= 5 {
                                    Text("\(seg.value)%").font(.caption2.bold()).foregroundStyle(.white)
                                }
                            }
                    }
                    .frame(height: 200)
                }
            }
            Chart(ergebnis.histogram) { bin in
                BarMark(
                    x: .value("Prognose", bin.bin),
                    y: .value("Häufigkeit", bin.count)
                )
                .foregroundStyle(
                    bin.pct >= 0.65 ? Color.green :
                    bin.pct >= 0.45 ? Color.orange : Color.red
                )
                .cornerRadius(2)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 5)) { value in
                    if let str = value.as(String.self) {
                        AxisValueLabel(str).font(.caption2)
                    }
                }
            }
            .frame(height: 180)
            PerzentilStreifen(ergebnis: ergebnis)
            SzenarienView(ergebnis: ergebnis)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.12), lineWidth: 1))
    }
    private struct OutcomePieSegment {
        let name: String
        let value: Int
        let color: Color
    }
    private var outcomeVerteilung: (sieg: Int, vergleich: Int, niederlage: Int) {
        let total = max(ergebnis.iterationen, 1)
        var sieg = 0, vergleich = 0, niederlage = 0
        for bin in ergebnis.histogram {
            if bin.pct >= 0.65 { sieg += bin.count }
            else if bin.pct >= 0.45 { vergleich += bin.count }
            else { niederlage += bin.count }
        }
        return (
            sieg: Int(round(Double(sieg) / Double(total) * 100)),
            vergleich: Int(round(Double(vergleich) / Double(total) * 100)),
            niederlage: Int(round(Double(niederlage) / Double(total) * 100))
        )
    }
    private var outcomePieData: [OutcomePieSegment] {
        let o = outcomeVerteilung
        return [
            OutcomePieSegment(name: "Sieg", value: o.sieg, color: .green),
            OutcomePieSegment(name: "Vergleich", value: o.vergleich, color: .orange),
            OutcomePieSegment(name: "Niederlage", value: o.niederlage, color: .red),
        ].filter { $0.value > 0 }
    }
    private func outcomeKarte(_ titel: String, _ wert: Int, _ farbe: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(wert)%").font(.title2.bold()).foregroundStyle(farbe)
            Text(titel).font(.caption.bold()).foregroundStyle(farbe.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(farbe.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.2)))
    }
}
struct PerzentilStreifen: View {
    let ergebnis: MonteCarloErgebnis
    var body: some View {
        HStack(spacing: 0) {
            ForEach([
                ("P10", ergebnis.p10, Color.red.opacity(0.7)),
                ("P25", ergebnis.p25, Color.orange.opacity(0.7)),
                ("Median", ergebnis.median, Color.blue),
                ("P75", ergebnis.p75, Color.teal.opacity(0.7)),
                ("P90", ergebnis.p90, Color.green.opacity(0.7))
            ], id: \.0) { label, wert, farbe in
                VStack(spacing: 4) {
                    Text("\(wert)%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(farbe)
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                if label != "P90" {
                    Divider()
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
struct SzenarienView: View {
    let ergebnis: MonteCarloErgebnis
    var body: some View {
        HStack(spacing: 12) {
            SzenarioKarte(
                titel: "Worst Case",
                wert: "\(ergebnis.szenarien.worstCase.wahrscheinlichkeit)%",
                erklaerung: ergebnis.szenarien.worstCase.erklaerung,
                farbe: .red,
                symbol: "arrow.down.circle.fill"
            )
            SzenarioKarte(
                titel: "Base Case",
                wert: "\(ergebnis.szenarien.baseCase.wahrscheinlichkeit)%",
                erklaerung: ergebnis.szenarien.baseCase.erklaerung,
                farbe: .blue,
                symbol: "arrow.right.circle.fill"
            )
            SzenarioKarte(
                titel: "Best Case",
                wert: "\(ergebnis.szenarien.bestCase.wahrscheinlichkeit)%",
                erklaerung: ergebnis.szenarien.bestCase.erklaerung,
                farbe: .green,
                symbol: "arrow.up.circle.fill"
            )
        }
    }
}
struct SzenarioKarte: View {
    let titel: String
    let wert: String
    let erklaerung: String
    let farbe: Color
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(farbe)
                Text(titel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(farbe)
            }
            Text(wert)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(farbe)
            Text(erklaerung)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.2), lineWidth: 1))
    }
}
