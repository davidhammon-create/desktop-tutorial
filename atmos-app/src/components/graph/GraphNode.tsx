import React, { useState, useRef, useEffect } from 'react';
import { ArgumentNode, ARGUMENT_TYPE_CONFIG } from '@/types/argument';
interface GraphNodeProps {
  node: ArgumentNode;
  isSelected: boolean;
  isDragging: boolean;
  isConnecting: boolean;
  isConnectSource: boolean;
  clickConnectMode: boolean;
  isClickConnectSource: boolean;
  onDragStart: (id: string, e: React.MouseEvent) => void;
  onSelect: (id: string) => void;
  onConnectionStart: (id: string, anchor: 'top' | 'bottom', e: React.MouseEvent) => void;
  onAnchorClick?: (nodeId: string, anchor: 'top' | 'bottom') => void;
  onInlineEdit?: (id: string, title: string, description: string) => void;
}
const NODE_WIDTH = 220;
const NODE_HEIGHT = 100;
export const GraphNode: React.FC<GraphNodeProps> = ({
  node,
  isSelected,
  isDragging,
  isConnecting,
  isConnectSource,
  clickConnectMode,
  isClickConnectSource,
  onDragStart,
  onSelect,
  onConnectionStart,
  onAnchorClick,
  onInlineEdit,
}) => {
  const config = ARGUMENT_TYPE_CONFIG[node.type];
  const isCounter = node.type === 'counterargument' || node.type === 'rebuttal';
  const strengthDots = Array.from({ length: 5 }, (_, i) => i < node.strength);
  const [hoveredAnchor, setHoveredAnchor] = useState<'top' | 'bottom' | null>(null);
  const anchorMouseDown = useRef<{ x: number; y: number; anchor: 'top' | 'bottom' } | null>(null);
  // Inline editing state
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState(node.title);
  const [editDesc, setEditDesc] = useState(node.description);
  const titleInputRef = useRef<HTMLInputElement>(null);
  const lastClickTime = useRef(0);
  useEffect(() => {
    setEditTitle(node.title);
    setEditDesc(node.description);
  }, [node.title, node.description]);
  useEffect(() => {
    if (isEditing && titleInputRef.current) {
      titleInputRef.current.focus();
      titleInputRef.current.select();
    }
  }, [isEditing]);
  const handleCommitEdit = () => {
    if (isEditing && onInlineEdit) {
      onInlineEdit(node.id, editTitle.trim() || node.title, editDesc.trim());
    }
    setIsEditing(false);
  };
  const showAnchorsHighlighted = isConnecting && !isConnectSource;
  const showClickTarget = clickConnectMode && !isClickConnectSource;
  // Node fill: counterarguments get a tinted red bg
  const nodeFill = isCounter ? 'hsl(0, 100%, 98%)' : 'white';
  const borderColor = isSelected ? config.color : isCounter ? 'hsl(0, 50%, 82%)' : '#e5e5e5';
  return (
    <g
      transform={`translate(${node.x}, ${node.y})`}
      onMouseDown={(e) => {
        if (!clickConnectMode && !isEditing) onDragStart(node.id, e);
      }}
      onClick={(e) => {
        e.stopPropagation();
        if (isEditing) return;
        const now = Date.now();
        if (now - lastClickTime.current < 350 && onInlineEdit) {
          // Double-click ? enter inline edit mode
          setIsEditing(true);
          lastClickTime.current = 0;
          return;
        }
        lastClickTime.current = now;
        if (clickConnectMode) {
          onSelect(node.id);
        } else if (!isConnecting) {
          onSelect(node.id);
        }
      }}
      style={{ cursor: isDragging ? 'grabbing' : isEditing ? 'text' : clickConnectMode ? 'pointer' : isConnecting ? 'crosshair' : 'grab' }}
    >
      {/* Glow effect when selected */}
      {isSelected && (
        <rect
          x={-4} y={-4}
          width={NODE_WIDTH + 8} height={NODE_HEIGHT + 8}
          rx={16} fill="none"
          stroke={config.color} strokeWidth={2} opacity={0.5}
          className="animate-pulse-glow"
        />
      )}
      {/* Highlight when connecting ? valid target */}
      {(showAnchorsHighlighted || showClickTarget) && (
        <rect
          x={-3} y={-3}
          width={NODE_WIDTH + 6} height={NODE_HEIGHT + 6}
          rx={16} fill="none"
          stroke="hsl(211, 100%, 50%)" strokeWidth={1.5} strokeDasharray="4,3" opacity={0.5}
        />
      )}
      {/* Click-connect source highlight */}
      {isClickConnectSource && (
        <rect
          x={-4} y={-4}
          width={NODE_WIDTH + 8} height={NODE_HEIGHT + 8}
          rx={16} fill="none"
          stroke="hsl(142, 71%, 45%)" strokeWidth={2.5} opacity={0.7}
          className="animate-pulse-glow"
        />
      )}
      {/* Shadow */}
      <rect
        x={2} y={3}
        width={NODE_WIDTH} height={NODE_HEIGHT}
        rx={14} fill="black"
        opacity={isDragging ? 0.12 : 0.06}
      />
      {/* Node body */}
      <rect
        x={0} y={0}
        width={NODE_WIDTH} height={NODE_HEIGHT}
        rx={14}
        fill={nodeFill}
        stroke={borderColor}
        strokeWidth={isSelected ? 2 : 1}
        opacity={0.95}
      />
      {/* Type indicator bar */}
      <rect x={0} y={0} width={4} height={NODE_HEIGHT} rx={2} fill={config.color} />
      <rect x={0} y={0} width={14} height={NODE_HEIGHT} rx={14} fill={config.color} opacity={isCounter ? 0.15 : 0.08} />
      {/* Type label */}
      <text x={18} y={22} fontSize={10} fontWeight={600} letterSpacing={0.5} fill={config.color}>
        {config.label.toUpperCase()}
      </text>
      {/* Title ? inline editable */}
      {isEditing ? (
        <foreignObject x={16} y={28} width={NODE_WIDTH - 24} height={24}>
          <input
            ref={titleInputRef}
            value={editTitle}
            onChange={(e) => setEditTitle(e.target.value)}
            onBlur={handleCommitEdit}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleCommitEdit();
              if (e.key === 'Escape') { setEditTitle(node.title); setEditDesc(node.description); setIsEditing(false); }
              e.stopPropagation();
            }}
            onMouseDown={(e) => e.stopPropagation()}
            style={{
              width: '100%', fontSize: 13, fontWeight: 600, color: '#1d1d1f',
              background: 'rgba(255,255,255,0.9)', border: `1px solid ${config.color}`,
              borderRadius: 4, padding: '1px 4px', outline: 'none',
              fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            }}
          />
        </foreignObject>
      ) : (
        <text
          x={18} y={44} fontSize={13} fontWeight={600} fill="#1d1d1f"
          style={{ fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif' }}
        >
          {node.title.length > 22 ? node.title.slice(0, 22) + '?' : node.title}
        </text>
      )}
      {/* Description preview */}
      {isEditing ? (
        <foreignObject x={16} y={54} width={NODE_WIDTH - 24} height={20}>
          <input
            value={editDesc}
            onChange={(e) => setEditDesc(e.target.value)}
            onBlur={handleCommitEdit}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleCommitEdit();
              if (e.key === 'Escape') { setEditTitle(node.title); setEditDesc(node.description); setIsEditing(false); }
              e.stopPropagation();
            }}
            onMouseDown={(e) => e.stopPropagation()}
            style={{
              width: '100%', fontSize: 10.5, color: '#86868b',
              background: 'rgba(255,255,255,0.9)', border: `1px solid ${config.color}40`,
              borderRadius: 4, padding: '1px 4px', outline: 'none',
              fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            }}
          />
        </foreignObject>
      ) : (
        <text
          x={18} y={62} fontSize={10.5} fill="#86868b"
          style={{ fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif' }}
        >
          {node.description.length > 30 ? node.description.slice(0, 30) + '?' : node.description}
        </text>
      )}
      {/* Strength dots ? inverted direction for counter-arguments */}
      <g transform={`translate(18, ${NODE_HEIGHT - 22})`}>
        {strengthDots.map((filled, i) => {
          // For counter-arguments, fill from RIGHT to LEFT (inverted)
          const invertedFilled = isCounter
            ? (5 - i) <= node.strength
            : filled;
          return (
            <circle
              key={i}
              cx={i * 14}
              cy={0}
              r={4}
              fill={invertedFilled ? config.color : '#e5e5e5'}
              opacity={invertedFilled ? 0.9 : 0.5}
            />
          );
        })}
        <text
          x={80} y={4} fontSize={9.5} fill="#86868b"
          style={{ fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif' }}
        >
          {isCounter ? 'Gegenkraft' : 'Stärke'}
        </text>
      </g>
      {/* Connection anchors ? Top */}
      <g
        onMouseDown={(e) => {
          e.stopPropagation();
          anchorMouseDown.current = { x: e.clientX, y: e.clientY, anchor: 'top' };
        }}
        onMouseMove={(e) => {
          if (anchorMouseDown.current && anchorMouseDown.current.anchor === 'top') {
            const dx = e.clientX - anchorMouseDown.current.x;
            const dy = e.clientY - anchorMouseDown.current.y;
            if (Math.sqrt(dx * dx + dy * dy) > 5) {
              onConnectionStart(node.id, 'top', e);
              anchorMouseDown.current = null;
            }
          }
        }}
        onMouseUp={(e) => {
          if (anchorMouseDown.current && anchorMouseDown.current.anchor === 'top') {
            e.stopPropagation();
            onAnchorClick?.(node.id, 'top');
            anchorMouseDown.current = null;
          }
        }}
        onMouseEnter={() => setHoveredAnchor('top')}
        onMouseLeave={() => { setHoveredAnchor(null); anchorMouseDown.current = null; }}
        style={{ cursor: 'pointer' }}
      >
        <circle cx={NODE_WIDTH / 2} cy={0} r={12} fill="transparent" />
        <circle
          cx={NODE_WIDTH / 2} cy={0}
          r={hoveredAnchor === 'top' || showAnchorsHighlighted ? 7 : 5}
          fill={config.color}
          opacity={hoveredAnchor === 'top' || showAnchorsHighlighted ? 0.8 : 0.4}
          style={{ transition: 'all 0.15s ease' }}
        />
        {hoveredAnchor === 'top' && (
          <circle cx={NODE_WIDTH / 2} cy={0} r={12} fill={config.color} opacity={0.15} />
        )}
      </g>
      {/* Bottom anchor */}
      <g
        onMouseDown={(e) => {
          e.stopPropagation();
          anchorMouseDown.current = { x: e.clientX, y: e.clientY, anchor: 'bottom' };
        }}
        onMouseMove={(e) => {
          if (anchorMouseDown.current && anchorMouseDown.current.anchor === 'bottom') {
            const dx = e.clientX - anchorMouseDown.current.x;
            const dy = e.clientY - anchorMouseDown.current.y;
            if (Math.sqrt(dx * dx + dy * dy) > 5) {
              onConnectionStart(node.id, 'bottom', e);
              anchorMouseDown.current = null;
            }
          }
        }}
        onMouseUp={(e) => {
          if (anchorMouseDown.current && anchorMouseDown.current.anchor === 'bottom') {
            e.stopPropagation();
            onAnchorClick?.(node.id, 'bottom');
            anchorMouseDown.current = null;
          }
        }}
        onMouseEnter={() => setHoveredAnchor('bottom')}
        onMouseLeave={() => { setHoveredAnchor(null); anchorMouseDown.current = null; }}
        style={{ cursor: 'pointer' }}
      >
        <circle cx={NODE_WIDTH / 2} cy={NODE_HEIGHT} r={12} fill="transparent" />
        <circle
          cx={NODE_WIDTH / 2} cy={NODE_HEIGHT}
          r={hoveredAnchor === 'bottom' || showAnchorsHighlighted ? 7 : 5}
          fill={config.color}
          opacity={hoveredAnchor === 'bottom' || showAnchorsHighlighted ? 0.8 : 0.4}
          style={{ transition: 'all 0.15s ease' }}
        />
        {hoveredAnchor === 'bottom' && (
          <circle cx={NODE_WIDTH / 2} cy={NODE_HEIGHT} r={12} fill={config.color} opacity={0.15} />
        )}
      </g>
    </g>
  );
};
export { NODE_WIDTH, NODE_HEIGHT };
