import SwiftUI
import UniformTypeIdentifiers

// MARK: - Argumente & Beweise mit allen KI-Buttons (wie TabArgumente.jsx + TabBeweise.jsx)

struct TabArgumenteBeweiseView: View {
let viewModel: CaseDetailViewModel
let kiMode: Bool

@State private var subTab = 0
@State private var argumentFilter: Argument.ArgumentSeite? = nil
@State private var zeigeNeuesArgument = false
@State private var zeigeNeuerBeweis = false
@State private var batchRating = false
@State private var kiGenerating = false
@State private var kiGenResult: KIArgumenteErgebnis? = nil
@State private var detectingDuplicates = false
@State private var duplicates: [DuplikatGruppe]? = nil
@State private var kiZuordnungLaeuft = false
@State private var kiZuordnungen: [String: (argId: String, reason: String)] = [:]
@State private var verkettungLaeuft = false
@State private var verkettungVerbindungen: [[String: Any]] = []
@State private var zeigeExtraktion = false
@State private var extractLaeuft = false
@State private var extractText = ""
@State private var extractFiles: [URL] = []
@State private var kiFehler: String?

struct KIArgumenteErgebnis {
  var eigene: [KIArgVorschlag]
  var gegner: [KIArgVorschlag]
}
struct KIArgVorschlag: Identifiable {
  let id = UUID()
  var titel: String
  var beschreibung: String
  var staerke: Int
}
struct DuplikatGruppe: Identifiable {
  let id = UUID()
  var nummern: [Int]
  var grund: String
  var zu_behalten: Int
}

var gefilterteArgumente: [Argument] {
  guard let f = argumentFilter else { return viewModel.argumente }
  return viewModel.argumente.filter { $0.side == f }
}

var body: some View {
  VStack(spacing: 16) {
    // KI-Toolbar (exakt wie Original)
    if kiMode {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          Button {
            Task { await kiArgumenteGenerieren() }
          } label: {
            if kiGenerating {
              ProgressView().scaleEffect(0.7)
              Text("Generiere…").font(.caption)
            } else {
              Label("KI-Argumente (max. 19)", systemImage: "sparkles")
            }
          }
          .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
          .controlSize(.small)
          .disabled(kiGenerating)

          Button {
            Task { await alleBewerten() }
          } label: {
            if batchRating {
              ProgressView().scaleEffect(0.7)
            } else {
              Label("Alle bewerten", systemImage: "star.fill")
            }
          }
          .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
          .controlSize(.small)
          .disabled(batchRating || viewModel.argumente.isEmpty)

          Button {
            Task { await duplikateErkennen() }
          } label: {
            if detectingDuplicates {
              ProgressView().scaleEffect(0.7)
            } else {
              Label("Duplikate", systemImage: "magnifyingglass")
            }
          }
          .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
          .controlSize(.small)
          .disabled(detectingDuplicates || viewModel.argumente.count < 2)

          Button {
            Task { await ohneBelegeLoeschen() }
          } label: {
           Label("Ohne Belege löschen", systemImage: "trash")
         }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
         .controlSize(.small)
         .disabled(viewModel.argumente.isEmpty)

         Button {
           zeigeExtraktion.toggle()
         } label: {
           Label("Analysieren", systemImage: "arrow.triangle.2.circlepath")
         }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
         .controlSize(.small)

         Button {
           Task { await kiZuordnungStarten() }
         } label: {
           if kiZuordnungLaeuft {
             ProgressView().scaleEffect(0.7)
           } else {
             Label("KI-Zuordnung", systemImage: "link")
           }
         }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
         .controlSize(.small)
         .disabled(kiZuordnungLaeuft || viewModel.beweise.isEmpty)
       }
     }
   }

   if let err = kiFehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   // Dokument-Extraktion Panel
   if zeigeExtraktion && kiMode {
     VStack(alignment: .leading, spacing: 8) {
       TextField("Text zum Analysieren…", text: $extractText, axis: .vertical)
         .lineLimit(3...6)
         .textFieldStyle(.roundedBorder)
       HStack {
         Button("Datei wählen") {
           let panel = NSOpenPanel()
           panel.allowsMultipleSelection = true
           if panel.runModal() == .OK { extractFiles = panel.urls }
         }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small)
         if !extractFiles.isEmpty {
           Text("\(extractFiles.count) Datei(en)").font(.caption2)
         }
         Spacer()
         Button(extractLaeuft ? "…" : "Extrahieren") {
           Task { await dokumentExtrahieren() }
         }
         .buttonStyle(FenlynineOSGlassProminentButtonStyle()).controlSize(.small)
         .disabled(extractLaeuft || (extractText.isEmpty && extractFiles.isEmpty))
       }
     }
     .padding(10)
     .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
   }

   // KI-Generierte Argumente
   if let gen = kiGenResult {
     KIArgumentePanel(ergebnis: gen, onUebernehmen: { arg, seite in
       Task { await kiArgumentUebernehmen(arg, seite: seite) }
     }, onSchliessen: { kiGenResult = nil })
   }

   // Duplikate
   if let dups = duplicates {
     VStack(alignment: .leading, spacing: 6) {
       Text("Ähnliche Argumente gefunden").font(.caption.bold())
       ForEach(dups) { g in
         HStack {
           Text("Gruppe: \(g.nummern.map(String.init).joined(separator: ", ")) -- \(g.grund)")
             .font(.caption2)
           Spacer()
         }
       }
       Button("Duplikate löschen") {
         Task { await duplikateLoeschen(dups) }
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.small).tint(.red)
     }
     .padding(10)
     .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
   }

   Picker("", selection: $subTab) {
     Text("Argumente").tag(0)
     Text("Beweise").tag(1)
     Text("Verkettung").tag(2)
   }
   .pickerStyle(.segmented)

   switch subTab {
   case 0:
     argumenteSection
   case 1:
     beweiseSection
   default:
     verkettungSection
   }
 }
 .sheet(isPresented: $zeigeNeuesArgument) {
   NeuesArgumentSheet(caseId: viewModel.caseId) { viewModel.argumente.append($0) }
 }
 .sheet(isPresented: $zeigeNeuerBeweis) {
   NeuerBeweisSheet(
     caseId: viewModel.caseId,
     argumente: viewModel.argumente,
     vorgewaehltesArgumentId: beweisVerknuepfenFuerArgument
   ) { created in
     viewModel.beweise.append(created)
     if let argId = beweisVerknuepfenFuerArgument ?? created.linked_argument_ids?.first,
      let idx = viewModel.argumente.firstIndex(where: { $0.id == argId }) {
       Task {
         if let arg = try? await Services.arguments.get(id: argId) {
           await MainActor.run { viewModel.argumente[idx] = arg }
         }
       }
     }
     beweisVerknuepfenFuerArgument = nil
   }
 }
}

// MARK: - Argumente

@ViewBuilder
private var argumenteSection: some View {
 HStack {
   Label("Argumente (\(viewModel.argumente.count))", systemImage: "text.bubble.fill")
     .font(.system(size: 14, weight: .semibold))
   Spacer()
   Menu {
     Button("Alle") { argumentFilter = nil }
     Button("Eigene") { argumentFilter = .eigen }
     Button("Gegner") { argumentFilter = .gegner }
   } label: {
     Image(systemName: "line.3.horizontal.decrease.circle")
   }
   Button { zeigeNeuesArgument = true } label: {
     Image(systemName: "plus.circle")
   }
 }

 if !viewModel.argumente.isEmpty {
   ArgumentBilanzView(argumente: viewModel.argumente)
 }

 if gefilterteArgumente.isEmpty {
   PlatzhalterView(nachricht: "Keine Argumente erfasst", symbol: "text.bubble")
 } else {
   ForEach(gefilterteArgumente) { arg in
     ArgumentBeweisBaumView(
       argument: arg,
       beweise: viewModel.beweise,
       viewModel: viewModel,
       kiMode: kiMode,
       onArgumentUpdate: { updated in
         if let idx = viewModel.argumente.firstIndex(where: { $0.id == updated.id }) {
           viewModel.argumente[idx] = updated
         }
       },
       onEvidenceUpdate: { updated in
         if let idx = viewModel.beweise.firstIndex(where: { $0.id == updated.id }) {
           viewModel.beweise[idx] = updated
         }
       },
       onLinkEvidence: { argId in
         beweisVerknuepfenFuerArgument = argId
         zeigeNeuerBeweis = true
       }
     )
   }
 }
}

@State private var beweisVerknuepfenFuerArgument: String?

// MARK: - Beweise

@ViewBuilder
private var beweiseSection: some View {
 HStack {
   Label("Beweise (\(viewModel.beweise.count))", systemImage: "doc.text.magnifyingglass")
     .font(.system(size: 14, weight: .semibold))
   Spacer()
   Button { zeigeNeuerBeweis = true } label: {
     Image(systemName: "plus.circle")
   }
 }
 if !viewModel.beweise.isEmpty {
   BeweisQualitaetsView(beweise: viewModel.beweise)
   BeweismatrixChartView(argumente: viewModel.argumente, beweise: viewModel.beweise)
 }
 if viewModel.beweise.isEmpty {
   PlatzhalterView(nachricht: "Keine Beweise erfasst", symbol: "doc.text.magnifyingglass")
 } else {
   let unverknuepft = ArgumentBeweisVerknuepfung.unverknuepfteBeweise(
     argumente: viewModel.argumente,
     beweise: viewModel.beweise
   )
   if !unverknuepft.isEmpty {
     Text("Unverknüpfte Beweise (\(unverknuepft.count))")
       .font(.caption.bold())
       .foregroundStyle(.secondary)
     ForEach(unverknuepft) { beweis in
       BeweisKarteKI(
         beweis: beweis,
         viewModel: viewModel,
         kiMode: kiMode,
         verfuegbareArgumente: viewModel.argumente,
         onUpdate: { updated in
           if let idx = viewModel.beweise.firstIndex(where: { $0.id == updated.id }) {
             viewModel.beweise[idx] = updated
           }
         },
         onVerknuepfen: { argId in
           Task { await manuelleVerknuepfung(evidenceId: beweis.id ?? "", argumentId: argId) }
         }
       )
     }
   }
 }
 if !kiZuordnungen.isEmpty {
   VStack(alignment: .leading, spacing: 8) {
     Text("KI-Zuordnungsvorschläge").font(.caption.bold())
     ForEach(unverknuepfteBeweise) { ev in
       if let sug = kiZuordnungen[ev.id ?? ""] {
         HStack {
           VStack(alignment: .leading, spacing: 2) {
             Text(ev.title).font(.caption)
             Text(sug.reason).font(.caption2).foregroundStyle(.purple).italic()
           }
           Spacer()
           Button("Übernehmen") {
             Task { await zuordnungUebernehmen(evidenceId: ev.id ?? "", argId: sug.argId) }
           }
           .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
         }
         .padding(8)
         .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
       }
     }
   }
 }
}

private var unverknuepfteBeweise: [Evidence] {
 ArgumentBeweisVerknuepfung.unverknuepfteBeweise(
   argumente: viewModel.argumente,
   beweise: viewModel.beweise
 )
}

private func manuelleVerknuepfung(evidenceId: String, argumentId: String) async {
 var args = viewModel.argumente
 var evs = viewModel.beweise
 await ArgumentBeweisVerknuepfung.verknuepfe(
   argumentId: argumentId,
   evidenceId: evidenceId,
   argumente: &args,
   beweise: &evs
 )
 await MainActor.run {
   viewModel.argumente = args
   viewModel.beweise = evs
 }
}

@State private var verkettungSubView = 0

// MARK: - Verkettung

@ViewBuilder
private var verkettungSection: some View {
 Picker("", selection: $verkettungSubView) {
   Text("Verkettung").tag(0)
   Text("Argumentkette").tag(1)
   Text("Zeitstrahl").tag(2)
 }
 .pickerStyle(.segmented)

 switch verkettungSubView {
 case 1:
   ArgumentationskettenView(viewModel: viewModel, kiMode: kiMode)
 case 2:
   ArgumentZeitstrahlChartView(viewModel: viewModel, kiMode: kiMode)
 default:
   verkettungKIInhalt
 }
}

@ViewBuilder
private var verkettungKIInhalt: some View {
 HStack {
   Label("Argumentverkettung", systemImage: "link.circle")
     .font(.title3.bold())
   Spacer()
   if kiMode {
     Button {
       Task { await verkettungAnalysieren() }
     } label: {
       if verkettungLaeuft {
         ProgressView().scaleEffect(0.7)
         Text("Analysiere…").font(.caption)
       } else {
         Label("KI-Analyse", systemImage: "wand.and.stars")
       }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .controlSize(.small)
     .disabled(verkettungLaeuft || viewModel.argumente.isEmpty)
   }
 }
 if !verkettungVerbindungen.isEmpty {
   VStack(alignment: .leading, spacing: 8) {
     HStack {
       Text("Erkannte Verbindungen (\(verkettungVerbindungen.count))").font(.caption.bold())
       Spacer()
       Button("Alle übernehmen") {
         Task { await alleVerbindungenUebernehmen() }
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       .controlSize(.mini)
     }
     ForEach(Array(verkettungVerbindungen.enumerated()), id: \.offset) { idx, v in
       let von = viewModel.argumente.first { $0.id == v["vonId"] as? String }?.title ?? "?"
       let nach = viewModel.argumente.first { $0.id == v["nachId"] as? String }?.title ?? "?"
       HStack(alignment: .top) {
         VStack(alignment: .leading, spacing: 2) {
           Text("\(von) -> \(nach) [\(v["typ"] as? String ?? "")]").font(.caption)
           if let e = v["erklaerung"] as? String, !e.isEmpty {
             Text(e).font(.caption2).foregroundStyle(.secondary)
           }
         }
         Spacer()
         Button("Übernehmen") {
           Task { await verbindungUebernehmenUndEntfernen(v) }
         }
         .buttonStyle(FenlynineOSGlassProminentButtonStyle())
         .controlSize(.mini)
       }
       .padding(8)
       .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
     }
   }
 } else {
   InfoHinweis(titel: "Argumentverkettung", nachricht: "Die KI erkennt logische Zusammenhänge, Lücken und Widersprüche zwischen Argumenten.", symbol: "link.circle")
 }
}

// MARK: - KI-Aktionen

private func kiArgumenteGenerieren() async {
 guard let fall = viewModel.fall else { return }
 kiGenerating = true
 kiFehler = nil
 defer { kiGenerating = false }
 let prompt = """
 Du bist ein erfahrener Rechtsanwalt. Generiere max. 19 Argumente für:
 Fall: \(fall.fallname), \(fall.rechtsgebiet ?? ""), \(fall.zentrale_rechtsfrage ?? "")
 Eigene und Gegner-Argumente mit Stärke 1-10.
 """
 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "eigene_argumente": ["type": "array", "items": ["type": "object", "properties": [
           "titel": ["type": "string"], "beschreibung": ["type": "string"], "staerke": ["type": "integer"]
         ]]],
         "gegner_argumente": ["type": "array", "items": ["type": "object", "properties": [
           "titel": ["type": "string"], "beschreibung": ["type": "string"], "staerke": ["type": "integer"]
         ]]]
       ] as [String: Any]
     ] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "KI-Argumente generieren"
   )
   let parse: ([String: Any]) -> KIArgVorschlag = { a in
     KIArgVorschlag(
       titel: KIJson.string(in: a, keys: "titel", "title") ?? "",
       beschreibung: KIJson.string(in: a, keys: "beschreibung", "description") ?? "",
       staerke: KIJson.int(in: a, keys: "staerke", "strength", "staerke") ?? 5
     )
   }
   let eigeneRaw = KIJson.array(in: d, keys: "eigene_argumente", "eigene", "eigen")
   let gegnerRaw = KIJson.array(in: d, keys: "gegner_argumente", "gegner")
   guard !eigeneRaw.isEmpty || !gegnerRaw.isEmpty else {
     await MainActor.run { kiFehler = "KI lieferte keine Argumente." }
     return
   }
   await MainActor.run {
     kiGenResult = KIArgumenteErgebnis(
       eigene: eigeneRaw.map(parse),
       gegner: gegnerRaw.map(parse)
     )
   }
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}

private func alleBewerten() async {
 batchRating = true
 kiFehler = nil
 defer { batchRating = false }
 let liste = viewModel.argumente.enumerated().map { i, a in
   let belege = ArgumentBeweisVerknuepfung.verknuepfteBeweise(fuer: a, in: viewModel.beweise)
     .map(\.title).joined(separator: ", ")
   return "\(i + 1). \(a.title) (\(a.side.rawValue), Stärke \(a.strength)/10) -- Belege: \(belege.isEmpty ? "KEINE" : belege)"
 }.joined(separator: "\n")
 let prompt = "Bewerte alle Argumente (0-10) mit Begründung. Prüfe ob jedes Argument durch verknüpfte Beweise gestützt ist (ist_bewiesen, beweis_status):\n\(liste)"
 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: ["type": "object", "properties": ["bewertungen": ["type": "array", "items": ["type": "object", "properties": [
       "index": ["type": "integer"], "staerke": ["type": "number"], "begruendung": ["type": "string"],
       "ist_bewiesen": ["type": "boolean"], "beweis_status": ["type": "string"]
     ]]]]] as [String: Any],
     model: "gemini_3_flash",
     logCaseId: viewModel.caseId,
     logKiName: "Argumente -- Alle bewerten"
   )
   let bewertungen = KIJson.array(in: d, keys: "bewertungen", "bewertung", "ratings")
   guard !bewertungen.isEmpty else {
     await MainActor.run { kiFehler = "KI lieferte keine Bewertungen." }
     return
   }
   for b in bewertungen {
     guard let rawIdx = KIJson.int(in: b, keys: "index", "nummer") else { continue }
     let idx = rawIdx - 1
     guard idx >= 0, idx < viewModel.argumente.count,
        let id = viewModel.argumente[idx].id else { continue }
     var updated = viewModel.argumente[idx]
     updated.ki_strength = KIJson.number(in: b, keys: "staerke", "strength", "score") ?? 5
     var reasoning = KIJson.string(in: b, keys: "begruendung", "reasoning", "reason") ?? ""
     if let status = KIJson.string(in: b, keys: "beweis_status") {
       reasoning += reasoning.isEmpty ? status : " · \(status)"
     }
     if let bewiesen = b["ist_bewiesen"] as? Bool {
       reasoning += bewiesen ? " · BEWIESEN" : " · OHNE BELEG"
     }
     updated.ki_reasoning = reasoning.isEmpty ? updated.ki_reasoning : reasoning
     if let saved = try? await Services.arguments.update(id: id, entity: updated) {
       await MainActor.run { viewModel.argumente[idx] = saved }
     }
   }
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}

private func duplikateErkennen() async {
 detectingDuplicates = true
 kiFehler = nil
 defer { detectingDuplicates = false }
 let liste = viewModel.argumente.enumerated().map { "\($0.offset + 1). \($0.element.title)" }.joined(separator: "\n")
 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: "Finde ähnliche/doppelte Argumente:\n\(liste)",
     schema: ["type": "object", "properties": ["duplikat_gruppen": ["type": "array", "items": ["type": "object", "properties": [
       "nummern": ["type": "array", "items": ["type": "integer"]],
       "grund": ["type": "string"], "zu_behalten": ["type": "integer"]
     ]]]]] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "Argumente -- Duplikate"
   )
   let gruppenRaw = KIJson.array(in: d, keys: "duplikat_gruppen", "duplikate", "groups")
   let gruppen = gruppenRaw.map {
     DuplikatGruppe(
       nummern: ($0["nummern"] as? [Int]) ?? ($0["nummern"] as? [Double])?.map { Int($0) } ?? [],
       grund: KIJson.string(in: $0, keys: "grund", "reason") ?? "",
       zu_behalten: KIJson.int(in: $0, keys: "zu_behalten", "keep") ?? 1
     )
   }
   await MainActor.run { duplicates = gruppen.isEmpty ? nil : gruppen }
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}

private func duplikateLoeschen(_ gruppen: [DuplikatGruppe]) async {
 var toDelete: [String] = []
 for g in gruppen {
   for idx in g.nummern where idx != g.zu_behalten {
     if idx >= 1, idx <= viewModel.argumente.count, let id = viewModel.argumente[idx - 1].id {
       toDelete.append(id)
     }
   }
 }
 for id in toDelete {
   try? await Services.arguments.delete(id: id)
 }
 await MainActor.run {
   viewModel.argumente.removeAll { toDelete.contains($0.id ?? "") }
   duplicates = nil
 }
}

private func ohneBelegeLoeschen() async {
 let ohne = viewModel.argumente.filter {
   !ArgumentBeweisVerknuepfung.istBewiesen(argument: $0, beweise: viewModel.beweise)
 }
 guard !ohne.isEmpty else { return }
 for arg in ohne {
   if let id = arg.id { try? await Services.arguments.delete(id: id) }
 }
 await MainActor.run {
   viewModel.argumente.removeAll { arg in ohne.contains { $0.id == arg.id } }
 }
}

private func dokumentExtrahieren() async {
 extractLaeuft = true
 kiFehler = nil
 defer { extractLaeuft = false }
 var fileUrls: [String] = []
 for url in extractFiles {
   if let data = try? Data(contentsOf: url),
    let uploaded = try? await LLMService.shared.uploadFile(data: data, fileName: url.lastPathComponent, mimeType: "application/octet-stream") {
     fileUrls.append(uploaded)
   }
 }
 let prompt = "Extrahiere Argumente, Beweise und Zuordnungen (welcher Beweis stützt welches Argument) aus:\n\(extractText)"
 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "eigene_argumente": ["type": "array", "items": ["type": "object"]],
       "gegner_argumente": ["type": "array", "items": ["type": "object"]],
       "beweise": ["type": "array", "items": ["type": "object", "properties": [
         "titel": ["type": "string"], "typ": ["type": "string"],
         "gewicht": ["type": "integer"], "argument_titel": ["type": "string"]
       ]]],
       "zuordnungen": ["type": "array", "items": ["type": "object", "properties": [
         "argument_titel": ["type": "string"], "beweis_titel": ["type": "string"]
       ]]]
     ]] as [String: Any],
     fileUrls: fileUrls.isEmpty ? nil : fileUrls,
     logCaseId: viewModel.caseId,
     logKiName: "Argumente -- Dokument extrahieren"
   )
   let d = try KIJson.requireObject(result, kontext: "Dokument-Extraktion")
   let parse: ([String: Any]) -> KIArgVorschlag = { a in
     KIArgVorschlag(titel: a["titel"] as? String ?? a["title"] as? String ?? "", beschreibung: a["beschreibung"] as? String ?? "", staerke: 5)
   }
   await MainActor.run {
     kiGenResult = KIArgumenteErgebnis(
       eigene: (d["eigene_argumente"] as? [[String: Any]] ?? []).map(parse),
       gegner: (d["gegner_argumente"] as? [[String: Any]] ?? []).map(parse)
     )
     zeigeExtraktion = false
   }
   await extrahierteBeweiseSpeichern(d)
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}

private func extrahierteBeweiseSpeichern(_ d: [String: Any]) async {
 let beweiseRaw = d["beweise"] as? [[String: Any]] ?? []
 guard !beweiseRaw.isEmpty else { return }

 for b in beweiseRaw {
   var ev = Evidence(case_id: viewModel.caseId, title: b["titel"] as? String ?? "Beweis")
   if let t = b["typ"] as? String, let typ = Evidence.EvidenceType(rawValue: t) {
     ev.type = typ
   }
   ev.weight = KIJson.intValue(b["gewicht"]) ?? 5
   if let created = try? await Services.evidence.create(ev) {
     await MainActor.run { viewModel.beweise.append(created) }
     if let argTitel = b["argument_titel"] as? String,
      let arg = viewModel.argumente.first(where: {
        $0.title.lowercased().contains(argTitel.lowercased().prefix(12))
      }),
      let argId = arg.id, let evId = created.id {
       var args = viewModel.argumente
       var evs = viewModel.beweise
       await ArgumentBeweisVerknuepfung.verknuepfe(
         argumentId: argId, evidenceId: evId,
         argumente: &args, beweise: &evs
       )
       await MainActor.run {
         viewModel.argumente = args
         viewModel.beweise = evs
       }
     }
   }
 }

 for z in d["zuordnungen"] as? [[String: Any]] ?? [] {
   guard let argT = z["argument_titel"] as? String,
      let evT = z["beweis_titel"] as? String,
      let arg = viewModel.argumente.first(where: { $0.title.contains(argT.prefix(10)) }),
      let ev = viewModel.beweise.first(where: { $0.title.contains(evT.prefix(10)) }),
      let argId = arg.id, let evId = ev.id else { continue }
   var args = viewModel.argumente
   var evs = viewModel.beweise
   await ArgumentBeweisVerknuepfung.verknuepfe(
     argumentId: argId, evidenceId: evId,
     argumente: &args, beweise: &evs
   )
   await MainActor.run {
     viewModel.argumente = args
     viewModel.beweise = evs
   }
 }
}

private func kiZuordnungStarten() async {
 let unlinked = unverknuepfteBeweise
 guard !unlinked.isEmpty, !viewModel.argumente.isEmpty else { return }
 kiZuordnungLaeuft = true
 kiFehler = nil
 defer { kiZuordnungLaeuft = false }

 let argsList = viewModel.argumente.map { "ID: \($0.id ?? "") | Seite: \($0.side.rawValue) | Titel: \($0.title)" }.joined(separator: "\n")
 let evList = unlinked.map { "ID: \($0.id ?? "") | Titel: \($0.title) | Typ: \($0.type.rawValue) | Beschreibung: \($0.description ?? "")" }.joined(separator: "\n")
 let prompt = """
 Du bist ein erfahrener Rechtsanwalt. Weise die folgenden Beweismittel den passendsten Argumenten zu.

 ARGUMENTE:
 \(argsList)

 BEWEISE (unverknüpft):
 \(evList)

 Gib für jeden Beweis die ID des am besten passenden Arguments an und eine kurze Begründung (max. 1 Satz).
 """
 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "zuordnungen": ["type": "array", "items": ["type": "object", "properties": [
         "evidence_id": ["type": "string"],
         "argument_id": ["type": "string"],
         "reason": ["type": "string"]
       ]]]
     ]] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "Beweise -- KI-Zuordnung"
   )
   let dict = try KIJson.requireObject(result, kontext: "Beweis-Zuordnung")
   var suggestions: [String: (argId: String, reason: String)] = [:]
   for z in dict["zuordnungen"] as? [[String: Any]] ?? [] {
     if let eid = z["evidence_id"] as? String, let aid = z["argument_id"] as? String {
       suggestions[eid] = (argId: aid, reason: z["reason"] as? String ?? "")
     }
   }
   await MainActor.run { kiZuordnungen = suggestions }
   // Auto-Übernahme aller KI-Zuordnungen
   for (eid, sug) in suggestions {
     await zuordnungUebernehmen(evidenceId: eid, argId: sug.argId)
   }
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}

private func zuordnungUebernehmen(evidenceId: String, argId: String) async {
 var args = viewModel.argumente
 var evs = viewModel.beweise
 await ArgumentBeweisVerknuepfung.verknuepfe(
   argumentId: argId,
   evidenceId: evidenceId,
   argumente: &args,
   beweise: &evs
 )
 await MainActor.run {
   viewModel.argumente = args
   viewModel.beweise = evs
   kiZuordnungen.removeValue(forKey: evidenceId)
 }
}

private func verkettungAnalysieren() async {
 guard viewModel.argumente.count >= 2 else { return }
 verkettungLaeuft = true
 kiFehler = nil
 defer { verkettungLaeuft = false }
 let argList = viewModel.argumente.map { "ID: \($0.id ?? "") | Titel: \"\($0.title)\" | Seite: \($0.side.rawValue)" }.joined(separator: "\n")
 let prompt = """
 Du bist ein erfahrener Rechtsanwalt. Analysiere folgende juristische Argumente und erkenne Beziehungen zwischen ihnen.

 Argumente:
 \(argList)

 Erkenne für jede sinnvolle Verbindung: welches Argument stützt, entkräftet, widerspricht, verstärkt, schwächt oder schließt ein anderes aus.
 Gib nur Verbindungen an die wirklich relevant sind (max 10). Bewerte die Intensität 1-10.
 """
 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "verbindungen": ["type": "array", "items": ["type": "object", "properties": [
         "vonId": ["type": "string"],
         "nachId": ["type": "string"],
         "typ": ["type": "string"],
         "erklaerung": ["type": "string"],
         "intensitaet": ["type": "number"]
       ]]]
     ]] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "Argumentverkettung"
   )
   let dict = try KIJson.requireObject(result, kontext: "Argumentverkettung")
   await MainActor.run {
     verkettungVerbindungen = dict["verbindungen"] as? [[String: Any]] ?? []
   }
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}

private func verbindungUebernehmen(_ v: [String: Any]) async {
 guard let vonId = v["vonId"] as? String,
    let nachId = v["nachId"] as? String,
    let idx = viewModel.argumente.firstIndex(where: { $0.id == vonId }) else { return }

 var arg = viewModel.argumente[idx]
 let neu = Argument.ArgumentConnection(
   targetId: nachId,
   type: v["typ"] as? String ?? "stützt",
   explanation: v["erklaerung"] as? String,
   intensitaet: v["intensitaet"] as? Int ?? 5
 )
 var bestehend = arg.connections ?? []
 bestehend.removeAll { $0.targetId == nachId }
 bestehend.append(neu)
 arg.connections = bestehend

 if let id = arg.id, let updated = try? await Services.arguments.update(id: id, entity: arg) {
   await MainActor.run { viewModel.argumente[idx] = updated }
 }
}

private func verbindungUebernehmenUndEntfernen(_ v: [String: Any]) async {
 await verbindungUebernehmen(v)
 await MainActor.run {
   verkettungVerbindungen.removeAll {
     ($0["vonId"] as? String) == (v["vonId"] as? String) &&
     ($0["nachId"] as? String) == (v["nachId"] as? String)
   }
 }
}

private func alleVerbindungenUebernehmen() async {
 let kopie = verkettungVerbindungen
 for v in kopie {
   await verbindungUebernehmen(v)
 }
 await MainActor.run { verkettungVerbindungen = [] }
}

private func kiArgumentUebernehmen(_ arg: KIArgVorschlag, seite: Argument.ArgumentSeite) async {
 var neu = Argument(case_id: viewModel.caseId, title: arg.titel)
 neu.description = arg.beschreibung
 neu.side = seite
 neu.strength = arg.staerke
 if let created = try? await Services.arguments.create(neu) {
   await MainActor.run { viewModel.argumente.append(created) }
 }
}
}

// MARK: - Argument-Karte mit KI bewerten + Diskrepanz

struct ArgumentKarteKI: View {
let argument: Argument
let viewModel: CaseDetailViewModel
let kiMode: Bool
var beweisStatus: ArgumentBeweisStatus? = nil
let onUpdate: (Argument) -> Void

@State private var aufgeklappt = false
@State private var kiWeighting = false
@State private var analyzing = false
@State private var analyse: (erklaerung: String, vorschlaege: [String])? = nil
@State private var cardFehler: String?

private var discrepancy: Double {
 guard let ks = argument.ki_strength else { return 0 }
 return abs(Double(argument.strength) - ks)
}

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   HStack(spacing: 10) {
     Image(systemName: argument.side == .eigen ? "checkmark.circle.fill" : "xmark.circle.fill")
       .foregroundStyle(argument.side == .eigen ? .green : .red)
     Text(argument.title).font(.system(size: 13, weight: .medium)).lineLimit(aufgeklappt ? .max : 2)
     Spacer()
     VStack(spacing: 1) {
       Text("Manuell: \(argument.strength)").font(.caption2)
       if let ks = argument.ki_strength {
         Text("KI: \(Int(ks))").font(.caption2.bold()).foregroundStyle(.purple)
       }
     }
     if discrepancy >= 2 {
       Text("D \(String(format: "%.1f", discrepancy))").font(.caption2.bold()).foregroundStyle(.orange)
     }
     if let status = beweisStatus ?? beweisStatusAusViewModel {
       beweisStatusBadge(status)
     }
     ComplianceStatusBadge(status: ComplianceStatusHelper.status(for: argument))
     Button { withAnimation { aufgeklappt.toggle() } } label: {
       Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down").font(.caption2)
     }.buttonStyle(.plain)
   }
   .padding(10)

   if aufgeklappt {
     Divider().padding(.horizontal, 10)
     VStack(alignment: .leading, spacing: 8) {
       if let desc = argument.description { Text(desc).font(.caption).foregroundStyle(.secondary) }
       if let reason = argument.ki_reasoning ?? argument.ki_bewertung {
         KITransparenzZeile(text: reason)
       }
       if kiMode {
         HStack(spacing: 8) {
           Button {
             Task { await kiBewerten() }
           } label: {
             if kiWeighting { ProgressView().scaleEffect(0.6) }
             else { Label("KI bewerten", systemImage: "sparkles") }
           }
           .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
           .disabled(kiWeighting)

           if discrepancy >= 2 {
             Button {
               Task { await diskrepanzAnalysieren() }
             } label: {
               if analyzing { ProgressView().scaleEffect(0.6) }
               else { Label("Diskrepanz analysieren", systemImage: "exclamationmark.triangle") }
             }
             .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
             .disabled(analyzing)
           }
         }
       }
       if let a = analyse {
         Text(a.erklaerung).font(.caption)
         ForEach(Array(a.vorschlaege.enumerated()), id: \.offset) { i, v in
           Text("\(i + 1). \(v)").font(.caption2)
         }
       }
       if let err = cardFehler {
         Text(err).font(.caption2).foregroundStyle(.red)
       }
     }
     .padding(10)
   }
 }
 .background(argument.side == .eigen ? Color.green.opacity(0.04) : Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}

private var beweisStatusAusViewModel: ArgumentBeweisStatus? {
 let bewiesen = ArgumentBeweisVerknuepfung.istBewiesen(argument: argument, beweise: viewModel.beweise)
 if bewiesen {
   let n = ArgumentBeweisVerknuepfung.verknuepfteBeweise(fuer: argument, in: viewModel.beweise).count
   return .bewiesen(count: n)
 }
 return .ohneBeleg
}

@ViewBuilder
private func beweisStatusBadge(_ status: ArgumentBeweisStatus) -> some View {
 switch status {
 case .bewiesen(let count):
   Label("\(count) Beleg\(count == 1 ? "" : "e")", systemImage: "link.circle.fill")
     .font(.system(size: 9, weight: .bold))
     .foregroundStyle(.teal)
     .padding(.horizontal, 6)
     .padding(.vertical, 2)
     .background(Color.teal.opacity(0.12), in: Capsule())
 case .ohneBeleg:
   Label("Ohne Beleg", systemImage: "exclamationmark.circle")
     .font(.system(size: 9, weight: .bold))
     .foregroundStyle(.orange)
     .padding(.horizontal, 6)
     .padding(.vertical, 2)
     .background(Color.orange.opacity(0.1), in: Capsule())
 }
}

private func kiBewerten() async {
 guard let id = argument.id else { return }
 kiWeighting = true
 cardFehler = nil
 defer { kiWeighting = false }
 let belegInfo = ArgumentBeweisVerknuepfung.verknuepfteBeweise(fuer: argument, in: viewModel.beweise)
   .map { "Beleg: \($0.title) (Gewicht \(Int($0.effectiveWeight)))" }
   .joined(separator: "; ")
 let prompt = """
 Bewerte die Stärke dieses Rechtsarguments (0-10):
 Argument: "\(argument.title)"
 Beschreibung: "\(argument.description ?? "")"
 Seite: \(argument.side.rawValue)
 Verknüpfte Beweise: \(belegInfo.isEmpty ? "KEINE -- Argument ist NICHT belegt" : belegInfo)
 Ist das Argument durch Beweise gestützt? Antworte in beweis_status.
 """
 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "staerke": ["type": "number"],
       "begruendung": ["type": "string"],
       "beweis_status": ["type": "string"],
       "ist_bewiesen": ["type": "boolean"]
     ]] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "Argument -- KI bewerten"
   )
   guard let staerke = KIJson.number(in: d, keys: "staerke", "strength", "score") else {
     await MainActor.run { cardFehler = "KI-Antwort ohne Stärke-Wert." }
     return
   }
   var updated = argument
   updated.ki_strength = min(10, max(0, staerke))
   updated.ki_reasoning = KIJson.string(in: d, keys: "begruendung", "reasoning", "reason")
   let saved = try await Services.arguments.update(id: id, entity: updated)
   await MainActor.run { onUpdate(saved) }
 } catch {
   await MainActor.run { cardFehler = error.localizedDescription }
 }
}

private func diskrepanzAnalysieren() async {
 analyzing = true
 cardFehler = nil
 defer { analyzing = false }
 let prompt = """
 Analysiere Diskrepanz: Manuell \(argument.strength)/10, KI \(Int(argument.ki_strength ?? 0))/10
 Argument: "\(argument.title)"
 """
 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "erklaerung": ["type": "string"],
       "vorschlaege": ["type": "array", "items": ["type": "string"]]
     ]] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "Argument -- Diskrepanz"
   )
   let erk = KIJson.string(in: d, keys: "erklaerung", "explanation") ?? ""
   let vorschlaege = (d["vorschlaege"] as? [String])
     ?? (d["vorschlaege"] as? [Any])?.compactMap { $0 as? String }
     ?? (d["suggestions"] as? [String])
     ?? []
   await MainActor.run { analyse = (erk, vorschlaege) }
 } catch {
   await MainActor.run { cardFehler = error.localizedDescription }
 }
}
}

// MARK: - Beweis-Karte mit KI gewichten

struct BeweisKarteKI: View {
let beweis: Evidence
let viewModel: CaseDetailViewModel
let kiMode: Bool
var eingerueckt: Bool = false
var verknuepftMit: String? = nil
var verfuegbareArgumente: [Argument] = []
let onUpdate: (Evidence) -> Void
var onLoesen: (() -> Void)? = nil
var onVerknuepfen: ((String) -> Void)? = nil

@State private var kiWeighting = false
@State private var analyzing = false
@State private var analyse: (erklaerung: String, vorschlaege: [String])? = nil
@State private var cardFehler: String?

private var discrepancy: Double {
 guard let kw = beweis.ki_weight else { return 0 }
 return abs(Double(beweis.weight) - kw)
}

var body: some View {
 VStack(alignment: .leading, spacing: 6) {
   HStack(spacing: 10) {
     Image(systemName: beweis.type.symbol).foregroundStyle(.teal)
     VStack(alignment: .leading, spacing: 2) {
       Text(beweis.title).font(.system(size: 12, weight: .medium))
       if let v = verknuepftMit {
         Text("-> \(v)").font(.caption2).foregroundStyle(.teal)
       }
       HStack(spacing: 4) {
         Text("Gewicht: \(Int(beweis.effectiveWeight))/10").font(.caption2)
         if let kw = beweis.ki_weight {
           Text("KI: \(Int(kw))").font(.caption2.bold()).foregroundStyle(.purple)
         }
       }
     }
     Spacer()
     ComplianceStatusBadge(status: ComplianceStatusHelper.status(for: beweis))
     if kiMode {
       Button {
         Task { await kiGewichten() }
       } label: {
         if kiWeighting { ProgressView().scaleEffect(0.6) }
         else { Text("KI").font(.caption2) }
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
       .disabled(kiWeighting)

       if let onLoesen {
         Button { onLoesen() } label: {
           Image(systemName: "link.slash").font(.caption2)
         }
         .buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
         .help("Verknüpfung lösen")
       }
     }
   }
   if !verfuegbareArgumente.isEmpty, let onVerknuepfen {
     HStack(spacing: 6) {
       Text("Verknüpfen:").font(.caption2).foregroundStyle(.secondary)
       Menu {
         ForEach(verfuegbareArgumente) { arg in
           Button(arg.title) { onVerknuepfen(arg.id ?? "") }
         }
       } label: {
         Label("Argument wählen", systemImage: "link")
           .font(.caption2)
       }
       .menuStyle(.borderlessButton)
     }
   }
 }
 .padding(10)
 .background(Color.teal.opacity(eingerueckt ? 0.07 : 0.04), in: RoundedRectangle(cornerRadius: 8))
 .overlay(
   RoundedRectangle(cornerRadius: 8)
     .stroke(eingerueckt ? Color.teal.opacity(0.25) : Color.clear, lineWidth: 1)
 )
 .overlay(alignment: .bottom) {
   if let err = cardFehler {
     Text(err).font(.caption2).foregroundStyle(.red).padding(4)
   }
 }
}

private func kiGewichten() async {
 guard let id = beweis.id else { return }
 kiWeighting = true
 cardFehler = nil
 defer { kiWeighting = false }
 let prompt = "Bewerte Beweisgewicht (0-10): \"\(beweis.title)\" -- \(beweis.description ?? "")"
 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: ["type": "object", "properties": ["gewicht": ["type": "number"], "begruendung": ["type": "string"]]] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "Beweis -- KI gewichten"
   )
   guard let gewicht = KIJson.number(in: d, keys: "gewicht", "weight", "staerke", "score") else {
     await MainActor.run { cardFehler = "KI-Antwort ohne Gewicht." }
     return
   }
   var updated = beweis
   updated.ki_weight = min(10, max(0, gewicht))
   updated.ki_bewertung = KIJson.string(in: d, keys: "begruendung", "reasoning")
   let saved = try await Services.evidence.update(id: id, entity: updated)
   await MainActor.run { onUpdate(saved) }
 } catch {
   await MainActor.run { cardFehler = error.localizedDescription }
 }
}

private func diskrepanzAnalysieren() async {
 analyzing = true
 cardFehler = nil
 defer { analyzing = false }
 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: "Diskrepanz Beweis: Manuell \(beweis.weight), KI \(Int(beweis.ki_weight ?? 0)). Beweis: \(beweis.title)",
     schema: ["type": "object", "properties": [
       "erklaerung": ["type": "string"], "vorschlaege": ["type": "array", "items": ["type": "string"]]
     ]] as [String: Any],
     logCaseId: viewModel.caseId,
     logKiName: "Beweis -- Diskrepanz"
   )
   let erk = KIJson.string(in: d, keys: "erklaerung", "explanation") ?? ""
   let vorschlaege = (d["vorschlaege"] as? [String]) ?? []
   await MainActor.run { analyse = (erk, vorschlaege) }
 } catch {
   await MainActor.run { cardFehler = error.localizedDescription }
 }
}
}

struct KIArgumentePanel: View {
let ergebnis: TabArgumenteBeweiseView.KIArgumenteErgebnis
let onUebernehmen: (TabArgumenteBeweiseView.KIArgVorschlag, Argument.ArgumentSeite) -> Void
let onSchliessen: () -> Void

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Label("KI-generierte Argumente", systemImage: "sparkles").font(.caption.bold())
     Spacer()
     Button { onSchliessen() } label: { Image(systemName: "xmark.circle") }.buttonStyle(.plain)
   }
   ForEach(ergebnis.eigene) { a in
     HStack {
       Text("n \(a.titel)").font(.caption)
       Spacer()
       Button("+") { onUebernehmen(a, .eigen) }.buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
     }
   }
   ForEach(ergebnis.gegner) { a in
     HStack {
       Text("nn \(a.titel)").font(.caption)
       Spacer()
       Button("+") { onUebernehmen(a, .gegner) }.buttonStyle(FenlynineOSGlassBorderedButtonStyle()).controlSize(.mini)
     }
   }
 }
 .padding(10)
 .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
}
}

