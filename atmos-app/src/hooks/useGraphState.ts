import { useState, useCallback, useRef } from 'react';
import { ArgumentNode, ArgumentEdge, GraphState, ArgumentType, RelationType, ArgumentStrength } from '@/types/argument';
const INITIAL_NODES: ArgumentNode[] = [
  {
    id: '1',
    type: 'claim',
    title: 'Breach of Contract',
    description: 'Defendant failed to deliver goods as specified in Section 4.2 of the agreement dated March 15, 2024.',
    strength: 5,
    x: 500,
    y: 200,
    caseReference: 'Smith v. Johnson, 2023',
    legalBasis: 'UCC § 2-301',
    paragraphs: [],
    fileLinks: [],
    createdAt: new Date(),
  },
  {
    id: '2',
    type: 'evidence',
    title: 'Delivery Records',
    description: 'Shipping manifests show delivery was 45 days past the contractual deadline with incomplete inventory.',
    strength: 4,
    x: 250,
    y: 400,
    paragraphs: [],
    fileLinks: [],
    createdAt: new Date(),
  },
  {
    id: '3',
    type: 'evidence',
    title: 'Email Correspondence',
    description: 'Chain of emails between parties acknowledging the delay and proposed remediation plan.',
    strength: 3,
    x: 750,
    y: 400,
    caseReference: 'Exhibit B',
    paragraphs: [],
    fileLinks: [],
    createdAt: new Date(),
  },
  {
    id: '4',
    type: 'counterargument',
    title: 'Force Majeure Defense',
    description: 'Defendant claims supply chain disruptions constituted force majeure under Section 12.1.',
    strength: 3,
    x: 500,
    y: 580,
    legalBasis: 'Restatement (Second) § 261',
    paragraphs: [],
    fileLinks: [],
    createdAt: new Date(),
  },
  {
    id: '5',
    type: 'rebuttal',
    title: 'Pre-existing Conditions',
    description: 'Supply chain issues were foreseeable and defendant failed to implement mitigation measures.',
    strength: 4,
    x: 250,
    y: 720,
    caseReference: 'Taylor v. Caldwell, 1863',
    paragraphs: [],
    fileLinks: [],
    createdAt: new Date(),
  },
  {
    id: '6',
    type: 'premise',
    title: 'Duty of Good Faith',
    description: 'All parties to a contract have an implied duty of good faith and fair dealing.',
    strength: 5,
    x: 750,
    y: 720,
    legalBasis: 'UCC § 1-304',
    paragraphs: [],
    fileLinks: [],
    createdAt: new Date(),
  },
];
const INITIAL_EDGES: ArgumentEdge[] = [
  { id: 'e1', source: '2', target: '1', relation: 'support', label: 'Documents breach' },
  { id: 'e2', source: '3', target: '1', relation: 'support', label: 'Confirms timeline' },
  { id: 'e3', source: '4', target: '1', relation: 'attack', label: 'Excuses performance' },
  { id: 'e4', source: '5', target: '4', relation: 'attack', label: 'Undermines defense' },
  { id: 'e5', source: '6', target: '4', relation: 'attack', label: 'Imposes obligation' },
];
const MAX_HISTORY = 50;
interface HistoryEntry {
  nodes: ArgumentNode[];
  edges: ArgumentEdge[];
}
// Serialize state for JSON export (dates ? strings)
function serializeState(state: GraphState) {
  return {
    nodes: state.nodes.map(n => ({ ...n, createdAt: n.createdAt instanceof Date ? n.createdAt.toISOString() : n.createdAt })),
    edges: state.edges,
  };
}
// Deserialize loaded JSON (strings ? dates)
function deserializeNodes(nodes: any[]): ArgumentNode[] {
  return nodes.map(n => ({ ...n, createdAt: new Date(n.createdAt) }));
}
export function useGraphState() {
  const [state, setState] = useState<GraphState>({
    nodes: INITIAL_NODES,
    edges: INITIAL_EDGES,
    selectedNodeId: null,
    zoom: 1,
    panX: 0,
    panY: 0,
  });
  // Undo/redo history
  const historyRef = useRef<HistoryEntry[]>([{ nodes: INITIAL_NODES, edges: INITIAL_EDGES }]);
  const historyIndexRef = useRef(0);
  const skipHistoryRef = useRef(false);
  const pushHistory = useCallback((nodes: ArgumentNode[], edges: ArgumentEdge[]) => {
    if (skipHistoryRef.current) return;
    const idx = historyIndexRef.current;
    // Truncate future history
    historyRef.current = historyRef.current.slice(0, idx + 1);
    historyRef.current.push({ nodes, edges });
    if (historyRef.current.length > MAX_HISTORY) {
      historyRef.current.shift();
    } else {
      historyIndexRef.current = historyRef.current.length - 1;
    }
  }, []);
  const undo = useCallback(() => {
    if (historyIndexRef.current <= 0) return;
    historyIndexRef.current -= 1;
    const entry = historyRef.current[historyIndexRef.current];
    skipHistoryRef.current = true;
    setState(prev => ({ ...prev, nodes: entry.nodes, edges: entry.edges, selectedNodeId: null }));
    skipHistoryRef.current = false;
  }, []);
  const redo = useCallback(() => {
    if (historyIndexRef.current >= historyRef.current.length - 1) return;
    historyIndexRef.current += 1;
    const entry = historyRef.current[historyIndexRef.current];
    skipHistoryRef.current = true;
    setState(prev => ({ ...prev, nodes: entry.nodes, edges: entry.edges, selectedNodeId: null }));
    skipHistoryRef.current = false;
  }, []);
  const canUndo = historyIndexRef.current > 0;
  const canRedo = historyIndexRef.current < historyRef.current.length - 1;
  const selectNode = useCallback((id: string | null) => {
    setState(prev => ({ ...prev, selectedNodeId: id }));
  }, []);
  const moveNode = useCallback((id: string, x: number, y: number) => {
    setState(prev => ({
      ...prev,
      nodes: prev.nodes.map(n => n.id === id ? { ...n, x, y } : n),
    }));
    // Note: move doesn't push history on every pixel ? we push on mouseup via commitMove
  }, []);
  const commitMove = useCallback(() => {
    setState(prev => {
      pushHistory(prev.nodes, prev.edges);
      return prev;
    });
  }, [pushHistory]);
  const addNode = useCallback((
    type: ArgumentType,
    title: string,
    description: string,
    strength: ArgumentStrength,
    opts?: { caseReference?: string; legalBasis?: string }
  ) => {
    const id = Date.now().toString();
    const newNode: ArgumentNode = {
      id,
      type,
      title,
      description,
      strength,
      x: 400 + Math.random() * 200,
      y: 300 + Math.random() * 200,
      caseReference: opts?.caseReference,
      legalBasis: opts?.legalBasis,
      paragraphs: [],
      fileLinks: [],
      createdAt: new Date(),
    };
    setState(prev => {
      const newState = { ...prev, nodes: [...prev.nodes, newNode], selectedNodeId: id };
      pushHistory(newState.nodes, newState.edges);
      return newState;
    });
    return id;
  }, [pushHistory]);
  const updateNode = useCallback((id: string, updates: Partial<ArgumentNode>) => {
    setState(prev => {
      const newNodes = prev.nodes.map(n => n.id === id ? { ...n, ...updates } : n);
      pushHistory(newNodes, prev.edges);
      return { ...prev, nodes: newNodes };
    });
  }, [pushHistory]);
  const deleteNode = useCallback((id: string) => {
    setState(prev => {
      const newNodes = prev.nodes.filter(n => n.id !== id);
      const newEdges = prev.edges.filter(e => e.source !== id && e.target !== id);
      pushHistory(newNodes, newEdges);
      return {
        ...prev,
        nodes: newNodes,
        edges: newEdges,
        selectedNodeId: prev.selectedNodeId === id ? null : prev.selectedNodeId,
      };
    });
  }, [pushHistory]);
  const addEdge = useCallback((source: string, target: string, relation: RelationType, label?: string) => {
    const id = `e-${Date.now()}`;
    setState(prev => {
      const newEdges = [...prev.edges, { id, source, target, relation, label }];
      pushHistory(prev.nodes, newEdges);
      return { ...prev, edges: newEdges };
    });
  }, [pushHistory]);
  const deleteEdge = useCallback((id: string) => {
    setState(prev => {
      const newEdges = prev.edges.filter(e => e.id !== id);
      pushHistory(prev.nodes, newEdges);
      return { ...prev, edges: newEdges };
    });
  }, [pushHistory]);
  const updateEdge = useCallback((id: string, updates: Partial<ArgumentEdge>) => {
    setState(prev => {
      const newEdges = prev.edges.map(e => e.id === id ? { ...e, ...updates } : e);
      pushHistory(prev.nodes, newEdges);
      return { ...prev, edges: newEdges };
    });
  }, [pushHistory]);
  const setZoom = useCallback((zoom: number) => {
    setState(prev => ({ ...prev, zoom: Math.max(0.3, Math.min(2, zoom)) }));
  }, []);
  const setPan = useCallback((panX: number, panY: number) => {
    setState(prev => ({ ...prev, panX, panY }));
  }, []);
  // Save/Load JSON
  const saveToJson = useCallback(() => {
    const data = serializeState(state);
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `argument-graph-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, [state]);
  const loadFromJson = useCallback((file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target?.result as string);
        if (!data.nodes || !data.edges) throw new Error('Invalid format');
        const nodes = deserializeNodes(data.nodes);
        const edges = data.edges as ArgumentEdge[];
        setState(prev => ({ ...prev, nodes, edges, selectedNodeId: null }));
        pushHistory(nodes, edges);
      } catch {
        // Error handled by caller via toast
        throw new Error('Invalid JSON file');
      }
    };
    reader.readAsText(file);
  }, [pushHistory]);
  return {
    state,
    selectNode,
    moveNode,
    commitMove,
    addNode,
    updateNode,
    deleteNode,
    addEdge,
    deleteEdge,
    updateEdge,
    setZoom,
    setPan,
    undo,
    redo,
    canUndo,
    canRedo,
    saveToJson,
    loadFromJson,
  };
}
