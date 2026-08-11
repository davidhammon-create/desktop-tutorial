import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// JURISDIKTIONEN -- Weltrecht-Kompass für grenzüberschreitende Mandate
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Kuratierte Profile: DACH · Skandinavien · USA · Japan · China.
// Jede Angabe trägt ihre Fundstelle (QuellenInfo, Art .quelle).
// Rein lokal, keine KI -- Orientierungswissen, ersetzt keine
// Rechtsberatung im Zielstaat (Hinweis wird angezeigt).
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Datenmodell

struct JurFakt: Identifiable, Hashable {
let id = UUID()
let titel: String
let text: String
let quelle: String
}

struct JurisdiktionsProfil: Identifiable, Hashable {
let id: String
let flagge: String
let name: String
let region: String
let rechtstradition: String
let gerichtssprache: String
let instanzen: String
let fakten: [JurFakt]
let warnungen: [String]
}

// MARK: - Kuratierte Wissensbasis

enum JurisdiktionenWissen {

static let alle: [JurisdiktionsProfil] = [
  JurisdiktionsProfil(
    id: "de", flagge: "nn", name: "Deutschland", region: "DACH",
    rechtstradition: "Civil Law (kodifiziert, BGB/ZPO)",
    gerichtssprache: "Deutsch (§ 184 GVG)",
    instanzen: "AG/LG -> OLG -> BGH · Verfassung: BVerfG",
    fakten: [
      JurFakt(titel: "Regelverjährung", text: "3 Jahre ab Schluss des Jahres von Entstehung und Kenntnis.", quelle: "§§ 195, 199 BGB"),
      JurFakt(titel: "Kostentragung", text: "Unterliegensprinzip -- der Verlierer trägt Gerichts- und gegnerische Anwaltskosten (RVG-Sätze).", quelle: "§ 91 ZPO"),
      JurFakt(titel: "Anwaltszwang", text: "Vor LG und höher Postulationsfähigkeit erforderlich; beim BGH Sonderzulassung.", quelle: "§ 78 ZPO"),
      JurFakt(titel: "Berufung", text: "1 Monat ab Zustellung des Urteils in vollständiger Form (Notfrist).", quelle: "§ 517 ZPO"),
      JurFakt(titel: "Elektronischer Rechtsverkehr", text: "Aktive Nutzungspflicht des beA für Anwälte.", quelle: "§ 130d ZPO"),
      JurFakt(titel: "Vollstreckung EU", text: "Titel zirkulieren ohne Exequatur in der EU.", quelle: "VO (EU) 1215/2012 (Brüssel Ia)")
    ],
    warnungen: ["Fristen sind überwiegend Notfristen -- keine Verlängerung möglich."]
  ),
  JurisdiktionsProfil(
    id: "at", flagge: "nn", name: "Österreich", region: "DACH",
    rechtstradition: "Civil Law (ABGB 1811, ZPO)",
    gerichtssprache: "Deutsch",
    instanzen: "BG/LG -> OLG -> OGH · Verfassung: VfGH",
    fakten: [
      JurFakt(titel: "Regelverjährung", text: "3 Jahre (Schadenersatz ab Kenntnis), lange Frist 30 Jahre.", quelle: "§§ 1478, 1489 ABGB"),
      JurFakt(titel: "Kostentragung", text: "Erfolgsprinzip nach Tarif (RATG).", quelle: "§§ 41 ff. ZPO (AT)"),
      JurFakt(titel: "Anwaltszwang", text: "Absoluter Anwaltszwang ab 5.000 € Streitwert vor LG.", quelle: "§ 27 ZPO (AT)"),
      JurFakt(titel: "Berufung", text: "4 Wochen ab Zustellung.", quelle: "§ 464 ZPO (AT)"),
      JurFakt(titel: "Elektronischer Rechtsverkehr", text: "webERV für Anwälte verpflichtend.", quelle: "§ 89c GOG")
    ],
    warnungen: ["Berufungsfrist 4 Wochen (nicht 1 Monat) -- abweichende Berechnung beachten."]
  ),
  JurisdiktionsProfil(
    id: "ch", flagge: "nn", name: "Schweiz", region: "DACH",
    rechtstradition: "Civil Law (OR/ZGB, eidg. ZPO 2011)",
    gerichtssprache: "Deutsch/Französisch/Italienisch je Kanton",
    instanzen: "Bezirksgericht -> Obergericht (Kanton) -> Bundesgericht",
    fakten: [
      JurFakt(titel: "Regelverjährung", text: "10 Jahre; 3 Jahre bei unerlaubter Handlung ab Kenntnis.", quelle: "Art. 127, 60 OR"),
      JurFakt(titel: "Schlichtung", text: "Obligatorisches Schlichtungsverfahren vor Klage (mit Ausnahmen).", quelle: "Art. 197 ZPO (CH)"),
      JurFakt(titel: "Kostenvorschuss", text: "Gericht kann Vorschuss in Höhe der mutmaßlichen Gerichtskosten verlangen.", quelle: "Art. 98 ZPO (CH)"),
      JurFakt(titel: "Vollstreckung Geld", text: "Eigenes Betreibungsverfahren (SchKG) statt klassischer Vollstreckung.", quelle: "SchKG"),
      JurFakt(titel: "Lugano", text: "Anerkennung/Vollstreckung im Verhältnis zur EU über Lugano-Übereinkommen.", quelle: "LugÜ 2007")
    ],
    warnungen: ["Nicht EU-Mitglied: EuGVVO gilt nicht -- Lugano-Übereinkommen prüfen.", "Fristenstillstand (Gerichtsferien) kantonal/bundesrechtlich beachten (Art. 145 ZPO)."]
  ),
  JurisdiktionsProfil(
    id: "dk", flagge: "nn", name: "Dänemark", region: "Skandinavien",
    rechtstradition: "Nordische Rechtsfamilie (Retsplejelov)",
    gerichtssprache: "Dänisch",
    instanzen: "Byret -> Landsret -> Højesteret",
    fakten: [
      JurFakt(titel: "Regelverjährung", text: "3 Jahre ab Fälligkeit/Kenntnis, absolute Grenze 10 Jahre.", quelle: "Forældelsesloven §§ 3, 6"),
      JurFakt(titel: "Kostentragung", text: "Unterliegensprinzip mit gerichtlich festgesetzten Pauschalen.", quelle: "Retsplejeloven Kap. 30"),
      JurFakt(titel: "Digitale Justiz", text: "Zivilklagen zwingend über das Portal minretssag.dk.", quelle: "Retsplejeloven § 148a"),
      JurFakt(titel: "EU-Sonderstatus", text: "Opt-out bei Justizzusammenarbeit -- Brüssel Ia gilt über Parallelabkommen.", quelle: "Abk. EG-Dänemark 2005")
    ],
    warnungen: ["Dänemark nimmt an vielen EU-Justizinstrumenten nicht teil (z. B. EuMahnVO) -- Einzelfallprüfung."]
  ),
  JurisdiktionsProfil(
    id: "se", flagge: "nn", name: "Schweden", region: "Skandinavien",
    rechtstradition: "Nordische Rechtsfamilie (Rättegångsbalk 1942)",
    gerichtssprache: "Schwedisch",
    instanzen: "Tingsrätt -> Hovrätt -> Högsta domstolen",
    fakten: [
     JurFakt(titel: "Regelverjährung", text: "10 Jahre; 3 Jahre bei Verbraucherforderungen.", quelle: "Preskriptionslag (1981:130) § 2"),
     JurFakt(titel: "Kostentragung", text: "Unterliegensprinzip, volle Erstattung angemessener Kosten.", quelle: "RB 18 kap."),
     JurFakt(titel: "Kein Anwaltszwang", text: "Parteien können sich grundsätzlich selbst vertreten.", quelle: "RB 12 kap."),
     JurFakt(titel: "Vollstreckungsbehörde", text: "Vollstreckung durch Kronofogden (Behörde), nicht durch Gerichte.", quelle: "Utsökningsbalk"),
     JurFakt(titel: "Öffentlichkeit", text: "Weitgehendes Öffentlichkeitsprinzip -- Schriftsätze sind meist öffentliche Dokumente.", quelle: "Offentlighetsprincipen, TF 2 kap.")
   ],
   warnungen: ["Öffentlichkeitsprinzip: Eingereichte Unterlagen können öffentlich einsehbar werden -- Geheimhaltungsantrag prüfen."]
 ),
 JurisdiktionsProfil(
   id: "no", flagge: "nn", name: "Norwegen", region: "Skandinavien",
   rechtstradition: "Nordische Rechtsfamilie (Tvisteloven 2005)",
   gerichtssprache: "Norwegisch",
   instanzen: "Tingrett -> Lagmannsrett -> Høyesterett",
   fakten: [
     JurFakt(titel: "Regelverjährung", text: "3 Jahre, Zusatzfrist 1 Jahr ab Kenntnis (max. 13 J.).", quelle: "Foreldelsesloven §§ 2, 10"),
     JurFakt(titel: "Schlichtungspflicht", text: "Vor Klage grundsätzlich Forliksråd (Schlichtungsrat) anrufen.", quelle: "Tvisteloven § 6-2"),
     JurFakt(titel: "Kein EU-Mitglied", text: "EWR-Staat -- Brüssel Ia gilt nicht, Lugano-Übereinkommen anwendbar.", quelle: "LugÜ 2007"),
     JurFakt(titel: "Kostentragung", text: "Unterliegensprinzip mit Angemessenheitskontrolle.", quelle: "Tvisteloven Kap. 20")
   ],
   warnungen: ["Forliksråd-Vorverfahren nicht überspringen -- Klage sonst unzulässig."]
 ),
 JurisdiktionsProfil(
   id: "fi", flagge: "nn", name: "Finnland", region: "Skandinavien",
   rechtstradition: "Nordische Rechtsfamilie (Oikeudenkäymiskaari)",
   gerichtssprache: "Finnisch/Schwedisch",
   instanzen: "Käräjäoikeus -> Hovioikeus -> Korkein oikeus",
   fakten: [
     JurFakt(titel: "Regelverjährung", text: "3 Jahre ab Kenntnis, absolute Grenze 10 Jahre.", quelle: "Laki velan vanhentumisesta 728/2003"),
     JurFakt(titel: "Kostentragung", text: "Unterliegensprinzip.", quelle: "OK 21 luku"),
     JurFakt(titel: "Rechtsmittel-Filter", text: "Berufung ans Hofgericht braucht oft Fortsetzungserlaubnis.", quelle: "OK 25a luku")
   ],
   warnungen: ["Zweisprachigkeit (fi/sv) kann Zustellungs- und Übersetzungsfragen auslösen."]
 ),
 JurisdiktionsProfil(
   id: "us", flagge: "nn", name: "USA (Federal)", region: "USA",
   rechtstradition: "Common Law · 50 Einzelstaaten + Bundesebene",
   gerichtssprache: "Englisch",
   instanzen: "District Court -> Court of Appeals (Circuit) -> Supreme Court",
   fakten: [
     JurFakt(titel: "American Rule", text: "Jede Partei trägt ihre Anwaltskosten selbst -- auch bei Sieg (Ausnahmen: Statute/Vertrag).", quelle: "Alyeska Pipeline v. Wilderness Soc., 421 U.S. 240 (1975)"),
     JurFakt(titel: "Discovery", text: "Umfassende vorprozessuale Ausforschung (Depositions, Document Requests, Interrogatories) -- enorm kosten- und geheimhaltungsrelevant.", quelle: "FRCP Rules 26-37"),
     JurFakt(titel: "Jury Trial", text: "Anspruch auf Geschworenenprozess in Zivilsachen > 20 $.", quelle: "7th Amendment"),
     JurFakt(titel: "Punitive Damages", text: "Strafschadensersatz möglich; Verhältnis zur Kompensation grob <= 9:1.", quelle: "State Farm v. Campbell, 538 U.S. 408 (2003)"),
     JurFakt(titel: "Verjährung", text: "Statutes of limitations einzelstaatlich, häufig 2-6 Jahre je Anspruchsart.", quelle: "z. B. NY CPLR § 213: 6 J. Vertrag"),
     JurFakt(titel: "Anerkennung dt. Urteile", text: "Kein Staatsvertrag -- Anerkennung nach einzelstaatlichem Recht (Uniform Foreign Money Judgments Recognition Act).", quelle: "UFMJRA / Comity")
   ],
   warnungen: ["Discovery kann deutsche Mandanten mit DSGVO kollidieren lassen -- Protective Orders verhandeln.", "Class Actions und Punitive Damages im Risikoprofil berücksichtigen."]
 ),
 JurisdiktionsProfil(
   id: "jp", flagge: "nn", name: "Japan", region: "Ostasien",
   rechtstradition: "Civil Law (Minpn 1896, dt./frz. geprägt)",
   gerichtssprache: "Japanisch (Art. 74 ZPG)",
   instanzen: "Chihn saibansho -> Kntn saibansho -> Saikn saibansho",
   fakten: [
     JurFakt(titel: "Verjährung (reformiert)", text: "5 Jahre ab Kenntnis oder 10 Jahre ab Entstehung (seit Reform 2020).", quelle: "Art. 166 Minpn n. F."),
     JurFakt(titel: "Kostentragung", text: "Gerichtskosten trägt der Verlierer; Anwaltskosten grundsätzlich jede Partei selbst.", quelle: "Art. 61 Minji soshn-hn"),
     JurFakt(titel: "Bengoshi", text: "Vertretung nur durch japanische Anwälte (bengoshi); ausländische Anwälte begrenzt als gaikokuhn jimu bengoshi.", quelle: "Bengoshi-hn; Gaiben-hn"),
     JurFakt(titel: "Vergleichskultur", text: "Gericht regt in jeder Lage Vergleich (wakai) an -- sehr hohe Vergleichsquoten.", quelle: "Art. 89 Minji soshn-hn"),
     JurFakt(titel: "Anerkennung", text: "Anerkennung ausländischer Urteile bei Gegenseitigkeit; mit Deutschland bejaht.", quelle: "Art. 118 Minji soshn-hn")
   ],
   warnungen: ["Keine US-artige Discovery -- Beweise frühzeitig selbst sichern.", "Alle Dokumente sind ins Japanische zu übersetzen (Gerichtssprache)."]
 ),
 JurisdiktionsProfil(
   id: "cn", flagge: "nn", name: "China (VR)", region: "Ostasien",
   rechtstradition: "Sozialistisches Civil Law (Zivilgesetzbuch 2021)",
   gerichtssprache: "Chinesisch",
   instanzen: "Basisgericht -> Mittleres -> Oberes Volksgericht -> OVG (SPC)",
   fakten: [
     JurFakt(titel: "Verjährung", text: "3 Jahre ab Kenntnis, absolute Grenze 20 Jahre.", quelle: "Art. 188 ZGB (VRC)"),
     JurFakt(titel: "Zwei-Instanzen-System", text: "Grundsätzlich nur eine Rechtsmittelinstanz (zweite Instanz endgültig).", quelle: "Art. 10 ZPG (VRC)"),
     JurFakt(titel: "Anwaltspflicht", text: "Kein Anwaltszwang; ausländische Kanzleien dürfen nicht vor Gericht auftreten.", quelle: "Rechtsanwaltsgesetz VRC"),
     JurFakt(titel: "Beweisregeln", text: "Notariell beglaubigte/legalisierte Auslandsbeweise erforderlich (Apostille seit 11/2023 möglich).", quelle: "SPC-Beweisregeln; Haager Apostille-Beitritt 2023"),
     JurFakt(titel: "Anerkennung", text: "Anerkennung deutscher Urteile zunehmend über Gegenseitigkeit (SPC-Leitlinien 2022) -- Einzelfallprüfung.", quelle: "SPC Conference Summary 2021/2022"),
     JurFakt(titel: "Datenexport", text: "Übermittlung von Beweisdaten ins Ausland unterliegt PIPL/DSL -- Genehmigungen nötig.", quelle: "Art. 36 DSL, Art. 41 PIPL")
   ],
   warnungen: ["Blocking-Regeln: Daten-/Beweisherausgabe an ausländische Behörden ohne Genehmigung verboten.", "Schiedsklauseln (CIETAC/HKIAC) sind häufig der sicherste Vollstreckungsweg (NY-Übereinkommen)."]
 )
]

// Grenzüberschreitende Checklisten
struct Checkliste: Identifiable {
 let id = UUID()
 let titel: String
 let symbol: String
 let punkte: [JurFakt]
}

static let checklisten: [Checkliste] = [
 Checkliste(titel: "Zustellung ins Ausland", symbol: "envelope.arrow.triangle.branch", punkte: [
   JurFakt(titel: "EU", text: "EU-Zustellungsverordnung -- Übermittlungsstellen, Fristen 1 Monat.", quelle: "VO (EU) 2020/1784"),
   JurFakt(titel: "Haager Staaten", text: "Zustellung über zentrale Behörde; USA/Japan/China sind Vertragsstaaten.", quelle: "HZÜ 1965"),
   JurFakt(titel: "China-Besonderheit", text: "Zustellung per Post nach China unzulässig (Vorbehalt) -- nur zentrale Behörde.", quelle: "HZÜ, Vorbehalt VRC"),
   JurFakt(titel: "Übersetzung", text: "Regelmäßig Übersetzung in Amtssprache des Zielstaats beifügen.", quelle: "Art. 5 Abs. 3 HZÜ")
 ]),
 Checkliste(titel: "Urkunden & Apostille", symbol: "doc.badge.ellipsis", punkte: [
   JurFakt(titel: "Apostille", text: "Ersetzt Legalisation zwischen Vertragsstaaten; China seit 7.11.2023 Mitglied.", quelle: "Haager Apostille-Übereinkommen 1961"),
   JurFakt(titel: "EU intern", text: "Bestimmte öffentliche Urkunden ohne Apostille verwendbar.", quelle: "VO (EU) 2016/1191")
 ]),
 Checkliste(titel: "Vollstreckung & Anerkennung", symbol: "checkmark.seal", punkte: [
   JurFakt(titel: "EU", text: "Unmittelbare Vollstreckbarkeit ohne Exequatur.", quelle: "VO (EU) 1215/2012"),
   JurFakt(titel: "CH/NO/IS", text: "Lugano-Übereinkommen -- Exequatur erforderlich.", quelle: "LugÜ 2007"),
   JurFakt(titel: "Schiedssprüche weltweit", text: "Vollstreckung in 170+ Staaten -- oft sicherer als Staatsurteile (USA, China, Japan).", quelle: "New Yorker Übereinkommen 1958"),
   JurFakt(titel: "Haager Urteilsübereinkommen", text: "Neues Anerkennungsregime; EU ist Vertragspartei (seit 9/2023), Beitrittsstand des Zielstaats prüfen.", quelle: "HAVÜ 2019")
 ]),
 Checkliste(titel: "Datenschutz & Beweise", symbol: "lock.shield", punkte: [
   JurFakt(titel: "DSGVO vs. Discovery", text: "US-Discovery-Herausgabe personenbezogener Daten nur mit Rechtsgrundlage -- Protective Order + Art. 49 DSGVO prüfen.", quelle: "Art. 48, 49 DSGVO; Sedona-Konferenz"),
   JurFakt(titel: "China PIPL/DSL", text: "Beweisexport aus China genehmigungspflichtig.", quelle: "Art. 36 DSL, Art. 41 PIPL"),
   JurFakt(titel: "Japan APPI", text: "Übermittlung personenbezogener Daten: Angemessenheitsbeschluss EU-Japan besteht.", quelle: "Beschluss (EU) 2019/419")
 ])
]
}

// MARK: - Hauptansicht

struct JurisdiktionenView: View {
@State private var auswahl: String = "de"
@State private var vergleich: String? = nil
@State private var zeigeChecklisten = false

private var profil: JurisdiktionsProfil {
 JurisdiktionenWissen.alle.first(where: { $0.id == auswahl }) ?? JurisdiktionenWissen.alle[0]
}
private var vergleichsProfil: JurisdiktionsProfil? {
 guard let v = vergleich else { return nil }
 return JurisdiktionenWissen.alle.first(where: { $0.id == v })
}

var body: some View {
 VStack(spacing: 0) {
   kopf
   Divider().overlay(Premium.hairline)
   if zeigeChecklisten {
     checklistenAnsicht
   } else {
     HStack(alignment: .top, spacing: 0) {
       liste
       Divider().overlay(Premium.hairline)
       ScrollView {
         HStack(alignment: .top, spacing: 14) {
           profilKarte(profil)
           if let vp = vergleichsProfil {
             profilKarte(vp)
           }
         }
         .padding(16)
       }
     }
   }
 }
 .background(Color.clear)
}

private var kopf: some View {
 HStack(spacing: 12) {
   VStack(alignment: .leading, spacing: 2) {
     HStack(spacing: 8) {
       Text("Jurisdiktionen")
         .font(.system(size: 17, weight: .bold))
         .foregroundStyle(Premium.text)
       QuellenInfo(auskunft: .quelle(
         "Kuratiertes Orientierungswissen zu 10 Rechtsordnungen -- jede Angabe trägt ihre Fundstelle (aufklappbar je Zeile)",
         fundstelle: "Lokale Wissensbasis FenlynineOS · Stand 2026 · keine KI"
       ))
     }
     Text("DACH · Skandinavien · USA · Japan · China -- Vergleich & grenzüberschreitende Checklisten")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
   }
   Spacer()

   Picker("", selection: $zeigeChecklisten) {
     Text("Profile").tag(false)
     Text("Grenzüberschreitend").tag(true)
   }
   .pickerStyle(.segmented)
   .frame(width: 240)

   if !zeigeChecklisten {
     Menu {
       Button("Kein Vergleich") { vergleich = nil }
       Divider()
       ForEach(JurisdiktionenWissen.alle.filter { $0.id != auswahl }) { p in
         Button("\(p.flagge) \(p.name)") { vergleich = p.id }
       }
     } label: {
       Label(vergleichsProfil.map { "\($0.flagge) Vergleich" } ?? "Vergleichen", systemImage: "rectangle.split.2x1")
         .font(.system(size: 11, weight: .semibold))
     }
     .menuStyle(.borderlessButton)
     .fixedSize()
   }
 }
 .padding(.horizontal, 18)
 .padding(.vertical, 12)
 .premiumGlasLeiste()
}

private var liste: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 4) {
     ForEach(["DACH", "Skandinavien", "USA", "Ostasien"], id: \.self) { region in
       Text(region.uppercased())
         .font(.system(size: 9, weight: .black))
         .kerning(0.7)
         .foregroundStyle(Premium.textFaint)
         .padding(.horizontal, 10)
         .padding(.top, 12)
       ForEach(JurisdiktionenWissen.alle.filter { $0.region == region }) { p in
         Button {
           auswahl = p.id
           if vergleich == p.id { vergleich = nil }
         } label: {
           HStack(spacing: 8) {
             Text(p.flagge).font(.system(size: 16))
             Text(p.name)
               .font(.system(size: 12.5, weight: auswahl == p.id ? .semibold : .regular))
               .foregroundStyle(auswahl == p.id ? Premium.text : Premium.textSoft)
             Spacer()
           }
           .padding(.horizontal, 10)
           .padding(.vertical, 7)
           .background(
             RoundedRectangle(cornerRadius: 8, style: .continuous)
               .fill(auswahl == p.id ? Premium.action.opacity(0.14) : Color.clear)
           )
         }
         .buttonStyle(.plain)
       }
     }
   }
   .padding(10)
 }
 .frame(width: 210)
}

private func profilKarte(_ p: JurisdiktionsProfil) -> some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack(spacing: 10) {
     Text(p.flagge).font(.system(size: 30))
     VStack(alignment: .leading, spacing: 2) {
       Text(p.name)
         .font(.system(size: 16, weight: .bold))
         .foregroundStyle(Premium.text)
       Text(p.rechtstradition)
         .font(.system(size: 11))
         .foregroundStyle(Premium.textSoft)
     }
     Spacer()
   }

   HStack(spacing: 14) {
     metaFeld("Instanzenzug", p.instanzen)
     metaFeld("Gerichtssprache", p.gerichtssprache)
   }

   Divider().overlay(Premium.hairline)

   ForEach(p.fakten) { f in
     HStack(alignment: .top, spacing: 8) {
       VStack(alignment: .leading, spacing: 2) {
         Text(f.titel.uppercased())
           .font(.system(size: 9, weight: .bold))
           .kerning(0.5)
           .foregroundStyle(Premium.textFaint)
         Text(f.text)
           .font(.system(size: 12))
           .foregroundStyle(Premium.text)
           .fixedSize(horizontal: false, vertical: true)
       }
       Spacer(minLength: 4)
       QuellenInfo(auskunft: .quelle(f.titel, fundstelle: f.quelle), groesse: 11)
     }
   }

   if !p.warnungen.isEmpty {
     Divider().overlay(Premium.hairline)
     ForEach(p.warnungen, id: \.self) { w in
       HStack(alignment: .top, spacing: 7) {
         Image(systemName: "exclamationmark.triangle.fill")
           .font(.system(size: 10))
           .foregroundStyle(Premium.proposed)
         Text(w)
           .font(.system(size: 11.5))
           .foregroundStyle(Premium.textSoft)
           .fixedSize(horizontal: false, vertical: true)
       }
     }
   }

   Text("Orientierungswissen -- ersetzt keine Beratung durch zugelassene Anwälte des Zielstaats.")
     .font(.system(size: 9.5))
     .foregroundStyle(Premium.textFaint)
 }
 .padding(16)
 .frame(maxWidth: .infinity, alignment: .leading)
 .premiumGlas(radius: Premium.rOuter, elevated: true)
}

private func metaFeld(_ titel: String, _ wert: String) -> some View {
 VStack(alignment: .leading, spacing: 2) {
   Text(titel.uppercased())
     .font(.system(size: 8.5, weight: .bold))
     .kerning(0.5)
     .foregroundStyle(Premium.textFaint)
   Text(wert)
     .font(.system(size: 11.5, weight: .medium))
     .foregroundStyle(Premium.textSoft)
     .fixedSize(horizontal: false, vertical: true)
 }
}

private var checklistenAnsicht: some View {
 ScrollView {
   LazyVGrid(columns: [GridItem(.adaptive(minimum: 340, maximum: 480), spacing: 14)], alignment: .leading, spacing: 14) {
     ForEach(JurisdiktionenWissen.checklisten) { c in
       VStack(alignment: .leading, spacing: 10) {
         HStack(spacing: 8) {
           Image(systemName: c.symbol)
             .font(.system(size: 13, weight: .semibold))
             .foregroundStyle(Premium.action)
           Text(c.titel)
             .font(.system(size: 13.5, weight: .bold))
             .foregroundStyle(Premium.text)
         }
         ForEach(c.punkte) { f in
           HStack(alignment: .top, spacing: 8) {
             Image(systemName: "checkmark.circle")
               .font(.system(size: 11))
               .foregroundStyle(Premium.computed)
               .padding(.top, 1)
             VStack(alignment: .leading, spacing: 2) {
               Text(f.titel)
                 .font(.system(size: 11.5, weight: .semibold))
                 .foregroundStyle(Premium.text)
               Text(f.text)
                 .font(.system(size: 11))
                 .foregroundStyle(Premium.textSoft)
                 .fixedSize(horizontal: false, vertical: true)
             }
             Spacer(minLength: 4)
             QuellenInfo(auskunft: .quelle(f.titel, fundstelle: f.quelle), groesse: 11)
           }
         }
       }
       .padding(16)
       .frame(maxWidth: .infinity, alignment: .leading)
       .premiumGlas(radius: Premium.rOuter)
     }
   }
   .padding(16)
 }
}
}

