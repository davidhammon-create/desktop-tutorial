import {
  clearSecrets,
  loadSecrets,
  maskSecret,
  providerConnection,
  saveSecrets,
  type ProviderSecrets,
} from "@/atmos/secrets";
import { googleStatus } from "@/atmos/google";
import { useCallback, useEffect, useState } from "react";
type Props = {
  onSaved?: (secrets: ProviderSecrets) => void;
};
export function SettingsPanel({ onSaved }: Props) {
  const [draft, setDraft] = useState<ProviderSecrets>(() => loadSecrets());
  const [savedFlash, setSavedFlash] = useState<string | null>(null);
  const [showGoogleKey, setShowGoogleKey] = useState(false);
  const status = googleStatus();
  useEffect(() => {
    setDraft(loadSecrets());
  }, []);
  const patch = useCallback((partial: Partial<ProviderSecrets>) => {
    setDraft((d) => ({ ...d, ...partial }));
  }, []);
  const save = () => {
    const next = saveSecrets(draft);
    setDraft(next);
    setSavedFlash("Gespeichert ? nur lokal (localStorage), nie im Repo.");
    onSaved?.(next);
    window.setTimeout(() => setSavedFlash(null), 3200);
  };
  const clear = () => {
    const next = clearSecrets();
    setDraft(next);
    setSavedFlash("Alle Provider-Keys gelöscht.");
    onSaved?.(next);
    window.setTimeout(() => setSavedFlash(null), 3200);
  };
  const apple = providerConnection("apple-intelligence", draft);
  const google = providerConnection("google", draft);
  const openai = providerConnection("openai", draft);
  const anthropic = providerConnection("anthropic", draft);
  return (
    <div className="atmos-settings">
      <p className="atmos-ov__lede">
        API-Keys und Provider. Lokal gespeichert ? nicht committed. Apple Intelligence zuerst.
      </p>
      <h3 className="atmos-ov__group-label">Status</h3>
      <ul className="atmos-ov__settings atmos-settings__status">
        <li>
          <span className="atmos-ov__settings-icon" data-tone="law">
            ?
          </span>
          <div>
            <strong>Apple Intelligence</strong>
            <span>Erster Provider</span>
          </div>
          <span className={`atmos-settings__pill atmos-settings__pill--${apple.kind}`}>{apple.label}</span>
        </li>
        <li>
          <span className="atmos-ov__settings-icon" data-tone={status.mode === "live" ? "ok" : "effort"}>
            G
          </span>
          <div>
            <strong>Google ? {status.mode}</strong>
            <span>
              Quelle {status.source} ? Gemini {status.geminiReady ? "an" : "aus"} ? Suche{" "}
              {status.searchReady ? "an" : "aus"}
            </span>
          </div>
          <span className={`atmos-settings__pill atmos-settings__pill--${google.kind}`}>{google.label}</span>
        </li>
      </ul>
      <h3 className="atmos-ov__group-label">1 ? Apple Intelligence</h3>
      <div className="atmos-settings__card">
        <div className="atmos-settings__row">
          <div>
            <strong>Aktivieren</strong>
            <span>On-device Stub ? bis System-API verfügbar</span>
          </div>
          <button
            type="button"
            className="atmos-settings__toggle"
            data-on={draft.appleIntelligenceEnabled}
            aria-pressed={draft.appleIntelligenceEnabled}
            aria-label="Apple Intelligence umschalten"
            onClick={() => patch({ appleIntelligenceEnabled: !draft.appleIntelligenceEnabled })}
          >
            <span className="atmos-settings__knob" />
          </button>
        </div>
        <label className="atmos-settings__field">
          <span>Notiz / Geräte-Kontext</span>
          <input
            value={draft.appleIntelligenceNote}
            onChange={(e) => patch({ appleIntelligenceNote: e.target.value })}
            placeholder="z. B. MacBook Pro ? Apple Intelligence"
            autoComplete="off"
          />
        </label>
      </div>
      <h3 className="atmos-ov__group-label">2 ? Google / Gemini</h3>
      <div className="atmos-settings__card">
        <div className="atmos-settings__row">
          <div>
            <strong>Google APIs</strong>
            <span>/suche ? Router ? Custom Search</span>
          </div>
          <button
            type="button"
            className="atmos-settings__toggle"
            data-on={draft.googleEnabled}
            aria-pressed={draft.googleEnabled}
            aria-label="Google APIs umschalten"
            onClick={() => patch({ googleEnabled: !draft.googleEnabled })}
          >
            <span className="atmos-settings__knob" />
          </button>
        </div>
        <label className="atmos-settings__field">
          <span>Google API Key einfügen</span>
          <div className="atmos-settings__secret">
            <input
              type={showGoogleKey ? "text" : "password"}
              value={draft.googleApiKey}
              onChange={(e) => patch({ googleApiKey: e.target.value })}
              placeholder="AIza? hier einfügen"
              autoComplete="off"
              spellCheck={false}
              aria-label="Google API Key"
            />
            <button type="button" className="atmos-ov__link" onClick={() => setShowGoogleKey((v) => !v)}>
              {showGoogleKey ? "Verbergen" : "Zeigen"}
            </button>
          </div>
          {draft.googleApiKey ? (
            <em className="atmos-settings__hint">Gespeichert als {maskSecret(draft.googleApiKey)}</em>
          ) : (
            <em className="atmos-settings__hint">Ohne Key: Demo-Treffer für /suche</em>
          )}
        </label>
        <label className="atmos-settings__field">
          <span>Custom Search Engine ID (optional)</span>
          <input
            value={draft.googleCseId}
            onChange={(e) => patch({ googleCseId: e.target.value })}
            placeholder="cx=?"
            autoComplete="off"
            spellCheck={false}
            aria-label="Google CSE ID"
          />
        </label>
        <label className="atmos-settings__field">
          <span>Gemini-Modell</span>
          <input
            value={draft.geminiModel}
            onChange={(e) => patch({ geminiModel: e.target.value })}
            placeholder="gemini-2.0-flash"
            autoComplete="off"
            aria-label="Gemini Modell"
          />
        </label>
      </div>
      <h3 className="atmos-ov__group-label">Weitere Provider</h3>
      <div className="atmos-settings__card">
        <div className="atmos-settings__row">
          <div>
            <strong>OpenAI</strong>
            <span>{openai.label}</span>
          </div>
          <button
            type="button"
            className="atmos-settings__toggle"
            data-on={draft.openaiEnabled}
            aria-pressed={draft.openaiEnabled}
            onClick={() => patch({ openaiEnabled: !draft.openaiEnabled })}
          >
            <span className="atmos-settings__knob" />
          </button>
        </div>
        <label className="atmos-settings__field">
          <span>OpenAI API Key</span>
          <input
            type="password"
            value={draft.openaiApiKey}
            onChange={(e) => patch({ openaiApiKey: e.target.value })}
            placeholder="sk-? hier einfügen"
            autoComplete="off"
            spellCheck={false}
            aria-label="OpenAI API Key"
          />
        </label>
        <div className="atmos-settings__row">
          <div>
            <strong>Anthropic</strong>
            <span>{anthropic.label}</span>
          </div>
          <button
            type="button"
            className="atmos-settings__toggle"
            data-on={draft.anthropicEnabled}
            aria-pressed={draft.anthropicEnabled}
            onClick={() => patch({ anthropicEnabled: !draft.anthropicEnabled })}
          >
            <span className="atmos-settings__knob" />
          </button>
        </div>
        <label className="atmos-settings__field">
          <span>Anthropic API Key</span>
          <input
            type="password"
            value={draft.anthropicApiKey}
            onChange={(e) => patch({ anthropicApiKey: e.target.value })}
            placeholder="sk-ant-? hier einfügen"
            autoComplete="off"
            spellCheck={false}
            aria-label="Anthropic API Key"
          />
        </label>
      </div>
      <div className="atmos-settings__actions">
        <button type="button" className="atmos-ov__run" onClick={save}>
          Speichern
        </button>
        <button type="button" className="atmos-settings__clear" onClick={clear}>
          Alle löschen
        </button>
      </div>
      {savedFlash ? <p className="atmos-settings__flash">{savedFlash}</p> : null}
    </div>
  );
}
