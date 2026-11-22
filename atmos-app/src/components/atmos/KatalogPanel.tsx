import { KATALOG, KATEGORIEN, lizenzklasse } from "@/atmos/katalog";
import { useAtmos } from "@/atmos/provider";
import { useMemo, useState } from "react";

/** Alle geprüften GitHub-Repos: suchen, filtern, einbetten. */
export function KatalogPanel() {
  const { run, state } = useAtmos();
  const [q, setQ] = useState("");
  const [kat, setKat] = useState("");
  const eingebettet = new Set(state.module.map((m) => m.name));
  const liste = useMemo(() => {
    const w = q.toLowerCase().split(/\s+/).filter(Boolean);
    return KATALOG.filter((k) => (!kat || k.kategorie === kat) && w.every((x) => `${k.repo} ${k.zweck} ${k.kategorie}`.toLowerCase().includes(x)))
      .sort((a, b) => (b.sterne ?? 0) - (a.sterne ?? 0));
  }, [q, kat]);

  return (
    <>
      <p className="atmos-ov__lede">
        {KATALOG.length} Repos in {KATEGORIEN.length} Kategorien, gegen GitHub geprüft (existieren, nicht archiviert). Einbetten heißt: als
        Daten übernehmen, Status AUS – fremder Code wird nie ausgeführt.
      </p>
      <div className="atmos-filter">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Suchen: pdf, agent, video, mcp …" aria-label="Katalog durchsuchen" />
        <span className="atmos-ov__meta">{liste.length} Treffer</span>
      </div>
      <div className="atmos-chips" role="tablist" aria-label="Kategorien">
        <button type="button" data-active={!kat} onClick={() => setKat("")}>Alle</button>
        {KATEGORIEN.map((k) => (
          <button key={k} type="button" data-active={kat === k} onClick={() => setKat(kat === k ? "" : k)}>
            {k} <span>{KATALOG.filter((x) => x.kategorie === k).length}</span>
          </button>
        ))}
      </div>
      <div className="atmos-ov__grid atmos-ov__grid--modules">
        {liste.map((k) => {
          const klasse = lizenzklasse(k.lizenz);
          return (
            <div key={k.repo} className="atmos-ov__row">
              <div className="atmos-ov__squircle" data-id="module" aria-hidden>{k.repo.split("/")[1].slice(0, 2)}</div>
              <div className="atmos-ov__row-text">
                <strong>
                  <a href={`https://github.com/${k.repo}`} target="_blank" rel="noreferrer">{k.repo}</a>
                </strong>
                <span>{k.zweck}</span>
                <span className="atmos-ov__meta">
                  {k.kategorie} · ★ {(k.sterne ?? 0).toLocaleString("de")} · <span className={`atmos-lizenz atmos-lizenz--${klasse}`}>{k.lizenz ?? "keine Lizenz"}</span>
                </span>
              </div>
              <div className="atmos-ov__row-actions">
                <button type="button" className="atmos-ov__pill" disabled={eingebettet.has(k.repo)} onClick={() => run(`/install ${k.repo}`)}>
                  {eingebettet.has(k.repo) ? "drin" : "Einbetten"}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
}
