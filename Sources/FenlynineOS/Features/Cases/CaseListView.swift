import SwiftUI

// MARK: - ViewModel

@Observable
final class CaseListViewModel {
var faelle: [LegalCase] = []
var ordner: [CaseFolder] = []
var isLoading = false
var error: String?
var suchtext = ""
var statusFilter: LegalCase.CaseStatus? = nil
var sortierung: SortierOption = .aktualisiert
var selectedOrdnerId: String? = nil

enum SortierOption: String, CaseIterable {
  case aktualisiert = "Zuletzt aktualisiert"
  case name = "Name"
  case prognose = "Prognose"
  case status = "Status"
}

var gefilterteFaelle: [LegalCase] {
  var result = faelle

  if let status = statusFilter {
    result = result.filter { $0.status == status }
  }

  if let ordnerId = selectedOrdnerId {
    result = result.filter { $0.folder_id == ordnerId }
  }

  if !suchtext.isEmpty {
    let t = suchtext.lowercased()
    result = result.filter {
      $0.fallname.lowercased().contains(t) ||
      ($0.aktenzeichen?.lowercased().contains(t) ?? false) ||
      ($0.rechtsgebiet?.lowercased().contains(t) ?? false) ||
      ($0.mandant_name?.lowercased().contains(t) ?? false)
    }
  }

  // Demo-Fälle immer oben (Showcase für neue Nutzer)
  result.sort { a, b in
    let aDemo = a.fallname.hasPrefix("[Demo]")
    let bDemo = b.fallname.hasPrefix("[Demo]")
    if aDemo != bDemo { return aDemo }
    switch sortierung {
    case .aktualisiert:
      return (a.updated_at ?? Date.distantPast) > (b.updated_at ?? Date.distantPast)
    case .name:
      return a.fallname < b.fallname
    case .prognose:
      return (a.prognose ?? 0) > (b.prognose ?? 0)
    case .status:
      return a.status.rawValue < b.status.rawValue
    }
  }
  return result
}

@MainActor
func laden() async {
  isLoading = true
  defer { isLoading = false }
  do {
    async let f = Services.cases.list()
    async let o = Services.caseFolders.list()
    let (loadedFaelle, loadedOrdner) = try await (f, o)
    faelle = loadedFaelle
    ordner = loadedOrdner
  } catch {
    self.error = error.localizedDescription
  }
}

@MainActor
func fallLoeschen(id: String) async throws {
  try await Services.cases.delete(id: id)
  faelle.removeAll { $0.id == id }
}

@MainActor
func ordnerErstellen(name: String) async throws {
  let ordner = CaseFolder(name: name)
  let created = try await Services.caseFolders.create(ordner)
  self.ordner.append(created)
}
}

// MARK: - Fall-Liste

struct CaseListView: View {
@State private var viewModel = CaseListViewModel()
@State private var selectedFallId: String? = nil
@State private var zeigeNeuerFall = false
@State private var ordnerSichtbar = true
@State private var faelleSichtbar = true
@EnvironmentObject var appState: AppState
@Environment(\.fenlynineOSFensterModus) private var fensterModus
@Environment(\.fenlynineOSVergleichSpalte) private var vergleichSpalte

private var hatAusgewaehltenFall: Bool {
 (selectedFallId ?? appState.selectedCaseId) != nil
}

private var ordnerBreite: CGFloat {
 if vergleichSpalte { return 0 }
 return fensterModus ? 150 : 176
}
private var fallListeBreite: CGFloat {
 if vergleichSpalte { return 200 }
 if fensterModus { return ordnerSichtbar ? 220 : 240 }
 return ordnerSichtbar ? 280 : 300
}

var body: some View {
 HStack(spacing: 0) {
   if ordnerSichtbar && !vergleichSpalte {
     OrdnerSidebar(viewModel: viewModel)
       .frame(width: ordnerBreite)
       .clipped()
     RevealDivider()
   }

   if faelleSichtbar {
     FallListe(
       viewModel: viewModel,
       selectedId: $selectedFallId,
       ordnerSichtbar: $ordnerSichtbar,
       faelleSichtbar: $faelleSichtbar
     )
     .frame(width: fallListeBreite)
     .clipped()
     RevealDivider()
   } else if hatAusgewaehltenFall && !vergleichSpalte {
     LexaraEinklappLeiste(
       symbol: "folder.fill",
       titel: "Mandate",
       anzahl: viewModel.gefilterteFaelle.count,
       onOeffnen: { withAnimation(.spring(duration: 0.28)) { faelleSichtbar = true } }
     )
     RevealDivider()
   }

   Group {
     if let id = selectedFallId ?? appState.selectedCaseId {
       VStack(spacing: 0) {
         // Immer wechselbar -- auch wenn die Mandate-Liste eingeklappt ist
         FenlynineOSEntitySwitcher(
           label: "Fall",
           symbol: "folder.fill",
           items: viewModel.gefilterteFaelle.compactMap { fall in
             guard let fid = fall.id else { return nil }
             return FenlynineOSEntityItem(
               id: fid,
               titel: fall.fallname,
               untertitel: fall.aktenzeichen ?? fall.rechtsgebiet,
               gruppe: fall.status.rawValue
             )
           },
           selectedId: Binding(
             get: { selectedFallId ?? appState.selectedCaseId },
             set: { neu in
               selectedFallId = neu
               appState.selectedCaseId = neu
             }
           ),
           onListe: {
             withAnimation(.spring(duration: 0.28)) { faelleSichtbar = true }
           },
           listenLabel: "Mandate"
         )
         CaseDetailView(
           caseId: id,
           faelleSichtbar: $faelleSichtbar,
           onMandateOeffnen: { withAnimation(.spring(duration: 0.28)) { faelleSichtbar = true } }
         )
         .id(id) // bei Wechsel komplett neu laden
       }
     } else {
       LexaraFallAuswahlPlatzhalter(
         faelleSichtbar: $faelleSichtbar,
         onNeuerFall: { zeigeNeuerFall = true }
       )
     }
   }
   .frame(maxWidth: .infinity, maxHeight: .infinity)
   .layoutPriority(1)
   .clipped()
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .clipped()
 // Im Fenstermodus keinen Window-Titel stehlen (sonst Vergleich/Modul-Titel kaputt)
 .navigationTitle(fensterModus ? "" : "Lexara -- Fallverwaltung")
 .toolbar { lexaraToolbar }
 .task { await viewModel.laden() }
 .onAppear {
   faelleSichtbar = true // Liste immer verfügbar -- Wechsel ohne Modul verlassen
   if fensterModus || vergleichSpalte {
     ordnerSichtbar = false
     faelleSichtbar = true
   }
 }
 .onChange(of: fensterModus) { _, aktiv in
   if aktiv {
     ordnerSichtbar = false
     faelleSichtbar = true
   }
 }
 .sheet(isPresented: $zeigeNeuerFall) {
   NeuerFallSheet(viewModel: viewModel, onCreated: { id in
     selectedFallId = id
   })
 }
 .onReceive(NotificationCenter.default.publisher(for: .navigateToCase)) { n in
   if let id = n.object as? String {
     selectedFallId = id
   }
 }
}

@ToolbarContentBuilder
private var lexaraToolbar: some ToolbarContent {
 ToolbarItemGroup(placement: .primaryAction) {
   Button {
     withAnimation(.spring(duration: 0.28)) { faelleSichtbar.toggle() }
   } label: {
     Label(faelleSichtbar ? "Mandate ausblenden" : "Mandate einblenden", systemImage: "sidebar.left")
   }

   Button {
     withAnimation(.spring(duration: 0.28)) { ordnerSichtbar.toggle() }
   } label: {
     Image(systemName: ordnerSichtbar ? "folder.fill" : "folder")
   }
   .help(ordnerSichtbar ? "Ordner ausblenden" : "Ordner einblenden")

   Menu {
     ForEach(CaseListViewModel.SortierOption.allCases, id: \.self) { option in
       Button(option.rawValue) { viewModel.sortierung = option }
     }
   } label: {
     Image(systemName: "arrow.up.arrow.down")
   }

   Menu {
     Button("Alle") { viewModel.statusFilter = nil }
     ForEach(LegalCase.CaseStatus.allCases, id: \.self) { status in
       Button(status.rawValue) { viewModel.statusFilter = status }
     }
   } label: {
     Image(systemName: viewModel.statusFilter != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
   }

   Button {
     NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.berufspflicht.rawValue)
   } label: {
     Image(systemName: "scalemass")
   }
   .help("Berufspflicht-Desk")

   Button {
     NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.konfliktRadar.rawValue)
   } label: {
     Image(systemName: "exclamationmark.shield")
   }
   .help("KonfliktRadar")

   Button {
     NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.mandatsPipeline.rawValue)
   } label: {
     Image(systemName: "arrow.triangle.branch")
   }
   .help("Mandats-Pipeline")

   VisionOSGlasButton(titel: "Neuer Fall", symbol: "plus", stil: .primaerBlau, kompakt: true) {
     zeigeNeuerFall = true
   }
 }
}
}

struct RevealDivider: View {
var body: some View {
 Rectangle()
   .fill(Color.white.opacity(0.08))
   .frame(width: 1)
}
}

struct LexaraEinklappLeiste: View {
let symbol: String
let titel: String
let anzahl: Int
let onOeffnen: () -> Void

var body: some View {
 VStack(spacing: 12) {
   Button(action: onOeffnen) {
     VStack(spacing: 6) {
       Image(systemName: symbol)
         .font(.system(size: 16, weight: .semibold))
       Text("\(anzahl)")
         .font(.system(size: 10, weight: .bold))
     }
     .foregroundStyle(FenlynineOSTheme.accent)
     .frame(width: 44)
     .padding(.vertical, 14)
   }
   .buttonStyle(.plain)
   .help("\(titel) ausklappen")
   Text(titel)
     .font(.system(size: 8, weight: .bold))
     .foregroundStyle(FenlynineOSTheme.textTertiary)
     .rotationEffect(.degrees(-90))
   Spacer()
 }
 .frame(width: 48)
 .background(.ultraThinMaterial.opacity(0.5))
}
}

struct LexaraFallAuswahlPlatzhalter: View {
@Binding var faelleSichtbar: Bool
let onNeuerFall: () -> Void

var body: some View {
 VStack(spacing: 24) {
   Image(systemName: "folder.badge.plus")
     .font(.system(size: 56))
     .foregroundStyle(FenlynineOSTheme.accent.opacity(0.7))
   Text("Lexara -- Mandatsverwaltung")
     .font(AppleUIKitTokens.title2)
   Text("Wählen Sie einen Fall oder legen Sie ein neues Mandat an.")
     .font(AppleUIKitTokens.callout)
     .foregroundStyle(.secondary)
     .multilineTextAlignment(.center)
   HStack(spacing: 12) {
     VisionOSPrimaerButton(titel: "Fallliste öffnen", symbol: "sidebar.left") {
       withAnimation { faelleSichtbar = true }
     }
     VisionOSSekundaerButton(titel: "Neuer Fall", symbol: "plus") { onNeuerFall() }
   }
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .padding(40)
}
}

// MARK: - Ordner-Seitenleiste

struct OrdnerSidebar: View {
@Bindable var viewModel: CaseListViewModel
@State private var zeigeNeuerOrdner = false
@State private var neuerOrdnerName = ""

var body: some View {
 List(selection: $viewModel.selectedOrdnerId) {
   Label("Alle Fälle (\(viewModel.faelle.count))", systemImage: "tray.2.fill")
     .tag(String?.none)

   Section("Ordner") {
     ForEach(viewModel.ordner) { ordner in
       HStack {
         Label(ordner.name, systemImage: ordner.symbol)
         Spacer()
         let ordnerId = ordner.id
         Text("\(viewModel.faelle.filter { $0.folder_id == ordnerId }.count)")
           .font(.caption2)
           .foregroundStyle(.secondary)
       }
       .tag(Optional(ordner.id ?? ""))
     }
     Button {
       zeigeNeuerOrdner = true
     } label: {
       Label("Ordner hinzufügen", systemImage: "folder.badge.plus")
         .font(.system(size: 12))
         .foregroundStyle(.blue)
     }
     .buttonStyle(.plain)
   }

   Section("Schnellfilter") {
     ForEach(LegalCase.CaseStatus.allCases, id: \.self) { status in
       Label(status.rawValue, systemImage: status.symbol)
         .tag(Optional("status_" + status.rawValue))
     }
   }
 }
 .listStyle(.sidebar)
 .scrollContentBackground(.hidden)
 .background(Color.clear)
 .alert("Neuer Ordner", isPresented: $zeigeNeuerOrdner) {
   TextField("Ordner-Name", text: $neuerOrdnerName)
   Button("Erstellen") {
     guard !neuerOrdnerName.isEmpty else { return }
     Task { try? await viewModel.ordnerErstellen(name: neuerOrdnerName) }
     neuerOrdnerName = ""
   }
   Button("Abbrechen", role: .cancel) {}
 }
}
}

// MARK: - Fall-Liste

struct FallListe: View {
let viewModel: CaseListViewModel
@Binding var selectedId: String?
@Binding var ordnerSichtbar: Bool
@Binding var faelleSichtbar: Bool
@Environment(\.fenlynineOSFensterModus) private var fensterModus

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Text("Mandate")
       .font(.system(size: 15, weight: .semibold))
       .foregroundStyle(MacOSSettingsTokens.title)
     Spacer()
     Text("\(viewModel.gefilterteFaelle.count)")
       .font(.system(size: 11, weight: .medium))
       .foregroundStyle(MacOSSettingsTokens.subtitle)
     if !fensterModus {
       Button {
         withAnimation(.spring(duration: 0.28)) { faelleSichtbar = false }
       } label: {
         Image(systemName: "xmark.circle.fill")
           .font(.system(size: 14, weight: .semibold))
       }
       .buttonStyle(.plain)
       .foregroundStyle(MacOSSettingsTokens.subtitle)
       .help("Fallliste einklappen -- mehr Platz für Fall")
     }
   }
   .padding(.horizontal, fensterModus ? 12 : 16)
   .padding(.vertical, 12)

   MacOSSettingsSearchField(text: Binding(
     get: { viewModel.suchtext },
     set: { viewModel.suchtext = $0 }
   ), placeholder: "Fälle suchen")
   .padding(.horizontal, fensterModus ? 8 : 12)
   .padding(.bottom, 10)

   if viewModel.isLoading {
     ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
   } else if viewModel.gefilterteFaelle.isEmpty {
     FallListePlatzhalter()
   } else {
     ScrollView {
       if fensterModus {
         // Flache Liste -- keine „schwebende" Grouped-Karte im Fenster
         LazyVStack(spacing: 0) {
           ForEach(viewModel.gefilterteFaelle) { fall in
             FallListenKarte(
               fall: fall,
               isSelected: selectedId == fall.id
             ) {
               withAnimation(.spring(duration: 0.22)) {
                 selectedId = fall.id
               }
             }
             Divider().overlay(Premium.hairline)
           }
         }
         .padding(.horizontal, 4)
       } else {
         MacOSSettingsGroupedList(titel: "Fälle") {
           ForEach(Array(viewModel.gefilterteFaelle.enumerated()), id: \.element.id) { index, fall in
             FallListenKarte(
               fall: fall,
               isSelected: selectedId == fall.id
             ) {
               withAnimation(.spring(duration: 0.22)) {
                 selectedId = fall.id
               }
             }
             if index < viewModel.gefilterteFaelle.count - 1 {
               MacOSSettingsGroupDivider()
             }
           }
         }
         .padding(12)
       }
     }
   }
 }
 .scrollContentBackground(.hidden)
 .background(fensterModus ? Premium.ink : Color.clear)
}
}

struct FallListenKarte: View {
let fall: LegalCase
let isSelected: Bool
let action: () -> Void

private var untertitel: String {
 var parts: [String] = []
 if let az = fall.aktenzeichen { parts.append(az) }
 parts.append(fall.status.rawValue)
 if let rg = fall.rechtsgebiet { parts.append(rg) }
 if let p = fall.prognose { parts.append("\(Int(p))% Prognose") }
 return parts.joined(separator: " · ")
}

var body: some View {
 Button(action: action) {
   MacOSSettingsDeviceRow(
     symbol: fallIconSymbol,
     iconColor: fallIconColor,
     titel: fall.fallname.replacingOccurrences(of: "[Demo] ", with: ""),
     untertitel: untertitel,
     isSelected: isSelected
   )
   .frame(maxWidth: .infinity, alignment: .leading)
   .contentShape(Rectangle())
 }
 .buttonStyle(.plain)
 .contentShape(Rectangle())
}

private var fallIconSymbol: String {
 if fall.fallname.hasPrefix("[Demo]") { return "star.fill" }
 switch fall.status {
 case .aktiv: return "folder.fill"
 case .vorbereitung: return "doc.badge.clock"
 case .abgeschlossen: return "checkmark.folder.fill"
 case .ruhend: return "pause.circle.fill"
 }
}

private var fallIconColor: Color {
 switch fall.status {
 case .aktiv: return MacOSSettingsTokens.selectionBlue
 case .vorbereitung: return Color(red: 1.0, green: 0.55, blue: 0.2)
 case .abgeschlossen: return Color(white: 0.5)
 case .ruhend: return Color(red: 1.0, green: 0.75, blue: 0.2)
 }
}
}

struct FallListenZeile: View {
let fall: LegalCase

var body: some View {
 HStack(spacing: 12) {
   if fall.fallname.hasPrefix("[Demo]") {
     Image(systemName: "star.fill")
       .font(.caption2)
       .foregroundStyle(FenlynineOSTheme.accent)
   }
   VStack(alignment: .leading, spacing: 4) {
     Text(fall.fallname)
       .font(.system(size: 13, weight: .semibold))
       .lineLimit(2)

     HStack(spacing: 6) {
       if let az = fall.aktenzeichen {
         Text(az)
           .font(.caption2)
           .foregroundStyle(.secondary)
       }
       if let rg = fall.rechtsgebiet {
         Text(rg)
           .font(.caption2)
           .foregroundStyle(FenlynineOSDesign.accent)
           .padding(.horizontal, 6)
           .padding(.vertical, 2)
           .background(FenlynineOSDesign.accent.opacity(0.08), in: Capsule())
       }
     }

     HStack(spacing: 4) {
       Image(systemName: fall.status.symbol)
         .font(.system(size: 9))
       Text(fall.status.rawValue)
         .font(.caption2)
     }
     .foregroundStyle(statusFarbe)
   }

   Spacer()

   if let prognose = fall.prognose {
     FenlynineOSPrognoseRing(wert: Int(prognose), groesse: 40)
   }
 }
 .padding(.vertical, 6)
 .padding(.horizontal, 4)
}

private var statusFarbe: Color {
 switch fall.status {
 case .aktiv: return .green
 case .vorbereitung: return .blue
 case .abgeschlossen: return .gray
 case .ruhend: return .orange
 }
}
}

struct PrognoseBadge: View {
let prognose: Int

var body: some View {
 Text("\(prognose)%")
   .font(.system(size: 12, weight: .bold, design: .rounded))
   .foregroundStyle(.white)
   .padding(.horizontal, 8)
   .padding(.vertical, 4)
   .background(farbe, in: Capsule())
}

private var farbe: Color {
 if prognose >= 65 { return .green }
 else if prognose >= 45 { return .orange }
 else { return .red }
}
}

struct FallListePlatzhalter: View {
var body: some View {
 VStack(spacing: 12) {
   Image(systemName: "folder")
     .font(.system(size: 40))
     .foregroundStyle(.tertiary)
   Text("Keine Fälle gefunden")
     .font(.headline)
     .foregroundStyle(.secondary)
   Text("Erstellen Sie einen neuen Fall oder passen Sie den Filter an.")
     .font(.subheadline)
     .foregroundStyle(.tertiary)
     .multilineTextAlignment(.center)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .padding(32)
}
}

struct FallDetailPlatzhalter: View {
var body: some View {
 VStack(spacing: 16) {
   Image(systemName: "cursorarrow.click.2")
     .font(.system(size: 48))
     .foregroundStyle(.tertiary)
   Text("Fall auswählen")
     .font(.title2)
     .foregroundStyle(.secondary)
   Text("Wählen Sie einen Fall aus der Liste, um die Details anzuzeigen.")
     .font(.subheadline)
     .foregroundStyle(.tertiary)
     .multilineTextAlignment(.center)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

// MARK: - Neuer Fall Sheet

struct NeuerFallSheet: View {
let viewModel: CaseListViewModel
let onCreated: (String) -> Void

@Environment(\.dismiss) var dismiss
@State private var fallname = ""
@State private var rechtsgebietAuswahl = LexaraRechtsgebietAuswahl()
@State private var gericht = ""
@State private var aktenzeichen = ""
@State private var mandant = ""
@State private var status = LegalCase.CaseStatus.vorbereitung
@State private var instanz = LegalCase.Instanz.erstinstanz
@State private var streitwert = ""
@State private var isCreating = false
@State private var error: String?

var body: some View {
 VStack(spacing: 0) {
   // Header
   HStack {
     Image(systemName: "folder.badge.plus")
       .font(.system(size: 20, weight: .semibold))
       .foregroundStyle(.blue)
     Text("Neuen Fall anlegen")
       .font(.title3.bold())
     Spacer()
     Button("Abbrechen") { dismiss() }
       .keyboardShortcut(.escape)
   }
   .padding(20)

   Divider()

   ScrollView {
     Form {
       Section("Pflichtfelder") {
         TextField("Fallname *", text: $fallname)
         Picker("Status", selection: $status) {
           ForEach(LegalCase.CaseStatus.allCases, id: \.self) {
             Text($0.rawValue).tag($0)
           }
         }
       }

       Section("Falldetails") {
         TextField("Aktenzeichen", text: $aktenzeichen)
         TextField("Gericht", text: $gericht)
         Picker("Instanz", selection: $instanz) {
           ForEach(LegalCase.Instanz.allCases, id: \.self) {
             Text($0.rawValue).tag($0)
           }
         }
         TextField("Mandant", text: $mandant)
         TextField("Streitwert (€)", text: $streitwert)
           .onChange(of: streitwert) { _, new in
             streitwert = new.filter { $0.isNumber || $0 == "." }
           }
       }

       Section("Rechtsgebiete") {
         LexaraRechtsgebietPickerView(
           auswahl: $rechtsgebietAuswahl,
           bearbeitung: true
         )
       }

       if let error {
         Section {
           Label(error, systemImage: "exclamationmark.triangle")
             .foregroundStyle(.red)
         }
       }
     }
     .formStyle(.grouped)
     .padding(.horizontal, 8)
   }

   Divider()

   HStack {
     Spacer()
     Button("Erstellen") {
       Task { await erstellen() }
     }
     .keyboardShortcut(.return, modifiers: .command)
     .disabled(fallname.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   }
   .padding(16)
 }
 .frame(width: 520, height: 720)
}

private func erstellen() async {
 isCreating = true
 defer { isCreating = false }
 error = nil

 var fall = LegalCase(fallname: fallname.trimmingCharacters(in: .whitespaces))
 fall.status = status
 fall.instanz = instanz
 if !aktenzeichen.isEmpty { fall.aktenzeichen = aktenzeichen }
 if !rechtsgebietAuswahl.istLeer { fall.applyRechtsgebietAuswahl(rechtsgebietAuswahl) }
 if !gericht.isEmpty { fall.gericht = gericht }
 if !mandant.isEmpty { fall.mandant_name = mandant }
 if let sw = Double(streitwert) { fall.streitwert = sw }

 do {
   let created = try await Services.cases.create(fall)
   await MainActor.run {
     viewModel.faelle.insert(created, at: 0)
     if let id = created.id { onCreated(id) }
     dismiss()
   }
 } catch {
   await MainActor.run { self.error = error.localizedDescription }
 }
}
}

