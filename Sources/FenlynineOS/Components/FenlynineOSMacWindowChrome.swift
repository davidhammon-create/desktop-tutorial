import AppKit
import SwiftUI

// MARK: - macOS-Fenster: transparent nur fürs Hauptfenster (visionOS-Look)
// Modulfenster MÜSSEN opak bleiben -- sonst Layout/Buttons kaputt.

enum FenlynineOSFensterKennung {
static let haupt = "fenlynineos.haupt"
static let modulPrefix = "fenlynineos.modul"
static let vergleichPrefix = "fenlynineos.vergleich"

static func istModulOderVergleich(_ fenster: NSWindow) -> Bool {
  let id = fenster.identifier?.rawValue ?? ""
  return id.hasPrefix(modulPrefix) || id.hasPrefix(vergleichPrefix)
}
}

struct FenlynineOSMacWindowChrome: ViewModifier {
func body(content: Content) -> some View {
  content
    .background(Color.clear)
    .onAppear {
      DispatchQueue.main.async {
        if let w = NSApp.keyWindow, w.identifier == nil {
          w.identifier = NSUserInterfaceItemIdentifier(FenlynineOSFensterKennung.haupt)
        }
        FenlynineOSMacWindowChrome.konfiguriereFenster()
      }
    }
}

static func konfiguriereFenster() {
  for fenster in NSApp.windows where fenster.canBecomeKey && !fenster.isSheet {
    if FenlynineOSFensterKennung.istModulOderVergleich(fenster) {
      haerteModulFenster(fenster)
      continue
    }
    let id = fenster.identifier?.rawValue ?? ""
    // Glas nur fürs markierte Hauptfenster -- sonst werden Hilfsfenster
    // transparent und „movableByBackground" (tote Buttons).
    guard id == FenlynineOSFensterKennung.haupt else { continue }
    fenster.isOpaque = false
    fenster.backgroundColor = .clear
    fenster.titlebarAppearsTransparent = true
    // WICHTIG: false -- sonst werden Klicks auf Buttons über Glas-Flächen
    // im Fenstermodus als Fenster-Ziehen interpretiert (Buttons wirken tot,
    // funktionieren nur im Vollbild). Verschieben geht über die Titelleiste.
    fenster.isMovableByWindowBackground = false
    if let content = fenster.contentView {
      content.wantsLayer = true
      content.layer?.backgroundColor = NSColor.clear.cgColor
    }
  }
}

/// Opak, klickbar, kein Hintergrund-Drag -- für AppKit-Modulfenster.
static func haerteModulFenster(_ fenster: NSWindow) {
  fenster.isOpaque = true
  fenster.backgroundColor = .windowBackgroundColor
  fenster.titlebarAppearsTransparent = false
  fenster.isMovableByWindowBackground = false
  fenster.hasShadow = true
  if let content = fenster.contentView {
    content.wantsLayer = true
    content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
  }
}
}

extension View {
func fenlynineOSMacWindowChrome() -> some View {
  modifier(FenlynineOSMacWindowChrome())
}
}

