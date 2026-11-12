import XCTest
@testable import FenlynineOSKern

final class PortfolioTests: XCTestCase {

    // Einfache Testposition für das Protokoll `PortfolioPosition`.
    private struct Position: PortfolioPosition {
        var erwartungswert: Double
        var streuung: Double
        var rechtsgebiet: String? = nil
        var gegnerId: String? = nil
        var gericht: String? = nil
        var tragendeNorm: String? = nil
    }

    private func gleicheMerkmale(streuung: Double) -> Position {
        Position(erwartungswert: 1000, streuung: streuung,
                 rechtsgebiet: "Miete", gegnerId: "G1", gericht: "AG M", tragendeNorm: "§ 535 BGB")
    }

    // Unkorrelierte Positionen (keine gemeinsamen Merkmale): Varianzen addieren sich,
    // Gesamtstreuung = sqrt(s1² + s2²).
    func testUnkorrelierteStreuungIstWurzelAusQuadratsumme() {
        let a = Position(erwartungswert: 100, streuung: 30)
        let b = Position(erwartungswert: 200, streuung: 40)
        let k = Portfolio.kennzahlen([a, b])
        XCTAssertEqual(k.streuung, (30.0 * 30.0 + 40.0 * 40.0).squareRoot(), accuracy: 1e-9)
        XCTAssertEqual(k.ev, 300, accuracy: 1e-9)
    }

    // Identische Merkmale ergeben rechnerisch 1,2 -> gedeckelt auf 0,95.
    // Die Streuung ist deutlich größer als bei Unkorreliertheit.
    func testKorrelierteStreuungDeutlichGroesser() {
        let a = gleicheMerkmale(streuung: 100)
        let b = gleicheMerkmale(streuung: 100)
        let unkorreliert = (2.0 * 100.0 * 100.0).squareRoot()
        let erwartet = (2.0 * 10000.0 + 2.0 * 0.95 * 10000.0).squareRoot()
        let k = Portfolio.kennzahlen([a, b])
        XCTAssertEqual(k.streuung, erwartet, accuracy: 1e-9)
        XCTAssertGreaterThan(k.streuung, unkorreliert * 1.3)
    }

    // Die Korrelation überschreitet nie 0,95, auch wenn alle vier Merkmale übereinstimmen.
    func testKorrelationNieUeberNeunzigFuenfProzent() {
        let a = gleicheMerkmale(streuung: 1)
        let b = gleicheMerkmale(streuung: 1)
        XCTAssertEqual(Portfolio.korrelation(a, b), 0.95, accuracy: 1e-12)
        XCTAssertLessThanOrEqual(Portfolio.korrelation(a, b), 0.95)
    }

    // Fehlende Merkmale (nil) gelten nie als gleich.
    func testFehlendeMerkmaleKorrelierenNicht() {
        let a = Position(erwartungswert: 0, streuung: 1)
        let b = Position(erwartungswert: 0, streuung: 1)
        XCTAssertEqual(Portfolio.korrelation(a, b), 0.0, accuracy: 1e-12)
    }
}
