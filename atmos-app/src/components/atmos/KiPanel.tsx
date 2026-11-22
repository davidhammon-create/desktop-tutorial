import { MODELL_EFFORT, frageKi, kiUebersicht, setzeKi, type ModellEffort } from "@/atmos/anbieter";
import { EFFORT_LABELS } from "@/atmos/constants";
import { standardKi } from "@/atmos/commands";
import { useAtmos } from "@/atmos/provider";
import { loadSecrets, saveSecrets } from "@/atmos/secrets";
import { useState } from "react";

const EFFORT_TEXT: Record<ModellEffort, string> = {
  aus: "Standard des Modells",
  low: "schnell, billig",
  medium: "ausgewogen",
  high: "gründlich",
  xhigh: "sehr gründlich",
  max: "maximal, teuer",
};

/** Alle KI-Anbieter verbinden, Standard wählen, Effort für alle setzen. */
export function KiPanel() {
  const { state, run } = useAtmos();
  const [stand, setStand] = useState(0);
  const [offen, setOffen] = useState<string | null>(null);
  const [zeigeKey, setZeigeKey] = useState(false);
  const [test, setTest] = useState<Record<string, string>>({});
  const kis = kiUebersicht();
  const std = standardKi();
  const s = loadSecrets();
  void stand;

  const speichere = (id: string, feld: "key" | "modell" | "basis", wert: string) => {
    setzeKi(id, { [feld]: wert });
    setStand((x) => x + 1);
  };
  const teste = async (id: string) => {
    setTest((t) => ({ ...t, [id]: "teste …" }));
    try {
      const a = await frageKi(id, [{ role: "user", content: "Antworte nur mit: OK" }], { effort: "low" });
      setTest((t) => ({ ...t, [id]: `✓ ${a.modell ?? ""} antwortet in ${(a.ms / 1000).toFixed(1)} s: ${a.text.slice(0, 40)}` }));
    } catch (e) {
      setTest((t) => ({ ...t, [id]: `✗ ${e instanceof Error ? e.message : String(e)}` }));
    }
  };

  return (
    <div className="atmos-settings">
      <p className="atmos-ov__lede">
        {kis.filter((k) => k.bereit).length} von {kis.length} KIs bereit. Schlüssel bleiben auf diesem Gerät und gehen nur an den
        jeweiligen Anbieter. Fragen kosten beim Anbieter Geld.
      </p>

      <h3 className="atmos-ov__group-label">Denktiefe für alle KIs</h3>
      <div className="atmos-ki__effort" role="radiogroup" aria-label="Denktiefe">
        {MODELL_EFFORT.map((e) => (
          <button key={e} type="button" role="radio" aria-checked={state.modellEffort === e} data-active={state.modellEffort === e}
            onClick={() => run(`/effort ${e}`)}>
            <strong>{e}</strong>
            <span>{EFFORT_TEXT[e]}</span>
          </button>
        ))}
      </div>
      <p className="atmos-ki__hint">
        Übersetzt je Anbieter: Claude <code>output_config.effort</code> · OpenAI <code>reasoning_effort</code> · Gemini{" "}
        <code>thinkingBudget</code> · OpenRouter <code>reasoning.effort</code>. Router-Stufe {state.effort} ({EFFORT_LABELS[state.effort]}): ab 4
        plant bei /mach eine echte KI mit, bei 6 alle.
      </p>

      <h3 className="atmos-ov__group-label">Anbieter</h3>
      <ul className="atmos-ki__liste">
        {kis.map((k) => (
          <li key={k.id} className="atmos-ki__item" data-offen={offen === k.id}>
            <button type="button" className="atmos-ki__kopf" onClick={() => setOffen(offen === k.id ? null : k.id)} aria-expanded={offen === k.id}>
              <span className="atmos-ki__dot" data-bereit={k.bereit} aria-hidden />
              <span className="atmos-ki__name">
                <strong>{k.name}</strong>
                <span>{k.modell || "kein Modell"}{k.effort ? ` · Effort: ${k.effort}` : ""}</span>
              </span>
              {k.id === std && <span className="atmos-settings__pill atmos-settings__pill--connected">Standard</span>}
              <span className={`atmos-settings__pill atmos-settings__pill--${k.bereit ? "connected" : "missing"}`}>
                {k.bereit ? "bereit" : k.lokal ? "lokal · aus" : "Schlüssel fehlt"}
              </span>
            </button>
            {offen === k.id && (
              <div className="atmos-ki__form">
                {k.env !== "" && (
                  <label className="atmos-settings__field">
                    <span>API-Schlüssel {k.konsole && <a href={k.konsole} target="_blank" rel="noreferrer">holen ↗</a>}</span>
                    <input type={zeigeKey ? "text" : "password"} autoComplete="off" placeholder={k.schluessel ? "gespeichert – neu eingeben zum Ersetzen" : k.env}
                      defaultValue={s.ki?.[k.id]?.key ?? ""} onBlur={(e) => speichere(k.id, "key", e.target.value)} />
                  </label>
                )}
                <label className="atmos-settings__field">
                  <span>Modell</span>
                  <input defaultValue={s.ki?.[k.id]?.modell ?? ""} placeholder={k.modell || "Modellname"} onBlur={(e) => speichere(k.id, "modell", e.target.value)} />
                </label>
                {k.lokal && (
                  <>
                    <label className="atmos-settings__field">
                      <span>Adresse</span>
                      <input defaultValue={s.ki?.[k.id]?.basis ?? ""} placeholder={k.basis} onBlur={(e) => speichere(k.id, "basis", e.target.value)} />
                    </label>
                    <div className="atmos-settings__row">
                      <div>
                        <strong>Lokalen Dienst nutzen</strong>
                        <span>{k.hinweis}</span>
                      </div>
                      <button type="button" className="atmos-settings__toggle" data-on={Boolean(s.ki?.[k.id]?.aktiv)} aria-pressed={Boolean(s.ki?.[k.id]?.aktiv)}
                        aria-label={`${k.name} umschalten`} onClick={() => { setzeKi(k.id, { aktiv: !s.ki?.[k.id]?.aktiv }); setStand((x) => x + 1); }}>
                        <span className="atmos-settings__knob" />
                      </button>
                    </div>
                  </>
                )}
                <div className="atmos-ki__aktionen">
                  <button type="button" className="atmos-ov__pill" disabled={!k.bereit} onClick={() => void teste(k.id)}>Testen</button>
                  <button type="button" className="atmos-ov__pill" disabled={!k.bereit} onClick={() => run(`/modelle ${k.id}`)}>Modelle</button>
                  <button type="button" className="atmos-ov__pill" onClick={() => { saveSecrets({ standardKi: k.id }); setStand((x) => x + 1); }}>Als Standard</button>
                  {k.env !== "" && (
                    <button type="button" className="atmos-ov__pill-ghost" onClick={() => setZeigeKey((z) => !z)}>{zeigeKey ? "verbergen" : "Schlüssel zeigen"}</button>
                  )}
                </div>
                {test[k.id] && <p className="atmos-ki__test">{test[k.id]}</p>}
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
