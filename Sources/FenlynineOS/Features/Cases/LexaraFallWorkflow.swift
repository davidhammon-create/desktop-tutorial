import SwiftUI

// MARK: - Lexara Workflow-Navigation (6 Phasen statt 11 flacher Tabs)

enum LexaraWorkflowPhase: Int, CaseIterable, Identifiable {
case uebersicht = 0
case erfassung = 1
case substanz = 2
case analyse = 3
case strategie = 4
case abschluss = 5

var id: Int { rawValue }

var bezeichnung: String {
  switch self {
  case .uebersicht: return "Übersicht"
  case .erfassung: return "Erfassung"
  case .substanz: return "Substanz"
  case .analyse: return "Analyse"
  case .strategie: return "Strategie"
  case .abschluss: return "Abschluss"
  }
}

var symbol: String {
  switch self {
  case .uebersicht: return "square.grid.2x2.fill"
  case .erfassung: return "doc.badge.plus"
  case .substanz: return "link"
  case .analyse: return "scale.3d"
  case .strategie: return "shield.lefthalf.filled"
  case .abschluss: return "checkmark.seal.fill"
  }
}

var kurzbeschreibung: String {
  switch self {
  case .uebersicht: return "Status, nächste Schritte, Schnellzugriff"
  case .erfassung: return "Fallakte, Dokumente, Akteure, Fristen"
  case .substanz: return "Argumente, Beweise, Verkettung"
  case .analyse: return "Gegner, Recht, Compliance"
  case .strategie: return "Prognose, Simulation, Risiko"
  case .abschluss: return "Aktion, Abschluss, Cockpit, KI-Protokoll"
  }
}

var tabs: [CaseTab] {
  switch self {
  case .uebersicht: return []
  case .erfassung: return [.basisdaten, .akteure]
  case .substanz: return [.fallsubstanz]
  case .analyse: return [.gegneranalyse, .rechtlicheAnalyse]
  case .strategie: return [.strategie, .simulation]
  case .abschluss: return [.aktion, .machtEinfluss, .pfadgraf, .abschluss, .cockpit, .kiProtokoll]
  }
}
}

// MARK: - Workflow-Einklapp-Leiste (klassisches Layout)

struct LexaraWorkflowEinklappLeiste: View {
let onOeffnen: () -> Void

var body: some View {
  VStack(spacing: 8) {
    Button(action: onOeffnen) {
      VStack(spacing: 4) {
        Image(systemName: "list.bullet.indent")
          .font(LexaraFiligranTokens.tabIcon)
        Text("Flow")
          .font(.system(size: 8, weight: .bold))
      }
      .foregroundStyle(FenlynineOSTheme.accent)
      .frame(width: LexaraFiligranTokens.workflowEingeklappt - 4)
      .padding(.vertical, 10)
    }
    .buttonStyle(.plain)
    .help("Workflow-Menü einblenden")
    Spacer()
  }
  .frame(width: LexaraFiligranTokens.workflowEingeklappt)
  .background { VisionOSGlasFlaeche.leiste() }
}
}

// MARK: - Seitenmenü (vertikal, visionOS)

struct LexaraSeitenmenue: View {
@Binding var phase: LexaraWorkflowPhase
@Binding var selectedTab: CaseTab
@Binding var eingeklappt: Bool
let viewModel: CaseDetailViewModel

var body: some View {
  Group {
    if eingeklappt {
      eingeklappteLeiste
    } else {
     ausgeklapptesMenue
   }
 }
 .frame(width: eingeklappt ? LexaraFiligranTokens.workflowEingeklappt : LexaraFiligranTokens.workflowBreite)
 .background { VisionOSGlasFlaeche.leiste() }
 .overlay(alignment: .trailing) {
   Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1)
 }
}

private var eingeklappteLeiste: some View {
 VStack(spacing: 8) {
   Button {
     withAnimation(.spring(duration: 0.28)) { eingeklappt = false }
   } label: {
     Image(systemName: "sidebar.right")
       .font(.system(size: 13, weight: .semibold))
       .foregroundStyle(FenlynineOSTheme.accent)
   }
   .buttonStyle(.plain)
   .padding(.top, 12)

   ForEach(LexaraWorkflowPhase.allCases) { p in
     Button {
       phase = p
       if p != .uebersicht, let first = p.tabs.first { selectedTab = first }
     } label: {
       Image(systemName: p.symbol)
         .font(.system(size: 13, weight: phase == p ? .bold : .regular))
         .foregroundStyle(phase == p ? FenlynineOSTheme.accent : FenlynineOSTheme.textSecondary)
         .frame(width: 36, height: 36)
         .background {
           if phase == p {
             VisionOSGlasFlaeche.sidebarZeile(aktiv: true, cornerRadius: 10)
           }
         }
     }
     .buttonStyle(.plain)
     .help(p.bezeichnung)
   }
   Spacer()
 }
 .padding(.horizontal, 8)
}

private var ausgeklapptesMenue: some View {
 VStack(alignment: .leading, spacing: 0) {
   HStack {
     Text("WORKFLOW")
       .font(AppleUIKitTokens.widgetTitle)
       .foregroundStyle(FenlynineOSTheme.accent)
       .tracking(AppleUIKitTokens.widgetTitleTracking)
     Spacer()
     Button {
       withAnimation(.spring(duration: 0.28)) { eingeklappt = true }
     } label: {
       Image(systemName: "sidebar.left")
         .font(.system(size: 11, weight: .semibold))
         .foregroundStyle(FenlynineOSTheme.textTertiary)
     }
     .buttonStyle(.plain)
   }
   .padding(.horizontal, 14)
   .padding(.vertical, 12)

   ScrollView {
     VStack(spacing: 4) {
       ForEach(LexaraWorkflowPhase.allCases) { p in
         LexaraSeitenmenuePhaseZeile(
           phase: p,
           isSelected: phase == p,
           fortschritt: LexaraPhasenFortschritt.berechne(phase: p, viewModel: viewModel),
           badge: badge(fuer: p)
         ) {
           phase = p
           if p != .uebersicht, let first = p.tabs.first { selectedTab = first }
         }

         if phase == p && p != .uebersicht {
           ForEach(p.tabs) { tab in
             LexaraSeitenmenueTabZeile(
               tab: tab,
               isSelected: selectedTab == tab
             ) {
               selectedTab = tab
             }
           }
           .padding(.leading, 12)
         }
       }
     }
     .padding(.horizontal, 8)
     .padding(.bottom, 16)
   }
 }
}

private func badge(fuer p: LexaraWorkflowPhase) -> Int? {
 switch p {
 case .analyse:
   let n = viewModel.warnungen.filter { $0.severity == .kritisch && !$0.resolved }.count
   return n > 0 ? n : nil
 case .abschluss:
   let n = viewModel.aufgaben.filter { $0.status == .offen }.count
   return n > 0 ? n : nil
 default: return nil
 }
}
}

struct LexaraSeitenmenuePhaseZeile: View {
let phase: LexaraWorkflowPhase
let isSelected: Bool
let fortschritt: LexaraPhasenStatus
let badge: Int?
let action: () -> Void

var body: some View {
 Button(action: action) {
   HStack(spacing: 10) {
     Image(systemName: phase.symbol)
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(isSelected ? FenlynineOSTheme.accent : FenlynineOSTheme.textSecondary)
       .frame(width: 28)
     VStack(alignment: .leading, spacing: 2) {
       HStack(spacing: 4) {
         Text(phase.bezeichnung)
           .font(.system(size: 11, weight: isSelected ? .bold : .medium))
         if let badge, badge > 0 {
           Text("\(badge)")
             .font(.system(size: 8, weight: .bold))
             .foregroundStyle(.white)
             .padding(.horizontal, 4)
             .padding(.vertical, 1)
             .background(.red, in: Capsule())
         }
       }
       Text(phase.kurzbeschreibung)
         .font(.system(size: 8))
         .foregroundStyle(FenlynineOSTheme.textTertiary)
         .lineLimit(1)
     }
     Spacer()
     Circle()
       .fill(fortschritt.farbe)
       .frame(width: 6, height: 6)
   }
   .foregroundStyle(isSelected ? FenlynineOSTheme.textPrimary : FenlynineOSTheme.textSecondary)
   .padding(.horizontal, 10)
   .padding(.vertical, 8)
   .background {
     if isSelected {
       VisionOSGlasFlaeche.sidebarZeile(aktiv: true, cornerRadius: 10)
     }
   }
 }
 .buttonStyle(.plain)
}
}

struct LexaraSeitenmenueTabZeile: View {
let tab: CaseTab
let isSelected: Bool
let action: () -> Void

var body: some View {
 Button(action: action) {
   HStack(spacing: 8) {
     Image(systemName: tab.symbol)
       .font(.system(size: 10))
       .frame(width: 20)
     Text(tab.bezeichnung)
       .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
     Spacer()
   }
   .foregroundStyle(isSelected ? FenlynineOSTheme.accent : FenlynineOSTheme.textTertiary)
   .padding(.horizontal, 10)
   .padding(.vertical, 6)
   .background(
     isSelected ? FenlynineOSTheme.accent.opacity(0.1) : Color.clear,
     in: RoundedRectangle(cornerRadius: 8, style: .continuous)
   )
 }
 .buttonStyle(.plain)
}
}

// MARK: - Workflow-Navigator (Legacy horizontal -- nicht mehr in CaseDetailView)

struct LexaraWorkflowNavigator: View {
@Binding var phase: LexaraWorkflowPhase
@Binding var selectedTab: CaseTab
let viewModel: CaseDetailViewModel

var body: some View {
 VStack(spacing: 0) {
   LexaraWorkflowStepper(phase: $phase, viewModel: viewModel, onPhaseSelect: { p in
     phase = p
     if p != .uebersicht, let first = p.tabs.first {
       selectedTab = first
     }
   })

   if phase != .uebersicht {
     Divider()
     LexaraSubTabLeiste(phase: phase, selectedTab: $selectedTab, viewModel: viewModel)
       .padding(.horizontal, 20)
       .padding(.vertical, 6)
   }
 }
}
}

struct LexaraWorkflowStepper: View {
@Binding var phase: LexaraWorkflowPhase
let viewModel: CaseDetailViewModel
let onPhaseSelect: (LexaraWorkflowPhase) -> Void

var body: some View {
 ScrollView(.horizontal, showsIndicators: false) {
   HStack(spacing: 0) {
     ForEach(Array(LexaraWorkflowPhase.allCases.enumerated()), id: \.element.id) { index, p in
       if index > 0 {
         Image(systemName: "chevron.right")
           .font(.system(size: 9, weight: .bold))
           .foregroundStyle(.tertiary)
           .padding(.horizontal, 4)
       }
       LexaraPhaseButton(
         phase: p,
         isSelected: phase == p,
         fortschritt: fortschritt(fuer: p),
         badge: badge(fuer: p)
       ) {
         onPhaseSelect(p)
       }
     }
   }
   .padding(.horizontal, 20)
   .padding(.vertical, 10)
 }
}

private func fortschritt(fuer p: LexaraWorkflowPhase) -> LexaraPhasenStatus {
 LexaraPhasenFortschritt.berechne(phase: p, viewModel: viewModel)
}

private func badge(fuer p: LexaraWorkflowPhase) -> Int? {
 switch p {
 case .analyse:
   let n = viewModel.warnungen.filter { $0.severity == .kritisch && !$0.resolved }.count
   return n > 0 ? n : nil
 case .abschluss:
   let n = viewModel.aufgaben.filter { $0.status == .offen }.count
   return n > 0 ? n : nil
 default: return nil
 }
}
}

enum LexaraPhasenStatus {
case leer, teilweise, fertig

var farbe: Color {
 switch self {
 case .leer: return .secondary.opacity(0.3)
 case .teilweise: return .orange
 case .fertig: return .green
 }
}

var symbol: String? {
 switch self {
 case .fertig: return "checkmark"
 case .teilweise: return nil
 case .leer: return nil
 }
}
}

enum LexaraPhasenFortschritt {
static func berechne(phase: LexaraWorkflowPhase, viewModel: CaseDetailViewModel) -> LexaraPhasenStatus {
 switch phase {
 case .uebersicht:
   return .teilweise
 case .erfassung:
   let hatBasis = viewModel.fall?.zentrale_rechtsfrage?.isEmpty == false
   let hatAkteure = !viewModel.personen.isEmpty
   if hatBasis && hatAkteure { return .fertig }
   if hatBasis || hatAkteure || !viewModel.dokumente.isEmpty { return .teilweise }
   return .leer
 case .substanz:
   let args = viewModel.argumente.count
   let bew = viewModel.beweise.count
   if args >= 2 && bew >= 1 { return .fertig }
   if args > 0 || bew > 0 { return .teilweise }
   return .leer
 case .analyse:
   if viewModel.kiFallanalyse != nil || viewModel.vollanalyse != nil { return .fertig }
   if !viewModel.warnungen.isEmpty { return .teilweise }
   return .leer
 case .strategie:
   if viewModel.vollanalyse != nil { return .fertig }
   if viewModel.fall?.prognose != nil { return .teilweise }
   return .leer
 case .abschluss:
   if viewModel.fall?.status == .abgeschlossen { return .fertig }
   if !viewModel.aufgaben.isEmpty { return .teilweise }
   return .leer
 }
}
}

struct LexaraPhaseButton: View {
let phase: LexaraWorkflowPhase
let isSelected: Bool
let fortschritt: LexaraPhasenStatus
let badge: Int?
let action: () -> Void

var body: some View {
 Button(action: action) {
   HStack(spacing: 8) {
     ZStack {
       Circle()
         .fill(fortschritt.farbe.opacity(isSelected ? 0.25 : 0.12))
         .frame(width: 28, height: 28)
       if let sym = fortschritt.symbol {
         Image(systemName: sym)
           .font(.system(size: 10, weight: .bold))
           .foregroundStyle(.green)
       } else {
         Image(systemName: phase.symbol)
           .font(.system(size: 11))
           .foregroundStyle(isSelected ? FenlynineOSTheme.accent : FenlynineOSTheme.textSecondary)
       }
     }
     VStack(alignment: .leading, spacing: 1) {
       HStack(spacing: 4) {
         Text(phase.bezeichnung)
           .font(.system(size: 12, weight: isSelected ? .bold : .medium))
         if let badge, badge > 0 {
           Text("\(badge)")
             .font(.system(size: 8, weight: .bold))
             .foregroundStyle(.white)
             .padding(.horizontal, 4)
             .padding(.vertical, 1)
             .background(.red, in: Capsule())
         }
       }
       Text(phase.kurzbeschreibung)
         .font(.system(size: 9))
         .foregroundStyle(.tertiary)
         .lineLimit(1)
     }
   }
   .foregroundStyle(isSelected ? FenlynineOSTheme.accent : FenlynineOSTheme.textPrimary)
   .padding(.horizontal, 12)
   .padding(.vertical, 8)
   .background(isSelected ? FenlynineOSTheme.accent.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
 }
 .buttonStyle(.plain)
}
}

struct LexaraSubTabLeiste: View {
let phase: LexaraWorkflowPhase
@Binding var selectedTab: CaseTab
let viewModel: CaseDetailViewModel

var body: some View {
 HStack(spacing: 4) {
   ForEach(phase.tabs) { tab in
     CaseTabButton(
       tab: tab,
       isSelected: selectedTab == tab,
       badge: badgeCount(for: tab)
     ) {
       withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
     }
   }
   Spacer()
 }
}

private func badgeCount(for tab: CaseTab) -> Int? {
 switch tab {
 case .rechtlicheAnalyse:
   let n = viewModel.warnungen.filter { $0.severity == .kritisch && !$0.resolved }.count
   return n > 0 ? n : nil
 case .aktion:
   let n = viewModel.aufgaben.filter { $0.status == .offen }.count
   return n > 0 ? n : nil
 default: return nil
 }
}
}

// MARK: - Fall-Übersicht (Startpunkt)

struct LexaraFallUebersichtView: View {
let viewModel: CaseDetailViewModel
let kiMode: Bool
var onNavigate: (LexaraWorkflowPhase, CaseTab) -> Void

var body: some View {
 VStack(alignment: .leading, spacing: 20) {
   Text("Fall-Übersicht")
     .font(.title2.bold())

   Text("Arbeiten Sie phasenweise -- jeder Bereich zeigt den Fortschritt und führt Sie direkt dorthin.")
     .font(.subheadline)
     .foregroundStyle(.secondary)

   LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
     ForEach(LexaraWorkflowPhase.allCases.filter { $0 != .uebersicht }) { phase in
       LexaraPhasenKarte(
         phase: phase,
         status: LexaraPhasenFortschritt.berechne(phase: phase, viewModel: viewModel),
         viewModel: viewModel
       ) {
         if let tab = phase.tabs.first {
           onNavigate(phase, tab)
         }
       }
     }
   }

   Divider()

   HStack(spacing: 16) {
     schnellKachel("Argumente", wert: "\(viewModel.argumente.count)", symbol: "text.quote", farbe: .indigo) {
       onNavigate(.substanz, .fallsubstanz)
     }
     schnellKachel("Beweise", wert: "\(viewModel.beweise.count)", symbol: "doc.badge.gearshape", farbe: .teal) {
       onNavigate(.substanz, .fallsubstanz)
     }
     schnellKachel("Fristen", wert: "\(viewModel.fristen.count)", symbol: "calendar", farbe: .orange) {
       onNavigate(.erfassung, .akteure)
     }
     schnellKachel("Aufgaben", wert: "\(viewModel.aufgaben.filter { $0.status == .offen }.count)", symbol: "checklist", farbe: .blue) {
       onNavigate(.abschluss, .aktion)
     }
   }

   if kiMode {
     naechsterSchrittHinweis
   }
 }
}

private func schnellKachel(_ titel: String, wert: String, symbol: String, farbe: Color, action: @escaping () -> Void) -> some View {
 Button(action: action) {
   FenlynineOSCard {
     HStack(spacing: 12) {
       Image(systemName: symbol)
         .font(.title2)
         .foregroundStyle(farbe)
       VStack(alignment: .leading) {
         Text(wert).font(.title2.bold())
         Text(titel).font(.caption).foregroundStyle(.secondary)
       }
       Spacer()
       Image(systemName: "chevron.right")
         .foregroundStyle(.tertiary)
     }
   }
 }
 .buttonStyle(.plain)
}

private var naechsterSchrittHinweis: some View {
 FenlynineOSCard(elevated: true) {
   HStack(spacing: 12) {
     Image(systemName: "lightbulb.fill")
       .foregroundStyle(FenlynineOSTheme.accent)
     VStack(alignment: .leading, spacing: 4) {
       Text("Nächster sinnvoller Schritt")
         .font(.caption.bold())
         .foregroundStyle(FenlynineOSTheme.accent)
       Text(empfohlenerSchritt)
         .font(.subheadline)
     }
     Spacer()
   }
 }
}

private var empfohlenerSchritt: String {
 if viewModel.argumente.isEmpty {
   return "Substanz aufbauen: Argumente und Beweise erfassen und verknüpfen."
 }
 if viewModel.beweise.isEmpty {
   return "Beweise hinzufügen und mit Argumenten verknüpfen -- KI-Zuordnung nutzen."
 }
 if viewModel.kiFallanalyse == nil {
   return "KI-Analyse starten (Toolbar) für Prognose und strategische Einschätzung."
 }
 if viewModel.aufgaben.filter({ $0.status == .offen }).isEmpty {
   return "Aktionsplan erstellen und Aufgaben zuweisen."
 }
 return "Simulation und Strategie prüfen, dann Abschluss vorbereiten."
}
}

struct LexaraPhasenKarte: View {
let phase: LexaraWorkflowPhase
let status: LexaraPhasenStatus
let viewModel: CaseDetailViewModel
let action: () -> Void

var body: some View {
 Button(action: action) {
   FenlynineOSCard {
     VStack(alignment: .leading, spacing: 10) {
       HStack {
         Image(systemName: phase.symbol)
           .foregroundStyle(FenlynineOSTheme.accent)
         Text(phase.bezeichnung)
           .font(.headline)
         Spacer()
         statusBadge
       }
       Text(phase.kurzbeschreibung)
         .font(.caption)
         .foregroundStyle(.secondary)
         .lineLimit(2)
       HStack(spacing: 6) {
         ForEach(phase.tabs, id: \.id) { tab in
           Text(tab.bezeichnung)
             .font(.system(size: 9))
             .padding(.horizontal, 6)
             .padding(.vertical, 3)
             .background(Color.secondary.opacity(0.08), in: Capsule())
         }
       }
     }
     .frame(maxWidth: .infinity, alignment: .leading)
   }
 }
 .buttonStyle(.plain)
}

@ViewBuilder
private var statusBadge: some View {
 switch status {
 case .fertig:
   Label("Bereit", systemImage: "checkmark.circle.fill")
     .font(.caption2)
     .foregroundStyle(.green)
 case .teilweise:
   Label("In Arbeit", systemImage: "circle.lefthalf.filled")
     .font(.caption2)
     .foregroundStyle(.orange)
 case .leer:
   Label("Offen", systemImage: "circle")
     .font(.caption2)
     .foregroundStyle(.secondary)
 }
}
}

/// Hilfsfunktion: CaseTab -> Workflow-Phase
func lexaraPhase(fuer tab: CaseTab) -> LexaraWorkflowPhase {
for phase in LexaraWorkflowPhase.allCases {
 if phase.tabs.contains(tab) { return phase }
}
return .uebersicht
}

