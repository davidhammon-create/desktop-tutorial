import Foundation
struct ERRegel {
    let dimension: ERDimension
    let titel: String
    let normen: [String]
    let punkte: Int
    let wahrscheinlichkeit: Int
    let schaden: Int
    let massnahme: String
    let frist: String?
    let trifft: (ERUnternehmen) -> Bool
    let begruendung: (ERUnternehmen) -> String
    init(_ dimension: ERDimension, _ titel: String, normen: [String], punkte: Int, p: Int, s: Int,
         massnahme: String, frist: String? = nil,
         trifft: @escaping (ERUnternehmen) -> Bool,
         begruendung: @escaping (ERUnternehmen) -> String) {
        self.dimension = dimension; self.titel = titel; self.normen = normen; self.punkte = punkte
        self.wahrscheinlichkeit = p; self.schaden = s; self.massnahme = massnahme; self.frist = frist
        self.trifft = trifft; self.begruendung = begruendung
    }
}
enum EnterpriseRadarEngine {
    static let regeln: [ERRegel] = {
        var r: [ERRegel] = []
        let hat: (ERSignal) -> (ERUnternehmen) -> Bool = { s in { $0.signale.contains(s) } }
        r.append(ERRegel(.datenschutz, "Besondere Datenkategorien ohne Art.-9-Rechtsgrundlage", normen: ["Art. 9, 35 DSGVO"], punkte: 18, p: 65, s: 80,
            massnahme: "Art.-9-Rechtsgrundlage je Verarbeitung dokumentieren, DSFA durchführen, Zugriffskonzept härten.",
            trifft: hat(.besondereKategorien)) { _ in "Gesundheits-, Biometrie- oder Finanzdaten lösen DSFA-Pflicht und erhöhten Bußgeldrahmen aus." })
        r.append(ERRegel(.datenschutz, "Benennungspflicht DSB verletzt", normen: ["Art. 37 DSGVO", "§ 38 BDSG"], punkte: 12, p: 80, s: 45,
            massnahme: "DSB benennen (intern/extern), bei Aufsichtsbehörde melden, Kontaktdaten veröffentlichen.", frist: "sofort",
            trifft: { $0.signale.contains(.keinDSB) && ($0.mitarbeiter >= 20 || $0.signale.contains(.besondereKategorien)) }) { u in "Ab 20 ständig mit Datenverarbeitung Beschäftigten (§ 38 BDSG) bzw. bei Kerntätigkeit mit sensiblen Daten zwingend. Hier: \(u.mitarbeiter) MA." })
        r.append(ERRegel(.datenschutz, "Drittlandtransfer ohne Transfer-Impact-Assessment", normen: ["Art. 44–49 DSGVO", "EU-US DPF", "SCC 2021/914"], punkte: 15, p: 60, s: 70,
            massnahme: "Transfer-Register, TIA je Empfänger, DPF-Zertifizierung prüfen, SCC + ergänzende Maßnahmen.",
            trifft: hat(.drittlandTransfer)) { _ in "Nach Schrems II trägt der Verantwortliche die Nachweislast; DPF-Status US-Empfänger bleibt politisch fragil (Latombe-Verfahren)." })
        r.append(ERRegel(.datenschutz, "Tracking ohne wirksame Einwilligung", normen: ["§ 25 TDDDG", "Art. 6, 7 DSGVO", "EuGH C-673/17 Planet49"], punkte: 14, p: 85, s: 50,
            massnahme: "Consent-Management rechtskonform (keine Dark Patterns), Server-Side-Tracking prüfen, Datenschutzhinweise synchronisieren.", frist: "30 Tage",
            trifft: hat(.trackingOhneConsent)) { _ in "Hohe Entdeckungswahrscheinlichkeit: Wettbewerber, Verbände (UKlaG) und Betroffene können ohne Aufwand prüfen und abmahnen (EuGH C-21/23 Lindenapotheke: UWG-Klagebefugnis bejaht)." })
        r.append(ERRegel(.datenschutz, "Rechenschaftspflicht nicht erfüllbar", normen: ["Art. 5 Abs. 2, 30, 32 DSGVO"], punkte: 12, p: 70, s: 55,
            massnahme: "Verarbeitungsverzeichnis und TOM-Dokumentation erstellen; Löschkonzept nach DIN 66398.",
            trifft: hat(.keinVVT)) { _ in "Ohne VVT/TOM-Doku ist jede Behördenanfrage ein Eigentor; Bußgeldzumessung (Art. 83 Abs. 2 lit. k) wirkt verschärfend." })
        r.append(ERRegel(.datenschutz, "Wiederholungstäter-Risiko", normen: ["Art. 83 Abs. 2 lit. e DSGVO"], punkte: 10, p: 55, s: 65,
            massnahme: "Lessons-learned-Protokoll, Nachweis der Abstellung, proaktive Behördenkommunikation.",
            trifft: hat(.datenpanneLetzte3J)) { _ in "Frühere Verstöße erhöhen Bußgeld und Reputationsschaden; Aufsichtsbehörden priorisieren Wiederholungsfälle." })
        r.append(ERRegel(.kiRegulierung, "KI-Kompetenzpflicht & Inventar fehlen", normen: ["Art. 4 AI Act (seit 02.02.2025)", "Art. 50 Transparenz (seit 02.08.2026)"], punkte: 10, p: 75, s: 40,
            massnahme: "KI-Inventar, Risikoklassifizierung je System, Schulungsnachweis, Transparenzhinweise bei generativen Ausgaben.", frist: "sofort",
            trifft: { $0.signale.contains(.setztKIEin) && $0.signale.contains(.keineKIGovernance) }) { _ in "Betreiberpflichten gelten bereits; Art. 50 Transparenzpflichten seit 02.08.2026 bußgeldbewehrt." })
        r.append(ERRegel(.kiRegulierung, "Hochrisiko-KI ohne Konformitätsnachweis", normen: ["Art. 6, 9–15, 26 AI Act", "Anhang III"], punkte: 22, p: 70, s: 85,
            massnahme: "Risikomanagementsystem (Art. 9), Datengovernance, menschliche Aufsicht, Grundrechte-Folgenabschätzung (Art. 27), Registrierung EU-Datenbank.", frist: "Anhang III: seit 02.08.2026 · Anhang I: 02.08.2027",
            trifft: hat(.kiHochrisiko)) { _ in "Einsatz in HR, Kredit, Biometrie, kritischer Infrastruktur oder Medizin — Pflichten für Anhang-III-Systeme seit 02.08.2026 anwendbar." })
        r.append(ERRegel(.kiRegulierung, "Anbieterpflichten GPAI / eigene Modelle", normen: ["Art. 53–55 AI Act", "Code of Practice GPAI"], punkte: 14, p: 60, s: 70,
            massnahme: "Technische Dokumentation, Urheberrechts-Policy, Trainingsdaten-Zusammenfassung, ggf. systemisches Risiko-Management.",
            trifft: hat(.kiGPAI)) { _ in "Anbieter tragen die volle Dokumentations- und Urheberrechtslast; Haftungsübergang auf Betreiber nur begrenzt möglich." })
        r.append(ERRegel(.kiRegulierung, "Automatisierte Einzelentscheidung", normen: ["Art. 22 DSGVO", "EuGH C-634/21 SCHUFA", "§ 31 BDSG"], punkte: 12, p: 65, s: 60,
            massnahme: "Menschliche Letztentscheidung nachweisbar implementieren, Logik erklären, Widerspruchsweg einrichten.",
            trifft: hat(.kiEntscheidetUeberPersonen)) { _ in "Nach SCHUFA-Rechtsprechung gilt bereits der Score als Entscheidung, wenn er maßgeblich ist." })
        r.append(ERRegel(.nachhaltigkeit, "LkSG-Sorgfaltspflichten nicht organisiert", normen: ["§§ 3–10 LkSG", "§ 24 LkSG (Bußgeld)", "§ 22 LkSG (Vergabeausschluss)"], punkte: 18, p: 60, s: 70,
            massnahme: "Risikoanalyse, Grundsatzerklärung, Präventions-/Abhilfemaßnahmen, Beschwerdeverfahren, BAFA-Bericht.", frist: "jährlich",
            trifft: { $0.mitarbeiter >= 1000 && $0.sitz == .de && $0.signale.contains(.keinLieferkettenRisikomanagement) }) { u in "Mit \(u.mitarbeiter) MA in Deutschland unmittelbar verpflichtet; BAFA prüft risikobasiert und auf Beschwerde Dritter (§ 14 LkSG)." })
        r.append(ERRegel(.nachhaltigkeit, "Mittelbare Lieferketten-Exposure", normen: ["§ 6 Abs. 4 LkSG (Zuliefererpflichten)", "CSDDD"], punkte: 9, p: 55, s: 45,
            massnahme: "Supplier-Code-of-Conduct, Audit-Rechte, Weitergabeklauseln verhandeln statt pauschal akzeptieren.",
            trifft: { $0.signale.contains(.lieferketteAussereuropa) && $0.mitarbeiter < 1000 }) { _ in "Große Kunden reichen LkSG-Pflichten vertraglich durch; ohne eigenes System drohen Auslistung und Haftungsklauseln." })
        r.append(ERRegel(.nachhaltigkeit, "CSRD/ESRS-Berichtspflicht unvorbereitet", normen: ["§§ 289b ff. HGB n. F.", "CSRD 2022/2464", "Omnibus I"], punkte: 12, p: 60, s: 50,
            massnahme: "Wesentlichkeitsanalyse (doppelt), Datenpunkte ESRS, Prüfungsbereitschaft; Omnibus-Schwellen (1.000 MA) laufend prüfen.", frist: "Welle 2 verschoben: GJ 2027",
            trifft: { $0.signale.contains(.keineCSRDVorbereitung) && ($0.boersennotiert || $0.mitarbeiter >= 1000) }) { _ in "Kapitalmarktorientiert oder ≥ 1.000 MA: Berichtspflicht trifft; Banken und Großkunden fordern ESG-Daten bereits heute." })
        r.append(ERRegel(.nachhaltigkeit, "EUDR-Sorgfaltserklärung", normen: ["VO (EU) 2023/1115", "Art. 4, 8 EUDR"], punkte: 14, p: 65, s: 60,
            massnahme: "Geolokalisierung der Erzeugungsflächen, Sorgfaltserklärung im EU-Informationssystem, Lieferantennachweise.", frist: "Anwendung 30.12.2026 (groß) · 30.06.2027 (KMU) — Stand prüfen",
            trifft: hat(.rohstoffeEUDR)) { _ in "Ohne Sorgfaltserklärung ist das Inverkehrbringen verboten; Zoll kann Ware stoppen." })
        r.append(ERRegel(.nachhaltigkeit, "CBAM / ETS-Kostenpfad", normen: ["VO (EU) 2023/956 (CBAM)", "TEHG"], punkte: 8, p: 70, s: 40,
            massnahme: "CBAM-Erklärung, Emissionsdaten von Lieferanten vertraglich sichern, Zertifikate-Budget planen.",
            trifft: hat(.hochemissiv)) { _ in "Ab 2026 kostenpflichtige CBAM-Zertifikate; fehlende Lieferantendaten führen zu Default-Werten (teurer)." })
        r.append(ERRegel(.kartell, "Marktbeherrschung / Missbrauchsaufsicht", normen: ["Art. 102 AEUV", "§§ 18–20 GWB"], punkte: 16, p: 50, s: 85,
            massnahme: "Konditionen-Audit (Diskriminierung, Kampfpreise, Lieferverweigerung), Dawn-Raid-Leitfaden, Kartell-Compliance-Schulung.",
            trifft: { $0.marktanteil >= 40 || $0.signale.contains(.marktfuehrer) }) { u in "Marktanteil \(Int(u.marktanteil)) % — ab 40 % Vermutung der Marktbeherrschung (§ 18 Abs. 4 GWB); jedes Verhalten unterliegt verschärfter Kontrolle." })
        r.append(ERRegel(.kartell, "Relative Marktmacht (Abhängigkeit)", normen: ["§ 20 GWB"], punkte: 8, p: 45, s: 55,
            massnahme: "Lieferbeziehungen zu abhängigen KMU auf Behinderung prüfen.",
            trifft: { $0.marktanteil >= 25 && $0.marktanteil < 40 }) { _ in "Auch unterhalb der Marktbeherrschung greift § 20 GWB gegenüber abhängigen Unternehmen." })
        r.append(ERRegel(.kartell, "Informationsaustausch mit Wettbewerbern", normen: ["Art. 101 AEUV", "§ 1 GWB", "Horizontal-Leitlinien 2023"], punkte: 15, p: 55, s: 80,
            massnahme: "Verbandssitzungen mit Kartell-Protokoll, Clean-Team für Benchmarks, keine Zukunftsdaten (Preise, Mengen, Kapazitäten).",
            trifft: hat(.infoaustauschWettbewerber)) { _ in "Bereits einseitige Offenlegung strategischer Daten kann abgestimmte Verhaltensweise sein (EuGH C-8/08 T-Mobile)." })
        r.append(ERRegel(.kartell, "Exklusivität / Alleinbezug", normen: ["Art. 101 Abs. 3 AEUV", "Vertikal-GVO 2022/720 Art. 5"], punkte: 10, p: 50, s: 60,
            massnahme: "Laufzeit ≤ 5 Jahre, Marktanteilsschwellen (30 %) prüfen, Kündigungsrechte einbauen.",
            trifft: hat(.exklusivvertraege)) { _ in "Wettbewerbsverbote > 5 Jahre fallen aus der Vertikal-GVO; bei Marktmacht Missbrauchsrisiko." })
        r.append(ERRegel(.kartell, "Kopplung / Bündelung", normen: ["Art. 102 lit. d AEUV", "§ 19 Abs. 2 Nr. 1 GWB"], punkte: 9, p: 45, s: 65,
            massnahme: "Einzelbezug ermöglichen, Preisstruktur dokumentieren (Microsoft-/Google-Praxis beachten).",
            trifft: { $0.signale.contains(.kopplung) && $0.marktanteil >= 25 }) { _ in "Kopplung durch marktstarke Anbieter ist Kernfall des Behinderungsmissbrauchs." })
        r.append(ERRegel(.kartell, "Plattform-Gatekeeper-Pflichten", normen: ["DMA VO 2022/1925", "§ 19a GWB", "P2B-VO 2019/1150"], punkte: 12, p: 55, s: 70,
            massnahme: "Selbstbevorzugung ausschließen, Ranking-Transparenz (P2B), Datenzugang für Geschäftskunden, interne Beschwerdestelle.",
            trifft: hat(.plattformGatekeeper)) { _ in "P2B-VO gilt für jede Vermittlungsplattform; § 19a GWB bei überragender marktübergreifender Bedeutung." })
        r.append(ERRegel(.kartell, "Paritätsklauseln", normen: ["Art. 5 Abs. 1 lit. d Vertikal-GVO", "BGH KVR 54/20 Booking"], punkte: 9, p: 60, s: 55,
            massnahme: "Weite Paritätsklauseln streichen, enge nur außerhalb Marktmacht; DMA-Verbot für Gatekeeper beachten.",
            trifft: hat(.preisparitaetsklauseln)) { _ in "Weite Bestpreisklauseln sind in DE/EU faktisch unzulässig." })
        r.append(ERRegel(.geistigesEigentum, "Keine Schutzrechtsstrategie", normen: ["PatG", "MarkenG", "DesignG"], punkte: 12, p: 60, s: 60,
            massnahme: "IP-Audit, Freedom-to-Operate-Analyse für Kernprodukte, Anmeldestrategie (DE → EP/UP → PCT).",
            trifft: hat(.keinIPAudit)) { _ in "Ohne FTO-Analyse besteht blindes Verletzungsrisiko; ohne eigene Rechte fehlt die Gegenwehr (Cross-License)." })
        r.append(ERRegel(.geistigesEigentum, "Abhängigkeit von Fremd-IP", normen: ["§ 24 PatG (Zwangslizenz)", "Lizenzvertragsrecht", "Art. 102 AEUV (FRAND)"], punkte: 14, p: 55, s: 75,
            massnahme: "Lizenzlaufzeiten/Change-of-Control-Klauseln prüfen, Second-Source, Design-around-Programm.",
            trifft: hat(.abhaengigVonFremdIP)) { _ in "Kündigung oder Übernahme des Lizenzgebers kann das Kernprodukt stoppen." })
        r.append(ERRegel(.geistigesEigentum, "Open-Source-Compliance", normen: ["GPL/AGPL Copyleft", "§ 97 UrhG", "CRA Art. 24 (Open-Source-Steward)"], punkte: 10, p: 65, s: 55,
            massnahme: "SBOM, Lizenz-Scan in CI/CD, Copyleft-Grenzen definieren, Beitragsrichtlinie.",
            trifft: hat(.openSourceOhneCompliance)) { _ in "GPL-Verstöße werden aktiv verfolgt (gpl-violations, SFC); Offenlegungspflicht kann Kernsoftware treffen." })
        r.append(ERRegel(.geistigesEigentum, "Geschäftsgeheimnisse ungeschützt", normen: ["§ 2 Nr. 1 lit. b GeschGehG", "§ 4 GeschGehG"], punkte: 13, p: 70, s: 65,
            massnahme: "Schutzkonzept (Klassifizierung, NDA, Zugriffskontrolle, Exit-Prozess) — sonst kein Geheimnis im Rechtssinne.",
            trifft: hat(.geheimnisseOhneSchutzkonzept)) { _ in "Ohne „angemessene Geheimhaltungsmaßnahmen“ entfällt der Schutz vollständig — der Abwerber darf das Wissen nutzen." })
        r.append(ERRegel(.geistigesEigentum, "Anhängiger IP-Streit", normen: ["§ 139 PatG", "§ 14 MarkenG", "§§ 935 ff. ZPO"], punkte: 16, p: 80, s: 70,
            massnahme: "Nichtigkeits-/Löschungsangriff prüfen, Schutzschrift hinterlegen, Rückstellungen bilden, Kommunikationsplan.",
            trifft: hat(.patentstreitAnhaengig)) { _ in "Einstweilige Verfügungen (UPC: Ex-parte möglich) können Vertrieb binnen Tagen stoppen." })
        r.append(ERRegel(.geistigesEigentum, "Schwaches Portfolio", normen: ["PatG", "MarkenG"], punkte: 8, p: 50, s: 50,
            massnahme: "Mindestens Kernmarke (Wort + Bild) in Kernmärkten; Gebrauchsmuster als schneller Schutz.",
            trifft: { $0.signale.contains(.schwachesPatentportfolio) || ($0.patente == 0 && [.software, .industrie, .gesundheit, .automotive, .chemie].contains($0.branche)) }) { u in "\(u.patente) Patente, \(u.marken) Marken in einer IP-intensiven Branche — kein Verhandlungs- oder Abschreckungspotenzial." })
        r.append(ERRegel(.vertraege, "AGB veraltet", normen: ["§§ 307–309 BGB", "§ 1 UKlaG", "Data Act Art. 13"], punkte: 10, p: 70, s: 45,
            massnahme: "AGB-Review (B2B/B2C getrennt), Data-Act-Klauselkontrolle, Transparenz- und Haftungsklauseln aktualisieren.",
            trifft: hat(.agbVeraltet)) { _ in "Unwirksame Klauseln fallen ersatzlos weg (Verbot geltungserhaltender Reduktion) — Verband und Wettbewerber können abmahnen." })
        r.append(ERRegel(.vertraege, "Unbegrenzte Haftung", normen: ["§ 309 Nr. 7 BGB", "§ 276 BGB"], punkte: 14, p: 50, s: 80,
            massnahme: "Haftungsdeckel (Auftragswert/Jahresvergütung), Ausschluss mittelbarer Schäden, Versicherungsabgleich.",
            trifft: hat(.haftungUnbegrenzt)) { _ in "Ein Schadensfall kann die Bilanz übersteigen; Versicherer zahlen nicht über Deckungssumme." })
        r.append(ERRegel(.vertraege, "Langfristbindung ohne Exit", normen: ["§ 314 BGB", "§ 313 BGB"], punkte: 9, p: 50, s: 55,
            massnahme: "Change-of-Control-, Benchmark- und Sonderkündigungsrechte nachverhandeln.",
            trifft: hat(.langfristBindung)) { _ in "Fehlender Ausstieg verhindert Reaktion auf Marktwechsel; § 313 BGB ist Ausnahme, kein Plan." })
        r.append(ERRegel(.vertraege, "Keine Force-Majeure/Preisgleitung", normen: ["§ 313 BGB", "§ 275 BGB", "ICC Force Majeure Clause 2020"], punkte: 9, p: 55, s: 60,
            massnahme: "FM-Klausel mit Katalog (Pandemie, Sanktionen, Cyber), Preisgleitklausel (Index) in Langfristverträge.",
            trifft: hat(.keineForceMajeure)) { _ in "Nach 2020–2024 ist das Fehlen dieser Klauseln nicht mehr marktüblich — Lieferausfälle gehen voll zu Lasten der Partei ohne Klausel." })
        r.append(ERRegel(.vertraege, "Kein Vertragsmanagement", normen: ["Organisationspflicht § 43 GmbHG"], punkte: 8, p: 75, s: 40,
            massnahme: "CLM-System mit Fristen, Verlängerungsautomatiken, Pflichtenmatrix.",
            trifft: hat(.keinVertragsmanagement)) { _ in "Verpasste Kündigungsfristen und automatische Verlängerungen sind vermeidbarer Vermögensabfluss — und Organhaftung." })
        r.append(ERRegel(.vertraege, "Klumpenrisiko Kunde/Lieferant", normen: ["§ 20 GWB (Abhängigkeit)", "§ 89 Abs. 1 HGB analog"], punkte: 12, p: 50, s: 75,
            massnahme: "Diversifizierung, Mindestabnahme-/Laufzeitklauseln, Abhängigkeitsschutz (§ 20 GWB) prüfen.",
            trifft: hat(.abhaengigVonEinemKunden)) { _ in "> 30 % Umsatzanteil: Verhandlungsmacht liegt beim Partner; Wegfall ist existenzbedrohend." })
        r.append(ERRegel(.arbeitsrecht, "Scheinselbständigkeit", normen: ["§ 7 SGB IV", "§ 611a BGB", "§ 266a StGB", "BAG 5 AZR 146/23"], punkte: 16, p: 60, s: 80,
            massnahme: "Statusfeststellung (§ 7a SGB IV), Vertrags- und Praxisprüfung, Umstellung auf Anstellung/AÜG.",
            trifft: hat(.freelancerKern)) { _ in "Nachzahlung von Gesamtsozialversicherung bis 4 Jahre (30 bei Vorsatz) plus Strafbarkeit der Geschäftsleitung." })
        r.append(ERRegel(.arbeitsrecht, "Hinweisgebersystem fehlt", normen: ["§ 12 HinSchG", "§ 40 HinSchG"], punkte: 8, p: 75, s: 35,
            massnahme: "Interne Meldestelle (intern/Ombudsperson), Verfahrensordnung, Vertraulichkeit, Rückmeldefristen 7 Tage / 3 Monate.", frist: "sofort",
            trifft: { $0.signale.contains(.keineHinweisgeberstelle) && $0.mitarbeiter >= 50 }) { u in "Pflicht ab 50 Beschäftigten (hier \(u.mitarbeiter)); Bußgeld bis 50.000 € — und Hinweise gehen direkt an externe Stellen." })
        r.append(ERRegel(.arbeitsrecht, "Entgelttransparenz-Richtlinie", normen: ["RL (EU) 2023/970", "EntgTranspG n. F.", "Art. 157 AEUV"], punkte: 10, p: 70, s: 50,
            massnahme: "Gender-Pay-Gap-Analyse, Gehaltsbänder, Auskunftsprozess; Berichtspflicht ab 100 MA.", frist: "Umsetzung 07.06.2026 — Berichte ab 2027",
            trifft: { $0.signale.contains(.entgeltLuecke) && $0.mitarbeiter >= 100 }) { _ in "Beweislastumkehr zugunsten der Beschäftigten; Lücke > 5 % ohne Rechtfertigung erzwingt gemeinsame Entgeltbewertung." })
        r.append(ERRegel(.arbeitsrecht, "Restrukturierung", normen: ["§§ 111–113 BetrVG", "§ 17 KSchG", "§ 1 Abs. 3 KSchG"], punkte: 12, p: 65, s: 65,
            massnahme: "Interessenausgleich/Sozialplan, Massenentlassungsanzeige fehlerfrei (EuGH C-134/22), Sozialauswahl dokumentieren.",
            trifft: hat(.restrukturierungGeplant)) { _ in "Formfehler bei Massenentlassungsanzeige machen alle Kündigungen unwirksam." })
        r.append(ERRegel(.arbeitsrecht, "Leiharbeit/Werkverträge", normen: ["§ 1 Abs. 1b AÜG (18 Monate)", "§ 8 AÜG (Equal Pay)", "§ 10 AÜG"], punkte: 9, p: 55, s: 55,
            massnahme: "Höchstüberlassungsdauer tracken, Equal Pay ab 9 Monaten, Werkverträge auf Eingliederung prüfen.",
            trifft: hat(.leiharbeit)) { _ in "Überschreitung fingiert Arbeitsverhältnis zum Entleiher." })
        r.append(ERRegel(.arbeitsrecht, "Mitbestimmungsvakuum", normen: ["§ 1 BetrVG", "§ 87 BetrVG"], punkte: 5, p: 40, s: 35,
            massnahme: "Betriebsratswahl nicht behindern (§ 119 BetrVG); Beteiligungsprozesse vorbereiten.",
            trifft: { $0.signale.contains(.keinBetriebsrat) && $0.mitarbeiter >= 50 }) { _ in "Spätere Gründung in Krisensituation ist konfliktträchtiger als geordnete Mitbestimmung." })
        r.append(ERRegel(.produkthaftung, "Neue Produkthaftungsrichtlinie", normen: ["RL (EU) 2024/2853", "Art. 9–10 (Offenlegung, Beweisvermutung)"], punkte: 14, p: 65, s: 70,
            massnahme: "Technische Dokumentation gerichtsfest, Update-/Patch-Prozesse, Haftungsketten mit Lieferanten regeln.", frist: "Anwendung ab 09.12.2026",
            trifft: { $0.signale.contains(.physischeProdukte) || $0.signale.contains(.softwareProdukt) }) { u in u.signale.contains(.softwareProdukt) ? "Software ist erstmals ausdrücklich Produkt; fehlende Updates sind Fehler; Offenlegungspflicht + Beweisvermutung drehen die Prozessdynamik." : "Beweislastumkehr und Offenlegungspflicht erhöhen die Erfolgsquote von Geschädigten deutlich." })
        r.append(ERRegel(.produkthaftung, "Cyber Resilience Act", normen: ["VO (EU) 2024/2847", "Art. 13, 14 CRA"], punkte: 12, p: 60, s: 60,
            massnahme: "Security-by-Design, SBOM, Schwachstellen-Meldeprozess (24 h an ENISA), Supportzeitraum definieren.", frist: "Meldepflichten 11.09.2026 · Vollanwendung 11.12.2027",
            trifft: hat(.vernetzteProdukte)) { _ in "Produkte mit digitalen Elementen brauchen CE-Konformität nach CRA; Marktüberwachung kann Rückruf anordnen." })
        r.append(ERRegel(.produkthaftung, "Kein Rückrufmanagement", normen: ["§ 6 ProdSG", "§ 823 BGB (Produktbeobachtung)"], punkte: 10, p: 55, s: 70,
            massnahme: "Krisenhandbuch, Rückversicherung, Rückverfolgbarkeit (Chargen), Behördenkommunikation.",
            trifft: { $0.signale.contains(.keinRueckrufplan) && ($0.signale.contains(.physischeProdukte) || $0.signale.contains(.sicherheitsrelevant)) }) { _ in "Verzögerte Rückrufe sind der Hauptgrund für Organhaftung und Strafverfahren in Produktfällen." })
        r.append(ERRegel(.produkthaftung, "Sicherheitsrelevante Produkte", normen: ["MDR 2017/745", "MaschVO 2023/1230", "SpielzeugRL"], punkte: 12, p: 55, s: 85,
            massnahme: "Benannte Stelle, Post-Market-Surveillance, Vigilanz-Meldungen.",
            trifft: hat(.sicherheitsrelevant)) { _ in "Höchste Schadensdimension (Personenschäden) und strafrechtliche Flankierung." })
        r.append(ERRegel(.governance, "Kein Compliance-Management-System", normen: ["§ 130 OWiG", "§ 43 GmbHG", "§ 93 AktG", "BGH 1 StR 265/16"], punkte: 15, p: 65, s: 75,
            massnahme: "CMS nach IDW PS 980 / ISO 37301: Risikoanalyse, Richtlinien, Schulung, Kontrolle, Sanktion — bußgeldmindernd anerkannt.",
            trifft: hat(.keinCMS)) { _ in "Ohne CMS keine Enthaftung der Geschäftsleitung; Verbandsgeldbuße wird nicht gemildert." })
        r.append(ERRegel(.governance, "Fehlende interne Kontrolle", normen: ["§ 91 Abs. 2, 3 AktG", "§ 1 StaRUG"], punkte: 10, p: 55, s: 60,
            massnahme: "Vier-Augen-Prinzip, Zahlungsfreigaben, IKS-Dokumentation, Frühwarnsystem.",
            trifft: hat(.keineInterneRevision)) { _ in "Fraud-Fälle entstehen in Lücken ohne Kontrolle; StaRUG verlangt Krisenfrüherkennung für alle haftungsbeschränkten Rechtsträger." })
        r.append(ERRegel(.governance, "Keine D&O", normen: ["§ 93 Abs. 2 AktG", "§ 43 Abs. 2 GmbHG"], punkte: 8, p: 40, s: 70,
            massnahme: "D&O mit ausreichender Deckung, Innenhaftungsklausel, Rückwärtsdeckung.",
            trifft: hat(.keineDOVersicherung)) { _ in "Organe haften mit Privatvermögen; unversichert sinkt die Bereitschaft zu notwendigen Entscheidungen." })
        r.append(ERRegel(.governance, "Schlüsselperson-Risiko", normen: ["§ 35 GmbHG", "§ 78 AktG"], punkte: 7, p: 45, s: 60,
            massnahme: "Stellvertretung, Prokura, Notfallvollmachten, Handlungsfähigkeit absichern.",
            trifft: hat(.einzelgeschaeftsfuehrung)) { _ in "Ausfall der einzigen vertretungsberechtigten Person lähmt das Unternehmen rechtlich." })
        r.append(ERRegel(.governance, "Nachfolge / Gesellschafterstreit", normen: ["§§ 34, 60 GmbHG", "§ 61 GmbHG (Auflösungsklage)"], punkte: 11, p: 50, s: 70,
            massnahme: "Gesellschaftervereinbarung (Drag/Tag, Deadlock, Bewertung), Nachfolgeregelung, Testamentsabstimmung.",
            trifft: hat(.nachfolgeOffen)) { _ in "Ungeklärte Nachfolge ist der häufigste Grund für Wertvernichtung im Mittelstand — und ein Hebel für Wettbewerber (Abwerbung, Übernahme)." })
        r.append(ERRegel(.governance, "Insolvenznähe", normen: ["§ 15a InsO", "§ 15b InsO", "§ 1 StaRUG"], punkte: 18, p: 70, s: 95,
            massnahme: "Liquiditätsplanung 13 Wochen, Fortbestehensprognose, Sanierungsoptionen (StaRUG), Zahlungsverbote beachten.", frist: "3 Wochen (Zahlungsunfähigkeit) / 6 Wochen (Überschuldung)",
            trifft: hat(.liquiditaetAngespannt)) { _ in "Verspätete Antragstellung ist strafbar und begründet persönliche Haftung für alle Zahlungen danach." })
        r.append(ERRegel(.cyberResilienz, "NIS2-Pflichten", normen: ["NIS2UmsuCG (§§ 28 ff. BSIG n. F.)", "Art. 20, 21, 23 NIS2"], punkte: 16, p: 70, s: 75,
            massnahme: "Registrierung beim BSI, Risikomanagement (10 Mindestmaßnahmen), Meldekette 24 h / 72 h / 1 Monat, Geschäftsleiter-Schulung.", frist: "in Kraft seit 12/2025",
            trifft: { $0.signale.contains(.kritischeInfrastruktur) || ($0.mitarbeiter >= 50 && [.energie, .gesundheit, .logistik, .finanzen, .software].contains($0.branche)) }) { _ in "Geschäftsleitung haftet persönlich für Billigung und Überwachung; Bußgeld bis 10 Mio. € / 2 %." })
        r.append(ERRegel(.cyberResilienz, "Kein ISMS", normen: ["Art. 32 DSGVO", "Art. 21 NIS2", "ISO 27001"], punkte: 12, p: 65, s: 65,
            massnahme: "ISMS aufbauen; Zertifizierung als Vertriebsargument und Versicherbarkeit.",
            trifft: hat(.keinISMS)) { _ in "Ohne ISMS kein Nachweis „Stand der Technik“ — Haftung und Versicherungsausschluss im Schadensfall." })
        r.append(ERRegel(.cyberResilienz, "DORA", normen: ["VO (EU) 2022/2554", "Art. 28–30 (IKT-Drittparteien)"], punkte: 13, p: 65, s: 65,
            massnahme: "IKT-Risikorahmen, Informationsregister, Vertragsklauseln Art. 30, TLPT-Tests.", frist: "in Kraft seit 17.01.2025",
            trifft: hat(.finanzsektorDORA)) { _ in "Finanzunternehmen reichen DORA-Pflichten vertraglich an IKT-Dienstleister durch — Kündigungsrechte und Audit-Rechte inklusive." })
        r.append(ERRegel(.cyberResilienz, "Vorfall-Historie", normen: ["Art. 33, 34 DSGVO", "Art. 23 NIS2"], punkte: 9, p: 60, s: 60,
            massnahme: "Forensik-Bericht, Lessons learned, Nachweis der Behebung, Versicherungs-Review.",
            trifft: hat(.cybervorfallLetzte24M)) { _ in "Wiederholung nach bekanntem Vorfall gilt als grob fahrlässig — Versicherer und Behörden reagieren schärfer." })
        r.append(ERRegel(.cyberResilienz, "Kein Notfallplan", normen: ["Art. 32 Abs. 1 lit. c DSGVO", "BSI-Standard 200-4"], punkte: 8, p: 60, s: 60,
            massnahme: "BCM/IRP mit Rollen, Kommunikationsvorlagen, Meldefristen, Übungen.",
            trifft: hat(.keinNotfallplan)) { _ in "Die 72-Stunden-Frist der DSGVO und die 24-Stunden-Frist der NIS2 sind ohne Plan nicht einhaltbar." })
        r.append(ERRegel(.steuernSanktionen, "Verrechnungspreis-Dokumentation", normen: ["§ 1 AStG", "§ 90 Abs. 3 AO", "GAufzV", "Pillar Two (MinStG)"], punkte: 12, p: 65, s: 60,
            massnahme: "Master/Local File, Benchmarking, Intercompany-Verträge schriftlich vor Leistung, APA prüfen.",
            trifft: hat(.konzernVerrechnungspreise)) { _ in "Fehlende Doku erlaubt Schätzung zu Lasten des Steuerpflichtigen plus Zuschlag bis 1 Mio. €." })
        r.append(ERRegel(.steuernSanktionen, "GwG-Verpflichteter ohne System", normen: ["§ 2, 4–7 GwG", "§ 56 GwG"], punkte: 14, p: 60, s: 65,
            massnahme: "Risikoanalyse, Geldwäschebeauftragter, KYC, Verdachtsmeldung FIU, Schulung.",
            trifft: { ($0.signale.contains(.bargeldintensiv) || $0.signale.contains(.kryptoAssets) || $0.branche == .finanzen) && $0.signale.contains(.keinGwGBeauftragter) }) { _ in "Güterhändler ab 10.000 € bar, Finanz- und Krypto-Dienstleister sind Verpflichtete — Aufsicht prüft verstärkt." })
        r.append(ERRegel(.steuernSanktionen, "Sanktions- und Exportkontrolle", normen: ["VO (EU) 833/2014", "AWG § 18", "Dual-Use-VO 2021/821", "No-Russia-Klausel Art. 12g"], punkte: 18, p: 65, s: 90,
            massnahme: "Sanktionslisten-Screening (Kunden, Endverwender, UBO), Endverbleibserklärungen, No-Russia-Klausel, Exportkontrollbeauftragter.",
            trifft: hat(.geschaeftSanktionslaender)) { _ in "Verstöße sind Straftaten (Freiheitsstrafe) — Umgehung über Drittstaaten (Türkei, VAE, Zentralasien) wird aktiv verfolgt." })
        r.append(ERRegel(.steuernSanktionen, "Krypto-Regulierung", normen: ["MiCAR", "KMAG", "Transfer-of-Funds-VO"], punkte: 10, p: 60, s: 60,
            massnahme: "MiCAR-Zulassung, Travel-Rule, Verwahrkonzept.",
            trifft: hat(.kryptoAssets)) { _ in "Ohne BaFin-Erlaubnis ist das Geschäft strafbar (§ 46 KMAG)." })
        r.append(ERRegel(.litigation, "Laufende Verfahren", normen: ["ZPO", "§ 249 HGB (Rückstellung)"], punkte: 12, p: 90, s: 55,
            massnahme: "Litigation-Portfolio-Bewertung, Vergleichskorridore, Rückstellungen, Prozessfinanzierung prüfen.",
            trifft: hat(.laufendeKlagen)) { _ in "Jedes offene Verfahren bindet Management, Liquidität und ist für Gegner öffentlich einsehbar (Registerportale, Pressestellen)." })
        r.append(ERRegel(.litigation, "Kollektivklage-Exposure", normen: ["VDuG (Abhilfeklage)", "§ 606 ff. ZPO", "RL 2020/1828"], punkte: 11, p: 50, s: 75,
            massnahme: "Massenschaden-Szenarien simulieren, Produkt-/AGB-Prozesse auditieren, Early-Settlement-Strategie.",
            trifft: hat(.b2cMassenmarkt)) { _ in "Verbraucherverbände können seit 2023 Leistung für tausende Verbraucher einklagen; Prozessfinanzierer suchen Fälle aktiv." })
        r.append(ERRegel(.litigation, "Auslandsexposure", normen: ["FRCP 26 (Discovery)", "UK Civil Procedure Rules", "HZÜ/HBÜ"], punkte: 10, p: 50, s: 70,
            massnahme: "Legal-Hold-Prozesse, Datenlokalisierung, Gerichtsstandsklauseln, Blocking-Statute-Prüfung.",
            trifft: hat(.verfahrenImAusland)) { _ in "US-Discovery erzwingt Offenlegung interner Kommunikation — Kollision mit DSGVO inklusive." })
        r.append(ERRegel(.litigation, "Keine Streitbeilegungsklauseln", normen: ["§ 38 ZPO", "§ 1029 ZPO", "Brüssel Ia-VO Art. 25"], punkte: 7, p: 55, s: 50,
            massnahme: "Gerichtsstand/Schiedsklausel (DIS, ICC), Eskalationsklausel, Rechtswahl in jeden Großvertrag.",
            trifft: hat(.schiedsklauselnFehlen)) { _ in "Ohne Klausel entscheidet der Gegner über Forum und Tempo." })
        r.append(ERRegel(.lauterkeit, "Preiswerbung", normen: ["§ 11 PAngV", "§ 5 UWG", "EuGH C-330/23 Aldi Süd"], punkte: 12, p: 80, s: 45,
            massnahme: "30-Tage-Tiefstpreis als Referenz, Rabatt-Kommunikation gegen PAngV prüfen, Preisangaben-Audit im Shop.",
            trifft: { $0.signale.contains(.aggressiveWerbung) || $0.signale.contains(.preisangabenOnline) }) { _ in "Streichpreise ohne 30-Tage-Referenz sind seit Aldi-Süd-Entscheidung die häufigste erfolgreiche Abmahnung im Handel." })
        r.append(ERRegel(.lauterkeit, "Vergleichende Werbung", normen: ["§ 6 UWG", "§ 4 Nr. 1, 2 UWG"], punkte: 10, p: 65, s: 50,
            massnahme: "Vergleich nur objektiv, nachprüfbar, wesentliche Eigenschaften; keine Herabsetzung.",
            trifft: hat(.vergleichendeWerbung)) { _ in "Jeder Vergleich lädt den Wettbewerber zur Abmahnung ein — Beweislast für Richtigkeit liegt beim Werbenden." })
        r.append(ERRegel(.lauterkeit, "Influencer-Kennzeichnung", normen: ["§ 5a Abs. 4 UWG", "§ 22 MStV", "BGH I ZR 90/20"], punkte: 8, p: 70, s: 35,
            massnahme: "Kennzeichnungs-Guideline, Vertragsklauseln mit Creatorn, Monitoring.",
            trifft: hat(.influencerMarketing)) { _ in "Kennzeichnungsfehler Dritter werden dem Unternehmen zugerechnet (§ 8 Abs. 2 UWG)." })
        r.append(ERRegel(.lauterkeit, "Green Claims", normen: ["§ 5 UWG", "BGH I ZR 98/23 Katjes (klimaneutral)", "RL 2024/825 EmpCo"], punkte: 14, p: 75, s: 55,
            massnahme: "Jede Umweltaussage belegen und erklären (Kompensation ≠ Reduktion), generische Claims streichen, Label nur zertifiziert.", frist: "EmpCo-Umsetzung 27.09.2026",
            trifft: hat(.nachhaltigkeitsClaims)) { _ in "„Klimaneutral“ ohne Erläuterung ist irreführend (BGH 2024); ab 2026 sind generische Umweltaussagen per se verboten." })
        r.append(ERRegel(.lauterkeit, "Bewertungen", normen: ["§ 5b Abs. 3 UWG", "Nr. 23b, 23c Anhang UWG"], punkte: 7, p: 60, s: 35,
            massnahme: "Echtheitsprüfung dokumentieren und offenlegen, keine gekauften/gefilterten Bewertungen.",
            trifft: hat(.kundenbewertungen)) { _ in "Fehlende Angabe zur Echtheitsprüfung ist per se unlauter." })
        r.append(ERRegel(.mna, "Fusionskontrolle", normen: ["§§ 35–41 GWB", "FKVO 139/2004", "Art. 22 FKVO / Towercast"], punkte: 12, p: 70, s: 70,
            massnahme: "Schwellenprüfung (DE: 500 Mio./50 Mio./17,5 Mio. € bzw. Transaktionswert 400 Mio. €), Timeline, Gun-Jumping vermeiden.",
            trifft: hat(.transaktionGeplant)) { _ in "Vollzug vor Freigabe ist nichtig und bußgeldbewehrt; Illumina/Grail zeigt: auch unterhalb der Schwellen ist Aufgriff möglich (§ 32f GWB)." })
        r.append(ERRegel(.mna, "Investitionsprüfung (FDI)", normen: ["§§ 55–59 AWV", "VO (EU) 2019/452"], punkte: 14, p: 65, s: 75,
            massnahme: "Sektorprüfung (10 % / 20 % / 25 % Schwellen), Meldepflicht, Unbedenklichkeitsbescheinigung, Long-Stop-Date.",
            trifft: hat(.auslaendischerInvestor)) { _ in "Erwerb ohne Freigabe ist schwebend unwirksam; Vollzugshandlungen strafbar (§ 18 AWG)." })
        r.append(ERRegel(.mna, "Carve-out / Umwandlung", normen: ["UmwG §§ 123 ff.", "§ 613a BGB", "§ 133 UmwG (Nachhaftung)"], punkte: 9, p: 55, s: 55,
            massnahme: "Betriebsübergangsunterrichtung fehlerfrei, Nachhaftung begrenzen, TSA/Lizenzen sauber schneiden.",
            trifft: hat(.carveOutGeplant)) { _ in "Fehlerhafte § 613a-Unterrichtung gibt Mitarbeitern unbefristetes Widerspruchsrecht." })
        r.append(ERRegel(.mna, "Drittstaatliche Subventionen", normen: ["VO (EU) 2022/2560 (FSR)"], punkte: 9, p: 50, s: 60,
            massnahme: "Subventionsregister, Meldeschwellen (50 Mio. € / 500 Mio. € Umsatz) prüfen, Vergabeverfahren beachten.",
            trifft: hat(.subventionenDrittstaat)) { _ in "FSR-Anmeldepflicht bei M&A und öffentlichen Aufträgen — Verstoß führt zu Vollzugsverbot." })
        r.append(ERRegel(.governance, "Konzernhaftung / Größenklasse", normen: ["§ 30 OWiG", "§ 81c GWB"], punkte: 6, p: 50, s: 60,
            massnahme: "Konzernweite Compliance-Steuerung mit Berichtslinien.",
            trifft: { $0.umsatzMio >= 500 }) { u in "Umsatz \(Int(u.umsatzMio)) Mio. € — Bußgeldrahmen bemessen sich konzernweit; Zumessung orientiert sich am Gesamtumsatz." })
        r.append(ERRegel(.litigation, "Kapitalmarkt-Exposure", normen: ["Art. 17 MAR (Ad-hoc)", "§ 97, 98 WpHG", "KapMuG"], punkte: 10, p: 50, s: 70,
            massnahme: "Ad-hoc-Komitee, Insiderlisten, Haftungsprävention bei Prognosen.",
            trifft: { $0.boersennotiert }) { _ in "Jede verspätete Ad-hoc-Mitteilung ist Anlegerklage-Potenzial (KapMuG); Rechtsrisiken selbst können ad-hoc-pflichtig sein." })
        return r
    }()
    static func bewerte(_ u: ERUnternehmen) -> [ERDimensionsScore] {
        var proDimension: [ERDimension: [ERBefund]] = [:]
        for regel in regeln where regel.trifft(u) {
            let b = ERBefund(
                dimension: regel.dimension,
                titel: regel.titel,
                begruendung: regel.begruendung(u),
                normen: regel.normen,
                punkte: regel.punkte,
                eintrittswahrscheinlichkeit: regel.wahrscheinlichkeit,
                schadenshoehe: regel.schaden,
                sofortmassnahme: regel.massnahme,
                frist: regel.frist
            )
            proDimension[regel.dimension, default: []].append(b)
        }
        let groessenfaktor: Double = u.umsatzMio >= 500 ? 1.1 : (u.istKMU ? 0.92 : 1.0)
        return ERDimension.allCases.map { d in
            let befunde = (proDimension[d] ?? []).sorted { $0.punkte > $1.punkte }
            let roh = befunde.map(\.punkte).reduce(0, +)
            let gewichtet = Double(roh) * d.gewicht(fuer: u.branche) * groessenfaktor
            let score = Int((100.0 * (1.0 - exp(-gewichtet / 32.0))).rounded())
            return ERDimensionsScore(dimension: d, score: min(100, score), rohpunkte: roh, befunde: befunde)
        }
    }
    static func gesamtscore(_ scores: [ERDimensionsScore]) -> Int {
        let sortiert = scores.map(\.score).sorted(by: >)
        guard !sortiert.isEmpty else { return 0 }
        let top3 = sortiert.prefix(3).reduce(0, +)
        let rest = sortiert.dropFirst(3).reduce(0, +)
        let wert = Double(top3) * 0.6 / 3.0 + Double(rest) * 0.4 / Double(max(1, sortiert.count - 3))
        return min(100, Int(wert.rounded()))
    }
    static func dimensionsPrior(_ d: ERDimension) -> Int {
        switch d {
        case .lauterkeit: return 92
        case .geistigesEigentum: return 86
        case .kartell: return 80
        case .datenschutz: return 72
        case .mna: return 68
        case .nachhaltigkeit: return 66
        case .produkthaftung: return 60
        case .kiRegulierung: return 56
        case .litigation: return 52
        case .steuernSanktionen: return 45
        case .arbeitsrecht: return 42
        case .vertraege: return 36
        case .cyberResilienz: return 34
        case .governance: return 30
        }
    }
    static func ausnutzbarkeit(_ d: ERDimension) -> Int { dimensionsPrior(d) }
    static func ausnutzbarkeit(dimension d: ERDimension, nachweis: Int, score: Int, befundAnzahl: Int) -> Int {
        let prior = Double(dimensionsPrior(d))
        let nachweisClamped = Double(min(100, max(0, nachweis)))
        let scoreClamped = Double(min(100, max(0, score)))
        let befundBonus = min(15.0, Double(befundAnzahl) * 4.0)
        let wert = prior * 0.45 + nachweisClamped * 0.35 + scoreClamped * 0.20 + befundBonus * 0.0
        return min(100, max(5, Int((wert + befundBonus * 0.25).rounded())))
    }
    static func nachweisbarkeit(_ u: ERUnternehmen, _ d: ERDimension) -> Int {
        let signale = u.signale.filter { $0.dimension == d }
        guard !signale.isEmpty else { return u.belegteFakten.isEmpty ? 20 : 45 }
        let beobachtbar = signale.filter(\.vonAussenBeobachtbar).count
        var wert = Int(Double(beobachtbar) / Double(signale.count) * 70.0) + 15
        if !u.belegteFakten.isEmpty { wert += 15 }
        return min(100, wert)
    }
    static func schwachstellen(eigen: ERUnternehmen, eigeneScores: [ERDimensionsScore],
                               wettbewerber: ERUnternehmen, scores: [ERDimensionsScore]) -> [ERSchwachstelle] {
        var out: [ERSchwachstelle] = []
        for s in scores where s.score >= 38 {
            let eigenScore = eigeneScores.first { $0.dimension == s.dimension }?.score ?? 0
            let diff = s.score - eigenScore
            guard diff >= 8 || s.score >= 60 else { continue }
            let top = s.befunde.prefix(2).map(\.titel).joined(separator: " · ")
            let nachweis = nachweisbarkeit(wettbewerber, s.dimension)
            out.append(ERSchwachstelle(
                unternehmenId: wettbewerber.id,
                unternehmenName: wettbewerber.name,
                rolle: .konkurrent,
                dimension: s.dimension,
                titel: "\(s.dimension.titel): \(top.isEmpty ? "erhöhte Exposure" : top)",
                beschreibung: s.befunde.first?.begruendung ?? "Struktur- und Größenmerkmale erzeugen überdurchschnittliche Exposure.",
                ausnutzbarkeit: ausnutzbarkeit(dimension: s.dimension, nachweis: nachweis, score: s.score, befundAnzahl: s.befunde.count),
                nachweisbarkeit: nachweis,
                dringlichkeit: s.score,
                differenzZumEigenen: diff
            ))
        }
        return out.sorted { $0.hebelIndex > $1.hebelIndex }
    }
    static func eigeneSchwachstellen(_ u: ERUnternehmen, scores: [ERDimensionsScore],
                                     wettbewerberScores: [[ERDimensionsScore]]) -> [ERSchwachstelle] {
        var out: [ERSchwachstelle] = []
        for s in scores where s.score >= 35 {
            let besterGegner = wettbewerberScores.compactMap { $0.first { $0.dimension == s.dimension }?.score }.min() ?? s.score
            let top = s.befunde.first
            let nachweis = nachweisbarkeit(u, s.dimension)
            out.append(ERSchwachstelle(
                unternehmenId: u.id,
                unternehmenName: u.name,
                rolle: .eigen,
                dimension: s.dimension,
                titel: top.map { "\(s.dimension.titel): \($0.titel)" } ?? s.dimension.titel,
                beschreibung: top?.begruendung ?? "",
                ausnutzbarkeit: ausnutzbarkeit(dimension: s.dimension, nachweis: nachweis, score: s.score, befundAnzahl: s.befunde.count),
                nachweisbarkeit: nachweis,
                dringlichkeit: s.score,
                differenzZumEigenen: besterGegner - s.score   // negativ = Gegner steht besser
            ))
        }
        return out.sorted { $0.hebelIndex > $1.hebelIndex }
    }
    struct VorteilVorlage {
        let typ: ERVorteilTyp
        let titel: String
        let mechanik: String
        let normen: [String]
        let aktivlegitimation: String
        let leitplanken: String
        let effekt: Int
        let aufwand: Int
        let zeitfenster: String
    }
    static func offensivVorlagen(_ d: ERDimension) -> [VorteilVorlage] {
        switch d {
        case .lauterkeit:
            return [
                .init(typ: .offensiv, titel: "Wettbewerbsrechtliche Abmahnung / Unterlassung", mechanik: "Unlautere Werbung (Preis, Green Claims, Vergleich, Bewertungen) des Wettbewerbers wird per Abmahnung und ggf. einstweiliger Verfügung gestoppt — Kampagnen fallen aus, Kosten entstehen beim Gegner.", normen: ["§§ 3, 5, 5a, 8 UWG", "§ 12 UWG", "§§ 935, 940 ZPO"], aktivlegitimation: "Mitbewerber (§ 8 Abs. 3 Nr. 1 UWG) — unmittelbar", leitplanken: "Keine missbräuchliche Abmahnung (§ 8c UWG), keine Herabsetzung in der Kommunikation (§ 4 Nr. 1 UWG), Dringlichkeit 1 Monat wahren.", effekt: 70, aufwand: 25, zeitfenster: "2–6 Wochen"),
                .init(typ: .positionierung, titel: "Transparenz-Positionierung", mechanik: "Eigene nachweisbar korrekte Preis- und Nachhaltigkeitskommunikation als Vertrauensmerkmal aufbauen, während der Gegner nachbessern muss.", normen: ["§ 6 UWG (zulässiger Vergleich)"], aktivlegitimation: "Eigenes Marketing", leitplanken: "Vergleich nur objektiv und nachprüfbar.", effekt: 45, aufwand: 20, zeitfenster: "1–3 Monate")
            ]
        case .geistigesEigentum:
            return [
                .init(typ: .offensiv, titel: "Schutzrechtsangriff (Nichtigkeit / Löschung / Einspruch)", mechanik: "Schwache Schutzrechte des Wettbewerbers werden angegriffen; Lizenzverhandlungen kippen, Verletzungsklagen des Gegners verlieren ihre Basis.", normen: ["§ 81 PatG", "Art. 99 EPÜ", "§ 49 ff. MarkenG", "Art. 65 EPGÜ"], aktivlegitimation: "Jedermann (Popularklage, außer Marken-Löschung wegen älterer Rechte)", leitplanken: "Keine Behauptung der Rechtsungültigkeit gegenüber Kunden vor Entscheidung (§ 4 Nr. 2 UWG).", effekt: 72, aufwand: 55, zeitfenster: "6–24 Monate"),
                .init(typ: .offensiv, titel: "Verletzungsdurchsetzung mit eigenem Portfolio", mechanik: "Eigene Patente/Marken gegen den Gegner durchsetzen — einstweilige Verfügung, Grenzbeschlagnahme, UPC-Weg für 18 Staaten in einem Verfahren.", normen: ["§ 139 PatG", "§ 14 MarkenG", "VO 608/2013 (Zoll)", "EPGÜ"], aktivlegitimation: "Schutzrechtsinhaber / ausschließlicher Lizenznehmer", leitplanken: "Unberechtigte Schutzrechtsverwarnung begründet Schadensersatz (BGH GSZ 1/04).", effekt: 80, aufwand: 60, zeitfenster: "Verfügung: Wochen · Hauptsache: 12–18 Monate"),
                .init(typ: .positionierung, titel: "Patentzaun & Design-around", mechanik: "Dort anmelden, wo der Wettbewerber Lücken hat; seine Weiterentwicklung wird blockiert oder lizenzpflichtig.", normen: ["PatG", "GebrMG (schnell, 10 Jahre)"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Keine Sperrpatente ohne Benutzungsabsicht bei Marktmacht (Art. 102 AEUV).", effekt: 60, aufwand: 45, zeitfenster: "3–12 Monate")
            ]
        case .kartell:
            return [
                .init(typ: .offensiv, titel: "Beschwerde bei Kartellbehörde", mechanik: "Missbrauch oder Absprachen des Wettbewerbers werden Bundeskartellamt / EU-Kommission angezeigt; Verfahren bindet Gegner über Jahre und öffnet den Markt.", normen: ["§ 54 Abs. 2 GWB (Beiladung)", "Art. 7 VO 1/2003", "§ 32 GWB"], aktivlegitimation: "Jedermann; Beteiligung als Beigeladener bei erheblichem Interesse", leitplanken: "Keine falschen Tatsachenbehauptungen; eigene Verhaltensweisen vorab prüfen (Spiegeleffekt).", effekt: 75, aufwand: 40, zeitfenster: "Prüfung 6–36 Monate · Sofortmaßnahmen möglich (§ 32a GWB)"),
                .init(typ: .offensiv, titel: "Private Enforcement", mechanik: "Schadensersatz und Unterlassung wegen Kartellverstoßes — Follow-on nach Behördenentscheidung mit Bindungswirkung.", normen: ["§ 33, 33a GWB", "§ 33b GWB (Bindung)", "§ 33g GWB (Offenlegung)"], aktivlegitimation: "Betroffene (Abnehmer, Wettbewerber)", leitplanken: "Verjährung 5 Jahre; Prozessfinanzierung prüfen.", effekt: 65, aufwand: 55, zeitfenster: "2–5 Jahre"),
                .init(typ: .verhandlung, titel: "Zugangs- und Konditionenforderung", mechanik: "Bei Marktbeherrschung des Gegners Zugang zu Infrastruktur/Daten/Plattform verlangen; Verhandlungsposition kippt.", normen: ["§ 19 Abs. 2 Nr. 4 GWB", "§ 19a GWB", "DMA Art. 6", "Data Act"], aktivlegitimation: "Abhängige / Geschäftsnutzer", leitplanken: "FRAND-Angebot selbst konstruktiv formulieren.", effekt: 58, aufwand: 35, zeitfenster: "3–12 Monate")
            ]
        case .datenschutz:
            return [
                .init(typ: .offensiv, titel: "UWG-Rechtsbruch wegen DSGVO-Verstoß", mechanik: "Datenschutzverstöße (Tracking, fehlende Information) des Wettbewerbers werden wettbewerbsrechtlich abgemahnt — seit EuGH Lindenapotheke ausdrücklich zulässig.", normen: ["§ 3a UWG", "EuGH C-21/23", "BGH I ZR 222/19"], aktivlegitimation: "Mitbewerber", leitplanken: "Nur Marktverhaltensregeln (Art. 12–14, 6 DSGVO); keine Datenerhebung über den Gegner ohne Rechtsgrundlage.", effekt: 62, aufwand: 25, zeitfenster: "4–8 Wochen"),
                .init(typ: .positionierung, titel: "Privacy-by-Design als Vertriebsargument", mechanik: "Zertifizierung (ISO 27701, EU-Datenschutzsiegel) und Datenresidenz als Ausschreibungs-Kriterium — Gegner ohne Nachweis scheidet aus.", normen: ["Art. 42 DSGVO", "§ 31 VgV (Zuschlagskriterien)"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Keine herabsetzenden Vergleiche ohne Beleg.", effekt: 50, aufwand: 40, zeitfenster: "3–9 Monate")
            ]
        case .mna:
            return [
                .init(typ: .offensiv, titel: "Stellungnahme im Fusionskontrollverfahren", mechanik: "Als Wettbewerber substantiiert gegen Freigabe oder für Auflagen argumentieren; Transaktion verzögert sich oder wird mit Veräußerungsauflagen belegt — Gelegenheit zum Erwerb der Assets.", normen: ["§ 54 Abs. 2 Nr. 3 GWB", "Art. 18 FKVO", "§ 40 Abs. 3 GWB (Bedingungen)"], aktivlegitimation: "Betroffene Dritte / Beigeladene", leitplanken: "Sachliche Marktdaten; Lobby-Interesse offenlegen.", effekt: 60, aufwand: 35, zeitfenster: "1–6 Monate (Phase I/II)"),
                .init(typ: .verhandlung, titel: "White Knight / Asset-Erwerb", mechanik: "Veräußerungsauflagen oder gescheiterte Transaktionen eröffnen Erwerbschancen zu Vorzugspreisen.", normen: ["§ 40 GWB", "UmwG"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Eigene Fusionskontrolle, FDI-Prüfung.", effekt: 55, aufwand: 70, zeitfenster: "6–18 Monate")
            ]
        case .nachhaltigkeit:
            return [
                .init(typ: .offensiv, titel: "BAFA-Beschwerde / Substantiierte Hinweise", mechanik: "Lieferkettenverstöße des Wettbewerbers werden der Behörde angezeigt (Beschwerdeverfahren § 14 LkSG, EUDR-Hinweise); drohender Vergabeausschluss trifft dessen öffentliche Aufträge.", normen: ["§ 14 Abs. 1 Nr. 2 LkSG", "§ 22 LkSG", "Art. 31 EUDR"], aktivlegitimation: "Jedermann (substantiierte Kenntnis)", leitplanken: "Nur belegte Tatsachen; Anschwärzung (§ 4 Nr. 2 UWG) und üble Nachrede vermeiden.", effekt: 58, aufwand: 30, zeitfenster: "3–12 Monate"),
                .init(typ: .positionierung, titel: "ESG-Vorsprung in Ausschreibungen und Finanzierung", mechanik: "Belegte Sorgfalt (CSRD-Daten, Zertifikate) als harte Zuschlags- und Finanzierungsbedingung; der unvorbereitete Gegner verliert Großkunden und zahlt höhere Zinsen.", normen: ["§ 97 Abs. 3 GWB", "EU-Taxonomie-VO", "§ 31 VgV"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Green Claims nur belegt (EmpCo-RL).", effekt: 55, aufwand: 45, zeitfenster: "6–18 Monate")
            ]
        case .produkthaftung:
            return [
                .init(typ: .offensiv, titel: "Marktüberwachungs-Hinweis", mechanik: "Nicht-konforme Produkte des Wettbewerbers (CE, CRA, Sicherheit) werden der Marktüberwachung gemeldet; Vertriebsverbot, Rückruf, RAPEX-Eintrag.", normen: ["§ 26 ProdSG", "VO 2019/1020 Art. 11", "Art. 52 CRA"], aktivlegitimation: "Jedermann", leitplanken: "Belegbare Mängel; keine Warnungen an Kunden vor Behördenentscheidung.", effekt: 66, aufwand: 30, zeitfenster: "2–9 Monate"),
                .init(typ: .positionierung, titel: "Konformitäts- und Sicherheitsführerschaft", mechanik: "Frühe CRA-/ProdHaftRL-Konformität als Marktzutrittsbarriere für Nachzügler.", normen: ["CRA", "RL 2024/2853"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "—", effekt: 50, aufwand: 50, zeitfenster: "6–14 Monate")
            ]
        case .kiRegulierung:
            return [
                .init(typ: .offensiv, titel: "Marktaufsicht AI Act", mechanik: "Verstöße des Wettbewerbers (fehlende Transparenz Art. 50, Hochrisiko ohne Konformität) werden der Marktüberwachungsbehörde gemeldet; parallel UWG-Rechtsbruch prüfen.", normen: ["Art. 85 AI Act (Beschwerderecht)", "§ 3a UWG"], aktivlegitimation: "Jede natürliche/juristische Person", leitplanken: "Nur eigene Beobachtungen, keine Testkäufe mit Täuschung.", effekt: 55, aufwand: 30, zeitfenster: "3–12 Monate"),
                .init(typ: .positionierung, titel: "Trusted-AI-Positionierung", mechanik: "Konformitätsnachweis als Einkaufskriterium bei Großkunden und öffentlicher Hand; Gegner ohne Dokumentation wird nicht gelistet.", normen: ["Art. 40 AI Act (harmonisierte Normen)", "ISO/IEC 42001"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "—", effekt: 52, aufwand: 45, zeitfenster: "6–12 Monate")
            ]
        case .arbeitsrecht:
            return [
                .init(typ: .verhandlung, titel: "Talent-Offensive", mechanik: "Abwerbung von Schlüsselpersonal ist zulässig; bei Restrukturierung, Entgeltlücke oder Scheinselbständigkeit des Gegners ist die Wechselbereitschaft hoch.", normen: ["Art. 12 GG", "§ 4 Nr. 4 UWG (Grenze)", "§ 74 ff. HGB"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Keine Verleitung zum Vertragsbruch, keine Mitnahme von Geschäftsgeheimnissen (§ 4 GeschGehG), Wettbewerbsverbote prüfen.", effekt: 58, aufwand: 35, zeitfenster: "laufend"),
                .init(typ: .offensiv, titel: "Hinweis an Prüfbehörden", mechanik: "Deutsche Rentenversicherung / Zoll (FKS) prüfen bei konkreten Anhaltspunkten Scheinselbständigkeit und Schwarzarbeit.", normen: ["§ 28p SGB IV", "§ 2 SchwarzArbG"], aktivlegitimation: "Jedermann", leitplanken: "Nur Tatsachen; sonst Anschwärzung.", effekt: 40, aufwand: 20, zeitfenster: "6–18 Monate")
            ]
        case .litigation:
            return [
                .init(typ: .verhandlung, titel: "Verhandlungsmacht aus Litigation-Last", mechanik: "Ein in Verfahren gebundener Wettbewerber verhandelt schwächer — Zeitpunkt für Lizenz-, Liefer- oder Übernahmeverhandlungen.", normen: ["Prozessökonomie"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Keine Ausnutzung von Zwangslagen (§ 138 BGB).", effekt: 48, aufwand: 20, zeitfenster: "verfahrensabhängig"),
                .init(typ: .offensiv, titel: "Streitgenossenschaft / Beitritt", mechanik: "Bestehenden Verfahren gegen den Gegner beitreten oder parallele Klagen koordinieren (Musterverfahren).", normen: ["§§ 59, 66 ZPO", "KapMuG", "VDuG"], aktivlegitimation: "Betroffene", leitplanken: "Eigene Anspruchsgrundlage nötig.", effekt: 45, aufwand: 45, zeitfenster: "6–24 Monate")
            ]
        case .steuernSanktionen:
            return [
                .init(typ: .positionierung, titel: "Compliance-Clearance als Lieferantenvorteil", mechanik: "Sanktions- und GwG-sauberes Profil wird für Banken und Konzerne zur Vorbedingung; Gegner mit Sanktions-Exposure wird de-risked (Konten, Lieferlisten).", normen: ["Art. 8 VO 833/2014", "§ 10 GwG"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Keine unbelegten Behauptungen gegenüber Banken Dritter.", effekt: 52, aufwand: 35, zeitfenster: "3–9 Monate"),
                .init(typ: .offensiv, titel: "Hinweis an Zoll / BAFA / FIU", mechanik: "Belegte Sanktionsumgehung oder Geldwäsche-Indizien werden gemeldet; strafrechtliche Konsequenz für den Gegner.", normen: ["§ 18 AWG", "§ 43 GwG"], aktivlegitimation: "Jedermann", leitplanken: "Nur Tatsachen; sonst falsche Verdächtigung (§ 164 StGB).", effekt: 55, aufwand: 25, zeitfenster: "6–24 Monate")
            ]
        case .vertraege:
            return [
                .init(typ: .verhandlung, titel: "Partner des Gegners gewinnen", mechanik: "Lieferanten/Kunden mit Langfristbindung oder Klumpenrisiko beim Gegner erhalten bessere Konditionen und Exit-Begleitung bei Kündigungsmöglichkeit.", normen: ["Vertragsfreiheit", "§ 4 Nr. 4 UWG (Grenze)"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Kein Verleiten zum Vertragsbruch; nur reguläre Kündigungsfenster nutzen.", effekt: 50, aufwand: 30, zeitfenster: "kündigungsfristabhängig"),
                .init(typ: .offensiv, titel: "Verbandsklage gegen AGB", mechanik: "Unwirksame AGB des Wettbewerbers über qualifizierte Einrichtung angreifen (UKlaG) oder als Mitbewerber abmahnen (§ 3a UWG).", normen: ["§ 1 UKlaG", "§ 3a UWG", "§ 307 BGB"], aktivlegitimation: "Verband / Mitbewerber", leitplanken: "—", effekt: 42, aufwand: 25, zeitfenster: "2–12 Monate")
            ]
        case .cyberResilienz:
            return [
                .init(typ: .positionierung, titel: "Resilienz-Zertifikate als Einkaufsbedingung", mechanik: "ISO 27001/NIS2-Nachweis in Ausschreibungen und Lieferantenaudits; der Gegner ohne ISMS wird von Großkunden ausgesteuert (DORA/NIS2-Weitergabe).", normen: ["Art. 21 Abs. 2 lit. d NIS2 (Lieferkette)", "DORA Art. 28"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "—", effekt: 55, aufwand: 45, zeitfenster: "6–12 Monate")
            ]
        case .governance:
            return [
                .init(typ: .verhandlung, titel: "Übernahme- / Beteiligungsfenster", mechanik: "Nachfolge-, Gesellschafterstreit- oder Liquiditätsschwäche des Gegners eröffnet Beteiligungs-, Übernahme- oder Asset-Deal-Optionen.", normen: ["GmbHG", "StaRUG", "InsO (§ 160 übertragende Sanierung)"], aktivlegitimation: "Eigenes Unternehmen", leitplanken: "Fusionskontrolle, kein Insiderhandel bei Börsennotierung.", effekt: 60, aufwand: 65, zeitfenster: "3–18 Monate")
            ]
        }
    }
    static func defensivVorlage(_ s: ERSchwachstelle, befund: ERBefund?) -> ERVorteil {
        ERVorteil(
            typ: .defensiv,
            dimension: s.dimension,
            titel: "Festung: \(s.dimension.titel) schließen",
            mechanik: befund?.sofortmassnahme ?? "Exposure in \(s.dimension.titel) durch Compliance-Programm und Vertragsgestaltung reduzieren.",
            rechtsgrundlage: befund?.normen ?? s.dimension.rechtsrahmen,
            aktivlegitimation: "Geschäftsleitung (Legalitätspflicht)",
            leitplanken: "Dokumentation gerichtsfest; Verteidigungsfähigkeit vor Außenkommunikation.",
            erwarteterEffekt: min(100, s.dringlichkeit + 10),
            umsetzungsaufwand: max(20, 100 - s.ausnutzbarkeit),
            zeitfenster: befund?.frist ?? "90 Tage",
            basisSchwachstelleId: s.id
        )
    }
    static func vorteile(eigen: ERUnternehmen, eigeneScores: [ERDimensionsScore],
                         eigeneSchwachstellen: [ERSchwachstelle],
                         wettbewerberSchwachstellen: [ERSchwachstelle]) -> [ERVorteil] {
        var out: [ERVorteil] = []
        var gesehen: Set<String> = []
        for s in wettbewerberSchwachstellen {
            for v in offensivVorlagen(s.dimension) {
                let key = "\(s.dimension.rawValue)|\(v.titel)"
                guard !gesehen.contains(key) else { continue }
                gesehen.insert(key)
                let effekt = Int(Double(v.effekt) * (0.55 + 0.45 * Double(s.hebelIndex) / 100.0))
                out.append(ERVorteil(
                    typ: v.typ, dimension: s.dimension, titel: v.titel,
                    mechanik: "\(v.mechanik) — Ziel: \(s.unternehmenName).",
                    rechtsgrundlage: v.normen, aktivlegitimation: v.aktivlegitimation,
                    leitplanken: v.leitplanken, erwarteterEffekt: effekt,
                    umsetzungsaufwand: v.aufwand, zeitfenster: v.zeitfenster,
                    basisSchwachstelleId: s.id
                ))
            }
        }
        for s in eigeneSchwachstellen.prefix(5) {
            let befund = eigeneScores.first { $0.dimension == s.dimension }?.befunde.first
            out.append(defensivVorlage(s, befund: befund))
        }
        return out.sorted { $0.nettoHebel > $1.nettoHebel }
    }
    static func strategien(eigen: ERUnternehmen, eigeneScores: [ERDimensionsScore],
                           eigeneSchwachstellen: [ERSchwachstelle],
                           wettbewerberSchwachstellen: [ERSchwachstelle],
                           vorteile: [ERVorteil], fristen: [ERFrist]) -> [ERStrategie] {
        var out: [ERStrategie] = []
        let offensiv = vorteile.filter { $0.typ == .offensiv }
        let defensiv = vorteile.filter { $0.typ == .defensiv }
        let position = vorteile.filter { $0.typ == .positionierung }
        let verhandlung = vorteile.filter { $0.typ == .verhandlung }
        if !defensiv.isEmpty {
            let zuege = defensiv.prefix(4).enumerated().map { i, v in
                ERZug(schritt: v.mechanik, verantwortlich: i == 0 ? "Geschäftsleitung + Legal" : "Legal / Compliance", frist: v.zeitfenster, norm: v.rechtsgrundlage.first)
            }
            out.append(ERStrategie(
                archetyp: .festung,
                titel: "Festung zuerst: eigene Angriffsflächen schließen",
                ziel: "Die \(defensiv.count) größten eigenen Exposures so weit senken, dass kein Wettbewerber sie als Hebel nutzen kann.",
                zuege: zuege, vorteilIds: defensiv.map(\.id),
                erfolgswahrscheinlichkeit: 0, erwarteterNutzen: min(100, defensiv.map(\.erwarteterEffekt).reduce(0, +) / max(1, defensiv.count)),
                risiko: 15,
                gegenreaktion: "Wettbewerber beschleunigen eigene Angriffe, bevor Lücken geschlossen sind — deshalb stille Umsetzung, Kommunikation erst nach Abschluss.",
                leitplanken: "Legalitätspflicht; keine Beweisvernichtung (Legal Hold), Selbstanzeige-Optionen prüfen (§ 371 AO, Kronzeugenprogramm)."
            ))
        }
        if let top = offensiv.first, top.nettoHebel >= 35 {
            let zuege: [ERZug] = [
                ERZug(schritt: "Beweissicherung: Screenshots, Testkäufe, Zeitstempel, notarielle Feststellung.", verantwortlich: "Legal", frist: "1–2 Wochen", norm: "§ 12 UWG / § 140c PatG"),
                ERZug(schritt: top.mechanik, verantwortlich: "Externe Kanzlei (Fachanwalt)", frist: top.zeitfenster, norm: top.rechtsgrundlage.first),
                ERZug(schritt: "Parallel: eigene Position in derselben Dimension prüfen (Spiegelrisiko).", verantwortlich: "Compliance", frist: "vor Einreichung", norm: nil),
                ERZug(schritt: "Kommunikation nur faktisch; Reaktion auf Gegenabmahnung vorbereiten (Schutzschrift).", verantwortlich: "Legal + Kommunikation", frist: "mit Zug 2", norm: "§ 945a ZPO")
            ]
            out.append(ERStrategie(
                archetyp: .unvorbereiteterGegner,
                titel: "Offensive: \(top.titel)",
                ziel: "Den Wettbewerber dort rechtlich binden, wo er nachweisbar exponiert ist — \(top.dimension.titel).",
                zuege: zuege, vorteilIds: offensiv.prefix(3).map(\.id),
                erfolgswahrscheinlichkeit: 0, erwarteterNutzen: top.erwarteterEffekt, risiko: 40,
                gegenreaktion: "Gegenabmahnung, Nichtigkeitsangriff auf eigene Rechte, Behördenbeschwerde gegen uns — Festung muss vorher stehen.",
                leitplanken: top.leitplanken
            ))
        }
        if !position.isEmpty {
            let zuege = position.prefix(3).map { v in
                ERZug(schritt: v.mechanik, verantwortlich: "Vertrieb + Compliance", frist: v.zeitfenster, norm: v.rechtsgrundlage.first)
            } + [ERZug(schritt: "Zuschlagskriterien bei Großkunden/öffentlicher Hand aktiv mitgestalten (Markterkundung § 28 VgV).", verantwortlich: "Vertrieb / Public Affairs", frist: "laufend", norm: "§ 28 VgV")]
            out.append(ERStrategie(
                archetyp: .siegOhneKampf,
                titel: "Sieg ohne Kampf: Compliance als Marktstandard",
                ziel: "Eigene Konformität zur Einkaufsbedingung der Kunden machen — der Gegner verliert, ohne dass wir klagen.",
                zuege: zuege, vorteilIds: position.map(\.id),
                erfolgswahrscheinlichkeit: 0, erwarteterNutzen: min(100, position.map(\.erwarteterEffekt).max() ?? 50), risiko: 12,
                gegenreaktion: "Gegner holt auf — deshalb Zertifikate früh, Kundenverträge mit Compliance-Klauseln sichern.",
                leitplanken: "Keine herabsetzenden Vergleiche; Behauptungen über den Gegner nur belegt."
            ))
        }
        let ipScore = eigeneScores.first { $0.dimension == .geistigesEigentum }?.score ?? 0
        if [.software, .industrie, .gesundheit, .automotive, .chemie, .energie].contains(eigen.branche) || ipScore >= 30 {
            out.append(ERStrategie(
                archetyp: .terrainBesetzen,
                titel: "Terrain besetzen: Schutzrechte, Standards, Daten",
                ziel: "Technologie- und Marktzugänge so absichern, dass der Wettbewerber nur mit Lizenz oder Umweg folgen kann.",
                zuege: [
                    ERZug(schritt: "FTO-Analyse und Anmeldewelle (DE/GebrM → EP/UP → PCT) für Kernfunktionen; Design-around-Lücken des Gegners gezielt besetzen.", verantwortlich: "Patentanwalt + F&E", frist: "3–9 Monate", norm: "PatG, GebrMG, EPGÜ"),
                    ERZug(schritt: "Normungsgremien (DIN/CEN/ETSI) besetzen — Standard-essenzielle Position mit FRAND-Verpflichtung.", verantwortlich: "CTO / Public Affairs", frist: "12–24 Monate", norm: "Art. 101 Abs. 3 AEUV, Horizontal-LL Kap. 7"),
                    ERZug(schritt: "Geschäftsgeheimnis-Schutzkonzept (§ 2 GeschGehG) als Voraussetzung jeder späteren Durchsetzung.", verantwortlich: "Legal + IT", frist: "90 Tage", norm: "§ 2 Nr. 1 lit. b GeschGehG"),
                    ERZug(schritt: "Datenzugangs- und Nutzungsrechte vertraglich sichern (Data Act), Datenräume als Eintrittsbarriere.", verantwortlich: "Legal + Produkt", frist: "6 Monate", norm: "Data Act Art. 4–7")
                ],
                vorteilIds: vorteile.filter { $0.dimension == .geistigesEigentum }.map(\.id),
                erfolgswahrscheinlichkeit: 0, erwarteterNutzen: 62, risiko: 25,
                gegenreaktion: "Einspruch/Nichtigkeit gegen eigene Anmeldungen; Standardisierungs-Gegenallianzen.",
                leitplanken: "Keine Sperrstrategie bei Marktmacht ohne Nutzungsabsicht (Art. 102 AEUV); FRAND-Verpflichtungen einhalten (EuGH Huawei/ZTE)."
            ))
        }
        if !verhandlung.isEmpty || eigen.signale.contains(.abhaengigVonEinemKunden) {
            let zuege = verhandlung.prefix(2).map { v in
                ERZug(schritt: v.mechanik, verantwortlich: "Geschäftsleitung + Vertrieb", frist: v.zeitfenster, norm: v.rechtsgrundlage.first)
            } + [
                ERZug(schritt: "Lieferanten- und Kundenbindung mit kartellrechtlich sauberen Instrumenten (Laufzeit ≤ 5 J., Mindestabnahme, Service-Level statt Exklusivität).", verantwortlich: "Legal + Einkauf", frist: "6 Monate", norm: "Vertikal-GVO 2022/720"),
                ERZug(schritt: "Behörden- und Verbandsbeziehungen professionalisieren (Stellungnahmen, Konsultationen) — Regulierungsvorsprung statt Reaktion.", verantwortlich: "Public Affairs", frist: "laufend", norm: nil)
            ]
            out.append(ERStrategie(
                archetyp: .allianz,
                titel: "Allianz & Bindung",
                ziel: "Das Ökosystem (Kunden, Lieferanten, Behörden, Talente) so binden, dass der Wettbewerber Zugänge verliert.",
                zuege: zuege, vorteilIds: verhandlung.map(\.id),
                erfolgswahrscheinlichkeit: 0, erwarteterNutzen: 55, risiko: 22,
                gegenreaktion: "Gegner bietet bessere Konditionen; Kartellbehörde prüft Bindungen bei Marktmacht.",
                leitplanken: "§ 1 GWB / Art. 101 AEUV; keine Verleitung zum Vertragsbruch; keine Abwerbung mit Geheimnismitnahme."
            ))
        }
        let relevanteFristen = fristen.filter { f in (eigeneScores.first { $0.dimension == f.dimension }?.score ?? 0) >= 25 }
        if !relevanteFristen.isEmpty {
            out.append(ERStrategie(
                archetyp: .timing,
                titel: "Timing: Regulatorische Stichtage als Waffe",
                ziel: "Jeden Stichtag vor dem Wettbewerber erfüllen — und ab Stichtag seine Nicht-Erfüllung nutzen.",
                zuege: relevanteFristen.prefix(5).map { f in
                    ERZug(schritt: "\(f.titel): eigene Konformität vor Stichtag, Monitoring des Wettbewerbers ab Stichtag. \(f.relevanz)", verantwortlich: "Compliance", frist: f.datum, norm: f.dimension.rechtsrahmen.first)
                },
                vorteilIds: [],
                erfolgswahrscheinlichkeit: 0, erwarteterNutzen: 58, risiko: 18,
                gegenreaktion: "Verschiebung von Stichtagen (Omnibus-Pakete) — Monitoring der Gesetzgebung ist Teil der Strategie.",
                leitplanken: "Behördenhinweise nur mit belegten Tatsachen."
            ))
        }
        return out
    }
    static let fristen: [ERFrist] = [
        ERFrist(titel: "AI Act — Hochrisiko Anhang III (in Kraft)", datum: "seit 02.08.2026", dimension: .kiRegulierung, relevanz: "Betreiber- und Anbieterpflichten vollständig anwendbar."),
        ERFrist(titel: "AI Act — Hochrisiko Anhang I (Produkte)", datum: "02.08.2027", dimension: .kiRegulierung, relevanz: "KI in regulierten Produkten (Maschinen, Medizin, Fahrzeuge)."),
        ERFrist(titel: "Produkthaftungsrichtlinie 2024/2853", datum: "09.12.2026", dimension: .produkthaftung, relevanz: "Software als Produkt, Beweisvermutung, Offenlegungspflicht."),
        ERFrist(titel: "Cyber Resilience Act — Meldepflichten", datum: "11.09.2026", dimension: .produkthaftung, relevanz: "Aktiv ausgenutzte Schwachstellen binnen 24 h melden."),
        ERFrist(titel: "Cyber Resilience Act — Vollanwendung", datum: "11.12.2027", dimension: .cyberResilienz, relevanz: "CE-Kennzeichnung nur mit CRA-Konformität."),
        ERFrist(titel: "Entgelttransparenz-RL — Umsetzung", datum: "07.06.2026", dimension: .arbeitsrecht, relevanz: "Berichtspflichten ab 100 MA, Beweislastumkehr."),
        ERFrist(titel: "EmpCo-RL (Green Claims) — Anwendung", datum: "27.09.2026", dimension: .lauterkeit, relevanz: "Generische Umweltaussagen und nicht zertifizierte Label verboten."),
        ERFrist(titel: "EUDR — Anwendung große Unternehmen", datum: "30.12.2026 (Stand prüfen)", dimension: .nachhaltigkeit, relevanz: "Sorgfaltserklärung Pflicht für Inverkehrbringen."),
        ERFrist(titel: "CSRD Welle 2 (Omnibus-verschoben)", datum: "GJ 2027 / Bericht 2028", dimension: .nachhaltigkeit, relevanz: "Große Unternehmen ≥ 1.000 MA."),
        ERFrist(titel: "CSDDD — Umsetzung", datum: "26.07.2027", dimension: .nachhaltigkeit, relevanz: "Europäische Lieferketten-Sorgfalt mit zivilrechtlicher Haftung."),
        ERFrist(titel: "NIS2UmsuCG — Registrierungs-/Nachweispflichten", datum: "laufend seit 12/2025", dimension: .cyberResilienz, relevanz: "BSI-Registrierung, Geschäftsleiter-Pflichten."),
        ERFrist(titel: "Data Act — Vertragsklauselkontrolle B2B", datum: "seit 12.09.2025 · Altverträge 12.09.2027", dimension: .vertraege, relevanz: "Unfaire Datenklauseln unwirksam."),
        ERFrist(titel: "DSGVO Verfahrensverordnung (grenzüberschreitend)", datum: "2026/2027", dimension: .datenschutz, relevanz: "Schnellere One-Stop-Shop-Verfahren — höhere Bußgeldgeschwindigkeit.")
    ]
    struct LCG {
        private var zustand: UInt64
        init(seed: UInt64) { zustand = seed &* 6364136223846793005 &+ 1442695040888963407 }
        mutating func naechste() -> Double {
            zustand = zustand &* 6364136223846793005 &+ 1442695040888963407
            return Double(zustand >> 11) / Double(1 << 53)
        }
    }
    static func stabilerHash(_ text: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in text.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }
    static func simuliere(_ s: ERStrategie, vorteile: [ERVorteil], laeufe: Int = 3000) -> ERSimulation {
        var rng = LCG(seed: stabilerHash(s.archetyp.rawValue + s.titel) ^ 0x9E3779B97F4A7C15)
        let beteiligt = vorteile.filter { s.vorteilIds.contains($0.id) }
        var ergebnisse: [Double] = []
        ergebnisse.reserveCapacity(laeufe)
        for _ in 0..<laeufe {
            var wert = Double(s.erwarteterNutzen) * (0.6 + 0.8 * rng.naechste())
            for v in beteiligt {
                let p = 0.35 + 0.6 * Double(v.erwarteterEffekt) / 100.0
                if rng.naechste() < p { wert += Double(v.nettoHebel) * 0.4 * rng.naechste() }
                else { wert -= Double(v.umsetzungsaufwand) * 0.25 * rng.naechste() }
            }
            wert -= Double(s.risiko) * rng.naechste() * 0.8
            ergebnisse.append(wert)
        }
        ergebnisse.sort()
        func q(_ p: Double) -> Int { Int(ergebnisse[Int(Double(laeufe - 1) * p)].rounded()) }
        let erfolg = ergebnisse.filter { $0 >= Double(s.erwarteterNutzen) * 0.75 }.count * 100 / laeufe
        return ERSimulation(strategieId: s.id, p10: max(0, q(0.10)), p50: max(0, q(0.50)), p90: max(0, q(0.90)), erfolgsquote: erfolg, laeufe: laeufe)
    }
    static func analysiere(eigen: ERUnternehmen, wettbewerber: [ERUnternehmen]) -> ERErgebnis {
        let eigeneScores = bewerte(eigen)
        var wScores: [String: [ERDimensionsScore]] = [:]
        var wSchwach: [ERSchwachstelle] = []
        for w in wettbewerber {
            let s = bewerte(w)
            wScores[w.id] = s
            wSchwach += schwachstellen(eigen: eigen, eigeneScores: eigeneScores, wettbewerber: w, scores: s)
        }
        wSchwach.sort { $0.hebelIndex > $1.hebelIndex }
        let eigeneSchwach = eigeneSchwachstellen(eigen, scores: eigeneScores, wettbewerberScores: Array(wScores.values))
        let vorteile = vorteile(eigen: eigen, eigeneScores: eigeneScores, eigeneSchwachstellen: eigeneSchwach, wettbewerberSchwachstellen: wSchwach)
        var strategien = strategien(eigen: eigen, eigeneScores: eigeneScores, eigeneSchwachstellen: eigeneSchwach, wettbewerberSchwachstellen: wSchwach, vorteile: vorteile, fristen: fristen)
        let simulationen = strategien.map { simuliere($0, vorteile: vorteile) }
        for i in strategien.indices {
            strategien[i].erfolgswahrscheinlichkeit = simulationen[i].erfolgsquote
        }
        strategien.sort { ($0.erfolgswahrscheinlichkeit * $0.erwarteterNutzen) > ($1.erfolgswahrscheinlichkeit * $1.erwarteterNutzen) }
        let relevanteFristen = fristen.filter { f in (eigeneScores.first { $0.dimension == f.dimension }?.score ?? 0) >= 20 }
        return ERErgebnis(
            eigen: eigen, wettbewerber: wettbewerber,
            eigeneScores: eigeneScores, wettbewerberScores: wScores,
            gesamtscoreEigen: gesamtscore(eigeneScores),
            eigeneSchwachstellen: eigeneSchwach, wettbewerberSchwachstellen: wSchwach,
            vorteile: vorteile, strategien: strategien, simulationen: simulationen,
            fristen: relevanteFristen
        )
    }
    static func kompaktFuerKI(_ e: ERErgebnis) -> String {
        var s = "EIGEN: \(e.eigen.name) · \(e.eigen.branche.titel) · \(e.eigen.sitz.titel) · \(e.eigen.mitarbeiter) MA · \(Int(e.eigen.umsatzMio)) Mio € · Marktanteil \(Int(e.eigen.marktanteil)) % · Gesamtrisiko \(e.gesamtscoreEigen)/100\n"
        s += "Top-Risiken: " + e.topRisiken.map { "\($0.dimension.titel) \($0.score)" }.joined(separator: ", ") + "\n"
        if !e.eigen.belegteFakten.isEmpty { s += "Fakten eigen: \(e.eigen.belegteFakten.prefix(600))\n" }
        for w in e.wettbewerber {
            let sc = e.wettbewerberScores[w.id] ?? []
            s += "WETTBEWERBER: \(w.name) · \(w.branche.titel) · \(w.mitarbeiter) MA · Marktanteil \(Int(w.marktanteil)) % · Risiko \(gesamtscore(sc))/100 · Schwächen: "
            s += sc.sorted { $0.score > $1.score }.prefix(4).map { "\($0.dimension.titel) \($0.score)" }.joined(separator: ", ") + "\n"
            if !w.belegteFakten.isEmpty { s += "Fakten: \(w.belegteFakten.prefix(500))\n" }
        }
        s += "VORTEILE (Regel-Engine): " + e.vorteile.prefix(6).map { "\($0.typ.titel) · \($0.titel) [\($0.nettoHebel)]" }.joined(separator: " | ") + "\n"
        s += "STRATEGIEN: " + e.strategien.prefix(5).map { "\($0.archetyp.titel) · \($0.titel) (P=\($0.erfolgswahrscheinlichkeit)%)" }.joined(separator: " | ")
        return s
    }
}
private extension ERDimension {
    func gewicht(fuer branche: ERBranche) -> Double { branche.gewicht(self) }
}
