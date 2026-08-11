import SwiftUI
import AppKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// DESIGN-PRESETS -- professionell für Top-Kanzleien, jederzeit zurück
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum DesignPreset: String, CaseIterable, Identifiable, Codable {
case kanzleiPro // Neu: ruhig, typografisch, Anwaltsebene
case original // Bisheriges Noir/Atelier-System

var id: String { rawValue }

var titel: String {
  switch self {
  case .kanzleiPro: return "Kanzlei Pro"
  case .original: return "Original"
  }
}

var untertitel: String {
  switch self {
  case .kanzleiPro: return "Ruhig · präzise · für Partner & Gerichtsarbeit"
  case .original: return "Klassisches FenlynineOS-Design (Noir / Atelier)"
  }
}

var symbol: String {
  switch self {
  case .kanzleiPro: return "briefcase.fill"
  case .original: return "arrow.counterclockwise"
  }
}
}

@Observable
final class DesignPresetStore {
static let shared = DesignPresetStore()

private let key = "fenlynineos_design_preset_v1"
private let backupKey = "fenlynineos_design_preset_backup_v1"
private let backupModellKey = "fenlynineos_design_modell_backup_v1"
private let backupAppearanceKey = "fenlynineos_appearance_backup_v1"

var preset: DesignPreset {
  didSet {
    UserDefaults.standard.set(preset.rawValue, forKey: key)
    apply()
  }
}

private init() {
  let raw = UserDefaults.standard.string(forKey: key) ?? DesignPreset.kanzleiPro.rawValue
  preset = DesignPreset(rawValue: raw) ?? .kanzleiPro
  apply()
}

/// Speichert aktuellen Stand und wechselt zu Kanzlei Pro.
func aktiviereKanzleiPro(mitBackup: Bool = true) {
  setze(.kanzleiPro)
}

/// Stellt das zuvor gesicherte / Original-Design wieder her.
func zuruecksetzen() {
  if let raw = UserDefaults.standard.string(forKey: backupKey),
   let p = DesignPreset(rawValue: raw) {
    preset = p
  } else {
    preset = .original
  }
  if let mRaw = UserDefaults.standard.string(forKey: backupModellKey),
   let modell = FenlynineOSDesignModell(rawValue: mRaw) {
    FenlynineOSDesignStore.shared.setzeModell(modell)
  }
  if let aRaw = UserDefaults.standard.string(forKey: backupAppearanceKey),
   let modus = AppearanceModus(rawValue: aRaw) {
    AppearanceStore.shared.setze(modus)
  }
}

func setze(_ p: DesignPreset) {
  if p != preset { sichereStand() }
  let wechselZuPro = (p == .kanzleiPro && preset != .kanzleiPro)
  preset = p
  if wechselZuPro {
    // Einmalig beim Aktivieren: helles Profi-Arbeitslicht
    AppearanceStore.shared.setze(.atelier)
    FenlynineOSDesignStore.shared.setzeModell(.appleLight)
  }
  if p == .original {
    FenlynineOSDesignStore.shared.setzeModell(.visionOSDark)
  }
}

private func sichereStand() {
  UserDefaults.standard.set(preset.rawValue, forKey: backupKey)
  UserDefaults.standard.set(FenlynineOSDesignStore.shared.aktivesModell.rawValue, forKey: backupModellKey)
  UserDefaults.standard.set(AppearanceStore.shared.modus.rawValue, forKey: backupAppearanceKey)
}

private func apply() {
 // Kein Zwangs-Umschalten bei jedem Launch -- Noir bleibt wählbar.
 DispatchQueue.main.async {
   for w in NSApp.windows where w.canBecomeKey {
     w.appearance = NSAppearance(
       named: AppearanceStore.shared.istAtelier ? .aqua : .darkAqua
     )
   }
 }
}
}

/// Zusätzliche Flächen/Typo nur für Kanzlei-Pro -- additiv über Premium.
enum KanzleiPro {
static var aktiv: Bool { DesignPresetStore.shared.preset == .kanzleiPro }

static var seitenrand: CGFloat { aktiv ? 28 : 20 }
static var kopfTracking: CGFloat { aktiv ? 1.2 : 0.5 }

static var kanzleiPapier: Color {
 AppearanceStore.shared.istAtelier
   ? Color(red: 0.985, green: 0.986, blue: 0.99)
   : Premium.void
}
}

struct DesignPresetPicker: View {
@Bindable private var store = DesignPresetStore.shared

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   Text("Design-Preset")
     .font(.system(size: 14, weight: .semibold))
     .foregroundStyle(Premium.text)
   Text("Kanzlei Pro ist für Top-Anwälte optimiert. Original stellt Ihr bisheriges Design wieder her.")
     .font(.system(size: 11))
     .foregroundStyle(Premium.textSoft)

   ForEach(DesignPreset.allCases) { p in
     Button {
       store.setze(p)
     } label: {
       HStack(spacing: 10) {
         Image(systemName: p.symbol)
           .foregroundStyle(store.preset == p ? Premium.action : Premium.textSoft)
           .frame(width: 22)
         VStack(alignment: .leading, spacing: 2) {
           Text(p.titel)
             .font(.system(size: 13, weight: .semibold))
             .foregroundStyle(Premium.text)
           Text(p.untertitel)
             .font(.system(size: 11))
             .foregroundStyle(Premium.textSoft)
         }
         Spacer()
         if store.preset == p {
           Image(systemName: "checkmark.circle.fill")
             .foregroundStyle(Premium.action)
         }
       }
       .padding(12)
       .background(
         RoundedRectangle(cornerRadius: 10)
           .fill(store.preset == p ? Premium.action.opacity(0.08) : Premium.panel)
       )
       .overlay(
         RoundedRectangle(cornerRadius: 10)
           .stroke(store.preset == p ? Premium.action.opacity(0.35) : Premium.hairline, lineWidth: 1)
       )
     }
     .buttonStyle(.plain)
   }

   Button("Design zurücksetzen (Original)") {
     store.zuruecksetzen()
   }
   .buttonStyle(.bordered)
 }
}
}

