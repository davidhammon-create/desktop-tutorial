import React, { useState } from 'react';
import { BusinessScenario, BusinessOption, PROBLEM_CATEGORIES, ProblemCategory, RiskItem, Deadline, BusinessArgument } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label } from '@/components/lexara/Primitives';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import { FileUploadSection } from './FileUploadSection';
interface Props {
  scenario: BusinessScenario;
  onUpdate: (s: BusinessScenario) => void;
}
interface AIPrefillResult {
  optionen: {
    label: string;
    description: string;
    anwaltskosten?: number;
    gerichtskosten?: number;
    interneKosten?: number;
    opportunitaetskosten?: number;
    erfolgswahrscheinlichkeit: number;
    bestCase?: number;
    worstCase?: number;
    likelyCase?: number;
    minMonths?: number;
    maxMonths?: number;
    relevanteLaws?: string[];
    proArgumente?: { text: string; weight: number }[];
    contraArgumente?: { text: string; weight: number }[];
    reputationsrisiko?: number;
    geschaeftsbeziehungGefaehrdet?: number;
    medienoeffentlichkeit?: number;
    praezedenzwirkung?: number;
    mitarbeitermoralAuswirkung?: number;
    riskItems?: { label: string; auftretenswahrscheinlichkeit: number; bedeutung: number; entdeckungswahrscheinlichkeit: number }[];
    deadlines?: { label: string; date: string; type: string; critical?: boolean; notes?: string }[];
  }[];
  lohntEsSich?: {
    ersparnis?: number;
    strafenGesamt?: number;
    zinsen?: number;
    bussgelder?: number;
    haftstrafeRisiko?: string;
    fazit?: string;
  };
  empfehlung: string;
  notizen?: string;
}
function mapAIToOptions(ai: AIPrefillResult): BusinessOption[] {
  return ai.optionen.map((o, i) => {
    const id = `opt-ai-${Date.now()}-${i}`;
    const args: BusinessArgument[] = [
      ...(o.proArgumente || []).map((a, j) => ({
        id: `arg-${id}-pro-${j}`, side: 'pro' as const, text: a.text, weight: Math.min(10, Math.max(1, a.weight)),
      })),
      ...(o.contraArgumente || []).map((a, j) => ({
        id: `arg-${id}-con-${j}`, side: 'contra' as const, text: a.text, weight: Math.min(10, Math.max(1, a.weight)),
      })),
    ];
    const riskItems: RiskItem[] = (o.riskItems || []).map((r, j) => ({
      id: `risk-${id}-${j}`, label: r.label,
      auftretenswahrscheinlichkeit: r.auftretenswahrscheinlichkeit,
      bedeutung: r.bedeutung,
      entdeckungswahrscheinlichkeit: r.entdeckungswahrscheinlichkeit,
    }));
    const deadlines: Deadline[] = (o.deadlines || []).map((d, j) => ({
      id: `dl-${id}-${j}`, label: d.label, date: d.date,
      type: (d.type as Deadline['type']) || 'Sonstige',
      critical: d.critical || false, notes: d.notes || '',
    }));
    return {
      id, label: o.label, description: o.description,
      costs: {
        anwaltskosten: o.anwaltskosten || 0,
        gerichtskosten: o.gerichtskosten || 0,
        interneKosten: o.interneKosten || 0,
        opportunitaetskosten: o.opportunitaetskosten || 0,
      },
      risk: {
        erfolgswahrscheinlichkeit: o.erfolgswahrscheinlichkeit,
        bestCase: o.bestCase || 0, worstCase: o.worstCase || 0, likelyCase: o.likelyCase || 0,
      },
      timeframe: { minMonths: o.minMonths || 1, maxMonths: o.maxMonths || 6, earliestResult: '' },
      nonMonetary: {
        reputationsrisiko: o.reputationsrisiko || 0,
        geschaeftsbeziehungGefaehrdet: o.geschaeftsbeziehungGefaehrdet || 0,
        medienoeffentlichkeit: o.medienoeffentlichkeit || 0,
        praezedenzwirkung: o.praezedenzwirkung || 0,
        mitarbeitermoralAuswirkung: o.mitarbeitermoralAuswirkung || 0,
      },
      relevanteLaws: o.relevanteLaws || [],
      arguments: args,
      riskItems,
      mitigations: [],
      deadlines,
    };
  });
}
export function ProblemStep({ scenario, onUpdate }: Props) {
  const [loading, setLoading] = useState(false);
  const set = (patch: Partial<BusinessScenario>) => onUpdate({ ...scenario, ...patch });
  const canPrefill = !!(scenario.title || scenario.description);
  const handlePrefill = async () => {
    if (!canPrefill) {
      toast.error('Bitte gib zuerst einen Titel oder eine Beschreibung ein.');
      return;
    }
    setLoading(true);
    try {
      const { data, error } = await supabase.functions.invoke('prefill-scenario', {
        body: {
          title: scenario.title,
          description: scenario.description,
          category: scenario.category,
          company: scenario.company,
          uploadedFiles: (scenario.uploadedFiles || []).map(f => ({
            name: f.name,
            type: f.type,
            storagePath: f.storagePath,
          })),
        },
      });
      if (error) throw error;
      if (!data?.success || !data?.data) throw new Error(data?.error || 'Keine Antwort von KI');
      const aiResult = data.data as AIPrefillResult;
      const newOptions = mapAIToOptions(aiResult);
      const notesParts = [scenario.notes];
      if (aiResult.empfehlung) notesParts.push(`KI-Empfehlung: ${aiResult.empfehlung}`);
      if (aiResult.notizen) notesParts.push(`KI-Hinweise: ${aiResult.notizen}`);
      if (aiResult.lohntEsSich) {
        const l = aiResult.lohntEsSich;
        const fmt = (n?: number) => n != null ? `${n.toLocaleString('de-DE')} €` : '?';
        notesParts.push(
          `LOHNT ES SICH? ? Kosten-Nutzen-Analyse:\n` +
          `  ? Potenzielle Ersparnis: ${fmt(l.ersparnis)}\n` +
          `  ? Erwartete Strafen: ${fmt(l.strafenGesamt)}\n` +
          `  ? Nachzahlungszinsen (6% p.a.): ${fmt(l.zinsen)}\n` +
          `  ? Bußgelder: ${fmt(l.bussgelder)}\n` +
          `  ? Haftstrafe-Risiko: ${l.haftstrafeRisiko || '?'}\n` +
          `  Fazit: ${l.fazit || '?'}`
        );
      }
      onUpdate({
        ...scenario,
        options: newOptions,
        notes: notesParts.filter(Boolean).join('\n\n'),
        status: 'In Analyse',
      });
      toast.success(`KI hat ${newOptions.length} Optionen mit Argumenten, Risiken und Fristen vorausgefüllt!`);
    } catch (e: any) {
      console.error('Prefill error:', e);
      toast.error(e.message || 'KI-Vorausfüllung fehlgeschlagen');
    } finally {
      setLoading(false);
    }
  };
  return (
    <div style={{ padding: 24, maxWidth: 800 }}>
      <Panel>
        <Label>Unternehmen</Label>
        <input
          value={scenario.company} onChange={e => set({ company: e.target.value })}
          placeholder="Name des Unternehmens?"
          style={{
            fontFamily: sans, fontSize: 15, width: '100%', padding: '10px 14px',
            border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
            outline: 'none', color: T.text, marginBottom: 20,
          }}
        />
        <FileUploadSection
          files={scenario.uploadedFiles || []}
          scenarioId={scenario.id}
          onFilesChange={(files) => set({ uploadedFiles: files })}
        />
        <Label>Szenario-Titel</Label>
        <input
          value={scenario.title} onChange={e => set({ title: e.target.value })}
          placeholder="z.B. 'Konkurrent kopiert Produkt'?"
          style={{
            fontFamily: sans, fontSize: 15, width: '100%', padding: '10px 14px',
            border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
            outline: 'none', color: T.text, marginBottom: 20,
          }}
        />
        <Label>Beschreibung der Situation</Label>
        <textarea
          value={scenario.description} onChange={e => set({ description: e.target.value })}
          placeholder="Beschreiben Sie die aktuelle Situation möglichst genau?"
          rows={4}
          style={{
            fontFamily: sans, fontSize: 14, width: '100%', padding: '10px 14px',
            border: `1px solid ${T.border}`, borderRadius: 10, background: T.bg,
            outline: 'none', color: T.text, resize: 'vertical', marginBottom: 20,
          }}
        />
        <Label>Rechtsgebiet / Kategorie</Label>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 10, marginBottom: 24 }}>
          {PROBLEM_CATEGORIES.map(cat => {
            const active = scenario.category === cat.id;
            return (
              <div key={cat.id} onClick={() => set({ category: cat.id })} style={{
                padding: '14px 16px', borderRadius: 12, cursor: 'pointer',
                border: `2px solid ${active ? T.blue : T.border}`,
                background: active ? T.blue + '08' : T.bg,
                transition: 'all 0.15s',
              }}>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>
                  {cat.id}
                </div>
                <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.4 }}>
                  {cat.examples[0]}
                </div>
              </div>
            );
          })}
        </div>
        {/* AI Prefill Button */}
        <div style={{
          borderTop: `1px solid ${T.border}`, paddingTop: 20,
          display: 'flex', flexDirection: 'column', gap: 12,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div>
              <div style={{ fontSize: 15, fontWeight: 700, color: T.text }}>
                KI-Vorausfüllung
              </div>
              <div style={{ fontSize: 12, color: T.dim, lineHeight: 1.4 }}>
                Die KI analysiert dein Problem und füllt alle Schritte vor: Optionen, Kosten, Risiken, Argumente, Fristen und Empfehlung.
              </div>
            </div>
          </div>
          <button
            onClick={handlePrefill}
            disabled={loading || !canPrefill}
            style={{
              fontFamily: sans, fontSize: 14, fontWeight: 600,
              color: '#fff',
              background: loading
                ? T.dim
                : canPrefill
                  ? T.blue
                  : T.muted,
              border: 'none', borderRadius: 12, padding: '12px 20px',
              cursor: loading || !canPrefill ? 'not-allowed' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              transition: 'all 0.2s',
              width: '100%',
            }}
          >
            {loading ? 'KI analysiert? (ca. 15-30 Sek.)' : 'Alle Schritte von KI vorausfüllen lassen'}
          </button>
          {!canPrefill && (
            <div style={{ fontSize: 11, color: T.orange, textAlign: 'center' }}>
              Gib zuerst einen Titel oder eine Beschreibung ein, damit die KI arbeiten kann.
            </div>
          )}
          {scenario.options.length > 0 && (
            <div style={{
              fontSize: 12, color: T.green, textAlign: 'center',
              padding: '8px 12px', background: T.green + '10', borderRadius: 8,
            }}>
              {scenario.options.length} Optionen vorhanden ? du kannst die KI erneut starten, um die Daten zu aktualisieren.
            </div>
          )}
        </div>
      </Panel>
    </div>
  );
}
