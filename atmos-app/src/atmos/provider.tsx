import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { approveFreigabe, executeCommand, rejectFreigabe } from "./commands";
import { geminiRouterHint, googleCustomSearch, googleStatus } from "./google";
import { loadState, pushTrace, saveState } from "./store";
import type { AtmosState, CommandResult, FreigabeAnfrage } from "./types";
export type AtmosPanel = "arbeit" | "module" | "kristalle" | "verfassung" | "status";
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
        const msg = `Google ${g.mode} (${g.source}): ${hits.length} Treffer für ?${q}?\n${lines}`;
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
            laufId: prev.lauf?.id ?? null,
            art: "plan",
            text: `Router-Hinweis (${hint.source})`,
            erklaerung: hint.text,
            stufe: Math.min(effort, 3),
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
  const run = useCallback((input: string) => {
    const { state: next, result } = executeCommand(state, input);
    setState(next);
    setLastResult(result);
    if (result.navigate) setPanel(result.navigate as AtmosPanel);
    void enrichGoogle(input, next, next.effort);
    return result;
  }, [state, enrichGoogle]);
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
    }),
    [state, panel, lastResult, run, approve, reject, resetDemo, googleMode, refreshGoogle],
  );
  return <AtmosContext.Provider value={value}>{children}</AtmosContext.Provider>;
}
export function useAtmos() {
  const ctx = useContext(AtmosContext);
  if (!ctx) throw new Error("useAtmos outside provider");
  return ctx;
}
