import SwiftUI
import Charts

// MARK: - Tab10 Abschluss Monte-Carlo-Kalibrierung (wie Tab10Abschluss.jsx)

struct AbschlussMonteCarloView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

@State private var laeuft = false
@State private var mcErgebnis: AbschlussMonteCarloErgebnis?
@State private var kiAcc: KITreffsicherheitErgebnis?
@State private var manualNotes = ""
@State private var gespeichert = false
@State private var fehler: String?

var body: some View {
  VStack(alignment: .leading, spacing: 16) {
    VStack(alignment: .leading, spacing: 8) {
      Text("Schritt 10 / Abschluss & Kalibrierung").font(.caption).foregroundStyle(.white.opacity(0.7))
      Text("Stochastische Gesamtbewertung").font(.title3.bold()).foregroundStyle(.white)
      Text("Kumuliert alle Faktoren, KI-Analysen und Falldaten. Zwei Szenarien: KI liegt richtig vs. falsch.")
        .font(.caption).foregroundStyle(.white.opacity(0.85))
      Button {
        Task { await analyseStarten() }
      } label: {
        if laeuft {
          ProgressView().scaleEffect(0.7)
          Text("Monte Carlo läuft…").font(.caption)
        } else {
          Label("Analyse starten (3.000 Simulationen)", systemImage: "dice.fill")
        }
      }
      .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
      .tint(.white)
      .disabled(laeuft)
    }
    .padding(16)
    .background(LinearGradient(colors: [.gray, .black.opacity(0.85)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 12))

    if let err = fehler {
      Text(err).font(.caption).foregroundStyle(.red)
    }

    faktorenUebersicht

    if let mc = mcErgebnis, let acc = kiAcc {
      kiTreffsicherheitPanel(acc)
      monteCarloErgebnisPanel(mc, accuracy: acc.accuracy)
      speichernBereich(combinedMean: mc.combinedMean)
    }

    KIFeedbackPanelView(caseId: viewModel.caseId)
  }
  .onAppear {
    manualNotes = viewModel.fall?.notes ?? ""
  }
}

@ViewBuilder
private var faktorenUebersicht: some View {
  let eigen = viewModel.argumente.filter { $0.side == .eigen }
  let gegner = viewModel.argumente.filter { $0.side == .gegner }
  let krit = viewModel.warnungen.filter { !$0.resolved && $0.severity == .kritisch }.count

  VStack(alignment: .leading, spacing: 8) {
    Text("Eingabefaktoren").font(.caption.bold())
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
      FaktorChip(label: "Eigene Argumente", wert: eigen.count, max: 10)
      FaktorChip(label: "Beweise", wert: viewModel.beweise.count, max: 10)
      FaktorChip(label: "Gegner-Argumente", wert: gegner.count, max: 10)
      FaktorChip(label: "Krit. Warnungen", wert: krit, max: 5, invertiert: true)
    }
    if let p = viewModel.fall?.prognose {
      Text("Algorithmus-Prognose: \(Int(p))%").font(.caption2).foregroundStyle(.secondary)
    }
  }
  .padding(12)
  .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}

@ViewBuilder
private func kiTreffsicherheitPanel(_ acc: KITreffsicherheitErgebnis) -> some View {
  VStack(alignment: .leading, spacing: 8) {
    Text("Geschätzte KI-Treffsicherheit").font(.caption.bold())
    HStack {
      Text("\(acc.accuracy)%").font(.title.bold()).foregroundStyle(.purple)
      Text("Wahrscheinlichkeit korrekte KI-Analyse").font(.caption2).foregroundStyle(.secondary)
    }
    ForEach(Array(acc.factors.enumerated()), id: \.offset) { _, f in
      HStack {
        Text(f.label).font(.caption2)
        Spacer()
        Text(f.delta >= 0 ? "+\(f.delta)%" : "\(f.delta)%")
          .font(.caption2.bold())
          .foregroundStyle(f.delta >= 0 ? .green : .red)
      }
    }
  }
 .padding(12)
 .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
}

@ViewBuilder
private func monteCarloErgebnisPanel(_ mc: AbschlussMonteCarloErgebnis, accuracy: Int) -> some View {
 VStack(alignment: .leading, spacing: 12) {
   Text("Monte-Carlo-Ergebnis").font(.caption.bold())
   HStack(spacing: 20) {
     prognoseGauge(wert: Double(mc.combinedMean), p5: mc.combinedP5, p95: mc.combinedP95, titel: "Gewichtet")
     prognoseGauge(wert: mc.correct.mean, p5: mc.correct.p5, p95: mc.correct.p95, titel: "KI richtig")
     prognoseGauge(wert: mc.wrong.mean, p5: mc.wrong.p5, p95: mc.wrong.p95, titel: "KI falsch")
   }
   Text("KI-Einfluss auf Varianz: \(mc.kiInfluence)% · s kombiniert: \(String(format: "%.1f", mc.combinedStd))")
     .font(.caption2).foregroundStyle(.secondary)

   Chart(mc.combinedHist) { bin in
     BarMark(x: .value("Range", bin.range), y: .value("Count", bin.count))
       .foregroundStyle(.blue)
   }
   .frame(height: 120)
 }
 .padding(12)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}

@ViewBuilder
private func prognoseGauge(wert: Double, p5: Double, p95: Double, titel: String) -> some View {
 VStack(spacing: 4) {
   Text(titel).font(.caption2).foregroundStyle(.secondary)
   Text("\(Int(wert.rounded()))%").font(.title2.bold())
     .foregroundStyle(wert >= 60 ? .green : wert >= 40 ? .orange : .red)
   Text("\(Int(p5))-\(Int(p95))%").font(.system(size: 9)).foregroundStyle(.secondary)
 }
}

@ViewBuilder
private func speichernBereich(combinedMean: Int) -> some View {
 VStack(alignment: .leading, spacing: 8) {
   Text("Notizen & Prognose speichern").font(.caption.bold())
   TextField("Abschlussnotizen…", text: $manualNotes, axis: .vertical)
     .lineLimit(2...4)
     .textFieldStyle(.roundedBorder)
   Text("Speichert Notizen und überschreibt die Fall-Prognose mit dem gewichteten Monte-Carlo-Median (\(combinedMean)%).")
     .font(.caption2).foregroundStyle(.secondary)
   Button(gespeichert ? "3 Gespeichert" : "Ergebnisse speichern") {
     Task { await ergebnisseSpeichern(median: combinedMean) }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(gespeichert)
 }
 .padding(12)
 .background(Color.green.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}

private func analyseStarten() async {
 laeuft = true
 fehler = nil
 defer { laeuft = false }

 guard let fall = viewModel.fall else { return }
 let algoPrognose = fall.prognose ?? 50
 let kiDict = fall.ki_berater_result?.dictValue
 let momentum = kiDict?["timing"] as? [String: Any]
 let momentumPct = momentum?["momentum_pct"] as? Double
 let kiPrognose = momentumPct.map { algoPrognose * 0.6 + $0 * 0.4 } ?? algoPrognose
 let kiAvail = kiDict != nil

 let krit = viewModel.warnungen.filter { !$0.resolved && $0.severity == .kritisch }.count
 let hoch = viewModel.warnungen.filter { !$0.resolved && $0.severity == .hoch }.count
 let complianceScore = max(0, 1 - (Double(krit) * 0.3 + Double(hoch) * 0.1))
 let negativeBehaviors = viewModel.gegnerVerhalten.filter { $0.auswirkung_prognose < 0 }.count
 let risikoScore = min(1, Double(negativeBehaviors) * 0.15)

 let accBase = AbschlussMonteCarloEngine.estimateKiAccuracy(
   args: viewModel.argumente,
   evs: viewModel.beweise,
   warnings: viewModel.warnungen.filter { !$0.resolved },
   behaviors: viewModel.gegnerVerhalten,
   kiResult: fall.ki_berater_result
 )
 let feedbackLogs = await KIFeedbackPanelView.feedbackLogsForCase(viewModel.caseId)
 let adjustedAccuracy = AbschlussMonteCarloEngine.feedbackAdjustedAccuracy(
   baseAccuracy: accBase.accuracy,
   feedbackLogs: feedbackLogs
 )
 var acc = accBase
 if adjustedAccuracy != accBase.accuracy {
   acc = KITreffsicherheitErgebnis(
     accuracy: adjustedAccuracy,
     factors: accBase.factors + [(label: "Feedback-Kalibrierung", delta: adjustedAccuracy - accBase.accuracy, formula: "Ø Bewertung x Multiplikator")]
   )
 }

 let inputs = AbschlussMonteCarloInputs(
   algoPrognose: algoPrognose,
   kiPrognose: kiPrognose,
   kiAvail: kiAvail,
   complianceScore: complianceScore,
   risikoScore: risikoScore,
   argCount: viewModel.argumente.count,
   evidenceCount: viewModel.beweise.count,
   kiAccuracy: Double(acc.accuracy)
 )

 let result = AbschlussMonteCarloEngine.runMonteCarlo(inputs: inputs, n: 3000)
 await MainActor.run {
   kiAcc = acc
   mcErgebnis = result
 }
}

private func ergebnisseSpeichern(median: Int) async {
 guard var fall = viewModel.fall, let id = fall.id else { return }
 fall.notes = manualNotes
 fall.prognose = Double(median)
 do {
   let saved = try await Services.cases.update(id: id, entity: fall)
   await MainActor.run {
     viewModel.fall = saved
     gespeichert = true
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

private struct FaktorChip: View {
let label: String
let wert: Int
let max: Int
var invertiert: Bool = false

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   HStack {
     Text(label).font(.caption2)
     Spacer()
     Text("\(wert)/\(max)").font(.caption2).foregroundStyle(.secondary)
   }
   ProgressView(value: Double(min(wert, max)), total: Double(max))
     .tint(invertiert && wert > 0 ? .red : .blue)
 }
}
}

