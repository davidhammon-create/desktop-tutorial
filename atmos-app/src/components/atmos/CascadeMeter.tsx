import { ROUTER_STUFEN } from "@/atmos/constants";
import { useAtmos } from "@/atmos/provider";
export function CascadeMeter() {
  const { state } = useAtmos();
  const total = Object.values(state.cascade.counts).reduce((a, b) => a + b, 0) || 1;
  return (
    <div className="atmos-cascade" aria-label="Router-Kaskade">
      <div className="atmos-cascade__label">
        <span>Kaskade 0?6</span>
        <span className="atmos-muted">billig ? teuer</span>
      </div>
      <div className="atmos-cascade__bars">
        {ROUTER_STUFEN.map((s) => {
          const n = state.cascade.counts[s.stufe] ?? 0;
          const pct = Math.max(4, (n / total) * 100);
          const active = state.effort >= s.stufe;
          return (
            <div key={s.stufe} className="atmos-cascade__col" title={`${s.name}: ${n}`}>
              <div
                className="atmos-cascade__bar"
                style={{ height: `${pct}%` }}
                data-active={active}
                data-stufe={s.stufe}
              />
              <span>{s.stufe}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
