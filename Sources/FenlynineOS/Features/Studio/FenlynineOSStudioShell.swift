import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// FENLYNINEOS STUDIO -- Produktwirbelsäule
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Ein Objekt. Viele Linsen. Keine Modul-Silos als Startseite.
// Vorgänge = Home. Legacy-Module = Werkzeugschublade.
// nK überall. Filigranes Premium-Design.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

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
  case .lage: return "Lage"
  case .organon: return "Organon"
  case .werkzeuge: return "Werkzeuge"
  case .wissen: return "Rechtswissen"
  case .einstellungen: return "System"
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
}

struct FenlynineOSStudioShell: View {
@EnvironmentObject var authManager: AuthManager
@EnvironmentObject var appState: AppState
@Bindable private var appearance = AppearanceStore.shared
@ObservedObject private var kontoStore = KontoStore.shared

var onZurueckZumHub: (() -> Void)? = nil

@State private var zone: StudioZone = .vorgaenge
@State private var offenerVorgangId: UUID?
@State private var kommandofeldOffen = false
@State private var werkzeug: SeitenleistenEintrag = .lexara
@State private var railEingeklappt = false
@State private var zeigeTutorial = false
@State private var showInspector = true
@State private var werkzeugFilter = ""
@AppStorage("fenlynineos_einstellungen_tab") private var einstellungenTab = "ki"

var body: some View {
  HStack(spacing: 0) {
    studioRail
    VStack(spacing: 0) {
      studioTopBar
      Divider().overlay(Premium.hairline)
      zoneInhalt
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    if showInspector {
      StudioInspektor(
        onNavigiere: navigiereZuWerkzeug,
        onOeffneFenster: oeffneModulFenster
      )
    }
  }
  .background(PremiumAurora())
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
    if zone == .werkzeuge && werkzeug == .schreibtisch {
      showInspector = false
   }
   // Deep-Link-Ziel nachziehen (fenlynineos://schreibtisch), falls Notification zu früh kam
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
 // Schreibtisch-Fenstermodus & Opportunisma Pro brauchen volle Breite
 if e == .schreibtisch || e == .opportunisma {
   withAnimation(.easeOut(duration: 0.15)) { showInspector = false }
 }
}

private func oeffneModulFenster(_ e: SeitenleistenEintrag) {
 // Direkt + Bridge -- doppelte Absicherung
 ModulFensterHost.shared.oeffneModul(e)
 ModulFensterBridge.installieren()
}

/// Welches Modul die Top-Bar als Fenster öffnen soll (je Zone).
/// `nil` = Zone hat kein Pop-out (z. B. Rechtswissen bleibt in Studio).
private var fensterZiel: SeitenleistenEintrag? {
 switch zone {
 case .vorgaenge: return .lexara
 case .lage: return .lageZentrale
 case .organon: return .organon
 case .werkzeuge: return werkzeug
 case .wissen: return nil
 case .einstellungen: return .einstellungen
 }
}

// MARK: - Rail

private var studioRail: some View {
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
       Image(systemName: z.symbol)
         .font(.system(size: 14, weight: .semibold))
         .foregroundStyle(zone == z ? (appearance.istAtelier ? Premium.action : .white) : Premium.textSoft)
         .frame(width: 40, height: 36)
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
     .help(z.titel)
   }

   Spacer()

   Button { zeigeTutorial = true } label: {
     Image(systemName: "questionmark.circle")
       .font(.system(size: 14, weight: .semibold))
       .foregroundStyle(Premium.textSoft)
       .frame(width: 40, height: 36)
   }
   .buttonStyle(.plain)
   .help("Tutorial")

   Button { kommandofeldOffen = true } label: {
     Image(systemName: "magnifyingglass")
       .font(.system(size: 13, weight: .semibold))
       .foregroundStyle(Premium.textSoft)
       .frame(width: 40, height: 36)
   }
   .buttonStyle(.plain)
   .help("nK Kommandofeld")
   .padding(.bottom, 10)
 }
 .frame(width: 52)
 .padding(.vertical, 6)
 .premiumGlasLeiste()
 .overlay(alignment: .trailing) {
   Rectangle().fill(Premium.hairline).frame(width: 1)
 }
}

// MARK: - Top bar

private var studioTopBar: some View {
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
      : "Aktuelles Modul als eigenes Fenster -- Menü: Fenster · Module · nn1-5")

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
   .help("2-3 Module nebeneinander · nnV")

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
       Text("nK")
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
       let v = VorgangStore.shared.neu(typ: .streit, titel: "Neuer Vorgang")
       offenerVorgangId = v.id
       Task(priority: .utility) { spiegle(v) }
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
     .keyboardShortcut("n", modifiers: [.command])
   }
 }
 .padding(.horizontal, 16)
 .padding(.vertical, 10)
 .premiumGlasLeiste()
}

// MARK: - Zone content

@ViewBuilder
private var zoneInhalt: some View {
 switch zone {
 case .vorgaenge:
   if let id = offenerVorgangId {
     StudioVorgangHost(vorgangId: id, onZurueck: {
       offenerVorgangId = nil
     })
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
       .padding(8)
   } else {
     AboGateView(eintrag: .lageZentrale)
   }
 case .organon:
   if kontoStore.darf(.organon) {
     OrganonView()
       .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
       .padding(10)
   } else {
     AboGateView(eintrag: .organon)
   }
 case .werkzeuge:
   werkzeugPanel
 case .wissen:
   RechtswissenPanel()
 case .einstellungen:
   EinstellungenView()
     .padding(10)
 }
}

private var werkzeugPanel: some View {
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
                   HStack(spacing: 8) {
                     Image(systemName: e.symbol)
                       .font(.system(size: 11))
                       .frame(width: 16)
                     Text(e.bezeichnung)
                       .font(.system(size: 12, weight: .medium))
                       .lineLimit(1)
                     Spacer()
                     if !kontoStore.darf(e) {
                       AboFensterSperrBadge(eintrag: e)
                     }
                   }
                   .foregroundStyle(werkzeug == e ? (appearance.istAtelier ? Premium.action : Premium.onAction) : Premium.textSoft)
                   .padding(.horizontal, 10)
                   .padding(.vertical, 7)
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
   .frame(width: 248)
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
 var sektionen: [WerkzeugSektion] = [
   .init(titel: "Imperium", items: [.lageZentrale, .berufspflicht, .praxisProfil, .konfliktRadar, .mandatsPipeline, .honorare, .entscheidungsjournal, .beaCheck]),
   .init(titel: "Lexara", items: [.lexara, .richterprofile, .jurisdiktionen, .zeitleiste, .dokumente]),
   .init(titel: "Strategos", items: [.strategos, .opportunisma, .sunTzu, .analytik]),
   .init(titel: "Übersicht", items: [.dashboard, .schreibtisch, .cockpit]),
   .init(titel: "Organisation", items: [.aufgaben, .mandanten]),
   .init(titel: "Arbeit & KI", items: [.kiChat, .compliance])
 ]
 sektionen.append(.init(titel: "System", items: [.selbstreparatur]))
 if kontoStore.istAdmin {
   sektionen.append(.init(titel: "Verwaltung", items: [.adminZentrale]))
 }
 return sektionen
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

// MARK: - Kausalspiegelung

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

// MARK: - Studio Vorgangliste (inline, kein Sheet)

struct StudioVorgangListe: View {
@Bindable var store: VorgangStore = .shared
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
 VStack(spacing: 0) {
   // Hero
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

   // Filter
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

private func zustandFarbe(_ z: VorgangZustand) -> Color {
 switch z {
 case .erfasst: return Premium.mute
 case .strukturiert: return Premium.proposed
 case .bewertet: return Premium.action
 case .entschieden, .laufend: return Premium.computed
 case .abgeschlossen: return Premium.mute
 }
}
}

// MARK: - Studio Vorgang-Host (inline Detail + KI + Organon)

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
   Kommandofeld(onOeffnen: { _ in }, aktuellerVorgang: vorgang)
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

