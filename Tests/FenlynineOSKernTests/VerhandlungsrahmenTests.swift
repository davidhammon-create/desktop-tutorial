import XCTest
@testable import FenlynineOSKern

final class VerhandlungsrahmenTests: XCTestCase {

    // Untergrenze 90 < Obergrenze 130: es gibt einen Einigungsbereich (ZOPA).
    func testFallMitEinigungsbereich() throws {
        let r = Verhandlungsrahmen(eigeneAlternative: 100, gegnerAlternative: 120, zeitwertVerlust: 10)
        XCTAssertEqual(r.untergrenze, 90, accuracy: 1e-9)
        XCTAssertEqual(r.obergrenze, 130, accuracy: 1e-9)
        XCTAssertLessThan(r.untergrenze, r.obergrenze)
        let bereich = try XCTUnwrap(r.einigungsbereich)
        XCTAssertEqual(bereich.lowerBound, 90, accuracy: 1e-9)
        XCTAssertEqual(bereich.upperBound, 130, accuracy: 1e-9)
        XCTAssertTrue(r.klartext.hasPrefix("Einigungsbereich von"))
    }

    // Untergrenze 190 > Obergrenze 110: kein Einigungsbereich, der Klartext weist darauf hin.
    func testFallOhneEinigungsbereich() {
        let r = Verhandlungsrahmen(eigeneAlternative: 200, gegnerAlternative: 100, zeitwertVerlust: 10)
        XCTAssertGreaterThan(r.untergrenze, r.obergrenze)
        XCTAssertNil(r.einigungsbereich)
        XCTAssertTrue(r.klartext.contains("keinen Einigungsbereich"))
    }
}
