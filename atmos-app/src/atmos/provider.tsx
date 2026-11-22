import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { frageAlle, frageKi, kiKonfig, modelleVon } from "./anbieter";
import { approveFreigabe, executeCommand, rejectFreigabe } from "./commands";
import { geminiRouterHint, googleCustomSearch, googleStatus } from "./google";
import { loadState, pushTrace, saveState } from "./store";
import type { AtmosState, CommandResult, FreigabeAnfrage, RouterStufe } from "./types";
export type AtmosPanel = "arbeit" | "module" | "kristalle" | "verfassung" | "status" | "kis" | "katalog" | "referenz";
interface AtmosContextValue {
  state: AtmosState;
  panel: AtmosPanel;
  setPanel: (p: AtmosPanel) => void;
  lastResult: CommandResult | null;
  run: (input: string) => CommandResult;
  approve: (id: string) => CommandResult;
  reject: (id: string) => void;
  pendingFreigabe: FreigabeAnfrage | null;
  resetDemo: () => void;
  googleMode: ReturnType<typeof googleStatus>;
  refreshGoogle: () => void;
  /** laeuft gerade eine KI-Anfrage? */
  denkt: boolean;
}
const AtmosContext = createContext<AtmosContextValue | null>(null);
export function AtmosProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AtmosState>(() => loadState());
  const [panel, setPanel] = useState<AtmosPanel>("arbeit");
  const [lastResult, setLastResult] = useState<CommandResult | null>(null);
  const [googleMode, setGoogleMode] = useState(() => googleStatus());
  useEffect(() => {
    saveState(state);
  }, [state]);
  const refreshGoogle = useCallback(() => {
    setGoogleMode(googleStatus());
  }, []);
  const enrichGoogle = useCallback(async (input: string, base: AtmosState, effort: number) => {
    const trimmed = input.trim();
    const lower = trimmed.toLowerCase();
    const isSuche =
      lower.startsWith("/suche") ||
      lower.startsWith("suche ") ||
      lower.startsWith("/google") ||
      lower.startsWith("google ");
    const isMach = lower.startsWith("/mach") || lower.startsWith("mach ");
    if (!isSuche && !isMach) return;
    try {
      if (isSuche) {
        const q = trimmed.replace(/^\/?(suche|google)\s*/i, "").trim() || "ki agent";
        const hits = await googleCustomSearch(q, 5);
        const g = googleStatus();
        const lines = hits
          .map((h) => `[${h.source}] ${h.title}\n  ${h.link}\n  ${h.snippet}`)
          .join("\n");
        const msg = `Google ${g.mode} (${g.source}): ${hits.length} Treffer für „${q}“\n${lines}`;
        setState((prev) =>
          pushTrace(prev, {
            laufId: null,
            art: "ergebnis",
            text: `Google-Suche: ${q}`,
            erklaerung: msg,
            stufe: 1,
            cent: 0,
          }),
        );
        setLastResult({ ok: true, message: msg, navigate: "module" });
        setGoogleMode(g);
      } else if (isMach) {
        const auftrag = trimmed.replace(/^\/?mach\s*/i, "").trim() || "Problem lösen";
        const hint = await geminiRouterHint(auftrag, effort);
        setState((prev) =>
          pushTrace(prev, {
            laufId: prev.laeufe[0]?.id ?? null,
            art: "plan",
            text: `Router-Hinweis (${hint.source})`,
            erklaerung: hint.text,
            stufe: Math.min(effort, 3) as RouterStufe,
            cent: 0,
          }),
        );
        setLastResult({
          ok: true,
          message: hint.text,
          navigate: "arbeit",
        });
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      setState((prev) =>
        pushTrace(prev, {
          laufId: null,
          art: "halt",
          text: "Google-Anreicherung fehlgeschlagen",
          erklaerung: message,
          cent: 0,
        }),
      );
      setLastResult({ ok: false, message });
    }
  }, []);
  const [denkt, setDenkt] = useState(false);
  /** Fuehrt die asynchrone Folgeaktion eines Befehls aus: echte KI-Anfragen und Modelllisten. */
  const fuehreAus = useCallback(async (job: NonNullable<CommandResult["async"]>, base: AtmosState) => {
    setDenkt(true);
    try {
      if (job.art === "modelle" && job.anbieter) {
        const liste = await modelleVon(job.anbieter);
        const msg = `${kiKonfig(job.anbieter).name}: ${liste.length} Modelle\n${liste.join("\n")}\n\nSetzen: /modell <name>`;
        setLastResult({ ok: true, message: msg });
        setState((prev) => pushTrace(prev, { laufId: null, art: "ergebnis", text: `Modelle von ${job.anbieter}`, erklaerung: msg, cent: 0 }));
      } else if (job.art === "frage" && job.anbieter && job.text) {
        const verlauf = [...(job.gespraech ? base.gespraech.map(({ role, content }) => ({ role, content })) : []), { role: "user" as const, content: job.text }];
        const a = await frageKi(job.anbieter, verlauf, { modell: job.modell, effort: job.effort });
        const kopf = `${kiKonfig(job.anbieter).name} · ${a.modell ?? ""} · ${(a.ms / 1000).toFixed(1)} s · Effort ${job.effort}`;
        setLastResult({ ok: a.ende !== "refusal", message: `${kopf}\n\n${a.text}` });
        setState((prev) => {
          const mitTrace = pushTrace(prev, { laufId: job.gespraech ? null : prev.laeufe[0]?.id ?? null, art: job.gespraech ? "ergebnis" : "plan",
            text: job.gespraech ? `${job.anbieter}: ${job.text.slice(0, 60)}` : `Plan von ${job.anbieter}`, erklaerung: a.text, modell: a.modell,
            stufe: 5, cent: 0 });
          return job.gespraech
            ? { ...mitTrace, gespraech: [...prev.gespraech, { role: "user" as const, content: job.text! }, { role: "assistant" as const, content: a.text, anbieter: job.anbieter }].slice(-40) }
            : mitTrace;
        });
      } else if (job.art === "alle" && job.text) {
        const antworten = await frageAlle(job.text, undefined, { effort: job.effort });
        const msg = antworten
          .map((a) => `── ${kiKonfig(a.anbieter).name}${a.modell ? ` · ${a.modell}` : ""}${a.ms ? ` · ${(a.ms / 1000).toFixed(1)} s` : ""}\n${a.fehler ? `Fehler: ${a.fehler}` : a.text}`)
          .join("\n\n");
        setLastResult({ ok: antworten.some((a) => !a.fehler), message: msg });
        setState((prev) => pushTrace(prev, { laufId: null, art: "ergebnis", text: `Ensemble: ${antworten.filter((a) => !a.fehler).length}/${antworten.length} Antworten`, erklaerung: msg, stufe: 6, cent: 0 }));
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      setLastResult({ ok: false, message: `Fehler: ${message}` });
      setState((prev) => pushTrace(prev, { laufId: null, art: "fehler", text: "KI-Anfrage fehlgeschlagen", erklaerung: message, cent: 0 }));
    } finally {
      setDenkt(false);
    }
  }, []);
  const run = useCallback((input: string) => {
    const { state: next, result } = executeCommand(state, input);
    setState(next);
    setLastResult(result);
    if (result.navigate) setPanel(result.navigate as AtmosPanel);
    if (result.async) void fuehreAus(result.async, next);
    else void enrichGoogle(input, next, next.effort);
    return result;
  }, [state, enrichGoogle, fuehreAus]);
  const approve = useCallback((id: string) => {
    const { state: next, result } = approveFreigabe(state, id);
    setState(next);
    setLastResult(result);
    if (result.navigate) setPanel(result.navigate as AtmosPanel);
    return result;
  }, [state]);
  const reject = useCallback((id: string) => {
    setState(rejectFreigabe(state, id));
    setLastResult({ ok: true, message: "Freigabe abgelehnt." });
  }, [state]);
  const resetDemo = useCallback(() => {
    localStorage.removeItem("atmos.koordinat.state.v1");
    const fresh = loadState();
    setState(fresh);
    setLastResult({ ok: true, message: "Demo zurückgesetzt." });
    setPanel("arbeit");
  }, []);
  const value = useMemo<AtmosContextValue>(
    () => ({
      state,
      panel,
      setPanel,
      lastResult,
      run,
      approve,
      reject,
      pendingFreigabe: state.freigaben[0] ?? null,
      resetDemo,
      googleMode,
      refreshGoogle,
      denkt,
    }),
    [state, panel, lastResult, run, approve, reject, resetDemo, googleMode, refreshGoogle, denkt],
  );
  return <AtmosContext.Provider value={value}>{children}</AtmosContext.Provider>;
}
export function useAtmos() {
  const ctx = useContext(AtmosContext);
  if (!ctx) throw new Error("useAtmos outside provider");
  return ctx;
}
