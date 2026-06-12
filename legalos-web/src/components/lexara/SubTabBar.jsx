
/**
 * SubTabBar.jsx — Wiederverwendbare Sub-Tab-Navigation
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
              fontWeight: active === i ? 700 : 500,
              color: active === i ? "#007AFF" : "#666",
              background: active === i ? "#fff" : "transparent",
              border: active === i ? "1px solid rgba(0,122,255,0.2)" : "1px solid transparent",
              borderRadius: 8,
              cursor: "pointer",
            }}>
            {label}
          </button>
        ))}
      </div>
    );
  }

  return (
    <div className="flex gap-0 border-b border-gray-100 overflow-x-auto">
      {tabs.map((label, i) => (
        <button
          key={i}
          onClick={() => onChange(i)}
          className="whitespace-nowrap px-4 py-2.5 text-sm font-medium border-b-2 transition-all"
          style={{
            borderBottomColor: active === i ? "#007AFF" : "transparent",
            color: active === i ? "#007AFF" : "#888",
            background: "transparent",
            cursor: "pointer",
          }}>
          {label}
        </button>
      ))}
    </div>
  );
}
