/**
 * ALGORITHMIC TEXT EXTRACTION ENGINE
 * Pure deterministic text analysis ? NO AI required.
 * Extracts arguments, evidence, deadlines, legal bases, contradictions,
 * pressure points, and psychological profiles from raw text using
 * pattern matching, keyword analysis, and heuristic scoring.
 */
// ???????????????????????????????????????????????????????????
// LEGAL PARAGRAPH PATTERNS
// ???????????????????????????????????????????????????????????
const PARAGRAPH_REGEX = /§\s*(\d+[a-z]?)\s*(?:(?:Abs|Absatz)\.\s*(\d+)\s*)?(?:(?:S|Satz)\.\s*(\d+)\s*)?(?:Nr\.\s*(\d+)\s*)?(BGB|ZPO|HGB|StGB|GmbHG|AktG|InsO|UWG|GWB|KSchG|BetrVG|AGG|MarkenG|UrhG|PatG|AO|OWiG|DSGVO|TKG|TMG|VVG|WEG|MietR|SGB|GG|StPO|BauGB|GenG|PartGG)/gi;
const DATE_REGEX = /(\d{1,2})[\.\-\/](\d{1,2})[\.\-\/](\d{2,4})/g;
const ISO_DATE_REGEX = /(\d{4})-(\d{2})-(\d{2})/g;
const DEADLINE_KEYWORDS = ['frist', 'deadline', 'termin', 'bis zum', 'spätestens', 'verjähr', 'ablauf', 'verfallsdatum', 'stichtag', 'ultimatum'];
const EVIDENCE_KEYWORDS = ['beweis', 'urkunde', 'zeuge', 'gutachten', 'anlage', 'protokoll', 'dokument', 'nachweis', 'beleg', 'quittung', 'rechnung', 'vertrag', 'schreiben', 'e-mail', 'email', 'screenshot', 'foto', 'video', 'aufzeichnung'];
// Argument signal words
const PRO_SIGNALS = [
  'anspruch', 'forderung', 'recht auf', 'berechtigt', 'zusteht', 'schuldet', 'verpflichtet',
  'hat zu leisten', 'muss zahlen', 'schuldig', 'haftbar', 'verantwortlich', 'vertragswidrig',
  'pflichtverletzung', 'schadensersatz', 'gewährleistung', 'mängelrüge', 'nachbesserung',
  'unterlassung', 'herausgabe', 'erstattung', 'entschädigung', 'kündigung wirksam',
  'vertragsverletzung', 'verzug', 'leistungsstörung', 'mangelhaft',
];
const CONTRA_SIGNALS = [
  'einrede', 'einwand', 'verjährt', 'verwirkt', 'unzulässig', 'unbegründet',
  'bestritten', 'nicht nachgewiesen', 'unsubstantiiert', 'mitverschulden',
  'gegenrecht', 'aufrechnung', 'zurückbehaltungsrecht', 'widerklage',
  'treuwidrig', 'rechtsmissbrauch', 'ausgeschlossen', 'verfristet',
  'keine pflichtverletzung', 'ordnungsgemäß', 'vertragsgemäß',
];
const CONTRADICTION_SIGNALS = [
  ['einerseits', 'andererseits'],
  ['zunächst', 'dann aber', 'später'],
  ['behauptet', 'widerspricht'],
  ['obwohl', 'dennoch'],
  ['trotzdem', 'gleichzeitig'],
];
const PRESSURE_SIGNALS = [
  { pattern: /strafanz|strafbar|strafrecht/i, label: 'Strafrechtliche Relevanz', strength: 8 },
  { pattern: /insolvenz|zahlungsunfähig|überschuld/i, label: 'Insolvenzrisiko', strength: 7 },
  { pattern: /öffentlichkeit|presse|medien|reputation/i, label: 'Reputationsrisiko', strength: 6 },
  { pattern: /behörd|aufsicht|regulier/i, label: 'Regulatorischer Druck', strength: 7 },
  { pattern: /schadensersatz.*hoh|hohe.*forderung|million/i, label: 'Hohe Streitwertexposition', strength: 8 },
  { pattern: /verjähr.*dro|frist.*ablauf|versäum/i, label: 'Fristdruck', strength: 9 },
  { pattern: /einstweilig.*verfügung|eilantrag/i, label: 'Eilrechtsschutz-Drohung', strength: 7 },
  { pattern: /vertragsstrafe|konventionalstrafe/i, label: 'Vertragsstrafe', strength: 6 },
  { pattern: /vollstreck|pfänd|zwangsvollstreck/i, label: 'Vollstreckungsdruck', strength: 8 },
  { pattern: /kündigung.*fristlos|außerordentlich.*kündig/i, label: 'Fristlose Kündigung', strength: 7 },
];
const PSYCHO_SIGNALS = [
  { pattern: /aggressive|aggressiv|droh|einschüchter/i, cat: 'Aggression', tactic: 'Deeskalation anbieten, Sachebene halten' },  { pattern: /emotional|wutentbrannt|empört|aufgebracht/i, cat: 'Emotionale Labilität', tactic: 'Ruhig bleiben, Fakten betonen' },
  { pattern: /vertrauensbruch|getäuscht|betrogen|arglistig/i, cat: 'Vertrauensverlust', tactic: 'Dokumentation betonen, Fakten statt Emotionen' },
  { pattern: /stur|uneinsichtig|kompromisslos|verweiger/i, cat: 'Rigidität', tactic: 'Alternative Perspektiven anbieten, Eskalation vermeiden' },
  { pattern: /angst|fürchte|sorge|befürcht/i, cat: 'Angst/Unsicherheit', tactic: 'Sicherheit signalisieren, klare Optionen bieten' },
  { pattern: /überheblich|arrogant|herablass/i, cat: 'Narzissmus', tactic: 'Schmeicheln, dann Fakten konfrontieren' },
];
// ???????????????????????????????????????????????????????????
// CORE EXTRACTION FUNCTIONS
// ???????????????????????????????????????????????????????????
interface AlgoExtractedArg {
  label: string;
  content: string;
  side: 'own' | 'opp';
  strength: number;
  legal_basis?: string;
  seite?: number | null;
  arg_type?: string;
}
interface AlgoWiderspruch {
  titel: string;
  beschreibung: string;
  schwere: number;
  seite?: number | null;
  angreifbar?: boolean;
}
interface AlgoDruckmittel {
  titel: string;
  beschreibung: string;
  staerke: number;
  zielseite: 'own' | 'opp';
  legal_basis?: string;
}
interface AlgoParagraph {
  paragraph: string;
  kontext: string;
  im_text_genannt: boolean;
}
interface AlgoPsychoProfile {
  seite: 'own' | 'opp';
  schwaeche: string;
  beschreibung: string;
  taktik?: string;
  ausnutzbar: number;
  kategorie: string;
  textstelle?: string;
}
interface AlgoEigenSchwaeche {
  titel: string;
  beschreibung: string;
  schwere: number;
  gegenmassnahme?: string;
  seite?: number | null;
}
interface AlgoStrang {
  from_index: number;
  to_index: number;
  type: 'supports' | 'weakens' | 'causal';
  beschreibung: string;
}
export interface AlgoExtractionResult {
  argumente: AlgoExtractedArg[];
  widersprueche: AlgoWiderspruch[];
  druckmittel: AlgoDruckmittel[];
  paragraphen: AlgoParagraph[];
  psycho_profile: AlgoPsychoProfile[];
  eigen_schwaechen: AlgoEigenSchwaeche[];
  straenge: AlgoStrang[];
  zusammenfassung: string;
  konfidenz: string;
  warnungen: string[];
}
function splitSentences(text: string): string[] {
  return text.split(/(?<=[.!?])\s+/).filter(s => s.trim().length > 10);
}
function extractContext(text: string, pos: number, windowSize: number = 200): string {
  const start = Math.max(0, pos - windowSize);
  const end = Math.min(text.length, pos + windowSize);
  return text.slice(start, end).trim();
}
function scoreArgStrength(sentence: string, legalBasis: string | undefined): number {
  let score = 5;
  if (legalBasis) score += 2;
  if (sentence.length > 200) score += 1;
  if (/muss|zwingend|unbedingt|erforderlich/i.test(sentence)) score += 1;
  if (/kann|möglicherweise|eventuell|vielleicht/i.test(sentence)) score -= 1;
  if (/BGH|BVerfG|OLG/i.test(sentence)) score += 1;
  if (/unstrittig|unbestritten|offensichtlich|zweifelsfrei/i.test(sentence)) score += 1;
  return Math.max(1, Math.min(10, score));
}
export function extractFromText(text: string): AlgoExtractionResult {
  const sentences = splitSentences(text);
  const lowerText = text.toLowerCase();
  const argumente: AlgoExtractedArg[] = [];
  const paragraphen: AlgoParagraph[] = [];
  const warnungen: string[] = [];
  // 1. Extract legal paragraphs
  const seenParagraphs = new Set<string>();
  let match: RegExpExecArray | null;
  const pRegex = new RegExp(PARAGRAPH_REGEX.source, 'gi');
  while ((match = pRegex.exec(text)) !== null) {
    const full = match[0].trim();
    if (!seenParagraphs.has(full)) {
      seenParagraphs.add(full);
      paragraphen.push({
        paragraph: full,
        kontext: extractContext(text, match.index, 150),
        im_text_genannt: true,
      });
    }
  }
  // 2. Extract arguments from sentences
  const usedSentences = new Set<number>();

  for (let i = 0; i < sentences.length; i++) {
    const s = sentences[i];
    const sl = s.toLowerCase();

    // Find legal basis in sentence
    const pMatch = s.match(PARAGRAPH_REGEX);
    const legalBasis = pMatch ? pMatch[0] : undefined;

    // Check pro signals
    const proHits = PRO_SIGNALS.filter(sig => sl.includes(sig));
    const contraHits = CONTRA_SIGNALS.filter(sig => sl.includes(sig));

    if (proHits.length > 0 && !usedSentences.has(i)) {
      usedSentences.add(i);
      const label = proHits[0].charAt(0).toUpperCase() + proHits[0].slice(1);
      argumente.push({
        label: legalBasis ? `${label} (${legalBasis})` : label,
        content: s.trim(),
        side: 'own',
        strength: scoreArgStrength(s, legalBasis),
        legal_basis: legalBasis,
        arg_type: legalBasis ? 'Rechtsargument' : 'Tatsachenargument',
      });
    }

    if (contraHits.length > 0 && !usedSentences.has(i)) {
      usedSentences.add(i);
      const label = contraHits[0].charAt(0).toUpperCase() + contraHits[0].slice(1);
      argumente.push({
        label: legalBasis ? `${label} (${legalBasis})` : label,
        content: s.trim(),
        side: 'opp',
        strength: scoreArgStrength(s, legalBasis),
        legal_basis: legalBasis,
        arg_type: legalBasis ? 'Rechtsargument' : 'Tatsachenargument',
      });
    }
  }
  // 3. Extract contradictions
  const widersprueche: AlgoWiderspruch[] = [];
  for (const [sig1, sig2] of CONTRADICTION_SIGNALS) {
    const idx1 = lowerText.indexOf(sig1);
    const idx2 = lowerText.indexOf(sig2);
    if (idx1 !== -1 && idx2 !== -1 && Math.abs(idx2 - idx1) < 500) {
      widersprueche.push({
        titel: `Widerspruch: "${sig1}" vs. "${sig2}"`,
        beschreibung: extractContext(text, Math.min(idx1, idx2), 250),
        schwere: 6,
        angreifbar: true,
      });
    }
  }
  // 4. Extract pressure points
  const druckmittel: AlgoDruckmittel[] = [];
  for (const ps of PRESSURE_SIGNALS) {
    const m = text.match(ps.pattern);
    if (m) {
      const idx = text.search(ps.pattern);
      druckmittel.push({
        titel: ps.label,
        beschreibung: extractContext(text, idx, 200),
        staerke: ps.strength,
        zielseite: 'opp',
        legal_basis: paragraphen.find(p => Math.abs(text.indexOf(p.paragraph) - idx) < 300)?.paragraph,
      });
    }
  }
  // 5. Psychological profiles
  const psycho_profile: AlgoPsychoProfile[] = [];
  for (const ps of PSYCHO_SIGNALS) {
    const m = text.match(ps.pattern);
    if (m) {
      const idx = text.search(ps.pattern);
      psycho_profile.push({
        seite: 'opp',
        schwaeche: ps.cat,
        beschreibung: extractContext(text, idx, 200),
        taktik: ps.tactic,
        ausnutzbar: 6,
        kategorie: ps.cat,
        textstelle: m[0],
      });
    }
  }
  // 6. Own weaknesses
  const eigen_schwaechen: AlgoEigenSchwaeche[] = [];
  const weaknessPatterns = [
    { pattern: /nicht nachweisbar|beweis.*fehlt|fehl.*beweis/i, label: 'Beweislücke', measure: 'Beweissicherung einleiten (§ 485 ZPO)' },
    { pattern: /versäum.*frist|frist.*versäum|verspätet/i, label: 'Fristversäumnis', measure: 'Wiedereinsetzung prüfen (§ 233 ZPO)' },
    { pattern: /mitverschulden|eigenes.*verschulden|mitursächlich/i, label: 'Mitverschulden', measure: '§ 254 BGB: Mitverschuldensanteil minimieren' },
    { pattern: /prozessrisiko|unsicher.*ausgang|unklar.*recht/i, label: 'Unsichere Rechtslage', measure: 'Rechtsgutachten einholen' },
  ];
  for (const wp of weaknessPatterns) {
    const m = text.match(wp.pattern);
    if (m) {
      eigen_schwaechen.push({
        titel: wp.label,
        beschreibung: extractContext(text, text.search(wp.pattern), 200),
        schwere: 6,
        gegenmassnahme: wp.measure,
      });
    }
  }
  // 7. Build causal chains (Stränge) between arguments
  const straenge: AlgoStrang[] = [];
  for (let i = 0; i < argumente.length; i++) {
    for (let j = i + 1; j < argumente.length; j++) {
      const a = argumente[i];
      const b = argumente[j];
      // Same legal basis = support chain
      if (a.legal_basis && b.legal_basis && a.legal_basis === b.legal_basis && a.side === b.side) {
        straenge.push({ from_index: i, to_index: j, type: 'supports', beschreibung: `Gleiche Rechtsgrundlage: ${a.legal_basis}` });
      }
      // Pro vs contra on same topic = attack
      if (a.side !== b.side && a.legal_basis && b.legal_basis && a.legal_basis === b.legal_basis) {
        straenge.push({ from_index: i, to_index: j, type: 'weakens', beschreibung: `Gegenläufig zu ${a.legal_basis}` });
      }
    }
  }
  // Summary
  const ownCount = argumente.filter(a => a.side === 'own').length;
  const oppCount = argumente.filter(a => a.side === 'opp').length;
  const zusammenfassung = `Algorithmische Analyse: ${argumente.length} Argumente extrahiert (${ownCount} eigene, ${oppCount} gegnerische). ${paragraphen.length} Rechtsgrundlagen, ${widersprueche.length} Widersprüche, ${druckmittel.length} Druckmittel identifiziert.`;
  // Confidence
  const konfidenz = argumente.length >= 5 && paragraphen.length >= 2 ? 'mittel' :
    argumente.length >= 3 ? 'niedrig' : 'sehr niedrig';
  if (text.length < 200) warnungen.push('Text sehr kurz ? Extraktion möglicherweise unvollständig');
  if (paragraphen.length === 0) warnungen.push('Keine §§ erkannt ? manuelle Zuordnung empfohlen');
  if (argumente.length === 0) warnungen.push('Keine Argumente automatisch erkannt ? Text manuell analysieren');
  return {
    argumente,
    widersprueche,
    druckmittel,
    paragraphen,
    psycho_profile,
    eigen_schwaechen,
    straenge,
    zusammenfassung,
    konfidenz,
    warnungen,
  };
}
// ???????????????????????????????????????????????????????????
// CONTRACT ANALYSIS (Algorithmic)
// ???????????????????????????????????????????????????????????
interface AlgoContractOption {
  label: string;
  description: string;
  anwaltskosten: number;
  gerichtskosten: number;
  interneKosten: number;
  opportunitaetskosten: number;
  erfolgswahrscheinlichkeit: number;
  bestCase: number;
  worstCase: number;
  likelyCase: number;
  minMonths: number;
  maxMonths: number;
  relevanteLaws: string[];
  proArgumente: string[];
  contraArgumente: string[];
}
interface AlgoContractResult {
  zusammenfassung: string;
  kategorie: string;
  optionen: AlgoContractOption[];
  risiken: { label: string; auftretenswahrscheinlichkeit: number; bedeutung: number; entdeckungswahrscheinlichkeit: number }[];  fristen: { label: string; date: string; type: string; critical: boolean; notes: string }[];
  vertragsbestandteile: { titel: string; inhalt: string; risiko: string; bewertung: string }[];
  konfidenz: string;
  warnungen: string[];
}
const CLAUSE_PATTERNS = [
  { pattern: /haftung|haft|schadenersatz|schadensersatz/i, title: 'Haftungsklausel', risk: 'mittel' },
  { pattern: /kündigung|kündig|beendig|laufzeit/i, title: 'Kündigungsklausel', risk: 'mittel' },
  { pattern: /gewährleist|garantie|mängelrecht|gewähr/i, title: 'Gewährleistung', risk: 'mittel' },
  { pattern: /vertragsstrafe|konventionalstrafe|pönale/i, title: 'Vertragsstrafenklausel', risk: 'hoch' },
  { pattern: /geheimhalt|vertraulich|NDA|verschwiegenheit/i, title: 'Geheimhaltungsklausel', risk: 'gering' },
  { pattern: /wettbewerbsverbot|konkurrenz|karenz/i, title: 'Wettbewerbsverbot', risk: 'hoch' },
  { pattern: /salvatorisch/i, title: 'Salvatorische Klausel', risk: 'gering' },
  { pattern: /gerichtsstand|zuständig.*gericht|schiedsgericht/i, title: 'Gerichtsstandsklausel', risk: 'mittel' },
  { pattern: /force.*majeure|höhere.*gewalt/i, title: 'Force-Majeure-Klausel', risk: 'gering' },
  { pattern: /vergütung|entgelt|honorar|preis|zahlung/i, title: 'Vergütungsklausel', risk: 'mittel' },
  { pattern: /eigentumsvorbehal/i, title: 'Eigentumsvorbehalt', risk: 'mittel' },
  { pattern: /abtretung|zession/i, title: 'Abtretungsklausel', risk: 'gering' },
  { pattern: /datenschutz|DSGVO|personenbezogen/i, title: 'Datenschutzklausel', risk: 'mittel' },
  { pattern: /lizenz|nutzungsrecht|urheberrecht/i, title: 'Lizenz-/Nutzungsrechte', risk: 'hoch' },
  { pattern: /abnahme|leistungsnachweis/i, title: 'Abnahmeklausel', risk: 'mittel' },
];
const CATEGORY_PATTERNS: [RegExp, string][] = [
  [/arbeitsvertrag|arbeitsverhältnis|kündigung.*arbeit/i, 'Arbeitsrecht'],
  [/mietvertrag|miete|vermieter|pacht/i, 'Vertragsmanagement'],
  [/kaufvertrag|kaufpreis|käufer|verkäufer/i, 'Vertragsmanagement'],
  [/dienstleistung|werkvertrag|auftraggeber/i, 'Vertragsmanagement'],
  [/patent|marke|urheberrecht|lizenz/i, 'IP-Streitigkeit'],
  [/steuer|finanzamt|steuererklärung/i, 'Steueroptimierung'],
  [/forderung|inkasso|mahnung|zahlungsverzug/i, 'Forderungsmanagement'],
  [/gesellschaft|geschäftsführer|GmbH|aktie/i, 'M&A / Transaktion'],
  [/kartell|wettbewerb.*recht|GWB|UWG/i, 'Compliance / Regulierung'],
];
export function analyzeContractAlgorithmically(text: string, context?: string): AlgoContractResult {
  const warnungen: string[] = [];
  const sentences = splitSentences(text);
  // Detect category
  let kategorie = 'Vertragsmanagement';
  for (const [pat, cat] of CATEGORY_PATTERNS) {
    if (pat.test(text)) { kategorie = cat; break; }
  }
  // Extract clauses
  const vertragsbestandteile: AlgoContractResult['vertragsbestandteile'] = [];
  for (const cp of CLAUSE_PATTERNS) {
    if (cp.pattern.test(text)) {
      const idx = text.search(cp.pattern);
      vertragsbestandteile.push({
        titel: cp.title,
        inhalt: extractContext(text, idx, 200),
        risiko: cp.risk,
        bewertung: cp.risk === 'hoch' ? 'Kritisch ? juristisch prüfen' : cp.risk === 'mittel' ? 'Standard ? auf Ausgewogenheit prüfen' : 'Unkritisch',
      });
    }
  }
  // Extract legal bases
  const laws: string[] = [];
  const pRegex2 = new RegExp(PARAGRAPH_REGEX.source, 'gi');
  let m2;
  while ((m2 = pRegex2.exec(text)) !== null) {
    if (!laws.includes(m2[0].trim())) laws.push(m2[0].trim());
  }
  // Extract dates as deadlines
  const fristen: AlgoContractResult['fristen'] = [];
  const dateRegex = new RegExp(DATE_REGEX.source, 'g');
  let dm;
  while ((dm = dateRegex.exec(text)) !== null) {
    const ctx = extractContext(text, dm.index, 100).toLowerCase();
    const isCritical = DEADLINE_KEYWORDS.some(k => ctx.includes(k));
    if (isCritical || fristen.length < 3) {
      const day = dm[1].padStart(2, '0');
      const month = dm[2].padStart(2, '0');
      let year = dm[3];
      if (year.length === 2) year = (parseInt(year) > 50 ? '19' : '20') + year;
      fristen.push({
        label: isCritical ? `Frist: ${extractContext(text, dm.index, 60).split(/[.!?]/)[0].trim()}` : `Datum: ${day}.${month}.${year}`,
        date: `${year}-${month}-${day}`,
        type: isCritical ? 'Vertragsfrist' : 'Sonstige',
        critical: isCritical,
        notes: extractContext(text, dm.index, 80),
      });
    }
  }
  // Generate options algorithmically
  const highRiskClauses = vertragsbestandteile.filter(v => v.risiko === 'hoch');
  const streitwertMatch = text.match(/(\d[\d.,]*)\s*(?:€|EUR|Euro)/i);
  const streitwert = streitwertMatch ? parseInt(streitwertMatch[1].replace(/[.,]/g, '')) : 50000;
  const proArgs = sentences.filter(s => PRO_SIGNALS.some(sig => s.toLowerCase().includes(sig))).slice(0, 5);
  const contraArgs = sentences.filter(s => CONTRA_SIGNALS.some(sig => s.toLowerCase().includes(sig))).slice(0, 5);
  const optionen: AlgoContractOption[] = [
    {
      label: 'Anspruch durchsetzen (Klage)',
      description: 'Gerichtliche Durchsetzung der Forderung',
      anwaltskosten: Math.round(streitwert * 0.08),
      gerichtskosten: Math.round(streitwert * 0.03),
      interneKosten: Math.round(streitwert * 0.02),
      opportunitaetskosten: Math.round(streitwert * 0.05),
      erfolgswahrscheinlichkeit: Math.min(80, Math.max(30, 50 + proArgs.length * 5 - contraArgs.length * 5 + laws.length * 3)),      bestCase: streitwert,
      worstCase: -Math.round(streitwert * 0.3),
      likelyCase: Math.round(streitwert * 0.6),
      minMonths: 6,
      maxMonths: 24,
      relevanteLaws: laws.slice(0, 5),
      proArgumente: proArgs.map(s => s.slice(0, 100)),
      contraArgumente: contraArgs.map(s => s.slice(0, 100)),
    },
    {
      label: 'Außergerichtliche Einigung',
      description: 'Verhandlung mit Gegenseite ohne Gericht',
      anwaltskosten: Math.round(streitwert * 0.03),
      gerichtskosten: 0,
      interneKosten: Math.round(streitwert * 0.01),
      opportunitaetskosten: Math.round(streitwert * 0.02),
      erfolgswahrscheinlichkeit: 65,
      bestCase: Math.round(streitwert * 0.7),
      worstCase: 0,
      likelyCase: Math.round(streitwert * 0.4),
      minMonths: 1,
      maxMonths: 4,
      relevanteLaws: laws.slice(0, 3),
      proArgumente: ['Kostenersparnis', 'Schnellere Lösung', 'Geschäftsbeziehung erhalten'],
      contraArgumente: ['Möglicherweise geringerer Erlös', 'Kein vollstreckbarer Titel'],
    },
    {
      label: 'Abwarten / Beobachten',
      description: 'Position sichern ohne sofortige Eskalation',
      anwaltskosten: Math.round(streitwert * 0.01),
      gerichtskosten: 0,
      interneKosten: Math.round(streitwert * 0.005),
      opportunitaetskosten: Math.round(streitwert * 0.1),
      erfolgswahrscheinlichkeit: 40,
      bestCase: Math.round(streitwert * 0.5),
      worstCase: -Math.round(streitwert * 0.1),
      likelyCase: 0,
      minMonths: 0,
      maxMonths: 12,
      relevanteLaws: [],
      proArgumente: ['Geringes Kostenrisiko', 'Mehr Informationsgewinn'],
      contraArgumente: ['Verjährungsrisiko', 'Beweismittelverlust möglich'],
    },
  ];
  // Risks
  const risiken = [
    ...highRiskClauses.map(c => ({
      label: `Risiko: ${c.titel}`,
      auftretenswahrscheinlichkeit: 6,
      bedeutung: 7,
      entdeckungswahrscheinlichkeit: 4,
    })),
    ...(fristen.filter(f => f.critical).map(f => ({
      label: `Fristrisiko: ${f.label}`,
      auftretenswahrscheinlichkeit: 8,
      bedeutung: 9,
      entdeckungswahrscheinlichkeit: 3,
    }))),
  ];
  const zusammenfassung = `Algorithmische Vertragsanalyse: ${vertragsbestandteile.length} Klauseln identifiziert (${highRiskClauses.length} kritisch), ${laws.length} Rechtsgrundlagen, ${fristen.length} Termine/Fristen. Kategorie: ${kategorie}.`;
  if (text.length < 200) warnungen.push('Text sehr kurz ? Analyse möglicherweise unvollständig');
  if (vertragsbestandteile.length === 0) warnungen.push('Keine Vertragsklauseln erkannt');
  return {
    zusammenfassung,
    kategorie,
    optionen,
    risiken,
    fristen,
    vertragsbestandteile,
    konfidenz: vertragsbestandteile.length >= 3 ? 'mittel' : 'niedrig',
    warnungen,
  };
}
