import SwiftUI
import AppKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// APPEARANCE -- Noir (OLED) + Atelier (hell, Apple-filigran)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Atelier = zusätzlicher Modus. Optik aus iCloud-Referenz:
// reines Weiß · Label/Wert-Zeilen · dünne Hairlines · Status-Badges
// · großzügiger Weißraum · SF · keine schweren Karten.
// Systemweit + programmweit über AppearanceStore.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum AppearanceModus: String, CaseIterable, Identifiable, Codable {
case noir // bestehendes Premium-Dunkel
case atelier // neuer Hellmodus

var id: String { rawValue }

var titel: String {
  switch self {
  case .noir: return "Noir"
  case .atelier: return "Atelier"
  }
}

var untertitel: String {
  switch self {
  case .noir: return "OLED · Entscheidung · Kontrast"
  case .atelier: return "Hell · Dokument · Apple-filigran"
  }
}

var symbol: String {
  switch self {
  case .noir: return "moon.fill"
  case .atelier: return "sun.max.fill"
  }
}

var preferredScheme: ColorScheme {
  switch self {
  case .noir: return .dark
  case .atelier: return .light
  }
}
}

@Observable
final class AppearanceStore {
static let shared = AppearanceStore()

private let key = "fenlynineos_appearance_modus_v1"
/// Optional: folgt Systemhelligkeit (sonst manuell).
private let systemKey = "fenlynineos_appearance_follow_system"

var modus: AppearanceModus {
  didSet {
    UserDefaults.standard.set(modus.rawValue, forKey: key)
    applySystemChrome()
  }
}

var folgtSystem: Bool {
  didSet {
    UserDefaults.standard.set(folgtSystem, forKey: systemKey)
    if folgtSystem { syncFromSystem() }
  }
}

private init() {
  let raw = UserDefaults.standard.string(forKey: key) ?? AppearanceModus.noir.rawValue
  modus = AppearanceModus(rawValue: raw) ?? .noir
  folgtSystem = UserDefaults.standard.bool(forKey: systemKey)
  if folgtSystem { syncFromSystem() }
  applySystemChrome()
}

func toggle() {
  folgtSystem = false
  modus = (modus == .noir) ? .atelier : .noir
}

func setze(_ m: AppearanceModus) {
  folgtSystem = false
  modus = m
}

func syncFromSystem() {
  let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
  modus = dark ? .noir : .atelier
}

private func applySystemChrome() {
  // Fenster-Chrome folgt dem Modus (macOS Titlebar)
  DispatchQueue.main.async {
    for w in NSApp.windows where w.canBecomeKey {
      w.appearance = NSAppearance(named: self.modus == .noir ? .darkAqua : .aqua)
    }
  }
}

var istAtelier: Bool { modus == .atelier }
}

extension View {
/// Bindet AppearanceStore und setzt ColorScheme.
func fenlynineOSAppearance() -> some View {
 modifier(FenlynineOSAppearanceModifier())
}
}

private struct FenlynineOSAppearanceModifier: ViewModifier {
@Bindable private var appearance = AppearanceStore.shared

func body(content: Content) -> some View {
 content
   .preferredColorScheme(appearance.modus.preferredScheme)
   .animation(.easeInOut(duration: 0.2), value: appearance.modus)
}
}

// MARK: - Umschalter (filigran)

struct AppearanceToggle: View {
@Bindable private var appearance = AppearanceStore.shared

var body: some View {
 HStack(spacing: 4) {
   ForEach(AppearanceModus.allCases) { m in
     Button {
       appearance.setze(m)
     } label: {
       Image(systemName: m.symbol)
         .font(.system(size: 11, weight: .semibold))
         .foregroundStyle(appearance.modus == m ? Premium.action : Premium.textSoft)
         .frame(width: 28, height: 24)
         .background(
           RoundedRectangle(cornerRadius: 6, style: .continuous)
             .fill(appearance.modus == m ? Premium.action.opacity(0.14) : Color.clear)
         )
     }
     .buttonStyle(.plain)
     .help(m.titel + " -- " + m.untertitel)
   }
 }
 .padding(3)
 .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(Premium.hairline, lineWidth: 1))
}
}

