import React, { useState, useCallback, useMemo, useEffect, useRef } from 'react';
import { LexaraCase, LexaraArgument, LexaraEdge } from '@/types/lexara';
import { ArgumentNode, ArgumentEdge, ArgumentType, RelationType, ArgumentStrength } from '@/types/argument';
import { computeAutoLayout } from '@/lib/autoLayout';
import { NODE_WIDTH, NODE_HEIGHT } from '@/components/graph/GraphNode';
import { GraphCanvas } from '@/components/graph/GraphCanvas';
import { GraphToolbar } from '@/components/graph/GraphToolbar';
import { NodeDetailPanel } from '@/components/graph/NodeDetailPanel';
import { AddNodeDialog } from '@/components/graph/AddNodeDialog';
import { ConnectionDialog } from '@/components/graph/ConnectionDialog';
import { GraphOverlays } from '@/components/graph/GraphOverlays';
import { useGraphHistory } from '@/hooks/useGraphHistory';
import { T } from './theme';
interface InteractiveGraphTabProps {
  c: LexaraCase;
  onUpdateCase: (updated: LexaraCase) => void;
}
function sideToType(side: 'own' | 'opp'): ArgumentType {
  return side === 'own' ? 'claim' : 'counterargument';
}
function typeToSide(type: ArgumentType): 'own' | 'opp' {
  return type === 'counterargument' || type === 'rebuttal' ? 'opp' : 'own';
}
function lexaraEdgeToRelation(type: string): RelationType {
  if (type === 'supports') return 'support';
  if (type === 'weakens' || type === 'exclude') return 'attack';
  if (type === 'causal') return 'causal';
  return 'neutral';
}
function relationToLexaraEdge(rel: RelationType): LexaraEdge['type'] {
  if (rel === 'support') return 'supports';
  if (rel === 'attack') return 'weakens';
  if (rel === 'causal') return 'causal';
  return 'supports';
}
function strengthToScale(s: number): ArgumentStrength {
  return Math.max(1, Math.min(5, Math.round(s / 2))) as ArgumentStrength;
}
export function InteractiveGraphTab({ c, onUpdateCase }: InteractiveGraphTabProps) {
  const initialNodes: ArgumentNode[] = useMemo(
    () => {
      const argNodes: ArgumentNode[] = c.arguments.map((a, i) => ({
        id: a.id,
        type: sideToType(a.side),
        title: a.label,
        description: a.content || a.description || '',
        strength: strengthToScale(a.strength),
        x: a.side === 'own' ? 120 + (i % 3) * 240 : 600 + (i % 3) * 240,
        y: 80 + Math.floor(i / 3) * 160,
        paragraphs: [],
        fileLinks: [],
        createdAt: new Date(),
        side: a.side,
      }));
      // Add fristen as nodes (both sides)
      const fristNodes: ArgumentNode[] = (c.fristen || []).map((f, i) => ({
        id: `frist-${f.id}`,
        type: 'frist' as ArgumentType,
        title: `? ${f.type}`,
        description: `${f.paragraph} ? Fällig: ${f.date} ? ${f.status}${f.notes ? ' ? ' + f.notes : ''}`,
        strength: (f.abzugMax && f.abzugMax >= 80 ? 5 : f.abzugMax && f.abzugMax >= 40 ? 3 : 1) as ArgumentStrength,
        x: f.side === 'own' ? 50 + (i % 2) * 220 : 700 + (i % 2) * 220,
        y: 500 + Math.floor(i / 2) * 140,
        paragraphs: [],
        fileLinks: [],
        createdAt: new Date(),
        side: f.side,
      }));
      // Derive risk/chance nodes from case data
      const metaNodes: ArgumentNode[] = [];
      const ownArgs = c.arguments.filter(a => a.side === 'own');
      const oppArgs = c.arguments.filter(a => a.side === 'opp');

      // Risks: weak own args without evidence
      const weakOwn = ownArgs.filter(a => a.strength >= 5 && !(c.evidence[a.id]?.length));
      if (weakOwn.length > 0) {
        metaNodes.push({
          id: 'risk-evidence-gap', type: 'risiko', title: '?? Beweislücken',
          description: `${weakOwn.length} starke(s) Argument(e) ohne Beweismittel: ${weakOwn.map(a => a.label).join(', ')}`,
          strength: (weakOwn.length >= 3 ? 5 : 3) as ArgumentStrength,
          x: 400, y: 650, paragraphs: [], fileLinks: [], createdAt: new Date(), side: 'own',
        });
      }
      // Chances: strong own args with strong evidence
      const strongOwn = ownArgs.filter(a => a.strength >= 7 && (c.evidence[a.id]?.length || 0) >= 2);
      if (strongOwn.length > 0) {
        metaNodes.push({
          id: 'chance-strong', type: 'chance', title: '? Starke Position',
          description: `${strongOwn.length} gut belegte(s) Argument(e): ${strongOwn.map(a => a.label).join(', ')}`,
          strength: (strongOwn.length >= 2 ? 5 : 3) as ArgumentStrength,
          x: 100, y: 650, paragraphs: [], fileLinks: [], createdAt: new Date(), side: 'own',
        });
      }
      // Problems: strong opponent args
      const strongOpp = oppArgs.filter(a => a.strength >= 7);
      if (strongOpp.length > 0) {
        metaNodes.push({
          id: 'problem-opp-strong', type: 'problem', title: '? Gegner stark',
          description: `${strongOpp.length} starke(s) Gegenargument(e): ${strongOpp.map(a => a.label).join(', ')}`,
          strength: (strongOpp.length >= 2 ? 5 : 3) as ArgumentStrength,
          x: 800, y: 650, paragraphs: [], fileLinks: [], createdAt: new Date(), side: 'opp',
        });
      }
      // Advantages: weak opponent args
      const weakOpp = oppArgs.filter(a => a.strength < 4);
      if (weakOpp.length > 0) {
        metaNodes.push({
          id: 'vorteil-opp-weak', type: 'vorteil', title: '? Gegner-Schwäche',
          description: `${weakOpp.length} schwache(s) Gegenargument(e) ? angreifbar: ${weakOpp.map(a => a.label).join(', ')}`,
          strength: 3 as ArgumentStrength,
          x: 600, y: 700, paragraphs: [], fileLinks: [], createdAt: new Date(), side: 'own',
        });
      }
      // Missed frist risk
      const missedFristen = (c.fristen || []).filter(f => f.status === 'versäumt' && f.side === 'own');
      if (missedFristen.length > 0) {
        metaNodes.push({
          id: 'risk-missed-frist', type: 'risiko', title: '? Versäumte Fristen',
          description: `${missedFristen.length} versäumte Frist(en): ${missedFristen.map(f => f.type).join(', ')}. Prognoseabzug!`,
          strength: 5 as ArgumentStrength,
          x: 300, y: 750, paragraphs: [], fileLinks: [], createdAt: new Date(), side: 'own',
        });
      }
      return [...argNodes, ...fristNodes, ...metaNodes];
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [c.id],
  );
  const initialEdges: ArgumentEdge[] = useMemo(
    () =>
      c.edges.map((e, i) => ({
        id: `le-${i}`,
        source: e.from,
        target: e.to,
        relation: lexaraEdgeToRelation(e.type),
        label: e.type === 'exclude' ? 'schließt aus' : e.type === 'weakens' ? 'entkräftet' : 'stützt',
      })),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [c.id],
  );
  const history = useGraphHistory(initialNodes, initialEdges);
  const { nodes, edges, push, undo, redo, canUndo, canRedo, reset, startBatch, endBatch } = history;
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const [zoom, setZoomState] = useState(0.85);
  const [panX, setPanX] = useState(40);
  const [panY, setPanY] = useState(40);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [clickConnectMode, setClickConnectMode] = useState(false);
  const [clickConnectSource, setClickConnectSource] = useState<string | null>(null);
  const [clickConnectDialog, setClickConnectDialog] = useState<{ source: string; target: string } | null>(null);
  // Keep refs for sync
  const nodesRef = useRef(nodes);
  nodesRef.current = nodes;
  const edgesRef = useRef(edges);
  edgesRef.current = edges;
  useEffect(() => {
    reset(initialNodes, initialEdges);
    setSelectedNodeId(null);
  }, [c.id, initialNodes, initialEdges, reset]);
  // Sync graph state back to Lexara case
  const syncToCase = useCallback(
    (newNodes: ArgumentNode[], newEdges: ArgumentEdge[]) => {
      const updatedArgs: LexaraArgument[] = newNodes.map((n) => ({
        id: n.id,
        side: typeToSide(n.type),
        label: n.title,
        strength: n.strength * 2,
        content: n.description,
        description: n.description,
      }));
      const updatedEdges: LexaraEdge[] = newEdges.map((e) => ({
        from: e.source,
        to: e.target,
        type: relationToLexaraEdge(e.relation),
      }));
      const newEvidence = { ...c.evidence };
      const ids = new Set(updatedArgs.map((a) => a.id));
      for (const key of Object.keys(newEvidence)) {
        if (!ids.has(key)) delete newEvidence[key];
      }
      for (const a of updatedArgs) {
        if (!newEvidence[a.id]) newEvidence[a.id] = [];
      }
      onUpdateCase({ ...c, arguments: updatedArgs, edges: updatedEdges, evidence: newEvidence });
    },
    [c, onUpdateCase],
  );
  // Positions are now persisted via the full case save in useLexaraCases
  // Auto-sync on undo/redo
  useEffect(() => {
    syncToCase(nodes, edges);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [nodes, edges]);
  const setZoom = useCallback((z: number) => setZoomState(Math.max(0.3, Math.min(2, z))), []);
  const setPan = useCallback((x: number, y: number) => {
    setPanX(x);
    setPanY(y);
  }, []);
  // We need direct node state for dragging without history pushes
  const [liveNodes, setLiveNodes] = useState<ArgumentNode[] | null>(null);
  const displayNodes = liveNodes || nodes;
  const handleMoveNode = useCallback((id: string, x: number, y: number) => {
    setLiveNodes((prev) => {
      const base = prev || nodesRef.current;
      return base.map((n) => (n.id === id ? { ...n, x, y } : n));
    });
  }, []);
  const handleCommitMove = useCallback(() => {
    if (liveNodes) {
      push(liveNodes, edgesRef.current);
      setLiveNodes(null);
    }
  }, [liveNodes, push]);
  const handleStartDrag = useCallback(() => {
    // snapshot live nodes from current history
    setLiveNodes(nodesRef.current);
  }, []);
  const addNode = useCallback(
    (type: ArgumentType, title: string, description: string, strength: ArgumentStrength) => {
      const id = `n-${Date.now()}`;
      const newNode: ArgumentNode = {
        id,
        type,
        title,
        description,
        strength,
        x: 300 + Math.random() * 200,
        y: 200 + Math.random() * 200,
        paragraphs: [],
        fileLinks: [],
        createdAt: new Date(),
      };
      const updated = [...nodesRef.current, newNode];
      push(updated, edgesRef.current);
      setSelectedNodeId(id);
      return id;
    },
    [push],
  );
  const updateNode = useCallback(
    (id: string, updates: Partial<ArgumentNode>) => {
      const updated = nodesRef.current.map((n) => (n.id === id ? { ...n, ...updates } : n));
      push(updated, edgesRef.current);
    },
    [push],
  );
  const handleInlineEdit = useCallback(
    (id: string, title: string, description: string) => {
      const updated = nodesRef.current.map((n) =>
        n.id === id ? { ...n, title, description } : n
      );
      push(updated, edgesRef.current);
    },
    [push],
  );
  const deleteNode = useCallback(
    (id: string) => {
      const updatedNodes = nodesRef.current.filter((n) => n.id !== id);
      const updatedEdges = edgesRef.current.filter((e) => e.source !== id && e.target !== id);
      push(updatedNodes, updatedEdges);
      setSelectedNodeId(null);
    },
    [push],
  );
  const addEdge = useCallback(
    (source: string, target: string, relation: RelationType, label?: string) => {
      const id = `ge-${Date.now()}`;
      const updated = [...edgesRef.current, { id, source, target, relation, label }];
      push(nodesRef.current, updated);
    },
    [push],
  );
  const deleteEdge = useCallback(
    (id: string) => {
      const updated = edgesRef.current.filter((e) => e.id !== id);
      push(nodesRef.current, updated);
    },
    [push],
  );
  const updateEdge = useCallback(
    (id: string, updates: Partial<ArgumentEdge>) => {
      const updated = edgesRef.current.map((e) => (e.id === id ? { ...e, ...updates } : e));
      push(nodesRef.current, updated);
    },
    [push],
  );
  const handleClickConnectSelect = useCallback(
    (nodeId: string) => {
      if (!clickConnectSource) {
        setClickConnectSource(nodeId);
      } else if (clickConnectSource !== nodeId) {
        const exists = edgesRef.current.some(
          (e) =>
            (e.source === clickConnectSource && e.target === nodeId) ||
            (e.source === nodeId && e.target === clickConnectSource),
        );
        if (!exists) setClickConnectDialog({ source: clickConnectSource, target: nodeId });
        setClickConnectSource(null);
      }
    },
    [clickConnectSource],
  );
  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'z' && !e.shiftKey) {
        e.preventDefault();
        undo();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === 'z' && e.shiftKey) {
        e.preventDefault();
        redo();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === 'y') {
        e.preventDefault();
        redo();
      }
      if (e.key === 'Delete' || e.key === 'Backspace') {
        if (selectedNodeId && document.activeElement === document.body) {
          e.preventDefault();
          deleteNode(selectedNodeId);
        }
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [undo, redo, selectedNodeId, deleteNode]);
  const selectedNode = displayNodes.find((n) => n.id === selectedNodeId) || null;
  return (
    <div style={{ position: 'absolute', inset: 0 }}>
      <GraphCanvas
        nodes={displayNodes}
        edges={edges}
        selectedNodeId={selectedNodeId}
        zoom={zoom}
        panX={panX}
        panY={panY}
        clickConnectMode={clickConnectMode}
        clickConnectSource={clickConnectSource}
        onSelectNode={setSelectedNodeId}
        onMoveNode={handleMoveNode}
        onCommitMove={handleCommitMove}
        onZoom={setZoom}
        onPan={setPan}
        onAddEdge={addEdge}
        onDeleteEdge={deleteEdge}
        onUpdateEdge={updateEdge}
        onClickConnectSelect={handleClickConnectSelect}
        onInlineEdit={handleInlineEdit}
      />
      <GraphToolbar
        zoom={zoom}
        onZoomIn={() => setZoom(zoom + 0.1)}
        onZoomOut={() => setZoom(zoom - 0.1)}
        onResetView={() => {
          setZoom(1);
          setPan(0, 0);
        }}
        onFitView={() => {
          if (displayNodes.length === 0) return;
          const xs = displayNodes.map((n) => n.x);
          const ys = displayNodes.map((n) => n.y);
          const minX = Math.min(...xs) - 100;
          const minY = Math.min(...ys) - 100;
          const maxX = Math.max(...xs) + NODE_WIDTH + 100;
          const maxY = Math.max(...ys) + NODE_HEIGHT + 100;
          const w = maxX - minX;
          const h = maxY - minY;
          const newZoom = Math.min(window.innerWidth / w, window.innerHeight / h, 1.5) * 0.85;
          setZoom(newZoom);
          setPan(-minX * newZoom + 40, -minY * newZoom + 40);
        }}
        onAddNode={() => setShowAddDialog(true)}
        nodeCount={displayNodes.length}
        edgeCount={edges.length}
        clickConnectMode={clickConnectMode}
        onToggleClickConnect={() => {
          setClickConnectMode((prev) => !prev);
          setClickConnectSource(null);
        }}
        onUndo={undo}
        onRedo={redo}
        canUndo={canUndo}
        canRedo={canRedo}
        onSave={() => {
          const blob = new Blob([JSON.stringify({ nodes: displayNodes, edges }, null, 2)], { type: 'application/json' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'graph.json';
          a.click();
          URL.revokeObjectURL(url);
        }}
        onLoad={(file) => {
          const reader = new FileReader();
          reader.onload = (e) => {
            try {
              const data = JSON.parse(e.target?.result as string);
              if (data.nodes && data.edges) {
                push(data.nodes, data.edges);
              }
            } catch {}
          };
          reader.readAsText(file);
        }}
        onAutoLayout={() => {
          const positions = computeAutoLayout(displayNodes, edges);
          const updated = displayNodes.map((n) => {
            const pos = positions.find((p: any) => p.id === n.id);
            return pos ? { ...n, x: pos.x, y: pos.y } : n;
          });
          push(updated, edges);
        }}
      />
      <GraphOverlays nodes={displayNodes} />
      <NodeDetailPanel node={selectedNode} onClose={() => setSelectedNodeId(null)} onDelete={deleteNode} onUpdate={updateNode} />
      <AddNodeDialog isOpen={showAddDialog} onClose={() => setShowAddDialog(false)} onAdd={addNode} />
      <ConnectionDialog
        isOpen={!!clickConnectDialog}
        onClose={() => setClickConnectDialog(null)}
        onConfirm={(relation, label) => {
          if (clickConnectDialog) addEdge(clickConnectDialog.source, clickConnectDialog.target, relation, label);
          setClickConnectDialog(null);
        }}
      />
    </div>
  );
}
