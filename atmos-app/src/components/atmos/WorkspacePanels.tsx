import { GESETZE, KRISTALL_ARTEN, VERFASSUNG, ZYKLUS } from "@/atmos/constants";
import { useAtmos, type AtmosPanel } from "@/atmos/provider";
import { CascadeMeter } from "./CascadeMeter";
export function WorkspacePanels() {
  const { panel, setPanel, state, lastResult, run } = useAtmos();
  return (
    <section className="atmos-work">
      <nav className="atmos-tabs" aria-label="Arbeitsfläche">
        {(
          [
            ["arbeit", "Arbeitsgang"],
            ["module", "Module"],
            ["kristalle", "Kristalle"],
            ["verfassung", "Verfassung"],
            ["status", "Vital"],
          ] as [AtmosPanel, string][]
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            className="atmos-tabs__btn"
            data-active={panel === id}
            onClick={() => setPanel(id)}
          >
            {label}
          </button>
        ))}
      </nav>
      <div className="atmos-work__body">
        {panel === "arbeit" && <ArbeitPanel />}
        {panel === "module" && <ModulePanel />}
        {panel === "kristalle" && <KristallPanel />}
        {panel === "verfassung" && <VerfassungPanel />}
        {panel === "status" && <VitalPanel />}
      </div>
      {lastResult && (
        <aside className="atmos-result" data-ok={lastResult.ok}>
          <pre>{lastResult.message}</pre>
          <div className="atmos-result__quick">
            <button type="button" onClick={() => run("/hilfe")}>
              /hilfe
            </button>
            <button type="button" onClick={() => run("/vital")}>
              /vital
            </button>
            <button type="button" onClick={() => run(state.stop ? "/fortsetzen" : "/stop")}>
              {state.stop ? "/fortsetzen" : "/stop"}
            </button>
          </div>
        </aside>
      )}
    </section>
  );
}
function ArbeitPanel() {
  const { state, run } = useAtmos();
  const lauf = state.laeufe[0];
  return (
    <div className="atmos-panel-grid">
      <div>
        <h3>12-Schritte-Zyklus</h3>
        <ol className="atmos-zyklus">
          {ZYKLUS.map((z) => {
            const active = lauf ? Math.min(12, lauf.schritt + 1) === z.nr : false;
            const done = lauf ? lauf.schritt >= z.nr : false;
            return (
              <li key={z.nr} data-active={active} data-done={done}>
                <strong>
                  {z.nr}. {z.name}
                </strong>
                <span>{z.kurz}</span>
              </li>
            );
          })}
        </ol>
      </div>
      <div>
        <div className="atmos-row-between">
          <h3>Aktiver Lauf</h3>
          <button type="button" className="atmos-btn atmos-btn--ghost" onClick={() => run("/mach Dokumente erschließen")}>
            Demo-Lauf
          </button>
        </div>
        {!lauf ? (
          <p className="atmos-muted">Noch kein Lauf. Tippe einen Auftrag oder /mach ?</p>
        ) : (
          <div className="atmos-lauf">
            <header>
              <strong>{lauf.titel}</strong>
              <span className="atmos-pill" data-tone={lauf.stand}>
                {lauf.stand}
              </span>
            </header>
            <p className="atmos-muted">{lauf.ziel}</p>
            <ul className="atmos-lauf__steps">
              {lauf.schritte.map((s, i) => (
                <li key={`${s.titel}-${i}`} data-state={i < lauf.schritt ? "done" : i === lauf.schritt ? "now" : "todo"}>
                  <span>{i + 1}.</span> {s.titel} <em>[{s.art}]</em>
                </li>
              ))}
            </ul>
          </div>
        )}
        <h3 className="atmos-mt">Spur</h3>
        <ul className="atmos-trace">
          {state.trace.slice(0, 10).map((t) => (
            <li key={t.id}>
              <time>{new Date(t.zeit).toLocaleTimeString()}</time>
              <span className="atmos-trace__art">{t.art}</span>
              <span>{t.text}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
function ModulePanel() {
  const { state, run } = useAtmos();
  return (
    <div>
      <div className="atmos-row-between">
        <div>
          <h3>Modul-Dock</h3>
          <p className="atmos-muted">GitHub-Projekte als Daten einbetten ? Ausführung nur nach Freigabe.</p>
        </div>
        <button type="button" className="atmos-btn atmos-btn--ghost" onClick={() => run("/suche pdf extraction")}>
          /suche
        </button>
      </div>
      <div className="atmos-module-list">
        {state.module.map((m) => (
          <article key={m.id} className="atmos-module">
            <header>
              <strong>{m.name}</strong>
              <span className="atmos-pill" data-tone={m.status}>
                {m.status.toUpperCase()}
              </span>
            </header>
            <p>{m.zweck}</p>
            <footer>
              <span>Score {m.score}</span>
              <span>{m.lizenz}</span>
              <span>Vital {m.vital}</span>
              <span>? {m.sterne.toLocaleString()}</span>
            </footer>
            <div className="atmos-module__actions">
              {m.status === "an" ? (
                <button type="button" onClick={() => run(`/aus ${m.name}`)}>
                  Ausschalten
                </button>
              ) : (
                <button type="button" onClick={() => run(`/an ${m.name}`)}>
                  Einschalten
                </button>
              )}
              <a href={m.url} target="_blank" rel="noreferrer">
                GitHub
              </a>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}
function KristallPanel() {
  const { state } = useAtmos();
  return (
    <div>
      <h3>Kristall-Regal</h3>
      <p className="atmos-muted">Was ohne Credits läuft ? nur Geprüftes wird fest.</p>
      <div className="atmos-kristall-list">
        {state.kristalle.map((k) => (
          <article key={k.id} className="atmos-kristall" data-status={k.status}>
            <span className="atmos-kristall__art">
              {k.art} ? {KRISTALL_ARTEN[k.art]}
            </span>
            <strong>{k.titel}</strong>
            <p>{k.inhalt}</p>
            <footer>
              <span>{k.status}</span>
              <span>{k.treffer} Treffer</span>
            </footer>
          </article>
        ))}
      </div>
    </div>
  );
}
function VerfassungPanel() {
  return (
    <div className="atmos-panel-grid">
      <div>
        <h3>9 Gesetze</h3>
        <ol className="atmos-gesetze">
          {GESETZE.map((g) => (
            <li key={g.nr}>
              <strong>
                {g.nr}. {g.titel}
              </strong>
              <span>{g.text}</span>
            </li>
          ))}
        </ol>
      </div>
      <div>
        <h3>Verfassung R1?R10</h3>
        <ul className="atmos-regeln">
          {VERFASSUNG.map((r) => (
            <li key={r.id}>
              <strong>
                {r.id} {r.titel}
              </strong>
              <span>{r.text}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
function VitalPanel() {
  const { state, resetDemo } = useAtmos();
  return (
    <div className="atmos-panel-grid">
      <div>
        <h3>Vitalität</h3>
        <CascadeMeter />
        <dl className="atmos-dl">
          <div>
            <dt>Puls</dt>
            <dd>{state.puls}</dd>
          </div>
          <div>
            <dt>Modus</dt>
            <dd>{state.modus}</dd>
          </div>
          <div>
            <dt>Ampel</dt>
            <dd>{state.ampel}</dd>
          </div>
          <div>
            <dt>Kosten</dt>
            <dd>
              {state.kostenCent.toFixed(1)}? / {state.budgetCent}?
            </dd>
          </div>
        </dl>
        <h4>Hunger</h4>
        <ul className="atmos-hunger">
          {state.hunger.map((h) => (
            <li key={h.problemtyp}>
              {h.problemtyp} <em>?{h.ungeloest}</em>
            </li>
          ))}
        </ul>
        <button type="button" className="atmos-btn atmos-btn--ghost atmos-mt" onClick={resetDemo}>
          Demo zurücksetzen
        </button>
      </div>
      <div>
        <h3>Freigaben</h3>
        {state.freigaben.length === 0 ? (
          <p className="atmos-muted">Keine offenen Freigaben.</p>
        ) : (
          <ul className="atmos-regeln">
            {state.freigaben.map((f) => (
              <li key={f.id}>
                <strong>{f.titel}</strong>
                <span>{f.beschreibung}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
