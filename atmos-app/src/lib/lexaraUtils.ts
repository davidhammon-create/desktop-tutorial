import { LexaraCase, LexaraPerson, LexaraEvidence, LexaraFrist, LexaraKosten, EVIDENCE_BASE_WEIGHTS, StrategieEmpfehlung } from '@/types/lexara';
// ??? Stufe 2: Beweisboost ???
export function computeEvidenceBoost(evs: LexaraEvidence[] | undefined): number {
  if (!evs || evs.length === 0) return 0;
  const chainResult = evs.reduce((s, e) => {
    const kraft = (e.strength ?? 5) / 10;
    const gueltigkeit = (e.validity ?? 50) / 100;
    return s + kraft * gueltigkeit * 10; // Gesamtstärke_i = Kraft ? Gültigkeit
  }, 0);
  // Boost-Faktor = 1 + (Kettenergebnis / 10) ? 0.5  ? we return just the boost portion
  return (chainResult / 10) * 0.5;
}
// ??? Zeugen-Glaubwürdigkeit (personenbezogen, nicht argumentbasiert) ???
export function computeCredibility(p: LexaraPerson): number | null {
  if (p.role === 'Richter' || p.role === 'Anwalt') return null;
  const raw = (
    p.historicalConsistency * 0.20 +
    (100 - p.conflictOfInterest) * 0.15 +
    (100 - p.hiddenMotive) * 0.15 +
    p.competenceLevel * 0.10 +
    (100 - p.manipulationSkill) * 0.15 +
    p.affectiveEmpathy * 0.10 +
    (100 - p.narcissism) * 0.10 +
    (100 - p.coldness) * 0.05
  );
  return Math.round(Math.max(0, Math.min(100, raw)));
}
// ??? Dark-Empath-Score (Kap. Psychologisches Profil) ???
// Dark Empath = hohe kognitive Empathie + niedrige affektive Empathie + dunkle Triade
export function computeDarkEmpathScore(p: LexaraPerson): number | null {
  if (p.role === 'Richter' || p.role === 'Anwalt') return null;
  const darkTriadAvg = ((p.narcissism || 0) + (p.manipulationSkill || 0) + (p.coldness || 0)) / 3;
  const empathyGap = Math.max(0, (p.cognitiveEmpathy || 50) - (p.affectiveEmpathy || 50));
  // Dark Empath: hohe dunkle Triade + große Empathie-Lücke (lesen können, aber nicht fühlen)
  const raw = darkTriadAvg * 0.55 + empathyGap * 0.45;
  return Math.round(Math.max(0, Math.min(100, raw)));
}
// ??? Machiavellischer Risiko-Index (taktische Gefährlichkeit) ???
export function computeMachiavelliRisk(p: LexaraPerson): number | null {
  if (p.role === 'Richter' || p.role === 'Anwalt') return null;
  const raw = (
    p.selfPreservation * 0.15 +
    p.hiddenMotive * 0.20 +
    p.loyaltySignals * 0.15 +
    p.fearFactor * 0.05 +
    (p.manipulationSkill || 0) * 0.20 +
    (p.cognitiveEmpathy || 50) * 0.10 +
    (100 - (p.affectiveEmpathy || 50)) * 0.15
  );
  return Math.round(Math.max(0, Math.min(100, raw)));
}
// ??? Persönlichkeitstyp-Klassifikation ???
export function classifyPersonality(p: LexaraPerson): { label: string; color: string; desc: string } {
  const darkTriadAvg = ((p.narcissism || 0) + (p.manipulationSkill || 0) + (p.coldness || 0)) / 3;
  const cogEmp = p.cognitiveEmpathy || 50;
  const affEmp = p.affectiveEmpathy || 50;
  if (darkTriadAvg >= 50 && cogEmp >= 55 && affEmp < 35) {
    return { label: 'Dark Empath', color: '#8b00ff', desc: 'Liest Emotionen, nutzt sie aus. Gefährlichster Typ.' };
  }
  if (darkTriadAvg >= 50 && cogEmp < 40) {
    return { label: 'Dark Triad', color: '#ff3b30', desc: 'Klassisch toxisch: manipulativ, kalt, narzisstisch.' };
  }
  if (darkTriadAvg >= 35 && darkTriadAvg < 50) {
    return { label: 'Taktiker', color: '#ff9500', desc: 'Strategisch denkend, eigennützig, aber begrenzt gefährlich.' };
  }
  if (affEmp >= 60 && darkTriadAvg < 25) {
    return { label: 'Empathisch', color: '#34c759', desc: 'Echtes Mitgefühl. Geringe Manipulationsgefahr.' };
  }
  return { label: 'Neutral', color: '#8e8e93', desc: 'Keine auffälligen psychologischen Merkmale.' };
}
// ??? Frist-Dringlichkeit (Kap. 6.2) ???
export function computeFristUrgency(frist: LexaraFrist): 'green' | 'yellow' | 'red' | 'grey' {
  if (frist.status === 'versäumt') return 'grey';
  if (frist.status === 'erledigt') return 'green';
  const now = new Date();
  const target = new Date(frist.date);
  const daysLeft = Math.ceil((target.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  if (daysLeft <= 0) return 'grey';
  if (daysLeft <= 3) return 'red';
  if (daysLeft <= 14) return 'yellow';
  return 'green';
}
export function daysUntil(dateStr: string): number {
  const now = new Date();
  const target = new Date(dateStr);
  return Math.ceil((target.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
}
// ??? Stufe 6: Fristenkorrektur (Kap. 6.2) ???
export function computeFristenAbzug(fristen: LexaraFrist[]): number {
  if (!fristen || fristen.length === 0) return 0;
  let product = 1;
  for (const f of fristen) {
    if (f.side !== 'own') continue;
    const urgency = computeFristUrgency(f);
    if (urgency === 'grey' || f.status === 'versäumt') {
      const abzug = ((f.abzugMin ?? 50) + (f.abzugMax ?? 100)) / 2 / 100;
      product *= (1 - abzug);
    } else if (urgency === 'red') {
      product *= (1 - 0.15); // 15% temporary risk deduction
    }
  }
  return 1 - product; // total deduction factor
}
// ??? Vollständiger 6-Stufen-Algorithmus (Kap. 9.1) ???
export function computeWinProbability(c: LexaraCase) {
  const ownArgs = c.arguments.filter(a => a.side === 'own');
  const oppArgs = c.arguments.filter(a => a.side === 'opp');
  // Stufe 1: Argument-Basisgewichtung
  // Stufe 2: Beweisboost ? ArgEffektiv = ArgBasis ? (1 + BoostFaktor)
  const ownEffective = ownArgs.map(a => {
    const boost = computeEvidenceBoost(c.evidence[a.id]);
    return a.strength * (1 + boost);
  });
  const oppEffective = oppArgs.map(a => {
    const boost = computeEvidenceBoost(c.evidence[a.id]);
    return a.strength * (1 + boost);
  });
  // Stufe 3: Kanteneffekte
  // Entkräftung: -20% auf Zielargument, Ausschluss: -80% auf Zielargument
  const oppReductions: Record<string, number> = {};
  for (const edge of c.edges) {
    if (edge.type === 'weakens') {
      const fromArg = c.arguments.find(a => a.id === edge.from);
      if (fromArg?.side === 'own') {
        oppReductions[edge.to] = (oppReductions[edge.to] ?? 1) * 0.80;
      }
    } else if (edge.type === 'exclude') {
      const fromArg = c.arguments.find(a => a.id === edge.from);
      if (fromArg?.side === 'own') {
        oppReductions[edge.to] = (oppReductions[edge.to] ?? 1) * 0.20;
      }
    }
  }
  const excludeCount = c.edges.filter(e => e.type === 'exclude' && c.arguments.find(a => a.id === e.from && a.side === 'own')).length;
  const edgeBonus = excludeCount * 0.02;
  let ownScore = ownEffective.reduce((s, v) => s + v, 0);
  let oppScore = oppArgs.reduce((s, a, i) => {
    const reduction = oppReductions[a.id] ?? 1;
    return s + oppEffective[i] * reduction;
  }, 0);
  // Stufe 4: Zeugenmultiplikator
  const oppWitnesses = c.persons.filter(p => p.role === 'Zeuge' && p.party === 'Beklagte');
  let oppWitnessMult = 1;
  if (oppWitnesses.length > 0) {
    const avgCred = oppWitnesses.reduce((s, p) => {
      const cr = computeCredibility(p);
      return s + (cr ?? 50);
    }, 0) / oppWitnesses.length;
    oppWitnessMult = 0.70 + (avgCred / 100) * 0.30;
    oppScore *= oppWitnessMult;
  }
  // Rohverhältnis
  const total = ownScore + oppScore;
  const rawRatio = total > 0 ? ownScore / total : 0.5;
  // Stufe 5: Richter-Kalibrierung
  const judge = c.persons.find(p => p.role === 'Richter');
  const judgeCalib = judge && judge.plaintiffWinRate != null
    ? (judge.plaintiffWinRate - 50) / 100 * 0.15
    : 0;
  let prognose = (rawRatio + edgeBonus + judgeCalib) * 100;
  // Stufe 6: Fristenkorrektur
  const fristenAbzug = c.fristen ? computeFristenAbzug(c.fristen) : 0;
  prognose = prognose * (1 - fristenAbzug);
  const evBoostOwn = ownArgs.length > 0
    ? ownArgs.reduce((s, a) => s + computeEvidenceBoost(c.evidence[a.id]), 0) / ownArgs.length
    : 0;
  const evBoostOpp = oppArgs.length > 0
    ? oppArgs.reduce((s, a) => s + computeEvidenceBoost(c.evidence[a.id]), 0) / oppArgs.length
    : 0;
  const final = Math.max(2, Math.min(95, Math.round(prognose)));
  return {
    final,
    ownScore,
    oppScore,
    evBoostOwn,
    evBoostOpp,
    oppWitnessMult,
    judgeCalib,
    excludeCount,
    fristenAbzug,
    rawRatio,
  };
}
// ??? Strategiepfad-Empfehlung (Kap. 9.2) ???
export function getStrategieEmpfehlung(prognose: number): StrategieEmpfehlung {
  if (prognose >= 70) return {
    pfad: 'klage', label: 'Streitiges Verfahren ? Vollsieg anstreben',
    desc: 'Starke Basis, Durchsetzung anstreben. Klage klar vorteilhaft.',
    color: '#34c759',
  };
  if (prognose >= 55) return {
    pfad: 'klage', label: 'Streitiges Verfahren + Vergleichsbereitschaft',
    desc: 'Solide Basis, aber Vergleichsoption offenhalten. Klage meist vorteilhaft.',
    color: '#34c759',
  };
  if (prognose >= 40) return {
    pfad: 'vergleich', label: 'Grauzone ? Vergleich aktiv anstreben',
    desc: 'Ungesichertes Terrain. Break-Even-Analyse entscheidend.',
    color: '#ff9500',
  };
  if (prognose >= 25) return {
    pfad: 'vergleich', label: 'Vergleich aktiv anstreben',
    desc: 'Argumentbasis zu unsicher. Vergleich meist besser.',
    color: '#ff9500',
  };
  return {
    pfad: 'aufgabe', label: 'Schadensminimierung / Aufgabe evaluieren',
    desc: 'Kein realistischer Gewinnpfad. Kostenrisiko überwiegt.',
    color: '#ff3b30',
  };
}
// ??? Kostenberechnung (Kap. 7.1 ? RVG) ???
// Simplified RVG calculation
const RVG_TABLE: [number, number][] = [
  [500, 49], [1000, 88], [1500, 127], [2000, 166], [3000, 222],
  [4000, 278], [5000, 334], [6000, 390], [7000, 446], [8000, 502],
  [9000, 558], [10000, 614], [13000, 666], [16000, 718], [19000, 770],
  [22000, 822], [25000, 874], [30000, 955], [35000, 1036], [40000, 1117],
  [45000, 1198], [50000, 1279], [65000, 1373], [80000, 1467], [95000, 1561],
  [110000, 1655], [125000, 1749], [140000, 1843], [155000, 1937], [170000, 2031],
  [185000, 2125], [200000, 2219], [230000, 2387], [260000, 2555], [290000, 2723],
  [320000, 2891], [350000, 3059], [380000, 3227], [410000, 3395], [440000, 3563],
  [470000, 3731], [500000, 3899],
];
export function getRVGGebuehr(streitwert: number): number {
  for (let i = RVG_TABLE.length - 1; i >= 0; i--) {
    if (streitwert >= RVG_TABLE[i][0]) return RVG_TABLE[i][1];
  }
  return RVG_TABLE[0][1];
}
export function computeKosten(kosten: LexaraKosten) {
  const basis = getRVGGebuehr(kosten.streitwert);
  const stufe = kosten.gebuehrenstufe || 1.3;
  const verfahrensgebuehr = basis * stufe;          // 1.3-fach
  const terminsgebuehr = basis * 1.2;               // 1.2-fach
  const eigenAnwalt = verfahrensgebuehr + terminsgebuehr;
  const gegnerAnwalt = eigenAnwalt; // same structure
  const gerichtskosten = basis * 3;  // 3-fach GKG
  const sv = kosten.sachverstaendigenKosten ?? 0;
  const reise = kosten.reisekosten ?? 0;
  // Drei Szenarien
  const szenarioSieg = {
    label: 'Vollsieg',
    eigenKosten: eigenAnwalt + sv + reise,
    gegnerKosten: 0,
    gerichtsKosten: 0, // Gegner zahlt
    netto: kosten.streitwert - (eigenAnwalt + sv + reise),
  };
  const szenarioNiederlage = {
    label: 'Niederlage',
    eigenKosten: eigenAnwalt + sv + reise,
    gegnerKosten: gegnerAnwalt,
    gerichtsKosten: gerichtskosten,
    netto: -(eigenAnwalt + gegnerAnwalt + gerichtskosten + sv + reise),
  };
  const vergleichsquote = 0.5;
  const szenarioVergleich = {
    label: 'Vergleich',
    eigenKosten: eigenAnwalt * 0.8 + reise,
    gegnerKosten: 0,
    gerichtsKosten: gerichtskosten * 0.5,
    netto: kosten.streitwert * vergleichsquote - (eigenAnwalt * 0.8 + gerichtskosten * 0.5 + reise),
  };
  return {
    basis,
    eigenAnwalt,
    gegnerAnwalt,
    gerichtskosten,
    szenarien: [szenarioSieg, szenarioNiederlage, szenarioVergleich],
  };
}
// ??? Vergleich vs. Klage vs. Aufgabe (Kap. 7.3) ???
export function computeDecisionAnalysis(c: LexaraCase) {
  const { final } = computeWinProbability(c);
  const kosten = c.kosten;
  if (!kosten) {
    return {
      empfehlung: final >= 50 ? 'klage' as const : final >= 25 ? 'vergleich' as const : 'aufgabe' as const,
      ewKlage: 0, ewVergleich: 0, breakEven: 0,
      details: 'Keine Kostendaten hinterlegt. Empfehlung basiert nur auf Prognose.',
    };
  }
  const kostenResult = computeKosten(kosten);
  const pGewinn = final / 100;
  const pVerlust = 1 - pGewinn;
  const kostenVerlust = Math.abs(kostenResult.szenarien[1].netto);
  // EW_Klage = P(Gewinn) ? Anspruchswert ? P(Verlust) ? Gesamtkosten_Verlust
  const ewKlage = pGewinn * kosten.streitwert - pVerlust * kostenVerlust;
  // EW_Vergleich = Vergleichsangebot ? Eigene_Kosten_bis_dato
  const vergleichsangebot = kosten.vergleichsangebot ?? kosten.streitwert * 0.4;
  const ewVergleich = vergleichsangebot - kostenResult.eigenAnwalt * 0.5;
  // Break-Even = Kosten_Niederlage / (Anspruchswert + Kosten_Niederlage)
  const breakEven = kostenVerlust / (kosten.streitwert + kostenVerlust) * 100;
  const risikoaufschlag = (kosten.risikoaufschlag ?? 15) / 100 * kosten.streitwert;
  let empfehlung: 'klage' | 'vergleich' | 'aufgabe';
  if (ewKlage > ewVergleich + risikoaufschlag) {
    empfehlung = 'klage';
  } else if (ewKlage < 0 && !c.goal?.includes('strateg')) {
    empfehlung = 'aufgabe';
  } else {
    empfehlung = 'vergleich';
  }
  return {
    empfehlung,
    ewKlage: Math.round(ewKlage),
    ewVergleich: Math.round(ewVergleich),
    breakEven: Math.round(breakEven * 10) / 10,
    kostenResult,
    details: empfehlung === 'klage'
      ? `Klage eindeutig vorteilhaft (EW ${ewKlage.toFixed(0)}€ > Vergleich ${ewVergleich.toFixed(0)}€ + Aufschlag).`
      : empfehlung === 'vergleich'
        ? `Vergleich empfohlen. Break-Even bei ${breakEven.toFixed(1)}% ? aktuelle Prognose ${final}%.`
        : `Aufgabe evaluieren. Erwartungswert Klage negativ (${ewKlage.toFixed(0)}€).`,
  };
}
