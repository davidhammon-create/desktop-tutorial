import { EFFORT_LABELS, GESETZE, ROUTER_STUFEN, VERFASSUNG, ZYKLUS } from "./constants";
import { googleStatus } from "./google";
import { ABLAEUFE, findeAblauf, freierAblauf, sucheKatalog } from "./katalog";
import { providerConnection } from "./secrets";
import { pushTrace } from "./store";
import type {
  AtmosState,
  CommandResult,
  FreigabeAnfrage,
  Lauf,
  Modul,
  RouterStufe,
} from "./types";
export interface CommandDef {
  id: string;
  label: string;
  aliases: string[];
  beschreibung: string;
  usage: string;
}
export const COMMANDS: CommandDef[] = [
  { id: "effort", label: "/effort", aliases: ["effort", "aufwand"], beschreibung: "Router-Stufe / Modellwahl setzen (0?6)", usage: "/effort 4" },
  { id: "stop", label: "/stop", aliases: ["stop"], beschreibung: "Sofortiger Halt (Verfassung R1)", usage: "/stop" },
  { id: "fortsetzen", label: "/fortsetzen", aliases: ["fortsetzen", "weiter-system"], beschreibung: "STOP aufheben", usage: "/fortsetzen" },
  { id: "suche", label: "/suche", aliases: ["suche", "search"], beschreibung: "GitHub/Module + Google finden", usage: "/suche pdf table" },
  { id: "google", label: "/google", aliases: ["google", "gapi"], beschreibung: "Google CSE / Gemini-Suche (Einstellungen)", usage: "/google gemini sdk" },
  { id: "install", label: "/install", aliases: ["install", "installiere"], beschreibung: "Projekt einbetten (noch AUS)", usage: "/install owner/repo" },
  { id: "an", label: "/an", aliases: ["an", "enable"], beschreibung: "Modul einschalten (Freigabe)", usage: "/an owner/repo" },  { id: "aus", label: "/aus", aliases: ["aus", "disable"], beschreibung: "Modul ausschalten", usage: "/aus owner/repo" },
  { id: "liste", label: "/liste", aliases: ["liste", "modules"], beschreibung: "Eingebettete Module listen", usage: "/liste" },  { id: "vital", label: "/vital", aliases: ["vital", "puls"], beschreibung: "Puls, Modus, Hunger", usage: "/vital" },
  { id: "lauf", label: "/lauf", aliases: ["lauf"], beschreibung: "Ablauf-Vorlage starten", usage: "/lauf dokumente" },
  { id: "mach", label: "/mach", aliases: ["mach", "lösen", "loesen"], beschreibung: "Freien Auftrag planen und starten", usage: "/mach Website bauen" },
  { id: "kristall", label: "/kristall", aliases: ["kristall", "kristalle"], beschreibung: "Kristall-Bibliothek", usage: "/kristall" },
  { id: "erklaere", label: "/erklaere", aliases: ["erklaere", "erkläre", "explain"], beschreibung: "Begriff erklären", usage: "/erklaere router" },
  { id: "verfassung", label: "/verfassung", aliases: ["verfassung", "gesetze"], beschreibung: "Gesetze und Regeln zeigen", usage: "/verfassung" },
  { id: "trace", label: "/trace", aliases: ["trace", "spur"], beschreibung: "Spur der letzten Schritte", usage: "/trace" },
  { id: "hilfe", label: "/hilfe", aliases: ["hilfe", "help", "?"], beschreibung: "Befehlsspeisekarte", usage: "/hilfe" },
];
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
    text: `${vorlage.titel} ? ${vorlage.schritte.length} Schritte`,
    erklaerung: `Quelle: ${quelle} ? Effort-Cap Stufe ${state.effort}`,
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
        message: `Lauf ${lauf.id} gestartet ? hält bei Schritt ${schritt + 1}. Freigabe nötig.`,
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
        .join(" ? ") || "keine Treffer (Demo)";
    case "erklaeren":
      return "Kontextfenster begrenzt ? holen statt kippen.";
    case "entwerfen":
      return "Variante B gewählt (billigster korrekter Weg).";
    case "bauen":
      return "Kleinster lauffähiger Stand erzeugt (Demo).";
    case "schreiben":
      return "Skript-Entwurf in Szenen (Demo).";
    case "pruefen":
      return "Prüfung gegen Ziel ? OK mit Vorbehalt.";
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
  let next = { ...state, lastCommand: def.id };
  switch (def.id) {
    case "hilfe": {
      const menu = COMMANDS.map((c) => `${c.label.padEnd(12)} ${c.beschreibung}`).join("\n");
      next = pushTrace(next, { laufId: null, art: "ergebnis", text: "Befehlsspeisekarte", erklaerung: menu, cent: 0 });
      return { state: next, result: { ok: true, message: menu } };
    }
    case "effort": {
      const n = Number(args);
      if (!Number.isFinite(n) || n < 0 || n > 6) {
        return { state: next, result: { ok: false, message: "Usage: /effort 0?6" } };
      }
      const stufe = Math.round(n) as RouterStufe;
      next = { ...next, effort: stufe };
      next = pushTrace(next, {
        laufId: null,
        art: "werkzeug",
        text: `Effort ? Stufe ${stufe} (${EFFORT_LABELS[stufe]})`,
        erklaerung: ROUTER_STUFEN[stufe].name,
        stufe,
        cent: 0,
      });
      return {
        state: next,
        result: { ok: true, message: `Aufwand auf Stufe ${stufe}: ${ROUTER_STUFEN[stufe].name}` },
      };
    }
    case "stop": {
      next = { ...next, stop: true, modus: "sicher" };
      next = pushTrace(next, { laufId: null, art: "halt", text: "STOP gesetzt", erklaerung: "R1 Abschaltbar ? sofort.", cent: 0 });
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
      const lines = treffer.map((t) => `${t.score.toString().padStart(3)} ${t.name} ?${t.sterne} ${t.lizenz}`).join("\n");
      const header = `Katalog ${treffer.length} ? Google ${g.mode} (${g.source})${g.appleIntelligence ? " ? Apple Intelligence an" : ""}`;
      const msg = `${header}\n${lines || "keine Katalog-Treffer"}\n(Live-Google folgt async, wenn Key in Einstellungen)`;
      next = pushTrace(next, {
        laufId: null,
        art: "ergebnis",
        text: `Suche: ${q} ? ${treffer.length} Katalog`,
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
        erklaerung: "Gesetz 9 ? Mensch hält den Schlüssel.",
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
      const hunger = next.hunger.map((h) => `${h.problemtyp}?${h.ungeloest}`).join(", ") || "?";
      const g = googleStatus();
      const apple = providerConnection("apple-intelligence");
      const msg = `Puls ${next.puls} ? Modus ${next.modus} ? Ampel ${next.ampel} ? Kosten ${next.kostenCent.toFixed(1)}? / ${next.budgetCent}?\nHunger: ${hunger}\nSiegel: ${next.siegel} ? STOP ${next.stop ? "AN" : "aus"}\nGoogle: ${g.mode} (${g.source}) ? Gemini ${g.geminiReady ? "an" : "aus"} ? CSE ${g.searchReady ? "an" : "aus"}\nApple Intelligence: ${apple.label}`;
      next = pushTrace(next, { laufId: null, art: "ergebnis", text: "Vitalitätsbericht", erklaerung: msg, cent: 0 });
      return { state: next, result: { ok: true, message: msg, navigate: "status" } };
    }
    case "kristall": {
      const lines = next.kristalle
        .map((k) => `${k.art} [${k.status}] ${k.titel} ? ${k.treffer} Treffer`)
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
        router: "Die Kaskade Stufen 0?6: jede Anfrage steigt nur bei Unsicherheit. Nutzen = P?Wert ? Kosten ? ??Zeit.",
        kristall: "Geprüftes Wissen (K1?K5), das ohne Credits läuft: Antwort, Regel, Funktion, Workflow, Makro.",
        vitalitaet: "Haushalt je Baustein. Puls = 0,5? mittlere Vitalität + 0,5? Erfolgsquote.",
        vitalität: "Haushalt je Baustein. Puls = 0,5? mittlere Vitalität + 0,5? Erfolgsquote.",
        verfassung: "Geschützter Kern: Stop wirkt immer, Mensch hält den Schlüssel, Fremdcode nur lesen.",
        hunger: "Ungelöste Problemtypen steuern die Suche nach Modulen.",
        zyklus: ZYKLUS.map((z) => `${z.nr}. ${z.name} ? ${z.kurz}`).join("\n"),
        effort: "Built-in Aufwand-Steuerung: mappt auf Router-Stufe / Modellwahl. Kein Extra-Download.",
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
      return { state: s2, result: { ...result, navigate: "arbeit" } };
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
    return { state: next, result: { ok: true, message: `${name} eingebettet ? Status AUS.`, navigate: "module" } };
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
