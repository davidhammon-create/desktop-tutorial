/**
 * base44Client.js — MOCK (Offline / Demo-Modus)
 * Ersetzt den echten base44-SDK durch eine localStorage-basierte
 * Offline-Implementierung. Alle Entity-CRUD-Operationen und KI-Aufrufe
 * arbeiten lokal. Beim ersten Start werden Demo-Daten geladen.
 */

import { MOCK_DATA } from './mockData';

// ── LocalStorage Helpers ──────────────────────────────────────────────────────
const LS_KEY = 'legalos_db_v1';

function getDB() {
  try { const r = localStorage.getItem(LS_KEY); if (r) return JSON.parse(r); } catch {}
  return null;
}
function saveDB(db) { localStorage.setItem(LS_KEY, JSON.stringify(db)); }
function initDB() {
  const ex = getDB();
  if (ex) return ex;
  const db = JSON.parse(JSON.stringify(MOCK_DATA));
  saveDB(db);
  return db;
}
function getTable(name) { return initDB()[name] || []; }
function setTable(name, rows) {
  const db = initDB();
  db[name] = rows;
  saveDB(db);
}
function newId() { return Math.random().toString(36).slice(2, 10) + Date.now().toString(36); }
function delay(ms = 120) { return new Promise(r => setTimeout(r, ms)); }

// ── Entity Factory ────────────────────────────────────────────────────────────
function makeEntity(name) {
  return {
    list: async (sortField) => {
      await delay();
      const rows = getTable(name);
      if (!sortField) return rows;
      const desc = sortField.startsWith('-');
      const field = desc ? sortField.slice(1) : sortField;
      return [...rows].sort((a, b) => {
        const av = a[field] ?? ''; const bv = b[field] ?? '';
        const cmp = av < bv ? -1 : av > bv ? 1 : 0;
        return desc ? -cmp : cmp;
      });
    },
    filter: async (query) => {
      await delay();
      const rows = getTable(name);
      if (!query || !Object.keys(query).length) return rows;
      return rows.filter(row => Object.entries(query).every(([k, v]) => row[k] === v));
    },
    get: async (id) => {
      await delay();
      return getTable(name).find(r => r.id === id) || null;
    },
    create: async (data) => {
      await delay();
      const rows = getTable(name);
      const record = { id: newId(), created_date: new Date().toISOString(), updated_date: new Date().toISOString(), created_by: 'demo-user', ...data };
      rows.unshift(record);
      setTable(name, rows);
      return record;
    },
    update: async (id, data) => {
      await delay();
      const rows = getTable(name);
      const idx = rows.findIndex(r => r.id === id);
      if (idx === -1) throw new Error(`${name} not found: ${id}`);
      rows[idx] = { ...rows[idx], ...data, updated_date: new Date().toISOString() };
      setTable(name, rows);
      return rows[idx];
    },
    delete: async (id) => {
      await delay();
      setTable(name, getTable(name).filter(r => r.id !== id));
      return { success: true };
    },
  };
}

// ── Auth Mock ─────────────────────────────────────────────────────────────────
const DEMO_USER = { id: 'demo-user', email: 'demo@legalos.de', full_name: 'Demo Nutzer', role: 'admin', jurisdiction: 'DE', language: 'DE', onboarding_completed: true, ki_credits: 500, plan: 'professional' };
const authMock = {
  getCurrentUser: async () => { await delay(50); return DEMO_USER; },
  login: async () => { await delay(300); return DEMO_USER; },
  logout: async () => { await delay(100); return { success: true }; },
  register: async () => { await delay(300); return DEMO_USER; },
  requestMagicLink: async () => { await delay(200); return { success: true }; },
  updateProfile: async (data) => { await delay(200); return { ...DEMO_USER, ...data }; },
  isAuthenticated: async () => { await delay(50); return true; },
  me: async () => { await delay(50); return DEMO_USER; },
};

// ── KI Mock ───────────────────────────────────────────────────────────────────
async function InvokeLLM({ prompt = '', response_json_schema }) {
  await delay(900 + Math.random() * 700);
  if (!response_json_schema) return buildText(prompt);
  return buildJson(prompt, response_json_schema);
}

function buildText(prompt) {
  const p = prompt.toLowerCase();
  if (p.includes('strateg') || p.includes('empfehl'))
    return 'Basierend auf der rechtlichen Analyse empfehle ich eine strukturierte Prozessstrategie. Die Erfolgsaussichten liegen bei ~72 %. Kritische Faktoren: Beweislage und BGH-Rechtsprechung zu § 242 BGB. Nächster Schritt: Klageschrift finalisieren und Güteverhandlung beantragen.';
  if (p.includes('argument'))
    return 'Das stärkste Argument liegt in der vertraglichen Pflichtverletzung gemäß § 280 BGB. Ergänzend stützt sich die Position auf OLG München Az. 7 U 4231/22. Empfehlung: Beweisanträge zeitnah stellen.';
  if (p.includes('beweis'))
    return 'Die vorgelegten Beweismittel sind prozessual verwertbar. Vertragsdokumente und E-Mail-Korrespondenz bilden eine solide Grundlage. Ergänzend empfiehlt sich ein Sachverständigengutachten.';
  return 'KI-Analyse abgeschlossen. Die rechtliche Einschätzung fällt positiv aus. Empfehlung: Gewählte Strategie weiterverfolgen und Fristen gemäß ZPO § 339 beachten.';
}

function buildJson(prompt, schema) {
  const p = prompt.toLowerCase();
  const props = schema?.properties || {};
  const VALS = {
    staerken: ['Starke Beweislage durch Vertragsdokumente', 'Klare BGH-Rechtsprechung', 'Sachverständiger verfügbar'],
    schwaechen: ['Zeitdruck durch nahen Fristablauf', 'Gegenseite anwaltlich stark vertreten'],
    chancen: ['Vergleichsbereitschaft der Gegenseite erkennbar', 'Neue BGH-Entscheidung stärkt Position'],
    risiken: ['Richter für restriktive Auslegung bekannt', 'Beweismittel könnten angefochten werden'],
    zusammenfassung: 'Die Gesamtsituation ist strategisch günstig. Aktive Prozessführung wird empfohlen.',
    kritischeFaktoren: ['Beweisführung zu § 280 BGB', 'Frist gemäß ZPO § 339'],
    empfohleneOption: 'Option B – Moderater Ansatz mit Vergleichsoption',
    begruendung: 'Der moderate Ansatz maximiert Vergleichsbereitschaft der Gegenseite bei Wahrung aller Rechte.',
    risikobewertung: 'Mittel – Prozessrisiko ca. 28 %, absicherbar durch frühzeitigen Vergleichsvorschlag.',
    naechsteSchritte: ['Klageschrift finalisieren', 'Güteverhandlung beantragen', 'Sachverständigen benennen'],
    warnhinweise: ['Frist 15.06.2026 zwingend beachten', 'Keine außergerichtliche Kommunikation ohne Rücksprache'],
    erfolgsprognose: '72 % – Hohe Erfolgswahrscheinlichkeit bei konsequenter Beweisführung',
    vorteile: ['Schnelle Durchsetzung möglich', 'Klare Rechtslage', 'Starke Präzedenzfälle'],
    nachteile: ['Hoher Kostenaufwand', 'Zeitintensiv bei streitiger Verhandlung'],
    massnahmen: ['Beweissicherung durchführen', 'Sachverständigengutachten einholen', 'Vergleichsgespräche initiieren'],
    analyse: 'Die KI-Analyse zeigt eine klare Bevorzugung der eigenen Rechtsposition. Prozessuale Schritte sollten zügig eingeleitet werden.',
    gegenstrategien: ['Beweislastumkehr beantragen', 'Mitverschulden geltend machen', '§ 254 BGB prüfen'],
    jurisdiktionsHinweise: ['Im deutschen Recht gilt das Verschuldensprinzip (§ 276 BGB).', 'Verjährung nach § 195 BGB: 3 Jahre.'],
    paragraph: '§ 280 BGB', gesetz: 'BGB',
    erklaerung: 'Die Norm schützt vor unberechtigten Schadensersatzforderungen.',
    fundstelle: 'BGH, Urt. v. 14.03.2023 – VI ZR 412/22',
    titel: 'KI-Strategieempfehlung',
    beschreibung: 'Auf Basis der Fallanalyse wird eine strukturierte Verhandlungsstrategie empfohlen.',
    kategorie: 'Vertragsrecht', impakt: 'hoch', horizont: 'kurzfristig', typ: 'Chance', risiko: 'mittel',
    quantitativeEinschaetzung: { erwarteterSchadenEUR: 45000, prozesskostenEUR: 8500, nettovorteilEUR: 36500 },
  };
  const result = {};
  for (const key of Object.keys(props)) {
    const type = props[key]?.type;
    if (key in VALS) { result[key] = VALS[key]; }
    else if (type === 'array') { result[key] = ['KI-Punkt 1: Rechtliche Grundlage geprüft', 'KI-Punkt 2: Strategie bewertet', 'KI-Punkt 3: Empfehlung formuliert']; }
    else if (type === 'number' || type === 'integer') { result[key] = p.includes('prognose') ? 72 : p.includes('risiko') ? 28 : 65; }
    else if (type === 'boolean') { result[key] = true; }
    else { result[key] = 'KI-Analyse: ' + key.replace(/([A-Z])/g, ' $1').trim(); }
  }
  return result;
}

async function UploadFile({ file }) {
  await delay(500);
  return { url: URL.createObjectURL(file), name: file?.name || 'upload', size: file?.size || 0 };
}

// ── Entities ──────────────────────────────────────────────────────────────────
const ENTITY_NAMES = [
  'Case','Argument','Evidence','Deadline','Person','Document',
  'JudgeProfile','CaseFolder','CaseHistory','CaseQuestionnaire',
  'CaseWarning','GegnerVerhalten','TimelineEvent','Task',
  'StrategosScenario','LegalLoophole','AIPerformanceFeedback',
  'KIUsageLog','JurisdictionInsight',
];
const entities = {};
for (const n of ENTITY_NAMES) entities[n] = makeEntity(n);

export const base44 = {
  entities,
  auth: authMock,
  integrations: { Core: { InvokeLLM, UploadFile }, Email: { SendEmail: async () => ({ success: true }) } },
};
