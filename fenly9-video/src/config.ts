// ============================================================
//  FENLY 9 – Imagefilm "Recht ist Macht"
//  Zentrale Steuerung: Szenen, Sprechertext, Dauer, Farben
// ============================================================

export const FPS = 30;

/** true, sobald die MP3s in public/voice/ liegen (npm run voice) */
export const VOICE_ENABLED = false;
/** true, sobald public/music/score.mp3 existiert (düsterer Ambient-Score) */
export const MUSIC_ENABLED = false;
/** Untertitel einblenden (empfohlen für Social Media, da oft ohne Ton) */
export const SUBTITLES = true;

export const COLORS = {
  black: "#050506",
  ink: "#0c0c10",
  panel: "rgba(18,18,24,0.82)",
  line: "rgba(201,169,97,0.25)",
  gold: "#c9a961",
  goldLight: "#ecd9a4",
  crimson: "#b3122e",
  crimsonGlow: "rgba(179,18,46,0.55)",
  green: "#3fae7a",
  amber: "#d8962b",
  text: "#e9e6df",
  muted: "#8a8778",
};

export type SceneId =
  | "schatten" | "machiavelli" | "suntzu" | "reiche" | "reveal" | "module"
  | "vertrag" | "zukunft" | "unternehmen" | "briefing" | "angriff" | "finale";

export type Scene = { id: SceneId; seconds: number; voice: string };

/**
 * Sprechertext (weibliche Stimme: ruhig, tief, kontrolliert, mächtig).
 * Nach dem Erzeugen der Stimme: "seconds" an die echte Länge der MP3 anpassen
 * (Länge der Audiodatei + ca. 1,5 s Luft).
 */
export const SCENES: Scene[] = [
  { id: "schatten", seconds: 9,
    voice: "Macht war nie laut. Sie flüstert. In Paragraphen. In Klauseln. In dem, was zwischen den Zeilen steht." },
  { id: "machiavelli", seconds: 11,
    voice: "Machiavelli wusste: Wer einen anderen mächtig macht, richtet sich selbst zugrunde. Und wer die Regeln nicht kennt, macht immer die anderen mächtig." },
  { id: "suntzu", seconds: 12,
    voice: "Sun Tzu lehrte: Kenne deinen Feind und kenne dich selbst, und du wirst hundert Schlachten bestehen. Heute werden diese Schlachten nicht auf Feldern geschlagen. Sondern in Verträgen." },
  { id: "reiche", seconds: 11,
    voice: "Das Recht formt Gesellschaften. Es entscheidet in der Politik. Über Märkte, Fusionen, Existenzen. Wer das Recht beherrscht, beherrscht das Spiel." },
  { id: "reveal", seconds: 9,
    voice: "Einst hieß sie Machiavellex. Dann Chiara Lex. Heute ist sie mehr. FENLY 9." },
  { id: "module", seconds: 9,
    voice: "Legalus durchleuchtet. Opportunisma erkennt Chancen. Stratego plant den nächsten Zug." },
  { id: "vertrag", seconds: 11,
    voice: "Jeder Vertrag wird durchleuchtet. Jeder Vorteil. Jede Schwäche. Jede Klausel, die sich eines Tages gegen dich wenden könnte." },
  { id: "zukunft", seconds: 13,
    voice: "Was passiert, wenn Klausel vierzehn eintritt? FENLY 9 simuliert die Zukunft deines Falls. Szenario für Szenario. Option für Option. Bevor es andere tun." },
  { id: "unternehmen", seconds: 13,
    voice: "Dein Unternehmen, als lebendige Karte. Wer kann was. Wer arbeitet woran. Die richtige Aufgabe, an die richtige Person. Direkt auf ihr Telefon." },
  { id: "briefing", seconds: 8,
    voice: "Und jeden Morgen weißt du, was du wissen musst. Kurz. Präzise. Ohne Lärm." },
  { id: "angriff", seconds: 11,
    voice: "Wo bist du angreifbar? Wo ist es dein Konkurrent? Wer seine Schwächen zuerst kennt, verwandelt sie in Stärke." },
  { id: "finale", seconds: 11,
    voice: "Recht ist Macht. Wissen ist Vorsprung. FENLY 9. Sieh, was kommt." },
];

export const sceneFrames = (s: Scene) => Math.round(s.seconds * FPS);
export const TOTAL_FRAMES = SCENES.reduce((a, s) => a + sceneFrames(s), 0);
