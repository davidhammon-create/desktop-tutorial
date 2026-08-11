import SwiftUI

// MARK: - Gegner-Strategie Dashboard (OpponentStrategyDashboard.jsx)

struct GegnerStrategieDashboardView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true

@State private var laeuft = false
@State private var matrix: [MatrixZelle] = []
@State private var counterMoves: [CounterMove] = []
@State private var hauptbedrohung: Hauptbedrohung?
@State private var fehler: String?

struct MatrixZelle: Identifiable {
  let id = UUID()
  var gegnerArgId: String?
  var evidenceId: String?
  var gegnerArgTitle: String
  var evidenceTitle: String
  var score: Double
  var reasoning: String?
}

struct CounterMove: Identifiable {
  let id = UUID()
  var typ: String
  var titel: String
  var beschreibung: String
  var gegnerArg: String?
  var unsereStrategie: String?
  var timing: String?
  var erfolgsaussicht: Int?
}

struct Hauptbedrohung {
  var argument: String
  var grund: String
  var severity: String
}

private var gegnerArgs: [Argument] { viewModel.argumente.filter { $0.side == .gegner } }
private var evidence: [Evidence] { viewModel.beweise }

var body: some View {
  VStack(spacing: 16) {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Gegner-Strategie Dashboard")
          .font(.system(size: 16, weight: .bold))
        Text("KI-gestützte Gegen-Schachzug-Matrix & taktische Analyse")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button {
        Task { await kiAnalyseStarten() }
      } label: {
        if laeuft {
          ProgressView().scaleEffect(0.7)
          Text("Analysiere…").font(.caption)
        } else {
          Label(matrix.isEmpty ? "KI-Analyse starten" : "Neu analysieren", systemImage: "sparkles")
        }
      }
      .buttonStyle(FenlynineOSGlassProminentButtonStyle())
      .tint(.red)
      .disabled(laeuft || !kiMode || gegnerArgs.isEmpty)
    }
    .padding(14)
    .background(Color.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.15)))

    if let err = fehler {
      Text(err).font(.caption).foregroundStyle(.red)
    }

    if let bedrohung = hauptbedrohung {
      VStack(alignment: .leading, spacing: 6) {
        Label("Hauptbedrohung erkannt", systemImage: "exclamationmark.triangle.fill")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.red)
        Text(bedrohung.argument).font(.system(size: 12, weight: .medium))
        Text(bedrohung.grund).font(.caption).foregroundStyle(.secondary)
        Text(bedrohung.severity.uppercased())
          .font(.caption2.bold())
          .padding(.horizontal, 8).padding(.vertical, 3)
          .background(severityFarbe(bedrohung.severity), in: Capsule())
          .foregroundStyle(.white)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    VStack(alignment: .leading, spacing: 8) {
      Text("Effektivitäts-Matrix").font(.system(size: 13, weight: .semibold))
      Text("Score 0-10: Wie effektiv widerlegt jeder Beweis das Gegner-Argument")
        .font(.caption2).foregroundStyle(.secondary)

     if matrix.isEmpty {
       Text("Führe KI-Analyse durch für Matrix")
         .font(.caption)
         .foregroundStyle(.tertiary)
         .frame(maxWidth: .infinity)
         .padding(.vertical, 24)
     } else {
       ScrollView(.horizontal, showsIndicators: false) {
         VStack(alignment: .leading, spacing: 0) {
           HStack(spacing: 0) {
             Text("Gegner-Argument")
               .font(.caption2.bold())
               .frame(width: 140, alignment: .leading)
               .padding(6)
             ForEach(evidence) { ev in
               Text(ev.title)
                 .font(.system(size: 9, weight: .semibold))
                 .lineLimit(2)
                 .multilineTextAlignment(.center)
                 .frame(width: 80)
                 .padding(4)
             }
           }
           Divider()
           ForEach(gegnerArgs) { arg in
             HStack(spacing: 0) {
               Text(arg.title)
                 .font(.caption2)
                 .lineLimit(2)
                 .frame(width: 140, alignment: .leading)
                 .padding(6)
               ForEach(evidence) { ev in
                 let score = matrixScore(gegnerArgId: arg.id, evidenceId: ev.id)
                 Text(String(format: "%.1f", score))
                   .font(.caption2.bold())
                   .frame(width: 80, height: 32)
                   .background(scoreFarbe(score))
               }
             }
             Divider()
           }
         }
       }
     }
   }
   .padding(12)
   .background(.background, in: RoundedRectangle(cornerRadius: 10))
   .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.12)))

   if !counterMoves.isEmpty {
     VStack(alignment: .leading, spacing: 10) {
       Text("Gegen-Schachzüge").font(.system(size: 13, weight: .semibold))
       LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
         ForEach(counterMoves) { move in
           CounterMoveKarte(move: move)
         }
       }
     }
   }
 }
 .onAppear { hydrateFromDemo() }
 .onChange(of: viewModel.argumente.count) { _, _ in rehydrateIfNeeded() }
 .onChange(of: viewModel.beweise.count) { _, _ in rehydrateIfNeeded() }
}

private func rehydrateIfNeeded() {
 guard matrix.isEmpty,
    let dash = viewModel.fall?.gegner_profil?.dictValue?["strategie_dashboard"] as? [String: Any]
 else { return }
 applyDashboard(dash)
}

private func hydrateFromDemo() {
 guard matrix.isEmpty,
    let dash = viewModel.fall?.gegner_profil?.dictValue?["strategie_dashboard"] as? [String: Any]
 else { return }
 applyDashboard(dash)
}

private func applyDashboard(_ dash: [String: Any]) {
 let argCandidates = gegnerArgs.map { (id: $0.id, title: $0.title) }
 let evCandidates = evidence.map { (id: $0.id, title: $0.title) }

 let matrixRaw = dash["effectiveness_matrix"] as? [[String: Any]] ?? []
 matrix = matrixRaw.map { m in
   let gTitle = m["gegner_arg_title"] as? String ?? ""
   let eTitle = m["evidence_title"] as? String ?? ""
   return MatrixZelle(
     gegnerArgId: KITitleMatcher.matchId(title: gTitle, candidates: argCandidates),
     evidenceId: KITitleMatcher.matchId(title: eTitle, candidates: evCandidates),
     gegnerArgTitle: gTitle,
     evidenceTitle: eTitle,
     score: KIJson.numberValue(m["score"]) ?? 0,
     reasoning: m["reasoning"] as? String
   )
 }

 let movesRaw = dash["counter_moves"] as? [[String: Any]] ?? []
 counterMoves = movesRaw.map { m in
   CounterMove(
     typ: m["typ"] as? String ?? "konter",
     titel: m["titel"] as? String ?? "",
     beschreibung: m["beschreibung"] as? String ?? "",
     gegnerArg: m["gegner_arg"] as? String,
     unsereStrategie: m["unsere_strategie"] as? String,
     timing: m["timing"] as? String,
     erfolgsaussicht: KIJson.intValue(m["erfolgsaussicht"]) ?? 0
   )
 }

 if let hb = dash["hauptbedrohung"] as? [String: Any] {
   hauptbedrohung = Hauptbedrohung(
     argument: hb["argument"] as? String ?? "",
     grund: hb["grund"] as? String ?? "",
     severity: hb["severity"] as? String ?? "mittel"
   )
 }
}

private func matrixScore(gegnerArgId: String?, evidenceId: String?) -> Double {
 matrix.first {
   $0.gegnerArgId == gegnerArgId && $0.evidenceId == evidenceId
 }?.score ?? 0
}

private func scoreFarbe(_ score: Double) -> Color {
 if score > 7 { return Color.green.opacity(0.25) }
 if score > 4 { return Color.yellow.opacity(0.25) }
 return Color.red.opacity(0.2)
}

private func severityFarbe(_ severity: String) -> Color {
 switch severity.lowercased() {
 case "hoch": return .red
 case "mittel": return .orange
 default: return .yellow
 }
}

private func kiAnalyseStarten() async {
 guard let fall = viewModel.fall else { return }
 laeuft = true
 fehler = nil
 defer { laeuft = false }

 let gegnerArgTexts = gegnerArgs.map { "\"\($0.title)\" (Stärke: \($0.strength)/10)" }.joined(separator: ", ")
 let eigeneArgTexts = viewModel.argumente.filter { $0.side == .eigen }
   .map { "\"\($0.title)\" (Stärke: \($0.strength)/10)" }.joined(separator: ", ")
 let evidenceTexts = evidence.map { "\"\($0.title)\" (Gewicht: \($0.weight)/10)" }.joined(separator: ", ")
 let deadlineTexts = viewModel.fristen.map {
   "\($0.title) (\($0.due_date.formatted(date: .abbreviated, time: .omitted)))"
 }.joined(separator: ", ")

 let prompt = KIPromptKit.wrap("""
 Analysiere die Gegner-Strategie:

 FALL: \(fall.fallname)
 Gegner-Argumente: \(gegnerArgTexts.isEmpty ? "keine" : gegnerArgTexts)
 Unsere Argumente: \(eigeneArgTexts.isEmpty ? "keine" : eigeneArgTexts)
 Unsere Beweise: \(evidenceTexts.isEmpty ? "keine" : evidenceTexts)
 Fristen: \(deadlineTexts.isEmpty ? "keine" : deadlineTexts)

 AUFGABEN:
 1. Erstelle eine Matrix: Für jedes Gegner-Argument bewerte (0-10), wie effektiv jeder unserer Beweise es widerlegt.
 2. Identifiziere 5-7 spezifische Gegenschachzüge (Konter, Neutralisierung, Verschiebung, Eskalation).
 3. Gib Threat-Analyse: Welches Gegner-Argument ist am gefährlichsten?
 """, modul: .gegner)

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "effectiveness_matrix": [
           "type": "array",
           "items": [
             "type": "object",
             "properties": [
               "gegner_arg_title": ["type": "string"],
               "evidence_title": ["type": "string"],
               "score": ["type": "number"],
               "reasoning": ["type": "string"]
             ] as [String: Any]
           ] as [String: Any]
         ],
         "counter_moves": [
           "type": "array",
           "items": [
             "type": "object",
             "properties": [
               "typ": ["type": "string"],
               "titel": ["type": "string"],
               "beschreibung": ["type": "string"],
               "gegner_arg": ["type": "string"],
               "unsere_strategie": ["type": "string"],
               "timing": ["type": "string"],
               "erfolgsaussicht": ["type": "number"]
             ] as [String: Any]
           ] as [String: Any]
         ],
         "hauptbedrohung": [
           "type": "object",
           "properties": [
             "argument": ["type": "string"],
             "grund": ["type": "string"],
             "severity": ["type": "string"]
           ] as [String: Any]
         ]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6",
     logCaseId: viewModel.caseId,
     logKiName: "Gegner-Strategie Dashboard"
   )

   let dict = try KIJson.requireObject(result, kontext: "Gegner-Strategie")

   let matrixRaw = dict["effectiveness_matrix"] as? [[String: Any]] ?? []
   let argCandidates = gegnerArgs.map { (id: $0.id, title: $0.title) }
   let evCandidates = evidence.map { (id: $0.id, title: $0.title) }
   let mappedMatrix = matrixRaw.map { m -> MatrixZelle in
     let gTitle = m["gegner_arg_title"] as? String ?? ""
     let eTitle = m["evidence_title"] as? String ?? ""
     return MatrixZelle(
       gegnerArgId: KITitleMatcher.matchId(title: gTitle, candidates: argCandidates),
       evidenceId: KITitleMatcher.matchId(title: eTitle, candidates: evCandidates),
       gegnerArgTitle: gTitle,
       evidenceTitle: eTitle,
       score: KIJson.numberValue(m["score"]) ?? 0,
       reasoning: m["reasoning"] as? String
     )
   }

   let movesRaw = dict["counter_moves"] as? [[String: Any]] ?? []
   let moves = movesRaw.map { m in
     CounterMove(
       typ: m["typ"] as? String ?? "konter",
       titel: m["titel"] as? String ?? "",
       beschreibung: m["beschreibung"] as? String ?? "",
       gegnerArg: m["gegner_arg"] as? String,
       unsereStrategie: m["unsere_strategie"] as? String,
       timing: m["timing"] as? String,
       erfolgsaussicht: KIJson.intValue(m["erfolgsaussicht"]) ?? 0
     )
   }

   var bedrohung: Hauptbedrohung?
   if let h = dict["hauptbedrohung"] as? [String: Any] {
     bedrohung = Hauptbedrohung(
       argument: h["argument"] as? String ?? "",
       grund: h["grund"] as? String ?? "",
       severity: h["severity"] as? String ?? "mittel"
     )
   }

   await MainActor.run {
     matrix = mappedMatrix
     counterMoves = moves
     hauptbedrohung = bedrohung
   }

   if var fallUpd = viewModel.fall {
     let dashPayload: [String: Any] = [
       "effectiveness_matrix": matrixRaw,
       "counter_moves": movesRaw,
       "hauptbedrohung": dict["hauptbedrohung"] ?? [:]
     ]
     let saved = try await KIResultStore.mergeGegnerProfilSubKey(
       caseId: viewModel.caseId,
       fall: &fallUpd,
       key: "strategie_dashboard",
       value: dashPayload
     )
     await MainActor.run { viewModel.fall = saved }
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct CounterMoveKarte: View {
let move: GegnerStrategieDashboardView.CounterMove

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Text(move.titel).font(.system(size: 12, weight: .bold))
     Spacer()
     Text(move.typ.uppercased())
       .font(.caption2.bold())
       .padding(.horizontal, 6).padding(.vertical, 2)
       .background(typFarbe.opacity(0.15), in: Capsule())
       .foregroundStyle(typFarbe)
   }
   Text(move.beschreibung).font(.caption)
   if let ga = move.gegnerArg {
     Text("Ziel: \(ga)").font(.caption2).foregroundStyle(.red)
   }
   if let strat = move.unsereStrategie {
     Text("Strategie: \(strat)").font(.caption2).foregroundStyle(.green)
   }
   if let timing = move.timing {
     Text("Timing: \(timing)").font(.caption2).foregroundStyle(.blue)
   }
   if let ea = move.erfolgsaussicht {
     HStack {
       ProgressView(value: Double(ea), total: 100)
         .progressViewStyle(.linear)
         .tint(.green)
       Text("\(ea)%").font(.caption2.bold())
     }
   }
 }
 .padding(10)
 .background(.background, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.12)))
}

private var typFarbe: Color {
 switch move.typ.lowercased() {
 case "konter": return .blue
 case "neutralisierung": return .purple
 case "verschiebung": return .green
 case "eskalation": return .red
 default: return .gray
 }
}
}

