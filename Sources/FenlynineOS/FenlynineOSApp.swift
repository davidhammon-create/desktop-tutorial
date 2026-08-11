import SwiftUI
import AppKit

@main
struct FenlynineOSApp: App {
@NSApplicationDelegateAdaptor(FenlynineOSAppDelegate.self) var appDelegate
@StateObject private var authManager = AuthManager.shared
@StateObject private var appState = AppState.shared

init() {
  FenlynineOSKeychain.migrateLegacySecretsIfNeeded()
  Self.migriereLegacyMarkenPfade()
}

/// Einmalig: alte LegalOS-/Juridisk-Pfade und UserDefaults-Keys -> FenlynineOS
private static func migriereLegacyMarkenPfade() {
  let d = UserDefaults.standard
  guard !d.bool(forKey: "fenlynineos_marken_migration_v1") else { return }
  let fm = FileManager.default
  if let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
    let alt = support.appendingPathComponent("LegalOS", isDirectory: true)
    let neu = support.appendingPathComponent("FenlynineOS", isDirectory: true)
    if fm.fileExists(atPath: alt.path), !fm.fileExists(atPath: neu.path) {
      try? fm.copyItem(at: alt, to: neu)
    }
    let altDocs = fm.homeDirectoryForCurrentUser.appendingPathComponent("Documents/LegalOS-Rechtsdaten", isDirectory: true)
    let neuDocs = fm.homeDirectoryForCurrentUser.appendingPathComponent("Documents/FenlynineOS-Rechtsdaten", isDirectory: true)
    if fm.fileExists(atPath: altDocs.path), !fm.fileExists(atPath: neuDocs.path) {
      try? fm.copyItem(at: altDocs, to: neuDocs)
    }
  }
  // UserDefaults-Keys legalos_* -> fenlynineos_* (Werte übernehmen, wenn Ziel leer)
  for (key, value) in d.dictionaryRepresentation() {
    guard key.hasPrefix("legalos_") else { continue }
    let neuKey = "fenlynineos_" + key.dropFirst("legalos_".count)
    if d.object(forKey: neuKey) == nil {
      d.set(value, forKey: neuKey)
    }
  }
  d.set(true, forKey: "fenlynineos_marken_migration_v1")
}

var body: some Scene {
  // WICHTIG: kein `return` hier -- sonst werden WindowGroup/MenuBarExtra nie registriert.
  WindowGroup {
    ContentRootView()
      .environmentObject(authManager)
      .environmentObject(appState)
  }
  .windowStyle(.titleBar)
  .defaultSize(width: 1200, height: 700)
  .commands {
    FenlynineOSCommands()
  }

  // Eigenständige Modul-Fenster (Lexara / Strategos / Opportunisma …)
  // Primär öffnet ModulFensterHost (AppKit); diese Groups sind Fallback.
  WindowGroup(id: ModulFensterKennung.modul, for: ModulFensterSchluessel.self) { $schluessel in
    if let schluessel {
      ModulFensterAnsicht(schluessel: schluessel)
        .environmentObject(authManager)
        .environmentObject(appState)
    } else {
      Text("Modul wird geladen…")
        .frame(minWidth: 400, minHeight: 300)
    }
  }
  .defaultSize(width: 980, height: 700)
  .windowStyle(.titleBar)

  // Vergleichsfenster: 2-3 Module nebeneinander
  WindowGroup(id: ModulFensterKennung.vergleich, for: Int.self) { $nummer in
    VergleichsFensterAnsicht(nummer: nummer ?? 1)
      .environmentObject(authManager)
      .environmentObject(appState)
  }
  .defaultSize(width: 1440, height: 820)
  .windowStyle(.titleBar)

  MenuBarExtra(AppDefaults.produktKurz, systemImage: "scale.3d") {
    MenuBarView()
      .environmentObject(authManager)
      .environmentObject(appState)
  }
  .menuBarExtraStyle(.window)
}
}

// MARK: - App Delegate (Fenster-Fokus & Tastatur)

final class FenlynineOSAppDelegate: NSObject, NSApplicationDelegate {
func applicationDidFinishLaunching(_ notification: Notification) {
  NSApp.setActivationPolicy(.regular)
  NSApp.activate(ignoringOtherApps: true)
  ModulFensterBridge.installieren()
  NSAppleEventManager.shared().setEventHandler(
    self,
    andSelector: #selector(handleGetURL(_:withReplyEvent:)),
    forEventClass: AEEventClass(kInternetEventClass),
   andEventID: AEEventID(kAEGetURL)
 )
 DispatchQueue.main.async {
   Self.aktiviereHauptfenster()
   Task { @MainActor in
     await UpdateService.shared.pruefen(automatisch: true)
   }
 }
}

func applicationDidBecomeActive(_ notification: Notification) {
 // Kein Zwangs-Fokus aufs erste Fenster -- Multi-Fenster-Vergleich bleibt nutzbar.
 NSApp.activate(ignoringOtherApps: true)
}

func application(_ application: NSApplication, open urls: [URL]) {
 for url in urls { Self.verarbeiteDeepLink(url) }
}

@objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
 guard let raw = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
    let url = URL(string: raw) else { return }
 Self.verarbeiteDeepLink(url)
}

/// Deep Links: fenlynineos://studio · fenlynineos://fenster/lexara · fenlynineos://vergleich · fenlynineos://atelier · fenlynineos://tutorial
static func verarbeiteDeepLink(_ url: URL) {
 guard url.scheme == "fenlynineos" else { return }
 let host = (url.host ?? "").lowercased()
 let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
 let ziel = path.isEmpty ? host : "\(host)/\(path)"

 DispatchQueue.main.async {
   switch host {
   case "studio", "hub-skip":
     NotificationCenter.default.post(name: .oeffneStudio, object: nil)
   case "schreibtisch":
     // Pending, falls Studio noch nicht gemountet ist (Notification sonst verloren).
     UserDefaults.standard.set(
       SeitenleistenEintrag.schreibtisch.rawValue,
       forKey: "fenlynineos_pending_sidebar"
     )
     NotificationCenter.default.post(name: .oeffneStudio, object: nil)
     DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
       NotificationCenter.default.post(
         name: .navigateToSidebar,
         object: SeitenleistenEintrag.schreibtisch.rawValue
       )
     }
   case "tutorial":
     NotificationCenter.default.post(name: .oeffneTutorial, object: nil)
   case "atelier":
     AppearanceStore.shared.setze(.atelier)
   case "noir":
     AppearanceStore.shared.setze(.noir)
   case "vergleich":
     NotificationCenter.default.post(name: .oeffneStudio, object: nil)
     Task { @MainActor in ModulFensterHost.shared.oeffneVergleich() }
   case "fenster":
     NotificationCenter.default.post(name: .oeffneStudio, object: nil)
     let modul = path.isEmpty ? "lexara" : path
     let eintrag = SeitenleistenEintrag(rawValue: modul)
       ?? SeitenleistenEintrag.allCases.first { $0.rawValue.contains(modul) || $0.bezeichnung.lowercased().contains(modul) }
       ?? .lexara
     Task { @MainActor in
       try? await Task.sleep(for: .milliseconds(250))
       ModulFensterHost.shared.oeffneModul(eintrag)
     }
   default:
     // fenlynineos://fenster-lexara Fallback
     if ziel.hasPrefix("fenster") {
       NotificationCenter.default.post(name: .oeffneStudio, object: nil)
       Task { @MainActor in ModulFensterHost.shared.oeffneModul(.lexara) }
     }
   }
   Self.aktiviereHauptfenster()
 }
}

static func aktiviereHauptfenster() {
 NSApp.activate(ignoringOtherApps: true)
 if NSApp.keyWindow == nil {
   NSApp.windows.first(where: { $0.canBecomeKey && !$0.isSheet && $0.isVisible })?
     .makeKeyAndOrderFront(nil)
 }
}
}

// MARK: - Root View (Auth-Gate)

struct ContentRootView: View {
@EnvironmentObject var authManager: AuthManager
@EnvironmentObject var appState: AppState
@ObservedObject private var kontoStore = KontoStore.shared
@Bindable private var design = FenlynineOSDesignStore.shared
@Bindable private var appearance = AppearanceStore.shared
@AppStorage("fenlynineos_tutorial_gesehen_v3") private var tutorialGesehen = false
@AppStorage("fenlynineos_tutorial_aktiv") private var tutorialAktiv = true
@AppStorage("fenlynineos_hub_uebersprungen") private var hubUebersprungen = true
@State private var zeigeStudio = false
@State private var zeigeTutorial = false

var body: some View {
 Group {
   if authManager.isInitializingSession {
     SplashView()
   } else if !kontoStore.istAngemeldet {
     // Konto-Gate: jede Person arbeitet mit eigenem Konto
     // (Abo-Stufen + verbrauchsgenaue KI-Abrechnung je Konto)
     KontoAnmeldungView()
       .frame(minWidth: 700, minHeight: 640)
   } else if authManager.isAuthenticated {
     if zeigeStudio || hubUebersprungen {
       FenlynineOSStudioShell(onZurueckZumHub: {
         hubUebersprungen = false
         zeigeStudio = false
       })
       .frame(minWidth: 1100, minHeight: 700)
     } else {
       HauptmenueView(
         onOeffneFenlynineOS: {
           hubUebersprungen = true
           zeigeStudio = true
           if tutorialAktiv && !tutorialGesehen { zeigeTutorial = true }
         },
         onTutorial: { zeigeTutorial = true }
       )
       .frame(minWidth: 900, minHeight: 700)
     }
   } else if !AppDefaults.geraeteModusAktiv {
     OnboardingView()
       .frame(minWidth: 520, minHeight: 720)
   } else {
     SplashView()
   }
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .fenlynineOSAppearance()
 .fenlynineOSProgramGlasChrome()
 .fenlynineOSCommandBackground()
 .fenlynineOSSFTypography()
 .fenlynineOSMacWindowChrome()
 .onAppear {
   FenlynineOSAppDelegate.aktiviereHauptfenster()
   RechtsradarAgent.shared.starten()
   SelbstreparaturAgent.shared.starte()
   _ = DesignPresetStore.shared
   if hubUebersprungen { zeigeStudio = true }
 }
 .onReceive(NotificationCenter.default.publisher(for: .oeffneTutorial)) { _ in
   zeigeTutorial = true
 }
 .onReceive(NotificationCenter.default.publisher(for: .oeffneStudio)) { _ in
   hubUebersprungen = true
   zeigeStudio = true
 }
 .onOpenURL { url in
   FenlynineOSAppDelegate.verarbeiteDeepLink(url)
 }
 .sheet(isPresented: $zeigeTutorial) {
   TutorialView(onFertig: { zeigeTutorial = false })
     .presentationBackground(.clear)
 }
}
}

// MARK: - Splash Screen

struct SplashView: View {
var body: some View {
 VStack(spacing: 28) {
   Text("FENLYNINEOS LEGAL SUITE")
     .font(.system(size: 22, weight: .black, design: .rounded))
     .foregroundStyle(Premium.action)
     .tracking(2)
   Text("Ein Objekt · Viele Linsen")
     .font(.system(size: 12, weight: .medium))
     .foregroundStyle(Premium.textSoft)
   ProgressView().tint(Premium.action)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .background(Premium.void)
}
}

// MARK: - macOS Menu Commands

struct FenlynineOSCommands: Commands {
var body: some Commands {
 CommandGroup(after: .newItem) {
   Button("Neuer Vorgang") {
     NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.vorgaenge.rawValue)
   }
   .keyboardShortcut("n", modifiers: [.command])
   Button("Neuer Fall (Legacy)") {
     NotificationCenter.default.post(name: .createNewCase, object: nil)
   }
   .keyboardShortcut("n", modifiers: [.command, .shift])
   Button("Kommandofeld…") {
     NotificationCenter.default.post(name: .oeffneKommandofeld, object: nil)
   }
   .keyboardShortcut("k", modifiers: [.command])
 }

 CommandMenu("Fenster · Module") {
   Button("Lexara als Fenster") {
     Task { @MainActor in ModulFensterHost.shared.oeffneModul(.lexara) }
   }
   .keyboardShortcut("1", modifiers: [.command, .option])
   Button("Strategos als Fenster") {
     Task { @MainActor in ModulFensterHost.shared.oeffneModul(.strategos) }
   }
   .keyboardShortcut("2", modifiers: [.command, .option])
   Button("Opportunisma als Fenster") {
     Task { @MainActor in ModulFensterHost.shared.oeffneModul(.opportunisma) }
   }
   .keyboardShortcut("3", modifiers: [.command, .option])
   Button("Richterprofile als Fenster") {
     Task { @MainActor in ModulFensterHost.shared.oeffneModul(.richterprofile) }
   }
   .keyboardShortcut("4", modifiers: [.command, .option])
   Button("Mandantenportal als Fenster") {
     Task { @MainActor in ModulFensterHost.shared.oeffneModul(.mandanten) }
   }
   .keyboardShortcut("5", modifiers: [.command, .option])
   Divider()
   Button("Vergleichsfenster…") {
     Task { @MainActor in ModulFensterHost.shared.oeffneVergleich() }
   }
   .keyboardShortcut("v", modifiers: [.command, .option])
   Button("Schnellvergleich Lexara · Strategos · Opportunisma") {
     Task { @MainActor in
       ModulFensterHost.shared.oeffneSchnellvergleich(
         links: .lexara, mitte: .strategos, rechts: .opportunisma
       )
     }
   }
   Divider()
   Button("Tutorial…") {
     NotificationCenter.default.post(name: .oeffneTutorial, object: nil)
   }
   .keyboardShortcut("t", modifiers: [.command, .shift])
   Button("Auf Updates prüfen…") {
     NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.einstellungen.rawValue)
     NotificationCenter.default.post(name: .oeffneUpdatePanel, object: nil)
   }
 }

 CommandGroup(replacing: .help) {
   Link("Dokumentation", destination: URL(string: "https://fenlynineos.app/docs")!)
   Divider()
   Button("Über \(AppDefaults.produktNameVoll)") {
     NSApp.orderFrontStandardAboutPanel(
       options: [
         .applicationName: AppDefaults.produktNameVoll,
         .credits: NSAttributedString(
           string: "\(AppDefaults.produktUntertitel)\nby \(AppDefaults.hersteller)",
           attributes: [
             .font: NSFont.systemFont(ofSize: 11),
             .foregroundColor: NSColor.secondaryLabelColor
           ]
         )
       ]
     )
   }
 }
}
}

// MARK: - Notification Names

extension Notification.Name {
static let createNewCase = Notification.Name("createNewCase")
static let navigateToCase = Notification.Name("navigateToCase")
static let navigateToSidebar = Notification.Name("navigateToSidebar")
static let refreshData = Notification.Name("refreshData")
static let oeffneUpdatePanel = Notification.Name("fenlynineos.oeffneUpdatePanel")
static let oeffneTutorial = Notification.Name("fenlynineos.oeffneTutorial")
static let oeffneStudio = Notification.Name("fenlynineos.oeffneStudio")
}

