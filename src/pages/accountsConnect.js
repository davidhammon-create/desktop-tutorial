import { h, mount } from "../shared/dom.js";
import { T, S } from "../shared/tokens.js";
import { fmt } from "../shared/format.js";
import { api } from "../shared/api.js";

const providerIcon = { bank: "🏦", paypal: "🅿", card: "💳", klarna: "🛍" };

export function accountsConnectPage({ accounts, onAccountsChanged, onImported }) {
  let currentAccounts = accounts;
  let file = null;

  const accountsGrid = h("div", { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 16, marginBottom: 32 } });

  function renderAccounts() {
    mount(
      accountsGrid,
      ...currentAccounts.map((acc) => {
        const connected = acc.status === "demo-connected";
        const btn = h(
          "button",
          { style: { ...S.btnGhost, padding: "8px 16px", fontSize: 13, width: "100%", boxSizing: "border-box", borderColor: connected ? T.red + "55" : T.border, color: connected ? T.red : T.text } },
          connected ? "Trennen" : "Verbinden"
        );
        btn.addEventListener("click", async () => {
          btn.disabled = true;
          btn.textContent = "…";
          const updated = connected ? await api.accounts.disconnect(acc.id) : await api.accounts.connect(acc.id);
          currentAccounts = currentAccounts.map((a) => (a.id === acc.id ? updated : a));
          onAccountsChanged?.(currentAccounts);
          renderAccounts();
        });
        return h(
          "div",
          { style: S.card },
          h("div", { style: { fontSize: 28, marginBottom: 10 } }, providerIcon[acc.provider] || "🔗"),
          h("div", { style: { fontWeight: 650, marginBottom: 4 } }, acc.label),
          h("div", { style: { fontSize: 13, color: connected ? T.green : T.textFaint, marginBottom: 12 } }, connected ? "✓ Verbunden (Demo)" : "Nicht verbunden"),
          btn
        );
      })
    );
  }

  const textarea = h("textarea", {
    style: { ...S.input, minHeight: 160, fontFamily: "SF Mono, Menlo, monospace", fontSize: 13, resize: "vertical" },
    placeholder: "Text einfügen, z.B.:\n28.06.2026  NETFLIX INTERNATIONAL B.V.   -17,99 EUR\n25.06.2026  SPOTIFY AB                    -10,99 EUR\n…",
  });

  const fileInput = h("input", { type: "file", accept: ".pdf,.csv,.txt", style: { display: "none" } });
  const fileBtn = h("button", { style: { ...S.btnGhost, padding: "10px 18px", fontSize: 13.5 } }, "📎 PDF / CSV hochladen");
  fileBtn.addEventListener("click", () => fileInput.click());
  const fileRow = h("div", { style: { display: "flex", gap: 12, marginTop: 14, alignItems: "center", flexWrap: "wrap" } }, fileBtn, fileInput);

  fileInput.addEventListener("change", () => {
    file = fileInput.files?.[0] || null;
    updateFileRow();
  });

  function updateFileRow() {
    mount(fileRow, fileBtn, fileInput);
    fileBtn.textContent = file ? `📎 ${file.name}` : "📎 PDF / CSV hochladen";
    if (file) {
      const removeBtn = h("button", { style: { ...S.btnGhost, padding: "6px 12px", fontSize: 12 } }, "✕ Entfernen");
      removeBtn.addEventListener("click", () => { file = null; fileInput.value = ""; updateFileRow(); });
      fileRow.appendChild(removeBtn);
    }
  }

  const analyzeBtn = h("button", { style: S.btn }, "✦ Jetzt analysieren");
  const resultSlot = h("div", {});

  analyzeBtn.addEventListener("click", async () => {
    if (!textarea.value.trim() && !file) return;
    analyzeBtn.disabled = true;
    analyzeBtn.style.opacity = "0.6";
    analyzeBtn.textContent = "⏳ KI analysiert…";
    mount(resultSlot);
    try {
      const result = await api.ai.analyzeStatement(textarea.value, file);
      renderResult(result);
    } catch (e) {
      renderResult({ error: e.message });
    }
    analyzeBtn.disabled = false;
    analyzeBtn.style.opacity = "1";
    analyzeBtn.textContent = "✦ Jetzt analysieren";
  });

  function renderResult(aiResult) {
    if (aiResult?.error) {
      mount(resultSlot, h("div", { style: { ...S.card, marginTop: 20, color: T.red } }, aiResult.error));
      return;
    }
    if (!aiResult) { mount(resultSlot); return; }

    const importBtn = h("button", { style: { ...S.btn, marginTop: 16 } }, "Alle in Abo-Liste übernehmen →");
    importBtn.addEventListener("click", async () => {
      if (!aiResult.subs) return;
      importBtn.disabled = true;
      for (const s of aiResult.subs) {
        await api.subscriptions.create({
          name: s.name, amount: s.amount, status: s.suspicious ? "warning" : "pending",
          category: "Importiert", note: s.reason || "",
        });
      }
      onImported?.();
      textarea.value = "";
      file = null;
      fileInput.value = "";
      updateFileRow();
      mount(resultSlot);
    });

    mount(
      resultSlot,
      h(
        "div",
        { style: { ...S.card, marginTop: 20 } },
        h("div", { style: { fontWeight: 650, marginBottom: 12 } }, "Ergebnis der Analyse"),
        h("p", { style: { color: T.textDim, fontSize: 14 } }, aiResult.summary),
        ...(aiResult.subs || []).map((s) =>
          h(
            "div",
            { style: { display: "flex", justifyContent: "space-between", padding: "10px 0", borderTop: `1px solid ${T.border}`, gap: 12, flexWrap: "wrap" } },
            h("div", {},
              h("span", { style: { fontWeight: 600 } }, s.name),
              s.suspicious ? h("span", { style: { ...S.tag(T.red), marginLeft: 10 } }, "⚠ verdächtig") : null,
              s.reason ? h("div", { style: { fontSize: 13, color: T.textDim } }, s.reason) : null
            ),
            h("div", { style: { fontWeight: 650 } }, fmt(s.amount))
          )
        ),
        importBtn
      )
    );
  }

  updateFileRow();
  renderAccounts();

  const el = h(
    "div",
    {},
    h("h1", { style: { fontSize: 34, fontWeight: 700, letterSpacing: "-1px", margin: "0 0 6px" } }, "Konten & Import"),
    h("p", { style: { color: T.textDim, margin: "0 0 24px", maxWidth: "680px" } },
      "Verbinde deine Konten oder importiere Kontoauszüge direkt — die KI erkennt wiederkehrende Zahlungen und markiert verdächtige Abbuchungen automatisch."
    ),
    accountsGrid,
    h(
      "div",
      { style: { ...S.card, marginBottom: 24, background: "rgba(255,159,10,0.06)", borderColor: "rgba(255,159,10,0.25)" } },
      h("p", { style: { fontSize: 12.5, color: T.textDim, margin: 0, lineHeight: 1.6 } },
        `ℹ Echte Bank-/PayPal-Anbindung (PSD2/OAuth) erfordert registrierte API-Zugänge bei einem Kontoaggregator (z. B. Tink, GoCardless, FinAPI) bzw. bei PayPal Developer. „Verbinden" simuliert diesen Schritt im Demo-Modus — für echte Daten nutze den Import unten: Kontoauszug einfügen oder als PDF/CSV hochladen.`
      )
    ),
    h(
      "div",
      { style: S.card },
      h("div", { style: { fontWeight: 650, marginBottom: 14 } }, "✦ Kontoauszug importieren"),
      textarea,
      fileRow,
      h("div", { style: { display: "flex", gap: 12, marginTop: 16, alignItems: "center", flexWrap: "wrap" } },
        analyzeBtn,
        h("span", { style: { fontSize: 12.5, color: T.textFaint } }, "KI-Kosten: ~0,02 € pro Analyse (transparent abgerechnet)")
      )
    ),
    resultSlot
  );

  return {
    el,
    update({ accounts: newAccounts } = {}) {
      if (newAccounts) { currentAccounts = newAccounts; renderAccounts(); }
    },
  };
}
