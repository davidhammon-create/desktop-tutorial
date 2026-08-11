import SwiftUI
import Charts
import PDFKit
import AppKit

// MARK: - Strategos Hauptansicht (6-Schritt-Enterprise-Workflow)

struct StrategosView: View {
@State private var szenarien: [StrategosScenario] = []
@State private var selectedId: String? = nil
@State private var zeigeNeueSzenario = false
@State private var isLoading = false
@State private var suchtext = ""
@Environment(\.fenlynineOSFensterModus) private var fensterModus
@Environment(\.fenlynineOSVergleichSpalte) private var vergleichSpalte

private var gefilterteSzenarien: [StrategosScenario] {
  var result = szenarien
  if !suchtext.isEmpty {
    let t = suchtext.lowercased()
    result = result.filter {
      $0.titel.lowercased().contains(t) ||
      ($0.rechtsgebiet?.lowercased().contains(t) ?? false) ||
      $0.modus.rawValue.lowercased().contains(t)
    }
  }
  result.sort { a, b in
    let aDemo = a.titel.hasPrefix("[Demo]")
    let bDemo = b.titel.hasPrefix("[Demo]")
    if aDemo != bDemo { return aDemo }
    return a.titel < b.titel
  }
  return result
}

private var szenarioGruppen: [(titel: String, modus: StrategosScenario.StrategosModus, eintraege: [StrategosScenario])] {
  let reihenfolge: [StrategosScenario.StrategosModus] = [.vertrag, .fall, .unternehmen]
  return reihenfolge.compactMap { modus in
    let eintraege = gefilterteSzenarien.filter { $0.modus == modus }
    guard !eintraege.isEmpty else { return nil }
    return (StrategosSzenarioListeTokens.gruppenTitel(fuer: modus), modus, eintraege)
  }
}

private var switcherItems: [FenlynineOSEntityItem] {
  gefilterteSzenarien.compactMap { s in
    guard let id = s.id else { return nil }
    return FenlynineOSEntityItem(
      id: id,
      titel: s.titel,
      untertitel: StrategosSzenarioListeTokens.untertitel(fuer: s),
      gruppe: StrategosSzenarioListeTokens.gruppenTitel(fuer: s.modus),
      symbol: "shield.lefthalf.filled"
    )
  }
}

@ViewBuilder
private func detailMitSwitcher() -> some View {
  VStack(spacing: 0) {
    FenlynineOSEntitySwitcher(
      label: "Situation",
      symbol: "shield.lefthalf.filled",
      items: switcherItems,
      selectedId: $selectedId,
      onListe: fensterModus ? nil : nil,
      listenLabel: "Szenarien"
    )
    Group {
      if let id = selectedId, let szenario = szenarien.first(where: { $0.id == id }) {
        StrategosEnterpriseShellView(szenario: szenario)
          .id(id)
      } else {
        StrategosWillkommen()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

var body: some View {
  Group {
    if fensterModus {
      // Fenstermodus: Switcher immer sichtbar -- Situation wechseln ohne Modul verlassen
      VStack(spacing: 0) {
        FenlynineOSEntitySwitcher(
          label: "Situation",
          symbol: "shield.lefthalf.filled",
          items: switcherItems,
          selectedId: $selectedId
        )
        HStack {
          Spacer(minLength: 0)
          Button { zeigeNeueSzenario = true } label: {
            Label("Neu", systemImage: "plus")
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
       .padding(.horizontal, 10)
       .padding(.vertical, 4)
       .background(Premium.ink.opacity(0.5))
       Divider().overlay(Premium.hairline)
       Group {
         if let id = selectedId, let szenario = szenarien.first(where: { $0.id == id }) {
           StrategosEnterpriseShellView(szenario: szenario)
             .id(id)
         } else {
           StrategosWillkommen()
         }
       }
       .frame(maxWidth: .infinity, maxHeight: .infinity)
     }
   } else {
     NavigationSplitView {
       StrategosSzenarioListe(
         szenarien: gefilterteSzenarien,
         gruppen: szenarioGruppen,
         selectedId: $selectedId,
         suchtext: $suchtext,
         isLoading: isLoading
       )
       .navigationSplitViewColumnWidth(min: 220, ideal: 260)
       .toolbar {
         ToolbarItem {
           Button { zeigeNeueSzenario = true } label: {
             Image(systemName: "plus")
           }
         }
       }
     } detail: {
       detailMitSwitcher()
     }
   }
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .clipped()
 .navigationTitle(fensterModus ? "" : "Strategos -- Enterprise Intelligence")
 .task { await laden() }
 .sheet(isPresented: $zeigeNeueSzenario) {
   NeuesSzenarioSheet { neues in
     szenarien.insert(neues, at: 0)
     selectedId = neues.id
   }
 }
}

private func laden() async {
 isLoading = true
 defer { isLoading = false }
 szenarien = (try? await Services.strategosScenarios.list()) ?? []
 if selectedId == nil, let demo = szenarien.first(where: { $0.id == DemoIDs.strategosEnterprise }) {
   selectedId = demo.id
 } else if selectedId == nil, let first = szenarien.first {
   selectedId = first.id
 }
}
}

// MARK: - Szenario-Auswahl (Lexara-Fallliste-Stil, einheitliches Icon)

private enum StrategosSzenarioListeTokens {
static let iconSymbol = "shield.lefthalf.filled"
static let iconColor = Color(red: 0.95, green: 0.65, blue: 0.2)

static func gruppenTitel(fuer modus: StrategosScenario.StrategosModus) -> String {
 switch modus {
 case .vertrag: return "Verträge"
 case .fall: return "Situationen"
 case .unternehmen: return "Unternehmen"
 }
}

static func untertitel(fuer szenario: StrategosScenario) -> String {
 var parts: [String] = []
 if let rg = szenario.rechtsgebiet { parts.append(rg) }
 parts.append("Schritt \(szenario.enterprise_step + 1)/8")
 if szenario.abgeschlossen { parts.append("Abgeschlossen") }
 return parts.joined(separator: " · ")
}
}

struct StrategosSzenarioListe: View {
let szenarien: [StrategosScenario]
let gruppen: [(titel: String, modus: StrategosScenario.StrategosModus, eintraege: [StrategosScenario])]
@Binding var selectedId: String?
@Binding var suchtext: String
let isLoading: Bool

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Text("Szenarien")
       .font(.system(size: 15, weight: .semibold))
       .foregroundStyle(MacOSSettingsTokens.title)
     Spacer()
     Text("\(szenarien.count)")
       .font(.system(size: 11, weight: .medium))
       .foregroundStyle(MacOSSettingsTokens.subtitle)
   }
   .padding(.horizontal, 16)
   .padding(.vertical, 12)

   MacOSSettingsSearchField(text: $suchtext, placeholder: "Szenarien suchen")
     .padding(.horizontal, 12)
     .padding(.bottom, 10)

   if isLoading {
     ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
   } else if szenarien.isEmpty {
     VStack(spacing: 12) {
       Image(systemName: StrategosSzenarioListeTokens.iconSymbol)
         .font(.system(size: 32))
         .foregroundStyle(MacOSSettingsTokens.subtitle)
       Text(suchtext.isEmpty ? "Kein Szenario" : "Keine Treffer")
         .font(.caption)
         .foregroundStyle(MacOSSettingsTokens.subtitle)
     }
     .frame(maxWidth: .infinity, maxHeight: .infinity)
   } else {
     ScrollView {
       VStack(spacing: 14) {
         ForEach(gruppen, id: \.modus) { gruppe in
           MacOSSettingsGroupedList(titel: gruppe.titel) {
             ForEach(Array(gruppe.eintraege.enumerated()), id: \.offset) { index, szenario in
               StrategosSzenarioKarte(
                 szenario: szenario,
                 isSelected: selectedId == szenario.id
               ) {
                 withAnimation(.spring(duration: 0.22)) {
                   selectedId = szenario.id
                 }
               }
               if index < gruppe.eintraege.count - 1 {
                 MacOSSettingsGroupDivider()
               }
             }
           }
         }
       }
       .padding(12)
     }
   }
 }
 .scrollContentBackground(.hidden)
 .background { Color.clear }
}
}

struct StrategosSzenarioKarte: View {
let szenario: StrategosScenario
let isSelected: Bool
let action: () -> Void

var body: some View {
 Button(action: action) {
   MacOSSettingsDeviceRow(
     symbol: StrategosSzenarioListeTokens.iconSymbol,
     iconColor: StrategosSzenarioListeTokens.iconColor,
     titel: szenario.titel.replacingOccurrences(of: "[Demo] ", with: ""),
     untertitel: StrategosSzenarioListeTokens.untertitel(fuer: szenario),
     isSelected: isSelected
   )
 }
 .buttonStyle(.plain)
}
}

// MARK: - Strategos Shell (6-Schritt-Workflow)

struct StrategosShellView: View {
let szenario: StrategosScenario
@State private var aktuellerSchritt: Int
@State private var localSzenario: StrategosScenario

init(szenario: StrategosScenario) {
 self.szenario = szenario
 _aktuellerSchritt = State(initialValue: szenario.aktueller_schritt)
 _localSzenario = State(initialValue: szenario)
}

private let schritte = [
 ("Kontext", "building.2.crop.circle"),
 ("Situation", "chart.bar.doc.horizontal"),
 ("Szenario-Matrix", "square.grid.3x3.fill"),
 ("Aktionsplan", "bolt.fill"),
 ("Empfehlung", "star.fill"),
 ("Sync & Export", "arrow.triangle.2.circlepath")
]

var body: some View {
 VStack(spacing: 0) {
   // Fortschritts-Header
   StrategosProgressHeader(schritte: schritte, aktuellerSchritt: aktuellerSchritt)
     .padding(.horizontal, 24)
     .padding(.vertical, 14)
     .background(Color(nsColor: .controlBackgroundColor))

   Divider()

   // Schritt-Inhalt
   ScrollView {
     VStack(spacing: 24) {
       switch aktuellerSchritt {
       case 0: StrategosSchritt1(szenario: $localSzenario)
       case 1: StrategosSchritt2(szenario: $localSzenario)
       case 2: StrategosSchritt3(szenario: $localSzenario)
       case 3: StrategosSchritt4(szenario: $localSzenario)
       case 4: StrategosSchritt5(szenario: $localSzenario)
       case 5: StrategosSchritt6(szenario: $localSzenario)
       default: EmptyView()
       }
     }
     .padding(24)
   }

   Divider()

   // Navigation
   HStack {
     if aktuellerSchritt > 0 {
       Button("<- Zurück") {
         withAnimation { aktuellerSchritt -= 1 }
       }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     }
     Spacer()
     Button("Speichern") {
       Task { await speichern() }
     }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())

     if aktuellerSchritt < 5 {
       Button("Weiter ->") {
         withAnimation { aktuellerSchritt += 1 }
       }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     } else {
       Button("Abschließen") {
         Task { await abschliessen() }
       }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     }
   }
   .padding(16)
 }
 .navigationTitle(localSzenario.titel)
}

private func speichern() async {
 localSzenario.aktueller_schritt = aktuellerSchritt
 guard let id = localSzenario.id else { return }
 _ = try? await Services.strategosScenarios.update(id: id, entity: localSzenario)
 await MainActor.run {
   ImperiumEntscheidungsJournal.shared.eintrag(
     typ: .strategie,
     titel: "Strategos gespeichert: \(localSzenario.titel)",
     detail: "Schritt \(aktuellerSchritt + 1) · \(localSzenario.abgeschlossen == true ? "abgeschlossen" : "in Arbeit")",
     module: ["Strategos", "Entscheidungsjournal"]
   )
 }
}

private func abschliessen() async {
 localSzenario.abgeschlossen = true
 await speichern()
}
}

// MARK: - Fortschritts-Header

struct StrategosProgressHeader: View {
let schritte: [(String, String)]
let aktuellerSchritt: Int

var body: some View {
 HStack(spacing: 0) {
   ForEach(Array(schritte.enumerated()), id: \.offset) { index, schritt in
     HStack(spacing: 0) {
       // Schritt-Kreis
       VStack(spacing: 4) {
         ZStack {
           Circle()
             .fill(index <= aktuellerSchritt ? Color.blue : Color.gray.opacity(0.2))
             .frame(width: 28, height: 28)
           if index < aktuellerSchritt {
             Image(systemName: "checkmark")
               .font(.system(size: 11, weight: .bold))
               .foregroundStyle(.white)
           } else if index == aktuellerSchritt {
             Image(systemName: schritt.1)
               .font(.system(size: 11, weight: .bold))
               .foregroundStyle(.white)
           } else {
             Text("\(index + 1)")
               .font(.system(size: 11, weight: .bold))
               .foregroundStyle(.secondary)
           }
         }
         Text(schritt.0)
           .font(.system(size: 10, weight: index == aktuellerSchritt ? .semibold : .regular))
           .foregroundStyle(index <= aktuellerSchritt ? .primary : .secondary)
       }

       // Verbindungslinie
       if index < schritte.count - 1 {
         Rectangle()
           .fill(index < aktuellerSchritt ? Color.blue : Color.gray.opacity(0.2))
           .frame(height: 2)
           .padding(.bottom, 22)
       }
     }
   }
 }
}
}

// MARK: - Schritt 1: Unternehmenskontext

struct StrategosSchritt1: View {
@Binding var szenario: StrategosScenario
@State private var unternehmen = ""
@State private var branche = ""
@State private var beschreibung = ""
@State private var selectedRechtsgebiete: Set<String> = []
@State private var kiLaeuft = false
@State private var kiAuswertung: String?
@State private var kiFehler: String?

var body: some View {
 VStack(spacing: 20) {
   StrategosSchrittHeader(
     nummer: 1,
     titel: "Unternehmenskontext",
     beschreibung: "Erfassen Sie den rechtlich-strategischen Kontext des Unternehmens oder Falls."
   )

   VStack(spacing: 16) {
     LabeledTextField("Unternehmen / Mandant", text: $unternehmen)
     LabeledTextField("Branche / Rechtsgebiet", text: $branche)
     LabeledTextArea("Sachverhalt & Ausgangslage", text: $beschreibung)

     VStack(alignment: .leading, spacing: 8) {
       Text("Rechtsgebiete (für Schritt 2)").font(.caption.bold()).foregroundStyle(.secondary)
       LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 6) {
         ForEach(StrategosRechtsgebiete.allKeys, id: \.key) { rg in
           let sel = selectedRechtsgebiete.contains(rg.key)
           Button(rg.label) {
             if sel { selectedRechtsgebiete.remove(rg.key) }
             else { selectedRechtsgebiete.insert(rg.key) }
             persistContext()
           }
           .font(.caption2)
           .padding(.horizontal, 8).padding(.vertical, 4)
           .background(sel ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08), in: Capsule())
           .buttonStyle(.plain)
         }
       }
     }

     DokumentUploadButton(modus: szenario.modus) { docs in
       var ctx = szenario.unternehmenskontext?.dictValue ?? [:]
       ctx["dokumente"] = docs
       szenario.unternehmenskontext = AnyCodable(ctx)
       Task {
         guard let id = szenario.id else { return }
         _ = try? await Services.strategosScenarios.update(id: id, entity: szenario)
       }
     }

     Button {
       Task { await kiKontextAnalyse() }
     } label: {
       if kiLaeuft {
         ProgressView().scaleEffect(0.8)
       } else {
         Label("KI-Kontextanalyse starten", systemImage: "brain.fill")
       }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(beschreibung.isEmpty || kiLaeuft)

     if let err = kiFehler {
       Text(err).font(.caption).foregroundStyle(.red)
     }

     if let ki = kiAuswertung {
       KIProfilKarte(titel: "KI-Kontextbewertung", inhalt: ki)
     }
   }
 }
 .onAppear { hydrate() }
}

private func hydrate() {
 guard let ctx = szenario.unternehmenskontext?.dictValue else { return }
 unternehmen = ctx["unternehmen_name"] as? String ?? ""
 branche = ctx["branche"] as? String ?? ""
 beschreibung = ctx["sachverhalt_lang"] as? String ?? ""
 if let rg = ctx["rechtsgebiete"] as? [String] {
   selectedRechtsgebiete = Set(rg)
 }
 kiAuswertung = ctx["ki_kontext_analyse"] as? String
}

private func persistContext() {
 var ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 ctx["unternehmen_name"] = unternehmen
 ctx["branche"] = branche
 ctx["sachverhalt_lang"] = beschreibung
 ctx["rechtsgebiete"] = Array(selectedRechtsgebiete)
 szenario.unternehmenskontext = AnyCodable(ctx)
 Task {
   guard let id = szenario.id else { return }
   _ = try? await Services.strategosScenarios.update(id: id, entity: szenario)
 }
}

private func kiKontextAnalyse() async {
 kiLaeuft = true
 kiFehler = nil
 defer { kiLaeuft = false }
 persistContext()
 let prompt = """
 Analysiere folgenden rechtlich-strategischen Kontext:
 Unternehmen: \(unternehmen)
 Branche: \(branche)
 Sachverhalt: \(beschreibung)
 Rechtsgebiete: \(selectedRechtsgebiete.joined(separator: ", "))

 1. Identifiziere die wichtigsten rechtlichen Risiken und Chancen
 2. Bewerte die strategische Ausgangslage (SWOT-ähnlich, juristisch fokussiert)
 3. Identifiziere mögliche Handlungsoptionen
 TRANSPARENZ: Erkläre deine Bewertungsmethodik.
 """
 do {
   let result: String = try await LLMService.shared.invokeText(prompt: prompt, model: "claude_sonnet_4_6")
   await MainActor.run {
     kiAuswertung = result
     var ctx = szenario.unternehmenskontext?.dictValue ?? [:]
     ctx["unternehmen_name"] = unternehmen
     ctx["branche"] = branche
     ctx["sachverhalt_lang"] = beschreibung
     ctx["rechtsgebiete"] = Array(selectedRechtsgebiete)
     ctx["ki_kontext_analyse"] = result
     szenario.unternehmenskontext = AnyCodable(ctx)
   }
   guard let id = szenario.id else { return }
   _ = try? await Services.strategosScenarios.update(id: id, entity: szenario)
 } catch {
   await MainActor.run { kiFehler = error.localizedDescription }
 }
}
}

// MARK: - Schritt 2: Situationsanalyse

struct StrategosSchritt2: View {
@Binding var szenario: StrategosScenario
@State private var vertragsText = ""
@State private var kiLaeuft = false
@State private var klauselAnalyse: [StrategosScenario.KlauselAnalyse] = []
@State private var situationsDaten: AnyCodable?
@State private var fehler: String?

var body: some View {
 VStack(spacing: 20) {
   StrategosSchrittHeader(
     nummer: 2,
     titel: "Situationsanalyse",
     beschreibung: szenario.modus == .vertrag ?
       "Vertragstextanalyse: Jede Klausel wird auf Risiken und Auswirkungen geprüft." :
       "KI-Tiefenanalyse pro Rechtsgebiet mit Risiko-Scores und Fristen."
   )

   if szenario.modus == .vertrag {
     LabeledTextArea("Vertragstext einfügen", text: $vertragsText, minHeight: 200)

     Button {
       Task { await vertragsAnalyse() }
     } label: {
       if kiLaeuft {
         ProgressView().scaleEffect(0.8)
       } else {
         Label("Vertragsklauseln analysieren", systemImage: "doc.text.magnifyingglass")
       }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(vertragsText.isEmpty || kiLaeuft)

     if !klauselAnalyse.isEmpty {
       KlauselHeatmapView(klauseln: klauselAnalyse)
     }
   } else {
     LabeledTextArea("Aktuelle Situation beschreiben", text: $vertragsText)
     Button {
       Task { await situationsAnalyse() }
     } label: {
       if kiLaeuft { ProgressView().scaleEffect(0.8) }
       else { Label("KI-Situationsanalyse", systemImage: "chart.bar.doc.horizontal") }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(vertragsText.isEmpty || kiLaeuft)

     if let dict = situationsDaten?.dictValue ?? szenario.situationsanalyse?.dictValue {
       situationsErgebnisView(dict)
     }
   }

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }
 }
 .onAppear {
   if let sit = szenario.situationsanalyse?.dictValue,
    let text = sit["sachverhalt"] as? String {
     vertragsText = text
   }
   situationsDaten = szenario.situationsanalyse
   if let ka = szenario.klausel_analyse { klauselAnalyse = ka }
 }
}

@ViewBuilder
private func situationsErgebnisView(_ dict: [String: Any]) -> some View {
 VStack(alignment: .leading, spacing: 12) {
   if let risiko = dict["gesamt_risiko"] as? Double {
     HStack {
       Text("Gesamtrisiko").font(.caption.bold())
       Text("\(Int(risiko))/10")
         .font(.system(size: 18, weight: .bold))
         .foregroundStyle(risiko >= 7 ? .red : risiko >= 4 ? .orange : .green)
     }
   }
   if let kritisch = dict["kritische_punkte"] as? [String], !kritisch.isEmpty {
     ListKarte(titel: "Kritische Punkte", eintraege: kritisch, farbe: .red, symbol: "exclamationmark.triangle.fill")
   }
   if let module = dict["module"] as? [[String: Any]] {
     ForEach(Array(module.prefix(4).enumerated()), id: \.offset) { _, m in
       VStack(alignment: .leading, spacing: 4) {
         Text(m["rechtsgebiet"] as? String ?? "Modul")
           .font(.system(size: 12, weight: .semibold))
         if let score = m["risiko_score"] as? Double {
           Text("Risiko: \(Int(score))/10").font(.caption2)
         }
         if let findings = m["findings"] as? [String], let first = findings.first {
           Text(first).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
         }
       }
       .padding(10)
       .background(Color.orange.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
     }
   }
 }
}

private func vertragsAnalyse() async {
 kiLaeuft = true
 fehler = nil
 defer { kiLaeuft = false }

 let prompt = """
 Analysiere folgenden Vertragstext Klausel für Klausel:
 \(vertragsText)

 Für JEDE Klausel: risiko_level (hoch/mittel/niedrig), abteilung, zeitlicher_impact, finanzielle_auswirkung (€), empfehlung.
 Antworte als JSON mit Feld "klauseln": Array von Objekten mit klausel_text, risiko_level, abteilung, zeitlicher_impact, finanzielle_auswirkung, empfehlung.
 TRANSPARENZ: Erkläre die Methodik deiner Risikobewertung.
 """

 do {
   let d = try await LLMService.shared.invokeObject(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "klauseln": [
           "type": "array",
           "items": [
             "type": "object",
             "properties": [
               "klausel_text": ["type": "string"],
               "risiko_level": ["type": "string"],
               "abteilung": ["type": "string"],
               "zeitlicher_impact": ["type": "string"],
               "finanzielle_auswirkung": ["type": "number"],
               "empfehlung": ["type": "string"]
             ] as [String: Any]
           ] as [String: Any]
         ] as [String: Any]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6"
   )
   let klauselnRaw = KIJson.array(in: d, keys: "klauseln", "clauses")
   let klauseln = klauselnRaw.map { row in
     StrategosScenario.KlauselAnalyse(
       klausel_text: KIJson.string(in: row, keys: "klausel_text", "text") ?? "",
       risiko_level: KIJson.string(in: row, keys: "risiko_level", "risiko_stufe") ?? "mittel",
       abteilung: KIJson.string(in: row, keys: "abteilung"),
       zeitlicher_impact: KIJson.string(in: row, keys: "zeitlicher_impact"),
       finanzielle_auswirkung: KIJson.number(in: row, keys: "finanzielle_auswirkung"),
       empfehlung: KIJson.string(in: row, keys: "empfehlung")
     )
   }
   guard !klauseln.isEmpty else {
     await MainActor.run { fehler = "KI lieferte keine Klauseln." }
     return
   }
   await MainActor.run {
     klauselAnalyse = klauseln
     szenario.klausel_analyse = klauseln
     szenario.vertrag_text = vertragsText
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}

private func situationsAnalyse() async {
 kiLaeuft = true
 fehler = nil
 defer { kiLaeuft = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let rechtsgebiete = ctx["rechtsgebiete"] as? [String] ?? [ctx["branche"] as? String ?? "Allgemein"].compactMap { $0 }

 let prompt = """
 Du bist Senior-Partner einer internationalen Großkanzlei. Führe eine vollständige Risikoanalyse durch.

 UNTERNEHMEN: \(ctx["unternehmen_name"] as? String ?? szenario.titel) (\(ctx["rechtsform"] as? String ?? "--"), \(ctx["branche"] as? String ?? "--"))
 SACHVERHALT: \(vertragsText.isEmpty ? (ctx["sachverhalt_lang"] as? String ?? "--") : vertragsText)
 GEGNER: \(ctx["gegner_name"] as? String ?? "--") (\(ctx["gegner_rolle"] as? String ?? "--"))
 RECHTSGEBIETE: \(rechtsgebiete.joined(separator: ", "))

 Für JEDES Rechtsgebiet: risiko_score (0-10), findings (4-6 Punkte mit §§), fristen, normen, querverbindungen.
 Gesamtbewertung: gesamt_risiko, kritische_punkte (Top-3), gesamt_exposure_eur, zeitachse.
 TRANSPARENZ: Erkläre deine Bewertungsmethodik.
 """

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "module": [
           "type": "array",
           "items": [
             "type": "object",
             "properties": [
               "rechtsgebiet": ["type": "string"],
               "risiko_score": ["type": "number"],
               "findings": ["type": "array", "items": ["type": "string"]],
               "normen": ["type": "array", "items": ["type": "string"]]
             ] as [String: Any]
           ] as [String: Any]
         ],
         "gesamt_risiko": ["type": "number"],
         "kritische_punkte": ["type": "array", "items": ["type": "string"]],
         "gesamt_exposure_eur": ["type": "number"]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6"
   )
   var dict = result.dictValue ?? [:]
   dict["sachverhalt"] = vertragsText
   let payload = AnyCodable(dict)
   await MainActor.run {
     situationsDaten = payload
     szenario.situationsanalyse = payload
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

// MARK: - Klausel-Heatmap

struct KlauselHeatmapView: View {
let klauseln: [StrategosScenario.KlauselAnalyse]

private func risikoFarbe(_ risiko: String) -> Color {
 switch risiko.lowercased() {
 case "hoch": return .red.opacity(0.7)
 case "mittel": return .orange.opacity(0.6)
 default: return .green.opacity(0.5)
 }
}

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   Text("Klausel-Risiko-Heatmap")
     .font(.system(size: 13, weight: .semibold))

   ScrollView {
     LazyVGrid(
       columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
       spacing: 8
     ) {
       ForEach(klauseln) { klausel in
         VStack(alignment: .leading, spacing: 4) {
           Text(klausel.klausel_text)
             .font(.system(size: 10, weight: .semibold))
             .lineLimit(3)
           if let abt = klausel.abteilung {
             Text(abt)
               .font(.system(size: 9))
               .foregroundStyle(.white.opacity(0.8))
           }
           if let fin = klausel.finanzielle_auswirkung {
             Text("\(Int(fin)) €")
               .font(.system(size: 11, weight: .bold))
               .foregroundStyle(.white)
           }
         }
         .padding(10)
         .frame(maxWidth: .infinity, alignment: .leading)
         .background(risikoFarbe(klausel.risiko_level), in: RoundedRectangle(cornerRadius: 8))
         .foregroundStyle(.white)
       }
     }
   }
   .frame(maxHeight: 300)

   // Legende
   HStack(spacing: 16) {
     HStack(spacing: 4) { Circle().fill(Color.red).frame(width: 10, height: 10); Text("Hoch").font(.caption2) }
     HStack(spacing: 4) { Circle().fill(Color.orange).frame(width: 10, height: 10); Text("Mittel").font(.caption2) }
     HStack(spacing: 4) { Circle().fill(Color.green).frame(width: 10, height: 10); Text("Niedrig").font(.caption2) }
   }
 }
 .padding(14)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
}
}

// MARK: - Schritte 3-6 (kompakt)

struct StrategosSchritt3: View {
@Binding var szenario: StrategosScenario
@State private var kiLaeuft = false
@State private var matrixDaten: AnyCodable?
@State private var fehler: String?

var body: some View {
 VStack(spacing: 20) {
   StrategosSchrittHeader(
     nummer: 3,
     titel: "Szenario-Matrix",
     beschreibung: "Handlungsoptionen mit Gegnerprognose, Wahrscheinlichkeiten und finanziellen Auswirkungen."
   )

   Button {
     Task { await matrixErstellen() }
   } label: {
     if kiLaeuft { ProgressView().scaleEffect(0.8) }
     else { Label("Szenario-Matrix erstellen", systemImage: "square.grid.3x3.fill") }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(kiLaeuft)

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   if let dict = matrixDaten?.dictValue ?? szenario.szenario_matrix?.dictValue {
     if let szenarien = dict["szenarien"] as? [[String: Any]], !szenarien.isEmpty {
       Text("\(szenarien.count) Szenarien generiert")
         .font(.caption)
         .foregroundStyle(.secondary)
       ForEach(Array(szenarien.prefix(5).enumerated()), id: \.offset) { _, sz in
         VStack(alignment: .leading, spacing: 4) {
           Text(sz["bezeichnung"] as? String ?? "Szenario")
             .font(.system(size: 12, weight: .semibold))
           HStack {
             if let pct = sz["erfolg_pct"] as? Double {
               Text("Erfolg: \(Int(pct))%").font(.caption2).foregroundStyle(.green)
             }
             if let aw = sz["auswirkungsgrad"] as? String {
               Text(aw).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                 .background(Color.orange.opacity(0.15), in: Capsule())
             }
           }
           if let emp = sz["strategos_empfehlung"] as? String {
             Text(emp).font(.caption).foregroundStyle(.secondary).lineLimit(3)
           }
         }
         .padding(10)
         .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
       }
     }
   }

   if matrixDaten != nil || szenario.szenario_matrix != nil {
     ChancenRisikoQuadrant(matrixDaten: matrixDaten ?? szenario.szenario_matrix)
   }
 }
 .onAppear {
   matrixDaten = szenario.szenario_matrix
 }
}

private func matrixErstellen() async {
 kiLaeuft = true
 fehler = nil
 defer { kiLaeuft = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let prompt = """
 Strategischer Senior-Berater. Generiere Handlungsoptionen mit 2-Zug-Gegnerprognose.
 KONTEXT: \(ctx["unternehmen_name"] as? String ?? szenario.titel) (\(ctx["branche"] as? String ?? "--"))
 Sachverhalt: \(ctx["sachverhalt_lang"] as? String ?? ctx["beschreibung"] as? String ?? "--")
 Gegner: \(ctx["gegner_name"] as? String ?? "--") (\(ctx["gegner_rolle"] as? String ?? "--"))
 TOP-RISIKEN: \((sit["kritische_punkte"] as? [String] ?? []).joined(separator: " | "))
 EXPOSURE: \(sit["gesamt_exposure_eur"] as? Double ?? 0)€

 Generiere 5-7 differenzierte Szenarien mit: bezeichnung, handlungstyp, erfolg_pct, zeithorizont, auswirkungsgrad,
 konsequenzen, finanzielle_folge_eur, gegner_reaktion, gegen_gegen_reaktion, strategos_empfehlung, strategos_quelle, rechtliche_grundlage, kosten.
 TRANSPARENZ: Erkläre die Grundlage deiner Wahrscheinlichkeitsschätzungen.
 """
 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "szenarien": [
           "type": "array",
           "items": [
             "type": "object",
             "properties": [
               "bezeichnung": ["type": "string"],
               "handlungstyp": ["type": "string"],
               "erfolg_pct": ["type": "number"],
               "zeithorizont": ["type": "string"],
               "auswirkungsgrad": ["type": "string"],
               "gegner_reaktion": ["type": "string"],
               "gegen_gegen_reaktion": ["type": "string"],
               "strategos_empfehlung": ["type": "string"],
               "strategos_quelle": ["type": "string"],
               "finanzielle_folge_eur": ["type": "number"]
             ] as [String: Any]
           ] as [String: Any]
         ] as [String: Any]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6"
   )
   await MainActor.run {
     matrixDaten = result
     szenario.szenario_matrix = result
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct StrategosSchritt4: View {
@Binding var szenario: StrategosScenario
@State private var aktionsplanDaten: AnyCodable?
@State private var kiLaeuft = false
@State private var fehler: String?

var body: some View {
 VStack(spacing: 20) {
   StrategosSchrittHeader(
     nummer: 4,
     titel: "Aktionsplan",
     beschreibung: "Konkrete Handlungsoptionen mit Priorisierung und Umsetzungsplan."
   )

   Button {
     Task { await planErstellen() }
   } label: {
     if kiLaeuft { ProgressView().scaleEffect(0.8) }
     else { Label("Aktionsplan entwickeln", systemImage: "bolt.fill") }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(kiLaeuft)

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   if let dict = aktionsplanDaten?.dictValue ?? szenario.aktionsplan?.dictValue,
    let massnahmen = dict["massnahmen"] as? [[String: Any]] {
     Text("\(massnahmen.count) Maßnahmen")
       .font(.caption).foregroundStyle(.secondary)
     ForEach(Array(massnahmen.prefix(8).enumerated()), id: \.offset) { _, m in
       HStack(alignment: .top, spacing: 8) {
         Image(systemName: "checkmark.circle")
           .font(.caption)
           .foregroundStyle(.blue)
         VStack(alignment: .leading, spacing: 2) {
           Text(m["titel"] as? String ?? "Maßnahme")
             .font(.system(size: 12, weight: .semibold))
           if let wirkung = m["wirkung"] as? String {
             Text(wirkung).font(.caption).foregroundStyle(.secondary)
           }
           HStack(spacing: 8) {
             if let h = m["horizont"] as? String {
               Text(h).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                 .background(Color.orange.opacity(0.12), in: Capsule())
             }
             if let frist = m["frist"] as? String {
               Text("Frist: \(frist)").font(.caption2).foregroundStyle(.secondary)
             }
           }
         }
       }
       .padding(10)
       .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
     }
   }
 }
 .onAppear { aktionsplanDaten = szenario.aktionsplan }
}

private func planErstellen() async {
 kiLaeuft = true
 fehler = nil
 defer { kiLaeuft = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let mat = szenario.szenario_matrix?.dictValue ?? [:]
 let szenarien = (mat["szenarien"] as? [[String: Any]] ?? []).prefix(3).map { $0["bezeichnung"] as? String ?? "" }.joined(separator: "; ")

 let prompt = """
 Senior-Strategieberater. Konkreter, spezifischer Aktionsplan -- KEINE abstrakten Empfehlungen.
 KONTEXT: \(ctx["unternehmen_name"] as? String ?? szenario.titel) (\(ctx["branche"] as? String ?? "--"))
 SACHVERHALT: \(ctx["sachverhalt_lang"] as? String ?? "--")
 TOP-RISIKEN: \((sit["kritische_punkte"] as? [String] ?? []).joined(separator: " | "))
 SZENARIEN: \(szenarien)
 Erzeuge 10-15 Maßnahmen auf 4 Horizonte (sofort/kurzfristig/mittelfristig/langfristig).
 Pro Maßnahme: titel, rechtsgebiet, verantwortlich, wirkung, risiko_unterlassen, aufwand, kosten_eur, frist, horizont.
 TRANSPARENZ: Begründe jede Priorisierung.
 """
 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "massnahmen": [
           "type": "array",
           "items": [
             "type": "object",
             "properties": [
               "titel": ["type": "string"],
               "rechtsgebiet": ["type": "string"],
               "verantwortlich": ["type": "string"],
               "wirkung": ["type": "string"],
               "risiko_unterlassen": ["type": "string"],
               "aufwand": ["type": "string"],
               "kosten_eur": ["type": "number"],
               "frist": ["type": "string"],
               "horizont": ["type": "string"]
             ] as [String: Any]
           ] as [String: Any]
         ] as [String: Any]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6"
   )
   await MainActor.run {
     aktionsplanDaten = result
     szenario.aktionsplan = result
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct StrategosSchritt5: View {
@Binding var szenario: StrategosScenario
@State private var empfehlungDaten: AnyCodable?
@State private var kiLaeuft = false
@State private var fehler: String?

var body: some View {
 VStack(spacing: 20) {
   StrategosSchrittHeader(
     nummer: 5,
     titel: "Strategos-Empfehlung",
     beschreibung: "Finale strategische Empfehlung nach Harvard-, Sun Tzu- und Machiavelli-Prinzipien."
   )

   Button {
     Task { await empfehlungErstellen() }
   } label: {
     if kiLaeuft { ProgressView().scaleEffect(0.8) }
     else { Label("Finale Empfehlung erstellen", systemImage: "star.fill") }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(kiLaeuft)

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   if let dict = empfehlungDaten?.dictValue ?? szenario.strategos_empfehlung?.dictValue {
     VStack(alignment: .leading, spacing: 12) {
       if let mp = dict["machtposition"] as? String {
         VStack(alignment: .leading, spacing: 4) {
           Text("Machtposition").font(.caption.bold()).foregroundStyle(.purple)
           Text(mp).font(.system(size: 12))
         }
       }
       if let hebel = dict["groesste_hebel"] as? [String], !hebel.isEmpty {
         ListKarte(titel: "Größte Hebel", eintraege: hebel, farbe: .green, symbol: "arrow.up.right")
       }
       if let risiken = dict["groesste_risiken"] as? [String], !risiken.isEmpty {
         ListKarte(titel: "Größte Risiken", eintraege: risiken, farbe: .red, symbol: "exclamationmark.triangle.fill")
       }
       if let haltung = dict["grundhaltung"] as? String {
         Text("Grundhaltung: \(haltung)")
           .font(.caption.bold())
           .padding(.horizontal, 10).padding(.vertical, 6)
           .background(Color.blue.opacity(0.1), in: Capsule())
       }
     }
   }
 }
 .onAppear { empfehlungDaten = szenario.strategos_empfehlung }
}

private func empfehlungErstellen() async {
 kiLaeuft = true
 fehler = nil
 defer { kiLaeuft = false }

 let ctx = szenario.unternehmenskontext?.dictValue ?? [:]
 let sit = szenario.situationsanalyse?.dictValue ?? [:]
 let mat = szenario.szenario_matrix?.dictValue ?? [:]
 let act = szenario.aktionsplan?.dictValue ?? [:]

 let prompt = """
 Du bist Strategos -- der ultimative Großkanzlei-Berater. Erstelle die Gesamtempfehlung.
 UNTERNEHMEN: \(ctx["unternehmen_name"] as? String ?? szenario.titel) (\(ctx["rechtsform"] as? String ?? "--"), \(ctx["branche"] as? String ?? "--"))
 SACHVERHALT: \(ctx["sachverhalt_lang"] as? String ?? "--")
 GEGNER: \(ctx["gegner_name"] as? String ?? "--") (\(ctx["gegner_rolle"] as? String ?? "--"))
 GESAMT-RISIKO: \(sit["gesamt_risiko"] as? Double ?? 0)/10
 TOP-SZENARIEN: \((mat["szenarien"] as? [[String: Any]] ?? []).prefix(3).map { "\($0["bezeichnung"] as? String ?? "") (\(Int($0["erfolg_pct"] as? Double ?? 0))%)" }.joined(separator: "; "))
 AKTIONSPLAN: \((act["massnahmen"] as? [[String: Any]] ?? []).count) Maßnahmen

 Liefere: machtposition, groesste_hebel, groesste_risiken, grundhaltung, sun_tzu, machiavelli, harvard, horizont_1/2/3, risiko_chancen_karte.
 TRANSPARENZ: Erkläre welches Prinzip warum angewendet wurde.
 """
 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: [
       "type": "object",
       "properties": [
         "machtposition": ["type": "string"],
         "groesste_hebel": ["type": "array", "items": ["type": "string"]],
         "groesste_risiken": ["type": "array", "items": ["type": "string"]],
         "grundhaltung": ["type": "string"],
         "sun_tzu": [
           "type": "array",
           "items": [
             "type": "object",
             "properties": [
               "prinzip": ["type": "string"],
               "anwendung": ["type": "string"],
               "zitat": ["type": "string"]
             ] as [String: Any]
           ] as [String: Any]
         ],
         "harvard": [
           "type": "object",
           "properties": [
             "interessen": ["type": "string"],
             "beste_alternative_batna": ["type": "string"],
             "zone_moeglicher_einigung": ["type": "string"]
           ] as [String: Any]
         ],
         "horizont_1": [
           "type": "object",
           "properties": [
             "ziel": ["type": "string"],
             "massnahmen": ["type": "array", "items": ["type": "string"]]
           ] as [String: Any]
         ]
       ] as [String: Any]
     ] as [String: Any],
     model: "claude_sonnet_4_6"
   )
   await MainActor.run {
     empfehlungDaten = result
     szenario.strategos_empfehlung = result
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

struct StrategosSchritt6: View {
@Binding var szenario: StrategosScenario

var body: some View {
 VStack(spacing: 20) {
   StrategosSchrittHeader(
     nummer: 6,
     titel: "Sync & Export",
     beschreibung: "Ergebnisse mit Lexara synchronisieren und als PDF/Notion exportieren."
   )

   HStack(spacing: 16) {
     ExportKnopf(
       titel: "PDF exportieren",
       beschreibung: "Vollständiger Strategos-Bericht",
       symbol: "doc.richtext.fill",
       farbe: .red
     ) {
       await pdfExportieren()
     }

     ExportKnopf(
       titel: "Lexara verknüpfen",
       beschreibung: "Mit Fall synchronisieren",
       symbol: "arrow.triangle.2.circlepath",
       farbe: .blue
     ) {
       // Fall-Verknüpfung
     }
   }
 }
}

private func pdfExportieren() async {
 // PDF-Generierung mit PDFKit
 let pdfDocument = PDFDocument()
 // Hier würde der vollständige PDF-Report generiert
 // Das PDFKit-Rendering erfolgt durch Erfassen der Views als Bilder

 if let data = pdfDocument.dataRepresentation() {
   let savePanel = NSSavePanel()
   savePanel.allowedContentTypes = [.pdf]
   savePanel.nameFieldStringValue = "\(szenario.titel)_Strategos.pdf"

   if savePanel.runModal() == .OK, let url = savePanel.url {
     try? data.write(to: url)
   }
 }
}
}

// MARK: - Chancen-Risiko-Quadrant

struct ChancenRisikoQuadrant: View {
var matrixDaten: AnyCodable? = nil
var klauseln: [[String: Any]]? = nil
var kiResult: [String: Any]? = nil

var body: some View {
 if let ki = kiResult, let portfolio = ki["portfolio"] as? [[String: Any]], !portfolio.isEmpty {
   kiPortfolioView(portfolio: portfolio, ki: ki)
 } else if let klauseln, !klauseln.isEmpty {
   klauselnView(klauseln)
 } else if let szenarien = matrixDaten?.dictValue?["szenarien"] as? [[String: Any]], !szenarien.isEmpty {
   szenarienView(szenarien)
 } else {
   fallbackView
 }
}

private var fallbackView: some View {
 LexaraScatterQuadrantView(
   title: "Chancen-Risiko-Quadrant",
   subtitle: "Portfolio-Sicht -- Wahrscheinlichkeit vs. Wirkungstiefe",
   punkte: [
     .init(name: "Hauptstrategie", x: 75, y: 3.0, color: .green),
     .init(name: "Vergleich", x: 55, y: 2.0, color: .blue),
     .init(name: "Vollstreckung", x: 85, y: 6.5, color: .orange),
     .init(name: "Mediation", x: 45, y: 1.5, color: .blue),
   ],
   xLabel: "Chance (%)",
   yLabel: "Risiko (%)",
   yDomain: 0...10,
   yMid: 5,
   topLeftLabel: "TAIL-RISK",
   topRightLabel: "VERMEIDEN",
   bottomLeftLabel: "VERNACHL.",
   bottomRightLabel: "MONITOREN"
 )
}

private func kiPortfolioView(portfolio: [[String: Any]], ki: [String: Any]) -> some View {
 let punkte = portfolio.enumerated().map { i, p in
   LexaraScatterQuadrantView.Pkt(
     name: String((p["klausel_typ"] as? String ?? "#\(i + 1)").prefix(18)),
     x: p["x_wahrscheinlichkeit"] as? Double ?? 50,
     y: p["y_wirkungstiefe"] as? Double ?? 5,
     color: quadrantFarbe(p["quadrant"] as? String)
   )
 }
 return LexaraScatterQuadrantView(
   title: "KI-Portfolio · Analyse",
   subtitle: "KI-generierte Quadranten-Positionierung",
   punkte: punkte,
   fazit: ki["portfolio_fazit"] as? String,
   prioritaet: ki["top_prioritaet"] as? String
 )
}

private func klauselnView(_ klauseln: [[String: Any]]) -> some View {
 let risikoProb: [String: Double] = ["kritisch": 75, "hoch": 55, "mittel": 40, "niedrig": 20, "positiv": 30]
 let risikoScore: [String: Double] = ["kritisch": 8.5, "hoch": 6.5, "mittel": 4.5, "niedrig": 2.5, "positiv": 2.5]
 let risikoColor: [String: Color] = [
   "kritisch": Color(red: 0.72, green: 0.11, blue: 0.23),
   "hoch": .orange, "mittel": .blue, "niedrig": .green, "positiv": .green
 ]

 let punkte = klauseln.enumerated().map { i, k in
   let stufe = k["risiko_stufe"] as? String ?? "mittel"
   let x = (risikoProb[stufe] ?? 40) + Double((i * 7) % 20) - 5
   let y = (risikoScore[stufe] ?? 4.5) + Double((i % 3) - 1) * 0.5
   return LexaraScatterQuadrantView.Pkt(
     name: String((k["klausel_typ"] as? String ?? "#\(i + 1)").prefix(18)),
     x: x,
     y: y,
     color: risikoColor[stufe] ?? .blue
   )
 }

 return LexaraScatterQuadrantView(
   title: "Format 05 · Chancen-Risiken-Quadrant",
   subtitle: "Portfolio-Sicht aller Klauseln -- Wahrscheinlichkeit vs. Wirkungstiefe",
   punkte: punkte
 )
}

private func szenarienView(_ szenarien: [[String: Any]]) -> some View {
 let punkte = szenarien.enumerated().map { i, sz in
   let erfolg = sz["erfolg_pct"] as? Double ?? 50
   let auswirkung = auswirkungsScore(sz["auswirkungsgrad"] as? String)
   return LexaraScatterQuadrantView.Pkt(
     name: String((sz["bezeichnung"] as? String ?? "Szenario \(i + 1)").prefix(18)),
     x: erfolg,
     y: auswirkung,
     color: erfolg >= 50 ? (auswirkung >= 5 ? .orange : .green) : (auswirkung >= 5 ? .red : .blue)
   )
 }
 return LexaraScatterQuadrantView(
   title: "Szenario-Matrix",
   subtitle: "Erfolgswahrscheinlichkeit vs. Auswirkungsgrad",
   punkte: punkte,
   xLabel: "Erfolg (%)",
   yLabel: "Auswirkung ›"
 )
}

private func auswirkungsScore(_ grad: String?) -> Double {
 switch grad?.lowercased() {
 case "kritisch", "sehr hoch": return 8.5
 case "hoch": return 6.5
 case "mittel": return 4.5
 case "niedrig", "gering": return 2.5
 default: return 5.0
 }
}

private func quadrantFarbe(_ quadrant: String?) -> Color {
 switch quadrant {
 case "VERMEIDEN": return Color(red: 0.72, green: 0.11, blue: 0.23)
 case "TAIL-RISK": return .orange
 case "MONITOREN": return .blue
 default: return .green
 }
}
}

// MARK: - Hilfskomponenten

struct StrategosSchrittHeader: View {
let nummer: Int
let titel: String
let beschreibung: String

var body: some View {
 HStack(alignment: .top, spacing: 14) {
   Text("\(nummer)")
     .font(.system(size: 20, weight: .black, design: .rounded))
     .foregroundStyle(.white)
     .frame(width: 40, height: 40)
     .background(.blue, in: Circle())

   VStack(alignment: .leading, spacing: 4) {
     Text(titel)
       .font(.title2.bold())
     Text(beschreibung)
       .font(.subheadline)
       .foregroundStyle(.secondary)
   }
 }
}
}

struct LabeledTextField: View {
let label: String
@Binding var text: String

init(_ label: String, text: Binding<String>) {
 self.label = label
 self._text = text
}

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(label)
     .font(.caption)
     .foregroundStyle(.secondary)
   TextField("", text: $text)
     .textFieldStyle(.plain)
     .padding(8)
     .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
 }
}
}

struct LabeledTextArea: View {
let label: String
@Binding var text: String
var minHeight: CGFloat = 100

init(_ label: String, text: Binding<String>, minHeight: CGFloat = 100) {
 self.label = label
 self._text = text
 self.minHeight = minHeight
}

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(label)
     .font(.caption)
     .foregroundStyle(Premium.textSoft)
   TextEditor(text: $text)
     .font(.system(size: 13))
     .foregroundStyle(Premium.text)
     .scrollContentBackground(.hidden)
     .frame(minHeight: minHeight)
     .padding(6)
     .background(Premium.well, in: RoundedRectangle(cornerRadius: 8))
     .overlay(RoundedRectangle(cornerRadius: 8).stroke(Premium.hairline, lineWidth: 1))
 }
}
}

struct DokumentUploadButton: View {
let modus: StrategosScenario.StrategosModus
var onUploaded: (([[String: Any]]) -> Void)? = nil

@State private var dokumente: [[String: Any]] = []
@State private var laeuft = false
@State private var fehler: String?

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   Button {
     Task { await upload() }
   } label: {
     HStack(spacing: 8) {
       if laeuft { ProgressView().scaleEffect(0.7) }
       else { Image(systemName: "doc.badge.plus") }
       Text(dokumente.isEmpty
         ? (modus == .vertrag ? "Vertrag hochladen (PDF/Text)" : "Dokument hochladen")
         : "\(dokumente.count) Dokument(e) hochgeladen")
         .font(.system(size: 12))
     }
   }
   .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
   .disabled(laeuft)

   if let fehler {
     Text(fehler).font(.caption2).foregroundStyle(.red)
   }

   ForEach(Array(dokumente.enumerated()), id: \.offset) { _, doc in
     HStack {
       Image(systemName: "doc.fill").font(.caption).foregroundStyle(.blue)
       Text(doc["name"] as? String ?? "Dokument").font(.caption)
       Spacer()
       if doc["analyse"] != nil {
         Text("3 KI").font(.caption2).foregroundStyle(.green)
       }
     }
   }
 }
}

private func upload() async {
 let panel = NSOpenPanel()
 panel.allowsMultipleSelection = true
 panel.allowedContentTypes = [.pdf, .plainText, .text]
 guard panel.runModal() == .OK else { return }
 laeuft = true
 fehler = nil
 defer { laeuft = false }
 var neu = dokumente
 for url in panel.urls {
   do {
     let data = try Data(contentsOf: url)
     let mime: String
     switch url.pathExtension.lowercased() {
     case "pdf": mime = "application/pdf"
     case "txt": mime = "text/plain"
     default: mime = "application/octet-stream"
     }
     let fileUrl = try await LLMService.shared.uploadFile(data: data, fileName: url.lastPathComponent, mimeType: mime)
     let schema: [String: Any] = [
       "type": "object",
       "properties": [
         "dokumenttyp": ["type": "string"],
         "zusammenfassung": ["type": "string"]
       ]
     ]
     let analyse = try await LLMService.shared.extractDataFromFile(fileUrl: fileUrl, jsonSchema: schema)
     neu.append([
       "name": url.lastPathComponent,
       "url": fileUrl,
       "type": url.pathExtension.lowercased(),
       "uploaded_at": ISO8601DateFormatter().string(from: Date()),
       "analyse": analyse?.dictValue ?? [:]
     ])
   } catch {
     await MainActor.run { fehler = error.localizedDescription }
   }
 }
 dokumente = neu
 onUploaded?(neu)
}
}

struct ExportKnopf: View {
let titel: String
let beschreibung: String
let symbol: String
let farbe: Color
let aktion: () async -> Void

@State private var laeuft = false

var body: some View {
 Button {
   Task { laeuft = true; await aktion(); laeuft = false }
 } label: {
   HStack(spacing: 12) {
     if laeuft {
       ProgressView().scaleEffect(0.8)
     } else {
       Image(systemName: symbol)
         .font(.system(size: 20))
         .foregroundStyle(farbe)
     }
     VStack(alignment: .leading, spacing: 2) {
       Text(titel)
         .font(.system(size: 13, weight: .semibold))
       Text(beschreibung)
         .font(.caption2)
         .foregroundStyle(.secondary)
     }
     Spacer()
   }
   .padding(14)
   .frame(maxWidth: .infinity)
   .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
   .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.2)))
 }
 .buttonStyle(.plain)
 .disabled(laeuft)
}
}

// MARK: - Neues Szenario Sheet

struct NeuesSzenarioSheet: View {
let onCreated: (StrategosScenario) -> Void
@Environment(\.dismiss) var dismiss
@State private var titel = ""
@State private var modus = StrategosScenario.StrategosModus.fall
@State private var isSaving = false
@State private var speichernFehler: String?

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Label("Neues Strategos-Szenario", systemImage: "shield.lefthalf.filled")
       .font(.title3.bold())
     Spacer()
     Button("Abbrechen") { dismiss() }
   }
   .padding(20)
   Divider()
   Form {
     TextField("Titel *", text: $titel)
     Picker("Modus", selection: $modus) {
       ForEach(StrategosScenario.StrategosModus.allCases, id: \.self) {
         Text($0.rawValue.capitalized).tag($0)
       }
     }
     if let err = speichernFehler {
       Text(err).font(.caption).foregroundStyle(.red)
     }
   }
   .formStyle(.grouped)
   Divider()
   HStack {
     Spacer()
     Button("Erstellen") { Task { await erstellen() } }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
       .disabled(titel.isEmpty || isSaving)
   }
   .padding(16)
 }
 .frame(width: 380, height: 280)
}

private func erstellen() async {
 isSaving = true
 speichernFehler = nil
 var szenario = StrategosScenario(titel: titel)
 szenario.modus = modus
 do {
   let created = try await Services.strategosScenarios.create(szenario)
   await MainActor.run { onCreated(created); dismiss() }
 } catch {
   await MainActor.run { speichernFehler = error.localizedDescription }
 }
 isSaving = false
}
}

// MARK: - Strategos Willkommen

struct StrategosWillkommen: View {
var body: some View {
 VStack(spacing: 20) {
   Image(systemName: "shield.lefthalf.filled")
     .font(.system(size: 60))
     .foregroundStyle(.blue)
   Text("Strategos Enterprise Intelligence")
     .font(.title2.bold())
   Text("Erstellen Sie ein neues Szenario für die 8-Schritt-Enterprise-Analyse:\nDokumenten-Intelligenz · Rechtsgebiete · Vertrag · Patent · Quant · Umsetzung")
     .font(.subheadline)
     .foregroundStyle(.secondary)
     .multilineTextAlignment(.center)
     .frame(maxWidth: 400)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

// HeatmapZelle für Chart-Daten
struct HeatmapZelle: Identifiable {
let id = UUID()
let x: Int
let y: Int
let wert: Double
}

