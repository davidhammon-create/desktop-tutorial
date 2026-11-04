import Foundation

/// Verhandlungsbereich (ZOPA) aus den Alternativen beider Seiten.
public struct Verhandlungsrahmen: Hashable, Sendable {
    public let eigeneAlternative: Double
    public let gegnerAlternative: Double
    public let zeitwertVerlust: Double

    public init(eigeneAlternative: Double,
                gegnerAlternative: Double,
                zeitwertVerlust: Double) {
        self.eigeneAlternative = eigeneAlternative
        self.gegnerAlternative = gegnerAlternative
        self.zeitwertVerlust = zeitwertVerlust
    }

    public var untergrenze: Double { eigeneAlternative - zeitwertVerlust }
    public var obergrenze: Double { gegnerAlternative + zeitwertVerlust }

    /// `nil`, wenn die Untergrenze über der Obergrenze liegt.
    public var einigungsbereich: ClosedRange<Double>? {
        untergrenze <= obergrenze ? untergrenze...obergrenze : nil
    }

    public var klartext: String {
        if let bereich = einigungsbereich {
            return "Einigungsbereich von \(Self.format(bereich.lowerBound)) bis \(Self.format(bereich.upperBound)). Jede Einigung in diesem Bereich stellt beide Seiten besser als das Verfahren."
        }
        return "Es gibt keinen Einigungsbereich: Beide Seiten fahren mit dem Verfahren besser als mit jeder Einigung. Das ist ungewöhnlich; mindestens eine Annahme (Alternativen oder Zeitwertverlust) muss falsch sein."
    }

    private static func format(_ wert: Double) -> String {
        String(format: "%.2f", wert)
    }
}
