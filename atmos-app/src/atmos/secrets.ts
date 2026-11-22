/**
 * Demo secret store for AtmOS providers (localStorage).
 * Never commit real keys ? values stay in the browser/Electron profile only.
 */
export type ProviderId = "apple-intelligence" | "google" | "openai" | "anthropic";
export interface ProviderSecrets {
  /** Apple Intelligence ? first-class toggle; backend stubbed for now */
  appleIntelligenceEnabled: boolean;
  appleIntelligenceNote: string;
  /** Google Generative Language / Gemini API key */
  googleApiKey: string;
  /** Programmable Search Engine ID */
  googleCseId: string;
  geminiModel: string;
  googleEnabled: boolean;
  /** Optional other providers (stored for future wiring) */
  openaiApiKey: string;
  openaiEnabled: boolean;
  anthropicApiKey: string;
  anthropicEnabled: boolean;
}
export const SECRETS_STORAGE_KEY = "atmos.provider.secrets.v1";
export const DEFAULT_SECRETS: ProviderSecrets = {
  appleIntelligenceEnabled: false,
  appleIntelligenceNote: "",
  googleApiKey: "",
  googleCseId: "",
  geminiModel: "gemini-2.0-flash",
  googleEnabled: true,
  openaiApiKey: "",
  openaiEnabled: false,
  anthropicApiKey: "",
  anthropicEnabled: false,
};
function canUseStorage(): boolean {
  try {
    return typeof localStorage !== "undefined";
  } catch {
    return false;
  }
}
export function loadSecrets(): ProviderSecrets {
  if (!canUseStorage()) return { ...DEFAULT_SECRETS };
  try {
    const raw = localStorage.getItem(SECRETS_STORAGE_KEY);
    if (!raw) return { ...DEFAULT_SECRETS };
    const parsed = JSON.parse(raw) as Partial<ProviderSecrets>;
    return { ...DEFAULT_SECRETS, ...parsed };
  } catch {
    return { ...DEFAULT_SECRETS };
  }
}
export function saveSecrets(partial: Partial<ProviderSecrets>): ProviderSecrets {
  const next = { ...loadSecrets(), ...partial };
  if (canUseStorage()) {
    localStorage.setItem(SECRETS_STORAGE_KEY, JSON.stringify(next));
  }
  return next;
}
export function clearSecrets(): ProviderSecrets {
  if (canUseStorage()) localStorage.removeItem(SECRETS_STORAGE_KEY);
  return { ...DEFAULT_SECRETS };
}
export function maskSecret(value: string): string {
  const v = value.trim();
  if (!v) return "";
  if (v.length <= 8) return "????????";
  return `${v.slice(0, 4)}?${v.slice(-4)}`;
}
export type ConnectionKind = "connected" | "partial" | "missing" | "stub" | "off";
export function providerConnection(
  id: ProviderId,
  secrets: ProviderSecrets = loadSecrets(),
): { kind: ConnectionKind; label: string } {
  switch (id) {
    case "apple-intelligence":
      if (!secrets.appleIntelligenceEnabled) return { kind: "off", label: "Aus" };
      return { kind: "stub", label: "Aktiv (Stub ? warte auf System-API)" };
    case "google": {
      if (!secrets.googleEnabled) return { kind: "off", label: "Aus" };
      const key = secrets.googleApiKey.trim();
      const cse = secrets.googleCseId.trim();
      if (key && cse) return { kind: "connected", label: "Verbunden (Gemini + Suche)" };
      if (key) return { kind: "partial", label: "Gemini bereit ? CSE-ID fehlt" };
      return { kind: "missing", label: "Key fehlt ? Demo-Modus" };
    }
    case "openai":
      if (!secrets.openaiEnabled) return { kind: "off", label: "Aus" };
      return secrets.openaiApiKey.trim()
        ? { kind: "connected", label: "Key gespeichert" }
        : { kind: "missing", label: "Key fehlt" };
    case "anthropic":
      if (!secrets.anthropicEnabled) return { kind: "off", label: "Aus" };
      return secrets.anthropicApiKey.trim()
        ? { kind: "connected", label: "Key gespeichert" }
        : { kind: "missing", label: "Key fehlt" };
  }
}
