import { useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { BusinessScenario, BusinessOption, createEmptyScenario } from '@/types/business';
import { useAuth } from '@/hooks/useAuth';
import { toast } from 'sonner';
import { SEED_BUSINESS_SCENARIOS } from '@/data/seedBusinessScenarios';
/** Convert DB rows ? BusinessScenario with nested options */
function rowToScenario(
  row: any,
  optionRows: any[]
): BusinessScenario {
  const options: BusinessOption[] = optionRows
    .filter(o => o.scenario_id === row.id)
    .sort((a, b) => a.sort_order - b.sort_order)
    .map(o => o.option_data as BusinessOption);
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    category: row.category as any,
    company: row.company,
    created: new Date(row.created_at).toLocaleDateString('de-DE'),
    status: row.status as any,
    options,
    selectedOptionId: row.selected_option_id || undefined,
    notes: row.notes,
    outcomeRating: row.outcome_rating || undefined,
    outcomeNotes: row.outcome_notes || '',
    outcomeDate: row.outcome_date || undefined,
  };
}
export function useBusinessScenarios() {
  const { user } = useAuth();
  const [scenarios, setScenarios] = useState<BusinessScenario[]>([]);
  const [loading, setLoading] = useState(true);
  const isDevMode = !user && sessionStorage.getItem('dev-access') === 'true';
  // Load from DB or seed/localStorage data for dev mode
  const load = useCallback(async () => {
    if (isDevMode) {
      const stored = sessionStorage.getItem('dev-business-scenarios');
      if (stored) {
        try { setScenarios(JSON.parse(stored)); } catch { setScenarios(SEED_BUSINESS_SCENARIOS); }
      } else {
        setScenarios(SEED_BUSINESS_SCENARIOS);
      }
      setLoading(false);
      return;
    }
    if (!user) { setLoading(false); return; }
    try {
      const { data: sRows, error: sErr } = await supabase
        .from('business_scenarios')
        .select('*')
        .order('created_at', { ascending: false });
      if (sErr) throw sErr;
      const { data: oRows, error: oErr } = await supabase
        .from('business_options')
        .select('*');
      if (oErr) throw oErr;
      setScenarios((sRows || []).map(s => rowToScenario(s, oRows || [])));
    } catch (e: any) {
      console.error('Failed to load scenarios', e);
      toast.error('Szenarien konnten nicht geladen werden');
    } finally {
      setLoading(false);
    }
  }, [user, isDevMode]);
  useEffect(() => { load(); }, [load]);
  const addScenario = useCallback(async (s: BusinessScenario): Promise<BusinessScenario | null> => {
    if (isDevMode) {
      setScenarios(prev => {
        const next = [...prev, s];
        sessionStorage.setItem('dev-business-scenarios', JSON.stringify(next));
        return next;
      });
      return s;
    }
    if (!user) return null;
    try {
      const { data, error } = await supabase
        .from('business_scenarios')
        .insert({
          user_id: user.id,
          title: s.title,
          description: s.description,
          category: s.category,
          company: s.company,
          status: s.status,
          notes: s.notes,
        })
        .select()
        .single();
      if (error) throw error;
      const created = rowToScenario(data, []);
      setScenarios(prev => [created, ...prev]);
      return created;
    } catch (e: any) {
      toast.error('Szenario konnte nicht erstellt werden');
      console.error(e);
      return null;
    }
  }, [user, isDevMode]);
  // Debounced DB persistence ref
  const saveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingUpdateRef = useRef<BusinessScenario | null>(null);
  const persistToDB = useCallback(async (updated: BusinessScenario) => {
    if (!user) return;
    try {
      const { error: sErr } = await supabase
        .from('business_scenarios')
        .update({
          title: updated.title,
          description: updated.description,
          category: updated.category,
          company: updated.company,
          status: updated.status,
          selected_option_id: updated.selectedOptionId || null,
          notes: updated.notes,
          outcome_rating: updated.outcomeRating || null,
          outcome_notes: updated.outcomeNotes || '',
          outcome_date: updated.outcomeRating ? (updated.outcomeDate || new Date().toISOString()) : null,
        })
        .eq('id', updated.id);
      if (sErr) throw sErr;
      await supabase
        .from('business_options')
        .delete()
        .eq('scenario_id', updated.id);
      if (updated.options.length > 0) {
        const optRows = updated.options.map((o, i) => ({
          scenario_id: updated.id,
          option_data: o as any,
          sort_order: i,
        }));
        const { error: oErr } = await supabase
          .from('business_options')
          .insert(optRows);
        if (oErr) throw oErr;
      }
    } catch (e: any) {
      toast.error('Änderungen konnten nicht gespeichert werden');
      console.error(e);
    }
  }, [user]);
  const updateScenario = useCallback(async (updated: BusinessScenario) => {
    setScenarios(prev => {
      const next = prev.map(s => s.id === updated.id ? updated : s);
      if (isDevMode) sessionStorage.setItem('dev-business-scenarios', JSON.stringify(next));
      return next;
    });
    if (isDevMode) return;
    if (!user) return;
    // Debounce DB writes (800ms)
    pendingUpdateRef.current = updated;
    if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    saveTimerRef.current = setTimeout(() => {
      if (pendingUpdateRef.current) {
        persistToDB(pendingUpdateRef.current);
        pendingUpdateRef.current = null;
      }
    }, 800);
  }, [user, isDevMode, persistToDB]);
  const deleteScenario = useCallback(async (id: string) => {
    if (isDevMode) {
      setScenarios(prev => {
        const next = prev.filter(s => s.id !== id);
        sessionStorage.setItem('dev-business-scenarios', JSON.stringify(next));
        return next;
      });
      return;
    }
    if (!user) return;
    try {
      const { error } = await supabase
        .from('business_scenarios')
        .delete()
        .eq('id', id);
      if (error) throw error;
      setScenarios(prev => prev.filter(s => s.id !== id));
    } catch (e: any) {
      toast.error('Szenario konnte nicht gelöscht werden');
      console.error(e);
    }
  }, [user, isDevMode]);
  return { scenarios, loading, addScenario, updateScenario, deleteScenario, reload: load };
}
