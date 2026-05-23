
/**
 * SubTabBar.jsx — Wiederverwendbare Sub-Tab-Navigation
 *
 * Zwei Ebenen:
 *   level="primary"   → Haupt-Unterreiter (größer, mit farbiger Unterstreichung)
 *   level="secondary" → Unter-Unterreiter (kompakter, Pill-Stil)
 */

export default function SubTabBar({ tabs, active, onChange, level = "primary" }) {
  if (level === "secondary") {
    return (
      <div className="flex flex-wrap gap-1.5 px-1 py-1 bg-gray-50 border border-gray-100 rounded-xl">
        {tabs.map((label, i) => (
          <button
            key={i}
            onClick={() => onChange(i)}
            className="no-override whitespace-nowrap transition-all"
            style={{
              padding: "4px 12px",
              fontSize: 11,
              fontWeight: active
