import { h, mount } from "./shared/dom.js";
import { T, S } from "./shared/tokens.js";
import { orbs } from "./shared/orbs.js";
import { api } from "./shared/api.js";
import { landingPage } from "./pages/landing.js";
import { dashboardPage } from "./pages/dashboard.js";
import { subscriptionsPage } from "./pages/subscriptions.js";
import { accountsConnectPage } from "./pages/accountsConnect.js";
import { etfExplorerPage } from "./pages/etfExplorer.js";
import { financeRadarPage } from "./pages/financeRadar.js";
import { settingsPage } from "./pages/settings.js";

const TABS = [
  { id: "dashboard", label: "Übersicht", icon: "◉" },
  { id: "abos", label: "Abos", icon: "☰" },
  { id: "konten", label: "Konten", icon: "🔗" },
  { id: "etf", label: "Investieren", icon: "↗" },
  { id: "radar", label: "Finanz-Radar", icon: "🧭" },
  { id: "settings", label: "Konto", icon: "⚙" },
];

export class AboWandlerApp {
  constructor(root) {
    this.root = root;
    this.state = {
      page: "landing",
      tab: "dashboard",
      subs: [],
      accounts: [],
      user: { name: "", emails: [""] },
      aiUsageCount: 0,
      loading: true,
      error: null,
      filterOverride: null,
    };
    this.pageInstances = {};
    this.navButtons = {};
    this.render();
  }

  loadAll(silent = false) {
    if (!silent) {
      this.state.loading = true;
      this.renderMain();
    }
    Promise.all([api.subscriptions.list(), api.accounts.list(), api.user.get()])
      .then(([s, a, u]) => {
        this.state.subs = s;
        this.state.accounts = a;
        this.state.user = u;
        this.state.error = null;
      })
      .catch((e) => {
        this.state.error = e.message;
      })
      .finally(() => {
        this.state.loading = false;
        this.updateAllInstances();
        this.renderMain();
      });
  }

  get switchedSum() {
    return this.state.subs.filter((s) => s.status === "switch").reduce((a, s) => a + s.amount, 0);
  }

  get emails() {
    return this.state.user.emails.filter(Boolean);
  }

  updateAllInstances() {
    const { subs, accounts, user, aiUsageCount } = this.state;
    this.pageInstances.dashboard?.update({ subs });
    this.pageInstances.abos?.update({ subs, emails: this.emails });
    this.pageInstances.konten?.update({ accounts });
    this.pageInstances.etf?.update({ subs, switchedSum: this.switchedSum });
    this.pageInstances.radar?.update({});
    this.pageInstances.settings?.update({ user, aiUsageCount });
  }

  render() {
    if (this.state.page === "landing") {
      mount(this.root, landingPage({ onStart: () => this.goToApp() }));
      return;
    }
    this.buildAppShell();
    this.renderMain();
  }

  goToApp() {
    this.state.page = "app";
    this.render();
    this.loadAll();
  }

  goToLanding() {
    this.state.page = "landing";
    this.render();
  }

  setTab(tab) {
    this.state.tab = tab;
    this.updateNavHighlight();
    this.renderMain();
  }

  updateNavHighlight() {
    for (const [id, btn] of Object.entries(this.navButtons)) {
      const active = id === this.state.tab;
      btn.style.background = active ? T.bgCardHover : "transparent";
      btn.style.color = active ? T.text : T.textDim;
      btn.style.fontWeight = active ? "600" : "450";
    }
  }

  buildAppShell() {
    const brand = h(
      "div",
      { style: { fontWeight: 700, fontSize: 17, cursor: "pointer", whiteSpace: "nowrap" } },
      "Abo",
      h("span", { style: { background: `linear-gradient(90deg, ${T.green}, ${T.teal})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" } }, "Wandler")
    );
    brand.addEventListener("click", () => this.goToLanding());

    this.navButtons = {};
    const navBtns = TABS.map((t) => {
      const btn = h(
        "button",
        {
          style: {
            background: "transparent", border: "none", color: T.textDim,
            borderRadius: 12, padding: "10px 16px", fontSize: 14.5, fontWeight: 450, cursor: "pointer",
            display: "flex", alignItems: "center", gap: 8, transition: "all 0.2s",
          },
        },
        `${t.icon} ${t.label}`
      );
      btn.addEventListener("click", () => this.setTab(t.id));
      this.navButtons[t.id] = btn;
      return btn;
    });

    const nav = h(
      "nav",
      { style: { position: "sticky", top: 0, zIndex: 10, backdropFilter: "blur(24px)", background: "rgba(5,5,8,0.75)", borderBottom: `1px solid ${T.border}` } },
      h("div", { style: { ...S.container, display: "flex", justifyContent: "space-between", alignItems: "center", height: 60, gap: 12 } },
        brand,
        h("div", { style: { display: "flex", gap: 4, overflowX: "auto" } }, ...navBtns)
      )
    );

    this.mainSlot = h("main", { style: { ...S.container, padding: "40px 24px 80px" } });

    mount(this.root, orbs(), nav, this.mainSlot);
    this.updateNavHighlight();
  }

  getOrCreatePage(tab) {
    if (this.pageInstances[tab]) return this.pageInstances[tab];
    const { subs, accounts, user, aiUsageCount } = this.state;
    let instance;
    if (tab === "dashboard") {
      instance = dashboardPage({
        subs,
        onFilterWarning: () => { this.state.filterOverride = "warning"; this.setTab("abos"); },
        onRefresh: () => this.loadAll(true),
      });
    } else if (tab === "abos") {
      instance = subscriptionsPage({
        subs, emails: this.emails,
        forceFilter: this.state.filterOverride,
        onForceFilterApplied: () => { this.state.filterOverride = null; },
        onSubsChanged: (newSubs) => { this.state.subs = newSubs; },
      });
    } else if (tab === "konten") {
      instance = accountsConnectPage({
        accounts,
        onAccountsChanged: (newAccounts) => { this.state.accounts = newAccounts; },
        onImported: () => { this.loadAll(true); this.state.aiUsageCount += 1; this.updateAllInstances(); },
      });
    } else if (tab === "etf") {
      instance = etfExplorerPage({ subs, switchedSum: this.switchedSum });
    } else if (tab === "radar") {
      instance = financeRadarPage();
    } else if (tab === "settings") {
      instance = settingsPage({
        user,
        onUserChanged: (newUser) => { this.state.user = newUser; },
        aiUsageCount,
      });
    }
    this.pageInstances[tab] = instance;
    return instance;
  }

  renderMain() {
    if (!this.mainSlot) return;
    if (this.state.error) {
      mount(this.mainSlot,
        h("div", { style: { ...S.card, marginBottom: 24, borderColor: "rgba(255,69,58,0.35)", color: T.red } },
          `Verbindung zum Server fehlgeschlagen: ${this.state.error}. Läuft das Backend (server/) auf Port 8787?`
        )
      );
      return;
    }
    if (this.state.loading) {
      mount(this.mainSlot, h("div", { style: { color: T.textDim } }, "Lädt…"));
      return;
    }
    // Special case: when jumping to "abos" with a forced filter, that instance
    // may already exist — apply the filter via update() instead of getOrCreatePage
    // (which only builds fresh instances, it won't re-apply a forced filter).
    const instance = this.getOrCreatePage(this.state.tab);
    if (this.state.tab === "abos" && this.state.filterOverride) {
      instance.update({ forceFilter: this.state.filterOverride });
    }
    mount(this.mainSlot, instance.el);
  }
}
