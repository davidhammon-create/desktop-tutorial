import { LexaraCase } from '@/types/lexara';
export const SEED_CASES: LexaraCase[] = [
  {
    id: 'c1',
    name: 'Schadensersatz Werkvertrag',
    number: 'LG-2024-0847',
    court: 'LG München I',
    type: 'Zivilrecht',
    goal: 'Vollsieg',
    status: 'Aktiv',
    created: '05.04.2024',
    instanz: 'Erstinstanz',
    kernfrage: 'Hat der Beklagte die vertraglich geschuldete Leistung mangelhaft erbracht und ist Schadensersatz geschuldet?',
    fristen: [
      { id: 'f1', type: 'Schriftsatzfrist', paragraph: '§296 ZPO', date: '2026-05-15', status: 'offen', responsible: 'RA Müller', side: 'own', abzugMin: 10, abzugMax: 30 },
      { id: 'f2', type: 'Klagebegründung', paragraph: '§276 ZPO', date: '2026-04-20', status: 'offen', responsible: 'RA Müller', side: 'own', abzugMin: 20, abzugMax: 50 },
    ],
    kosten: { streitwert: 47200, gebuehrenstufe: 1.3, instanz: 'Erstinstanz' },
    arguments: [
      { id: 'a1', side: 'own', label: 'Vertragsverletzung §633 BGB', strength: 9.0, content: 'Beklagter hat die vertraglich geschuldete Leistung mangelhaft erbracht.' },
      { id: 'a2', side: 'own', label: 'Nacherfüllungsverweigerung', strength: 7.5, content: 'Trotz Fristsetzung wurde keine Nacherfüllung geleistet.' },
      { id: 'a3', side: 'own', label: 'Schadensnachweis dokumentiert', strength: 8.0, content: 'Gutachterliche Schadensfeststellung liegt vor.' },
      { id: 'b1', side: 'opp', label: 'Leistung vertragsgemäß erbracht', strength: 6.0, content: 'Beklagter behauptet vertragsgemäße Erfüllung.' },
      { id: 'b2', side: 'opp', label: 'Mitverschulden §254 BGB', strength: 5.0, content: 'Kläger habe Schaden mitverursacht.' },
      { id: 'b3', side: 'opp', label: 'Verjährungseinrede', strength: 3.5, content: 'Anspruch sei verjährt.' },
    ],
    edges: [
      { from: 'a1', to: 'b1', type: 'exclude' },
      { from: 'a2', to: 'b1', type: 'weakens' },
      { from: 'a3', to: 'b2', type: 'weakens' },
      { from: 'a1', to: 'a2', type: 'supports' },
      { from: 'a2', to: 'a3', type: 'supports' },
      { from: 'b1', to: 'b2', type: 'supports' },
    ],
    evidence: {
      a1: [
        { id: 'e1', name: 'Originalkaufvertrag', desc: 'Kaufvertrag 05.04.2024 mit allen Gewährleistungsklauseln', type: 'Urkunde', validity: 95, strength: 9 },
        { id: 'e2', name: 'Abnahmeprotokoll', desc: 'Unterzeichnetes Protokoll mit Mängelliste, 12.05.2024', type: 'Urkunde', validity: 90, strength: 8 },
        { id: 'e3', name: 'Mängelrüge (E-Mail)', desc: 'Schriftliche Mängelrüge, fristgerecht per E-Mail versandt', type: 'Schriftstück', validity: 85, strength: 7 },
      ],
      a2: [
        { id: 'e4', name: 'Nacherfüllungsschreiben', desc: 'Einschreiben mit 30-Tage-Fristsetzung zur Nacherfüllung', type: 'Urkunde', validity: 92, strength: 8 },
        { id: 'e5', name: 'Schweigen dokumentiert', desc: 'Keine Reaktion innerhalb der Frist ? protokolliert', type: 'Protokoll', validity: 80, strength: 7 },
      ],
      a3: [
        { id: 'e6', name: 'SV-Gutachten Dr. Huber', desc: 'Gerichtlich bestellter SV, Schaden €47.200 festgestellt', type: 'Gutachten', validity: 96, strength: 9 },
        { id: 'e7', name: 'Kostenvoranschläge (3?)', desc: 'Drei unabhängige KV zur Mängelbeseitigung', type: 'Schriftstück', validity: 78, strength: 6 },
      ],
      b1: [
        { id: 'e8', name: 'Bautagebuch (intern)', desc: 'Echtheit unbestätigt, Lücken am 10.?14.05', type: 'Intern', validity: 40, strength: 4 },
      ],
      b2: [
        { id: 'e9', name: 'Zeuge Krämer', desc: 'Bauleiter Beklagte ? Interessenskonflikt erkennbar', type: 'Zeuge', validity: 35, strength: 3 },
      ],
      b3: [
        { id: 'e10', name: 'Verjährungsberechnung', desc: 'Beklagte: Mangel erkennbar ab 2021 ? bestritten', type: 'Berechnung', validity: 30, strength: 2 },
      ],
    },
    persons: [
      {
        id: 'p1', name: 'Dr. Andreas Müller', role: 'Richter', party: null,
        court: 'LG München I, 3. Kammer f. Handelssachen',
        historicalCases: 847, historicalConsistency: 85, priorContradictions: 1,
        plaintiffWinRate: 54, settleRate: 38, avgDuration: '14 Mo.',
        conflictOfInterest: 10, hiddenMotive: 5, competenceLevel: 92,
        selfPreservation: 20, loyaltySignals: 15, fearFactor: 10,
        narcissism: 15, cognitiveEmpathy: 70, affectiveEmpathy: 40, manipulationSkill: 10, coldness: 15,
        legalLevers: [
          { title: 'Präklusion §296 ZPO', desc: 'Verspätetes Vorbringen der Gegenseite ? konsequent rügen' },
          { title: 'Beweiswürdigung §286 ZPO', desc: 'Unglaubwürdigkeit Gegenzeugen aktiv darstellen' },
          { title: 'Hinweispflicht §139 ZPO', desc: 'Frühere Hinweisbeschlüsse referenzieren' },
        ],
        psychLevers: [],
        questionModules: [],
        pastCaseNotes: 'Konsistent urkunden-orientiert. In 3 Verfahren Befangenheitsantrag abgelehnt.',
      },
      {
        id: 'p2', name: 'Thomas Krämer', role: 'Zeuge', party: 'Beklagte',
        court: 'Bauleiter bei Beklagter GmbH, 8 Jahre angestellt',
        historicalCases: 3, historicalConsistency: 41, priorContradictions: 2,
        plaintiffWinRate: null, settleRate: null, avgDuration: null,
        conflictOfInterest: 88, hiddenMotive: 75, competenceLevel: 55,
        selfPreservation: 82, loyaltySignals: 90, fearFactor: 68,
        narcissism: 35, cognitiveEmpathy: 30, affectiveEmpathy: 20, manipulationSkill: 60, coldness: 55,
        legalLevers: [
          { title: 'Interessenkonflikt §138 ZPO', desc: 'Abhängigkeitsverhältnis thematisieren' },
          { title: 'Widerspruch zur Urkunde §444 ZPO', desc: 'Bautagebuch widerspricht Aussage' },
        ],
        psychLevers: [
          { type: 'Gedächtnislücke provozieren', example: 'Das ist 14 Monate her ? haben Sie sich Notizen gemacht?' },
          { type: 'Detailkette', example: 'Waren Sie persönlich anwesend? Welche genaue Uhrzeit?' },
          { type: 'Übertreibung provozieren', example: 'Sie haben also JEDEN Arbeitsschritt persönlich überwacht?' },
          { type: 'Eitelkeit nutzen', example: 'Als erfahrener Bauleiter müssen Sie doch sofort gemerkt haben...' },
        ],
        questionModules: [
          { title: 'Gedächtnislücken-Modul', qs: ['Das ist nun 14 Monate her ? haben Sie sich Notizen gemacht?', 'Können Sie das Datum exakt benennen?'] },
          { title: 'Detailketten-Modul', qs: ['Waren Sie persönlich anwesend?', 'Welche genaue Uhrzeit war das?'] },
        ],
        pastCaseNotes: 'In Verfahren LG-2022-0312: Aussage widersprach Protokoll. In LG-2023-0198: Terminlich nicht erschienen.',
      },
    ],
  },
  {
    id: 'c2',
    name: 'Kündigungsschutzklage Müller ./. TechCorp AG',
    number: 'ArbG-2024-1123',
    court: 'ArbG Frankfurt',
    type: 'Arbeitsrecht',
    goal: 'Weiterbeschäftigung',
    status: 'Aktiv',
    created: '18.07.2024',
    instanz: 'Erstinstanz',
    kernfrage: 'Ist die betriebsbedingte Kündigung sozial gerechtfertigt und wurde der BR ordnungsgemäß angehört?',
    fristen: [
      { id: 'f1', type: 'Klagefrist KSchG', paragraph: '§4 KSchG', date: '2026-04-10', status: 'erledigt', responsible: 'RA Schmidt', side: 'own', abzugMin: 100, abzugMax: 100 },
    ],
    kosten: { streitwert: 36000, gebuehrenstufe: 1.3, instanz: 'Erstinstanz' },
    arguments: [
      { id: 'a1', side: 'own', label: 'Soziale Auswahl fehlerhaft §1 KSchG', strength: 8.5, content: 'Vergleichbare Kollegen mit kürzerer Betriebszugehörigkeit nicht gekündigt.' },
      { id: 'a2', side: 'own', label: 'Betriebsrat nicht ordnungsgemäß angehört', strength: 9.0, content: 'Anhörung war formal fehlerhaft ? Sozialangaben unvollständig.' },
      { id: 'a3', side: 'own', label: 'Kein dringender betrieblicher Grund', strength: 6.5, content: 'Stelle wurde 6 Wochen nach Kündigung erneut ausgeschrieben.' },
      { id: 'b1', side: 'opp', label: 'Betriebsbedingte Kündigung §1 KSchG', strength: 7.0, content: 'Umstrukturierung führte zum Wegfall des Arbeitsplatzes.' },
      { id: 'b2', side: 'opp', label: 'Umstrukturierung nachgewiesen', strength: 6.0, content: 'Vorstandsbeschluss zur Restrukturierung liegt vor.' },
    ],
    edges: [
      { from: 'a1', to: 'b1', type: 'weakens' },
      { from: 'a2', to: 'b1', type: 'exclude' },
      { from: 'a3', to: 'b2', type: 'weakens' },
      { from: 'a1', to: 'a2', type: 'supports' },
    ],
    evidence: {
      a1: [
        { id: 'e1', name: 'Sozialdaten Vergleichsgruppe', desc: 'Vergleichbarkeit mit Kollegen Berger und Schäfer', type: 'Dokument', validity: 88, strength: 8 },
        { id: 'e2', name: 'Betriebszugehörigkeit (12 Jahre)', desc: 'Kläger: 12 Jahre, entlassene Vergleichsperson: 4 Jahre', type: 'Nachweis', validity: 95, strength: 9 },
      ],
      a2: [
        { id: 'e3', name: 'Anhörungsprotokoll BR', desc: 'Protokoll zeigt unvollständige Sozialangaben', type: 'Protokoll', validity: 90, strength: 8 },
        { id: 'e4', name: 'BR-Stellungnahme', desc: 'Betriebsrat hat widersprochen ? Widerspruch dokumentiert', type: 'Schriftstück', validity: 92, strength: 9 },
      ],
      a3: [
        { id: 'e5', name: 'Stellenausschreibung (nach Kündigung)', desc: 'Identische Stelle 6 Wochen nach Kündigung ausgeschrieben', type: 'Screenshot', validity: 85, strength: 7 },
      ],
      b1: [
        { id: 'e6', name: 'Organigramm neu', desc: 'Neue Org-Struktur ? Echtheit und Datum prüfen', type: 'Intern', validity: 50, strength: 5 },
      ],
      b2: [
        { id: 'e7', name: 'Vorstandsbeschluss', desc: 'Beschluss zur Restrukturierung ? intern, nicht notariell', type: 'Intern', validity: 55, strength: 5 },
      ],
    },
    persons: [
      {
        id: 'p1', name: 'Richterin Sabine Vogel', role: 'Richter', party: null,
        court: 'ArbG Frankfurt, 12. Kammer',
        historicalCases: 1240, historicalConsistency: 88, priorContradictions: 0,
        plaintiffWinRate: 61, settleRate: 72, avgDuration: '8 Mo.',
        conflictOfInterest: 5, hiddenMotive: 5, competenceLevel: 94,
        selfPreservation: 15, loyaltySignals: 10, fearFactor: 8,
        narcissism: 10, cognitiveEmpathy: 75, affectiveEmpathy: 55, manipulationSkill: 5, coldness: 10,
        legalLevers: [
          { title: 'Güteverhandlung strategisch nutzen', desc: 'Richterin bevorzugt Vergleiche ? Vergleichsbereitschaft zeigen' },
          { title: 'Anhörungsmangel §102 BetrVG', desc: 'Formfehler bei BR-Anhörung führt zwingend zur Unwirksamkeit' },
        ],
        psychLevers: [],
        questionModules: [],
        pastCaseNotes: 'Hohe Vergleichsquote. Bevorzugt pragmatische Lösungen.',
      },
      {
        id: 'p2', name: 'HR-Leiterin Dr. Becker', role: 'Zeuge', party: 'Beklagte',
        court: 'HR-Leiterin TechCorp AG, seit 2019',
        historicalCases: 5, historicalConsistency: 62, priorContradictions: 1,
        plaintiffWinRate: null, settleRate: null, avgDuration: null,
        conflictOfInterest: 70, hiddenMotive: 65, competenceLevel: 78,
        selfPreservation: 72, loyaltySignals: 80, fearFactor: 55,
        narcissism: 45, cognitiveEmpathy: 65, affectiveEmpathy: 15, manipulationSkill: 70, coldness: 50,
        legalLevers: [
          { title: 'Kenntnis der Sozialauswahl §1 KSchG', desc: 'Sie hat Auswahl durchgeführt ? muss Kriterien darlegen' },
        ],
        psychLevers: [
          { type: 'Kompetenzgrenze aufzeigen', example: 'Wer hat die Sozialpunkte konkret berechnet?' },
          { type: 'Widerspruch zur Urkunde', example: 'Das Protokoll vom 15.07. zeigt X ? wie erklären Sie das?' },
        ],
        questionModules: [
          { title: 'Sozialauswahlmodul', qs: ['Welche Kriterien wurden bei der Sozialauswahl herangezogen?', 'Wer war in der Vergleichsgruppe?'] },
        ],
        pastCaseNotes: 'In ArbG-2022-0445 Aussage zur Sozialauswahl von Richter als "nicht nachvollziehbar" bewertet.',
      },
    ],
  },
  {
    id: 'c3',
    name: 'Markenrechtsverletzung LogoTech ./. StartUp GmbH',
    number: 'LG-2024-2291',
    court: 'LG Hamburg',
    type: 'Markenrecht',
    goal: 'Unterlassung + Schadensersatz',
    status: 'Vorbereitung',
    created: '02.11.2024',
    instanz: 'Erstinstanz',
    kernfrage: 'Liegt eine Verwechslungsgefahr i.S.d. §14 MarkenG vor?',
    fristen: [
      { id: 'f1', type: 'eV-Antragsfrist', paragraph: '§940 ZPO', date: '2026-06-01', status: 'offen', responsible: 'RA Weber', side: 'own', abzugMin: 30, abzugMax: 70 },
    ],
    kosten: { streitwert: 100000, gebuehrenstufe: 1.3, instanz: 'Erstinstanz' },
    arguments: [
      { id: 'a1', side: 'own', label: 'Verwechslungsgefahr §14 MarkenG', strength: 8.0, content: 'Verwechslungsquote 68% in Verkehrsbefragung.' },
      { id: 'a2', side: 'own', label: 'Benutzung im geschäftlichen Verkehr', strength: 9.0, content: 'Nachweis der Verwendung auf Webseite und Social Media.' },
      { id: 'b1', side: 'opp', label: 'Keine Zeichenähnlichkeit', strength: 5.5, content: 'Behauptung fehlender visueller Ähnlichkeit.' },
      { id: 'b2', side: 'opp', label: 'Unterschiedliche Verkehrskreise', strength: 4.0, content: 'Behauptung unterschiedlicher Branchen ? belegbar widerlegt.' },
    ],
    edges: [
      { from: 'a1', to: 'b1', type: 'exclude' },
      { from: 'a2', to: 'b2', type: 'weakens' },
      { from: 'a1', to: 'a2', type: 'supports' },
    ],
    evidence: {
      a1: [
        { id: 'e1', name: 'Markenregisterauszug', desc: 'Eingetragene Wortbildmarke seit 2018, DPMA-Nr. 302018012345', type: 'Urkunde', validity: 98, strength: 9 },
        { id: 'e2', name: 'Verwechslungsgutachten', desc: 'Verkehrsbefragung: 68% Verwechslungsquote', type: 'Gutachten', validity: 88, strength: 8 },
      ],
      a2: [
        { id: 'e3', name: 'Website-Screenshots', desc: 'Verwendung des Zeichens auf Webseite, datiert und notariell gesichert', type: 'Screenshot', validity: 90, strength: 8 },
      ],
      b1: [
        { id: 'e4', name: 'Eigenes Gutachten Beklagte', desc: 'Parteibeauftragtes Gutachten ? Interessenskonflikt', type: 'Gutachten', validity: 35, strength: 4 },
      ],
      b2: [
        { id: 'e5', name: 'Marktabgrenzung', desc: 'Behauptung unterschiedlicher Branchen ? belegbar widerlegt', type: 'Schriftstück', validity: 30, strength: 3 },
      ],
    },
    persons: [
      {
        id: 'p1', name: 'Richter Dr. Hoffmann', role: 'Richter', party: null,
        court: 'LG Hamburg, 3. Zivilkammer (Markenrecht)',
        historicalCases: 423, historicalConsistency: 79, priorContradictions: 2,
        plaintiffWinRate: 58, settleRate: 45, avgDuration: '10 Mo.',
        conflictOfInterest: 8, hiddenMotive: 8, competenceLevel: 88,
        selfPreservation: 25, loyaltySignals: 20, fearFactor: 15,
        narcissism: 20, cognitiveEmpathy: 60, affectiveEmpathy: 45, manipulationSkill: 15, coldness: 20,
        legalLevers: [
          { title: 'Verwechslungsgefahr §14 II MarkenG', desc: 'Gesamtbildvergleich ? Durchschnittsverbraucher-Maßstab' },
          { title: 'Bekanntheitsgrad der Marke', desc: 'Belege für Marktpräsenz und Werbeinvestitionen vorlegen' },
        ],
        psychLevers: [],
        questionModules: [],
        pastCaseNotes: 'Gilt als streng bei Markenrechtsverletzungen. Verkehrsbefragungen werden hoch gewichtet.',
      },
    ],
  },
];
