// ============================================================
//  FENLY 9 – "Wissen. Strategie. Macht."  (Cinematic Brand Film, v2)
//  Basierend auf dem Videoskript & Produktionsplan (9 Szenen, ~90 s)
// ============================================================
import { getStaticFiles, staticFile } from "remotion";
/** Sprechertext: ein Satz pro Zeile, in src/voice.json bearbeiten */
import V from "./voice.json";

export const FPS = 30;
/** Untertitel (Sprechertext) zusätzlich einblenden – z. B. für stumme Social-Feeds */
export const SUBTITLES = false;

export const COLORS = {
  black: "#040405", panel: "rgba(14,14,18,0.78)", line: "rgba(201,169,97,0.22)",
  gold: "#c9a961", goldLight: "#ecd9a4", crimson: "#b3122e", green: "#3fae7a",
  amber: "#d8962b", blue: "#7fa7d9", text: "#ece8df", muted: "#8a8778",
};

export type Scene = {
  id: string; title: string; min: number; voice: string;
  /** Einblendung (Typo) */
  claim?: string;
};

/** Sprechertext 1:1 aus dem Skript (src/voice.json). "min" = Mindestdauer; mit Stimme passt sich die Länge automatisch an. */
export const SCENES: Scene[] = [
  { id: "s1", title: "Der erste Gedanke", min: 9, claim: "MACHT BEGINNT MIT WISSEN.",
    voice: V.s1.join(" ") },
  { id: "s2", title: "Die Strategen", min: 10, claim: "ERKENNEN. VORAUSDENKEN. HANDELN.",
    voice: V.s2.join(" ") },
  { id: "s3", title: "Die Macht des Rechts", min: 11, claim: "RECHT FORMT DIE ZUKUNFT.",
    voice: V.s3.join(" ") },
  { id: "s4", title: "Fenly 9 tritt auf", min: 10, claim: "FENLY 9",
    voice: V.s4.join(" ") },
  { id: "s5", title: "Verträge lesen – Folgen verstehen", min: 14,
    voice: V.s5.join(" ") },
  { id: "s6", title: "Stratego – mögliche Zukünfte", min: 12, claim: "SZENARIEN. RISIKEN. OPTIONEN.",
    voice: V.s6.join(" ") },
  { id: "s7", title: "Das Unternehmen im Blick", min: 11,
    voice: V.s7.join(" ") },
  { id: "s8", title: "Die Information erreicht den Richtigen", min: 6,
    voice: V.s8.join(" ") },
  { id: "s9", title: "Der Abschluss", min: 10, claim: "WISSEN. STRATEGIE. MACHT.",
    voice: V.s9.join(" ") },
];

// ---------- Assets automatisch erkennen (public/…) ----------
const files = () => new Set(getStaticFiles().map((f) => f.name.replace(/^\//, "")));
export const has = (name: string) => files().has(name);
export const asset = (name: string) => staticFile(name);
/** erster vorhandener Name aus einer Liste (z. B. KI-Clip, sonst Standbild) */
export const firstOf = (...names: string[]) => names.find(has);
