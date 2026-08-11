import SwiftUI

// MARK: - SeitenleistenEintrag (+ Gruppen)
// AppShell selbst wird NICHT gemountet -- Studio (`FenlynineOSStudioShell`) ist die Produkt-Spine.
// Diese Datei bleibt die Quelle für Modul-IDs, Labels und Werkzeug-Suche.

// MARK: - Navigations-Einträge

enum SeitenleistenEintrag: String, CaseIterable, Identifiable {
case dashboard = "dashboard"
case schreibtisch = "schreibtisch"
/// NEU (PDF Prozessarchitektur/Interface): Ein Vorgang, ein Motor, vier Konfigurationen.
/// Fügt sich ADDITIV in die bestehende Navigation ein.
case vorgaenge = "vorgaenge"
case lexara = "lexara"
case richterprofile = "richterprofile"
case aufgaben = "aufgaben"
case zeitleiste = "zeitleiste"
case cockpit = "cockpit"
case analytik = "analytik"
case strategos = "strategos"
case opportunisma = "opportunisma"
case kiChat = "ki-chat"
/// Versteckt in Werkzeugen -- Chat bleibt via KI-Assistent erreichbar; Eintrag für Deep-Links.
case plattformAgent = "plattform-agent"
case sunTzu = "strategic-analysis"
case mandanten = "mandant"
case organon = "organon"
case compliance = "compliance"
case dokumente = "dokumente"
case einstellungen = "einstellungen"
// Imperium 2.4 -- Querschnittssysteme
case lageZentrale = "lage-zentrale"
case konfliktRadar = "konflikt-radar"
case mandatsPipeline = "mandats-pipeline"
case honorare = "honorare"
case entscheidungsjournal = "entscheidungsjournal"
case praxisProfil = "praxis-profil"
case beaCheck = "bea-check"
case berufspflicht = "berufspflicht-desk"
// Konto-System 2.6 -- Admin-Zentrale (nur für Administratoren sichtbar)
case adminZentrale = "admin-zentrale"
// Weltrecht 2.7 -- Jurisdiktionen-Kompass (DACH · Skandinavien · USA · Japan · China)
case jurisdiktionen = "jurisdiktionen"
// Wartung 2.8 -- Selbstreparatur-Agent (automatische Scans, Reparaturen, Beschwerden)
case selbstreparatur = "selbstreparatur"

var id: String { rawValue }

/// Flache Reihenfolge (Fallback / Suche).
static let commandSidebarOrder: [SeitenleistenEintrag] =
  SeitenleistenKoordinationsGruppe.allCases.flatMap(\.eintraege)

// KLARTEXT-PRINZIP: Funktion zuerst, Markenname in Klammern.
// Jeder Nutzer versteht sofort, was ein Modul tut -- die Marke bleibt sichtbar.
var bezeichnung: String {
  switch self {
  case .dashboard: return "Übersicht"
  case .schreibtisch: return "Schreibtisch"
  case .vorgaenge: return "Vorgänge"
  case .lexara: return "Fälle & Mandate (Lexara)"
  case .richterprofile: return "Richter & Gegner"
  case .aufgaben: return "Aufgaben"
  case .zeitleiste: return "Fristen & Termine"
  case .cockpit: return "Kanzlei-Cockpit"
  case .analytik: return "Kanzlei-Analytik"
  case .strategos: return "Zukunfts-Szenarien (Strategos)"
  case .opportunisma: return "Chancen-Radar (Opportunisma)"
  case .kiChat: return "KI-Assistent"
  case .plattformAgent: return "Plattform-Agent"
  case .sunTzu: return "Strategieraum (Fenylaw)"
  case .mandanten: return "Mandantenportal"
  case .organon: return "Team & Netzwerk (Organon)"
  case .compliance: return "KI-Compliance"
  case .dokumente: return "Dokumente & Akten"
  case .einstellungen: return "Einstellungen"
  case .lageZentrale: return "Lagezentrale"
  case .konfliktRadar: return "Interessenkonflikte"
  case .mandatsPipeline: return "Mandats-Pipeline"
  case .honorare: return "Honorare & Zeit"
  case .entscheidungsjournal: return "Entscheidungsjournal"
  case .praxisProfil: return "Praxisprofil"
  case .beaCheck: return "beA-Checkliste"
  case .berufspflicht: return "Berufspflichten"
  case .adminZentrale: return "Admin-Zentrale"
  case .jurisdiktionen: return "Weltrecht-Kompass"
  case .selbstreparatur: return "Selbstreparatur"
  }
}

/// Sidebar-Label -- identisch mit `bezeichnung` (Klartext-Prinzip).
/// Früher trugen Suche und Sidebar andere Namen als die Modulliste -- das war verwirrend.
var commandLabel: String { bezeichnung }

/// Ein Satz in Alltagssprache: Was mache ich hier?
var commandSubtitle: String? {
 switch self {
 case .dashboard: return "Alles Wichtige auf einen Blick: Kennzahlen, Risiken, nächste Schritte"
 case .schreibtisch: return "Freie Arbeitsfläche mit Fenstern, Kausalgraph und Advocatus"
 case .vorgaenge: return "Der Startpunkt: Akten anlegen, bewerten und entscheiden"
 case .lexara: return "Laufende Fälle Schritt für Schritt bearbeiten und analysieren"
 case .strategos: return "Zukunfts-Szenarien durchspielen und vergleichen"
 case .opportunisma: return "Chancen, Optionen und Positionierung erkunden"
 case .analytik: return "Kennzahlen und Strategie-Metriken der Kanzlei"
 case .richterprofile: return "Profile von Richtern, Gegnern und weiteren Akteuren"
 case .zeitleiste: return "Fristen, Termine und Verfahrensplan im Überblick"
 case .dokumente: return "Dokumente hochladen, analysieren und freigeben"
 case .kiChat: return "Mit der KI über Fälle sprechen und Rückfragen stellen"
 case .sunTzu: return "Lagescore und Strategie-Prinzipien für den Gesamtfall"
 case .mandanten: return "Kommunikation mit Mandanten und Portal-Freigaben"
 case .organon: return "Wer macht was: Organisationskarte, Skills, Zuständigkeiten"
 case .cockpit: return "Kapazität, Ressourcen und Steuerung der Kanzlei"
 case .aufgaben: return "To-dos anlegen, zuweisen und nachverfolgen"
 case .compliance: return "EU AI Act, KI-Protokoll und Audit"
 case .plattformAgent: return "Administration, Optimierung, Automatisierung"
 case .einstellungen: return "Konto, Design, KI, Daten und System"
 case .lageZentrale: return "Mandate, Konflikte, Pipeline und Fristen in einem Blick"
 case .konfliktRadar: return "Interessenkonflikte über Fälle, Mandanten und Team erkennen"
 case .mandatsPipeline: return "Vom Lead über die Annahme bis zur Abrechnung"
 case .honorare: return "Zeiterfassung und RVG-Orientierung -- lokal"
 case .entscheidungsjournal: return "Nachvollziehbare Spur aller strategischen Entscheidungen"
 case .praxisProfil: return "Fachrichtung wählen: Patent, Straf, Wirtschaft, Syndikus …"
 case .beaCheck: return "Checkliste für die Gerichts-Kommunikation (beA)"
 case .berufspflicht: return "Ausgangskontrolle, Mandatsannahme und KI-Endprüfung"
 case .adminZentrale: return "Konten, Abos, KI-Abrechnung, DSGVO, Audit"
 case .jurisdiktionen: return "Rechtsordnungen vergleichen: DACH, Skandinavien, USA, Japan, China"
 case .selbstreparatur: return "Automatische Scans, Reparaturen und KI-Failover"
 }
}

var symbol: String {
 switch self {
 case .dashboard: return "house.fill"
 case .schreibtisch: return "rectangle.3.group.fill"
 case .vorgaenge: return "square.stack.3d.up.fill"
 case .lexara: return "folder.fill"
 case .richterprofile: return "person.text.rectangle.fill"
 case .aufgaben: return "checklist"
 case .zeitleiste: return "calendar"
 case .cockpit: return "gauge.with.dots.needle.33percent"
 case .analytik: return "chart.bar.fill"
 case .strategos: return "shield.lefthalf.filled"
 case .opportunisma: return "scope"
 case .kiChat: return "bubble.left.and.bubble.right.fill"
 case .plattformAgent: return "cpu.fill"
 case .sunTzu: return "scope"
 case .mandanten: return "person.crop.circle.badge.checkmark"
 case .organon: return "point.3.connected.trianglepath.dotted"
 case .compliance: return "checkmark.shield.fill"
 case .dokumente: return "doc.text.fill"
 case .einstellungen: return "gearshape.fill"
 case .lageZentrale: return "rectangle.3.group.bubble.left.fill"
 case .konfliktRadar: return "exclamationmark.shield.fill"
 case .mandatsPipeline: return "arrow.triangle.branch"
 case .honorare: return "eurosign.circle.fill"
 case .entscheidungsjournal: return "book.closed.fill"
 case .praxisProfil: return "person.crop.rectangle.stack.fill"
 case .beaCheck: return "envelope.badge.shield.half.filled"
 case .berufspflicht: return "scalemass.fill"
 case .adminZentrale: return "person.2.badge.gearshape.fill"
 case .jurisdiktionen: return "globe.europe.africa.fill"
 case .selbstreparatur: return "wrench.and.screwdriver.fill"
 }
}

var gruppe: SeitenleistenGruppe {
 switch self {
 case .dashboard: return .haupt
 case .schreibtisch: return .haupt
 case .vorgaenge: return .haupt
 case .lexara: return .haupt
 case .richterprofile: return .analyse
 case .aufgaben: return .organisation
 case .zeitleiste: return .organisation
 case .cockpit: return .kanzlei
 case .analytik: return .kanzlei
 case .strategos: return .enterprise
 case .opportunisma: return .enterprise
 case .kiChat: return .ki
 case .plattformAgent: return .ki
 case .sunTzu: return .enterprise
 case .mandanten: return .organisation
 case .organon: return .organisation
 case .compliance: return .ki
 case .dokumente: return .organisation
 case .einstellungen: return .system
 case .adminZentrale: return .system
 case .selbstreparatur: return .system
 case .jurisdiktionen: return .analyse
 case .lageZentrale, .konfliktRadar, .mandatsPipeline, .honorare,
   .entscheidungsjournal, .praxisProfil, .beaCheck, .berufspflicht:
   return .kanzlei
 }
}
}

enum SeitenleistenGruppe: String {
case haupt = "Haupt"
case analyse = "Analyse"
case organisation = "Organisation"
case kanzlei = "Kanzlei"
case enterprise = "Enterprise"
case ki = "KI"
case system = "System"
}

// MARK: - Koordinations-Ablauf (Sidebar-Gruppen)

enum SeitenleistenKoordinationsGruppe: String, CaseIterable, Identifiable {
case koordination
case lexara
case strategos
case organisation
case delegation
case pragmatismus
case system

var id: String { rawValue }

var titel: String {
 switch self {
 case .koordination: return "KOORDINATION"
 case .lexara: return "LEXARA"
 case .strategos: return "STRATEGOS"
 case .organisation: return "ORGANISATION"
 case .delegation: return "DELEGATION"
 case .pragmatismus: return "UMSETZUNG"
 case .system: return "SYSTEM"
 }
}

var untertitel: String {
 switch self {
 case .koordination: return "Lage · Cockpit · Kausalgraph"
 case .lexara: return "Mandate · Verfahren · Beweise"
 case .strategos: return "Enterprise · Szenarien · Optionen"
 case .organisation: return "Mandanten · Organon · Kommunikation"
 case .delegation: return "Aufgaben · Zuweisungen · Verantwortung"
 case .pragmatismus: return "Pragmatisch · KI · Cockpit"
 case .system: return "Compliance · Einstellungen · Admin"
 }
}

var eintraege: [SeitenleistenEintrag] {
 switch self {
 case .koordination:
   return [.lageZentrale, .dashboard, .vorgaenge, .schreibtisch, .cockpit]
 case .lexara:
   return [.lexara, .richterprofile, .jurisdiktionen, .zeitleiste, .dokumente, .mandatsPipeline]
 case .strategos:
   return [.strategos, .opportunisma, .sunTzu, .analytik, .entscheidungsjournal]
 case .organisation:
   return [.organon, .mandanten, .konfliktRadar, .praxisProfil]
 case .delegation:
   return [.aufgaben, .honorare]
 case .pragmatismus:
   return [.kiChat]
 case .system:
   // plattformAgent bewusst aus der sichtbaren Navigation genommen (dünner Chat-Duplikat)
   return [.berufspflicht, .compliance, .beaCheck, .selbstreparatur, .adminZentrale, .einstellungen]
 }
}

/// Sichtbare Trennung zwischen Lexara (Verfahren) und Strategos (Enterprise)
var zeigtMarkenTrennerDanach: Bool {
 self == .lexara
}

var accent: Color {
 switch self {
 case .koordination: return FenlynineOSTheme.accent
 case .lexara: return FenlynineOSTheme.accent
 case .strategos: return FenlynineOSTheme.warning
 case .organisation: return FenlynineOSTheme.success.opacity(0.9)
 case .delegation: return Color(red: 0.45, green: 0.62, blue: 0.95)
 case .pragmatismus: return FenlynineOSTheme.success.opacity(0.85)
 case .system: return FenlynineOSTheme.textSecondary
 }
}
}

// MARK: - Vision-Inhaltspanel (PDF: äußeres Glas um Hauptinhalt)

private struct VisionInhaltsPanel: ViewModifier {
let aktiv: Bool

func body(content: Content) -> some View {
 if aktiv {
   content.fenlynineOSVisionHauptPanel(abstand: 20)
 } else {
   content
 }
}
}

// MARK: - App-Shell (UNUSED -- nicht mounten)
// Historische NavigationSplitView-Shell. Produkt-Spine ist `FenlynineOSStudioShell`.
// Nicht instantiieren; `SeitenleistenEintrag` oben bleibt die kanonische Modul-Registry.

struct AppShell: View {
@EnvironmentObject var authManager: AuthManager
@EnvironmentObject var appState: AppState

@State private var selectedEintrag: SeitenleistenEintrag? = .dashboard
@State private var sidebarEingeklappt = false

private var nutztVisionLayout: Bool {
 guard let e = selectedEintrag else { return true }
 return e.glasModus != .kein
}

private let bottomNavEintraege: [(SeitenleistenEintrag, String, String)] = [
 (.dashboard, "Lagebild", "house.fill"),
 (.lexara, "Lexara", "folder.fill"),
 (.cockpit, "Cockpit", "gauge.with.dots.needle.33percent"),
 (.einstellungen, "System", "gearshape.fill")
]

var body: some View {
 HStack(spacing: 10) {
   SidebarView(selected: $selectedEintrag, eingeklappt: $sidebarEingeklappt)
     .frame(width: sidebarEingeklappt ? 68 : 268)
     .background { VisionOSGlasFlaeche.seitenleiste() }
     .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
     .padding(.leading, 10)
     .padding(.vertical, 16)

   ZStack {
     if let eintrag = selectedEintrag {
       NavigationStack {
         DetailView(
           eintrag: eintrag,
           selectedEintrag: $selectedEintrag,
           sidebarEingeklappt: $sidebarEingeklappt
         )
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .padding(.trailing, 14)
         .padding(.top, 10)
         .padding(.bottom, nutztVisionLayout ? 68 : 12)
         .modifier(VisionInhaltsPanel(aktiv: nutztVisionLayout))
       }
     } else {
       HomeView(inVisionPanel: false)
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .padding(.trailing, 14)
         .padding(.top, 10)
         .padding(.bottom, 68)
         .modifier(VisionInhaltsPanel(aktiv: true))
     }
   }
   .frame(maxWidth: .infinity, maxHeight: .infinity)
 }
 .overlay(alignment: .bottom) {
   ZStack(alignment: .bottom) {
     if nutztVisionLayout {
       VisionOSBottomNavPill(auswahl: $selectedEintrag, eintraege: bottomNavEintraege)
         .padding(.bottom, 14)
     }
     GlobalToastView(extraBottomPadding: nutztVisionLayout ? 58 : 0)
   }
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .fenlynineOSProgramGlasChrome()
 .fenlynineOSCommandBackground()
 .onReceive(NotificationCenter.default.publisher(for: .navigateToCase)) { notification in
   if let caseId = notification.object as? String {
     appState.selectedCaseId = caseId
     selectedEintrag = .lexara
   }
 }
 .onReceive(NotificationCenter.default.publisher(for: .createNewCase)) { _ in
   selectedEintrag = .lexara
 }
 .onReceive(NotificationCenter.default.publisher(for: .navigateToSidebar)) { notification in
   if let raw = notification.object as? String,
    let eintrag = SeitenleistenEintrag(rawValue: raw) {
     selectedEintrag = eintrag
   }
 }
 .onAppear { applyLaunchRoute() }
}

private func applyLaunchRoute() {
 let route = UserDefaults.standard.string(forKey: "fenlynineos_launch_route")
   ?? (CommandLine.arguments.contains("--opportunisma-fragebogen") ? "opportunisma_fragebogen" : nil)
 guard route == "opportunisma_fragebogen" else { return }
 selectedEintrag = .opportunisma
 UserDefaults.standard.set(OpportunismaTab.fragebogen.rawValue, forKey: "opportunisma_initial_tab")
 UserDefaults.standard.removeObject(forKey: "fenlynineos_launch_route")
}
}

// MARK: - Vision Pro Icon-Rail (linke schwebende Pille)

struct VisionOSSidebarRail: View {
@Binding var selected: SeitenleistenEintrag?

private let hauptIcons: [SeitenleistenEintrag] = [
 .dashboard, .lexara, .cockpit, .strategos, .organon,
 .opportunisma, .aufgaben, .kiChat, .compliance, .einstellungen
]

var body: some View {
 ZStack {
   Color.clear
   VisionOSIconRail(auswahl: $selected, eintraege: hauptIcons)
     .padding(.vertical, 20)
     .padding(.leading, 8)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

// MARK: - Seitenleiste (Legacy)

struct SidebarView: View {
@Binding var selected: SeitenleistenEintrag?
@Binding var eingeklappt: Bool
@EnvironmentObject var authManager: AuthManager
@State private var sidebarSuche = ""
@State private var sidebarSucheAktiv = ""

private var gefilterteGruppen: [SeitenleistenKoordinationsGruppe] {
 guard !sidebarSucheAktiv.trimmingCharacters(in: .whitespaces).isEmpty else {
   return Array(SeitenleistenKoordinationsGruppe.allCases)
 }
 let q = sidebarSucheAktiv.lowercased()
 return SeitenleistenKoordinationsGruppe.allCases.filter { gruppe in
   gruppe.eintraege.contains { e in
     e.commandLabel.lowercased().contains(q)
       || (e.commandSubtitle?.lowercased().contains(q) ?? false)
   }
 }
}

var body: some View {
 List(selection: $selected) {
   if !eingeklappt {
     HStack {
       VStack(alignment: .leading, spacing: 2) {
         Text("FENLYNINEOS LEGAL SUITE")
           .font(.system(size: 13, weight: .semibold))
           .foregroundStyle(.white)
         Text("Koordinationszentrale")
           .font(.system(size: 11))
           .foregroundStyle(MacOSSettingsTokens.subtitle)
       }
       Spacer()
       Button {
         withAnimation(.spring(duration: 0.28)) { eingeklappt.toggle() }
       } label: {
         Image(systemName: eingeklappt ? "sidebar.right" : "sidebar.left")
           .font(.system(size: 12, weight: .semibold))
           .foregroundStyle(MacOSSettingsTokens.subtitle)
       }
       .buttonStyle(.plain)
       .help(eingeklappt ? "Menü ausklappen" : "Menü einklappen")
     }
     .padding(.vertical, 8)
     .padding(.horizontal, 8)
     .listRowInsets(EdgeInsets())
     .listRowBackground(Color.clear)
     .listRowSeparator(.hidden)

     MacOSSettingsSearchField(text: $sidebarSuche, placeholder: "Suchen")
       .padding(.horizontal, 4)
       .padding(.bottom, 6)
       .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 4, trailing: 8))
       .listRowBackground(Color.clear)
       .listRowSeparator(.hidden)
       .onChange(of: sidebarSuche) { _, neu in
         Task {
           try? await Task.sleep(for: .milliseconds(200))
           await MainActor.run { sidebarSucheAktiv = neu }
         }
       }
   }

   ForEach(gefilterteGruppen) { gruppe in
     Section {
       ForEach(gefilterteEintraege(in: gruppe)) { eintrag in
         if eingeklappt {
           SidebarIconRow(eintrag: eintrag, isSelected: selected == eintrag)
             .tag(eintrag)
             .listRowBackground(Color.clear)
         } else {
           SidebarRow(eintrag: eintrag, isSelected: selected == eintrag)
             .tag(eintrag)
             .listRowBackground(Color.clear)
         }
       }

       if gruppe.zeigtMarkenTrennerDanach && !eingeklappt {
         SidebarLexaraStrategosTrenner()
       }
     } header: {
       if !eingeklappt {
         SidebarSectionHeader(gruppe: gruppe)
       }
     }
   }
 }
 .scrollContentBackground(.hidden)
 .background { Color.clear }
 .listStyle(.sidebar)
 .safeAreaInset(edge: .bottom) {
   SidebarFooter()
 }
}

private func gefilterteEintraege(in gruppe: SeitenleistenKoordinationsGruppe) -> [SeitenleistenEintrag] {
 let q = sidebarSucheAktiv.trimmingCharacters(in: .whitespaces).lowercased()
 guard !q.isEmpty else { return gruppe.eintraege }
 return gruppe.eintraege.filter {
   $0.commandLabel.lowercased().contains(q)
     || ($0.commandSubtitle?.lowercased().contains(q) ?? false)
 }
}
}

struct SidebarSectionHeader: View {
let gruppe: SeitenleistenKoordinationsGruppe

var body: some View {
 Text(gruppe.titel)
   .font(.system(size: 11, weight: .semibold))
   .foregroundStyle(MacOSSettingsTokens.subtitle)
   .padding(.top, 8)
   .padding(.bottom, 2)
   .textCase(nil)
}
}

/// Goldene Trennlinie zwischen Lexara (Verfahren) und Strategos (Enterprise)
struct SidebarLexaraStrategosTrenner: View {
var body: some View {
 VStack(spacing: 4) {
   Rectangle()
     .fill(FenlynineOSTheme.borderGold)
     .frame(height: 1)
   HStack {
     Text("LEXARA")
       .font(.system(size: 7, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.goldLight.opacity(0.7))
     Image(systemName: "arrow.right")
       .font(.system(size: 7, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.textTertiary)
     Text("STRATEGOS")
       .font(.system(size: 7, weight: .bold))
       .foregroundStyle(FenlynineOSTheme.warning.opacity(0.85))
     Spacer()
   }
 }
 .padding(.vertical, 8)
 .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
 .listRowBackground(Color.clear)
 .listRowSeparator(.hidden)
}
}

struct SidebarIconRow: View {
let eintrag: SeitenleistenEintrag
let isSelected: Bool

var body: some View {
 MacOSSettingsSquircleIcon(
   symbol: eintrag.macSettingsSymbol,
   color: eintrag.macSettingsIconColor
 )
 .padding(4)
 .background {
   if isSelected {
     RoundedRectangle(cornerRadius: 8, style: .continuous)
       .fill(MacOSSettingsTokens.selectionBlue)
   }
 }
 .help(eintrag.commandLabel)
}
}

struct SidebarRow: View {
let eintrag: SeitenleistenEintrag
let isSelected: Bool

var body: some View {
 MacOSSettingsSidebarRow(
   titel: eintrag.commandLabel,
   untertitel: eintrag.commandSubtitle,
   symbol: eintrag.macSettingsSymbol,
   iconColor: eintrag.macSettingsIconColor,
   isSelected: isSelected
 )
}
}

struct SidebarFooter: View {
@EnvironmentObject var authManager: AuthManager
@State private var zeigeMenu = false

var body: some View {
 Divider().overlay(FenlynineOSTheme.border)
 Button {
   zeigeMenu.toggle()
 } label: {
   HStack(spacing: 8) {
     Image(systemName: "person.crop.circle.fill")
       .font(.system(size: 28))
       .foregroundStyle(FenlynineOSTheme.accent)
     VStack(alignment: .leading, spacing: 2) {
       Text("Benutzer")
         .font(.system(size: 8, weight: .medium))
         .foregroundStyle(FenlynineOSTheme.textTertiary)
       Text(authManager.userName.isEmpty ? "Chefstratege" : authManager.userName)
         .font(.system(size: 11, weight: .semibold))
         .foregroundStyle(FenlynineOSTheme.textPrimary)
         .lineLimit(1)
     }
     Spacer()
   }
   .padding(.horizontal, 12)
   .padding(.vertical, 10)
   .fenlynineOSAdaptivePanel(cornerRadius: 12)
 }
 .buttonStyle(.plain)
 .popover(isPresented: $zeigeMenu, arrowEdge: .top) {
   BenutzerMenuView()
 }
 .padding(.bottom, 4)
}
}

struct BenutzerMenuView: View {
@EnvironmentObject var authManager: AuthManager

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   VStack(alignment: .leading, spacing: 4) {
     Text(authManager.userName)
       .font(.headline)
     Text(authManager.userEmail)
       .font(.caption)
       .foregroundStyle(.secondary)
   }
   .padding(.horizontal, 12)
   .padding(.top, 12)
   .padding(.bottom, 8)

   Divider()

   Button("Einstellungen") {
     NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.einstellungen.rawValue)
   }

   Divider()

   Button("Abmelden", role: .destructive) {
     authManager.logout()
   }
   .buttonStyle(.plain)
   .foregroundStyle(.red)
   .padding(.horizontal, 12)
   .padding(.vertical, 6)
   .padding(.bottom, 8)
 }
 .frame(width: 220)
}
}

// MARK: - Haupt-Inhaltsrouter

struct DetailView: View {
let eintrag: SeitenleistenEintrag
@Binding var selectedEintrag: SeitenleistenEintrag?
@Binding var sidebarEingeklappt: Bool
@EnvironmentObject var appState: AppState

private var istLegacyModul: Bool { eintrag.glasModus == .kein }

var body: some View {
 Group {
   if istLegacyModul {
     routedContent
       .fenlynineOSModuleChrome(for: eintrag)
       .modifier(FenlynineOSModuleBackground(glasModus: .kein))
   } else {
     Group {
       if eintrag == .opportunisma {
         OpportunismaView()
       } else {
         routedContent
       }
     }
     .frame(maxWidth: .infinity, maxHeight: .infinity)
     .fenlynineOSModuleChrome(for: eintrag)
   }
 }
 .navigationTitle(eintrag.bezeichnung)
}

@ViewBuilder
private var routedContent: some View {
 switch eintrag {
 case .dashboard: HomeView(inVisionPanel: false)
 case .schreibtisch: SchreibtischView()
 case .vorgaenge: VorgangListeView()
 case .lexara: CaseListView()
 case .richterprofile: RichterProfileView()
 case .aufgaben: AufgabenView()
 case .zeitleiste: ZeitleisteView()
 case .cockpit: KanzleiCockpitView()
 case .analytik: KanzleiAnalytikView()
 case .strategos: StrategosView().fenlynineOSSFTypographyOnly()
 case .opportunisma: OpportunismaView()
 case .kiChat: FallAssistentView()
 case .plattformAgent: PlattformAgentView()
 case .sunTzu: FenylawStrategiesView()
 case .mandanten: MandantenView()
 case .organon: OrganonView()
 case .compliance: KIComplianceView()
 case .dokumente: DokumenteUebersichtView()
 case .einstellungen: EinstellungenView()
 case .lageZentrale: ImperiumLageZentraleView()
 case .konfliktRadar: ImperiumKonfliktRadarView()
 case .mandatsPipeline: ImperiumMandatsPipelineView()
 case .honorare: ImperiumHonorareZeitView()
 case .entscheidungsjournal: ImperiumEntscheidungsJournalView()
 case .praxisProfil: ImperiumPraxisProfilView()
 case .beaCheck: ImperiumBeAChecklisteView()
 case .berufspflicht: ImperiumBerufspflichtDeskView()
 case .adminZentrale: AdminZentraleView()
 case .jurisdiktionen: JurisdiktionenView()
 case .selbstreparatur: SelbstreparaturView()
 }
}
}

// MARK: - Globale Toast-Benachrichtigungen

struct GlobalToastView: View {
@EnvironmentObject var appState: AppState
var extraBottomPadding: CGFloat = 0

var body: some View {
 VStack(spacing: 8) {
   if let error = appState.globalError {
     ToastView(message: error, typ: .fehler)
       .transition(.move(edge: .bottom).combined(with: .opacity))
   }
   if let success = appState.globalSuccess {
     ToastView(message: success, typ: .erfolg)
       .transition(.move(edge: .bottom).combined(with: .opacity))
   }
 }
 .animation(.spring(duration: 0.3), value: appState.globalError)
 .animation(.spring(duration: 0.3), value: appState.globalSuccess)
 .padding(.bottom, 20 + extraBottomPadding)
}
}

struct ToastView: View {
let message: String
let typ: ToastTyp

enum ToastTyp {
 case fehler, erfolg, info

 var farbe: Color {
   switch self {
   case .fehler: return .red
   case .erfolg: return .green
   case .info: return .blue
   }
 }

 var symbol: String {
   switch self {
   case .fehler: return "xmark.circle.fill"
   case .erfolg: return "checkmark.circle.fill"
   case .info: return "info.circle.fill"
   }
 }
}

var body: some View {
 HStack(spacing: 10) {
   Image(systemName: typ.symbol)
     .font(.system(size: 14, weight: .semibold))
     .foregroundStyle(typ.farbe)
   Text(message)
     .font(.system(size: 13, weight: .medium))
 }
 .padding(.horizontal, 18)
 .padding(.vertical, 12)
 .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
 .overlay(
   RoundedRectangle(cornerRadius: 12, style: .continuous)
     .stroke(typ.farbe.opacity(0.2), lineWidth: 1)
 )
 .shadow(color: FenlynineOSDesign.cardShadow, radius: 12, y: 6)
}
}

// MARK: - Dokumente-Übersicht

struct DokumenteUebersichtView: View {
@State private var dokumente: [LegalDocument] = []
@State private var isLoading = false

var body: some View {
 ScrollView {
   VStack(spacing: 12) {
     if dokumente.isEmpty && !isLoading {
       Text("Keine Dokumente vorhanden")
         .font(.subheadline)
         .foregroundStyle(FenlynineOSTheme.textSecondary)
         .frame(maxWidth: .infinity, alignment: .leading)
         .padding(.top, 8)
     } else {
       ForEach(dokumente, id: \.self) { doc in
         FenlynineOSCard(elevated: false) {
           HStack(spacing: 12) {
             Image(systemName: "doc.text.fill")
               .foregroundStyle(FenlynineOSTheme.accent)
             VStack(alignment: .leading, spacing: 4) {
               Text(doc.title)
                 .font(.system(size: 13, weight: .semibold))
                 .foregroundStyle(FenlynineOSTheme.textPrimary)
                 .lineLimit(1)
               HStack(spacing: 8) {
                 Text(doc.kategorie.rawValue)
                   .font(.caption2)
                   .foregroundStyle(FenlynineOSTheme.textTertiary)
                 if !doc.vertraulich {
                   Text("freigegeben")
                     .font(.caption2.bold())
                     .foregroundStyle(FenlynineOSTheme.success)
                 }
               }
             }
             Spacer()
           }
         }
       }
     }
   }
   .padding(20)
 }
 .overlay {
   if isLoading {
     ProgressView().tint(FenlynineOSTheme.accent)
   }
 }
 .task { await laden() }
 .refreshable { await laden() }
}

@MainActor
private func laden() async {
 isLoading = true
 defer { isLoading = false }
 do {
   dokumente = try await Services.documents.list()
 } catch {
   dokumente = []
 }
}
}

