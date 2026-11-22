import React, { useState } from 'react';
import { T, sans } from './theme';
import { Panel } from './Primitives';
interface WidgetDef {
  id: string;
  name: string;
  subtitle: string;
  icon: string;
  desc: string;
}
const WORKFLOW_STEPS = [
  '1. Materialien einsammeln (Dokumente, E-Mails, Zeugenaussagen, Gutachten)',
  '2. Inhalte extrahieren (Textstellen, Behauptungen, Daten)',
  '3. Elemente klassifizieren (Beweis, Argument, Problem, Anspruch, Frist)',
  '4. Elemente kartieren (Timeline, Argument-Graph, Szenarien)',
  '5. Simulation & Taktik planen (Risiko-Scoring, Reihenfolge, Einsatzorte)',
  '6. Outputs erzeugen (Gerichtsschrift, Strategie-Sheet, Gesprächsskript)',
  '7. Audit & Ethik-Checks (Logs, Compliance-Hinweise)',
];
const WIDGETS: WidgetDef[] = [
  { id: 'normnav', name: 'NormNav', subtitle: 'Gesetzesbibliothek', icon: '?', desc: 'Normen suchen, zitierfähig darstellen, Querverweise anzeigen.' },
  { id: 'praxiscase', name: 'PraxisCase', subtitle: 'Case Finder', icon: '?', desc: 'Relevante Entscheidungen finden, Regionalfilter, Zitier-Ketten.' },
  { id: 'clausemine', name: 'ClauseMine', subtitle: 'Vertragsparser', icon: '?', desc: 'Verträge in Klauseln zerlegen und Pflichten/Fristen markieren.' },
  { id: 'witnessboard', name: 'WitnessBoard', subtitle: 'Zeugenaussagen-Manager', icon: '?', desc: 'Aussagen strukturieren, Widersprüche erkennen, Glaubwürdigkeitsmerkmale notieren.' },
  { id: 'textclip', name: 'TextClip', subtitle: 'Dokumenten-Annotator', icon: '??', desc: 'Textstellen markieren und taggen (Beweis, Problem, Argument).' },
  { id: 'exhibitrack', name: 'ExhibitRack', subtitle: 'Beweis-Katalog', icon: '??', desc: 'Beweise mit Metadaten und Chain-of-Custody verwalten.' },
  { id: 'timemap', name: 'TimeMap', subtitle: 'Timeline & Chronologie', icon: '?', desc: 'Ereignisse auf Timeline ziehen, Verbindungen herstellen.' },
  { id: 'argubuilder', name: 'ArguBuilder', subtitle: 'Argument-Composer', icon: '?', desc: 'Aus Markierungen ein strukturiertes Argument erzeugen.' },
  { id: 'redteam', name: 'RedTeam', subtitle: 'Gegenargument-Generator', icon: '??', desc: 'Eigene Argumente auf Schwächen testen; Erwiderungen simulieren.' },
  { id: 'scenariolab', name: 'ScenarioLab', subtitle: 'Szenario-Planer', icon: '?', desc: 'Best/Worst/Real-Szenarien erstellen, Wahrscheinlichkeiten zuweisen.' },
  { id: 'riskscorer', name: 'RiskScorer', subtitle: 'Risiko-Dashboard', icon: '?', desc: 'Aggregiertes Risiko-Scoring über alle Elemente.' },
  { id: 'draftengine', name: 'DraftEngine', subtitle: 'Schriftsatz-Generator', icon: '?', desc: 'Aus Argumenten und Beweisen automatisiert Gerichtsschriften generieren.' },
  { id: 'auditlog', name: 'AuditLog', subtitle: 'Compliance & Protokoll', icon: '?', desc: 'Vollständiges Audit-Log aller Aktionen im Fall.' },
  { id: 'ethicscheck', name: 'EthicsCheck', subtitle: 'Ethik-Prüfer', icon: '??', desc: 'Automatische Checks auf ethische/berufsrechtliche Compliance.' },
];
interface Props {
  onBack: () => void;
}
export function ControlCenterView({ onBack }: Props) {
  const [search, setSearch] = useState('');
  const filtered = WIDGETS.filter(w =>
    !search || w.name.toLowerCase().includes(search.toLowerCase()) || w.desc.toLowerCase().includes(search.toLowerCase())
  );
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      {/* Dark header */}
      <div style={{ background: '#1d1d1f', padding: '14px 24px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ display: 'flex', gap: 6 }}>
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ff5f57' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ffbd2e' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#28c840' }} />
        </div>
        <span style={{ color: '#fff', fontSize: 17, fontWeight: 700 }}>MachiavelLEX</span>
      </div>
      <div style={{ padding: '28px 32px', maxWidth: 1200, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 22 }}>?</span>
            <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Control Center</h1>
          </div>
          <button onClick={onBack} style={{
            fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.text,
            background: T.surface, border: `1px solid ${T.border}`, borderRadius: 10,
            padding: '8px 18px', cursor: 'pointer',
          }}>
            Zurück zum Dashboard
          </button>
        </div>
        {/* Workflow steps */}
        <Panel style={{ marginBottom: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <span style={{ fontSize: 18 }}>??</span>
            <div>
              <div style={{ fontSize: 17, fontWeight: 700 }}>Gesamtworkflow</div>
              <div style={{ fontSize: 13, color: T.dim }}>Von Materialeinsatz bis Audit ? alles in einem Fluss</div>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 10 }}>
            {WORKFLOW_STEPS.map((step, i) => (
              <div key={i} style={{
                background: T.bg, borderRadius: 10, padding: '12px 14px',
                fontSize: 13, color: T.textSecondary, lineHeight: 1.5,
              }}>
                {step}
              </div>
            ))}
          </div>
        </Panel>
        {/* Search */}
        <div style={{ position: 'relative', marginBottom: 20 }}>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Widgets durchsuchen..."
            style={{
              fontFamily: sans, fontSize: 14, padding: '10px 14px 10px 36px',
              border: `1px solid ${T.border}`, borderRadius: 10, background: T.surface,
              outline: 'none', width: '100%', maxWidth: 500, color: T.text,
            }}
          />
          <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', fontSize: 14, color: T.dim }}>?</span>
        </div>
        {/* Widget grid */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
          {filtered.map(w => (
            <Panel key={w.id} style={{ cursor: 'pointer', transition: 'all 0.15s' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 10 }}>
                <span style={{ fontSize: 22, flexShrink: 0 }}>{w.icon}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 15, fontWeight: 600 }}>{w.name}</div>
                  <div style={{
                    fontSize: 11, fontWeight: 500, color: T.textSecondary,
                    background: T.bg, borderRadius: 6, padding: '2px 8px', display: 'inline-block', marginTop: 2,
                  }}>{w.subtitle}</div>
                </div>
                <button style={{
                  fontSize: 12, fontWeight: 500, color: T.text, background: T.bg,
                  border: `1px solid ${T.border}`, borderRadius: 8, padding: '4px 10px', cursor: 'pointer',
                }}>Details</button>
              </div>
              <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.45 }}>
                <strong style={{ color: T.textSecondary }}>Funktion:</strong> {w.desc}
              </div>
            </Panel>
          ))}
        </div>
      </div>
    </div>
  );
}
