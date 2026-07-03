import SwiftUI

// MARK: - Kern-Datenmodelle

struct Txn: Identifiable, Codable, Hashable {
    var id = UUID()
    var accountId: UUID
    var date: Date
    var name: String
    var iban: String?
    var subject: String
    var amount: Double // negativ = Ausgabe
}

enum SubStatus: String, Codable, CaseIterable {
    case pending, warning, keep, convert

    var label: String {
        switch self {
        case .pending: return "Ausstehender Check"
        case .warning: return "Warnung / Risiko"
        case .keep: return "Behalten"
        case .convert: return "In Sparplan umwandeln"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .warning: return .red
        case .keep: return .blue
        case .convert: return .green
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .warning: return "exclamationmark.triangle"
        case .keep: return "checkmark"
        case .convert: return "arrow.up.right"
        }
    }
}

struct Conversion: Codable, Hashable {
    var cancelled = false
    var planCreated = false
    var confirmed = false
    var etfIsin: String?
    var etfName: String?
}

struct PricePoint: Codable, Hashable {
    var month: String // "2026-05"
    var amount: Double
}

struct Subscription: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var amount: Double
    var cycle: String = "monatlich"
    var sinceMonth: String
    var category: String
    var status: SubStatus = .pending
    var iban: String?
    var note: String = ""
    var paused = false
    var paymentDay: Int?
    var occurrences: Int = 0
    var priceHistory: [PricePoint] = []
    var conversion = Conversion()

    var monthlyAmount: Double {
        switch cycle {
        case "jährlich": return amount / 12
        case "vierteljährlich": return amount / 3
        default: return amount
        }
    }
}

struct Account: Identifiable, Codable, Hashable {
    var id = UUID()
    var providerId: String
    var label: String
    var iban: String?
}

// MARK: - Kataloge (statisch, wie die JSON-Dateien der Web-App)

struct Provider: Identifiable, Hashable {
    let id: String
    let name: String
    let colorHex: String
    let letter: String
    let type: String
    let exportGuide: [String]

    static let genericGuide = [
        "Online-Banking/App öffnen → Konto wählen",
        "Umsätze anzeigen → Zeitraum wählen",
        "Export/Download als CSV",
        "Datei hier importieren",
    ]

    static let all: [Provider] = [
        Provider(id: "sparkasse", name: "Sparkasse", colorHex: "E30613", letter: "S", type: "Bank",
                 exportGuide: ["Online-Banking öffnen → Girokonto wählen", "Reiter „Umsätze“ → Zeitraum wählen", "Symbol „Export“ → „CSV-Export“", "Datei hier importieren"]),
        Provider(id: "volksbank", name: "Volksbank", colorHex: "0066B3", letter: "V", type: "Bank", exportGuide: genericGuide),
        Provider(id: "deutsche-bank", name: "Deutsche Bank", colorHex: "0018A8", letter: "D", type: "Bank", exportGuide: genericGuide),
        Provider(id: "commerzbank", name: "Commerzbank", colorHex: "FFCC33", letter: "C", type: "Bank", exportGuide: genericGuide),
        Provider(id: "ing", name: "ING", colorHex: "FF6200", letter: "I", type: "Bank",
                 exportGuide: ["Internetbanking → Girokonto", "„Umsatzanzeige“ → Zeitraum", "„Export“ → CSV (Excel)", "Datei hier importieren"]),
        Provider(id: "dkb", name: "DKB", colorHex: "1482C9", letter: "D", type: "Bank", exportGuide: genericGuide),
        Provider(id: "n26", name: "N26", colorHex: "36A18B", letter: "N", type: "Bank", exportGuide: genericGuide),
        Provider(id: "revolut", name: "Revolut", colorHex: "191C1F", letter: "R", type: "Bank", exportGuide: genericGuide),
        Provider(id: "paypal", name: "PayPal", colorHex: "003087", letter: "P", type: "Wallet",
                 exportGuide: ["paypal.com anmelden → „Aktivitäten“", "Oben rechts „Herunterladen“", "Format „CSV“ + Zeitraum → Bericht erstellen", "Datei hier importieren"]),
        Provider(id: "klarna", name: "Klarna", colorHex: "FFB3C7", letter: "K", type: "Wallet", exportGuide: genericGuide),
        Provider(id: "amex", name: "American Express", colorHex: "006FCF", letter: "A", type: "Karte", exportGuide: genericGuide),
        Provider(id: "visa", name: "Visa", colorHex: "1A1F71", letter: "V", type: "Karte", exportGuide: genericGuide),
        Provider(id: "mastercard", name: "Mastercard", colorHex: "EB001B", letter: "M", type: "Karte", exportGuide: genericGuide),
        Provider(id: "trade-republic", name: "Trade Republic", colorHex: "111111", letter: "T", type: "Broker", exportGuide: genericGuide),
        Provider(id: "scalable", name: "Scalable Capital", colorHex: "1B4DFF", letter: "S", type: "Broker", exportGuide: genericGuide),
    ]

    static func byId(_ id: String) -> Provider {
        all.first { $0.id == id } ?? Provider(id: id, name: id, colorHex: "999999", letter: "?", type: "Bank", exportGuide: genericGuide)
    }
}

struct Broker: Identifiable, Hashable {
    let id: String
    let name: String
    let colorHex: String
    let letter: String
    let url: String
    let etfUrlPattern: String?

    func etfUrl(isin: String) -> URL? {
        if let pattern = etfUrlPattern {
            return URL(string: pattern.replacingOccurrences(of: "{ISIN}", with: isin))
        }
        return URL(string: "https://www.justetf.com/de/etf-profile.html?isin=\(isin)")
    }

    static let all: [Broker] = [
        Broker(id: "trade-republic", name: "Trade Republic", colorHex: "111111", letter: "T", url: "https://traderepublic.com/de-de", etfUrlPattern: nil),
        Broker(id: "scalable", name: "Scalable Capital", colorHex: "1B4DFF", letter: "S", url: "https://de.scalable.capital", etfUrlPattern: "https://de.scalable.capital/broker/security?isin={ISIN}"),
        Broker(id: "ing", name: "ING", colorHex: "FF6200", letter: "I", url: "https://www.ing.de/wertpapiere/", etfUrlPattern: "https://wertpapiere.ing.de/Investieren/Suche/{ISIN}"),
        Broker(id: "comdirect", name: "comdirect", colorHex: "C8A800", letter: "c", url: "https://www.comdirect.de", etfUrlPattern: "https://www.comdirect.de/inf/search/all.html?SEARCH_VALUE={ISIN}"),
        Broker(id: "zero", name: "finanzen.net zero", colorHex: "00A005", letter: "Z", url: "https://www.finanzen.net/zero/", etfUrlPattern: nil),
    ]
}

struct CancelLink {
    let match: [String]
    let label: String
    let url: String

    static let all: [CancelLink] = [
        CancelLink(match: ["netflix"], label: "Netflix kündigen", url: "https://www.netflix.com/cancelplan"),
        CancelLink(match: ["spotify"], label: "Spotify kündigen", url: "https://www.spotify.com/de/account/subscription/"),
        CancelLink(match: ["adobe"], label: "Adobe-Abo kündigen", url: "https://account.adobe.com/plans"),
        CancelLink(match: ["amazon prime", "prime mitglied"], label: "Amazon Prime kündigen", url: "https://www.amazon.de/mc/pipelines/cancellation"),
        CancelLink(match: ["disney"], label: "Disney+ kündigen", url: "https://www.disneyplus.com/de-de/account/subscription"),
        CancelLink(match: ["vodafone"], label: "Vodafone kündigen", url: "https://www.vodafone.de/kuendigung/"),
        CancelLink(match: ["telekom"], label: "Telekom kündigen", url: "https://www.telekom.de/kuendigung"),
        CancelLink(match: ["o2"], label: "o2 kündigen", url: "https://www.o2online.de/vertrag/kuendigung/"),
        CancelLink(match: ["fitness first"], label: "Fitness First kündigen", url: "https://www.fitnessfirst.de/kuendigen"),
        CancelLink(match: ["mcfit"], label: "McFIT kündigen", url: "https://www.mcfit.com/de/kuendigung/"),
        CancelLink(match: ["dazn"], label: "DAZN kündigen", url: "https://www.dazn.com/de-DE/account/subscription"),
        CancelLink(match: ["youtube"], label: "YouTube Premium kündigen", url: "https://www.youtube.com/paid_memberships"),
        CancelLink(match: ["apple"], label: "Apple-Abo kündigen", url: "https://support.apple.com/de-de/118428"),
        CancelLink(match: ["audible"], label: "Audible kündigen", url: "https://www.audible.de/account/membership"),
        CancelLink(match: ["stadtwerke", "strom", "gas"], label: "Versorger wechseln", url: "https://www.check24.de/strom/"),
    ]

    static func find(for name: String) -> CancelLink? {
        let hay = name.lowercased()
        return all.first { link in link.match.contains { hay.contains($0) } }
    }
}

struct InvestAsset: Identifiable, Hashable {
    let id: String
    let name: String
    let assetClass: String // etf, aktie, anleihe, rohstoff, portfolio
    let ret: Double        // historische Rendite % p.a.
    let risk: String
    let riskScore: Int
    let isin: String?
    let desc: String
    let mix: String?

    static let universe: [InvestAsset] = [
        InvestAsset(id: "msci-world", name: "MSCI World (thesaurierend)", assetClass: "etf", ret: 7.1, risk: "Mittel", riskScore: 3, isin: "IE00B4L5Y983", desc: "Weltweit gestreut, ~1.500 Unternehmen aus 23 Industrieländern.", mix: nil),
        InvestAsset(id: "sp500", name: "S&P 500", assetClass: "etf", ret: 9.2, risk: "Mittel-Hoch", riskScore: 4, isin: "IE00B5BMR087", desc: "500 größte börsennotierte US-Unternehmen.", mix: nil),
        InvestAsset(id: "ftse-all-world", name: "FTSE All-World", assetClass: "etf", ret: 6.9, risk: "Mittel", riskScore: 3, isin: "IE00BK5BQT80", desc: "Industrieländer + Schwellenländer, ~4.000 Positionen.", mix: nil),
        InvestAsset(id: "nasdaq", name: "Nasdaq 100", assetClass: "etf", ret: 11.8, risk: "Hoch", riskScore: 5, isin: "IE00B53SZB19", desc: "100 größte Nicht-Finanz-Unternehmen der Nasdaq — Tech-lastig.", mix: nil),
        InvestAsset(id: "em", name: "MSCI Emerging Markets", assetClass: "etf", ret: 5.4, risk: "Hoch", riskScore: 5, isin: "IE00BKM4GZ66", desc: "China, Indien, Brasilien & Co. — höhere Schwankungen.", mix: nil),
        InvestAsset(id: "esg", name: "MSCI World SRI (ESG)", assetClass: "etf", ret: 6.7, risk: "Mittel", riskScore: 3, isin: "IE00BYX2JD69", desc: "Nachhaltig gefiltert, ~400 Unternehmen.", mix: nil),
        InvestAsset(id: "apple", name: "Apple", assetClass: "aktie", ret: 15.0, risk: "Hoch", riskScore: 5, isin: "US0378331005", desc: "Größter Tech-Konzern der Welt — Einzelaktien-Risiko.", mix: nil),
        InvestAsset(id: "microsoft", name: "Microsoft", assetClass: "aktie", ret: 14.2, risk: "Hoch", riskScore: 5, isin: "US5949181045", desc: "Cloud und KI treiben das Wachstum.", mix: nil),
        InvestAsset(id: "nvidia", name: "NVIDIA", assetClass: "aktie", ret: 28.0, risk: "Sehr hoch", riskScore: 6, isin: "US67066G1040", desc: "KI-Chip-Profiteur — extreme Rendite, extreme Schwankung.", mix: nil),
        InvestAsset(id: "asml", name: "ASML", assetClass: "aktie", ret: 16.5, risk: "Hoch", riskScore: 5, isin: "NL0010273215", desc: "Quasi-Monopol für EUV-Lithographie.", mix: nil),
        InvestAsset(id: "allianz", name: "Allianz", assetClass: "aktie", ret: 8.0, risk: "Mittel", riskScore: 3, isin: "DE0008404005", desc: "Versicherungsriese mit ~5% Dividendenrendite.", mix: nil),
        InvestAsset(id: "bund", name: "Bundesanleihen 10J", assetClass: "anleihe", ret: 2.4, risk: "Sehr niedrig", riskScore: 1, isin: "DE0001102580", desc: "Höchste Bonität der Eurozone, planbare Rendite.", mix: nil),
        InvestAsset(id: "corp", name: "Euro Unternehmensanleihen (IG)", assetClass: "anleihe", ret: 3.6, risk: "Niedrig", riskScore: 2, isin: "IE00B3F81R35", desc: "Anleihen solider europäischer Konzerne.", mix: nil),
        InvestAsset(id: "highyield", name: "Global High Yield", assetClass: "anleihe", ret: 5.2, risk: "Mittel", riskScore: 3, isin: "IE00B74DQ490", desc: "Mehr Zins, spürbares Ausfallrisiko.", mix: nil),
        InvestAsset(id: "gold", name: "Gold (physisch hinterlegt)", assetClass: "rohstoff", ret: 6.5, risk: "Mittel", riskScore: 3, isin: "DE000A0S9GB0", desc: "Bewährter Baustein gegen Inflations- und Krisenrisiken.", mix: nil),
        InvestAsset(id: "silber", name: "Silber", assetClass: "rohstoff", ret: 5.0, risk: "Hoch", riskScore: 5, isin: "DE000A0N62F2", desc: "Halb Edelmetall, halb Industrierohstoff — volatil.", mix: nil),
        InvestAsset(id: "rohstoffe", name: "Bloomberg Commodity (breit)", assetClass: "rohstoff", ret: 4.0, risk: "Hoch", riskScore: 4, isin: "IE00BD6FTQ80", desc: "Energie, Metalle, Agrar in einem Index.", mix: nil),
        InvestAsset(id: "mix-ki", name: "Themen-Mix: KI & Chips", assetClass: "portfolio", ret: 13.5, risk: "Sehr hoch", riskScore: 6, isin: nil, desc: "Bündelt die KI-Wertschöpfungskette.", mix: "40% Halbleiter-ETF, 30% Nasdaq 100, 20% Einzelwerte, 10% Cash"),
        InvestAsset(id: "mix-7030", name: "Klassik-Mix: 70/30 Welt", assetClass: "portfolio", ret: 6.8, risk: "Mittel", riskScore: 3, isin: nil, desc: "Der bewährte Standard-Mix.", mix: "70% MSCI World, 30% Emerging Markets"),
        InvestAsset(id: "mix-allwetter", name: "Allwetter-Mix (defensiv)", assetClass: "portfolio", ret: 5.0, risk: "Niedrig", riskScore: 2, isin: nil, desc: "Soll in jeder Marktphase moderat bestehen.", mix: "40% Aktien, 40% Anleihen, 15% Gold, 5% Rohstoffe"),
    ]
}

struct RadarTip: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let text: String
    let saving: String?
}

struct RadarTopic: Identifiable, Hashable {
    let id: String
    let icon: String
    let title: String
    let intro: String
    let tips: [RadarTip]

    static let all: [RadarTopic] = [
        RadarTopic(id: "kredite", icon: "banknote", title: "Kredite & Zinsen", intro: "Wo ist der Kreditzins am günstigsten — und wie drückst du ihn weiter?", tips: [
            RadarTip(title: "Vergleichsportale gegeneinander ausspielen", text: "Der gleiche Kredit kostet je nach Portal unterschiedlich viel. Konditionsanfragen sind SCHUFA-neutral.", saving: "oft 1–3% eff. Zins"),
            RadarTip(title: "Hausbank mit Online-Angebot konfrontieren", text: "Konkretes Konkurrenzangebot vorlegen und um ein Gegenangebot bitten.", saving: "0,3–1% Zins"),
            RadarTip(title: "Restschuldversicherung fast immer abwählen", text: "Verteuert den effektiven Zins oft massiv. Separater Risikoschutz ist meist günstiger.", saving: "teils 4-stellig"),
            RadarTip(title: "Dispo ist der teuerste Kredit", text: "Bei regelmäßiger Nutzung auf Rahmenkredit (ca. 6–8%) umschulden.", saving: "~50% der Dispozinsen"),
        ]),
        RadarTopic(id: "waehrungen", icon: "dollarsign.arrow.circlepath", title: "Währungen & Auslandsgeld", intro: "Euro-Dollar, Auslandsüberweisungen, Reisegeld: wo Banken still mitverdienen.", tips: [
            RadarTip(title: "Wechselkurs-Aufschlag erkennen", text: "Banken schlagen oft 2–4% auf den Marktkurs auf. Anbieter wie Wise/Revolut tauschen nahe am Mittelkurs.", saving: "2–4% pro Tausch"),
            RadarTip(title: "Im Ausland IMMER in Landeswährung zahlen", text: "„In Euro abrechnen?“ am Automaten ablehnen — die Umrechnung des Betreibers ist meist miserabel.", saving: "3–8% pro Zahlung"),
            RadarTip(title: "FX-Gebühr des Brokers prüfen", text: "Vor US-Aktienkäufen die Fremdwährungsgebühr vergleichen (0% bis 0,5% je Broker).", saving: "bis 0,5% pro Order"),
        ]),
        RadarTopic(id: "immobilien", icon: "house", title: "Immobilien clever kaufen", intro: "Die größten Sparhebel stecken in Nebenkosten und Verhandlung.", tips: [
            RadarTip(title: "Bewegliches Inventar aus dem Kaufpreis rechnen", text: "Küche, Sauna, Markisen separat im Notarvertrag ausweisen — darauf fällt keine Grunderwerbsteuer an.", saving: "3,5–6,5% auf den Inventarwert"),
            RadarTip(title: "Maklerprovision ist verhandelbar", text: "Käufer zahlt höchstens die Hälfte; Gesamthöhe frei verhandelbar — besonders bei Ladenhütern.", saving: "0,5–1,5% des Kaufpreises"),
            RadarTip(title: "Kaufnebenkosten nie mitfinanzieren", text: "Nebenkosten aus Eigenkapital zahlen drückt den Zins der gesamten Finanzierung.", saving: "0,2–0,8% Zins"),
            RadarTip(title: "Förderung VOR Kauf prüfen", text: "KfW-/BAFA-Zuschüsse gibt es teils nur bei Antrag vor Beginn der Maßnahme.", saving: "bis 70.000 € Zuschuss"),
        ]),
        RadarTopic(id: "steuern", icon: "scalemass", title: "Steuern, Schenken & Erben", intro: "Legale Gestaltung: Freibeträge nutzen. Kein Steuerberater-Ersatz!", tips: [
            RadarTip(title: "Schenkungs-Freibeträge alle 10 Jahre neu", text: "Kinder: 400.000 € pro Elternteil alle 10 Jahre steuerfrei, Enkel 200.000 €, Ehepartner 500.000 €.", saving: "bis zu 30% Erbschaftsteuer"),
            RadarTip(title: "Ehegattenschaukel bei vermieteten Immobilien", text: "Verkauf zwischen Ehegatten frischt die Abschreibungsbasis auf. Nur mit Steuerberater umsetzen!", saving: "neue AfA-Basis, oft 5-stellig/Jahr"),
            RadarTip(title: "Familienheim erbt sich steuerfrei", text: "Selbstgenutzte Immobilie geht steuerfrei an Ehepartner/Kinder — Bedingung: 10 Jahre selbst bewohnen.", saving: "komplette ErbSt auf das Heim"),
            RadarTip(title: "Sparerpauschbetrag richtig verteilen", text: "1.000 €/Person Kapitalerträge steuerfrei — Freistellungsaufträge auf Banken verteilen.", saving: "bis ~500 €/Jahr"),
        ]),
        RadarTopic(id: "alltag", icon: "cart", title: "Alltags-Tricks", intro: "Kleine Hebel, die sich jeden Monat summieren.", tips: [
            RadarTip(title: "Jahreszahlung statt Monatsabo", text: "Versicherungen und Abos geben 5–10% Rabatt bei jährlicher Zahlweise.", saving: "5–10% pro Vertrag"),
            RadarTip(title: "Neukunden-Karussell bei Strom & Gas", text: "Jährlicher Wechsel bringt oft 100–300 € Bonus. Erinnerung nach 11 Monaten setzen.", saving: "100–300 €/Jahr"),
            RadarTip(title: "Cashback & Deals stapeln", text: "Gutschein-Code + Cashback-Portal + Kreditkarten-Cashback schließen sich meist nicht aus.", saving: "3–15% pro Einkauf"),
            RadarTip(title: "Arbeitgeber-Benefits abfragen", text: "Deutschlandticket-Zuschuss, bAV mit AG-Zuschuss, Jobrad, Sachbezugskarte — oft ungenutzt.", saving: "oft >1.000 €/Jahr netto"),
        ]),
        RadarTopic(id: "versicherungen", icon: "shield", title: "Versicherungen entrümpeln", intro: "Überversichert bei Kleinkram, unterversichert bei Existenzrisiken.", tips: [
            RadarTip(title: "Diese 4 zuerst", text: "Privathaftpflicht, Berufsunfähigkeit, ggf. Risikoleben, Auslandskranken. Handy-/Geräteversicherungen lieber selbst ansparen.", saving: "oft 300–600 €/Jahr"),
            RadarTip(title: "KFZ: jedes Jahr im November vergleichen", text: "Stichtag 30.11. — Wechsel spart im Schnitt 200–400 €.", saving: "200–400 €/Jahr"),
            RadarTip(title: "Alte Lebensversicherung nicht vorschnell kündigen", text: "Verträge vor 2005: steuerfrei + 3–4% Garantiezins. Beitragsfreistellung statt Kündigung prüfen.", saving: "Garantiezins sichern"),
        ]),
    ]
}

// MARK: - Finanzmathematik

enum FinMath {
    /// Endwert eines monatlichen Sparplans (nachschüssig).
    static func futureValue(monthly: Double, annualPct: Double, years: Double) -> Double {
        let r = annualPct / 100 / 12
        let n = years * 12
        guard r > 0 else { return monthly * n }
        return monthly * ((pow(1 + r, n) - 1) / r)
    }
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension Double {
    var euro: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: NSNumber(value: self)) ?? "\(self) €"
    }
}
