import React, { useState } from "react";

// Uses Clearbit's public logo API (no key required) when a domain is known;
// falls back to a colored letter avatar for unknown companies or load failures.
export function Logo({ domain, letter, color, size = 48 }) {
  const [failed, setFailed] = useState(false);
  const showImage = domain && !failed;
  return (
    <div style={{ width: size, height: size, borderRadius: size * 0.29, background: `${color}22`, color, display: "flex", alignItems: "center", justifyContent: "center", fontSize: size * 0.42, fontWeight: 700, flexShrink: 0, overflow: "hidden" }}>
      {showImage ? (
        <img
          src={`https://logo.clearbit.com/${domain}?size=128`}
          alt=""
          width={size}
          height={size}
          style={{ objectFit: "contain", width: "100%", height: "100%" }}
          onError={() => setFailed(true)}
        />
      ) : (
        letter
      )}
    </div>
  );
}
