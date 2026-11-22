import { afterEach, describe, expect, it } from "vitest";
import {
  ANBIETER,
  baueAnfrage,
  frageAlle,
  frageKi,
  kiBereit,
  kiSchluessel,
  kiUebersicht,
  leseAntwort,
  leseEffort,
  modelleVon,
  setzeKi,
  type Sender,
} from "./anbieter";
import { executeCommand, leseFrageOptionen, standardKi } from "./commands";
import { REFERENZ, sucheReferenz } from "./befehle";
import { KATALOG, sucheKatalog } from "./katalog";
import { SECRETS_STORAGE_KEY, saveSecrets } from "./secrets";
import { createInitialState } from "./store";

afterEach(() => localStorage.removeItem(SECRETS_STORAGE_KEY));

const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status });

describe("Anbieter: alle KIs über eine Schnittstelle", () => {
  it("kennt 15 Anbieter in drei Bauarten", () => {
    expect(ANBIETER.length).toBe(15);
    expect(new Set(ANBIETER.map((a) => a.bauart))).toEqual(new Set(["anthropic", "openai", "gemini"]));
  });

  it("Claude: Messages-API, Effort in output_config, serverseitiger Fallback", () => {
    setzeKi("anthropic", { key: "sk-test" });
    const a = baueAnfrage("anthropic", [{ role: "user", content: "Hallo" }], { effort: "max", system: "S" });
    expect(a.url).toBe("https://api.anthropic.com/v1/messages");
    expect(a.headers["x-api-key"]).toBe("sk-test");
    expect(a.headers["anthropic-dangerous-direct-browser-access"]).toBe("true");
    expect(a.body).toMatchObject({ model: "claude-opus-5-5", output_config: { effort: "max" }, system: "S", fallbacks: "default" });
    expect(baueAnfrage("anthropic", [], { effort: "aus" }).body.output_config).toBeUndefined();
  });

  it("übersetzt den Effort je Anbieter", () => {
    expect(baueAnfrage("openai", [], { effort: "xhigh" }).body.reasoning_effort).toBe("high");
    expect(baueAnfrage("openrouter", [], { effort: "low" }).body.reasoning).toEqual({ effort: "low" });
    const g = baueAnfrage("gemini", [{ role: "user", content: "a" }, { role: "assistant", content: "b" }], { effort: "medium" });
    expect(g.url).toContain(":generateContent");
    expect((g.body.contents as { role: string }[]).map((c) => c.role)).toEqual(["user", "model"]);
    expect(g.body.generationConfig).toEqual({ thinkingConfig: { thinkingBudget: 8192 } });
    const m = baueAnfrage("mistral", [], { effort: "high", system: "S" }).body;
    expect(m.reasoning_effort).toBeUndefined();
    expect((m.messages as { role: string }[])[0].role).toBe("system");
  });

  it("liest Antworten aller Bauarten, auch Ablehnungen", () => {
    expect(leseAntwort("anthropic", { content: [{ type: "thinking" }, { type: "text", text: "A" }] }).text).toBe("A");
    expect(leseAntwort("anthropic", { stop_reason: "refusal", content: [] }).text).toMatch(/^\[abgelehnt\]/);
    expect(leseAntwort("gemini", { candidates: [{ content: { parts: [{ text: "x", thought: true }, { text: "G" }] } }] }).text).toBe("G");
    expect(leseAntwort("openai", { choices: [{ message: { content: "O" } }] }).text).toBe("O");
  });

  it("deutsche Effort-Wörter", () => {
    expect(leseEffort("hoch")).toBe("high");
    expect(leseEffort("maximal")).toBe("max");
    expect(leseEffort("turbo")).toBeNull();
  });

  it("alte Einstellungsfelder gelten weiter als Schlüssel", () => {
    saveSecrets({ openaiApiKey: "sk-alt", googleApiKey: "g-alt", googleEnabled: true });
    expect(kiSchluessel("openai")).toBe("sk-alt");
    expect(kiSchluessel("gemini")).toBe("g-alt");
    expect(kiBereit("openai")).toBe(true);
  });

  it("lokale KIs brauchen keinen Schlüssel, aber eine Freischaltung", () => {
    expect(kiBereit("ollama")).toBe(false);
    setzeKi("ollama", { aktiv: true });
    expect(kiBereit("ollama")).toBe(true);
    expect(kiBereit("eigener")).toBe(false); // ohne Modell nie bereit
  });

  it("frageKi, frageAlle und modelleVon über einen Test-Sender", async () => {
    setzeKi("anthropic", { key: "sk-test" });
    setzeKi("openai", { key: "sk-o" });
    const sender: Sender = async (url) => {
      if (url.endsWith("/models")) return json({ data: [{ id: "m-b" }, { id: "m-a" }] });
      if (url.includes("anthropic")) return json({ content: [{ type: "text", text: "Antwort" }], model: "claude-opus-5-5", stop_reason: "end_turn" });
      return json({ error: { message: "falscher Schlüssel" } }, 401);
    };
    const a = await frageKi("anthropic", [{ role: "user", content: "Hi" }], {}, sender);
    expect(a.text).toBe("Antwort");
    const alle = await frageAlle("Hi", ["anthropic", "openai"], {}, sender);
    expect(alle.find((x) => x.anbieter === "anthropic")?.text).toBe("Antwort");
    expect(alle.find((x) => x.anbieter === "openai")?.fehler).toContain("401");
    expect(await modelleVon("openai", sender)).toEqual(["m-a", "m-b"]);
  });

  it("ohne Schlüssel keine Anfrage", async () => {
    await expect(frageKi("openai", [{ role: "user", content: "x" }])).rejects.toThrow(/Kein Schlüssel/);
  });

  it("Übersicht verrät nie den Schlüssel", () => {
    setzeKi("groq", { key: "gsk-geheim" });
    expect(JSON.stringify(kiUebersicht())).not.toContain("geheim");
  });
});

describe("Befehle für alle KIs", () => {
  it("/effort nimmt Denktiefe und Router-Stufe", () => {
    let { state } = executeCommand(createInitialState(), "/effort max");
    expect(state.modellEffort).toBe("max");
    ({ state } = executeCommand(state, "/effort 6"));
    expect(state.effort).toBe(6);
    expect(state.modellEffort).toBe("max");
  });

  it("/frage ohne KI verweist auf die KI-Einstellungen, mit KI startet sie die Anfrage", () => {
    let r = executeCommand(createInitialState(), "/frage Hallo").result;
    expect(r.ok).toBe(false);
    expect(r.navigate).toBe("kis");
    setzeKi("anthropic", { key: "sk-test" });
    r = executeCommand(createInitialState(), "/frage --effort low Hallo Welt").result;
    expect(r.async).toMatchObject({ art: "frage", anbieter: "anthropic", effort: "low", text: "Hallo Welt", gespraech: true });
  });

  it("@anbieter, --modell und --effort werden aus dem Text gezogen", () => {
    expect(leseFrageOptionen("@gemini --effort hoch --modell x Was ist RAG?")).toEqual({ text: "Was ist RAG?", anbieter: "gemini", modell: "x", effort: "high" });
    expect(leseFrageOptionen("Mail an @peter").anbieter).toBeUndefined();
  });

  it("/anbieter setzt die Standard-KI", () => {
    executeCommand(createInitialState(), "/anbieter mistral");
    expect(standardKi()).toBe("mistral");
  });

  it("/mach ab Stufe 4 lässt eine echte KI planen, Stufe 6 alle", () => {
    setzeKi("anthropic", { key: "sk-test" });
    let s = executeCommand(createInitialState(), "/effort 4").state;
    expect(executeCommand(s, "/mach Website bauen").result.async?.art).toBe("frage");
    s = executeCommand(s, "/effort 6").state;
    expect(executeCommand(s, "/mach Website bauen").result.async?.art).toBe("alle");
    expect(executeCommand(createInitialState(), "/mach Website bauen").result.async).toBeUndefined();
  });

  it("Referenz und Katalog sind vollständig und durchsuchbar", () => {
    expect(REFERENZ.length).toBeGreaterThanOrEqual(200);
    expect(new Set(sucheReferenz("effort").map((r) => r.gruppe))).toContain("Claude Code");
    expect(KATALOG.length).toBeGreaterThanOrEqual(200);
    expect(new Set(KATALOG.map((k) => k.repo.toLowerCase())).size).toBe(KATALOG.length);
    expect(sucheKatalog("mcp server", 8).some((t) => t.name === "modelcontextprotocol/servers")).toBe(true);
    expect(executeCommand(createInitialState(), "/katalog MCP").result.message).toContain("modelcontextprotocol/servers");
    expect(executeCommand(createInitialState(), "/befehle compact").result.message).toContain("/compact");
  });
});
