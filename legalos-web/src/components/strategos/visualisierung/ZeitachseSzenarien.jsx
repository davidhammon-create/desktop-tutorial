
/**
 * FORMAT 03 — Zeitachse mit Eintrittsszenarien
 */
export default function ZeitachseSzenarien({ klausel }) {
  if (!klausel?.szenarien?.length) return null;

  const HORIZONT_POS = { kurzfristig: 20, mittelfristig: 50, langfristig: 80 };
  const HORIZONT_LABEL = { kurzfristig: "+6 Mon.", mittelfristig: "+24 Mon.", langfristig: "+48 Mon." };
  const HORIZONT_COLOR = { kurzfristig: "#FF9500", mittelfristig: "#B81C3A", langfristig: "#0A84FF" };

  const milestones = [0, 20, 50, 80, 100];
  const labels = ["HEUTE", "+6 Mon.", "+24 Mon.", "+48 Mon.", "+60 Mon."];

  const szenarien = klausel.szenarien.filter(s => HORIZONT_POS[s.horizont]);

  return (
    <div style={{ background: "#fff", border: "1px solid rgba(0,0,0,0.09)", borderRadius: 14, overflow: "hidden" }}>
      <div style={{ padding: "10px 14px 8px", borderBottom: "1px solid rgba(0,0,0,0.06)" }}>
        <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", letterSpacing: "0.1em" }}>FORMAT 03 · Zeitachse mit Eintrittsszenarien</p>
        <p style={{ fontSize: 11, color: "#aaa", marginTop: 2 }}>
          {klausel.klausel_typ} — Wann wird diese Klausel scharf?
        </p>
      </div>

      <div style={{ padding: "24px 20px 20px" }}>
        {/* Szenarien-Bubbles über der Zeitachse */}
        <div style={{ position: "relative", height: 120, marginBottom: 8 }}>
          {szenarien.map((s, i) => {
            const pos = HORIZONT_POS[s.horizont] || 50;
            const color = HORIZONT_COLOR[s.horizont] || "#0A84FF";
            const top = i % 2 === 0 ? 0 : 50;
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: `${pos}%`,
                  top: top,
                  transform: "translateX(-50%)",
                  maxWidth: 140,
                  background: `${color}12`,
                  border: `1px solid ${color}40`,
                  borderRadius: 9,
                  padding: "5px 8px",
                }}
              >
                <p style={{ fontSize: 9, fontWeight: 700, color, textTransform: "uppercase", marginBottom: 2 }}>{HORIZONT_LABEL[s.horizont]}</p>
                <p style={{ fontSize: 10, color: "#333", lineHeight: 1.3 }}>{s.beschreibung?.slice(0, 60)}{s.beschreibung?.length > 60 ? "…" : ""}</p>
              </div>
            );
          })}
        </div>

        {/* Timeline bar */}
        <div style={{ position: "relative", height: 4, background: "rgba(0,0,0,0.06)", borderRadius: 2, margin: "8px 0 16px" }}>
          {milestones.map((pos, i) => (
            <div key={i} style={{ position: "absolute", left: `${pos}%`, transform: "translateX(-50%)", top: -3 }}>
              <div style={{ width: 10, height: 10, borderRadius: "50%", background: "#ddd", border: "2px solid #fff", boxShadow: "0 0 0 1px rgba(0,0,0,0.08)" }} />
              <p style={{ fontSize: 8, color: "#aaa", marginTop: 8, whiteSpace: "nowrap", transform: "translateX(-50%)", textAlign: "center", textTransform: "uppercase" }}>{labels[i]}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Szenario-Details */}
      <div style={{ borderTop: "1px solid rgba(0,0,0,0.06)", padding: "10px 14px 12px" }}>
        {szenarien.map((s, i) => (
          <div key={i} style={{ display: "flex", gap: 8, padding: "6px 0", borderBottom: i < szenarien.length - 1 ? "1px solid rgba(0,0,0,0.04)" : "none" }}>
            <div style={{ width: 6, height: 6, borderRadius: "50%", background: HORIZONT_COLOR[s.horizont] || "#0A84FF", flexShrink: 0, marginTop: 4 }} />
            <div>
              <p style={{ fontSize: 10, fontWeight: 700, color: HORIZONT_COLOR[s.horizont] || "#0A84FF", textTransform: "uppercase", marginBottom: 2 }}>{s.horizont}</p>
              <p style={{ fontSize: 11, color: "#333", lineHeight: 1.4 }}>{s.beschreibung}</p>
              {s.eintrittsbedingung && <p style={{ fontSize: 10, color: "#888", marginTop: 2 }}>Wenn: {s.eintrittsbedingung}</p>}
              {s.empfohlene_reaktion && <p style={{ fontSize: 10, color: "#1DB954", marginTop: 2 }}>→ {s.empfohlene_reaktion}</p>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
