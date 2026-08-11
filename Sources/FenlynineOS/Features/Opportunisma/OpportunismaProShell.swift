import SwiftUI
import AppKit

// MARK: - Opportunisma Pro Shell -- Spatial / visionOS Desk (Standalone)

struct OpportunismaProShell: View {
@Bindable var vm: OpportunismaViewModel
@Environment(\.fenlynineOSFensterModus) private var fensterModus
@State private var phase: OpportunismaPhase = .start
@State private var navFilter = ""
@State private var showCommand = false
@State private var boardKopiert = false
@State private var appear = false

private static let tabsOhneBeschreibung: Set<OpportunismaTab> = [
  .briefing, .journey, .playbooks, .warRoom, .weeklyBrief, .exportStudio,
  .actionBoard, .chancen, .feed, .uebersicht,
  .szenarien, .risiken, .gegneranalyse, .netzwerk, .zeitplan, .zielpersonen, .dossier,
  .hegemonogramm, .machtStrategie, .entscheidungsnetz, .ressourcen, .narrativ, .influence
]

var body: some View {
  ZStack {
    OpportunismaSpatialBackground()

    HStack(spacing: 14) {
      if !fensterModus {
        rail
          .frame(width: 248)
          .opportunismaGlass(elevated: true, corner: OpportunismaPro.radiusWindow)
      }

      VStack(spacing: 0) {
        topBar
        szenarioSwitcher
        if fensterModus { compactPhaseBar }
        workflowLeiste
        kontextLeiste
        if let err = vm.kiFehler {
          banner(err, farbe: OpportunismaPro.danger) { vm.kiFehler = nil }
        }
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            if !Self.tabsOhneBeschreibung.contains(vm.selectedTab) {
              Text(vm.selectedTab.proBeschreibung)
                .font(OpportunismaPro.caption)
                .foregroundStyle(OpportunismaPro.textSoft)
                .padding(.horizontal, 4)
            }
            tabInhalt
          }
          .padding(fensterModus ? 14 : 18)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .opportunismaGlass(elevated: true, corner: OpportunismaPro.radiusWindow)
    }
    .padding(fensterModus ? 8 : 14)
    .opacity(appear ? 1 : 0)
    .offset(y: appear ? 0 : 12)
  }
  .environment(\.opportunismaProMode, true)
  .onAppear {
    withAnimation(.easeOut(duration: 0.45)) { appear = true }
    phase = OpportunismaPhase.phase(fuer: vm.selectedTab)
    if !UserDefaults.standard.bool(forKey: "opportunisma_pro_seen") {
      vm.selectedTab = .journey
      UserDefaults.standard.set(true, forKey: "opportunisma_pro_seen")
      phase = .start
    }
    vm.regeneriereActionBoardAusLage()
  }
  .onChange(of: vm.selectedTab) { _, tab in
    withAnimation(.easeInOut(duration: 0.22)) {
      phase = OpportunismaPhase.phase(fuer: tab)
    }
  }
  .sheet(isPresented: $showCommand) {
    OpportunismaProCommandSheet(vm: vm, isPresented: $showCommand)
      .frame(width: 520, height: 460)
  }
}

// MARK: Rail

private var rail: some View {
  VStack(alignment: .leading, spacing: 0) {
    VStack(alignment: .leading, spacing: 8) {
      Text("Opportunisma")
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(OpportunismaPro.text)
      Text("CI Strategy Desk")
        .font(OpportunismaPro.micro)
        .foregroundStyle(OpportunismaPro.accent)
        .tracking(1.0)
      Text("Intelligence -> Entscheidung -> Ausführung")
        .font(OpportunismaPro.micro)
        .foregroundStyle(OpportunismaPro.textFaint)
        .fixedSize(horizontal: false, vertical: true)
   }
   .padding(18)

   // Pins
   if !vm.pinnedTabIds.isEmpty {
     VStack(alignment: .leading, spacing: 6) {
       Text("GEPINNT")
         .font(OpportunismaPro.micro)
         .foregroundStyle(OpportunismaPro.textFaint)
         .padding(.horizontal, 14)
       ForEach(vm.pinnedTabIds.compactMap { OpportunismaTab(rawValue: $0) }) { tab in
         tabButton(tab, indented: false)
       }
     }
     .padding(.bottom, 8)
   }

   HStack(spacing: 6) {
     Image(systemName: "magnifyingglass")
       .font(.system(size: 11))
       .foregroundStyle(OpportunismaPro.textFaint)
     TextField("Modul finden…", text: $navFilter)
       .textFieldStyle(.plain)
       .font(OpportunismaPro.caption)
       .foregroundStyle(OpportunismaPro.text)
   }
   .padding(.horizontal, 12)
   .padding(.vertical, 9)
   .background {
     Capsule().fill(.thinMaterial)
       .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
   }
   .padding(.horizontal, 12)
   .padding(.bottom, 12)

   ScrollView {
     VStack(alignment: .leading, spacing: 10) {
       if navFilter.trimmingCharacters(in: .whitespaces).isEmpty {
         // Nur aktive Phase ausgeklappt -- übersichtlicher
         ForEach(OpportunismaPhase.allCases) { p in
           phaseBlock(p, expanded: phase == p)
         }
       } else {
         ForEach(gefilterteTabs) { tab in
           tabButton(tab, indented: false)
         }
       }
     }
     .padding(.horizontal, 10)
     .padding(.bottom, 12)
   }

   Spacer(minLength: 0)

   VStack(spacing: 12) {
     OpportunismaProScoreRing(wert: vm.machtIndex, label: "Position")
     Text("\(vm.offenActions) offene Züge · \(phase.titel)")
       .font(OpportunismaPro.micro)
       .foregroundStyle(OpportunismaPro.textFaint)
       .multilineTextAlignment(.center)
   }
   .frame(maxWidth: .infinity)
   .padding(.vertical, 16)
   .background(Color.white.opacity(0.03))
 }
}

private func phaseBlock(_ p: OpportunismaPhase, expanded: Bool = true) -> some View {
 VStack(alignment: .leading, spacing: 5) {
   Button {
     withAnimation(.easeInOut(duration: 0.18)) {
       phase = p
       if let first = p.tabs.first { vm.selectedTab = first }
     }
   } label: {
     HStack(spacing: 8) {
       Image(systemName: p.symbol)
         .font(.system(size: 11, weight: .semibold))
         .foregroundStyle(phase == p ? OpportunismaPro.accent : OpportunismaPro.textFaint)
         .frame(width: 16)
       Text(p.titel.uppercased())
         .font(OpportunismaPro.micro)
         .tracking(0.8)
         .foregroundStyle(phase == p ? OpportunismaPro.accent : OpportunismaPro.textFaint)
       Spacer()
       Image(systemName: expanded ? "chevron.down" : "chevron.right")
         .font(.system(size: 8, weight: .bold))
         .foregroundStyle(OpportunismaPro.textFaint)
     }
     .contentShape(Rectangle())
   }
   .buttonStyle(.plain)
   .padding(.horizontal, 6)

   if expanded {
     ForEach(p.tabs) { tab in
       tabButton(tab, indented: true)
     }
   }
 }
}

// MARK: - Situation/Szenario-Switcher (ohne Modul verlassen)

private var szenarioSwitcher: some View {
 let items: [FenlynineOSEntityItem] = vm.strategosSzenarien.enumerated().compactMap { idx, sz in
   let id = sz.id ?? "sz-\(idx)"
   return FenlynineOSEntityItem(
     id: id,
     titel: sz.titel,
     untertitel: sz.rechtsgebiet,
     gruppe: {
       switch sz.modus {
       case .fall: return "Situationen"
       case .vertrag: return "Verträge"
       case .unternehmen: return "Unternehmen"
       }
     }(),
     symbol: "chart.line.uptrend.xyaxis"
   )
 }
 return Group {
   if !items.isEmpty {
     FenlynineOSEntitySwitcher(
       label: "Szenario",
       symbol: "link",
       items: items,
       selectedId: Binding(
         get: { vm.verknuepftesStrategosId ?? items.first?.id },
         set: { neu in
           vm.verknuepftesStrategosId = neu
           Task { await vm.synchronisiereMitStrategos() }
         }
       ),
       onListe: { vm.selectedTab = .strategosLink },
       listenLabel: "Verknüpfung"
     )
   }
 }
}

/// Klarer 4-Schritt-Workflow statt 8 Phasen auf einmal
private var workflowLeiste: some View {
 let schritte: [(String, String, OpportunismaTab)] = [
   ("1", "Fragebogen", .fragebogen),
   ("2", "Lagebild", .uebersicht),
   ("3", "Strategie", .machtStrategie),
   ("4", "Umsetzen", .zeitplan)
 ]
 return HStack(spacing: 6) {
   Text("Ablauf")
     .font(OpportunismaPro.micro)
     .foregroundStyle(OpportunismaPro.textFaint)
   ForEach(Array(schritte.enumerated()), id: \.offset) { idx, s in
     if idx > 0 {
       Image(systemName: "chevron.right")
         .font(.system(size: 7, weight: .bold))
         .foregroundStyle(OpportunismaPro.textFaint)
     }
     Button {
       vm.selectedTab = s.2
       phase = OpportunismaPhase.phase(fuer: s.2)
     } label: {
       HStack(spacing: 4) {
         Text(s.0)
           .font(.system(size: 9, weight: .bold, design: .rounded))
           .foregroundStyle(vm.selectedTab == s.2 ? .white : OpportunismaPro.accent)
           .frame(width: 16, height: 16)
           .background(Circle().fill(vm.selectedTab == s.2 ? OpportunismaPro.accent : OpportunismaPro.accent.opacity(0.2)))
         Text(s.1)
           .font(.system(size: 10, weight: vm.selectedTab == s.2 ? .semibold : .medium))
           .foregroundStyle(vm.selectedTab == s.2 ? OpportunismaPro.text : OpportunismaPro.textSoft)
       }
       .padding(.horizontal, 8)
       .padding(.vertical, 5)
       .background(
         RoundedRectangle(cornerRadius: 8)
           .fill(vm.selectedTab == s.2 ? OpportunismaPro.accentSoft : Color.clear)
       )
     }
     .buttonStyle(.plain)
   }
   Spacer(minLength: 0)
 }
 .padding(.horizontal, 14)
 .padding(.vertical, 8)
 .background(Color.white.opacity(0.02))
 .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5) }
}

private func tabButton(_ tab: OpportunismaTab, indented: Bool) -> some View {
 let aktiv = vm.selectedTab == tab
 return Button {
   withAnimation(.easeInOut(duration: 0.15)) { vm.selectedTab = tab }
 } label: {
   HStack(spacing: 8) {
     Image(systemName: tab.symbol)
       .font(.system(size: 12, weight: aktiv ? .semibold : .regular))
       .frame(width: 16)
     Text(tab.proTitel)
       .font(.system(size: 12.5, weight: aktiv ? .semibold : .medium))
       .lineLimit(1)
     Spacer(minLength: 0)
     if vm.isPinned(tab) {
       Image(systemName: "pin.fill")
         .font(.system(size: 8))
         .foregroundStyle(OpportunismaPro.accent.opacity(0.8))
     }
   }
   .foregroundStyle(aktiv ? OpportunismaPro.text : OpportunismaPro.textSoft)
   .padding(.horizontal, 10)
   .padding(.vertical, 8)
   .padding(.leading, indented ? 10 : 0)
   .background {
     if aktiv {
       RoundedRectangle(cornerRadius: 10, style: .continuous)
         .fill(OpportunismaPro.accentSoft)
         .overlay(
           RoundedRectangle(cornerRadius: 10, style: .continuous)
             .stroke(OpportunismaPro.accentLine, lineWidth: 1)
         )
     }
   }
   .contentShape(Rectangle())
 }
 .buttonStyle(.plain)
 .contextMenu {
   Button(vm.isPinned(tab) ? "Loslösen" : "Anheften") { vm.togglePin(tab) }
 }
}

// MARK: Top

private var topBar: some View {
 HStack(spacing: 12) {
   VStack(alignment: .leading, spacing: 3) {
     Text(vm.selectedTab.proTitel)
       .font(OpportunismaPro.title)
       .foregroundStyle(OpportunismaPro.text)
     Text(phase.untertitel)
       .font(OpportunismaPro.micro)
       .foregroundStyle(OpportunismaPro.textFaint)
   }
   Spacer()

   if fensterModus {
     OpportunismaProScoreRing(wert: vm.machtIndex, label: "Pos.")
       .scaleEffect(0.7)
       .frame(width: 54, height: 54)
   }

   Button { showCommand = true } label: {
     Label("Gehe zu", systemImage: "command")
   }
   .buttonStyle(OpportunismaProGhostButton())
   .keyboardShortcut("k", modifiers: [.command, .shift])

   Button { vm.togglePin(vm.selectedTab) } label: {
     Image(systemName: vm.isPinned(vm.selectedTab) ? "pin.fill" : "pin")
   }
   .buttonStyle(OpportunismaProGhostButton())
   .help("Modul anheften")

   Button {
     Task { await OpportunismaService.analysiereLage(vm: vm) }
   } label: {
     if vm.kiLaeuft { ProgressView().controlSize(.small) }
     else { Label("KI-Analyse", systemImage: "wand.and.stars") }
   }
   .buttonStyle(OpportunismaProPrimaryButton())
   .disabled(vm.kiLaeuft || !vm.kiBereit)

   Button { kopiereBoardPack() } label: {
     Label(boardKopiert ? "Kopiert" : "Board Pack", systemImage: boardKopiert ? "checkmark" : "doc.on.clipboard")
   }
   .buttonStyle(OpportunismaProGhostButton())
 }
 .padding(.horizontal, 18)
 .padding(.vertical, 14)
 .background(Color.white.opacity(0.03))
 .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
}

private var compactPhaseBar: some View {
 ScrollView(.horizontal, showsIndicators: false) {
   HStack(spacing: 8) {
     ForEach(OpportunismaPhase.allCases) { p in
       OpportunismaProChip(titel: p.titel, aktiv: phase == p) {
         phase = p
         if let t = p.tabs.first { vm.selectedTab = t }
       }
     }
     Divider().frame(height: 18).overlay(Color.white.opacity(0.2))
     ForEach(phase.tabs) { tab in
       OpportunismaProChip(titel: tab.proTitel, aktiv: vm.selectedTab == tab) {
         vm.selectedTab = tab
       }
     }
   }
   .padding(.horizontal, 14)
   .padding(.vertical, 10)
 }
 .background(Color.white.opacity(0.02))
}

private var kontextLeiste: some View {
 HStack(spacing: 10) {
   Image(systemName: "text.alignleft")
     .foregroundStyle(OpportunismaPro.accent)
   TextField("Ausgangslage…", text: $vm.situationText, axis: .vertical)
     .lineLimit(1...2)
     .textFieldStyle(.plain)
     .font(OpportunismaPro.caption)
     .foregroundStyle(OpportunismaPro.text)
   Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 22)
   Image(systemName: "flag.fill")
     .foregroundStyle(OpportunismaPro.signal)
   TextField("Ziel…", text: $vm.zielText, axis: .vertical)
     .lineLimit(1...2)
     .textFieldStyle(.plain)
     .font(OpportunismaPro.caption)
     .foregroundStyle(OpportunismaPro.text)
   Button("Übernehmen") { vm.aktualisiereAusgangUndZiel() }
     .buttonStyle(OpportunismaProGhostButton())
 }
 .padding(.horizontal, 16)
 .padding(.vertical, 10)
 .background(Color.white.opacity(0.025))
 .onChange(of: vm.situationText) { _, _ in vm.aktualisiereAusgangUndZiel() }
 .onChange(of: vm.zielText) { _, _ in vm.aktualisiereAusgangUndZiel() }
}

@ViewBuilder
private var tabInhalt: some View {
 switch vm.selectedTab {
 case .journey:
   OpportunismaProJourneyView(vm: vm)
 case .playbooks:
   OpportunismaProPlaybooksView(vm: vm)
 case .briefing:
   OpportunismaProBriefingView(vm: vm)
 case .warRoom:
   OpportunismaProWarRoomView(vm: vm)
 case .weeklyBrief:
   OpportunismaProWeeklyBriefView(vm: vm)
 case .exportStudio:
   OpportunismaProExportStudioView(vm: vm)
 case .actionBoard:
   OpportunismaProActionBoardView(vm: vm)
 case .chancen:
   OpportunismaProChancenView(vm: vm)
 case .feed:
   OpportunismaProFeedView(vm: vm)
 case .fragebogen:
   OpportunismaProFragebogenHub(vm: vm)
 case .strategosLink:
   OpportunismaProStrategosHub(vm: vm)
 case .uebersicht:
   OpportunismaProCommandDashboard(vm: vm)
 case .hegemonogramm:
   OpportunismaProHegemonogrammView(vm: vm)
 case .machtStrategie:
   OpportunismaProStrategieView(vm: vm)
 case .entscheidungsnetz:
   OpportunismaProEntscheidungView(vm: vm)
 case .szenarien:
   OpportunismaProSzenarienView(vm: vm)
 case .risiken:
   OpportunismaProRisikenView(vm: vm)
 case .gegneranalyse:
   OpportunismaProWettbewerbView(vm: vm)
 case .netzwerk:
   OpportunismaProStakeholderView(vm: vm)
 case .ressourcen:
   OpportunismaProRessourcenView(vm: vm)
 case .narrativ:
   OpportunismaProNarrativView(vm: vm)
 case .influence:
   OpportunismaProInfluenceView(vm: vm)
 case .zeitplan:
   OpportunismaProUmsetzungsplanView(vm: vm)
 case .zielpersonen:
   OpportunismaProAkteureView(vm: vm)
 case .dossier:
   OpportunismaProDossierView(vm: vm)
 }
}

private var gefilterteTabs: [OpportunismaTab] {
 let q = navFilter.trimmingCharacters(in: .whitespaces).lowercased()
 guard !q.isEmpty else { return OpportunismaTab.allCases }
 return OpportunismaTab.allCases.filter {
   $0.proTitel.lowercased().contains(q)
     || $0.proBeschreibung.lowercased().contains(q)
     || $0.titel.lowercased().contains(q)
 }
}

private func banner(_ text: String, farbe: Color, dismiss: @escaping () -> Void) -> some View {
 HStack(spacing: 8) {
   Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(farbe)
   Text(text).font(OpportunismaPro.caption).foregroundStyle(farbe)
   Spacer()
   Button("Schließen", action: dismiss)
     .font(OpportunismaPro.micro.weight(.bold))
     .buttonStyle(.plain)
     .foregroundStyle(OpportunismaPro.textSoft)
 }
 .padding(.horizontal, 16)
 .padding(.vertical, 10)
 .background(farbe.opacity(0.14))
}

private func kopiereBoardPack() {
 let md = vm.exportMarkdown(fuer: .board)
 NSPasteboard.general.clearContents()
 NSPasteboard.general.setString(md, forType: .string)
 boardKopiert = true
 DispatchQueue.main.asyncAfter(deadline: .now() + 2) { boardKopiert = false }
}
}

struct OpportunismaProPanelChrome<Content: View>: View {
@ViewBuilder var content: () -> Content

var body: some View {
 content()
   .padding(16)
   .frame(maxWidth: .infinity, alignment: .leading)
   .opportunismaGlass(elevated: true)
}
}

struct OpportunismaProCommandSheet: View {
@Bindable var vm: OpportunismaViewModel
@Binding var isPresented: Bool
@State private var query = ""
@State private var status = ""

var body: some View {
 ZStack {
   OpportunismaSpatialBackground()
   VStack(alignment: .leading, spacing: 14) {
     Text("Command Console")
       .font(OpportunismaPro.title)
       .foregroundStyle(OpportunismaPro.text)
     TextField("Suche Modul oder Befehl…", text: $query)
       .textFieldStyle(.roundedBorder)

     OpportunismaProSection(titel: "Ops", untertitel: "Schnelle Aktionen") {
       HStack(spacing: 8) {
         Button("KI-Analyse") {
           Task { await OpportunismaService.analysiereLage(vm: vm) }
           status = "KI-Analyse gestartet"
         }
         .buttonStyle(OpportunismaProGhostButton())
         Button("Actions regenerieren") {
           vm.regeneriereActionBoardAusLage()
           status = "Action Board aktualisiert"
         }
         .buttonStyle(OpportunismaProGhostButton())
         Button("Board Pack") {
           NSPasteboard.general.clearContents()
           NSPasteboard.general.setString(vm.exportMarkdown(fuer: .board), forType: .string)
           status = "Board Pack kopiert"
         }
         .buttonStyle(OpportunismaProGhostButton())
         Button("Weekly") {
           NSPasteboard.general.clearContents()
           NSPasteboard.general.setString(vm.exportMarkdown(fuer: .weekly), forType: .string)
           status = "Weekly Brief kopiert"
         }
         .buttonStyle(OpportunismaProGhostButton())
         Button("War Room") {
           vm.selectedTab = .warRoom
           isPresented = false
         }
         .buttonStyle(OpportunismaProPrimaryButton())
       }
       if !status.isEmpty {
         Text(status).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.signal)
       }
     }

     List {
       ForEach(filtered) { tab in
         Button {
           vm.selectedTab = tab
           isPresented = false
         } label: {
           Label(tab.proTitel, systemImage: tab.symbol)
         }
       }
     }
     .listStyle(.plain)
     .scrollContentBackground(.hidden)
   }
   .padding(18)
   .opportunismaGlass(elevated: true, corner: OpportunismaPro.radiusWindow)
   .padding(16)
 }
}

private var filtered: [OpportunismaTab] {
 let q = query.lowercased()
 if q.isEmpty { return OpportunismaTab.allCases }
 return OpportunismaTab.allCases.filter {
   $0.proTitel.lowercased().contains(q)
     || $0.proBeschreibung.lowercased().contains(q)
 }
}
}

