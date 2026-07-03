import { h, mount } from "../shared/dom.js";
import { T, S } from "../shared/tokens.js";
import { fmt, futureValue } from "../shared/format.js";
import { growthChart, compareChart } from "../shared/growthChart.js";
import { api } from "../shared/api.js";

const requiredMonthly = (targetFv, annualPct, years) => {
  const r = annualPct / 100 / 12;
  const n = years * 12;
  if (r === 0) return targetFv / n;
  return targetFv / ((Math.pow(1 + r, n) - 1) / r);
};

export function etfExplorerPage({ subs, switchedSum }) {
  let allEtfs = [];
  let etfs = [];
  const calc = { monthly: 59.99, etfId: null, years: 10 };
  let compareIds = [];
  let pensionGoal = 200;
  let gapEtfId = null;
  let gapYears = 20;

  const bestCardsSlot = h("div", {});
  const etfListSlot = h("div", { style: { display: "grid", gap: 8 } });
  const resultsSlot = h("div", {});
  const compareSlot = h("div", {});
  const gapSelect = h("select", { style: { ...S.input, marginTop: 16, maxWidth: 320 } });
  const gapResultSlot = h("div", {});
  const quickAmountRow = h("div", { style: { display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap" } });

  function renderBestCards() {
    if (allEtfs.length === 0) { mount(bestCardsSlot); return; }
    const bestReturn = allEtfs.reduce((a, b) => (b.ret > (a?.ret ?? -Infinity) ? b : a), null);
    const safest = allEtfs.reduce((a, b) => (b.riskScore < (a?.riskScore ?? Infinity) ? b : a), null);
    const cheapest = allEtfs.reduce((a, b) => (b.ter < (a?.ter ?? Infinity) ? b : a), null);
    mount(
      bestCardsSlot,
      h(
        "div",
        { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 12, marginBottom: 24 } },
        h("div", { style: { ...S.card, padding: 16 } },
          h("div", { style: { fontSize: 12, color: T.textDim } }, "Höchste Rendite (hist.)"),
          h("div", { style: { fontWeight: 650, marginTop: 4 } }, bestReturn.name),
          h("div", { style: { color: T.green, fontWeight: 700 } }, `${bestReturn.ret}% p.a.*`)
        ),
        h("div", { style: { ...S.card, padding: 16 } },
          h("div", { style: { fontSize: 12, color: T.textDim } }, "Sicherster"),
          h("div", { style: { fontWeight: 650, marginTop: 4 } }, safest.name),
          h("div", { style: { color: T.teal, fontWeight: 700 } }, `Risiko: ${safest.risk}`)
        ),
        h("div", { style: { ...S.card, padding: 16 } },
          h("div", { style: { fontSize: 12, color: T.textDim } }, "Günstigste TER"),
          h("div", { style: { fontWeight: 650, marginTop: 4 } }, cheapest.name),
          h("div", { style: { color: T.purple, fontWeight: 700 } }, `${cheapest.ter}%`)
        )
      )
    );
  }

  function renderQuickAmounts() {
    mount(
      quickAmountRow,
      ...subs.filter((s) => s.status === "switch").map((s) => {
        const btn = h("button", { style: { ...S.btnGhost, padding: "6px 12px", fontSize: 12.5 } }, `${s.name} (${fmt(s.amount)})`);
        btn.addEventListener("click", () => { calc.monthly = s.amount; monthlyRange.value = String(s.amount); onCalcChanged(); });
        return btn;
      }),
      switchedSum > 0
        ? (() => {
            const btn = h("button", { style: { ...S.btnGhost, padding: "6px 12px", fontSize: 12.5, color: T.green, borderColor: T.green + "55" } }, `Alle markierten (${fmt(switchedSum)})`);
            btn.addEventListener("click", () => { calc.monthly = +switchedSum.toFixed(2); monthlyRange.value = String(calc.monthly); onCalcChanged(); });
            return btn;
          })()
        : null
    );
  }

  function renderEtfList() {
    if (etfs.length === 0) {
      mount(etfListSlot, h("div", { style: { color: T.textDim, fontSize: 13.5 } }, "Keine ETFs gefunden."));
      return;
    }
    mount(
      etfListSlot,
      ...etfs.map((e) => {
        const selected = calc.etfId === e.id;
        const compared = compareIds.includes(e.id);
        const compareBtn = h(
          "button",
          { style: { ...S.btnGhost, padding: "4px 10px", fontSize: 11, color: compared ? T.purple : T.textFaint, borderColor: compared ? T.purple : T.border } },
          compared ? "✓ Vergleich" : "+ Vergleich"
        );
        compareBtn.addEventListener("click", (ev) => {
          ev.stopPropagation();
          compareIds = compared ? compareIds.filter((x) => x !== e.id) : compareIds.length < 3 ? [...compareIds, e.id] : compareIds;
          renderEtfList();
          renderCompare();
        });
        const row = h(
          "div",
          {
            style: {
              ...S.btnGhost, textAlign: "left", padding: "12px 16px", borderRadius: 14,
              borderColor: selected ? T.green : T.border, background: selected ? "rgba(48,209,88,0.08)" : "transparent",
              display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10, flexWrap: "wrap", cursor: "pointer",
            },
          },
          h("span", {},
            h("span", { style: { fontWeight: 600, fontSize: 14.5 } }, e.name),
            ...e.tags.map((t) => h("span", { style: { ...S.tag(T.teal), marginLeft: 8, fontSize: 11 } }, t)),
            h("div", { style: { fontSize: 12.5, color: T.textDim, marginTop: 3 } }, `${e.desc} · Risiko: ${e.risk} · TER ${e.ter}%`)
          ),
          h("span", { style: { display: "flex", alignItems: "center", gap: 10 } },
            h("span", { style: { fontWeight: 700, color: T.green } }, `${e.ret}% p.a.*`),
            compareBtn
          )
        );
        row.addEventListener("click", () => { calc.etfId = e.id; renderEtfList(); renderResults(); });
        return row;
      })
    );
  }

  function selectedEtf() {
    return allEtfs.find((e) => e.id === calc.etfId) || allEtfs[0];
  }

  function renderResults() {
    const etf = selectedEtf();
    const fv = etf ? futureValue(calc.monthly, etf.ret, calc.years) : 0;
    const invested = calc.monthly * 12 * calc.years;
    const monthlyPension = (fv * 0.04) / 12;
    mount(
      resultsSlot,
      h(
        "div",
        { style: { ...S.card, background: "linear-gradient(135deg, rgba(48,209,88,0.10), rgba(100,210,255,0.06))" } },
        h(
          "div",
          { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 16, marginBottom: 20 } },
          h("div", {}, h("div", { style: { fontSize: 13, color: T.textDim } }, "Eingezahlt"), h("div", { style: { fontSize: 24, fontWeight: 700 } }, fmt(invested))),
          h("div", {}, h("div", { style: { fontSize: 13, color: T.textDim } }, "Mögliches Vermögen*"), h("div", { style: { fontSize: 24, fontWeight: 700, color: T.green } }, fmt(fv))),
          h("div", {}, h("div", { style: { fontSize: 13, color: T.textDim } }, "Davon Zinseszins"), h("div", { style: { fontSize: 24, fontWeight: 700, color: T.teal } }, fmt(fv - invested))),
          h("div", {}, h("div", { style: { fontSize: 13, color: T.textDim } }, "Renten-Boost (4%-Regel)*"), h("div", { style: { fontSize: 24, fontWeight: 700, color: T.purple } }, `+${fmt(monthlyPension)}/Mon.`))
        ),
        etf ? growthChart({ monthly: calc.monthly, ret: etf.ret, years: calc.years }) : null,
        h("p", { style: { fontSize: 11.5, color: T.textFaint, marginTop: 14, lineHeight: 1.5 } },
          "*Modellrechnung mit historischen Durchschnittsrenditen. Keine Anlageberatung, keine Garantie. Renditen schwanken, Verluste sind möglich. Die 4%-Entnahmeregel ist eine Faustformel, keine Zusicherung."
        )
      )
    );
  }

  function renderCompare() {
    if (compareIds.length === 0) { mount(compareSlot); return; }
    const series = compareIds.map((id) => { const e = allEtfs.find((x) => x.id === id) || etfs.find((x) => x.id === id); return { name: e.name, monthly: calc.monthly, ret: e.ret }; });
    mount(
      compareSlot,
      h(
        "div",
        { style: S.card },
        h("div", { style: { fontWeight: 650, marginBottom: 14 } }, `ETF-Vergleich (${fmt(calc.monthly)}/Monat, ${calc.years} Jahre)`),
        compareChart({ years: calc.years, series }),
        h(
          "div",
          { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 12, marginTop: 16 } },
          ...compareIds.map((id) => {
            const e = allEtfs.find((x) => x.id === id) || etfs.find((x) => x.id === id);
            return h(
              "div",
              { style: { padding: 12, background: "rgba(255,255,255,0.03)", borderRadius: 12 } },
              h("div", { style: { fontWeight: 600, fontSize: 13.5 } }, e.name),
              h("div", { style: { fontSize: 18, fontWeight: 700, color: T.green, marginTop: 4 } }, fmt(futureValue(calc.monthly, e.ret, calc.years))),
              h("div", { style: { fontSize: 11.5, color: T.textFaint } }, `${e.ret}% p.a. · TER ${e.ter}%`)
            );
          })
        )
      )
    );
  }

  function renderGapSelect() {
    mount(gapSelect, ...allEtfs.map((e) => h("option", { value: e.id, selected: e.id === gapEtfId }, `${e.name} (${e.ret}% p.a.)`)));
  }

  function renderGapResult() {
    const gapEtf = allEtfs.find((e) => e.id === gapEtfId) || allEtfs[0];
    const gapMonthly = gapEtf ? requiredMonthly(pensionGoal * 300, gapEtf.ret, gapYears) : 0;
    mount(
      gapResultSlot,
      h("div", {},
        `Du müsstest ≈ `, h("b", { style: { color: T.purple, fontSize: 20 } }, fmt(gapMonthly)),
        ` monatlich investieren, um in ${gapYears} Jahren einen Renten-Boost von ${fmt(pensionGoal)}/Monat zu erreichen.*`
      )
    );
  }

  function onCalcChanged() {
    monthlyLabel.textContent = fmt(calc.monthly);
    renderResults();
    renderCompare();
  }

  const monthlyRange = h("input", { type: "range", min: "5", max: "300", step: "0.01", value: String(calc.monthly), style: { flex: 1, accentColor: T.green } });
  const monthlyLabel = h("div", { style: { fontSize: 24, fontWeight: 700, minWidth: 110, textAlign: "right" } }, fmt(calc.monthly));
  monthlyRange.addEventListener("input", () => { calc.monthly = +monthlyRange.value; onCalcChanged(); });

  const yearsLabelEl = h("b", { style: { color: T.text } }, String(calc.years));
  const yearsRange = h("input", { type: "range", min: "1", max: "50", value: String(calc.years), style: { width: "100%", accentColor: T.teal, marginTop: 8 } });
  yearsRange.addEventListener("input", () => { calc.years = +yearsRange.value; yearsLabelEl.textContent = String(calc.years); renderResults(); renderCompare(); });

  const searchInput = h("input", { style: { ...S.input, maxWidth: 320, marginBottom: 16 }, placeholder: "🔍 ETF suchen (z.B. World, Tech, Dividende)…" });
  searchInput.addEventListener("input", () => {
    api.etfs.list(searchInput.value).then((list) => { etfs = list; renderEtfList(); });
  });

  const pensionGoalLabel = h("b", { style: { color: T.text } }, fmt(pensionGoal));
  const pensionGoalRange = h("input", { type: "range", min: "10", max: "2000", step: "10", value: String(pensionGoal), style: { width: "100%", accentColor: T.purple, marginTop: 8 } });
  pensionGoalRange.addEventListener("input", () => { pensionGoal = +pensionGoalRange.value; pensionGoalLabel.textContent = fmt(pensionGoal); renderGapResult(); });

  const gapYearsLabel = h("b", { style: { color: T.text } }, String(gapYears));
  const gapYearsRange = h("input", { type: "range", min: "1", max: "50", value: String(gapYears), style: { width: "100%", accentColor: T.teal, marginTop: 8 } });
  gapYearsRange.addEventListener("input", () => { gapYears = +gapYearsRange.value; gapYearsLabel.textContent = String(gapYears); renderGapResult(); });

  gapSelect.addEventListener("change", () => { gapEtfId = gapSelect.value; renderGapResult(); });

  api.etfs.list().then((list) => {
    allEtfs = list;
    calc.etfId = calc.etfId || list[0]?.id;
    gapEtfId = gapEtfId || list[0]?.id;
    renderBestCards();
    renderGapSelect();
    renderGapResult();
    renderResults();
    renderCompare();
  });
  api.etfs.list().then((list) => { etfs = list; renderEtfList(); });

  renderQuickAmounts();

  const el = h(
    "div",
    {},
    h("h1", { style: { fontSize: 34, fontWeight: 700, letterSpacing: "-1px", margin: "0 0 6px" } }, "↗ ETF-Explorer & Rechner"),
    h("p", { style: { color: T.textDim, margin: "0 0 24px" } }, "Was könnte aus deinem gekündigten Abo werden?"),
    bestCardsSlot,
    searchInput,
    h(
      "div",
      { style: { display: "grid", gridTemplateColumns: "1fr", gap: 20, maxWidth: 780 } },
      h(
        "div",
        { style: S.card },
        h("label", { style: { fontSize: 13.5, color: T.textDim } }, "Monatlicher Betrag (z. B. dein gekündigtes Abo)"),
        h("div", { style: { display: "flex", alignItems: "center", gap: 12, marginTop: 8 } }, monthlyRange, monthlyLabel),
        quickAmountRow,
        h("label", { style: { fontSize: 13.5, color: T.textDim, display: "block", marginTop: 22 } }, "Anlagedauer: ", yearsLabelEl, " Jahre"),
        yearsRange,
        h("label", { style: { fontSize: 13.5, color: T.textDim, display: "block", marginTop: 22, marginBottom: 10 } }, "ETF wählen (Klick zum Vergleichen anhaken)"),
        etfListSlot
      ),
      resultsSlot,
      compareSlot,
      h(
        "div",
        { style: S.card },
        h("div", { style: { fontWeight: 650, marginBottom: 6 } }, "🎯 Renten-Lücken-Rechner"),
        h("p", { style: { fontSize: 13, color: T.textDim, margin: "0 0 16px" } }, "Wie viel musst du monatlich sparen, um eine bestimmte Rentenaufstockung zu erreichen?"),
        h(
          "div",
          { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 16 } },
          h("div", {}, h("label", { style: { fontSize: 13, color: T.textDim } }, "Gewünschter Renten-Boost: ", pensionGoalLabel, "/Monat"), pensionGoalRange),
          h("div", {}, h("label", { style: { fontSize: 13, color: T.textDim } }, "Anlagedauer: ", gapYearsLabel, " Jahre"), gapYearsRange)
        ),
        gapSelect,
        h("div", { style: { marginTop: 16, padding: 16, background: "rgba(191,90,242,0.08)", borderRadius: 14 } }, gapResultSlot)
      )
    )
  );

  return {
    el,
    update({ subs: newSubs, switchedSum: newSum } = {}) {
      if (newSubs) subs = newSubs;
      if (newSum !== undefined) switchedSum = newSum;
      renderQuickAmounts();
    },
  };
}
