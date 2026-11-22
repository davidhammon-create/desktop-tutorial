import { useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { LexaraCase, LexaraArgument, LexaraEdge, LexaraEvidence, LexaraPerson, LexaraFrist, LexaraKosten } from '@/types/lexara';
import { useAuth } from '@/hooks/useAuth';
import { toast } from 'sonner';
import { SEED_CASES } from '@/data/seedCases';
// Convert DB rows to a LexaraCase
function assembleCases(
  caseRows: any[],
  argRows: any[],
  edgeRows: any[],
  evidenceRows: any[],
  personRows: any[],
): LexaraCase[] {
  return caseRows.map(cr => {
    const caseArgs: LexaraArgument[] = argRows
      .filter(a => a.case_id === cr.id)
      .map(a => ({
        id: a.id,
        side: a.side as 'own' | 'opp',
        label: a.label,
        strength: Number(a.strength) || 5,
        content: a.content || '',
        description: a.description || '',
      }));
    const caseEdges: LexaraEdge[] = edgeRows
      .filter(e => e.case_id === cr.id)
      .map(e => ({
        from: e.from_arg_id,
        to: e.to_arg_id,
        type: e.type as LexaraEdge['type'],
      }));
    const evidence: Record<string, LexaraEvidence[]> = {};
    evidenceRows.filter(ev => ev.case_id === cr.id).forEach(ev => {
      if (!evidence[ev.argument_id]) evidence[ev.argument_id] = [];
      evidence[ev.argument_id].push({
        id: ev.id,
        name: ev.name,
        desc: ev.description || '',
        type: ev.type || '',
        validity: ev.validity ?? 50,
        strength: ev.strength ?? 5,
      });
    });
    const persons: LexaraPerson[] = personRows
      .filter(p => p.case_id === cr.id)
      .map(p => ({
        id: p.id,
        name: p.name,
        role: p.role as LexaraPerson['role'],
        party: p.party,
        court: p.court || '',
        historicalCases: p.historical_cases || 0,
        historicalConsistency: p.historical_consistency || 50,
        priorContradictions: p.prior_contradictions || 0,
        plaintiffWinRate: p.plaintiff_win_rate,
        settleRate: p.settle_rate,
        avgDuration: p.avg_duration,
        conflictOfInterest: p.conflict_of_interest || 0,
        hiddenMotive: p.hidden_motive || 0,
        competenceLevel: p.competence_level || 50,
        selfPreservation: p.self_preservation || 0,
        loyaltySignals: p.loyalty_signals || 0,
        fearFactor: p.fear_factor || 0,
        narcissism: p.narcissism || 0,
        cognitiveEmpathy: p.cognitive_empathy ?? 50,
        affectiveEmpathy: p.affective_empathy ?? 50,
        manipulationSkill: p.manipulation_skill || 0,
        coldness: p.coldness || 0,
        legalLevers: (p.legal_levers as any[]) || [],
        psychLevers: (p.psych_levers as any[]) || [],
        questionModules: (p.question_modules as any[]) || [],
        pastCaseNotes: p.past_case_notes || '',
      }));
    return {
      id: cr.id,
      name: cr.name,
      number: cr.number || '',
      court: cr.court || '',
      type: cr.type || '',
      goal: cr.goal || '',
      status: cr.status || 'Vorbereitung',
      created: new Date(cr.created_at).toLocaleDateString('de-DE'),
      instanz: cr.instanz || '',
      kernfrage: cr.kernfrage || '',
      arguments: caseArgs,
      edges: caseEdges,
      evidence,
      persons,
      fristen: (cr.fristen as LexaraFrist[]) || [],
      kosten: cr.kosten as LexaraKosten | undefined,
    };
  });
}
export function useLexaraCases() {
  const { user } = useAuth();
  const [cases, setCases] = useState<LexaraCase[]>([]);
  const [loading, setLoading] = useState(true);
  const isDevMode = !user && sessionStorage.getItem('dev-access') === 'true';
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingRef = useRef<LexaraCase | null>(null);
  // Load
  const load = useCallback(async () => {
    if (isDevMode) {
      const stored = sessionStorage.getItem('dev-lexara-cases');
      if (stored) {
        try { setCases(JSON.parse(stored)); } catch { setCases(SEED_CASES); }
      } else {
        setCases(SEED_CASES);
      }
      setLoading(false);
      return;
    }
    if (!user) { setLoading(false); return; }
    try {
      const [cR, aR, eR, evR, pR] = await Promise.all([
        supabase.from('cases').select('*').order('created_at', { ascending: false }),
        supabase.from('arguments').select('*'),
        supabase.from('edges').select('*'),
        supabase.from('evidence').select('*'),
        supabase.from('persons').select('*'),
      ]);
      if (cR.error) throw cR.error;
      setCases(assembleCases(cR.data || [], aR.data || [], eR.data || [], evR.data || [], pR.data || []));
    } catch (e: any) {
      console.error('Failed to load cases', e);
      toast.error('Fälle konnten nicht geladen werden');
    } finally {
      setLoading(false);
    }
  }, [user, isDevMode]);
  useEffect(() => { load(); }, [load]);
  // Add case
  const addCase = useCallback(async (data: Partial<LexaraCase>): Promise<LexaraCase | null> => {
    const newCase: LexaraCase = {
      id: `c-${Date.now()}`,
      name: data.name || 'Neuer Fall',
      number: data.number || '',
      court: data.court || '',
      type: data.type || '',
      goal: data.goal || '',
      status: data.status || 'Vorbereitung',
      created: data.created || new Date().toLocaleDateString('de-DE'),
      arguments: [],
      edges: [],
      evidence: {},
      fristen: [],
      persons: [],
    };
    if (isDevMode) {
      setCases(prev => {
        const next = [...prev, newCase];
        sessionStorage.setItem('dev-lexara-cases', JSON.stringify(next));
        return next;
      });
      return newCase;
    }
    if (!user) return null;
    try {
      const { data: row, error } = await supabase
        .from('cases')
        .insert({
          name: newCase.name,
          number: newCase.number,
          court: newCase.court,
          type: newCase.type,
          goal: newCase.goal,
          status: newCase.status,
          instanz: '',
          kernfrage: '',
          fristen: [],
          kosten: null,
          user_id: user.id,
        })
        .select()
        .single();
      if (error) throw error;
      const created: LexaraCase = { ...newCase, id: row.id, created: new Date(row.created_at).toLocaleDateString('de-DE') };
      setCases(prev => [created, ...prev]);
      return created;
    } catch (e: any) {
      console.error(e);
      toast.error('Fall konnte nicht erstellt werden');
      return null;
    }
  }, [user, isDevMode]);
  // Persist full case to DB (debounced)
  const persistToDB = useCallback(async (c: LexaraCase) => {
    if (!user) return;
    try {
      // Update case row
      await supabase.from('cases').update({
        name: c.name, number: c.number, court: c.court, type: c.type,
        goal: c.goal, status: c.status,
        instanz: c.instanz || '', kernfrage: c.kernfrage || '',
        fristen: c.fristen as any, kosten: c.kosten as any,
      }).eq('id', c.id);
      // Sync arguments: delete + re-insert
      await supabase.from('evidence').delete().eq('case_id', c.id);
      await supabase.from('edges').delete().eq('case_id', c.id);
      await supabase.from('arguments').delete().eq('case_id', c.id);
      if (c.arguments.length > 0) {
        const argRows = c.arguments.map(a => ({
          id: a.id,
          case_id: c.id,
          side: a.side,
          label: a.label,
          strength: a.strength,
          content: a.content || '',
          description: a.description || '',
          pos_x: null as number | null,
          pos_y: null as number | null,
        }));
        await supabase.from('arguments').insert(argRows);
      }
      // Edges
      if (c.edges.length > 0) {
        const edgeRows = c.edges.map(e => ({
          case_id: c.id,
          from_arg_id: e.from,
          to_arg_id: e.to,
          type: e.type,
        }));
        await supabase.from('edges').insert(edgeRows);
      }
      // Evidence
      const evRows: any[] = [];
      for (const [argId, evs] of Object.entries(c.evidence)) {
        for (const ev of evs) {
          evRows.push({
            id: ev.id,
            case_id: c.id,
            argument_id: argId,
            name: ev.name,
            description: ev.desc,
            type: ev.type || '',
            validity: ev.validity ?? 50,
            strength: ev.strength ?? 5,
          });
        }
      }
      if (evRows.length > 0) await supabase.from('evidence').insert(evRows);
      // Persons: delete + re-insert
      await supabase.from('persons').delete().eq('case_id', c.id);
      if (c.persons.length > 0) {
        const pRows = c.persons.map(p => ({
          id: p.id,
          case_id: c.id,
          name: p.name,
          role: p.role,
          party: p.party,
          court: p.court,
          historical_cases: p.historicalCases,
          historical_consistency: p.historicalConsistency,
          prior_contradictions: p.priorContradictions,
          plaintiff_win_rate: p.plaintiffWinRate,
          settle_rate: p.settleRate,
          avg_duration: p.avgDuration,
          conflict_of_interest: p.conflictOfInterest,
          hidden_motive: p.hiddenMotive,
          competence_level: p.competenceLevel,
          self_preservation: p.selfPreservation,
          loyalty_signals: p.loyaltySignals,
          fear_factor: p.fearFactor,
          narcissism: p.narcissism,
          cognitive_empathy: p.cognitiveEmpathy,
          affective_empathy: p.affectiveEmpathy,
          manipulation_skill: p.manipulationSkill,
          coldness: p.coldness,
          legal_levers: p.legalLevers as any,
          psych_levers: p.psychLevers as any,
          question_modules: p.questionModules as any,
          past_case_notes: p.pastCaseNotes,
        }));
        await supabase.from('persons').insert(pRows);
      }
    } catch (e: any) {
      console.error('Failed to persist case', e);
      toast.error('Änderungen konnten nicht gespeichert werden');
    }
  }, [user]);
  // Update case (debounced DB write)
  const updateCase = useCallback((updated: LexaraCase) => {
    setCases(prev => {
      const next = prev.map(c => c.id === updated.id ? updated : c);
      if (isDevMode) sessionStorage.setItem('dev-lexara-cases', JSON.stringify(next));
      return next;
    });
    if (isDevMode || !user) return;
    pendingRef.current = updated;
    if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    saveTimerRef.current = setTimeout(() => {
      if (pendingRef.current) {
        persistToDB(pendingRef.current);
        pendingRef.current = null;
      }
    }, 1000);
  }, [user, isDevMode, persistToDB]);
  // Delete case
  const deleteCase = useCallback(async (id: string) => {
    if (isDevMode) {
      setCases(prev => {
        const next = prev.filter(c => c.id !== id);
        sessionStorage.setItem('dev-lexara-cases', JSON.stringify(next));
        return next;
      });
      return;
    }
    if (!user) return;
    try {
      // Cascade: evidence ? edges ? arguments ? persons ? case
      await supabase.from('evidence').delete().eq('case_id', id);
      await supabase.from('edges').delete().eq('case_id', id);
      await supabase.from('arguments').delete().eq('case_id', id);
      await supabase.from('persons').delete().eq('case_id', id);
      const { error } = await supabase.from('cases').delete().eq('id', id);
      if (error) throw error;
      setCases(prev => prev.filter(c => c.id !== id));
    } catch (e: any) {
      console.error(e);
      toast.error('Fall konnte nicht gelöscht werden');
    }
  }, [user, isDevMode]);
  return { cases, loading, addCase, updateCase, deleteCase, reload: load };
}
