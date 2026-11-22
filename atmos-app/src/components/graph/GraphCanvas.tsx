import React, { useRef, useCallback, useEffect, useState } from 'react';
import { ArgumentNode, ArgumentEdge, RelationType } from '@/types/argument';
import { GraphNode, NODE_WIDTH, NODE_HEIGHT } from './GraphNode';
import { GraphEdge } from './GraphEdge';
import { ConnectionLinePreview } from './ConnectionLinePreview';
import { ConnectionDialog } from './ConnectionDialog';
import { EdgeEditDialog } from './EdgeEditDialog';
import { GraphMiniMap } from './GraphMiniMap';
interface GraphCanvasProps {
  nodes: ArgumentNode[];
  edges: ArgumentEdge[];
  selectedNodeId: string | null;
  zoom: number;
  panX: number;
  panY: number;
  clickConnectMode: boolean;
  clickConnectSource: string | null;
  onSelectNode: (id: string | null) => void;
  onMoveNode: (id: string, x: number, y: number) => void;
  onCommitMove?: () => void;
  onZoom: (zoom: number) => void;
  onPan: (x: number, y: number) => void;
  onAddEdge: (source: string, target: string, relation: RelationType, label?: string) => void;
  onDeleteEdge: (id: string) => void;
  onUpdateEdge: (id: string, updates: Partial<ArgumentEdge>) => void;
  onClickConnectSelect: (nodeId: string) => void;
  onInlineEdit?: (id: string, title: string, description: string) => void;
}
export const GraphCanvas: React.FC<GraphCanvasProps> = ({
  nodes, edges, selectedNodeId, zoom, panX, panY,
  clickConnectMode, clickConnectSource,
  onSelectNode, onMoveNode, onCommitMove, onZoom, onPan,
  onAddEdge, onDeleteEdge, onUpdateEdge, onClickConnectSelect,
  onInlineEdit,
}) => {
  const svgRef = useRef<SVGSVGElement>(null);
  // ?? Interaction state ??
  const [isPanning, setIsPanning] = useState(false);
  const panStartRef = useRef({ x: 0, y: 0 });
  const [draggingNode, setDraggingNode] = useState<string | null>(null);
  const dragOffsetRef = useRef({ x: 0, y: 0 });
  const [connectingFrom, setConnectingFrom] = useState<{ nodeId: string; anchor: 'top' | 'bottom' } | null>(null);
  const [connectMousePos, setConnectMousePos] = useState({ x: 0, y: 0 });
  const [connectionDialog, setConnectionDialog] = useState<{ source: string; target: string } | null>(null);
  const [editingEdge, setEditingEdge] = useState<ArgumentEdge | null>(null);
  // ?? Stable refs for global listeners ??
  const nodesRef = useRef(nodes); nodesRef.current = nodes;
  const edgesRef = useRef(edges); edgesRef.current = edges;
  const zoomRef = useRef(zoom); zoomRef.current = zoom;
  const panXRef = useRef(panX); panXRef.current = panX;
  const panYRef = useRef(panY); panYRef.current = panY;
  const draggingNodeRef = useRef(draggingNode); draggingNodeRef.current = draggingNode;
  const isPanningRef = useRef(isPanning); isPanningRef.current = isPanning;
  const connectingFromRef = useRef(connectingFrom); connectingFromRef.current = connectingFrom;
  const onMoveNodeRef = useRef(onMoveNode); onMoveNodeRef.current = onMoveNode;
  const onPanRef = useRef(onPan); onPanRef.current = onPan;
  const onCommitMoveRef = useRef(onCommitMove); onCommitMoveRef.current = onCommitMove;
  const onAddEdgeRef = useRef(onAddEdge); onAddEdgeRef.current = onAddEdge;
  const screenToGraph = useCallback((clientX: number, clientY: number) => {
    const rect = svgRef.current?.getBoundingClientRect();
    if (!rect) return { x: 0, y: 0 };
    return {
      x: (clientX - rect.left - panXRef.current) / zoomRef.current,
      y: (clientY - rect.top - panYRef.current) / zoomRef.current,
    };
  }, []);
  // ?? SVG mouse-down: start pan or deselect ??
  const handleSvgMouseDown = useCallback((e: React.MouseEvent) => {
    if (connectingFromRef.current) return;
    const target = e.target as SVGElement;
    if (target === svgRef.current || target.tagName === 'rect' && !target.closest('g[data-nodeid]')) {
      setIsPanning(true);
      panStartRef.current = { x: e.clientX - panXRef.current, y: e.clientY - panYRef.current };
      onSelectNode(null);
    }
  }, [onSelectNode]);
  // ?? Node drag start ??
  const handleNodeDragStart = useCallback((nodeId: string, e: React.MouseEvent) => {
    if (connectingFromRef.current) return;
    e.stopPropagation();
    const node = nodesRef.current.find(n => n.id === nodeId);
    if (!node) return;
    const gp = screenToGraph(e.clientX, e.clientY);
    dragOffsetRef.current = { x: gp.x - node.x, y: gp.y - node.y };
    setDraggingNode(nodeId);
    onSelectNode(nodeId);
  }, [screenToGraph, onSelectNode]);
  // ?? Anchor drag start (for creating connections) ??
  const handleConnectionStart = useCallback((nodeId: string, anchor: 'top' | 'bottom', e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    const node = nodesRef.current.find(n => n.id === nodeId);
    if (!node) return;
    setConnectingFrom({ nodeId, anchor });
    setConnectMousePos({
      x: node.x + NODE_WIDTH / 2,
      y: anchor === 'top' ? node.y : node.y + NODE_HEIGHT,
    });
  }, []);
  // ?? Global mouse move + mouse up ??
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      // Panning
      if (isPanningRef.current) {
        onPanRef.current(e.clientX - panStartRef.current.x, e.clientY - panStartRef.current.y);
        return;
      }
      // Node dragging
      if (draggingNodeRef.current) {
        const gp = screenToGraph(e.clientX, e.clientY);
        onMoveNodeRef.current(
          draggingNodeRef.current,
          gp.x - dragOffsetRef.current.x,
          gp.y - dragOffsetRef.current.y,
        );
        return;
      }
      // Connection dragging
      if (connectingFromRef.current) {
        const gp = screenToGraph(e.clientX, e.clientY);
        setConnectMousePos(gp);
      }
    };
    const handleMouseUp = (e: MouseEvent) => {
      // Finish connection drag
      if (connectingFromRef.current) {
        const gp = screenToGraph(e.clientX, e.clientY);
        const padding = 20;
        let targetNode: ArgumentNode | null = null;
        for (const node of nodesRef.current) {
          if (node.id === connectingFromRef.current.nodeId) continue;
          if (
            gp.x >= node.x - padding && gp.x <= node.x + NODE_WIDTH + padding &&
            gp.y >= node.y - padding && gp.y <= node.y + NODE_HEIGHT + padding
          ) {
            targetNode = node;
            break;
          }
        }
        if (targetNode) {
          const exists = edgesRef.current.some(edge =>
            (edge.source === connectingFromRef.current!.nodeId && edge.target === targetNode!.id) ||
            (edge.source === targetNode!.id && edge.target === connectingFromRef.current!.nodeId),
          );
          if (!exists) {
            setConnectionDialog({ source: connectingFromRef.current.nodeId, target: targetNode.id });
          }
        }
        setConnectingFrom(null);
      }
      // Finish node drag
      if (draggingNodeRef.current) {
        onCommitMoveRef.current?.();
        setDraggingNode(null);
      }
      // Finish pan
      setIsPanning(false);
    };
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [screenToGraph]);
  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? -0.08 : 0.08;
    onZoom(zoom + delta);
  }, [zoom, onZoom]);
  const handleConfirmConnection = useCallback((relation: RelationType, label?: string) => {
    if (connectionDialog) onAddEdge(connectionDialog.source, connectionDialog.target, relation, label);
    setConnectionDialog(null);
  }, [connectionDialog, onAddEdge]);
  const connectStartPos = connectingFrom ? (() => {
    const node = nodesRef.current.find(n => n.id === connectingFrom.nodeId);
    if (!node) return null;
    return { x: node.x + NODE_WIDTH / 2, y: connectingFrom.anchor === 'top' ? node.y : node.y + NODE_HEIGHT };
  })() : null;
  return (
    <div id="graph-canvas-container" className="relative w-full h-full overflow-hidden bg-background">
      {/* Dot grid */}
      <div
        className="absolute inset-0 opacity-[0.08]"
        style={{
          backgroundImage: 'radial-gradient(circle, hsl(var(--foreground)) 1px, transparent 1px)',
          backgroundSize: `${24 * zoom}px ${24 * zoom}px`,
          backgroundPosition: `${panX % (24 * zoom)}px ${panY % (24 * zoom)}px`,
        }}
      />
      <svg
        ref={svgRef}
        className={`w-full h-full ${connectingFrom ? 'cursor-crosshair' : draggingNode ? 'cursor-grabbing' : 'cursor-grab'}`}
        onWheel={handleWheel}
        onMouseDown={handleSvgMouseDown}
      >
        <rect width="100%" height="100%" fill="transparent" />
        <g transform={`translate(${panX}, ${panY}) scale(${zoom})`}>
          {/* Edges */}
          {edges.map(edge => {
            const source = nodes.find(n => n.id === edge.source);
            const target = nodes.find(n => n.id === edge.target);
            if (!source || !target) return null;
            return (
              <GraphEdge
                key={edge.id}
                edge={edge}
                sourceNode={source}
                targetNode={target}
                onEdit={(e) => setEditingEdge(e)}
              />
            );
          })}
          {/* Connection preview line */}
          {connectingFrom && connectStartPos && (
            <ConnectionLinePreview
              startX={connectStartPos.x}
              startY={connectStartPos.y}
              endX={connectMousePos.x}
              endY={connectMousePos.y}
            />
          )}
          {/* Nodes */}
          {nodes.map(node => (
            <GraphNode
              key={node.id}
              node={node}
              isSelected={node.id === selectedNodeId}
              isDragging={node.id === draggingNode}
              isConnecting={!!connectingFrom}
              isConnectSource={connectingFrom?.nodeId === node.id}
              clickConnectMode={clickConnectMode}
              isClickConnectSource={clickConnectSource === node.id}
              onDragStart={handleNodeDragStart}
              onSelect={(id) => {
                if (clickConnectMode) onClickConnectSelect(id);
                else onSelectNode(id);
              }}
              onConnectionStart={handleConnectionStart}
              onInlineEdit={onInlineEdit}
            />
          ))}
        </g>
      </svg>
      {/* Connection type dialog */}
      <ConnectionDialog
        isOpen={!!connectionDialog}
        onClose={() => setConnectionDialog(null)}
        onConfirm={handleConfirmConnection}
      />
      {/* Mini-map */}
      <GraphMiniMap
        nodes={nodes}
        edges={edges}
        zoom={zoom}
        panX={panX}
        panY={panY}
        viewportWidth={svgRef.current?.clientWidth || 800}
        viewportHeight={svgRef.current?.clientHeight || 500}
        onNavigate={(x, y) => onPan(x, y)}
      />
      {/* Edge edit dialog */}
      <EdgeEditDialog
        edge={editingEdge}
        onClose={() => setEditingEdge(null)}
        onUpdate={(id, relation, label) => {
          onUpdateEdge(id, { relation, label });
          setEditingEdge(null);
        }}
        onDelete={(id) => {
          onDeleteEdge(id);
          setEditingEdge(null);
        }}
      />
    </div>
  );
};
