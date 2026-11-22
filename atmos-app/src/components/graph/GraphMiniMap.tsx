import React, { useMemo } from 'react';
import { ArgumentNode, ArgumentEdge, ARGUMENT_TYPE_CONFIG } from '@/types/argument';
const MINIMAP_W = 180;
const MINIMAP_H = 120;
const PADDING = 10;
interface GraphMiniMapProps {
  nodes: ArgumentNode[];
  edges: ArgumentEdge[];
  zoom: number;
  panX: number;
  panY: number;
  viewportWidth: number;
  viewportHeight: number;
  onNavigate: (panX: number, panY: number) => void;
}
export const GraphMiniMap: React.FC<GraphMiniMapProps> = ({
  nodes, edges, zoom, panX, panY, viewportWidth, viewportHeight, onNavigate,
}) => {
  const { scale, offsetX, offsetY, bounds } = useMemo(() => {
    if (nodes.length === 0) return { scale: 1, offsetX: 0, offsetY: 0, bounds: { minX: 0, minY: 0, maxX: 400, maxY: 300 } };
    const xs = nodes.map(n => n.x);
    const ys = nodes.map(n => n.y);
    const minX = Math.min(...xs) - 60;
    const minY = Math.min(...ys) - 60;
    const maxX = Math.max(...xs) + 280;
    const maxY = Math.max(...ys) + 160;
    const w = maxX - minX || 1;
    const h = maxY - minY || 1;
    const s = Math.min((MINIMAP_W - PADDING * 2) / w, (MINIMAP_H - PADDING * 2) / h);
    return { scale: s, offsetX: -minX * s + PADDING, offsetY: -minY * s + PADDING, bounds: { minX, minY, maxX, maxY } };
  }, [nodes]);
  // Viewport rectangle in minimap coords
  const vpX = (-panX / zoom) * scale + offsetX;
  const vpY = (-panY / zoom) * scale + offsetY;
  const vpW = (viewportWidth / zoom) * scale;
  const vpH = (viewportHeight / zoom) * scale;
  const handleClick = (e: React.MouseEvent<SVGSVGElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    // Convert minimap coords to graph coords, then to pan
    const graphX = (mx - offsetX) / scale;
    const graphY = (my - offsetY) / scale;
    const newPanX = -(graphX - viewportWidth / (2 * zoom)) * zoom;
    const newPanY = -(graphY - viewportHeight / (2 * zoom)) * zoom;
    onNavigate(newPanX, newPanY);
  };
  if (nodes.length === 0) return null;
  return (
    <div
      className="absolute bottom-14 right-3 rounded-lg border border-border/50 bg-background/80 backdrop-blur-sm shadow-lg overflow-hidden"
      style={{ width: MINIMAP_W, height: MINIMAP_H, zIndex: 20 }}
    >
      <svg width={MINIMAP_W} height={MINIMAP_H} onClick={handleClick} className="cursor-pointer">
        {/* Edges */}
        {edges.map(edge => {
          const s = nodes.find(n => n.id === edge.source);
          const t = nodes.find(n => n.id === edge.target);
          if (!s || !t) return null;
          return (
            <line
              key={edge.id}
              x1={s.x * scale + offsetX + 110 * scale}
              y1={s.y * scale + offsetY + 50 * scale}
              x2={t.x * scale + offsetX + 110 * scale}
              y2={t.y * scale + offsetY + 50 * scale}
              stroke={edge.relation === 'attack' ? 'hsl(0,72%,51%)' : edge.relation === 'support' ? 'hsl(152,60%,36%)' : 'hsl(220,10%,46%)'}
              strokeWidth={0.8}
              opacity={0.5}
            />
          );
        })}
        {/* Nodes as small rectangles */}
        {nodes.map(node => {
          const config = ARGUMENT_TYPE_CONFIG[node.type];
          return (
            <rect
              key={node.id}
              x={node.x * scale + offsetX}
              y={node.y * scale + offsetY}
              width={220 * scale}
              height={100 * scale}
              rx={2}
              fill={config?.color || '#888'}
              opacity={0.7}
            />
          );
        })}
        {/* Viewport indicator */}
        <rect
          x={vpX}
          y={vpY}
          width={Math.max(vpW, 8)}
          height={Math.max(vpH, 8)}
          fill="hsl(var(--primary) / 0.1)"
          stroke="hsl(var(--primary))"
          strokeWidth={1.5}
          rx={2}
        />
      </svg>
    </div>
  );
};
