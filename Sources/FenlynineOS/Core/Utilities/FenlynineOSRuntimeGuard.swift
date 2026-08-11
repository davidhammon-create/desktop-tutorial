import Foundation
import SwiftUI

// MARK: - Laufzeit-Absicherung (Abstürze vermeiden)

enum FenlynineOSRuntimeGuard {
/// Sicherer Array-Zugriff -- nil statt Crash.
static func element<T>(_ array: [T], at index: Int) -> T? {
  guard index >= 0, index < array.count else { return nil }
  return array[index]
}

/// Fragebogen-Schrittindex begrenzen wenn Schritte sich ändern (Strategos-Sync).
static func clampIndex(_ index: Int, count: Int) -> Int {
  guard count > 0 else { return 0 }
  return min(max(0, index), count - 1)
}
}

/// Fallback-Schritt wenn Fragebogen leer (sollte nie vorkommen).
enum PragFragebogenFallback {
static let leererSchritt = PragFragebogenSchritt(
  index: 0,
  titel: "LAGEFRAGEBOGEN",
  untertitel: "Standardfragen laden …",
  strategosBezug: nil,
  fragen: []
)
}

extension OpportunismaViewModel {
func clampFragebogenSchritt() {
  fragebogenSchrittIndex = FenlynineOSRuntimeGuard.clampIndex(
    fragebogenSchrittIndex,
    count: fragebogenSchritte.count
  )
}
}

