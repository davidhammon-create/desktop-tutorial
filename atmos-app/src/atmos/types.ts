import type { ModellEffort } from "./anbieter";
export type RouterStufe = 0 | 1 | 2 | 3 | 4 | 5 | 6;
export type KristallArt = "K1" | "K2" | "K3" | "K4" | "K5";
export type KristallStatus = "schatten" | "aktiv" | "verfallen";
export type ModulStatus = "aus" | "an" | "apoptose";
export type LizenzKlasse = "frei" | "bedingt" | "copyleft" | "unklar" | "keine";
export type Sicherheit = "ok" | "vorsicht" | "hoch";
export type VitalZustand = "stark" | "stabil" | "not" | "apoptose";
export type Modus = "normal" | "vorsicht" | "not" | "sicher";
export type Ampel = "gruen" | "gelb" | "rot";
export type LaufStand = "offen" | "laeuft" | "halt" | "fertig" | "abgebrochen" | "fehler";
export type TraceArt = "plan" | "schritt" | "werkzeug" | "ergebnis" | "halt" | "fehler" | "ende";
export type FreigabeArt =
  | "modul_an"
  | "lauf_weiter"
  | "kern_aendern"
  | "senden"
  | "loeschen"
  | "install";
export interface Gesetz {
  nr: number;
  titel: string;
  text: string;
}
export interface VerfassungRegel {
  id: string;
  titel: string;
  text: string;
}
export interface RouterStufeInfo {
  stufe: RouterStufe;
  name: string;
  kosten: "gratis" | "niedrig" | "mittel" | "hoch" | "sehr-hoch";
}
export interface ZyklusSchritt {
  nr: number;
  name: string;
  kurz: string;
}
export interface Kristall {
  id: string;
  art: KristallArt;
  titel: string;
  inhalt: string;
  status: KristallStatus;
  erstellt: number;
  treffer: number;
}
export interface Modul {
  id: string;
  name: string;
  zweck: string;
  kategorie: string;
  score: number;
  lizenz: string;
  lizenzklasse: LizenzKlasse;
  sicherheit: Sicherheit;
  status: ModulStatus;
  sterne: number;
  url: string;
  vital: number;
  eingebettet: number;
}
export interface GithubTreffer {
  name: string;
  beschreibung: string;
  sterne: number;
  forks: number;
  sprache: string;
  lizenz: string;
  lizenzklasse: LizenzKlasse;
  score: number;
  url: string;
  themen: string[];
}
export interface TraceEintrag {
  id: string;
  zeit: number;
  laufId: string | null;
  art: TraceArt;
  text: string;
  erklaerung?: string;
  modell?: string;
  stufe?: RouterStufe;
  cent: number;
}
export interface LaufSchritt {
  art: string;
  titel: string;
  text: string;
  erklaerung: string;
  stufe: number;
}
export interface Lauf {
  id: string;
  titel: string;
  ziel: string;
  ablaufId: string;
  schritt: number;
  stand: LaufStand;
  schritte: LaufSchritt[];
  quelle: string;
  gestartet: number;
}
export interface FreigabeAnfrage {
  id: string;
  art: FreigabeArt;
  titel: string;
  beschreibung: string;
  payload?: Record<string, unknown>;
  erstellt: number;
}
export interface CascadeStats {
  counts: Record<RouterStufe, number>;
}
export interface AtmosState {
  version: number;
  stop: boolean;
  siegel: "offen" | "gesiegelt";
  puls: number;
  modus: Modus;
  ampel: Ampel;
  kostenCent: number;
  budgetCent: number;
  effort: RouterStufe;
  /** Denktiefe der Modelle: aus · low · medium · high · xhigh · max (je Anbieter übersetzt) */
  modellEffort: ModellEffort;
  /** Laufendes Gespräch mit der Standard-KI (/frage); /neu leert es */
  gespraech: { role: "user" | "assistant"; content: string; anbieter?: string }[];
  module: Modul[];
  kristalle: Kristall[];
  laeufe: Lauf[];
  trace: TraceEintrag[];
  freigaben: FreigabeAnfrage[];
  cascade: CascadeStats;
  hunger: { problemtyp: string; ungeloest: number }[];
  lastCommand?: string;
}
export interface CommandResult {
  ok: boolean;
  message: string;
  needsFreigabe?: FreigabeAnfrage;
  navigate?: string;
  /** Asynchrone Folgeaktion, die der Provider ausführt (KI-Anfrage, Modellliste) */
  async?: { art: "frage" | "alle" | "modelle"; text?: string; anbieter?: string; modell?: string; effort?: ModellEffort; gespraech?: boolean };
}
