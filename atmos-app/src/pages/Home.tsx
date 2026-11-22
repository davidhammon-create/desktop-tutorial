import React from 'react';
import { useNavigate } from 'react-router-dom';
import { T, sans } from '@/components/lexara/theme';
const modules = [
  {
    id: 'dashboard',
    icon: '?',
    title: 'Executive Dashboard',
    subtitle: 'CEO / CRO Übersicht',
    desc: 'Alle offenen Risiken, kritische Fristen, Top-Empfehlungen und KI-Bewertungstrends auf einen Blick.',
    route: '/dashboard',
    color: '#1d1d1f',
  },
  {
    id: 'lexara',
    icon: '??',
    title: 'Anwalts-Tool',
    subtitle: 'Kanzlei ? Fallmanagement',
    desc: 'Argumentketten, Beweisführung, Strategie & Prognose für laufende Mandantenakten.',
    route: '/lexara',
    color: T.blue,
  },
  {
    id: 'business',
    icon: '?',
    title: 'Business Risk Management',
    subtitle: 'Enterprise ? 9-Schritt-Analyse',
    desc: 'Rechtliche Risiken strukturiert durchdenken, mit 8 mathematischen Modellen durchrechnen und fundierte Entscheidungen treffen.',
    route: '/business',
    color: T.green,
  },
  {
    id: 'document',
    icon: '?',
    title: 'Dokument-Analyse',
    subtitle: 'KI-Dokumentenprüfung',
    desc: 'Verträge, Buchhaltung oder beliebige Dokumente hochladen und sofort KI-gestützt auf Risiken, Klauseln und Handlungsempfehlungen prüfen lassen.',
    route: '/documents',
    color: T.orange,
  },
];
const audienceCards = [
  {
    id: 'enterprise',
    label: 'FÜR UNTERNEHMEN',
    title: 'Enterprise',
    points: [
      'Kosten-Nutzen-Analyse mit EV, RAV, Sharpe Ratio & Monte-Carlo',
      'Strukturierte Entscheidungsgrundlage statt teurer Ersteinschätzung',
      'Vollständiger Governance-Nachweis (Business Judgment Rule)',
      '30?60 % weniger externer Beratungsbedarf',
    ],
    color: '#1d1d1f',
  },
  {
    id: 'lawyer',
    label: 'FÜR ANWÄLTE',
    title: 'Kanzleien',
    points: [
      'Juristische Expertise in Zahlen übersetzen',
      'Mandantenkommunikation mit quantitativer Grundlage',
      'Schriftsatzvorbereitung durch strukturierte Argumente',
      'Differenzierung am Markt & Effizienzsteigerung',
    ],
    color: T.green,
  },
];
const HomePage = () => {
  const navigate = useNavigate();
  return (
    <div style={{
      background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
    }}>
      <div style={{ maxWidth: 760, width: '100%', padding: '48px 24px 24px' }}>
        {/* Hero */}
        <div style={{ textAlign: 'center', marginBottom: 40 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
            MachiavelLEX
          </div>
          <div style={{ fontSize: 34, fontWeight: 700, lineHeight: 1.15, letterSpacing: '-0.01em' }}>
            Legal Decision Intelligence
          </div>
          <div style={{ fontSize: 16, color: T.dim, marginTop: 10, lineHeight: 1.6, maxWidth: 560, margin: '10px auto 0' }}>
            Juristische Entscheidungen mit mathematischer Präzision analysieren, quantifizieren und strategisch vorbereiten.
          </div>
        </div>
        {/* Module cards */}
        <div style={{ display: 'grid', gap: 14, marginBottom: 40 }}>
          {modules.map(m => (
            <div key={m.id} onClick={() => navigate(m.route)} style={{
              background: T.surface, borderRadius: 16, padding: '28px 28px',
              border: `1px solid ${T.border}`, cursor: 'pointer',
              boxShadow: '0 1px 4px rgba(0,0,0,0.05)',
              transition: 'box-shadow 0.2s, border-color 0.2s',
              display: 'flex', alignItems: 'flex-start', gap: 20,
            }}
            onMouseEnter={e => {
              (e.currentTarget as HTMLElement).style.borderColor = m.color;
              (e.currentTarget as HTMLElement).style.boxShadow = `0 4px 20px ${m.color}15`;
            }}
            onMouseLeave={e => {
              (e.currentTarget as HTMLElement).style.borderColor = T.border;
              (e.currentTarget as HTMLElement).style.boxShadow = '0 1px 4px rgba(0,0,0,0.05)';
            }}
            >
              <div style={{
                fontSize: 36, width: 64, height: 64, borderRadius: 16,
                background: m.color + '10',
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
              }}>{m.icon}</div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: m.color, textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                  {m.subtitle}
                </div>
                <div style={{ fontSize: 20, fontWeight: 700, marginTop: 4 }}>{m.title}</div>
                <div style={{ fontSize: 14, color: T.dim, marginTop: 6, lineHeight: 1.5 }}>{m.desc}</div>
              </div>
              <div style={{ marginLeft: 'auto', fontSize: 20, color: T.dim, alignSelf: 'center' }}>?</div>
            </div>
          ))}
        </div>
        {/* Dual-audience section */}
        <div style={{ marginBottom: 40 }}>
          <div style={{ textAlign: 'center', marginBottom: 20 }}>
            <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.01em' }}>Für wen ist MachiavelLEX?</div>
            <div style={{ fontSize: 14, color: T.dim, marginTop: 6 }}>Zwei Zielgruppen, ein Framework</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
            {audienceCards.map(a => (
              <div key={a.id} style={{
                background: T.surface, borderRadius: 16, padding: '24px 24px',
                border: `1px solid ${T.border}`,
              }}>
                <div style={{ fontSize: 10, fontWeight: 700, color: a.color, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
                  {a.label}
                </div>
                <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 14 }}>{a.title}</div>
                <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {a.points.map((p, i) => (
                    <li key={i} style={{ fontSize: 13, color: T.dim, lineHeight: 1.5, display: 'flex', gap: 8 }}>
                      <span style={{ color: a.color, fontWeight: 700, flexShrink: 0 }}>?</span>
                      <span>{p}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
        {/* Methodology highlight */}
        <div style={{
          background: T.surface, borderRadius: 16, padding: '24px 28px',
          border: `1px solid ${T.border}`, marginBottom: 40,
        }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 12 }}>
            8 MATHEMATISCHE MODELLE
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(170px, 1fr))', gap: 8 }}>
            {[
              'Erwartungswert (EV)',
              'Risikoadjustierter Wert (RAV)',
              'Downside Risk & VaR',
              'RPN / FMEA',
              'Monte-Carlo (1.000 Szenarien)',
              'Sharpe Ratio',
              'Kelly-Kriterium',
              'Break-Even-Analyse',
            ].map(f => (
              <div key={f} style={{
                fontSize: 12, color: T.text, padding: '8px 12px',
                borderRadius: 8, background: T.bg, fontWeight: 500,
              }}>{f}</div>
            ))}
          </div>
        </div>
        {/* Disclaimer */}
        <div style={{ textAlign: 'center', padding: '16px 0 32px', fontSize: 12, color: T.dim, lineHeight: 1.6 }}>
          MachiavelLEX ist ein Werkzeug zur Entscheidungsvorbereitung ? kein Ersatz für Rechtsberatung.
          <br />Alle Analysen müssen von einem Juristen geprüft werden.
        </div>
      </div>
    </div>
  );
};
export default HomePage;
