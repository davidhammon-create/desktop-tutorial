import React, { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useBusinessScenarios } from '@/hooks/useBusinessScenarios';
import { T, sans } from '@/components/lexara/theme';
import {
  BusinessScenario, expectedValue, totalCosts, bruttoRisiko, nettoRisiko,
  riskAmpel, Deadline
} from '@/types/business';
import {
  BarChart, Bar, LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, PieChart, Pie,
} from 'recharts';
/* ?? helpers ?? */
function daysUntil(d: string) {
  return Math.ceil((new Date(d).getTime() - Date.now()) / 86400000);
}
function fmt(n: number) {
  return n.toLocaleString('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 });
}
/* ?? Stat Card ?? */
function Stat({ label, value, sub, color }: { label: string; value: string | number; sub?: string; color?: string }) {
  return (
    <div style={{
      background: '#fff', borderRadius: 20, padding: '28px 24px', flex: 1, minWidth: 180,
      boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
    }}>
      <div style={{ fontSize: 12, fontWeight: 500, color: T.dim, marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
        {label}
      </div>
      <div style={{ fontSize: 34, fontWeight: 700, color: color || T.text, letterSpacing: '-0.02em' }}>
        {value}
      </div>
      {sub && <div style={{ fontSize: 12, color: T.dim, marginTop: 6 }}>{sub}</div>}
    </div>
  );
}
const ExecutiveDashboard = () => {
  const navigate = useNavigate();
  const { scenarios, loading } = useBusinessScenarios();
  const stats = useMemo(() => {
    const open = scenarios.filter(s => s.status !== 'Abgeschlossen');
    const done = scenarios.filter(s => s.status === 'Abgeschlossen');
    // All deadlines across all scenarios
    const allDeadlines: (Deadline & { scenarioTitle: string; optionLabel: string })[] = [];
    scenarios.forEach(s => {
      s.options.forEach(o => {
        (o.deadlines || []).forEach(dl => {
          allDeadlines.push({ ...dl, scenarioTitle: s.title, optionLabel: o.label });
        });
      });
    });
    const criticalDeadlines = allDeadlines
      .filter(dl => {
        const days = daysUntil(dl.date);
        return days >= 0 && days <= 14;
      })
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    // Total risk exposure
    const totalRisk = open.reduce((sum, s) => {
      return sum + s.options.reduce((os, o) => os + bruttoRisiko(o), 0);
    }, 0);
    // Risk distribution (ampel)
    const ampelCounts = { green: 0, yellow: 0, red: 0 };
    open.forEach(s => s.options.forEach(o => { ampelCounts[riskAmpel(o)]++; }));
    // Category breakdown
    const catMap: Record<string, number> = {};
    open.forEach(s => { catMap[s.category] = (catMap[s.category] || 0) + 1; });
    const categoryData = Object.entries(catMap).map(([name, value]) => ({ name, value }));
    // Outcome trend (monthly)
    const rated = done.filter(s => s.outcomeRating && s.outcomeDate);
    const trendMap: Record<string, { sum: number; count: number }> = {};
    rated.forEach(s => {
      const month = s.outcomeDate!.slice(0, 7);
      if (!trendMap[month]) trendMap[month] = { sum: 0, count: 0 };
      trendMap[month].sum += s.outcomeRating!;
      trendMap[month].count++;
    });
    const trendData = Object.entries(trendMap)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([month, d]) => ({ month, avg: +(d.sum / d.count).toFixed(1) }));
    // Top recommendations
    const topRecs = open
      .filter(s => s.options.length > 0)
      .map(s => {
        const best = s.options.reduce((a, b) => expectedValue(a) > expectedValue(b) ? a : b);
        return {
          scenario: s.title || 'Unbenannt',
          option: best.label,
          ev: expectedValue(best),
          ampel: riskAmpel(best),
        };
      })
      .sort((a, b) => b.ev - a.ev)
      .slice(0, 5);
    return { open, done, criticalDeadlines, totalRisk, ampelCounts, categoryData, trendData, topRecs };
  }, [scenarios]);
  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh', fontFamily: sans, color: T.dim, background: T.bg }}>
        Dashboard wird geladen?
      </div>
    );
  }
  const ampelColor = (a: string) => a === 'green' ? '#34c759' : a === 'yellow' ? '#ff9f0a' : '#ff3b30';
  return (
    <div style={{ background: T.bg, fontFamily: sans, color: T.text, minHeight: '100vh' }}>
      {/* Top Bar */}
      <div style={{
        background: 'rgba(255,255,255,0.8)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: `1px solid ${T.border}`, padding: '0 40px', height: 56,
        display: 'flex', alignItems: 'center', gap: 16, position: 'sticky', top: 0, zIndex: 10,
      }}>
        <button onClick={() => navigate('/')} style={{
          fontFamily: sans, fontSize: 13, color: T.dim, background: 'none', border: 'none', cursor: 'pointer',
        }}>? Home</button>
        <div style={{ width: 1, height: 24, background: T.border }} />
        <div style={{ fontSize: 18, fontWeight: 700 }}>Executive Dashboard</div>
        <div style={{ flex: 1 }} />
        <div style={{ fontSize: 12, color: T.dim }}>
          Stand: {new Date().toLocaleDateString('de-DE', { day: '2-digit', month: 'long', year: 'numeric' })}
        </div>
      </div>
      <div style={{ maxWidth: 1200, margin: '0 auto', padding: '32px 24px' }}>
        {/* KPI Row */}
        <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', marginBottom: 32 }}>
          <Stat label="Offene Szenarien" value={stats.open.length} sub={`${stats.done.length} abgeschlossen`} />
          <Stat label="Gesamt-Risikoexposition" value={fmt(stats.totalRisk)} color={T.red} />
          <Stat label="Kritische Fristen" value={stats.criticalDeadlines.length} sub="nächste 14 Tage" color={stats.criticalDeadlines.length > 0 ? '#ff3b30' : T.green} />
          <Stat
            label="? Bewertung"
            value={stats.trendData.length > 0 ? stats.trendData[stats.trendData.length - 1].avg + '/5' : '?'}
            sub="letzte KI-Outcomes"
          />
        </div>
        {/* Two column grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 32 }}>
          {/* Risk Ampel */}
          <div style={{ background: '#fff', borderRadius: 20, padding: 28, boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
            <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 20 }}>Risiko-Verteilung</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
              <div style={{ width: 140, height: 140 }}>
                <ResponsiveContainer>
                  <PieChart>
                    <Pie data={[
                      { name: 'Grün', value: stats.ampelCounts.green, fill: '#34c759' },
                      { name: 'Gelb', value: stats.ampelCounts.yellow, fill: '#ff9f0a' },
                      { name: 'Rot', value: stats.ampelCounts.red, fill: '#ff3b30' },
                    ].filter(d => d.value > 0)} dataKey="value" cx="50%" cy="50%" innerRadius={35} outerRadius={60} strokeWidth={0} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {[
                  { label: 'Niedriges Risiko', count: stats.ampelCounts.green, color: '#34c759' },
                  { label: 'Mittleres Risiko', count: stats.ampelCounts.yellow, color: '#ff9f0a' },
                  { label: 'Hohes Risiko', count: stats.ampelCounts.red, color: '#ff3b30' },
                ].map(r => (
                  <div key={r.label} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}>
                    <div style={{ width: 10, height: 10, borderRadius: 5, background: r.color }} />
                    <span>{r.label}</span>
                    <span style={{ fontWeight: 700, marginLeft: 'auto' }}>{r.count}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
          {/* Category breakdown */}
          <div style={{ background: '#fff', borderRadius: 20, padding: 28, boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
            <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 20 }}>Szenarien nach Kategorie</div>
            {stats.categoryData.length > 0 ? (
              <ResponsiveContainer width="100%" height={160}>
                <BarChart data={stats.categoryData} layout="vertical">
                  <XAxis type="number" hide />
                  <YAxis type="category" dataKey="name" width={140} tick={{ fontSize: 12, fill: T.dim }} />
                  <Bar dataKey="value" radius={[0, 6, 6, 0]} fill={T.text} barSize={18} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div style={{ fontSize: 13, color: T.dim, textAlign: 'center', padding: 40 }}>Keine offenen Szenarien</div>
            )}
          </div>
        </div>
        {/* Critical Deadlines */}
        <div style={{ background: '#fff', borderRadius: 20, padding: 28, boxShadow: '0 1px 3px rgba(0,0,0,0.04)', marginBottom: 20 }}>
          <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 16 }}>
            ? Kritische Fristen (nächste 14 Tage)
          </div>
          {stats.criticalDeadlines.length === 0 ? (
            <div style={{ fontSize: 13, color: T.green, padding: 16, textAlign: 'center' }}>
              ? Keine kritischen Fristen in den nächsten 14 Tagen
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {stats.criticalDeadlines.map((dl, i) => {
                const days = daysUntil(dl.date);
                return (
                  <div key={i} style={{
                    display: 'grid', gridTemplateColumns: '1fr 200px 100px 80px',
                    gap: 12, alignItems: 'center', padding: '12px 16px', borderRadius: 12,
                    background: days <= 3 ? '#ff3b3008' : T.bg,
                  }}>
                    <div>
                      <div style={{ fontSize: 14, fontWeight: 600 }}>{dl.label || 'Ohne Bezeichnung'}</div>
                      <div style={{ fontSize: 12, color: T.dim }}>{dl.scenarioTitle}</div>
                    </div>
                    <div style={{ fontSize: 12, color: T.dim }}>{dl.type} ? Option: {dl.optionLabel}</div>
                    <div style={{ fontSize: 13 }}>{new Date(dl.date).toLocaleDateString('de-DE')}</div>
                    <div style={{
                      fontSize: 13, fontWeight: 700, textAlign: 'right',
                      color: days <= 3 ? '#ff3b30' : days <= 7 ? '#ff9f0a' : T.orange,
                    }}>
                      {days === 0 ? 'Heute!' : `${days} Tage`}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
        {/* Top Recommendations */}
        <div style={{ background: '#fff', borderRadius: 20, padding: 28, boxShadow: '0 1px 3px rgba(0,0,0,0.04)', marginBottom: 20 }}>
          <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 16 }}>Top-Empfehlungen</div>
          {stats.topRecs.length === 0 ? (
            <div style={{ fontSize: 13, color: T.dim, textAlign: 'center', padding: 16 }}>Keine offenen Szenarien mit Optionen</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {stats.topRecs.map((r, i) => (
                <div key={i} style={{
                  display: 'grid', gridTemplateColumns: '1fr 200px 120px 20px',
                  gap: 12, alignItems: 'center', padding: '12px 16px', borderRadius: 12, background: T.bg,
                }}>
                  <div>
                    <div style={{ fontSize: 14, fontWeight: 600 }}>{r.scenario}</div>
                  </div>
                  <div style={{ fontSize: 13, color: T.dim }}>? {r.option}</div>
                  <div style={{ fontSize: 14, fontWeight: 700, textAlign: 'right', color: r.ev >= 0 ? '#34c759' : '#ff3b30' }}>                    {fmt(r.ev)}
                  </div>
                  <div style={{ width: 12, height: 12, borderRadius: 6, background: ampelColor(r.ampel) }} />
                </div>
              ))}
            </div>
          )}
        </div>
        {/* Outcome Trend */}
        {stats.trendData.length > 0 && (
          <div style={{ background: '#fff', borderRadius: 20, padding: 28, boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
            <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 20 }}>KI-Bewertungstrend über Zeit</div>
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={stats.trendData}>
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: T.dim }} />
                <YAxis domain={[1, 5]} tick={{ fontSize: 12, fill: T.dim }} />
                <Tooltip formatter={(v: number) => [`${v}/5`, '? Bewertung']} />
                <Line type="monotone" dataKey="avg" stroke={T.text} strokeWidth={2} dot={{ r: 4 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>
    </div>
  );
};
export default ExecutiveDashboard;
