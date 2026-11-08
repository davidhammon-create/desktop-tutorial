import Foundation

// MARK: - ProfilVerwalter
//
// Verwaltet das aktive Profil und führt Profilwechsel über den Modellverwalter durch.
// Ein Profilwechsel ist eine Folge von ModellAenderungen (modulSichtbarkeit, zoneSichtbarkeit),
// die alle einzeln protokolliert und rücknehmbar sind.
//
// WICHTIG: Der Profilwechsel ändert NUR die Sichtbarkeit. Er kann keine Pflichtmodule
// ausblenden (der Modellverwalter würde das ablehnen), und er löscht keine Daten.

public final class ProfilVerwalter {

    public enum Profilfehler: Error, LocalizedError {
        case profilNichtGefunden(String)
        case modellverwalterFehler(String)

        public var errorDescription: String? {
            switch self {
            case let .profilNichtGefunden(id):
                return "Das Profil ‚\(id)' ist nicht vorhanden."
            case let .modellverwalterFehler(grund):
                return "Der Profilwechsel konnte nicht durchgeführt werden: \(grund)"
            }
        }
    }

    public private(set) var profile: [Nutzungsprofil]
    public private(set) var aktivesProfilId: String

    public init(profile: [Nutzungsprofil] = Nutzungsprofil.alleStandard,
                aktivesProfilId: String = "vollzugriff") {
        self.profile = profile
        self.aktivesProfilId = aktivesProfilId
    }

    public var aktivesProfil: Nutzungsprofil? {
        profile.first { $0.id == aktivesProfilId }
    }

    // MARK: Profilwechsel

    /// Wechselt zum Profil `profilId`. Erzeugt die nötigen ModellAenderungen und
    /// wendet sie über den Modellverwalter an. Pflichtmodule werden automatisch
    /// sichtbar gehalten.
    ///
    /// Rückgabe: Die Zahl der tatsächlich angewendeten Änderungen. Null bedeutet,
    /// dass die Sichtbarkeit schon dem Profil entsprach.
    @discardableResult
    public func wechseln(zu profilId: String,
                         modellverwalter: Modellverwalter,
                         von: String = "Profilwechsel") throws -> Int {
        guard let profil = profile.first(where: { $0.id == profilId }) else {
            throw Profilfehler.profilNichtGefunden(profilId)
        }

        let modell = modellverwalter.aktuell
        var aenderungen: [ModellAenderung] = []

        // Module: sichtbar setzen, wenn im Profil; ausblenden, wenn nicht.
        for modul in modell.module {
            let sollSichtbar = profil.sichtbareModulIds.contains(modul.id)
                            || modul.istPflichtmodul
            if modul.sichtbar != sollSichtbar {
                aenderungen.append(.modulSichtbarkeit(modulId: modul.id, sichtbar: sollSichtbar))
            }
        }

        // Zonen: sichtbar setzen, wenn im Profil.
        for zone in modell.zonen {
            let sollSichtbar = profil.sichtbareZonenIds.contains(zone.id)
            if zone.sichtbar != sollSichtbar {
                aenderungen.append(.zoneSichtbarkeit(zoneId: zone.id, sichtbar: sollSichtbar))
            }
        }

        // Alle Änderungen anwenden. Schlägt eine fehl (z. B. Pflichtmodul), bricht
        // der gesamte Wechsel ab. Das ist bewusst: Ein halber Profilwechsel wäre
        // verwirrender als keiner.
        var angewendet = 0
        for a in aenderungen {
            do {
                try modellverwalter.anwenden(a, von: von)
                angewendet += 1
            } catch {
                throw Profilfehler.modellverwalterFehler(error.localizedDescription)
            }
        }

        aktivesProfilId = profilId
        return angewendet
    }

    // MARK: Benutzerdefinierte Profile

    /// Erstellt ein neues Profil aus den aktuell sichtbaren Modulen.
    public func profilAusAktuellemZustand(id: String,
                                          titel: String,
                                          untertitel: String,
                                          symbol: String,
                                          modell: Anwendungsmodell) -> Nutzungsprofil {
        let sichtbareModule = Set(modell.module.filter(\.sichtbar).map(\.id))
        let sichtbareZonen = Set(modell.zonen.filter(\.sichtbar).map(\.id))
        return Nutzungsprofil(
            id: id,
            titel: titel,
            untertitel: untertitel,
            symbol: symbol,
            sichtbareModulIds: sichtbareModule,
            sichtbareZonenIds: sichtbareZonen,
            reihenfolge: (profile.map(\.reihenfolge).max() ?? 0) + 1,
            istBenutzerdefiniert: true)
    }

    /// Fügt ein benutzerdefiniertes Profil hinzu. Überschreibt ein bestehendes
    /// Profil mit derselben id.
    public func profilHinzufuegen(_ profil: Nutzungsprofil) {
        profile.removeAll { $0.id == profil.id }
        profile.append(profil)
        profile.sort { $0.reihenfolge < $1.reihenfolge }
    }

    /// Entfernt ein benutzerdefiniertes Profil. Mitgelieferte Profile können nicht
    /// entfernt werden.
    public func profilEntfernen(id: String) -> Bool {
        guard let profil = profile.first(where: { $0.id == id }),
              profil.istBenutzerdefiniert else { return false }
        profile.removeAll { $0.id == id }
        if aktivesProfilId == id { aktivesProfilId = "vollzugriff" }
        return true
    }

    // MARK: Verbund-Abfragen

    /// Liefert die Verbünde des aktiven Profils, in denen `modulId` vorkommt
    /// (als Leit- oder Nebenmodul).
    public func verbuende(fuer modulId: String) -> [Modulverbund] {
        guard let profil = aktivesProfil else { return [] }
        return profil.verbuende.filter {
            $0.leitmodulId == modulId || $0.nebenmodulIds.contains(modulId)
        }
    }

    /// Liefert alle Module, die im aktiven Profil mit `modulId` in einem Verbund
    /// stehen — also die Module, deren Daten querverknüpft werden.
    public func verbundPartner(fuer modulId: String) -> Set<String> {
        var partner = Set<String>()
        for v in verbuende(fuer: modulId) {
            partner.insert(v.leitmodulId)
            partner.formUnion(v.nebenmodulIds)
        }
        partner.remove(modulId)
        return partner
    }
}
