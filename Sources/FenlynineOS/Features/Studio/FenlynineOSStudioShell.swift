import SwiftUI
import FenlynineOSKern
enum StudioZone: String, CaseIterable, Identifiable {
case vorgaenge
case lage
case organon
case werkzeuge
case wissen
case einstellungen
var id: String { rawValue }
var titel: String {
  switch self {
  case .vorgaenge: return "Vorgänge"
  case .lage: return "Lagezentrale"
  case .organon: return "Team & Netzwerk"
  case .werkzeuge: return "Alle Module"
  case .wissen: return "Rechtswissen"
  case .einstellungen: return "Einstellungen"
  }
}
var railLabel: String {
  switch self {
  case .vorgaenge: return "Vorgänge"
  case .lage: return "Lage"
  case .organon: return "Team"
  case .werkzeuge: return "Module"
  case .wissen: return "Wissen"
  case .einstellungen: return "System"
  }
}
var railHilfe: String {
  switch self {
  case .vorgaenge: return "Vorgänge -- der Startpunkt: Akten anlegen, bewerten, entscheiden"
  case .lage: return "Lagezentrale -- Mandate, Konflikte, Pipeline und Fristen in einem Blick"
  case .organon: return "Team & Netzwerk (Organon) -- wer macht was"
  case .werkzeuge: return "Alle Module -- jede Funktion der Suite, durchsuchbar an einem Ort"
  case .wissen: return "Rechtswissen -- lokaler Wissenskorpus des Rechtsradars"
  case .einstellungen: return "Einstellungen -- Konto, Design, KI, Daten und System"
  }
}
var symbol: String {
  switch self {
  case .vorgaenge: return "square.stack.3d.up.fill"
  case .lage: return "rectangle.3.group.bubble.left.fill"
  case .organon: return "point.3.connected.trianglepath.dotted"
  case .werkzeuge: return "wrench.and.screwdriver.fill"
  case .wissen: return "books.vertical.fill"
  case .einstellungen: return "gearshape.fill"
  }
}
var appleSymbol: String {
  switch self {
  case .vorgaenge: return "star"
  case .lage: return "dot.radiowaves.left.and.right"
  case .organon: return "person.2"
  case .werkzeuge: return "square.grid.2x2"
  case .wissen: return "book"
  case .einstellungen: return "gearshape"
  }
}
}
struct FenlynineOSStudioShell: View {
@EnvironmentObject var authManager: AuthManager
@EnvironmentObject var appState: AppState
@Bindable private var appearance = AppearanceStore.shared
@ObservedObject private var kontoStore = KontoStore.shared
@ObservedObject private var arbeitsfluss = ArbeitsflussDienst.shared
var onZurueckZumHub: (() -> Void)? = nil
@State private var zone: StudioZone = .vorgaenge
@State private var offenerVorgangId: UUID?
@State private var kommandofeldOffen = false
@State private var werkzeug: SeitenleistenEintrag = .lexara
@State private var railEingeklappt = false
@State private var zeigeTutorial = false
@State private var showInspector = true
@State private var werkzeugFilter = ""
/// Apple-Ansicht: false = App-Store-Startseite ("Entdecken"), true = ein Modul ist geöffnet.
@State private var appleModulOffen = false
/// Apple-Ansicht: geöffnete Kategorie-Seite (nil = Startseite "Heute").
@State private var appleKategorie: NavKategorie?
@AppStorage("fenlynineos_einstellungen_tab") private var einstellungenTab = "ki"
private var istApple: Bool { appearance.istApple }
var body: some View {
  HStack(spacing: 0) {
    if istApple { appleRail } else { classicRail }
    VStack(spacing: 0) {
      if istApple { appleTopBar } else { classicTopBar }
      Divider().overlay(istApple ? Color.white.opacity(0.08) : Premium.hairline)
      zoneInhalt
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    if showInspector {
      StudioInspektor(
        onNavigiere: navigiereZuWerkzeug,
        onOeffneFenster: oeffneModulFenster
      )
    }
  }
  .background {
    if istApple { StoreCanvasBackground() } else { PremiumAurora() }
  }
  .fenlynineOSAppearance()
  .sheet(isPresented: $kommandofeldOffen) {
    Kommandofeld { v in
      zone = .vorgaenge
      offenerVorgangId = v.id
    }
    .presentationBackground(.clear)
  }
  .sheet(isPresented: $zeigeTutorial) {
    TutorialView(onFertig: { zeigeTutorial = false })
      .presentationBackground(.clear)
  }
  .onAppear {
    VorgangStore.shared.kernStore = FenlynineOSKernStore.shared
    Task(priority: .utility) { spiegleAlleVorgaenge() }
    if !RechtsradarAgent.shared.laeuft {
      RechtsradarAgent.shared.starten()
    }
    Task { await ArbeitsflussDienst.shared.aktualisieren() }
    if zone == .werkzeuge && werkzeug == .schreibtisch {
      showInspector = false
   }
   if let raw = UserDefaults.standard.string(forKey: "fenlynineos_pending_sidebar"),
    let e = SeitenleistenEintrag(rawValue: raw) {
     UserDefaults.standard.removeObject(forKey: "fenlynineos_pending_sidebar")
     DispatchQueue.main.async {
       navigiereZuWerkzeug(e)
     }
   }
 }
 .onChange(of: werkzeug) { _, neu in
   if zone == .werkzeuge && neu == .schreibtisch {
     withAnimation(.easeOut(duration: 0.15)) { showInspector = false }
   }
 }
 .onReceive(NotificationCenter.default.publisher(for: .oeffneKommandofeld)) { _ in
   kommandofeldOffen = true
 }
 .onReceive(NotificationCenter.default.publisher(for: .oeffneUpdatePanel)) { _ in
   zone = .einstellungen
   einstellungenTab = "updates"
 }
 .onReceive(NotificationCenter.default.publisher(for: .navigateToSidebar)) { note in
   if let raw = note.object as? String, let e = SeitenleistenEintrag(rawValue: raw) {
     navigiereZuWerkzeug(e)
   }
 }
 .onReceive(NotificationCenter.default.publisher(for: .oeffneTutorial)) { _ in
   zeigeTutorial = true
 }
 // Diese drei Nachrichten hatten bisher nur in der nicht mehr angezeigten
 // AppShell einen Empfänger -- Menü und Menüleiste liefen dadurch ins Leere.
 .onReceive(NotificationCenter.default.publisher(for: .neuerVorgang)) { _ in
   neuerVorgang()
 }
 .onReceive(NotificationCenter.default.publisher(for: .oeffneVorgang)) { note in
   guard let id = note.object as? UUID, VorgangStore.shared.vorgang(id) != nil else { return }
   zone = .vorgaenge
   offenerVorgangId = id
 }
 .onReceive(NotificationCenter.default.publisher(for: .oeffneKategorie)) { note in
   guard let raw = note.object as? String, let k = NavKategorie(rawValue: raw) else { return }
   if istApple {
     waehle(.kategorie(k))
   } else if let erstes = k.module(istAdmin: kontoStore.istAdmin).first {
     navigiereZuWerkzeug(erstes)
   }
 }
 .onReceive(NotificationCenter.default.publisher(for: .createNewCase)) { _ in
   appState.neuerFallAngefordert = true
   navigiereZuWerkzeug(.lexara)
 }
 .onReceive(NotificationCenter.default.publisher(for: .navigateToCase)) { note in
   guard let id = note.object as? String, !id.isEmpty else { return }
   appState.selectedCaseId = id
   navigiereZuWerkzeug(.lexara)
 }
}
private func navigiereZuWerkzeug(_ e: SeitenleistenEintrag) {
 if e == .vorgaenge {
   zone = .vorgaenge
 } else if e == .einstellungen {
   zone = .einstellungen
 } else if e == .organon {
   zone = .organon
 } else if e == .lageZentrale {
   zone = .lage
 } else if e == .opportunisma {
   zone = .werkzeuge
   werkzeug = .opportunisma
 } else {
   zone = .werkzeuge
   werkzeug = e
 }
 if zone == .werkzeuge { appleModulOffen = true }
 appleKategorie = e.navKategorie
 if e == .schreibtisch || e == .opportunisma {
   withAnimation(.easeOut(duration: 0.15)) { showInspector = false }
 }
}
private func neuerVorgang() {
 let v = VorgangStore.shared.neu(typ: .streit, titel: "Neuer Vorgang")
 zone = .vorgaenge
 offenerVorgangId = v.id
 Task(priority: .utility) { spiegle(v) }
}
private func oeffneModulFenster(_ e: SeitenleistenEintrag) {
 ModulFensterHost.shared.oeffneModul(e)
 ModulFensterBridge.installieren()
}
private var fensterZiel: SeitenleistenEintrag? {
 switch zone {
 case .vorgaenge: return .vorgaenge
 case .lage: return .lageZentrale
 case .organon: return .organon
 case .werkzeuge: return (istApple && !appleModulOffen) ? nil : werkzeug
 case .wissen: return nil
 case .einstellungen: return .einstellungen
 }
}
private var appleRail: some View {
  AppleSeitenleiste(
    auswahl: appleAuswahl,
    suchtext: $werkzeugFilter,
    istAdmin: kontoStore.istAdmin,
    hinweise: { k in
      let ids = Set(k.module(istAdmin: true).map(\.rawValue))
      return arbeitsfluss.schritte.filter { ids.contains($0.modulId) && $0.dringlichkeit == .kritisch }.count
    },
    dringendGesamt: arbeitsfluss.schritte.filter { $0.dringlichkeit == .kritisch }.count,
    profilName: profilName,
    profilInitialen: profilInitialen,
    onWaehle: waehle,
    onSuche: { kommandofeldOffen = true },
    onHilfe: { zeigeTutorial = true }
  )
  .onChange(of: werkzeugFilter) { _, neu in
    if !neu.trimmingCharacters(in: .whitespaces).isEmpty {
      zone = .werkzeuge
      appleModulOffen = false
      appleKategorie = nil
    }
  }
}
/// Was in der Apple-Seitenleiste markiert ist -- abgeleitet aus dem Zustand,
/// damit Seitenleiste, Menü und Kommandofeld nie auseinanderlaufen.
private var appleAuswahl: AppleZiel {
  switch zone {
  case .vorgaenge: return .modul(.vorgaenge)
  case .lage: return .modul(.lageZentrale)
  case .organon: return .modul(.organon)
  case .einstellungen: return .modul(.einstellungen)
  case .wissen: return .wissen
  case .werkzeuge:
    if appleModulOffen { return .modul(werkzeug) }
    return appleKategorie.map(AppleZiel.kategorie) ?? .heute
  }
}
private func waehle(_ ziel: AppleZiel) {
  werkzeugFilter = ""
  switch ziel {
  case .heute:
    zone = .werkzeuge
    appleModulOffen = false
    appleKategorie = nil
  case let .kategorie(k):
    zone = .werkzeuge
    appleModulOffen = false
    appleKategorie = k
  case let .modul(e):
    if e == .vorgaenge { offenerVorgangId = nil }
    navigiereZuWerkzeug(e)
  case .wissen:
    zone = .wissen
  }
}
private var profilName: String {
  let n = authManager.userName.trimmingCharacters(in: .whitespacesAndNewlines)
  return n.isEmpty ? "FenlynineOS" : n
}
private var profilInitialen: String {
  let parts = profilName.split(whereSeparator: { !$0.isLetter }).filter { !$0.isEmpty }.prefix(2)
  let ini = parts.compactMap { $0.first.map(String.init) }.joined()
  return ini.isEmpty ? "FO" : ini.uppercased()
}
private var classicRail: some View {
 VStack(spacing: 4) {
   Button {
     onZurueckZumHub?()
   } label: {
       Text("JI")
       .font(.system(size: 13, weight: .black, design: .rounded))
       .foregroundStyle(Premium.action)
       .frame(width: 40, height: 36)
   }
   .buttonStyle(.plain)
   .help("FenlynineOS Legal Suite -- Hauptmenü (Hub)")
   .padding(.top, 8)
   ForEach(StudioZone.allCases) { z in
     Button {
       zone = z
       if z == .vorgaenge { offenerVorgangId = nil }
     } label: {
       VStack(spacing: 3) {
         Image(systemName: z.symbol)
           .font(.system(size: 14, weight: .semibold))
         Text(z.railLabel)
           .font(.system(size: 8.5, weight: .semibold))
           .lineLimit(1)
           .minimumScaleFactor(0.8)
       }
       .foregroundStyle(zone == z ? (appearance.istAtelier ? Premium.action : .white) : Premium.textSoft)
       .frame(width: 60, height: 46)
       .background(
         RoundedRectangle(cornerRadius: 9, style: .continuous)
           .fill(zone == z ? Premium.action.opacity(appearance.istAtelier ? 0.12 : 0.28) : Color.clear)
       )
       .overlay(
         RoundedRectangle(cornerRadius: 9, style: .continuous)
           .stroke(zone == z ? Premium.action.opacity(0.45) : Color.clear, lineWidth: 1)
       )
     }
     .buttonStyle(.plain)
     .help(z.railHilfe)
   }
   Spacer()
   Button { zeigeTutorial = true } label: {
     VStack(spacing: 3) {
       Image(systemName: "questionmark.circle")
         .font(.system(size: 14, weight: .semibold))
       Text("Hilfe")
         .font(.system(size: 8.5, weight: .semibold))
     }
   }
   .foregroundStyle(Premium.textSoft)
   .frame(width: 60, height: 44)
   .buttonStyle(.plain)
   .help("Tutorial -- Bedienung Schritt für Schritt")
   Button { kommandofeldOffen = true } label: {
     VStack(spacing: 3) {
       Image(systemName: "magnifyingglass")
         .font(.system(size: 13, weight: .semibold))
       Text("Suchen")
         .font(.system(size: 8.5, weight: .semibold))
     }
     .foregroundStyle(Premium.textSoft)
     .frame(width: 60, height: 44)
   }
   .buttonStyle(.plain)
   .help("Alles finden: Funktionen, Befehle, Vorgänge -- ⌘K")
   .padding(.bottom, 10)
 }
 .frame(width: 68)
 .padding(.vertical, 6)
 .premiumGlasLeiste()
 .overlay(alignment: .trailing) {
   Rectangle().fill(Premium.hairline).frame(width: 1)
 }
}
private var appleTopBar: some View {
  HStack(spacing: 10) {
    if zone == .vorgaenge, let id = offenerVorgangId,
       let v = VorgangStore.shared.vorgang(id) {
      Button(action: { offenerVorgangId = nil }) {
        Image(systemName: "chevron.left")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(Store.accent)
      }
      .buttonStyle(.plain)
      Text(v.titel)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Store.text)
        .lineLimit(1)
    }
    if zone == .werkzeuge && appleModulOffen {
      Button(action: {
        appleKategorie = werkzeug.navKategorie
        appleModulOffen = false
      }) {
        HStack(spacing: 4) {
          Image(systemName: "chevron.left")
            .font(.system(size: 13, weight: .semibold))
          Text(werkzeug.navKategorie.titel)
            .font(.system(size: 13, weight: .regular))
        }
        .foregroundStyle(Store.accent)
      }
      .buttonStyle(.plain)
      .keyboardShortcut("[", modifiers: [.command])
      .help("Zurück zur Übersicht „\(werkzeug.navKategorie.titel)“ · ⌘[")
      Text(werkzeug.bezeichnung)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Store.text)
        .lineLimit(1)
    }
    Spacer()
    KIPruefsiegelButton()
    AppearanceToggle()
    StorePillButton(titel: "Fenster", action: {
      if let ziel = fensterZiel { oeffneModulFenster(ziel) }
    })
    .opacity(fensterZiel == nil ? 0.35 : 1)
    .disabled(fensterZiel == nil)
    StorePillButton(titel: "Vergleich") {
      ModulFensterHost.shared.oeffneVergleich()
    }
    Button {
      withAnimation(.easeOut(duration: 0.15)) { showInspector.toggle() }
    } label: {
      Image(systemName: "sidebar.right")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(showInspector ? Store.accent : Store.textSecondary)
        .frame(width: 28, height: 28)
        .background(Circle().fill(Store.pillFill))
    }
    .buttonStyle(.plain)
    if zone == .vorgaenge && offenerVorgangId == nil {
      StorePillButton(titel: "Neu", prominent: true) { neuerVorgang() }
        .help("Neuer Vorgang · ⌘N")
    }
  }
  .padding(.horizontal, 20)
  .padding(.vertical, 10)
  .background(Store.canvas)
}
private var classicTopBar: some View {
 HStack(spacing: 12) {
   Text(zone.titel)
     .font(.system(size: 13, weight: .semibold))
     .foregroundStyle(Premium.text)
   if zone == .vorgaenge, let id = offenerVorgangId,
    let v = VorgangStore.shared.vorgang(id) {
     Image(systemName: "chevron.right")
       .font(.system(size: 9, weight: .bold))
       .foregroundStyle(Premium.textFaint)
     Text(v.titel)
       .font(.system(size: 13, weight: .medium))
       .foregroundStyle(Premium.textSoft)
       .lineLimit(1)
   }
   Spacer()
   KIPruefsiegelButton()
   AppearanceToggle()
   Button {
     if let ziel = fensterZiel {
       oeffneModulFenster(ziel)
     }
   } label: {
     Label("Fenster", systemImage: "macwindow")
       .font(.system(size: 11, weight: .semibold))
       .foregroundStyle(fensterZiel == nil ? Premium.textFaint : Premium.text)
       .padding(.horizontal, 10).padding(.vertical, 6)
       .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action.opacity(fensterZiel == nil ? 0.05 : 0.12)))
       .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.action.opacity(fensterZiel == nil ? 0.15 : 0.35), lineWidth: 1))
   }
   .buttonStyle(.plain)
   .disabled(fensterZiel == nil)
   .help(fensterZiel == nil
      ? "Rechtswissen bleibt in Studio -- kein separates Modul-Fenster"
      : "Aktuelles Modul als eigenes Fenster -- Menü: Fenster · Module · ⌥⌘1–5")
   Button {
     ModulFensterHost.shared.oeffneVergleich()
   } label: {
     Label("Vergleich", systemImage: "rectangle.split.3x1")
       .font(.system(size: 11, weight: .medium))
       .foregroundStyle(Premium.textSoft)
       .padding(.horizontal, 10).padding(.vertical, 6)
       .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
       .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.hairline, lineWidth: 1))
   }
   .buttonStyle(.plain)
   .help("2–3 Module nebeneinander · ⌥⌘V")
   Button {
     withAnimation(.easeOut(duration: 0.15)) { showInspector.toggle() }
   } label: {
     Image(systemName: "sidebar.right")
       .font(.system(size: 12, weight: .medium))
       .foregroundStyle(showInspector ? Premium.action : Premium.textSoft)
       .frame(width: 28, height: 28)
       .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
   }
   .buttonStyle(.plain)
   .help("Inspektor ein-/ausblenden")
   Button {
     kommandofeldOffen = true
   } label: {
     HStack(spacing: 6) {
       Image(systemName: "magnifyingglass")
       Text("Suchen")
       Text("⌘K")
         .font(.system(size: 10, weight: .semibold, design: .monospaced))
         .padding(.horizontal, 5).padding(.vertical, 2)
         .background(RoundedRectangle(cornerRadius: 4).fill(Premium.well))
     }
     .font(.system(size: 11, weight: .medium))
     .foregroundStyle(Premium.textSoft)
     .padding(.horizontal, 10).padding(.vertical, 6)
     .background(RoundedRectangle(cornerRadius: 7).fill(Premium.panel))
     .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.hairline, lineWidth: 1))
   }
   .buttonStyle(.plain)
   if zone == .vorgaenge && offenerVorgangId == nil {
     Button {
       neuerVorgang()
     } label: {
       HStack(spacing: 4) {
         Image(systemName: "plus")
         Text("Neu")
       }
       .font(.system(size: 11, weight: .semibold))
       .foregroundStyle(Premium.onAction)
       .padding(.horizontal, 12).padding(.vertical, 6)
       .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action))
     }
     .buttonStyle(.plain)
   }
 }
 .padding(.horizontal, 16)
 .padding(.vertical, 10)
 .premiumGlasLeiste()
}
@ViewBuilder
private var zoneInhalt: some View {
 switch zone {
 case .vorgaenge:
   if let id = offenerVorgangId {
     StudioVorgangHost(vorgangId: id, onZurueck: { offenerVorgangId = nil })
       .background(istApple ? Store.canvas : Color.clear)
   } else {
     StudioVorgangListe(onOeffnen: { id in
       offenerVorgangId = id
       if let v = VorgangStore.shared.vorgang(id) {
         Task(priority: .utility) { spiegle(v) }
       }
     })
   }
 case .lage:
   if kontoStore.darf(.lageZentrale) {
     ImperiumLageZentraleView()
       .padding(istApple ? 16 : 8)
       .background(istApple ? Store.canvas : Color.clear)
   } else {
     AboGateView(eintrag: .lageZentrale)
   }
 case .organon:
   if kontoStore.darf(.organon) {
     OrganonView()
       .clipShape(RoundedRectangle(cornerRadius: istApple ? 14 : 12, style: .continuous))
       .padding(istApple ? 16 : 10)
       .background(istApple ? Store.canvas : Color.clear)
   } else {
     AboGateView(eintrag: .organon)
   }
 case .werkzeuge:
   if istApple { appleWerkzeugPanel } else { classicWerkzeugPanel }
 case .wissen:
   RechtswissenPanel()
     .background(istApple ? Store.canvas : Color.clear)
 case .einstellungen:
   EinstellungenView()
     .padding(istApple ? 16 : 10)
     .background(istApple ? Store.canvas : Color.clear)
 }
}
private var appleWerkzeugPanel: some View {
  Group {
    if appleModulOffen {
      ModulInhalt(eintrag: werkzeug)
        .id(werkzeug)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(Store.canvas)
    } else if let k = appleKategorie {
      KategorieSeite(
        kategorie: k,
        istAdmin: kontoStore.istAdmin,
        darf: { kontoStore.darf($0) },
        onOeffnen: { waehle(.modul($0)) },
        onFenster: oeffneModulFenster
      )
      .id(k)
    } else {
      AppStoreStartseite(
        regale: NavKategorie.allCases.map {
          AppStoreRegal(titel: $0.titel, eintraege: $0.module(istAdmin: kontoStore.istAdmin), kategorie: $0)
        },
        onKategorie: { waehle(.kategorie($0)) },
        suchtext: werkzeugFilter,
        darf: { kontoStore.darf($0) },
        onOeffnen: { e in
          werkzeugFilter = ""
          navigiereZuWerkzeug(e)
        },
        onFenster: oeffneModulFenster,
        onSchritt: oeffneArbeitsschritt
      )
    }
  }
}
/// Öffnet die Akte eines Arbeitsschritts im Modul, in dem er erledigt wird.
private func oeffneArbeitsschritt(_ schritt: Arbeitsschritt) {
  appState.selectedCaseId = schritt.akteId
  navigiereZuWerkzeug(SeitenleistenEintrag(rawValue: schritt.modulId) ?? .lexara)
}
private var classicWerkzeugPanel: some View {
 HStack(spacing: 0) {
   VStack(spacing: 0) {
     HStack(spacing: 6) {
       Image(systemName: "magnifyingglass")
         .font(.system(size: 10))
         .foregroundStyle(Premium.textFaint)
       TextField("Module filtern…", text: $werkzeugFilter)
         .textFieldStyle(.plain)
         .font(.system(size: 11))
     }
     .padding(.horizontal, 10)
     .padding(.vertical, 7)
     .background(RoundedRectangle(cornerRadius: 7).fill(Premium.well))
     .padding(10)
     ScrollView {
       VStack(alignment: .leading, spacing: 2) {
         ForEach(werkzeugSektionen, id: \.titel) { sektion in
           let items = gefilterteWerkzeuge(sektion.items)
           if !items.isEmpty {
             Text(sektion.titel.uppercased())
               .font(.system(size: 9, weight: .bold))
               .kerning(0.7)
               .foregroundStyle(Premium.textFaint)
               .padding(.horizontal, 12)
               .padding(.top, 10)
               .padding(.bottom, 4)
             ForEach(items, id: \.self) { e in
               HStack(spacing: 4) {
                 Button {
                   werkzeug = e
                 } label: {
                   HStack(alignment: .top, spacing: 8) {
                     Image(systemName: e.symbol)
                       .font(.system(size: 11))
                       .frame(width: 16)
                       .padding(.top, 1)
                     VStack(alignment: .leading, spacing: 1) {
                       Text(e.bezeichnung)
                         .font(.system(size: 12, weight: .medium))
                         .lineLimit(1)
                       if let sub = e.commandSubtitle {
                         Text(sub)
                           .font(.system(size: 9.5))
                           .foregroundStyle(werkzeug == e ? (appearance.istAtelier ? Premium.action.opacity(0.75) : Premium.onAction.opacity(0.75)) : Premium.textFaint)
                           .lineLimit(1)
                       }
                     }
                     Spacer()
                     if !kontoStore.darf(e) {
                       AboFensterSperrBadge(eintrag: e)
                     }
                   }
                   .foregroundStyle(werkzeug == e ? (appearance.istAtelier ? Premium.action : Premium.onAction) : Premium.textSoft)
                   .padding(.horizontal, 10)
                   .padding(.vertical, 6)
                   .background(
                     RoundedRectangle(cornerRadius: 8)
                       .fill(werkzeug == e ? Premium.action.opacity(appearance.istAtelier ? 0.12 : 0.22) : Color.clear)
                   )
                 }
                 .buttonStyle(.plain)
                 .contextMenu {
                   Button("Als Fenster öffnen") { oeffneModulFenster(e) }
                   Button("Vergleichsfenster") { ModulFensterHost.shared.oeffneVergleich() }
                 }
                 Button {
                   oeffneModulFenster(e)
                 } label: {
                   Image(systemName: "macwindow")
                     .font(.system(size: 11, weight: .semibold))
                     .foregroundStyle(Premium.action)
                     .frame(width: 28, height: 28)
                     .background(RoundedRectangle(cornerRadius: 6).fill(Premium.action.opacity(0.10)))
                 }
                 .buttonStyle(.plain)
                 .help("Als Fenster öffnen")
               }
               .padding(.horizontal, 6)
             }
           }
         }
       }
       .padding(.bottom, 20)
     }
   }
   .frame(width: 292)
   .premiumGlasLeiste()
   .overlay(alignment: .trailing) {
     Rectangle().fill(Premium.hairline).frame(width: 1)
   }
   ModulInhalt(eintrag: werkzeug)
     .frame(maxWidth: .infinity, maxHeight: .infinity)
 }
}
private struct WerkzeugSektion {
 let titel: String
 let items: [SeitenleistenEintrag]
}
private var werkzeugSektionen: [WerkzeugSektion] {
 // Dieselbe Ordnung wie Seitenleiste und Startseite der Apple-Ansicht.
 NavKategorie.allCases.map {
   WerkzeugSektion(titel: $0.titel, items: $0.module(istAdmin: kontoStore.istAdmin))
 }
}
private func gefilterteWerkzeuge(_ items: [SeitenleistenEintrag]) -> [SeitenleistenEintrag] {
 let q = werkzeugFilter.trimmingCharacters(in: .whitespaces).lowercased()
 guard !q.isEmpty else { return items }
 return items.filter {
   $0.bezeichnung.lowercased().contains(q)
     || $0.commandLabel.lowercased().contains(q)
     || ($0.commandSubtitle?.lowercased().contains(q) ?? false)
 }
}
private func spiegleAlleVorgaenge() {
 let store = FenlynineOSKernStore.shared
 for v in VorgangStore.shared.vorgaenge {
   VorgangKausalBrucke.spiegleAlsEreignis(v, in: store)
 }
}
private func spiegle(_ v: Vorgang) {
 VorgangKausalBrucke.spiegleAlsEreignis(v, in: FenlynineOSKernStore.shared)
}
}
struct StudioVorgangListe: View {
@Bindable var store: VorgangStore = .shared
@Bindable private var appearance = AppearanceStore.shared
let onOeffnen: (UUID) -> Void
@State private var filterTyp: VorgangTyp? = nil
@State private var filterZustand: VorgangZustand? = nil
private var liste: [Vorgang] {
 var l = store.vorgaenge
 if let t = filterTyp { l = l.filter { $0.typ == t } }
 if let z = filterZustand { l = l.filter { $0.zustand == z } }
 return l.sorted { $0.geaendert > $1.geaendert }
}
var body: some View {
  Group {
    if appearance.istApple { appleBody } else { classicBody }
  }
}
private var appleBody: some View {
  ScrollView {
    VStack(alignment: .leading, spacing: Store.sectionGap) {
      StorePageHeader(
        titel: "Vorgänge",
        untertitel: "Akten · bewerten · entscheiden — App-Store-Bedienung, volle Funktion."
      )
      .padding(.top, 4)
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 16) {
          StoreHeroCard(
            eyebrow: "Unsere Favoriten",
            titel: "Vom Sachverhalt zur Entscheidung",
            text: "Strukturieren, bewerten, empfehlen — der Motor rechnet.",
            gradient: [Color(red: 0.35, green: 0.12, blue: 0.75), Color(red: 0.85, green: 0.20, blue: 0.35)],
            symbol: "scale.3d",
            height: 200
          )
          StoreHeroCard(
            eyebrow: "Jetzt im Spotlight",
            titel: "Formelkaskade live",
            text: "EV, Risiko und Fristen in einem Blick.",
            gradient: [Color(red: 0.05, green: 0.35, blue: 0.85), Color(red: 0.15, green: 0.65, blue: 0.75)],
            symbol: "function",
            height: 200
          )
        }
        StoreHeroCard(
          eyebrow: "Unsere Favoriten",
          titel: "Vom Sachverhalt zur Entscheidung",
          text: "Strukturieren, bewerten, empfehlen — der Motor rechnet.",
          gradient: [Color(red: 0.35, green: 0.12, blue: 0.75), Color(red: 0.85, green: 0.20, blue: 0.35)],
          symbol: "scale.3d",
          height: 200
        )
      }
      StoreSectionHeader(titel: "Essenzielle Werkzeuge")
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        StoreMediaCard(
          eyebrow: "Nur für kurze Zeit",
          titel: "Lagezentrale",
          text: "Mandate, Konflikte, Pipeline.",
          gradient: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.05, green: 0.2, blue: 0.55)],
          symbol: "dot.radiowaves.left.and.right",
          action: { NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.lageZentrale.rawValue) }
        )
        StoreMediaCard(
          eyebrow: "Sammlung",
          titel: "Team & Netzwerk",
          text: "Organon — wer macht was.",
          gradient: [Color(red: 0.2, green: 0.7, blue: 0.45), Color(red: 0.05, green: 0.35, blue: 0.25)],
          symbol: "person.2",
          action: { NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.organon.rawValue) }
        )
        StoreMediaCard(
          eyebrow: "Neu",
          titel: "Alle Module",
          text: "Lexara, Strategos, Radar …",
          gradient: [Color(red: 0.95, green: 0.45, blue: 0.15), Color(red: 0.55, green: 0.1, blue: 0.2)],
          symbol: "square.grid.2x2",
          action: { NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.lexara.rawValue) }
        )
      }
      StoreSectionHeader(titel: "Übersicht")
      HStack(alignment: .top, spacing: 16) {
        StoreWidget(titel: "Erwartungswert-Trend", untertitel: "Illustrativ aus offenen Vorgängen", symbol: "chart.xyaxis.line") {
          StoreSparkline(values: sparkValues, tint: Store.accent)
        }
        StoreWidget(titel: "Zustand", untertitel: "Verteilung der Akte", symbol: "chart.bar.fill") {
          StoreBarStrip(values: barValues)
        }
      }
      .frame(minHeight: 200)
      HStack(spacing: 8) {
        storeChip("Alle", aktiv: filterTyp == nil) { filterTyp = nil }
        ForEach(VorgangTyp.allCases) { typ in
          storeChip(typ.bezeichnung, aktiv: filterTyp == typ) {
            filterTyp = filterTyp == typ ? nil : typ
          }
        }
        Spacer()
        Text("\(liste.count)")
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundStyle(Store.textTertiary)
      }
      StoreSectionHeader(titel: "Aktuelle Vorgänge")
      VStack(spacing: 0) {
        ForEach(liste) { v in
          StoreAppZeile(
            symbol: v.typ.linsenSymbol,
            iconColor: zustandFarbe(v.zustand),
            titel: v.titel,
            untertitel: untertitel(v),
            pillTitel: "Öffnen",
            action: { onOeffnen(v.id) }
          )
          Divider().overlay(Color.white.opacity(0.06))
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: Store.radiusCard, style: .continuous)
          .fill(Store.canvasElevated)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Store.radiusCard, style: .continuous)
          .stroke(Color.white.opacity(0.10), lineWidth: 1)
      )
    }
    .padding(.horizontal, Store.contentInset)
    .padding(.bottom, 48)
  }
  .background(Store.canvas)
}
private var sparkValues: [Double] {
  var evs: [Double] = []
  for v in liste {
    if let wert = v.optionen.first(where: { !$0.istVorgeschichte })?.bewertung.ev?.wert {
      evs.append(wert)
    }
  }
  guard evs.count >= 2 else {
    return [0.25, 0.4, 0.38, 0.55, 0.62, 0.58, 0.72, 0.8]
  }
  let maxAbs = max(evs.map { abs($0) }.max() ?? 1, 1)
  return evs.map { ($0 / maxAbs + 1) / 2 }
}
private var barValues: [(label: String, value: Double, color: Color)] {
  let total = Double(max(liste.count, 1))
  func share(_ z: VorgangZustand) -> Double {
    Double(liste.filter { $0.zustand == z }.count) / total
  }
  return [
    (label: "Erfasst", value: share(.erfasst), color: Store.textSecondary),
    (label: "Strukturiert", value: share(.strukturiert), color: Premium.proposed),
    (label: "Bewertet", value: share(.bewertet), color: Store.accent),
    (label: "Laufend", value: share(.laufend), color: Premium.computed)
  ]
}
private var classicBody: some View {
 VStack(spacing: 0) {
   VStack(alignment: .leading, spacing: 6) {
     Text("Akten · Vorgänge · Entscheidungen")
       .font(.system(size: 22, weight: .semibold))
       .foregroundStyle(Premium.text)
     Text("Ein Objekt. Vier Linsen. Eine Formelkaskade. Die KI schlägt vor -- der Motor rechnet.")
       .font(.system(size: 12))
       .foregroundStyle(Premium.textSoft)
   }
   .frame(maxWidth: .infinity, alignment: .leading)
   .padding(.horizontal, 24)
   .padding(.top, 20)
   .padding(.bottom, 14)
   HStack(spacing: 6) {
     chip("Alle", aktiv: filterTyp == nil) { filterTyp = nil }
     ForEach(VorgangTyp.allCases) { t in
       chip(t.bezeichnung, aktiv: filterTyp == t, symbol: t.linsenSymbol) {
         filterTyp = filterTyp == t ? nil : t
       }
     }
     Spacer()
     Text("\(liste.count)")
       .font(.system(size: 11, weight: .medium, design: .monospaced))
       .foregroundStyle(Premium.textFaint)
   }
   .padding(.horizontal, 24)
   .padding(.bottom, 10)
   ScrollView {
     LazyVStack(spacing: 8) {
       ForEach(liste) { v in
         Button { onOeffnen(v.id) } label: {
           zeile(v)
         }
         .buttonStyle(.plain)
       }
     }
     .padding(.horizontal, 16)
     .padding(.bottom, 40)
   }
 }
 .background(Color.clear)
}
private func storeChip(_ label: String, aktiv: Bool, action: @escaping () -> Void) -> some View {
  Button(action: action) {
    Text(label)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(aktiv ? .black : Store.text)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(Capsule().fill(aktiv ? Color.white : Store.pillFill))
  }
  .buttonStyle(.plain)
}
private func chip(_ label: String, aktiv: Bool, symbol: String? = nil, action: @escaping () -> Void) -> some View {
 Button(action: action) {
   HStack(spacing: 4) {
     if let s = symbol { Image(systemName: s).font(.system(size: 9)) }
     Text(label)
   }
   .premiumChip(active: aktiv)
 }
 .buttonStyle(.plain)
}
private func zeile(_ v: Vorgang) -> some View {
 HStack(spacing: 14) {
   Image(systemName: v.typ.linsenSymbol)
     .font(.system(size: 13, weight: .medium))
     .foregroundStyle(Premium.action)
     .frame(width: 28, height: 28)
     .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action.opacity(0.12)))
   Circle()
     .fill(zustandFarbe(v.zustand))
     .frame(width: 6, height: 6)
   VStack(alignment: .leading, spacing: 2) {
     Text(v.titel)
       .font(.system(size: 13, weight: .semibold))
       .foregroundStyle(Premium.text)
       .lineLimit(1)
     HStack(spacing: 8) {
       Text(v.kurzId)
         .font(.system(size: 10, design: .monospaced))
       Text(v.zustand.bezeichnung)
       if let p = v.parteien.first { Text(p.name) }
     }
     .font(.system(size: 10))
     .foregroundStyle(Premium.textFaint)
   }
   Spacer()
   if let ev = v.optionen.first(where: { !$0.istVorgeschichte })?.bewertung.ev {
     WertBadge(wert: ev, groesseText: 13, fett: true)
   }
   if let f = v.fristen.min(by: { $0.tageBisAblauf < $1.tageBisAblauf }) {
     Text("\(f.tageBisAblauf) T")
       .font(.system(size: 11, weight: .semibold, design: .monospaced))
       .foregroundStyle(f.tageBisAblauf < 14 ? Premium.critical : Premium.textFaint)
       .frame(width: 36, alignment: .trailing)
   }
   Image(systemName: "chevron.right")
     .font(.system(size: 10, weight: .semibold))
     .foregroundStyle(Premium.textFaint)
 }
 .padding(.horizontal, 14)
 .padding(.vertical, 12)
 .premiumGlas(radius: 10)
 .contentShape(Rectangle())
}
private func untertitel(_ v: Vorgang) -> String {
  var parts: [String] = [v.kurzId, v.zustand.bezeichnung]
  if let p = v.parteien.first { parts.append(p.name) }
  if let f = v.fristen.min(by: { $0.tageBisAblauf < $1.tageBisAblauf }) {
    parts.append("\(f.tageBisAblauf) T")
  }
  return parts.joined(separator: " · ")
}
private func zustandFarbe(_ z: VorgangZustand) -> Color {
  switch z {
  case .erfasst: return appearance.istApple ? Store.textSecondary : Premium.mute
  case .strukturiert: return Premium.proposed
  case .bewertet: return appearance.istApple ? Store.accent : Premium.action
  case .entschieden, .laufend: return Premium.computed
  case .abgeschlossen: return appearance.istApple ? Store.textTertiary : Premium.mute
  }
}
}
struct StudioVorgangHost: View {
let vorgangId: UUID
let onZurueck: () -> Void
@Bindable var store: VorgangStore = .shared
@State private var aktiveLinse: VorgangTyp = .streit
@State private var zeigeTypWechsel = false
@State private var zeigeOrganon = false
@State private var kommandofeldOffen = false
@State private var kiLaeuft = false
@State private var kiVorschlaege: [VorgangKIVorschlag] = []
private var vorgang: Vorgang? { store.vorgang(vorgangId) }
var body: some View {
 VStack(spacing: 0) {
   HStack {
     Button(action: onZurueck) {
       HStack(spacing: 4) {
         Image(systemName: "chevron.left")
         Text("Liste")
       }
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(Premium.action)
     }
     .buttonStyle(.plain)
     Spacer()
     Button {
       Task { await kiOptionen() }
     } label: {
       HStack(spacing: 6) {
         if kiLaeuft { ProgressView().controlSize(.small) }
         else { Image(systemName: "sparkles") }
         Text("KI-Optionen")
       }
       .font(.system(size: 11, weight: .semibold))
       .foregroundStyle(Premium.proposed)
       .padding(.horizontal, 10).padding(.vertical, 6)
       .background(RoundedRectangle(cornerRadius: 7).fill(Premium.proposed.opacity(0.12)))
       .overlay(RoundedRectangle(cornerRadius: 7).stroke(Premium.proposed.opacity(0.35), lineWidth: 1))
     }
     .buttonStyle(.plain)
     .disabled(kiLaeuft)
     Button {
       store.bewerteAlleOptionen(vorgangId)
       store.setzeEmpfehlung(vorgangId)
       if let v = vorgang {
         VorgangKausalBrucke.spiegleAlsEreignis(v, in: FenlynineOSKernStore.shared)
       }
     } label: {
       HStack(spacing: 4) {
         Image(systemName: "function")
         Text("Neu berechnen")
       }
       .font(.system(size: 11, weight: .semibold))
       .foregroundStyle(Premium.computed)
       .padding(.horizontal, 10).padding(.vertical, 6)
       .background(RoundedRectangle(cornerRadius: 7).fill(Premium.computed.opacity(0.12)))
     }
     .buttonStyle(.plain)
     if let v = vorgang, v.zustand.reihenfolge >= VorgangZustand.bewertet.reihenfolge,
      let best = v.optionen.first(where: { $0.id == v.empfehlung?.optionId }) {
       Button {
         store.entscheide(vorgangId, optionId: best.id, wer: "Nutzer")
       } label: {
         Text("Entscheiden")
           .font(.system(size: 11, weight: .bold))
           .foregroundStyle(Premium.onAction)
           .padding(.horizontal, 12).padding(.vertical, 6)
           .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action))
       }
       .buttonStyle(.plain)
     }
   }
   .padding(.horizontal, 16)
   .padding(.vertical, 8)
   if let v = vorgang {
     Vorgangskopf(
       vorgang: v,
       aktiveLinse: $aktiveLinse,
       onKommandofeld: { kommandofeldOffen = true },
       onExport: { },
       onZuPortfolio: { aktiveLinse = .programm },
       onTypWechsel: { neu in
         if neu != v.typ {
           aktiveLinse = neu
           zeigeTypWechsel = true
         } else if neu == .programm {
           aktiveLinse = .programm
         }
       }
     )
     .padding(.horizontal, 12)
     if !kiVorschlaege.isEmpty {
       kiBanner
         .padding(.horizontal, 16)
         .padding(.top, 8)
     }
     Group {
       switch aktiveLinse {
       case .streit: StreitLinse(vorgangId: v.id)
       case .gestaltung: GestaltungLinse(vorgangId: v.id)
       case .verhandlung: VerhandlungLinse(vorgangId: v.id)
       case .programm: PortfolioLinse()
       }
     }
     .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
 }
 .background(Color.clear)
 .onAppear {
   if let v = vorgang { aktiveLinse = v.typ == .verhandlung ? .streit : v.typ }
 }
 .sheet(isPresented: $zeigeTypWechsel) {
   if let v = vorgang {
     typWechselSheet(v)
   }
 }
 .sheet(isPresented: $kommandofeldOffen) {
   Kommandofeld(aktuellerVorgang: vorgang)
     .presentationBackground(.clear)
 }
}
private var kiBanner: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Herkunftsmarke(herkunft: .ki, groesse: 8)
     Text("KI-VORSCHLÄGE · UNBESTÄTIGT")
       .font(.system(size: 10, weight: .bold))
       .kerning(0.5)
       .foregroundStyle(Premium.proposed)
     Spacer()
     Button("Übernehmen & berechnen") {
       VorgangKIService.uebernehmeAlsOptionen(kiVorschlaege, in: store, vorgangId: vorgangId)
       kiVorschlaege = []
     }
     .font(.system(size: 11, weight: .semibold))
     .foregroundStyle(Premium.action)
     Button("Verwerfen") { kiVorschlaege = [] }
       .font(.system(size: 11, weight: .medium))
       .foregroundStyle(Premium.textFaint)
   }
   ForEach(kiVorschlaege) { v in
     HStack(alignment: .top, spacing: 8) {
       Text(v.titel).font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
       Text(v.text).font(.system(size: 11)).foregroundStyle(Premium.textSoft).lineLimit(2)
       Spacer()
       if let p = v.zahl {
         Text(InterfaceZahl.prozent(p))
           .font(.system(size: 11, design: .monospaced))
           .foregroundStyle(Premium.proposed)
       }
     }
   }
 }
 .padding(12)
 .background(RoundedRectangle(cornerRadius: 10).fill(Premium.proposed.opacity(0.08)))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(Premium.proposed.opacity(0.25), lineWidth: 1))
}
private func typWechselSheet(_ v: Vorgang) -> some View {
 VStack(alignment: .leading, spacing: 14) {
   Text("Typ wechseln").font(.system(size: 17, weight: .semibold)).foregroundStyle(Premium.text)
   Text("Ein Feld. Alles bleibt. Alte Optionen werden Vorgeschichte.")
     .font(.system(size: 12)).foregroundStyle(Premium.textSoft)
   HStack {
     Spacer()
     Button("Abbrechen") { zeigeTypWechsel = false }
       .foregroundStyle(Premium.textSoft)
     Button("Bestätigen") {
       store.typWechseln(v.id, zu: aktiveLinse)
       zeigeTypWechsel = false
       VorgangKausalBrucke.spiegleAlsEreignis(store.vorgang(v.id) ?? v, in: FenlynineOSKernStore.shared)
     }
     .font(.system(size: 12, weight: .semibold))
     .foregroundStyle(Premium.onAction)
     .padding(.horizontal, 14).padding(.vertical, 7)
     .background(RoundedRectangle(cornerRadius: 8).fill(Premium.action))
     .buttonStyle(.plain)
   }
 }
 .padding(20)
 .frame(width: 440)
 .background(Premium.ink)
}
private func kiOptionen() async {
 guard let v = vorgang else { return }
 kiLaeuft = true
 defer { kiLaeuft = false }
 kiVorschlaege = await VorgangKIService.schlageOptionenVor(fuer: v)
}
}
