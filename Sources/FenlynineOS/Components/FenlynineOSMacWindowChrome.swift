import AppKit
import SwiftUI
enum FenlynineOSFensterKennung {
    static let haupt = "fenlynineos.haupt"
    /// Kennung der SwiftUI-Fenstergruppe des Hauptfensters (für openWindow).
    static let hauptGruppe = "fenlynineos-haupt"
    /// Hauptfenster = jedes Fenster mit Titelleiste, das kein Modul- oder
    /// Vergleichsfenster ist. SwiftUI vergibt eigene Kennungen; ein Vergleich
    /// auf "fenlynineos.haupt" allein traf das Hauptfenster deshalb nie.
    static func istHauptfenster(_ fenster: NSWindow) -> Bool {
        fenster.styleMask.contains(.titled) && !fenster.isSheet && !istModulOderVergleich(fenster)
    }
    static let modulPrefix = "fenlynineos.modul"
    static let vergleichPrefix = "fenlynineos.vergleich"
    static func istModulOderVergleich(_ fenster: NSWindow) -> Bool {
        let id = fenster.identifier?.rawValue ?? ""
        return id.hasPrefix(modulPrefix) || id.hasPrefix(vergleichPrefix)
    }
}
struct FenlynineOSMacWindowChrome: ViewModifier {
    @Bindable private var appearance = AppearanceStore.shared
    func body(content: Content) -> some View {
        content
            .background(appearance.istApple ? Store.canvas : Color.clear)
            .onAppear { DispatchQueue.main.async { self.konfiguriere() } }
            .onChange(of: appearance.modus) { _, _ in
                DispatchQueue.main.async { self.konfiguriere() }
            }
    }
    private func konfiguriere() {
        if let w = NSApp.keyWindow, w.identifier == nil {
            w.identifier = NSUserInterfaceItemIdentifier(FenlynineOSFensterKennung.haupt)
        }
        FenlynineOSMacWindowChrome.konfiguriereFenster(appleMode: AppearanceStore.shared.istApple)
    }
    static func konfiguriereFenster(appleMode: Bool = AppearanceStore.shared.istApple) {
        for fenster in NSApp.windows where fenster.canBecomeKey && !fenster.isSheet {
            if FenlynineOSFensterKennung.istModulOderVergleich(fenster) {
                haerteModulFenster(fenster)
                continue
            }
            guard FenlynineOSFensterKennung.istHauptfenster(fenster) else { continue }
            if appleMode {
                fenster.isOpaque = true
                fenster.backgroundColor = NSColor.black
                fenster.titlebarAppearsTransparent = true
                fenster.isMovableByWindowBackground = false
                if let content = fenster.contentView {
                    content.wantsLayer = true
                    content.layer?.backgroundColor = NSColor.black.cgColor
                }
            } else {
                fenster.isOpaque = false
                fenster.backgroundColor = .clear
                fenster.titlebarAppearsTransparent = true
                fenster.isMovableByWindowBackground = false
                if let content = fenster.contentView {
                    content.wantsLayer = true
                    content.layer?.backgroundColor = NSColor.clear.cgColor
                }
            }
        }
    }
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
