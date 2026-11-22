export type ArgumentType = 'Rechtsargument' | 'Tatsachenargument' | 'Beweisargument' | 'Verfahrensargument' | 'Präzedenzargument' | 'Gegenargument';
export interface LexaraEvidence {
  id: string;
  name: string;
  desc: string;
  type?: string;
  validity?: number;   // 0?100%
  strength?: number;   // 0?10
}
export interface LexaraArgument {
  id: string;
  side: 'own' | 'opp';
  label: string;
  strength: number;    // 0?10
  content?: string;
  description?: string;
  argType?: ArgumentType;
  date?: string;
  timestamp?: string;  // ISO datetime for chronological sorting
  sortOrder?: number;  // manual sort order (drag & drop)
  legalBasis?: string; // e.g. "§633 BGB"
  notes?: string;      // internal notes
  source?: 'manual' | 'ki';  // origin of the argument
  seite?: number | null;     // page reference from document
}
export interface LexaraEdge {
  from: string;
  to: string;
  type: 'supports' | 'weakens' | 'exclude' | 'causal';
}
export type FristStatus = 'offen' | 'erledigt' | 'versäumt';
export type FristUrgency = 'green' | 'yellow' | 'red' | 'grey';
export interface LexaraFrist {
  id: string;
  type: string;          // e.g. "Berufungsfrist", "Schriftsatzfrist"
  paragraph: string;     // e.g. "§517 ZPO"
  date: string;          // ISO date
  status: FristStatus;
  responsible: string;
  notes?: string;
  abzugMin?: number;     // min prognosis deduction %
  abzugMax?: number;     // max prognosis deduction %
  side: 'own' | 'opp';
}
export interface LexaraKosten {
  streitwert: number;
  gebuehrenstufe: number;    // 1.0?2.3
  instanz: string;           // "Erstinstanz", "Berufung", "Revision"
  sachverstaendigenKosten?: number;
  reisekosten?: number;
  vergleichsangebot?: number;
  risikoaufschlag?: number;  // default 15%
}
export const FRIST_TYPES = [
  { type: 'Berufungsfrist', paragraph: '§517 ZPO', dauer: '1 Monat', abzugMin: 60, abzugMax: 100 },
  { type: 'Berufungsbegründung', paragraph: '§520 ZPO', dauer: '2 Monate', abzugMin: 40, abzugMax: 70 },
  { type: 'Revisionsfrist', paragraph: '§548 ZPO', dauer: '1 Monat', abzugMin: 100, abzugMax: 100 },
  { type: 'Klagebegründung', paragraph: '§276 ZPO', dauer: 'Richterlich', abzugMin: 20, abzugMax: 50 },
  { type: 'Schriftsatzfrist', paragraph: '§296 ZPO', dauer: 'Richterlich', abzugMin: 10, abzugMax: 30 },
  { type: 'Widerspruch Mahnbescheid', paragraph: '§694 ZPO', dauer: '2 Wochen', abzugMin: 80, abzugMax: 100 },
  { type: 'Einspruch Versäumnisurteil', paragraph: '§339 ZPO', dauer: '2 Wochen', abzugMin: 90, abzugMax: 100 },
  { type: 'eV-Antragsfrist', paragraph: '§940 ZPO', dauer: 'Fallabhängig', abzugMin: 30, abzugMax: 70 },
  { type: 'Verjährungsfrist', paragraph: '§§195ff. BGB', dauer: '3 Jahre', abzugMin: 100, abzugMax: 100 },
  { type: 'Klagefrist KSchG', paragraph: '§4 KSchG', dauer: '3 Wochen', abzugMin: 100, abzugMax: 100 },
  { type: 'BR-Anzeige §102 BetrVG', paragraph: '§102 BetrVG', dauer: '1 Woche', abzugMin: -40, abzugMax: -20 },
  { type: 'Vollstreckungsfristen', paragraph: '§§767ff. ZPO', dauer: 'Variabel', abzugMin: 30, abzugMax: 60 },
] as const;
export const EVIDENCE_BASE_WEIGHTS: Record<string, number> = {
  'Geständnis': 10.0,
  'Notarielle Beurkundung': 9.5,
  'Öffentliche Urkunde': 9.0,
  'Gerichtliches SV-Gutachten': 8.5,
  'Private Urkunde': 7.5,
  'Handelsüblicher Brief': 7.5,
  'Augenscheinsbeweis': 7.0,
  'Handelsbücher': 7.0,
  'Privates SV-Gutachten': 6.5,
  'E-Mail': 6.0,
  'Zeuge (unabhängig)': 6.0,
  'Zeuge (parteinah)': 3.5,
  'Indizien': 3.5,
  'Parteivernehmung': 4.0,
  'Negative Tatsache': 3.0,
  'Urkunde': 7.5,
  'Gutachten': 8.5,
  'Schriftstück': 6.0,
  'Protokoll': 6.5,
  'Screenshot': 5.5,
  'Dokument': 6.0,
  'Nachweis': 7.0,
  'Intern': 4.0,
  'Zeuge': 5.0,
  'Berechnung': 5.0,
};
export const ARGUMENT_WEIGHT_TABLE = [
  { type: 'Gesetzliche Grundlage / Normtext', weight: 10.0, category: 'Recht' },
  { type: 'BGH/BVerfG Entscheidung (einschlägig)', weight: 9.5, category: 'Rspr.' },
  { type: 'Notarielle Beurkundung', weight: 9.5, category: 'Beweis' },
  { type: 'Öffentliche Urkunde §415 ZPO', weight: 9.0, category: 'Beweis' },
  { type: 'BGH-Entscheidung (übertragbar)', weight: 8.5, category: 'Rspr.' },
  { type: 'Gerichtliches SV-Gutachten', weight: 8.5, category: 'Beweis' },
  { type: 'OLG-Entscheidung (gleiches BL)', weight: 7.5, category: 'Rspr.' },
  { type: 'Private Urkunde §416 ZPO', weight: 7.5, category: 'Beweis' },
  { type: 'Augenscheinsbeweis', weight: 7.0, category: 'Beweis' },
  { type: 'Privates SV-Gutachten', weight: 6.5, category: 'Beweis' },
  { type: 'E-Mail / elektronisch', weight: 6.0, category: 'Beweis' },
  { type: 'Zeuge (unabhängig)', weight: 6.0, category: 'Beweis' },
  { type: 'LG-Entscheidung', weight: 5.0, category: 'Rspr.' },
  { type: 'Parteivernehmung §445 ZPO', weight: 4.0, category: 'Beweis' },
  { type: 'Zeuge (parteinah)', weight: 3.5, category: 'Beweis' },
  { type: 'Indizien (kumulativ)', weight: 3.5, category: 'Beweis' },
  { type: 'Negative Tatsache', weight: 3.0, category: 'Beweis' },
];
export interface LegalLever {
  title: string;
  desc: string;
}
export interface PsychLever {
  type: string;
  example: string;
}
export interface QuestionModule {
  title: string;
  qs: string[];
}
export interface LexaraPerson {
  id: string;
  name: string;
  role: 'Richter' | 'Zeuge' | 'Anwalt';
  party: string | null;
  court: string;
  historicalCases: number;
  historicalConsistency: number;
  priorContradictions: number;
  plaintiffWinRate: number | null;
  settleRate: number | null;
  avgDuration: string | null;
  conflictOfInterest: number;
  hiddenMotive: number;
  competenceLevel: number;
  selfPreservation: number;
  loyaltySignals: number;
  fearFactor: number;
  // Dark Empath dimensions
  narcissism: number;           // 0?100: Selbstüberschätzung, Geltungsdrang
  cognitiveEmpathy: number;     // 0?100: Fähigkeit Emotionen anderer zu lesen (HOCH = gefährlicher)
  affectiveEmpathy: number;     // 0?100: Echtes Mitgefühl (NIEDRIG = Dark Empath)
  manipulationSkill: number;    // 0?100: Strategisches Kalkül, Täuschungstalent
  coldness: number;             // 0?100: Emotionale Kälte, fehlende Reue
  legalLevers: LegalLever[];
  psychLevers: PsychLever[];
  questionModules: QuestionModule[];
  pastCaseNotes: string;
}
export type StrategiePfad = 'klage' | 'vergleich' | 'aufgabe';
export interface StrategieEmpfehlung {
  pfad: StrategiePfad;
  label: string;
  desc: string;
  color: string;
}
export interface LexaraCase {
  id: string;
  name: string;
  number: string;
  court: string;
  type: string;        // Rechtsgebiet
  goal: string;        // Prozessziel
  status: string;
  created: string;
  instanz?: string;    // Erstinstanz, Berufung, Revision
  kernfrage?: string;  // zentrale Rechtsfrage
  arguments: LexaraArgument[];
  edges: LexaraEdge[];
  evidence: Record<string, LexaraEvidence[]>;
  persons: LexaraPerson[];
  fristen: LexaraFrist[];
  kosten?: LexaraKosten;
}
