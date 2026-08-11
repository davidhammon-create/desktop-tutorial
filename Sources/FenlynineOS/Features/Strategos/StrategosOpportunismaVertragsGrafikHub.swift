import SwiftUI

// MARK: - Opportunisma-Grafiken direkt in Strategos Vertragsanalyse

struct StrategosOpportunismaVertragsGrafikHub: View {
let vertrag: [String: Any]
let szenario: StrategosScenario?
var onOpenOpportunismaTab: ((OpportunismaTab) -> Void)?

@State private var vm = OpportunismaViewModel()
@State private var geoeffneteGrafik: OpportunismaTab?
@State private var verletzer = "Eigenes Unternehmen"
@State private var gewaehlteKlausel = ""
@State private var folgeTyp = "Schadenersatz"
@State private var zusaetzlicheFolge = ""

private let verletzerOptionen = ["Eigenes Unternehmen", "Vertragspartner", "Beide Seiten"]
private let folgeOptionen = [
  "Schadenersatz", "Vertragsstrafe", "Kündigung", "Reputationsschaden",
  "Wettbewerbsnachteil", "Steuer-/Ressourcenfolge", "Politik/Lobby", "Compliance-Verstoß"
]

private let grafikTabs: [OpportunismaTab] = [
  .machtStrategie, .uebersicht, .hegemonogramm, .entscheidungsnetz,
  .szenarien, .risiken, .gegneranalyse, .netzwerk, .ressourcen,
  .narrativ, .influence, .zeitplan, .zielpersonen, .dossier
]

var body: some View {
  VStack(alignment: .leading, spacing: 16) {
    kopfzeile
    grafikRaster
    wasWennEditor
    if !vm.kausalitaeten.isEmpty {
      sectionTitel("Kausalitäten", symbol: "arrow.left.arrow.right")
      PragKausalitaetenTabelle(zeilen: vm.kausalitaeten)
        .pragCardStyle()
    }
    if !vm.prognosen.isEmpty {
      sectionTitel("Prognosen & Optionen", symbol: "chart.line.uptrend.xyaxis")
      PragPrognosenTabelle(zeilen: vm.prognosen)
        .pragCardStyle()
    }
    fehlendeFelderHinweis
  }
  .onAppear { ladeDaten() }
  .onChange(of: vertragHash) { _, _ in ladeDaten() }
  .sheet(item: $geoeffneteGrafik) { tab in
    grafikSheet(fuer: tab)
  }
}

private var vertragHash: String {
  String(describing: vertrag.keys.sorted())
}

private var klauselNamen: [String] {
  KIJson.array(in: vertrag, keys: "klauseln").compactMap { $0["klausel_typ"] as? String }
}

private var kopfzeile: some View {
  HStack(spacing: 10) {
    Image(systemName: "chart.xyaxis.line")
      .foregroundStyle(.purple)
    VStack(alignment: .leading, spacing: 2) {
      Text("Opportunisma-Grafiken · Vertragsanalyse")
        .font(.subheadline.bold())
      Text("Alle Diagramme aus Vertragsdaten -- antippen zum Öffnen & Durchklicken")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    Spacer()
    if let r = vertrag["gesamtrisiko"] as? String {
      Text(r)
        .font(.caption2.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.15), in: Capsule())
    }
  }
}

private var grafikRaster: some View {
  LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
    ForEach(grafikTabs) { tab in
      Button {
        geoeffneteGrafik = tab
      } label: {
        VStack(spacing: 8) {
          Image(systemName: tab.symbol)
            .font(.title3)
            .foregroundStyle(.purple)
          Text(tab.titel)
            .font(.system(size: 9, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
          miniVorschau(fuer: tab)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
       .padding(10)
       .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
       .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.2)))
     }
     .buttonStyle(.plain)
     .help("Öffnet \(tab.titel) mit Vertragsdaten")
   }
 }
}

@ViewBuilder
private func miniVorschau(fuer tab: OpportunismaTab) -> some View {
 switch tab {
 case .machtStrategie:
   Text("\(vm.aktivesSzenario.root.children.count) Zweige")
     .font(.caption2)
     .foregroundStyle(.secondary)
 case .risiken:
   Text("Heatmap")
     .font(.caption2)
     .foregroundStyle(.secondary)
 case .szenarien:
   Text("\(vm.szenarien.count) Szenarien")
     .font(.caption2)
     .foregroundStyle(.secondary)
 case .netzwerk, .entscheidungsnetz:
   Text("\(vm.netzKnoten.count) Knoten")
     .font(.caption2)
     .foregroundStyle(.secondary)
 default:
   Text("Öffnen ->")
     .font(.caption2)
     .foregroundStyle(.purple)
 }
}

private var wasWennEditor: some View {
 VStack(alignment: .leading, spacing: 10) {
   sectionTitel("Was-wenn-Szenario", symbol: "questionmark.diamond")
   Text("Was passiert, wenn Sie oder der Vertragspartner eine Klausel nicht einhalten?")
     .font(.caption2)
     .foregroundStyle(.secondary)

   HStack(spacing: 12) {
     VStack(alignment: .leading, spacing: 4) {
       Text("Wer verletzt Pflicht?").font(.caption2.bold())
       Picker("", selection: $verletzer) {
         ForEach(verletzerOptionen, id: \.self) { Text($0).tag($0) }
       }
       .labelsHidden()
     }
     VStack(alignment: .leading, spacing: 4) {
       Text("Klausel").font(.caption2.bold())
       Picker("", selection: $gewaehlteKlausel) {
         if klauselNamen.isEmpty {
           Text("Allgemeine Pflicht").tag("")
         }
         ForEach(klauselNamen, id: \.self) { Text($0).tag($0) }
       }
       .labelsHidden()
     }
     VStack(alignment: .leading, spacing: 4) {
       Text("Folge / Option").font(.caption2.bold())
       Picker("", selection: $folgeTyp) {
         ForEach(folgeOptionen, id: \.self) { Text($0).tag($0) }
       }
       .labelsHidden()
     }
   }

   LabeledTextArea("Zusätzliche Folge für Unternehmen", text: $zusaetzlicheFolge, minHeight: 44)

   HStack(spacing: 10) {
     Button("In Grafiken anwenden") { wendeWasWennAn() }
       .buttonStyle(FenlynineOSGlassProminentButtonStyle())
       .tint(.purple)
       .controlSize(.small)
     Button("Strategie-Baum öffnen") { geoeffneteGrafik = .machtStrategie }
       .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
       .controlSize(.small)
   }
 }
 .padding(12)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
}

@ViewBuilder
private var fehlendeFelderHinweis: some View {
 let prog = KIJson.array(in: vertrag, keys: "opportunisma_prognosen")
 let lobby = KIJson.array(in: vertrag, keys: "politik_lobby")
 if prog.isEmpty || lobby.isEmpty {
   Text("Tipp: Erneute KI-Analyse mit Dokumenten erzeugt mehr Prognosen, Politik/Lobby und Entscheidungszweige.")
     .font(.caption2)
     .foregroundStyle(.tertiary)
 }
}

@ViewBuilder
private func grafikSheet(fuer tab: OpportunismaTab) -> some View {
 @Bindable var bindableVM = vm
 VStack(spacing: 0) {
   HStack {
     Label(tab.titel, systemImage: tab.symbol)
       .font(.headline)
     Spacer()
     Button("In Opportunisma-Reiter") {
       geoeffneteGrafik = nil
       onOpenOpportunismaTab?(tab)
     }
     .controlSize(.small)
     Button("Schließen") { geoeffneteGrafik = nil }
       .keyboardShortcut(.cancelAction)
   }
   .padding()
   .background(Color(nsColor: .windowBackgroundColor))

   ScrollView {
     VStack(spacing: 16) {
       grafikInhalt(tab: tab, vm: bindableVM)
     }
     .padding(16)
   }
 }
 .frame(minWidth: 720, minHeight: 520)
 .opportunismaBackground()
 .onAppear { bindableVM.selectedTab = tab }
}

@ViewBuilder
private func grafikInhalt(tab: OpportunismaTab, vm: OpportunismaViewModel) -> some View {
 switch tab {
 case .machtStrategie: OpportunismaMachtportalView(vm: vm)
 case .uebersicht: OpportunismaDashboardView(vm: vm)
 case .hegemonogramm: OpportunismaHegemonogrammView(vm: vm)
 case .entscheidungsnetz: OpportunismaEntscheidungsnetzView(vm: vm)
 case .szenarien: OpportunismaSzenarienPanel(vm: vm)
 case .risiken: OpportunismaRisikenPanel(vm: vm)
 case .gegneranalyse: OpportunismaGegnerPanel(vm: vm)
 case .netzwerk: OpportunismaNetzwerkPanel(vm: vm)
 case .ressourcen: OpportunismaRessourcenPanel(vm: vm)
 case .narrativ: OpportunismaNarrativPanel(vm: vm)
 case .influence: OpportunismaInfluencePanel(vm: vm)
 case .zeitplan: OpportunismaZeitplanPanel(vm: vm)
 case .zielpersonen: OpportunismaZielpersonenPanel(vm: vm)
 case .dossier: OpportunismaDossierPanel(vm: vm)
 case .fragebogen: OpportunismaFragebogenView(vm: vm)
 case .strategosLink: OpportunismaStrategosLinkView(vm: vm)
 case .briefing, .actionBoard, .chancen, .feed,
     .warRoom, .weeklyBrief, .exportStudio, .journey, .playbooks:
   OpportunismaDashboardView(vm: vm)
 }
}

private func sectionTitel(_ text: String, symbol: String) -> some View {
 Label(text, systemImage: symbol)
   .font(.caption.bold())
   .foregroundStyle(.purple)
}

private func ladeDaten() {
 StrategosOpportunismaVertragsMapper.anwenden(auf: vm, vertrag: vertrag, szenario: szenario)
 if gewaehlteKlausel.isEmpty, let first = klauselNamen.first {
   gewaehlteKlausel = first
 }
}

private func wendeWasWennAn() {
 let klausel = gewaehlteKlausel.isEmpty ? "Vertragliche Pflicht" : gewaehlteKlausel
 let folge = zusaetzlicheFolge.isEmpty ? folgeTyp : "\(folgeTyp): \(zusaetzlicheFolge)"
 StrategosOpportunismaVertragsMapper.fuegeWasWennSzenarioHinzu(
   auf: vm,
   verletzer: verletzer,
   klausel: klausel,
   folge: folge,
   rechtlicheOptionen: rechtlicheOptionen(fuer: folgeTyp),
   unternehmenswirkung: zusaetzlicheFolge.isEmpty ? folgeTyp : zusaetzlicheFolge
 )
 geoeffneteGrafik = .machtStrategie
}

private func rechtlicheOptionen(fuer typ: String) -> [String] {
 switch typ {
 case "Schadenersatz": return ["Schadensersatz klagen", "Verhandeln", "Abfindung", "Schiedsgericht"]
 case "Vertragsstrafe": return ["Vertragsstrafe geltend machen", "Mahnung", "Fristsetzung"]
 case "Kündigung": return ["Ordentliche Kündigung", "Außerordentliche Kündigung", "Nacherfüllung verlangen"]
 case "Reputationsschaden": return ["Kommunikation", "Mediation", "Schadensminderung"]
 case "Wettbewerbsnachteil": return ["Marktreaktion", "Vertragsnachverhandlung", "Alternative Lieferanten"]
 case "Steuer-/Ressourcenfolge": return ["Bußgeld", "Rückstellung", "Compliance-Investition"]
 case "Politik/Lobby": return ["Verbandsarbeit", "Regulatorisches Gespräch", "Transparenz"]
 default: return ["Rechtliche Prüfung", "Verhandlung", "Dokumentation"]
 }
}
}

