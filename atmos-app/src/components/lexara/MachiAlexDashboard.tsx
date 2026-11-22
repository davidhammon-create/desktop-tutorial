import React, { useState } from 'react';
import { T, sans } from './theme';
import { useAuth } from '@/hooks/useAuth';
export interface ModuleCard {
  id: string;
  title: string;
  desc: string;
  icon: string;
  active?: boolean;
}
export interface ModuleCategory {
  label: string;
  modules: ModuleCard[];
}
const CATEGORIES: ModuleCategory[] = [
  {
    label: 'STRATEGY',
    modules: [
      { id: 'litigation-strategy', title: 'Litigation Strategy Board', desc: 'Interaktives Dashboard mit Timeline, Eigen-/Fremdstrategie und Drag & Drop.', icon: '??', active: true },
      { id: 'argument-extraction', title: 'Argument & Problem Extraction Board', desc: 'Texte analysieren & Argumente strukturieren.', icon: '?', active: true },
      { id: 'doc-risk', title: 'Dokumenten-Risikoanalyse', desc: 'KI-gestützte Analyse von Verträgen & Fällen mit juristischer Datenbank.', icon: '?' },
      { id: 'argument-visualizer', title: 'Argument Visualizer', desc: 'Argumentationsstärke über Zeit visualisieren und analysieren.', icon: '?', active: true },
      { id: 'scenario-planning', title: 'Strategic Scenario Planning', desc: 'Kausalketten und Zukunftsszenarien strategisch planen.', icon: '??' },
      { id: 'arbitration', title: 'Arbitration Board', desc: 'Digitale, asynchrone Schiedsverfahren durchführen.', icon: '?' },      { id: 'control-center', title: 'Control Center', desc: 'Zentrale Tools: Normen, Cases, Verträge, Beweise, Szenarien, Audit & mehr.', icon: '?', active: true },
    ],
  },
  {
    label: 'ANALYSIS',
    modules: [
      { id: 'strategical-analytics', title: 'Strategical Analytics', desc: 'Zusammenhänge von Zeugen, Beweisen und Aussagen in visueller Timeline analysieren.', icon: '?' },
      { id: 'argument-success-db', title: 'Argument Success Database', desc: 'Erfolgsquoten von Argumenten und Strategien analysieren.', icon: '?' },
      { id: 'risk-matrix', title: 'Risk & Opportunity Matrix', desc: 'Risiken und Chancen eines Falls systematisch bewerten.', icon: '?', active: true },
      { id: 'evidence-matrix', title: 'Evidence Matrix', desc: 'Beweismittel den Argumenten zuordnen und auf Lücken prüfen.', icon: '??', active: true },
    ],
  },
  {
    label: 'ADVANCED ANALYTICS',
    modules: [
      { id: 'performance-analytics', title: 'Performance Analytics', desc: 'Real-time KPIs mit Predictive Modeling für Fallerfolgsprognosen.', icon: '?', active: true },
      { id: 'predictive-outcomes', title: 'Predictive Case Outcomes', desc: 'ML-basierte Erfolgsvorhersagen anhand historischer Falldaten.', icon: '?', active: true },
      { id: 'time-billing', title: 'Time & Billing Analytics', desc: 'Analyse von Arbeitszeiten, Effizienz und Rentabilität pro Fall.', icon: '??' },
      { id: 'client-portfolio', title: 'Client Portfolio Analysis', desc: 'Mandantenportfolio-Analyse mit Risikobewertung.', icon: '?' },
    ],
  },
  {
    label: 'CASE MANAGEMENT',
    modules: [
      { id: 'case-management', title: 'Case Management', desc: 'Fallbearbeitung mit Prognose, Argumenten und Beweisen.', icon: '?', active: true },
      { id: 'witness-map', title: 'Witness & People Map', desc: 'Alle Beteiligten, Rollen und Beziehungen visualisieren.', icon: '??', active: true },
      { id: 'process-graph', title: 'Prozeßgraph', desc: 'Interaktiver Argumentgraph mit Nodes, Edges und Auto-Layout.', icon: '?', active: true },
      { id: 'evidence-chains', title: 'Beweisstränge', desc: 'Beweisstränge pro Argument mit Validität und Beweiskraft.', icon: '?', active: true },
    ],
  },
  {
    label: 'COMMUNICATION & NETWORK',
    modules: [
      { id: 'comm-hub', title: 'Communication Hub', desc: 'Zentrale Kommunikationsplattform für alle Beteiligten.', icon: '?', active: true },
      { id: 'profile-mgmt', title: 'Profile Management', desc: 'Benutzerprofile und Berechtigungsverwaltung.', icon: '?' },
      { id: 'org-mgmt', title: 'Organization Management', desc: 'Organisationsstrukturen und Mitgliederverwaltung.', icon: '??' },
      { id: 'video-conf', title: 'Secure Video Conferencing', desc: 'DSGVO-konforme Videokonferenzen mit Transkription.', icon: '?' },
    ],
  },
  {
    label: 'LAW-MAC',
    modules: [
      { id: 'strategic-tactics', title: 'Strategic Witness Tactics', desc: 'Legale, psychologisch fundierte Taktiken zur Wahrheitsfindung.', icon: '?', active: true },
    ],
  },
  {
    label: 'API-FIRST ARCHITECTURE',
    modules: [
      { id: 'strategic-case-overview', title: 'Strategische Fallübersicht', desc: 'Interaktive Kanban-ähnliche Übersicht für Litigation Management.', icon: '?' },
      { id: 'document-annotation', title: 'Dokumenten-Analyse', desc: 'KI-gestützte Dokumentenannotation mit Texterkennung.', icon: '??' },
      { id: 'argument-builder', title: 'Argumentations-Builder', desc: 'Strukturierte Argumentationsentwicklung mit Risikobewertung.', icon: '?', active: true },
      { id: 'document-intelligence', title: 'Document Intelligence', desc: 'Automatische Vertragsextraktion und Compliance-Checks.', icon: '?' },
    ],
  },
  {
    label: 'ADMINISTRATION',
    modules: [
      { id: 'profile-settings', title: 'Profile Settings', desc: 'Persönliche Einstellungen und Präferenzen.', icon: '??' },
      { id: 'onboarding', title: 'Onboarding Center', desc: 'Benutzer-Setup und Ersteinrichtung.', icon: '?' },
      { id: 'api-hub', title: 'API Integration Hub', desc: 'Externe Dienste anbinden und verwalten.', icon: '?' },
    ],
  },
];
interface Props {
  onNavigate: (moduleId: string) => void;
}
export function MachiAlexDashboard({ onNavigate }: Props) {
  const [search, setSearch] = useState('');
  const { signOut, user } = useAuth();
  const filtered = CATEGORIES.map(cat => ({
    ...cat,
    modules: cat.modules.filter(m =>
      !search || m.title.toLowerCase().includes(search.toLowerCase()) || m.desc.toLowerCase().includes(search.toLowerCase())
    ),
  })).filter(cat => cat.modules.length > 0);
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      {/* Dark header */}
      <div style={{
        background: '#1d1d1f', padding: '14px 24px', display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{ display: 'flex', gap: 6 }}>
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ff5f57' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#ffbd2e' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#28c840' }} />
        </div>
        <span style={{ color: '#fff', fontSize: 17, fontWeight: 700, letterSpacing: '-0.01em' }}>MachiavelLEX</span>
      </div>
      {/* Dashboard content */}
      <div style={{ padding: '28px 32px', maxWidth: 1400, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 20, color: T.dim }}>?</span>
            <h1 style={{ fontSize: 26, fontWeight: 700, margin: 0 }}>Dashboard</h1>
          </div>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <div style={{ position: 'relative' }}>
              <input
                value={search}
                onChange={e => setSearch(e.target.value)}
                placeholder="Module durchsuchen..."
                style={{
                  fontFamily: sans, fontSize: 14, padding: '8px 14px 8px 34px',
                  border: `1px solid ${T.border}`, borderRadius: 10, background: T.surface,
                  outline: 'none', width: 220, color: T.text,
                }}
              />
              <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', fontSize: 14, color: T.dim }}>?</span>
            </div>
            <button style={{ width: 36, height: 36, borderRadius: 10, border: `1px solid ${T.border}`, background: T.surface, cursor: 'pointer', fontSize: 16 }}>?</button>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 12, color: T.dim, maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user?.email}</span>
              <button onClick={signOut} style={{ height: 36, borderRadius: 10, border: `1px solid ${T.border}`, background: T.surface, cursor: 'pointer', fontSize: 12, fontFamily: sans, padding: '0 12px', color: T.red }}>Abmelden</button>
            </div>
          </div>
        </div>
        {filtered.map(cat => (
          <div key={cat.label} style={{ marginBottom: 28 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 14 }}>
              {cat.label}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 14 }}>
              {cat.modules.map(mod => (
                <div
                  key={mod.id}
                  onClick={() => mod.active ? onNavigate(mod.id) : undefined}
                  style={{
                    background: T.surface, borderRadius: 12, padding: '18px 20px',
                    border: `1px solid ${T.border}`,
                    cursor: mod.active ? 'pointer' : 'default',
                    opacity: mod.active ? 1 : 0.55,
                    transition: 'all 0.15s',
                    position: 'relative',
                  }}
                  onMouseEnter={e => { if (mod.active) { e.currentTarget.style.boxShadow = '0 2px 8px rgba(0,0,0,0.08)'; e.currentTarget.style.transform = 'translateY(-1px)'; } }}
                  onMouseLeave={e => { e.currentTarget.style.boxShadow = ''; e.currentTarget.style.transform = ''; }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>                    <div style={{ fontSize: 16, fontWeight: 600, color: T.text }}>{mod.title}</div>
                    <span style={{ fontSize: 18, flexShrink: 0, marginLeft: 8 }}>{mod.icon}</span>
                  </div>
                  <div style={{ fontSize: 13, color: T.dim, lineHeight: 1.45 }}>{mod.desc}</div>
                  {!mod.active && (
                    <div style={{ position: 'absolute', top: 8, right: 8, fontSize: 10, fontWeight: 600, color: T.dim, background: T.muted, borderRadius: 6, padding: '2px 6px' }}>
                      Soon
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
