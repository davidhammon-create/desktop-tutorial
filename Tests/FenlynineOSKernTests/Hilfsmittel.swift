import Foundation
@testable import FenlynineOSKern

/// Baut aus Tag/Monat/Jahr ein Date (00:00 Uhr) im selben Kalender und in derselben
/// Zeitzone wie `Feiertagskalender.kalender`. Ohne diese Konstruktion schlagen
/// Datumsvergleiche je nach Zeitzone des Testrechners fehl.
func datum(_ tag: Int, _ monat: Int, _ jahr: Int) -> Date {
    Feiertagskalender.kalender.date(
        from: DateComponents(year: jahr, month: monat, day: tag))!
}
