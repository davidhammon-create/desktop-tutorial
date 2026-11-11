import SwiftUI
struct LexaraRechtsgebietFeldWerte: Codable, Equatable, Hashable {
    var untergebiet: String = ""
    var relevanteNormen: String = ""
    var schwerpunkt: String = ""
    var bemerkung: String = ""
}
struct LexaraRechtsgebietAuswahl: Equatable {
    var gewaehlteIds: Set<String> = []
    var primaerId: String?
    var felder: [String: LexaraRechtsgebietFeldWerte] = [:]
    var istLeer: Bool { gewaehlteIds.isEmpty }
    var primaeresLabel: String? {
        guard let id = primaerId ?? gewaehlteIds.first else { return nil }
        return LexaraRechtsgebietKatalog.label(fuer: id)
    }
    var alleLabels: [String] {
        gewaehlteIds.map { LexaraRechtsgebietKatalog.label(fuer: $0) }.sorted()
    }
    var zusammenfassung: String {
        alleLabels.joined(separator: " · ")
    }
}
struct LexaraRechtsgebietEintrag: Identifiable, Hashable {
    let id: String
    let label: String
    let icon: String
    let untergebiete: [String]
    let normenHinweis: String?
}
struct LexaraRechtsgebietKategorie: Identifiable {
    let id: String
    let titel: String
    let icon: String
    let accent: Color
    let gebiete: [LexaraRechtsgebietEintrag]
}
enum LexaraRechtsgebietKatalog {
    static let speicherKey = "rechtsgebiete_meta"
    static let kategorien: [LexaraRechtsgebietKategorie] = [
        LexaraRechtsgebietKategorie(
            id: "zivil",
            titel: "Zivilrecht",
            icon: "doc.text",
            accent: AppleUIKitTokens.systemBlue,
            gebiete: [
                .init(id: "vertragsrecht_bgb", label: "Vertragsrecht (BGB)", icon: "signature", untergebiete: ["Kaufrecht", "Werkvertrag", "Dienstvertrag", "AGB-Recht"], normenHinweis: "BGB §§ 433 ff."),
                .init(id: "mietrecht", label: "Miet- & WEG-Recht", icon: "house", untergebiete: ["Wohnraummiete", "Gewerberaummiete", "WEG / Teilungserklärung"], normenHinweis: "BGB §§ 535 ff., WEG"),
                .init(id: "familienrecht", label: "Familienrecht", icon: "person.2", untergebiete: ["Scheidung", "Unterhalt", "Sorge / Umgang", "Zugewinn"], normenHinweis: "BGB Familienrecht"),
                .init(id: "erbrecht", label: "Erbrecht", icon: "scroll", untergebiete: ["Testament", "Erbfolge", "Pflichtteil", "Erbauseinandersetzung"], normenHinweis: "BGB Erbrecht"),
                .init(id: "deliktsrecht", label: "Delikts- & Sachenrecht", icon: "exclamationmark.shield", untergebiete: ["Schadensersatz", "Eigentum / Besitz", "Unterlassung"], normenHinweis: "BGB §§ 823 ff.")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "arbeit",
            titel: "Arbeits- & Sozialrecht",
            icon: "person.badge.clock",
            accent: AppleUIKitTokens.systemGreen,
            gebiete: [
                .init(id: "arbeitsrecht", label: "Arbeitsrecht", icon: "briefcase", untergebiete: ["Kündigungsschutz", "Abmahnung", "Zeugnis", "Transfer/TUP"], normenHinweis: "KSchG, BGB AT"),
                .init(id: "tarifrecht", label: "Tarif- & Betriebsverfassung", icon: "person.3", untergebiete: ["Tarifvertrag", "Betriebsrat", "Mitbestimmung"], normenHinweis: "BetrVG, TVG"),
                .init(id: "sozialrecht", label: "Sozialrecht", icon: "heart.text.square", untergebiete: ["Rente", "Krankenversicherung", "Arbeitslosengeld"], normenHinweis: "SGB I–XII")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "wirtschaft",
            titel: "Wirtschaft & Gesellschaft",
            icon: "building.2",
            accent: Color.orange,
            gebiete: [
                .init(id: "gesellschaftsrecht", label: "Gesellschaftsrecht", icon: "building.columns", untergebiete: ["GmbH", "AG", "Geschäftsführerhaftung", "Gesellschafterstreit"], normenHinweis: "GmbHG, AktG"),
                .init(id: "handelsrecht", label: "Handels- & Gesellschaftsrecht", icon: "cart", untergebiete: ["Handelsgeschäfte", "Prokura", "Konkursnahe Zahlungen"], normenHinweis: "HGB"),
                .init(id: "insolvenzrecht", label: "Insolvenzrecht", icon: "chart.line.downtrend.xyaxis", untergebiete: ["Regelinsolvenz", "Eigenverwaltung", "Anfechtung"], normenHinweis: "InsO"),
                .init(id: "kartellrecht", label: "Kartell- & Wettbewerbsrecht", icon: "arrow.triangle.branch", untergebiete: ["GWB", "Fusionskontrolle", "Missbrauch marktbeherrschende Stellung"], normenHinweis: "GWG, GWB"),
                .init(id: "compliance_owig", label: "Compliance / OWiG", icon: "checkmark.shield", untergebiete: ["Bußgeldverfahren", "Internal Investigation"], normenHinweis: "OWiG")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "immobilien",
            titel: "Immobilien & Baurecht",
            icon: "building",
            accent: Color(red: 0.55, green: 0.72, blue: 0.95),
            gebiete: [
                .init(id: "baurecht", label: "Baurecht", icon: "hammer", untergebiete: ["Baugenehmigung", "VOB/B", "Architektenvertrag"], normenHinweis: "BauGB, HOAI"),
                .init(id: "planungsrecht", label: "Planungs- & Immobilienrecht", icon: "map", untergebiete: ["Bebauungsplan", "Nachbarschaftsrecht", "Grunddienstbarkeit"], normenHinweis: "BauGB, BGB")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "straf",
            titel: "Straf- & Ordnungsrecht",
            icon: "scalemass",
            accent: AppleUIKitTokens.systemRed,
            gebiete: [
                .init(id: "strafrecht", label: "Strafrecht", icon: "hand.raised", untergebiete: ["Allgemeines Strafrecht", "Betrug", "Körperverletzung"], normenHinweis: "StGB"),
                .init(id: "wirtschaftsstrafrecht", label: "Wirtschaftsstrafrecht", icon: "briefcase.fill", untergebiete: ["Steuerhinterziehung", "Insolvenzdelikte", "Korruption"], normenHinweis: "StGB, StPO"),
                .init(id: "ordnungswidrigkeiten", label: "Ordnungswidrigkeiten", icon: "exclamationmark.triangle", untergebiete: ["Bußgeld", "Verwarnungsgeld"], normenHinweis: "OWiG")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "oeffentlich",
            titel: "Öffentliches Recht",
            icon: "building.columns.fill",
            accent: Color.purple,
            gebiete: [
                .init(id: "verwaltungsrecht", label: "Verwaltungsrecht", icon: "doc.badge.gearshape", untergebiete: ["Baugenehmigung", "Subvention", "Disziplinar"], normenHinweis: "VwVfG, VwGO"),
                .init(id: "vergaberecht", label: "Vergaberecht", icon: "list.bullet.rectangle", untergebiete: ["EU-Vergabe", "Nachprüfungsverfahren"], normenHinweis: "GWB, VgV"),
                .init(id: "umweltrecht", label: "Umweltrecht", icon: "leaf", untergebiete: ["Immissionsschutz", "Naturschutz", "Wasserrecht"], normenHinweis: "BImSchG, WHG")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "ip_it",
            titel: "IP, Medien & IT",
            icon: "cpu",
            accent: Color.cyan,
            gebiete: [
                .init(id: "patentrecht", label: "Patentrecht", icon: "lightbulb", untergebiete: ["Patentverletzung", "Lizenz", "EPÜ"], normenHinweis: "PatG"),
                .init(id: "urheberrecht", label: "Urheberrecht", icon: "paintbrush", untergebiete: ["Lizenz", "Filesharing", "Werkvertrag"], normenHinweis: "UrhG"),
                .init(id: "markenrecht", label: "Markenrecht", icon: "tag", untergebiete: ["Markenverletzung", "Unlauterer Wettbewerb"], normenHinweis: "MarkenG, UWG"),
                .init(id: "datenschutz", label: "Datenschutz (DSGVO)", icon: "lock.shield", untergebiete: ["DSGVO-Audit", "Datenpanne", "Auftragsverarbeitung"], normenHinweis: "DSGVO, BDSG"),
                .init(id: "medizinrecht", label: "Medizinrecht", icon: "cross.case", untergebiete: ["Arzthaftung", "Behandlungsfehler", "Approbation"], normenHinweis: "BGB, HeilM-RL")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "steuer_finanz",
            titel: "Steuer & Finanzen",
            icon: "eurosign.circle",
            accent: Color.yellow,
            gebiete: [
                .init(id: "steuerrecht", label: "Steuerrecht", icon: "percent", untergebiete: ["Einkommensteuer", "Umsatzsteuer", "Erbschaftsteuer"], normenHinweis: "AO, EStG"),
                .init(id: "bank_kapitalmarkt", label: "Bank- & Kapitalmarktrecht", icon: "chart.bar", untergebiete: ["WpHG", "KWG", "Prospekthaftung"], normenHinweis: "WpHG, KWG")
            ]
        ),
        LexaraRechtsgebietKategorie(
            id: "international",
            titel: "International & EU",
            icon: "globe.europe.africa",
            accent: Color.indigo,
            gebiete: [
                .init(id: "europarecht", label: "Europarecht", icon: "flag", untergebiete: ["Grundfreiheiten", "Beihilferecht", "EuGH-Verfahren"], normenHinweis: "AEUV, EuGH"),
                .init(id: "internationales_privatrecht", label: "Internationales Privatrecht", icon: "airplane", untergebiete: ["Gerichtsstand", "Anwendbares Recht", "Anerkennung"], normenHinweis: "Brüssel Ia, Rom I/II")
            ]
        )
    ]
    static var alleGebiete: [LexaraRechtsgebietEintrag] {
        kategorien.flatMap(\.gebiete)
    }
    static func eintrag(fuer id: String) -> LexaraRechtsgebietEintrag? {
        alleGebiete.first { $0.id == id }
    }
    static func label(fuer id: String) -> String {
        eintrag(fuer: id)?.label ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }
    static func kategorie(fuer gebietId: String) -> LexaraRechtsgebietKategorie? {
        kategorien.first { kat in kat.gebiete.contains { $0.id == gebietId } }
    }
    private static let legacyLabelZuId: [String: String] = [
        "Arbeitsrecht": "arbeitsrecht",
        "Mietrecht": "mietrecht",
        "Vertragsrecht": "vertragsrecht_bgb",
        "Familienrecht": "familienrecht",
        "Gesellschaftsrecht": "gesellschaftsrecht",
        "Strafrecht": "strafrecht",
        "Verwaltungsrecht": "verwaltungsrecht",
        "Insolvenzrecht": "insolvenzrecht",
        "IP": "markenrecht",
        "Steuerrecht": "steuerrecht",
        "Baurecht": "baurecht",
        "Medizinrecht": "medizinrecht",
        "Handelsrecht": "handelsrecht",
        "Erbrecht": "erbrecht"
    ]
    static func id(fuerLabel label: String) -> String? {
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        if let id = legacyLabelZuId[trimmed] { return id }
        if let exakt = alleGebiete.first(where: { $0.label == trimmed })?.id { return exakt }
        if let teil = alleGebiete.first(where: { $0.label.localizedCaseInsensitiveContains(trimmed) })?.id { return teil }
        return nil
    }
}
extension LegalCase {
    func rechtsgebietAuswahl() -> LexaraRechtsgebietAuswahl {
        if let meta = ki_berater_result?.dictValue?[LexaraRechtsgebietKatalog.speicherKey] as? [String: Any] {
            return Self.decodeAuswahl(meta)
        }
        if let rg = rechtsgebiet, !rg.isEmpty {
            var auswahl = LexaraRechtsgebietAuswahl()
            for teil in rg.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
                if let id = LexaraRechtsgebietKatalog.id(fuerLabel: teil) {
                    auswahl.gewaehlteIds.insert(id)
                }
            }
            if auswahl.primaerId == nil { auswahl.primaerId = auswahl.gewaehlteIds.first }
            return auswahl
        }
        return LexaraRechtsgebietAuswahl()
    }
    mutating func applyRechtsgebietAuswahl(_ auswahl: LexaraRechtsgebietAuswahl) {
        var a = auswahl
        if let primaer = a.primaerId, !a.gewaehlteIds.contains(primaer) {
            a.primaerId = a.gewaehlteIds.first
        }
        for id in a.felder.keys where !a.gewaehlteIds.contains(id) {
            a.felder.removeValue(forKey: id)
        }
        for id in a.gewaehlteIds {
            var f = a.felder[id] ?? LexaraRechtsgebietFeldWerte()
            f.untergebiet = String(f.untergebiet.prefix(200))
            f.relevanteNormen = String(f.relevanteNormen.prefix(500))
            f.schwerpunkt = String(f.schwerpunkt.prefix(300))
            f.bemerkung = String(f.bemerkung.prefix(1000))
            a.felder[id] = f
        }
        rechtsgebiet = a.istLeer ? nil : (a.primaeresLabel ?? a.zusammenfassung)
        var ki = ki_berater_result?.dictValue ?? [:]
        ki[LexaraRechtsgebietKatalog.speicherKey] = Self.encodeAuswahl(a)
        ki_berater_result = AnyCodable(ki)
    }
    private static func encodeAuswahl(_ a: LexaraRechtsgebietAuswahl) -> [String: Any] {
        var felder: [String: Any] = [:]
        for (id, f) in a.felder {
            felder[id] = [
                "untergebiet": f.untergebiet,
                "relevante_normen": f.relevanteNormen,
                "schwerpunkt": f.schwerpunkt,
                "bemerkung": f.bemerkung
            ]
        }
        return [
            "ids": Array(a.gewaehlteIds),
            "primaer_id": a.primaerId as Any,
            "felder": felder
        ]
    }
    private static func decodeAuswahl(_ meta: [String: Any]) -> LexaraRechtsgebietAuswahl {
        var a = LexaraRechtsgebietAuswahl()
        if let ids = meta["ids"] as? [String] { a.gewaehlteIds = Set(ids) }
        if let primaer = meta["primaer_id"] as? String, a.gewaehlteIds.contains(primaer) {
            a.primaerId = primaer
        } else {
            a.primaerId = a.gewaehlteIds.first
        }
        if let rawFelder = meta["felder"] as? [String: Any] {
            for (id, val) in rawFelder {
                guard let dict = val as? [String: Any] else { continue }
                a.felder[id] = LexaraRechtsgebietFeldWerte(
                    untergebiet: dict["untergebiet"] as? String ?? "",
                    relevanteNormen: dict["relevante_normen"] as? String ?? "",
                    schwerpunkt: dict["schwerpunkt"] as? String ?? "",
                    bemerkung: dict["bemerkung"] as? String ?? ""
                )
            }
        }
        return a
    }
}
