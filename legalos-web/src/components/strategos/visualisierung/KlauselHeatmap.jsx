
/**
 * FORMAT 01 — Klausel-Risiko-Heatmap
 * Einstiegsansicht — alle Klauseln nach Risikostufe sortiert, als horizontale Balken.
 */
export default function KlauselHeatmap({ klauseln, onSelect, selectedIdx }) {
  if (!klauseln?.length) return null;

  const RISIKO_ORDER = ["kritisch", "hoch", "mittel", "niedrig", "positiv"];
  const RISIKO_COLOR = {
    kritisch: "#B81C3A",
    hoch:     "#FF9500",
    mittel:   "#0A84FF",
    niedrig:  "#1DB954",
    positiv:  "#1DB954",
  };
  const RISIKO_SCORE = { kritisch: 9, hoch: 7.5, mittel: 5.5, niedrig: 3, positiv: 2 };
  const LABEL = { kritisch: "KRITISCH", hoch: "HOCH", mittel: "MITTEL", niedrig: "NIEDRIG", positiv: "NIEDRIG" };

  const sorted = [...klauseln].sort((a, b) =>
    RISIKO_ORDER.indexOf(a.risiko_stufe) - RISIKO_ORDER.indexOf(b.risiko_stufe)
  );

  return (
    <div style={{ background: "#fff", border: "1px solid rgba(0,0,0,0.09)", borderRadius: 14, overflow: "hidden" }}>
      <div style={{ padding: "10px 14px 8px", borderBottom: "1px solid rgba(0,0,0,0.06)" }}>
        <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", letterSpacing: "0.1em" }}>FORMAT 01 · Klausel-Risiko-Heatmap</p>
        <p style={{ fontSize: 11, color: "#aaa", marginTop: 2 }}>Alle Klauseln nach Risikostufe — klicken für Detailansicht</p>
      </div>
      <div style={{ padding: "8px 14px 12px" }}>
        {sorted.map((k, i) => {
          const color = RISIKO_COLOR[k.risiko_stufe] || "#0A84FF";
          const score = RISIKO_SCORE[k.risiko_stufe] || 5;
          const isSelected = selectedIdx === i;
          return (
            <div
              key={i}
              onClick={() => onSelect?.(i)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                padding: "8px 10px",
                borderRadius: 9,
                marginBottom: 5,
                cursor: "pointer",
                background: isSelected ? `${color}10` : "rgba(0,0,0,0.015)",
                border: `1px solid ${isSelected ? color + "50" : "transparent"}`,
                transition: "all 0.15s",
              }}
            >
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: color, flexShrink: 0, boxShadow: `0 0 0 3px ${color}25` }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ fontSize: 11, fontWeight: 600, color: "#1a1a1a", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {k.klausel_typ || `Klausel ${i + 1}`}
                </p>
                <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 3 }}>
                  <div style={{ height: 4, background: "rgba(0,0,0,0.06)", borderRadius: 2, flex: 1, overflow: "hidden" }}>
                    <div style={{ height: "100%", width: `${(score / 10) * 100}%`, background: color, borderRadius: 2 }} />
                  </div>
                  <span style={{ fontSize: 9, fontWeight: 700, color, textTransform: "uppercase", letterSpacing: "0.05em" }}>{LABEL[k.risiko_stufe] || "—"}</span>
                  <span style={{ fontSize: 9, color: "#aaa" }}>{score}/10</span>
                </div>
              </div>
              {k.norm && <span style={{ fontSize: 9, fontFamily: "monospace", color: "#999", flexShrink: 0 }}>{k.norm}</span>}
            </div>
          );
        })}
      </div>
    </div>
  );
}
