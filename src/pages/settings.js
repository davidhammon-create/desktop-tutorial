import { h, mount } from "../shared/dom.js";
import { T, S } from "../shared/tokens.js";
import { api } from "../shared/api.js";

export function settingsPage({ user, onUserChanged, aiUsageCount }) {
  let currentUser = user;
  let hasApiKey = false;

  const emailsContainer = h("div", {});
  function renderEmails() {
    mount(
      emailsContainer,
      ...currentUser.emails.map((em, i) => {
        const input = h("input", { style: S.input, placeholder: `E-Mail ${i + 1}`, value: em });
        input.addEventListener("input", () => { currentUser.emails[i] = input.value; });
        const row = h("div", { style: { display: "flex", gap: 8, marginTop: 8 } }, input);
        if (currentUser.emails.length > 1) {
          const removeBtn = h("button", { style: { ...S.btnGhost, padding: "0 14px" } }, "✕");
          removeBtn.addEventListener("click", () => { currentUser.emails = currentUser.emails.filter((_, j) => j !== i); renderEmails(); });
          row.appendChild(removeBtn);
        }
        return row;
      })
    );
  }

  const nameInput = h("input", { style: { ...S.input, marginTop: 6, marginBottom: 16 }, placeholder: "Dein Name", value: currentUser.name });
  nameInput.addEventListener("input", () => { currentUser.name = nameInput.value; });

  const addEmailBtn = h("button", { style: { ...S.btnGhost, padding: "8px 16px", fontSize: 13 } }, "+ Weitere E-Mail hinzufügen");
  addEmailBtn.addEventListener("click", () => { currentUser.emails.push(""); renderEmails(); });

  const saveProfileBtn = h("button", { style: { ...S.btn, padding: "8px 16px", fontSize: 13 } }, "Speichern");
  saveProfileBtn.addEventListener("click", async () => {
    saveProfileBtn.disabled = true;
    saveProfileBtn.textContent = "Speichert…";
    try {
      currentUser = await api.user.save(currentUser);
      onUserChanged?.(currentUser);
    } finally {
      saveProfileBtn.disabled = false;
      saveProfileBtn.textContent = "Speichern";
    }
  });

  const apiKeyBadge = h("span", { style: S.tag(T.orange) }, "⚠ Kein Key hinterlegt");
  const apiKeyInput = h("input", { type: "password", style: { ...S.input, maxWidth: 340 }, placeholder: "sk-ant-…" });
  const saveKeyBtn = h("button", { style: { ...S.btn, padding: "10px 18px", fontSize: 13.5 } }, "Speichern");
  const removeKeyBtnSlot = h("span", {});
  const keyMessageSlot = h("div", { style: { fontSize: 12.5, color: T.textDim, marginTop: 8 } });

  function renderKeyBadge() {
    apiKeyBadge.textContent = hasApiKey ? "✓ KI-Zugang aktiv" : "⚠ Kein Key hinterlegt";
    Object.assign(apiKeyBadge.style, S.tag(hasApiKey ? T.green : T.orange));
    mount(removeKeyBtnSlot);
    if (hasApiKey) {
      const removeBtn = h("button", { style: { ...S.btnGhost, padding: "10px 18px", fontSize: 13.5, color: T.red, borderColor: T.red + "55" } }, "Entfernen");
      removeBtn.addEventListener("click", async () => {
        removeBtn.disabled = true;
        const res = await api.config.saveApiKey("");
        hasApiKey = res.hasApiKey;
        keyMessageSlot.textContent = "Key entfernt.";
        renderKeyBadge();
      });
      removeKeyBtnSlot.appendChild(removeBtn);
    }
  }

  saveKeyBtn.addEventListener("click", async () => {
    if (!apiKeyInput.value) return;
    saveKeyBtn.disabled = true;
    saveKeyBtn.textContent = "…";
    keyMessageSlot.textContent = "";
    try {
      const res = await api.config.saveApiKey(apiKeyInput.value);
      hasApiKey = res.hasApiKey;
      apiKeyInput.value = "";
      keyMessageSlot.textContent = res.hasApiKey ? "✓ Gespeichert — KI-Funktionen sind jetzt aktiv." : "Key entfernt.";
    } catch (e) {
      keyMessageSlot.textContent = e.message;
    }
    saveKeyBtn.disabled = false;
    saveKeyBtn.textContent = "Speichern";
    renderKeyBadge();
  });

  api.config.get().then((c) => { hasApiKey = c.hasApiKey; renderKeyBadge(); }).catch(() => {});

  const usageNote = h("p", { style: { fontSize: 12, color: T.textFaint, marginTop: 12 } },
    `${aiUsageCount} KI-Analysen in dieser Sitzung. Abgerechnet direkt über dein Anthropic-Konto — AboWandler selbst verlangt keine eigene Gebühr.`
  );
  if (aiUsageCount === 0) usageNote.style.display = "none";

  renderEmails();
  renderKeyBadge();

  const el = h(
    "div",
    { style: { maxWidth: 640 } },
    h("h1", { style: { fontSize: 34, fontWeight: 700, letterSpacing: "-1px", margin: "0 0 24px" } }, "⚙ Konto & Einstellungen"),

    h(
      "div",
      { style: { ...S.card, marginBottom: 20 } },
      h("div", { style: { fontWeight: 650, marginBottom: 14 } }, "Profil"),
      h("label", { style: { fontSize: 13, color: T.textDim } }, "Name"),
      nameInput,
      h("label", { style: { fontSize: 13, color: T.textDim } }, "Deine E-Mail-Adressen (werden Abos zugeordnet)"),
      emailsContainer,
      h("div", { style: { display: "flex", gap: 10, marginTop: 12 } }, addEmailBtn, saveProfileBtn)
    ),

    h(
      "div",
      { style: { ...S.card, marginBottom: 20 } },
      h("div", { style: { fontWeight: 650, marginBottom: 6 } }, "✦ KI-Zugang"),
      h("p", { style: { fontSize: 13, color: T.textDim, margin: "0 0 14px", lineHeight: 1.5 } },
        "Für KI-Auto-Check, Kontoauszug-Analyse, Firmenberichte und Kündigungsbriefe brauchst du einen eigenen ",
        h("a", { href: "https://console.anthropic.com/settings/keys", target: "_blank", rel: "noreferrer", style: { color: T.teal } }, "Anthropic API-Key"),
        ". Er wird nur lokal auf diesem Gerät gespeichert (in deinem App-Datenordner) — nie auf einem fremden Server."
      ),
      h("div", { style: { display: "flex", gap: 8, alignItems: "center", marginBottom: 8, flexWrap: "wrap" } }, apiKeyBadge),
      h("div", { style: { display: "flex", gap: 8, flexWrap: "wrap" } }, apiKeyInput, saveKeyBtn, removeKeyBtnSlot),
      keyMessageSlot,
      usageNote
    ),

    h(
      "div",
      { style: { ...S.card, marginBottom: 20 } },
      h("div", { style: { fontWeight: 650, marginBottom: 10 } }, "🔒 Daten & Sicherheit"),
      h("p", { style: { fontSize: 13.5, color: T.textDim, lineHeight: 1.6, margin: "0 0 10px" } },
        "Alle Abo-Daten und Zugangsdaten bleiben auf diesem Gerät — es gibt keinen zentralen Cloud-Server. Passwörter werden lokal AES-256-verschlüsselt gespeichert und nie im Klartext geloggt. Kontoauszüge werden nur bei aktiver KI-Analyse an Anthropic übermittelt, sonst nirgendwo hin."
      ),
      h("p", { style: { fontSize: 12.5, color: T.textFaint, lineHeight: 1.6, margin: 0 } },
        "Damit du AboWandler auch von deinem Handy im selben WLAN öffnen kannst, ist es im lokalen Netzwerk erreichbar (nicht nur auf diesem Gerät). Andere Geräte in deinem WLAN könnten die Adresse theoretisch mit-erraten — für ein privates Heimnetz unkritisch. Willst du es auf dieses Gerät beschränken oder später an einen echten Server/eine echte Domain anbinden, ist das über die Umgebungsvariablen ",
        h("code", {}, "HOST"), "/", h("code", {}, "PORT"), " beim Start einstellbar (siehe README)."
      )
    ),

    h(
      "div",
      { style: { ...S.card, borderColor: "rgba(255,159,10,0.3)" } },
      h("div", { style: { fontWeight: 650, marginBottom: 10, color: T.orange } }, "Wichtiger Hinweis"),
      h("p", { style: { fontSize: 13.5, color: T.textDim, lineHeight: 1.6, margin: 0 } },
        "AboWandler ist keine Finanz-, Anlage- oder Rechtsberatung. Alle Prognosen sind unverbindliche Modellrechnungen. Risiko-Hinweise zu Zahlungen sind Wahrscheinlichkeits-Einschätzungen, keine Tatsachenbehauptungen. Entscheidungen triffst du eigenverantwortlich."
      )
    )
  );

  return {
    el,
    update({ user: newUser, aiUsageCount: newCount } = {}) {
      if (newUser) { currentUser = newUser; nameInput.value = currentUser.name; renderEmails(); }
      if (newCount !== undefined) {
        usageNote.textContent = `${newCount} KI-Analysen in dieser Sitzung. Abgerechnet direkt über dein Anthropic-Konto — AboWandler selbst verlangt keine eigene Gebühr.`;
        usageNote.style.display = newCount > 0 ? "" : "none";
      }
    },
  };
}
