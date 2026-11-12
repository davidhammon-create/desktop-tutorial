import Foundation
import SwiftUI
enum Rechtsordnung: String, CaseIterable, Identifiable, Codable {
    case de, ch, no, jp, cn
    var id: String { rawValue }
    var name: String {
        switch self {
        case .de: return "Deutschland"
        case .ch: return "Schweiz"
        case .no: return "Norwegen"
        case .jp: return "Japan"
        case .cn: return "China"
        }
    }
    var flagge: String {
        switch self {
        case .de: return "🇩🇪"
        case .ch: return "🇨🇭"
        case .no: return "🇳🇴"
        case .jp: return "🇯🇵"
        case .cn: return "🇨🇳"
        }
    }
    var rechtstradition: String {
        switch self {
        case .de: return "Civil Law (germanisch) — BGB/ZPO"
        case .ch: return "Civil Law — OR/ZGB, kantonale Vielfalt"
        case .no: return "Skandinavisches Civil Law — pragmatisch, Schlichtung zuerst"
        case .jp: return "Civil Law (dt./frz. geprägt) — 民法, konsensorientiert"
        case .cn: return "Sozialistisches Recht — 民法典 (2021), staatlich gelenkt"
        }
    }
    var gerichtsaufbau: [String] {
        switch self {
        case .de: return ["Amtsgericht / Landgericht", "Oberlandesgericht", "Bundesgerichtshof (BGH)"]
        case .ch: return ["Bezirks-/Kantonsgericht", "Obergericht (Kanton)", "Bundesgericht (Lausanne)"]
        case .no: return ["Forliksråd (Schlichtung)", "Tingrett", "Lagmannsrett", "Høyesterett"]
        case .jp: return ["簡易/地方裁判所 (Chihō)", "高等裁判所 (Kōtō)", "最高裁判所 (Saikō)"]
        case .cn: return ["基層人民法院", "中級/高級人民法院", "最高人民法院 (SPC)"]
        }
    }
    var amtlicheQuellen: [String] {
        switch self {
        case .de: return ["gesetze-im-internet.de", "rechtsprechung-im-internet.de", "BGH/BVerfG"]
        case .ch: return ["fedlex.admin.ch", "bger.ch (Bundesgericht)", "entscheidsuche.ch"]
        case .no: return ["lovdata.no", "domstol.no", "Norges Høyesterett"]
        case .jp: return ["e-gov.go.jp (法令検索)", "courts.go.jp (裁判例)", "法務省"]
        case .cn: return ["npc.gov.cn (法律法规)", "court.gov.cn", "pkulaw / 北大法宝"]
        }
    }
    var kiSprachHinweis: String {
        switch self {
        case .de: return "Deutsches Recht: zitiere Normen als § + Gesetz (z. B. § 626 BGB)."
        case .ch: return "Schweizer Recht: zitiere Art. + Gesetz (z. B. Art. 336 OR); kantonale Zuständigkeiten beachten."
        case .no: return "Norwegisches Recht: zitiere Gesetz + § (z. B. arbeidsmiljøloven § 15-7); Forliksråd-Pflicht beachten."
        case .jp: return "Japanisches Recht: zitiere 法令 + 条 (z. B. 民法709条); Namen in Original + Umschrift."
        case .cn: return "Chinesisches Recht: zitiere 法律 + 条 (z. B. 民法典188条); SPC-Justizauslegungen (司法解释) einbeziehen."
        }
    }
    struct FristPaket {
        let titel: String
        let norm: String
        let beschreibung: String
        let tage: Int?
    }
    var fristenPakete: [FristPaket] {
        switch self {
        case .de: return [
            .init(titel: "Kündigungsschutzklage", norm: "§ 4 KSchG", beschreibung: "3 Wochen ab Zugang der Kündigung.", tage: 21),
            .init(titel: "Regelverjährung", norm: "§ 195 BGB", beschreibung: "3 Jahre ab Ende des Entstehungsjahres.", tage: 1095),
            .init(titel: "Berufung", norm: "§ 517 ZPO", beschreibung: "1 Monat ab Zustellung des Urteils.", tage: 30),
            .init(titel: "Mängelrüge Handelskauf", norm: "§ 377 HGB", beschreibung: "Unverzüglich nach Ablieferung.", tage: 3)
        ]
        case .ch: return [
            .init(titel: "Anfechtung Kündigung", norm: "Art. 336b OR", beschreibung: "Einsprache bis Ende Kündigungsfrist; Klage 180 Tage nach Vertragsende.", tage: 180),
            .init(titel: "Verjährung Forderungen", norm: "Art. 127 OR", beschreibung: "10 Jahre (Grundsatz), 5 Jahre für periodische Leistungen (Art. 128).", tage: 3650),
            .init(titel: "Berufung ZPO", norm: "Art. 311 ZPO-CH", beschreibung: "30 Tage ab Eröffnung des Entscheids.", tage: 30),
            .init(titel: "Betreibungsrechtlicher Rechtsvorschlag", norm: "Art. 74 SchKG", beschreibung: "10 Tage nach Zustellung des Zahlungsbefehls.", tage: 10)
        ]
        case .no: return [
            .init(titel: "Søksmål etter oppsigelse", norm: "arbeidsmiljøloven § 17-4", beschreibung: "8 Wochen Klagefrist (Kündigungsstreit), 6 Monate für Entschädigung.", tage: 56),
            .init(titel: "Foreldelse (Verjährung)", norm: "foreldelsesloven § 2", beschreibung: "3 Jahre Grundfrist ab Fälligkeit.", tage: 1095),
            .init(titel: "Anke (Berufung)", norm: "tvisteloven § 29-5", beschreibung: "1 Monat ab Zustellung.", tage: 30),
            .init(titel: "Forliksråd-Pflicht", norm: "tvisteloven § 6-2", beschreibung: "Schlichtung vor Klage grundsätzlich obligatorisch.", tage: nil)
        ]
        case .jp: return [
            .init(titel: "不当解雇の争い (Kündigung)", norm: "労働契約法16条", beschreibung: "Keine starre Frist — aber 労働審判 (Arbeitsschnellverfahren) früh einleiten.", tage: nil),
            .init(titel: "消滅時効 (Verjährung)", norm: "民法166条", beschreibung: "5 Jahre ab Kenntnis / 10 Jahre objektiv (seit Reform 2020).", tage: 1825),
            .init(titel: "控訴 (Berufung)", norm: "民訴法285条", beschreibung: "2 Wochen ab Zustellung des Urteils.", tage: 14),
            .init(titel: "内容証明郵便", norm: "郵便法", beschreibung: "Beweissicheres Mahnschreiben — Standard vor jeder Klage.", tage: nil)
        ]
        case .cn: return [
            .init(titel: "劳动仲裁 (Arbeitsschiedsverfahren)", norm: "劳动争议调解仲裁法27条", beschreibung: "1 Jahr ab Kenntnis der Rechtsverletzung — zwingend VOR Klage.", tage: 365),
            .init(titel: "诉讼时效 (Verjährung)", norm: "民法典188条", beschreibung: "3 Jahre ab Kenntnis von Schaden und Schuldner.", tage: 1095),
            .init(titel: "上诉 (Berufung)", norm: "民事诉讼法171条", beschreibung: "15 Tage ab Zustellung des Urteils (Beschluss: 10 Tage).", tage: 15),
            .init(titel: "行政复议", norm: "行政复议法20条", beschreibung: "60 Tage für Verwaltungswiderspruch.", tage: 60)
        ]
        }
    }
    var gebuehrenModell: (titel: String, norm: String, beschreibung: String) {
        switch self {
        case .de: return ("RVG-Wertgebühren", "§ 13 RVG",
                          "Gesetzliche Gebühren nach Gegenstandswert; Honorarvereinbarung nach § 3a RVG möglich.")
        case .ch: return ("Kantonale Anwaltstarife", "z. B. AnwGebV ZH",
                          "Kantonal geregelte Tarife + freie Honorarvereinbarung; Erfolgshonorar (pactum de quota litis) unzulässig, pactum de palmario begrenzt zulässig.")
        case .no: return ("Salærforskrift / freie Vereinbarung", "salærforskriften § 2",
                          "Öffentlicher Stundensatz für Pflichtmandate; sonst freie Vereinbarung mit Angemessenheitskontrolle (RGA pkt. 3.3).")
        case .jp: return ("弁護士報酬 (frei seit 2004)", "弁護士職務基本規程",
                          "Freie Vereinbarung — üblich: 着手金 (Startgebühr) + 報酬金 (Erfolgsgebühr) nach altem 日弁連-Tarif als Marktreferenz.")
        case .cn: return ("律师收费 (reguliert)", "律师服务收费管理办法",
                          "Staatlich regulierte Rahmen + Verhandlungsspielraum; Erfolgshonorar (风险代理) bis max. 30 % — verboten in Straf-/Familiensachen.")
        }
    }
    struct FunktionsPaket {
        let funktion: String
        let ursprung: Rechtsordnung
        let beschreibung: String
        let uebertragbar: String   // Nutzen in anderen Rechtsordnungen
    }
    static let funktionsUnion: [FunktionsPaket] = [
        .init(funktion: "RVG-Wertgebühren-Rechner", ursprung: .de,
              beschreibung: "Gebühren nach Streitwert-Tabelle (§ 13 RVG).",
              uebertragbar: "Als Kostenschätzungs-Referenz auch für CH/NO/JP/CN-Mandate nutzbar (Honorar-Benchmark)."),
        .init(funktion: "Güte-/Schlichtungs-Gate", ursprung: .no,
              beschreibung: "Forliksråd-Pflichtprüfung vor Klage (tvisteloven § 6-2).",
              uebertragbar: "Als Vergleichs-/Mediations-Check für alle Rechtsordnungen — DE: § 278 ZPO Güteverhandlung, JP: 調停, CN: 人民调解."),
        .init(funktion: "Beweissicheres Mahnschreiben", ursprung: .jp,
              beschreibung: "内容証明郵便 — Post zertifiziert Inhalt und Zugang.",
              uebertragbar: "Übertragbar als Zustellungs-/Zugangsbeweis-Checkliste (DE: Einwurfeinschreiben + Zeuge, CH: Gerichtsurkunde, NO: rekommandert brev)."),
        .init(funktion: "Zwingendes Vorschaltverfahren Arbeitsrecht", ursprung: .cn,
              beschreibung: "劳动仲裁 — Arbeitsschiedsverfahren zwingend vor Gericht (1-Jahres-Frist).",
              uebertragbar: "Als Verfahrensweichen-Check: prüft in jeder Rechtsordnung, ob ein obligatorisches Vorverfahren existiert (DE: keins, NO: Forliksråd, JP: 労働審判 optional)."),
        .init(funktion: "Betreibungs-Schnellverfahren", ursprung: .ch,
              beschreibung: "SchKG-Betreibung: Zahlungsbefehl ohne Gericht, Rechtsvorschlag in 10 Tagen.",
              uebertragbar: "Als Forderungs-Durchsetzungs-Vergleich: DE Mahnbescheid (§ 688 ZPO), NO forliksklage, CN 支付令 (民诉法216条)."),
        .init(funktion: "Fristen-Kaskadenrechner", ursprung: .de,
              beschreibung: "Notfristen-Logik (ZPO) mit Wiedereinsetzungs-Prüfung (§ 233 ZPO).",
              uebertragbar: "Kaskade rechnet in jeder aktiven Rechtsordnung mit deren Fristen-Paket — inkl. Warnung bei kürzester Frist (CN Berufung nur 15 Tage, JP nur 2 Wochen).")
    ]
    var radarImpulse: [(norm: String, titel: String, text: String)] {
        switch self {
        case .de: return [
            ("§ 626 BGB", "Fristlose Kündigung", "Außerordentliche Kündigung nur aus wichtigem Grund; 2-Wochen-Erklärungsfrist ab Kenntnis (Abs. 2)."),
            ("§ 138 ZPO", "Wahrheitspflicht", "Parteien haben vollständig und der Wahrheit gemäß vorzutragen."),
            ("Art. 22 DSGVO", "Automatisierte Entscheidung", "Anspruch auf menschliche Intervention bei automatisierten Einzelentscheidungen.")
        ]
        case .ch: return [
            ("Art. 336 OR", "Missbräuchliche Kündigung", "Entschädigung bis 6 Monatslöhne; Kündigungsschutz schwächer als DE — keine Weiterbeschäftigung."),
            ("Art. 2 ZGB", "Treu und Glauben", "Offenbarer Rechtsmissbrauch findet keinen Rechtsschutz — zentrale Generalklausel."),
            ("Art. 257 ZPO-CH", "Rechtsschutz in klaren Fällen", "Schnellverfahren bei liquidem Sachverhalt und klarer Rechtslage.")
        ]
        case .no: return [
            ("arbeidsmiljøloven § 15-7", "Saklig grunn", "Kündigung nur mit sachlichem Grund; Interessenabwägung zwingend — Standard ähnlich DE."),
            ("tvisteloven § 6-2", "Forliksråd", "Schlichtungsrat grundsätzlich obligatorische erste Instanz für Zivilklagen."),
            ("avtaleloven § 36", "Generalklausel", "Unbillige Verträge können angepasst oder aufgehoben werden — sehr weitgehende richterliche Eingriffsbefugnis.")
        ]
        case .jp: return [
            ("労働契約法16条", "解雇権濫用法理", "Kündigung ohne objektiv vernünftigen Grund ist missbräuchlich und nichtig — strengster Kündigungsschutz der 5 Rechtsordnungen."),
            ("民法709条", "不法行為 (Delikt)", "Generalklausel: Vorsatz/Fahrlässigkeit + Rechtsverletzung + Schaden + Kausalität."),
            ("民訴法248条", "Schadensschätzung", "Gericht darf Schadenshöhe nach freier Überzeugung schätzen, wenn Nachweis extrem schwierig.")
        ]
        case .cn: return [
            ("劳动合同法39条", "Fristlose Kündigung AG", "Arbeitgeber-Kündigung nur bei gesetzlich aufgezählten Gründen — keine Generalklausel; 经济补偿 (Abfindung) nach 47条."),
            ("民法典577条", "Vertragsbruch", "Verschuldensunabhängige Haftung für Vertragsverletzung — anders als DE (§ 280 BGB: Vertretenmüssen)."),
            ("最高人民法院司法解释", "SPC-Auslegungen", "Justizauslegungen des Obersten Volksgerichts wirken quasi-normativ und sind zwingend mitzuprüfen.")
        ]
        }
    }
}
extension Rechtsordnung {
    static var aktiveAusDefaults: [Rechtsordnung] {
        let roh = UserDefaults.standard.stringArray(forKey: "fenlynineos_rechtsordnungen") ?? ["de"]
        let set = Set(roh.compactMap(Rechtsordnung.init(rawValue:)))
        let liste = Rechtsordnung.allCases.filter { set.contains($0) }
        return liste.isEmpty ? [.de] : liste
    }
    static var promptKopf: String {
        let laender = aktiveAusDefaults
        var zeilen = ["# Aktive Rechtsordnungen: " + laender.map { "\($0.flagge) \($0.name)" }.joined(separator: " · ")]
        for l in laender { zeilen.append("- \(l.name): \(l.kiSprachHinweis)") }
        if laender.count > 1 {
            zeilen.append("Rechtsvergleichend antworten, Unterschiede der Rechtsordnungen ausdrücklich benennen.")
        }
        return zeilen.joined(separator: "\n")
    }
}
@MainActor
final class RechtsordnungManager: ObservableObject {
    static let shared = RechtsordnungManager()
    @Published var aktive: Set<Rechtsordnung> {
        didSet {
            UserDefaults.standard.set(aktive.map(\.rawValue).sorted(), forKey: "fenlynineos_rechtsordnungen")
        }
    }
    private init() {
        let roh = UserDefaults.standard.stringArray(forKey: "fenlynineos_rechtsordnungen") ?? ["de"]
        var set = Set(roh.compactMap(Rechtsordnung.init(rawValue:)))
        if set.isEmpty { set = [.de] }
        aktive = set
    }
    var aktiveSortiert: [Rechtsordnung] {
        Rechtsordnung.allCases.filter { aktive.contains($0) }
    }
    func umschalten(_ r: Rechtsordnung) {
        if aktive.contains(r) {
            if aktive.count > 1 { aktive.remove(r) }   // mindestens eine bleibt aktiv
        } else {
            aktive.insert(r)
        }
    }
    var kontextFuerPrompt: String {
        let laender = aktiveSortiert
        guard !laender.isEmpty else { return "" }
        var zeilen = ["# Aktive Rechtsordnungen: " + laender.map { "\($0.flagge) \($0.name)" }.joined(separator: " · ")]
        for l in laender {
            zeilen.append("- \(l.name): \(l.kiSprachHinweis)")
        }
        if laender.count > 1 {
            zeilen.append("Rechtsvergleichend antworten, Unterschiede der Rechtsordnungen ausdrücklich benennen.")
        }
        return zeilen.joined(separator: "\n")
    }
    var verfuegbareFunktionen: [Rechtsordnung.FunktionsPaket] {
        Rechtsordnung.funktionsUnion
    }
}
