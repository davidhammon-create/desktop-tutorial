import SwiftUI

// MARK: - KI-Risikomatrix (wie RiskMatrix.jsx -- Strategie Tab 4)

struct KIRisikoMatrixView: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var laeuft = false
@State private var ergebnis: [RisikoBewertung] = []
@State private var fehler: String?

struct RisikoBewertung: Identifiable {
  let id = UUID()
  var titel: String
  var eintrittswahrscheinlichkeit: Int
  var auswirkung: Int
  var begruendung: String
}

var body: some View {
  VStack(spacing: 16) {
    HStack {
      Label("KI-Risikomatrix", systemImage: "square.grid.3x3.fill")
        .font(.title2.bold())
      Spacer()
      Button {
        Task { await analysieren() }
      } label: {
        if laeuft {
          ProgressView().scaleEffect(0.7)
          Text("Analysiere…").font(.caption)
        } else {
          Label(ergebnis.isEmpty ? "Analysieren" : "Neu analysieren", systemImage: "wand.and.stars")
        }
      }
      .buttonStyle(FenlynineOSGlassProminentButtonStyle())
      .disabled(laeuft || !kiMode)
    }

    if let err = fehler {
      Text(err).font(.caption).foregroundStyle(.red)
    }

    if ergebnis.isEmpty && !laeuft {
      InfoHinweis(titel: "Risikomatrix", nachricht: "Die KI bewertet alle Risikofaktoren nach Eintrittswahrscheinlichkeit und Auswirkung.", symbol: "square.grid.3x3.fill")
    } else {
      ForEach(ergebnis) { r in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(r.titel).font(.system(size: 12, weight: .semibold))
            Text(r.begruendung).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
          }
          Spacer()
          VStack(spacing: 2) {
            Text("E: \(r.eintrittswahrscheinlichkeit)%").font(.caption2.bold()).foregroundStyle(.orange)
            Text("A: \(r.auswirkung)/10").font(.caption2.bold()).foregroundStyle(.red)
          }
          FenlynineOSTransparenzInfoButton(inhalt: .kiModul(
            titel: "Risiko: \(r.titel)",
            modell: "Gemini 3 Flash",
            begruendung: r.begruendung,
            ausgabe: "Eintritt \(r.eintrittswahrscheinlichkeit)% · Auswirkung \(r.auswirkung)/10"
          ))
        }
        .padding(8)
        .background(Color.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
      }
    }
  }
  .onAppear { hydrateFromStored() }
}

private func hydrateFromStored() {
  guard ergebnis.isEmpty,
     let items = viewModel.fall?.ki_berater_result?.dictValue?["risiko_matrix"] as? [[String: Any]]
  else { return }
  ergebnis = items.map {
    RisikoBewertung(
      titel: $0["titel"] as? String ?? "",
      eintrittswahrscheinlichkeit: KIJson.intValue($0["eintrittswahrscheinlichkeit"]) ?? 50,
      auswirkung: KIJson.intValue($0["auswirkung"]) ?? 5,
      begruendung: $0["begruendung"] as? String ?? ""
    )
  }
}

private func analysieren() async {
  guard let fall = viewModel.fall else { return }
  laeuft = true
  fehler = nil
  defer { laeuft = false }
  let args = viewModel.argumente.map { $0.title }.joined(separator: "; ")
  let prompt = "Bewerte Risikofaktoren für Fall \(fall.fallname) (\(fall.rechtsgebiet ?? "")). Argumente: \(args)"
  do {
    let result: AnyCodable = try await LLMService.shared.invoke(
      prompt: prompt,
      schema: [
        "type": "object",
        "properties": [
         "bewertungen": ["type": "array", "items": ["type": "object", "properties": [
           "titel": ["type": "string"],
           "eintrittswahrscheinlichkeit": ["type": "integer"],
           "auswirkung": ["type": "integer"],
           "begruendung": ["type": "string"]
         ]]]
       ] as [String: Any]
     ] as [String: Any],
     model: "gemini_3_flash",
     logCaseId: viewModel.caseId,
     logKiName: "KI-Risikomatrix"
   )
   guard let d = try? KIJson.requireObject(result, kontext: "KI-Risikomatrix") else {
     await MainActor.run { fehler = KIResultStore.parseFehler }
     return
   }
   let items = (d["bewertungen"] as? [[String: Any]] ?? []).map {
     RisikoBewertung(
       titel: $0["titel"] as? String ?? "",
       eintrittswahrscheinlichkeit: KIJson.intValue($0["eintrittswahrscheinlichkeit"]) ?? 50,
       auswirkung: KIJson.intValue($0["auswirkung"]) ?? 5,
       begruendung: $0["begruendung"] as? String ?? ""
     )
   }
   await MainActor.run { ergebnis = items }
   if var fallUpd = viewModel.fall {
     let payload = items.map { item in
       [
         "titel": item.titel,
         "eintrittswahrscheinlichkeit": item.eintrittswahrscheinlichkeit,
         "auswirkung": item.auswirkung,
         "begruendung": item.begruendung
       ] as [String: Any]
     }
     let saved = try await KIResultStore.mergeBeraterSubKey(
       caseId: viewModel.caseId,
       fall: &fallUpd,
       key: "risiko_matrix",
       value: payload
     )
     await MainActor.run { viewModel.fall = saved }
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

