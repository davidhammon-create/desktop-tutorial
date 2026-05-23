
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
          const isSelected = selectedIdx
