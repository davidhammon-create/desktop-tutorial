// ??? Vertragsklausel-Inventar: DL (Dienstleistung), KV (Kauf), LV (Lizenz) ???
export type ContractType = 'Dienstleistung' | 'Kauf' | 'Lizenz' | 'Sonstige';
export type ClauseClass = 1 | 2 | 3 | 4 | 5; // I=Existenziell, II=Strategisch, III=Operativ, IV=Schutz, V=Formal
export type Perspective = 'A' | 'L'; // A=Auftraggeber/Käufer/Lizenznehmer, L=Leistungserbringer/Verkäufer/Lizenzgeber
export type TrafficLight = 'green' | 'yellow' | 'red';
export interface ClauseDefinition {
  id: string;
  name: string;
  group: string;
  klpiClass: ClauseClass;
  contractType: ContractType;
  triggers: string[];
  description: string;
  problemTextRed?: string;
  problemTextYellow?: string;
}
export interface ClauseScore {
  clauseId: string;
  rawValue: string;
  score: number; // 0-100
  confidence: number; // 0-100
  trafficLight: TrafficLight;
  comment?: string;
  bewertung?: string;
  verhandlungsempfehlung?: string;
}
export interface ClauseAnalysisResult {
  contractType: ContractType;
  perspective: Perspective;
  gesamtScore: number;
  clauses: ClauseScore[];
  zusammenfassung: string;
  empfehlung: 'Unterzeichnen' | 'Nachverhandeln' | 'Ablehnen';
  kritischeKlauseln: string[];
  staerken: string[];
  schwaechen: string[];
}
export function getTrafficLight(score: number, klpiClass: ClauseClass): TrafficLight {
  if (klpiClass === 1) {
    if (score >= 60) return 'green';
    if (score >= 30) return 'yellow';
    return 'red';
  }
  if (klpiClass === 2) {
    if (score >= 50) return 'green';
    if (score >= 25) return 'yellow';
    return 'red';
  }
  if (score >= 40) return 'green';
  if (score >= 20) return 'yellow';
  return 'red';
}
export function getClassLabel(c: ClauseClass): string {
  switch (c) {
    case 1: return 'Existenziell';
    case 2: return 'Strategisch';
    case 3: return 'Operativ';
    case 4: return 'Schutz';
    case 5: return 'Formal';
  }
}
// ??????????????????????????????????????????????
// DIENSTLEISTUNGSVERTRAG (DL-01 bis DL-40)
// ??????????????????????????????????????????????
export const DL_CLAUSES: ClauseDefinition[] = [
  // Gruppe 1: Leistungsdefinition
  { id: 'DL-01', name: 'Präzision der Leistungsbeschreibung', group: 'Leistungsdefinition', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Leistungsinhalt', 'Leistungsumfang', 'Leistungsbeschreibung', 'Aufgaben', 'Leistungen umfassen', 'beauftragt mit'],
    description: 'Detailtiefe der Leistungsbeschreibung (Anlage, Aufzählung, allgemein)',
    problemTextRed: 'Die Leistungsbeschreibung ist zu unspezifisch. 71% der Verträge mit unspezifischen Leistungsbeschreibungen erlebten Nachverhandlungen (+23% Kosten, +34% Zeit).' },
  { id: 'DL-02', name: 'Ausschlussliste', group: 'Leistungsdefinition', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['nicht umfasst', 'nicht geschuldet', 'ausgeschlossen', 'nicht Gegenstand', 'ausdrücklich nicht'],
    description: 'Explizit ausgeschlossene Leistungen',
    problemTextRed: 'Kein expliziter Leistungsausschluss. 58% der Verträge ohne Ausschlussliste hatten Streit über den Leistungsumfang.' },
  { id: 'DL-03', name: 'Messbarkeit der Leistungsziele', group: 'Leistungsdefinition', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['KPI', 'Leistungskennzahl', 'Erfolgskriterium', 'messbar', 'Zielerreichung', 'Abnahmekriterium'],
    description: 'Quantitative vs. qualitative Leistungsziele',
    problemTextRed: 'Keine messbaren Leistungsziele. Abnahme basiert auf subjektiver Einschätzung. 62% Abnahmestreitigkeiten.' },
  { id: 'DL-04', name: 'Change-Request-Verfahren', group: 'Leistungsdefinition', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Änderungsanforderung', 'Change Request', 'Leistungsänderung', 'Nachtrag', 'zusätzliche Leistungen'],
    description: 'Verfahren für Leistungsänderungen (Schriftform, Frist, Kosten, Zeitplan)',
    problemTextRed: 'Kein Change-Request-Verfahren. 77% der Projekte ohne CR-Verfahren hatten ungeplante Kostensteigerungen (+31%).' },
  { id: 'DL-05', name: 'Mitwirkungspflichten des Auftraggebers', group: 'Leistungsdefinition', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Mitwirkungspflicht', 'Mitwirkung', 'zur Verfügung stellen', 'beizustellen', 'Beistellung'],
    description: 'Explizite Mitwirkungspflichten mit Rechtsfolge bei Verletzung',
    problemTextRed: 'Mitwirkungspflichten nicht definiert. 64% hatten Projektverzögerungen ohne Entlastungsmöglichkeit.' },
  // Gruppe 2: Vergütung
  { id: 'DL-06', name: 'Vergütungsmodell', group: 'Vergütung', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Vergütung', 'Honorar', 'Pauschalpreis', 'Festpreis', 'Tagessatz', 'Stundensatz', 'Erfolgshonorar'],
    description: 'Vergütungstyp: Festpreis, T&M, Mischmodell',
    problemTextRed: 'Unkontrolliertes Vergütungsmodell. 81% der T&M-Verträge ohne Cap überschritten Budget um >20%.' },
  { id: 'DL-07', name: 'Zahlungsziel', group: 'Vergütung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Zahlungsziel', 'zahlbar innerhalb', 'fällig', 'Zahlungsfrist', 'nach Rechnungseingang'],
    description: 'Frist zwischen Rechnungsstellung und Fälligkeit',
    problemTextRed: 'Zahlungsziel >60 Tage. 43% höhere Rate an Zahlungsverzögerungen, +28% Ausfallrisiko.' },
  { id: 'DL-08', name: 'Zahlungsverzugsfolgen', group: 'Vergütung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Verzugszinsen', 'Verzug', 'Mahnung', 'automatisch in Verzug', '§ 288 BGB'],
    description: 'Automatischer Verzug, Zinssatz, Inkassokosten, Leistungsverweigerungsrecht',
    problemTextRed: 'Schwache Verzugsregelung. 67% ohne automatischen Verzug hatten unbezahlte Rechnungen (>2 Mahnungen).' },
  { id: 'DL-09', name: 'Skonto-Regelung', group: 'Vergütung', klpiClass: 3, contractType: 'Dienstleistung',
    triggers: ['Skonto', 'Nachlass', 'Frühzahlerrabatt'],
    description: 'Skonto-Satz und Skonto-Frist' },
  { id: 'DL-10', name: 'Vorauszahlung/Anzahlung', group: 'Vergütung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Anzahlung', 'Vorauszahlung', 'Vorschuss', 'bei Vertragsschluss fällig'],
    description: 'Anzahlungsprozentsatz und Absicherung' },
  { id: 'DL-11', name: 'Zahlungsplan und Milestones', group: 'Vergütung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Zahlungsplan', 'Meilensteinzahlung', 'Teilzahlung', 'Abschlagsrechnung'],
    description: 'Zahlungsmeilensteine und deren Messbarkeit' },
  { id: 'DL-12', name: 'Preisanpassungsklausel', group: 'Vergütung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Preisanpassung', 'Indexanpassung', 'Tariferhöhung', 'Preissteigerung'],
    description: 'Referenzindex, max. Anpassung, Ankündigungsfrist' },
  // Gruppe 3: Laufzeit und Kündigung
  { id: 'DL-13', name: 'Vertragslaufzeit', group: 'Laufzeit & Kündigung', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Laufzeit', 'Vertragsdauer', 'befristet', 'unbefristet', 'Vertragsbeginn', 'Vertragsende'],
    description: 'Laufzeit in Monaten, befristet/unbefristet' },
  { id: 'DL-14', name: 'Automatische Verlängerung', group: 'Laufzeit & Kündigung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['automatische Verlängerung', 'verlängert sich automatisch', 'stillschweigende Verlängerung'],
    description: 'Verlängerungszeitraum und Kündigungsfrist vor Ablauf',
    problemTextRed: 'Automatische Verlängerung mit >3 Monaten Kündigungsfrist. 41% der AG verlängerten ungewollt.' },
  { id: 'DL-15', name: 'Ordentliches Kündigungsrecht', group: 'Laufzeit & Kündigung', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['ordentliche Kündigung', 'Kündigung mit Frist', 'Kündigungsfrist'],
    description: 'Symmetrie und Frist des ordentlichen Kündigungsrechts',
    problemTextRed: 'Keine ordentliche Kündigung bei Langzeitvertrag. 58% waren zu Abstandszahlungen gezwungen.' },
  { id: 'DL-16', name: 'Außerordentliches Kündigungsrecht', group: 'Laufzeit & Kündigung', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['außerordentliche Kündigung', 'fristlose Kündigung', 'wichtiger Grund', 'sofortige Kündigung'],
    description: 'Spezifizierte Kündigungsgründe (Pflichtverstoß, Insolvenz, Verzug, etc.)',
    problemTextRed: 'Unspezifiziertes Kündigungsrecht. 52% der fristlosen Kündigungen mündeten in Rechtsstreitigkeiten.' },
  { id: 'DL-17', name: 'Rechtsfolgen bei Kündigung', group: 'Laufzeit & Kündigung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['bei Kündigung', 'im Falle der Kündigung', 'Vergütung bei vorzeitiger Beendigung'],
    description: 'Vergütung, Rückgabe, Übergabe, Übergangsunterstützung' },
  // Gruppe 4: Haftung & Gewährleistung
  { id: 'DL-18', name: 'Haftungsmaximum', group: 'Haftung', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Haftungsbeschränkung', 'Haftungsdeckel', 'Haftungsmaximum', 'maximale Haftung'],
    description: 'Haftungsdeckel als Absolutbetrag oder % des Vertragswertes',
    problemTextRed: 'Keine Haftungsbeschränkung. 78% hatten Haftungsrisiken über dem Vertragsvolumen.' },
  { id: 'DL-19', name: 'Haftungsausschluss Folgeschäden', group: 'Haftung', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Folgeschäden', 'mittelbare Schäden', 'entgangener Gewinn', 'indirekte Schäden'],
    description: 'Ausschluss von Folge-/mittelbaren Schäden',
    problemTextRed: 'Keine Regelung zu Folgeschäden. 71% der Haftungsfälle über Vertragswert waren Folgeschäden.' },
  { id: 'DL-20', name: 'Haftung bei leichter Fahrlässigkeit', group: 'Haftung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['leichte Fahrlässigkeit', 'einfache Fahrlässigkeit', 'nur bei Vorsatz und grober Fahrlässigkeit'],
    description: 'Fahrlässigkeitsmaßstab' },
  { id: 'DL-21', name: 'Gewährleistungsfrist', group: 'Haftung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Gewährleistung', 'Mängelgewährleistung', 'Gewährleistungsfrist', 'Mängelhaftung'],
    description: 'Gewährleistungsfrist in Monaten (gesetzlich: 24 Monate)' },
  { id: 'DL-22', name: 'Nachbesserungsrecht', group: 'Haftung', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Nachbesserung', 'Nacherfüllung', 'Mangelbeseitigung', 'Recht zur Nachbesserung'],
    description: 'Vorrang, Anzahl Versuche, Frist' },
  // Gruppe 5: Vertragsstrafen
  { id: 'DL-23', name: 'Terminpönale', group: 'Vertragsstrafen', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Vertragsstrafe', 'Pönale', 'Konventionalstrafe', 'Verzugsstrafe'],
    description: 'Pönalsatz, Bezugsbasis, Deckel, Anrechenbarkeit',
    problemTextRed: 'Keine Terminpönale. 63% hatten Terminüberschreitungen (+28% der Vertragslaufzeit).' },
  { id: 'DL-24', name: 'Leistungsqualitätspönale', group: 'Vertragsstrafen', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Qualitätspönale', 'SLA-Pönale', 'bei Unterschreitung', 'KPI-Unterschreitung'],
    description: 'Bezugsmetrik, Schwellenwert, Pönalsatz, Cap' },
  { id: 'DL-25', name: 'Gegenseitige Vertragsstrafe', group: 'Vertragsstrafen', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['gegenseitige Vertragsstrafe', 'beidseitige Pönale'],
    description: 'Symmetrie: Pönale für beide Parteien oder einseitig' },
  // Gruppe 6: Abnahme
  { id: 'DL-26', name: 'Abnahmeverfahren', group: 'Abnahme', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Abnahme', 'Abnahmeverfahren', 'Abnahmeprotokoll', 'förmliche Abnahme'],
    description: 'Formales Verfahren, Frist, fiktive Abnahme, Mängelrüge',
    problemTextRed: 'Kein definiertes Abnahmeverfahren. 73% hatten Streitigkeiten über den Leistungsnachweis.' },
  { id: 'DL-27', name: 'Teilabnahmen', group: 'Abnahme', klpiClass: 3, contractType: 'Dienstleistung',
    triggers: ['Teilabnahme', 'Meilensteinabnahme', 'Zwischenabnahme'],
    description: 'Regelung von Teilabnahmen' },
  { id: 'DL-28', name: 'Reaktionspflicht bei Mängelrüge', group: 'Abnahme', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Reaktionspflicht', 'Reaktionsfrist', 'Frist zur Mangelbeseitigung'],
    description: 'Reaktionsfrist und Erledigungsfrist' },
  // Gruppe 7: Geistiges Eigentum
  { id: 'DL-29', name: 'Eigentumsübergang Arbeitsergebnisse', group: 'Geistiges Eigentum', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Eigentumsübergang', 'geht auf den Auftraggeber über', 'Nutzungsrechte übertragen', 'Urheberrecht'],
    description: 'Rechteübertragung: vollständig, exklusiv, einfach, Lizenz',
    problemTextRed: 'Keine klare Rechteübertragung. 44% erlebten Nutzungsbeschränkungen bei Weiterentwicklung.' },
  { id: 'DL-30', name: 'Source Code Escrow', group: 'Geistiges Eigentum', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Source Code Escrow', 'Quellcode-Hinterlegung', 'Escrow', 'bei Insolvenz des Dienstleisters'],
    description: 'Escrow-Klausel mit Treuhänder und Auslösebedingungen' },
  { id: 'DL-31', name: 'IP-Freistellung', group: 'Geistiges Eigentum', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['frei von Rechten Dritter', 'Freistellung', 'Schadloshaltung', 'IP-Verletzung'],
    description: 'Zusicherung + Freistellungsverpflichtung' },
  // Gruppe 8: Vertraulichkeit
  { id: 'DL-32', name: 'Geheimhaltungsvereinbarung', group: 'Vertraulichkeit', klpiClass: 2, contractType: 'Dienstleistung',
    triggers: ['Geheimhaltung', 'vertraulich', 'NDA', 'Verschwiegenheit'],
    description: 'Laufzeit, Definition, Ausnahmen, Konsequenzen, Rückgabepflicht' },
  { id: 'DL-33', name: 'Datenschutz und AVV', group: 'Vertraulichkeit', klpiClass: 1, contractType: 'Dienstleistung',
    triggers: ['Datenschutz', 'DSGVO', 'Auftragsverarbeitung', 'personenbezogene Daten', 'AVV'],
    description: 'AVV bei personenbezogenen Daten',
    problemTextRed: 'Fehlender AVV bei Datenverarbeitung. Bußgeldrisiko nach Art. 83 DSGVO bis 10 Mio. € oder 2% Jahresumsatz.' },
  { id: 'DL-34', name: 'Referenzrecht', group: 'Vertraulichkeit', klpiClass: 3, contractType: 'Dienstleistung',
    triggers: ['Referenz', 'Referenzprojekt', 'Nennung als Referenz'],
    description: 'Referenznutzung: zustimmungspflichtig oder automatisch' },
  // Gruppe 9: Formale Klauseln
  { id: 'DL-35', name: 'Gerichtsstand', group: 'Formales', klpiClass: 5, contractType: 'Dienstleistung',
    triggers: ['Gerichtsstand', 'ausschließlicher Gerichtsstand', 'Zuständigkeit'],
    description: 'Eigener Sitz, neutraler Ort, Gegenseite' },
  { id: 'DL-36', name: 'Schiedsklausel', group: 'Formales', klpiClass: 5, contractType: 'Dienstleistung',
    triggers: ['Schiedsgericht', 'Schiedsklausel', 'Schiedsverfahren', 'DIS', 'ICC'],
    description: 'Schiedsordnung, -ort, Anzahl Schiedsrichter' },
  { id: 'DL-37', name: 'Schriftformerfordernis', group: 'Formales', klpiClass: 4, contractType: 'Dienstleistung',
    triggers: ['Schriftform', 'Textform', 'Änderungen bedürfen der Schriftform'],
    description: 'Einfach, doppelt, E-Mail-Wirksamkeit' },
  { id: 'DL-38', name: 'Salvatorische Klausel', group: 'Formales', klpiClass: 5, contractType: 'Dienstleistung',
    triggers: ['salvatorische Klausel', 'Teilnichtigkeit', 'unwirksam oder nichtig'],
    description: 'Vorhanden/nicht vorhanden' },
  { id: 'DL-39', name: 'Vollständigkeitsvermerk', group: 'Formales', klpiClass: 5, contractType: 'Dienstleistung',
    triggers: ['gesamte Vereinbarung', 'vollständige Regelung', 'keine mündlichen Nebenabreden'],
    description: 'Vorhanden/nicht vorhanden' },
  { id: 'DL-40', name: 'Versicherungspflicht', group: 'Formales', klpiClass: 4, contractType: 'Dienstleistung',
    triggers: ['Berufshaftpflicht', 'Betriebshaftpflicht', 'Haftpflichtversicherung', 'Versicherungspflicht'],
    description: 'Mindestdeckungssumme, Nachweispflicht' },
];
// ??????????????????????????????????????????????
// KAUFVERTRAG (KV-01 bis KV-34)
// ??????????????????????????????????????????????
export const KV_CLAUSES: ClauseDefinition[] = [
  // Gruppe 1: Kaufgegenstand
  { id: 'KV-01', name: 'Warenbeschreibung und Spezifikation', group: 'Kaufgegenstand', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Kaufgegenstand', 'Ware', 'Produkt', 'Spezifikation', 'technische Beschreibung'],
    description: 'Detailtiefe: Technische Spezifikation, Katalognummer, allgemein',
    problemTextRed: 'Unzureichende Warenbeschreibung. 69% hatten Streit über Mangelfreiheit.' },
  { id: 'KV-02', name: 'Normkonformität und Zertifizierungen', group: 'Kaufgegenstand', klpiClass: 2, contractType: 'Kauf',
    triggers: ['DIN', 'EN', 'ISO', 'CE-Konformität', 'Zertifizierung', 'Prüfzeichen'],
    description: 'Normen, Zertifikate, Nachweispflicht' },
  { id: 'KV-03', name: 'Beschaffenheitsgarantie', group: 'Kaufgegenstand', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Beschaffenheitsgarantie', 'garantiert', 'zusichert', 'zugesicherte Eigenschaft'],
    description: 'Explizite Garantien über gesetzliche Mängelhaftung hinaus' },
  { id: 'KV-04', name: 'Muster und Referenzlieferung', group: 'Kaufgegenstand', klpiClass: 3, contractType: 'Kauf',
    triggers: ['Muster', 'Referenzmuster', 'Erstmuster', 'Bemusterung'],
    description: 'Musterpflicht vor Serienlieferung' },
  // Gruppe 2: Preis, Zahlung, Incoterms
  { id: 'KV-05', name: 'Preisfestlegung und Preisbasis', group: 'Preis & Zahlung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Kaufpreis', 'Preis', 'Entgelt', 'netto', 'zzgl. MwSt', 'Gesamtpreis'],
    description: 'Fest/variabel, MwSt-Behandlung, Nebenkosten' },
  { id: 'KV-06', name: 'Preisgleitklausel', group: 'Preis & Zahlung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Preisgleitung', 'Rohstoffpreisanpassung', 'Indexanpassung', 'Metallpreisklausel'],
    description: 'Referenzindex, Formel, Deckel' },
  { id: 'KV-07', name: 'Zahlungsziel', group: 'Preis & Zahlung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Zahlungsziel', 'zahlbar innerhalb', 'fällig', 'Zahlungsfrist'],
    description: 'Frist in Tagen, Standard im Kaufrecht: 0-30 Tage' },
  { id: 'KV-08', name: 'Eigentumsvorbehalt', group: 'Preis & Zahlung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Eigentumsvorbehalt', 'Eigentumsübergang', 'Eigentum verbleibt', 'bis zur vollständigen Zahlung'],
    description: 'Einfach, verlängert, erweitert',
    problemTextRed: 'Kein Eigentumsvorbehalt. 83% der Lieferanten konnten in Insolvenzfällen Forderungen nicht realisieren.' },  { id: 'KV-09', name: 'Incoterms und Lieferkonditionen', group: 'Preis & Zahlung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Incoterms', 'EXW', 'FCA', 'CPT', 'CIP', 'DAP', 'DDP', 'FOB', 'CIF', 'Gefahrübergang'],
    description: 'Lieferklausel, Gefahrübergang, Transportversicherung' },
  { id: 'KV-10', name: 'Transportversicherung', group: 'Preis & Zahlung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Transportversicherung', 'Warenversicherung', 'Versicherungspflicht'],
    description: 'Wer schließt ab, Umfang' },
  // Gruppe 3: Lieferung
  { id: 'KV-11', name: 'Liefertermin und Lieferfrist', group: 'Lieferung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Liefertermin', 'Lieferfrist', 'Lieferdatum', 'spätestens am', 'Lieferzeit'],
    description: 'Verbindlich/unverbindlich, Datum/Frist',
    problemTextRed: 'Kein verbindlicher Liefertermin. 58% hatten Lieferverzögerungen ohne Konsequenzen.' },
  { id: 'KV-12', name: 'Teillieferungen', group: 'Lieferung', klpiClass: 3, contractType: 'Kauf',
    triggers: ['Teillieferung', 'Teilmenge', 'Teilsendung', 'Einzelabrufe'],
    description: 'Zulässig/unzulässig, separate Rechnungsstellung' },
  { id: 'KV-13', name: 'Lieferpönale', group: 'Lieferung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Vertragsstrafe', 'Pönale', 'Konventionalstrafe', 'bei Lieferverzug'],
    description: 'Pönalsatz, Bezugsbasis, Deckel bei Lieferverzug' },
  { id: 'KV-14', name: 'Wareneingangsprüfung/Rügeobliegenheit', group: 'Lieferung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Wareneingangsprüfung', 'Rügeobliegenheit', 'unverzüglich rügen', '§ 377 HGB'],
    description: 'Rügefrist in Tagen, Abweichung von § 377 HGB',
    problemTextRed: 'Strenge Rügeobliegenheit. 47% der Käufer verloren Mängelrechte durch Fristversäumnis.' },
  // Gruppe 4: Gewährleistung
  { id: 'KV-15', name: 'Gewährleistungsfrist', group: 'Gewährleistung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Gewährleistung', 'Mängelgewährleistung', 'Gewährleistungsfrist'],
    description: 'Frist in Monaten (gesetzlich: 24 Monate)' },
  { id: 'KV-16', name: 'Sachmängelrechte-Reihenfolge', group: 'Gewährleistung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Nacherfüllung', 'Ersatzlieferung', 'Rücktritt', 'Minderung', 'Reihenfolge der Mängelrechte'],
    description: 'Vorrang Nacherfüllung, Anzahl Versuche' },
  { id: 'KV-17', name: 'Aufwendungsersatz bei Mängeln', group: 'Gewährleistung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Aufwendungsersatz', 'Ein- und Ausbaukosten', 'Montagekosten'],
    description: 'Ein-/Ausbaukosten bei bereits eingebauten Teilen' },
  // Gruppe 5: Haftung
  { id: 'KV-18', name: 'Haftungsmaximum', group: 'Haftung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Haftungsbeschränkung', 'Haftungsdeckel', 'maximale Haftung'],
    description: 'Haftungsdeckel als Absolutbetrag oder % des Kaufpreises' },
  { id: 'KV-19', name: 'Haftungsausschluss Folgeschäden', group: 'Haftung', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Folgeschäden', 'mittelbare Schäden', 'entgangener Gewinn'],
    description: 'Ausschluss von Folge-/mittelbaren Schäden' },
  { id: 'KV-20', name: 'Haftung bei Fahrlässigkeit', group: 'Haftung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['leichte Fahrlässigkeit', 'nur bei Vorsatz und grober Fahrlässigkeit'],
    description: 'Fahrlässigkeitsmaßstab' },
  { id: 'KV-21', name: 'Nachbesserungsrecht Kauf', group: 'Haftung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Nachbesserung', 'Nacherfüllung', 'Mangelbeseitigung'],
    description: 'Vorrang, Versuche, Frist' },
  { id: 'KV-22', name: 'Verbrauchsgüterkauf-Prüfung', group: 'Haftung', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Verbraucher', 'Endkunde', 'Privatperson', 'B2C'],
    description: 'B2C-Prüfung: Haftungsbeschränkungen ggf. unwirksam' },
  // Gruppe 6: Force Majeure
  { id: 'KV-23', name: 'Force-Majeure-Klausel', group: 'Force Majeure', klpiClass: 2, contractType: 'Kauf',
    triggers: ['höhere Gewalt', 'Force Majeure', 'außerhalb der Kontrolle', 'Pandemie'],
    description: 'Ereignisliste, Anzeigepflicht, Rechtsfolgen, Zeitlimit' },
  { id: 'KV-24', name: 'Lieferschwierigkeits-Eskalation', group: 'Force Majeure', klpiClass: 2, contractType: 'Kauf',
    triggers: ['Lieferschwierigkeit', 'Engpass', 'Allokation', 'Versorgungsengpass'],
    description: 'Allokationsrecht, Informationspflicht, Priorisierung' },
  // Gruppe 7: Gefahrübergang
  { id: 'KV-25', name: 'Gefahrübergang', group: 'Gefahrübergang', klpiClass: 1, contractType: 'Kauf',
    triggers: ['Gefahrübergang', 'Gefahr geht über', 'Sachgefahr', 'ab Lieferung'],
    description: 'Bei Übergabe, Versand, Ankunft' },
  { id: 'KV-26', name: 'Warenkreditversicherung', group: 'Gefahrübergang', klpiClass: 4, contractType: 'Kauf',
    triggers: ['Bonitätsprüfung', 'Kreditlimit', 'Akkreditiv', 'Bankgarantie'],
    description: 'Sicherungsinstrumente für Zahlungseingang' },
  // Gruppe 8: Formales
  { id: 'KV-27', name: 'AGB-Vorrang', group: 'Formales', klpiClass: 2, contractType: 'Kauf',
    triggers: ['AGB', 'Einkaufsbedingungen', 'Lieferbedingungen', 'ausschließlich unsere AGB'],
    description: 'AGB-Geltung, Kollisionsregel',
    problemTextRed: 'AGB beider Parteien ohne Kollisionsregel. 68% hatten Streit über anwendbares Recht.' },
  { id: 'KV-28', name: 'Kaufmännisches Bestätigungsschreiben', group: 'Formales', klpiClass: 3, contractType: 'Kauf',
    triggers: ['kaufmännisches Bestätigungsschreiben', 'Auftragsbestätigung', 'Schweigen gilt als'],
    description: 'Schweigen als Zustimmung' },
  { id: 'KV-29', name: 'Gerichtsstand (Kauf)', group: 'Formales', klpiClass: 5, contractType: 'Kauf',
    triggers: ['Gerichtsstand', 'ausschließlicher Gerichtsstand'],
    description: 'Eigener Sitz, neutraler Ort, Gegenseite' },
  { id: 'KV-30', name: 'Schiedsklausel (Kauf)', group: 'Formales', klpiClass: 5, contractType: 'Kauf',
    triggers: ['Schiedsgericht', 'Schiedsklausel'],
    description: 'Schiedsordnung, Schiedsort' },
  { id: 'KV-31', name: 'Schriftformerfordernis (Kauf)', group: 'Formales', klpiClass: 4, contractType: 'Kauf',
    triggers: ['Schriftform', 'Textform'],
    description: 'Einfach, doppelt, E-Mail' },
  { id: 'KV-32', name: 'Salvatorische Klausel (Kauf)', group: 'Formales', klpiClass: 5, contractType: 'Kauf',
    triggers: ['salvatorische Klausel', 'Teilnichtigkeit'],
    description: 'Vorhanden/nicht vorhanden' },
  { id: 'KV-33', name: 'Vollständigkeitsvermerk (Kauf)', group: 'Formales', klpiClass: 5, contractType: 'Kauf',
    triggers: ['gesamte Vereinbarung', 'keine mündlichen Nebenabreden'],
    description: 'Vorhanden/nicht vorhanden' },
  { id: 'KV-34', name: 'Versicherungspflicht (Kauf)', group: 'Formales', klpiClass: 4, contractType: 'Kauf',
    triggers: ['Produkthaftpflicht', 'Haftpflichtversicherung', 'Versicherungspflicht'],
    description: 'Mindestdeckung, Nachweispflicht' },
];
// ??????????????????????????????????????????????
// LIZENZVERTRAG (LV-01 bis LV-34)
// ??????????????????????????????????????????????
export const LV_CLAUSES: ClauseDefinition[] = [
  // Gruppe 1: Rechteeinräumung
  { id: 'LV-01', name: 'Definition des Schutzgegenstands', group: 'Lizenzgegenstand', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Schutzrecht', 'Patent', 'Marke', 'Urheberrecht', 'Software', 'Know-how', 'Lizenzgegenstand'],
    description: 'Schutzrechtstyp, Registernummer, Status, Territorium',
    problemTextRed: 'Unspezifischer Lizenzgegenstand. 62% der Lizenzstreitigkeiten durch unklare Schutzrechtsdefinitionen.' },
  { id: 'LV-02', name: 'Lizenztyp und Exklusivität', group: 'Lizenzgegenstand', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['ausschließliche Lizenz', 'exklusive Lizenz', 'nicht-ausschließliche Lizenz', 'einfache Lizenz'],
    description: 'Ausschließlich, alleinig, nicht-ausschließlich' },
  { id: 'LV-03', name: 'Territoriale Beschränkung', group: 'Lizenzgegenstand', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['beschränkt auf', 'Territorium', 'Gebiet', 'weltweit', 'territoriale Einschränkung'],
    description: 'Weltweit, Europa, DACH, Deutschland, regional' },
  { id: 'LV-04', name: 'Sachliche Beschränkung (Field of Use)', group: 'Lizenzgegenstand', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Field of Use', 'Nutzungsbereich', 'Anwendungsbereich', 'beschränkt auf den Einsatz'],
    description: 'Branchenbeschränkung, Nutzungsfeldeinschränkung' },
  { id: 'LV-05', name: 'Unterlizenzierungsrecht', group: 'Lizenzgegenstand', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Unterlizenz', 'Sublizenz', 'Unterlizenzierung'],
    description: 'Erlaubt/verboten, mit/ohne Genehmigung, verbundene Unternehmen' },
  { id: 'LV-06', name: 'Übertragungsrecht', group: 'Lizenzgegenstand', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Übertragung der Lizenz', 'Abtretung', 'Change of Control'],
    description: 'Übertragbar bei M&A, mit/ohne Genehmigung',
    problemTextRed: 'Lizenz nicht übertragbar. 33% der Übernahmen hatten Lizenzprobleme.' },
  // Gruppe 2: Lizenzgebühren
  { id: 'LV-07', name: 'Lizenzgebühren-Modell', group: 'Lizenzgebühren', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Lizenzgebühr', 'Royalty', 'Lizenzentgelt', 'Einmalzahlung', 'umsatzabhängig', 'stückbezogen'],
    description: 'Einmal, laufend umsatzabhängig, stückbezogen, Kombination' },
  { id: 'LV-08', name: 'Royalty-Satz und Berechnungsbasis', group: 'Lizenzgebühren', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Royalty', 'Lizenzrate', 'Prozent vom Nettoumsatz', '% des Nettoerlöses'],
    description: 'Satz in %, Basis (Nettoumsatz, Listenpreis, Gewinn)' },
  { id: 'LV-09', name: 'Mindestlizenzgebühr', group: 'Lizenzgebühren', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Mindestlizenzgebühr', 'Minimum Royalty', 'Mindestgarantie'],
    description: 'Mindestbetrag p.a., Konsequenz bei Nicht-Erreichung' },
  { id: 'LV-10', name: 'Abrechnung und Reporting', group: 'Lizenzgebühren', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Abrechnung', 'Royalty-Report', 'Lizenzabrechnung', 'Verkaufsberichte'],
    description: 'Periode, Frist, Inhaltsvorgaben' },
  { id: 'LV-11', name: 'Audit-Recht', group: 'Lizenzgebühren', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Audit', 'Prüfungsrecht', 'Buchprüfung', 'Wirtschaftsprüfer'],
    description: 'Häufigkeit, Ankündigungsfrist, Kostenwechsel',
    problemTextRed: 'Kein Prüfungsrecht. 38% der Audits deckten Unterzahlungen von ? 12% auf.' },
  // Gruppe 3: Schutzrechtspflege
  { id: 'LV-12', name: 'Pflicht zur Schutzrechtspflege', group: 'Schutzrechtspflege', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Schutzrechtspflege', 'Aufrechterhaltung', 'Annuitäten', 'Erneuerungsgebühren'],
    description: 'Pflegeverantwortung, Informationspflicht bei Erlöschen',
    problemTextRed: 'Keine Schutzrechtspflege-Regelung. 7% der Patente erloschen durch Pflegefehler.' },
  { id: 'LV-13', name: 'Rechtsbestandsgarantie', group: 'Schutzrechtspflege', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Rechtsbestand', 'gültig und durchsetzbar', 'keine Nichtigkeitsgründe'],
    description: 'Garantie der Gültigkeit und Durchsetzbarkeit',
    problemTextRed: 'Keine Rechtsbestandsgarantie. 3-5% der Patente werden nach Erteilung für nichtig erklärt.' },
  { id: 'LV-14', name: 'Drittangriffe auf das Schutzrecht', group: 'Schutzrechtspflege', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Nichtigkeitsklage', 'Löschungsantrag', 'Verteidigung des Schutzrechts'],
    description: 'Verteidigungspflicht, Kostentragung' },
  { id: 'LV-15', name: 'Drittrechtsverletzungen durch Dritte', group: 'Schutzrechtspflege', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Verletzung durch Dritte', 'Durchsetzung gegen Dritte'],
    description: 'Pflicht zur Durchsetzung gegen Verletzer' },
  // Gruppe 4: Gewährleistung & Haftung
  { id: 'LV-16', name: 'Freistellung von Drittansprüchen', group: 'Haftung Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Freistellung', 'Schadloshaltung', 'Indemnifikation'],
    description: 'Indemnifikation mit Verteidigungsübernahme und Kostentragung',
    problemTextRed: 'Keine Freistellung. 8% der Lizenznehmer konfrontiert mit IP-Klagen.' },
  { id: 'LV-17', name: 'Nutzungsgarantie', group: 'Haftung Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['ruhige Nutzung', 'ungestörte Nutzung', 'Nicht-Störungs-Verpflichtung'],
    description: 'Garantie keine weiteren Lizenzen, Nicht-Störung' },
  { id: 'LV-18', name: 'Haftungsmaximum (Lizenz)', group: 'Haftung Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Haftungsbeschränkung', 'Haftungsdeckel', 'maximale Haftung'],
    description: 'Haftungsdeckel für Lizenzvertrag' },
  { id: 'LV-19', name: 'As-is-Klausel', group: 'Haftung Lizenz', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['as is', 'wie besehen', 'ohne Gewähr', 'Gewährleistungsausschluss'],
    description: 'Ausschluss der Tauglichkeitsgewähr' },
  { id: 'LV-20', name: 'Folgeschäden Lizenz', group: 'Haftung Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Folgeschäden', 'mittelbare Schäden', 'entgangener Gewinn'],
    description: 'Ausschluss von Folgeschäden' },
  // Gruppe 5: Laufzeit & Beendigung
  { id: 'LV-21', name: 'Lizenzdauer', group: 'Laufzeit Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Lizenzdauer', 'Lizenzlaufzeit', 'unbefristet', 'für die Dauer des Schutzrechts'],
    description: 'Unbefristet (Schutzdauer), befristet, Verlängerungsoption' },
  { id: 'LV-22', name: 'Außerordentliches Kündigungsrecht (Lizenz)', group: 'Laufzeit Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['außerordentliche Kündigung', 'fristlose Kündigung', 'wichtiger Grund'],
    description: 'Mindestgebühr-Unterschreitung, Insolvenz, Patentverletzung' },
  { id: 'LV-23', name: 'Rechtsfolgen bei Vertragsende', group: 'Laufzeit Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['nach Vertragsende', 'bei Beendigung', 'Lizenz erlischt', 'Lagerbestände'],
    description: 'Bestandsschutz für laufende Projekte/Lagerbestände' },
  // Gruppe 6: Weiterentwicklung
  { id: 'LV-24', name: 'Grant-Back (Verbesserungen LN)', group: 'Weiterentwicklung', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Grant-Back', 'Verbesserungserfindung', 'Weiterentwicklung', 'Rücklizenz'],
    description: 'Kein Grant-Back, nicht-exklusiv, exklusiv, entgeltlich',
    problemTextRed: 'Exklusive Grant-Back-Klausel. Fehlanreiz für F&E, wettbewerbsrechtlich problematisch.' },
  { id: 'LV-25', name: 'Verbesserungen des Lizenzgebers', group: 'Weiterentwicklung', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Updates', 'neue Versionen', 'Weiterentwicklungen', 'Verbesserungspatente'],
    description: 'Automatischer Einschluss oder neue Vereinbarung' },
  // Gruppe 7: Formales & Compliance
  { id: 'LV-26', name: 'Exportkontrolle und Sanktionen', group: 'Compliance Lizenz', klpiClass: 4, contractType: 'Lizenz',
    triggers: ['Exportkontrolle', 'EAR', 'ITAR', 'Sanktionen', 'Dual-Use'],
    description: 'Exportkontrollrechtliche Compliance' },
  { id: 'LV-27', name: 'Geheimhaltung Know-how', group: 'Compliance Lizenz', klpiClass: 1, contractType: 'Lizenz',
    triggers: ['Geheimhaltung', 'vertraulich', 'Know-how', 'Betriebsgeheimnis'],
    description: 'Bei Know-how-Lizenzen: Klasse I (einziges Schutzinstrument)' },
  { id: 'LV-28', name: 'Datenschutz Lizenz', group: 'Compliance Lizenz', klpiClass: 2, contractType: 'Lizenz',
    triggers: ['Datenschutz', 'DSGVO', 'personenbezogene Daten'],
    description: 'Datenschutz bei Software-/Technologielizenzen' },
  { id: 'LV-29', name: 'Gerichtsstand (Lizenz)', group: 'Formales Lizenz', klpiClass: 5, contractType: 'Lizenz',
    triggers: ['Gerichtsstand', 'ausschließlicher Gerichtsstand'],
    description: 'Eigener Sitz, neutraler Ort, Gegenseite' },
  { id: 'LV-30', name: 'Schiedsklausel (Lizenz)', group: 'Formales Lizenz', klpiClass: 5, contractType: 'Lizenz',
    triggers: ['Schiedsgericht', 'Schiedsklausel'],
    description: 'Schiedsordnung, Schiedsort' },
  { id: 'LV-31', name: 'Schriftform (Lizenz)', group: 'Formales Lizenz', klpiClass: 4, contractType: 'Lizenz',
    triggers: ['Schriftform', 'Textform'],
    description: 'Einfach, doppelt, E-Mail' },
  { id: 'LV-32', name: 'Salvatorische Klausel (Lizenz)', group: 'Formales Lizenz', klpiClass: 5, contractType: 'Lizenz',
    triggers: ['salvatorische Klausel', 'Teilnichtigkeit'],
    description: 'Vorhanden/nicht vorhanden' },
  { id: 'LV-33', name: 'Vollständigkeit (Lizenz)', group: 'Formales Lizenz', klpiClass: 5, contractType: 'Lizenz',
    triggers: ['gesamte Vereinbarung', 'keine mündlichen Nebenabreden'],
    description: 'Vorhanden/nicht vorhanden' },
  { id: 'LV-34', name: 'Versicherungspflicht (Lizenz)', group: 'Formales Lizenz', klpiClass: 4, contractType: 'Lizenz',
    triggers: ['Haftpflichtversicherung', 'Versicherungspflicht', 'Produkthaftpflicht'],
    description: 'Mindestdeckung, Nachweispflicht' },
];
// ??????????????????????????????????????????????
// Hilfsfunktionen
// ??????????????????????????????????????????????
export function getClausesForType(type: ContractType): ClauseDefinition[] {
  switch (type) {
    case 'Dienstleistung': return DL_CLAUSES;
    case 'Kauf': return KV_CLAUSES;
    case 'Lizenz': return LV_CLAUSES;
    default: return [...DL_CLAUSES, ...KV_CLAUSES, ...LV_CLAUSES];
  }
}
export function getAllClauses(): ClauseDefinition[] {
  return [...DL_CLAUSES, ...KV_CLAUSES, ...LV_CLAUSES];
}
export function getClauseById(id: string): ClauseDefinition | undefined {
  return getAllClauses().find(c => c.id === id);
}
export function groupClausesByGroup(clauses: ClauseScore[], definitions: ClauseDefinition[]): Record<string, { clauses: (ClauseScore & { def: ClauseDefinition })[]; avgScore: number }> {
  const groups: Record<string, (ClauseScore & { def: ClauseDefinition })[]> = {};
  for (const cs of clauses) {
    const def = definitions.find(d => d.id === cs.clauseId);
    if (!def) continue;
    if (!groups[def.group]) groups[def.group] = [];
    groups[def.group].push({ ...cs, def });
  }
  const result: Record<string, { clauses: (ClauseScore & { def: ClauseDefinition })[]; avgScore: number }> = {};
  for (const [group, items] of Object.entries(groups)) {
    const avg = items.reduce((s, c) => s + c.score, 0) / items.length;
    result[group] = { clauses: items, avgScore: Math.round(avg) };
  }
  return result;
}
export function computeGesamtScore(clauses: ClauseScore[], definitions: ClauseDefinition[]): number {
  if (!clauses.length) return 0;
  let weightedSum = 0;
  let totalWeight = 0;
  for (const cs of clauses) {
    const def = definitions.find(d => d.id === cs.clauseId);
    if (!def) continue;
    const weight = def.klpiClass === 1 ? 5 : def.klpiClass === 2 ? 3 : def.klpiClass === 3 ? 2 : def.klpiClass === 4 ? 1.5 : 1;    weightedSum += cs.score * weight;
    totalWeight += weight;
  }
  return totalWeight > 0 ? Math.round(weightedSum / totalWeight) : 0;
}
export function getEmpfehlung(score: number): 'Unterzeichnen' | 'Nachverhandeln' | 'Ablehnen' {
  if (score >= 70) return 'Unterzeichnen';
  if (score >= 40) return 'Nachverhandeln';
  return 'Ablehnen';
}
