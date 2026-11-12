import Foundation

// MARK: - Gemeinsame Kalenderhilfe für alle Regeln
//
// Regeln dürfen die Uhr nicht selbst fragen (siehe `Regel`): "heute" kommt aus dem
// Prüfzustand. Auch der Kalender ist festgelegt (gregorianisch, Zeitzone Berlin),
// damit eine Regel auf jedem Gerät und in jedem Test denselben Tag meint. Sonst
// könnte dieselbe Frist je nach Geräte-Zeitzone "heute" oder "morgen" fällig sein.
enum Regelkalender {
    static let kalender: Calendar = {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "Europe/Berlin") ?? TimeZone(secondsFromGMT: 3600)!
        return k
    }()

    /// Ganze Kalendertage von `von` bis `bis` (negativ, wenn `bis` in der Vergangenheit liegt).
    static func kalendertage(von: Date, bis: Date) -> Int {
        let a = kalender.startOfDay(for: von)
        let b = kalender.startOfDay(for: bis)
        return kalender.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// Beginn des letzten Werktags (Mo-Fr) vor dem Tag von `heute`.
    /// Feiertage sind bewusst nicht berücksichtigt: Im Zweifel prüft die Regel
    /// dann einmal zu oft, nie zu selten.
    static func letzterWerktag(vor heute: Date) -> Date {
        var tag = kalender.startOfDay(for: heute)
        repeat {
            tag = kalender.date(byAdding: .day, value: -1, to: tag) ?? tag.addingTimeInterval(-86_400)
            let wochentag = kalender.component(.weekday, from: tag) // 1 = Sonntag, 7 = Samstag
            if wochentag != 1 && wochentag != 7 { break }
        } while true
        return tag
    }
}

// MARK: - Fristenregeln
//
// Fristversäumnis ist der klassische Haftungsfall. Diese Regeln prüfen deshalb
// nicht die Frist selbst, sondern ob ihre Entstehung belegbar und abgesichert ist.
// Erledigte und gestrichene Fristen werden übersprungen: Dort ist nichts mehr zu retten.

private func offeneFristen(_ z: any Pruefzustand) -> [any PruefbareFrist] {
    z.fristen.filter { !$0.erledigt && !$0.gestrichen }
}

/// Frist ohne nachvollziehbare Herleitung.
public struct FristOhneHerleitungRegel: Regel {
    public let id = "frist.ohne.herleitung"
    public let version = "1.0"
    public let titel = "Frist ohne Herleitung"
    public let schwere: Schwere = .kritisch
    public let norm: String? = "§ 233 ZPO"

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        offeneFristen(zustand).filter { !$0.hatHerleitung }.map { f in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Für diese Frist ist nicht festgehalten, wie das Datum zustande kam. Wird sie versäumt, lässt sich im Haftungsfall nicht belegen, dass sie sorgfältig berechnet wurde -- und eine Wiedereinsetzung setzt genau diese Sorgfalt voraus.",
                   objektId: f.id, belegstelle: "Herleitung der Frist",
                   korrektur: .neuBerechnen(objektId: f.id, grund: "Herleitung fehlt; Frist mit nachvollziehbarer Rechnung neu berechnen"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Notfrist ohne Vier-Augen-Bestätigung.
public struct NotfristOhneVieraugenRegel: Regel {
    public let id = "notfrist.ohne.vieraugen"
    public let version = "1.0"
    public let titel = "Notfrist ohne Vier-Augen-Bestätigung"
    public let schwere: Schwere = .kritisch
    public let norm: String? = "§ 233 ZPO"

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        offeneFristen(zustand).filter { $0.istNotfrist && !$0.vierAugenBestaetigt }.map { f in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Eine Notfrist lässt sich nicht verlängern; ein Fehler ist nicht mehr gutzumachen. Deshalb soll eine zweite Person das Datum bestätigen. Ohne diese Bestätigung steht und fällt alles mit einer einzigen Berechnung.",
                   objektId: f.id, belegstelle: "Vier-Augen-Bestätigung",
                   korrektur: .pruefungAnfordern(objektId: f.id, frage: "Bitte die Notfrist durch eine zweite Person bestätigen lassen"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Frist ohne Vorfrist.
public struct FristOhneVorfristRegel: Regel {
    public let id = "frist.ohne.vorfrist"
    public let version = "1.0"
    public let titel = "Frist ohne Vorfrist"
    public let schwere: Schwere = .ernst
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        offeneFristen(zustand).filter { !$0.hatVorfrist }.map { f in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Ohne Vorfrist erfährt niemand rechtzeitig, dass die Frist naht. Krankheit oder ein voller Terminkalender am Fristtag reichen dann, um sie zu versäumen.",
                   objektId: f.id, belegstelle: "Vorfrist",
                   korrektur: .pruefungAnfordern(objektId: f.id, frage: "Bitte eine Vorfrist für diese Frist festlegen"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Frist ohne Verantwortlichen.
public struct FristOhneVerantwortlichenRegel: Regel {
    public let id = "frist.ohne.verantwortlichen"
    public let version = "1.0"
    public let titel = "Frist ohne Verantwortlichen"
    public let schwere: Schwere = .ernst
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        offeneFristen(zustand).filter { !$0.verantwortlicherGesetzt }.map { f in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Für diese Frist ist niemand zuständig. Wenn jeder annimmt, ein anderer kümmere sich, kümmert sich am Ende keiner.",
                   objektId: f.id, belegstelle: "Feld Verantwortlicher",
                   korrektur: .feldErgaenzen(objektId: f.id, feld: "verantwortlicher", vorschlag: "Zuständige Person eintragen"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Frist wurde mit einer älteren Kernversion berechnet.
public struct FristVeralteteBerechnungRegel: Regel {
    public let id = "frist.veraltete.berechnung"
    public let version = "1.0"
    public let titel = "Frist mit veralteter Berechnung"
    public let schwere: Schwere = .auffaellig
    public let norm: String? = nil

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        // `nil` (Version unbekannt) gilt ebenfalls als abweichend: Wer nicht weiß,
        // womit gerechnet wurde, kann die Rechnung nicht als aktuell ausgeben.
        offeneFristen(zustand).filter { $0.berechnetMitVersion != zustand.aktuelleKernversion }.map { f in
            Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Diese Frist wurde mit einer anderen Fassung der Rechenregeln berechnet als der heutigen. Seitdem können sich Regeln (etwa zu Feiertagen oder Zustellung) geändert haben; das Datum stimmt dann womöglich nicht mehr.",
                   objektId: f.id, belegstelle: "Berechnet mit Kernversion \(f.berechnetMitVersion ?? "unbekannt")",
                   korrektur: .neuBerechnen(objektId: f.id, grund: "Rechenregeln haben sich geändert (aktuell: \(zustand.aktuelleKernversion))"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Offene Frist läuft in weniger als 7 Kalendertagen ab (oder ist überschritten).
public struct FristKritischNahRegel: Regel {
    public let id = "frist.kritisch.nah"
    public let version = "1.0"
    public let titel = "Frist läuft in weniger als 7 Tagen ab"
    public let schwere: Schwere = .kritisch
    public let norm: String? = nil

    /// Schwelle in Kalendertagen.
    public let schwelleTage = 7

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        // Auch bereits überschrittene, noch offene Fristen (negative Tage) sind
        // gemeint: Sie sind das Dringendste von allem und dürfen nicht durchs Raster fallen.
        offeneFristen(zustand).filter {
            Regelkalender.kalendertage(von: zustand.heute, bis: $0.faelligkeit) < schwelleTage
        }.map { f in
            let tage = Regelkalender.kalendertage(von: zustand.heute, bis: f.faelligkeit)
            let wann = tage < 0 ? "ist seit \(-tage) Tag(en) überschritten" : "läuft in \(tage) Tag(en) ab"
            return Befund(regelId: id, regelVersion: version, schwere: schwere,
                   titel: titel,
                   erklaerung: "Diese offene Frist \(wann). Je näher das Ende rückt, desto weniger Spielraum bleibt für Rückfragen, Krankheit oder technische Probleme.",
                   objektId: f.id, belegstelle: "Fälligkeit",
                   korrektur: .markierungSetzen(objektId: f.id, markierung: "Frist dringend"),
                   norm: norm, gefundenAm: zustand.heute)
        }
    }
}

/// Die Ausgangskontrolle (Prüfung dessen, was die Kanzlei verlässt) ist überfällig.
public struct AusgangskontrolleFehltRegel: Regel {
    public let id = "ausgangskontrolle.fehlt"
    public let version = "1.0"
    public let titel = "Ausgangskontrolle überfällig"
    public let schwere: Schwere = .kritisch
    public let norm: String? = "§ 233 ZPO"

    public init() {}

    public func pruefe(_ zustand: any Pruefzustand) -> [Befund] {
        let grenze = Regelkalender.letzterWerktag(vor: zustand.heute)
        if let letzte = zustand.letzteAusgangskontrolle, letzte >= grenze {
            return []
        }
        return [Befund(regelId: id, regelVersion: version, schwere: schwere,
                       titel: titel,
                       erklaerung: "Die letzte Kontrolle der ausgehenden Schriftsätze liegt länger als einen Werktag zurück (oder hat noch nie stattgefunden). Die Ausgangskontrolle ist der letzte Schutz davor, dass ein Schriftsatz zu spät oder fehlerhaft hinausgeht.",
                       objektId: nil, belegstelle: "Protokoll der Ausgangskontrolle",
                       korrektur: .pruefungAnfordern(objektId: "ausgangskontrolle", frage: "Bitte die Ausgangskontrolle heute durchführen"),
                       norm: norm, gefundenAm: zustand.heute)]
    }
}
