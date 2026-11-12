import Foundation

// MARK: - ModellAenderung
//
// Jede erlaubte Anpassung der App-Struktur ist eine eigene, kleine, benannte
// Änderung. Es gibt bewusst keine "setze beliebiges Feld"-Änderung: Ein Agent kann
// nur tun, was hier aufgezählt ist, und jede dieser Änderungen lässt sich umkehren.

public enum ModellAenderung: Codable, Hashable, Identifiable {
    case modulSichtbarkeit(modulId: String, sichtbar: Bool)
    case modulReihenfolge(modulId: String, neueReihenfolge: Int)
    case modulInZone(modulId: String, zoneId: String)
    case zoneSichtbarkeit(zoneId: String, sichtbar: Bool)
    case schrittReihenfolge(ablaufId: String, schrittId: String, neueReihenfolge: Int)
    case pflichtfeldHinzufuegen(ablaufId: String, schrittId: String, feld: String)
    case pflichtfeldEntfernen(ablaufId: String, schrittId: String, feld: String)
    case bestaetigungErforderlich(ablaufId: String, schrittId: String, erforderlich: Bool)
    case darstellungDichte(Darstellung.Dichte)
    case erklaersaetze(an: Bool)

    // MARK: Identität

    /// Stabile Kennung (aus Art und Parametern), damit eine Korrektur
    /// (`Korrektur.modellAendern`) auf genau diese Änderung verweisen kann.
    public var id: String {
        switch self {
        case let .modulSichtbarkeit(modulId, sichtbar):
            return "modulSichtbarkeit:\(modulId):\(sichtbar)"
        case let .modulReihenfolge(modulId, neu):
            return "modulReihenfolge:\(modulId):\(neu)"
        case let .modulInZone(modulId, zoneId):
            return "modulInZone:\(modulId):\(zoneId)"
        case let .zoneSichtbarkeit(zoneId, sichtbar):
            return "zoneSichtbarkeit:\(zoneId):\(sichtbar)"
        case let .schrittReihenfolge(ablaufId, schrittId, neu):
            return "schrittReihenfolge:\(ablaufId):\(schrittId):\(neu)"
        case let .pflichtfeldHinzufuegen(ablaufId, schrittId, feld):
            return "pflichtfeldHinzufuegen:\(ablaufId):\(schrittId):\(feld)"
        case let .pflichtfeldEntfernen(ablaufId, schrittId, feld):
            return "pflichtfeldEntfernen:\(ablaufId):\(schrittId):\(feld)"
        case let .bestaetigungErforderlich(ablaufId, schrittId, erforderlich):
            return "bestaetigungErforderlich:\(ablaufId):\(schrittId):\(erforderlich)"
        case let .darstellungDichte(dichte):
            return "darstellungDichte:\(dichte.rawValue)"
        case let .erklaersaetze(an):
            return "erklaersaetze:\(an)"
        }
    }

    // MARK: Beschreibung in Alltagssprache

    /// Kurzer Satz für Protokoll und Freigabe-Dialog. Nennt nur ids, weil ohne
    /// Modell keine Titel bekannt sind; `beschreibung(gegen:)` löst sie auf.
    public var beschreibung: String {
        beschreibung(modulName: { $0 }, zonenName: { $0 },
                     schrittName: { _, schritt in schritt })
    }

    /// Wie `beschreibung`, aber mit den Titeln aus dem Modell -- das liest sich für
    /// Menschen besser ("Modul ‚Honorare & Zeit' einblenden").
    public func beschreibung(gegen modell: Anwendungsmodell) -> String {
        beschreibung(
            modulName: { modell.modul($0)?.titel ?? $0 },
            zonenName: { modell.zone($0)?.titel ?? $0 },
            schrittName: { ablauf, schritt in
                modell.ablauf(ablauf)?.schritte.first { $0.id == schritt }?.titel ?? schritt
            })
    }

    private func beschreibung(modulName: (String) -> String,
                              zonenName: (String) -> String,
                              schrittName: (String, String) -> String) -> String {
        switch self {
        case let .modulSichtbarkeit(modulId, sichtbar):
            return "Modul ‚\(modulName(modulId))' \(sichtbar ? "einblenden" : "ausblenden")"
        case let .modulReihenfolge(modulId, neu):
            return "Modul ‚\(modulName(modulId))' an Position \(neu) setzen"
        case let .modulInZone(modulId, zoneId):
            return "Modul ‚\(modulName(modulId))' in den Bereich ‚\(zonenName(zoneId))' verschieben"
        case let .zoneSichtbarkeit(zoneId, sichtbar):
            return "Bereich ‚\(zonenName(zoneId))' \(sichtbar ? "einblenden" : "ausblenden")"
        case let .schrittReihenfolge(ablaufId, schrittId, neu):
            return "Schritt ‚\(schrittName(ablaufId, schrittId))' im Ablauf ‚\(ablaufId)' an Position \(neu) setzen"
        case let .pflichtfeldHinzufuegen(ablaufId, schrittId, feld):
            return "Feld ‚\(feld)' im Schritt ‚\(schrittName(ablaufId, schrittId))' zum Pflichtfeld machen"
        case let .pflichtfeldEntfernen(ablaufId, schrittId, feld):
            return "Feld ‚\(feld)' im Schritt ‚\(schrittName(ablaufId, schrittId))' nicht mehr verlangen"
        case let .bestaetigungErforderlich(ablaufId, schrittId, erforderlich):
            return erforderlich
                ? "Im Schritt ‚\(schrittName(ablaufId, schrittId))' eine Bestätigung verlangen"
                : "Im Schritt ‚\(schrittName(ablaufId, schrittId))' keine Bestätigung mehr verlangen"
        case let .darstellungDichte(dichte):
            return "Darstellung auf ‚\(dichte.rawValue)' stellen"
        case let .erklaersaetze(an):
            return "Erklärsätze \(an ? "einblenden" : "ausblenden")"
        }
    }

    // MARK: Umkehrbarkeit

    /// Alle Änderungen sind umkehrbar -- das ist der Punkt: Eine Anpassung, die sich
    /// nicht auf Knopfdruck zurücknehmen ließe, dürfte ein Agent nicht vornehmen.
    public var istUmkehrbar: Bool { true }

    /// Sicherungen sind Pflichtfelder und Bestätigungen (z. B. Vier-Augen bei
    /// Notfristen). Eine Änderung, die eine davon entfernt oder abschwächt, liefert
    /// hier `true`.
    ///
    /// WICHTIG: Solche Änderungen dürfen NIEMALS automatisch laufen -- weder durch
    /// den Wächter noch durch einen Agenten. Sie brauchen immer eine ausdrückliche
    /// menschliche Freigabe. Der Grund: Ein Agent, der seine eigenen Kontrollen
    /// abbauen kann, hat keine. Dass die Änderung umkehrbar ist, genügt nicht, denn
    /// bis zur Rücknahme könnte bereits eine Frist ungeprüft versäumt sein.
    /// Die Prüfung erzwingt der Aufrufer (Freigabe-Ablauf); der Verwalter kennt den
    /// Freigebenden nicht, stellt dieses Merkmal aber bereit.
    public var schwaechtSicherungAb: Bool {
        switch self {
        case .pflichtfeldEntfernen:
            return true
        case let .bestaetigungErforderlich(_, _, erforderlich):
            return !erforderlich
        default:
            return false
        }
    }

    /// Die Änderung, die den Zustand von `modell` wiederherstellt, wenn diese
    /// Änderung darauf angewendet wurde. `nil`, wenn das Ziel im Modell nicht
    /// existiert (dann lässt sich die Änderung ohnehin nicht anwenden).
    ///
    /// Die Umkehrung wird aus dem Zustand VOR der Änderung gebildet, nicht durch
    /// bloßes Spiegeln: War ein Modul schon ausgeblendet, ist "ausblenden" ein
    /// Nichtstun, und die Umkehrung muss es wieder ausgeblendet lassen.
    public func umkehrung(gegen modell: Anwendungsmodell) -> ModellAenderung? {
        switch self {
        case let .modulSichtbarkeit(modulId, _):
            guard let m = modell.modul(modulId) else { return nil }
            return .modulSichtbarkeit(modulId: modulId, sichtbar: m.sichtbar)

        case let .modulReihenfolge(modulId, _):
            guard let m = modell.modul(modulId) else { return nil }
            return .modulReihenfolge(modulId: modulId, neueReihenfolge: m.reihenfolge)

        case let .modulInZone(modulId, _):
            guard let m = modell.modul(modulId) else { return nil }
            return .modulInZone(modulId: modulId, zoneId: m.zoneId)

        case let .zoneSichtbarkeit(zoneId, _):
            guard let z = modell.zone(zoneId) else { return nil }
            return .zoneSichtbarkeit(zoneId: zoneId, sichtbar: z.sichtbar)

        case let .schrittReihenfolge(ablaufId, schrittId, _):
            guard let s = schritt(ablaufId, schrittId, in: modell) else { return nil }
            return .schrittReihenfolge(ablaufId: ablaufId, schrittId: schrittId,
                                       neueReihenfolge: s.reihenfolge)

        case let .pflichtfeldHinzufuegen(ablaufId, schrittId, feld),
             let .pflichtfeldEntfernen(ablaufId, schrittId, feld):
            guard let s = schritt(ablaufId, schrittId, in: modell) else { return nil }
            // War das Feld vorher schon Pflicht, stellt "hinzufügen" den Zustand her;
            // war es keins, stellt "entfernen" ihn her. Beides ist wiederholbar.
            return s.pflichtfelder.contains(feld)
                ? .pflichtfeldHinzufuegen(ablaufId: ablaufId, schrittId: schrittId, feld: feld)
                : .pflichtfeldEntfernen(ablaufId: ablaufId, schrittId: schrittId, feld: feld)

        case let .bestaetigungErforderlich(ablaufId, schrittId, _):
            guard let s = schritt(ablaufId, schrittId, in: modell) else { return nil }
            return .bestaetigungErforderlich(ablaufId: ablaufId, schrittId: schrittId,
                                             erforderlich: s.bestaetigungErforderlich)

        case .darstellungDichte:
            return .darstellungDichte(modell.darstellung.dichte)

        case .erklaersaetze:
            return .erklaersaetze(an: modell.darstellung.zeigeErklaersaetze)
        }
    }

    private func schritt(_ ablaufId: String, _ schrittId: String,
                         in modell: Anwendungsmodell) -> Ablaufschritt? {
        modell.ablauf(ablaufId)?.schritte.first { $0.id == schrittId }
    }
}
