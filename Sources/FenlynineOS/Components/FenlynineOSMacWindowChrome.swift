import AppKit
import SwiftUI
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
            let id = fenster.identifier?.rawValue ?? ""
            guard id == FenlynineOSFensterKennung.haupt else { continue }
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
