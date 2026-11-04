import Foundation

/// Das Einzige, was Korrekturen tatsächlich in die Welt bringt -- und es liegt
/// AUSSERHALB des Kerns. Der Kern beschreibt nur, was zu tun wäre (`Korrektur`),
/// und schreibt selbst nichts. Wer den Ausführer baut (die App), muss jeden Fall
/// des Typs einzeln umsetzen; Falldaten kann er dabei nicht berühren, weil kein
/// Fall dafür existiert.
public protocol Korrekturausfuehrer {
    func fuehreAus(_ k: Korrektur) throws
}

/// Der Prüf- und Korrektur-Agent: wendet Regeln auf einen Zustand an, sortiert
/// die Befunde, führt je nach Autonomie folgenlose Korrekturen aus und
/// protokolliert alles in einer verketteten Spur.
public final class Waechter {
    public let regeln: [any Regel]
    public let autonomie: Autonomie
    public let protokoll: Pruefprotokoll

    private let jetzt: () -> Date
    private let sperre = NSLock()

    public init(regeln: [any Regel],
                autonomie: Autonomie = Autonomie.empfohlen,
                protokoll: Pruefprotokoll = Pruefprotokoll(),
                jetzt: @escaping () -> Date = { Date() }) {
        self.regeln = regeln
        self.autonomie = autonomie
        self.protokoll = protokoll
        self.jetzt = jetzt
    }

    /// Prüft den Zustand, führt ggf. folgenlose Korrekturen aus und hängt den Lauf ans Protokoll.
    ///
    /// Ohne `ausfuehrer` oder unterhalb von `.selbstheilend` wird nichts
    /// ausgeführt. Auf `.selbstheilend` laufen nur Korrekturen, die
    /// `darfAutomatischLaufen` bejahen -- alles andere bleibt Vorschlag.
    public func pruefe(_ zustand: any Pruefzustand,
                       ausfuehrer: (any Korrekturausfuehrer)? = nil) -> Prueflauf {
        // Ein Lauf nach dem anderen, sonst könnten zwei Läufe denselben
        // Vorgängerhash nehmen und die Kette gabeln.
        sperre.lock()
        defer { sperre.unlock() }

        let start = jetzt()

        var alle: [Befund] = []
        for regel in regeln {
            alle.append(contentsOf: regel.pruefe(zustand))
        }

        // Schwerstes zuerst; bei Gleichstand feste Reihenfolge, damit gleiche
        // Eingaben immer dasselbe Protokoll ergeben.
        let sortiert = alle.sorted { a, b in
            if a.schwere != b.schwere { return a.schwere > b.schwere }
            if a.titel != b.titel { return a.titel < b.titel }
            return (a.objektId ?? "") < (b.objektId ?? "")
        }

        var ausgefuehrt: [Korrektur] = []
        if autonomie == .selbstheilend, let ausfuehrer = ausfuehrer {
            for befund in sortiert {
                // istAutomatischBehebbar schliesst KI-Befunde mit ein:
                // ein Vorschlag aus einem Sprachmodell laeuft nie von selbst.
                guard befund.istAutomatischBehebbar,
                      let korrektur = befund.korrektur,
                      !ausgefuehrt.contains(korrektur) else { continue }
                do {
                    try ausfuehrer.fuehreAus(korrektur)
                    ausgefuehrt.append(korrektur)
                } catch {
                    // Misslingt eine Korrektur, bleibt der Befund bestehen und
                    // sie gilt nicht als ausgeführt -- im Protokoll steht nur,
                    // was wirklich geschah.
                    continue
                }
            }
        }

        let lauf = Prueflauf(gestartetAm: start,
                             beendetAm: jetzt(),
                             anzahlRegeln: regeln.count,
                             befunde: sortiert,
                             autonomie: autonomie,
                             ausgefuehrteKorrekturen: ausgefuehrt,
                             vorgaengerHash: protokoll.letzterHash)
        protokoll.anhaengen(lauf)
        return lauf
    }
}
