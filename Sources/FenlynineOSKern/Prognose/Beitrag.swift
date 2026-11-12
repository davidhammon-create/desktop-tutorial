import Foundation

/// Ein Beitrag zur Prognose -- vom Anwalt in einer Sprache angegeben, die er
/// tatsächlich beherrscht ("verdoppelt die Chancen") statt in Log-Odds.
public struct Beitrag: Codable, Identifiable, Hashable, Sendable {

    public enum Staerke: String, Codable, CaseIterable, Hashable, Sendable {
        case schwach        // "spricht leicht dafür"
        case merklich       // "verdoppelt die Chancen etwa"
        case stark          // "vervierfacht sie etwa"
        case entscheidend   // "zehnfach -- das trägt den Fall"

        /// Bayes-Faktor: wirkt multiplikativ auf die Odds. Die Stufen sind bewusst
        /// grob -- Scheingenauigkeit wäre derselbe Fehler noch einmal, nur feiner.
        public var faktor: Double {
            switch self {
            case .schwach:      return 1.5
            case .merklich:     return 2.0
            case .stark:        return 4.0
            case .entscheidend: return 10.0
            }
        }

        public var beschreibung: String {
            switch self {
            case .schwach:      return "spricht leicht dafür (Faktor 1,5)"
            case .merklich:     return "verdoppelt die Chancen (Faktor 2)"
            case .stark:        return "vervierfacht die Chancen (Faktor 4)"
            case .entscheidend: return "trägt den Fall (Faktor 10)"
            }
        }
    }

    public var id: UUID
    /// z. B. "BGH VIII ZR 1/23 -- direkt einschlägig"
    public var bezeichnung: String
    public var staerke: Staerke
    public var fuerUns: Bool
    /// Pflichtfeld: Ein Beitrag ohne Begründung ist nicht verteidigungsfähig.
    public var begruendung: String
    public var gesetztVon: String
    public var gesetztAm: Date
    /// Abhängigkeiten: zwei Beweise aus derselben Quelle zählen nicht doppelt.
    /// z. B. "Zeuge Schmidt", "Vertragsakte 2023"
    public var quellenGruppe: String?

    public init(id: UUID = UUID(),
                bezeichnung: String,
                staerke: Staerke,
                fuerUns: Bool,
                begruendung: String,
                gesetztVon: String,
                gesetztAm: Date = Date(),
                quellenGruppe: String? = nil) {
        self.id = id
        self.bezeichnung = bezeichnung
        self.staerke = staerke
        self.fuerUns = fuerUns
        self.begruendung = begruendung
        self.gesetztVon = gesetztVon
        self.gesetztAm = gesetztAm
        self.quellenGruppe = quellenGruppe
    }

    /// Wirkung auf der Log-Odds-Skala: auf dieser Skala werden Beiträge addiert,
    /// weil sich Bayes-Faktoren dort nicht multiplizieren müssen.
    public var logOdds: Double {
        (fuerUns ? 1 : -1) * log(staerke.faktor)
    }
}
