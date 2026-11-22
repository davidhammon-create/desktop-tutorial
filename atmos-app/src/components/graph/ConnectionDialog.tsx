import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Link, X } from 'lucide-react';
import { RelationType, RELATION_CONFIG } from '@/types/argument';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
interface ConnectionDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (relation: RelationType, label?: string) => void;
}
const RELATION_OPTIONS: RelationType[] = ['support', 'attack', 'neutral', 'causal'];
export const ConnectionDialog: React.FC<ConnectionDialogProps> = ({ isOpen, onClose, onConfirm }) => {
  const [selectedRelation, setSelectedRelation] = useState<RelationType>('support');
  const [label, setLabel] = useState('');
  const handleConfirm = () => {
    onConfirm(selectedRelation, label.trim() || undefined);
    setSelectedRelation('support');
    setLabel('');
  };
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/30 backdrop-blur-sm z-40"
            onClick={onClose}
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[360px] glass rounded-2xl z-50 overflow-hidden"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-5 pb-3">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center bg-primary/10">
                  <Link size={16} className="text-primary" />
                </div>
                <h2 className="text-base font-semibold text-foreground">New Connection</h2>
              </div>
              <button
                onClick={onClose}
                className="p-1.5 rounded-full hover:bg-secondary transition-colors"
              >
                <X size={14} className="text-muted-foreground" />
              </button>
            </div>
            <div className="px-5 pb-5 space-y-4">
              {/* Relation type */}
              <div>
                <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Relationship Type
                </Label>
                <div className="flex gap-2 mt-2">
                  {RELATION_OPTIONS.map((rel) => {
                    const config = RELATION_CONFIG[rel];
                    const isActive = rel === selectedRelation;
                    return (
                      <button
                        key={rel}
                        onClick={() => setSelectedRelation(rel)}
                        className={`flex-1 flex flex-col items-center gap-1.5 p-3 rounded-xl border transition-all ${
                          isActive
                            ? 'border-primary/30 shadow-sm'
                            : 'border-transparent hover:bg-secondary'
                        }`}
                        style={isActive ? { backgroundColor: config.color + '10' } : undefined}
                      >
                        <svg width="24" height="4">
                          <line
                            x1="0" y1="2" x2="24" y2="2"
                            stroke={config.color}
                            strokeWidth={2}
                            strokeDasharray={config.dash || undefined}
                          />
                        </svg>
                        <span
                          className="text-[10px] font-medium"
                          style={{ color: isActive ? config.color : 'hsl(var(--muted-foreground))' }}
                        >
                          {config.label}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
              {/* Label */}
              <div>
                <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Label (optional)
                </Label>
                <Input
                  value={label}
                  onChange={(e) => setLabel(e.target.value)}
                  placeholder="e.g., Documents breach"
                  className="mt-1.5"
                />
              </div>
              {/* Actions */}
              <div className="flex gap-2 justify-end pt-2">
                <Button variant="ghost" onClick={onClose}>
                  Cancel
                </Button>
                <Button onClick={handleConfirm}>
                  <Link size={14} />
                  Connect
                </Button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
