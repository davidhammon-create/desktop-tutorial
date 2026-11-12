import Foundation

/// Bayessche Aktualisierung auf der Log-Odds-Skala.
public enum Prognoserechner {

    /// Dämpfung für jeden weiteren Beitrag derselben Quelle.
    public static let daempfungWeitererBeitraege = 0.5

    /// Ein Schritt des Rechenwegs -- so kann der Anwalt die Kette dem Mandanten vorlesen.
    public struct Schritt: Hashable, Sendable {
        public let bezeichnung: String
        /// Beitrag auf der Log-Odds-Skala nach Dämpfung.
        public let logOdds: Double
        /// Dämpfungsfaktor (1 = voll gezählt).
        public let daempfung: Double
        /// Wahrscheinlichkeit nach diesem Schritt.
        public let wahrscheinlichkeitDanach: Double
        public let begruendung: String

        public init(bezeichnung: String, logOdds: Double, daempfung: Double,
                    wahrscheinlichkeitDanach: Double, begruendung: String) {
            self.bezeichnung = bezeichnung
            self.logOdds = logOdds
            self.daempfung = daempfung
            self.wahrscheinlichkeitDanach = wahrscheinlichkeitDanach
            self.begruendung = begruendung
        }
    }

    public struct Herleitung: Hashable, Sendable {
        public let prior: Double
        public let schritte: [Schritt]
        public let ergebnis: Double

        public init(prior: Double, schritte: [Schritt], ergebnis: Double) {
            self.prior = prior
            self.schritte = schritte
            self.ergebnis = ergebnis
        }
    }

    public static func rechne(prior: Double, beitraege: [Beitrag]) -> Double {
        rechneMitHerleitung(prior: prior, beitraege: beitraege).ergebnis
    }

    /// Wie `rechne`, liefert aber die Schrittliste mit. Die Reihenfolge ist
    /// deterministisch (Gruppen nach erstem Auftreten), damit der Rechenweg
    /// bei gleicher Eingabe immer gleich aussieht -- Voraussetzung für Rechenbelege.
    public static func rechneMitHerleitung(prior: Double, beitraege: [Beitrag]) -> Herleitung {
        // Prior auf das offene Intervall begrenzen: log(0) bzw. Division durch 0
        // würde sonst das gesamte Ergebnis zu NaN/Inf machen.
        let p0 = min(1 - 1e-9, max(1e-9, prior))
        var l = log(p0 / (1 - p0))

        // Beiträge ohne Gruppe sind unabhängig und bilden je eine eigene Gruppe.
        var reihenfolge: [String] = []
        var gruppen: [String: [Beitrag]] = [:]
        for (i, b) in beitraege.enumerated() {
            let schluessel = b.quellenGruppe.map { "g:" + $0 } ?? "e:\(i)"
            if gruppen[schluessel] == nil { reihenfolge.append(schluessel) }
            gruppen[schluessel, default: []].append(b)
        }

        var schritte: [Schritt] = []
        for schluessel in reihenfolge {
            // Stärkster Beitrag zuerst und voll; jeder weitere gedämpft, damit
            // korrelierte Evidenz nicht doppelt zählt. Stabile Sortierung über Index.
            let sortiert = (gruppen[schluessel] ?? []).enumerated()
                .sorted { a, b in
                    let x = abs(a.element.logOdds), y = abs(b.element.logOdds)
                    return x != y ? x > y : a.offset < b.offset
                }
                .map { $0.element }
            for (i, b) in sortiert.enumerated() {
                let d = i == 0 ? 1.0 : daempfungWeitererBeitraege
                let beitrag = b.logOdds * d
                l += beitrag
                schritte.append(Schritt(bezeichnung: b.bezeichnung,
                                        logOdds: beitrag,
                                        daempfung: d,
                                        wahrscheinlichkeitDanach: logistisch(l),
                                        begruendung: b.begruendung))
            }
        }
        return Herleitung(prior: p0, schritte: schritte, ergebnis: logistisch(l))
    }

    private static func logistisch(_ l: Double) -> Double {
        1 / (1 + exp(-l))
    }
}
