import { h, mount } from "./shared/dom.js";
import { T, S } from "./shared/tokens.js";
import { api, getCurrentUserId, setCurrentUserId } from "./shared/api.js";
import { landingPage } from "./pages/landing.js";
import { dashboardPage } from "./pages/dashboard.js";
import { subscriptionsPage } from "./pages/subscriptions.js";
import { accountsPage } from "./pages/accounts.js";
import { etfExplorerPage } from "./pages/etfExplorer.js";
import { financeRadarPage } from "./pages/financeRadar.js";
import { settingsPage } from "./pages/settings.js";
import { adminPage } from "./pages/admin.js";

const TABS = [
  { id: "dashboard", label: "Übersicht" },
  { id: "konten", label: "Konten" },
  { id: "abos", label: "Abos" },
  { id: "etf", label: "Investieren" },
  { id: "radar", label: "Radar" },
  { id: "settings", label: "Einstellungen" },
  { id: "admin", label: "Admin", adminOnly: true },
];

export class AboWandlerApp {
  constructor(root) {
    this.root = root;
    this.state = {
      page: "landing", // landing | login | app
      tab: "dashboard",
      me: null, // full current-user profile incl. role + settings
      subs: [],
      accounts: [],
      loading: true,
      error: null,
      filterOverride: null,
    };
    this.pageInstances = {};
    this.navButtons = {};
    this.render();
  }

  get aiEnabled() {
    return Boolean(this.state.me?.settings?.aiEnabled);
  }

  get switchedSum() {
    return this.state.subs.filter((s) => s.status === "switch").reduce((a, s) => a + s.amount, 0);
  }

  get emails() {
    return (this.state.me?.emails || []).filter(Boolean);
  }

  loadAll(silent = false) {
    if (!silent) {
      this.state.loading = true;
      this.renderMain();
    }
    Promise.all([api.subscriptions.list(), api.accounts.list(), api.user.get()])
      .then(([s, a, me]) => {
        this.state.subs = s;
        this.state.accounts = a;
        this.state.me = me;
        this.state.error = null;
      })
      .catch((e) => {
        this.state.error = e.message;
      })
      .finally(() => {
        this.state.loading = false;
        this.updateAllInstances();
        this.renderMain();
        this.updateNavUser();
      });
  }

  updateAllInstances() {
    const { subs, accounts, me } = this.state;
    this.pageInstances.dashboard?.update({ subs, aiEnabled: this.aiEnabled });
    this.pageInstances.abos?.update({ subs, emails: this.emails, aiEnabled: this.aiEnabled });
    this.pageInstances.konten?.update({ accounts });
    this.pageInstances.etf?.update({ subs, switchedSum: this.switchedSum, aiEnabled: this.aiEnabled });
    this.pageInstances.radar?.update({ aiEnabled: this.aiEnabled });
    this.pageInstances.settings?.update({ me });
  }

  render() {
    if (this.state.page === "landing") {
      mount(this.root, landingPage({ onStart: () => this.goToLogin() }));
      return;
    }
    if (this.state.page === "login") {
      this.renderLogin();
      return;
    }
    this.buildAppShell();
    this.renderMain();
  }

  goToLogin() {
    // Skip the picker when a valid profile is already selected on this device.
    const stored = getCurrentUserId();
    if (stored) {
      api.user
        .get()
        .then(() => this.enterApp())
        .catch(() => {
          setCurrentUserId(null);
          this.state.page = "login";
          this.render();
        });
      this.state.page = "login";
      this.render();
      return;
    }
    this.state.page = "login";
    this.render();
  }

  enterApp() {
    this.state.page = "app";
    this.pageInstances = {};
    this.render();
    this.loadAll();
  }

  goToLanding() {
    this.state.page = "landing";
    this.render();
  }

  renderLogin() {
    const slot = h("div", { style: { display: "grid", gap: 12, maxWidth: 420, margin: "0 auto" } }, h("div", { style: { color: T.textDim, textAlign: "center" } }, "Lade Profile…"));

    api.users.list().then((users) => {
      const newName = h("input", { style: { ...S.input, flex: 1 }, placeholder: "Name des neuen Profils" });
      const createBtn = h("button", { style: { ...S.btn, whiteSpace: "nowrap" } }, "Anlegen");
      createBtn.addEventListener("click", async () => {
        if (!newName.value.trim()) return;
        const u = await api.users.create(newName.value.trim());
        setCurrentUserId(u.id);
        this.enterApp();
      });
      mount(
        slot,
        ...users.map((u) => {
          const row = h(
            "button",
            { style: { display: "flex", alignItems: "center", gap: 14, padding: "14px 18px", background: T.bgCard, border: "1px solid transparent", borderRadius: 16, cursor: "pointer", textAlign: "left", width: "100%", fontSize: 16, color: T.text } },
            h("span", { style: { width: 40, height: 40, borderRadius: "50%", background: u.role === "admin" ? T.blue : "#c7c7cc", color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 17 } }, u.name[0].toUpperCase()),
            h("span", { style: { flex: 1, fontWeight: 550 } }, u.name),
            u.role === "admin" ? h("span", { style: S.tag(T.blue) }, "Admin") : null
          );
          row.addEventListener("mouseenter", () => (row.style.background = T.bgCardHover));
          row.addEventListener("mouseleave", () => (row.style.background = T.bgCard));
          row.addEventListener("click", () => {
            setCurrentUserId(u.id);
            this.enterApp();
          });
          return row;
        }),
        h("div", { style: { display: "flex", gap: 10, marginTop: 10 } }, newName, createBtn)
      );
    });

    mount(
      this.root,
      h(
        "div",
        { style: { ...S.page, display: "flex", alignItems: "center", justifyContent: "center", padding: 24 } },
        h(
          "div",
          { style: { width: "100%", maxWidth: 480 } },
          h("h1", { style: { fontSize: 32, fontWeight: 600, letterSpacing: "-0.02em", textAlign: "center", margin: "0 0 6px" } }, "Wer nutzt AboWandler?"),
          h("p", { style: { color: T.textDim, textAlign: "center", margin: "0 0 28px", fontSize: 15 } }, "Wähle dein Profil oder lege ein neues an. Alle Daten bleiben auf diesem Gerät."),
          slot
        )
      )
    );
  }

  setTab(tab) {
    this.state.tab = tab;
    this.updateNavHighlight();
    this.renderMain();
  }

  updateNavHighlight() {
    for (const [id, btn] of Object.entries(this.navButtons)) {
      const active = id === this.state.tab;
      btn.style.color = active ? T.text : "rgba(0,0,0,0.56)";
      btn.style.fontWeight = active ? "600" : "400";
    }
  }

  updateNavUser() {
    if (!this.userChip) return;
    const me = this.state.me;
    if (!me) return;
    mount(
      this.userChip,
      h("span", { style: { width: 26, height: 26, borderRadius: "50%", background: me.role === "admin" ? T.blue : "#c7c7cc", color: "#fff", display: "inline-flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 12.5 } }, (me.name || "?")[0].toUpperCase()),
      h("span", { style: { fontSize: 13 } }, me.name)
    );
  }

  buildAppShell() {
    const brand = h("div", { style: { fontWeight: 650, fontSize: 16, cursor: "pointer", whiteSpace: "nowrap", letterSpacing: "-0.01em" } }, "AboWandler");
    brand.addEventListener("click", () => this.goToLanding());

    this.navButtons = {};
    const navBtns = TABS.filter((t) => !t.adminOnly || this.state.me?.role === "admin" || true).map((t) => {
      const btn = h(
        "button",
        {
          style: {
            background: "transparent", border: "none", color: "rgba(0,0,0,0.56)",
            padding: "6px 10px", fontSize: 13.5, fontWeight: 400, cursor: "pointer", whiteSpace: "nowrap",
            transition: "color 0.2s", display: t.adminOnly ? "none" : "block",
          },
        },
        t.label
      );
      btn.addEventListener("click", () => this.setTab(t.id));
      this.navButtons[t.id] = btn;
      if (t.adminOnly) this.adminNavBtn = btn;
      return btn;
    });

    this.userChip = h("button", {
      style: { display: "flex", alignItems: "center", gap: 8, background: "transparent", border: "none", cursor: "pointer", color: T.text, padding: "4px 8px", borderRadius: 980 },
      title: "Profil wechseln",
    });
    this.userChip.addEventListener("click", () => {
      setCurrentUserId(null);
      this.state.page = "login";
      this.render();
    });

    const nav = h(
      "nav",
      { style: { position: "sticky", top: 0, zIndex: 10, backdropFilter: "saturate(180%) blur(20px)", background: "rgba(251,251,253,0.85)", borderBottom: "1px solid rgba(0,0,0,0.08)" } },
      h("div", { style: { ...S.container, display: "flex", justifyContent: "space-between", alignItems: "center", height: 48, gap: 10 } },
        brand,
        h("div", { style: { display: "flex", gap: 2, overflowX: "auto", alignItems: "center" } }, ...navBtns),
        this.userChip
      )
    );

    this.mainSlot = h("main", { style: { ...S.container, padding: "36px 22px 80px" } });

    mount(this.root, h("div", { style: S.page }, nav, this.mainSlot));
    this.updateNavHighlight();
  }

  getOrCreatePage(tab) {
    if (this.pageInstances[tab]) return this.pageInstances[tab];
    const { subs, accounts, me } = this.state;
    let instance;
    if (tab === "dashboard") {
      instance = dashboardPage({
        subs,
        aiEnabled: this.aiEnabled,
        onFilterWarning: () => { this.state.filterOverride = "warning"; this.setTab("abos"); },
        onRefresh: () => this.loadAll(true),
        onGoTo: (t) => this.setTab(t),
      });
    } else if (tab === "abos") {
      instance = subscriptionsPage({
        subs, emails: this.emails, aiEnabled: this.aiEnabled,
        forceFilter: this.state.filterOverride,
        onForceFilterApplied: () => { this.state.filterOverride = null; },
        onSubsChanged: (newSubs) => { this.state.subs = newSubs; },
      });
    } else if (tab === "konten") {
      instance = accountsPage({
        accounts,
        onAccountsChanged: () => this.loadAll(true),
        onScanned: () => this.loadAll(true),
      });
    } else if (tab === "etf") {
      instance = etfExplorerPage({ subs, switchedSum: this.switchedSum, aiEnabled: this.aiEnabled });
    } else if (tab === "radar") {
      instance = financeRadarPage({ aiEnabled: this.aiEnabled });
    } else if (tab === "settings") {
      instance = settingsPage({
        me,
        onUserChanged: () => this.loadAll(true),
        onSwitchProfile: () => { setCurrentUserId(null); this.state.page = "login"; this.render(); },
      });
    } else if (tab === "admin") {
      instance = adminPage();
    }
    this.pageInstances[tab] = instance;
    return instance;
  }

  renderMain() {
    if (!this.mainSlot) return;
    // Admin nav item only for admins.
    if (this.adminNavBtn) this.adminNavBtn.style.display = this.state.me?.role === "admin" ? "block" : "none";

    if (this.state.error) {
      mount(this.mainSlot,
        h("div", { style: { ...S.card, marginBottom: 24, border: `1px solid ${T.red}44`, color: T.red } },
          `Verbindung zum Server fehlgeschlagen: ${this.state.error}. Läuft das Backend (server/) auf Port 8787?`
        )
      );
      return;
    }
    if (this.state.loading) {
      mount(this.mainSlot, h("div", { style: { color: T.textDim } }, "Lädt…"));
      return;
    }
    const instance = this.getOrCreatePage(this.state.tab);
    if (this.state.tab === "abos" && this.state.filterOverride) {
      instance.update({ forceFilter: this.state.filterOverride });
    }
    mount(this.mainSlot, instance.el);
  }
}
