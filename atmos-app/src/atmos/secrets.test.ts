import { afterEach, describe, expect, it } from "vitest";
import {
  SECRETS_STORAGE_KEY,
  clearSecrets,
  loadSecrets,
  maskSecret,
  providerConnection,
  saveSecrets,
} from "./secrets";
afterEach(() => {
  localStorage.removeItem(SECRETS_STORAGE_KEY);
});
describe("provider secrets", () => {
  it("defaults to empty keys and Apple Intelligence off", () => {
    const s = loadSecrets();
    expect(s.appleIntelligenceEnabled).toBe(false);
    expect(s.googleApiKey).toBe("");
    expect(providerConnection("apple-intelligence", s).kind).toBe("off");
    expect(providerConnection("google", s).kind).toBe("missing");
  });
  it("persists Google key and Apple toggle", () => {
    saveSecrets({
      appleIntelligenceEnabled: true,
      googleApiKey: "AIzaSyDemoKey123456",
      googleCseId: "cx-demo",
      googleEnabled: true,
    });
    const s = loadSecrets();
    expect(s.appleIntelligenceEnabled).toBe(true);
    expect(providerConnection("apple-intelligence", s).kind).toBe("stub");
    expect(providerConnection("google", s).kind).toBe("connected");
    expect(maskSecret(s.googleApiKey)).toMatch(/^AIza/);
  });
  it("clearSecrets wipes storage", () => {
    saveSecrets({ googleApiKey: "secret" });
    clearSecrets();
    expect(loadSecrets().googleApiKey).toBe("");
  });
});
