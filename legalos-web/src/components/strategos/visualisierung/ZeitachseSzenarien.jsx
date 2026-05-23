
/**
 * FORMAT 03 — Zeitachse mit Eintrittsszenarien
 * Zeigt wann mit welcher Wahrscheinlichkeit welche Wirkung eintreten kann.
 */
export default function ZeitachseSzenarien({ klausel }) {
  if (!klausel?.szenarien?.length) return null;

  const HORIZONT_POS = { kurzfristig: 20, mittelfristig: 50, langfristig: 80 };
  const HORIZONT_LABEL = { kurzfristig: "+6 Mon.", mittelfristig: "+24 Mon.", langfristig: "+48 Mon." };
  const HORIZONT_COLOR = { kurzfristig: "#FF9500", mittelfristig: "#B81C3A", langfristig: "#0A84FF" };

  // Milestones: HEUTE + Szenarien
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
            const top = i % 2
