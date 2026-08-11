import SwiftUI
import Charts

// MARK: - Prognose-Vergleich (wie TabPrognoseVergleich.jsx)

struct TabPrognoseVergleichView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

struct PrognoseEintrag: Identifiable {
  let id: String
  let label: String
  let reiter: String
  let wert: Int
  let farbe: Color
  let methode: String
  let faktoren: [String]
  let beschreibung: String
}

struct KIErklaerung: Decodable {
  var abweichungs_erklaerung: String?
  var verlasslichste_prognose: String?
  var begruendung_verlasslich: String?
  var top_faktoren: [TopFaktor]?
  var verbesserungsmassnahmen: [Verbesserung]?
  var gesamtbewertung: String?

  struct TopFaktor: Decodable {
    var faktor: String?
    var einfluss: String?
    var richtung: String?
  }

  struct Verbesserung: Decodable {
    var massnahme: String?
    var erwartete_wirkung: String?
    var prioritaet: String?
  }
}

@State private var kiErklaerung: KIErklaerung?
@State private var kiLaeuft = false
@State private var aufgeklappt: Set<String> = []
@State private var kiFehler: String?
@State private var chartMode = 0

private var algoResult: VollanalyseErgebnis? {
  guard let fall = viewModel.fall else { return nil }
  return LegalAlgorithmsService.computeVollanalyse(
    args: viewModel.argumente,
    evidence: viewModel.beweise,
    deadlines: viewModel.fristen,
    persons: viewModel.personen,
    caseData: fall
  )
}

private var prognosen: [PrognoseEintrag] {
  guard let fall = viewModel.fall, let algo = algoResult else { return [] }
  let args = viewModel.argumente
  let evidence = viewModel.beweise
  let deadlines = viewModel.fristen

  var list: [PrognoseEintrag] = []

  let strategie = computeStrategiePrognose(args: args, evidence: evidence, deadlines: deadlines, persons: viewModel.personen, fall: fall)
  list.append(PrognoseEintrag(
    id: "manuell",
    label: "Manuelle Prognose",
    reiter: "Reiter 6 · Strategie",
    wert: Int(fall.prognose ?? Double(strategie)),
    farbe: .blue,
    methode: "Manuell gespeichert oder aus dem 6-Stufen-Algorithmus",
    faktoren: [
      "Argumente: \(args.filter { $0.side == .eigen }.count) eigen / \(args.filter { $0.side == .gegner }.count) Gegner",
      "Beweise: \(evidence.count) Stück",
      "Richter-Klägerquote: \(Int(fall.richter_klaeger_rate ?? 50))%",
      "Versäumte Fristen: \(deadlines.filter { $0.status == .versaeumt }.count)"
    ],
    beschreibung: "Der einfache 6-Stufen-Algorithmus berechnet eine Basisprognose aus Argumentstärke, Beweislage, Widersprüchen, Glaubwürdigkeit der Zeugen, Richter-Kalibrierung und Fristenrisiko."
  ))

  let prozess = computeProzessStaerke(args: args, evidence: evidence, deadlines: deadlines, fall: fall)
  list.append(PrognoseEintrag(
    id: "prozessstaerke",
    label: "Prozessstärke-Score",
    reiter: "Reiter 6 · Strategie (unten)",
    wert: prozess,
    farbe: .purple,
    methode: "Gewichtete Faktoren-Matrix (5 Dimensionen)",
    faktoren: ["Argumente-Balance (30%)", "Beweislage (20%)", "Fristen-Risiko (20%)", "Gegnerverhalten (15%)", "Richter-Profil (15%)"],
    beschreibung: "Gewichtetes Mittel aus 5 unabhängigen Faktoren -- stärker berücksichtigt Gegnerverhalten und Fristen-Überfälligkeit."
  ))

  list.append(PrognoseEintrag(
    id: "bayes",
    label: "Bayesianische Prognose",
    reiter: "Reiter 6 · Risikoformeln",
   wert: algo.prognose.score,
   farbe: .green,
   methode: "Bayesianisches Modell mit Log-Odds + s-Funktion",
   faktoren: [
     "Konfidenzintervall: [\(algo.prognose.ciLow)%, \(algo.prognose.ciHigh)%]",
     "Unsicherheit s: \(String(format: "%.1f", algo.prognose.sigma * 100))pp",
     "\(algo.prognose.schritte.count) Berechnungsschritte",
     "Gesamtrisiko: \(algo.risikofaktoren.gesamtrisiko.capitalized)"
   ],
   beschreibung: "Mathematisch robuster als lineare Multiplikation -- extreme Werte werden abgefangen."
 ))

 list.append(PrognoseEintrag(
   id: "montecarlo",
   label: "Monte Carlo Median",
   reiter: "Reiter 6 · Risikoformeln",
   wert: algo.monteCarlo.median,
   farbe: .orange,
   methode: "\(algo.monteCarlo.iterationen.formatted()) stochastische Simulationen",
   faktoren: [
     "P10: \(algo.monteCarlo.p10)%",
     "Median: \(algo.monteCarlo.median)%",
     "P90: \(algo.monteCarlo.p90)%"
   ],
   beschreibung: "Simuliert tausende Szenarien mit zufälligen Abweichungen -- zeigt die realistische Bandbreite."
 ))

 return list
}

var body: some View {
 VStack(spacing: 16) {
   if let err = kiFehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }
   if prognosen.isEmpty {
     ProgressView("Lade und berechne alle Prognosen…")
       .frame(maxWidth: .infinity, minHeight: 200)
   } else {
     let minP = prognosen.map(\.wert).min() ?? 0
     let maxP = prognosen.map(\.wert).max() ?? 0
     let spanne = maxP - minP

     // Header
     VStack(alignment: .leading, spacing: 10) {
       Text("PROGNOSE-VERGLEICH -- ALLE MODELLE")
         .font(.caption2.bold()).foregroundStyle(.secondary)
       HStack(alignment: .bottom) {
         VStack(alignment: .leading, spacing: 4) {
           Text("\(prognosen.count) Prognosen").font(.largeTitle.bold())
           Text("Spannweite: \(minP)% - \(maxP)% (D \(spanne)pp)")
             .font(.caption).foregroundStyle(.secondary)
         }
         Spacer()
         if kiMode {
           Button { Task { await kiErklaerungStarten() } } label: {
             if kiLaeuft {
               ProgressView().scaleEffect(0.7)
               Text("Analysiere Unterschiede…").font(.caption)
             } else {
               Label("KI erklärt die Unterschiede", systemImage: "sparkles")
             }
           }
           .buttonStyle(FenlynineOSGlassProminentButtonStyle())
           .disabled(kiLaeuft)
         }
       }
       if spanne >= 15 {
         Label("Hohe Abweichung (\(spanne)pp) -- KI-Erklärung empfohlen", systemImage: "exclamationmark.triangle.fill")
           .font(.caption).foregroundStyle(.orange)
           .padding(8)
           .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
       }
     }
     .padding(14)
     .background(Color.primary.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
     .foregroundStyle(.white)

     // Kreise + Chart
     VStack(alignment: .leading, spacing: 12) {
       HStack {
         Text("Alle Prognosen auf einen Blick").font(.subheadline.bold())
         Spacer()
         Picker("", selection: $chartMode) {
           Text("Balken").tag(0)
           Text("Radar").tag(1)
         }
         .pickerStyle(.segmented)
         .frame(width: 150)
       }
       ScrollView(.horizontal, showsIndicators: false) {
         HStack(spacing: 20) {
           ForEach(prognosen) { p in
             PrognoseKreisView(wert: p.wert, label: p.label, farbe: p.farbe)
           }
         }
       }
       if chartMode == 0 {
         Chart(prognosen) { p in
           BarMark(x: .value("Prognose", p.wert), y: .value("Modell", p.label))
             .foregroundStyle(p.farbe)
         }
         .frame(height: CGFloat(prognosen.count * 36 + 20))
       } else {
         LexaraRadarChartView(
           data: prognosen.map { (label: String($0.label.prefix(14)), value: Double($0.wert)) },
           maxValue: 100,
           fillColor: .blue,
           strokeColor: .purple
         )
         .frame(height: 260)
       }
     }
     .padding(14)
     .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

     // Detailkarten
     Text("Warum diese Prognose? -- Einzelerklärungen").font(.subheadline.bold())
     ForEach(prognosen) { p in
       PrognoseDetailKarte(eintrag: p, aufgeklappt: aufgeklappt.contains(p.id)) {
         if aufgeklappt.contains(p.id) { aufgeklappt.remove(p.id) }
         else { aufgeklappt.insert(p.id) }
       }
     }

     // KI-Erklärung
     if let ki = kiErklaerung {
       prognoseKIErklaerungView(ki)
     } else if !kiLaeuft && kiMode {
       InfoHinweis(
         titel: "KI-Analyse",
         nachricht: "Klicken Sie auf \u{201E}KI erklärt die Unterschiede\u{201C} für eine detaillierte Analyse warum die Prognosen variieren.",
         symbol: "sparkles"
       )
     }
   }
 }
 .onAppear { hydratePrognoseKI() }
}

private func hydratePrognoseKI() {
 guard kiErklaerung == nil,
    let d = viewModel.fall?.ki_berater_result?.dictValue?["prognose_vergleich"] as? [String: Any]
 else { return }
 kiErklaerung = KIErklaerung(
   abweichungs_erklaerung: d["abweichungs_erklaerung"] as? String,
   verlasslichste_prognose: d["verlasslichste_prognose"] as? String,
   gesamtbewertung: d["empfehlung"] as? String
 )
}

@ViewBuilder
private func prognoseKIErklaerungView(_ ki: KIErklaerung) -> some View {
 VStack(alignment: .leading, spacing: 12) {
   Label("KI-Analyse der Prognose-Unterschiede", systemImage: "sparkles")
     .font(.subheadline.bold()).foregroundStyle(.purple)

   if let t = ki.gesamtbewertung {
     KIProfilKarte(titel: "Gesamtbewertung", inhalt: t)
   }
   if let t = ki.abweichungs_erklaerung {
     VStack(alignment: .leading, spacing: 6) {
       Text("Warum weichen die Prognosen ab?").font(.caption.bold())
       Text(t).font(.caption).lineSpacing(3)
     }
     .padding(12)
     .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
   }
   if let t = ki.verlasslichste_prognose {
     VStack(alignment: .leading, spacing: 4) {
       Text("Verlässlichste Prognose").font(.caption.bold()).foregroundStyle(.green)
       Text(t).font(.subheadline.bold())
       if let b = ki.begruendung_verlasslich {
         Text(b).font(.caption).foregroundStyle(.secondary)
       }
     }
     .padding(12)
     .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
   }
   if let faktoren = ki.top_faktoren, !faktoren.isEmpty {
     VStack(alignment: .leading, spacing: 8) {
       Text("Die 3 stärksten Einfluss-Faktoren").font(.caption.bold())
       ForEach(Array(faktoren.prefix(3).enumerated()), id: \.offset) { _, f in
         VStack(alignment: .leading, spacing: 2) {
           Text(f.faktor ?? "").font(.caption.bold())
           Text(f.einfluss ?? "").font(.caption2).foregroundStyle(.secondary)
         }
         .padding(8)
         .frame(maxWidth: .infinity, alignment: .leading)
         .background(farbeFuerRichtung(f.richtung).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
       }
     }
   }
   if let massnahmen = ki.verbesserungsmassnahmen, !massnahmen.isEmpty {
     VStack(alignment: .leading, spacing: 8) {
       Text("Konkrete Verbesserungsmaßnahmen").font(.caption.bold())
       ForEach(Array(massnahmen.enumerated()), id: \.offset) { _, m in
         HStack(alignment: .top, spacing: 8) {
           Text((m.prioritaet ?? "mittel").uppercased())
             .font(.system(size: 8, weight: .bold))
             .padding(.horizontal, 4).padding(.vertical, 2)
             .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
           VStack(alignment: .leading, spacing: 2) {
             Text(m.massnahme ?? "").font(.caption.bold())
             Text(m.erwartete_wirkung ?? "").font(.caption2).foregroundStyle(.secondary)
           }
         }
       }
     }
   }
 }
}

private func farbeFuerRichtung(_ r: String?) -> Color {
 switch r {
 case "positiv": return .green
 case "negativ": return .red
 default: return .gray
 }
}

private func kiErklaerungStarten() async {
 guard let fall = viewModel.fall, !prognosen.isEmpty else { return }
 kiLaeuft = true
 kiFehler = nil
 defer { kiLaeuft = false }

 let args = viewModel.argumente
 let evidence = viewModel.beweise
 let deadlines = viewModel.fristen
 let prompt = """
 Du bist ein erfahrener Rechtsanwalt und Statistiker. Erkläre einem Mandanten (nicht-technisch) warum die folgenden Prognosen für seinen Fall unterschiedlich ausfallen.

 FALL: \(fall.fallname) | \(fall.rechtsgebiet ?? "") | Instanz: \(fall.instanz.rawValue)
 Zentrale Frage: \(fall.zentrale_rechtsfrage ?? "")

 PROGNOSEN IM VERGLEICH:
 \(prognosen.map { "(cid:127) \($0.label) (\($0.reiter)): \($0.wert)% -- Methode: \($0.methode)" }.joined(separator: "\n"))

 FALL-DATEN:
 - Argumente: \(args.filter { $0.side == .eigen }.count) eigene, \(args.filter { $0.side == .gegner }.count) Gegner-Argumente
 - Beweise: \(evidence.count) Stück
 - Versäumte Fristen: \(deadlines.filter { $0.status == .versaeumt }.count)
 - Richter-Klägerquote: \(fall.richter_klaeger_rate ?? 50)%

 Beantworte: 1) WARUM weichen die Prognosen ab? 2) WELCHE ist am verlässlichsten? 3) Top-3-Faktoren 4) Verbesserungsmaßnahmen
 """

 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "abweichungs_erklaerung": ["type": "string"],
     "verlasslichste_prognose": ["type": "string"],
     "begruendung_verlasslich": ["type": "string"],
     "top_faktoren": [
       "type": "array",
       "items": [
         "type": "object",
         "properties": [
           "faktor": ["type": "string"],
           "einfluss": ["type": "string"],
           "richtung": ["type": "string", "enum": ["positiv", "negativ", "neutral"]]
         ]
       ]
     ],
     "verbesserungsmassnahmen": [
       "type": "array",
       "items": [
         "type": "object",
         "properties": [
           "massnahme": ["type": "string"],
           "erwartete_wirkung": ["type": "string"],
           "prioritaet": ["type": "string", "enum": ["hoch", "mittel", "niedrig"]]
         ]
       ]
     ],
     "gesamtbewertung": ["type": "string"]
   ]
 ]

 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: schema,
     model: "claude_sonnet_4_6",
     logCaseId: viewModel.caseId,
     logKiName: "Prognose-Vergleich -- KI-Erklärung"
   )
   let erklaerung = TabPrognoseVergleichView.KIErklaerung(
     abweichungs_erklaerung: KIJson.string(in: d, keys: "abweichungs_erklaerung"),
     verlasslichste_prognose: KIJson.string(in: d, keys: "verlasslichste_prognose"),
     begruendung_verlasslich: KIJson.string(in: d, keys: "begruendung_verlasslich"),
     top_faktoren: (KIJson.array(in: d, keys: "top_faktoren") as [[String: Any]]).map {
       TabPrognoseVergleichView.KIErklaerung.TopFaktor(
         faktor: KIJson.string(in: $0, keys: "faktor"),
         einfluss: KIJson.string(in: $0, keys: "einfluss"),
         richtung: KIJson.string(in: $0, keys: "richtung")
       )
     },
     verbesserungsmassnahmen: (KIJson.array(in: d, keys: "verbesserungsmassnahmen") as [[String: Any]]).map {
       TabPrognoseVergleichView.KIErklaerung.Verbesserung(
         massnahme: KIJson.string(in: $0, keys: "massnahme"),
         erwartete_wirkung: KIJson.string(in: $0, keys: "erwartete_wirkung"),
         prioritaet: KIJson.string(in: $0, keys: "prioritaet")
       )
     },
     gesamtbewertung: KIJson.string(in: d, keys: "gesamtbewertung")
   )
   await MainActor.run { kiErklaerung = erklaerung }
   if var fallUpd = viewModel.fall {
     let saved = try await KIResultStore.mergeBeraterSubKey(
       caseId: viewModel.caseId,
       fall: &fallUpd,
       key: "prognose_vergleich",
       value: d
     )
     await MainActor.run { viewModel.fall = saved }
   }
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}

// MARK: - Algorithmen (wie Original)

private func computeStrategiePrognose(args: [Argument], evidence: [Evidence], deadlines: [Deadline], persons: [Person], fall: LegalCase) -> Int {
 let eigene = args.filter { $0.side == .eigen }
 let gegner = args.filter { $0.side == .gegner }
 let eigenStaerke = eigene.reduce(0.0) { $0 + Double($1.strength ?? 5) }
 let gegnerStaerke = gegner.reduce(0.0) { $0 + Double($1.strength ?? 5) }
 let argBasis: Double = (eigene.count > 0 || gegner.count > 0)
   ? max(0, ((eigenStaerke / max(1, Double(eigene.count))) - (gegnerStaerke / max(1, Double(gegner.count)))) * 5 + 50)
   : 50
 let avgEvidW = evidence.isEmpty ? 5.0 : evidence.reduce(0.0) { $0 + Double($1.weight ?? 5) } / Double(evidence.count)
 let beweisBoost = 1 + (avgEvidW / 10) * 0.5
 let contradictions = 0
 let kantenEffekt = max(0.2, 1 - Double(contradictions) * 0.2)
 let judges = persons.filter { $0.role == .richter }
 let avgGlaubw = judges.isEmpty ? 80.0 : judges.reduce(0.0) { $0 + Double($1.glaubwuerdigkeit ?? 80) } / Double(judges.count)
 let zeugenMult = 0.70 + (avgGlaubw / 100) * 0.30
 let richterRate = Double(judges.first?.klaeger_rate ?? Int(fall.richter_klaeger_rate ?? 50))
 let richterAdj = 1 + (richterRate - 50) / 100 * 0.15
 let versaeumt = deadlines.filter { $0.status == .versaeumt }.count
 let fristenFaktor = max(0.5, 1 - Double(versaeumt) * 0.30)
 let raw = argBasis * beweisBoost * kantenEffekt * zeugenMult * richterAdj * fristenFaktor
 return min(99, max(1, Int(raw.rounded())))
}

private func computeProzessStaerke(args: [Argument], evidence: [Evidence], deadlines: [Deadline], fall: LegalCase) -> Int {
 let eigenArgs = args.filter { $0.side == .eigen }
 let gegnerArgs = args.filter { $0.side == .gegner }
 let eigenStaerke = eigenArgs.isEmpty ? 5.0 : eigenArgs.reduce(0.0) { $0 + Double($1.strength ?? 5) } / Double(eigenArgs.count)
 let gegnerStaerke = gegnerArgs.isEmpty ? 5.0 : gegnerArgs.reduce(0.0) { $0 + Double($1.strength ?? 5) } / Double(gegnerArgs.count)
 let argScore = min(100, max(0, (eigenStaerke - gegnerStaerke) * 5 + 50))
 let beweisScore = evidence.isEmpty ? 50.0 : min(100, evidence.reduce(0.0) { $0 + Double($1.weight ?? 5) } / Double(evidence.count) * 10)
 let versaeumt = deadlines.filter { $0.status == .versaeumt }.count
 let ueberfaellig = deadlines.filter { $0.status == .offen && $0.due_date < Date() }.count
 let fristenScore = max(0, 100 - versaeumt * 25 - ueberfaellig * 10)
 let richterScore = fall.richter_klaeger_rate ?? 50
 return Int((argScore * 0.30 + beweisScore * 0.20 + Double(fristenScore) * 0.20 + 50 * 0.15 + richterScore * 0.15).rounded())
}
}

struct PrognoseKreisView: View {
let wert: Int
let label: String
let farbe: Color

var body: some View {
 VStack(spacing: 6) {
   ZStack {
     Circle().stroke(Color.gray.opacity(0.2), lineWidth: 6)
     Circle()
       .trim(from: 0, to: CGFloat(wert) / 100)
       .stroke(farbe, style: StrokeStyle(lineWidth: 6, lineCap: .round))
       .rotationEffect(.degrees(-90))
     Text("\(wert)%").font(.caption.bold())
   }
   .frame(width: 72, height: 72)
   Text(label).font(.system(size: 9)).multilineTextAlignment(.center).frame(width: 90)
 }
}
}

struct PrognoseDetailKarte: View {
let eintrag: TabPrognoseVergleichView.PrognoseEintrag
let aufgeklappt: Bool
let onToggle: () -> Void

var body: some View {
 VStack(spacing: 0) {
   Button(action: onToggle) {
     HStack(spacing: 12) {
       Text("\(eintrag.wert)")
         .font(.caption.bold()).foregroundStyle(.white)
         .frame(width: 36, height: 36)
         .background(eintrag.farbe, in: Circle())
       VStack(alignment: .leading, spacing: 2) {
         Text(eintrag.label).font(.subheadline.bold())
         Text("\(eintrag.reiter) · \(eintrag.methode)").font(.caption2).foregroundStyle(.secondary)
       }
       Spacer()
       FenlynineOSTransparenzInfoButton(inhalt: TransparenzInhalt(
         titel: eintrag.label,
         quelle: eintrag.methode.lowercased().contains("ki") ? .ki : .algorithmus,
         modell: eintrag.methode,
         ergebnis: "\(eintrag.wert)%",
         begruendung: eintrag.beschreibung,
         erklaerung: eintrag.faktoren.joined(separator: " · ")
       ))
       Image(systemName: aufgeklappt ? "chevron.down" : "chevron.right").font(.caption2)
     }
     .padding(12)
   }
   .buttonStyle(.plain)

   if aufgeklappt {
     VStack(alignment: .leading, spacing: 8) {
       Text(eintrag.beschreibung).font(.caption).foregroundStyle(.secondary)
       Text("Eingeflossene Faktoren").font(.caption2.bold()).foregroundStyle(.tertiary)
       ForEach(eintrag.faktoren, id: \.self) { f in
         Text("(cid:127) \(f)").font(.caption2)
       }
     }
     .padding(.horizontal, 12).padding(.bottom, 12)
     .background(Color.gray.opacity(0.03))
   }
 }
 .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}
}

