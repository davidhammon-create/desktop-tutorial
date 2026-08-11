import SwiftUI
import Charts

// MARK: - Argument-Zeitstrahl mit KI-Wahrscheinlichkeitsanalyse (wie ArgumentZeitstrahlChart.jsx)

struct ArgumentZeitstrahlChartView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

@State private var kiLaeuft = false
@State private var kiErgebnis: [String: Any]? = nil
@State private var zeigeKiPanel = false
@State private var fehler: String?

private struct Verbindung: Identifiable {
  let id = UUID()
  let vonId: String
  let nachId: String
  let typ: String
  let intensitaet: Int
  let erklaerung: String?
}

private var verbindungen: [Verbindung] {
  viewModel.argumente.flatMap { arg in
    (arg.connections ?? []).compactMap { c in
      guard let von = arg.id else { return nil }
      return Verbindung(vonId: von, nachId: c.targetId, typ: c.type, intensitaet: c.intensitaet ?? 5, erklaerung: c.explanation)
    }
  }
}

private var undatierteArgumente: [Argument] {
  viewModel.argumente.filter { ($0.zeitpunkt ?? "").isEmpty }
}

var body: some View {
  VStack(alignment: .leading, spacing: 12) {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("Argument-Zeitstrahl").font(.caption.bold())
        Text("Y = Stärke · X = juristisches Datum · Verbindungen = Einfluss")
          .font(.caption2).foregroundStyle(.secondary)
        if !undatierteArgumente.isEmpty {
          Text("\(undatierteArgumente.count) Argument(e) ohne Zeitpunkt -- bitte im Argument-Formular setzen")
            .font(.caption2).foregroundStyle(.orange)
        }
      }
      Spacer()
      if kiMode {
        Button {
          Task { await kiWahrscheinlichkeitsanalyse() }
        } label: {
          if kiLaeuft {
            ProgressView().scaleEffect(0.7)
            Text("KI analysiert…").font(.caption)
          } else {
            Label("KI-Wahrscheinlichkeitsanalyse", systemImage: "sparkles")
          }
        }
        .buttonStyle(FenlynineOSGlassProminentButtonStyle())
        .controlSize(.small)
        .disabled(kiLaeuft || viewModel.argumente.isEmpty)
      }
    }

    if let err = fehler {
      Text(err).font(.caption).foregroundStyle(.red)
    }

    if viewModel.argumente.isEmpty {
      InfoHinweis(titel: "Keine Argumente", nachricht: "Noch keine Argumente mit Zeitbezug vorhanden.", symbol: "calendar")
    } else {
      zeitstrahlChart
      if !verbindungen.isEmpty {
        let naive = naivePrognoseDelta
        HStack {
          Image(systemName: "chart.line.uptrend.xyaxis").font(.caption2).foregroundStyle(.secondary)
          Text("Naive Prognose-D:").font(.caption2).foregroundStyle(.secondary)
          Text(String(format: "%+.0f%%", naive * 100))
            .font(.caption.bold())
            .foregroundStyle(naive > 0 ? .green : naive < 0 ? .red : .secondary)
        }
      }
    }

    if zeigeKiPanel, let ki = kiErgebnis {
      kiErgebnisPanel(ki)
    }
  }
}

@ViewBuilder
private var zeitstrahlChart: some View {
  let punkte = chartPunkte
  Chart {
    ForEach(punkte) { p in
      PointMark(
        x: .value("Datum", p.datum),
       y: .value("Stärke", p.staerke)
     )
     .foregroundStyle(p.seite == .eigen ? .blue : .red)
     .symbolSize(p.hatZeitpunkt ? 80 : 40)
   }
 }
 .chartYScale(domain: 0...10)
 .frame(height: 220)

 ScrollView(.horizontal, showsIndicators: false) {
   HStack(spacing: 8) {
     ForEach(viewModel.argumente) { a in
       VStack(alignment: .leading, spacing: 2) {
         Text(a.title).font(.caption2).lineLimit(1)
         Text("\(a.side == .eigen ? "EIGEN" : "GEGNER") · \(Int(a.effectiveStrength))/10")
           .font(.system(size: 9)).foregroundStyle(.secondary)
       }
       .padding(6)
       .background((a.side == .eigen ? Color.blue : Color.red).opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
     }
   }
 }
}

private struct ChartPunkt: Identifiable {
 let id: String
 let datum: Date
 let staerke: Double
 let seite: Argument.ArgumentSeite
 let hatZeitpunkt: Bool
}

private var chartPunkte: [ChartPunkt] {
 viewModel.argumente.compactMap { a in
   guard let id = a.id else { return nil }
   let hatZeit = !(a.zeitpunkt ?? "").isEmpty
   let datum = hatZeit ? parseDatum(a.zeitpunkt!) : (a.created_at ?? Date())
   return ChartPunkt(id: id, datum: datum, staerke: a.effectiveStrength, seite: a.side, hatZeitpunkt: hatZeit)
 }
}

private var connProbMap: [String: Double] {
 [ "stützt": 0.15, "verstärkt": 0.20, "kausal": 0.12, "entkräftet": -0.18, "schwächt": -0.10, "widerspricht": -0.15, "schließt aus": -0.25 ]
}

private var naivePrognoseDelta: Double {
 verbindungen.reduce(0.0) { sum, c in
   let base = connProbMap[c.typ] ?? 0
   return sum + base * (Double(c.intensitaet) / 5.0)
 }
}

@ViewBuilder
private func kiErgebnisPanel(_ ki: [String: Any]) -> some View {
 VStack(alignment: .leading, spacing: 10) {
   HStack {
     Label("KI-Wahrscheinlichkeitsanalyse", systemImage: "sparkles").font(.caption.bold())
     Spacer()
     Button { zeigeKiPanel = false; kiErgebnis = nil } label: {
       Image(systemName: "xmark.circle").foregroundStyle(.secondary)
     }.buttonStyle(.plain)
   }

   if let delta = ki["prognose_delta"] as? Double {
     HStack {
       Text("Prognose-D:").font(.caption.bold())
       Text(String(format: "%+.0f%%", delta)).font(.title3.bold())
         .foregroundStyle(delta > 0 ? .green : delta < 0 ? .red : .secondary)
     }
   }
   if let erk = ki["prognose_erklaerung"] as? String, !erk.isEmpty {
     Text(erk).font(.caption).lineSpacing(3)
   }
   if let staerk = ki["staerkste_argument"] as? String, !staerk.isEmpty {
     Label("Stärkstes Argument: \(staerk)", systemImage: "star.fill").font(.caption2)
   }
   if let schw = ki["schwaechste_stelle"] as? String, !schw.isEmpty {
     Label("Schwächste Stelle: \(schw)", systemImage: "exclamationmark.triangle").font(.caption2).foregroundStyle(.orange)
   }
   if let emp = ki["handlungsempfehlung"] as? String, !emp.isEmpty {
     Text("Handlungsempfehlung").font(.caption.bold())
     Text(emp).font(.caption)
   }
   if let fristen = ki["kritische_fristen"] as? [String], !fristen.isEmpty {
     Text("Kritische Fristen").font(.caption.bold())
     ForEach(fristen, id: \.self) { f in Text("(cid:127) \(f)").font(.caption2) }
   }
   if let analyse = ki["verbindungen_analyse"] as? [[String: Any]], !analyse.isEmpty {
     Text("Verbindungsanalyse").font(.caption.bold())
     ForEach(Array(analyse.enumerated()), id: \.offset) { _, v in
       let von = v["von_titel"] as? String ?? "?"
       let nach = v["nach_titel"] as? String ?? "?"
       let typ = v["typ"] as? String ?? ""
       let prob = v["einfluss_wahrscheinlichkeit"] as? Double ?? 0
       Text("\(von) -> \(nach) [\(typ)]: \(Int(prob))%")
         .font(.caption2)
     }
   }
 }
 .padding(12)
 .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
}

private func parseDatum(_ s: String) -> Date {
 let iso = ISO8601DateFormatter()
 if let d = iso.date(from: s) { return d }
 let df = DateFormatter()
 df.locale = Locale(identifier: "de_DE")
 for fmt in ["yyyy-MM-dd", "dd.MM.yyyy", "dd.MM.yy"] {
   df.dateFormat = fmt
   if let d = df.date(from: s) { return d }
 }
 return Date()
}

private func formatDatum(_ d: Date) -> String {
 d.formatted(date: .numeric, time: .omitted)
}

private func kiWahrscheinlichkeitsanalyse() async {
 guard !viewModel.argumente.isEmpty else { return }
 kiLaeuft = true
 fehler = nil
 defer { kiLaeuft = false }

 let argDesc = viewModel.argumente.map { a in
   let datum = (a.zeitpunkt ?? "").isEmpty ? "Datum: unbekannt" : "Geäußert/Bewiesen: \(formatDatum(parseDatum(a.zeitpunkt!)))"
   return "[\(a.side == .eigen ? "EIGEN" : "GEGNER")] \"\(a.title)\" | Stärke: \(Int(a.effectiveStrength))/10 | \(datum)"
 }.joined(separator: "\n")

 let dlDesc = viewModel.fristen.isEmpty ? "Keine Fristen" : viewModel.fristen.map {
   "Frist: \"\($0.title)\" | Datum: \(formatDatum($0.due_date)) | Status: \($0.status.rawValue)"
 }.joined(separator: "\n")

 let connDesc = verbindungen.isEmpty ? "Keine Verbindungen" : verbindungen.map { c in
   let f = viewModel.argumente.first { $0.id == c.vonId }?.title ?? c.vonId
   let t = viewModel.argumente.first { $0.id == c.nachId }?.title ?? c.nachId
   return "\"\(f)\" \(c.typ) \"\(t)\" (Intensität \(c.intensitaet)/10)"
 }.joined(separator: "\n")

 let prompt = """
 Du bist ein KI-gestützter Rechtsanalyst. Analysiere die folgenden Argumente, Verbindungen und Fristen eines Rechtsstreits.

 ARGUMENTE (chronologisch):
 \(argDesc)

 VERBINDUNGEN:
 \(connDesc)

 FRISTEN:
 \(dlDesc)

 Aufgabe:
 1. Berechne für jede Verbindung eine Wahrscheinlichkeit (0-100%), wie stark dieses Argument das andere tatsächlich beeinflusst.
 2. Berechne die Gesamtprognose-Auswirkung aller Argumente zusammen (-30% bis +30%).
 3. Identifiziere kritische zeitliche Abhängigkeiten (Fristen die Argumente beeinflussen).
 4. Gib eine strategische Handlungsempfehlung.

 Sei präzise und verwende Wahrscheinlichkeitswerte.
 """

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "verbindungen_analyse": ["type": "array", "items": ["type": "object", "properties": [
         "von_titel": ["type": "string"], "nach_titel": ["type": "string"],
         "typ": ["type": "string"], "einfluss_wahrscheinlichkeit": ["type": "number"],
         "erklaerung": ["type": "string"]
       ]]],
       "prognose_delta": ["type": "number"],
       "prognose_erklaerung": ["type": "string"],
       "kritische_fristen": ["type": "array", "items": ["type": "string"]],
       "staerkste_argument": ["type": "string"],
       "schwaechste_stelle": ["type": "string"],
       "handlungsempfehlung": ["type": "string"]
     ]] as [String: Any],
     model: "claude_sonnet_4_6",
     logCaseId: viewModel.caseId,
     logKiName: "Argument-Zeitstrahl -- KI-Wahrscheinlichkeitsanalyse"
   )
   guard let dict = result.dictValue else {
     await MainActor.run { fehler = "Keine KI-Antwort erhalten." }
     return
   }
   await MainActor.run {
     kiErgebnis = dict
     zeigeKiPanel = true
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

