import { h, mount } from "../shared/dom.js";
import { T, S } from "../shared/tokens.js";
import { api } from "../shared/api.js";

// Einstellungen: profile data, the KI opt-in switch, data export and
// profile switching. API keys live in the admin area, not here.
export function settingsPage({ me: initialMe, onUserChanged, onSwitchProfile }) {
  let me = initialMe;

  const profileSlot = h("div", {});
  const aiSlot = h("div", {});
  const dataSlot = h("div", {});

  function renderProfile() {
    const nameInput = h("input", { style: { ...S.input, marginTop: 4 }, value: me?.name || "", placeholder: "Dein Name" });
    const emailInputs = (me?.emails?.length ? me.emails : [""]).map((em) =>
      h("input", { style: { ...S.input, marginTop: 8 }, value: em, placeholder: "E-Mail (für Abo-Zuordnung)" })
    );
    const emailWrap = h("div", {}, ...emailInputs);
    const addEmailBtn = h("button", { style: { ...S.btnGhost, padding: "8px 16px", fontSize: 13, marginTop: 10 } }, "＋ Weitere E-Mail");
    addEmailBtn.addEventListener("click", () => {
      const inp = h("input", { style: { ...S.input, marginTop: 8 }, placeholder: "E-Mail" });
      emailInputs.push(inp);
      emailWrap.appendChild(inp);
    });
    const saveBtn = h("button", { style: { ...S.btn, padding: "10px 22px", fontSize: 14, marginTop: 14 } }, "Speichern");
    const msg = h("span", { style: { fontSize: 13, marginLeft: 10 } });
    saveBtn.addEventListener("click", async () => {
      try {
        me = { ...me, ...(await api.user.save({ name: nameInput.value, emails: emailInputs.map((i) => i.value) })) };
        msg.style.color = T.green;
        msg.textContent = "✓ Gespeichert";
        onUserChanged?.();
      } catch (e) {
        msg.style.color = T.red;
        msg.textContent = e.message;
      }
      setTimeout(() => (msg.textContent = ""), 3000);
    });

    const switchBtn = h("button", { style: { ...S.btnGhost, padding: "8px 16px", fontSize: 13 } }, "Profil wechseln");
    switchBtn.addEventListener("click", () => onSwitchProfile?.());

    mount(profileSlot,
      h("div", { style: S.card },
        h("div", { style: { display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10, flexWrap: "wrap", marginBottom: 10 } },
          h("div", { style: { fontWeight: 600, fontSize: 17 } }, "Profil"),
          h("div", { style: { display: "flex", gap: 8, alignItems: "center" } },
            me?.role === "admin" ? h("span", { style: S.tag(T.blue) }, "Admin") : null,
            switchBtn
          )
        ),
        h("label", { style: { fontSize: 12.5, color: T.textFaint } }, "Name"),
        nameInput,
        h("label", { style: { fontSize: 12.5, color: T.textFaint, display: "block", marginTop: 14 } }, "E-Mail-Adressen (werden Abos zugeordnet)"),
        emailWrap,
        h("div", {}, addEmailBtn),
        h("div", { style: { display: "flex", alignItems: "center" } }, saveBtn, msg)
      )
    );
  }

  function renderAi() {
    const enabled = Boolean(me?.settings?.aiEnabled);
    const toggle = h(
      "button",
      {
        style: {
          width: 52, height: 32, borderRadius: 980, border: "none", cursor: "pointer", position: "relative",
          background: enabled ? T.green : "rgba(0,0,0,0.2)", transition: "background 0.25s", flexShrink: 0,
        },
        title: enabled ? "KI ausschalten" : "KI einschalten",
      },
      h("span", { style: { position: "absolute", top: 3, left: enabled ? 23 : 3, width: 26, height: 26, borderRadius: "50%", background: "#fff", transition: "left 0.25s", boxShadow: "0 1px 3px rgba(0,0,0,0.3)" } })
    );
    toggle.addEventListener("click", async () => {
      const settings = await api.user.saveSettings({ aiEnabled: !enabled });
      me = { ...me, settings };
      renderAi();
      onUserChanged?.();
    });

    mount(aiSlot,
      h("div", { style: { ...S.card, marginTop: 20 } },
        h("div", { style: { display: "flex", justifyContent: "space-between", gap: 16, alignItems: "center", flexWrap: "wrap" } },
          h("div", { style: { maxWidth: 560 } },
            h("div", { style: { fontWeight: 600, fontSize: 17, marginBottom: 4 } }, "KI-Funktionen"),
            h("p", { style: { fontSize: 13, color: T.textDim, margin: 0, lineHeight: 1.55 } },
              "Standardmäßig arbeitet AboWandler rein algorithmisch — ohne KI, ohne Datenübertragung. Schaltest du die KI ein, kannst du zusätzlich: Firmen & IBANs auf Seriosität recherchieren lassen, Kündigungsbriefe generieren, den KI-Anlage-Finder und die Live-Recherche im Finanz-Radar nutzen. Dafür wird ein Anthropic-API-Schlüssel benötigt (Admin → APIs); Daten gehen nur bei aktiver Analyse an die KI."
            )
          ),
          toggle
        ),
        h("div", { style: { marginTop: 10 } }, h("span", { style: S.tag(enabled ? T.green : T.textFaint) }, enabled ? "KI aktiviert" : "KI deaktiviert — nur Algorithmen"))
      )
    );
  }

  function renderData() {
    const exportBtn = h("button", { style: { ...S.btnGhost, padding: "9px 18px", fontSize: 13 } }, "⬇ Meine Daten als JSON exportieren");
    exportBtn.addEventListener("click", async () => {
      const [subs, accounts, txs] = await Promise.all([api.subscriptions.list(), api.accounts.list(), api.accounts.transactions()]);
      const blob = new Blob([JSON.stringify({ profil: me, konten: accounts, umsaetze: txs, abos: subs }, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = h("a", { href: url, download: "abowandler_export.json" });
      a.click();
      URL.revokeObjectURL(url);
    });

    mount(dataSlot,
      h("div", { style: { ...S.card, marginTop: 20 } },
        h("div", { style: { fontWeight: 600, fontSize: 17, marginBottom: 6 } }, "Daten & Sicherheit"),
        h("p", { style: { fontSize: 13, color: T.textDim, margin: "0 0 14px", lineHeight: 1.55 } },
          "Alle Daten liegen lokal auf diesem Gerät — kein Cloud-Server. Passwörter werden AES-256-verschlüsselt gespeichert. Dein PC ist der Host: Im selben WLAN ist die App auch vom Handy erreichbar."
        ),
        exportBtn
      )
    );
  }

  renderProfile();
  renderAi();
  renderData();

  const el = h(
    "div",
    {},
    h("h1", { style: { fontSize: 34, fontWeight: 600, letterSpacing: "-0.02em", margin: "0 0 6px" } }, "Einstellungen"),
    h("p", { style: { color: T.textDim, margin: "0 0 20px" } }, "Profil, KI-Freischaltung und deine Daten."),
    profileSlot,
    aiSlot,
    dataSlot
  );

  return {
    el,
    update({ me: newMe } = {}) {
      if (newMe) {
        me = newMe;
        renderProfile();
        renderAi();
      }
    },
  };
}
