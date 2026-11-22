/**
 * Google API helpers for AtmOS (Custom Search + Gemini).
 * Keys: Einstellungen (localStorage) ? ATMOS_* / VITE_* env ? demo fallback.
 */
import { loadSecrets } from "./secrets";
export type GoogleMode = "live" | "demo";
export interface GoogleStatus {
  mode: GoogleMode;
  hasApiKey: boolean;
  hasCseId: boolean;
  geminiReady: boolean;
  searchReady: boolean;
  appleIntelligence: boolean;
  source: "settings" | "env" | "none";
}
export interface GoogleSearchHit {
  title: string;
  link: string;
  snippet: string;
  source: "google" | "demo";
}
export interface GeminiSuggest {
  text: string;
  source: "gemini" | "demo";
}
function readEnv(name: string): string {
  const env = import.meta.env as Record<string, string | undefined>;
  return (env[name] || "").trim();
}
/** Prefer Einstellungen secrets, then ATMOS_* / VITE_* env. */
export function getGoogleConfig() {
  const secrets = loadSecrets();
  const fromSettingsKey = secrets.googleEnabled ? secrets.googleApiKey.trim() : "";
  const fromSettingsCse = secrets.googleEnabled ? secrets.googleCseId.trim() : "";
  const envKey =
    readEnv("ATMOS_GOOGLE_API_KEY") ||
    readEnv("VITE_GOOGLE_API_KEY") ||
    readEnv("VITE_GEMINI_API_KEY") ||
    "";
  const envCse = readEnv("ATMOS_GOOGLE_CSE_ID") || readEnv("VITE_GOOGLE_CSE_ID") || "";
  const apiKey = fromSettingsKey || envKey;
  const cseId = fromSettingsCse || envCse;
  const geminiModel =
    secrets.geminiModel.trim() || readEnv("ATMOS_GEMINI_MODEL") || "gemini-2.0-flash";
  const source: GoogleStatus["source"] = fromSettingsKey
    ? "settings"
    : envKey
      ? "env"
      : "none";
  return { apiKey, cseId, geminiModel, source, secrets };
}
export function googleStatus(): GoogleStatus {
  const { apiKey, cseId, source, secrets } = getGoogleConfig();
  const hasApiKey = Boolean(apiKey);
  const hasCseId = Boolean(cseId);
  return {
    mode: hasApiKey ? "live" : "demo",
    hasApiKey,
    hasCseId,
    geminiReady: hasApiKey,
    searchReady: hasApiKey && hasCseId,
    appleIntelligence: secrets.appleIntelligenceEnabled,
    source,
  };
}
const DEMO_HITS: GoogleSearchHit[] = [
  {
    title: "google/generative-ai ? Gemini JS SDK",
    link: "https://github.com/google/generative-ai",
    snippet: "Demo-Treffer: offizielles Generative Language SDK (ohne API-Key).",
    source: "demo",
  },
  {
    title: "googleapis/google-api-nodejs-client",
    link: "https://github.com/googleapis/google-api-nodejs-client",
    snippet: "Demo-Treffer: Node-Client für Google APIs.",
    source: "demo",
  },
  {
    title: "Custom Search JSON API",
    link: "https://developers.google.com/custom-search/v1/overview",
    snippet: "Demo-Treffer: Programmable Search für /suche.",
    source: "demo",
  },
];
export async function googleCustomSearch(query: string, n = 5): Promise<GoogleSearchHit[]> {
  const q = query.trim() || "ki agent";
  const { apiKey, cseId } = getGoogleConfig();
  if (!apiKey || !cseId) {
    return DEMO_HITS.slice(0, n).map((h) => ({
      ...h,
      snippet: `${h.snippet} ? Query: ${q}`,
    }));
  }
  const url = new URL("https://www.googleapis.com/customsearch/v1");
  url.searchParams.set("key", apiKey);
  url.searchParams.set("cx", cseId);
  url.searchParams.set("q", q);
  url.searchParams.set("num", String(Math.min(Math.max(n, 1), 10)));
  const res = await fetch(url.toString());
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Google CSE ${res.status}: ${body.slice(0, 180)}`);
  }
  const data = (await res.json()) as {
    items?: { title?: string; link?: string; snippet?: string }[];
  };
  return (data.items ?? []).map((item) => ({
    title: item.title || "Ohne Titel",
    link: item.link || "",
    snippet: item.snippet || "",
    source: "google" as const,
  }));
}
export async function geminiComplete(prompt: string): Promise<GeminiSuggest> {
  const { apiKey, geminiModel } = getGoogleConfig();
  if (!apiKey) {
    return {
      source: "demo",
      text:
        "Demo (kein Google-Key in Einstellungen): Router empfiehlt Stufe 3?4 für Recherche. " +
        "Öffne ?K ? Einstellungen und speichere ATMOS_GOOGLE_API_KEY / Gemini-Key.",
    };
  }
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(
    geminiModel,
  )}:generateContent?key=${encodeURIComponent(apiKey)}`;
  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 512 },
    }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Gemini ${res.status}: ${body.slice(0, 180)}`);
  }
  const data = (await res.json()) as {
    candidates?: { content?: { parts?: { text?: string }[] } }[];
  };
  const text =
    data.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") ||
    "(leere Gemini-Antwort)";
  return { source: "gemini", text: text.trim() };
}
export async function geminiRouterHint(aufgabe: string, effort: number): Promise<GeminiSuggest> {
  return geminiComplete(
    `Du bist der AtmOS/KOORDINAT-Router (Stufen 0?6). Aktuelle Stufe: ${effort}.\n` +
      `Aufgabe: ${aufgabe || "(keine)"}\n` +
      `Antworte kurz auf Deutsch: empfohlene Stufe, warum, und ob Google-Suche oder GitHub-Modul sinnvoll ist.`,
  );
}
