// ??? Advanced Business Risk Formulas ???
import { BusinessOption, totalCosts, expectedValue } from './business';
/** Risikoadjustierter Wert (RAV) mit Zeitdiskontierung */
export function riskAdjustedValue(o: BusinessOption, diskontRate: number = 0.05): number {
  const ev = expectedValue(o);
  const t = o.timeframe.maxMonths / 12; // Convert months to years
  return ev / Math.pow(1 + diskontRate, t);
}
/** Downside Risk: Summe aller negativen Szenarien */
export function downsideRisk(o: BusinessOption): number {
  const pFail = 1 - o.risk.erfolgswahrscheinlichkeit / 100;
  const costs = totalCosts(o.costs);
  const worstLoss = Math.abs(o.risk.worstCase);
  return pFail * worstLoss + costs;
}
/** Sharpe Ratio: (EV - risikofreier Gewinn) / Standardabweichung */
export function sharpeRatio(o: BusinessOption, risikofreierZins: number = 0.03): number {
  const ev = expectedValue(o);
  const costs = totalCosts(o.costs);
  const risikofreierGewinn = risikofreierZins * costs;

  // Calculate standard deviation from outcomes
  const p = o.risk.erfolgswahrscheinlichkeit / 100;
  const outcomes = [
    { prob: p, value: o.risk.bestCase - costs },
    { prob: 1 - p, value: o.risk.worstCase - costs },
  ];
  const mean = outcomes.reduce((s, o) => s + o.prob * o.value, 0);
  const variance = outcomes.reduce((s, o) => s + o.prob * Math.pow(o.value - mean, 2), 0);
  const stdDev = Math.sqrt(variance);

  if (stdDev === 0) return 0;
  return (ev - risikofreierGewinn) / stdDev;
}
/** Kelly-Kriterium: Optimaler Anteil des Budgets */
export function kellyKriterium(o: BusinessOption): number {
  const p = o.risk.erfolgswahrscheinlichkeit / 100;
  const q = 1 - p;
  const costs = totalCosts(o.costs);
  const gain = o.risk.bestCase;

  if (costs === 0) return 0;
  const b = gain / costs; // Gewinn/Einsatz Verhältnis
  if (b === 0) return 0;

  const f = (p * b - q) / b;
  return Math.max(0, Math.min(1, f)); // Clamp 0-1
}
/** Qualitative Score with customizable weights */
export interface QualitativeWeights {
  reputationsrisiko: number;
  geschaeftsbeziehung: number;
  praezedenzwirkung: number;
  medienoeffentlichkeit: number;
  mitarbeitermoral: number;
  regulierung: number;
  strategischeBedeutung: number;
}
export const DEFAULT_QUALI_WEIGHTS: QualitativeWeights = {
  reputationsrisiko: 0.20,
  geschaeftsbeziehung: 0.15,
  praezedenzwirkung: 0.10,
  medienoeffentlichkeit: 0.10,
  mitarbeitermoral: 0.05,
  regulierung: 0.10,
  strategischeBedeutung: 0.30,
};
export function qualitativeScore(o: BusinessOption, weights: QualitativeWeights = DEFAULT_QUALI_WEIGHTS): number {
  const nm = o.nonMonetary;
  return (
    weights.reputationsrisiko * (10 - nm.reputationsrisiko) +
    weights.geschaeftsbeziehung * (10 - nm.geschaeftsbeziehungGefaehrdet) +
    weights.praezedenzwirkung * nm.praezedenzwirkung +
    weights.medienoeffentlichkeit * (10 - nm.medienoeffentlichkeit) +
    weights.mitarbeitermoral * (10 - nm.mitarbeitermoralAuswirkung) +
    weights.regulierung * 5 + // Default 5 if not set
    weights.strategischeBedeutung * 5 // Default 5 if not set
  );
}
/** Gewichtete Gesamtbewertung für Option */
export interface ComparisonWeights {
  erwartungswert: number;
  risiko: number;
  geschwindigkeit: number;
  qualitativ: number;
}
export const DEFAULT_COMPARISON_WEIGHTS: ComparisonWeights = {
  erwartungswert: 0.40,
  risiko: 0.30,
  geschwindigkeit: 0.20,
  qualitativ: 0.10,
};
export function weightedScore(
  o: BusinessOption,
  allOptions: BusinessOption[],
  weights: ComparisonWeights = DEFAULT_COMPARISON_WEIGHTS,
  diskontRate: number = 0.05,
): number {
  const evs = allOptions.map(opt => expectedValue(opt));
  const maxEv = Math.max(...evs.map(Math.abs), 1);
  const maxDuration = Math.max(...allOptions.map(opt => opt.timeframe.maxMonths), 1);

  const evNorm = expectedValue(o) / maxEv;
  const riskNorm = 1 - (downsideRisk(o) / Math.max(...allOptions.map(downsideRisk), 1));
  const speedNorm = 1 - (o.timeframe.maxMonths / maxDuration);
  const qualiNorm = qualitativeScore(o) / 10;

  return (
    weights.erwartungswert * evNorm +
    weights.risiko * riskNorm +
    weights.geschwindigkeit * speedNorm +
    weights.qualitativ * qualiNorm
  );
}
/** Recommendation strength based on weighted score */
export function recommendationStrength(score: number): {
  level: 'strong' | 'moderate' | 'conditional' | 'not_recommended';
  label: string;
  color: string;
} {
  if (score > 0.7) return { level: 'strong', label: 'Stark empfohlen', color: '#34c759' };
  if (score > 0.5) return { level: 'moderate', label: 'Empfohlen mit Vorbehalt', color: '#ff9500' };
  if (score > 0.3) return { level: 'conditional', label: 'Nur mit Risikominderung', color: '#ff9500' };
  return { level: 'not_recommended', label: 'Nicht empfohlen', color: '#ff3b30' };
}
/** Tornado sensitivity: which parameter changes EV the most? */
export interface TornadoItem {
  parameter: string;
  baseValue: number;
  lowValue: number;
  highValue: number;
  evAtLow: number;
  evAtHigh: number;
  spread: number;
}
export function tornadoAnalysis(o: BusinessOption, variation: number = 0.2): TornadoItem[] {
  const baseEv = expectedValue(o);
  const costs = totalCosts(o.costs);

  const params: { name: string; base: number; apply: (val: number) => number }[] = [
    {
      name: 'Erfolgswahrscheinlichkeit',
      base: o.risk.erfolgswahrscheinlichkeit,
      apply: (v) => {
        const p = v / 100;
        return p * o.risk.bestCase + (1 - p) * o.risk.worstCase - costs;
      },
    },
    {
      name: 'Best Case',
      base: o.risk.bestCase,
      apply: (v) => {
        const p = o.risk.erfolgswahrscheinlichkeit / 100;
        return p * v + (1 - p) * o.risk.worstCase - costs;
      },
    },
    {
      name: 'Worst Case',
      base: o.risk.worstCase,
      apply: (v) => {
        const p = o.risk.erfolgswahrscheinlichkeit / 100;
        return p * o.risk.bestCase + (1 - p) * v - costs;
      },
    },
    {
      name: 'Gesamtkosten',
      base: costs,
      apply: (v) => {
        const p = o.risk.erfolgswahrscheinlichkeit / 100;
        return p * o.risk.bestCase + (1 - p) * o.risk.worstCase - v;
      },
    },
  ];

  return params.map(param => {
    const low = param.base * (1 - variation);
    const high = param.base * (1 + variation);
    const evLow = param.apply(low);
    const evHigh = param.apply(high);
    return {
      parameter: param.name,
      baseValue: param.base,
      lowValue: low,
      highValue: high,
      evAtLow: evLow,
      evAtHigh: evHigh,
      spread: Math.abs(evHigh - evLow),
    };
  }).sort((a, b) => b.spread - a.spread);
}
