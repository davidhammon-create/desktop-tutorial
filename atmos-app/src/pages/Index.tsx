import React, { useState, useCallback, useEffect } from 'react';
import { computeAutoLayout } from '@/lib/autoLayout';
import { motion } from 'framer-motion';
import { Scale, Info } from 'lucide-react';
import { RelationType } from '@/types/argument';
import { GraphCanvas } from '@/components/graph/GraphCanvas';
import { GraphToolbar } from '@/components/graph/GraphToolbar';
import { NodeDetailPanel } from '@/components/graph/NodeDetailPanel';
import { AddNodeDialog } from '@/components/graph/AddNodeDialog';
import { ConnectionDialog } from '@/components/graph/ConnectionDialog';
import { useGraphState } from '@/hooks/useGraphState';
const Index = () => {
  const {
    state, selectNode, moveNode, commitMove, addNode, updateNode, deleteNode,
    addEdge, deleteEdge, updateEdge, setZoom, setPan, undo, redo, canUndo, canRedo,
    saveToJson, loadFromJson,
  } = useGraphState();
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [clickConnectMode, setClickConnectMode] = useState(false);
  const [clickConnectSource, setClickConnectSource] = useState<string | null>(null);
  const [clickConnectDialog, setClickConnectDialog] = useState<{ source: string; target: string } | null>(null);
  // Keyboard shortcuts for undo/redo
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'z' && !e.shiftKey) { e.preventDefault(); undo(); }
      if ((e.metaKey || e.ctrlKey) && e.key === 'z' && e.shiftKey) { e.preventDefault(); redo(); }
      if ((e.metaKey || e.ctrlKey) && e.key === 'y') { e.preventDefault(); redo(); }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [undo, redo]);
  const handleClickConnectSelect = useCallback((nodeId: string) => {
    if (!clickConnectSource) {
      setClickConnectSource(nodeId);
    } else if (clickConnectSource !== nodeId) {
      const exists = state.edges.some(
        e => (e.source === clickConnectSource && e.target === nodeId) ||
             (e.source === nodeId && e.target === clickConnectSource)
      );
      if (!exists) setClickConnectDialog({ source: clickConnectSource, target: nodeId });
      setClickConnectSource(null);
    }
  }, [clickConnectSource, state.edges]);
  const handleClickConnectConfirm = useCallback((relation: RelationType, label?: string) => {
    if (clickConnectDialog) addEdge(clickConnectDialog.source, clickConnectDialog.target, relation, label);
    setClickConnectDialog(null);
  }, [clickConnectDialog, addEdge]);
  const selectedNode = state.nodes.find(n => n.id === state.selectedNodeId) || null;
  const handleResetView = useCallback(() => { setZoom(1); setPan(0, 0); }, [setZoom, setPan]);
  const handleAutoLayout = useCallback(() => {
    const positions = computeAutoLayout(state.nodes, state.edges);
    for (const pos of positions) {
      moveNode(pos.id, pos.x, pos.y);
    }
    commitMove();
    // Fit view after layout
    setTimeout(() => {
      const xs = positions.map(p => p.x);
      const ys = positions.map(p => p.y);
      const minX = Math.min(...xs) - 100;
      const minY = Math.min(...ys) - 100;
      const maxX = Math.max(...xs) + 320;
      const maxY = Math.max(...ys) + 200;
      const w = maxX - minX;
      const h = maxY - minY;
      const newZoom = Math.min(window.innerWidth / w, window.innerHeight / h, 1.5) * 0.85;
      setZoom(newZoom);
      setPan(-minX * newZoom + 40, -minY * newZoom + 40);
    }, 50);
  }, [state.nodes, state.edges, moveNode, commitMove, setZoom, setPan]);
  const handleFitView = useCallback(() => {
    if (state.nodes.length === 0) return;
    const xs = state.nodes.map(n => n.x);
    const ys = state.nodes.map(n => n.y);
    const minX = Math.min(...xs) - 100;
    const minY = Math.min(...ys) - 100;
    const maxX = Math.max(...xs) + 320;
    const maxY = Math.max(...ys) + 200;
    const w = maxX - minX;
    const h = maxY - minY;
    const newZoom = Math.min(window.innerWidth / w, window.innerHeight / h, 1.5) * 0.85;
    setZoom(newZoom);
    setPan(-minX * newZoom + 40, -minY * newZoom + 40);
  }, [state.nodes, setZoom, setPan]);
  return (
    <div className="h-screen w-screen flex flex-col overflow-hidden bg-background">
      {/* Header */}
      <motion.header
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="h-14 flex items-center justify-between px-5 border-b border-border glass-subtle z-30 shrink-0"
      >
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-xl bg-primary flex items-center justify-center">
            <Scale size={16} className="text-primary-foreground" />
          </div>
          <div>
            <h1 className="text-sm font-semibold text-foreground tracking-tight">ArgumentGraph</h1>
            <p className="text-[10px] text-muted-foreground -mt-0.5">Legal Reasoning Visualizer</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-secondary">
            <div className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
            <span className="text-xs font-medium text-muted-foreground">Smith v. Johnson ? Case Analysis</span>
          </div>
        </div>
      </motion.header>
      {/* Main Canvas */}
      <div className="flex-1 relative">
        <GraphCanvas
          nodes={state.nodes}
          edges={state.edges}
          selectedNodeId={state.selectedNodeId}
          zoom={state.zoom}
          panX={state.panX}
          panY={state.panY}
          clickConnectMode={clickConnectMode}
          clickConnectSource={clickConnectSource}
          onSelectNode={selectNode}
          onMoveNode={moveNode}
          onCommitMove={commitMove}
          onZoom={setZoom}
          onPan={setPan}
          onAddEdge={addEdge}
          onDeleteEdge={deleteEdge}
          onUpdateEdge={updateEdge}
          onClickConnectSelect={handleClickConnectSelect}
        />
        <GraphToolbar
          zoom={state.zoom}
          onZoomIn={() => setZoom(state.zoom + 0.1)}
          onZoomOut={() => setZoom(state.zoom - 0.1)}
          onResetView={handleResetView}
          onFitView={handleFitView}
          onAddNode={() => setShowAddDialog(true)}
          nodeCount={state.nodes.length}
          edgeCount={state.edges.length}
          clickConnectMode={clickConnectMode}
          onToggleClickConnect={() => { setClickConnectMode(prev => !prev); setClickConnectSource(null); }}
          onUndo={undo}
          onRedo={redo}
          canUndo={canUndo}
          canRedo={canRedo}
          onSave={saveToJson}
          onLoad={loadFromJson}
          onAutoLayout={handleAutoLayout}
        />
        <NodeDetailPanel
          node={selectedNode}
          onClose={() => selectNode(null)}
          onDelete={(id) => deleteNode(id)}
          onUpdate={updateNode}
        />
        {/* Legend */}
        <motion.div
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.4 }}
          className="absolute top-4 left-4 glass rounded-xl p-3 z-10"
        >
          <div className="flex items-center gap-1.5 mb-2">
            <Info size={12} className="text-muted-foreground" />
            <span className="text-[10px] font-medium text-muted-foreground uppercase tracking-wider">Legend</span>
          </div>
          <div className="space-y-1.5">
            {[
              { color: 'hsl(142, 71%, 45%)', label: 'Supports', dash: false },
              { color: 'hsl(0, 84%, 60%)', label: 'Attacks', dash: true },
              { color: 'hsl(0, 0%, 45%)', label: 'Relates', dash: true },
            ].map((item) => (
              <div key={item.label} className="flex items-center gap-2">
                <svg width="20" height="4">
                  <line x1="0" y1="2" x2="20" y2="2" stroke={item.color} strokeWidth={2}
                    strokeDasharray={item.dash ? (item.label === 'Attacks' ? '6,3' : '3,3') : undefined} />
                </svg>
                <span className="text-[10px] text-muted-foreground">{item.label}</span>
              </div>
            ))}
          </div>
          <div className="mt-2 pt-2 border-t border-border">
            <span className="text-[9px] text-muted-foreground">Click edge to edit</span>
          </div>
        </motion.div>
      </div>
      <AddNodeDialog isOpen={showAddDialog} onClose={() => setShowAddDialog(false)} onAdd={addNode} />
      <ConnectionDialog isOpen={!!clickConnectDialog} onClose={() => setClickConnectDialog(null)} onConfirm={handleClickConnectConfirm} />
    </div>
  );
};
export default Index;
