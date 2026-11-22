import React, { useState } from 'react';
import { T, sans } from './theme';
import { Panel, SectionTitle, Chip } from './Primitives';
interface Props {
  onBack: () => void;
}
interface Message {
  id: string;
  from: string;
  subject: string;
  preview: string;
  date: string;
  read: boolean;
  channel: 'email' | 'intern' | 'gericht';
}
const MOCK_MESSAGES: Message[] = [
  { id: '1', from: 'RA Dr. Meier', subject: 'Schriftsatz Erwiderung', preview: 'Anbei der Entwurf für die Erwiderung zum Schriftsatz der Gegenseite?', date: '21.03.2025', read: false, channel: 'intern' },
  { id: '2', from: 'LG München I', subject: 'Terminsladung 05.04.2025', preview: 'In der Sache LG-2024-0847 wird Termin zur mündlichen Verhandlung bestimmt?', date: '20.03.2025', read: false, channel: 'gericht' },
  { id: '3', from: 'Mandant Huber', subject: 'Neue Unterlagen', preview: 'Ich habe weitere Rechnungen gefunden, die als Beweis dienen könnten?', date: '19.03.2025', read: true, channel: 'email' },
  { id: '4', from: 'RA Schmidt (Gegenseite)', subject: 'Vergleichsangebot', preview: 'Unser Mandant wäre bereit, einen Vergleich über €35.000 zu?', date: '18.03.2025', read: true, channel: 'email' },
  { id: '5', from: 'Kanzlei-System', subject: 'Frist-Erinnerung', preview: 'Frist für Stellungnahme endet am 25.03.2025. Bitte prüfen.', date: '17.03.2025', read: true, channel: 'intern' },
];
const CHANNEL_COLORS = { email: T.blue, intern: T.purple, gericht: T.orange };
const CHANNEL_LABELS = { email: 'E-Mail', intern: 'Intern', gericht: 'Gericht' };
export function CommunicationHubView({ onBack }: Props) {
  const [messages, setMessages] = useState(MOCK_MESSAGES);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'email' | 'intern' | 'gericht'>('all');
  const filtered = filter === 'all' ? messages : messages.filter(m => m.channel === filter);
  const selected = messages.find(m => m.id === selectedId);
  const unread = messages.filter(m => !m.read).length;
  const markRead = (id: string) => {
    setMessages(prev => prev.map(m => m.id === id ? { ...m, read: true } : m));
  };
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <div style={{ background: T.surface, borderBottom: `1px solid ${T.border}`, padding: '14px 24px', display: 'flex', alignItems: 'center', gap: 16 }}>
        <button onClick={onBack} style={{ fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.blue, background: 'none', border: 'none', cursor: 'pointer' }}>? Dashboard</button>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 22, fontWeight: 700 }}>Communication Hub</div>
          <div style={{ fontSize: 13, color: T.dim }}>{unread} ungelesen</div>
        </div>
        <button style={{
          fontFamily: sans, fontSize: 14, fontWeight: 600, color: '#fff', background: T.blue,
          border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
        }}>
          + Neue Nachricht
        </button>
      </div>
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        {/* Sidebar: message list */}
        <div style={{ width: 380, borderRight: `1px solid ${T.border}`, background: T.surface, overflowY: 'auto' }}>
          {/* Filters */}
          <div style={{ padding: '12px 16px', borderBottom: `1px solid ${T.border}`, display: 'flex', gap: 6 }}>
            {(['all', 'email', 'intern', 'gericht'] as const).map(f => (
              <button key={f} onClick={() => setFilter(f)} style={{
                fontFamily: sans, fontSize: 12, fontWeight: filter === f ? 600 : 400,
                color: filter === f ? T.text : T.dim,
                background: filter === f ? T.bg : 'transparent',
                border: 'none', borderRadius: 8, padding: '5px 12px', cursor: 'pointer',
              }}>
                {f === 'all' ? 'Alle' : CHANNEL_LABELS[f]}
              </button>
            ))}
          </div>
          {filtered.map(m => (
            <div key={m.id} onClick={() => { setSelectedId(m.id); markRead(m.id); }}
              style={{
                padding: '14px 16px', borderBottom: `1px solid ${T.border}`, cursor: 'pointer',
                background: selectedId === m.id ? T.bg : m.read ? 'transparent' : T.blue + '06',
                transition: 'background 0.15s',
              }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                <span style={{ fontSize: 14, fontWeight: m.read ? 400 : 600 }}>{m.from}</span>
                <span style={{ fontSize: 11, color: T.dim }}>{m.date}</span>
              </div>
              <div style={{ fontSize: 13, fontWeight: m.read ? 400 : 600, marginBottom: 4 }}>{m.subject}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <Chip small color={CHANNEL_COLORS[m.channel]}>{CHANNEL_LABELS[m.channel]}</Chip>
                {!m.read && <div style={{ width: 8, height: 8, borderRadius: '50%', background: T.blue }} />}
              </div>
            </div>
          ))}
        </div>
        {/* Main: message detail */}
        <div style={{ flex: 1, padding: 24, overflowY: 'auto' }}>
          {selected ? (
            <Panel>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
                <div>
                  <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>{selected.subject}</div>
                  <div style={{ fontSize: 14, color: T.dim }}>Von: {selected.from} ? {selected.date}</div>
                </div>
                <Chip small variant="filled" color={CHANNEL_COLORS[selected.channel]}>{CHANNEL_LABELS[selected.channel]}</Chip>              </div>
              <div style={{ fontSize: 15, color: T.text, lineHeight: 1.7, marginBottom: 20 }}>
                {selected.preview}
              </div>
              <div style={{ display: 'flex', gap: 10 }}>
                <button style={{
                  fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.blue,
                  background: T.blue + '10', border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
                }}>
                  ? Antworten
                </button>
                <button style={{
                  fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.dim,
                  background: T.bg, border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
                }}>
                  ? Weiterleiten
                </button>
                <button style={{
                  fontFamily: sans, fontSize: 14, fontWeight: 500, color: T.dim,
                  background: T.bg, border: 'none', borderRadius: 10, padding: '8px 18px', cursor: 'pointer',
                }}>
                  ? An Fall anhängen
                </button>
              </div>
            </Panel>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: T.dim, fontSize: 16 }}>
              Nachricht auswählen
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
