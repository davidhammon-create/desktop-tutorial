import SwiftUI

enum OrganonHauptReiter: String, CaseIterable, Identifiable {
case hierarchie, karte, suche, profil, skills, kapazitaet, verknuepfung, bearbeiten, audit, compliance

var id: String { rawValue }

var bezeichnung: String {
  switch self {
  case .hierarchie: return "Hierarchie"
  case .karte: return "Karte"
  case .suche: return "Suche"
  case .profil: return "Personen"
  case .skills: return "Skills"
  case .kapazitaet: return "Kapazität"
  case .verknuepfung: return "Links"
  case .bearbeiten: return "Bearbeiten"
  case .audit: return "Audit"
  case .compliance: return "Transparenz"
  }
}

var symbol: String {
  switch self {
  case .hierarchie: return "arrow.triangle.branch"
  case .karte: return "map.fill"
  case .suche: return "magnifyingglass"
  case .profil: return "person.text.rectangle"
  case .skills: return "square.grid.3x3.fill"
  case .kapazitaet: return "gauge.with.dots.needle.33percent"
  case .verknuepfung: return "link"
  case .bearbeiten: return "pencil"
  case .audit: return "list.clipboard"
  case .compliance: return "checkmark.shield"
  }
}
}

struct OrganonView: View {
@State private var vm = OrganonViewModel()
@State private var reiter: OrganonHauptReiter = .hierarchie
@Bindable private var design = FenlynineOSDesignStore.shared

var body: some View {
  VStack(spacing: 0) {
    OrganonKopfzeile(vm: vm, design: design)
    if !vm.statusMeldung.isEmpty {
      Text(vm.statusMeldung)
        .font(.caption)
        .foregroundStyle(FenlynineOSTheme.success)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(FenlynineOSTheme.success.opacity(0.08))
    }
    Divider().opacity(0.3)
    OrganonReiterLeiste(auswahl: $reiter)
    Divider().opacity(0.3)

    Group {
      switch reiter {
      case .hierarchie:
        OrganonHierarchieView(vm: vm, onZurKarte: { reiter = .karte })
      case .karte:
        OrganonCanvasView(vm: vm, onPersonDetail: { reiter = .bearbeiten })
      case .suche:
        OrganonSearchView(vm: vm, onTreffer: { reiter = .karte })
      case .profil:
        OrganonProfilListeView(vm: vm)
      case .skills:
        OrganonSkillsMatrixView(vm: vm)
      case .kapazitaet:
        OrganonKapazitaetView(vm: vm)
      case .verknuepfung:
        OrganonVerknuepfungenView(vm: vm)
      case .bearbeiten:
        OrganonEditorView(vm: vm)
      case .audit:
        OrganonAuditView(vm: vm)
      case .compliance:
        OrganonComplianceView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  .fenlynineOSCommandBackground()
  .onAppear {
    OrganonStore.shared.repariereHierarchie(still: true)
  }
}
}

struct OrganonKopfzeile: View {
@Bindable var vm: OrganonViewModel
@Bindable var design: FenlynineOSDesignStore

var body: some View {
  FenlynineOSGlassBar {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
       HStack(spacing: 6) {
         Image(systemName: "point.3.connected.trianglepath.dotted")
           .foregroundStyle(FenlynineOSTheme.accent)
         Text("ORGANON")
           .font(.system(size: 10, weight: .bold))
           .foregroundStyle(FenlynineOSTheme.brand)
           .tracking(1.4)
       }
       Text("Organisation -- Abteilungen & Personen")
         .font(.system(size: 20, weight: .bold))
       Text("Hierarchie: Gesellschaft -> Abteilung -> Team -> Person")
         .font(.caption)
         .foregroundStyle(FenlynineOSTheme.textSecondary)
     }
     Spacer()
     FenlynineOSDesignModellPicker(store: design, kompakt: true)
     HStack(spacing: 10) {
       FenlynineOSMetricChip(titel: "Abteilungen", wert: "\(vm.abteilungen.count)", farbe: OrganonKnotenTyp.bereich.farbe, compact: true)
       FenlynineOSMetricChip(titel: "Teams", wert: "\(vm.teams.count)", farbe: OrganonKnotenTyp.team.farbe, compact: true)
       FenlynineOSMetricChip(titel: "Personen", wert: "\(vm.personen.filter { !$0.istVakanz }.count)", farbe: FenlynineOSTheme.success, compact: true)
       FenlynineOSMetricChip(titel: "Vakanzen", wert: "\(vm.vakanzen.count)", farbe: FenlynineOSTheme.warning, compact: true)
     }
   }
 }
}
}

struct OrganonReiterLeiste: View {
@Binding var auswahl: OrganonHauptReiter

var body: some View {
 ScrollView(.horizontal, showsIndicators: false) {
   HStack(spacing: 4) {
     ForEach(OrganonHauptReiter.allCases) { r in
       Button {
         withAnimation(.easeInOut(duration: 0.15)) { auswahl = r }
       } label: {
         HStack(spacing: 6) {
           Image(systemName: r.symbol)
             .font(.system(size: 12))
           Text(r.bezeichnung)
             .font(.system(size: 12, weight: auswahl == r ? .semibold : .regular))
         }
         .foregroundStyle(auswahl == r ? FenlynineOSTheme.accent : FenlynineOSTheme.textSecondary)
         .padding(.horizontal, 12)
         .padding(.vertical, 8)
         .background(auswahl == r ? FenlynineOSTheme.accent.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
       }
       .buttonStyle(.plain)
     }
   }
   .padding(.horizontal, 16)
   .padding(.vertical, 8)
 }
}
}

struct OrganonComplianceView: View {
var body: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 20) {
     Text("Rechtskonformes Design")
       .font(.title2.bold())
     Text("Organon trennt Strukturebene (Karte, Profile, Skills, Verknüpfungen) strikt von Leistungsüberwachung. Aggregation ist Standard -- personenscharfe Auswertungen nur mit dokumentierter Betriebsvereinbarung. Das Audit-Protokoll dokumentiert Strukturänderungen, keine Produktivität.")
       .font(.subheadline)
       .foregroundStyle(.secondary)

     ForEach(prinzipien, id: \.titel) { p in
       FenlynineOSCard {
         VStack(alignment: .leading, spacing: 8) {
           Label(p.titel, systemImage: p.symbol)
             .font(.headline)
           Text(p.text)
             .font(.subheadline)
             .foregroundStyle(.secondary)
         }
         .frame(maxWidth: .infinity, alignment: .leading)
       }
     }

     FenlynineOSCard {
       VStack(alignment: .leading, spacing: 8) {
         Label("Was sieht wer über mich?", systemImage: "eye.slash.fill")
           .font(.headline)
         Text("Jede Person kann einsehen, welche Profildaten gespeichert sind und welche Rollen Zugriff haben. Keine verdeckte Auswertung -- Voraussetzung für Betriebsrats-Tauglichkeit.")
           .font(.subheadline)
           .foregroundStyle(.secondary)
       }
       .frame(maxWidth: .infinity, alignment: .leading)
     }
   }
   .padding(24)
 }
}

private var prinzipien: [(titel: String, symbol: String, text: String)] {
 [
   ("Zweckbindung", "target", "Nur Organisations- und Zuständigkeitszwecke -- keine Bewertung individueller Leistung."),
   ("Datenminimierung", "leaf", "Skills und Kapazität nur soweit für Staffing nötig; Notizen freiwillig."),
   ("Transparenz", "eye", "Audit-Tab zeigt Strukturänderungen; Profile sind einsehbar."),
   ("Mitbestimmung", "person.3", "Betriebsvereinbarung vor personenscharfen Auswertungen.")
 ]
}
}

