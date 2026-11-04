import Foundation

/// Kostenrisiko eines Zivilverfahrens erster Instanz.
public struct Kostenrisiko: Hashable, Sendable {
    public let eigeneAnwaltskosten: Decimal
    public let gegnerAnwaltskosten: Decimal
    public let gerichtskosten: Decimal

    public init(eigeneAnwaltskosten: Decimal,
                gegnerAnwaltskosten: Decimal,
                gerichtskosten: Decimal) {
        self.eigeneAnwaltskosten = eigeneAnwaltskosten
        self.gegnerAnwaltskosten = gegnerAnwaltskosten
        self.gerichtskosten = gerichtskosten
    }

    /// Bei vollständiger Niederlage: eigene + gegnerische Anwaltskosten + Gerichtskosten (§ 91 ZPO).
    public var gesamtkostenBeiNiederlage: Decimal {
        eigeneAnwaltskosten + gegnerAnwaltskosten + gerichtskosten
    }

    /// Bei vollständigem Sieg trägt die eigene Seite keine Kosten (§ 91 ZPO).
    public var eigeneKostenBeiSieg: Decimal { 0 }

    /// Auslagenpauschale Nr. 7002 VV RVG: 20 % der Gebühren, höchstens 20 €.
    public static func auslagenpauschale(gebuehren: Decimal) -> Decimal {
        min(gebuehren * Decimal(string: "0.20")!, Decimal(20))   // Nr. 7002 VV RVG
    }

    /// Kostenrisiko erster Instanz. `nil`, wenn der Streitwert außerhalb der
    /// implementierten Tabelle liegt (> 500.000 €).
    /// - Parameter gerichtsgebuehr: einfache Gerichtsgebühr nach Anlage 2 zu § 34 GKG
    ///   (muss vom Aufrufer geliefert werden).
    public static func erstinstanz(streitwert: Decimal,
                                   ustSatz: Decimal = Decimal(string: "0.19")!,
                                   gerichtsgebuehr: Decimal) -> Kostenrisiko? {
        guard let einfach = RVGTabelle.gebuehr(streitwert: streitwert) else { return nil }
        let verfahren = einfach * Decimal(string: "1.3")!          // Nr. 3100 VV RVG
        let termin = einfach * Decimal(string: "1.2")!             // Nr. 3104 VV RVG
        let gebuehren = verfahren + termin
        let auslagen = auslagenpauschale(gebuehren: gebuehren)     // Nr. 7002 VV RVG
        let netto = gebuehren + auslagen
        let ust = netto * ustSatz                                  // Nr. 7008 VV RVG
        let anwalt = netto + ust
        let gericht = gerichtsgebuehr * Decimal(3)                 // KV 1210 GKG (3,0 Gebühren)
        return Kostenrisiko(eigeneAnwaltskosten: anwalt,
                            gegnerAnwaltskosten: anwalt,           // gleich hoch angenommen
                            gerichtskosten: gericht)
    }
}
