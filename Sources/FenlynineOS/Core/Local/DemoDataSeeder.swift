import Foundation

// MARK: - Demo-Daten für Lexara & Strategos (Showcase für neue Nutzer)
//
// Legt beim ersten Start einen vollständig befüllten Lexara-Demo-Fall und zwei
// Strategos-Szenarien mit allen KI-Ergebnissen (Mock) an -- ohne Live-KI-Aufrufe.

enum DemoIDs {
static let folder = "demo-folder-v1"
static let lexaraCase = "demo-lexara-v1"
static let lexaraMietrecht = "demo-lexara-v2"
static let lexaraPatent = "demo-lexara-v3"
static let strategosEnterprise = "demo-strategos-enterprise-v1"
static let strategosVertrag = "demo-strategos-vertrag-v1"
static let strategosPatent = "demo-strategos-patent-v1"
static let strategosCompliance = "demo-strategos-compliance-v1"
static let judge = "demo-richter-v1"
}

enum DemoDataSeeder {

private static let versionKey = "fenlynineos_demo_seed_version"
private static let currentVersion = 4

static func seedIfNeeded() async {
  if await demoExists {
    await upgradeDemoIfNeeded()
    return
  }
  await seed()
  UserDefaults.standard.set(currentVersion, forKey: versionKey)
}

private static var demoExists: Bool {
  get async {
    (try? await Services.cases.get(id: DemoIDs.lexaraCase)) != nil
  }
}

static func seed() async {
  let now = Date()
  let cal = Calendar.current

  // nn Ordner nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
  let folder = CaseFolder(
    id: DemoIDs.folder,
    name: "Demo & Schulung",
    farbe: "purple",
    symbol: "star.fill",
    beschreibung: "Beispielfälle mit vollständigen Daten und KI-Ergebnissen -- ideal zum Erkunden von Lexara und Strategos.",
    sortierung: 0
  )
  _ = try? await Services.caseFolders.create(folder)

  // nn Richterprofil nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
  let richter = JudgeProfile(
    id: DemoIDs.judge,
    name: "Dr. Sabine König",
    gericht: "Arbeitsgericht München",
    kammer: "3. Kammer",
    fachgebiet: "Arbeitsrecht",
    klaeger_rate: 58,
    vergleich_rate: 72,
    urteil_dauer_tage: 145,
    stil: .pragmatisch,
    psycho_profil: "Sachorientiert, vergleichsaffin bei komplexen Beweislagen. Reagiert positiv auf strukturierte Klagebegründungen.",
    entscheidungsmuster: ["Bevorzugt schriftliche Beweisaufnahme", "Hohe Vergleichsbereitschaft ab 60% Prognose"],
    erfolgsquote_bei_uns: 64,
    faelle_analysiert: 12,
    rechtsgebiet: "Arbeitsrecht",
    erfahrungen: [
      .init(datum: "2024-11-08", autor: "Kanzlei", fall_kontext: "KSchG-Klage", vergleichsbereitschaft: 8, text: "Vergleich nach mündlicher Verhandlung empfohlen.")
    ]
  )
  _ = try? await Services.judgeProfiles.create(richter)

  // nn Lexara Demo-Fall nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
  let caseId = DemoIDs.lexaraCase
  let kiResult = DemoLexaraContent.kiBeraterResult
  let gegnerProfil = DemoLexaraContent.gegnerProfil

  let fall = LegalCase(
    id: caseId,
    created_at: cal.date(byAdding: .month, value: -4, to: now),
    updated_at: now,
    fallname: "[Demo] Kündigungsschutz -- Müller ./. TechVision GmbH",
    aktenzeichen: "5 Ca 1234/25",
    gericht: "Arbeitsgericht München",
    rechtsgebiet: "Arbeitsrecht",
    prozessziel: "Feststellung der Unwirksamkeit der außerordentlichen Kündigung und Fortsetzung des Arbeitsverhältnisses",
    status: .aktiv,
    instanz: .erstinstanz,
    zentrale_rechtsfrage: "War die außerordentliche Kündigung wegen Verletzung von Treuepflichten (Weitergabe von Quellcode) sozial ungerechtfertigt im Sinne des § 626 BGB?",
    prognose: 68,
    streitwert: 85_000,
    gebuehrenstufe: 1.3,
    sv_kosten: 12_400,
    reisekosten: 890,
    vergleichsangebot: 42_000,
   richter_name: "Dr. Sabine König",
   richter_klaeger_rate: 58,
   ki_berater_result: AnyCodable(kiResult),
   gegner_profil: AnyCodable(gegnerProfil),
   notes: "fenlynineos_demo_case -- Vollständiger Schulungsfall mit Mock-KI-Ergebnissen.",
   folder_id: DemoIDs.folder,
   mandant_name: "Thomas Müller"
 )
 _ = try? await Services.cases.create(fall)

 // Argumente
 for arg in DemoLexaraContent.argumente(caseId: caseId) {
   _ = try? await Services.arguments.create(arg)
 }
 for ev in DemoLexaraContent.beweise(caseId: caseId) {
   _ = try? await Services.evidence.create(ev)
 }
 for dl in DemoLexaraContent.fristen(caseId: caseId, cal: cal, now: now) {
   _ = try? await Services.deadlines.create(dl)
 }
 for doc in DemoLexaraContent.dokumente(caseId: caseId, cal: cal, now: now) {
   _ = try? await Services.documents.create(doc)
 }
 for p in DemoLexaraContent.personen(caseId: caseId) {
   _ = try? await Services.persons.create(p)
 }
 for ev in DemoLexaraContent.timeline(caseId: caseId, cal: cal, now: now) {
   _ = try? await Services.timelineEvents.create(ev)
 }
 for gv in DemoLexaraContent.gegnerVerhalten(caseId: caseId) {
   _ = try? await Services.gegnerVerhalten.create(gv)
 }
 for w in DemoLexaraContent.warnungen(caseId: caseId) {
   _ = try? await Services.caseWarnings.create(w)
 }
 for t in DemoLexaraContent.aufgaben(caseId: caseId, cal: cal, now: now) {
   _ = try? await Services.tasks.create(t)
 }
 for l in DemoLexaraContent.loopholes(caseId: caseId) {
   _ = try? await Services.legalLoopholes.create(l)
 }
 for log in DemoLexaraContent.kiProtokoll(caseId: caseId, fallname: fall.fallname) {
   _ = try? await Services.kiUsageLogs.create(log)
 }

 // nn Strategos Szenarien nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
 for szenario in DemoStrategosContent.allScenarios(lexaraCaseId: caseId, now: now) {
   _ = try? await Services.strategosScenarios.create(szenario)
 }

 await seedZusatzDemos(now: now, cal: cal)
 UserDefaults.standard.set(currentVersion, forKey: versionKey)
}

private static func seedZusatzDemos(now: Date, cal: Calendar) async {
 // Lexara Demo 2 -- Mietrecht
 if (try? await Services.cases.get(id: DemoIDs.lexaraMietrecht)) == nil {
   let fall = LegalCase(
     id: DemoIDs.lexaraMietrecht,
     created_at: cal.date(byAdding: .month, value: -2, to: now),
     updated_at: now,
     fallname: "[Demo] Mietrecht -- Weber ./. Hausverwaltung Schmidt",
     aktenzeichen: "12 S 456/25",
     gericht: "Amtsgericht München",
     rechtsgebiet: "Mietrecht",
     prozessziel: "Mietminderung wegen Schimmelbefall",
     status: .aktiv,
     prognose: 55,
     streitwert: 12_000,
     notes: "fenlynineos_demo_case",
     folder_id: DemoIDs.folder,
     mandant_name: "Familie Weber"
   )
   _ = try? await Services.cases.create(fall)
   _ = try? await Services.tasks.create(CaseTask(
     id: "demo-task-m1", case_id: DemoIDs.lexaraMietrecht,
     title: "Sachverständigengutachten Schimmel", status: .offen, priority: .hoch,
     due_date: cal.date(byAdding: .day, value: 14, to: now)
   ))
   _ = try? await Services.deadlines.create(Deadline(
     id: "demo-fr-m1", case_id: DemoIDs.lexaraMietrecht,
     title: "Klageerwiderungsfrist", frist_type: .schriftsatzfrist,
     due_date: cal.date(byAdding: .day, value: 28, to: now)!,
     side: "Gegner", status: .offen, wichtigkeit: .hoch
   ))
 }

 // Lexara Demo 3 -- Patent
 if (try? await Services.cases.get(id: DemoIDs.lexaraPatent)) == nil {
   let fall = LegalCase(
     id: DemoIDs.lexaraPatent,
     created_at: cal.date(byAdding: .month, value: -3, to: now),
     updated_at: now,
     fallname: "[Demo] Patent -- InnoLabs ./. CopyTech AG",
     aktenzeichen: "7 O 889/25",
     gericht: "Landgericht München I",
     rechtsgebiet: "Patentrecht",
     prozessziel: "Unterlassung Patentverletzung EP 3 456 789",
     status: .vorbereitung,
     prognose: 61,
     streitwert: 420_000,
     notes: "fenlynineos_demo_case",
     folder_id: DemoIDs.folder,
     mandant_name: "InnoLabs GmbH"
   )
   _ = try? await Services.cases.create(fall)
   _ = try? await Services.tasks.create(CaseTask(
     id: "demo-task-p1", case_id: DemoIDs.lexaraPatent,
     title: "FTO-Analyse aktualisieren", status: .inBearbeitung, priority: .kritisch,
     due_date: cal.date(byAdding: .day, value: 7, to: now)
   ))
 }

 // Strategos Zusatz-Szenarien
 for sz in DemoStrategosContent.zusatzSzenarien(lexaraPatentId: DemoIDs.lexaraPatent, now: now) {
   if (try? await Services.strategosScenarios.get(id: sz.id ?? "")) == nil {
     _ = try? await Services.strategosScenarios.create(sz)
   }
 }

}

/// Ergänzt Demo-Inhalte (Base44-Showcase), ohne bestehende Nutzerdaten zu löschen.
static func upgradeDemoIfNeeded() async {
 let stored = UserDefaults.standard.integer(forKey: versionKey)
 guard stored < currentVersion else { return }

 let caseId = DemoIDs.lexaraCase
 let now = Date()
 let cal = Calendar.current

 if var fall = try? await Services.cases.get(id: caseId) {
   var berater = fall.ki_berater_result?.dictValue ?? [:]
   for (key, value) in DemoLexaraContent.kiBeraterResult where berater[key] == nil {
     berater[key] = value
   }
   fall.ki_berater_result = AnyCodable(berater)

   var gp = fall.gegner_profil?.dictValue ?? [:]
   for (key, value) in DemoLexaraContent.gegnerProfil where gp[key] == nil {
     gp[key] = value
   }
   // Showcase-Daten (Simulation & Dashboard) immer auf Mock-Stand für Demo-Fall
   gp["simulation"] = DemoLexaraContent.gegnerProfil["simulation"]
   gp["strategie_dashboard"] = DemoLexaraContent.gegnerProfil["strategie_dashboard"]
   fall.gegner_profil = AnyCodable(gp)

   if fall.notes?.contains("fenlynineos_demo_case") != true {
     fall.notes = DemoLexaraContent.demoNotes
   }
   _ = try? await Services.cases.update(id: caseId, entity: fall)
 }

 if (try? await Services.arguments.listForCase(caseId: caseId))?.isEmpty != false {
   for arg in DemoLexaraContent.argumente(caseId: caseId) {
     _ = try? await Services.arguments.create(arg)
   }
 }
 if (try? await Services.evidence.listForCase(caseId: caseId))?.isEmpty != false {
   for ev in DemoLexaraContent.beweise(caseId: caseId) {
     _ = try? await Services.evidence.create(ev)
   }
 }
 if (try? await Services.deadlines.listForCase(caseId: caseId))?.isEmpty != false {
   for dl in DemoLexaraContent.fristen(caseId: caseId, cal: cal, now: now) {
     _ = try? await Services.deadlines.create(dl)
   }
 }
 if (try? await Services.documents.listForCase(caseId: caseId))?.isEmpty != false {
   for doc in DemoLexaraContent.dokumente(caseId: caseId, cal: cal, now: now) {
     _ = try? await Services.documents.create(doc)
   }
 }
 if (try? await Services.persons.listForCase(caseId: caseId))?.isEmpty != false {
   for p in DemoLexaraContent.personen(caseId: caseId) {
     _ = try? await Services.persons.create(p)
   }
 }
 if (try? await Services.timelineEvents.listForCase(caseId: caseId))?.isEmpty != false {
   for ev in DemoLexaraContent.timeline(caseId: caseId, cal: cal, now: now) {
     _ = try? await Services.timelineEvents.create(ev)
   }
 }
 if (try? await Services.gegnerVerhalten.listForCase(caseId: caseId))?.isEmpty != false {
   for gv in DemoLexaraContent.gegnerVerhalten(caseId: caseId) {
     _ = try? await Services.gegnerVerhalten.create(gv)
   }
 }
 if (try? await Services.caseWarnings.listForCase(caseId: caseId))?.isEmpty != false {
   for w in DemoLexaraContent.warnungen(caseId: caseId) {
     _ = try? await Services.caseWarnings.create(w)
   }
 }
 if (try? await Services.tasks.listForCase(caseId: caseId))?.isEmpty != false {
   for t in DemoLexaraContent.aufgaben(caseId: caseId, cal: cal, now: now) {
     _ = try? await Services.tasks.create(t)
   }
 }
 if (try? await Services.legalLoopholes.listForCase(caseId: caseId))?.isEmpty != false {
   for l in DemoLexaraContent.loopholes(caseId: caseId) {
     _ = try? await Services.legalLoopholes.create(l)
   }
 }

 let fallname = (try? await Services.cases.get(id: caseId))?.fallname ?? "[Demo] Lexara"
 let existingLogs = (try? await Services.kiUsageLogs.list())?.filter { $0.case_id == caseId } ?? []
 if existingLogs.isEmpty {
   for log in DemoLexaraContent.kiProtokoll(caseId: caseId, fallname: fallname) {
     _ = try? await Services.kiUsageLogs.create(log)
   }
 }

 if (try? await Services.strategosScenarios.list())?.contains(where: { $0.id == DemoIDs.strategosEnterprise }) != true {
   for szenario in DemoStrategosContent.allScenarios(lexaraCaseId: caseId, now: now) {
     _ = try? await Services.strategosScenarios.create(szenario)
   }
 }

 await seedZusatzDemos(now: now, cal: cal)
 UserDefaults.standard.set(currentVersion, forKey: versionKey)
}
}

// MARK: - Lexara-Inhalte

private enum DemoLexaraContent {

static let demoNotes = "fenlynineos_demo_case -- Vollständiger Schulungsfall mit Mock-KI-Ergebnissen (Base44-Showcase)."

static let kiBeraterResult: [String: Any] = [
 "rechtliche_einordnung": [
   "anspruchsgrundlagen": ["§ 626 BGB (fristlose Kündigung)", "§ 4 KSchG (Klagefrist)", "§ 102 BetrVG (BR-Anhörung)"],
   "pruefungsschema": "Verdacht -> Abmahnung -> Verhältnismäßigkeit -> Sozialwidrigkeit -> KSchG-Klagefrist",
   "gegner_gegenargumente": ["Schwerer Pflichtverstoß durch Quellcode-Weitergabe", "Vertrauensverlust irreparabel", "Abmahnung entbehrlich bei schwerem Verstoß"],
   "kritische_schwachstellen": ["Lückenhafte BR-Anhörung", "Zeitlicher Zusammenhang Kündigung « Projektabschluss fraglich"]
 ] as [String: Any],
 "issue_spotting": [
   ["risiko": "BR-Anhörung unvollständig", "kategorie": "Form", "empfehlung": "§ 102 BetrVG-Verstoß prüfen", "prioritaet": "hoch"],
   ["risiko": "Beweis Quellcode-Weitergabe indirekt", "kategorie": "Beweis", "empfehlung": "IT-Forensik-Gutachten einholen", "prioritaet": "kritisch"]
 ],
 "psychologisches_profil": [
   "big_five": ["Offenheit": 3.0, "Verträglichkeit": 2.0, "Extraversion": 8.0, "Gewissenhaftigkeit": 7.0, "Neurotizismus": 4.0] as [String: Any],
   "dark_triad": ["Machiavellismus": 7.0, "Narzissmus": 6.0, "Psychopathie": 3.0] as [String: Any],
   "trigger": "Reputationsbedrohung, Zeitdruck durch Investoren-Runde",
   "empfehlung": "CEO reagiert auf öffentlichen Druck -- kooperativer Einstieg mit harter Formrüge im Hintergrund."
 ] as [String: Any],
 "druckmittel": [
   ["titel": "Investoren-Timeline", "staerke": 8, "wie_nutzen": "Series-B-Verzögerung als Hebel für schnellen Vergleich"],
   ["titel": "Presse/Stellenabbau-Narrativ", "staerke": 6, "wie_nutzen": "Öffentlichen Druck auf Vergleich nutzen, ohne Mandant zu exponieren"]
 ],
 "strategien": [
   ["name": "Kooperativer Vergleich", "erfolg_pct": 72, "risiko": "niedrig", "beschreibung": "Abfindung 6-8 Bruttomonatsgehälter"],
   ["name": "Prozess maximieren", "erfolg_pct": 58, "risiko": "mittel", "beschreibung": "BR-Verstoß + Beweislastverteilung"],
   ["name": "Einigungsstelle", "erfolg_pct": 65, "risiko": "niedrig", "beschreibung": "Schnelle Einigung vor mündlicher Verhandlung"]
 ],
 "timing": ["naechster_schritt": "Klagefrist § 4 KSchG", "fenster": "14 Tage bis mündliche Verhandlung", "empfehlung": "Vergleichsvorschlag vor Termin"] as [String: Any],
 "informationsstrategie": [
   "sofort_offenlegen": ["Starke Argumente zu BR-Anhörung", "Formelle Mängel der Kündigung"],
   "verbergen": ["Interne E-Mails zu Projektdruck"],
   "als_bluff": ["Alternative Beschäftigungsangebote"]
 ] as [String: Any],
 "verhandlungsskript": ["eroeffnung": "Feststellung der Unwirksamkeit wegen formeller Mängel", "schlussphase": "Vergleichsbandbreite 45.000-55.000 €"] as [String: Any],
 "compliance_check": ["status": "grün", "hinweise": ["Keine Drohungen gegenüber Zeugen", "Anwaltsgeheimnis beachten"]] as [String: Any],
 "empfehlung": "Kombination aus prozessualer BR-Anhörung-Rüge und kooperativem Vergleichsangebot bei 52.000 € -- Erfolgsaussicht ca. 68%.",
 "gesamtbewertung": gesamtbewertung,
 "strategie_checkliste_schritte": strategieChecklisteSchritte,
 "prognose_vergleich": prognoseVergleich,
 "was_waere_wenn": wasWaereWenn,
 "last_minute_check": lastMinuteCheck,
 "ki_zusatz_analyse": kiZusatzAnalyse
]

static let gegnerProfil: [String: Any] = [
 "gegner_name": "TechVision GmbH",
 "gegner_branche": "Software / SaaS",
 "gegner_groesse": "120 MA, Series-B",
 "entscheider_name": "Lisa Hartmann (CEO)",
 "entscheider_persoenlichkeit": "Dominant, ergebnisorientiert, verhandlungsstark",
 "anwalt_kanzlei": "Freshfields Bruckhaus Deringer",
 "anwalt_bekannt_fuer": "Harte arbeitsrechtliche Abwehr in Tech-Sektor",
 "verhalten_taktik": "Verzögerung + Druck über Presse",
 "ziel_maximal": "Kündigung wirksam, keine Abfindung",
 "ziel_realistisch": "Vergleich unter 35.000 €",
 "ki_zusammenfassung": "TechVision (Series-B, 120 MA) führt harte Abwehr über Freshfields. CEO Hartmann: dominant, verhandlungsstark, presseaffin. Realistisches Gegnerziel: Vergleich unter 35k €. Hebel: BR-Formrüge, Investoren-Timeline, IT-Forensik.",
 "taktiken": [
   ["name": "Verzögerung", "beschreibung": "Schriftsatzfristen ausnutzen", "wirkung": "hoch"],
   ["name": "Presse-Druck", "beschreibung": "Narrativ Stellenabbau", "wirkung": "mittel"],
   ["name": "GitHub-Indizien", "beschreibung": "Quellcode als schwerer Verstoß", "wirkung": "hoch"]
 ],
 "simulation": simulation,
 "strategie_dashboard": strategieDashboard
]

private static let gesamtbewertung: [String: Any] = [
 "erfolgswahrscheinlichkeit": 68,
 "erfolgswahrscheinlichkeit_begruendung": "Starke Formangriffe (BR-Anhörung) und schwache direkte Beweise für Quellcode-Weitergabe sprechen für den Kläger.",
 "unsere_taktiken": [
   ["titel": "BR-Anhörung rügen", "beschreibung": "§ 102 BetrVG -- fehlende Unterrichtung des BR"],
   ["titel": "Beweislast Quellcode", "beschreibung": "Indizienkette durch IT-Logs schwächen"]
 ],
 "gegner_strategien": [
   ["titel": "Schwerer Vertrauensbruch", "beschreibung": "Quellcode als unersetzlicher Schaden", "gefahr": "hoch"],
   ["titel": "Presse-Druck", "beschreibung": "Narrativ Stellenabbau", "gefahr": "mittel"]
 ],
 "gegner_asse": [["titel": "Interne E-Mail Müller", "beschreibung": "Unvorsichtige Formulierung zu GitHub"]],
 "unsere_schwachstellen": [["titel": "GitHub-Aktivität", "risiko": "Indiz für Weitergabe"]],
 "gesamtstrategie": "Formangriff + Vergleich bei 52.000 € als Primärstrategie.",
 "gegner_argumente": [
   ["argument": "Schwerer Pflichtverstoß", "paragraphen": "§ 626 BGB", "staerke": "hoch", "unsere_antwort": "Beweislücke + Verhältnismäßigkeit"]
 ],
 "gegner_vorgehen": [
   ["phase": "Schriftsatz", "beschreibung": "Schwerpunkt Beweis GitHub-Logs", "risiko": "mittel"]
 ]
]

private static let strategieChecklisteSchritte: [[String: Any]] = [
 ["titel": "BR-Anhörung dokumentieren", "prinzip": "Kenntnis des Feindes", "quelle": "suntzu", "kategorie": "Form", "empfehlung": "Protokoll BR-Sitzung anfordern", "norm": "§ 102 BetrVG", "prioritaet": "kritisch", "risiko": "Formverstoß"],
 ["titel": "Vergleichsbandbreite definieren", "prinzip": "Der kluge Fürst wählt den Kampf", "quelle": "machiavelli", "kategorie": "Taktik", "empfehlung": "45-55k € kommunizieren", "norm": "§ 278 ZPO", "prioritaet": "hoch", "risiko": "Kosten"],
 ["titel": "IT-Forensik-Gutachten", "prinzip": "Stärke aus Beweis", "quelle": "suntzu", "kategorie": "Beweis", "empfehlung": "Sachverständiger beauftragen", "norm": "§ 404 ZPO", "prioritaet": "hoch", "risiko": "Beweis"],
 ["titel": "Zeugenvernehmung vorbereiten", "prinzip": "Überraschung vermeiden", "quelle": "machiavelli", "kategorie": "Prozess", "empfehlung": "CTO Schmidt als Zeuge", "norm": "§ 373 ZPO", "prioritaet": "mittel", "risiko": "Zeuge"]
]

private static let prognoseVergleich: [String: Any] = [
 "abweichungs_erklaerung": "Die algorithmische Prognose (68%) liegt über dem KI-Modell (62%), weil die Formrüge BR-Anhörung im Algorithmus stärker gewichtet wird als im KI-Kontextmodell.",
 "verlasslichste_prognose": "Algorithmus + Formangriff",
 "empfehlung": "Prognoseband 62-68% -- Vergleich ab 50.000 € sinnvoll.",
 "modelle": [
   ["name": "Algorithmus", "wert": 68, "begruendung": "Argument-/Beweis-Gewichtung"],
   ["name": "KI-Statistik", "wert": 62, "begruendung": "Branchen-Benchmark Tech-Kündigungen"],
   ["name": "Richterprofil", "wert": 58, "begruendung": "Dr. König -- Klägerquote 58%"]
 ]
]

private static let wasWaereWenn: [String: Any] = [
 "ki_analyse_text": "Optimistisch (+15%): BR-Verstoß führt zu Kündigungsunwirksamkeit. Realistisch (0%): Vergleich 52k. Pessimistisch (-25%): GitHub-Beweis überzeugt Gericht.",
 "motive_text": "TIMING: Gegner setzt auf Termindruck vor Investoren-Runde.\nFRISTEN: Klagefrist läuft -- Gegner will schnelle Einigung.\nVerdeckte Ziele: Stellenabbau ohne Abfindung.\nEmpfohlene Reaktion: Vergleichsangebot mit BR-Rüge kombinieren.",
 "prozessnotiz_zusammenfassung": "Gegner plant Schwerpunkt auf GitHub-Indizien. Konter: IT-Forensik + BR-Formrüge. Vergleichsfenster 14 Tage."
]

private static let lastMinuteCheck: [String: Any] = [
 "gefahren": [
   ["angriff": "GitHub-Commit als Beweis", "konter": "Alternativer Zugriff durch Team-Account"],
   ["angriff": "Abmahnung entbehrlich", "konter": "Verhältnismäßigkeit § 626 BGB"],
   ["angriff": "Schadenshöhe", "konter": "Kein konkreter Schaden bezifferbar"]
 ],
 "verbote": ["Emotionale Ausbrüche", "Neue Tatsachen ohne Beweis", "Drohungen"],
 "motiviation": "BR-Anhörung ist stärkster Hebel -- ruhig und strukturiert vortragen."
]

private static let kiZusatzAnalyse: [String: Any] = [
 "quelle": "demo",
 "personen_analyse": [
   [
     "name": "Dr. Sabine König", "rolle": "Richter", "organisation": "Arbeitsgericht München",
     "statistiken": ["klaeger_pct": 58, "vergleich_pct": 72, "dauer_monate": 11] as [String: Any],
     "psychologisches_profil": "Offen für Vergleich, aber nur bei substanziellem Angebot. Strukturierte Verhandlungsführung, wenig Geduld für Nebenschauplätze.",
     "verhaltenstaktik": "Fordert klare Beweisketten; reagiert positiv auf kooperative Prozessführung.",
     "prognose_einfluss": "hoch",
     "handlungsempfehlung": "Vergleichsangebot erst nach BR-Formrüge platzieren."
   ],
   [
     "name": "Lisa Hartmann", "rolle": "Gegner", "organisation": "TechVision GmbH -- CEO",
     "psychologisches_profil": "Dominant, ergebnisorientiert, presseaffin. Reagiert auf Reputationsdruck und Investoren-Timeline.",
     "verhaltenstaktik": "Ex-GF-Taktik: Verzögerung, Anwaltswechsel-Signal, Unterlagen zurückhalten.",
     "prognose_einfluss": "hoch",
     "handlungsempfehlung": "Zeitdruck über Series-B-Termine als Hebel nutzen -- ohne Mandant zu exponieren."
   ],
   [
     "name": "Markus Schmidt", "rolle": "Zeuge", "organisation": "TechVision -- CTO",
     "psychologisches_profil": "Technisch präzise, potenziell widersprüchlich zu CEO-Narrativ.",
     "verhaltenstaktik": "Kennt GitHub-Zugriffsrechte -- Schlüsselzeuge für Beweislücke.",
     "handlungsempfehlung": "Zeugenvorbereitung mit IT-Forensik abstimmen."
   ]
 ],
 "erfolgsaussichten": [
   "erfolgswahrscheinlichkeit": 68,
   "staerken": [
     ["titel": "BR-Anhörung formell fehlerhaft", "gewicht": 9, "beschreibung": "§ 102 BetrVG -- starker Formangriff"],
     ["titel": "Beweislücke Quellcode", "gewicht": 7, "beschreibung": "Kein direkter Nachweis der Weitergabe"]
   ],
   "schwaechen": [
     ["titel": "GitHub-Aktivität", "gewicht": 7, "beschreibung": "Indiz für unbefugten Zugriff"],
     ["titel": "Unvorsichtige E-Mail", "gewicht": 5, "beschreibung": "Formulierung zu GitHub-Upload"]
   ],
   "chancen_risiken_balken": [
     ["name": "Formrüge BR", "wert": 85, "typ": "chance"],
     ["name": "Vergleich 52k", "wert": 72, "typ": "chance"],
     ["name": "GitHub-Beweis", "wert": 65, "typ": "risiko"],
     ["name": "Presse-Druck", "wert": 45, "typ": "risiko"]
   ]
 ] as [String: Any],
 "wahrscheinlichkeits_verteilung": [
   "titel": "Vergleichssummen-Verteilung (€)",
   "punkte": [
     ["x": 25000, "y": 0.05], ["x": 35000, "y": 0.12], ["x": 45000, "y": 0.22],
     ["x": 52000, "y": 0.28], ["x": 60000, "y": 0.18], ["x": 75000, "y": 0.08]
   ],
   "median": 52000,
   "konfidenzintervall": [45000, 68000]
 ] as [String: Any],
 "verfahrensprognose": [
   "gesamt_dauer_monate": 14,
   "phasen": [
     ["phase": "Klageerwiderung", "datum_schaetzung": "Aug 2026", "wahrscheinlichkeit": 90, "beschreibung": "Schwerpunkt GitHub-Beweis"],
     ["phase": "Gütetermin", "datum_schaetzung": "Okt 2026", "wahrscheinlichkeit": 75, "beschreibung": "Vergleichsfenster"],
     ["phase": "Beweisaufnahme", "datum_schaetzung": "Dez 2026", "wahrscheinlichkeit": 55, "beschreibung": "IT-Forensik entscheidend"],
     ["phase": "Urteil", "datum_schaetzung": "Feb 2027", "wahrscheinlichkeit": 40, "beschreibung": "Bei fehlendem Vergleich"]
   ]
 ] as [String: Any],
 "prognose_zeitverlauf": [
   "punkte": [
     ["monat": 0, "prognose_pct": 62, "szenario": "aktuell"],
     ["monat": 2, "prognose_pct": 65, "szenario": "nach BR-Rüge"],
     ["monat": 4, "prognose_pct": 68, "szenario": "Vergleichsangebot"],
     ["monat": 6, "prognose_pct": 58, "szenario": "pessimistisch"]
   ]
 ] as [String: Any],
 "strategie_taktik_detail": [
   "psychologische_analyse": "CEO Hartmann (dominant, competitive) wird auf öffentlichen Druck und Investoren-Timeline reagieren, aber nicht auf emotionale Konfrontation. Richterin König bevorzugt strukturierte Formangriffe vor materiellen Spekulationen. Der CTO als Zeuge ist der psychologische Schwachpunkt der Gegenseite.",
   "prognose_text": "Erfolgsband 62-68%. Algorithmus gewichtet Formrüge stärker als KI-Kontextmodell. Realistisches Szenario: Vergleich bei 52.000 € nach Gütetermin. Pessimistisches Szenario (-25%): überzeugender GitHub-Beweis.",
   "handlungsvorschlaege": [
     ["prioritaet": "kritisch", "titel": "BR-Anhörung rügen", "beschreibung": "§ 102 BetrVG -- Protokoll anfordern und Formmängel dokumentieren", "erfolgsaussicht_pct": 78],
     ["prioritaet": "hoch", "titel": "IT-Forensik beauftragen", "beschreibung": "GitHub-Logs durch Sachverständigen auswerten", "erfolgsaussicht_pct": 65],
     ["prioritaet": "hoch", "titel": "Vergleichsangebot 52k", "beschreibung": "Vor mündlicher Verhandlung, kombiniert mit BR-Rüge", "erfolgsaussicht_pct": 72]
   ],
   "taktiken_matrix": [
     ["taktik": "Formrüge BR", "wirkung": 9, "risiko": 2],
     ["taktik": "Vergleich 52k", "wirkung": 7, "risiko": 3],
     ["taktik": "Presse-Druck", "wirkung": 5, "risiko": 7],
     ["taktik": "Prozess maximieren", "wirkung": 6, "risiko": 6]
   ]
 ] as [String: Any]
]

private static let simulation: [String: Any] = [
 "naechste_zuege": [
   ["zug": "Schriftsatz mit GitHub-Fokus", "wahrscheinlichkeit": 75, "verteidigung": "Forensik-Gutachten", "dringlichkeit": "hoch"],
   ["zug": "Vergleichsangebot 35k", "wahrscheinlichkeit": 60, "verteidigung": "Gegenangebot 52k", "dringlichkeit": "mittel"]
 ],
 "psycho_profil": [
   "motivation": "Series-B-Finanzierung und Investoren-Timeline",
   "risikobereitschaft": "hoch",
   "verhandlungstyp": "competitive",
   "dominanz": "hoch",
   "risikoaversion": "niedrig",
   "verhandlungsstil": "competitive",
   "schwaechen": ["Presse-Leaks", "Verzögerungstaktik"],
   "hebelpunkte": ["BR-Formrüge", "Vergleich 52k", "Zeuge CTO Schmidt"]
 ] as [String: Any],
 "top_strategie": [
   "name": "Kooperativer Vergleich",
   "beschreibung": "Abfindung 6-8 Bruttomonatsgehälter bei paralleler BR-Rüge",
   "erfolgsquote": 72,
   "massnahmen": ["BR-Rüge", "Vergleich 52k", "Zeugen CTO"]
 ] as [String: Any],
 "warnung": "Presse-Leaks möglich -- Mandant informieren."
]

private static let strategieDashboard: [String: Any] = [
 "effectiveness_matrix": [
   ["gegner_arg_title": "Schwerer Pflichtverstoß Quellcode", "evidence_title": "GitHub-Aktivitätsprotokoll", "score": 7.2, "reasoning": "Direkter Bezug möglich"],
   ["gegner_arg_title": "Vertrauensverlust", "evidence_title": "BR-Anhörungsprotokoll (fehlerhaft)", "score": 8.5, "reasoning": "Formangriff entkräftet Vertrauensnarrativ"],
   ["gegner_arg_title": "Abmahnung entbehrlich", "evidence_title": "E-Mail Projektleiter", "score": 4.5, "reasoning": "Kein direkter Beweis"]
 ],
 "counter_moves": [
   ["typ": "konter", "titel": "BR-Formrüge", "beschreibung": "§ 102 BetrVG-Verstoß geltend machen", "gegner_arg": "Schwerer Verstoß", "unsere_strategie": "Form vor Materie", "timing": "Nächster Schriftsatz", "erfolgsaussicht": 78],
   ["typ": "offensive", "titel": "Vergleichsangebot", "beschreibung": "52.000 € mit BR-Rüge", "unsere_strategie": "Zeitdruck nutzen", "timing": "Vor mündlicher Verhandlung", "erfolgsaussicht": 65]
 ],
 "hauptbedrohung": [
   "argument": "GitHub-Quellcode-Indiz",
   "grund": "Stärkstes materielles Gegenargument -- IT-Forensik erforderlich",
   "severity": "hoch"
 ] as [String: Any]
]

static func argumente(caseId: String) -> [Argument] {
 let ids = ["demo-arg-e1", "demo-arg-e2", "demo-arg-e3", "demo-arg-e4", "demo-arg-e5",
      "demo-arg-g1", "demo-arg-g2", "demo-arg-g3", "demo-arg-g4"]
 let data: [(String, Argument.ArgumentSeite, Int, Double?, String?, String?)] = [
   ("Fehlerhafte BR-Anhörung (§ 102 BetrVG)", .eigen, 9, 9.2, "Formeller Verstoß ohne vollständige Unterrichtung", "Form"),
   ("Kein schwerer Pflichtverstoß -- Quellcode nicht bewiesen", .eigen, 8, 7.8, "Beweislücke bei GitHub-Indizien", "Sach"),
   ("Verhältnismäßigkeit der Kündigung fehlt", .eigen, 7, 7.5, "Abmahnung wäre vor Kündigung geboten gewesen", "Rechts"),
   ("Projekterfolg widerlegt Leistungsmangel", .eigen, 6, 6.2, "Projekt pünktlich abgeschlossen", "Indiz"),
   ("Kündigungsschutzklage fristgerecht", .eigen, 8, 8.0, "Klage innerhalb 3-Wochen-Frist", "Prozess"),
   ("Schwerer Pflichtverstoß -- Quellcode-Weitergabe", .gegner, 7, 7.5, "GitHub-Commits als Indiz", "Sach"),
   ("Vertrauensverlust irreparabel", .gegner, 6, 6.8, "CEO-Erklärung im BR", "Psychologie"),
   ("Abmahnung bei schwerem Verstoß entbehrlich", .gegner, 5, 5.5, "§ 626 BGB -- sofortige Kündigung", "Rechts"),
   ("Wettbewerbsverstoß droht", .gegner, 4, 4.2, "Kein konkreter Schaden", "Spekulativ")
 ]
 return zip(ids, data).map { id, d in
   let evLinks: [String] = switch id {
   case "demo-arg-e1": ["demo-ev-1"]
   case "demo-arg-e2": ["demo-ev-4"]
   case "demo-arg-e4": ["demo-ev-5", "demo-ev-6"]
   case "demo-arg-g1": ["demo-ev-2"]
   case "demo-arg-g3": ["demo-ev-6"]
   default: []
   }
   return Argument(id: id, case_id: caseId, title: d.0, description: d.4, side: d.1, strength: d.2,
       ki_strength: d.3, ki_reasoning: d.4, type: d.5,
       linked_evidence_ids: evLinks.isEmpty ? nil : evLinks,
       connections: id == "demo-arg-e1" ? [.init(targetId: "demo-arg-g1", type: "konter", explanation: "Form vs. Materie", intensitaet: 8)] : nil)
 }
}

static func beweise(caseId: String) -> [Evidence] {
 [
   Evidence(id: "demo-ev-1", case_id: caseId, title: "BR-Anhörungsprotokoll", description: "Unvollständige Unterrichtung", type: .urkunde, weight: 9, ki_weight: 9.0, linked_argument_ids: ["demo-arg-e1"]),
   Evidence(id: "demo-ev-2", case_id: caseId, title: "GitHub-Aktivitätsprotokoll", description: "Commits am Kündigungstag", type: .dokument, weight: 6, ki_weight: 5.5, linked_argument_ids: ["demo-arg-g1"]),
   Evidence(id: "demo-ev-3", case_id: caseId, title: "Kündigungsschreiben", description: "Außerordentliche Kündigung 15.01.2025", type: .urkunde, weight: 8, ki_weight: 8.0),
   Evidence(id: "demo-ev-4", case_id: caseId, title: "Zeugenaussage CTO Schmidt", description: "Team-Zugriff auf Repository", type: .zeuge, weight: 7, ki_weight: 7.2, linked_argument_ids: ["demo-arg-e2"]),
   Evidence(id: "demo-ev-5", case_id: caseId, title: "Projektabschlussbericht", description: "Pünktliche Lieferung Q4/2024", type: .dokument, weight: 7, ki_weight: 7.0, linked_argument_ids: ["demo-arg-e4"]),
   Evidence(id: "demo-ev-6", case_id: caseId, title: "E-Mail Projektleiter", description: "Dank für Projektabschluss", type: .dokument, weight: 6, ki_weight: 6.5, linked_argument_ids: ["demo-arg-e4", "demo-arg-g3"])
 ]
}

static func fristen(caseId: String, cal: Calendar, now: Date) -> [Deadline] {
 [
   Deadline(id: "demo-fr-1", case_id: caseId, title: "Klagefrist § 4 KSchG", frist_type: .klagefristKSchG, paragraph: "§ 4 KSchG", due_date: cal.date(byAdding: .day, value: 12, to: now)!, side: "Wir", status: .offen, wichtigkeit: .kritisch),
   Deadline(id: "demo-fr-2", case_id: caseId, title: "Schriftsatzfrist Gegner", frist_type: .schriftsatzfrist, paragraph: "§ 276 ZPO", due_date: cal.date(byAdding: .day, value: 21, to: now)!, side: "Gegner", status: .offen, wichtigkeit: .hoch),
   Deadline(id: "demo-fr-3", case_id: caseId, title: "Mündliche Verhandlung", frist_type: .gerichtlich, due_date: cal.date(byAdding: .day, value: 45, to: now)!, side: "Gericht", status: .offen, wichtigkeit: .kritisch),
   Deadline(id: "demo-fr-4", case_id: caseId, title: "IT-Gutachten einreichen", frist_type: .intern, due_date: cal.date(byAdding: .day, value: 18, to: now)!, side: "Wir", status: .offen, wichtigkeit: .hoch),
   Deadline(id: "demo-fr-5", case_id: caseId, title: "Vergleichsgespräch", frist_type: .mandant, due_date: cal.date(byAdding: .day, value: 8, to: now)!, side: "Wir", status: .offen, wichtigkeit: .normal),
   Deadline(id: "demo-fr-6", case_id: caseId, title: "BR-Anzeige § 102", frist_type: .brAnzeige, paragraph: "§ 102 BetrVG", due_date: cal.date(byAdding: .day, value: -5, to: now)!, side: "Gegner", status: .erledigt, wichtigkeit: .hoch)
 ]
}

static func dokumente(caseId: String, cal: Calendar, now: Date) -> [LegalDocument] {
 [
   LegalDocument(id: "demo-doc-1", case_id: caseId, title: "Kündigungsschreiben TechVision", ai_summary: "Außerordentliche Kündigung wegen Quellcode-Weitergabe. Verweis auf § 626 BGB.", kategorie: .korrespondenz, datum: cal.date(byAdding: .day, value: -30, to: now), analyse_status: "analysiert"),
   LegalDocument(id: "demo-doc-2", case_id: caseId, title: "Klage KSchG", ai_summary: "Feststellungsklage Unwirksamkeit. BR-Anhörung gerügt.", kategorie: .schriftsatz, datum: cal.date(byAdding: .day, value: -14, to: now), analyse_status: "analysiert"),
   LegalDocument(id: "demo-doc-3", case_id: caseId, title: "Arbeitsvertrag Müller", ai_summary: "Senior Developer, Kündigungsfrist 3 Monate, Wettbewerbsklausel.", kategorie: .vertrag, datum: cal.date(byAdding: .year, value: -3, to: now), analyse_status: "analysiert"),
   LegalDocument(id: "demo-doc-4", case_id: caseId, title: "GitHub-Export Logs", ai_summary: "47 Commits im relevanten Zeitraum, 3 von Team-Account.", kategorie: .beweismittel, datum: cal.date(byAdding: .day, value: -7, to: now), analyse_status: "analysiert", tags: ["IT", "Beweis"])
 ]
}

static func personen(caseId: String) -> [Person] {
 [
   Person(id: "demo-p-1", case_id: caseId, name: "Dr. Sabine König", role: .richter, organisation: "Arbeitsgericht München", klaeger_rate: 58, vergleich_rate: 72, dauer_monate: 11, ki_profil: "Offen für Vergleich, aber nur bei substanziellem Angebot."),
   Person(id: "demo-p-2", case_id: caseId, name: "Thomas Müller", role: .mandant, organisation: "Kläger", email: "t.mueller@example.de"),
   Person(id: "demo-p-3", case_id: caseId, name: "Lisa Hartmann", role: .gegner, organisation: "TechVision GmbH -- CEO", notizen: "Versucht Verzögerung, hat Anwalt gewechselt", ki_profil: "Dominant, ergebnisorientiert -- reagiert auf Reputationsdruck."),
   Person(id: "demo-p-4", case_id: caseId, name: "Markus Schmidt", role: .zeuge, organisation: "TechVision -- CTO", glaubwuerdigkeit: 7, notizen: "Kennt GitHub-Zugriffsrechte"),
   Person(id: "demo-p-5", case_id: caseId, name: "Dr. Weber (Freshfields)", role: .anwalt, organisation: "Freshfields", notizen: "Gegnerische Vertretung"),
   Person(id: "demo-p-6", case_id: caseId, name: "Anna Krause", role: .zeuge, organisation: "BR-Vorsitzende TechVision")
 ]
}

static func timeline(caseId: String, cal: Calendar, now: Date) -> [TimelineEvent] {
 [
   TimelineEvent(id: "demo-tl-1", case_id: caseId, title: "Kündigung zugestellt", datum: cal.date(byAdding: .day, value: -30, to: now)!, typ: .ereignis, wichtigkeit: 9),
   TimelineEvent(id: "demo-tl-2", case_id: caseId, title: "KSchG-Klage eingereicht", datum: cal.date(byAdding: .day, value: -14, to: now)!, typ: .schriftsatz, wichtigkeit: 8),
   TimelineEvent(id: "demo-tl-3", case_id: caseId, title: "Gegnerische Klageerwiderung", datum: cal.date(byAdding: .day, value: -7, to: now)!, typ: .schriftsatz, wichtigkeit: 7),
   TimelineEvent(id: "demo-tl-4", case_id: caseId, title: "Mündliche Verhandlung", datum: cal.date(byAdding: .day, value: 45, to: now)!, typ: .hearing, wichtigkeit: 10),
   TimelineEvent(id: "demo-tl-5", case_id: caseId, title: "Vergleichsgespräch Mandant", datum: cal.date(byAdding: .day, value: 8, to: now)!, typ: .meilenstein, wichtigkeit: 6)
 ]
}

static func gegnerVerhalten(caseId: String) -> [GegnerVerhalten] {
 [
   GegnerVerhalten(id: "demo-gv-1", case_id: caseId, titel: "Vergleichsangebot 35k abgelehnt", typ: .vergleichsreaktion, datum: ISO8601DateFormatter().string(from: Date()), reaktion: .abgelehnt, unser_angebot: 52000, gegner_angebot: 35000, pattern_tag: .konzessionsbereit, auswirkung_prognose: -3),
   GegnerVerhalten(id: "demo-gv-2", case_id: caseId, titel: "Presse-Hinweis Stellenabbau", typ: .taktik, datum: ISO8601DateFormatter().string(from: Date()), pattern_tag: .druckmittel, auswirkung_prognose: -5),
   GegnerVerhalten(id: "demo-gv-3", case_id: caseId, titel: "Schriftsatzfrist-Verlängerung beantragt", typ: .prozessverhalten, datum: ISO8601DateFormatter().string(from: Date()), reaktion: .verzoegert, verzoegerung_tage: 14, pattern_tag: .verzoegerungstaktik, auswirkung_prognose: -2)
 ]
}

static func warnungen(caseId: String) -> [CaseWarning] {
 [
   CaseWarning(id: "demo-w-1", case_id: caseId, title: "KI/Manuell-Diskrepanz Argument GitHub", description: "Manuelle Stärke 6 vs. KI 5.5", severity: .mittel, warning_type: "diskrepanz", element_title: "Kein schwerer Pflichtverstoß", suggestion: "IT-Gutachten einholen"),
   CaseWarning(id: "demo-w-2", case_id: caseId, title: "Frist BR-Anzeige prüfen", description: "Formeller Angriffspunkt", severity: .hoch, warning_type: "frist", suggestion: "Protokoll anfordern"),
   CaseWarning(id: "demo-w-3", case_id: caseId, title: "Vergleich unter Streitwert", description: "Angebot 52k vs. Streitwert 85k", severity: .niedrig, warning_type: "vergleich", suggestion: "Mandantenaufklärung")
 ]
}

static func aufgaben(caseId: String, cal: Calendar, now: Date) -> [CaseTask] {
 [
   CaseTask(id: "demo-task-1", case_id: caseId, title: "IT-Forensik beauftragen", status: .inBearbeitung, priority: .hoch, due_date: cal.date(byAdding: .day, value: 10, to: now)),
   CaseTask(id: "demo-task-2", case_id: caseId, title: "Vergleichsvorschlag Mandant", status: .offen, priority: .kritisch, due_date: cal.date(byAdding: .day, value: 5, to: now)),
   CaseTask(id: "demo-task-3", case_id: caseId, title: "Zeugen CTO vorbereiten", status: .offen, priority: .mittel, due_date: cal.date(byAdding: .day, value: 20, to: now))
 ]
}

static func loopholes(caseId: String) -> [LegalLoophole] {
 [
   LegalLoophole(id: "demo-ll-1", case_id: caseId, title: "BR-Anhörung § 102 BetrVG", beschreibung: "Unvollständige Anhörung kann Kündigung unwirksam machen", rechtsgrundlage: "§ 102 BetrVG", nutzbarkeit: 9, risiko: 2, anwendungsempfehlung: "Primärer Formangriff"),
   LegalLoophole(id: "demo-ll-2", case_id: caseId, title: "Verhältnismäßigkeit § 626", beschreibung: "Abmahnung vor fristloser Kündigung", rechtsgrundlage: "§ 626 BGB", nutzbarkeit: 7, risiko: 4)
 ]
}

static func kiProtokoll(caseId: String, fallname: String) -> [KIUsageLog] {
 let fns: [(String, String)] = [
   ("KI-Berater Gegneranalyse", "Psychologisches Profil: CEO dominant, verhandlungsstark. Strategien: kooperativer Vergleich 72%, Prozess maximieren 58%."),
   ("Gegner-Strategie Dashboard", "Matrix: GitHub-Indiz vs. BR-Protokoll (Score 85). 2 Konter: BR-Formrüge, Vergleich 52k €."),
   ("Argumente -- Alle bewerten", "9 Argumente bewertet -- 5 eigen / 4 Gegner. Stärkstes eigenes: BR-Anhörung § 102 BetrVG (9/10)."),
   ("Strategie-Checkliste -- KI-Schritte", "4 KI-Schritte: BR dokumentieren, Vergleichsbandbreite 45-55k, IT-Forensik, Zeugen CTO."),
   ("Gesamtbewertung -- KI-Strategieanalyse", "Erfolgswahrscheinlichkeit 68%. Primärstrategie: Formangriff + Vergleich 52.000 €."),
   ("Prognose-Vergleich -- KI-Erklärung", "Algorithmus 68% vs. KI-Statistik 62% -- Formrüge BR stärker gewichtet."),
   ("Was-wäre-wenn -- Prozessnotiz", "Optimistisch +15%, Realistisch Vergleich 52k, Pessimistisch GitHub-Beweis."),
   ("Last-Minute-Check", "3 Gefahren identifiziert: GitHub-Commit, Abmahnung entbehrlich, Schadenshöhe."),
   ("Gegner-Profil Simulation", "Nächste Züge: Schriftsatz GitHub (75%), Vergleich 35k (60%). Top: Kooperativer Vergleich."),
   ("Monte Carlo Rechtsprechung", "Median 52.000 €, P10 35.000 €, P90 78.000 € -- Tech-Kündigungen Benchmark."),
   ("KI-Fristenerkennung", "Klagefrist § 4 KSchG in 12 Tagen -- kritisch. Schriftsatzfrist Gegner in 21 Tagen.")
 ]
 return fns.enumerated().map { i, entry in
   KIUsageLog(
     id: "demo-ki-\(i)",
     created_at: Date(),
     case_id: caseId,
     ki_function: entry.0,
     input_summary: fallname,
     output: entry.1,
     model: i % 3 == 0 ? "claude_sonnet_4_6" : (i % 3 == 1 ? "gemini_3_flash" : "gpt_5"),
     erfolg: true
   )
 }
}
}

// MARK: - Strategos-Inhalte

private enum DemoStrategosContent {

static func allScenarios(lexaraCaseId: String, now: Date) -> [StrategosScenario] {
 [enterpriseScenario(lexaraCaseId: lexaraCaseId, now: now), vertragScenario(now: now)]
}

static func zusatzSzenarien(lexaraPatentId: String, now: Date) -> [StrategosScenario] {
 [patentScenario(lexaraCaseId: lexaraPatentId, now: now), complianceScenario(now: now)]
}

static func patentScenario(lexaraCaseId: String, now: Date) -> StrategosScenario {
 let ctx: [String: Any] = [
   "unternehmen_name": "InnoLabs GmbH",
   "branche": "MedTech / Patente",
   "sachverhalt_lang": "CopyTech AG soll EP 3 456 789 verletzen. Parallel FTO-Risiko in USA.",
   "gegner_name": "CopyTech AG",
   "lexara_case_id": lexaraCaseId,
   "rechtsgebiete": ["patentrecht", "wettbewerbsrecht"]
 ]
 let sit: [String: Any] = [
   "gesamt_risiko": 6.2,
   "kritische_punkte": ["FTO USA", "Unterlassungsanspruch", "Schadenshöhe"],
   "gesamt_exposure_eur": 890_000
 ]
 return StrategosScenario(
   id: DemoIDs.strategosPatent,
   created_at: now, updated_at: now,
   titel: "[Demo] InnoLabs -- Patent & FTO",
   modus: .unternehmen,
   case_id: lexaraCaseId,
   unternehmenskontext: AnyCodable(ctx),
   situationsanalyse: AnyCodable(sit),
   aktionsplan: AnyCodable(["massnahmen": [
     ["titel": "FTO-USA abschließen", "prioritaet": 1],
     ["titel": "Unterlassungsandrohung", "prioritaet": 2]
   ]]),
   enterprise_step: 4,
   fragestellung: "Patent durchsetzen bei vertretbarem FTO-Risiko?",
   ki_analyse: AnyCodable([
     "handlungsoptionen": [
       "optionen": [
         ["name": "Unterlassung + Schadensersatz", "erfolg_pct": 61],
         ["name": "Lizenzverhandlung", "erfolg_pct": 74],
         ["name": "Design-around", "erfolg_pct": 55]
       ]
     ] as [String: Any],
     "patent_analyse": ["status": "EP aktiv", "fto": "USA prüfen"]
   ]),
   finanzdaten: AnyCodable(["exposure": 890_000, "vergleich_budget": 120_000])
 )
}

static func complianceScenario(now: Date) -> StrategosScenario {
 let ctx: [String: Any] = [
   "unternehmen_name": "MedCare Kliniken AG",
   "branche": "Gesundheitswesen",
   "sachverhalt_lang": "Datenschutzvorfall: 12.000 Patientenakten kurzzeitig offen. Behörde droht Bußgeld.",
   "rechtsgebiete": ["datenschutz_dsgvo", "compliance_ordnungswidrigkeiten"]
 ]
 return StrategosScenario(
   id: DemoIDs.strategosCompliance,
   created_at: now, updated_at: now,
   titel: "[Demo] MedCare -- DSGVO-Bußgeld",
   modus: .unternehmen,
   unternehmenskontext: AnyCodable(ctx),
   situationsanalyse: AnyCodable([
     "gesamt_risiko": 7.5,
     "kritische_punkte": ["Bußgeld bis 4%", "Reputation", "Meldepflicht"],
     "gesamt_exposure_eur": 1_200_000
   ]),
   aktionsplan: AnyCodable(["massnahmen": [
     ["titel": "DSFA nachziehen", "prioritaet": 1],
     ["titel": "Behörde informieren", "prioritaet": 2],
     ["titel": "Technische Maßnahmen", "prioritaet": 3]
   ]]),
   enterprise_step: 5,
   fragestellung: "Bußgeld minimieren und Compliance wiederherstellen?",
   ki_analyse: AnyCodable([
     "handlungsoptionen": [
       "optionen": [
         ["name": "Kooperation mit Behörde", "erfolg_pct": 68],
         ["name": "Compliance-Programm", "erfolg_pct": 72],
         ["name": "Rechtsmittel", "erfolg_pct": 40]
       ]
     ] as [String: Any],
     "quant_analyse": ["bussgeld_worst": 1_200_000, "ev_vergleich": 180_000]
   ]),
   finanzdaten: AnyCodable(["exposure": 1_200_000])
 )
}

static func enterpriseScenario(lexaraCaseId: String, now: Date) -> StrategosScenario {
 let ctx: [String: Any] = [
   "unternehmen_name": "TechVision GmbH",
   "rechtsform": "GmbH",
   "branche": "SaaS / Enterprise Software",
   "umsatz": 28_000_000,
   "mitarbeiter": 120,
   "sachverhalt_lang": "TechVision kündigt Senior Developer Müller fristlos wegen angeblicher Quellcode-Weitergabe. Parallel droht Lieferantenstreit mit CloudHost AG über SLA-Verletzungen. Series-B-Finanzierung hängt an Projektabwicklung.",
   "gegner_name": "CloudHost AG / intern HR-Konflikt",
   "gegner_rolle": "Lieferant + Arbeitsrecht",
   "rechtsgebiete": ["arbeitsrecht", "vertragsrecht_buergerliches_recht", "datenschutz_dsgvo"],
   "lexara_case_id": lexaraCaseId,
   "dokumente": [["title": "SaaS-Rahmenvertrag CloudHost", "url": "demo://doc-1"]]
 ]

 let sitAnalyse: [String: Any] = [
   "module": [
     ["rechtsgebiet": "Arbeitsrecht", "risiko_score": 7.2, "findings": ["§ 626 BGB Kündigung", "§ 102 BetrVG BR", "§ 4 KSchG Frist"], "normen": ["§ 626 BGB", "§ 102 BetrVG"], "querverbindungen": ["Datenschutz GitHub-Logs"]],
     ["rechtsgebiet": "Vertragsrecht", "risiko_score": 6.5, "findings": ["SLA-Verletzung CloudHost", "Schadensersatz droht"], "normen": ["§ 280 BGB"]],
     ["rechtsgebiet": "Datenschutz", "risiko_score": 5.8, "findings": ["GitHub personenbezogene Logs", "Art. 32 DSGVO"], "normen": ["DSGVO Art. 32"]]
   ],
   "gesamt_risiko": 6.8,
   "kritische_punkte": ["KSchG-Frist", "Series-B-Timeline", "CloudHost-Kündigungsrecht"],
   "gesamt_exposure_eur": 420_000,
   "zeitachse": [["monat": "M1", "ereignis": "Klage"], ["monat": "M3", "ereignis": "Verhandlung"], ["monat": "M6", "ereignis": "Vergleich/ Urteil"]]
 ]

 let kiAnalyse: [String: Any] = [
   "ki_briefing": "TechVision steht vor arbeitsrechtlichem Konflikt (Müller) und vertraglichem Lieferantenstreit. Gesamtexposure 420k€. Empfehlung: parallele Vergleichsstrategie.",
   "vertrags_analyse": [
     "dokument_typ": "SaaS-Rahmenvertrag",
     "klauseln": [
       ["klausel_text": "Haftungsobergrenze 500k€", "risiko_level": "mittel", "empfehlung": "Cap prüfen"],
       ["klausel_text": "Kündigung aus wichtigem Grund", "risiko_level": "hoch", "empfehlung": "Fristen dokumentieren"]
     ],
     "gesamtrisiko": "hoch"
   ] as [String: Any],
   "handlungsoptionen": handlungsoptionen,
   "ziel_zustand": "Kündigung abgewendet oder Vergleich <= 55k, CloudHost-Streit beigelegt",
   "zeitraum": "12 Monate",
   "quant_analyse": quantAnalyse,
   "umsetzungsplan": umsetzungsplan,
   "patent_analyse": ["status": "Keine Patente betroffen", "fto": "frei"]
 ]

 let matrix: [String: Any] = [
   "szenarien": [
     ["name": "Optimistisch", "chance": 75, "risiko": 25, "x": 70, "y": 30],
     ["name": "Realistisch", "chance": 62, "risiko": 45, "x": 55, "y": 50],
     ["name": "Pessimistisch", "chance": 40, "risiko": 70, "x": 35, "y": 75]
   ]
 ]

 let empfehlung: [String: Any] = [
   "machtposition": "Mittel -- Formangriffe stark, Beweislage gemischt",
   "groesste_hebel": ["BR-Anhörung", "Vergleich 52k", "CloudHost-SLA"],
   "groesste_risiken": ["GitHub-Indiz", "Presse", "Series-B-Verzögerung"],
   "grundhaltung": "Kooperativ-prozessual",
   "empfehlung_kurz": "Option B -- Vergleich + Formangriff kombinieren"
 ]

 return StrategosScenario(
   id: DemoIDs.strategosEnterprise,
   created_at: now,
   updated_at: now,
   titel: "[Demo] TechVision -- Lieferkette & Kündigung",
   modus: .unternehmen,
   case_id: lexaraCaseId,
   unternehmenskontext: AnyCodable(ctx),
   situationsanalyse: AnyCodable(sitAnalyse),
   szenario_matrix: AnyCodable(matrix),
   aktionsplan: AnyCodable(["massnahmen": [["titel": "BR-Rüge", "prioritaet": 1], ["titel": "CloudHost-Gespräch", "prioritaet": 2]]]),
   strategos_empfehlung: AnyCodable(empfehlung),
   lexara_sync: AnyCodable(["synced": true, "case_id": lexaraCaseId]),
   klausel_analyse: [
     .init(klausel_text: "Haftungsobergrenze", risiko_level: "mittel", abteilung: "Legal", finanzielle_auswirkung: 500_000, empfehlung: "Verhandeln"),
     .init(klausel_text: "Kündigungsrecht", risiko_level: "hoch", abteilung: "HR", finanzielle_auswirkung: 85_000, empfehlung: "BR prüfen")
   ],
   aktueller_schritt: 7,
   enterprise_step: 7,
   abgeschlossen: false,
   szenario_typ: "enterprise",
   rechtsgebiet: "Multi-Rechtsgebiet",
   fragestellung: "Wie minimiert TechVision das Gesamtrisiko aus Kündigung und Lieferantenstreit?",
   ausgangslage: "Series-B unter Druck, parallele Konflikte",
   status: "in_analyse",
   ki_kontext: AnyCodable(["ki_briefing": kiAnalyse["ki_briefing"] ?? ""]),
   ki_analyse: AnyCodable(kiAnalyse),
   finanzdaten: AnyCodable(["umsatz": 28_000_000, "exposure": 420_000, "vergleich_budget": 55_000])
 )
}

static func vertragScenario(now: Date) -> StrategosScenario {
 let ctx: [String: Any] = [
   "unternehmen_name": "NovaTech Solutions AG",
   "rechtsform": "AG",
   "branche": "FinTech",
   "sachverhalt_lang": "Rahmenvertrag mit PaymentProvider über 3 Jahre. Kündigungsfrist 6 Monate, SLA 99.9%, Haftungsobergrenze 2 Mio €.",
   "rechtsgebiete": ["vertragsrecht_buergerliches_recht", "compliance_ordnungswidrigkeiten"]
 ]
 return StrategosScenario(
   id: DemoIDs.strategosVertrag,
   created_at: now,
   updated_at: now,
   titel: "[Demo] NovaTech -- SaaS-Rahmenvertrag",
   modus: .vertrag,
   unternehmenskontext: AnyCodable(ctx),
   vertrag_text: "Rahmenvertrag Payment-Services zwischen NovaTech AG und PayFlow GmbH...",
   klausel_analyse: [
     .init(klausel_text: "SLA 99.9%", risiko_level: "hoch", empfehlung: "Verhandeln"),
     .init(klausel_text: "Haftung 2 Mio Cap", risiko_level: "mittel", empfehlung: "Versicherung prüfen")
   ],
   enterprise_step: 3,
   rechtsgebiet: "Vertragsrecht",
   fragestellung: "Kündigungsrisiken und Haftungsexposure?",
   ki_analyse: AnyCodable(["vertrags_analyse": ["gesamtrisiko": "mittel", "klauseln": 12]])
 )
}

private static let handlungsoptionen: [String: Any] = [
 "optionen": [
   ["name": "Formangriff + Prozess", "erfolg_pct": 58, "beschreibung": "BR-Rüge, KSchG maximieren", "juristische_vorteile": ["Starke Form"], "ist_illegal": false],
   ["name": "Vergleich 52k", "erfolg_pct": 72, "beschreibung": "Schnelle Einigung", "juristische_vorteile": ["Kostensicherheit"], "ist_illegal": false],
   ["name": "CloudHost parallel", "erfolg_pct": 65, "beschreibung": "SLA-Streit entkoppeln", "ist_illegal": false]
 ],
 "empfohlene_option": "B",
 "beguendung": "Höchster EV bei moderatem Risiko",
 "gegner_szenarien": [["reaktion": "Gegenangebot 40k"], ["reaktion": "Verzögerung"], ["reaktion": "Presse"]]
]

private static let quantAnalyse: [String: Any] = [
 "empfohlene_option": "B -- Vergleich 52k",
 "ev_vergleich": 48_000,
 "ev_prozess": 35_000,
 "monte_carlo": ["median": 52000, "p10": 35000, "p90": 78000],
 "bussgeld_worst": 0
]

private static let umsetzungsplan: [String: Any] = [
 "umsetzung_sofort": ["BR-Protokoll anfordern", "Vergleichsvorschlag 52k"],
 "umsetzung_mittelfristig": ["IT-Gutachten", "CloudHost-Gespräch"],
 "umsetzung_langfristig": ["Compliance GitHub-Policy"],
 "monitoring_indikatoren": ["Klagefrist", "Series-B-Timeline"],
 "executive_summary": "Parallele Vergleichs- und Formstrategie -- Exposure 420k auf 55k reduzierbar.",
 "lexara_checkliste": ["Argumente BR-Anhörung", "Fristen KSchG", "Gegner-Profil TechVision"]
]
}

