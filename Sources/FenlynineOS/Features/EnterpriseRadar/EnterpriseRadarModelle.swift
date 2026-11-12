import Foundation
enum ERDimension: String, Codable, CaseIterable, Identifiable {
    case datenschutz
    case kiRegulierung
    case nachhaltigkeit
    case kartell
    case geistigesEigentum
    case vertraege
    case arbeitsrecht
    case produkthaftung
    case governance
    case cyberResilienz
    case steuernSanktionen
    case litigation
    case lauterkeit
    case mna
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .datenschutz: return "Datenschutz"
        case .kiRegulierung: return "KI-Regulierung"
        case .nachhaltigkeit: return "Lieferkette & ESG"
        case .kartell: return "Kartell & Marktmacht"
        case .geistigesEigentum: return "IP & Geschäftsgeheimnis"
        case .vertraege: return "Verträge & AGB"
        case .arbeitsrecht: return "Arbeit & Mitbestimmung"
        case .produkthaftung: return "Produkt & Haftung"
        case .governance: return "Governance & Organhaftung"
        case .cyberResilienz: return "Cyber & Resilienz"
        case .steuernSanktionen: return "Steuern, GwG & Sanktionen"
        case .litigation: return "Litigation-Exposure"
        case .lauterkeit: return "Lauterkeit & Werbung"
        case .mna: return "M&A & Investitionskontrolle"
        }
    }
    var kurz: String {
        switch self {
        case .datenschutz: return "DSGVO"
        case .kiRegulierung: return "AI Act"
        case .nachhaltigkeit: return "ESG"
        case .kartell: return "GWB"
        case .geistigesEigentum: return "IP"
        case .vertraege: return "AGB"
        case .arbeitsrecht: return "ArbR"
        case .produkthaftung: return "ProdH"
        case .governance: return "Gov"
        case .cyberResilienz: return "NIS2"
        case .steuernSanktionen: return "GwG"
        case .litigation: return "Lit"
        case .lauterkeit: return "UWG"
        case .mna: return "M&A"
        }
    }
    var symbol: String {
        switch self {
        case .datenschutz: return "lock.shield"
        case .kiRegulierung: return "cpu"
        case .nachhaltigkeit: return "leaf"
        case .kartell: return "building.columns"
        case .geistigesEigentum: return "lightbulb"
        case .vertraege: return "doc.text"
        case .arbeitsrecht: return "person.3"
        case .produkthaftung: return "shippingbox"
        case .governance: return "person.badge.shield.checkmark"
        case .cyberResilienz: return "network.badge.shield.half.filled"
        case .steuernSanktionen: return "banknote"
        case .litigation: return "scalemass"
        case .lauterkeit: return "megaphone"
        case .mna: return "arrow.triangle.merge"
        }
    }
    var rechtsrahmen: [String] {
        switch self {
        case .datenschutz: return ["DSGVO", "BDSG", "TDDDG", "ePrivacy"]
        case .kiRegulierung: return ["VO (EU) 2024/1689 (AI Act)", "DSGVO Art. 22", "ProdHaftRL 2024/2853"]
        case .nachhaltigkeit: return ["LkSG", "CSRD / ESRS", "CSDDD", "EUDR", "CBAM"]
        case .kartell: return ["Art. 101, 102 AEUV", "§§ 1, 19, 19a, 20 GWB", "DMA", "FKVO"]
        case .geistigesEigentum: return ["PatG", "EPÜ / EPGÜ", "MarkenG", "UrhG", "GeschGehG", "DesignG"]
        case .vertraege: return ["§§ 305–310 BGB", "CISG", "§ 377 HGB", "Data Act"]
        case .arbeitsrecht: return ["BetrVG", "AÜG", "KSchG", "HinSchG", "EntgTranspG", "SGB IV § 7"]
        case .produkthaftung: return ["ProdHaftG (neu, RL 2024/2853)", "ProdSG", "Cyber Resilience Act", "MaschVO"]
        case .governance: return ["§ 43 GmbHG", "§ 93 AktG", "§§ 30, 130 OWiG", "StaRUG § 1", "DCGK"]
        case .cyberResilienz: return ["NIS2 / NIS2UmsuCG", "DORA", "CRA", "KRITIS-DachG"]
        case .steuernSanktionen: return ["GwG", "AWG / AWV", "EU-Sanktions-VO", "§ 1 AStG (Verrechnungspreise)"]
        case .litigation: return ["ZPO", "VDuG (Abhilfeklage)", "UKlaG", "Schiedsordnungen"]
        case .lauterkeit: return ["UWG", "PAngV", "EmpCo-RL 2024/825 (Green Claims)", "MStV"]
        case .mna: return ["FKVO / §§ 35 ff. GWB", "AWV §§ 55 ff. (FDI)", "FSR (VO 2022/2560)", "UmwG"]
        }
    }
    var sanktionsrahmen: String {
        switch self {
        case .datenschutz: return "bis 20 Mio. € / 4 % Konzernumsatz (Art. 83 DSGVO)"
        case .kiRegulierung: return "bis 35 Mio. € / 7 % (verbotene Praktiken) · 15 Mio. € / 3 % (Hochrisiko)"
        case .nachhaltigkeit: return "LkSG: bis 2 % Umsatz (> 400 Mio. €), Vergabeausschluss bis 3 Jahre"
        case .kartell: return "bis 10 % Konzernumsatz · Schadensersatz § 33a GWB · Nichtigkeit § 134 BGB"
        case .geistigesEigentum: return "Unterlassung, Vernichtung, Schadensersatz (3 Berechnungsarten), Strafbarkeit § 142 PatG"
        case .vertraege: return "Klauselunwirksamkeit, Rückabwicklung, Verbandsklage UKlaG"
        case .arbeitsrecht: return "Nachzahlung SV-Beiträge (§ 266a StGB), Bußgeld HinSchG bis 50.000 €, Unwirksamkeit Kündigungen"
        case .produkthaftung: return "verschuldensunabhängig, Beweislastumkehr (RL 2024/2853), Rückruf, Marktüberwachung"
        case .governance: return "persönliche Organhaftung (unbegrenzt), § 130 OWiG bis 1 Mio. € (× 10 bei Konzern)"
        case .cyberResilienz: return "NIS2: bis 10 Mio. € / 2 % · Geschäftsleiter-Haftung · Meldepflicht 24 h"
        case .steuernSanktionen: return "GwG bis 5 Mio. € / 10 % · AWG Freiheitsstrafe · Hinzuschätzung + Zinsen"
        case .litigation: return "Streitwert + Kosten beider Seiten + Reputations- und Managementkosten"
        case .lauterkeit: return "Abmahnung, Unterlassung, Gewinnabschöpfung § 10 UWG, Bußgeld bis 4 % (UWG § 19)"
        case .mna: return "Vollzugsverbot (§ 41 GWB), Entflechtung, Bußgeld bis 10 %, Nichtigkeit"
        }
    }
}
enum ERRolle: String, Codable, CaseIterable, Identifiable {
    case eigen, konkurrent
    var id: String { rawValue }
    var titel: String { self == .eigen ? "Eigenes Unternehmen" : "Wettbewerber" }
}
enum ERBranche: String, Codable, CaseIterable, Identifiable {
    case software, industrie, handel, finanzen, gesundheit, energie, logistik, bau, medien, dienstleistung, automotive, chemie
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .software: return "Software / Plattform"
        case .industrie: return "Industrie / Maschinenbau"
        case .handel: return "Handel / E-Commerce"
        case .finanzen: return "Finanzen / Versicherung"
        case .gesundheit: return "Gesundheit / Pharma / MedTech"
        case .energie: return "Energie / Versorger"
        case .logistik: return "Logistik / Transport"
        case .bau: return "Bau / Immobilien"
        case .medien: return "Medien / Marketing"
        case .dienstleistung: return "Beratung / Dienstleistung"
        case .automotive: return "Automotive / Zulieferer"
        case .chemie: return "Chemie / Rohstoffe"
        }
    }
    func gewicht(_ d: ERDimension) -> Double {
        switch (self, d) {
        case (.software, .datenschutz), (.software, .kiRegulierung), (.software, .geistigesEigentum): return 1.35
        case (.software, .cyberResilienz): return 1.25
        case (.industrie, .produkthaftung), (.industrie, .nachhaltigkeit), (.industrie, .geistigesEigentum): return 1.3
        case (.handel, .lauterkeit), (.handel, .datenschutz), (.handel, .vertraege): return 1.3
        case (.handel, .nachhaltigkeit): return 1.2
        case (.finanzen, .cyberResilienz), (.finanzen, .steuernSanktionen), (.finanzen, .governance): return 1.4
        case (.finanzen, .kiRegulierung): return 1.3
        case (.gesundheit, .datenschutz), (.gesundheit, .produkthaftung), (.gesundheit, .kiRegulierung): return 1.4
        case (.energie, .cyberResilienz), (.energie, .kartell), (.energie, .nachhaltigkeit): return 1.35
        case (.logistik, .nachhaltigkeit), (.logistik, .arbeitsrecht), (.logistik, .steuernSanktionen): return 1.3
        case (.bau, .arbeitsrecht), (.bau, .vertraege), (.bau, .litigation): return 1.3
        case (.medien, .lauterkeit), (.medien, .geistigesEigentum), (.medien, .datenschutz): return 1.35
        case (.dienstleistung, .arbeitsrecht), (.dienstleistung, .vertraege): return 1.2
        case (.automotive, .produkthaftung), (.automotive, .kartell), (.automotive, .nachhaltigkeit): return 1.35
        case (.chemie, .produkthaftung), (.chemie, .nachhaltigkeit), (.chemie, .litigation): return 1.35
        default: return 1.0
        }
    }
}
enum ERLand: String, Codable, CaseIterable, Identifiable {
    case de, at, ch, eu, uk, us, cn, jp, sonst
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .de: return "Deutschland"
        case .at: return "Österreich"
        case .ch: return "Schweiz"
        case .eu: return "EU (sonstige)"
        case .uk: return "Vereinigtes Königreich"
        case .us: return "USA"
        case .cn: return "China"
        case .jp: return "Japan"
        case .sonst: return "Sonstige"
        }
    }
    var inEU: Bool { [.de, .at, .eu].contains(self) }
}
enum ERSignal: String, Codable, CaseIterable, Identifiable {
    case besondereKategorien, keinDSB, drittlandTransfer, trackingOhneConsent, keinVVT, datenpanneLetzte3J
    case setztKIEin, kiHochrisiko, kiGPAI, keineKIGovernance, kiEntscheidetUeberPersonen
    case lieferketteAussereuropa, keinLieferkettenRisikomanagement, keineCSRDVorbereitung, rohstoffeEUDR, hochemissiv
    case marktfuehrer, infoaustauschWettbewerber, exklusivvertraege, kopplung, plattformGatekeeper, preisparitaetsklauseln
    case keinIPAudit, abhaengigVonFremdIP, openSourceOhneCompliance, geheimnisseOhneSchutzkonzept, patentstreitAnhaengig, schwachesPatentportfolio
    case agbVeraltet, haftungUnbegrenzt, langfristBindung, keineForceMajeure, keinVertragsmanagement, abhaengigVonEinemKunden
    case freelancerKern, keineHinweisgeberstelle, entgeltLuecke, restrukturierungGeplant, leiharbeit, keinBetriebsrat
    case physischeProdukte, softwareProdukt, vernetzteProdukte, keinRueckrufplan, sicherheitsrelevant
    case keinCMS, keineInterneRevision, keineDOVersicherung, einzelgeschaeftsfuehrung, nachfolgeOffen, liquiditaetAngespannt
    case kritischeInfrastruktur, keinISMS, finanzsektorDORA, cybervorfallLetzte24M, keinNotfallplan
    case konzernVerrechnungspreise, bargeldintensiv, geschaeftSanktionslaender, kryptoAssets, keinGwGBeauftragter
    case laufendeKlagen, b2cMassenmarkt, verfahrenImAusland, schiedsklauselnFehlen
    case aggressiveWerbung, vergleichendeWerbung, influencerMarketing, nachhaltigkeitsClaims, preisangabenOnline, kundenbewertungen
    case transaktionGeplant, auslaendischerInvestor, carveOutGeplant, subventionenDrittstaat
    var id: String { rawValue }
    var dimension: ERDimension {
        switch self {
        case .besondereKategorien, .keinDSB, .drittlandTransfer, .trackingOhneConsent, .keinVVT, .datenpanneLetzte3J: return .datenschutz
        case .setztKIEin, .kiHochrisiko, .kiGPAI, .keineKIGovernance, .kiEntscheidetUeberPersonen: return .kiRegulierung
        case .lieferketteAussereuropa, .keinLieferkettenRisikomanagement, .keineCSRDVorbereitung, .rohstoffeEUDR, .hochemissiv: return .nachhaltigkeit
        case .marktfuehrer, .infoaustauschWettbewerber, .exklusivvertraege, .kopplung, .plattformGatekeeper, .preisparitaetsklauseln: return .kartell
        case .keinIPAudit, .abhaengigVonFremdIP, .openSourceOhneCompliance, .geheimnisseOhneSchutzkonzept, .patentstreitAnhaengig, .schwachesPatentportfolio: return .geistigesEigentum
        case .agbVeraltet, .haftungUnbegrenzt, .langfristBindung, .keineForceMajeure, .keinVertragsmanagement, .abhaengigVonEinemKunden: return .vertraege
        case .freelancerKern, .keineHinweisgeberstelle, .entgeltLuecke, .restrukturierungGeplant, .leiharbeit, .keinBetriebsrat: return .arbeitsrecht
        case .physischeProdukte, .softwareProdukt, .vernetzteProdukte, .keinRueckrufplan, .sicherheitsrelevant: return .produkthaftung
        case .keinCMS, .keineInterneRevision, .keineDOVersicherung, .einzelgeschaeftsfuehrung, .nachfolgeOffen, .liquiditaetAngespannt: return .governance
        case .kritischeInfrastruktur, .keinISMS, .finanzsektorDORA, .cybervorfallLetzte24M, .keinNotfallplan: return .cyberResilienz
        case .konzernVerrechnungspreise, .bargeldintensiv, .geschaeftSanktionslaender, .kryptoAssets, .keinGwGBeauftragter: return .steuernSanktionen
        case .laufendeKlagen, .b2cMassenmarkt, .verfahrenImAusland, .schiedsklauselnFehlen: return .litigation
        case .aggressiveWerbung, .vergleichendeWerbung, .influencerMarketing, .nachhaltigkeitsClaims, .preisangabenOnline, .kundenbewertungen: return .lauterkeit
        case .transaktionGeplant, .auslaendischerInvestor, .carveOutGeplant, .subventionenDrittstaat: return .mna
        }
    }
    var titel: String {
        switch self {
        case .besondereKategorien: return "Verarbeitet Gesundheits-/Biometrie-/Finanzdaten"
        case .keinDSB: return "Kein Datenschutzbeauftragter benannt"
        case .drittlandTransfer: return "Datentransfer in Drittländer (USA, China …)"
        case .trackingOhneConsent: return "Tracking/Cookies ohne belastbare Einwilligung"
        case .keinVVT: return "Kein Verarbeitungsverzeichnis / keine TOM-Doku"
        case .datenpanneLetzte3J: return "Datenpanne oder Bußgeld in den letzten 3 Jahren"
        case .setztKIEin: return "Setzt KI-Systeme produktiv ein"
        case .kiHochrisiko: return "KI in Hochrisikobereich (HR, Kredit, Biometrie, Infrastruktur, Medizin)"
        case .kiGPAI: return "Entwickelt/vertreibt eigene KI-Modelle (GPAI/Anbieter)"
        case .keineKIGovernance: return "Keine KI-Governance / kein KI-Kompetenznachweis (Art. 4)"
        case .kiEntscheidetUeberPersonen: return "Automatisierte Entscheidungen über Personen"
        case .lieferketteAussereuropa: return "Lieferkette außerhalb Europas"
        case .keinLieferkettenRisikomanagement: return "Kein Lieferketten-Risikomanagement / Beschwerdeverfahren"
        case .keineCSRDVorbereitung: return "Keine CSRD/ESRS-Berichtsvorbereitung"
        case .rohstoffeEUDR: return "Handel mit EUDR-Rohstoffen (Holz, Soja, Kaffee, Kakao, Rind, Palmöl, Kautschuk)"
        case .hochemissiv: return "Emissionsintensiv (CBAM / ETS)"
        case .marktfuehrer: return "Marktführer oder marktstarke Stellung"
        case .infoaustauschWettbewerber: return "Informationsaustausch mit Wettbewerbern (Verband, Benchmarking)"
        case .exklusivvertraege: return "Exklusivitäts-/Alleinbezugsverträge"
        case .kopplung: return "Kopplungs- oder Bündelgeschäfte"
        case .plattformGatekeeper: return "Betreibt Plattform/Marktplatz mit Drittanbietern"
        case .preisparitaetsklauseln: return "Preisparitäts- oder Bestpreisklauseln"
        case .keinIPAudit: return "Kein IP-Audit / keine Schutzrechtsstrategie"
        case .abhaengigVonFremdIP: return "Kerntechnologie abhängig von Fremd-IP / Lizenzen"
        case .openSourceOhneCompliance: return "Open Source ohne Lizenz-Compliance (Copyleft)"
        case .geheimnisseOhneSchutzkonzept: return "Geschäftsgeheimnisse ohne angemessene Schutzmaßnahmen (§ 2 GeschGehG)"
        case .patentstreitAnhaengig: return "Patent-/Markenstreit anhängig oder angedroht"
        case .schwachesPatentportfolio: return "Schwaches/kein eigenes Schutzrechtsportfolio"
        case .agbVeraltet: return "AGB seit > 2 Jahren nicht geprüft"
        case .haftungUnbegrenzt: return "Unbegrenzte Haftung in Kernverträgen"
        case .langfristBindung: return "Langfristige Lieferanten-/Kundenbindung ohne Ausstieg"
        case .keineForceMajeure: return "Keine Force-Majeure-/Preisgleitklauseln"
        case .keinVertragsmanagement: return "Kein zentrales Vertragsmanagement (Fristen, Verlängerungen)"
        case .abhaengigVonEinemKunden: return "> 30 % Umsatz mit einem Kunden/Lieferanten"
        case .freelancerKern: return "Kernleistung durch Freelancer/Soloselbständige"
        case .keineHinweisgeberstelle: return "Keine interne Meldestelle (HinSchG ab 50 MA)"
        case .entgeltLuecke: return "Unerklärte Entgeltlücke / keine Entgelttransparenz-Vorbereitung"
        case .restrukturierungGeplant: return "Restrukturierung / Personalabbau geplant"
        case .leiharbeit: return "Erheblicher Leiharbeits-/Werkvertragseinsatz"
        case .keinBetriebsrat: return "Kein Betriebsrat (bei > 5 MA)"
        case .physischeProdukte: return "Stellt physische Produkte her / importiert"
        case .softwareProdukt: return "Vertreibt Software als Produkt (neue ProdHaftRL)"
        case .vernetzteProdukte: return "Vernetzte Produkte / IoT (CRA)"
        case .keinRueckrufplan: return "Kein Rückruf-/Krisenplan"
        case .sicherheitsrelevant: return "Sicherheitsrelevante Produkte (Medizin, Maschinen, Kinder)"
        case .keinCMS: return "Kein Compliance-Management-System"
        case .keineInterneRevision: return "Keine interne Revision / kein 4-Augen-Prinzip"
        case .keineDOVersicherung: return "Keine D&O-Versicherung"
        case .einzelgeschaeftsfuehrung: return "Einzelgeschäftsführung ohne Stellvertretung"
        case .nachfolgeOffen: return "Nachfolge / Gesellschafterstreit offen"
        case .liquiditaetAngespannt: return "Liquidität angespannt (StaRUG-Frühwarnpflicht)"
        case .kritischeInfrastruktur: return "KRITIS / NIS2-Sektor (Energie, Gesundheit, Verkehr, Digital …)"
        case .keinISMS: return "Kein ISMS (ISO 27001 / BSI-Grundschutz)"
        case .finanzsektorDORA: return "Finanzsektor oder IKT-Dienstleister dafür (DORA)"
        case .cybervorfallLetzte24M: return "Cybervorfall in den letzten 24 Monaten"
        case .keinNotfallplan: return "Kein Incident-Response-/Notfallplan"
        case .konzernVerrechnungspreise: return "Konzerninterne Leistungen / Verrechnungspreise"
        case .bargeldintensiv: return "Bargeld- oder güterhandelsintensiv (GwG-Verpflichteter)"
        case .geschaeftSanktionslaender: return "Geschäft mit Russland, Iran, Belarus, China (Dual-Use)"
        case .kryptoAssets: return "Krypto-Assets / Zahlungsdienste"
        case .keinGwGBeauftragter: return "Kein Geldwäschebeauftragter / keine KYC-Prozesse"
        case .laufendeKlagen: return "Laufende Gerichtsverfahren"
        case .b2cMassenmarkt: return "B2C-Massenmarkt (Abhilfeklage-Exposure)"
        case .verfahrenImAusland: return "Verfahren / Exposure im Ausland (US Discovery, UK)"
        case .schiedsklauselnFehlen: return "Keine Schieds-/Gerichtsstandsklauseln in Großverträgen"
        case .aggressiveWerbung: return "Aggressive Preis-/Rabattwerbung"
        case .vergleichendeWerbung: return "Vergleichende Werbung gegenüber Wettbewerbern"
        case .influencerMarketing: return "Influencer-/Social-Media-Marketing"
        case .nachhaltigkeitsClaims: return "Nachhaltigkeits-/Klimaneutral-Claims"
        case .preisangabenOnline: return "Streichpreise / Online-Preisangaben"
        case .kundenbewertungen: return "Kundenbewertungen ohne Echtheitsprüfung"
        case .transaktionGeplant: return "Übernahme / Fusion / Beteiligung geplant"
        case .auslaendischerInvestor: return "Nicht-EU-Investor beteiligt oder im Gespräch"
        case .carveOutGeplant: return "Carve-out / Umwandlung geplant"
        case .subventionenDrittstaat: return "Drittstaatliche Subventionen erhalten (FSR)"
        }
    }
    var vonAussenBeobachtbar: Bool {
        switch self {
        case .keinVVT, .keineInterneRevision, .keinNotfallplan, .keinGwGBeauftragter, .konzernVerrechnungspreise,
             .keinVertragsmanagement, .keineForceMajeure, .haftungUnbegrenzt, .keinRueckrufplan, .keineDOVersicherung,
             .liquiditaetAngespannt, .geheimnisseOhneSchutzkonzept, .keinISMS, .keineKIGovernance, .keinCMS:
            return false
        default:
            return true
        }
    }
}
struct ERUnternehmen: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var rolle: ERRolle = .eigen
    var branche: ERBranche = .software
    var sitz: ERLand = .de
    var mitarbeiter: Int = 250
    var umsatzMio: Double = 50
    var marktanteil: Double = 10
    var boersennotiert: Bool = false
    var patente: Int = 0
    var marken: Int = 1
    var signale: Set<ERSignal> = []
    var belegteFakten: String = ""
    static func leer(rolle: ERRolle) -> ERUnternehmen {
        var u = ERUnternehmen()
        u.rolle = rolle
        u.name = rolle == .eigen ? "Eigenes Unternehmen" : "Wettbewerber"
        return u
    }
    var istGross: Bool { mitarbeiter >= 250 || umsatzMio >= 50 }
    var istKMU: Bool { !istGross }
}
enum ERQuelle: String, Codable { case regel, ki, nutzer }
enum ERSchwere: String, Codable, CaseIterable, Comparable {
    case gering, mittel, hoch, kritisch
    var titel: String {
        switch self {
        case .gering: return "Gering"
        case .mittel: return "Mittel"
        case .hoch: return "Hoch"
        case .kritisch: return "Kritisch"
        }
    }
    static func aus(score: Int) -> ERSchwere {
        switch score {
        case ..<30: return .gering
        case 30..<55: return .mittel
        case 55..<78: return .hoch
        default: return .kritisch
        }
    }
    private var rang: Int { ERSchwere.allCases.firstIndex(of: self) ?? 0 }
    static func < (l: ERSchwere, r: ERSchwere) -> Bool { l.rang < r.rang }
}
struct ERBefund: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var dimension: ERDimension
    var titel: String
    var begruendung: String
    var normen: [String]
    var punkte: Int                 // Beitrag zum Dimensions-Score
    var eintrittswahrscheinlichkeit: Int // 0–100
    var schadenshoehe: Int          // 0–100 (relativ zum Unternehmen)
    var sofortmassnahme: String
    var frist: String?
    var quelle: ERQuelle = .regel
    var schwere: ERSchwere { ERSchwere.aus(score: min(100, punkte * 2)) }
}
struct ERDimensionsScore: Codable, Identifiable, Hashable {
    var dimension: ERDimension
    var score: Int                  // 0–100 gewichtet
    var rohpunkte: Int
    var befunde: [ERBefund]
    var id: String { dimension.rawValue }
    var schwere: ERSchwere { ERSchwere.aus(score: score) }
}
struct ERSchwachstelle: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var unternehmenId: String
    var unternehmenName: String
    var rolle: ERRolle
    var dimension: ERDimension
    var titel: String
    var beschreibung: String
    var ausnutzbarkeit: Int         // 0–100: Wie gut lässt sie sich (legal) in Hebel verwandeln?
    var nachweisbarkeit: Int        // 0–100: Wie belastbar ist der Nachweis von außen?
    var dringlichkeit: Int          // 0–100
    var differenzZumEigenen: Int    // Konkurrent-Score minus eigener Score (positiv = Vorteil für uns)
    var hebelIndex: Int { Int(Double(ausnutzbarkeit) * 0.5 + Double(nachweisbarkeit) * 0.3 + Double(dringlichkeit) * 0.2) }
}
enum ERVorteilTyp: String, Codable, CaseIterable {
    case offensiv, defensiv, positionierung, verhandlung
    var titel: String {
        switch self {
        case .offensiv: return "Offensiv"
        case .defensiv: return "Defensiv"
        case .positionierung: return "Positionierung"
        case .verhandlung: return "Verhandlung"
        }
    }
}
struct ERVorteil: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var typ: ERVorteilTyp
    var dimension: ERDimension
    var titel: String
    var mechanik: String            // Wie entsteht der Vorteil?
    var rechtsgrundlage: [String]   // Anspruchs-/Handlungsgrundlage
    var aktivlegitimation: String   // Wer darf handeln? (Mitbewerber, Verband, Betroffener, Behörde)
    var leitplanken: String         // Was ist verboten? (§ 4 Nr. 1/2 UWG, Kartellverbot, Verleumdung …)
    var erwarteterEffekt: Int       // 0–100
    var umsetzungsaufwand: Int      // 0–100
    var zeitfenster: String
    var basisSchwachstelleId: String?
    var quelle: ERQuelle = .regel
    var nettoHebel: Int { max(0, erwarteterEffekt - umsetzungsaufwand / 2) }
}
enum ERArchetyp: String, Codable, CaseIterable, Identifiable {
    case siegOhneKampf, unvorbereiteterGegner, festung, terrainBesetzen, allianz, timing
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .siegOhneKampf: return "Sieg ohne Kampf"
        case .unvorbereiteterGegner: return "Treffen, wo der Gegner unvorbereitet ist"
        case .festung: return "Die eigene Festung"
        case .terrainBesetzen: return "Terrain besetzen"
        case .allianz: return "Allianz & Bindung"
        case .timing: return "Der richtige Moment"
        }
    }
    var prinzip: String {
        switch self {
        case .siegOhneKampf: return "Sun Tzu III · Compliance als Marktstandard — der Wettbewerber muss folgen oder fällt zurück."
        case .unvorbereiteterGegner: return "Sun Tzu I · Rechtlich zulässige Offensive dort, wo der Wettbewerber nachweisbar exponiert ist."
        case .festung: return "Sun Tzu IV · Erst unbesiegbar werden — eigene Schwachstellen schließen, bevor sie zum Hebel des Gegners werden."
        case .terrainBesetzen: return "Sun Tzu X · Standards, Schutzrechte, Zertifikate und Verbandsarbeit als Gelände, das der Gegner nicht mehr betreten kann."
        case .allianz: return "Sun Tzu XI · Kunden, Lieferanten, Behörden und Partner vertraglich und reputativ binden — kartellrechtlich sauber."
        case .timing: return "Sun Tzu VI · Regulatorische Stichtage als Zeitfenster: früh erfüllen, früh kommunizieren, früh klagen."
        }
    }
}
struct ERZug: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var schritt: String
    var verantwortlich: String
    var frist: String
    var norm: String?
}
struct ERStrategie: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var archetyp: ERArchetyp
    var titel: String
    var ziel: String
    var zuege: [ERZug]
    var vorteilIds: [String]
    var erfolgswahrscheinlichkeit: Int   // 0–100 (Simulation)
    var erwarteterNutzen: Int            // 0–100
    var risiko: Int                      // 0–100
    var gegenreaktion: String
    var leitplanken: String
    var quelle: ERQuelle = .regel
}
struct ERSimulation: Codable, Hashable {
    var strategieId: String
    var p10: Int
    var p50: Int
    var p90: Int
    var erfolgsquote: Int
    var laeufe: Int
}
struct ERFrist: Codable, Identifiable, Hashable {
    var id: String { titel }
    var titel: String
    var datum: String
    var dimension: ERDimension
    var relevanz: String
}
struct ERKISynthese: Codable, Hashable {
    var executiveSummary: String
    var verborgeneRisiken: [String]
    var gegenzuegeDesWettbewerbers: [String]
    var prioritaeten: [String]
    var unternehmensDynamik: [String]
    var massnahmenFolgen: [String]
    var wissenschaftlicheStrategien: [String]
    var machtErhalt: [String]
    var machtWegnahmeLegal: [String]
    var modell: String
    var zeitpunkt: Date
    enum CodingKeys: String, CodingKey {
        case executiveSummary, verborgeneRisiken, gegenzuegeDesWettbewerbers, prioritaeten
        case unternehmensDynamik, massnahmenFolgen, wissenschaftlicheStrategien
        case machtErhalt, machtWegnahmeLegal, modell, zeitpunkt
    }
    init(
        executiveSummary: String,
        verborgeneRisiken: [String],
        gegenzuegeDesWettbewerbers: [String],
        prioritaeten: [String],
        unternehmensDynamik: [String] = [],
        massnahmenFolgen: [String] = [],
        wissenschaftlicheStrategien: [String] = [],
        machtErhalt: [String] = [],
        machtWegnahmeLegal: [String] = [],
        modell: String,
        zeitpunkt: Date
    ) {
        self.executiveSummary = executiveSummary
        self.verborgeneRisiken = verborgeneRisiken
        self.gegenzuegeDesWettbewerbers = gegenzuegeDesWettbewerbers
        self.prioritaeten = prioritaeten
        self.unternehmensDynamik = unternehmensDynamik
        self.massnahmenFolgen = massnahmenFolgen
        self.wissenschaftlicheStrategien = wissenschaftlicheStrategien
        self.machtErhalt = machtErhalt
        self.machtWegnahmeLegal = machtWegnahmeLegal
        self.modell = modell
        self.zeitpunkt = zeitpunkt
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        executiveSummary = try c.decode(String.self, forKey: .executiveSummary)
        verborgeneRisiken = try c.decode([String].self, forKey: .verborgeneRisiken)
        gegenzuegeDesWettbewerbers = try c.decode([String].self, forKey: .gegenzuegeDesWettbewerbers)
        prioritaeten = try c.decode([String].self, forKey: .prioritaeten)
        unternehmensDynamik = try c.decodeIfPresent([String].self, forKey: .unternehmensDynamik) ?? []
        massnahmenFolgen = try c.decodeIfPresent([String].self, forKey: .massnahmenFolgen) ?? []
        wissenschaftlicheStrategien = try c.decodeIfPresent([String].self, forKey: .wissenschaftlicheStrategien) ?? []
        machtErhalt = try c.decodeIfPresent([String].self, forKey: .machtErhalt) ?? []
        machtWegnahmeLegal = try c.decodeIfPresent([String].self, forKey: .machtWegnahmeLegal) ?? []
        modell = try c.decode(String.self, forKey: .modell)
        zeitpunkt = try c.decode(Date.self, forKey: .zeitpunkt)
    }
}
struct ERErgebnis: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var zeitpunkt: Date = .now
    var eigen: ERUnternehmen
    var wettbewerber: [ERUnternehmen]
    var eigeneScores: [ERDimensionsScore]
    var wettbewerberScores: [String: [ERDimensionsScore]]  // unternehmenId → Scores
    var gesamtscoreEigen: Int
    var eigeneSchwachstellen: [ERSchwachstelle]
    var wettbewerberSchwachstellen: [ERSchwachstelle]
    var vorteile: [ERVorteil]
    var strategien: [ERStrategie]
    var simulationen: [ERSimulation]
    var fristen: [ERFrist]
    var kiSynthese: ERKISynthese?
    var topRisiken: [ERDimensionsScore] { eigeneScores.sorted { $0.score > $1.score }.prefix(5).map { $0 } }
    var resilienzIndex: Int { max(0, 100 - gesamtscoreEigen) }
    var vorteilsIndex: Int {
        guard !vorteile.isEmpty else { return 0 }
        return min(100, vorteile.map(\.nettoHebel).reduce(0, +) / max(1, vorteile.count) + min(30, vorteile.count * 3))
    }
}
