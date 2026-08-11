import SwiftUI
import AppKit

// MARK: - Opportunisma Pro Analytics Spine v4
// Hegemonogramm · Strategie · Entscheidung · Hebel · Playbooks · Ziele · Fragebogen-Handoff

struct OpportunismaProHegemonogrammView: View {
@Bindable var vm: OpportunismaViewModel

private var gaps: [(label: String, ist: Double, soll: Double, gap: Double)] {
  vm.hegemonogramm
    .map { (label: $0.label, ist: $0.ist, soll: $0.soll, gap: $0.soll - $0.ist) }
    .sorted { $0.gap > $1.gap }
}

var body: some View {
  VStack(alignment: .leading, spacing: 16) {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Positionsradar")
          .font(OpportunismaPro.hero)
          .foregroundStyle(OpportunismaPro.text)
        Text("Ist vs. Soll über Politik, Markt und Wissenschaft -- Gap wird zum Zug.")
          .font(OpportunismaPro.body)
          .foregroundStyle(OpportunismaPro.textSoft)
      }
      Spacer()
      if let top = gaps.first {
        OpportunismaProMetricTile(label: "Größte Lücke", value: top.label, hint: "Gap \(Int(top.gap))", tone: OpportunismaPro.warn)
          .frame(width: 200)
      }
    }

    HStack(alignment: .top, spacing: 14) {
      OpportunismaProSection(titel: "Radar", untertitel: "Ist (gefüllt) · Soll (Ziel)") {
        PragDualRadarPanel(data: vm.hegemonogramm)
          .frame(minHeight: 280)
      }
      .frame(maxWidth: .infinity)

      OpportunismaProSection(titel: "Gap-Ranking", untertitel: "Priorität aus Distanz", accent: OpportunismaPro.warn) {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(Array(gaps.prefix(6).enumerated()), id: \.offset) { _, g in
            VStack(alignment: .leading, spacing: 6) {
              HStack {
                Text(g.label)
                  .font(OpportunismaPro.section)
                  .foregroundStyle(OpportunismaPro.text)
                Spacer()
                Text("\(Int(g.ist))->\(Int(g.soll))")
                  .font(OpportunismaPro.micro)
                  .foregroundStyle(OpportunismaPro.textFaint)
              }
              GeometryReader { geo in
                ZStack(alignment: .leading) {
                  Capsule().fill(Color.white.opacity(0.08))
                  Capsule()
                    .fill(OpportunismaPro.warn.opacity(0.85))
                    .frame(width: geo.size.width * min(1, g.gap / 50))
                }
              }
              .frame(height: 6)
              Button("Als Action") {
                vm.actionItems.insert(
                  .init(titel: "Lücke schließen: \(g.label)", detail: "Ist \(Int(g.ist)) -> Soll \(Int(g.soll))", status: .offen, prio: g.gap >= 20 ? .hoch : .mittel, tab: .hegemonogramm),
                  at: 0
                )
                vm.speichereProSession()
                vm.selectedTab = .actionBoard
              }
              .buttonStyle(OpportunismaProGhostButton())
            }
            .padding(.vertical, 4)
          }
        }
      }
      .frame(width: 300)
    }

    HStack(spacing: 10) {
      Button { vm.selectedTab = .machtStrategie } label: {
        Label("Strategie-Baum", systemImage: "arrow.triangle.branch")
      }
      .buttonStyle(OpportunismaProPrimaryButton())
      Button { vm.selectedTab = .warRoom } label: {
        Label("War Room", systemImage: "shield.lefthalf.filled")
      }
      .buttonStyle(OpportunismaProGhostButton())
    }
  }
}
}

struct OpportunismaProStrategieView: View {
@Bindable var vm: OpportunismaViewModel

private var moves: [PragTreeNode] {
  vm.flacheKnoten.filter { $0.typ == .move }
}

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   HStack(alignment: .bottom) {
     VStack(alignment: .leading, spacing: 6) {
       Text("Strategie-Baum")
         .font(OpportunismaPro.hero)
         .foregroundStyle(OpportunismaPro.text)
       Text("Handlungspfade mit Wirksamkeit und Risiko -- Signaturfläche des CI-Desks.")
         .font(OpportunismaPro.body)
         .foregroundStyle(OpportunismaPro.textSoft)
     }
     Spacer()
     OpportunismaProScoreRing(wert: vm.machtIndex, label: "Lage")
   }

   ScrollView(.horizontal, showsIndicators: false) {
     HStack(spacing: 8) {
       ForEach(Array(vm.szenarienBaum.keys.sorted()), id: \.self) { key in
         OpportunismaProChip(titel: vm.szenarienBaum[key]?.label ?? key, aktiv: vm.szenarioKey == key) {
           vm.szenarioKey = key
         }
       }
     }
   }

   HStack(spacing: 14) {
     OpportunismaProMetricTile(label: "Knoten", value: "\(vm.flacheKnoten.count)")
     OpportunismaProMetricTile(label: "Züge", value: "\(moves.count)", tone: OpportunismaPro.accent)
     OpportunismaProMetricTile(label: "Szenario", value: vm.aktivesSzenario.label, hint: "aktiv")
   }

   OpportunismaProSection(titel: "Zug-Board", untertitel: "Promote -> Action Board", accent: OpportunismaPro.signal) {
     if moves.isEmpty {
       Text("Keine Handlungsknoten -- KI-Pfad oder Fragebogen.")
         .font(OpportunismaPro.caption)
         .foregroundStyle(OpportunismaPro.textFaint)
     } else {
       ForEach(Array(moves.prefix(8))) { node in
         HStack(spacing: 12) {
           VStack(alignment: .leading, spacing: 4) {
             Text(node.label)
               .font(OpportunismaPro.section)
               .foregroundStyle(OpportunismaPro.text)
             Text(node.detail)
               .font(OpportunismaPro.caption)
               .foregroundStyle(OpportunismaPro.textSoft)
               .lineLimit(2)
             if let s = node.scores {
               Text("Wirkung \(s.efficacy) · Risiko \(s.risk) · Schaden \(s.harm)")
                 .font(OpportunismaPro.micro)
                 .foregroundStyle(OpportunismaPro.textFaint)
             }
           }
           Spacer()
           Button("Als Zug") {
             vm.actionItems.insert(
               .init(
                 titel: node.label,
                 detail: node.detail,
                 status: .offen,
                 prio: (node.scores?.risk ?? 50) >= 70 ? .hoch : .mittel,
                 tab: .machtStrategie
               ),
               at: 0
             )
             vm.speichereProSession()
             vm.selectedTab = .actionBoard
           }
           .buttonStyle(OpportunismaProGhostButton())
           Button("Fokus") { vm.selectedNodeId = node.id }
             .buttonStyle(OpportunismaProGhostButton())
         }
         .padding(12)
         .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
       }
     }
   }

   HStack(spacing: 10) {
     Button {
       Task { await OpportunismaService.erweitereStrategiebaum(vm: vm) }
     } label: {
       if vm.kiLaeuft { ProgressView().controlSize(.small) }
       else { Label("KI-Pfad erweitern", systemImage: "wand.and.stars") }
     }
     .buttonStyle(OpportunismaProPrimaryButton())
     .disabled(vm.kiLaeuft || !vm.kiBereit)

     Button { vm.selectedTab = .szenarien } label: {
       Label("Szenarien", systemImage: "chart.line.uptrend.xyaxis")
     }
     .buttonStyle(OpportunismaProGhostButton())
   }

   OpportunismaProSection(titel: "Vollständiger Baum", untertitel: "Interaktive Pfadansicht") {
     OpportunismaMachtportalView(vm: vm)
   }
 }
}
}

struct OpportunismaProEntscheidungView: View {
@Bindable var vm: OpportunismaViewModel

private var optionen: [(label: String, typ: String, score: Int)] {
 let extra = [
   (label: "Politik-Option", typ: "neutral", score: 62),
   (label: "Wissenschaft-Option", typ: "verbündet", score: 74),
   (label: "Unternehmensziel", typ: "kontrolliert", score: 80)
 ]
 let fromNetz = vm.netzKnoten.prefix(6).map { ($0.label, $0.typ, score(for: $0.typ)) }
 return fromNetz + extra
}

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Text("Entscheidungsnetz")
     .font(OpportunismaPro.hero)
     .foregroundStyle(OpportunismaPro.text)
   Text("Optionen und Abhängigkeiten -- bewertet und bereit für das Action Board.")
     .font(OpportunismaPro.body)
     .foregroundStyle(OpportunismaPro.textSoft)

   OpportunismaProSection(titel: "Netz", untertitel: "Lage der Optionen") {
     PragNetzwerkGraph(
       knoten: vm.netzKnoten + [
         .init(label: "Politik-Option", typ: "neutral", x: 0.15, y: 0.35),
         .init(label: "Wissenschaft-Option", typ: "verbündet", x: 0.85, y: 0.38),
         .init(label: "Unternehmensziel", typ: "kontrolliert", x: 0.5, y: 0.08)
       ],
       kanten: vm.netzKanten + [
         .init(von: "UNTERNEHMEN", zu: "Politik-Option"),
         .init(von: "UNTERNEHMEN", zu: "Wissenschaft-Option"),
         .init(von: "Wissenschaft-Option", zu: "Unternehmensziel")
       ]
     )
     .frame(minHeight: 240)
   }

   OpportunismaProSection(titel: "Optionen-Score", untertitel: "Vergleich & Promote") {
     ForEach(Array(optionen.prefix(8).enumerated()), id: \.offset) { _, o in
       HStack {
         VStack(alignment: .leading, spacing: 2) {
           Text(o.label).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
           Text(o.typ).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.textFaint)
         }
         Spacer()
         Text("\(o.score)")
           .font(.system(size: 20, weight: .bold, design: .rounded))
           .foregroundStyle(OpportunismaPro.accent)
         Button("Als Zug") {
           vm.actionItems.insert(
             .init(titel: "Option: \(o.label)", detail: "Score \(o.score) · \(o.typ)", status: .offen, prio: o.score >= 75 ? .hoch : .mittel, tab: .entscheidungsnetz),
             at: 0
           )
           vm.speichereProSession()
           vm.selectedTab = .actionBoard
         }
         .buttonStyle(OpportunismaProGhostButton())
       }
       .padding(10)
       .opportunismaGlass(elevated: true)
     }
   }
 }
}

private func score(for typ: String) -> Int {
 switch typ {
 case "kontrolliert": return 88
 case "verbündet": return 76
 case "feindlich": return 42
 default: return 58
 }
}
}

struct OpportunismaProRessourcenView: View {
@Bindable var vm: OpportunismaViewModel

private var items: [PragBarItem] { vm.hebel.isEmpty ? vm.ressourcen : vm.hebel }

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Text("Ressourcen")
     .font(OpportunismaPro.hero)
     .foregroundStyle(OpportunismaPro.text)
   Text("Kapazitäten und Engpässe -- der schwächste Hebel steuert die Lage.")
     .font(OpportunismaPro.body)
     .foregroundStyle(OpportunismaPro.textSoft)

   if let e = vm.engpassRessource {
     Label("Engpass: \(e.name) (\(e.wert))", systemImage: "exclamationmark.triangle.fill")
       .font(OpportunismaPro.caption)
       .foregroundStyle(OpportunismaPro.warn)
   }

   ForEach(items) { item in
     VStack(alignment: .leading, spacing: 8) {
       HStack {
         Text(item.name).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
         Spacer()
         Text("\(item.wert)")
           .font(.system(size: 18, weight: .bold, design: .rounded))
           .foregroundStyle(item.wert < 55 ? OpportunismaPro.warn : OpportunismaPro.text)
       }
       ProgressView(value: Double(item.wert) / 100)
         .tint(item.wert < 55 ? OpportunismaPro.warn : OpportunismaPro.accent)
       Button("Engpass -> Action") {
         vm.actionItems.insert(
           .init(titel: "Ressource stärken: \(item.name)", detail: "Aktuell \(item.wert)%", status: .offen, prio: item.wert < 55 ? .hoch : .mittel, tab: .ressourcen),
           at: 0
         )
         vm.speichereProSession()
         vm.selectedTab = .actionBoard
       }
       .buttonStyle(OpportunismaProGhostButton())
     }
     .padding(14)
     .opportunismaGlass(elevated: true)
   }
 }
}
}

struct OpportunismaProNarrativView: View {
@Bindable var vm: OpportunismaViewModel

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Text("Narrativ")
     .font(OpportunismaPro.hero)
     .foregroundStyle(OpportunismaPro.text)
   Text("Wahrnehmung in Politik und Öffentlichkeit -- Messaging-Entwürfe für Counsel.")
     .font(OpportunismaPro.body)
     .foregroundStyle(OpportunismaPro.textSoft)

   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
     ForEach(Array(vm.narrativ.enumerated()), id: \.offset) { _, n in
       VStack(alignment: .leading, spacing: 8) {
         Text(n.label)
           .font(OpportunismaPro.section)
           .foregroundStyle(OpportunismaPro.text)
         Text("\(Int(n.value))")
           .font(.system(size: 28, weight: .bold, design: .rounded))
           .foregroundStyle(OpportunismaPro.text)
         ProgressView(value: n.value / 100)
           .tint(OpportunismaPro.warn)
         Button("Messaging-Zug") {
           vm.actionItems.insert(
             .init(titel: "Narrativ schärfen: \(n.label)", detail: "Score \(Int(n.value)) -- Peer-Messaging angleichen", status: .offen, prio: n.value < 55 ? .hoch : .mittel, tab: .narrativ),
             at: 0
           )
           vm.speichereProSession()
           vm.selectedTab = .actionBoard
         }
         .buttonStyle(OpportunismaProGhostButton())
       }
       .padding(16)
       .opportunismaGlass(elevated: true)
     }
   }

   OpportunismaProSection(titel: "Messaging-Draft", untertitel: "Kopiervorlage") {
     let draft = """
     Positionierung: \(vm.zielText)
     Lage: \(vm.situationText)
     Kernbotschaft: Resilienz und Gestaltungsmacht -- nicht nur Compliance.
     """
     Text(draft)
       .font(.system(size: 12, design: .monospaced))
       .foregroundStyle(OpportunismaPro.textSoft)
       .textSelection(.enabled)
     Button("Draft kopieren") {
       NSPasteboard.general.clearContents()
       NSPasteboard.general.setString(draft, forType: .string)
     }
     .buttonStyle(OpportunismaProPrimaryButton())
   }
 }
}
}

struct OpportunismaProInfluenceView: View {
@Bindable var vm: OpportunismaViewModel

private var items: [PragBarItem] { vm.influence.isEmpty ? vm.dimensionen : vm.influence }

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   Text("Einflusskanäle")
     .font(OpportunismaPro.hero)
     .foregroundStyle(OpportunismaPro.text)
   Text("Kanäle, die die Lage bewegen -- Channel-Plays für Public Affairs.")
     .font(OpportunismaPro.body)
     .foregroundStyle(OpportunismaPro.textSoft)

   ForEach(items) { item in
     HStack(spacing: 14) {
       VStack(alignment: .leading, spacing: 6) {
         Text(item.name).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
         ProgressView(value: Double(item.wert) / 100)
           .tint(OpportunismaPro.signal)
       }
       Text("\(item.wert)")
         .font(.system(size: 22, weight: .bold, design: .rounded))
         .foregroundStyle(OpportunismaPro.text)
       Button("Channel-Play") {
         vm.actionItems.insert(
           .init(titel: "Kanal aktivieren: \(item.name)", detail: "Einfluss \(item.wert)%", status: .offen, prio: .mittel, tab: .influence),
           at: 0
         )
         vm.speichereProSession()
         vm.selectedTab = .actionBoard
       }
       .buttonStyle(OpportunismaProGhostButton())
     }
     .padding(14)
     .opportunismaGlass(elevated: true)
   }
 }
}
}

struct OpportunismaProPlaybooksView: View {
@Bindable var vm: OpportunismaViewModel
@State private var praxis = ImperiumPraxisStore.shared

var body: some View {
 VStack(alignment: .leading, spacing: 18) {
   Text("Sektor-Playbooks")
     .font(OpportunismaPro.hero)
     .foregroundStyle(OpportunismaPro.text)
   Text("Ein Klick lädt Lage, Ziel, Chancen und Actions -- sofort verkaufsfähiger Desk. Praxisprofil: \(praxis.aktiv.titel).")
     .font(OpportunismaPro.body)
     .foregroundStyle(OpportunismaPro.textSoft)

   // Praxis-Checkliste -> Action Board Brücke
   VStack(alignment: .leading, spacing: 10) {
     Text("Aus Praxisprofil laden")
       .font(OpportunismaPro.section)
       .foregroundStyle(OpportunismaPro.text)
     Text("Offene Checklistenpunkte werden als Actions übernommen -- Anwaltspfad statt leerer Kanban.")
       .font(OpportunismaPro.caption)
       .foregroundStyle(OpportunismaPro.textSoft)
     Button("Checkliste -> Action Board") {
       let offen = (praxis.checklistenStand[praxis.aktiv.rawValue] ?? []).filter { !$0.erledigt }
       for p in offen.prefix(8) {
         vm.actionItems.insert(
           OpportunismaActionItem(
             titel: p.titel,
             detail: p.detail,
             status: .offen,
             prio: .hoch,
             tab: .actionBoard,
             owner: "Lead Counsel",
             dueLabel: "7 Tage"
           ),
           at: 0
         )
       }
       vm.speichereProSession()
       vm.selectedTab = .actionBoard
       ImperiumEntscheidungsJournal.shared.eintrag(
         typ: .opportunisma,
         titel: "Praxis->Opportunisma: \(praxis.aktiv.titel)",
         detail: "\(offen.count) Checkpunkte als Actions",
         module: ["Opportunisma", "Praxisprofil"]
       )
     }
     .buttonStyle(OpportunismaProPrimaryButton())
   }
   .padding(16)
   .opportunismaGlass(elevated: true)

   if let id = vm.aktivesPlaybookId, let active = OpportunismaProDemo.playbooks.first(where: { $0.id == id }) {
     Label("Aktiv: \(active.titel)", systemImage: "checkmark.seal.fill")
       .font(OpportunismaPro.caption)
       .foregroundStyle(OpportunismaPro.signal)
   }

   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
     ForEach(OpportunismaProDemo.playbooks) { book in
       VStack(alignment: .leading, spacing: 12) {
         Image(systemName: book.symbol)
           .font(.system(size: 28, weight: .semibold))
           .foregroundStyle(OpportunismaPro.accent)
         Text(book.titel)
           .font(OpportunismaPro.title)
           .foregroundStyle(OpportunismaPro.text)
         Text(book.sektor.uppercased())
           .font(OpportunismaPro.micro)
           .foregroundStyle(OpportunismaPro.textFaint)
         Text(book.detail)
           .font(OpportunismaPro.caption)
           .foregroundStyle(OpportunismaPro.textSoft)
           .fixedSize(horizontal: false, vertical: true)
         Button(vm.aktivesPlaybookId == book.id ? "Erneut laden" : "Playbook laden") {
           vm.wendePlaybookAn(book)
           ImperiumEntscheidungsJournal.shared.eintrag(
             typ: .opportunisma,
             titel: "Playbook: \(book.titel)",
             detail: book.detail,
             module: ["Opportunisma"]
           )
         }
         .buttonStyle(OpportunismaProPrimaryButton())
       }
       .padding(20)
       .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
       .opportunismaGlass(elevated: true)
     }
   }
 }
}
}

struct OpportunismaProZieleView: View {
@Bindable var vm: OpportunismaViewModel

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   ForEach(vm.strategischeZiele) { z in
     HStack {
       VStack(alignment: .leading, spacing: 4) {
         Text(z.ziel).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
         Text(z.status).font(OpportunismaPro.micro).foregroundStyle(OpportunismaPro.textFaint)
       }
       Spacer()
       Text("\(z.fortschritt)%")
         .font(.system(size: 18, weight: .bold, design: .rounded))
         .foregroundStyle(OpportunismaPro.accent)
       ProgressView(value: Double(z.fortschritt) / 100)
         .tint(OpportunismaPro.accent)
         .frame(width: 80)
     }
     .padding(12)
     .opportunismaGlass(elevated: true)
   }
 }
}
}

struct OpportunismaProFragebogenHub: View {
@Bindable var vm: OpportunismaViewModel

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   HStack {
     VStack(alignment: .leading, spacing: 6) {
       Text("Lagefragebogen")
         .font(OpportunismaPro.display)
         .foregroundStyle(OpportunismaPro.text)
       Text(vm.fragebogenAbgeschlossen
          ? "Abgeschlossen -- Prognosen und Module sind hart."
          : "Strukturierte Lageaufnahme · \(Int(vm.fragebogenFortschritt * 100))%")
         .font(OpportunismaPro.caption)
         .foregroundStyle(OpportunismaPro.textSoft)
     }
     Spacer()
     if vm.fragebogenAbgeschlossen {
       Button { vm.selectedTab = .warRoom } label: {
         Label("Weiter zum War Room", systemImage: "shield.lefthalf.filled")
       }
       .buttonStyle(OpportunismaProPrimaryButton())
     }
   }

   if !vm.prognosen.isEmpty {
     OpportunismaProSection(titel: "Prognosen", untertitel: "Aus dem Fragebogen") {
       ForEach(vm.prognosen.prefix(5)) { p in
         VStack(alignment: .leading, spacing: 4) {
           Text(p.option).font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
           Text("-> \(p.fuehrt_zu) · P=\(p.wahrscheinlichkeit)% · K=\(p.kontrolle)%")
             .font(OpportunismaPro.caption)
             .foregroundStyle(OpportunismaPro.textSoft)
         }
         .padding(.vertical, 4)
       }
     }
   }

   OpportunismaProPanelChrome {
     OpportunismaFragebogenView(vm: vm)
   }
 }
}
}

struct OpportunismaProStrategosHub: View {
@Bindable var vm: OpportunismaViewModel

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   HStack {
     VStack(alignment: .leading, spacing: 6) {
       Text("Strategos-Anbindung")
         .font(OpportunismaPro.display)
         .foregroundStyle(OpportunismaPro.text)
       Text(vm.verknuepftesStrategosName.map { "Verknüpft: \($0)" } ?? "Kein Szenario -- Kontext importieren.")
         .font(OpportunismaPro.caption)
         .foregroundStyle(OpportunismaPro.textSoft)
     }
     Spacer()
     Button {
       Task { await vm.synchronisiereMitStrategos() }
     } label: {
       Label("Sync", systemImage: "arrow.triangle.2.circlepath")
     }
     .buttonStyle(OpportunismaProGhostButton())
   }
   OpportunismaProPanelChrome {
     OpportunismaStrategosLinkView(vm: vm)
   }
 }
}
}

