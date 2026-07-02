export const T = {
  bg: "#050508",
  bgCard: "rgba(255,255,255,0.04)",
  bgCardHover: "rgba(255,255,255,0.07)",
  border: "rgba(255,255,255,0.08)",
  text: "#F5F5F7",
  textDim: "#A1A1A6",
  textFaint: "#6E6E73",
  green: "#30D158",
  teal: "#64D2FF",
  purple: "#BF5AF2",
  orange: "#FF9F0A",
  red: "#FF453A",
  blue: "#0A84FF",
};

export const statusCfg = {
  pending: { label: "Ausstehender Check", color: T.orange, icon: "◷" },
  warning: { label: "Warnung / Risiko", color: T.red, icon: "⚠" },
  keep: { label: "Behalten", color: T.blue, icon: "✓" },
  switch: { label: "In ETF umwandeln", color: T.green, icon: "↗" },
};

export const S = {
  page: { minHeight: "100vh", background: T.bg, color: T.text, fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Roboto, sans-serif", position: "relative", overflowX: "hidden" },
  container: { maxWidth: 1100, margin: "0 auto", padding: "0 24px", position: "relative", zIndex: 1 },
  card: { background: T.bgCard, border: `1px solid ${T.border}`, borderRadius: 20, padding: 24, backdropFilter: "blur(20px)" },
  btn: { background: T.text, color: T.bg, border: "none", borderRadius: 999, padding: "14px 28px", fontSize: 16, fontWeight: 600, cursor: "pointer", transition: "transform 0.2s, opacity 0.2s" },
  btnGhost: { background: "transparent", color: T.text, border: `1px solid ${T.border}`, borderRadius: 999, padding: "13px 26px", fontSize: 16, fontWeight: 500, cursor: "pointer" },
  input: { background: "rgba(255,255,255,0.06)", border: `1px solid ${T.border}`, borderRadius: 12, padding: "12px 16px", color: T.text, fontSize: 15, outline: "none", width: "100%", boxSizing: "border-box" },
  tag: (c) => ({ display: "inline-flex", alignItems: "center", gap: 6, background: `${c}22`, color: c, borderRadius: 999, padding: "5px 12px", fontSize: 12.5, fontWeight: 600 }),
};
