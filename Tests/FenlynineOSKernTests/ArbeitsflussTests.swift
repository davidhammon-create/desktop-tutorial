import XCTest
@testable import FenlynineOSKern

final class ArbeitsflussTests: XCTestCase {

    func testAbgelaufeneFristStehtImmerVorn() {
        let s = Aktenstand(akteId: "a", eigeneArgumente: 0, offeneFristen: 2, ueberfaelligeFristen: 1,
                           tageBisNaechsteFrist: 20)
        let schritte = Arbeitsfluss.naechsteSchritte(s)
        XCTAssertEqual(schritte.first?.regel, "frist.ueberfaellig")
        XCTAssertEqual(schritte.first?.dringlichkeit, .kritisch)
        XCTAssertEqual(schritte.first?.modulId, "zeitleiste")
    }

    func testFristHeuteIstKritisch() {
        let s = Aktenstand(akteId: "a", offeneFristen: 1, tageBisNaechsteFrist: 0)
        XCTAssertEqual(Arbeitsfluss.naechsteSchritte(s).first?.titel, "Frist läuft heute ab")
    }

    func testLaufendeAkteOhneFristWirdGemeldet() {
        let s = Aktenstand(akteId: "a", hatRechtsfrage: true, hatProzessziel: true)
        XCTAssertTrue(Arbeitsfluss.naechsteSchritte(s).contains { $0.regel == "frist.keine" })
    }

    func testArgumentOhneBeweis() {
        let s = Aktenstand(akteId: "a", hatRechtsfrage: true, hatProzessziel: true, hatStreitwert: true,
                           hatPrognose: true, eigeneArgumente: 3, gegnerArgumente: 1,
                           eigeneArgumenteOhneBeweis: 2, dokumente: 1, offeneFristen: 1,
                           tageBisNaechsteFrist: 30)
        let schritte = Arbeitsfluss.naechsteSchritte(s)
        XCTAssertEqual(schritte.map(\.regel), ["vortrag.beweis"])
    }

    func testVergleichErstMitGrundlagePruefbar() {
        var s = Aktenstand(akteId: "a", hatRechtsfrage: true, hatProzessziel: true, hatStreitwert: true,
                           hatVergleichsangebot: true, eigeneArgumente: 1, gegnerArgumente: 1,
                           dokumente: 1, offeneFristen: 1, tageBisNaechsteFrist: 30)
        XCTAssertTrue(Arbeitsfluss.naechsteSchritte(s).contains { $0.regel == "verhandlung.grundlage" })
        s.hatPrognose = true
        let schritte = Arbeitsfluss.naechsteSchritte(s)
        XCTAssertTrue(schritte.contains { $0.regel == "verhandlung.pruefen" && $0.modulId == "strategos" })
        XCTAssertFalse(schritte.contains { $0.regel == "verhandlung.grundlage" })
    }

    func testVollstaendigeAkteHatKeineSchritte() {
        let s = Aktenstand(akteId: "a", hatRechtsfrage: true, hatProzessziel: true, hatStreitwert: true,
                           hatPrognose: true, eigeneArgumente: 3, gegnerArgumente: 2,
                           beweismittel: 3, dokumente: 4, offeneFristen: 1, tageBisNaechsteFrist: 40)
        XCTAssertTrue(Arbeitsfluss.naechsteSchritte(s).isEmpty)
    }

    func testAbgeschlosseneAkteNurNacharbeit() {
        let s = Aktenstand(akteId: "a", istAbgeschlossen: true)
        XCTAssertEqual(Arbeitsfluss.naechsteSchritte(s).map(\.regel), ["abschluss.ergebnis"])
    }

    func testUebersichtMischtAktenUndBegrenzt() {
        let leer = (1...5).map { Aktenstand(akteId: "leer\($0)") }
        let brand = Aktenstand(akteId: "brand", offeneFristen: 1, ueberfaelligeFristen: 1)
        let liste = Arbeitsfluss.uebersicht(leer + [brand], limit: 6, jeAkte: 2)
        XCTAssertEqual(liste.count, 6)
        XCTAssertEqual(liste.first?.akteId, "brand")
        XCTAssertLessThanOrEqual(liste.filter { $0.akteId == "leer1" }.count, 2)
    }

    func testGleicherStandGleicheEmpfehlung() {
        let s = Aktenstand(akteId: "a", eigeneArgumente: 2)
        XCTAssertEqual(Arbeitsfluss.naechsteSchritte(s), Arbeitsfluss.naechsteSchritte(s))
    }
}
