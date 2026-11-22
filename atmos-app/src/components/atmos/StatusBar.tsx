import { EFFORT_LABELS } from "@/atmos/constants";
import { useAtmos } from "@/atmos/provider";
export function StatusBar() {
  const { state } = useAtmos();
  const ampelColor =
    state.ampel === "gruen" ? "var(--atmos-ok)" : state.ampel === "gelb" ? "var(--atmos-warn)" : "var(--atmos-danger)";
  return (
    <footer className="atmos-statusbar">
      <div className="atmos-statusbar__cluster">
        <span className="atmos-pill" data-tone={state.modus}>
          Puls {state.puls}
        </span>
        <span className="atmos-muted">Modus {state.modus}</span>
      </div>
      <div className="atmos-statusbar__cluster">
        <span className="atmos-muted">Stufe</span>
        <strong>
          {state.effort} ? {EFFORT_LABELS[state.effort]}
        </strong>
      </div>
      <div className="atmos-statusbar__cluster">
        <span className="atmos-dot" style={{ background: ampelColor }} />
        <span>
          Ampel {state.ampel} ? {state.kostenCent.toFixed(1)}? / {state.budgetCent}?
        </span>
      </div>
      <div className="atmos-statusbar__cluster">
        <span className="atmos-muted">Siegel</span>
        <span>{state.siegel}</span>
      </div>
      <div className="atmos-statusbar__cluster">
        {state.stop ? (
          <span className="atmos-pill" data-tone="stop">
            STOP AN
          </span>
        ) : (
          <span className="atmos-muted">STOP aus</span>
        )}
      </div>
    </footer>
  );
}
