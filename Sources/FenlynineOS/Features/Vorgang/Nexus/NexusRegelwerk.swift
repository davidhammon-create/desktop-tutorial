import Foundation
struct NexusMerkmalVorlage: Identifiable {
    var id: String
    var text: String
    var beweislast: NexusBeweislast
    var vermutung: Bool = false
    var fundstelle: String? = nil
}
struct NexusAnspruchVorlage: Identifiable {
    var id: String
    var norm: String
    var ziel: String
    var verknuepfung: String
    var rechtsgebiet: String = "BGB"
    var merkmale: [NexusMerkmalVorlage]
    var einreden: [String] = []
    var kurz: String { "\(norm) — \(ziel)" }
    func skelett(optionId: UUID, vorgangId: UUID) -> NexusGraph {
        NexusRegelwerk.skelett(vorlage: self, optionId: optionId, vorgangId: vorgangId)
    }
}
enum NexusRegelwerk {
    static let alle: [NexusAnspruchVorlage] = [
        bgb280, bgb437, bgb433, bgb535, bgb488, bgb626, bgb812, bgb985, bgb1004, bgb823,
        kschg, hgb377, gmbh43, uwg8, dsgvo82, marken14, stgbPruefung
    ]
    static let bgb280 = NexusAnspruchVorlage(
        id: "bgb_280_281",
        norm: "§§ 280 I, III, 281 I BGB",
        ziel: "Schadensersatz statt der Leistung",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Schuldrecht",
        merkmale: [
            .init(id: "m1", text: "Schuldverhältnis", beweislast: .glaeubiger),
            .init(id: "m2", text: "Pflichtverletzung", beweislast: .glaeubiger),
            .init(id: "m3", text: "Fristsetzung erfolglos", beweislast: .glaeubiger),
            .init(id: "m4", text: "Vertretenmüssen", beweislast: .schuldner, vermutung: true, fundstelle: "§ 280 I 2 BGB"),
            .init(id: "m5", text: "Schaden (Differenzhypothese)", beweislast: .glaeubiger)
        ],
        einreden: ["Gesamtnichtigkeit § 139", "Mitverschulden § 254", "Verjährung § 195", "Mitwirkung unterblieben"]
    )
    static let bgb437 = NexusAnspruchVorlage(
        id: "bgb_437",
        norm: "§§ 437, 434, 280, 281 BGB",
        ziel: "Mängelrechte des Käufers",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Kauf",
        merkmale: [
            .init(id: "m1", text: "Kaufvertrag", beweislast: .glaeubiger),
            .init(id: "m2", text: "Mangel bei Gefahrübergang", beweislast: .glaeubiger),
            .init(id: "m3", text: "Keine Kenntnis / kein Ausschluss", beweislast: .glaeubiger),
            .init(id: "m4", text: "Nacherfüllung fehlgeschlagen oder entbehrlich", beweislast: .glaeubiger),
            .init(id: "m5", text: "Gewähltes Recht (Minderung / Schadensersatz / Rücktritt)", beweislast: .glaeubiger)
        ],
        einreden: ["Rüge verspätet", "Beschaffenheitsausschluss", "Verjährung § 438", "Arglist des Käufers"]
    )
    static let bgb433 = NexusAnspruchVorlage(
        id: "bgb_433",
        norm: "§ 433 II BGB",
        ziel: "Kaufpreisanspruch",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Kauf",
        merkmale: [
            .init(id: "m1", text: "Kaufvertrag geschlossen", beweislast: .glaeubiger),
            .init(id: "m2", text: "Fälligkeit des Kaufpreises", beweislast: .glaeubiger),
            .init(id: "m3", text: "Keine Einrede des nicht erfüllten Vertrags", beweislast: .schuldner)
        ],
        einreden: ["Anfechtung", "Rücktritt", "Aufrechnung", "Stundung"]
    )
    static let bgb535 = NexusAnspruchVorlage(
        id: "bgb_535",
        norm: "§§ 535, 543, 546 BGB",
        ziel: "Miete — Räumung / Mietzins / Mangel",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Miete",
        merkmale: [
            .init(id: "m1", text: "Mietvertrag", beweislast: .glaeubiger),
            .init(id: "m2", text: "Überlassung / Rückgabe fällig", beweislast: .glaeubiger),
            .init(id: "m3", text: "Kündigung wirksam oder Mietverhältnis beendet", beweislast: .glaeubiger),
            .init(id: "m4", text: "Keine entgegenstehende Einrede (Minderung, Zurückbehalt)", beweislast: .schuldner)
        ],
        einreden: ["Schönheitsreparaturen unwirksam", "Mietminderung § 536", "Kündigungsschutz", "Schriftform § 550"]
    )
    static let bgb488 = NexusAnspruchVorlage(
        id: "bgb_488",
        norm: "§ 488 I BGB",
        ziel: "Darlehensrückzahlung",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Darlehen",
        merkmale: [
            .init(id: "m1", text: "Darlehensvertrag", beweislast: .glaeubiger),
            .init(id: "m2", text: "Auszahlung der Valuta", beweislast: .glaeubiger),
            .init(id: "m3", text: "Fälligkeit (Zeitablauf / Kündigung)", beweislast: .glaeubiger)
        ],
        einreden: ["Widerruf Verbraucherdarlehen", "Sittenwidrigkeit Zins", "Aufrechnung", "Verjährung"]
    )
    static let bgb626 = NexusAnspruchVorlage(
        id: "bgb_626",
        norm: "§ 626 BGB",
        ziel: "Außerordentliche Kündigung aus wichtigem Grund",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Dauerschuld",
        merkmale: [
            .init(id: "m1", text: "Dauerschuldverhältnis", beweislast: .glaeubiger),
            .init(id: "m2", text: "Wichtiger Grund", beweislast: .glaeubiger),
            .init(id: "m3", text: "Unzumutbarkeit der Fortsetzung", beweislast: .glaeubiger),
            .init(id: "m4", text: "Kündigungserklärungsfrist zwei Wochen", beweislast: .glaeubiger, fundstelle: "§ 626 II BGB")
        ],
        einreden: ["Abmahnung entbehrlich?", "Frist versäumt", "Interessenabwägung", "Verdachtskündigung ohne Anhörung"]
    )
    static let bgb812 = NexusAnspruchVorlage(
        id: "bgb_812",
        norm: "§ 812 I 1 Alt. 1 BGB",
        ziel: "Leistungskondiktion",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Bereicherung",
        merkmale: [
            .init(id: "m1", text: "Etwas erlangt", beweislast: .glaeubiger),
            .init(id: "m2", text: "Durch Leistung des Gläubigers", beweislast: .glaeubiger),
            .init(id: "m3", text: "Ohne rechtlichen Grund", beweislast: .glaeubiger)
        ],
        einreden: ["Entreicherung § 818 III", "Kondiktionssperre § 814", "§ 817 S. 2", "Unmöglichkeitsrechtlicher Vorrang"]
    )
    static let bgb985 = NexusAnspruchVorlage(
        id: "bgb_985",
        norm: "§ 985 BGB",
        ziel: "Herausgabe (Vindikation)",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Sachenrecht",
        merkmale: [
            .init(id: "m1", text: "Eigentum des Klägers", beweislast: .glaeubiger),
            .init(id: "m2", text: "Besitz des Beklagten", beweislast: .glaeubiger),
            .init(id: "m3", text: "Kein Recht zum Besitz § 986", beweislast: .schuldner)
        ],
        einreden: ["Gutgläubiger Erwerb", "Ersitzung", "Pfandrecht / Zurückbehalt", "Einigung und Übergabe streitig"]
    )
    static let bgb1004 = NexusAnspruchVorlage(
        id: "bgb_1004",
        norm: "§ 1004 BGB",
        ziel: "Beseitigung / Unterlassung",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Sachenrecht",
        merkmale: [
            .init(id: "m1", text: "Eigentum oder sonstiges absolutes Recht", beweislast: .glaeubiger),
            .init(id: "m2", text: "Beeinträchtigung nicht in Entziehung des Besitzes", beweislast: .glaeubiger),
            .init(id: "m3", text: "Störer (Handlungs- oder Zustandsstörer)", beweislast: .glaeubiger),
            .init(id: "m4", text: "Wiederholungs- oder Erstbegehungsgefahr", beweislast: .glaeubiger)
        ],
        einreden: ["Duldungspflicht", "Verjährung", "Mitstörer", "Öffentlich-rechtlicher Vorrang"]
    )
    static let bgb823 = NexusAnspruchVorlage(
        id: "bgb_823_1",
        norm: "§ 823 I BGB",
        ziel: "Schadensersatz aus unerlaubter Handlung",
        verknuepfung: "UND",
        rechtsgebiet: "BGB · Delikt",
        merkmale: [
            .init(id: "m1", text: "Rechtsgutverletzung", beweislast: .glaeubiger),
            .init(id: "m2", text: "Handlung", beweislast: .glaeubiger),
            .init(id: "m3", text: "Haftungsbegründende Kausalität", beweislast: .glaeubiger),
            .init(id: "m4", text: "Rechtswidrigkeit", beweislast: .glaeubiger),
            .init(id: "m5", text: "Verschulden", beweislast: .glaeubiger),
            .init(id: "m6", text: "Schaden", beweislast: .glaeubiger)
        ],
        einreden: ["Mitverschulden", "Rechtfertigungsgrund", "Verjährung § 199", "Schutzzweck der Norm"]
    )
    static let kschg = NexusAnspruchVorlage(
        id: "kschg_4",
        norm: "§ 4 KSchG / § 1 KSchG",
        ziel: "Feststellung der Unwirksamkeit der Kündigung",
        verknuepfung: "UND",
        rechtsgebiet: "Arbeitsrecht",
        merkmale: [
            .init(id: "m1", text: "Anwendbarkeit KSchG", beweislast: .glaeubiger),
            .init(id: "m2", text: "Kündigungserklärung zugegangen", beweislast: .glaeubiger),
            .init(id: "m3", text: "Klagefrist drei Wochen", beweislast: .glaeubiger, fundstelle: "§ 4 S. 1 KSchG"),
            .init(id: "m4", text: "Soziale Rechtfertigung fehlt", beweislast: .schuldner, vermutung: false, fundstelle: "§ 1 KSchG")
        ],
        einreden: ["Kleinbetrieb", "Warteeit sechs Monate", "Betriebsratsanhörung", "Verdachtskündigung"]
    )
    static let hgb377 = NexusAnspruchVorlage(
        id: "hgb_377",
        norm: "§ 377 HGB",
        ziel: "Rügeobliegenheit — Erhalt der Mängelrechte",
        verknuepfung: "UND",
        rechtsgebiet: "Handelsrecht",
        merkmale: [
            .init(id: "m1", text: "Beiderseitiges Handelsgeschäft", beweislast: .glaeubiger),
            .init(id: "m2", text: "Kauf / Werklieferung", beweislast: .glaeubiger),
            .init(id: "m3", text: "Untersuchung nach Ablieferung", beweislast: .glaeubiger),
            .init(id: "m4", text: "Unverzügliche Rüge — oder versteckter Mangel", beweislast: .glaeubiger)
        ],
        einreden: ["Arglist des Verkäufers", "Kein Handelskauf", "Rüge zu spät — Genehmigung", "Teilrüge"]
    )
    static let gmbh43 = NexusAnspruchVorlage(
        id: "gmbh_43",
        norm: "§ 43 GmbHG",
        ziel: "Geschäftsführerhaftung gegenüber der Gesellschaft",
        verknuepfung: "UND",
        rechtsgebiet: "Gesellschaftsrecht",
        merkmale: [
            .init(id: "m1", text: "Organstellung Geschäftsführer", beweislast: .glaeubiger),
            .init(id: "m2", text: "Pflichtverletzung (Sorgfalt ordentlicher Geschäftsmann)", beweislast: .glaeubiger),
            .init(id: "m3", text: "Verschulden", beweislast: .schuldner, vermutung: true),
            .init(id: "m4", text: "Kausalität und Schaden der Gesellschaft", beweislast: .glaeubiger)
        ],
        einreden: ["Business Judgment Rule", "Weisung der Gesellschafter", "Verzicht / Vergleich § 43 III", "Verjährung fünf Jahre"]
    )
    static let uwg8 = NexusAnspruchVorlage(
        id: "uwg_8_9",
        norm: "§§ 8, 9, 3 UWG",
        ziel: "Unterlassung / Schadensersatz unlauteren Wettbewerbs",
        verknuepfung: "UND",
        rechtsgebiet: "Wettbewerb",
        merkmale: [
            .init(id: "m1", text: "Geschäftliche Handlung", beweislast: .glaeubiger),
            .init(id: "m2", text: "Unlauterkeit (§ 3 / Katalog)", beweislast: .glaeubiger),
            .init(id: "m3", text: "Aktivlegitimation (§ 8 III)", beweislast: .glaeubiger),
            .init(id: "m4", text: "Wiederholungsgefahr", beweislast: .glaeubiger)
        ],
        einreden: ["Bagatelle", "Presseprivileg", "Verjährung sechs Monate", "Rechtsmissbrauch § 8c"]
    )
    static let dsgvo82 = NexusAnspruchVorlage(
        id: "dsgvo_82",
        norm: "Art. 82 DSGVO",
        ziel: "Schadensersatz wegen Datenschutzverstoß",
        verknuepfung: "UND",
        rechtsgebiet: "Datenschutz",
        merkmale: [
            .init(id: "m1", text: "Verstoß gegen die DSGVO", beweislast: .glaeubiger),
            .init(id: "m2", text: "Verantwortlicher oder Auftragsverarbeiter", beweislast: .glaeubiger),
            .init(id: "m3", text: "Immaterieller oder materieller Schaden", beweislast: .glaeubiger),
            .init(id: "m4", text: "Kausalität", beweislast: .glaeubiger)
        ],
        einreden: ["Exkulpation Art. 82 III", "Mitverschulden", "Bagatelle / Erheblichkeit", "Verjährung"]
    )
    static let marken14 = NexusAnspruchVorlage(
        id: "marken_14",
        norm: "§ 14 MarkenG",
        ziel: "Unterlassung / Schadensersatz Markenverletzung",
        verknuepfung: "UND",
        rechtsgebiet: "IP",
        merkmale: [
            .init(id: "m1", text: "Schutzrecht (Marke / bekannte Marke)", beweislast: .glaeubiger),
            .init(id: "m2", text: "Benutzung in identischen / ähnlichen Waren", beweislast: .glaeubiger),
            .init(id: "m3", text: "Verwechslungsgefahr oder Rufausbeutung", beweislast: .glaeubiger),
            .init(id: "m4", text: "Keine Erschöpfung / keine beschreibende Benutzung", beweislast: .schuldner)
        ],
        einreden: ["Nichtbenutzung", "Verjährung", "Freihaltebedürfnis", "Zustimmung"]
    )
    static let stgbPruefung = NexusAnspruchVorlage(
        id: "stgb_pruefung",
        norm: "StGB — Tatbestand · Rechtswidrigkeit · Schuld",
        ziel: "Strafrechtliche Vorprüfung (nicht Anklage)",
        verknuepfung: "UND",
        rechtsgebiet: "Strafrecht",
        merkmale: [
            .init(id: "m1", text: "Objektiver Tatbestand", beweislast: .glaeubiger),
            .init(id: "m2", text: "Subjektiver Tatbestand", beweislast: .glaeubiger),
            .init(id: "m3", text: "Rechtswidrigkeit (keine Rechtfertigung)", beweislast: .glaeubiger),
            .init(id: "m4", text: "Schuld (keine Entschuldigung)", beweislast: .glaeubiger)
        ],
        einreden: ["Notwehr / Notstand", "Verbotsirrtum", "Schuldunfähigkeit", "Verjährung der Tat"]
    )
    static func skelett(vorlage: NexusAnspruchVorlage, optionId: UUID, vorgangId: UUID) -> NexusGraph {
        var g = NexusGraph(optionId: optionId, vorgangId: vorgangId)
        let wurzel = NexusKnoten(
            typ: .norm,
            kern: NexusAnzeige.zwoelfWoerter("\(vorlage.norm) — \(vorlage.ziel)"),
            volltext: vorlage.norm,
            qRang: .gesetz,
            passgenauigkeit: 1,
            nachweis: .urkundeUnstreitig,
            status: .belegt
        )
        g.knoten.append(wurzel)
        for m in vorlage.merkmale {
            let k = NexusKnoten(
                parentId: wurzel.id,
                typ: .merkmal,
                kern: NexusAnzeige.zwoelfWoerter(m.text),
                volltext: m.fundstelle ?? m.text,
                qRang: .gesetz,
                passgenauigkeit: 1,
                nachweis: .behauptung,
                status: .belegt,
                beweislast: m.beweislast,
                vermutung: m.vermutung
            )
            g.knoten.append(k)
            g.kanten.append(.init(von: k.id, nach: wurzel.id, typ: .stuetzt))
        }
        NexusPropagation.auswerten(&g)
        return g
    }
}
