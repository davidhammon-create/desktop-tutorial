import katalogJson from "@/data/katalog.json";
import ablaeufeJson from "@/data/ablaeufe.json";
import type { GithubTreffer, LaufSchritt, LizenzKlasse, Modul } from "./types";
export interface KatalogEintrag {
  kategorie: string;
  repo: string;
  zweck: string;
  /** Stand der Pruefung gegen GitHub (Sterne, SPDX-Lizenz) */
  sterne?: number;
  lizenz?: string | null;
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
const FREI = new Set(["MIT", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Apache-2.0", "Unlicense", "0BSD", "Zlib", "BSL-1.0", "CC0-1.0"]);
const BEDINGT = new Set(["MPL-2.0", "LGPL-2.1", "LGPL-3.0", "EPL-2.0"]);
const COPYLEFT = new Set(["GPL-2.0", "GPL-3.0", "AGPL-3.0"]);
export function lizenzklasse(spdx?: string | null): LizenzKlasse {
  if (!spdx) return "keine";
  if (FREI.has(spdx)) return "frei";
  if (BEDINGT.has(spdx)) return "bedingt";
  if (COPYLEFT.has(spdx)) return "copyleft";
  return "unklar";
}
export const KATEGORIEN = [...new Set(KATALOG.map((k) => k.kategorie))];
/** Bekanntheit 0..1 aus den Sternen (log), fuer den Score */
function bekanntheit(sterne = 0): number {
  return Math.min(1, Math.log10(Math.max(sterne, 1)) / 5);
}
function hashScore(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return 55 + (h % 40);
}
export function katalogAlsModule(limit = 12): Modul[] {
  // je Kategorie das bekannteste Projekt zuerst, damit die Startauswahl breit ist
  const erste = KATEGORIEN.map((kat) => KATALOG.filter((k) => k.kategorie === kat).sort((a, b) => (b.sterne ?? 0) - (a.sterne ?? 0))[0]);
  return erste.slice(0, limit).map((k, i) => {
    const score = Math.round(55 + 40 * bekanntheit(k.sterne) * (lizenzklasse(k.lizenz) === "frei" ? 1 : 0.8));
    return {
      id: `mod-${i}-${k.repo.replace("/", "-")}`,
      name: k.repo,
      zweck: k.zweck,
      kategorie: k.kategorie,
      score,
      lizenz: k.lizenz ?? "keine",
      lizenzklasse: lizenzklasse(k.lizenz),
      sicherheit: "ok",
      status: "aus",
      sterne: k.sterne ?? 0,
      url: `https://github.com/${k.repo}`,
      vital: 50,
      eingebettet: Date.now() - i * 86_400_000,
    };
  });
}
export function sucheKatalog(begriff: string, n = 8): GithubTreffer[] {
  const words = begriff
    .toLowerCase()
    .split(/[^\p{L}\p{N}.+#-]+/u)
    .filter((w) => w.length > 1);
  const scored = KATALOG.map((k) => {
    const hay = `${k.repo} ${k.zweck} ${k.kategorie}`.toLowerCase();
    const passung = words.length ? words.filter((w) => hay.includes(w)).length / words.length : 0.4;
    const klasse = lizenzklasse(k.lizenz);
    const score = Math.round(Math.min(100, 55 * passung + 30 * bekanntheit(k.sterne) + (klasse === "frei" ? 15 : klasse === "bedingt" ? 10 : 4)));
    return {
      name: k.repo,
      beschreibung: k.zweck,
      sterne: k.sterne ?? 0,
      forks: 0,
      sprache: "",
      lizenz: k.lizenz ?? "keine",
      lizenzklasse: klasse,
      score,
      url: `https://github.com/${k.repo}`,
      themen: [k.kategorie.toLowerCase()],
      passung,
    } as GithubTreffer & { passung: number };
  });
  const passend = words.length ? scored.filter((t) => t.passung > 0) : scored;
  return passend.sort((a, b) => b.score - a.score).slice(0, n);
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
