/**
 * Nachschlagewerk: Befehle und Regler aller KI-Werkzeuge (src/data/befehle.json).
 * Ein neuer Eintrag ist eine Zeile JSON, ohne Programmierung.
 */
import befehleJson from "@/data/befehle.json";

export interface Referenz {
  werkzeug: string;
  gruppe: string;
  befehl: string;
  was: string;
}

export const REFERENZ = befehleJson as Referenz[];
export const WERKZEUGE = [...new Set(REFERENZ.map((r) => r.werkzeug))];

function norm(t: string): string {
  return t.toLowerCase().replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss");
}

/** Alle Wörter müssen vorkommen (Werkzeug, Gruppe, Befehl oder Wirkung). */
export function sucheReferenz(begriff = "", werkzeug?: string): Referenz[] {
  const woerter = norm(begriff).split(/\s+/).filter(Boolean);
  return REFERENZ.filter((r) => {
    if (werkzeug && r.werkzeug !== werkzeug) return false;
    const text = norm(`${r.werkzeug} ${r.gruppe} ${r.befehl} ${r.was}`);
    return woerter.every((w) => text.includes(w));
  });
}
