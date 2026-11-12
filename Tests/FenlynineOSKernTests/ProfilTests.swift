import XCTest
@testable import FenlynineOSKern

final class ProfilTests: XCTestCase {

    // MARK: - Grundlagen

    func testAlleStandardprofileHabenEindeutigeIds() {
        let ids = Nutzungsprofil.alleStandard.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count,
                       "Doppelte Profil-IDs gefunden.")
    }

    func testVollzugriffEnthaeltAlleModule() {
        let profil = Nutzungsprofil.vollzugriff
        let modell = Anwendungsmodell.standard
        for modul in modell.module {
            XCTAssertTrue(profil.sichtbareModulIds.contains(modul.id),
                          "Vollzugriff fehlt Modul ‚\(modul.id)'.")
        }
    }

    func testJedesProfilEnthaeltEinstellungen() {
        for profil in Nutzungsprofil.alleStandard {
            XCTAssertTrue(profil.sichtbareModulIds.contains("einstellungen"),
                          "Profil ‚\(profil.titel)' hat keine Einstellungen.")
        }
    }

    // MARK: - Profilwechsel

    func testProfilwechselBlendetModuleAusUndEin() throws {
        let verwalter = Modellverwalter()
        let profil = ProfilVerwalter()

        let anzahl = try profil.wechseln(zu: "rechtsfall",
                                         modellverwalter: verwalter)
        XCTAssertGreaterThan(anzahl, 0, "Es sollten Module ein-/ausgeblendet werden.")

        let modell = verwalter.aktuell
        let sichtbare = Set(modell.module.filter(\.sichtbar).map(\.id))
        let erwartet = Nutzungsprofil.rechtsfall.sichtbareModulIds

        for modulId in erwartet {
            if modell.modul(modulId) != nil {
                XCTAssertTrue(sichtbare.contains(modulId),
                              "Modul ‚\(modulId)' sollte nach Profilwechsel sichtbar sein.")
            }
        }
    }

    func testProfilwechselLaesstPflichtmoduleSichtbar() throws {
        let verwalter = Modellverwalter()
        let profil = ProfilVerwalter()

        try profil.wechseln(zu: "risikoanalyse", modellverwalter: verwalter)

        let modell = verwalter.aktuell
        let pflichtmodule = modell.module.filter(\.istPflichtmodul)
        for modul in pflichtmodule {
            XCTAssertTrue(modul.sichtbar,
                          "Pflichtmodul ‚\(modul.id)' wurde ausgeblendet.")
        }
    }

    func testUnbekanntesProfilWirftFehler() {
        let verwalter = Modellverwalter()
        let profil = ProfilVerwalter()

        XCTAssertThrowsError(try profil.wechseln(zu: "gibt-es-nicht",
                                                   modellverwalter: verwalter))
    }

    func testZweimalGleichesProfilAendertNichts() throws {
        let verwalter = Modellverwalter()
        let profil = ProfilVerwalter()

        try profil.wechseln(zu: "rechtsfall", modellverwalter: verwalter)
        let version1 = verwalter.aktuell.version

        let anzahl = try profil.wechseln(zu: "rechtsfall",
                                         modellverwalter: verwalter)
        XCTAssertEqual(anzahl, 0, "Ein erneuter Wechsel zum selben Profil sollte nichts ändern.")
        XCTAssertEqual(verwalter.aktuell.version, version1)
    }

    // MARK: - Verbünde

    func testRechtsfallHatVerbundFallKern() {
        let profil = Nutzungsprofil.rechtsfall
        let verbund = profil.verbuende.first { $0.id == "fall.kern" }
        XCTAssertNotNil(verbund)
        XCTAssertEqual(verbund?.leitmodulId, "lexara")
        XCTAssertTrue(verbund?.nebenmodulIds.contains("zeitleiste") ?? false)
    }

    func testVerbundPartnerLiefertAllePartner() {
        let profil = ProfilVerwalter(aktivesProfilId: "rechtsfall")
        let partner = profil.verbundPartner(fuer: "zeitleiste")
        XCTAssertTrue(partner.contains("lexara"),
                      "Zeitleiste sollte Lexara als Partner haben.")
    }

    // MARK: - Benutzerdefinierte Profile

    func testEigenesProfilErstellen() {
        let profil = ProfilVerwalter()
        let modell = Anwendungsmodell.standard
        let eigenes = profil.profilAusAktuellemZustand(
            id: "test.eigenes", titel: "Test", untertitel: "Test",
            symbol: "star", modell: modell)
        XCTAssertTrue(eigenes.istBenutzerdefiniert)
        XCTAssertFalse(eigenes.sichtbareModulIds.isEmpty)
    }

    func testEigenesProfilEntfernenGeht() {
        let profil = ProfilVerwalter()
        let eigenes = Nutzungsprofil(
            id: "test.eigenes", titel: "Test", untertitel: "Test",
            symbol: "star", sichtbareModulIds: ["einstellungen"],
            sichtbareZonenIds: ["system"], reihenfolge: 99,
            istBenutzerdefiniert: true)
        profil.profilHinzufuegen(eigenes)
        XCTAssertTrue(profil.profilEntfernen(id: "test.eigenes"))
    }

    func testStandardprofilKannNichtEntferntWerden() {
        let profil = ProfilVerwalter()
        XCTAssertFalse(profil.profilEntfernen(id: "vollzugriff"))
    }

    // MARK: - Hash-Kette bleibt intakt

    func testHashKetteNachProfilwechsel() throws {
        let verwalter = Modellverwalter()
        let profil = ProfilVerwalter()

        try profil.wechseln(zu: "rechtsfall", modellverwalter: verwalter)
        try profil.wechseln(zu: "risikoanalyse", modellverwalter: verwalter)
        try profil.wechseln(zu: "vollzugriff", modellverwalter: verwalter)

        XCTAssertTrue(verwalter.istUnversehrt(),
                      "Die Hash-Kette ist nach drei Profilwechseln nicht mehr intakt.")
    }
}
