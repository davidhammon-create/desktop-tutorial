import Foundation

// ACHTUNG -- VOR AUSLIEFERUNG PRÜFEN:
// Sämtliche Werte dieser Tabelle sind vor der Auslieferung gegen Anlage 2 RVG
// (Gebührentabelle zu § 13 Abs. 1 RVG) in der jeweils geltenden Fassung zu
// prüfen. Der Gesetzgeber ändert die Beträge gelegentlich (zuletzt KostRÄG);
// eine unbemerkt veraltete Tabelle führt zu falschen Kostenrisiko-Angaben.
//
// Oberhalb von 500.000 € Gegenstandswert gilt § 13 Abs. 1 S. 3 RVG
// (Erhöhung je angefangene 50.000 € um einen festen Betrag). Dieser Bereich
// ist bewusst NICHT implementiert: `gebuehr(streitwert:)` liefert dort `nil`,
// statt einen Wert zu raten. Der Aufrufer muss den Fall sichtbar machen.

/// Wertgebühr nach Anlage 2 zu § 13 Abs. 1 RVG (einfache Gebühr, 1,0).
public enum RVGTabelle {

    /// Fassung, gegen die die Tabelle zu prüfen ist.
    public static let fassung = "Anlage 2 RVG"

    /// Datum der letzten Prüfung gegen den Gesetzestext (muss bei Prüfung
    /// aktualisiert werden).
    public static let geprueftAm = "2026-11-04 (ungeprüft, Prüfung vor Auslieferung offen)"

    /// Stufen: Gegenstandswert bis einschließlich `bis` -> einfache Gebühr.
    public static let stufen: [(bis: Decimal, gebuehr: Decimal)] = [
        (500, 49), (1000, 88), (1500, 127), (2000, 166),
        (3000, 222), (4000, 278), (5000, 334), (6000, 390),
        (7000, 446), (8000, 502), (9000, 558), (10000, 614),
        (13000, 666), (16000, 718), (19000, 770), (22000, 822),
        (25000, 874), (30000, 955), (35000, 1036), (40000, 1117),
        (45000, 1198), (50000, 1279), (65000, 1373), (80000, 1467),
        (95000, 1561), (110000, 1655), (125000, 1749), (140000, 1843),
        (155000, 1937), (170000, 2031), (185000, 2125), (200000, 2219),
        (230000, 2351), (260000, 2483), (290000, 2615), (320000, 2747),
        (350000, 2879), (380000, 3011), (410000, 3143), (440000, 3275),
        (470000, 3407), (500000, 3539)
    ]

    /// Einfache Gebühr: erste Stufe mit `streitwert <= bis`.
    /// Oberhalb von 500.000 € `nil` (§ 13 Abs. 1 S. 3 RVG nicht implementiert).
    public static func gebuehr(streitwert: Decimal) -> Decimal? {
        for stufe in stufen where streitwert <= stufe.bis {
            return stufe.gebuehr
        }
        return nil
    }
}
