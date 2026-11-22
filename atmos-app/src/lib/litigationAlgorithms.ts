/**
 * DETERMINISTIC LITIGATION ALGORITHMS
 * Rein algorithmische Prozessstrategie-Berechnungen.
 * KI ist OPTIONAL ? diese Funktionen arbeiten vollständig ohne KI.
 * KI kann die Ergebnisse anreichern/verfeinern, ist aber nie Voraussetzung.
 */
import { LexaraCase, LexaraArgument, LexaraEvidence, LexaraFrist, LexaraKosten, EVIDENCE_BASE_WEIGHTS } from '@/types/lexara';
import { computeWinProbability, computeKosten, computeEvidenceBoost, computeCredibility, getRVGGebuehr, computeFristUrgency, daysUntil } from './lexaraUtils';
// ???????????????????????????????????????????????????????????
// MODUL 1: ANSPRUCHSPYRAMIDE (Algorithmisch)
// ???????????????????????????????????????????????????????????
export interface AlgoAnspruch {
  ebene: 'primaer' | 'sekundaer' | 'hilfs' | 'prozessual';
  label: string;
  paragraphen: string;
  betrag: number | null;
  schluessigkeit_pct: number;
  beweisbarkeit_pct: number;
  verjaehrung_status: string;
  begruendung: string;
}
export function computeAnspruchspyramide(c: LexaraCase): { ansprueche: AlgoAnspruch[]; gesamtbetrag: number } {
  const { final, ownScore, oppScore } = computeWinProbability(c);
  const ownArgs = c.arguments.filter(a => a.side === 'own');
  const oppArgs = c.arguments.filter(a => a.side === 'opp');
  const streitwert = c.kosten?.streitwert || 0;
  // Derive claims from arguments - group by legal basis
  const ansprueche: AlgoAnspruch[] = [];
  // Primary claims from strong own arguments
  const strongOwn = ownArgs.filter(a => a.strength >= 7);
  const mediumOwn = ownArgs.filter(a => a.strength >= 4 && a.strength < 7);
  const weakOwn = ownArgs.filter(a => a.strength < 4);
  // Primary: strongest arguments
  for (const a of strongOwn) {
    const evs = c.evidence[a.id] || [];
    const evBoost = computeEvidenceBoost(evs);
    const beweisbarkeit = Math.min(95, Math.round(evBoost * 100 + 30 + evs.length * 10));
    ansprueche.push({
      ebene: 'primaer',
      label: a.label,
      paragraphen: a.legalBasis || extractLegalBasis(a),
      betrag: streitwert > 0 ? Math.round(streitwert * (a.strength / 10)) : null,
      schluessigkeit_pct: Math.min(95, Math.round(a.strength * 10 + (a.content?.length || 0) / 20)),
      beweisbarkeit_pct: beweisbarkeit,
      verjaehrung_status: computeVerjStatus(c),
      begruendung: `Starkes Argument (Kraft ${a.strength}/10) mit ${evs.length} Beweismittel(n).`,
    });
  }
  // Secondary: medium arguments
  for (const a of mediumOwn) {
    const evs = c.evidence[a.id] || [];
    ansprueche.push({
      ebene: 'sekundaer',
      label: a.label,
      paragraphen: a.legalBasis || extractLegalBasis(a),
      betrag: streitwert > 0 ? Math.round(streitwert * 0.3 * (a.strength / 10)) : null,
      schluessigkeit_pct: Math.min(85, Math.round(a.strength * 10 + 10)),
      beweisbarkeit_pct: Math.min(80, Math.round(evs.length * 15 + 20)),
      verjaehrung_status: computeVerjStatus(c),
      begruendung: `Unterstützendes Argument (Kraft ${a.strength}/10).`,
    });
  }
  // Hilfs: weak arguments
  for (const a of weakOwn) {
    ansprueche.push({
      ebene: 'hilfs',
      label: a.label,
      paragraphen: a.legalBasis || '',
      betrag: null,
      schluessigkeit_pct: Math.round(a.strength * 10),
      beweisbarkeit_pct: Math.round((c.evidence[a.id]?.length || 0) * 10 + 10),
      verjaehrung_status: computeVerjStatus(c),
      begruendung: `Hilfsargument ? geringe Durchsetzungskraft.`,
    });
  }
  // Prozessuale Nebenansprüche
  if (streitwert > 0) {
    ansprueche.push({
      ebene: 'prozessual',
      label: 'Verzugszinsen',
      paragraphen: '§ 288 BGB',
      betrag: Math.round(streitwert * 0.05),
      schluessigkeit_pct: 90,
      beweisbarkeit_pct: 85,
      verjaehrung_status: 'offen',
      begruendung: 'Gesetzliche Verzugszinsen ab Mahnung/Klage (5% über Basiszinssatz).',
    });
    ansprueche.push({
      ebene: 'prozessual',
      label: 'Vorgerichtliche RA-Kosten',
      paragraphen: '§ 280 BGB',
      betrag: Math.round(getRVGGebuehr(streitwert) * 1.3),
      schluessigkeit_pct: 75,
      beweisbarkeit_pct: 90,
      verjaehrung_status: 'offen',
      begruendung: '1.3 Geschäftsgebühr als Verzugsschaden.',
    });
  }
  const gesamtbetrag = ansprueche.reduce((s, a) => s + (a.betrag || 0), 0);
  return { ansprueche, gesamtbetrag };
}
function extractLegalBasis(a: LexaraArgument): string {
  const text = (a.content || '') + ' ' + (a.description || '') + ' ' + a.label;
  const match = text.match(/§\s*\d+[a-z]?\s*(?:Abs\.\s*\d+\s*)?(?:S\.\s*\d+\s*)?(?:BGB|ZPO|HGB|StGB|GmbHG|AktG|InsO|UWG|GWB|KSchG|BetrVG|AGG|MarkenG|UrhG|PatG)/i);
  return match ? match[0] : '';
}
function computeVerjStatus(c: LexaraCase): string {
  const verjFrist = c.fristen?.find(f => f.type.includes('Verjähr'));
  if (!verjFrist) return 'prüfen';
  const days = daysUntil(verjFrist.date);
  if (days <= 0) return '?? verjährt';
  if (days <= 90) return `?? ${days} Tage`;
  return 'offen';
}
// ???????????????????????????????????????????????????????????
// MODUL 2: BEWEISLÜCKEN-ANALYSE (Algorithmisch)
// ???????????????????????????????????????????????????????????
export interface AlgoBeweisluecke {
  merkmal: string;
  schweregrad: 'kritisch' | 'mittel' | 'gering';
  fehlender_beweis: string;
  massnahme: string;
  argument_id: string;
}
export interface AlgoBeweislastEintrag {
  tatbestandsmerkmal: string;
  beweislast_traeger: 'eigen' | 'gegner';
  beweismittel_vorhanden: boolean;
  beweismittel_typ: string;
  beweiskraft: 'stark' | 'mittel' | 'schwach';
  angreifbarkeit: string;
}
export function computeBeweisluecken(c: LexaraCase): {
  luecken: AlgoBeweisluecke[];
  beweislast_matrix: AlgoBeweislastEintrag[];
  gesamtbewertung: string;
} {
  const ownArgs = c.arguments.filter(a => a.side === 'own');
  const luecken: AlgoBeweisluecke[] = [];
  const matrix: AlgoBeweislastEintrag[] = [];
  for (const a of ownArgs) {
    const evs = c.evidence[a.id] || [];
    const totalStrength = evs.reduce((s, e) => s + (e.strength ?? 5), 0);
    const hasEvidence = evs.length > 0;
    // Build matrix entry
    const bestEv = evs.length > 0
      ? evs.reduce((best, e) => (e.strength ?? 5) > (best.strength ?? 5) ? e : best, evs[0])
      : null;
    matrix.push({
      tatbestandsmerkmal: a.label,
      beweislast_traeger: 'eigen',
      beweismittel_vorhanden: hasEvidence,
      beweismittel_typ: bestEv?.type || '?',
      beweiskraft: !hasEvidence ? 'schwach' : totalStrength / evs.length > 6 ? 'stark' : totalStrength / evs.length > 3 ? 'mittel' : 'schwach',
      angreifbarkeit: hasEvidence ? (evs.some(e => e.type === 'Zeuge (parteinah)' || e.type === 'Indizien') ? 'hoch' : 'mittel') : '?',
    });
    // Identify gaps
    if (!hasEvidence && a.strength >= 5) {
      luecken.push({
        merkmal: a.label,
        schweregrad: a.strength >= 8 ? 'kritisch' : 'mittel',
        fehlender_beweis: `Kein Beweismittel für "${a.label}" (Kraft ${a.strength}/10)`,
        massnahme: a.strength >= 8
          ? 'Sofortige Beweissicherung empfohlen (§§ 485 ff. ZPO). Urkundenvorlagepflicht prüfen.'
          : 'Beweismittel sammeln: Urkunden, Zeugen oder Sachverständige identifizieren.',
        argument_id: a.id,
      });
    } else if (hasEvidence && totalStrength / evs.length < 4) {
      luecken.push({
        merkmal: a.label,
        schweregrad: 'gering',
        fehlender_beweis: `Nur schwache Beweismittel vorhanden (? ${(totalStrength / evs.length).toFixed(1)}/10)`,
        massnahme: 'Corroborierende Beweismittel suchen. Sachverständigengutachten prüfen.',
        argument_id: a.id,
      });
    }
  }
  // Also check opponent arguments for counter-evidence gaps
  const oppArgs = c.arguments.filter(a => a.side === 'opp');
  for (const a of oppArgs) {
    matrix.push({
      tatbestandsmerkmal: `[Gegner] ${a.label}`,
      beweislast_traeger: 'gegner',
      beweismittel_vorhanden: (c.evidence[a.id]?.length || 0) > 0,
      beweismittel_typ: c.evidence[a.id]?.[0]?.type || '?',
      beweiskraft: (c.evidence[a.id]?.length || 0) > 0 ? 'mittel' : 'schwach',
      angreifbarkeit: 'prüfen',
    });
  }
  const kritisch = luecken.filter(l => l.schweregrad === 'kritisch').length;
  const mittel = luecken.filter(l => l.schweregrad === 'mittel').length;
  const gesamtbewertung = kritisch > 0
    ? `?? ${kritisch} kritische Beweislücke(n). Prozessrisiko erheblich erhöht. Beweissicherung vor Klageerhebung dringend empfohlen.`
    : mittel > 0
      ? `? ${mittel} mittlere Beweislücke(n). Beweisführung möglich, aber zusätzliche Beweismittel stärken die Position.`
      : '? Beweissituation solide. Alle wesentlichen Tatbestandsmerkmale sind durch Beweismittel gedeckt.';
  return { luecken, beweislast_matrix: matrix, gesamtbewertung };
}
// ???????????????????????????????????????????????????????????
// MODUL 3: VERGLEICHSKORRIDOR / ZOPA (Algorithmisch)
// ???????????????????????????????????????????????????????????
export interface AlgoZOPA {
  mindestbetrag_klaeger: number;
  maximalbetrag_beklagter: number;
  zopa_untergrenze: number;
  zopa_obergrenze: number;
  optimaler_vergleichsbetrag: number;
  rapb: number;
  diskontierungssatz: number;
  verfahrensdauer_monate: number;
  batna_wert: number;
  batna_beschreibung: string;
  stufenklage_sinnvoll: boolean;
  stufenklage_begruendung: string;
  empfehlung: string;
  berechnung_klaeger: string;
  berechnung_beklagter: string;
}
export function computeVergleichskorridor(c: LexaraCase): AlgoZOPA {
  const { final } = computeWinProbability(c);
  const kosten = c.kosten;
  const streitwert = kosten?.streitwert || 50000;
  const pGewinn = final / 100;
  const pVerlust = 1 - pGewinn;
  // Kosten berechnen
  const kostenData = kosten ? computeKosten(kosten) : null;
  const kostenSieg = kostenData?.szenarien[0]?.eigenKosten || streitwert * 0.1;
  const kostenNiederlage = kostenData ? Math.abs(kostenData.szenarien[1].netto) : streitwert * 0.3;
  const kostenVergleich = kostenData?.szenarien[2]?.eigenKosten || streitwert * 0.05;
  // Erwartungswert Klage
  const ewKlage = pGewinn * streitwert - pVerlust * kostenNiederlage;
  // Mindestbetrag Kläger: EW(Klage) - Kostendifferenz
  const mindestbetrag = Math.max(0, Math.round(ewKlage - (kostenSieg - kostenVergleich)));
  // Maximalbetrag Beklagter: Erwartete Kosten bei Verlust
  const maxBeklagter = Math.round(pGewinn * (streitwert + kostenNiederlage));
  // ZOPA
  const zopa_untergrenze = Math.round(mindestbetrag * 0.9);
  const zopa_obergrenze = Math.round(maxBeklagter * 1.05);
  const optimal = Math.round((zopa_untergrenze + zopa_obergrenze) / 2);
  // RAPB: Diskontierung
  const diskontierungssatz = 5;
  const verfahrensdauer = kosten?.instanz === 'Revision' ? 48 : kosten?.instanz === 'Berufung' ? 30 : 18;
  const diskontFaktor = Math.pow(1 + diskontierungssatz / 100, -(verfahrensdauer / 12));
  const rapb = Math.round(ewKlage * diskontFaktor);
  // BATNA
  const batna_wert = Math.round(kosten?.vergleichsangebot || streitwert * 0.3);
  // Stufenklage
  const hasAuskunftsBedarf = c.arguments.some(a =>
    a.side === 'own' && (a.label.toLowerCase().includes('auskunft') || a.label.toLowerCase().includes('schaden') || a.label.toLowerCase().includes('gewinn'))
  );
  const stufenklage_sinnvoll = hasAuskunftsBedarf && !streitwert;
  return {
    mindestbetrag_klaeger: mindestbetrag,
    maximalbetrag_beklagter: maxBeklagter,
    zopa_untergrenze,
    zopa_obergrenze,
    optimaler_vergleichsbetrag: optimal,
    rapb,
    diskontierungssatz,
    verfahrensdauer_monate: verfahrensdauer,
    batna_wert,
    batna_beschreibung: `Alternativwert basierend auf ${kosten?.vergleichsangebot ? 'Vergleichsangebot' : 'geschätztem Mindesterlös (30% Streitwert)'}`,
    stufenklage_sinnvoll,
    stufenklage_begruendung: stufenklage_sinnvoll
      ? 'Auskunftsanspruch vorgeschaltet ? Stufenklage nach § 254 ZPO empfohlen.'
      : 'Streitwert bestimmbar ? direkte Klage vorzuziehen.',
    empfehlung: rapb > batna_wert
      ? `Klage vorteilhaft: RAPB (${rapb.toLocaleString('de-DE')}€) > BATNA (${batna_wert.toLocaleString('de-DE')}€). Vergleichskorridor: ${zopa_untergrenze.toLocaleString('de-DE')}€ ? ${zopa_obergrenze.toLocaleString('de-DE')}€.`
      : `Vergleich anstreben: BATNA (${batna_wert.toLocaleString('de-DE')}€) ? RAPB (${rapb.toLocaleString('de-DE')}€). Optimaler Vergleich: ${optimal.toLocaleString('de-DE')}€.`,
    berechnung_klaeger: `EW(Klage) = ${pGewinn.toFixed(0)}% ? ${streitwert.toLocaleString('de-DE')}€ ? ${(pVerlust * 100).toFixed(0)}% ? ${kostenNiederlage.toLocaleString('de-DE')}€ = ${ewKlage.toLocaleString('de-DE')}€`,
    berechnung_beklagter: `EW(Verlust) = ${(pGewinn * 100).toFixed(0)}% ? (${streitwert.toLocaleString('de-DE')}€ + ${kostenNiederlage.toLocaleString('de-DE')}€) = ${maxBeklagter.toLocaleString('de-DE')}€`,
  };
}
// ???????????????????????????????????????????????????????????
// MODUL 4: MONTE-CARLO PROZESSRISIKO (Algorithmisch)
// ???????????????????????????????????????????????????????????
export interface AlgoRisikoResult {
  gesamt_erfolgswahrscheinlichkeit: number;
  erwartungswert: number;
  var_95: number;
  var_99: number;
  break_even_pct: number;
  sharpe_ratio: number;
  rapb: number;
  wahrscheinlichkeitsbaum: { stufe: number; name: string; wahrscheinlichkeit_pct: number; begruendung: string }[];
  instanz_kosten: { instanz: string; szenario: string; gerichtsgebuehren: number; eigen_anwalt: number; gegner_anwalt: number; netto: number }[];
  empfehlung: string;
}
export function computeProzessrisiko(c: LexaraCase): AlgoRisikoResult {
  const { final, ownScore, oppScore, evBoostOwn, fristenAbzug, judgeCalib } = computeWinProbability(c);
  const kosten = c.kosten;
  const streitwert = kosten?.streitwert || 50000;
  // Wahrscheinlichkeitsbaum (5 Stufen)
  const schluesselArgs = c.arguments.filter(a => a.side === 'own');
  const allEvidence = schluesselArgs.flatMap(a => c.evidence[a.id] || []);
  const pSchluessigkeit = Math.min(95, Math.max(15, Math.round(
    schluesselArgs.length > 0 ? 40 + (schluesselArgs.reduce((s, a) => s + a.strength, 0) / schluesselArgs.length) * 5 : 30
  )));
  const pBeweis = Math.min(95, Math.max(15, Math.round(
    allEvidence.length > 0 ? 30 + allEvidence.length * 8 + evBoostOwn * 30 : 25
  )));
  const pRechtlich = Math.min(90, Math.max(20, Math.round(final * 0.8 + 15)));
  const pRechtsmittel = Math.min(85, Math.max(30, Math.round(60 + judgeCalib * 100)));
  const judge = c.persons.find(p => p.role === 'Richter');
  const pVollstreckung = Math.min(95, Math.max(40, 75)); // default without opponent financial data
  const wahrscheinlichkeitsbaum = [
    { stufe: 1, name: 'Schlüssigkeitsprüfung', wahrscheinlichkeit_pct: pSchluessigkeit, begruendung: `${schluesselArgs.length} Argumente, ? Stärke ${schluesselArgs.length > 0 ? (schluesselArgs.reduce((s, a) => s + a.strength, 0) / schluesselArgs.length).toFixed(1) : '?'}` },
    { stufe: 2, name: 'Beweisaufnahme', wahrscheinlichkeit_pct: pBeweis, begruendung: `${allEvidence.length} Beweismittel, Boost ${(evBoostOwn * 100).toFixed(0)}%` },
    { stufe: 3, name: 'Rechtliche Bewertung', wahrscheinlichkeit_pct: pRechtlich, begruendung: `Prognose ${final}%, Richter-Kalibrierung ${judgeCalib > 0 ? '+' : ''}${(judgeCalib * 100).toFixed(1)}%` },
    { stufe: 4, name: 'Rechtsmittelrisiko', wahrscheinlichkeit_pct: pRechtsmittel, begruendung: `Berufungswahrscheinlichkeit ca. ${100 - pRechtsmittel}%` },
    { stufe: 5, name: 'Vollstreckung', wahrscheinlichkeit_pct: pVollstreckung, begruendung: 'Standard-Vollstreckungswahrscheinlichkeit' },
  ];
  const gesamtP = wahrscheinlichkeitsbaum.reduce((p, s) => p * s.wahrscheinlichkeit_pct / 100, 1);
  const gesamt = Math.round(gesamtP * 100);
  // Monte-Carlo (1000 Simulationen)
  const results: number[] = [];
  const kostenData = kosten ? computeKosten(kosten) : null;
  const kostenVerlust = kostenData ? Math.abs(kostenData.szenarien[1].netto) : streitwert * 0.3;
  for (let i = 0; i < 1000; i++) {
    // Jitter each probability ?15%
    const pSim = wahrscheinlichkeitsbaum.reduce((p, s) => {
      const jitter = 1 + (Math.random() - 0.5) * 0.3;
      return p * Math.min(1, Math.max(0, s.wahrscheinlichkeit_pct / 100 * jitter));
    }, 1);
    const win = Math.random() < pSim;
    results.push(win ? streitwert - (kostenData?.szenarien[0]?.eigenKosten || streitwert * 0.1) : -kostenVerlust);
  }
  results.sort((a, b) => a - b);
  const ewSim = Math.round(results.reduce((s, v) => s + v, 0) / results.length);
  const var95 = Math.round(results[Math.floor(results.length * 0.05)]);
  const var99 = Math.round(results[Math.floor(results.length * 0.01)]);
  const stdDev = Math.sqrt(results.reduce((s, v) => s + Math.pow(v - ewSim, 2), 0) / results.length);
  const sharpe = stdDev > 0 ? Math.round((ewSim / stdDev) * 100) / 100 : 0;
  const breakEven = Math.round(kostenVerlust / (streitwert + kostenVerlust) * 100);
  // Diskontierung
  const verfahrensdauer = kosten?.instanz === 'Revision' ? 48 : kosten?.instanz === 'Berufung' ? 30 : 18;
  const rapb = Math.round(ewSim * Math.pow(1.05, -(verfahrensdauer / 12)));
  // Instanz-Kosten
  const instanz_kosten: AlgoRisikoResult['instanz_kosten'] = [];
  if (kostenData) {
    for (const sz of kostenData.szenarien) {
      instanz_kosten.push({
        instanz: kosten?.instanz || 'Erstinstanz',
        szenario: sz.label,
        gerichtsgebuehren: sz.gerichtsKosten,
        eigen_anwalt: sz.eigenKosten,
        gegner_anwalt: sz.gegnerKosten,
        netto: sz.netto,
      });
    }
  }
  const empfehlung = gesamt >= 50
    ? `Gesamterfolgswahrscheinlichkeit ${gesamt}% ? Klage vertretbar. EW: ${ewSim.toLocaleString('de-DE')}€, VaR 95%: ${var95.toLocaleString('de-DE')}€.`
    : gesamt >= 30
      ? `Gesamterfolgswahrscheinlichkeit ${gesamt}% ? Vergleich erwägen. EW: ${ewSim.toLocaleString('de-DE')}€. Break-Even bei ${breakEven}%.`
      : `Gesamterfolgswahrscheinlichkeit nur ${gesamt}% ? Klage nicht empfohlen. Negativer EW: ${ewSim.toLocaleString('de-DE')}€.`;
  return {
    gesamt_erfolgswahrscheinlichkeit: gesamt,
    erwartungswert: ewSim,
    var_95: var95,
    var_99: var99,
    break_even_pct: breakEven,
    sharpe_ratio: sharpe,
    rapb,
    wahrscheinlichkeitsbaum,
    instanz_kosten,
    empfehlung,
  };
}
// ???????????????????????????????????????????????????????????
// MODUL 5: DYNAMISCHE STRATEGIE (Algorithmisch)
// ???????????????????????????????????????????????????????????
export interface AlgoStrategieOption {
  name: string;
  erwartungswert: number;
  risiko_score: number;
  empfohlen: boolean;
  dominiert: boolean;
  verfahrensart: string;
  zeitpunkt: string;
  instanzenziel: string;
  kooperation: string;
}
export function computeDynamischeStrategie(c: LexaraCase): {
  strategieoptionen: AlgoStrategieOption[];
  trigger_ereignisse: { ereignis: string; auswirkung: string; reaktion: string }[];
  eskalationsmassnahmen: { typ: 'eskalation' | 'de_eskalation'; massnahme: string; erwartete_wirkung: string }[];
  naechste_schritte: { nr: number; aktion: string; wann: string; ziel: string }[];
  empfehlung: string;
} {
  const { final } = computeWinProbability(c);
  const kosten = c.kosten;
  const streitwert = kosten?.streitwert || 50000;
  const zopa = computeVergleichskorridor(c);
  const risiko = computeProzessrisiko(c);
  // Strategieoptionen ableiten
  const optionen: AlgoStrategieOption[] = [
    {
      name: 'Direktklage (1. Instanz)',
      erwartungswert: risiko.erwartungswert,
      risiko_score: Math.round((100 - risiko.gesamt_erfolgswahrscheinlichkeit) / 10),
      empfohlen: final >= 60,
      dominiert: false,
      verfahrensart: 'Zivilklage',
      zeitpunkt: 'Sofort',
      instanzenziel: '1. Instanz',
      kooperation: final >= 70 ? 'Streitig' : 'Vergleichsbereit',
    },
    {
      name: 'Außergerichtliche Einigung',
      erwartungswert: zopa.optimaler_vergleichsbetrag,
      risiko_score: 2,
      empfohlen: final >= 35 && final < 60,
      dominiert: false,
      verfahrensart: 'Außergerichtlich',
      zeitpunkt: 'Sofort',
      instanzenziel: '?',
      kooperation: 'Aktiver Vergleich',
    },
    {
      name: 'Einstweiliger Rechtsschutz + Hauptsache',
      erwartungswert: Math.round(risiko.erwartungswert * 1.1),
      risiko_score: Math.round((100 - final) / 8),
      empfohlen: false,
      dominiert: final < 50,
      verfahrensart: 'eV + Klage',
      zeitpunkt: 'Sofort (Dringlichkeit)',
      instanzenziel: '1. Instanz + Eilverfahren',
      kooperation: 'Streitig',
    },
    {
      name: 'Abwarten + Beweissicherung',
      erwartungswert: Math.round(risiko.erwartungswert * 0.95),
      risiko_score: 4,
      empfohlen: false,
      dominiert: final >= 70,
      verfahrensart: '§485 ZPO Beweissicherung',
      zeitpunkt: '2-4 Wochen',
      instanzenziel: '?',
      kooperation: 'Vergleichssignal nach Sicherung',
    },
  ];
  // Mark dominated
  for (let i = 0; i < optionen.length; i++) {
    for (let j = 0; j < optionen.length; j++) {
      if (i !== j && optionen[j].erwartungswert >= optionen[i].erwartungswert && optionen[j].risiko_score <= optionen[i].risiko_score) {
        optionen[i].dominiert = true;
      }
    }
  }
  // Trigger-Ereignisse
  const trigger = [
    { ereignis: 'Klageerwiderung eingeht', auswirkung: 'Gegnerische Position wird klar', reaktion: 'Strategie-Neubewertung, ggf. Vergleichskorrektur' },
    { ereignis: 'Richterlicher Hinweis (§ 139 ZPO)', auswirkung: 'Vorläufige Rechtsauffassung des Gerichts', reaktion: 'Sofortige Analyse ? Vergleichsfenster oder Klageverstärkung' },
    { ereignis: 'Beweisaufnahme-Ergebnis', auswirkung: 'Bestätigt oder erschüttert Beweislage', reaktion: 'EW und ZOPA aktualisieren' },
  ];
  if (c.fristen?.some(f => f.type.includes('Verjähr') && daysUntil(f.date) < 180)) {
    trigger.unshift({ ereignis: 'Verjährungsfrist nähert sich', auswirkung: 'Zeitdruck steigt', reaktion: 'Verjährungshemmung durch Verhandlung (§ 203 BGB) oder Mahnbescheid prüfen' });
  }
  // Eskalation/De-Eskalation
  const eskalation = [
    { typ: 'eskalation' as const, massnahme: 'Einstweilige Verfügung beantragen', erwartete_wirkung: 'Starker Druck auf Gegner, schnelle Sicherung' },
    { typ: 'eskalation' as const, massnahme: 'Strafanzeige prüfen (bei Strafrechtsgehalt)', erwartete_wirkung: 'Zusätzlicher Druck, Beweissicherung durch StA' },
    { typ: 'de_eskalation' as const, massnahme: 'Mediationsangebot', erwartete_wirkung: 'Kostenersparnis, Geschäftsbeziehung erhalten' },
    { typ: 'de_eskalation' as const, massnahme: 'Teilrücknahme als Verhandlungsöffnung', erwartete_wirkung: 'Signal der Kompromissbereitschaft' },
  ];
  // Nächste Schritte
  const steps = [];
  const urgentFristen = (c.fristen || []).filter(f => f.status === 'offen' && daysUntil(f.date) <= 14);
  if (urgentFristen.length > 0) {
    steps.push({ nr: 1, aktion: `Dringende Frist(en) bearbeiten: ${urgentFristen.map(f => f.type).join(', ')}`, wann: 'Sofort', ziel: 'Fristwahrung' });
  }
  const beweisluecken = computeBeweisluecken(c);
  if (beweisluecken.luecken.filter(l => l.schweregrad === 'kritisch').length > 0) {
    steps.push({ nr: steps.length + 1, aktion: 'Kritische Beweislücken schließen', wann: '1-2 Wochen', ziel: 'Beweissicherung vor Klageerhebung' });
  }
  steps.push({ nr: steps.length + 1, aktion: final >= 50 ? 'Außergerichtliches Mahnschreiben mit Frist' : 'Vergleichsangebot formulieren', wann: '1 Woche', ziel: final >= 50 ? 'Druckaufbau + Inverzugsetzung' : 'Kostenoptimierung' });
  steps.push({ nr: steps.length + 1, aktion: 'Strategie nach Gegnerreaktion anpassen', wann: 'Nach Fristablauf', ziel: 'Optimale nächste Eskalationsstufe' });
  return {
    strategieoptionen: optionen,
    trigger_ereignisse: trigger,
    eskalationsmassnahmen: eskalation,
    naechste_schritte: steps,
    empfehlung: optionen.find(o => o.empfohlen)
      ? `Empfohlene Strategie: "${optionen.find(o => o.empfohlen)!.name}" (EW: ${optionen.find(o => o.empfohlen)!.erwartungswert.toLocaleString('de-DE')}€, Risiko: ${optionen.find(o => o.empfohlen)!.risiko_score}/10).`
      : 'Keine eindeutige Empfehlung ? alle Optionen prüfen.',
  };
}
// ???????????????????????????????????????????????????????????
// MODUL 6: GEGNER-ANALYSE (Algorithmisch)
// ???????????????????????????????????????????????????????????
export function computeGegnerAnalyse(c: LexaraCase): {
  vollstreckungswahrscheinlichkeit: number;
  vergleichsmotivation: number;
  gegenansprueche: { anspruch: string; betrag: number | null; wahrscheinlichkeit: number }[];
  netto_prozessgegenstand: number;
  schwachstellen: string[];
  prozessverhalten_prognose: string;
  empfehlung: string;
} {
  const { final, oppScore } = computeWinProbability(c);
  const oppArgs = c.arguments.filter(a => a.side === 'opp');
  const streitwert = c.kosten?.streitwert || 50000;
  // Gegner-Profil aus Personen
  const gegnerAnwalt = c.persons.find(p => p.role === 'Anwalt' && p.party === 'Beklagte');
  const gegnerZeugen = c.persons.filter(p => p.role === 'Zeuge' && p.party === 'Beklagte');
  // Vollstreckungswahrscheinlichkeit (default ohne spezifische Finanzdaten)
  const vollstreckung = 75;
  // Vergleichsmotivation = höher wenn eigene Position stark
  const vergleichsmotivation = Math.min(95, Math.max(10, Math.round(final * 0.8 + 15)));
  // Gegenansprüche aus Gegner-Argumenten ableiten
  const gegenansprueche = oppArgs.slice(0, 5).map(a => ({
    anspruch: a.label,
    betrag: a.strength >= 5 ? Math.round(streitwert * (a.strength / 20)) : null,
    wahrscheinlichkeit: Math.min(80, Math.round(a.strength * 8 + (c.evidence[a.id]?.length || 0) * 10)),
  }));
  const gegnerGesamt = gegenansprueche.reduce((s, g) => s + (g.betrag || 0) * g.wahrscheinlichkeit / 100, 0);
  const netto = Math.round(streitwert * final / 100 - gegnerGesamt);
  // Schwachstellen des Gegners identifizieren
  const schwachstellen: string[] = [];
  const weakOppArgs = oppArgs.filter(a => a.strength < 4);
  if (weakOppArgs.length > 0) schwachstellen.push(`${weakOppArgs.length} schwache Gegenargument(e) ? angreifbar`);
  const oppArgsOhneEv = oppArgs.filter(a => !(c.evidence[a.id]?.length));
  if (oppArgsOhneEv.length > 0) schwachstellen.push(`${oppArgsOhneEv.length} Gegenargument(e) ohne Beweismittel`);
  const lowCredZeugen = gegnerZeugen.filter(p => {
    const cr = computeCredibility(p);
    return cr !== null && cr < 40;
  });
  if (lowCredZeugen.length > 0) schwachstellen.push(`${lowCredZeugen.length} Zeuge(n) mit niedriger Glaubwürdigkeit`);
  if (oppArgs.length === 0) schwachstellen.push('Keine strukturierten Gegenargumente bekannt');
  return {
    vollstreckungswahrscheinlichkeit: vollstreckung,
    vergleichsmotivation,
    gegenansprueche,
    netto_prozessgegenstand: netto,
    schwachstellen,
    prozessverhalten_prognose: gegnerAnwalt
      ? `Gegnerischer Anwalt (${gegnerAnwalt.name}): Kompetenz ${gegnerAnwalt.competenceLevel}/100. ${gegnerAnwalt.manipulationSkill > 50 ? 'Hohe taktische Fähigkeiten ? vorsichtig agieren.' : 'Standard-Prozessführung zu erwarten.'}`
      : 'Keine Informationen zum gegnerischen Anwalt verfügbar.',
    empfehlung: netto > 0
      ? `Netto-Prozessgegenstand positiv (${netto.toLocaleString('de-DE')}€). Klage/Vergleich lohnenswert.`
      : `?? Netto-Prozessgegenstand negativ (${netto.toLocaleString('de-DE')}€). Gegenansprüche übersteigen eigene Position.`,
  };
}
// ???????????????????????????????????????????????????????????
// MODUL 7: VERHANDLUNGSSIMULATION (Algorithmisch)
// ???????????????????????????????????????????????????????????
export interface VerhandlungsPrioritaet {
  argument_id: string;
  label: string;
  side: 'own' | 'opp';
  strength: number;
  score_impact: number; // Wie viel % der Gesamtprognose hängt an diesem Argument
  evidence_count: number;
  priority_rank: number;
  empfehlung: string;
}
export interface TauschOption {
  aufgeben_id: string;
  aufgeben_label: string;
  aufgeben_score_verlust: number;
  erhalten_id: string;
  erhalten_label: string;
  erhalten_score_gewinn: number;
  netto_effekt: number;
}
export function computeVerhandlungssimulation(c: LexaraCase): {
  prioritaeten: VerhandlungsPrioritaet[];
  tausch_optionen: TauschOption[];
  batna: { wert: number; schwelle: number; empfehlung: string };
  verhandlungsstaerke: number;
  empfehlung: string;
} {
  const { final, ownScore, oppScore } = computeWinProbability(c);
  const total = ownScore + oppScore;
  // Prioritätenliste: Welche Argumente sind am wichtigsten?
  const allArgs = c.arguments.map(a => {
    const evs = c.evidence[a.id] || [];
    const effectiveStrength = a.strength * (1 + computeEvidenceBoost(evs));
    const impact = total > 0 ? (effectiveStrength / total) * 100 : 0;
    return {
      argument_id: a.id,
      label: a.label,
      side: a.side,
      strength: a.strength,
      score_impact: Math.round(impact * 10) / 10,
      evidence_count: evs.length,
      priority_rank: 0,
      empfehlung: '',
    };
  });
  // Sort: opponent arguments with HIGH impact = highest priority to neutralize
  // Own arguments with HIGH impact = must protect
  const oppPriorities = allArgs.filter(a => a.side === 'opp').sort((a, b) => b.score_impact - a.score_impact);
  const ownPriorities = allArgs.filter(a => a.side === 'own').sort((a, b) => b.score_impact - a.score_impact);
  const prioritaeten: VerhandlungsPrioritaet[] = [];
  let rank = 1;
  // Top opponent threats (to neutralize)
  for (const p of oppPriorities) {
    p.priority_rank = rank++;
    p.empfehlung = p.score_impact > 10
      ? '? Kritisch ? muss in Verhandlung neutralisiert werden'
      : p.score_impact > 5
        ? '? Wichtig ? Gegenbeweis oder Entkräftung vorbereiten'
        : '? Gering ? kann akzeptiert werden wenn nötig';
    prioritaeten.push(p);
  }
  // Own strengths (to leverage)
  for (const p of ownPriorities) {
    p.priority_rank = rank++;
    p.empfehlung = p.score_impact > 10
      ? '? Kernargument ? maximal nutzen, nicht aufgeben'
      : p.score_impact > 5
        ? '? Solide Position ? als Verhandlungsstärke einsetzen'
        : '? Verhandlungsmasse ? kann als Konzession angeboten werden';
    prioritaeten.push(p);
  }
  // Tausch-Analyse: Welche Konzessionen kosten am wenigsten?
  const tausch_optionen: TauschOption[] = [];
  const konzessionsfaehig = ownPriorities.filter(a => a.score_impact < 8).sort((a, b) => a.score_impact - b.score_impact);
  const wertvolle_gegner = oppPriorities.filter(a => a.score_impact > 3).sort((a, b) => b.score_impact - a.score_impact);
  for (let i = 0; i < Math.min(konzessionsfaehig.length, 5); i++) {
    for (let j = 0; j < Math.min(wertvolle_gegner.length, 3); j++) {
      const netto = wertvolle_gegner[j].score_impact - konzessionsfaehig[i].score_impact;
      if (netto > 0) {
        tausch_optionen.push({
          aufgeben_id: konzessionsfaehig[i].argument_id,
          aufgeben_label: konzessionsfaehig[i].label,
          aufgeben_score_verlust: konzessionsfaehig[i].score_impact,
          erhalten_id: wertvolle_gegner[j].argument_id,
          erhalten_label: wertvolle_gegner[j].label,
          erhalten_score_gewinn: wertvolle_gegner[j].score_impact,
          netto_effekt: Math.round(netto * 10) / 10,
        });
      }
    }
  }
  tausch_optionen.sort((a, b) => b.netto_effekt - a.netto_effekt);
  // BATNA
  const streitwert = c.kosten?.streitwert || 50000;
  const batnaWert = c.kosten?.vergleichsangebot || Math.round(streitwert * 0.3);
  const schwelle = Math.round(streitwert * (final / 100) * 0.7); // 70% des EW als Mindestschwelle
  // Verhandlungsstärke
  const verhandlungsstaerke = Math.min(100, Math.max(5, Math.round(
    (ownScore / Math.max(1, total)) * 60 +
    (c.arguments.filter(a => a.side === 'own').length > c.arguments.filter(a => a.side === 'opp').length ? 15 : 0) +
    (Object.values(c.evidence).flat().length * 3) +
    (final > 60 ? 15 : 0)
  )));
  return {
    prioritaeten,
    tausch_optionen: tausch_optionen.slice(0, 10),
    batna: {
      wert: batnaWert,
      schwelle,
      empfehlung: final >= 50
        ? `BATNA ${batnaWert.toLocaleString('de-DE')}€. Verhandeln Sie nicht unter ${schwelle.toLocaleString('de-DE')}€ (70% des EW). Ihre Position ist stark.`
        : `BATNA ${batnaWert.toLocaleString('de-DE')}€. Mindest-Vergleichsschwelle ${schwelle.toLocaleString('de-DE')}€. Vergleich aktiv anstreben.`,
    },
    verhandlungsstaerke,
    empfehlung: verhandlungsstaerke >= 60
      ? `Starke Verhandlungsposition (${verhandlungsstaerke}/100). ${tausch_optionen.length} Tausch-Optionen verfügbar. Aggressive Verhandlung möglich.`
      : `Moderate Verhandlungsposition (${verhandlungsstaerke}/100). Konzessionen vorbereiten. ${prioritaeten.filter(p => p.side === 'own' && p.score_impact < 5).length} Positionen als Verhandlungsmasse nutzbar.`,
  };
}
// ???????????????????????????????????????????????????????????
// GESAMTANALYSE: Alle Module zusammenführen
// ???????????????????????????????????????????????????????????
export function computeGesamtanalyse(c: LexaraCase) {
  const { final } = computeWinProbability(c);
  const ansprueche = computeAnspruchspyramide(c);
  const beweisluecken = computeBeweisluecken(c);
  const zopa = computeVergleichskorridor(c);
  const risiko = computeProzessrisiko(c);
  const gegner = computeGegnerAnalyse(c);
  const verhandlung = computeVerhandlungssimulation(c);
  const empfehlung = final >= 60 ? 'klage' : final >= 35 ? 'vergleich' : 'aufgabe';
  const empLabel = empfehlung === 'klage' ? 'Klage erheben' : empfehlung === 'vergleich' ? 'Vergleich anstreben' : 'Schadensminimierung';
  return {
    empfehlung,
    begruendung: `Prognose ${final}%. ${risiko.empfehlung} Verhandlungsstärke: ${verhandlung.verhandlungsstaerke}/100.`,
    ansprueche_top3: ansprueche.ansprueche.filter(a => a.ebene === 'primaer').slice(0, 3).map(a => ({
      anspruchsgrundlage: a.label,
      paragraphen: a.paragraphen,
      erfolgswahrscheinlichkeit: a.schluessigkeit_pct,
      betrag: a.betrag,
    })),
    risiko: {
      erwartungswert: risiko.erwartungswert,
      var_95: risiko.var_95,
      break_even: risiko.break_even_pct,
      sharpe_ratio: risiko.sharpe_ratio,
    },
    zopa: {
      untergrenze: zopa.zopa_untergrenze,
      obergrenze: zopa.zopa_obergrenze,
      optimal: zopa.optimaler_vergleichsbetrag,
    },
    kritische_beweisluecken: beweisluecken.luecken.filter(l => l.schweregrad === 'kritisch').map(l => ({
      merkmal: l.merkmal,
      massnahme: l.massnahme,
    })),
    naechste_schritte: [
      { nr: 1, aktion: empLabel, timing: 'Innerhalb 1 Woche' },
      { nr: 2, aktion: beweisluecken.luecken.length > 0 ? 'Beweislücken schließen' : 'Beweismittel sichern', timing: '2 Wochen' },
      { nr: 3, aktion: 'Vergleichskorridor kommunizieren', timing: 'Nach Gegnerreaktion' },
    ],
  };
}
