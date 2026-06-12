/**
 * mockData.js — Demo-Daten für den Offline-Modus
 * Realistische juristische Beispieldaten für alle Entitäten.
 */

const now = new Date();
const d = (offset) => new Date(now.getTime() + offset * 86400000).toISOString();

export const MOCK_DATA = {
  Case: [
    { id: 'case-001', fallname: 'Müller vs. Schmidt GmbH', aktenzeichen: 'LG München I – 4 O 12342/26', rechtsgebiet: 'Vertragsrecht', status: 'Aktiv', instanz: 'Erstinstanz', gericht: 'LG München I', prognose: 74, streitwert: 85000, zentrale_rechtsfrage: 'Schadensersatz wegen Lieferverzugs § 280 BGB', risiko: 'mittel', notizen: 'Wichtige Frist am 15.06.2026', created_date: d(-30), updated_date: d(-2), created_by: 'demo-user', folder_id: null },
    { id: 'case-002', fallname: 'Innovatech AG – Patentverletzung', aktenzeichen: 'OLG Frankfurt – 6 U 891/26', rechtsgebiet: 'IP-Recht', status: 'Aktiv', instanz: 'Berufung', gericht: 'OLG Frankfurt', prognose: 58, streitwert: 250000, zentrale_rechtsfrage: 'Patentverletzung EP 3 412 887 B1', risiko: 'hoch', notizen: '', created_date: d(-60), updated_date: d(-5), created_by: 'demo-user', folder_id: null },
    { id: 'case-003', fallname: 'Weber Immobilien – Mietrecht', aktenzeichen: 'AG Köln – 222 C 441/26', rechtsgebiet: 'Mietrecht', status: 'Vorbereitung', instanz: 'Erstinstanz', gericht: 'AG Köln', prognose: 82, streitwert: 12000, zentrale_rechtsfrage: 'Kündigung wegen Eigenbedarfs § 573 BGB', risiko: 'gering', notizen: 'Mandant informiert', created_date: d(-10), updated_date: d(-1), created_by: 'demo-user', folder_id: null },
    { id: 'case-004', fallname: 'Bauer – Arbeitsrecht Abfindung', aktenzeichen: 'ArbG Hamburg – 3 Ca 1122/26', rechtsgebiet: 'Arbeitsrecht', status: 'Abgeschlossen', instanz: 'Erstinstanz', gericht: 'ArbG Hamburg', prognose: 91, streitwert: 38000, zentrale_rechtsfrage: 'Abfindungsanspruch § 1a KSchG', risiko: 'gering', notizen: 'Vergleich erzielt', created_date: d(-90), updated_date: d(-3), created_by: 'demo-user', folder_id: null },
  ],

  Argument: [
    { id: 'arg-001', case_id: 'case-001', typ: 'eigen', titel: 'Vertragliche Pflichtverletzung § 280 BGB', inhalt: 'Die Beklagte hat durch den Lieferverzug von 47 Tagen ihre vertragliche Hauptpflicht verletzt. Der Schaden ist kausal auf diese Pflichtverletzung zurückzuführen.', staerke: 85, status: 'aktiv', created_date: d(-25), updated_date: d(-2), created_by: 'demo-user' },
    { id: 'arg-002', case_id: 'case-001', typ: 'eigen', titel: 'Verzugsschaden nachgewiesen', inhalt: 'Sämtliche Schadenspositionen sind durch Rechnungen und Gutachten belegt. Betriebsunterbrechungsschaden i.H.v. 62.000 € ist dokumentiert.', staerke: 78, status: 'aktiv', created_date: d(-20), updated_date: d(-3), created_by: 'demo-user' },
    { id: 'arg-003', case_id: 'case-001', typ: 'gegner', titel: 'Höhere Gewalt (Force Majeure)', inhalt: 'Die Beklagte beruft sich auf Lieferengpässe durch Covid-Nachwirkungen als höhere Gewalt.', staerke: 45, status: 'aktiv', created_date: d(-18), updated_date: d(-4), created_by: 'demo-user' },
    { id: 'arg-004', case_id: 'case-002', typ: 'eigen', titel: 'Wortsinngemäße Patentverletzung', inhalt: 'Alle Merkmale des Anspruchs 1 von EP 3 412 887 B1 sind in der angegriffenen Ausführungsform verwirklicht.', staerke: 72, status: 'aktiv', created_date: d(-50), updated_date: d(-6), created_by: 'demo-user' },
  ],

  Evidence: [
    { id: 'ev-001', case_id: 'case-001', typ: 'Dokument', bezeichnung: 'Liefervertrag vom 12.01.2026', beschreibung: 'Hauptvertrag mit Liefertermin 28.02.2026', staerke: 90, status: 'vorhanden', created_date: d(-25), updated_date: d(-5), created_by: 'demo-user' },
    { id: 'ev-002', case_id: 'case-001', typ: 'E-Mail', bezeichnung: 'Mahnung vom 15.03.2026', beschreibung: 'Erste schriftliche Mahnung mit Fristsetzung', staerke: 80, status: 'vorhanden', created_date: d(-22), updated_date: d(-5), created_by: 'demo-user' },
    { id: 'ev-003', case_id: 'case-001', typ: 'Gutachten', bezeichnung: 'Sachverständigengutachten Schadensbewertung', beschreibung: 'Unabhängiges Gutachten: Schaden 62.000 €', staerke: 88, status: 'vorhanden', created_date: d(-15), updated_date: d(-3), created_by: 'demo-user' },
    { id: 'ev-004', case_id: 'case-002', typ: 'Patent', bezeichnung: 'EP 3 412 887 B1 Registerauszug', beschreibung: 'Offizieller Registerauszug des europäischen Patents', staerke: 95, status: 'vorhanden', created_date: d(-55), updated_date: d(-7), created_by: 'demo-user' },
  ],

  Deadline: [
    { id: 'dl-001', case_id: 'case-001', bezeichnung: 'Einreichung Klageschrift', datum: d(8), typ: 'Frist', status: 'offen', erinnerung_tage: 3, created_date: d(-20), updated_date: d(-5), created_by: 'demo-user' },
    { id: 'dl-002', case_id: 'case-001', bezeichnung: 'Gütetermin LG München', datum: d(22), typ: 'Termin', status: 'offen', erinnerung_tage: 7, created_date: d(-18), updated_date: d(-4), created_by: 'demo-user' },
    { id: 'dl-003', case_id: 'case-002', bezeichnung: 'Berufungsbegründung OLG Frankfurt', datum: d(3), typ: 'Frist', status: 'offen', erinnerung_tage: 5, created_date: d(-30), updated_date: d(-2), created_by: 'demo-user' },
    { id: 'dl-004', case_id: 'case-003', bezeichnung: 'Stellungnahme Gegenseite', datum: d(-2), typ: 'Frist', status: 'überfällig', erinnerung_tage: 2, created_date: d(-15), updated_date: d(-8), created_by: 'demo-user' },
  ],

  Person: [
    { id: 'per-001', case_id: 'case-001', name: 'Dr. Klaus Müller', rolle: 'Mandant', kontakt: 'k.mueller@email.de', notizen: 'Hauptmandant, Geschäftsführer', created_date: d(-25), updated_date: d(-5), created_by: 'demo-user' },
    { id: 'per-002', case_id: 'case-001', name: 'RA Frank Becker', rolle: 'Gegenseite', kontakt: 'f.becker@kanzlei.de', notizen: 'Anwalt der Beklagten', created_date: d(-20), updated_date: d(-6), created_by: 'demo-user' },
    { id: 'per-003', case_id: 'case-001', name: 'Richter Hans Wagner', rolle: 'Richter', kontakt: '', notizen: 'Vorsitzender Richter 4. Kammer', created_date: d(-18), updated_date: d(-7), created_by: 'demo-user' },
    { id: 'per-004', case_id: 'case-002', name: 'Prof. Dr. Anna Bauer', rolle: 'Sachverständige', kontakt: 'a.bauer@tu-muenchen.de', notizen: 'Patentexpertin, TU München', created_date: d(-45), updated_date: d(-10), created_by: 'demo-user' },
  ],

  Document: [
    { id: 'doc-001', case_id: 'case-001', bezeichnung: 'Klageschrift Entwurf v3', typ: 'Schriftsatz', status: 'In Bearbeitung', datei_url: null, created_date: d(-5), updated_date: d(-1), created_by: 'demo-user' },
    { id: 'doc-002', case_id: 'case-002', bezeichnung: 'Berufungsbegründung', typ: 'Schriftsatz', status: 'Fertig', datei_url: null, created_date: d(-40), updated_date: d(-8), created_by: 'demo-user' },
  ],

  JudgeProfile: [
    { id: 'jp-001', name: 'RiLG Hans Wagner', gericht: 'LG München I', kammer: '4. Zivilkammer', rechtsgebiet: 'Vertragsrecht', stil: 'Pragmatisch', vergleichsbereitschaft: 75, entscheidungsgeschwindigkeit: 80, strenge: 60, notizen: 'Bevorzugt frühen Gütetermin. Bekannt für schnelle Entscheidungen.', created_date: d(-40), updated_date: d(-10), created_by: 'demo-user' },
    { id: 'jp-002', name: 'VRiOLG Dr. Petra Schneider', gericht: 'OLG Frankfurt', kammer: '6. Zivilsenat', rechtsgebiet: 'IP-Recht', stil: 'Streng-formal', vergleichsbereitschaft: 40, entscheidungsgeschwindigkeit: 55, strenge: 85, notizen: 'Sehr formalistisch. Schriftsätze müssen präzise sein.', created_date: d(-60), updated_date: d(-15), created_by: 'demo-user' },
  ],

  CaseFolder: [
    { id: 'cf-001', name: 'Priorität A', farbe: '#FF3B30', icon: 'star', created_date: d(-50), updated_date: d(-10), created_by: 'demo-user' },
    { id: 'cf-002', name: 'Vertragsrecht', farbe: '#007AFF', icon: 'folder', created_date: d(-40), updated_date: d(-8), created_by: 'demo-user' },
  ],

  Task: [
    { id: 'task-001', case_id: 'case-001', titel: 'Klageschrift finalisieren', beschreibung: 'Version 4 ausarbeiten und prüfen lassen', prioritaet: 'hoch', status: 'offen', faellig: d(5), created_date: d(-3), updated_date: d(-1), created_by: 'demo-user' },
    { id: 'task-002', case_id: 'case-001', titel: 'Gutachten anfordern', beschreibung: 'Prof. Meier um Ergänzungsgutachten bitten', prioritaet: 'mittel', status: 'offen', faellig: d(10), created_date: d(-2), updated_date: d(-1), created_by: 'demo-user' },
    { id: 'task-003', case_id: 'case-002', titel: 'Patentregister prüfen', beschreibung: 'Aktuellen Registerstand verifizieren', prioritaet: 'hoch', status: 'erledigt', faellig: d(-5), created_date: d(-20), updated_date: d(-5), created_by: 'demo-user' },
  ],

  TimelineEvent: [
    { id: 'te-001', case_id: 'case-001', datum: d(-45), bezeichnung: 'Vertragsabschluss', beschreibung: 'Liefervertrag unterzeichnet', typ: 'Vertragsrelevant', created_date: d(-20), updated_date: d(-5), created_by: 'demo-user' },
    { id: 'te-002', case_id: 'case-001', datum: d(-30), bezeichnung: 'Lieferverzug eingetreten', beschreibung: 'Liefertermin 28.02.2026 nicht eingehalten', typ: 'Pflichtverletzung', created_date: d(-20), updated_date: d(-5), created_by: 'demo-user' },
    { id: 'te-003', case_id: 'case-001', datum: d(-22), bezeichnung: 'Erste Mahnung', beschreibung: 'Schriftliche Mahnung mit 14-Tage-Frist', typ: 'Mahnung', created_date: d(-18), updated_date: d(-4), created_by: 'demo-user' },
  ],

  GegnerVerhalten: [
    { id: 'gv-001', case_id: 'case-001', datum: d(-20), verhalten: 'Ablehnung der Schadensersatzforderung', kategorie: 'Reaktion', bewertung: 'negativ', notizen: 'Schriftliche Ablehnung per Anwaltsschreiben', created_date: d(-18), updated_date: d(-5), created_by: 'demo-user' },
    { id: 'gv-002', case_id: 'case-001', datum: d(-10), verhalten: 'Angebot eines Teilvergleichs (30.000 €)', kategorie: 'Vergleichsangebot', bewertung: 'neutral', notizen: 'Angebot weit unter Schadenssumme', created_date: d(-9), updated_date: d(-3), created_by: 'demo-user' },
  ],

  StrategosScenario: [
    { id: 'ss-001', titel: 'Vertragsstreit – aggressive Strategie', beschreibung: 'Vollständige Klagedurchführung ohne Vergleich', rechtsgebiet: 'Vertragsrecht', status: 'In Bearbeitung', schritt: 3, erstellt: d(-15), aktualisiert: d(-2), created_date: d(-15), updated_date: d(-2), created_by: 'demo-user' },
  ],

  LegalLoophole: [
    { id: 'll-001', case_id: 'case-001', titel: '§ 254 BGB – Mitverschulden prüfen', paragraph: '§ 254 BGB', gesetz: 'BGB', beschreibung: 'Die Gegenseite könnte Mitverschulden des Klägers geltend machen. Präventiv dokumentieren, dass alle zumutbaren Schritte unternommen wurden.', gegenstrategien: ['Vollständige Schadensdokumentation', 'Nachweisen, dass keine Schadensminderungspflicht verletzt'], created_date: d(-12), updated_date: d(-3), created_by: 'demo-user' },
  ],

  AIPerformanceFeedback: [],
  KIUsageLog: [],
  CaseHistory: [],
  CaseQuestionnaire: [],
  CaseWarning: [],
  JurisdictionInsight: [],
};
