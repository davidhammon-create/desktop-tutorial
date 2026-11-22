import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Trash2, Plus, X, ArrowRight } from 'lucide-react';
import { ArgumentEdge, ArgumentNode, RELATION_CONFIG } from '@/types/argument';
interface AnchorEdgeMenuProps {
  nodeId: string;
  anchor: 'top' | 'bottom';
  edges: ArgumentEdge[];
  nodes: ArgumentNode[];
  position: { x: number; y: number };
  onClose: () => void;
  onDeleteEdge: (id: string) => void;
  onEditEdge: (edge: ArgumentEdge) => void;
  onStartConnect: (nodeId: string, anchor: 'top' | 'bottom') => void;
}
export const AnchorEdgeMenu: React.FC<AnchorEdgeMenuProps> = ({
  nodeId, anchor, edges, nodes, position, onClose, onDeleteEdge, onEditEdge, onStartConnect,
}) => {
  const connectedEdges = edges.filter(e => e.source === nodeId || e.target === nodeId);
  const getOtherNode = (edge: ArgumentEdge) => {
    const otherId = edge.source === nodeId ? edge.target : edge.source;
    return nodes.find(n => n.id === otherId);
  };
  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: anchor === 'top' ? 10 : -10 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.9 }}
        className="absolute z-50 w-[260px] glass rounded-xl shadow-lg overflow-hidden"
        style={{
          left: position.x - 130,
          top: anchor === 'top' ? position.y - 8 : position.y + 8,
          transform: anchor === 'top' ? 'translateY(-100%)' : 'translateY(0)',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-3 py-2.5 border-b border-border">
          <span className="text-xs font-semibold text-foreground">
            Connections ({connectedEdges.length})
          </span>
          <button onClick={onClose} className="p-1 rounded-full hover:bg-secondary transition-colors">
            <X size={12} className="text-muted-foreground" />
          </button>
        </div>
        {/* Edge list */}
        <div className="max-h-[200px] overflow-y-auto">
          {connectedEdges.length === 0 ? (
            <div className="px-3 py-4 text-center">
              <span className="text-xs text-muted-foreground">No connections</span>
            </div>
          ) : (
            connectedEdges.map((edge) => {
              const otherNode = getOtherNode(edge);
              const config = RELATION_CONFIG[edge.relation];
              const isSource = edge.source === nodeId;
              return (
                <div
                  key={edge.id}
                  className="flex items-center gap-2 px-3 py-2 hover:bg-secondary/50 transition-colors group"
                >
                  {/* Relation indicator */}
                  <svg width="16" height="4" className="shrink-0">
                    <line
                      x1="0" y1="2" x2="16" y2="2"
                      stroke={config.color}
                      strokeWidth={2}
                      strokeDasharray={config.dash || undefined}
                    />
                  </svg>

                  {/* Edge info - clickable to edit */}
                  <button
                    className="flex-1 text-left min-w-0"
                    onClick={() => onEditEdge(edge)}
                  >
                    <div className="flex items-center gap-1">
                      <span className="text-[10px] font-medium" style={{ color: config.color }}>
                        {config.label}
                      </span>
                      <ArrowRight size={8} className="text-muted-foreground" />
                      <span className="text-[10px] text-foreground font-medium truncate">
                        {otherNode?.title || 'Unknown'}
                      </span>
                    </div>
                    {edge.label && (
                      <span className="text-[9px] text-muted-foreground truncate block">
                        {edge.label}
                      </span>
                    )}
                  </button>
                  {/* Delete button */}
                  <button
                    onClick={(e) => { e.stopPropagation(); onDeleteEdge(edge.id); }}
                    className="p-1 rounded-md opacity-0 group-hover:opacity-100 hover:bg-destructive/10 transition-all"
                  >
                    <Trash2 size={12} className="text-destructive" />
                  </button>
                </div>
              );
            })
          )}
        </div>
        {/* New connection button */}
        <div className="border-t border-border px-3 py-2">
          <button
            onClick={() => {
              onClose();
              onStartConnect(nodeId, anchor);
            }}
            className="flex items-center gap-1.5 w-full px-2 py-1.5 rounded-lg text-xs font-medium text-primary hover:bg-primary/10 transition-colors"
          >
            <Plus size={12} />
            New connection
          </button>
        </div>
      </motion.div>
    </AnimatePresence>
  );
};
