import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Scale, FileText, ShieldAlert, Reply, BookOpen, X } from 'lucide-react';
import { ArgumentType, ArgumentStrength, ARGUMENT_TYPE_CONFIG } from '@/types/argument';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
interface AddNodeDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onAdd: (
    type: ArgumentType,
    title: string,
    description: string,
    strength: ArgumentStrength,
    opts?: { caseReference?: string; legalBasis?: string }
  ) => void;
}
const TYPE_OPTIONS: { type: ArgumentType; Icon: React.FC<any> }[] = [
  { type: 'claim', Icon: Scale },
  { type: 'evidence', Icon: FileText },
  { type: 'counterargument', Icon: ShieldAlert },
  { type: 'rebuttal', Icon: Reply },
  { type: 'premise', Icon: BookOpen },
];
export const AddNodeDialog: React.FC<AddNodeDialogProps> = ({ isOpen, onClose, onAdd }) => {
  const [selectedType, setSelectedType] = useState<ArgumentType>('claim');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [strength, setStrength] = useState<ArgumentStrength>(3);
  const [caseReference, setCaseReference] = useState('');
  const [legalBasis, setLegalBasis] = useState('');
  const reset = () => {
    setSelectedType('claim');
    setTitle('');
    setDescription('');
    setStrength(3);
    setCaseReference('');
    setLegalBasis('');
  };
  const handleSubmit = () => {
    if (!title.trim()) return;
    onAdd(selectedType, title.trim(), description.trim(), strength, {
      caseReference: caseReference.trim() || undefined,
      legalBasis: legalBasis.trim() || undefined,
    });
    reset();
    onClose();
  };
  const config = ARGUMENT_TYPE_CONFIG[selectedType];
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
            initial={{ opacity: 0, scale: 0.95, y: -20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: -20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed right-4 top-20 w-[480px] max-h-[85vh] glass rounded-2xl z-50 overflow-hidden flex flex-col"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-5 pb-3">
              <div className="flex items-center gap-2.5">
                <div
                  className="w-8 h-8 rounded-lg flex items-center justify-center"
                  style={{ backgroundColor: config.color + '18' }}
                >
                  <Plus size={16} style={{ color: config.color }} />
                </div>
                <h2 className="text-base font-semibold text-foreground">New Argument</h2>
              </div>
              <button
                onClick={onClose}
                className="p-1.5 rounded-full hover:bg-secondary transition-colors"
              >
                <X size={14} className="text-muted-foreground" />
              </button>
            </div>
            <Separator />
            {/* Content */}
            <div className="flex-1 overflow-y-auto p-5 space-y-5">
              {/* Type selector */}
              <div>
                <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Argument Type
                </Label>
                <div className="grid grid-cols-5 gap-2 mt-2">
                  {TYPE_OPTIONS.map(({ type, Icon }) => {
                    const tc = ARGUMENT_TYPE_CONFIG[type];
                    const isActive = type === selectedType;
                    return (
                      <button
                        key={type}
                        onClick={() => setSelectedType(type)}
                        className={`flex flex-col items-center gap-1.5 p-3 rounded-xl border transition-all ${
                          isActive
                            ? 'border-primary/30 shadow-sm'
                            : 'border-transparent hover:bg-secondary'
                        }`}
                        style={isActive ? { backgroundColor: tc.color + '10' } : undefined}
                      >
                        <Icon size={18} style={{ color: isActive ? tc.color : 'hsl(var(--muted-foreground))' }} />
                        <span
                          className="text-[10px] font-medium"
                          style={{ color: isActive ? tc.color : 'hsl(var(--muted-foreground))' }}
                        >
                          {tc.label}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
              {/* Title */}
              <div>
                <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Title
                </Label>
                <Input
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g., Breach of Contract"
                  className="mt-1.5"
                />
              </div>
              {/* Description */}
              <div>
                <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Description
                </Label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Describe the argument in detail..."
                  rows={3}
                  className="mt-1.5 flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 resize-none"
                />
              </div>
              {/* Strength */}
              <div>
                <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Strength ({strength}/5)
                </Label>
                <div className="flex items-center gap-2 mt-2">
                  {([1, 2, 3, 4, 5] as ArgumentStrength[]).map((s) => (
                    <button
                      key={s}
                      onClick={() => setStrength(s)}
                      className="h-3 flex-1 rounded-full transition-all"
                      style={{
                        backgroundColor: s <= strength ? config.color : 'hsl(var(--border))',
                        opacity: s <= strength ? 0.85 : 0.4,
                      }}
                    />
                  ))}
                </div>
              </div>
              {/* Legal references */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Case Reference
                  </Label>
                  <Input
                    value={caseReference}
                    onChange={(e) => setCaseReference(e.target.value)}
                    placeholder="Optional"
                    className="mt-1.5"
                  />
                </div>
                <div>
                  <Label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Legal Basis
                  </Label>
                  <Input
                    value={legalBasis}
                    onChange={(e) => setLegalBasis(e.target.value)}
                    placeholder="Optional"
                    className="mt-1.5"
                  />
                </div>
              </div>
            </div>
            {/* Footer */}
            <div className="p-4 border-t border-border flex gap-2 justify-end">
              <Button variant="ghost" onClick={onClose}>
                Cancel
              </Button>
              <Button onClick={handleSubmit} disabled={!title.trim()}>
                <Plus size={14} />
                Add Argument
              </Button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
