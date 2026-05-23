/**
 * kiProvider.js — Mock-Modus (Demo ohne Backend)
 * Alle invokeLLM-Aufrufe gehen an den mock-basierten base44Client.
 * Für echte KI: KI_MODE = "offline" + OFFLINE_KI_URL einstellen.
 */
import { base44 } from "@/api/base44Client";

const KI_MODE = "base44"; // "base44" = mock | "offline" = lokale KI
const OFFLINE_KI_URL = "http://localhost:11434/api/chat";
const OFFLINE_KI_MODEL = "llama3";

export async function invokeLLM(params) {
  if (KI_MODE === "offline") return await _invokeOfflineLLM(params);
  return await base44.integrations.Core.InvokeLLM(params);
}

async function _invokeOfflineLLM({ prompt, response_json_schema, model }) {
  const messages = [
    { role: "system", content: response_json_schema ? `Antworte AUSSCHLIESSLICH mit validem JSON. Schema: ${JSON.stringify(response_json_schema)}` : "Du bist ein juristischer KI-Assistent." },
    { role: "user", content: prompt }
  ];
  const res = await fetch(OFFLINE_KI_URL, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ model: model || OFFLINE_KI_MODEL, messages, stream: false, ...(response_json_schema ? { format: "json" } : {}) }) });
  if (!res.ok) throw new Error(`Offline-KI Fehler: ${res.status}`);
  const data = await res.json();
  const raw = data?.message?.content || data?.choices?.[0]?.message?.content || data?.response || "";
  if (!response_json_schema) return raw;
  try { return JSON.parse(raw.replace(/```json\n?/g,'').replace(/```\n?/g,'').trim()); } catch { return {}; }
}

export async function uploadFile(params) {
  return await base44.integrations.Core.UploadFile(params);
}
