import { REFERENZ, WERKZEUGE, sucheReferenz, type Referenz } from "@/atmos/befehle";
import { COMMANDS } from "@/atmos/commands";
import { useMemo, useState } from "react";

const ATMOS: Referenz[] = COMMANDS.map((c) => ({ werkzeug: "AtmOS", gruppe: c.gruppe, befehl: c.usage, was: c.beschreibung }));

/** Nachschlagewerk: Befehle und Regler aller KI-Werkzeuge, inklusive AtmOS selbst. */
export function ReferenzPanel({ onTippen }: { onTippen: (befehl: string) => void }) {
  const [q, setQ] = useState("");
  const [w, setW] = useState("");
  const [kopiert, setKopiert] = useState<string | null>(null);
  const liste = useMemo(() => {
    const atmos = ATMOS.filter((r) => (!w || w === "AtmOS") && q.toLowerCase().split(/\s+/).every((x) => `${r.befehl} ${r.was} ${r.gruppe}`.toLowerCase().includes(x)));
    return [...atmos, ...(w === "AtmOS" ? [] : sucheReferenz(q, w || undefined))];
  }, [q, w]);
  const kopiere = (t: string) => {
    void navigator.clipboard?.writeText(t).catch(() => undefined);
    setKopiert(t);
    window.setTimeout(() => setKopiert(null), 1400);
  };

  return (
    <>
      <p className="atmos-ov__lede">
        {REFERENZ.length + ATMOS.length} Befehle und Regler: AtmOS, Claude Code, Codex CLI, Gemini CLI, Aider, Cursor, Ollama, llama.cpp, die APIs
        von Claude/OpenAI/Gemini, MCP, Git/GitHub, Prompting – und wo „Effort“ in jedem Werkzeug steckt.
      </p>
      <div className="atmos-filter">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Suchen: effort, compact, mcp, modell …" aria-label="Referenz durchsuchen" />
        <span className="atmos-ov__meta">{liste.length} Einträge</span>
      </div>
      <div className="atmos-chips" role="tablist" aria-label="Werkzeuge">
        {["", "AtmOS", ...WERKZEUGE].map((x) => (
          <button key={x || "alle"} type="button" data-active={w === x} onClick={() => setW(x)}>{x || "Alle"}</button>
        ))}
      </div>
      <div className="atmos-ref">
        {liste.map((r, i) => (
          <div key={`${r.werkzeug}-${r.befehl}-${i}`} className="atmos-ref__row">
            <span className="atmos-ref__tool">{r.werkzeug}<span>{r.gruppe}</span></span>
            <code>{r.befehl}</code>
            <span className="atmos-ref__was">{r.was}</span>
            <button type="button" className="atmos-ov__pill-ghost" onClick={() => (r.werkzeug === "AtmOS" ? onTippen(r.befehl) : kopiere(r.befehl))}>
              {r.werkzeug === "AtmOS" ? "Tippen" : kopiert === r.befehl ? "kopiert" : "Kopieren"}
            </button>
          </div>
        ))}
      </div>
    </>
  );
}
