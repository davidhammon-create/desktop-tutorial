import SwiftUI

// MARK: - Opportunisma Hauptansicht
// Standalone = Pro-Shell (neues Design). Strategos-Einbettung = Legacy (unverändert).

struct OpportunismaView: View {
var initialStrategosId: String? = nil
var eingebettetInStrategos: Bool = false

@State private var vm = OpportunismaViewModel()
@Environment(\.fenlynineOSFensterModus) private var fensterModus

var body: some View {
  Group {
    if eingebettetInStrategos {
      OpportunismaEmbeddedLegacyView(vm: vm, fensterModus: fensterModus)
    } else {
      OpportunismaProShell(vm: vm)
    }
  }
  .onChange(of: initialStrategosId) { _, newId in
    if let newId {
      vm.verknuepftesStrategosId = newId
      Task { await vm.synchronisiereMitStrategos() }
    }
  }
  .task {
    if let id = initialStrategosId {
      vm.verknuepftesStrategosId = id
    }
    await vm.ladeStrategosSzenarien()
    await vm.synchronisiereMitStrategos()
    if vm.modulQuellen.isEmpty {
      vm.modulQuellen = OpportunismaFragebogenBank.moduleFuerAntworten(
        vm.fragebogenAntworten,
        szenario: vm.verknuepftesStrategos
      )
    }
    vm.clampFragebogenSchritt()
  }
  .onAppear {
    if let tabRaw = UserDefaults.standard.string(forKey: "opportunisma_initial_tab"),
     let tab = OpportunismaTab(rawValue: tabRaw) {
      // Strategos-Deep-Link: Briefing nur in Pro, Legacy ohne briefing
      if eingebettetInStrategos && tab == .briefing {
        vm.selectedTab = .uebersicht
      } else {
        vm.selectedTab = tab
      }
      UserDefaults.standard.removeObject(forKey: "opportunisma_initial_tab")
    } else if !eingebettetInStrategos && !UserDefaults.standard.bool(forKey: "opportunisma_pro_seen") {
      vm.selectedTab = .journey
    }
  }
}
}

// MARK: - Legacy Embedded (Strategos-Reiter -- optisch/strukturell unverändert)

struct OpportunismaEmbeddedLegacyView: View {
@Bindable var vm: OpportunismaViewModel
var fensterModus: Bool

var body: some View {
  HStack(spacing: 0) {
    if !fensterModus {
      OpportunismaSidebar(selected: $vm.selectedTab, machtIndex: vm.machtIndex)
    }
    VStack(spacing: 0) {
      if fensterModus {
        opportunismaFensterTabLeiste(selected: $vm.selectedTab, machtIndex: vm.machtIndex)
      }
      OpportunismaHeader(vm: vm, kompakt: fensterModus)
      if !fensterModus {
        OpportunismaKontextLeiste(vm: vm)
      }
      if let err = vm.kiFehler {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(OpportunismaTheme.red)
          Text(err)
            .font(.system(size: 10))
            .foregroundStyle(OpportunismaTheme.red)
          Spacer()
          Button("Schließen") { vm.kiFehler = nil }
            .font(.system(size: 9, weight: .bold))
            .buttonStyle(.plain)
            .foregroundStyle(OpportunismaTheme.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(OpportunismaTheme.red.opacity(0.08))
      }
      if let tipp = vm.kiTipp {
        HStack(spacing: 8) {
          Image(systemName: "lightbulb.fill").foregroundStyle(OpportunismaTheme.red)
          Text(tipp).font(.system(size: 10)).foregroundStyle(OpportunismaTheme.ink)
          Spacer()
          FenlynineOSTransparenzInfoButton(inhalt: .opportunismaKI(
           titel: "Opportunisma KI-Tipp",
           begruendung: vm.kiAnalyse ?? "KI-generierte Handlungsempfehlung",
           ausgabe: tipp
         ))
       }
       .padding(.horizontal, 16)
       .padding(.vertical, 8)
       .background(OpportunismaTheme.red.opacity(0.06))
     }
     ScrollView {
       VStack(spacing: 16) {
         switch vm.selectedTab {
         case .briefing, .actionBoard, .chancen, .feed,
             .warRoom, .weeklyBrief, .exportStudio, .journey, .playbooks:
           OpportunismaDashboardView(vm: vm)
         case .fragebogen: OpportunismaFragebogenView(vm: vm)
         case .strategosLink: OpportunismaStrategosLinkView(vm: vm)
         case .uebersicht: OpportunismaDashboardView(vm: vm)
         case .hegemonogramm: OpportunismaHegemonogrammView(vm: vm)
         case .machtStrategie: OpportunismaMachtportalView(vm: vm)
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
         }
       }
       .padding(16)
     }
     PragFooterMottos()
   }
 }
 .background {
   if fensterModus {
     Premium.void
   } else {
     ZStack {
       FenlynineOSVisionOSBackground()
       Color.black.opacity(0.15)
     }
   }
 }
 .onAppear {
   if vm.selectedTab == .briefing {
     vm.selectedTab = .fragebogen
   }
 }
}

@ViewBuilder
private func opportunismaFensterTabLeiste(selected: Binding<OpportunismaTab>, machtIndex: Int) -> some View {
 HStack(spacing: 8) {
   Picker("Modul", selection: selected) {
     ForEach(OpportunismaTab.legacyCases) { tab in
       Label(tab.titel, systemImage: tab.symbol).tag(tab)
     }
   }
   .labelsHidden()
   .pickerStyle(.menu)
   .frame(maxWidth: 280)

   Spacer(minLength: 0)

   Text("Position \(machtIndex)")
     .font(.system(size: 10, weight: .bold))
     .foregroundStyle(Premium.textSoft)
     .padding(.horizontal, 8)
     .padding(.vertical, 4)
     .background(Premium.well, in: Capsule())
 }
 .padding(.horizontal, 12)
 .padding(.vertical, 8)
 .background(Premium.ink.opacity(0.7))
}
}

// MARK: - Sidebar

struct OpportunismaSidebar: View {
@Binding var selected: OpportunismaTab
let machtIndex: Int

var body: some View {
 VStack(spacing: 0) {
   VStack(alignment: .leading, spacing: 4) {
     Text("lOS FENLYNINEOS")
       .font(.system(size: 11, weight: .black))
       .foregroundStyle(FenlynineOSTheme.accent)
     Text("OPPORTUNISMA")
       .font(.system(size: 8, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.textSecondary)
     Text("Strategos-Erweiterung")
       .font(.system(size: 7, weight: .medium))
       .foregroundStyle(FenlynineOSTheme.accent.opacity(0.8))
   }
   .frame(maxWidth: .infinity, alignment: .leading)
   .padding(14)

   ScrollView {
     VStack(spacing: 4) {
       ForEach(OpportunismaTab.legacyCases) { tab in
         Button {
           withAnimation(.easeInOut(duration: 0.18)) { selected = tab }
         } label: {
           HStack(spacing: 8) {
             Image(systemName: tab.symbol)
               .font(.system(size: 11, weight: selected == tab ? .semibold : .regular))
               .frame(width: 16)
             Text(tab.titel)
               .font(.system(size: 9, weight: selected == tab ? .bold : .medium))
               .lineLimit(2)
               .multilineTextAlignment(.leading)
             Spacer()
           }
           .foregroundStyle(selected == tab ? .white : FenlynineOSTheme.textPrimary)
           .padding(.horizontal, 10)
           .padding(.vertical, 8)
           .background {
             if selected == tab {
               VisionOSGlasFlaeche.button(stil: .primaerBlau)
             } else {
               VisionOSGlasFlaeche.button(stil: .ghost)
             }
           }
         }
         .buttonStyle(.plain)
       }
     }
     .padding(.horizontal, 8)
   }

   VStack(spacing: 8) {
     PragDominanzGauge(wert: machtIndex, label: "POSITION")
     Text("ZIELFORTSCHRITT")
       .font(.system(size: 7, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.textTertiary)
     FenlynineOSVisionOSAccentProgressBar(wert: Double(machtIndex))
       .frame(height: 4)
       .padding(.horizontal, 12)
   }
   .padding(.vertical, 12)
   .visionOSGlass(cornerRadius: 16, elevated: false)
   .padding(.horizontal, 8)
   .padding(.bottom, 8)
 }
 .frame(width: 188)
 .background {
   VisionOSGlasFlaeche.leiste()
 }
 .overlay(Color.white.opacity(0.1).frame(width: 1), alignment: .trailing)
}
}

// MARK: - Header

struct OpportunismaHeader: View {
let vm: OpportunismaViewModel
var kompakt: Bool = false

var body: some View {
 HStack(alignment: .center, spacing: 10) {
   VStack(alignment: .leading, spacing: kompakt ? 2 : 4) {
     Text(kompakt ? "OPPORTUNISMA" : "UNTERNEHMEN. POSITION. ZUKUNFT.")
       .font(.system(size: kompakt ? 13 : 18, weight: .black))
       .foregroundStyle(kompakt ? Premium.text : FenlynineOSTheme.textPrimary)
       .lineLimit(1)
     Text(kompakt ? "Strategos-Erweiterung" : "OPPORTUNISMA -- STRATEGOS-ERWEITERUNG")
       .font(.system(size: kompakt ? 9 : 9, weight: .bold))
       .foregroundStyle(kompakt ? Premium.textSoft : FenlynineOSTheme.accent)
       .lineLimit(1)
   }
   Spacer(minLength: 0)
   HStack(spacing: kompakt ? 8 : 16) {
     if !kompakt {
       Label("SICHERHEITSSTUFE MAXIMAL", systemImage: "lock.fill")
         .font(.system(size: 8, weight: .bold))
         .foregroundStyle(OpportunismaTheme.gray)
     }
     PragKIButton(
       titel: kompakt ? "KI-Analyse" : "KI-UNTERNEHMENSANALYSE",
       laeuft: vm.kiLaeuft
     ) {
       Task { await OpportunismaService.analysiereLage(vm: vm) }
     }
     .disabled(vm.kiLaeuft || !vm.kiBereit)
   }
 }
 .padding(.horizontal, kompakt ? 12 : 16)
 .padding(.vertical, kompakt ? 8 : 12)
 .background {
   if kompakt {
     Premium.ink.opacity(0.7)
   } else {
     Rectangle().fill(.ultraThinMaterial.opacity(0.5))
   }
 }
 .overlay(alignment: .bottom) {
   (kompakt ? Premium.hairline : Color.white.opacity(0.08))
     .frame(height: 1)
 }
}
}

// MARK: - Dashboard (Übersicht)

struct OpportunismaDashboardView: View {
@Bindable var vm: OpportunismaViewModel

var body: some View {
 VStack(spacing: 12) {
   if !vm.fragebogenAbgeschlossen {
     fragebogenHinweis
   } else if !vm.quellen(fuer: .uebersicht).isEmpty {
     PragModulQuellenBadge(quellen: vm.quellen(fuer: .uebersicht))
   }
   sitzungsZeile
   OpportunismaZielPfadDiagramm(
     root: vm.aktivesSzenario.root,
     ausgangText: vm.situationText,
     zielText: vm.zielText
   )
   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
     PragWidgetCard(titel: "Positionsindex", transparenz: .opportunismaWidget(
       titel: "Unternehmens-Positionsindex",
       formel: "S(Politik + Wirtschaft + Wissenschaft + Markt) / n",
       begruendung: "Gewichtete Position des Unternehmens in relevanten Dimensionen.",
       ergebnis: "\(vm.machtIndex)% Position"
     )) {
       HStack {
         PragDominanzGauge(wert: vm.machtIndex, label: "POSITION")
         PragHorizontalBars(items: vm.dimensionen)
       }
     }
     PragWidgetCard(titel: "Strategische Ziele", transparenz: .opportunismaWidget(
       titel: "Strategische Ziele",
       formel: "Fortschritt = erreichte Teilschritte / Gesamtschritte",
       begruendung: "Verfolgung der operativen Ziele zur Lageverbesserung.",
       ergebnis: "\(vm.strategischeZiele.count) aktive Ziele"
     )) {
       PragZieleTabelle(zeilen: vm.strategischeZiele)
     }
     PragWidgetCard(titel: "Kontrollhebel", transparenz: .opportunismaWidget(
       titel: "Kontrollhebel",
       formel: "Hebelstärke = f(Ressourcen, Position, Information)",
       begruendung: "Systemische Einflussfaktoren auf die Lage.",
       ergebnis: "Top: \(vm.hebel.first?.name ?? "--")"
     )) {
       PragHorizontalBars(items: vm.hebel)
     }
   }
   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
     PragWidgetCard(titel: "Stakeholder-Ebenen") {
       PragPyramid(stufen: ["Verbände & Regulatoren", "Forschung & Innovation", "Markt & Wettbewerb", "Öffentlichkeit & Medien", "Unternehmenskern"].reversed())
     }
     PragWidgetCard(titel: "Narrativ-Position", transparenz: .opportunismaWidget(
       titel: "Narrativ-Position",
       formel: "Radar über 7 Informationsdomänen",
       begruendung: "Wahrnehmung des Unternehmens in Politik, Wirtschaft und Wissenschaft.",
       ergebnis: "Recht: \(Int((vm.narrativ.first { $0.label == "Recht" }?.value ?? 0) * 10))%"
     )) {
       PragRadarPanel(data: vm.narrativ)
     }
     PragWidgetCard(titel: "Wettbewerbsanalyse") {
       PragGegnerTabelle(zeilen: vm.gegner)
     }
     PragWidgetCard(titel: "Einflusskanäle") {
       PragHorizontalBars(items: vm.influence)
     }
   }
   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
     PragWidgetCard(titel: "Szenario-Simulation") {
       PragSzenarioTabelle(zeilen: vm.szenarien)
     }
     PragWidgetCard(titel: "Ressourcenkontrolle") {
       LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
         ForEach(vm.ressourcen) { r in
           VStack(spacing: 2) {
             Text("\(r.wert)%").font(.system(size: 14, weight: .black)).foregroundStyle(OpportunismaTheme.red)
             Text(r.name).font(.system(size: 7)).foregroundStyle(OpportunismaTheme.gray).multilineTextAlignment(.center)
           }
           .padding(8)
           .frame(maxWidth: .infinity)
           .pragCardStyle()
         }
       }
     }
     PragWidgetCard(titel: "Stakeholder-Netzwerk") {
       PragNetzwerkGraph(knoten: vm.netzKnoten, kanten: vm.netzKanten)
         .frame(height: 140)
     }
     PragWidgetCard(titel: "Zeitplan & Umsetzung") {
       PragGantt(meilensteine: vm.meilensteine)
     }
   }
   if let analyse = vm.kiAnalyse {
     PragWidgetCard(titel: "KI-Lageanalyse", transparenz: .opportunismaKI(
       titel: "KI-Lageanalyse",
       begruendung: "Vollständige strategische Lagebewertung",
       ausgabe: analyse
     )) {
       Text(analyse).font(.system(size: 11)).foregroundStyle(OpportunismaTheme.gray).lineSpacing(4)
     }
   }
 }
}

private var fragebogenHinweis: some View {
 HStack(spacing: 10) {
   Image(systemName: "list.bullet.clipboard").foregroundStyle(OpportunismaTheme.red)
   VStack(alignment: .leading, spacing: 2) {
     Text("Lagefragebogen ausfüllen")
       .font(.system(size: 10, weight: .bold))
     Text("Für präzise Graphen, Kausalitäten und Prognosen -- Schritt für Schritt durch Opportunisma.")
       .font(.system(size: 9)).foregroundStyle(OpportunismaTheme.gray)
   }
   Spacer()
   Button("Starten") { vm.selectedTab = .fragebogen }
     .font(.system(size: 9, weight: .bold))
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .tint(OpportunismaTheme.red)
 }
 .padding(12)
 .background(OpportunismaTheme.red.opacity(0.08), in: OpportunismaTheme.cardShape)
 .overlay(OpportunismaTheme.cardShape.stroke(OpportunismaTheme.red.opacity(0.35)))
}

private var sitzungsZeile: some View {
 OpportunismaAusgangZielEingabe(vm: vm)
}
}

// MARK: - Sub-Panels (wiederverwendbare Widgets)

struct OpportunismaHegemonogrammView: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .hegemonogramm)
   HStack(alignment: .top, spacing: 16) {
   PragWidgetCard(titel: "Positionsradar -- Ist vs. Soll", transparenz: .opportunismaWidget(
     titel: "Positionsradar",
     formel: "8-Achsen-Radar: Ist (rot) vs. Soll (schwarz gestrichelt)",
     begruendung: "Gap-Analyse der Unternehmensposition in Politik, Wirtschaft und Wissenschaft.",
     ergebnis: "Größte Lücke: \(groessteLuecke())"
   )) {
     PragDualRadarPanel(data: vm.hegemonogramm)
       .frame(height: 280)
   }
   .frame(maxWidth: .infinity)
   PragWidgetCard(titel: "Empfohlene Maßnahmen") {
     VStack(alignment: .leading, spacing: 6) {
       ForEach(["Verbandsarbeit intensivieren", "Forschungsallianz ausbauen", "Regulatorik mitgestalten", "Stakeholder-Roadmap umsetzen"], id: \.self) { m in
         Label(m, systemImage: "checkmark.square").font(.system(size: 10))
       }
     }
   }
   .frame(width: 260)
   }
 }
}
private func groessteLuecke() -> String {
 vm.hegemonogramm.max(by: { ($0.soll - $0.ist) < ($1.soll - $1.ist) })?.label ?? "--"
}
}

struct OpportunismaEntscheidungsnetzView: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .entscheidungsnetz)
   PragWidgetCard(titel: "Entscheidungsnetzwerk -- Unternehmen") {
     PragNetzwerkGraph(knoten: vm.netzKnoten + [
       .init(label: "Politik-Option", typ: "neutral", x: 0.15, y: 0.35),
       .init(label: "Wissenschaft-Option", typ: "verbündet", x: 0.85, y: 0.38),
       .init(label: "Unternehmensziel", typ: "kontrolliert", x: 0.5, y: 0.08)
     ], kanten: vm.netzKanten + [
       .init(von: "UNTERNEHMEN", zu: "Politik-Option"),
       .init(von: "UNTERNEHMEN", zu: "Wissenschaft-Option"),
       .init(von: "Wissenschaft-Option", zu: "Unternehmensziel")
     ])
     .frame(height: 260)
   }
 }
}
}

struct OpportunismaSzenarienPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .szenarien)
   PragWidgetCard(titel: "Szenario-Simulation", transparenz: .opportunismaWidget(titel: "Szenarien", formel: "P(Erfolg) x Kontrolle", begruendung: "Bewertung strategischer Unternehmenspfade.", ergebnis: "Best: \(vm.szenarien.max(by: { $0.wahrscheinlichkeit < $1.wahrscheinlichkeit })?.name ?? "--")")) {
     PragSzenarioTabelle(zeilen: vm.szenarien)
   }
 }
}
}
struct OpportunismaRisikenPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .risiken)
   PragWidgetCard(titel: "Risiko-Matrix", transparenz: .opportunismaWidget(titel: "Risiko-Matrix", formel: "Impact x Wahrscheinlichkeit", begruendung: "Heatmap identifizierter Unternehmensrisiken.", ergebnis: "6 Risikofelder")) {
     PragRisikoHeatmap(matrix: vm.risikoMatrix)
   }
 }
}
}
struct OpportunismaGegnerPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .gegneranalyse)
   PragWidgetCard(titel: "Wettbewerbsanalyse") { PragGegnerTabelle(zeilen: vm.gegner) }
 }
}
}
struct OpportunismaNetzwerkPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .netzwerk)
   PragWidgetCard(titel: "Stakeholder-Netzwerk") { PragNetzwerkGraph(knoten: vm.netzKnoten, kanten: vm.netzKanten).frame(height: 300) }
 }
}
}
struct OpportunismaRessourcenPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .ressourcen)
   PragWidgetCard(titel: "Ressourcen & Kapazitäten") { PragHorizontalBars(items: vm.ressourcen) }
 }
}
}
struct OpportunismaNarrativPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .narrativ)
   PragWidgetCard(titel: "Politik & Narrativ") { PragRadarPanel(data: vm.narrativ).frame(height: 280) }
 }
}
}
struct OpportunismaInfluencePanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .influence)
   PragWidgetCard(titel: "Einflusskanäle") { PragHorizontalBars(items: vm.influence) }
 }
}
}
struct OpportunismaZeitplanPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .zeitplan)
   PragWidgetCard(titel: "Zeitplan & Meilensteine") { PragGantt(meilensteine: vm.meilensteine, gesamtMonate: 10) }
 }
}
}
struct OpportunismaZielpersonenPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   PragModulKopf(vm: vm, tab: .zielpersonen)
   PragWidgetCard(titel: "Institutionelle Akteure") {
     VStack(alignment: .leading, spacing: 8) {
       ForEach(vm.aktivesSzenario.akteure, id: \.self) { a in
         HStack { Circle().fill(OpportunismaTheme.red).frame(width: 6, height: 6); Text(a).font(.system(size: 11)) }
       }
     }
   }
 }
}
}
struct OpportunismaDossierPanel: View {
@Bindable var vm: OpportunismaViewModel
var body: some View {
 VStack(spacing: 12) {
   PragModulKopf(vm: vm, tab: .dossier)
 if !vm.fragebogenAbgeschlossen {
   PragWidgetCard(titel: "Lagefragebogen") {
     Text("Starten Sie den Lagefragebogen, um ein vollständiges strategisches Dossier mit Kausalitäten und Prognosen zu erhalten.")
       .font(.system(size: 10)).foregroundStyle(OpportunismaTheme.gray)
   }
 }
 PragWidgetCard(titel: "Strategisches Dossier") {
   Text(vm.fragebogenZusammenfassung ?? vm.kiAnalyse ?? "Starten Sie den Lagefragebogen oder eine KI-Lageanalyse.")
     .font(.system(size: 11)).foregroundStyle(OpportunismaTheme.gray)
 }
 if !vm.kausalitaeten.isEmpty {
   PragWidgetCard(titel: "Kausalitäten") {
     PragKausalitaetenTabelle(zeilen: vm.kausalitaeten)
   }
 }
 }
}
}

