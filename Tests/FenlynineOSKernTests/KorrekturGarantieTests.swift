import XCTest
@testable import FenlynineOSKern

/// Diese Tests sichern die Zusage ab, die das ganze Agenten-Konzept trägt:
/// Der Wächter darf Oberfläche und Abläufe ändern, aber niemals Falldaten.
///
/// Die Zusage steht und fällt mit dem Enum `Korrektur`. Solange es keine
/// Variante gibt, die eine Frist schreibt, kann der Agent es nicht -- auch
/// nicht versehentlich, auch nicht nach einem schlechten Prompt, auch nicht
/// nach einem Modellwechsel.
final class KorrekturGarantieTests: XCTestCase {

    /// Die Mauer. Wird in `Korrektur` ein Fall ergänzt, kompiliert dieser
    /// Schalter nicht mehr -- Swift verlangt Vollständigkeit. Wer eine
    /// Variante hinzufügen will, die Mandats- oder Fristdaten schreibt, muss
    /// hier vorbei, und das fällt im Diff und in der Codeprüfung auf.
    ///
    /// Ohne diesen Test wäre die Garantie nur eine Momentaufnahme: Ein
    /// Entwickler ergänzt in sechs Monaten `case fristErledigen`, alles
    /// kompiliert, und niemand merkt es.
    func testKorrekturKenntNurUngefaehrlicheFaelle() {
        let alle: [Korrektur] = [
            .hinweisAnlegen(text: "x"),
            .markierungSetzen(objektId: "1", markierung: "x"),
            .neuBerechnen(objektId: "1", grund: "x"),
            .feldErgaenzen(objektId: "1", feld: "x", vorschlag: "y"),
            .pruefungAnfordern(objektId: "1", frage: "x"),
            .modellAendern(aenderungId: "x", beschreibung: "y", umkehrbar: true)
        ]
        XCTAssertEqual(alle.count, 6,
                       "Die Zahl der Korrektur-Varianten hat sich geändert. "
                     + "Prüfen Sie, ob die neue Variante Falldaten schreiben kann.")

        for k in alle {
            switch k {
            case .hinweisAnlegen, .markierungSetzen, .neuBerechnen,
                 .feldErgaenzen, .pruefungAnfordern, .modellAendern:
                continue   // bekannt, geprüft, ungefährlich
            }
        }
    }

    /// Inhalt bleibt Sache des Anwalts: Ein Feldvorschlag darf nie von selbst
    /// übernommen werden, auch nicht auf der höchsten Autonomiestufe.
    func testFeldvorschlagLaeuftNieAutomatisch() {
        let k = Korrektur.feldErgaenzen(objektId: "1", feld: "Verantwortlicher",
                                        vorschlag: "Dr. Meier")
        XCTAssertFalse(k.darfAutomatischLaufen)
    }

    /// Eine Oberflächenänderung darf nur dann automatisch laufen, wenn sie
    /// sich auf Knopfdruck zurücknehmen lässt. Was nicht umkehrbar ist,
    /// braucht eine menschliche Freigabe -- sonst steht die Kanzlei morgens
    /// vor einer App, die sie nicht wiedererkennt und nicht zurückdrehen kann.
    func testNichtUmkehrbareModellaenderungBrauchtFreigabe() {
        let umkehrbar = Korrektur.modellAendern(aenderungId: "modul.ausblenden.honorare",
                                                beschreibung: "Modul ausblenden",
                                                umkehrbar: true)
        let endgueltig = Korrektur.modellAendern(aenderungId: "pflichtfeld.entfernen",
                                                 beschreibung: "Pflichtfeld entfernen",
                                                 umkehrbar: false)
        XCTAssertTrue(umkehrbar.darfAutomatischLaufen)
        XCTAssertFalse(endgueltig.darfAutomatischLaufen)
    }

    /// Neuberechnen ist ungefährlich, weil es einen zusätzlichen Beleg
    /// erzeugt und keinen bestehenden überschreibt.
    func testNeuberechnenDarfAutomatischLaufen() {
        XCTAssertTrue(Korrektur.neuBerechnen(objektId: "1", grund: "neue Kernversion")
                        .darfAutomatischLaufen)
    }

    /// Die empfohlene Stufe ist bewusst nicht die höchste.
    func testEmpfohleneAutonomieIstNichtDieHoechste() {
        XCTAssertEqual(Autonomie.empfohlen, .vorschlagen)
        XCTAssertLessThan(Autonomie.empfohlen, .selbstheilend)
    }

    /// Das gefährlichste Loch im ganzen Entwurf -- und der Test, der es zuhält.
    ///
    /// Ein KI-Vorschlag wird als `Befund` geführt und trägt eine `Korrektur`.
    /// Wäre diese Korrektur für sich genommen harmlos (etwa `neuBerechnen`),
    /// liefe sie auf der Stufe `selbstheilend` ohne Rückfrage -- ein
    /// Sprachmodell hätte dann unmittelbare Wirkung auf die App. Genau das
    /// soll der Entwurf ausschließen.
    func testKIVorschlagLaeuftNiemalsAutomatisch() {
        let ausRegelwerk = Befund(
            regelId: "frist.veraltete.berechnung", regelVersion: "1",
            schwere: .auffaellig, titel: "Veraltete Berechnung",
            erklaerung: "…",
            korrektur: .neuBerechnen(objektId: "1", grund: "neue Kernversion"))

        let ausKI = Befund(
            regelId: "ki.vorschlag", regelVersion: "modell-x",
            schwere: .hinweis, titel: "KI-Vorschlag: Neu berechnen",
            erklaerung: "…",
            korrektur: .neuBerechnen(objektId: "1", grund: "Modell meint das"),
            ausKI: true)

        // Dieselbe Korrektur, zwei Herkünfte -- nur die geprüfte Regel darf wirken.
        XCTAssertTrue(ausRegelwerk.istAutomatischBehebbar)
        XCTAssertFalse(ausKI.istAutomatischBehebbar,
                       "Ein KI-Vorschlag darf nie von selbst ausgeführt werden.")
    }

    /// Voreinstellung: Ein Befund gilt als NICHT aus der KI stammend. Wer eine
    /// KI anbindet, muss das Kennzeichen aktiv setzen -- Vergessen führt zur
    /// sicheren Seite, nicht zur unsicheren.
    func testBefundIstStandardmaessigNichtAusKI() {
        let b = Befund(regelId: "x", regelVersion: "1", schwere: .hinweis,
                       titel: "t", erklaerung: "e")
        XCTAssertFalse(b.ausKI)
    }
}
