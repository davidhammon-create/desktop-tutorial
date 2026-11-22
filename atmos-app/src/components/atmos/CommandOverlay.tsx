import { COMMANDS, COMMAND_GRUPPEN, standardKi, type CommandDef } from "@/atmos/commands";
import { kiKonfig, kiUebersicht } from "@/atmos/anbieter";
import { KATALOG } from "@/atmos/katalog";
import { EFFORT_LABELS, KOORDINAT_VERSION } from "@/atmos/constants";
import { useAtmos, type AtmosPanel } from "@/atmos/provider";
import {
  BookOpen,
  Bot,
  Boxes,
  Compass,
  Library,
  MessagesSquare,
  Gem,
  Hammer,
  HeartPulse,
  LayoutGrid,
  PauseCircle,
  Play,
  Rocket,
  Scale,
  Search,
  Settings2,
  Sparkles,
  Star,
  Terminal,
  X,
} from "lucide-react";
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { SettingsPanel } from "./SettingsPanel";
import { KiPanel } from "./KiPanel";
import { KatalogPanel } from "./KatalogPanel";
import { ReferenzPanel } from "./ReferenzPanel";
type OverlayNav =
  | "entdecken"
  | "chat"
  | "kis"
  | "katalog"
  | "referenz"
  | "befehle"
  | "module"
  | "arbeit"
  | "kristalle"
  | "verfassung"
  | "status"
  | "account"
  | "einstellungen";
const NAV: { id: OverlayNav; label: string; icon: ReactNode; panel?: AtmosPanel }[] = [
  { id: "entdecken", label: "Entdecken", icon: <Star size={15} strokeWidth={1.75} /> },
  { id: "chat", label: "Chat", icon: <MessagesSquare size={15} strokeWidth={1.75} /> },
  { id: "kis", label: "KIs", icon: <Bot size={15} strokeWidth={1.75} />, panel: "kis" },
  { id: "befehle", label: "Befehle", icon: <Terminal size={15} strokeWidth={1.75} /> },
  { id: "referenz", label: "Referenz", icon: <BookOpen size={15} strokeWidth={1.75} />, panel: "referenz" },
  { id: "katalog", label: "Katalog", icon: <Library size={15} strokeWidth={1.75} />, panel: "katalog" },
  { id: "arbeit", label: "Arbeit", icon: <Rocket size={15} strokeWidth={1.75} />, panel: "arbeit" },
  { id: "module", label: "Module", icon: <Boxes size={15} strokeWidth={1.75} />, panel: "module" },
  { id: "kristalle", label: "Kristalle", icon: <Gem size={15} strokeWidth={1.75} />, panel: "kristalle" },
  { id: "verfassung", label: "Verfassung", icon: <Scale size={15} strokeWidth={1.75} />, panel: "verfassung" },
  { id: "status", label: "Status", icon: <HeartPulse size={15} strokeWidth={1.75} />, panel: "status" },
  { id: "einstellungen", label: "Einstellungen", icon: <Settings2 size={15} strokeWidth={1.75} /> },
  { id: "account", label: "Account", icon: <LayoutGrid size={15} strokeWidth={1.75} /> },
];
const FEATURED: {
  eyebrow: string;
  title: string;
  subtitle: string;
  cmd: string;
  tone: "copper" | "teal" | "violet" | "blue";
}[] = [
  { eyebrow: "ALLE KIs", title: "Alle fragen, vergleichen", subtitle: "Dieselbe Frage parallel an jede verbundene KI", cmd: "/alle ", tone: "copper" },
  { eyebrow: "EFFORT", title: "Denktiefe setzen", subtitle: "aus · low · medium · high · xhigh · max – für jede KI", cmd: "/effort high", tone: "teal" },
  { eyebrow: "GITHUB", title: `${KATALOG.length} geprüfte Repos`, subtitle: "Katalog nach Kategorie durchsuchen und einbetten", cmd: "/katalog ", tone: "violet" },
  { eyebrow: "AUFTRAG", title: "Mach es einfach", subtitle: "Freien Auftrag planen und starten", cmd: "/mach ", tone: "blue" },
];
const ICON_FOR: Record<string, ReactNode> = {
  effort: <Hammer size={20} />,
  stop: <PauseCircle size={20} />,
  fortsetzen: <Play size={20} />,
  suche: <Search size={20} />,
  install: <Boxes size={20} />,
  an: <Play size={20} />,
  aus: <PauseCircle size={20} />,
  liste: <LayoutGrid size={20} />,
  vital: <HeartPulse size={20} />,
  lauf: <Rocket size={20} />,
  mach: <Sparkles size={20} />,
  kristall: <Gem size={20} />,
  erklaere: <Compass size={20} />,
  verfassung: <Scale size={20} />,
  trace: <Terminal size={20} />,
  hilfe: <Star size={20} />,
  frage: <MessagesSquare size={20} />,
  alle: <Bot size={20} />,
  neu: <X size={20} />,
  anbieter: <Bot size={20} />,
  modell: <Settings2 size={20} />,
  modelle: <LayoutGrid size={20} />,
  befehle: <BookOpen size={20} />,
  katalog: <Library size={20} />,
  google: <Search size={20} />,
};
const TONE_CLASS: Record<string, string> = {
  copper: "atmos-ov__feature--copper",
  teal: "atmos-ov__feature--teal",
  violet: "atmos-ov__feature--violet",
  blue: "atmos-ov__feature--blue",
};
function filterCommands(q: string): CommandDef[] {
  const needle = q.startsWith("/") ? q.slice(1).toLowerCase() : q.toLowerCase().trim();
  if (!needle) return COMMANDS;
  return COMMANDS.filter(
    (c) =>
      c.id.includes(needle) ||
      c.label.toLowerCase().includes(needle) ||
      c.aliases.some((a) => a.includes(needle)) ||
      c.beschreibung.toLowerCase().includes(needle),
  );
}
function CommandRow({
  cmd,
  actionLabel = "Laden",
  onRun,
  onFill,
}: {
  cmd: CommandDef;
  actionLabel?: string;
  onRun: (usage: string) => void;
  onFill: (usage: string) => void;
}) {
  return (
    <div className="atmos-ov__row">
      <div className="atmos-ov__squircle" data-id={cmd.id} aria-hidden>
        {ICON_FOR[cmd.id] ?? <Terminal size={20} />}
      </div>
      <div className="atmos-ov__row-text">
        <strong>{cmd.label}</strong>
        <span>{cmd.beschreibung}</span>
      </div>
      <div className="atmos-ov__row-actions">
        <button
          type="button"
          className="atmos-ov__pill"
          onClick={() => onRun(cmd.usage)}
          title={cmd.usage}
        >
          {actionLabel}
        </button>
        <button type="button" className="atmos-ov__pill-ghost" onClick={() => onFill(`${cmd.label} `)}>
          Tippen
        </button>
      </div>
    </div>
  );
}
export function CommandOverlay(_props: { autofocus?: boolean } = {}) {
  const { run, state, setPanel, pendingFreigabe, refreshGoogle, lastResult, denkt } = useAtmos();
  const [antwortZu, setAntwortZu] = useState(false);
  useEffect(() => setAntwortZu(false), [lastResult]);
  const kis = kiUebersicht();
  const stdKi = standardKi();
  const [nav, setNav] = useState<OverlayNav>("entdecken");
  const [query, setQuery] = useState("");
  const [segment, setSegment] = useState<"befehle" | "module">("befehle");
  const searchRef = useRef<HTMLInputElement>(null);
  const composerRef = useRef<HTMLInputElement>(null);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        searchRef.current?.focus();
        setNav("entdecken");
      }
      if (e.key === "/" && document.activeElement?.tagName !== "INPUT" && document.activeElement?.tagName !== "TEXTAREA") {
        e.preventDefault();
        setQuery("/");
        setNav("befehle");
        window.setTimeout(() => searchRef.current?.focus(), 0);
      }
      if (e.key === "Escape") {
        e.preventDefault();
        setQuery("");
        setNav("entdecken");
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  useEffect(() => {
    const t = window.setTimeout(() => searchRef.current?.focus(), 80);
    return () => window.clearTimeout(t);
  }, []);
  const filtered = useMemo(() => filterCommands(query), [query]);
  const submit = (raw?: string) => {
    const input = (raw ?? query).trim();
    if (!input) return;
    const result = run(input);
    setQuery("");
    if (result.navigate) {
      const match = NAV.find((n) => n.panel === result.navigate);
      if (match) setNav(match.id);
    }
  };
  const selectNav = (id: OverlayNav) => {
    setNav(id);
    setAntwortZu(true);
    const item = NAV.find((n) => n.id === id);
    if (item?.panel) setPanel(item.panel);
  };
  const pageTitle =
    NAV.find((n) => n.id === nav)?.label ??
    "Entdecken";
  const badgeCount = state.freigaben.length + (state.stop ? 1 : 0);
  return (
    <div className="atmos-ov-stage" role="application" aria-label="AtmOS">
      <div className="atmos-ov">
              <aside className="atmos-ov__sidebar">
                <label className="atmos-ov__search">
                  <Search size={13} strokeWidth={2} aria-hidden />
                  <input
                    ref={searchRef}
                    value={query}
                    placeholder="Suchen"
                    onChange={(e) => {
                      setQuery(e.target.value);
                      if (e.target.value) setNav("befehle");
                    }}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        submit();
                      }
                    }}
                    aria-label="Befehle suchen"
                  />
                </label>
                <nav className="atmos-ov__nav" aria-label="Kategorien">
                  {NAV.map((item) => (
                    <button
                      key={item.id}
                      type="button"
                      className="atmos-ov__nav-item"
                      data-active={nav === item.id}
                      onClick={() => selectNav(item.id)}
                    >
                      <span className="atmos-ov__nav-icon">{item.icon}</span>
                      <span>{item.label}</span>
                      {item.id === "status" && badgeCount > 0 ? (
                        <span className="atmos-ov__badge">{badgeCount}</span>
                      ) : null}
                      {item.id === "einstellungen" ? (
                        <span className="atmos-ov__badge atmos-ov__badge--api">API</span>
                      ) : null}
                    </button>
                  ))}
                </nav>
                <div className="atmos-ov__profile">
                  <div className="atmos-ov__avatar" aria-hidden>
                    A
                  </div>
                  <div>
                    <strong>AtmOS</strong>
                    <span>KOORDINAT {KOORDINAT_VERSION}</span>
                  </div>
                </div>
              </aside>
              <section className="atmos-ov__main">
                <header className="atmos-ov__top">
                  <h2 className="atmos-ov__title">{pageTitle}</h2>
                  <button
                    type="button"
                    className="atmos-ov__close"
                    onClick={() => {
                      setQuery("");
                      setNav("entdecken");
                    }}
                    aria-label="Zurück zu Entdecken"
                  >
                    <X size={16} />
                  </button>
                </header>
                <div className="atmos-ov__scroll">
                  {nav === "entdecken" && (
                    <>
                      <div className="atmos-ov__features">
                        {FEATURED.map((f) => (
                          <button
                            key={f.cmd}
                            type="button"
                            className={`atmos-ov__feature ${TONE_CLASS[f.tone]}`}
                            onClick={() => {
                              if (f.cmd.trim().endsWith("/") || f.cmd.endsWith(" ")) {
                                setQuery(f.cmd);
                                setNav("befehle");
                                searchRef.current?.focus();
                              } else {
                                submit(f.cmd);
                              }
                            }}
                          >
                            <span className="atmos-ov__eyebrow">{f.eyebrow}</span>
                            <strong>{f.title}</strong>
                            <span>{f.subtitle}</span>
                            <code>{f.cmd.trim()}</code>
                          </button>
                        ))}
                      </div>
                      <div className="atmos-ov__section-head">
                        <h3>Tolle aktuelle Befehle</h3>
                        <button type="button" className="atmos-ov__link" onClick={() => setNav("befehle")}>
                          Alle anzeigen
                        </button>
                      </div>
                      <div className="atmos-ov__grid">
                        {(
                          ["effort", "stop", "fortsetzen", "suche", "install", "an", "aus", "liste", "vital"]
                            .map((id) => COMMANDS.find((c) => c.id === id))
                            .filter(Boolean) as CommandDef[]
                        ).map((c) => (
                          <CommandRow
                            key={c.id}
                            cmd={c}
                            onRun={submit}
                            onFill={(v) => {
                              setQuery(v);
                              setNav("befehle");
                            }}
                          />
                        ))}
                      </div>
                    </>
                  )}
                  {nav === "befehle" && (
                    <>
                      <p className="atmos-ov__lede">
                        {COMMANDS.length} AtmOS-Befehle – laden führt direkt aus, Tippen füllt die Eingabe. Alles ohne / ist ein Auftrag (/mach).
                      </p>
                      {COMMAND_GRUPPEN.map((g) => {
                        const liste = (query ? filtered : COMMANDS).filter((c) => c.gruppe === g);
                        if (!liste.length) return null;
                        return (
                          <div key={g}>
                            <h3 className="atmos-ov__group-label">{g}</h3>
                            <div className="atmos-ov__grid">
                              {liste.map((c) => (
                                <CommandRow key={c.id} cmd={c} onRun={submit} onFill={(v) => setQuery(v)} />
                              ))}
                            </div>
                          </div>
                        );
                      })}
                      {query && filtered.length === 0 && (
                        <p className="atmos-ov__empty">Keine Treffer für „{query}“.</p>
                      )}
                    </>
                  )}
                  {nav === "chat" && (
                    <>
                      <p className="atmos-ov__lede">
                        {stdKi ? <>Standard-KI: <strong>{kiKonfig(stdKi).name}</strong> · {kiKonfig(stdKi).modell} · Denktiefe {state.modellEffort}</> : "Noch keine KI verbunden – unter KIs einen Schlüssel eintragen oder Ollama einschalten."}
                        {" "}Schreib unten mit <code>/frage …</code>, an alle mit <code>/alle …</code>; <code>@gemini</code> oder <code>--effort max</code> gelten je Frage.
                      </p>
                      <div className="atmos-chat">
                        {state.gespraech.map((m, i) => (
                          <div key={i} className="atmos-chat__msg" data-rolle={m.role}>
                            {m.role === "assistant" && m.anbieter ? <span className="atmos-ov__meta">{kiKonfig(m.anbieter).name}</span> : null}
                            {m.content}
                          </div>
                        ))}
                        {state.gespraech.length === 0 && <p className="atmos-ov__empty">Noch kein Gespräch.</p>}
                      </div>
                      <div className="atmos-ki__aktionen">
                        <button type="button" className="atmos-ov__pill" onClick={() => { setQuery("/frage "); window.setTimeout(() => composerRef.current?.focus(), 0); }}>Fragen</button>
                        <button type="button" className="atmos-ov__pill" onClick={() => { setQuery("/alle "); window.setTimeout(() => composerRef.current?.focus(), 0); }}>Alle fragen</button>
                        <button type="button" className="atmos-ov__pill-ghost" onClick={() => submit("/neu")}>Gespräch leeren</button>
                        <button type="button" className="atmos-ov__pill-ghost" onClick={() => selectNav("kis")}>KIs verwalten</button>
                      </div>
                    </>
                  )}
                  {nav === "kis" && <KiPanel />}
                  {nav === "katalog" && <KatalogPanel />}
                  {nav === "referenz" && <ReferenzPanel onTippen={(b) => { setQuery(`${b} `); composerRef.current?.focus(); }} />}
                  {nav === "module" && (
                    <>
                      <div className="atmos-ov__section-head">
                        <h3>Eingebettete Module</h3>
                        <button type="button" className="atmos-ov__link" onClick={() => submit("/suche ki agent")}>
                          Suchen
                        </button>
                      </div>
                      <div className="atmos-ov__grid atmos-ov__grid--modules">
                        {state.module.map((m) => (
                          <div key={m.id} className="atmos-ov__row">
                            <div className="atmos-ov__squircle" data-id="module" aria-hidden>
                              <Boxes size={20} />
                            </div>
                            <div className="atmos-ov__row-text">
                              <strong>{m.name}</strong>
                              <span>
                                {m.kategorie} · Score {m.score} · {m.status.toUpperCase()}
                              </span>
                            </div>
                            <div className="atmos-ov__row-actions">
                              <button
                                type="button"
                                className="atmos-ov__pill atmos-ov__pill--blue"
                                onClick={() => submit(m.status === "an" ? `/aus ${m.name}` : `/an ${m.name}`)}
                              >
                                {m.status === "an" ? "AUS" : "AN"}
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    </>
                  )}
                  {nav === "arbeit" && (
                    <>
                      <div className="atmos-ov__features atmos-ov__features--two">
                        <button
                          type="button"
                          className="atmos-ov__feature atmos-ov__feature--copper"
                          onClick={() => {
                            setQuery("/mach ");
                            searchRef.current?.focus();
                          }}
                        >
                          <span className="atmos-ov__eyebrow">AUFTRAG</span>
                          <strong>Neuen Lauf starten</strong>
                          <span>Freier Auftrag mit Freigabe-Stops</span>
                          <code>/mach …</code>
                        </button>
                        <button
                          type="button"
                          className="atmos-ov__feature atmos-ov__feature--blue"
                          onClick={() => submit("/lauf dokumente")}
                        >
                          <span className="atmos-ov__eyebrow">VORLAGE</span>
                          <strong>Dokumente-Ablauf</strong>
                          <span>Bewährte Schritte aus dem Katalog</span>
                          <code>/lauf dokumente</code>
                        </button>
                      </div>
                      <div className="atmos-ov__section-head">
                        <h3>Letzte Spur</h3>
                        <button type="button" className="atmos-ov__link" onClick={() => submit("/trace")}>
                          /trace
                        </button>
                      </div>
                      <ul className="atmos-ov__settings">
                        {state.trace.slice(0, 6).map((t) => (
                          <li key={t.id}>
                            <span className="atmos-ov__settings-icon" data-tone="trace">
                              <Terminal size={14} />
                            </span>
                            <div>
                              <strong>{t.text}</strong>
                              <span>{t.art}</span>
                            </div>
                          </li>
                        ))}
                        {state.trace.length === 0 && <li className="atmos-ov__empty-row">Noch keine Spur.</li>}
                      </ul>
                    </>
                  )}
                  {nav === "kristalle" && (
                    <>
                      <div className="atmos-ov__section-head">
                        <h3>Kristall-Regal</h3>
                        <button type="button" className="atmos-ov__link" onClick={() => submit("/kristall")}>
                          Aktualisieren
                        </button>
                      </div>
                      <div className="atmos-ov__grid">
                        {state.kristalle.map((k) => (
                          <div key={k.id} className="atmos-ov__row">
                            <div className="atmos-ov__squircle" data-id="kristall" aria-hidden>
                              <Gem size={20} />
                            </div>
                            <div className="atmos-ov__row-text">
                              <strong>
                                {k.art} · {k.titel}
                              </strong>
                              <span>
                                {k.status} · {k.treffer} Treffer
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </>
                  )}
                  {nav === "verfassung" && (
                    <>
                      <p className="atmos-ov__lede">Geschützter Kern – Mensch hält den Schlüssel.</p>
                      <h3 className="atmos-ov__group-label">Gesetze</h3>
                      <ul className="atmos-ov__settings">
                        {[
                          ["1", "Rechne nie zweimal"],
                          ["9", "Mensch hält den Schlüssel"],
                          ["R1", "STOP wirkt immer"],
                          ["R7", "Fremdcode nur lesen"],
                        ].map(([nr, title]) => (
                          <li key={nr}>
                            <span className="atmos-ov__settings-icon" data-tone="law">
                              {nr}
                            </span>
                            <div>
                              <strong>{title}</strong>
                              <span>Verfassung · {nr}</span>
                            </div>
                            <span className="atmos-ov__chevron" aria-hidden>
                              ›
                            </span>
                          </li>
                        ))}
                      </ul>
                      <button type="button" className="atmos-ov__link atmos-ov__link--block" onClick={() => submit("/verfassung")}>
                        Volle Verfassung anzeigen
                      </button>
                    </>
                  )}
                  {nav === "status" && (
                    <>
                      <h3 className="atmos-ov__group-label">System</h3>
                      <ul className="atmos-ov__settings">
                        <li>
                          <span className="atmos-ov__settings-icon" data-tone="pulse">
                            <HeartPulse size={14} />
                          </span>
                          <div>
                            <strong>Puls {state.puls}</strong>
                            <span>Modus {state.modus}</span>
                          </div>
                        </li>
                        <li>
                          <span className="atmos-ov__settings-icon" data-tone="effort">
                            {state.effort}
                          </span>
                          <div>
                            <strong>
                              Stufe {state.effort} · {EFFORT_LABELS[state.effort]}
                            </strong>
                            <span>Router-Cap</span>
                          </div>
                        </li>
                        <li>
                          <span className="atmos-ov__settings-icon" data-tone={state.stop ? "stop" : "ok"}>
                            {state.stop ? "!" : "✓"}
                          </span>
                          <div>
                            <strong>STOP {state.stop ? "AN" : "aus"}</strong>
                            <span>{state.stop ? "Nur /fortsetzen möglich" : "System läuft"}</span>
                          </div>
                          <button
                            type="button"
                            className="atmos-ov__pill"
                            onClick={() => submit(state.stop ? "/fortsetzen" : "/stop")}
                          >
                            {state.stop ? "Fortsetzen" : "Stop"}
                          </button>
                        </li>
                        <li>
                          <span className="atmos-ov__settings-icon" data-tone={kis.some((k) => k.bereit) ? "ok" : "effort"}>
                            <Bot size={14} />
                          </span>
                          <div>
                            <strong>{kis.filter((k) => k.bereit).length} von {kis.length} KIs bereit</strong>
                            <span>Standard {stdKi ?? "–"} · Denktiefe {state.modellEffort}</span>
                          </div>
                          <button type="button" className="atmos-ov__pill" onClick={() => selectNav("kis")}>KIs</button>
                        </li>
                        {pendingFreigabe && (
                          <li>
                            <span className="atmos-ov__settings-icon" data-tone="warn">
                              !
                            </span>
                            <div>
                              <strong>{pendingFreigabe.titel}</strong>
                              <span>Freigabe wartet</span>
                            </div>
                          </li>
                        )}
                      </ul>
                      <button type="button" className="atmos-ov__link atmos-ov__link--block" onClick={() => submit("/vital")}>
                        Vitalitätsbericht
                      </button>
                    </>
                  )}
                  {nav === "einstellungen" && <SettingsPanel onSaved={() => refreshGoogle()} />}
                  {nav === "account" && (
                    <>
                      <div className="atmos-ov__section-head">
                        <h3>Meine Apps</h3>
                      </div>
                      <div className="atmos-ov__segment" role="tablist" aria-label="Account Filter">
                        <button
                          type="button"
                          role="tab"
                          aria-selected={segment === "befehle"}
                          data-active={segment === "befehle"}
                          onClick={() => setSegment("befehle")}
                        >
                          Befehle
                        </button>
                        <button
                          type="button"
                          role="tab"
                          aria-selected={segment === "module"}
                          data-active={segment === "module"}
                          onClick={() => setSegment("module")}
                        >
                          Module
                        </button>
                      </div>
                      <div className="atmos-ov__grid atmos-ov__grid--account">
                        {segment === "befehle"
                          ? COMMANDS.slice(0, 8).map((c) => (
                              <div key={c.id} className="atmos-ov__account-item">
                                <div className="atmos-ov__squircle atmos-ov__squircle--lg" data-id={c.id}>
                                  {ICON_FOR[c.id] ?? <Terminal size={22} />}
                                </div>
                                <div className="atmos-ov__row-text">
                                  <strong>{c.label}</strong>
                                  <span>{c.beschreibung}</span>
                                  <span className="atmos-ov__meta">{c.usage}</span>
                                </div>
                                <button type="button" className="atmos-ov__pill atmos-ov__pill--blue" onClick={() => submit(c.usage)}>
                                  Öffnen
                                </button>
                              </div>
                            ))
                          : state.module.map((m) => (
                              <div key={m.id} className="atmos-ov__account-item">
                                <div className="atmos-ov__squircle atmos-ov__squircle--lg" data-id="module">
                                  <Boxes size={22} />
                                </div>
                                <div className="atmos-ov__row-text">
                                  <strong>{m.name}</strong>
                                  <span>{m.zweck}</span>
                                  <span className="atmos-ov__meta">
                                    {m.status.toUpperCase()} · ★ {m.sterne.toLocaleString("de")}
                                  </span>
                                </div>
                                <button
                                  type="button"
                                  className="atmos-ov__pill atmos-ov__pill--blue"
                                  onClick={() => submit(`/liste`)}
                                >
                                  Öffnen
                                </button>
                              </div>
                            ))}
                      </div>
                    </>
                  )}
                </div>
                {(denkt || (lastResult && !antwortZu)) && (
                  <div className="atmos-antwort" data-ok={lastResult?.ok ?? true} aria-live="polite">
                    <div className="atmos-antwort__kopf">
                      <span>{denkt ? "KI denkt …" : lastResult?.ok ? "Antwort" : "Hinweis"}</span>
                      {!denkt && lastResult && (
                        <span>
                          <button type="button" className="atmos-ov__pill-ghost" onClick={() => void navigator.clipboard?.writeText(lastResult.message).catch(() => undefined)}>Kopieren</button>
                          <button type="button" className="atmos-ov__close" onClick={() => setAntwortZu(true)} aria-label="Antwort schließen"><X size={14} /></button>
                        </span>
                      )}
                    </div>
                    {lastResult && <pre className="atmos-antwort__text">{lastResult.message}</pre>}
                    {denkt && <div className="atmos-antwort__laden" aria-hidden />}
                  </div>
                )}
                <footer className="atmos-ov__composer">
                  <span className="atmos-ov__prompt" aria-hidden>
                    ›
                  </span>
                  <input
                    ref={composerRef}
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        submit();
                      }
                    }}
                    placeholder="Frag oder befiehl: /frage  /alle  /effort high  /katalog  /mach … – Enter"
                    aria-label="Befehl eingeben"
                    disabled={
                      state.stop &&
                      !query.startsWith("/fortsetzen") &&
                      !query.startsWith("/vital") &&
                      !query.startsWith("/hilfe") &&
                      !query.startsWith("/verfassung") &&
                      !query.startsWith("/stop")
                    }
                  />
                  <button type="button" className="atmos-ov__run" onClick={() => submit()}>
                    Laden
                  </button>
                </footer>
              </section>
      </div>
    </div>
  );
}
