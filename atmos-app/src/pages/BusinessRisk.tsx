import React, { useState, useCallback } from 'react';
import { BusinessScenario } from '@/types/business';
import { useBusinessScenarios } from '@/hooks/useBusinessScenarios';
import { ScenarioListView } from '@/components/business/ScenarioListView';
import { ScenarioWorkflow } from '@/components/business/ScenarioWorkflow';
import { T, sans } from '@/components/lexara/theme';
type View =
  | { type: 'list' }
  | { type: 'workflow'; scenarioId: string };
const BusinessRiskPage = () => {
  const { scenarios, loading, addScenario, updateScenario, deleteScenario } = useBusinessScenarios();
  const [view, setView] = useState<View>({ type: 'list' });
  const handleAdd = useCallback(async (s: BusinessScenario) => {
    const created = await addScenario(s);
    if (created) {
      setView({ type: 'workflow', scenarioId: created.id });
    }
  }, [addScenario]);
  const handleUpdate = useCallback((updated: BusinessScenario) => {
    updateScenario(updated);
  }, [updateScenario]);
  const handleDelete = useCallback((id: string) => {
    deleteScenario(id);
    if (view.type === 'workflow' && view.scenarioId === id) {
      setView({ type: 'list' });
    }
  }, [deleteScenario, view]);
  if (loading) {
    return (
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        minHeight: '100vh', fontFamily: sans, color: T.dim, background: T.bg,
      }}>
        Szenarien werden geladen?
      </div>
    );
  }
  const getScenario = (id: string) => scenarios.find(s => s.id === id);
  if (view.type === 'workflow') {
    const active = getScenario(view.scenarioId);
    if (!active) {
      return <ScenarioListView scenarios={scenarios} onSelect={id => setView({ type: 'workflow', scenarioId: id })} onAdd={handleAdd} onDelete={handleDelete} />;
    }
    return <ScenarioWorkflow scenario={active} onBack={() => setView({ type: 'list' })} onUpdate={handleUpdate} />;
  }
  return <ScenarioListView scenarios={scenarios} onSelect={id => setView({ type: 'workflow', scenarioId: id })} onAdd={handleAdd} onDelete={handleDelete} />;
};
export default BusinessRiskPage;
