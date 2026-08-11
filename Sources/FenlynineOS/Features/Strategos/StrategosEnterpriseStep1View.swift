import SwiftUI

// MARK: - Strategos Enterprise Schritt 1 (Step1Kontext.jsx)

struct StrategosEnterpriseStep1View: View {
@Binding var szenario: StrategosScenario
let onSave: ([String: Any]) async -> Void

@State private var ctx: [String: Any] = [:]
@State private var selRG: Set<String> = []
@State private var selMaerkte: Set<String> = []
@State private var docs: [[String: Any]] = []
@State private var lexCases: [LegalCase] = []
@State private var linkedCase: LegalCase?
@State private var uploading = false
@State private var analyzing = false
@State private var syncingLexara = false
@State private var lexaraSyncOK: String?
@State private var fehler: String?

private let rechtsformen = ["GmbH", "AG", "GmbH & Co. KG", "SE", "Ltd.", "Inc.", "OHG", "KG", "Einzelunternehmen", "Sonstige"]
private let branchen = ["Technologie", "Pharma", "Automobil", "Energie", "Finanzdienstleistungen", "Handel", "Immobilien", "Maschinenbau", "Chemie", "Telekommunikation", "Medien", "Rüstung / Verteidigung", "Agrar / Lebensmittel", "Sonstige"]
private let laender = ["Deutschland", "Österreich", "Schweiz", "Niederlande", "Frankreich", "Italien", "Spanien", "UK", "USA", "China", "Sonstige"]
private let maerkte = ["DE", "AT", "CH", "UK", "US", "EU", "CN", "Asien-Pazifik", "MENA", "LATAM", "Global"]
private let situationstypen: [(String, String, String)] = [
  ("geplante_handlung", "Geplante Handlung", "n"),
  ("bestehende_situation", "Bestehende Situation", "n"),
  ("reaktion_dritte", "Reaktion auf Dritten", "n"),
  ("vertrag_analyse", "Vertrag / Dokument", "n"),
  ("risikovorsorge", "Compliance-Check", "nn")
]

var body: some View {
  VStack(spacing: 20) {
    StrategosSchrittHeader(
      nummer: 1,
      titel: "Eingabe & Kontext",
      beschreibung: "Grundinformationen für die gesamte Enterprise-KI-Analyse"
    )

    if let fehler { Text(fehler).font(.caption).foregroundStyle(.red) }

    unternehmensIdentitaet
    situationCard
    dokumenteCard
    rechtsgebieteCard
    lexaraCard
  }
  .onAppear {
    ctx = szenario.unternehmenskontext?.dictValue ?? [:]
    selRG = Set(ctx["rechtsgebiete"] as? [String] ?? [])
    selMaerkte = Set(ctx["operative_maerkte"] as? [String] ?? [])
    docs = ctx["dokumente"] as? [[String: Any]] ?? []
    if let lid = ctx["lexara_case_id"] as? String {
      linkedCase = lexCases.first { $0.id == lid }
    }
    Task {
      lexCases = (try? await Services.cases.list(sort: "-updated_at", limit: 50)) ?? []
      if let lid = ctx["lexara_case_id"] as? String {
        linkedCase = lexCases.first { $0.id == lid }
      }
    }
  }
}

private var unternehmensIdentitaet: some View {
  VStack(alignment: .leading, spacing: 12) {
    Text("A · Unternehmensidentität").font(.caption.bold()).foregroundStyle(.blue)
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
      ctxField("Unternehmensname", key: "unternehmen_name")
      ctxPicker("Rechtsform", key: "rechtsform", options: rechtsformen)
      ctxPicker("Branche", key: "branche", options: branchen)
      ctxField("Spezialisierung", key: "branche_freitext")
      ctxNumberField("Jahresumsatz", key: "umsatz")
      ctxNumberField("Mitarbeiter", key: "mitarbeiter")
      ctxPicker("Hauptsitz -- Land", key: "hauptsitz_land", options: laender)
      ctxField("Hauptsitz -- Stadt", key: "hauptsitz_stadt")
    }
    VStack(alignment: .leading, spacing: 6) {
      Text("Operative Märkte").font(.caption2.bold()).foregroundStyle(.secondary)
      FlowLayout(spacing: 6) {
        ForEach(maerkte, id: \.self) { m in
          let sel = selMaerkte.contains(m)
          Button(m) {
            if sel { selMaerkte.remove(m) } else { selMaerkte.insert(m) }
            persist(["operative_maerkte": Array(selMaerkte)])
          }
          .font(.caption2)
          .padding(.horizontal, 8).padding(.vertical, 4)
          .background(sel ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08), in: Capsule())
          .buttonStyle(.plain)
        }
      }
    }
  }
  .padding(14)
  .background(.background, in: RoundedRectangle(cornerRadius: 12))
  .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.15)))
}

private var situationCard: some View {
 VStack(alignment: .leading, spacing: 12) {
   Text("B · Situation").font(.caption.bold()).foregroundStyle(.orange)
   LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
     ForEach(situationstypen, id: \.0) { val, label, icon in
       let sel = (ctx["situationstyp"] as? String) == val
       Button {
         persist(["situationstyp": val])
       } label: {
         VStack(spacing: 4) {
           Text(icon).font(.title3)
           Text(label).font(.caption2.bold()).multilineTextAlignment(.center)
         }
         .frame(maxWidth: .infinity)
         .padding(10)
         .background(sel ? Color.orange.opacity(0.1) : Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
         .overlay(RoundedRectangle(cornerRadius: 10).stroke(sel ? Color.orange : Color.gray.opacity(0.15), lineWidth: sel ? 2 : 1))
       }
       .buttonStyle(.plain)
     }
   }
   LabeledTextArea("Sachverhalt (min. 3 Sätze)", text: bindingString("sachverhalt_lang"), minHeight: 100)
   HStack(spacing: 10) {
     ctxField("Gegenpartei", key: "gegner_name")
     ctxPicker("Rolle", key: "gegner_rolle", options: ["kunde", "lieferant", "wettbewerber", "behoerde", "investor", "mitarbeiter"])
   }
   let zk = (ctx["zeitkritikalitaet"] as? Int) ?? (ctx["zeitkritikalitaet"] as? Double).map { Int($0) } ?? 5
   VStack(alignment: .leading, spacing: 4) {
     Text("Zeitkritikalität: \(zk)/10").font(.caption2.bold())
     Slider(value: Binding(
       get: { Double((ctx["zeitkritikalitaet"] as? Int) ?? zk) },
       set: { persist(["zeitkritikalitaet": Int($0)]) }
     ), in: 1...10, step: 1)
   }
 }
 .padding(14)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.15)))
}

private var dokumenteCard: some View {
 VStack(alignment: .leading, spacing: 10) {
   HStack {
     Text("C · Dokument-Upload").font(.caption.bold()).foregroundStyle(.purple)
     Spacer()
     Button {
       Task { await uploadDokumente() }
     } label: {
       if uploading { ProgressView().scaleEffect(0.7) }
       else { Label("Dokumente", systemImage: "doc.badge.plus") }
     }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     .disabled(uploading)
   }
   if docs.isEmpty {
     Text("Verträge, Patente, Bilanzen · PDF / DOCX / TXT").font(.caption).foregroundStyle(.secondary)
       .frame(maxWidth: .infinity).padding(.vertical, 16)
   } else {
     ForEach(Array(docs.enumerated()), id: \.offset) { i, doc in
       HStack {
         VStack(alignment: .leading, spacing: 2) {
           Text(doc["name"] as? String ?? "Dokument").font(.caption.bold())
           if let a = doc["analyse"] as? [String: Any] {
             Text("3 \(a["dokumenttyp"] as? String ?? "Analysiert")").font(.caption2).foregroundStyle(.purple)
           }
         }
         Spacer()
         if doc["analyse"] == nil, let url = doc["url"] as? String {
           Button("KI-Scan") { Task { await scanDoc(index: i, url: url) } }
             .font(.caption2).buttonStyle(FenlynineOSGlassBorderedButtonStyle())
         }
         Button {
           docs.remove(at: i)
           persist(["dokumente": docs])
         } label: {
           Image(systemName: "trash").font(.caption).foregroundStyle(.secondary)
         }
         .buttonStyle(.plain)
       }
       .padding(8)
       .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
     }
   }
 }
 .padding(14)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
}

private var rechtsgebieteCard: some View {
 VStack(alignment: .leading, spacing: 10) {
   HStack {
     Text("D · Rechtsgebiete").font(.caption.bold()).foregroundStyle(.green)
     Spacer()
     Button {
       Task { await kiVorauswahl() }
     } label: {
       if analyzing { ProgressView().scaleEffect(0.7) }
       else { Label("KI-Vorauswahl", systemImage: "sparkles") }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(analyzing)
   }
   LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 6) {
     ForEach(StrategosRechtsgebiete.allKeys, id: \.key) { rg in
       let sel = selRG.contains(rg.key)
       Button(rg.label) {
         if sel { selRG.remove(rg.key) } else { selRG.insert(rg.key) }
         persist(["rechtsgebiete": Array(selRG)])
       }
       .font(.caption2)
       .padding(.horizontal, 8).padding(.vertical, 6)
       .frame(maxWidth: .infinity, alignment: .leading)
       .background(sel ? Color.green.opacity(0.12) : Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
       .overlay(RoundedRectangle(cornerRadius: 8).stroke(sel ? Color.green : Color.clear))
       .buttonStyle(.plain)
     }
   }
 }
 .padding(14)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
}

private var lexaraCard: some View {
 VStack(alignment: .leading, spacing: 10) {
   Text("E · LEXARA-Import (optional)").font(.caption.bold()).foregroundStyle(.red)
   Picker("LEXARA-Fall", selection: Binding(
     get: { ctx["lexara_case_id"] as? String ?? "" },
     set: { id in
       persist(["lexara_case_id": id.isEmpty ? nil : id])
       linkedCase = lexCases.first { $0.id == id }
     }
   )) {
     Text("-- nicht verknüpft --").tag("")
     ForEach(lexCases) { c in
       Text("\(c.fallname) \(c.aktenzeichen.map { "(\($0))" } ?? "")").tag(c.id ?? "")
     }
   }
   if let lc = linkedCase {
     HStack {
       VStack(alignment: .leading) {
         Text(lc.fallname).font(.caption.bold())
         Text("\(lc.aktenzeichen ?? "") · \(lc.rechtsgebiet ?? "")").font(.caption2).foregroundStyle(.secondary)
       }
       Spacer()
       Text("\(Int(lc.prognose ?? 0))%")
         .font(.title3.bold())
         .foregroundStyle((lc.prognose ?? 0) >= 60 ? .green : .orange)
     }
     .padding(10)
     .background(Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

     Button {
       Task { await lexaraKontextSync() }
     } label: {
       if syncingLexara {
         ProgressView().scaleEffect(0.7)
         Text("Synchronisiere Lexara…")
       } else {
         Label("Lexara-Kontext live synchronisieren", systemImage: "arrow.triangle.2.circlepath")
       }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .tint(.red)
     .disabled(syncingLexara || (ctx["lexara_case_id"] as? String ?? "").isEmpty)

     if let ok = lexaraSyncOK {
       Text(ok).font(.caption2).foregroundStyle(.green)
     }
   }
 }
 .padding(14)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
}

@ViewBuilder
private func ctxField(_ label: String, key: String) -> some View {
 LabeledTextField(label, text: bindingString(key))
}

@ViewBuilder
private func ctxNumberField(_ label: String, key: String) -> some View {
 LabeledTextField(label, text: Binding(
   get: {
     if let n = ctx[key] as? Int { return "\(n)" }
     if let n = ctx[key] as? Double { return "\(Int(n))" }
     return ""
   },
   set: { persist([key: Int($0) ?? 0]) }
 ))
}

@ViewBuilder
private func ctxPicker(_ label: String, key: String, options: [String]) -> some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
   Picker(label, selection: Binding(
     get: { ctx[key] as? String ?? "" },
     set: { persist([key: $0]) }
   )) {
     Text("--").tag("")
     ForEach(options, id: \.self) { Text($0).tag($0) }
   }
   .labelsHidden()
 }
}

private func bindingString(_ key: String) -> Binding<String> {
 Binding(
   get: { ctx[key] as? String ?? "" },
   set: { persist([key: $0]) }
 )
}

private func persist(_ patch: [String: Any]) {
 for (k, v) in patch { ctx[k] = v }
 szenario.unternehmenskontext = AnyCodable(ctx)
 if let rg = ctx["rechtsgebiete"] as? [String] { selRG = Set(rg) }
 Task { await onSave(["unternehmenskontext": ctx]) }
}

private func lexaraKontextSync() async {
 guard let caseId = ctx["lexara_case_id"] as? String, !caseId.isEmpty else { return }
 syncingLexara = true
 fehler = nil
 lexaraSyncOK = nil
 defer { syncingLexara = false }
 do {
   let sync = try await LexaraStrategosBridge.sync(caseId: caseId)
   var updated = szenario
   updated = try await LexaraStrategosBridge.apply(to: &updated, sync: sync)
   await MainActor.run {
     szenario = updated
     ctx = updated.unternehmenskontext?.dictValue ?? ctx
     if let rg = ctx["rechtsgebiete"] as? [String] { selRG = Set(rg) }
     let argCount = (sync.briefing["eigene_argumente"] as? [[String: Any]])?.count ?? 0
     let beweisCount = (sync.briefing["beweise"] as? [[String: Any]])?.count ?? 0
     lexaraSyncOK = "3 \(argCount) Argumente, \(beweisCount) Beweise importiert"
   }
   await onSave([
     "unternehmenskontext": ctx,
     "ki_kontext": updated.ki_kontext?.dictValue ?? [:],
     "lexara_sync": updated.lexara_sync?.dictValue ?? [:],
     "case_id": caseId
   ])
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}

private func uploadDokumente() async {
 let panel = NSOpenPanel()
 panel.allowsMultipleSelection = true
 panel.canChooseFiles = true
 guard panel.runModal() == .OK else { return }
 uploading = true
 defer { uploading = false }
 var neu = docs
 for url in panel.urls {
   do {
     let data = try Data(contentsOf: url)
     let mime = mimeType(for: url.pathExtension)
     let uploaded = try await LLMService.shared.uploadFile(data: data, fileName: url.lastPathComponent, mimeType: mime)
     neu.append([
       "name": url.lastPathComponent,
       "url": uploaded,
       "type": url.pathExtension.lowercased(),
       "uploaded_at": ISO8601DateFormatter().string(from: Date())
     ])
   } catch {
     await MainActor.run { fehler = error.localizedDescription }
   }
 }
 docs = neu
 persist(["dokumente": neu])
}

private func scanDoc(index: Int, url: String) async {
 uploading = true
 defer { uploading = false }
 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "dokumenttyp": ["type": "string"],
     "parteien": ["type": "array", "items": ["type": "string"]],
     "fristen": ["type": "array", "items": ["type": "object"]],
     "kritische_klauseln": ["type": "array", "items": ["type": "string"]]
   ]
 ]
 do {
   let result = try await LLMService.shared.extractDataFromFile(fileUrl: url, jsonSchema: schema)
   docs[index]["analyse"] = result?.dictValue ?? [:]
   persist(["dokumente": docs])
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}

private func kiVorauswahl() async {
 analyzing = true
 fehler = nil
 defer { analyzing = false }
 let keys = StrategosRechtsgebiete.allKeys.map(\.key).joined(separator: ", ")
 let prompt = """
 Wirtschaftsrechtler: Wähle relevante Rechtsgebiete.
 Unternehmen: \(ctx["unternehmen_name"] as? String ?? "--") (\(ctx["rechtsform"] as? String ?? "--"), \(ctx["branche"] as? String ?? "--"))
 Umsatz: \(ctx["umsatz"] as? Int ?? 0)€, MA: \(ctx["mitarbeiter"] as? Int ?? 0)
 Situation: \(ctx["situationstyp"] as? String ?? "--")
 Sachverhalt: \(ctx["sachverhalt_lang"] as? String ?? "--")
 Verfügbar: \(keys)
 """
 let schema: [String: Any] = [
   "type": "object",
   "properties": [
     "empfohlene_rechtsgebiete": ["type": "array", "items": ["type": "string"]],
     "dringlichkeit": ["type": "number"]
   ]
 ]
 do {
   let response: AnyCodable = try await LLMService.shared.invoke(prompt: prompt, schema: schema, model: "claude_sonnet_4_6")
   if let rg = response.dictValue?["empfohlene_rechtsgebiete"] as? [String], !rg.isEmpty {
     selRG = Set(rg)
     persist(["rechtsgebiete": rg])
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}

private func mimeType(for ext: String) -> String {
 switch ext.lowercased() {
 case "pdf": return "application/pdf"
 case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
 case "txt": return "text/plain"
 case "jpg", "jpeg": return "image/jpeg"
 case "png": return "image/png"
 default: return "application/octet-stream"
 }
}
}

