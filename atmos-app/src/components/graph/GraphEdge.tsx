import React, { useState } from 'react';
import { ArgumentEdge, ArgumentNode, RELATION_CONFIG } from '@/types/argument';
import { NODE_WIDTH, NODE_HEIGHT } from './GraphNode';
interface GraphEdgeProps {
  edge: ArgumentEdge;
  sourceNode: ArgumentNode;
  targetNode: ArgumentNode;
  onEdit?: (edge: ArgumentEdge) => void;
}
export const GraphEdge: React.FC<GraphEdgeProps> = ({ edge, sourceNode, targetNode, onEdit }) => {
  const config = RELATION_CONFIG[edge.relation];
  const [hovered, setHovered] = useState(false);
  const sx = sourceNode.x + NODE_WIDTH / 2;
  const sy = sourceNode.y + NODE_HEIGHT / 2;
  const tx = targetNode.x + NODE_WIDTH / 2;
  const ty = targetNode.y + NODE_HEIGHT / 2;
  const dx = tx - sx;
  const dy = ty - sy;
  const dist = Math.max(Math.sqrt(dx * dx + dy * dy), 1);
  const midX = sx + dx / 2;
  const midY = sy + dy / 2;
  const curvature = Math.min(dist * 0.3, 80);
  const nx = (-dy / dist) * curvature * 0.15;
  const ny = (dx / dist) * curvature * 0.15;
  const path = `M ${sx} ${sy} Q ${midX + nx} ${midY + ny} ${tx} ${ty}`;
  const arrowAngle = Math.atan2(ty - (midY + ny), tx - (midX + nx));
  const arrowLen = 10;
  const arrowPts = [
    { x: tx, y: ty },
    { x: tx - arrowLen * Math.cos(arrowAngle - 0.35), y: ty - arrowLen * Math.sin(arrowAngle - 0.35) },
    { x: tx - arrowLen * Math.cos(arrowAngle + 0.35), y: ty - arrowLen * Math.sin(arrowAngle + 0.35) },
  ];
  const labelX = midX + nx;
  const labelY = midY + ny - 8;
  const displayLabel = edge.label || config.label;
  const labelWidth = Math.max(82, displayLabel.length * 6.4 + 18);
  return (
    <g
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{ cursor: onEdit ? 'pointer' : 'default' }}
      onClick={(e) => {
        if (onEdit) {
          e.stopPropagation();
          onEdit(edge);
        }
      }}
      onDoubleClick={(e) => {
        if (onEdit) {
          e.stopPropagation();
          onEdit(edge);
        }
      }}
    >
      <path d={path} fill="none" stroke="transparent" strokeWidth={20} pointerEvents="stroke" />
      <path d={path} fill="none" stroke="black" strokeWidth={hovered ? 4 : 3} opacity={0.04} strokeDasharray={config.dash || undefined} />
      <path
        d={path}
        fill="none"
        stroke={hovered ? 'hsl(var(--primary))' : config.color}
        strokeWidth={hovered ? 3 : 2.2}
        opacity={hovered ? 0.95 : 0.75}
        strokeDasharray={config.dash || undefined}
        strokeLinecap="round"
        style={{ transition: 'stroke 0.15s, stroke-width 0.15s, opacity 0.15s' }}
      />
      <polygon
        points={arrowPts.map((p) => `${p.x},${p.y}`).join(' ')}
        fill={hovered ? 'hsl(var(--primary))' : config.color}
        opacity={hovered ? 0.95 : 0.75}
        style={{ transition: 'fill 0.15s, opacity 0.15s' }}
      />
      {hovered && onEdit && (
        <g transform={`translate(${labelX}, ${labelY - 18})`}>
          <circle r={10} fill="hsl(var(--primary))" opacity={0.9} />
          <line x1={-3} y1={-3} x2={3} y2={3} stroke="white" strokeWidth={1.5} strokeLinecap="round" />
          <line x1={-3} y1={3} x2={0} y2={0} stroke="white" strokeWidth={1.5} strokeLinecap="round" />
          <circle cx={3} cy={-3} r={1.5} fill="white" />
        </g>
      )}
      <g transform={`translate(${labelX}, ${labelY})`}>
        <rect
          x={-labelWidth / 2}
          y={-10}
          width={labelWidth}
          height={18}
          rx={9}
          fill="white"
          stroke={hovered ? 'hsl(var(--primary))' : '#e5e5e5'}
          strokeWidth={hovered ? 1 : 0.6}
          opacity={0.94}
        />
        <text
          textAnchor="middle"
          y={3}
          fontSize={9.5}
          fill={hovered ? 'hsl(var(--primary))' : '#60646c'}
          fontWeight={600}
          style={{ fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif' }}
        >
          {displayLabel}
        </text>
      </g>
    </g>
  );
};
