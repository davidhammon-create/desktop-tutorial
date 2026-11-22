import React, { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { BusinessScenario, PROBLEM_CATEGORIES, createEmptyScenario } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { importScenarioFromFile } from './BusinessReportPdf';
import { toast } from 'sonner';
interface Props {
  scenarios: BusinessScenario[];
  onSelect: (id: string) => void;
  onAdd: (s: BusinessScenario) => void;
  onDelete: (id: string) => void;
}
const statusColor = (s: string) =>
  s === 'Abgeschlossen' ? T.green : s === 'In Analyse' ? T.orange : T.dim;
export function ScenarioListView({ scenarios, onSelect, onAdd, onDelete }: Props) {
  const [search, setSearch] = useState('');
  const navigate = useNavigate();
  const fileRef = useRef<HTMLInputElement>(null);
  const filtered = scenarios.filter(s =>
    s.title.toLowerCase().includes(search.toLowerCase()) ||
    s.category.toLowerCase().includes(search.toLowerCase())
  );
  const handleNew = () => {
    const s = createEmptyScenario();
    s.title = 'Neues Szenario';
    onAdd(s);
  };
  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const s = await importScenarioFromFile(file);
      onAdd(s);
      toast.success(`Szenario "${s.title}" importiert`);
    } catch (err: any) {
      toast.error(err.message || 'Import fehlgeschlagen');
    }
    e.target.value = '';
  };
  const stats = {
    total: scenarios.length,
    active: scenarios.filter(s => s.status === 'In Analyse').length,
    done: scenarios.filter(s => s.status === 'Abgeschlossen').length,
  };
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      {/* Hero */}
      <div style={{ padding: '60px 48px 40px', maxWidth: 1200, margin: '0 auto' }}>
        <button onClick={() => navigate('/')} style={{
          fontFamily: sans, fontSize: 12, color: T.dim,
          background: 'none', border: 'none', cursor: 'pointer', padding: 0, marginBottom: 24,
          display: 'block',
        }}>? Zurück</button>
        <div style={{ fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.1, marginBottom: 8 }}>
          Risk Management
        </div>
        <div style={{ fontSize: 18, color: T.dim, fontWeight: 400, marginBottom: 40 }}>
          Analysieren. Bewerten. Entscheiden.
        </div>
        {/* Stats */}
        <div style={{ display: 'flex', gap: 32, marginBottom: 40 }}>
          {[
            { label: 'Szenarien', value: stats.total },
            { label: 'Aktiv', value: stats.active },
            { label: 'Abgeschlossen', value: stats.done },
          ].map(s => (
            <div key={s.label}>
              <div style={{ fontSize: 32, fontWeight: 700 }}>{s.value}</div>
              <div style={{ fontSize: 13, color: T.dim }}>{s.label}</div>
            </div>
          ))}
        </div>
        {/* Actions Row */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 32 }}>
          <input
            value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Suchen?"
            style={{
              fontFamily: sans, fontSize: 15, width: 280,
              padding: '12px 16px', border: 'none', borderRadius: 12,
              background: T.surface, outline: 'none', color: T.text,
            }}
          />
          <div style={{ flex: 1 }} />
          <input ref={fileRef} type="file" accept=".json" onChange={handleImport} style={{ display: 'none' }} />
          <button onClick={() => fileRef.current?.click()} style={{
            fontFamily: sans, fontSize: 13, color: T.dim,
            background: T.surface, border: 'none', borderRadius: 12, padding: '12px 20px', cursor: 'pointer',
          }}>Import</button>
          <button onClick={handleNew} style={{
            fontFamily: sans, fontSize: 15, fontWeight: 600, color: '#fff',
            background: T.text, border: 'none', borderRadius: 12, padding: '12px 28px', cursor: 'pointer',
          }}>
            Neues Szenario
          </button>
        </div>
      </div>
      {/* Grid */}
      <div style={{ maxWidth: 1200, margin: '0 auto', padding: '0 48px 60px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: 20 }}>
          {filtered.map(s => (
            <div key={s.id} onClick={() => onSelect(s.id)} style={{
              background: T.surface, borderRadius: 20, padding: 28, cursor: 'pointer',
              transition: 'transform 0.2s, box-shadow 0.2s',
              position: 'relative',
            }}
            onMouseEnter={e => {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 8px 30px rgba(0,0,0,0.08)';
            }}
            onMouseLeave={e => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = 'none';
            }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
                <div style={{
                  fontSize: 11, fontWeight: 600, color: statusColor(s.status),
                  textTransform: 'uppercase', letterSpacing: '0.06em',
                }}>{s.status}</div>
                <button onClick={e => { e.stopPropagation(); onDelete(s.id); }} style={{
                  fontFamily: sans, fontSize: 11, color: T.dim, background: 'none', border: 'none', cursor: 'pointer',
                  opacity: 0.4, padding: '2px 6px',
                }}>Entfernen</button>
              </div>
              <div style={{ fontSize: 20, fontWeight: 700, marginBottom: 8, lineHeight: 1.3 }}>
                {s.title || 'Ohne Titel'}
              </div>
              <div style={{ fontSize: 14, color: T.dim, marginBottom: 20, lineHeight: 1.6 }}>
                {s.description ? (s.description.length > 120 ? s.description.slice(0, 120) + '?' : s.description) : 'Keine Beschreibung'}
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ fontSize: 12, color: T.dim }}>{s.category}</div>
                <div style={{ fontSize: 12, color: T.dim }}>{s.options.length} Optionen</div>
              </div>
            </div>
          ))}
          {filtered.length === 0 && (
            <div style={{ gridColumn: '1/-1', textAlign: 'center', padding: 80, color: T.dim }}>
              <div style={{ fontSize: 24, fontWeight: 700, marginBottom: 8 }}>Noch keine Szenarien</div>
              <div style={{ fontSize: 15 }}>Erstellen Sie Ihr erstes Risiko-Szenario</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
