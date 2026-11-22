import { useState, useCallback, useRef } from 'react';
import { ArgumentNode, ArgumentEdge } from '@/types/argument';
interface GraphSnapshot {
  nodes: ArgumentNode[];
  edges: ArgumentEdge[];
}
const MAX_HISTORY = 40;
export function useGraphHistory(initialNodes: ArgumentNode[], initialEdges: ArgumentEdge[]) {
  const [history, setHistory] = useState<GraphSnapshot[]>([{ nodes: initialNodes, edges: initialEdges }]);
  const [pointer, setPointer] = useState(0);
  const batchRef = useRef(false);
  const current = history[pointer];
  const push = useCallback((nodes: ArgumentNode[], edges: ArgumentEdge[]) => {
    if (batchRef.current) return;
    setHistory(prev => {
      const next = [...prev.slice(0, pointer + 1), { nodes, edges }];
      if (next.length > MAX_HISTORY) next.shift();
      return next;
    });
    setPointer(prev => Math.min(prev + 1, MAX_HISTORY - 1));
  }, [pointer]);
  const undo = useCallback(() => {
    setPointer(prev => Math.max(0, prev - 1));
  }, []);
  const redo = useCallback(() => {
    setPointer(prev => Math.min(history.length - 1, prev + 1));
  }, [history.length]);
  const reset = useCallback((nodes: ArgumentNode[], edges: ArgumentEdge[]) => {
    setHistory([{ nodes, edges }]);
    setPointer(0);
  }, []);
  // For moves: batch updates so only the final position is pushed
  const startBatch = useCallback(() => { batchRef.current = true; }, []);
  const endBatch = useCallback((nodes: ArgumentNode[], edges: ArgumentEdge[]) => {
    batchRef.current = false;
    push(nodes, edges);
  }, [push]);
  return {
    nodes: current.nodes,
    edges: current.edges,
    push,
    undo,
    redo,
    reset,
    canUndo: pointer > 0,
    canRedo: pointer < history.length - 1,
    startBatch,
    endBatch,
  };
}
