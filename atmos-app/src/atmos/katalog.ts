import katalogJson from "@/data/katalog.json";
import ablaeufeJson from "@/data/ablaeufe.json";
import type { GithubTreffer, LaufSchritt, LizenzKlasse, Modul } from "./types";
export interface KatalogEintrag {
  kategorie: string;
  repo: string;
  zweck: string;
}
export interface AblaufVorlage {
  id: string;
  titel: string;
  ziel: string;
  ausloeser: string[];
  schritte: LaufSchritt[];
}
export const KATALOG = katalogJson as KatalogEintrag[];
export const ABLAEUFE = ablaeufeJson as AblaufVorlage[];
const MOCK_META: Record<string, Partial<GithubTreffer>> = {
  "jsvine/pdfplumber": { sterne: 6200, sprache: "Python", lizenz: "MIT", lizenzklasse: "frei" },
  "Aider-AI/aider": { sterne: 28000, sprache: "Python", lizenz: "Apache-2.0", lizenzklasse: "frei" },
  "langchain-ai/langgraph": { sterne: 11000, sprache: "Python", lizenz: "MIT", lizenzklasse: "frei" },
  "ollama/ollama": { sterne: 110000, sprache: "Go", lizenz: "MIT", lizenzklasse: "frei" },
  "chroma-core/chroma": { sterne: 18000, sprache: "Python", lizenz: "Apache-2.0", lizenzklasse: "frei" },
  "shadcn-ui/ui": { sterne: 85000, sprache: "TypeScript", lizenz: "MIT", lizenzklasse: "frei" },
};
function hashScore(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return 55 + (h % 40);
}
export function katalogAlsModule(limit = 12): Modul[] {
  return KATALOG.slice(0, limit).map((k, i) => {
    const meta = MOCK_META[k.repo] ?? {};
    const score = meta.score ?? hashScore(k.repo);
    return {
      id: `mod-${i}-${k.repo.replace("/", "-")}`,
      name: k.repo,
      zweck: k.zweck,
      kategorie: k.kategorie,
      score,
      lizenz: meta.lizenz ?? "MIT",
      lizenzklasse: (meta.lizenzklasse as LizenzKlasse) ?? "frei",
      sicherheit: "ok",
      status: i < 2 ? "an" : "aus",
      sterne: meta.sterne ?? 500 + ((score * 17) % 9000),
      url: `https://github.com/${k.repo}`,
      vital: 50 + (score % 40),
      eingebettet: Date.now() - i * 86_400_000,
    };
  });
}
export function sucheKatalog(begriff: string, n = 8): GithubTreffer[] {
  const words = begriff
    .toLowerCase()
    .split(/\W+/)
    .filter((w) => w.length > 2);
  const scored = KATALOG.map((k) => {
    const hay = `${k.repo} ${k.zweck} ${k.kategorie}`.toLowerCase();
    const passung = words.length
      ? words.filter((w) => hay.includes(w)).length / words.length
      : 0.4;
    const meta = MOCK_META[k.repo] ?? {};
    const base = hashScore(k.repo);
    const score = Math.round(Math.min(100, base * 0.6 + passung * 40));
    return {
      name: k.repo,
      beschreibung: k.zweck,
      sterne: meta.sterne ?? 800,
      forks: Math.round((meta.sterne ?? 800) * 0.08),
      sprache: meta.sprache ?? "Python",
      lizenz: meta.lizenz ?? "MIT",
      lizenzklasse: (meta.lizenzklasse as LizenzKlasse) ?? "frei",
      score,
      url: `https://github.com/${k.repo}`,
      themen: [k.kategorie.toLowerCase()],
    } satisfies GithubTreffer;
  });
  return scored.sort((a, b) => b.score - a.score).slice(0, n);
}
export function findeAblauf(auftrag: string): AblaufVorlage | null {
  const words = auftrag
    .toLowerCase()
    .split(/\W+/)
    .filter((w) => w.length > 2);
  let best: AblaufVorlage | null = null;
  let bp = 0;
  for (const v of ABLAEUFE) {
    const heu = [...v.ausloeser, v.titel].join(" ").toLowerCase();
    const p = words.reduce((acc, w) => acc + (heu.includes(w) ? 3 : 0), 0);
    if (p > bp) {
      best = v;
      bp = p;
    }
  }
  return bp >= 3 ? best : null;
}
export function freierAblauf(auftrag: string): AblaufVorlage {
  return {
    id: "frei",
    titel: `Freier Auftrag: ${auftrag.slice(0, 60)}`,
    ziel: auftrag,
    ausloeser: [],
    schritte: [
      {
        art: "klaeren",
        titel: "Ziel klären",
        text: "Was genau soll am Ende dastehen, in einem Satz.",
        erklaerung: "Ohne Ziel kein Abbruchkriterium.",
        stufe: 0,
      },
      {
        art: "erkunden",
        titel: "Umfeld erkunden",
        text: "Welche Bausteine gibt es, welche Lizenzen.",
        erklaerung: "Erst sehen, was da ist.",
        stufe: 1,
      },
      {
        art: "entwerfen",
        titel: "Entwurf",
        text: "Grober Aufbau, drei Varianten, eine gewählt.",
        erklaerung: "Der billigste Moment für Korrekturen.",
        stufe: 1,
      },
      {
        art: "bauen",
        titel: "Bauen",
        text: "Kleinster lauffähiger Stand.",
        erklaerung: "Erst laufen, dann schön.",
        stufe: 2,
      },
      {
        art: "pruefen",
        titel: "Prüfen",
        text: "Gegen das Ziel aus Schritt 1.",
        erklaerung: "Wer baut, prüft nicht.",
        stufe: 1,
      },
      {
        art: "freigabe",
        titel: "Abgeben",
        text: "Ergebnis vorlegen.",
        erklaerung: "Ohne Freigabe kein Abschluss.",
        stufe: 1,
      },
    ],
  };
}
