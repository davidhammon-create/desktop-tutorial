import { h } from "../shared/dom.js";
import { T, S } from "../shared/tokens.js";
import { reveal } from "../shared/scrollReveal.js";
import { growthChart } from "../shared/growthChart.js";
import { animatedNumber } from "../shared/animatedNumber.js";
import { logo } from "../shared/logo.js";
import { fmt, futureValue } from "../shared/format.js";

const brandStrip = [
  { name: "Sparkasse", domain: "sparkasse.de", color: "#E30613", letter: "S" },
  { name: "PayPal", domain: "paypal.com", color: "#003087", letter: "P" },
  { name: "Klarna", domain: "klarna.com", color: "#FFB3C7", letter: "K" },
  { name: "Amex", domain: "americanexpress.com", color: "#006FCF", letter: "A" },
  { name: "Netflix", domain: "netflix.com", color: "#E50914", letter: "N" },
  { name: "Spotify", domain: "spotify.com", color: "#1DB954", letter: "S" },
  { name: "Vodafone", domain: "vodafone.de", color: "#E60000", letter: "V" },
  { name: "Amazon", domain: "amazon.de", color: "#FF9900", letter: "P" },
];

// Full-width band with alternating background, content centered at 980px.
function band(bg, ...children) {
  return h("section", { style: { background: bg } },
    h("div", { style: { maxWidth: 980, margin: "0 auto", padding: "0 22px" } }, ...children)
  );
}

export function landingPage({ onStart }) {
  const root = h("div", { style: { ...S.page, background: "#fff" } });

  // Slim translucent nav
  root.appendChild(
    h(
      "nav",
      { style: { position: "sticky", top: 0, zIndex: 10, backdropFilter: "saturate(180%) blur(20px)", background: "rgba(251,251,253,0.85)", borderBottom: "1px solid rgba(0,0,0,0.08)" } },
      h(
        "div",
        { style: { maxWidth: 980, margin: "0 auto", padding: "0 22px", display: "flex", justifyContent: "space-between", alignItems: "center", height: 48 } },
        h("div", { style: { fontWeight: 650, fontSize: 16, letterSpacing: "-0.01em" } }, "AboWandler"),
        h("button", { style: { ...S.btn, padding: "7px 16px", fontSize: 13 }, onClick: onStart }, "App starten")
      )
    )
  );

  // Hero — huge tight headline on white
  root.appendChild(
    band("#fff",
      h("div", { style: { textAlign: "center", padding: "96px 0 48px" } },
        reveal(h("div", { style: { fontSize: 17, fontWeight: 600, color: T.orange, marginBottom: 14 } }, "Neu: Algorithmus-Scan ganz ohne KI")),
        reveal(
          h("h1", { style: { fontSize: "clamp(44px, 8vw, 84px)", fontWeight: 600, letterSpacing: "-0.02em", lineHeight: 1.03, margin: "0 0 20px", color: T.text } },
            "Dein Netflix-Abo", h("br"), "wird zu Vermögen."
          ),
          { delay: 0.08 }
        ),
        reveal(
          h("p", { style: { fontSize: 21, color: T.textDim, maxWidth: 580, margin: "0 auto 32px", lineHeight: 1.45, fontWeight: 400 } },
            "Konten verbinden, wiederkehrende Zahlungen automatisch erkennen, Unnötiges kündigen — und denselben Betrag investieren. Lokal auf deinem Gerät."
          ),
          { delay: 0.16 }
        ),
        reveal(
          h("div", { style: { display: "flex", gap: 14, justifyContent: "center", flexWrap: "wrap" } },
            h("button", { style: { ...S.btn, padding: "13px 28px", fontSize: 16 }, onClick: onStart }, "Jetzt starten"),
            h("button", { style: { background: "none", border: "none", color: T.blue, fontSize: 16, cursor: "pointer", padding: "13px 10px" }, onClick: () => document.getElementById("how")?.scrollIntoView({ behavior: "smooth" }) }, "So funktioniert's ›")
          ),
          { delay: 0.24 }
        )
      )
    )
  );

  // Brand marquee
  root.appendChild(
    h("section", { style: { padding: "10px 0 64px", overflow: "hidden", background: "#fff" } },
      h(
        "div",
        { style: { display: "flex", width: "max-content", animation: "marquee 26s linear infinite", gap: 44, alignItems: "center" } },
        ...[...brandStrip, ...brandStrip].map((b) =>
          h("div", { style: { display: "flex", alignItems: "center", gap: 10, opacity: 0.8 } },
            logo({ domain: b.domain, letter: b.letter, color: b.color, size: 30 }),
            h("span", { style: { color: T.textDim, fontSize: 15, fontWeight: 500 } }, b.name)
          )
        )
      )
    )
  );

  // Stat band on soft gray
  const stats = [
    { value: 47, label: "Ø vergessenes Abo pro Monat", format: (v) => `${Math.round(v)} €` },
    { value: 1250000, label: "Möglicher Vermögensaufbau in 25 J.*", format: (v) => fmt(v) },
    { value: 10, label: "Erkennungs-Regeln im Algorithmus", format: (v) => `${Math.round(v)}+` },
  ];
  root.appendChild(
    band(T.bgAlt,
      h("div", { style: { padding: "64px 0" } },
        h(
          "div",
          { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 20 } },
          ...stats.map((s, i) =>
            reveal(
              h("div", { style: { textAlign: "center" } },
                h("div", { style: { fontSize: 44, fontWeight: 600, color: T.text, letterSpacing: "-0.02em" } }, animatedNumber(s.value, s.format)),
                h("div", { style: { fontSize: 14, color: T.textDim, marginTop: 6 } }, s.label)
              ),
              { delay: i * 0.1 }
            )
          )
        )
      )
    )
  );

  // Example projection card
  root.appendChild(
    band("#fff",
      h("div", { style: { padding: "72px 0" } },
        reveal(
          h("div", { style: { ...S.card, padding: 36, background: T.bgAlt } },
            h("div", { style: { display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 16, marginBottom: 20 } },
              h("div", {},
                h("div", { style: { fontSize: 14, color: T.textDim } }, "Beispiel: Adobe-Abo (59,99 €/Monat) → MSCI World, 25 Jahre"),
                h("div", { style: { fontSize: 34, fontWeight: 600, letterSpacing: "-0.02em" } }, `≈ ${fmt(futureValue(59.99, 7.1, 25))}`)
              ),
              h("div", { style: { textAlign: "right" } },
                h("div", { style: { fontSize: 14, color: T.textDim } }, "Möglicher Renten-Boost*"),
                h("div", { style: { fontSize: 26, fontWeight: 600, color: T.green } }, `+${fmt((futureValue(59.99, 7.1, 25) * 0.04) / 12)}/Monat`)
              )
            ),
            growthChart({ monthly: 59.99, ret: 7.1, years: 25 }),
            h("p", { style: { fontSize: 12, color: T.textFaint, marginTop: 14 } },
              "*Modellrechnung auf Basis historischer Durchschnittsrenditen. Keine Garantie, keine Anlageberatung. Vergangene Wertentwicklung ist kein Indikator für zukünftige Ergebnisse."
            )
          )
        )
      )
    )
  );

  // How it works — gray band
  const howSteps = [
    { icon: "🔗", t: "Konten verbinden", d: "Sparkasse, PayPal, Klarna, Amex und viele weitere — oder Umsätze einfach als Text/CSV importieren." },
    { icon: "◎", t: "Algorithmus erkennt alles", d: "Wiederholte IBANs, Namen und Betreffe, regelmäßige Intervalle und Beträge — rein algorithmisch, ohne KI, ohne Datenübertragung." },
    { icon: "↗", t: "Kündigen & investieren", d: "Unnötige Abos verwalten, pausieren oder kündigen — und denselben Betrag in ETFs, Aktien oder Anleihen umleiten." },
  ];
  root.appendChild(
    band(T.bgAlt,
      h("div", { id: "how", style: { padding: "72px 0" } },
        reveal(h("h2", { style: { fontSize: 44, fontWeight: 600, letterSpacing: "-0.02em", textAlign: "center", marginBottom: 8, marginTop: 0 } }, "Drei Schritte zur Klarheit.")),
        reveal(h("p", { style: { textAlign: "center", color: T.textDim, marginBottom: 48, fontSize: 17 } }, "Standardmäßig ohne KI — sie lässt sich zuschalten, wenn du mehr willst."), { delay: 0.08 }),
        h(
          "div",
          { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: 18 } },
          ...howSteps.map((f, i) =>
            reveal(
              h("div", { style: { background: "#fff", borderRadius: 18, padding: 28, height: "100%", boxSizing: "border-box" } },
                h("div", { style: { fontSize: 34, marginBottom: 14 } }, f.icon),
                h("h3", { style: { fontSize: 20, fontWeight: 600, margin: "0 0 8px", color: T.text } }, f.t),
                h("p", { style: { color: T.textDim, lineHeight: 1.5, margin: 0, fontSize: 15 } }, f.d)
              ),
              { delay: i * 0.1 }
            )
          )
        )
      )
    )
  );

  // Feature grid — white band
  const features = [
    ["◎ Algorithmus-Scan", "Erkennt wiederkehrende Zahlungen über wiederholte IBANs, Wörter, Bezeichnungen und Betreffe — komplett ohne KI."],
    ["📅 Zahlungsplan", "Nächste Abbuchungen, Monats- und Jahressummen, Kategorien-Auswertung. Zahlungen pausieren und verwalten."],
    ["✦ KI zuschaltbar", "Auf Wunsch recherchiert die KI Firmen & IBANs auf Seriosität, schreibt Kündigungsbriefe und analysiert Märkte."],
    ["↗ Investieren-Studio", "ETFs, Aktien, Anleihen, Rohstoffe und fertige Mixe — mit Rechner, Vergleich und Renten-Lücken-Rechner."],
    ["🧭 Finanz-Radar", "Alltags-Taktiken zu Krediten, Währungen, Immobilien, Steuern & Erben, Versicherungen."],
    ["👥 Profile & Admin", "Mehrere Nutzerprofile auf einem Gerät, Admin-Bereich für APIs, Rollen und Systemeinstellungen."],
    ["🔑 Zugangs-Tresor", "Zugangsdaten pro Abo verschlüsselt (AES-256) lokal gespeichert."],
    ["🏠 Lokal & privat", "Kein Cloud-Server: Dein PC ist der Host, erreichbar auch vom Handy im selben WLAN."],
  ];
  root.appendChild(
    band("#fff",
      h("div", { style: { padding: "72px 0" } },
        reveal(h("h2", { style: { fontSize: 44, fontWeight: 600, letterSpacing: "-0.02em", textAlign: "center", marginBottom: 8, marginTop: 0 } }, "Alles Finanzielle. Ein Ort.")),
        reveal(h("p", { style: { textAlign: "center", color: T.textDim, marginBottom: 48, fontSize: 17 } }, "Was AboWandler anders macht als klassische Finanz-Apps"), { delay: 0.08 }),
        h(
          "div",
          { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))", gap: 16 } },
          ...features.map(([t, d], i) =>
            reveal(
              h("div", { style: { ...S.card, padding: 22, height: "100%", boxSizing: "border-box" } },
                h("div", { style: { fontWeight: 600, marginBottom: 6, fontSize: 15.5 } }, t),
                h("div", { style: { color: T.textDim, fontSize: 13.5, lineHeight: 1.5 } }, d)
              ),
              { delay: (i % 4) * 0.07 }
            )
          )
        )
      )
    )
  );

  // Final CTA — dark band for contrast
  root.appendChild(
    h("section", { style: { background: "#1d1d1f" } },
      h("div", { style: { maxWidth: 980, margin: "0 auto", padding: "88px 22px", textAlign: "center" } },
        reveal(h("h2", { style: { fontSize: 40, fontWeight: 600, letterSpacing: "-0.02em", margin: "0 0 12px", color: "#f5f5f7" } }, "Bereit für den Abo-Check?")),
        reveal(h("p", { style: { color: "#a1a1a6", marginBottom: 30, fontSize: 17 } }, "Finde in 2 Minuten heraus, wo dein Geld wirklich hingeht."), { delay: 0.08 }),
        reveal(h("button", { style: { ...S.btn, padding: "13px 30px", fontSize: 16 }, onClick: onStart }, "Jetzt starten"), { delay: 0.16 }),
        h("p", { style: { fontSize: 12, color: "#6e6e73", margin: "44px auto 0", maxWidth: 640, lineHeight: 1.6 } },
          "AboWandler bietet keine Finanz- oder Anlageberatung. Alle Prognosen sind Modellrechnungen ohne Garantie. Investments bergen Verlustrisiken. Die Nutzung erfolgt auf eigenes Risiko."
        )
      )
    )
  );

  return root;
}
