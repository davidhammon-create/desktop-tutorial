import XCTest
@testable import FenlynineOSKern

final class RVGTests: XCTestCase {

    // Golden-Test gegen Tippfehler in der Tabelle (Anlage 2 zu § 13 Abs. 1 RVG).
    func testGebuehrStuetzstellen() {
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 500), Decimal(49))
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 5000), Decimal(334))
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 10000), Decimal(614))
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 13000), Decimal(666))
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 25000), Decimal(874))
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 50000), Decimal(1279))
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 200000), Decimal(2219))
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: 500000), Decimal(3539))
    }

    // Stufengrenze: "bis einschließlich 5.000 €" -- 5.000,01 € fällt in die nächste Stufe.
    func testStufengrenzeNaechsteStufe() {
        XCTAssertEqual(RVGTabelle.gebuehr(streitwert: Decimal(string: "5000.01")!), Decimal(390))
    }

    // § 13 Abs. 1 S. 3 RVG ist nicht implementiert: jenseits der Tabelle wird nicht geschätzt.
    func testJenseitsDerTabelleLiefertNil() {
        XCTAssertNil(RVGTabelle.gebuehr(streitwert: 600000))
    }

    // Nr. 7002 VV RVG: 20 % der Gebühren, höchstens 20 € (Deckel greift).
    // Hinweis: die Funktion liegt in `Kostenrisiko`, nicht in `RVGTabelle`.
    func testAuslagenpauschaleDeckelGreift() {
        XCTAssertEqual(Kostenrisiko.auslagenpauschale(gebuehren: 2410), Decimal(20))
    }

    func testAuslagenpauschaleProzentsatzBeiKleinenGebuehren() {
        XCTAssertEqual(Kostenrisiko.auslagenpauschale(gebuehren: 50), Decimal(10))
    }

    // Dokumentiert die Schwelle: 20 % von 100 € = 20 € -- ab 100 € Gebühren greift der Deckel.
    func testDeckelGreiftAbHundertEuroGebuehren() {
        XCTAssertEqual(Kostenrisiko.auslagenpauschale(gebuehren: 99), Decimal(string: "19.8")!)
        XCTAssertEqual(Kostenrisiko.auslagenpauschale(gebuehren: 100), Decimal(20))
        XCTAssertEqual(Kostenrisiko.auslagenpauschale(gebuehren: 101), Decimal(20))
    }
}
