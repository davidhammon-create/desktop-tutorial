import { h, svg, mount } from "../shared/dom.js";
import { T, S, statusCfg } from "../shared/tokens.js";
import { reveal } from "../shared/scrollReveal.js";
import { growthChart } from "../shared/growthChart.js";
import { fmt, futureValue, monthsSince } from "../shared/format.js";
import { api } from "../shared/api.js";

// 0-100 health score: rewards low suspicious share and reviewed subscriptions, penalizes stale unreviewed ones.
function healthScore(subs) {
  if (subs.length === 0) return 100;
  const warn = subs.filter((s) => s.status === "warning").length;
  const pendingOld = subs.filter((s) => s.status === "pending" && monthsSince(s.since) >= 24).length;
  const reviewed = subs.filter((s) => s.status === "keep" || s.status === "switch").length;
  let score = 100;
  score -= warn * 18;
  score -= pendingOld * 8;
  score += Math.min(10, reviewed * 1.5);
  return Math.max(0, Math.min(100, Math.round(score)));
}

export function dashboardPage({ subs: initialSubs, onFilterWarning, onRefresh }) {
  let subs = initialSubs;

  const autoCheckBtn = h("button", { style: S.btn }, "✦ KI-Auto-Check starten");
  const resultSlot = h("div", {});
  const el = h("div", {});

  autoCheckBtn.addEventListener("click", async () => {
    autoCheckBtn.disabled = true;
    autoCheckBtn.style.opacity = "0.6";
    autoCheckBtn.textContent = "⏳ Prüft alle Abos…";
    mount(resultSlot);
    try {
      const res = await api.ai.autoClassify();
      renderResult(res);
      onRefresh?.();
    } catch (e) {
      renderResult({ summary: e.message, engine: "fehler", results: [] });
    }
    autoCheckBtn.disabled = false;
    autoCheckBtn.style.opacity = "1";
    autoCheckBtn.textContent = "✦ KI-Auto-Check starten";
  });

  function renderResult(checkResult) {
    const badgeColor = checkResult.engine === "ki" ? T.purple : T.teal;
    const title =
      checkResult.engine === "ki" ? "✦ KI-Analyse abgeschlossen" :
      checkResult.engine === "basis" ? "🛡 Basis-Check abgeschlossen" : "Fehler";
    const tags = (checkResult.results || [])
      .map((r) => {
        const sub = subs.find((s) => s.id === r.id);
        const cfg = statusCfg[r.status];
        if (!cfg) return null;
        const tag = h("span", { style: S.tag(cfg.color), title: r.reason }, `${cfg.icon} ${sub?.name || `#${r.id}`}`);
        return tag;
      })
      .filter(Boolean);

    mount(
      resultSlot,
      reveal(
        h("div", { style: { ...S.card, marginBottom: 32, borderColor: checkResult.engine === "ki" ? "rgba(191,90,242,0.35)" : "rgba(100,210,255,0.3)" } },
          h("div", { style: { fontWeight: 650, marginBottom: 8, color: badgeColor } }, title),
          h("p", { style: { fontSize: 14, color: T.textDim, margin: "0 0 12px", lineHeight: 1.5 } }, checkResult.summary),
          tags.length > 0 ? h("div", { style: { display: "flex", gap: 8, flexWrap: "wrap" } }, ...tags) : null
        )
      )
    );
  }

  function renderBody() {
  const switchedSum = subs.filter((s) => s.status === "switch").reduce((a, s) => a + s.amount, 0);
  const totalMonthly = subs.reduce((a, s) => a + s.amount, 0);
  const warnings = subs.filter((s) => s.status === "warning");
  const score = healthScore(subs);
  const scoreColor = score >= 75 ? T.green : score >= 45 ? T.orange : T.red;

  const statCards = [
    ["Monatliche Abo-Kosten", fmt(totalMonthly), T.text],
    ["Umwandlungs-Potenzial", fmt(switchedSum) + "/Monat", T.green],
    ["Warnungen", warnings.length + " verdächtige Zahlung" + (warnings.length !== 1 ? "en" : ""), T.red],
    ["In 25 J. (bei 7,1% p.a.)", "≈ " + fmt(futureValue(switchedSum, 7.1, 25)), T.teal],
  ];

  const circumference = 2 * Math.PI * 40;
  const scoreCircle = svg("circle", {
    cx: "46", cy: "46", r: "40", fill: "none", stroke: scoreColor, "stroke-width": "8", "stroke-linecap": "round",
    "stroke-dasharray": String(circumference), "stroke-dashoffset": String(circumference * (1 - score / 100)),
    transform: "rotate(-90 46 46)", style: { transition: "stroke-dashoffset 1.2s cubic-bezier(0.16,1,0.3,1)" },
  });
  const scoreSvg = svg("svg", { width: "92", height: "92", viewBox: "0 0 92 92" });
  scoreSvg.append(
    svg("circle", { cx: "46", cy: "46", r: "40", fill: "none", stroke: T.border, "stroke-width": "8" }),
    scoreCircle
  );

  const root = h(
    "div",
    {},
    h("div", { style: { display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: 12 } },
      h("div", {},
        reveal(h("h1", { style: { fontSize: 34, fontWeight: 700, letterSpacing: "-1px", margin: "0 0 6px" } }, "Deine Finanz-Übersicht")),
        reveal(h("p", { style: { color: T.textDim, margin: "0 0 32px" } }, `${subs.length} erkannte wiederkehrende Zahlungen`), { delay: 0.05 })
      ),
      reveal(autoCheckBtn, { delay: 0.1 })
    ),
    resultSlot,
    h("div", { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(230px, 1fr))", gap: 16, marginBottom: 32 } },
      ...statCards.map(([l, v, c], i) =>
        reveal(
          h("div", { style: S.card },
            h("div", { style: { fontSize: 13, color: T.textDim, marginBottom: 8 } }, l),
            h("div", { style: { fontSize: 24, fontWeight: 700, color: c, letterSpacing: "-0.5px" } }, v)
          ),
          { delay: i * 0.08 }
        )
      )
    ),
    reveal(
      h("div", { style: { ...S.card, marginBottom: 32, display: "flex", alignItems: "center", gap: 24, flexWrap: "wrap" } },
        h("div", { style: { position: "relative", width: 92, height: 92, flexShrink: 0 } },
          scoreSvg,
          h("div", { style: { position: "absolute", inset: "0", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22, fontWeight: 700, color: scoreColor } }, String(score))
        ),
        h("div", {},
          h("div", { style: { fontWeight: 650, fontSize: 16 } }, "Abo-Gesundheits-Score"),
          h("div", { style: { fontSize: 13.5, color: T.textDim, marginTop: 4, maxWidth: "480px" } },
            score >= 75 ? "Sehr gut — deine Abos sind größtenteils überprüft und unbedenklich." :
            score >= 45 ? "Mittel — einige Abos sollten noch geprüft werden." :
            "Achtung — mehrere verdächtige oder lange unüberprüfte Abos."
          )
        )
      )
    ),
    warnings.length > 0
      ? reveal(
          h("div", { style: { ...S.card, borderColor: "rgba(255,69,58,0.35)", background: "rgba(255,69,58,0.06)", marginBottom: 32 } },
            h("div", { style: { fontWeight: 650, color: T.red, marginBottom: 12 } }, "⚠ Verdächtige Abbuchungen erkannt"),
            ...warnings.map((w) =>
              h("div", { style: { display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderTop: `1px solid ${T.border}`, gap: 12, flexWrap: "wrap" } },
                h("div", {},
                  h("div", { style: { fontWeight: 600 } }, `${w.name} · ${fmt(w.amount)}`),
                  h("div", { style: { fontSize: 13, color: T.textDim } }, w.note)
                ),
                h("button", { style: { ...S.btnGhost, padding: "8px 16px", fontSize: 13, borderColor: T.red, color: T.red }, onClick: onFilterWarning }, "Prüfen →")
              )
            )
          )
        )
      : null,
    reveal(
      h("div", { style: { ...S.card, padding: 32 } },
        h("div", { style: { display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 12, marginBottom: 16 } },
          h("div", {},
            h("div", { style: { fontSize: 14, color: T.textDim } },
              `Wenn du deine ${subs.filter((s) => s.status === "switch").length} markierten Abos umwandelst (${fmt(switchedSum)}/Monat, MSCI World, 25 Jahre)`
            ),
            h("div", { style: { fontSize: 30, fontWeight: 700, letterSpacing: "-0.5px" } }, `≈ ${fmt(futureValue(switchedSum, 7.1, 25))} Vermögen`)
          ),
          h("div", { style: { ...S.tag(T.green), alignSelf: "center", fontSize: 14 } }, `+${fmt((futureValue(switchedSum, 7.1, 25) * 0.04) / 12)}/Monat Renten-Boost*`)
        ),
        growthChart({ monthly: switchedSum || 1, ret: 7.1, years: 25 })
      )
    )
  );

  return root;
  }

  mount(el, renderBody());

  return {
    el,
    update({ subs: newSubs } = {}) {
      if (newSubs) subs = newSubs;
      mount(el, renderBody());
    },
  };
}
