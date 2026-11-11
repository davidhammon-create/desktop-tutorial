import SwiftUI
import AppKit
import os.log
private let modulFensterLog = Logger(subsystem: "com.fenlynineos.app", category: "ModulFenster")
@MainActor
final class ModulFensterController: NSWindowController, NSWindowDelegate {
    let fensterId: UUID
    init(fensterId: UUID, window: NSWindow) {
        self.fensterId = fensterId
        super.init(window: window)
        window.delegate = self
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    func windowWillClose(_ notification: Notification) {
        ModulFensterHost.shared.entferne(fensterId)
    }
    func windowDidBecomeKey(_ notification: Notification) {
        if let w = window { FenlynineOSMacWindowChrome.haerteModulFenster(w) }
    }
}
@MainActor
final class ModulFensterHost {
    static let shared = ModulFensterHost()
    private var controller: [UUID: ModulFensterController] = [:]
    private var vergleichZaehler = 0
    private var cascadeIndex = 0
    private init() {}
    func oeffneModul(_ eintrag: SeitenleistenEintrag) {
        let schluessel = ModulFensterRegister.shared.naechsterSchluessel(fuer: eintrag)
        modulFensterLog.info("Öffne Modul-Fenster: \(eintrag.rawValue, privacy: .public) #\(schluessel.instanz)")
        let freigeschaltet = KontoStore.shared.darf(eintrag)
        let stufe = AboPlan.benoetigteStufe(fuer: eintrag)
        let titelSuffix = freigeschaltet
            ? "— FenlynineOS Legal Suite"
            : "— gesperrt · ab \(stufe.titel)"
        let root = ModulFensterAnsicht(schluessel: schluessel)
            .environmentObject(AuthManager.shared)
            .environmentObject(AppState.shared)
            .environment(\.fenlynineOSFensterModus, true)
            .environment(\.fenlynineOSGlasModus, .kein)
            .environment(\.fenlynineOSVisionOSChrome, false)
            .fenlynineOSAppearance()
        zeige(
            titel: "\(eintrag.bezeichnung) \(titelSuffix)",
            kennung: "\(FenlynineOSFensterKennung.modulPrefix).\(eintrag.rawValue).\(schluessel.instanz)",
            root: AnyView(root),
            size: NSSize(width: 1180, height: 780),
            minSize: NSSize(width: 880, height: 560)
        )
    }
    func oeffneVergleich() {
        vergleichZaehler += 1
        modulFensterLog.info("Öffne Vergleichsfenster #\(self.vergleichZaehler)")
        let root = VergleichsFensterAnsicht(nummer: vergleichZaehler)
            .environmentObject(AuthManager.shared)
            .environmentObject(AppState.shared)
            .environment(\.fenlynineOSFensterModus, true)
            .environment(\.fenlynineOSGlasModus, .kein)
            .environment(\.fenlynineOSVisionOSChrome, false)
            .fenlynineOSAppearance()
        zeige(
            titel: "Vergleich \(vergleichZaehler) — FenlynineOS Legal Suite",
            kennung: "\(FenlynineOSFensterKennung.vergleichPrefix).\(vergleichZaehler)",
            root: AnyView(root),
            size: NSSize(width: 1680, height: 900),
            minSize: NSSize(width: 1280, height: 700)
        )
    }
    func oeffneSchnellvergleich(links: SeitenleistenEintrag, mitte: SeitenleistenEintrag, rechts: SeitenleistenEintrag? = nil) {
        oeffneModul(links)
        oeffneModul(mitte)
        if let rechts { oeffneModul(rechts) }
        oeffneVergleich()
    }
    func entferne(_ id: UUID) {
        controller.removeValue(forKey: id)
    }
    private func zeige(titel: String, kennung: String, root: AnyView, size: NSSize, minSize: NSSize) {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        let id = UUID()
        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = [.minSize]
        hosting.view.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = titel
        window.identifier = NSUserInterfaceItemIdentifier(kennung)
        window.contentViewController = hosting
        window.minSize = minSize
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.fullScreenPrimary, .managed, .moveToActiveSpace]
        window.appearance = NSAppearance(
            named: AppearanceStore.shared.istAtelier ? .aqua : .darkAqua
        )
        window.setFrameAutosaveName(kennung)
        FenlynineOSMacWindowChrome.haerteModulFenster(window)
        if let screen = NSScreen.main {
            let origin = cascadeOrigin(on: screen, size: size)
            window.setFrame(NSRect(origin: origin, size: size), display: false)
        } else {
            window.center()
        }
        let wc = ModulFensterController(fensterId: id, window: window)
        controller[id] = wc
        NSApp.activate(ignoringOtherApps: true)
        wc.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        DispatchQueue.main.async {
            FenlynineOSMacWindowChrome.haerteModulFenster(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            hosting.view.needsLayout = true
            hosting.view.layoutSubtreeIfNeeded()
        }
        modulFensterLog.info("Fenster aktiv · offene Controller: \(self.controller.count)")
    }
    private func cascadeOrigin(on screen: NSScreen, size: NSSize) -> NSPoint {
        let visible = screen.visibleFrame
        let step: CGFloat = 28
        let i = CGFloat(cascadeIndex % 10)
        cascadeIndex += 1
        var x = visible.minX + 48 + i * step
        var y = visible.maxY - size.height - 48 - i * step
        if x + size.width > visible.maxX { x = visible.minX + 40 }
        if y < visible.minY { y = visible.minY + 40 }
        return NSPoint(x: x, y: y)
    }
}
extension Notification.Name {
    static let oeffneModulFenster = Notification.Name("fenlynineos.oeffneModulFenster")
    static let oeffneVergleichFenster = Notification.Name("fenlynineos.oeffneVergleichFenster")
}
enum ModulFensterBridge {
    private static var installiert = false
    static func installieren() {
        guard !installiert else { return }
        installiert = true
        NotificationCenter.default.addObserver(
            forName: .oeffneModulFenster,
            object: nil,
            queue: .main
        ) { note in
            let raw = (note.object as? String)
                ?? (note.userInfo?["modul"] as? String)
            guard let raw, let e = SeitenleistenEintrag(rawValue: raw) else {
                modulFensterLog.error("Modul-Fenster: ungültiger Schlüssel")
                return
            }
            Task { @MainActor in ModulFensterHost.shared.oeffneModul(e) }
        }
        NotificationCenter.default.addObserver(
            forName: .oeffneVergleichFenster,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in ModulFensterHost.shared.oeffneVergleich() }
        }
        modulFensterLog.info("ModulFensterBridge installiert")
    }
    static func oeffne(_ e: SeitenleistenEintrag) {
        installieren()
        Task { @MainActor in
            ModulFensterHost.shared.oeffneModul(e)
        }
    }
    static func oeffneVergleich() {
        installieren()
        Task { @MainActor in
            ModulFensterHost.shared.oeffneVergleich()
        }
    }
}
