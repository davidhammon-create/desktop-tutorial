import Foundation

// MARK: - Modellverwalter
//
// Einzige Stelle, die das Anwendungsmodell verändert. Jede Änderung wird geprüft,
// angewendet und als neuer Eintrag in eine Hash-Kette gehängt (wie beim
// Rechenbeleg: kanonisch serialisiert, SHA256 bzw. Fallback). Es wird nie etwas
// gelöscht oder überschrieben -- auch eine Rücknahme ist ein neuer Eintrag. So
// bleibt jederzeit nachvollziehbar, wer wann was an der App geändert hat.
//
// Freigabe: Der Verwalter erzwingt KEINE menschliche Freigabe. Wer
// `ModellAenderung.schwaechtSicherungAb` meldet, muss vom Aufrufer vorher freigegeben
// worden sein; der Verwalter kennt die Freigabe nicht, nur den Namen in `von`.

public struct Modellversion: Codable, Identifiable {
    /// Entspricht `modell.version`; dadurch eindeutig und für `zuruecknehmen` nutzbar.
    public var id: Int { modell.version }
    /// Vollständiger Stand nach dieser Änderung (Struktur ist klein, und so ist
    /// ein Rückroll ohne Neuberechnung möglich).
    public var modell: Anwendungsmodell
    /// `nil` beim Ausgangsstand und bei einem Rückroll (der Rückroll ist keine
    /// einzelne Änderung, sondern die Wiederherstellung eines ganzen Stands).
    public var aenderung: ModellAenderung?
    public var angewendetAm: Date
    public var angewendetVon: String
    /// Hash des Vorgängereintrags; beim ersten Eintrag leer.
    public var vorgaengerHash: String
    public var eigenerHash: String

    public init(modell: Anwendungsmodell,
                aenderung: ModellAenderung?,
                angewendetAm: Date,
                angewendetVon: String,
                vorgaengerHash: String,
                eigenerHash: String) {
        self.modell = modell
        self.aenderung = aenderung
        self.angewendetAm = angewendetAm
        self.angewendetVon = angewendetVon
        self.vorgaengerHash = vorgaengerHash
        self.eigenerHash = eigenerHash
    }
}

public final class Modellverwalter {

    public enum Modellfehler: Error, Equatable, LocalizedError {
        case pflichtmodulAusgeblendet(modulId: String)
        case unbekanntesModul(String)
        case unbekannteZone(String)
        case unbekannterAblauf(String)
        case unbekannterSchritt(ablaufId: String, schrittId: String)
        case ungueltigeReihenfolge(Int)
        case leeresFeld
        case versionNichtGefunden(Int)

        public var errorDescription: String? {
            switch self {
            case let .pflichtmodulAusgeblendet(id):
                return "Das Pflichtmodul ‚\(id)' darf nicht ausgeblendet werden."
            case let .unbekanntesModul(id):
                return "Das Modul ‚\(id)' gibt es nicht."
            case let .unbekannteZone(id):
                return "Der Bereich ‚\(id)' gibt es nicht."
            case let .unbekannterAblauf(id):
                return "Den Ablauf ‚\(id)' gibt es nicht."
            case let .unbekannterSchritt(ablaufId, schrittId):
                return "Den Schritt ‚\(schrittId)' gibt es im Ablauf ‚\(ablaufId)' nicht."
            case let .ungueltigeReihenfolge(wert):
                return "Die Reihenfolge \(wert) ist ungültig (nicht negativ erlaubt)."
            case .leeresFeld:
                return "Der Feldname darf nicht leer sein."
            case let .versionNichtGefunden(version):
                return "Die Version \(version) ist im Verlauf nicht vorhanden."
            }
        }
    }

    public private(set) var aktuell: Anwendungsmodell
    public private(set) var verlauf: [Modellversion]

    private let sperre = NSLock()

    /// Startet mit einem Ausgangsstand als erstem Verlaufseintrag.
    public init(startmodell: Anwendungsmodell = .standard, von: String = "System") {
        let am = Modellverwalter.ganzeSekunden(startmodell.geaendertAm)
        var start = startmodell
        start.geaendertAm = am
        self.aktuell = start
        let hash = Modellverwalter.hash(vorgaengerHash: "", modell: start, aenderung: nil,
                                        am: am, von: von)
        self.verlauf = [Modellversion(modell: start, aenderung: nil, angewendetAm: am,
                                      angewendetVon: von, vorgaengerHash: "",
                                      eigenerHash: hash)]
    }

    // MARK: Anwenden

    /// Prüft die Änderung, wendet sie an und hängt sie an den Verlauf. Bei einem
    /// Fehler bleibt alles unverändert.
    @discardableResult
    public func anwenden(_ a: ModellAenderung, von: String) throws -> Modellversion {
        sperre.lock()
        defer { sperre.unlock() }

        var neu = try angewendet(a, auf: aktuell)
        let jetzt = Modellverwalter.ganzeSekunden(Date())
        neu.version = aktuell.version + 1
        neu.geaendertAm = jetzt
        neu.geaendertVon = von
        return anhaengen(neu, aenderung: a, am: jetzt, von: von)
    }

    // MARK: Zurücknehmen

    /// Stellt den Stand einer früheren Version wieder her. Das ist ein NEUER
    /// Verlaufseintrag mit neuer Versionsnummer; der Verlauf dazwischen bleibt
    /// vollständig erhalten (Protokolltreue -- man sieht auch, dass zurückgerollt wurde).
    @discardableResult
    public func zuruecknehmen(bisVersion: Int, von: String) throws -> Modellversion {
        sperre.lock()
        defer { sperre.unlock() }

        guard let ziel = verlauf.first(where: { $0.modell.version == bisVersion }) else {
            throw Modellfehler.versionNichtGefunden(bisVersion)
        }
        var neu = ziel.modell
        let jetzt = Modellverwalter.ganzeSekunden(Date())
        neu.version = aktuell.version + 1
        neu.geaendertAm = jetzt
        neu.geaendertVon = von
        return anhaengen(neu, aenderung: nil, am: jetzt, von: von)
    }

    /// Würde ein Rückroll auf `bisVersion` eine Sicherung abschwächen (ein
    /// Pflichtfeld oder eine Bestätigung, die jetzt gilt, entfiele)? Ein Rückroll
    /// kann dieselbe Wirkung haben wie `pflichtfeldEntfernen`; dann gilt dieselbe
    /// Regel: nur mit menschlicher Freigabe. `nil`, wenn die Version fehlt.
    public func rueckrollSchwaechtSicherungAb(bisVersion: Int) -> Bool? {
        sperre.lock()
        defer { sperre.unlock() }

        guard let ziel = verlauf.first(where: { $0.modell.version == bisVersion })?.modell else {
            return nil
        }
        for ablauf in aktuell.ablaeufe {
            for schritt in ablauf.schritte {
                // Fehlt der Schritt im Ziel, ist er dort weder Pflicht noch geprüft.
                let zielSchritt = ziel.ablauf(ablauf.id)?.schritte.first { $0.id == schritt.id }
                if schritt.bestaetigungErforderlich && zielSchritt?.bestaetigungErforderlich != true {
                    return true
                }
                let zielPflicht = Set(zielSchritt?.pflichtfelder ?? [])
                if !Set(schritt.pflichtfelder).isSubset(of: zielPflicht) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: Unversehrtheit

    /// Prüft die Hash-Kette: jeder Eintrag verweist auf den Hash seines Vorgängers,
    /// sein eigener Hash passt zum Inhalt, und `aktuell` ist der letzte Stand.
    /// Wurde ein Eintrag nachträglich verändert oder entfernt, schlägt das fehl.
    public func istUnversehrt() -> Bool {
        sperre.lock()
        defer { sperre.unlock() }

        guard let letzte = verlauf.last, letzte.modell == aktuell else { return false }
        var erwarteterVorgaenger = ""
        for eintrag in verlauf {
            guard eintrag.vorgaengerHash == erwarteterVorgaenger else { return false }
            let neu = Modellverwalter.hash(vorgaengerHash: eintrag.vorgaengerHash,
                                           modell: eintrag.modell,
                                           aenderung: eintrag.aenderung,
                                           am: eintrag.angewendetAm,
                                           von: eintrag.angewendetVon)
            guard neu == eintrag.eigenerHash else { return false }
            erwarteterVorgaenger = eintrag.eigenerHash
        }
        return true
    }

    // MARK: Intern

    private func anhaengen(_ neu: Anwendungsmodell, aenderung: ModellAenderung?,
                           am: Date, von: String) -> Modellversion {
        let vorgaenger = verlauf.last?.eigenerHash ?? ""
        let hash = Modellverwalter.hash(vorgaengerHash: vorgaenger, modell: neu,
                                        aenderung: aenderung, am: am, von: von)
        let eintrag = Modellversion(modell: neu, aenderung: aenderung, angewendetAm: am,
                                    angewendetVon: von, vorgaengerHash: vorgaenger,
                                    eigenerHash: hash)
        verlauf.append(eintrag)
        aktuell = neu
        return eintrag
    }

    /// Inhalt, über den gehasht wird. Eigene Struktur, damit die Reihenfolge der
    /// Felder und die Kanonisierung (sortierte Schlüssel) eindeutig sind.
    private struct Hashinhalt: Encodable {
        let vorgaengerHash: String
        let modell: Anwendungsmodell
        let aenderung: ModellAenderung?
        let angewendetAm: Date
        let angewendetVon: String
    }

    /// Schlägt das Hashen fehl (praktisch ausgeschlossen), entsteht ein Marker, der
    /// nie zu einer Neuberechnung passt -- `istUnversehrt()` meldet dann `false`,
    /// also lieber zu streng als zu lax.
    private static func hash(vorgaengerHash: String, modell: Anwendungsmodell,
                             aenderung: ModellAenderung?, am: Date, von: String) -> String {
        let inhalt = Hashinhalt(vorgaengerHash: vorgaengerHash, modell: modell,
                                aenderung: aenderung, angewendetAm: am, angewendetVon: von)
        return (try? Rechenkern.hash(inhalt)) ?? "hashfehler"
    }

    /// ISO-8601 im Hash kennt nur ganze Sekunden; würden wir Bruchteile speichern,
    /// ergäbe derselbe Eintrag nach dem Speichern und Laden einen anderen Hash.
    private static func ganzeSekunden(_ datum: Date) -> Date {
        Date(timeIntervalSince1970: datum.timeIntervalSince1970.rounded(.down))
    }

    // MARK: Gültigkeitsprüfung und Anwendung

    private func angewendet(_ a: ModellAenderung,
                            auf modell: Anwendungsmodell) throws -> Anwendungsmodell {
        var neu = modell
        switch a {
        case let .modulSichtbarkeit(modulId, sichtbar):
            let i = try modulIndex(modulId, in: neu)
            // Pflichtmodule bleiben immer erreichbar -- sonst könnte eine Anpassung
            // Fristen, Berufspflichten oder die Rücknahme selbst verbergen.
            if !sichtbar && neu.module[i].istPflichtmodul {
                throw Modellfehler.pflichtmodulAusgeblendet(modulId: modulId)
            }
            neu.module[i].sichtbar = sichtbar

        case let .modulReihenfolge(modulId, neueReihenfolge):
            let i = try modulIndex(modulId, in: neu)
            try pruefeReihenfolge(neueReihenfolge)
            neu.module[i].reihenfolge = neueReihenfolge

        case let .modulInZone(modulId, zoneId):
            let i = try modulIndex(modulId, in: neu)
            guard let zone = neu.zone(zoneId) else {
                throw Modellfehler.unbekannteZone(zoneId)
            }
            // In eine ausgeblendete Zone verschoben, wäre ein Pflichtmodul indirekt weg.
            if !zone.sichtbar && neu.module[i].istPflichtmodul {
                throw Modellfehler.pflichtmodulAusgeblendet(modulId: modulId)
            }
            neu.module[i].zoneId = zoneId

        case let .zoneSichtbarkeit(zoneId, sichtbar):
            guard let i = neu.zonen.firstIndex(where: { $0.id == zoneId }) else {
                throw Modellfehler.unbekannteZone(zoneId)
            }
            // Eine Zone mit Pflichtmodul auszublenden blendet das Pflichtmodul mit aus.
            if !sichtbar,
               let pflicht = neu.module.first(where: { $0.zoneId == zoneId && $0.istPflichtmodul }) {
                throw Modellfehler.pflichtmodulAusgeblendet(modulId: pflicht.id)
            }
            neu.zonen[i].sichtbar = sichtbar

        case let .schrittReihenfolge(ablaufId, schrittId, neueReihenfolge):
            let (ai, si) = try schrittIndex(ablaufId, schrittId, in: neu)
            try pruefeReihenfolge(neueReihenfolge)
            neu.ablaeufe[ai].schritte[si].reihenfolge = neueReihenfolge

        case let .pflichtfeldHinzufuegen(ablaufId, schrittId, feld):
            let (ai, si) = try schrittIndex(ablaufId, schrittId, in: neu)
            let name = feld.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { throw Modellfehler.leeresFeld }
            if !neu.ablaeufe[ai].schritte[si].pflichtfelder.contains(name) {
                neu.ablaeufe[ai].schritte[si].pflichtfelder.append(name)
            }

        case let .pflichtfeldEntfernen(ablaufId, schrittId, feld):
            let (ai, si) = try schrittIndex(ablaufId, schrittId, in: neu)
            neu.ablaeufe[ai].schritte[si].pflichtfelder.removeAll { $0 == feld }

        case let .bestaetigungErforderlich(ablaufId, schrittId, erforderlich):
            let (ai, si) = try schrittIndex(ablaufId, schrittId, in: neu)
            neu.ablaeufe[ai].schritte[si].bestaetigungErforderlich = erforderlich

        case let .darstellungDichte(dichte):
            neu.darstellung.dichte = dichte

        case let .erklaersaetze(an):
            neu.darstellung.zeigeErklaersaetze = an
        }
        return neu
    }

    private func modulIndex(_ id: String, in modell: Anwendungsmodell) throws -> Int {
        guard let i = modell.module.firstIndex(where: { $0.id == id }) else {
            throw Modellfehler.unbekanntesModul(id)
        }
        return i
    }

    private func schrittIndex(_ ablaufId: String, _ schrittId: String,
                              in modell: Anwendungsmodell) throws -> (Int, Int) {
        guard let ai = modell.ablaeufe.firstIndex(where: { $0.id == ablaufId }) else {
            throw Modellfehler.unbekannterAblauf(ablaufId)
        }
        guard let si = modell.ablaeufe[ai].schritte.firstIndex(where: { $0.id == schrittId }) else {
            throw Modellfehler.unbekannterSchritt(ablaufId: ablaufId, schrittId: schrittId)
        }
        return (ai, si)
    }

    private func pruefeReihenfolge(_ wert: Int) throws {
        guard wert >= 0 else { throw Modellfehler.ungueltigeReihenfolge(wert) }
    }
}
