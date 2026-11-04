import XCTest
@testable import FenlynineOSKern

final class FristenRechnerTests: XCTestCase {

    // Berufungsfrist: 1 Monat, Notfrist (§ 517 ZPO, § 224 ZPO)
    private let berufungsfrist = Fristdefinition(
        laenge: 1, einheit: .monate, anfang: .ereignis,
        norm: "§ 517 ZPO", istNotfrist: true, verlaengerbar: false)

    // 1. § 187 Abs. 1, § 188 Abs. 2 BGB: Ereignisfrist, Ablauf am gleichen Tag des Folgemonats.
    func testBerufungsfristEinMonatOhneVerschiebung() {
        let h = FristenRechner.berechne(
            ereignis: datum(15, 4, 2024),
            ereignisBezeichnung: "Zustellung Urteil",
            definition: berufungsfrist,
            land: .by)
        XCTAssertEqual(h.rohesEnde, datum(15, 5, 2024))
        XCTAssertEqual(h.faelligkeit, datum(15, 5, 2024))
        XCTAssertNil(h.verschiebungsgrund)
        XCTAssertTrue(h.istNotfrist)
    }

    // 2. § 188 Abs. 3 BGB: Fehlt der Monatstag, endet die Frist am letzten Tag des Monats.
    // Schaltjahr 2024; prüft, dass Foundation den Monatstag kappt.
    func testMonatsendeKappungImSchaltjahr() {
        let h = FristenRechner.berechne(
            ereignis: datum(31, 1, 2024),
            ereignisBezeichnung: "Zustellung",
            definition: berufungsfrist,
            land: .by)
        XCTAssertEqual(h.rohesEnde, datum(29, 2, 2024))
        XCTAssertEqual(h.faelligkeit, datum(29, 2, 2024))
    }

    // 3. § 193 BGB / § 222 Abs. 2 ZPO: Fristende am Samstag -> nächster Werktag (Montag).
    // Einspruch gegen Versäumnisurteil: 2 Wochen (§ 339 ZPO).
    func testFristendeSamstagWirdAufMontagVerschoben() {
        let einspruch = Fristdefinition(
            laenge: 2, einheit: .wochen, anfang: .ereignis,
            norm: "§ 339 ZPO", istNotfrist: true, verlaengerbar: false)
        let h = FristenRechner.berechne(
            ereignis: datum(30, 3, 2024),
            ereignisBezeichnung: "Zustellung Versäumnisurteil",
            definition: einspruch,
            land: .nw)
        XCTAssertEqual(h.rohesEnde, datum(13, 4, 2024))
        XCTAssertEqual(h.faelligkeit, datum(15, 4, 2024))
        XCTAssertEqual(h.verschiebungsgrund, "Samstag")
    }

    // 4. § 4 KSchG: 3 Wochen ab Zugang der Kündigung (Ereignisfrist) über den Jahreswechsel.
    func testKuendigungsschutzklageDreiWochenUeberJahreswechsel() {
        let klage = Fristdefinition(
            laenge: 3, einheit: .wochen, anfang: .ereignis,
            norm: "§ 4 KSchG", istNotfrist: false, verlaengerbar: false)
        let h = FristenRechner.berechne(
            ereignis: datum(20, 12, 2023),
            ereignisBezeichnung: "Zugang der Kündigung",
            definition: klage,
            land: .hh)
        XCTAssertEqual(h.rohesEnde, datum(10, 1, 2024))
        XCTAssertEqual(h.faelligkeit, datum(10, 1, 2024))
        XCTAssertNil(h.verschiebungsgrund)
    }

    // 5. WICHTIGSTER TEST: § 193 BGB knüpft an den Erklärungsort an.
    // 31.10.2024 (Donnerstag): in NI Reformationstag (Feiertag), in NW nicht.
    // Allerheiligen (01.11.) gilt in NW, nicht in NI -- daher 01.11. in NI Werktag.
    func testErklaerungsortEntscheidetUeberFeiertag() {
        let (niTag, niGrund) = Feiertagskalender.naechsterWerktag(datum(31, 10, 2024), land: .ni)
        XCTAssertEqual(niTag, datum(1, 11, 2024))
        XCTAssertEqual(niGrund, "Reformationstag")

        let (nwTag, nwGrund) = Feiertagskalender.naechsterWerktag(datum(31, 10, 2024), land: .nw)
        XCTAssertEqual(nwTag, datum(31, 10, 2024))
        XCTAssertNil(nwGrund)
    }

    // 6. Ostersonntag (Meeus/Jones/Butcher) als Stützstellen für alle beweglichen Feiertage.
    func testOstersonntagStuetzstellen() {
        XCTAssertEqual(Feiertagskalender.ostersonntag(jahr: 2024), datum(31, 3, 2024))
        XCTAssertEqual(Feiertagskalender.ostersonntag(jahr: 2025), datum(20, 4, 2025))
        XCTAssertEqual(Feiertagskalender.ostersonntag(jahr: 2026), datum(5, 4, 2026))
    }

    // 7. Tag der Arbeit ist bundeseinheitlicher Feiertag: Donnerstag 01.05.2025 -> Freitag 02.05.2025.
    func testTagDerArbeitInJedemBundesland() {
        for land in Bundesland.allCases {
            let (tag, grund) = Feiertagskalender.naechsterWerktag(datum(1, 5, 2025), land: land)
            XCTAssertEqual(tag, datum(2, 5, 2025), "Land: \(land.rawValue)")
            XCTAssertEqual(grund, "Tag der Arbeit", "Land: \(land.rawValue)")
        }
    }

    // 8. § 199 Abs. 1 BGB: Die Regelverjährung (3 Jahre, § 195 BGB) beginnt erst mit
    // Schluss des Jahres der Entstehung -> Ende 31.12.2027, nicht 15.03.2027.
    func testRegelverjaehrungBeginntMitJahresschluss() {
        let h = FristenRechner.regelverjaehrung(entstehung: datum(15, 3, 2024), land: .by)
        XCTAssertEqual(h.faelligkeit, datum(31, 12, 2027))
        XCTAssertNotEqual(h.faelligkeit, datum(15, 3, 2027))
    }

    // 9. § 517 ZPO -- der Beginn ist gekappt, nicht das Ende.
    // Ohne (oder mit sehr später) Zustellung beginnt die Berufungsfrist spätestens
    // fünf Monate nach Verkündung und endet einen MONAT SPÄTER, also sechs Monate
    // nach Verkündung. Würde der Rechner stattdessen das Ende kappen, verlöre der
    // Mandant einen vollen Monat -- und die Berufung wäre als Notfrist unzulässig.
    func testBerufungsfristBeginnWirdGekapptNichtDasEnde() {
        let verkuendung = datum(10, 1, 2024)
        let spaeteZustellung = datum(20, 9, 2024)   // viel später als 5 Monate
        let berufung = Fristdefinition(
            laenge: 1, einheit: .monate, anfang: .ereignis,
            norm: "§ 517 ZPO", istNotfrist: true, verlaengerbar: false,
            spaetesterBeginnMonateAbVerkuendung: 5)

        let h = FristenRechner.berechne(
            ereignis: spaeteZustellung,
            ereignisBezeichnung: "Zustellung Urteil",
            definition: berufung, land: .by, verkuendung: verkuendung)

        // Spätester Beginn: 10.06.2024. Plus ein Monat: 10.07.2024 (Mittwoch).
        XCTAssertEqual(h.faelligkeit, datum(10, 7, 2024))
        // Und ausdrücklich NICHT der 10.06.2024 -- das wäre die gekappte Endfrist.
        XCTAssertNotEqual(h.faelligkeit, datum(10, 6, 2024))
        XCTAssertTrue(h.istNotfrist)
    }

    // 10. Liegt die Zustellung innerhalb der fünf Monate, bleibt sie maßgeblich.
    func testFrueheZustellungBleibtMassgeblich() {
        let berufung = Fristdefinition(
            laenge: 1, einheit: .monate, anfang: .ereignis,
            norm: "§ 517 ZPO", istNotfrist: true, verlaengerbar: false,
            spaetesterBeginnMonateAbVerkuendung: 5)
        let h = FristenRechner.berechne(
            ereignis: datum(15, 2, 2024),
            ereignisBezeichnung: "Zustellung Urteil",
            definition: berufung, land: .by, verkuendung: datum(10, 1, 2024))
        XCTAssertEqual(h.faelligkeit, datum(15, 3, 2024))
    }
}
