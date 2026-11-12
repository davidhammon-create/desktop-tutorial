import Foundation

/// Erwartungswert einer Wahrscheinlichkeit bei unsicheren Log-Odds.
///
/// Warum Gauß-Hermite-Quadratur statt Monte Carlo: Gesucht ist der Mittelwert einer
/// glatten Funktion (Logistik) über eine Normalverteilung. Dafür genügen 7
/// Auswertungen statt 3.000 Zufallsziehungen; das Ergebnis ist deterministisch
/// (kein Startwert-Problem, jeder Lauf identisch, also belegbar) und genauer
/// (Fehler unter 1e-6 statt rund 5e-3 Zufallsfehler). Monte Carlo bleibt nur dort
/// richtig, wo Pfadabhängigkeiten vorliegen -- hier nicht.
public enum Unsicherheit {

    // 7-Punkt-Gauß-Hermite (Gewichtsfunktion e^{-x^2}); Summe der Gewichte = sqrt(pi).
    private static let knoten: [Double] = [
        -2.651961356835233, -1.673551628767471, -0.816287882858965, 0,
         0.816287882858965,  1.673551628767471,  2.651961356835233
    ]
    private static let gewichte: [Double] = [
        0.000971781245099519, 0.054515582819127, 0.425607252610128,
        0.810264617556807,
        0.425607252610128, 0.054515582819127, 0.000971781245099519
    ]
    private static let wurzelPi = 1.772453850905516

    /// mittel = erwartete Log-Odds, streuung = Unsicherheit darauf (Log-Odds-Skala).
    /// Ergebnis: erwartete Wahrscheinlichkeit samt Bandbreite.
    public static func wahrscheinlichkeit(mittel: Double, streuung: Double)
        -> (erwartet: Double, unten: Double, oben: Double) {
        guard streuung > 0 else {
            let p = logistisch(mittel)
            return (p, p, p)
        }
        var summe = 0.0
        for (k, g) in zip(knoten, gewichte) {
            // Substitution x = mittel + sqrt(2) * streuung * k überführt das
            // Gauß-Hermite-Integral in den Normalverteilungs-Erwartungswert.
            let l = mittel + 1.4142135623730951 * streuung * k
            summe += g * logistisch(l)
        }
        let erwartet = summe / wurzelPi
        // 90-%-Band: 1,645 Standardabweichungen auf der Log-Odds-Skala. Auf dieser
        // Skala ist das Band symmetrisch und bleibt nach Rücktransformation in (0, 1).
        let unten = logistisch(mittel - 1.645 * streuung)
        let oben = logistisch(mittel + 1.645 * streuung)
        return (erwartet, unten, oben)
    }

    private static func logistisch(_ l: Double) -> Double {
        1 / (1 + exp(-l))
    }
}
