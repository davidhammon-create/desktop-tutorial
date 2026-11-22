import { jsPDF } from 'jspdf';
import {
  BusinessScenario, BusinessOption, totalCosts, expectedValue,
  argumentScore, breakEvenProbability, nettoRisiko, bruttoRisiko,
  computeRPN, valueAtRisk, monteCarloSimulation, sensitivityEV,
} from '@/types/business';
import {
  riskAdjustedValue, downsideRisk, sharpeRatio, kellyKriterium,
  weightedScore, recommendationStrength, tornadoAnalysis,
} from '@/types/businessFormulas';
const BLUE: [number, number, number] = [0, 122, 255];
const GREEN: [number, number, number] = [52, 199, 89];
const RED: [number, number, number] = [255, 59, 48];
const ORANGE: [number, number, number] = [255, 149, 0];
const DARK: [number, number, number] = [29, 29, 31];
const DIM: [number, number, number] = [134, 134, 139];
export function generateBusinessReportPdf(scenario: BusinessScenario) {
  const pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const W = 210;
  const M = 18;
  const CW = W - 2 * M;
  let y = M;
  // ?? Helpers ??
  const fmt = (n: number) => n.toLocaleString('de-DE', { maximumFractionDigits: 0 });
  const pct = (n: number) => `${n.toFixed(1)}%`;
  const addHeader = () => {
    pdf.setFillColor(...DARK);
    pdf.rect(0, 0, W, 16, 'F');
    pdf.setTextColor(255, 255, 255);
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'bold');
    pdf.text('MachiavelLEX ? Risiko-Analyse', M, 11);
    pdf.setFontSize(8);
    pdf.setFont('helvetica', 'normal');
    pdf.text(new Date().toLocaleDateString('de-DE'), W - M, 11, { align: 'right' });
    y = 24;
  };
  const checkPage = (needed: number) => {
    if (y + needed > 278) { pdf.addPage(); addHeader(); }
  };
  const sectionTitle = (title: string) => {
    checkPage(14);
    pdf.setFontSize(13);
    pdf.setFont('helvetica', 'bold');
    pdf.setTextColor(...DARK);
    pdf.text(title, M, y);
    y += 2;
    pdf.setDrawColor(...BLUE);
    pdf.setLineWidth(0.5);
    pdf.line(M, y, M + CW, y);
    y += 7;
  };
  const kv = (label: string, value: string, labelWidth = 55) => {
    checkPage(6);
    pdf.setFontSize(9);
    pdf.setFont('helvetica', 'bold');
    pdf.setTextColor(...DIM);
    pdf.text(label, M, y);
    pdf.setFont('helvetica', 'normal');
    pdf.setTextColor(...DARK);
    const lines = pdf.splitTextToSize(value || '?', CW - labelWidth);
    pdf.text(lines, M + labelWidth, y);
    y += Math.max(lines.length * 4.5, 5.5);
  };
  const bodyText = (text: string) => {
    checkPage(10);
    pdf.setFontSize(9);
    pdf.setFont('helvetica', 'normal');
    pdf.setTextColor(60, 60, 67);
    const lines = pdf.splitTextToSize(text, CW);
    pdf.text(lines, M, y);
    y += lines.length * 4.2 + 3;
  };
  const formulaBox = (title: string, formula: string, result: string) => {
    checkPage(20);
    pdf.setFillColor(245, 245, 247);
    pdf.roundedRect(M, y - 1, CW, 18, 2, 2, 'F');
    pdf.setFontSize(9);
    pdf.setFont('helvetica', 'bold');
    pdf.setTextColor(...BLUE);
    pdf.text(title, M + 4, y + 4);
    pdf.setFont('helvetica', 'normal');
    pdf.setTextColor(...DARK);
    pdf.setFontSize(8);
    pdf.text(formula, M + 4, y + 9);
    pdf.setFont('helvetica', 'bold');
    pdf.setFontSize(10);
    pdf.text(`= ${result}`, M + 4, y + 14);
    y += 21;
  };
  // ??????????????????????????????????????
  // PAGE 1: Overview
  // ??????????????????????????????????????
  addHeader();
  pdf.setFontSize(20);
  pdf.setFont('helvetica', 'bold');
  pdf.setTextColor(...DARK);
  pdf.text(scenario.title || 'Risiko-Analyse', M, y);
  y += 8;
  kv('Unternehmen', scenario.company);
  kv('Kategorie', scenario.category);
  kv('Status', scenario.status);
  kv('Erstellt', scenario.created);
  kv('Optionen', `${scenario.options.length}`);
  y += 4;
  if (scenario.description) {
    sectionTitle('Beschreibung');
    bodyText(scenario.description);
  }
  // ??????????????????????????????????????
  // OPTION DETAILS
  // ??????????????????????????????????????
  const opts = scenario.options;
  opts.forEach((o, idx) => {
    sectionTitle(`Option ${String.fromCharCode(65 + idx)}: ${o.label}`);
    if (o.description) bodyText(o.description);
    // Costs
    const costs = totalCosts(o.costs);
    kv('Anwaltskosten', `${fmt(o.costs.anwaltskosten)} €`);
    kv('Gerichtskosten', `${fmt(o.costs.gerichtskosten)} €`);
    kv('Interne Kosten', `${fmt(o.costs.interneKosten)} €`);
    kv('Opportunitätskosten', `${fmt(o.costs.opportunitaetskosten)} €`);
    kv('Gesamtkosten', `${fmt(costs)} €`);
    y += 2;
    // Risk params
    kv('Erfolgswahrsch.', pct(o.risk.erfolgswahrscheinlichkeit));
    kv('Best Case', `${fmt(o.risk.bestCase)} €`);
    kv('Worst Case', `${fmt(o.risk.worstCase)} €`);
    kv('Likely Case', `${fmt(o.risk.likelyCase)} €`);
    kv('Zeitrahmen', `${o.timeframe.minMonths}?${o.timeframe.maxMonths} Monate`);
    y += 4;
    // ?? Formulas ??
    const ev = expectedValue(o);
    const p = o.risk.erfolgswahrscheinlichkeit / 100;
    formulaBox(
      '1. Erwartungswert (EV)',
      `EV = ${pct(o.risk.erfolgswahrscheinlichkeit)} ? ${fmt(o.risk.bestCase)}€ + ${pct(100 - o.risk.erfolgswahrscheinlichkeit)} ? ${fmt(o.risk.worstCase)}€ ? ${fmt(costs)}€`,
      `${ev >= 0 ? '+' : ''}${fmt(ev)} €`,
    );
    const rav = riskAdjustedValue(o);
    const t = o.timeframe.maxMonths / 12;
    formulaBox(
      '2. Risikoadjustierter Wert (RAV)',
      `RAV = ${fmt(ev)}€ / (1 + 0,05)^${t.toFixed(2)} = ${fmt(ev)}€ / ${(Math.pow(1.05, t)).toFixed(3)}`,
      `${rav >= 0 ? '+' : ''}${fmt(rav)} €`,
    );
    const ds = downsideRisk(o);
    formulaBox(
      '3. Downside Risk',
      `DR = (1 ? ${pct(o.risk.erfolgswahrscheinlichkeit)}) ? |${fmt(o.risk.worstCase)}€| + ${fmt(costs)}€`,
      `${fmt(ds)} €`,
    );
    const beP = breakEvenProbability(o);
    formulaBox(
      '8. Break-Even-Wahrscheinlichkeit',
      `P_BE = Kosten / (Gewinn + |Verlust|) ? 100`,
      `${pct(beP)} ? ${o.risk.erfolgswahrscheinlichkeit > beP ? 'Lohnt sich ?' : 'Unter Break-Even ?'}`,
    );
    const sr = sharpeRatio(o);
    formulaBox(
      '6. Sharpe Ratio',
      `SR = (EV ? risikofreier Gewinn) / Standardabweichung`,
      `${sr.toFixed(2)} ${sr >= 1 ? '(Gut)' : sr >= 0.5 ? '(Akzeptabel)' : '(Schlecht)'}`,
    );
    const kelly = kellyKriterium(o);
    formulaBox(
      '7. Kelly-Kriterium',
      `f* = (p ? b ? q) / b`,
      `${(kelly * 100).toFixed(1)}% des Budgets`,
    );
    // VaR
    const var_ = valueAtRisk(o);
    kv('VaR 95%', `${fmt(var_.var95)} €`);
    kv('VaR 99%', `${fmt(var_.var99)} €`);
    // Monte Carlo summary
    const mc = monteCarloSimulation(o, 10000);
    checkPage(16);
    kv('Monte-Carlo (10.000 Runs)', '');
    kv('  Mittelwert', `${fmt(mc.mean)} €`);
    kv('  Median', `${fmt(mc.median)} €`);
    kv('  5. Perzentil', `${fmt(mc.p5)} €`);
    kv('  95. Perzentil', `${fmt(mc.p95)} €`);
    y += 3;
    // RPN Items
    if (o.riskItems && o.riskItems.length > 0) {
      checkPage(10);
      pdf.setFontSize(10);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(...DARK);
      pdf.text('Risikoprioritätszahlen (RPN)', M, y);
      y += 6;
      o.riskItems.forEach(ri => {
        const rpn = computeRPN(ri);
        checkPage(6);
        pdf.setFontSize(9);
        pdf.setFont('helvetica', 'normal');
        pdf.setTextColor(...(rpn >= 100 ? RED : DARK));
        pdf.text(`? ${ri.label}: A=${ri.auftretenswahrscheinlichkeit} ? B=${ri.bedeutung} ? E=${ri.entdeckungswahrscheinlichkeit} = ${rpn}${rpn >= 100 ? ' ? KRITISCH' : ''}`, M + 2, y);
        y += 5;
      });
      y += 3;
    }
    // Arguments
    const args = o.arguments || [];
    if (args.length > 0) {
      checkPage(10);
      const score = argumentScore(args);
      pdf.setFontSize(10);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(...DARK);
      pdf.text(`Argumente (Pro ? ${score.pro.toFixed(1)} / Contra ? ${score.contra.toFixed(1)} ? Netto: ${score.net >= 0 ? '+' : ''}${score.net.toFixed(1)})`, M, y);
      y += 6;
      args.forEach(a => {
        checkPage(6);
        pdf.setFontSize(9);
        pdf.setFont('helvetica', 'normal');
        pdf.setTextColor(...(a.side === 'pro' ? GREEN : RED));
        pdf.text(`${a.side === 'pro' ? '+' : '?'} [${a.weight}/10] ${a.text}`, M + 2, y);
        y += 5;
      });
      y += 3;
    }
    // Sensitivity (tornado)
    const tornado = tornadoAnalysis(o);
    if (tornado.length > 0) {
      checkPage(14);
      pdf.setFontSize(10);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(...DARK);
      pdf.text('Sensitivitätsanalyse (?20%)', M, y);
      y += 6;
      tornado.forEach(ti => {
        checkPage(6);
        pdf.setFontSize(9);
        pdf.setFont('helvetica', 'normal');
        pdf.setTextColor(...DARK);
        pdf.text(`${ti.parameter}: ${fmt(ti.evAtLow)}€ ? ${fmt(ti.evAtHigh)}€ (Spannweite: ${fmt(ti.spread)}€)`, M + 2, y);
        y += 5;
      });
      y += 5;
    }
  });
  // ??????????????????????????????????????
  // COMPARISON & RECOMMENDATION
  // ??????????????????????????????????????
  if (opts.length >= 2) {
    sectionTitle('Gesamtvergleich & Empfehlung');
    const scored = opts.map(o => ({
      o,
      ev: expectedValue(o),
      rav: riskAdjustedValue(o),
      ds: downsideRisk(o),
      sr: sharpeRatio(o),
      k: kellyKriterium(o),
      ws: weightedScore(o, opts),
    })).sort((a, b) => b.ws - a.ws);
    scored.forEach((s, rank) => {
      const idx = opts.findIndex(o => o.id === s.o.id);
      const strength = recommendationStrength(s.ws);
      checkPage(8);
      pdf.setFontSize(10);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(...(rank === 0 ? GREEN : DARK));
      pdf.text(`${rank + 1}. Option ${String.fromCharCode(65 + idx)}: ${s.o.label}${rank === 0 ? ' ? EMPFOHLEN' : ''}`, M, y);
      y += 5;
      pdf.setFontSize(9);
      pdf.setFont('helvetica', 'normal');
      pdf.setTextColor(...DIM);
      pdf.text(`Score: ${s.ws.toFixed(2)} (${strength.label}) | EW: ${fmt(s.ev)}€ | RAV: ${fmt(s.rav)}€ | Sharpe: ${s.sr.toFixed(2)} | Kelly: ${(s.k * 100).toFixed(0)}%`, M + 2, y);
      y += 7;
    });
    // Winner bar
    const best = scored[0];
    checkPage(12);
    pdf.setFillColor(228, 228, 237);
    pdf.roundedRect(M, y, CW, 5, 2, 2, 'F');
    pdf.setFillColor(...GREEN);
    pdf.roundedRect(M, y, CW * Math.min(best.ws, 1), 5, 2, 2, 'F');
    y += 10;
    pdf.setFontSize(9);
    pdf.setTextColor(...DIM);
    pdf.text(`Gewichtung: 40% EW ? 30% Risiko ? 20% Geschwindigkeit ? 10% Qualitativ`, M, y);
    y += 8;
  }
  // Notes
  if (scenario.notes) {
    sectionTitle('Notizen');
    bodyText(scenario.notes);
  }
  // Disclaimer
  checkPage(20);
  y += 4;
  pdf.setFillColor(255, 249, 235);
  pdf.roundedRect(M, y, CW, 16, 2, 2, 'F');
  pdf.setFontSize(8);
  pdf.setFont('helvetica', 'bold');
  pdf.setTextColor(...ORANGE);
  pdf.text('? Haftungsausschluss', M + 4, y + 5);
  pdf.setFont('helvetica', 'normal');
  pdf.setFontSize(7);
  pdf.setTextColor(100, 100, 100);
  pdf.text('Alle Berechnungen und KI-Schätzungen sind unverbindlich und ersetzen keine Rechtsberatung. Alle Werte müssen von einem qualifizierten Juristen geprüft werden.', M + 4, y + 10, { maxWidth: CW - 8 });
  y += 20;
  // Footer on all pages
  const pageCount = pdf.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    pdf.setPage(i);
    pdf.setFontSize(7);
    pdf.setTextColor(...DIM);
    pdf.text(`Seite ${i} von ${pageCount}`, W / 2, 292, { align: 'center' });
    pdf.text('Vertraulich ? MachiavelLEX', M, 292);
  }
  pdf.save(`Risiko-Analyse_${scenario.title.replace(/\s+/g, '_')}_${Date.now()}.pdf`);
}
/** Export scenario as JSON for import */
export function exportScenarioJson(scenario: BusinessScenario) {
  const blob = new Blob([JSON.stringify(scenario, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.download = `Szenario_${scenario.title.replace(/\s+/g, '_')}_${Date.now()}.json`;
  link.href = url;
  link.click();
  URL.revokeObjectURL(url);
}
/** Import scenario from JSON file */
export function importScenarioFromFile(file: File): Promise<BusinessScenario> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const data = JSON.parse(reader.result as string);
        if (!data.title || !data.options) throw new Error('Ungültiges Format');
        // Generate new ID to avoid collisions
        data.id = `biz-import-${Date.now()}`;
        resolve(data as BusinessScenario);
      } catch (e) {
        reject(new Error('Datei konnte nicht als Szenario gelesen werden'));
      }
    };
    reader.onerror = () => reject(new Error('Datei konnte nicht gelesen werden'));
    reader.readAsText(file);
  });
}
