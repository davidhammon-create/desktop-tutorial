import { EFFORT_LABELS, GESETZE, ROUTER_STUFEN, VERFASSUNG, ZYKLUS } from "./constants";
import { googleStatus } from "./google";
import { ABLAEUFE, KATALOG, KATEGORIEN, findeAblauf, freierAblauf, sucheKatalog } from "./katalog";
import { ANBIETER, MODELL_EFFORT, effortAusStufe, kiBereit, kiKonfig, kiUebersicht, leseEffort, type ModellEffort } from "./anbieter";
import { REFERENZ, WERKZEUGE, sucheReferenz } from "./befehle";
import { loadSecrets, providerConnection, saveSecrets } from "./secrets";
import { pushTrace } from "./store";
import type {
  AtmosState,
  CommandResult,
  FreigabeAnfrage,
  Lauf,
  Modul,
  RouterStufe,
} from "./types";
export type CommandGruppe = "KIs" | "Lösen" | "Finden" | "Module" | "System" | "Wissen";
export interface CommandDef {
  id: string;
  label: string;
  aliases: string[];
  beschreibung: string;
  usage: string;
  gruppe: CommandGruppe;
}
export const COMMAND_GRUPPEN: CommandGruppe[] = ["KIs", "Lösen", "Finden", "Module", "Wissen", "System"];
export const COMMANDS: CommandDef[] = [
  { id: "frage", label: "/frage", aliases: ["frage", "ask", "ki", "chat"], gruppe: "KIs", beschreibung: "Der Standard-KI eine Frage stellen (Gespräch läuft weiter)", usage: "/frage Erkläre RAG in 5 Sätzen" },
  { id: "alle", label: "/alle", aliases: ["alle", "vergleiche", "ensemble"], gruppe: "KIs", beschreibung: "Dieselbe Frage an alle verbundenen KIs – Antworten vergleichen", usage: "/alle Welche Vektordatenbank für 1 Mio. Dokumente?" },
  { id: "neu", label: "/neu", aliases: ["neu", "clear", "reset-chat"], gruppe: "KIs", beschreibung: "Gespräch mit der KI leeren", usage: "/neu" },
  { id: "anbieter", label: "/anbieter", aliases: ["anbieter", "kis", "provider"], gruppe: "KIs", beschreibung: "Alle 15 KI-Anbieter anzeigen oder Standard setzen", usage: "/anbieter anthropic" },
  { id: "modell", label: "/modell", aliases: ["modell", "model"], gruppe: "KIs", beschreibung: "Modell der Standard-KI setzen", usage: "/modell claude-opus-5-5" },
  { id: "modelle", label: "/modelle", aliases: ["modelle", "models"], gruppe: "KIs", beschreibung: "Aktuelle Modellliste direkt beim Anbieter holen", usage: "/modelle openai" },
  { id: "effort", label: "/effort", aliases: ["effort", "aufwand", "denken"], gruppe: "KIs", beschreibung: "Denktiefe (aus · low · medium · high · xhigh · max) oder Router-Stufe 0–6", usage: "/effort high" },
  { id: "mach", label: "/mach", aliases: ["mach", "lösen", "loesen"], gruppe: "Lösen", beschreibung: "Freien Auftrag planen und starten", usage: "/mach Website bauen" },
  { id: "lauf", label: "/lauf", aliases: ["lauf"], gruppe: "Lösen", beschreibung: "Ablauf-Vorlage starten", usage: "/lauf dokumente" },
  { id: "trace", label: "/trace", aliases: ["trace", "spur"], gruppe: "Lösen", beschreibung: "Spur der letzten Schritte", usage: "/trace" },
  { id: "suche", label: "/suche", aliases: ["suche", "search"], gruppe: "Finden", beschreibung: "Katalog + Google durchsuchen", usage: "/suche pdf table" },
  { id: "katalog", label: "/katalog", aliases: ["katalog", "repos"], gruppe: "Finden", beschreibung: `${KATALOG.length} geprüfte GitHub-Repos nach Kategorie`, usage: "/katalog MCP" },
  { id: "google", label: "/google", aliases: ["google", "gapi"], gruppe: "Finden", beschreibung: "Google CSE / Gemini-Suche (Einstellungen)", usage: "/google gemini sdk" },
  { id: "befehle", label: "/befehle", aliases: ["befehle", "referenz", "commands"], gruppe: "Wissen", beschreibung: `${REFERENZ.length} Befehle & Regler: Claude Code, Codex, Gemini CLI, Aider, Cursor, Ollama, APIs …`, usage: "/befehle effort" },
  { id: "erklaere", label: "/erklaere", aliases: ["erklaere", "erkläre", "explain"], gruppe: "Wissen", beschreibung: "Begriff erklären", usage: "/erklaere router" },
  { id: "install", label: "/install", aliases: ["install", "installiere"], gruppe: "Module", beschreibung: "Projekt einbetten (noch AUS)", usage: "/install owner/repo" },
  { id: "an", label: "/an", aliases: ["an", "enable"], gruppe: "Module", beschreibung: "Modul einschalten (Freigabe)", usage: "/an owner/repo" },
  { id: "aus", label: "/aus", aliases: ["aus", "disable"], gruppe: "Module", beschreibung: "Modul ausschalten", usage: "/aus owner/repo" },
  { id: "liste", label: "/liste", aliases: ["liste", "modules"], gruppe: "Module", beschreibung: "Eingebettete Module listen", usage: "/liste" },
  { id: "kristall", label: "/kristall", aliases: ["kristall", "kristalle"], gruppe: "Module", beschreibung: "Kristall-Bibliothek", usage: "/kristall" },
  { id: "vital", label: "/vital", aliases: ["vital", "puls"], gruppe: "System", beschreibung: "Puls, Modus, Hunger, verbundene KIs", usage: "/vital" },
  { id: "stop", label: "/stop", aliases: ["stop"], gruppe: "System", beschreibung: "Sofortiger Halt (Verfassung R1)", usage: "/stop" },
  { id: "fortsetzen", label: "/fortsetzen", aliases: ["fortsetzen", "weiter-system"], gruppe: "System", beschreibung: "STOP aufheben", usage: "/fortsetzen" },
  { id: "verfassung", label: "/verfassung", aliases: ["verfassung", "gesetze"], gruppe: "System", beschreibung: "Gesetze und Regeln zeigen", usage: "/verfassung" },
  { id: "hilfe", label: "/hilfe", aliases: ["hilfe", "help", "?"], gruppe: "System", beschreibung: "Alle Befehle nach Gruppen", usage: "/hilfe" },
];
/** Standard-KI: ausdrücklich gesetzt, sonst die erste bereite. */
export function standardKi(): string | null {
  const s = loadSecrets();
  if (s.standardKi && ANBIETER.some((a) => a.id === s.standardKi)) return s.standardKi;
  return kiUebersicht(s).find((a) => a.bereit)?.id ?? null;
}
/** Zieht --effort, --modell und @anbieter aus dem Text. */
export function leseFrageOptionen(args: string): { text: string; anbieter?: string; modell?: string; effort?: ModellEffort } {
  let text = args;
  const o: { anbieter?: string; modell?: string; effort?: ModellEffort } = {};
  text = text.replace(/--effort\s+(\S+)/i, (_, e: string) => {
    const x = leseEffort(e);
    if (x) o.effort = x;
    return "";
  });
  text = text.replace(/--modell\s+(\S+)/i, (_, m: string) => {
    o.modell = m;
    return "";
  });
  text = text.replace(/(^|\s)@([a-z]+)\b/i, (all, pre: string, id: string) => {
    if (ANBIETER.some((a) => a.id === id.toLowerCase())) {
      o.anbieter = id.toLowerCase();
      return pre;
    }
    return all;
  });
  return { text: text.replace(/\s+/g, " ").trim(), ...o };
}
function uid(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
}
function parseCommand(input: string): { cmd: string; args: string } {
  const t = input.trim();
  const withoutSlash = t.startsWith("/") ? t.slice(1) : t;
  const sp = withoutSlash.indexOf(" ");
  if (sp < 0) return { cmd: withoutSlash.toLowerCase(), args: "" };
  return { cmd: withoutSlash.slice(0, sp).toLowerCase(), args: withoutSlash.slice(sp + 1).trim() };
}
function matchCommand(cmd: string): CommandDef | undefined {
  return COMMANDS.find((c) => c.id === cmd || c.aliases.includes(cmd) || c.label.slice(1) === cmd);
}
function freigabe(
  art: FreigabeAnfrage["art"],
  titel: string,
  beschreibung: string,
  payload?: Record<string, unknown>,
): FreigabeAnfrage {
  return { id: uid("fg"), art, titel, beschreibung, payload, erstellt: Date.now() };
}
function startLauf(state: AtmosState, vorlage: ReturnType<typeof freierAblauf>, quelle: string): { state: AtmosState; lauf: Lauf; result: CommandResult } {
  if (state.stop) {
    return {
      state,
      lauf: null as unknown as Lauf,
      result: { ok: false, message: "STOP ist gesetzt. /fortsetzen hebt auf." },
    };
  }
  const lauf: Lauf = {
    id: uid("lauf"),
    titel: vorlage.titel,
    ziel: vorlage.ziel,
    ablaufId: vorlage.id,
    schritt: 0,
    stand: "laeuft",
    schritte: vorlage.schritte,
    quelle,
    gestartet: Date.now(),
  };
  let next = pushTrace(state, {
    laufId: lauf.id,
    art: "plan",
    text: `${vorlage.titel} · ${vorlage.schritte.length} Schritte`,
    erklaerung: `Quelle: ${quelle} · Effort-Cap Stufe ${state.effort}`,
    stufe: Math.min(state.effort, 3) as RouterStufe,
    cent: 0,
  });
  // Advance first non-freigabe steps until halt or effort-limited demo step
  let schritt = 0;
  const maxAuto = Math.min(2, vorlage.schritte.length);
  while (schritt < maxAuto) {
    const s = vorlage.schritte[schritt];
    const stufe = Math.min(state.effort, (s.stufe + 2) as RouterStufe) as RouterStufe;
    next = pushTrace(next, {
      laufId: lauf.id,
      art: "schritt",
      text: `${schritt + 1}/${vorlage.schritte.length} ${s.titel}`,
      erklaerung: s.erklaerung,
      stufe,
      modell: stufe >= 4 ? (stufe >= 5 ? "groß" : "klein") : "lokal",
      cent: stufe >= 4 ? stufe * 0.4 : 0,
    });
    next = pushTrace(next, {
      laufId: lauf.id,
      art: "ergebnis",
      text: demoErgebnis(s.art, vorlage.ziel || s.text),
      stufe,
      cent: 0,
    });
    schritt += 1;
    if (s.art === "freigabe") break;
  }
  lauf.schritt = schritt;
  const nextStep = vorlage.schritte[schritt];
  if (nextStep?.art === "freigabe" || schritt < vorlage.schritte.length) {
    lauf.stand = "halt";
    next = pushTrace(next, {
      laufId: lauf.id,
      art: "halt",
      text: `Wartet auf Freigabe bei Schritt ${schritt + 1}`,
      erklaerung: "Mensch hält den Schlüssel (Gesetz 9).",
      cent: 0,
    });
    const fg = freigabe(
      "lauf_weiter",
      `Lauf fortsetzen: ${lauf.titel}`,
      `Schritt ${schritt + 1}/${vorlage.schritte.length} freigeben?`,
      { laufId: lauf.id },
    );
    next = { ...next, laeufe: [lauf, ...next.laeufe], freigaben: [fg, ...next.freigaben] };
    return {
      state: next,
      lauf,
      result: {
        ok: true,
        message: `Lauf ${lauf.id} gestartet – hält bei Schritt ${schritt + 1}. Freigabe nötig.`,
        needsFreigabe: fg,
      },
    };
  }
  lauf.stand = "fertig";
  next = {
    ...pushTrace(next, { laufId: lauf.id, art: "ende", text: "fertig", cent: 0 }),
    laeufe: [lauf, ...next.laeufe],
  };
  return { state: next, lauf, result: { ok: true, message: `Lauf ${lauf.id} fertig.` } };
}
function demoErgebnis(art: string, ziel: string): string {
  switch (art) {
    case "klaeren":
      return `Ziel: ${ziel.slice(0, 120)}`;
    case "erkunden":
      return sucheKatalog(ziel, 3)
        .map((t) => `${t.score} ${t.name}`)
        .join(" · ") || "keine Treffer";
    case "erklaeren":
      return "Kontextfenster begrenzt → holen statt kippen.";
    case "entwerfen":
      return "Variante B gewählt (billigster korrekter Weg).";
    case "bauen":
      return "Kleinster lauffähiger Stand erzeugt (Demo).";
    case "schreiben":
      return "Skript-Entwurf in Szenen (Demo).";
    case "pruefen":
      return "Prüfung gegen Ziel → OK mit Vorbehalt.";
    case "freigabe":
      return "Freigabe angefordert.";
    default:
      return `Schritt ${art} ausgeführt (Demo).`;
  }
}
export function executeCommand(state: AtmosState, input: string): { state: AtmosState; result: CommandResult } {
  const trimmed = input.trim();
  if (!trimmed) return { state, result: { ok: false, message: "Leerer Befehl." } };
  // Natural language without slash ? mach
  const isSlash = trimmed.startsWith("/") || matchCommand(parseCommand(trimmed).cmd);
  if (!trimmed.startsWith("/") && !isSlash) {
    return executeCommand(state, `/mach ${trimmed}`);
  }
  const { cmd, args } = parseCommand(trimmed);
  const def = matchCommand(cmd);
  if (!def) {
    return {
      state: pushTrace(state, {
        laufId: null,
        art: "fehler",
        text: `Unbekannter Befehl: ${cmd}`,
        erklaerung: "Tippe /hilfe für die Speisekarte.",
        cent: 0,
      }),
      result: { ok: false, message: `Unbekannt: ${cmd}. /hilfe zeigt alles.` },
    };
  }
  if (state.stop && def.id !== "fortsetzen" && def.id !== "vital" && def.id !== "hilfe" && def.id !== "verfassung" && def.id !== "stop") {
    return { state, result: { ok: false, message: "STOP gesetzt. Nur /fortsetzen, /vital, /hilfe." } };
  }
  let next: AtmosState = { ...state, lastCommand: def.id };
  switch (def.id) {
    case "hilfe": {
      const menu = COMMAND_GRUPPEN.map(
        (g) => `${g}\n${COMMANDS.filter((c) => c.gruppe === g).map((c) => `  ${c.label.padEnd(12)} ${c.beschreibung}`).join("\n")}`,
      ).join("\n\n");
      const tipp = "\n\nOhne / geschrieben = /mach. @anbieter und --effort gelten in /frage, z. B. /frage @gemini --effort max …";
      next = pushTrace(next, { laufId: null, art: "ergebnis", text: "Befehlsspeisekarte", erklaerung: menu, cent: 0 });
      return { state: next, result: { ok: true, message: menu + tipp } };
    }
    case "effort": {
      const arg = args.trim();
      const me = leseEffort(arg);
      if (me) {
        next = { ...next, modellEffort: me };
        next = pushTrace(next, { laufId: null, art: "werkzeug", text: `Modell-Effort → ${me}`, erklaerung: "Gilt für alle KIs; je Anbieter übersetzt.", cent: 0 });
        return { state: next, result: { ok: true, message: `Denktiefe der Modelle: ${me}. Übersetzt: Claude output_config.effort, OpenAI reasoning_effort, Gemini thinkingBudget, OpenRouter reasoning.effort.` } };
      }
      const n = Number(arg);
      if (!arg || !Number.isFinite(n) || n < 0 || n > 6) {
        return {
          state: next,
          result: {
            ok: !arg,
            message: `Denktiefe: ${next.modellEffort} · Router-Stufe: ${next.effort} (${EFFORT_LABELS[next.effort]})\n` +
              `/effort ${MODELL_EFFORT.join(" | ")}   Denktiefe der Modelle\n/effort 0–6   Router-Stufe der Kaskade (6 = alle KIs)`,
          },
        };
      }
      const stufe = Math.round(n) as RouterStufe;
      next = { ...next, effort: stufe };
      next = pushTrace(next, {
        laufId: null,
        art: "werkzeug",
        text: `Router → Stufe ${stufe} (${EFFORT_LABELS[stufe]})`,
        erklaerung: ROUTER_STUFEN[stufe].name,
        stufe,
        cent: 0,
      });
      return {
        state: next,
        result: { ok: true, message: `Router-Stufe ${stufe}: ${ROUTER_STUFEN[stufe].name}. Modelle denken mit „${next.modellEffort}“ (ohne eigene Angabe: ${effortAusStufe(stufe)}).` },
      };
    }
    case "frage":
    case "alle": {
      const o = leseFrageOptionen(args);
      if (!o.text) return { state: next, result: { ok: false, message: `Was soll ich fragen?  ${def.usage}` } };
      const effort = o.effort ?? next.modellEffort;
      if (def.id === "alle") {
        const bereit = kiUebersicht().filter((a) => a.bereit);
        if (!bereit.length) return { state: next, result: { ok: false, message: "Keine KI verbunden. Navigation → KIs → Schlüssel eintragen.", navigate: "kis" } };
        next = pushTrace(next, { laufId: null, art: "plan", text: `Ensemble: ${bereit.length} KIs`, erklaerung: o.text, stufe: 6, cent: 0 });
        return { state: next, result: { ok: true, message: `Frage an ${bereit.map((a) => a.name).join(", ")} …`, async: { art: "alle", text: o.text, effort } } };
      }
      const ki = o.anbieter ?? standardKi();
      if (!ki) return { state: next, result: { ok: false, message: "Keine KI verbunden. Navigation → KIs → Schlüssel eintragen (Ollama lokal geht ohne).", navigate: "kis" } };
      if (!kiBereit(ki)) return { state: next, result: { ok: false, message: `${kiKonfig(ki).name} ist nicht bereit: Schlüssel oder Modell fehlt (Navigation → KIs).`, navigate: "kis" } };
      return { state: next, result: { ok: true, message: `${kiKonfig(ki).name} denkt (${effort}) …`, async: { art: "frage", text: o.text, anbieter: ki, modell: o.modell, effort, gespraech: true } } };
    }
    case "neu": {
      next = { ...next, gespraech: [] };
      return { state: next, result: { ok: true, message: "Gespräch geleert." } };
    }
    case "anbieter": {
      const id = args.trim().toLowerCase();
      if (id) {
        if (!ANBIETER.some((a) => a.id === id)) return { state: next, result: { ok: false, message: `Unbekannt: ${id}. Bekannt: ${ANBIETER.map((a) => a.id).join(", ")}` } };
        saveSecrets({ standardKi: id });
        return { state: next, result: { ok: true, message: `Standard-KI: ${kiKonfig(id).name}${kiBereit(id) ? "" : " – noch nicht bereit (Schlüssel/Modell in KIs eintragen)"}.` } };
      }
      const std = standardKi();
      const lines = kiUebersicht().map((a) => `${a.id === std ? "★" : " "} ${a.bereit ? "bereit" : "  –   "}  ${a.id.padEnd(11)} ${a.modell || "(kein Modell)"}${a.effort ? `   Effort: ${a.effort}` : ""}`).join("\n");
      return { state: next, result: { ok: true, message: `${lines}\n\n★ = Standard · /anbieter <id> setzt den Standard`, navigate: "kis" } };
    }
    case "modell": {
      const ki = standardKi();
      if (!ki) return { state: next, result: { ok: false, message: "Erst eine KI verbinden (Navigation → KIs).", navigate: "kis" } };
      const m = args.trim();
      if (!m) return { state: next, result: { ok: true, message: `${kiKonfig(ki).name}: ${kiKonfig(ki).modell}. /modelle zeigt die verfügbaren.` } };
      const s = loadSecrets();
      saveSecrets({ ki: { ...s.ki, [ki]: { ...(s.ki[ki] ?? {}), modell: m } } });
      return { state: next, result: { ok: true, message: `${kiKonfig(ki).name} nutzt jetzt ${m}.` } };
    }
    case "modelle": {
      const ki = args.trim().toLowerCase() || standardKi();
      if (!ki || !ANBIETER.some((a) => a.id === ki)) return { state: next, result: { ok: false, message: "Anbieter angeben: /modelle openai", navigate: "kis" } };
      return { state: next, result: { ok: true, message: `Hole Modelle von ${kiKonfig(ki).name} …`, async: { art: "modelle", anbieter: ki } } };
    }
    case "befehle": {
      const w = WERKZEUGE.find((x) => x.toLowerCase() === args.trim().toLowerCase());
      const treffer = w ? sucheReferenz("", w) : sucheReferenz(args);
      const msg = treffer.length
        ? treffer.slice(0, 40).map((r) => `[${r.werkzeug} · ${r.gruppe}] ${r.befehl}\n    ${r.was}`).join("\n") + (treffer.length > 40 ? `\n… ${treffer.length - 40} weitere im Bereich „Referenz“` : "")
        : `Nichts zu „${args}“. Werkzeuge: ${WERKZEUGE.join(", ")}`;
      return { state: next, result: { ok: treffer.length > 0, message: msg, navigate: "referenz" } };
    }
    case "katalog": {
      const q = args.trim().toLowerCase();
      const kat = KATEGORIEN.find((k) => k.toLowerCase().startsWith(q));
      const liste = q ? (kat ? KATALOG.filter((k) => k.kategorie === kat) : sucheKatalog(q, 25).map((t) => KATALOG.find((k) => k.repo === t.name)!)) : [];
      const msg = q
        ? liste.map((k) => `${k.repo.padEnd(40)} ★${(k.sterne ?? 0).toLocaleString("de")}  ${k.lizenz ?? "keine"}  ${k.zweck}`).join("\n") || "keine Treffer"
        : `${KATALOG.length} geprüfte Repos in ${KATEGORIEN.length} Kategorien:\n${KATEGORIEN.map((k) => `  ${k} (${KATALOG.filter((x) => x.kategorie === k).length})`).join("\n")}`;
      return { state: next, result: { ok: true, message: msg, navigate: "katalog" } };
    }
    case "stop": {
      next = { ...next, stop: true, modus: "sicher" };
      next = pushTrace(next, { laufId: null, art: "halt", text: "STOP gesetzt", erklaerung: "R1 Abschaltbar – sofort.", cent: 0 });
      return { state: next, result: { ok: true, message: "STOP gesetzt. Alle Läufe pausiert." } };
    }
    case "fortsetzen": {
      next = { ...next, stop: false };
      next = pushTrace(next, { laufId: null, art: "ende", text: "STOP aufgehoben", cent: 0 });
      return { state: next, result: { ok: true, message: "Stop-Marke entfernt." } };
    }
    case "suche":
    case "google": {
      const q = args || "ki agent";
      const treffer = sucheKatalog(q, 8);
      const g = googleStatus();
      const lines = treffer.map((t) => `${t.score.toString().padStart(3)} ${t.name} ★${t.sterne.toLocaleString("de")} ${t.lizenz}`).join("\n");
      const header = `Katalog ${treffer.length} · Google ${g.mode} (${g.source})${g.appleIntelligence ? " · Apple Intelligence an" : ""}`;
      const msg = `${header}\n${lines || "keine Katalog-Treffer"}\n(Live-Google folgt async, wenn Key in Einstellungen)`;
      next = pushTrace(next, {
        laufId: null,
        art: "ergebnis",
        text: `Suche: ${q} · ${treffer.length} Katalog`,
        erklaerung: msg,
        stufe: 1,
        cent: 0,
      });
      return { state: next, result: { ok: true, message: msg, navigate: "module" } };
    }
    case "install": {
      const name = args.trim();
      if (!name.includes("/")) {
        return { state: next, result: { ok: false, message: "Usage: /install owner/repo" } };
      }
      if (next.module.some((m) => m.name === name)) {
        return { state: next, result: { ok: false, message: `${name} ist schon eingebettet.` } };
      }
      const hit = sucheKatalog(name, 1)[0];
      const fg = freigabe(
        "install",
        `Einbetten: ${name}`,
        `Modul wird als Daten eingebettet (Status AUS). Fremdcode wird nicht ausgeführt.`,
        { name, score: hit?.score ?? 60 },
      );
      next = { ...next, freigaben: [fg, ...next.freigaben] };
      next = pushTrace(next, {
        laufId: null,
        art: "halt",
        text: `Freigabe für Installation: ${name}`,
        erklaerung: "Gesetz 9 – Mensch hält den Schlüssel.",
        cent: 0,
      });
      return { state: next, result: { ok: true, message: `Freigabe angefordert für ${name}.`, needsFreigabe: fg } };
    }
    case "an":
    case "aus": {
      const name = args.trim();
      const mod = next.module.find((m) => m.name === name || m.name.endsWith(name));
      if (!mod) return { state: next, result: { ok: false, message: `Modul nicht gefunden: ${name}` } };
      if (def.id === "aus") {
        next = {
          ...next,
          module: next.module.map((m) => (m.id === mod.id ? { ...m, status: "aus" as const } : m)),
        };
        next = pushTrace(next, { laufId: null, art: "werkzeug", text: `${mod.name} AUS`, cent: 0 });
        return { state: next, result: { ok: true, message: `${mod.name} ausgeschaltet.`, navigate: "module" } };
      }
      const fg = freigabe("modul_an", `Modul AN: ${mod.name}`, `Score ${mod.score}, Lizenz ${mod.lizenz}. Einschalten?`, {
        modulId: mod.id,
      });
      next = { ...next, freigaben: [fg, ...next.freigaben] };
      return { state: next, result: { ok: true, message: `Freigabe für AN: ${mod.name}`, needsFreigabe: fg } };
    }
    case "liste": {
      const lines = next.module
        .map((m) => `${m.status === "an" ? "AN " : "aus"} ${m.name} Score ${m.score} Vital ${m.vital}`)
        .join("\n");
      return { state: next, result: { ok: true, message: lines || "keine Module", navigate: "module" } };
    }
    case "vital": {
      const hunger = next.hunger.map((h) => `${h.problemtyp} ×${h.ungeloest}`).join(", ") || "–";
      const g = googleStatus();
      const apple = providerConnection("apple-intelligence");
      const kis = kiUebersicht().filter((a) => a.bereit).map((a) => a.id);
      const msg = `Puls ${next.puls} · Modus ${next.modus} · Ampel ${next.ampel} · Kosten ${next.kostenCent.toFixed(1)} ct / ${next.budgetCent} ct\n` +
        `KIs bereit: ${kis.join(", ") || "keine"} · Standard ${standardKi() ?? "–"} · Denktiefe ${next.modellEffort} · Router-Stufe ${next.effort}\n` +
        `Hunger: ${hunger}\nSiegel: ${next.siegel} · STOP ${next.stop ? "AN" : "aus"}\n` +
        `Google: ${g.mode} (${g.source}) · Gemini ${g.geminiReady ? "an" : "aus"} · CSE ${g.searchReady ? "an" : "aus"}\nApple Intelligence: ${apple.label}`;
      next = pushTrace(next, { laufId: null, art: "ergebnis", text: "Vitalitätsbericht", erklaerung: msg, cent: 0 });
      return { state: next, result: { ok: true, message: msg, navigate: "status" } };
    }
    case "kristall": {
      const lines = next.kristalle
        .map((k) => `${k.art} [${k.status}] ${k.titel} · ${k.treffer} Treffer`)
        .join("\n");
      return { state: next, result: { ok: true, message: lines, navigate: "kristalle" } };
    }
    case "verfassung": {
      const g = GESETZE.map((x) => `${x.nr}. ${x.titel}`).join("\n");
      const r = VERFASSUNG.map((x) => `${x.id} ${x.titel}`).join("\n");
      const msg = `9 Gesetze\n${g}\n\nVerfassung\n${r}`;
      return { state: next, result: { ok: true, message: msg, navigate: "verfassung" } };
    }
    case "erklaere": {
      const begriff = args || "router";
      const erklaerungen: Record<string, string> = {
        router: "Die Kaskade Stufen 0–6: jede Anfrage steigt nur bei Unsicherheit. Nutzen = P·Wert − Kosten − λ·Zeit. Stufe 6 = Ensemble: alle verbundenen KIs.",
        kristall: "Geprüftes Wissen (K1–K5), das ohne Credits läuft: Antwort, Regel, Funktion, Workflow, Makro.",
        vitalitaet: "Haushalt je Baustein. Puls = 0,5 · mittlere Vitalität + 0,5 · Erfolgsquote.",
        vitalität: "Haushalt je Baustein. Puls = 0,5 · mittlere Vitalität + 0,5 · Erfolgsquote.",
        verfassung: "Geschützter Kern: Stop wirkt immer, Mensch hält den Schlüssel, Fremdcode nur lesen.",
        hunger: "Ungelöste Problemtypen steuern die Suche nach Modulen.",
        zyklus: ZYKLUS.map((z) => `${z.nr}. ${z.name} – ${z.kurz}`).join("\n"),
        effort: "Zwei Regler: Denktiefe der Modelle (/effort aus|low|medium|high|xhigh|max – je Anbieter übersetzt: Claude output_config.effort, OpenAI reasoning_effort, Gemini thinkingBudget) und Router-Stufe 0–6 der Kaskade.",
      };
      const key = Object.keys(erklaerungen).find((k) => begriff.toLowerCase().includes(k)) ?? "router";
      const text = erklaerungen[key];
      next = pushTrace(next, { laufId: null, art: "ergebnis", text: `Erklärung: ${begriff}`, erklaerung: text, stufe: 0, cent: 0 });
      return { state: next, result: { ok: true, message: text } };
    }
    case "trace": {
      const lines = next.trace
        .slice(0, 12)
        .map((t) => `${new Date(t.zeit).toLocaleTimeString()} ${t.art.padEnd(9)} ${t.text}`)
        .join("\n");
      return { state: next, result: { ok: true, message: lines, navigate: "arbeit" } };
    }
    case "lauf": {
      const id = args.trim() || "dokumente";
      const exact = ABLAEUFE.find((a) => a.id === id) ?? null;
      const plan = exact ?? findeAblauf(id) ?? freierAblauf(id);
      const { state: s2, result } = startLauf(next, plan, exact ? `vorlage:${plan.id}` : "bausteine");
      return { state: s2, result: { ...result, navigate: "arbeit" } };
    }
    case "mach": {
      const auftrag = args || "Problem lösen";
      const vorlage = findeAblauf(auftrag) ?? freierAblauf(auftrag);
      const quelle = findeAblauf(auftrag) ? `vorlage:${vorlage.id}` : "bausteine";
      const { state: s2, result } = startLauf(next, { ...vorlage, ziel: auftrag }, quelle);
      const ki = standardKi();
      // Ab Router-Stufe 4 plant eine echte KI mit; Stufe 6 fragt alle verbundenen KIs (Ensemble)
      const planFrage = `Plane diesen Auftrag in höchstens 6 prüfbaren Schritten, je Schritt Werkzeug oder GitHub-Projekt, kurz und auf Deutsch:\n${auftrag}`;
      const plan =
        !next.stop && next.effort >= 6 && kiUebersicht().some((a) => a.bereit)
          ? { art: "alle" as const, text: planFrage, effort: next.modellEffort }
          : !next.stop && next.effort >= 4 && ki && kiBereit(ki)
            ? { art: "frage" as const, text: planFrage, anbieter: ki, effort: next.modellEffort }
            : undefined;
      return { state: s2, result: { ...result, navigate: "arbeit", async: plan } };
    }
    default:
      return { state: next, result: { ok: false, message: "Noch nicht implementiert." } };
  }
}
export function approveFreigabe(state: AtmosState, freigabeId: string): { state: AtmosState; result: CommandResult } {
  const fg = state.freigaben.find((f) => f.id === freigabeId);
  if (!fg) return { state, result: { ok: false, message: "Freigabe nicht gefunden." } };
  let next: AtmosState = {
    ...state,
    freigaben: state.freigaben.filter((f) => f.id !== freigabeId),
  };
  if (fg.art === "modul_an") {
    const modulId = fg.payload?.modulId as string;
    next = {
      ...next,
      module: next.module.map((m) => (m.id === modulId ? { ...m, status: "an" as const } : m)),
    };
    next = pushTrace(next, { laufId: null, art: "werkzeug", text: `Modul AN freigegeben`, erklaerung: fg.titel, cent: 0 });
    return { state: next, result: { ok: true, message: "Modul eingeschaltet." } };
  }
  if (fg.art === "install") {
    const name = String(fg.payload?.name ?? "");
    const score = Number(fg.payload?.score ?? 60);
    const neu: Modul = {
      id: uid("mod"),
      name,
      zweck: "Eingebettet aus GitHub-Suche (Demo)",
      kategorie: "Import",
      score,
      lizenz: "MIT",
      lizenzklasse: "frei",
      sicherheit: "ok",
      status: "aus",
      sterne: 1000,
      url: `https://github.com/${name}`,
      vital: 50,
      eingebettet: Date.now(),
    };
    next = { ...next, module: [neu, ...next.module] };
    next = pushTrace(next, {
      laufId: null,
      art: "ergebnis",
      text: `${name} eingebettet (AUS)`,
      erklaerung: "R7 Fremdcode nur lesen. Mensch schaltet AN.",
      cent: 0,
    });
    return { state: next, result: { ok: true, message: `${name} eingebettet – Status AUS.`, navigate: "module" } };
  }
  if (fg.art === "lauf_weiter") {
    const laufId = String(fg.payload?.laufId ?? "");
    const lauf = next.laeufe.find((l) => l.id === laufId);
    if (!lauf) return { state: next, result: { ok: false, message: "Lauf nicht gefunden." } };
    let schritt = lauf.schritt;
    let sState = next;
    const max = Math.min(lauf.schritte.length, schritt + 2);
    while (schritt < max) {
      const s = lauf.schritte[schritt];
      sState = pushTrace(sState, {
        laufId,
        art: "schritt",
        text: `${schritt + 1}/${lauf.schritte.length} ${s.titel}`,
        erklaerung: s.erklaerung,
        stufe: Math.min(sState.effort, 3) as RouterStufe,
        cent: 0.2,
      });
      sState = pushTrace(sState, {
        laufId,
        art: "ergebnis",
        text: demoErgebnis(s.art, lauf.ziel || s.text),
        cent: 0,
      });
      schritt += 1;
      if (s.art === "freigabe") break;
    }
    const fertig = schritt >= lauf.schritte.length;
    const updated: Lauf = {
      ...lauf,
      schritt,
      stand: fertig ? "fertig" : "halt",
    };
    sState = {
      ...sState,
      laeufe: sState.laeufe.map((l) => (l.id === laufId ? updated : l)),
    };
    if (fertig) {
      sState = pushTrace(sState, { laufId, art: "ende", text: "fertig", cent: 0 });
      // Crystallize on success
      sState = {
        ...sState,
        kristalle: [
          {
            id: uid("k"),
            art: "K4",
            titel: lauf.titel,
            inhalt: lauf.ziel,
            status: "schatten",
            erstellt: Date.now(),
            treffer: 1,
          },
          ...sState.kristalle,
        ],
      };
      return { state: sState, result: { ok: true, message: `Lauf fertig. Kristall im Schattenbetrieb.`, navigate: "kristalle" } };
    }
    const nextFg = freigabe("lauf_weiter", `Weiter: ${lauf.titel}`, `Schritt ${schritt + 1} freigeben?`, { laufId });
    sState = {
      ...pushTrace(sState, { laufId, art: "halt", text: `Halt bei ${schritt + 1}`, cent: 0 }),
      freigaben: [nextFg, ...sState.freigaben],
    };
    return { state: sState, result: { ok: true, message: `Fortgesetzt bis Schritt ${schritt}.`, needsFreigabe: nextFg } };
  }
  return { state: next, result: { ok: true, message: "Freigabe erteilt." } };
}
export function rejectFreigabe(state: AtmosState, freigabeId: string): AtmosState {
  return {
    ...pushTrace(state, {
      laufId: null,
      art: "halt",
      text: "Freigabe abgelehnt",
      erklaerung: "Mensch behält den Schlüssel.",
      cent: 0,
    }),
    freigaben: state.freigaben.filter((f) => f.id !== freigabeId),
  };
}
