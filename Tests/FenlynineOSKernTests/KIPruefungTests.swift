import XCTest
@testable import FenlynineOSKern

final class PseudonymisiererTests: XCTestCase {

    func testBekannterNameWirdErsetztUndWiederhergestellt() {
        var p = Pseudonymisierer(bekannteNamen: ["Dr. Hans Müller", "Bauwerk Nord GmbH"])
        let text = "Dr. Hans Müller klagt gegen die Bauwerk Nord GmbH. Herr Müller verlangt Lohn."
        let raus = p.pseudonymisiere(text)
        XCTAssertFalse(raus.contains("Müller"), raus)
        XCTAssertFalse(raus.contains("Bauwerk"), raus)
        XCTAssertTrue(raus.contains("[[PERSON_1]]"))
        XCTAssertTrue(raus.contains("[[PERSON_2]]"))
        // Voller Name und Nachname zeigen auf dieselbe Person.
        XCTAssertEqual(p.anzahl, 2)
        let zurueck = p.wiederherstellen(raus)
        XCTAssertTrue(zurueck.contains("Bauwerk Nord GmbH"))
        XCTAssertFalse(zurueck.contains("[["))
    }

    func testMehrdeutigerNachnameBleibtStehen() {
        var p = Pseudonymisierer(bekannteNamen: ["Anna Richter"])
        let raus = p.pseudonymisiere("Der Richter fragte Anna Richter nach dem Vertrag.")
        XCTAssertTrue(raus.hasPrefix("Der Richter fragte [[PERSON_1]]"), raus)
    }

    func testNameNurAlsGanzesWort() {
        var p = Pseudonymisierer(bekannteNamen: ["Lang"])
        let raus = p.pseudonymisiere("Die Langfristigkeit betrifft Frau Lang.")
        XCTAssertTrue(raus.contains("Langfristigkeit"))
        XCTAssertTrue(raus.hasSuffix("Frau [[PERSON_1]]."), raus)
    }

    func testMusterEmailIbanTelefonAnschrift() {
        var p = Pseudonymisierer()
        let text = "Mail an h.mueller@kanzlei-nord.de, Tel. 030 1234567, "
                 + "IBAN DE89 3704 0044 0532 0130 00, wohnhaft Hauptstraße 12, 10115 Berlin, "
                 + "geb. 03.04.1980."
        let raus = p.pseudonymisiere(text)
        XCTAssertFalse(raus.contains("@"), raus)
        XCTAssertFalse(raus.contains("3704"), raus)
        XCTAssertFalse(raus.contains("1234567"), raus)
        XCTAssertFalse(raus.contains("Hauptstraße"), raus)
        XCTAssertFalse(raus.contains("1980"), raus)
        XCTAssertEqual(p.wiederherstellen(raus), text)
    }

    func testInstanzAktenzeichenGeschuetztBundesgerichtBleibt() {
        var p = Pseudonymisierer()
        let raus = p.pseudonymisiere("Unser Verfahren 12 O 345/23; vgl. BGH VIII ZR 123/21 und BAG 2 AZR 45/20.")
        XCTAssertFalse(raus.contains("12 O 345/23"), raus)
        XCTAssertTrue(raus.contains("VIII ZR 123/21"), raus)
        XCTAssertTrue(raus.contains("2 AZR 45/20"), raus)
    }

    func testFristdatenUndBetraegeBleibenUnberuehrt() {
        var p = Pseudonymisierer()
        let text = "Zustellung am 03.11.2026, Streitwert 12.500,00 €, Frist § 517 ZPO."
        XCTAssertEqual(p.pseudonymisiere(text), text)
        XCTAssertEqual(p.anzahl, 0)
    }

    func testGleicheAngabeGleicherPlatzhalter() {
        var p = Pseudonymisierer()
        let a = p.pseudonymisiere("a@b.de")
        let b = p.pseudonymisiere("Nochmals A@B.de bitte")
        XCTAssertEqual(a, "[[EMAIL_1]]")
        XCTAssertTrue(b.contains("[[EMAIL_1]]"))
    }

    func testWiederherstellenTolerantGegenUmformung() {
        var p = Pseudonymisierer(bekannteNamen: ["Erika Beispiel"])
        _ = p.pseudonymisiere("Erika Beispiel")
        XCTAssertEqual(p.wiederherstellen("Für [PERSON_1] und [[ person_1 ]]."),
                       "Für Erika Beispiel und Erika Beispiel.")
    }

    func testJSONWiederherstellungBleibtGueltig() throws {
        var p = Pseudonymisierer(bekannteNamen: ["Firma \"Alpha\" KG"])
        let raus = p.pseudonymisiere("Firma \"Alpha\" KG")
        let json = "{\"partei\": \"\(raus)\"}"
        let fertig = p.wiederherstellenInJSON(json)
        let obj = try JSONSerialization.jsonObject(with: Data(fertig.utf8)) as? [String: String]
        XCTAssertEqual(obj?["partei"], "Firma 'Alpha' KG")
    }
}

final class NormzitatPrueferTests: XCTestCase {

    func testEinfacheZitate() {
        let z = NormzitatPruefer.zitate(in: "Anspruch aus § 280 Abs. 1 BGB i.V.m. § 241 Abs. 2 BGB; Frist § 4 KSchG.")
        XCTAssertEqual(z.map(\.kurz), ["§ 280 BGB", "§ 241 BGB", "§ 4 KSchG"])
    }

    func testMehrfachzitatUndBuchstabe() {
        let z = NormzitatPruefer.zitate(in: "§§ 187, 188 BGB sowie § 312a BGB")
        XCTAssertEqual(z.map(\.kurz), ["§ 187 BGB", "§ 188 BGB", "§ 312a BGB"])
    }

    func testArtikel() {
        let z = NormzitatPruefer.zitate(in: "Art. 6 Abs. 1 lit. f DSGVO und Art. 3 GG")
        XCTAssertEqual(z.map(\.kurz), ["Art. 6 DSGVO", "Art. 3 GG"])
    }

    func testVertragsklauselIstKeinNormzitat() {
        XCTAssertTrue(NormzitatPruefer.zitate(in: "Nach § 3 des Vertrags schuldet der Käufer Zinsen.").isEmpty)
    }

    func testErfundenerParagraphFaelltAuf() {
        let b = NormzitatPruefer.pruefe("Der Anspruch folgt aus § 3120 BGB.")
        XCTAssertEqual(b.count, 1)
        XCTAssertTrue(b[0].istAuffaellig)
        XCTAssertTrue(b[0].hinweis.contains("2385"))
    }

    func testEchteNormenUnauffaellig() {
        let text = "§ 626 BGB, § 517 ZPO, § 233 ZPO, § 102 BetrVG, § 43a BRAO, Art. 103 GG"
        let b = NormzitatPruefer.pruefe(text)
        XCTAssertEqual(b.count, 6)
        XCTAssertFalse(b.contains(where: \.istAuffaellig), b.map(\.hinweis).joined(separator: "\n"))
    }

    func testFalscheZaehlart() {
        let b = NormzitatPruefer.pruefe("§ 6 DSGVO")
        XCTAssertEqual(b.first?.status, .falscheZaehlart)
    }

    func testUnbekanntesGesetzIstKeinFehler() {
        let b = NormzitatPruefer.pruefe("§ 15 FernUSG")
        XCTAssertEqual(b.first?.status, .gesetzUnbekannt)
        XCTAssertFalse(b[0].istAuffaellig)
    }
}

final class BelegpruefungTests: XCTestCase {

    func testBetragAusQuelleIstBelegt() {
        let e = Belegpruefung.pruefe(
            antwort: "Das Kostenrisiko beträgt 4.830,50 € bei einem Streitwert von 25.000 EUR.",
            quellen: "streitwert: 25000\nkostenrisiko: 4830.5")
        XCTAssertEqual(e.belegteBetraege, 2)
        XCTAssertTrue(e.unbelegteBetraege.isEmpty, "\(e.unbelegteBetraege)")
    }

    func testErfundenerBetragFaelltAuf() {
        let e = Belegpruefung.pruefe(
            antwort: "Realistisch sind 18.000 € Vergleichssumme.",
            quellen: "Streitwert 25.000 €")
        XCTAssertEqual(e.unbelegteBetraege, ["18.000 €"])
    }

    func testZitierteEntscheidungOhneQuelle() {
        let e = Belegpruefung.pruefe(
            antwort: "So BGH, Urt. v. 12.3.2020 – VIII ZR 123/21 und BAG 2 AZR 45/20.",
            quellen: "Der Mandant verweist auf BAG 2 AZR 45/20.")
        XCTAssertEqual(e.ungepruefteEntscheidungen, ["VIII ZR 123/21"])
    }

    func testBerichtStufen() {
        let sauber = KIAntwortPruefer.pruefe(antwort: "Es gilt § 626 BGB.", quellen: "",
                                             modul: "t", modell: "m")
        XCTAssertEqual(sauber.stufe, .sauber)
        let pruefen = KIAntwortPruefer.pruefe(antwort: "Vgl. VIII ZR 1/20.", quellen: "",
                                              modul: "t", modell: "m")
        XCTAssertEqual(pruefen.stufe, .pruefen)
        let auff = KIAntwortPruefer.pruefe(antwort: "§ 9999 ZPO", quellen: "",
                                           modul: "t", modell: "m")
        XCTAssertEqual(auff.stufe, .auffaellig)
        XCTAssertFalse(auff.hinweise.isEmpty)
    }
}

final class RelevanzsucheTests: XCTestCase {

    private let korpus = [
        Suchdokument(id: "kschg", titel: "Klagefrist Kündigungsschutz",
                     text: "Die Kündigungsschutzklage ist binnen drei Wochen nach Zugang der Kündigung zu erheben.",
                     norm: "§ 4 KSchG"),
        Suchdokument(id: "miete", titel: "Mietminderung bei Mängeln",
                     text: "Die Miete ist kraft Gesetzes gemindert, solange der Mangel besteht.",
                     norm: "§ 536 BGB"),
        Suchdokument(id: "berufung", titel: "Berufungsfrist",
                     text: "Die Berufungsfrist beträgt einen Monat ab Zustellung des Urteils.",
                     norm: "§ 517 ZPO")
    ]

    func testLangeFrageFindetPassendenEintrag() {
        let t = Relevanzsuche.suche(
            "Mein Mandant hat gestern eine Kündigung erhalten, bis wann müssen wir Klage erheben?",
            in: korpus)
        XCTAssertEqual(t.first?.id, "kschg")
    }

    func testNormtrefferSchlaegtWorttreffer() {
        let t = Relevanzsuche.suche("Was regelt § 517 ZPO zur Kündigung?", in: korpus)
        XCTAssertEqual(t.first?.id, "berufung")
        XCTAssertTrue(t.first?.gruende.contains("§ 517 ZPO") ?? false)
    }

    func testKeinTrefferBeiFremdemThema() {
        XCTAssertTrue(Relevanzsuche.suche("Umsatzsteuervoranmeldung Quartal", in: korpus).isEmpty)
    }

    func testReihenfolgeIstStabil() {
        let a = Relevanzsuche.suche("Frist Zustellung Urteil", in: korpus)
        let b = Relevanzsuche.suche("Frist Zustellung Urteil", in: korpus.reversed())
        XCTAssertEqual(a.map(\.id), b.map(\.id))
    }
}

final class JSONReparaturTests: XCTestCase {

    private func objekt(_ s: String) -> [String: Any]? {
        JSONReparatur.extrahiere(s).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
    }

    func testSauberesJSONBleibt() {
        XCTAssertEqual(objekt("{\"a\": 1}")?["a"] as? Int, 1)
    }

    func testMarkdownZaunUndEinleitung() {
        let s = "Hier ist die Analyse:\n```json\n{\"risiko\": \"hoch\", \"punkte\": [1, 2]}\n```\nViel Erfolg!"
        XCTAssertEqual(objekt(s)?["risiko"] as? String, "hoch")
    }

    func testHaengendesKomma() {
        XCTAssertEqual((objekt("{\"liste\": [1, 2, ], \"x\": \"y\", }")?["liste"] as? [Int]) ?? [], [1, 2])
    }

    func testKlammerInZeichenketteZaehltNicht() {
        XCTAssertEqual(objekt("Antwort: {\"text\": \"Klausel } bleibt, auch [so]\"} Ende")?["text"] as? String,
                       "Klausel } bleibt, auch [so]")
    }

    func testAbgeschnittenesJSONWirdNichtErfunden() {
        XCTAssertNil(JSONReparatur.extrahiere("{\"a\": [1, 2"))
        XCTAssertNil(JSONReparatur.extrahiere("Dazu kann ich nichts sagen."))
    }
}
