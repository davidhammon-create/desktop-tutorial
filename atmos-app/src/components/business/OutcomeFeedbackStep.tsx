import React from 'react';
import { BusinessScenario } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
const RATINGS = [
  { value: 1, label: 'Schlecht' },
  { value: 2, label: 'Mäßig' },
  { value: 3, label: 'OK' },
  { value: 4, label: 'Gut' },
  { value: 5, label: 'Sehr gut' },
];
export function OutcomeFeedbackStep({ scenario, onUpdate }: Props) {
  const rating = scenario.outcomeRating || 0;
  const notes = scenario.outcomeNotes || '';
  const setRating = (v: number) => onUpdate({ ...scenario, outcomeRating: v, outcomeDate: new Date().toISOString() });
  const setNotes = (v: string) => onUpdate({ ...scenario, outcomeNotes: v });
  return (
    <div style={{ padding: '24px 40px', maxWidth: 640 }}>
      <div style={{ background: T.surface, borderRadius: 16, padding: 32 }}>
        <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>Ergebnis bewerten</div>
        <div style={{ fontSize: 13, color: T.dim, marginBottom: 28, lineHeight: 1.6 }}>
          Wie hat sich die gewählte Strategie bewährt? Ihr Feedback verbessert künftige Analysen.
        </div>
        {/* Rating */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 28, justifyContent: 'center' }}>
          {RATINGS.map(r => {
            const active = rating === r.value;
            return (
              <button
                key={r.value}
                onClick={() => setRating(r.value)}
                style={{
                  fontFamily: sans, fontSize: 14, fontWeight: active ? 600 : 400,
                  color: active ? '#fff' : T.text,
                  background: active ? T.text : T.bg,
                  border: 'none',
                  borderRadius: 12, padding: '14px 20px', cursor: 'pointer',
                  transition: 'all 0.15s', minWidth: 80,
                }}
              >
                {r.label}
              </button>
            );
          })}
        </div>
        <div style={{ fontSize: 13, color: T.dim, marginBottom: 8 }}>Was ist passiert? (optional)</div>
        <textarea
          value={notes}
          onChange={e => setNotes(e.target.value)}
          placeholder="War die Empfehlung hilfreich? Was lief anders als erwartet?"
          rows={4}
          style={{
            fontFamily: sans, fontSize: 14, width: '100%', padding: '14px 16px',
            border: 'none', borderRadius: 12, background: T.bg,
            outline: 'none', color: T.text, resize: 'vertical', marginBottom: 24,
          }}
        />
        {/* Privacy */}
        <div style={{
          padding: '12px 16px', borderRadius: 12,
          background: T.bg, fontSize: 12, color: T.dim, lineHeight: 1.6,
        }}>
          Ihr Feedback wird nur in Ihrer Datenbank gespeichert und anonymisiert für künftige Analysen genutzt.
          Keine Daten werden an Entwickler oder Dritte weitergegeben.
        </div>
      </div>
    </div>
  );
}
