import React, { useEffect, useMemo, useRef, useState } from 'react'
import Viewer from './three/Viewer'
import { FACHBEREICHE, MODELLE, sucheModelle } from './models'
import './styles.css'

export default function App() {
  const [aktiv, setAktiv] = useState(MODELLE[0].id)
  const [suche, setSuche] = useState('')
  const [laeuft, setLaeuft] = useState(true)
  const [tempo, setTempo] = useState(1)
  const [labels, setLabels] = useState(true)
  const [layerZustand, setLayerZustand] = useState({})
  const [layerListe, setLayerListe] = useState([])
  const [resetZaehler, setResetZaehler] = useState(0)
  const [panelOffen, setPanelOffen] = useState(true)
  const [tab, setTab] = useState('ueberblick')
  const [sidebarOffen, setSidebarOffen] = useState(false)

  const modell = useMemo(() => MODELLE.find((m) => m.id === aktiv), [aktiv])
  const treffer = useMemo(() => sucheModelle(suche), [suche])

  // Beim Modellwechsel Layer-Auswahl und Textbereich zurücksetzen.
  const beiAufbau = useRef(null)
  beiAufbau.current = ({ layers }) => {
    setLayerListe(layers)
    setLayerZustand(Object.fromEntries(layers.map((l) => [l.id, l.on])))
  }

  useEffect(() => {
    setTab('ueberblick')
    setSidebarOffen(false)
  }, [aktiv])

  // Tastatursteuerung
  useEffect(() => {
    const beiTaste = (e) => {
      if (e.target.tagName === 'INPUT') return
      if (e.code === 'Space') {
        e.preventDefault()
        setLaeuft((v) => !v)
      }
      if (e.key === 'r' || e.key === 'R') setResetZaehler((v) => v + 1)
      if (e.key === 'l' || e.key === 'L') setLabels((v) => !v)
      if (e.key === 'i' || e.key === 'I') setPanelOffen((v) => !v)
      if (e.key === 'ArrowDown' || e.key === 'ArrowRight') {
        const i = MODELLE.findIndex((m) => m.id === aktiv)
        setAktiv(MODELLE[(i + 1) % MODELLE.length].id)
      }
      if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') {
        const i = MODELLE.findIndex((m) => m.id === aktiv)
        setAktiv(MODELLE[(i - 1 + MODELLE.length) % MODELLE.length].id)
      }
    }
    window.addEventListener('keydown', beiTaste)
    return () => window.removeEventListener('keydown', beiTaste)
  }, [aktiv])

  const fach = FACHBEREICHE.find((f) => f.id === modell.discipline)

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark">◈</span>
          <div>
            <h1>Modell&shy;sammlung</h1>
            <p>Interaktive 3D-Modelle für Studium und Prüfungsvorbereitung</p>
          </div>
        </div>

        <div className="suche">
          <input
            type="search"
            placeholder="Suche in allen Modellen und Fachtexten …"
            value={suche}
            onChange={(e) => setSuche(e.target.value)}
            aria-label="Modelle durchsuchen"
          />
          {suche && <span className="treffer-zahl">{treffer.length}</span>}
        </div>

        <button className="burger" onClick={() => setSidebarOffen((v) => !v)} aria-label="Modellliste">
          ☰
        </button>
      </header>

      <div className="layout">
        <aside className={`sidebar ${sidebarOffen ? 'offen' : ''}`}>
          {FACHBEREICHE.map((f) => {
            const liste = treffer.filter((m) => m.discipline === f.id)
            if (!liste.length) return null
            return (
              <section key={f.id} className="fach">
                <h2 style={{ '--fach': f.farbe }}>
                  <span className="fach-icon">{f.icon}</span>
                  {f.name}
                  <span className="fach-zahl">{liste.length}</span>
                </h2>
                <ul>
                  {liste.map((m) => (
                    <li key={m.id}>
                      <button
                        className={m.id === aktiv ? 'modell aktiv' : 'modell'}
                        style={{ '--fach': f.farbe }}
                        onClick={() => setAktiv(m.id)}
                      >
                        <span className="modell-name">{m.name}</span>
                        <span className="modell-tag">{m.tagline}</span>
                        <span className="modell-level">{m.level}</span>
                      </button>
                    </li>
                  ))}
                </ul>
              </section>
            )
          })}
          {!treffer.length && <p className="leer">Keine Treffer für „{suche}“.</p>}
        </aside>

        <main className="buehne">
          <Viewer
            model={modell}
            playing={laeuft}
            showLabels={labels}
            layers={layerZustand}
            speed={tempo}
            resetSignal={resetZaehler}
            onBuilt={(d) => beiAufbau.current(d)}
          />

          <div className="modell-kopf">
            <span className="chip" style={{ '--fach': fach.farbe }}>
              {fach.icon} {fach.name}
            </span>
            <h2>{modell.name}</h2>
            <p>{modell.tagline}</p>
            <span className="massstab">Maßstab: {modell.scale}</span>
          </div>

          <div className="werkzeuge">
            <button onClick={() => setLaeuft((v) => !v)} title="Leertaste">
              {laeuft ? '⏸' : '▶'} {laeuft ? 'Pause' : 'Start'}
            </button>
            <button onClick={() => setResetZaehler((v) => v + 1)} title="Taste R">
              ⟲ Ansicht
            </button>
            <button className={labels ? 'an' : ''} onClick={() => setLabels((v) => !v)} title="Taste L">
              🏷 Beschriftung
            </button>
            <label className="tempo">
              Tempo
              <input
                type="range"
                min="0"
                max="2.5"
                step="0.1"
                value={tempo}
                onChange={(e) => setTempo(parseFloat(e.target.value))}
              />
              <span>{tempo.toFixed(1)}×</span>
            </label>
          </div>

          {layerListe.length > 0 && (
            <div className="layer-leiste">
              <span className="layer-titel">Ebenen</span>
              {layerListe.map((l) => (
                <button
                  key={l.id}
                  className={layerZustand[l.id] ? 'layer an' : 'layer'}
                  onClick={() =>
                    setLayerZustand((z) => ({ ...z, [l.id]: !z[l.id] }))
                  }
                >
                  {layerZustand[l.id] ? '●' : '○'} {l.name}
                </button>
              ))}
            </div>
          )}

          <div className="hinweis">
            Ziehen = drehen · Scrollen = zoomen · Rechte Maustaste = verschieben
          </div>
        </main>

        <aside className={`infopanel ${panelOffen ? '' : 'zu'}`}>
          <button className="panel-schalter" onClick={() => setPanelOffen((v) => !v)}>
            {panelOffen ? '›' : '‹'}
          </button>

          {panelOffen && (
            <div className="panel-inhalt">
              <nav className="tabs">
                {[
                  ['ueberblick', 'Überblick'],
                  ['vertiefung', 'Vertiefung'],
                  ['fakten', 'Kennzahlen'],
                  ['pruefung', 'Prüfung'],
                ].map(([id, name]) => (
                  <button
                    key={id}
                    className={tab === id ? 'tab aktiv' : 'tab'}
                    onClick={() => setTab(id)}
                  >
                    {name}
                  </button>
                ))}
              </nav>

              <div className="panel-scroll">
                {tab === 'ueberblick' && (
                  <>
                    <p className="summary">{modell.info.summary}</p>
                    {modell.info.sections.slice(0, 1).map((s) => (
                      <article key={s.title}>
                        <h3>{s.title}</h3>
                        {s.body.map((p, i) => (
                          <p key={i}>{p}</p>
                        ))}
                      </article>
                    ))}
                    <button className="weiterlesen" onClick={() => setTab('vertiefung')}>
                      Weiter zur Vertiefung →
                    </button>
                  </>
                )}

                {tab === 'vertiefung' &&
                  modell.info.sections.map((s) => (
                    <article key={s.title}>
                      <h3>{s.title}</h3>
                      {s.body.map((p, i) => (
                        <p key={i}>{p}</p>
                      ))}
                    </article>
                  ))}

                {tab === 'fakten' && (
                  <table className="fakten">
                    <tbody>
                      {modell.info.facts.map((f) => (
                        <tr key={f.k}>
                          <th>{f.k}</th>
                          <td>{f.v}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}

                {tab === 'pruefung' && (
                  <>
                    <h3>Typische Prüfungsfragen</h3>
                    <ul className="pruefung">
                      {modell.info.exam.map((e, i) => (
                        <li key={i}>{e}</li>
                      ))}
                    </ul>
                  </>
                )}
              </div>
            </div>
          )}
        </aside>
      </div>

      <footer className="fusszeile">
        <span>{MODELLE.length} Modelle · {FACHBEREICHE.length} Fachbereiche</span>
        <span className="tasten">
          <kbd>Leer</kbd> Pause · <kbd>R</kbd> Ansicht · <kbd>L</kbd> Beschriftung ·{' '}
          <kbd>I</kbd> Infopanel · <kbd>↑↓</kbd> Modell
        </span>
      </footer>
    </div>
  )
}
