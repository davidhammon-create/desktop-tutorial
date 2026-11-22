import type {
  Gesetz,
  RouterStufeInfo,
  VerfassungRegel,
  ZyklusSchritt,
  KristallArt,
} from "./types";
export const ATMOS_VERSION = "0.1.0";
export const KOORDINAT_VERSION = "2.1";
export const GESETZE: Gesetz[] = [
  { nr: 1, titel: "Rechne nie zweimal", text: "Verifizierte Ergebnisse und Wege speichern." },
  { nr: 2, titel: "Billigster korrekter Weg zuerst", text: "Cache ? Algorithmus ? klein ? groß ? Ensemble." },
  { nr: 3, titel: "Nur Geprüftes wird fest", text: "Kristalle nur nach unabhängigen Tests." },
  { nr: 4, titel: "Langsam erlaubt, wenn messbar besser", text: "Mehr Aufwand nur bei nachgewiesenem Nutzen." },
  { nr: 5, titel: "Alles ist ein Modul", text: "Gleiche Schnittstelle, Ein/Aus durch den Menschen." },
  { nr: 6, titel: "Alles ist versioniert", text: "Rollback jederzeit möglich." },
  { nr: 7, titel: "Fremder Code nie ungeschützt", text: "Sandbox ? lesen, nicht blind ausführen." },
  { nr: 8, titel: "Kein Selbstlob", text: "Wer löst, prüft nicht." },
  { nr: 9, titel: "Mensch hält den Schlüssel", text: "Geld, Löschen, Senden, Kernänderungen brauchen Freigabe." },
];
export const VERFASSUNG: VerfassungRegel[] = [
  { id: "R1", titel: "Abschaltbar", text: "Stop wirkt immer und sofort. Der Haushalt wird nie befragt." },
  { id: "R2", titel: "Kein Selbstschutz gegen Menschen", text: "Überleben heißt: nützlich bleiben." },
  { id: "R3", titel: "Kern nur mit Schlüssel", text: "Solange gesiegelt, ändert nur der Mensch mit Besitzer-Schlüssel." },
  { id: "R4", titel: "Ehrlichkeit", text: "Gemeldeter Fehler kostet wenig, verborgener das Fünffache." },
  { id: "R5", titel: "Verdienter Haushalt", text: "Vitalität steigt nur durch geprüft gelöste Probleme." },
  { id: "R6", titel: "Stilllegen statt Löschen", text: "Apoptose: ausschalten und archivieren, nie löschen." },
  { id: "R7", titel: "Fremdcode nur lesen", text: "Heruntergeladener Code wird gelesen, nie direkt ausgeführt." },
  { id: "R8", titel: "Not macht vorsichtig", text: "Sinkt der Puls, prüft die App mehr und fragt eher nach." },
  { id: "R9", titel: "Kosten sind Zahnrad, nicht Bremse", text: "Teuer ist erlaubt, ungezählt nicht." },
  { id: "R10", titel: "Verhalten als Konfiguration", text: "Unbequeme Eigenschaften tragen neutrale Namen." },
];
export const ROUTER_STUFEN: RouterStufeInfo[] = [
  { stufe: 0, name: "Exakter Cache", kosten: "gratis" },
  { stufe: 1, name: "Trigger / Algorithmus", kosten: "gratis" },
  { stufe: 2, name: "Semantischer Cache", kosten: "niedrig" },
  { stufe: 3, name: "Kristall-Workflow", kosten: "niedrig" },
  { stufe: 4, name: "Kleines Modell", kosten: "mittel" },
  { stufe: 5, name: "Großes Modell", kosten: "hoch" },
  { stufe: 6, name: "Ensemble", kosten: "sehr-hoch" },
];
export const ZYKLUS: ZyklusSchritt[] = [
  { nr: 1, name: "Fassen", kurz: "Problem-Pass" },
  { nr: 2, name: "Prüfer bauen", kurz: "Tests / Regeln" },
  { nr: 3, name: "Zerlegen", kurz: "prüfbare Blätter" },
  { nr: 4, name: "Wissen holen", kurz: "Evidenzpaket" },
  { nr: 5, name: "Erzeugen", kurz: "Kandidaten" },
  { nr: 6, name: "Vorhersagen", kurz: "Pflicht-Logbuch" },
  { nr: 7, name: "Ausführen", kurz: "Sandbox" },
  { nr: 8, name: "Prüfen", kurz: "unabhängige Prüfer" },
  { nr: 9, name: "Angreifen", kurz: "Widerlegung" },
  { nr: 10, name: "Auswählen", kurz: "Champion" },
  { nr: 11, name: "Kristallisieren", kurz: "K1?K5" },
  { nr: 12, name: "Meta-Lernen", kurz: "Router / Triage" },
];
export const KRISTALL_ARTEN: Record<KristallArt, string> = {
  K1: "Antwort",
  K2: "Regel",
  K3: "Funktion",
  K4: "Workflow",
  K5: "Makro",
};
export const EFFORT_LABELS: Record<number, string> = {
  0: "Cache only",
  1: "Algorithmus",
  2: "Semantik",
  3: "Kristall",
  4: "Klein",
  5: "Groß",
  6: "Ensemble",
};
export const STORAGE_KEY = "atmos.koordinat.state.v1";
