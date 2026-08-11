import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Jurisdiktionskonfiguration (Port von jurisdictionConfig.js)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Jurisdiktion: Identifiable, Hashable {
let id: String // "DE", "AT", "CH", "EU", "US", "UK", "FR"
let name: String
let flag: String
let sprache: String
let waehrung: String
let waehrungsSymbol: String
let gerichtssystem: Gerichtssystem
let rechtsgebiete: [Rechtsgebiet]
let fristenRegeln: FristenRegeln
let kostenRegeln: KostenRegeln
let ki_hinweise: [String]
}

// MARK: - Gerichtssystem

struct Gerichtssystem: Hashable {
let instanzen: [String] // ["AG/LG", "OLG", "BGH"]
let verfassungsgericht: String?
let spezialgerichte: [String]
let beschreibung: String
}

// MARK: - Rechtsgebiet

struct Rechtsgebiet: Identifiable, Hashable {
let id: String
let name: String
let symbol: String
let unterbereiche: [String]
let typischeVerfahrensdauer: ClosedRange<Int> // Monate
let typischeKosten: ClosedRange<Double> // Euro
let erfolgsquoteDurchschnitt: Double // 0.0-1.0
}

// MARK: - Fristen-Regeln

struct FristenRegeln: Hashable {
let berufungsfrist: Int // Tage ab Urteilszustellung
let revisionsfrist: Int
let widerspruchsfrist: Int
let verjährungsfristen: [String: Int] // [Fristtyp: Tage]
let gerichtsferien: [String] // ["24.12.-06.01.", "…"]
let hinweis: String
}

// MARK: - Kosten-Regeln

struct KostenRegeln: Hashable {
let kostenerstattungSieger: Bool // Unterlegener trägt Kosten?
let anwaltspflicht: Bool
let streitwertFormel: String
let gebuehrentabelleURL: String?
let mehrwertsteuer: Double // 0.19 für DE
}

// MARK: - Zentrales Konfigurations-Register

enum JurisdiktionRegister {

static let alle: [Jurisdiktion] = [DE, AT, CH, EU, US, UK, FR]

static func finden(id: String) -> Jurisdiktion? {
  alle.first { $0.id == id }
}

// MARK: - Deutschland
static let DE = Jurisdiktion(
  id: "DE",
  name: "Deutschland",
  flag: "nn",
  sprache: "de",
  waehrung: "EUR",
  waehrungsSymbol: "€",
  gerichtssystem: Gerichtssystem(
    instanzen: ["AG / LG", "OLG", "BGH"],
    verfassungsgericht: "BVerfG",
    spezialgerichte: ["VG", "FG", "SG", "ArbG", "PatG"],
    beschreibung: "Zivilrechtliches System nach BGB, ZPO, GVG"
  ),
  rechtsgebiete: [
    Rechtsgebiet(id: "zivilrecht", name: "Zivilrecht", symbol: "doc.text",
          unterbereiche: ["Vertragsrecht", "Schadensersatz", "Kaufrecht", "Werkvertrag", "Darlehen"],
          typischeVerfahrensdauer: 6...24, typischeKosten: 3000...50000, erfolgsquoteDurchschnitt: 0.54),
    Rechtsgebiet(id: "arbeitsrecht", name: "Arbeitsrecht", symbol: "briefcase",
          unterbereiche: ["Kündigung", "Abfindung", "Diskriminierung", "Betriebsrat"],
          typischeVerfahrensdauer: 3...18, typischeKosten: 2000...20000, erfolgsquoteDurchschnitt: 0.48),
    Rechtsgebiet(id: "verwaltungsrecht", name: "Verwaltungsrecht", symbol: "building.columns",
          unterbereiche: ["Baugenehmigung", "Gewerberecht", "Ausländerrecht", "Sozialrecht"],
          typischeVerfahrensdauer: 12...60, typischeKosten: 5000...80000, erfolgsquoteDurchschnitt: 0.38),
    Rechtsgebiet(id: "strafrecht", name: "Strafrecht", symbol: "exclamationmark.triangle",
          unterbereiche: ["Wirtschaftsstrafrecht", "Betrug", "Körperverletzung", "Verkehrsrecht"],
         typischeVerfahrensdauer: 6...36, typischeKosten: 5000...100000, erfolgsquoteDurchschnitt: 0.62),
   Rechtsgebiet(id: "handelsrecht", name: "Handels-/Gesellschaftsrecht", symbol: "building.2",
         unterbereiche: ["GmbH", "AG", "M&A", "Insolvenz", "Handelsvertreter"],
         typischeVerfahrensdauer: 12...48, typischeKosten: 15000...500000, erfolgsquoteDurchschnitt: 0.51),
   Rechtsgebiet(id: "ip", name: "IP / Medienrecht", symbol: "lightbulb",
         unterbereiche: ["Patent", "Marke", "Urheberrecht", "Wettbewerbsrecht", "Datenschutz"],
         typischeVerfahrensdauer: 12...60, typischeKosten: 10000...200000, erfolgsquoteDurchschnitt: 0.55),
 ],
 fristenRegeln: FristenRegeln(
   berufungsfrist: 30,
   revisionsfrist: 30,
   widerspruchsfrist: 14,
   verjährungsfristen: [
     "regelmäßig": 1095, // 3 Jahre § 195 BGB
     "deliktsrecht": 3650, // 10 Jahre Schadensersatz
     "kaufmännisch": 1825, // 5 Jahre HGB
     "bereicherung": 3650,
   ],
   gerichtsferien: ["24.12.-06.01.", "Oster-/Pfingstferien variabel"],
   hinweis: "Notfristen nicht verlängerbar (§ 224 ZPO). Fristberechnung nach §§ 186-193 BGB."
 ),
 kostenRegeln: KostenRegeln(
   kostenerstattungSieger: true,
   anwaltspflicht: true,
   streitwertFormel: "GKG + RVG nach Streitwert",
   gebuehrentabelleURL: "https://www.gesetze-im-internet.de/rvg/",
   mehrwertsteuer: 0.19
 ),
 ki_hinweise: [
   "DE: Zivilprozessordnung (ZPO) als Verfahrensgrundlage",
   "Kostenerstattung richtet sich nach RVG-Gegenstandswert",
   "Richterliche Unabhängigkeit nach GG Art. 97",
   "EU-Grundrechtecharta und EMRK ergänzen nationales Recht",
 ]
)

// MARK: - Österreich
static let AT = Jurisdiktion(
 id: "AT",
 name: "Österreich",
 flag: "nn",
 sprache: "de",
 waehrung: "EUR",
 waehrungsSymbol: "€",
 gerichtssystem: Gerichtssystem(
   instanzen: ["BG / LG", "OLG", "OGH"],
   verfassungsgericht: "VfGH",
   spezialgerichte: ["VwGH", "BAG", "HG Wien"],
   beschreibung: "ABGB, ZPO (AT), ähnlich deutschem System"
 ),
 rechtsgebiete: [
   Rechtsgebiet(id: "zivilrecht", name: "Zivilrecht", symbol: "doc.text",
         unterbereiche: ["ABGB", "UGB", "Mietrecht", "Schadenersatz"],
         typischeVerfahrensdauer: 6...24, typischeKosten: 3000...40000, erfolgsquoteDurchschnitt: 0.53),
 ],
 fristenRegeln: FristenRegeln(
   berufungsfrist: 28, revisionsfrist: 28, widerspruchsfrist: 14,
   verjährungsfristen: ["regelmäßig": 1095, "delikt": 3650],
   gerichtsferien: ["24.12.-06.01.", "Juli-August"],
   hinweis: "Fristen nach ZPO (AT), § 125 ZPO für Gerichtsferien."
 ),
 kostenRegeln: KostenRegeln(
   kostenerstattungSieger: true, anwaltspflicht: true,
   streitwertFormel: "RAO-Tarif nach Streitwert", gebuehrentabelleURL: nil, mehrwertsteuer: 0.20
 ),
 ki_hinweise: ["AT: ABGB als primäres Zivilgesetzbuch", "Richterrecht durch OGH-Entscheidungen relevant"]
)

// MARK: - Schweiz
static let CH = Jurisdiktion(
 id: "CH",
 name: "Schweiz",
 flag: "nn",
 sprache: "de",
 waehrung: "CHF",
 waehrungsSymbol: "Fr.",
 gerichtssystem: Gerichtssystem(
   instanzen: ["Kantonsgericht", "Obergericht", "Bundesgericht"],
   verfassungsgericht: "Bundesgericht",
   spezialgerichte: ["Handelsgericht", "Arbeitsgericht"],
   beschreibung: "ZGB/OR, kantonale Unterschiede"
 ),
 rechtsgebiete: [
   Rechtsgebiet(id: "zivilrecht", name: "Zivilrecht", symbol: "doc.text",
         unterbereiche: ["ZGB", "OR", "SchKG", "Mietrecht"],
         typischeVerfahrensdauer: 6...36, typischeKosten: 5000...80000, erfolgsquoteDurchschnitt: 0.52),
 ],
 fristenRegeln: FristenRegeln(
   berufungsfrist: 30, revisionsfrist: 30, widerspruchsfrist: 20,
   verjährungsfristen: ["regelmäßig": 3650, "delikt": 3650],
   gerichtsferien: ["Kantonale Gerichtsferien variieren"],
   hinweis: "Kantonale ZPO-Unterschiede beachten. Bundesgericht nur bei >=30k CHF Streitwert."
 ),
 kostenRegeln: KostenRegeln(
   kostenerstattungSieger: true, anwaltspflicht: false,
   streitwertFormel: "Kantonale Tarife", gebuehrentabelleURL: nil, mehrwertsteuer: 0.077
 ),
 ki_hinweise: ["CH: Kantonale Unterschiede beachten", "SchKG für Schuldbetreibung zentral"]
)

// MARK: - Europäische Union
static let EU = Jurisdiktion(
 id: "EU",
 name: "Europäische Union",
 flag: "nn",
 sprache: "de",
 waehrung: "EUR",
 waehrungsSymbol: "€",
 gerichtssystem: Gerichtssystem(
   instanzen: ["EuGH", "EuG", "EGMR"],
   verfassungsgericht: "EuGH",
   spezialgerichte: ["Gericht für den öffentlichen Dienst", "EUIPO"],
   beschreibung: "Supranationales EU-Recht, Vorabentscheidungsverfahren"
 ),
 rechtsgebiete: [
   Rechtsgebiet(id: "wettbewerb", name: "Wettbewerbs-/Kartellrecht", symbol: "chart.line.uptrend.xyaxis",
         unterbereiche: ["Art. 101/102 AEUV", "Fusionskontrolle", "Beihilferecht"],
         typischeVerfahrensdauer: 24...120, typischeKosten: 50000...5000000, erfolgsquoteDurchschnitt: 0.35),
   Rechtsgebiet(id: "datenschutz", name: "Datenschutz (DSGVO)", symbol: "lock.shield",
         unterbereiche: ["Art. 6 DSGVO", "Betroffenenrechte", "Datenpannen", "Art. 22 KI"],
         typischeVerfahrensdauer: 6...36, typischeKosten: 5000...500000, erfolgsquoteDurchschnitt: 0.45),
 ],
 fristenRegeln: FristenRegeln(
   berufungsfrist: 60, revisionsfrist: 60, widerspruchsfrist: 30,
   verjährungsfristen: [:],
   gerichtsferien: ["15.07.-15.09. (EuGH)", "21.12.-07.01."],
   hinweis: "Vorabentscheidungsersuchen nach Art. 267 AEUV. Effektiver Rechtsschutz nach Art. 47 GRCh."
 ),
 kostenRegeln: KostenRegeln(
   kostenerstattungSieger: true, anwaltspflicht: true,
   streitwertFormel: "Kein einheitlicher Tarif", gebuehrentabelleURL: nil, mehrwertsteuer: 0.0
 ),
 ki_hinweise: ["EU AI Act (2024) anwendbar", "DSGVO Datenschutz-Folgenabschätzung", "Whistleblower-Richtlinie"]
)

// MARK: - USA
static let US = Jurisdiktion(
 id: "US",
 name: "United States",
 flag: "nn",
 sprache: "en",
 waehrung: "USD",
 waehrungsSymbol: "$",
 gerichtssystem: Gerichtssystem(
   instanzen: ["District Court", "Circuit Court of Appeals", "U.S. Supreme Court"],
   verfassungsgericht: "U.S. Supreme Court",
   spezialgerichte: ["Bankruptcy Court", "Tax Court", "PTAB", "NLRB"],
   beschreibung: "Common Law, federal and state dual system"
 ),
 rechtsgebiete: [
   Rechtsgebiet(id: "contracts", name: "Contract Law", symbol: "doc.text",
         unterbereiche: ["Breach", "Tortious Interference", "UCC", "Arbitration"],
         typischeVerfahrensdauer: 12...60, typischeKosten: 25000...1000000, erfolgsquoteDurchschnitt: 0.51),
   Rechtsgebiet(id: "ip", name: "Intellectual Property", symbol: "lightbulb",
         unterbereiche: ["Patent", "Trademark", "Copyright", "Trade Secret"],
         typischeVerfahrensdauer: 18...84, typischeKosten: 100000...5000000, erfolgsquoteDurchschnitt: 0.47),
 ],
 fristenRegeln: FristenRegeln(
   berufungsfrist: 30, revisionsfrist: 90, widerspruchsfrist: 21,
   verjährungsfristen: ["contract": 1825, "tort": 730, "federal": 1095],
   gerichtsferien: ["Federal holidays"],
   hinweis: "Statute of Limitations varies by state and cause of action. Discovery phase critical."
 ),
 kostenRegeln: KostenRegeln(
   kostenerstattungSieger: false,
   anwaltspflicht: false,
   streitwertFormel: "Attorney's fees by agreement (contingency common)",
   gebuehrentabelleURL: nil,
   mehrwertsteuer: 0.0
 ),
 ki_hinweise: [
   "US: American Rule -- each party bears own attorney fees",
   "Discovery can take 12-24 months and dominate costs",
   "Jury trials available in federal civil cases > $20",
   "Class actions common -- FRCP Rule 23",
 ]
)

// MARK: - United Kingdom
static let UK = Jurisdiktion(
 id: "UK",
 name: "United Kingdom",
 flag: "nn",
 sprache: "en",
 waehrung: "GBP",
 waehrungsSymbol: "£",
 gerichtssystem: Gerichtssystem(
   instanzen: ["County Court / High Court", "Court of Appeal", "Supreme Court"],
   verfassungsgericht: "UK Supreme Court",
   spezialgerichte: ["Employment Tribunal", "Competition Appeal Tribunal", "Intellectual Property Enterprise Court"],
   beschreibung: "English Common Law, Civil Procedure Rules (CPR)"
 ),
 rechtsgebiete: [
   Rechtsgebiet(id: "contract", name: "Contract & Commercial", symbol: "doc.text",
         unterbereiche: ["Breach of Contract", "Misrepresentation", "TUPE", "Agency"],
         typischeVerfahrensdauer: 12...48, typischeKosten: 15000...500000, erfolgsquoteDurchschnitt: 0.53),
 ],
 fristenRegeln: FristenRegeln(
   berufungsfrist: 21, revisionsfrist: 28, widerspruchsfrist: 14,
   verjährungsfristen: ["contract": 2190, "tort": 1095, "personal_injury": 1095],
   gerichtsferien: ["Christmas", "Easter", "Summer"],
   hinweis: "Limitation Act 1980. Pre-Action Protocols mandatory. CPR Part 36 offers strategic."
 ),
 kostenRegeln: KostenRegeln(
   kostenerstattungSieger: true, anwaltspflicht: false,
   streitwertFormel: "Solicitor hourly rates + disbursements",
   gebuehrentabelleURL: nil, mehrwertsteuer: 0.20
 ),
 ki_hinweise: [
   "UK: Costs follow the event (loser pays)",
   "Part 36 offers create cost consequences",
   "Post-Brexit: UK law independent from EU law",
 ]
)

// MARK: - Frankreich
static let FR = Jurisdiktion(
 id: "FR",
 name: "Frankreich",
 flag: "nn",
 sprache: "fr",
 waehrung: "EUR",
 waehrungsSymbol: "€",
 gerichtssystem: Gerichtssystem(
   instanzen: ["TJ / TC", "CA", "Cour de cassation"],
   verfassungsgericht: "Conseil constitutionnel",
   spezialgerichte: ["Conseil d'État", "Conseil des Prud'hommes", "Tribunal de commerce"],
   beschreibung: "Code civil, Code de procédure civile"
 ),
 rechtsgebiete: [
   Rechtsgebiet(id: "contrats", name: "Droit des contrats", symbol: "doc.text",
         unterbereiche: ["Contrat de vente", "Bail commercial", "Responsabilité contractuelle"],
         typischeVerfahrensdauer: 12...48, typischeKosten: 5000...100000, erfolgsquoteDurchschnitt: 0.50),
 ],
 fristenRegeln: FristenRegeln(
   berufungsfrist: 30, revisionsfrist: 30, widerspruchsfrist: 15,
   verjährungsfristen: ["general": 1825, "delikt": 1825],
   gerichtsferien: ["Juillet-Août", "Noël"],
   hinweis: "Délais de prescription: Code civil art. 2219 ss. Médiation préalable recommandée."
 ),
 kostenRegeln: KostenRegeln(
   kostenerstattungSieger: true, anwaltspflicht: true,
   streitwertFormel: "Barème Macron (honoraires)",
   gebuehrentabelleURL: nil, mehrwertsteuer: 0.20
 ),
 ki_hinweise: [
   "FR: Principe contradictoire central",
   "Conseil d'État pour actes administratifs",
   "Code de commerce pour litiges commerciaux",
 ]
)
}

// MARK: - JurisdiktionView (UI-Auswahl-Komponente)

struct JurisdiktionPicker: View {
@Binding var selectedId: String
@ObservedObject private var appState = AppState.shared

var body: some View {
 Menu {
   ForEach(JurisdiktionRegister.alle) { jurisdiktion in
     Button {
       selectedId = jurisdiktion.id
       appState.setJurisdiction(jurisdiktion.id)
     } label: {
       HStack {
         Text(jurisdiktion.flag)
         Text(jurisdiktion.name)
         if jurisdiktion.id == selectedId {
           Image(systemName: "checkmark")
         }
       }
     }
   }
 } label: {
   HStack(spacing: 6) {
     if let j = JurisdiktionRegister.finden(id: selectedId) {
       Text(j.flag)
       Text(j.name)
         .font(.system(size: 12, weight: .medium))
     }
     Image(systemName: "chevron.down")
       .font(.caption2)
       .foregroundStyle(.secondary)
   }
 }
 .menuStyle(.borderlessButton)
}
}

// MARK: - Jurisdiktions-Infokarte

struct JurisdiktionsInfoKarte: View {
let jurisdiktionId: String

private var j: Jurisdiktion? { JurisdiktionRegister.finden(id: jurisdiktionId) }

var body: some View {
 if let j {
   GroupBox {
     VStack(alignment: .leading, spacing: 10) {
       HStack(spacing: 8) {
         Text(j.flag).font(.title2)
         VStack(alignment: .leading, spacing: 2) {
           Text(j.name).font(.headline)
           Text(j.gerichtssystem.beschreibung)
             .font(.caption)
             .foregroundStyle(.secondary)
         }
       }

       Divider()

       // Instanzen
       VStack(alignment: .leading, spacing: 4) {
         Label("Instanzen", systemImage: "building.columns")
           .font(.caption.bold())
         HStack(spacing: 4) {
           ForEach(Array(j.gerichtssystem.instanzen.enumerated()), id: \.offset) { idx, inst in
             if idx > 0 {
               Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
             }
             Text(inst).font(.caption2)
               .padding(.horizontal, 6).padding(.vertical, 2)
               .background(Color.blue.opacity(0.08), in: Capsule())
           }
         }
       }

       // Wichtige Fristen
       VStack(alignment: .leading, spacing: 4) {
         Label("Fristen", systemImage: "clock")
           .font(.caption.bold())
         HStack(spacing: 16) {
           fristBadge("Berufung", tage: j.fristenRegeln.berufungsfrist)
           fristBadge("Revision", tage: j.fristenRegeln.revisionsfrist)
           fristBadge("Widerspruch", tage: j.fristenRegeln.widerspruchsfrist)
         }
       }

       // KI-Hinweise
       if !j.ki_hinweise.isEmpty {
         Divider()
         VStack(alignment: .leading, spacing: 3) {
           Label("KI-Hinweise", systemImage: "brain")
             .font(.caption.bold())
           ForEach(j.ki_hinweise, id: \.self) { hinweis in
             HStack(alignment: .top, spacing: 4) {
               Text("(cid:127)").font(.caption2).foregroundStyle(.blue)
               Text(hinweis).font(.caption2).foregroundStyle(.secondary)
             }
           }
         }
       }
     }
     .padding(.vertical, 4)
   }
 }
}

private func fristBadge(_ name: String, tage: Int) -> some View {
 VStack(spacing: 2) {
   Text("\(tage)T")
     .font(.system(size: 13, weight: .semibold))
     .foregroundStyle(tage <= 14 ? .red : tage <= 30 ? .orange : .green)
   Text(name)
     .font(.caption2)
     .foregroundStyle(.secondary)
 }
}
}

