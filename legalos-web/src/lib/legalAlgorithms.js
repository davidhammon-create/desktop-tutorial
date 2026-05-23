
/**
 * legalAlgorithms.js — Stochastisch-Juristische Berechnungsmaschine
 *
 * ══════════════════════════════════════════════════════════════════
 *  WICHTIG: Alle Berechnungen hier sind REIN ALGORITHMISCH (keine KI).
 *  KI-Aufrufe erfolgen ausschließlich über lib/kiProvider.js.
 * ══════════════════════════════════════════════════════════════════
 *
 * EXPORTIERTE FUNKTIONEN:
 * ─────────────────────────────────────────────────────────────────
 *  computePrognose(input)
 *    → Bayesianisches Update: Berechnet Erfolgsprognose (0–100%)
 *    → Eingabe: args, evidence, deadlines, persons, caseData
 *    → Ausgabe: { score, ci_low, ci_high, logOdds, sigma, steps, inputs }
 *
 *  runMonteCarlo({ baseResult, iterations })
 *    → Monte-Carlo-Simulation (Standard: 5.000 Iterationen)
 *    → Ausgabe: { mean, median, p10, p25, p75, p90, histogram, scenarios }
 *
 *  computeRisikoFaktoren(input)
 *    → 8 Risikodimensionen (Beweis, Richter, Recht, Kosten, Zeit, Gegner, Reputation, Vergleich)
 *    → Ausgabe: { faktoren[], gesamtrisiko, gesamtScore, steps }
 *
 *  computeBreakEven({ caseData })
 *    → Break-Even-Analyse: Mindest-Erfolgschance für wirtschaftliche Klage
 *    → Ausgabe: { break_even_pct, gesamtkosten, formel, erklaerung, zusatzoptionen[] }
 *
 *  computeVollanalyse(input)
 *    → Kombiniert alle vier Funktionen in einem Aufruf
 *    → Ausgabe: { prognose, risikofaktoren, monteCarlo, breakEven, timestamp, version }
 *
 * METHODIK:
 *   Bayesianische Inferenz, Monte-Carlo-Simulation,
 *   gewichtete Kombination juristischer Faktoren,
 *   statistische Konfidenzintervalle (90% CI via Fehlerfortpflanzung).
 *
 * ANPASSUNG DER GEWICHTE:
 *   Gewichtungskonstanten sind inline kommentiert (z.B. × 1.6, × 0.4).
 *   Basisraten je Rechtsgebiet → RECHTSGEBIET_BASERATES (Zeile ~21)
 *   Instanzfaktoren            → INSTANZ_FAKTOR (Zeile ~15)
 * ─────────────────────────────────────────────────────────────────
 */

/**
 * MachiavelLEX – Stochastisch-Juristische Berechnungsmaschine
 *
 * Alle Prognosen und Risikowerte werden OHNE KI berechnet.
 * Methoden: Bayesianische Inferenz, Monte-Carlo-Simulation,
 *           gewichtete Kombination juristischer Faktoren,
 *           statistische Konfidenzintervalle (90% CI).
 *
 * Transparenz: Jede Berechnung gibt `steps` zurück, die die
 * genaue Rechenschritte-Dokumentation enthalten.
 */

// ─── Konstanten & Gewichtungsmatrizen ────────────────────────────────────────

const INSTANZ_FAKTOR = {
  Erstinstanz: 1.0,
  Berufung: 0.88,    // Berufungsgerichte bestätigen i.d.R. ~70-75% Urteile
  Revision: 0.70,   // Revision: Nur Rechtsfehlerüberprüfung, enger Erfolgsraum
};

const RECHTSGEBIET_BASERATES = {
  Arbeitsrecht: 0.52,
  Mietrecht: 0.54,
  Vertragsrecht: 0.51,
  Familienrecht: 0.50,
  Gesellschaftsrecht: 0.49,
  Strafrecht: 0.35,    // Staatsanwaltschaft hat strukturellen Vorteil
  Verwaltungsrecht: 0.38,
  Insolvenzrecht: 0.48,
  IP: 0.50,
  default: 0.50,
};

// Kläger gewinnt statistisch in Deutschland etwa 50-55% der Verfahren
// Quelle: Statistisches Bundesamt, Rechtspflegestatistik
const BASE_WIN_RATE = 0.51;

// ─── Hilfsfunktionen ────────────────────────────────────────────────────────

function clamp(v, min = 0, max = 1) {
  return Math.max(min, Math.min(max, v));
}

function avg(arr) {
  if (!arr || arr.length
