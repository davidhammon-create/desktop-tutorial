/**
 * Alle KIs über eine Schnittstelle.
 *
 * Drei Bauarten decken praktisch jeden Anbieter ab:
 *   anthropic – Claude (Messages-API)
 *   gemini    – Google Gemini (generateContent)
 *   openai    – OpenAI und alles mit OpenAI-Schnittstelle: Mistral, Groq, DeepSeek, xAI, OpenRouter,
 *               Together, Perplexity, Fireworks, Cerebras, Ollama, LM Studio, vLLM, LiteLLM …
 *
 * Ein Effort-Regler (aus · low · medium · high · xhigh · max) wird je Anbieter auf dessen Parameter
 * übersetzt. Schlüssel liegen nur lokal (localStorage bzw. Electron-Profil) und gehen nur an den
 * jeweiligen Anbieter. Standardmodelle sind Startwerte: /modelle <anbieter> holt die aktuelle Liste.
 */
import { loadSecrets, saveSecrets, type ProviderSecrets } from "./secrets";

export const MODELL_EFFORT = ["aus", "low", "medium", "high", "xhigh", "max"] as const;
export type ModellEffort = (typeof MODELL_EFFORT)[number];
export type Bauart = "anthropic" | "openai" | "gemini";
export type EffortParameter = "output_config.effort" | "reasoning_effort" | "reasoning.effort" | "thinkingBudget" | null;

export interface AnbieterDef {
  id: string;
  name: string;
  bauart: Bauart;
  basis: string;
  modell: string;
  effort: EffortParameter;
  lokal?: boolean;
  /** Umgebungsvariable (Vite: ATMOS_ / VITE_ Präfix) */
  env: string;
  konsole: string;
  hinweis?: string;
}

export const ANBIETER: AnbieterDef[] = [
  { id: "anthropic", name: "Anthropic Claude", bauart: "anthropic", basis: "https://api.anthropic.com/v1", modell: "claude-opus-5-5",
    effort: "output_config.effort", env: "ANTHROPIC_API_KEY", konsole: "https://platform.claude.com" },
  { id: "openai", name: "OpenAI", bauart: "openai", basis: "https://api.openai.com/v1", modell: "gpt-5",
    effort: "reasoning_effort", env: "OPENAI_API_KEY", konsole: "https://platform.openai.com/api-keys" },
  { id: "gemini", name: "Google Gemini", bauart: "gemini", basis: "https://generativelanguage.googleapis.com/v1beta", modell: "gemini-2.5-flash",
    effort: "thinkingBudget", env: "GEMINI_API_KEY", konsole: "https://aistudio.google.com/apikey" },
  { id: "mistral", name: "Mistral", bauart: "openai", basis: "https://api.mistral.ai/v1", modell: "mistral-large-latest",
    effort: null, env: "MISTRAL_API_KEY", konsole: "https://console.mistral.ai" },
  { id: "deepseek", name: "DeepSeek", bauart: "openai", basis: "https://api.deepseek.com/v1", modell: "deepseek-chat",
    effort: null, env: "DEEPSEEK_API_KEY", konsole: "https://platform.deepseek.com" },
  { id: "xai", name: "xAI Grok", bauart: "openai", basis: "https://api.x.ai/v1", modell: "grok-4",
    effort: null, env: "XAI_API_KEY", konsole: "https://console.x.ai" },
  { id: "groq", name: "Groq", bauart: "openai", basis: "https://api.groq.com/openai/v1", modell: "llama-3.3-70b-versatile",
    effort: null, env: "GROQ_API_KEY", konsole: "https://console.groq.com/keys" },
  { id: "openrouter", name: "OpenRouter (hunderte Modelle)", bauart: "openai", basis: "https://openrouter.ai/api/v1", modell: "openrouter/auto",
    effort: "reasoning.effort", env: "OPENROUTER_API_KEY", konsole: "https://openrouter.ai/keys" },
  { id: "together", name: "Together AI", bauart: "openai", basis: "https://api.together.xyz/v1", modell: "meta-llama/Llama-3.3-70B-Instruct-Turbo",
    effort: null, env: "TOGETHER_API_KEY", konsole: "https://api.together.ai" },
  { id: "perplexity", name: "Perplexity (mit Websuche)", bauart: "openai", basis: "https://api.perplexity.ai", modell: "sonar",
    effort: null, env: "PERPLEXITY_API_KEY", konsole: "https://www.perplexity.ai/settings/api" },
  { id: "fireworks", name: "Fireworks AI", bauart: "openai", basis: "https://api.fireworks.ai/inference/v1",
    modell: "accounts/fireworks/models/llama-v3p3-70b-instruct", effort: null, env: "FIREWORKS_API_KEY", konsole: "https://fireworks.ai" },
  { id: "cerebras", name: "Cerebras", bauart: "openai", basis: "https://api.cerebras.ai/v1", modell: "llama-3.3-70b",
    effort: null, env: "CEREBRAS_API_KEY", konsole: "https://cloud.cerebras.ai" },
  { id: "ollama", name: "Ollama (lokal, kostenlos)", bauart: "openai", basis: "http://localhost:11434/v1", modell: "llama3.2",
    effort: null, lokal: true, env: "", konsole: "https://ollama.com/download",
    hinweis: "Browser-Zugriff erlauben: OLLAMA_ORIGINS=* ollama serve" },
  { id: "lmstudio", name: "LM Studio (lokal)", bauart: "openai", basis: "http://localhost:1234/v1", modell: "local-model",
    effort: null, lokal: true, env: "", konsole: "https://lmstudio.ai", hinweis: "In LM Studio den lokalen Server mit CORS starten." },
  { id: "eigener", name: "Eigener Server (OpenAI-kompatibel)", bauart: "openai", basis: "http://localhost:8000/v1", modell: "",
    effort: null, lokal: true, env: "EIGENER_KEY", konsole: "", hinweis: "vLLM, LiteLLM-Proxy, LocalAI … Adresse und Modell eintragen." },
];

const OPENAI_EFFORT: Record<Exclude<ModellEffort, "aus">, string> = { low: "low", medium: "medium", high: "high", xhigh: "high", max: "high" };
const GEMINI_BUDGET: Record<Exclude<ModellEffort, "aus">, number> = { low: 1024, medium: 8192, high: 24576, xhigh: 32768, max: -1 };
const FALLBACK_BETA = "server-side-fallback-2026-07-01";
const MIT_FALLBACK = new Set(["claude-fable-5-2", "claude-fable-5-1", "claude-opus-5-5", "claude-opus-5", "claude-sonnet-5-5"]);

export interface KiEinstellung {
  key?: string;
  modell?: string;
  basis?: string;
}

export interface Nachricht {
  role: "user" | "assistant";
  content: string;
}

export interface KiAntwort {
  anbieter: string;
  text: string;
  modell?: string;
  ende?: string;
  ms: number;
  fehler?: string;
}

export function anbieterDef(id: string): AnbieterDef {
  const a = ANBIETER.find((x) => x.id === id);
  if (!a) throw new Error(`Unbekannter Anbieter: ${id}. Bekannt: ${ANBIETER.map((x) => x.id).join(", ")}`);
  return a;
}

function readEnv(name: string): string {
  if (!name) return "";
  try {
    const env = (import.meta as unknown as { env?: Record<string, string | undefined> }).env ?? {};
    return (env[`ATMOS_${name}`] || env[`VITE_${name}`] || "").trim();
  } catch {
    return "";
  }
}

/** Schlüssel: KI-Panel → ältere Einstellungsfelder (Google/OpenAI/Anthropic) → Umgebungsvariable. */
export function kiSchluessel(id: string, s: ProviderSecrets = loadSecrets()): string {
  const eigen = s.ki?.[id]?.key?.trim();
  if (eigen) return eigen;
  if (id === "gemini" && s.googleEnabled && s.googleApiKey.trim()) return s.googleApiKey.trim();
  if (id === "openai" && s.openaiApiKey.trim()) return s.openaiApiKey.trim();
  if (id === "anthropic" && s.anthropicApiKey.trim()) return s.anthropicApiKey.trim();
  const def = ANBIETER.find((a) => a.id === id);
  return def ? readEnv(def.env) || (id === "gemini" ? readEnv("GOOGLE_API_KEY") : "") : "";
}

export function kiKonfig(id: string, s: ProviderSecrets = loadSecrets()) {
  const def = anbieterDef(id);
  const e = s.ki?.[id] ?? {};
  const modell = e.modell?.trim() || (id === "gemini" && s.geminiModel?.trim() && s.geminiModel !== "gemini-2.0-flash" ? s.geminiModel.trim() : def.modell);
  return { ...def, modell, basis: e.basis?.trim() || def.basis, key: kiSchluessel(id, s) };
}

export function kiBereit(id: string, s: ProviderSecrets = loadSecrets()): boolean {
  const k = kiKonfig(id, s);
  if (!k.modell) return false;
  return k.lokal ? Boolean(s.ki?.[id]?.aktiv) : Boolean(k.key);
}

export function setzeKi(id: string, patch: KiEinstellung & { aktiv?: boolean }): ProviderSecrets {
  anbieterDef(id);
  const s = loadSecrets();
  const ki = { ...(s.ki ?? {}) };
  ki[id] = { ...(ki[id] ?? {}), ...patch };
  return saveSecrets({ ki });
}

export function kiUebersicht(s: ProviderSecrets = loadSecrets()) {
  return ANBIETER.map((a) => {
    const k = kiKonfig(a.id, s);
    return { id: a.id, name: a.name, bauart: a.bauart, modell: k.modell, basis: k.basis, lokal: Boolean(a.lokal),
      bereit: kiBereit(a.id, s), effort: a.effort, schluessel: Boolean(k.key), env: a.env, konsole: a.konsole, hinweis: a.hinweis };
  });
}

export function istModellEffort(x: string): x is ModellEffort {
  return (MODELL_EFFORT as readonly string[]).includes(x);
}

/** Deutsche und englische Wörter für den Effort-Regler. */
export function leseEffort(x: string): ModellEffort | null {
  const t = x.trim().toLowerCase();
  const map: Record<string, ModellEffort> = {
    aus: "aus", off: "aus", none: "aus", keiner: "aus",
    low: "low", niedrig: "low", wenig: "low", schnell: "low",
    medium: "medium", mittel: "medium", normal: "medium",
    high: "high", hoch: "high", gruendlich: "high", gründlich: "high",
    xhigh: "xhigh", "sehr-hoch": "xhigh", sehrhoch: "xhigh",
    max: "max", maximal: "max", maximum: "max",
  };
  return map[t] ?? null;
}

export interface Anfrage {
  url: string;
  headers: Record<string, string>;
  body: Record<string, unknown>;
}

/** Baut genau eine Anfrage (ohne Netz prüfbar). */
export function baueAnfrage(
  id: string,
  verlauf: Nachricht[],
  opt: { modell?: string; effort?: ModellEffort; system?: string; maxTokens?: number } = {},
  s: ProviderSecrets = loadSecrets(),
): Anfrage {
  const k = kiKonfig(id, s);
  const modell = opt.modell?.trim() || k.modell;
  if (!modell) throw new Error(`Für ${k.name} ist kein Modell gesetzt. KIs → ${k.name} → Modell eintragen.`);
  const effort = opt.effort ?? "high";
  const headers: Record<string, string> = { "content-type": "application/json" };
  const msgs = verlauf.map((m) => ({ role: m.role, content: m.content }));

  if (k.bauart === "anthropic") {
    headers["x-api-key"] = k.key;
    headers["anthropic-version"] = "2023-06-01";
    headers["anthropic-dangerous-direct-browser-access"] = "true";
    const body: Record<string, unknown> = { model: modell, max_tokens: opt.maxTokens ?? 16000, messages: msgs };
    if (opt.system) body.system = opt.system;
    if (effort !== "aus") body.output_config = { effort };
    if (MIT_FALLBACK.has(modell)) {
      headers["anthropic-beta"] = FALLBACK_BETA;
      body.fallbacks = "default"; // bei Ablehnung übernimmt serverseitig ein passendes Modell
    }
    return { url: `${k.basis}/messages`, headers, body };
  }

  if (k.bauart === "gemini") {
    headers["x-goog-api-key"] = k.key;
    const body: Record<string, unknown> = {
      contents: msgs.map((m) => ({ role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.content }] })),
    };
    if (opt.system) body.systemInstruction = { parts: [{ text: opt.system }] };
    if (effort !== "aus") body.generationConfig = { thinkingConfig: { thinkingBudget: GEMINI_BUDGET[effort] } };
    return { url: `${k.basis}/models/${encodeURIComponent(modell)}:generateContent`, headers, body };
  }

  if (k.key) headers.authorization = `Bearer ${k.key}`;
  const body: Record<string, unknown> = {
    model: modell,
    messages: [...(opt.system ? [{ role: "system", content: opt.system }] : []), ...msgs],
  };
  if (effort !== "aus" && k.effort === "reasoning_effort") body.reasoning_effort = OPENAI_EFFORT[effort];
  if (effort !== "aus" && k.effort === "reasoning.effort") body.reasoning = { effort: OPENAI_EFFORT[effort] };
  return { url: `${k.basis}/chat/completions`, headers, body };
}

type Json = Record<string, any>; // eslint-disable-line @typescript-eslint/no-explicit-any

export function leseAntwort(bauart: Bauart, d: Json): { text: string; modell?: string; ende?: string } {
  if (bauart === "anthropic") {
    if (d.stop_reason === "refusal") {
      const det = d.stop_details ?? {};
      return { text: `[abgelehnt] ${det.explanation ?? det.category ?? ""}`.trim(), modell: d.model, ende: "refusal" };
    }
    const text = (d.content ?? []).filter((b: Json) => b.type === "text").map((b: Json) => b.text ?? "").join("");
    return { text, modell: d.model, ende: d.stop_reason };
  }
  if (bauart === "gemini") {
    const k = d.candidates?.[0] ?? {};
    const text = (k.content?.parts ?? []).filter((p: Json) => !p.thought).map((p: Json) => p.text ?? "").join("");
    return { text, modell: d.modelVersion, ende: k.finishReason };
  }
  const w = d.choices?.[0] ?? {};
  return { text: w.message?.content ?? "", modell: d.model, ende: w.finish_reason };
}

export type Sender = (url: string, init: RequestInit) => Promise<Response>;

async function sendeJson(senden: Sender, url: string, init: RequestInit): Promise<Json> {
  let res: Response;
  try {
    res = await senden(url, init);
  } catch (e) {
    throw new Error(
      `nicht erreichbar (${e instanceof Error ? e.message : String(e)}). Läuft der Dienst? Lokale Server brauchen CORS-Freigabe.`,
    );
  }
  const text = await res.text();
  let data: Json = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { roh: text };
  }
  if (!res.ok) {
    const msg = typeof data.error === "object" ? data.error?.message : data.error;
    throw new Error(`HTTP ${res.status}: ${msg || text.slice(0, 200)}`);
  }
  return data;
}

export async function frageKi(
  id: string,
  verlauf: Nachricht[],
  opt: { modell?: string; effort?: ModellEffort; system?: string } = {},
  senden: Sender = (u, i) => fetch(u, i),
  s: ProviderSecrets = loadSecrets(),
): Promise<KiAntwort> {
  const k = kiKonfig(id, s);
  if (!k.lokal && !k.key) {
    throw new Error(`Kein Schlüssel für ${k.name}. KIs → ${k.name} → Schlüssel eintragen.`);
  }
  const a = baueAnfrage(id, verlauf, opt, s);
  const t0 = Date.now();
  const d = await sendeJson(senden, a.url, { method: "POST", headers: a.headers, body: JSON.stringify(a.body) });
  return { anbieter: id, ...leseAntwort(k.bauart, d), ms: Date.now() - t0 };
}

/** Dieselbe Frage parallel an mehrere KIs – Fehler einer KI stoppen die anderen nicht. */
export async function frageAlle(
  frage: string,
  ids: string[] = kiUebersicht().filter((a) => a.bereit).map((a) => a.id),
  opt: { effort?: ModellEffort; system?: string } = {},
  senden?: Sender,
  s?: ProviderSecrets,
): Promise<KiAntwort[]> {
  return Promise.all(
    ids.map((id) =>
      frageKi(id, [{ role: "user", content: frage }], opt, senden, s).catch(
        (e): KiAntwort => ({ anbieter: id, text: "", ms: 0, fehler: e instanceof Error ? e.message : String(e) }),
      ),
    ),
  );
}

/** Aktuelle Modellliste direkt beim Anbieter. */
export async function modelleVon(id: string, senden: Sender = (u, i) => fetch(u, i), s: ProviderSecrets = loadSecrets()): Promise<string[]> {
  const k = kiKonfig(id, s);
  if (k.bauart === "anthropic") {
    const d = await sendeJson(senden, `${k.basis}/models?limit=100`, {
      headers: { "x-api-key": k.key, "anthropic-version": "2023-06-01", "anthropic-dangerous-direct-browser-access": "true" },
    });
    return (d.data ?? []).map((m: Json) => m.id);
  }
  if (k.bauart === "gemini") {
    const d = await sendeJson(senden, `${k.basis}/models?pageSize=200`, { headers: { "x-goog-api-key": k.key } });
    return (d.models ?? []).map((m: Json) => String(m.name).replace(/^models\//, ""));
  }
  const d = await sendeJson(senden, `${k.basis}/models`, { headers: k.key ? { authorization: `Bearer ${k.key}` } : {} });
  return (d.data ?? []).map((m: Json) => m.id).sort();
}

/** Effort-Stufe der Kaskade (0–6) → Modell-Effort, wenn keiner ausdrücklich gesetzt ist. */
export function effortAusStufe(stufe: number): ModellEffort {
  return stufe <= 3 ? "low" : stufe === 4 ? "medium" : stufe === 5 ? "high" : "max";
}
