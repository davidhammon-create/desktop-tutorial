// ??? Business Risk Management Types ???
export type ProblemCategory =
  | 'Steueroptimierung'
  | 'IP-Streitigkeit'
  | 'Vertragsmanagement'
  | 'Forderungsmanagement'
  | 'Arbeitsrecht'
  | 'M&A / Transaktion'
  | 'Compliance / Regulierung'
  | 'Geschäftsbeziehung';
export const PROBLEM_CATEGORIES: { id: ProblemCategory; icon: string; examples: string[] }[] = [
  { id: 'Steueroptimierung', icon: '', examples: ['Steuerstruktur nutzen?', 'Kosten bei Entdeckung vs. Ersparnis', 'Compliance-Risiken'] },
  { id: 'IP-Streitigkeit', icon: '', examples: ['Patent-/Markenverletzung', 'Abmahnung senden oder erhalten', 'Lizenzierung vs. Klage'] },
  { id: 'Vertragsmanagement', icon: '', examples: ['Vertrag annehmen/ablehnen?', 'Klauseln nachverhandeln', 'Vertragsbruch: Kündigen oder nachverhandeln?'] },
  { id: 'Forderungsmanagement', icon: '', examples: ['Kunden verklagen?', 'Inkasso beauftragen?', 'Zahlungsplan anbieten?'] },
  { id: 'Arbeitsrecht', icon: '', examples: ['Kündigung oder Abfindung?', 'Ex-Mitarbeiter bei Konkurrent', 'Wettbewerbsverbot durchsetzen?'] },
  { id: 'M&A / Transaktion', icon: '', examples: ['Due Diligence-Risiken bewerten', 'Kaufpreis-Verhandlung', 'Earn-Out vs. fixer Preis'] },
  { id: 'Compliance / Regulierung', icon: '', examples: ['Selbstanzeige vs. Abwarten?', 'DSGVO-Verstoß melden?', 'Leniency-Programm nutzen?'] },
  { id: 'Geschäftsbeziehung', icon: '', examples: ['Partner verklagen oder Beziehung retten?', 'Joint Venture fortsetzen/auflösen?', 'Lieferant wechseln?'] },
];
export interface BusinessArgument {
  id: string;
  side: 'pro' | 'contra';
  text: string;
  weight: number; // 1-10
}
export interface OptionCosts {
  anwaltskosten: number;
  gerichtskosten: number;
  interneKosten: number;
  opportunitaetskosten: number;
}
export interface OptionRisk {
  erfolgswahrscheinlichkeit: number; // 0-100
  bestCase: number;   // €
  worstCase: number;  // €
  likelyCase: number; // €
}
export interface OptionTimeframe {
  minMonths: number;
  maxMonths: number;
  earliestResult: string;
}
export interface NonMonetaryFactors {
  reputationsrisiko: number;      // 0-10
  geschaeftsbeziehungGefaehrdet: number; // 0-10
  medienoeffentlichkeit: number;  // 0-10
  praezedenzwirkung: number;      // 0-10
  mitarbeitermoralAuswirkung: number; // 0-10
}
// ??? Deadline / Fristen ???
export type DeadlineType = 'Verjährung' | 'Widerspruch' | 'Kündigung' | 'Vertragsfrist' | 'Behördenfrist' | 'Sonstige';
export interface Deadline {
  id: string;
  label: string;
  date: string; // ISO date string
  type: DeadlineType;
  critical: boolean;
  notes: string;
}
// ??? RPN (Risikoprioritätszahl) ???
export interface RiskItem {
  id: string;
  label: string;
  auftretenswahrscheinlichkeit: number; // 1-10
  bedeutung: number;                    // 1-10
  entdeckungswahrscheinlichkeit: number; // 1-10
}
// ??? Risk Mitigation (Schutzmaßnahmen) ???
export interface RiskMitigation {
  id: string;
  label: string;
  risikoreduktion: number; // € amount of risk reduced
  kosten: number;          // € cost of the measure
}
export interface BusinessOption {
  id: string;
  label: string;
  description: string;
  costs: OptionCosts;
  risk: OptionRisk;
  timeframe: OptionTimeframe;
  nonMonetary: NonMonetaryFactors;
  relevanteLaws: string[];
  arguments: BusinessArgument[];
  riskItems: RiskItem[];
  mitigations: RiskMitigation[];
  deadlines: Deadline[];
}
export interface UploadedFile {
  id: string;
  name: string;
  size: number;
  type: string;
  storagePath: string;
  uploadedAt: string;
}
export interface BusinessScenario {
  id: string;
  title: string;
  description: string;
  category: ProblemCategory;
  company: string;
  created: string;
  status: 'Entwurf' | 'In Analyse' | 'Abgeschlossen';
  options: BusinessOption[];
  selectedOptionId?: string;
  notes: string;
  uploadedFiles?: UploadedFile[];
  outcomeRating?: number;       // 1-5
  outcomeNotes?: string;
  outcomeDate?: string;         // ISO date
}
// ??? Calculation helpers ???
export function totalCosts(c: OptionCosts): number {
  return c.anwaltskosten + c.gerichtskosten + c.interneKosten + c.opportunitaetskosten;
}
/** EV = (P(success) ? bestCase) + (P(fail) ? worstCase) - costs */
export function expectedValue(o: BusinessOption): number {
  const p = o.risk.erfolgswahrscheinlichkeit / 100;
  const ev = p * o.risk.bestCase + (1 - p) * o.risk.worstCase;
  return ev - totalCosts(o.costs);
}
/** RPN = Auftretenswahrscheinlichkeit ? Bedeutung ? Entdeckungswahrscheinlichkeit */
export function computeRPN(item: RiskItem): number {
  return item.auftretenswahrscheinlichkeit * item.bedeutung * item.entdeckungswahrscheinlichkeit;
}
/** Brutto-Risiko = ? (Wahrscheinlichkeit ? Schadenshöhe) approximated from risk items */
export function bruttoRisiko(o: BusinessOption): number {
  const p = o.risk.erfolgswahrscheinlichkeit / 100;
  return (1 - p) * Math.abs(o.risk.worstCase) + totalCosts(o.costs);
}
/** Total risk reduction from mitigations */
export function totalMitigationReduction(mitigations: RiskMitigation[]): number {
  return mitigations.reduce((s, m) => s + m.risikoreduktion, 0);
}
/** Total cost of mitigations */
export function totalMitigationCost(mitigations: RiskMitigation[]): number {
  return mitigations.reduce((s, m) => s + m.kosten, 0);
}
/** Netto-Risiko = Brutto-Risiko - ? Risikominderung */
export function nettoRisiko(o: BusinessOption): number {
  return Math.max(0, bruttoRisiko(o) - totalMitigationReduction(o.mitigations));
}
/** VaR approximation: 95% confidence = worstCase ? 0.7, 99% = worstCase */
export function valueAtRisk(o: BusinessOption): { var95: number; var99: number } {
  const worst = Math.abs(o.risk.worstCase) + totalCosts(o.costs);
  return {
    var95: Math.round(worst * 0.7),
    var99: worst,
  };
}
/** Risk-Ampel: Green if EV > 2? costs, Yellow if EV > 0, Red otherwise */
export function riskAmpel(o: BusinessOption): 'green' | 'yellow' | 'red' {
  const ev = expectedValue(o);
  const costs = totalCosts(o.costs);
  if (ev > costs * 0.5) return 'green';
  if (ev > 0) return 'yellow';
  return 'red';
}
/** Break-Even: Ab welcher P% lohnt sich die Option? */
export function breakEvenProbability(o: BusinessOption): number {
  const gain = o.risk.bestCase;
  const loss = Math.abs(o.risk.worstCase);
  const costs = totalCosts(o.costs);
  const denom = gain + loss;
  if (denom === 0) return 100;
  return Math.min(100, Math.max(0, ((loss + costs) / denom) * 100));
}
/** ROI einer Schutzmaßnahme */
export function roiMitigation(m: RiskMitigation): number {
  if (m.kosten === 0) return m.risikoreduktion > 0 ? Infinity : 0;
  return m.risikoreduktion / m.kosten;
}
/** Sensitivitätsanalyse: EV bei verschiedenen P-Werten */
export function sensitivityEV(o: BusinessOption, pValues: number[]): { p: number; ev: number }[] {
  const costs = totalCosts(o.costs);
  return pValues.map(p => {
    const pFrac = p / 100;
    const ev = pFrac * o.risk.bestCase + (1 - pFrac) * o.risk.worstCase - costs;
    return { p, ev };
  });
}
/** Monte-Carlo-Simulation mit Dreiecksverteilung */
export interface MonteCarloResult {
  mean: number;
  median: number;
  p5: number;
  p95: number;
  min: number;
  max: number;
  histogram: { binStart: number; binEnd: number; count: number }[];
}
function triangularRandom(min: number, mode: number, max: number): number {
  const u = Math.random();
  if (min === max) return min;
  const fc = (mode - min) / (max - min);
  if (u < fc) {
    return min + Math.sqrt(u * (max - min) * (mode - min));
  }
  return max - Math.sqrt((1 - u) * (max - min) * (max - mode));
}
export function monteCarloSimulation(o: BusinessOption, runs: number = 1000): MonteCarloResult {
  const costs = totalCosts(o.costs);
  const worst = o.risk.worstCase;
  const best = o.risk.bestCase;
  const likely = o.risk.likelyCase || (best + worst) / 2;
  const pBase = o.risk.erfolgswahrscheinlichkeit / 100;
  const results: number[] = [];
  for (let i = 0; i < runs; i++) {
    // Vary probability ?20% around base
    const pVar = Math.max(0, Math.min(1, pBase + (Math.random() - 0.5) * 0.4));
    const outcome = triangularRandom(worst, likely, best);
    const ev = pVar * Math.max(0, outcome) + (1 - pVar) * Math.min(0, outcome) - costs;
    results.push(ev);
  }
  results.sort((a, b) => a - b);
  const mean = results.reduce((s, v) => s + v, 0) / runs;
  const median = results[Math.floor(runs / 2)];
  const p5 = results[Math.floor(runs * 0.05)];
  const p95 = results[Math.floor(runs * 0.95)];
  const min = results[0];
  const max = results[runs - 1];
  // Build 10-bin histogram
  const binCount = 10;
  const range = max - min || 1;
  const binSize = range / binCount;
  const histogram: MonteCarloResult['histogram'] = [];
  for (let b = 0; b < binCount; b++) {
    const binStart = min + b * binSize;
    const binEnd = binStart + binSize;
    const count = results.filter(v => v >= binStart && (b === binCount - 1 ? v <= binEnd : v < binEnd)).length;
    histogram.push({ binStart, binEnd, count });
  }
  return { mean, median, p5, p95, min, max, histogram };
}
export function argumentScore(args: BusinessArgument[]): { pro: number; contra: number; net: number } {
  const pros = args.filter(a => a.side === 'pro');
  const contras = args.filter(a => a.side === 'contra');
  const proSum = pros.reduce((s, a) => s + a.weight, 0);
  const contraSum = contras.reduce((s, a) => s + a.weight, 0);
  const proAvg = pros.length ? proSum / pros.length : 0;
  const contraAvg = contras.length ? contraSum / contras.length : 0;
  return { pro: proAvg, contra: contraAvg, net: proAvg - contraAvg };
}
export function recommendOption(options: BusinessOption[]): BusinessOption | null {
  if (!options.length) return null;
  const evs = options.map(o => expectedValue(o));
  const maxEv = Math.max(...evs.map(Math.abs), 1);
  const maxDuration = Math.max(...options.map(o => o.timeframe.maxMonths), 1);
  let best: BusinessOption | null = null;
  let bestScore = -Infinity;
  options.forEach((o, i) => {
    const evNorm = evs[i] / maxEv;
    const probNorm = o.risk.erfolgswahrscheinlichkeit / 100;
    const argNet = argumentScore(o.arguments).net / 10;
    const speedNorm = 1 - (o.timeframe.maxMonths / maxDuration);
    const score = evNorm * 0.4 + probNorm * 0.3 + argNet * 0.2 + speedNorm * 0.1;
    if (score > bestScore) {
      bestScore = score;
      best = o;
    }
  });
  return best;
}
export function createEmptyOption(label: string): BusinessOption {
  return {
    id: `opt-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    label,
    description: '',
    costs: { anwaltskosten: 0, gerichtskosten: 0, interneKosten: 0, opportunitaetskosten: 0 },
    risk: { erfolgswahrscheinlichkeit: 50, bestCase: 0, worstCase: 0, likelyCase: 0 },
    timeframe: { minMonths: 1, maxMonths: 6, earliestResult: '' },
    nonMonetary: { reputationsrisiko: 0, geschaeftsbeziehungGefaehrdet: 0, medienoeffentlichkeit: 0, praezedenzwirkung: 0, mitarbeitermoralAuswirkung: 0 },
    relevanteLaws: [],
    arguments: [],
    riskItems: [],
    mitigations: [],
    deadlines: [],
  };
}
export function createEmptyScenario(): BusinessScenario {
  return {
    id: `biz-${Date.now()}`,
    title: '',
    description: '',
    category: 'Vertragsmanagement',
    company: '',
    created: new Date().toLocaleDateString('de-DE'),
    status: 'Entwurf',
    options: [],
    notes: '',
  };
}
