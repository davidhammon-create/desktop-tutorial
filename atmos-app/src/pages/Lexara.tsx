import React, { useState, useCallback } from 'react';
import { useLexaraCases } from '@/hooks/useLexaraCases';
import { LexaraCase } from '@/types/lexara';
import { CaseListView } from '@/components/lexara/CaseListView';
import { CaseWorkflow } from '@/components/lexara/CaseWorkflow';
type View =
  | { type: 'case-list' }
  | { type: 'case-workflow'; caseId: string };
const LexaraPage = () => {
  const { cases, loading, addCase, updateCase, deleteCase } = useLexaraCases();
  const [view, setView] = useState<View>({ type: 'case-list' });
  const handleAddCase = useCallback(async (data: Partial<LexaraCase>) => {
    const created = await addCase(data);
    if (created) {
      setView({ type: 'case-workflow', caseId: created.id });
    }
  }, [addCase]);
  const handleDeleteCase = useCallback(async (id: string) => {
    await deleteCase(id);
    if (view.type === 'case-workflow' && view.caseId === id) {
      setView({ type: 'case-list' });
    }
  }, [view, deleteCase]);
  const getCase = (id: string) => cases.find(c => c.id === id);
  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', color: '#888' }}>
        Lade Fälle?
      </div>
    );
  }
  switch (view.type) {
    case 'case-list':
      return (
        <CaseListView
          cases={cases}
          onSelect={(id) => setView({ type: 'case-workflow', caseId: id })}
          onAddCase={handleAddCase}
          onUpdateCase={updateCase}
          onDeleteCase={handleDeleteCase}
        />
      );
    case 'case-workflow': {
      const activeCase = getCase(view.caseId);
      if (!activeCase) return (
        <CaseListView
          cases={cases}
          onSelect={(id) => setView({ type: 'case-workflow', caseId: id })}
          onAddCase={handleAddCase}
          onUpdateCase={updateCase}
          onDeleteCase={handleDeleteCase}
        />
      );
      return (
        <CaseWorkflow
          c={activeCase}
          onBack={() => setView({ type: 'case-list' })}
          onUpdateCase={updateCase}
        />
      );
    }
    default:
      return null;
  }
};
export default LexaraPage;
