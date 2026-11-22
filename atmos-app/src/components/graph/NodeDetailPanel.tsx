import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Scale, FileText, ShieldAlert, Reply, BookOpen, Trash2, ExternalLink, Pencil, Check, Plus, Link } from 'lucide-react';
import { ArgumentNode, ARGUMENT_TYPE_CONFIG, ArgumentStrength, ArgumentType, NodeParagraph, NodeFileLink } from '@/types/argument';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { Input } from '@/components/ui/input';
interface NodeDetailPanelProps {
  node: ArgumentNode | null;
  onClose: () => void;
  onDelete: (id: string) => void;
  onUpdate: (id: string, updates: Partial<ArgumentNode>) => void;
}
const TYPE_ICONS = {
  claim: Scale,
  evidence: FileText,
  counterargument: ShieldAlert,
  rebuttal: Reply,
  premise: BookOpen,
};
const TYPE_OPTIONS: ArgumentType[] = ['claim', 'evidence', 'counterargument', 'rebuttal', 'premise'];
export const NodeDetailPanel: React.FC<NodeDetailPanelProps> = ({ node, onClose, onDelete, onUpdate }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState('');
  const [editDescription, setEditDescription] = useState('');
  const [editStrength, setEditStrength] = useState<ArgumentStrength>(3);
  const [editCaseRef, setEditCaseRef] = useState('');
  const [editLegalBasis, setEditLegalBasis] = useState('');
  const [editType, setEditType] = useState<ArgumentType>('claim');
  // Paragraph & file link inputs
  const [newParagraph, setNewParagraph] = useState('');
  const [newFileName, setNewFileName] = useState('');
  const [newFileUrl, setNewFileUrl] = useState('');
  useEffect(() => {
    if (node) {
      setEditTitle(node.title);
      setEditDescription(node.description);
      setEditStrength(node.strength);
      setEditCaseRef(node.caseReference || '');
      setEditLegalBasis(node.legalBasis || '');
      setEditType(node.type);
    }
    setIsEditing(false);
  }, [node?.id]);
  const handleSave = () => {
    if (!node) return;
    onUpdate(node.id, {
      title: editTitle.trim(),
      description: editDescription.trim(),
      strength: editStrength,
      type: editType,
      caseReference: editCaseRef.trim() || undefined,
      legalBasis: editLegalBasis.trim() || undefined,
    });
    setIsEditing(false);
  };
  const handleAddParagraph = () => {
    if (!node || !newParagraph.trim()) return;
    const paragraph: NodeParagraph = { id: Date.now().toString(), text: newParagraph.trim() };
    onUpdate(node.id, { paragraphs: [...(node.paragraphs || []), paragraph] });
    setNewParagraph('');
  };
  const handleRemoveParagraph = (pId: string) => {
    if (!node) return;
    onUpdate(node.id, { paragraphs: (node.paragraphs || []).filter(p => p.id !== pId) });
  };
  const handleAddFileLink = () => {
    if (!node || !newFileName.trim() || !newFileUrl.trim()) return;
    const fileLink: NodeFileLink = { id: Date.now().toString(), name: newFileName.trim(), url: newFileUrl.trim() };
    onUpdate(node.id, { fileLinks: [...(node.fileLinks || []), fileLink] });
    setNewFileName('');
    setNewFileUrl('');
  };
  const handleRemoveFileLink = (fId: string) => {
    if (!node) return;
    onUpdate(node.id, { fileLinks: (node.fileLinks || []).filter(f => f.id !== fId) });
  };
  const config = node ? ARGUMENT_TYPE_CONFIG[isEditing ? editType : node.type] : null;
  return (
    <AnimatePresence>
      {node && config && (
        <motion.div
          initial={{ x: 340, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          exit={{ x: 340, opacity: 0 }}
          transition={{ type: 'spring', damping: 28, stiffness: 300 }}
          className="absolute top-4 right-4 bottom-4 w-[320px] glass rounded-2xl z-20 overflow-hidden flex flex-col"
        >
          {/* Header */}
          <div className="p-5 pb-3">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                {React.createElement(TYPE_ICONS[isEditing ? editType : node.type], {
                  size: 16,
                  color: config.color,
                })}
                <span
                  className="text-xs font-semibold tracking-wide uppercase"
                  style={{ color: config.color }}
                >
                  {config.label}
                </span>
              </div>
              <div className="flex items-center gap-1">
                {isEditing ? (
                  <button
                    onClick={handleSave}
                    className="p-1.5 rounded-full hover:bg-secondary transition-colors"
                    title="Save changes"
                  >
                    <Check size={14} className="text-primary" />
                  </button>
                ) : (
                  <button
                    onClick={() => setIsEditing(true)}
                    className="p-1.5 rounded-full hover:bg-secondary transition-colors"
                    title="Edit argument"
                  >
                    <Pencil size={14} className="text-muted-foreground" />
                  </button>
                )}
                <button
                  onClick={onClose}
                  className="p-1.5 rounded-full hover:bg-secondary transition-colors"
                >
                  <X size={14} className="text-muted-foreground" />
                </button>
              </div>
            </div>
            {isEditing ? (
              <Input
                value={editTitle}
                onChange={(e) => setEditTitle(e.target.value)}
                className="text-lg font-semibold"
                autoFocus
              />
            ) : (
              <h2 className="text-lg font-semibold text-foreground leading-tight">
                {node.title}
              </h2>
            )}
          </div>
          <Separator />
          {/* Content */}
          <div className="flex-1 overflow-y-auto p-5 space-y-5">
            {/* Type selector (edit mode) */}
            {isEditing && (
              <div>
                <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Type
                </label>
                <div className="flex gap-1.5 mt-2 flex-wrap">
                  {TYPE_OPTIONS.map((type) => {
                    const tc = ARGUMENT_TYPE_CONFIG[type];
                    const isActive = type === editType;
                    return (
                      <button
                        key={type}
                        onClick={() => setEditType(type)}
                        className={`px-2.5 py-1 rounded-lg text-[10px] font-medium border transition-all ${
                          isActive ? 'border-primary/30 shadow-sm' : 'border-transparent hover:bg-secondary'
                        }`}
                        style={{
                          color: isActive ? tc.color : 'hsl(var(--muted-foreground))',
                          backgroundColor: isActive ? tc.color + '10' : undefined,
                        }}
                      >
                        {tc.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}
            {/* Description */}
            <div>
              <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Description
              </label>
              {isEditing ? (
                <textarea
                  value={editDescription}
                  onChange={(e) => setEditDescription(e.target.value)}
                  rows={4}
                  className="mt-1.5 flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 resize-none"
                />
              ) : (
                <p className="mt-1.5 text-sm text-foreground leading-relaxed">
                  {node.description}
                </p>
              )}
            </div>
            {/* Strength */}
            <div>
              <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Argument Strength
              </label>
              <div className="mt-2 flex items-center gap-1.5">
                {([1, 2, 3, 4, 5] as ArgumentStrength[]).map((s) => (
                  <div
                    key={s}
                    className={`h-2 flex-1 rounded-full transition-colors ${isEditing ? 'cursor-pointer' : ''}`}
                    onClick={() => isEditing && setEditStrength(s)}
                    style={{
                      backgroundColor: s <= (isEditing ? editStrength : node.strength)
                        ? config.color
                        : 'hsl(var(--border))',
                      opacity: s <= (isEditing ? editStrength : node.strength) ? 0.85 : 0.4,
                    }}
                  />
                ))}
              </div>
              <span className="text-xs text-muted-foreground mt-1 inline-block">
                {isEditing ? editStrength : node.strength}/5
              </span>
            </div>
            {/* Legal References */}
            {isEditing ? (
              <div className="space-y-3">
                <div>
                  <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Case Reference
                  </label>
                  <Input
                    value={editCaseRef}
                    onChange={(e) => setEditCaseRef(e.target.value)}
                    placeholder="Optional"
                    className="mt-1.5"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    Legal Basis
                  </label>
                  <Input
                    value={editLegalBasis}
                    onChange={(e) => setEditLegalBasis(e.target.value)}
                    placeholder="Optional"
                    className="mt-1.5"
                  />
                </div>
              </div>
            ) : (
              (node.caseReference || node.legalBasis) && (
                <div className="space-y-3">
                  {node.caseReference && (
                    <div>
                      <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                        Case Reference
                      </label>
                      <div className="mt-1.5 flex items-center gap-2">
                        <Badge variant="secondary" className="text-xs font-medium">
                          <ExternalLink size={10} className="mr-1" />
                          {node.caseReference}
                        </Badge>
                      </div>
                    </div>
                  )}
                  {node.legalBasis && (
                    <div>
                      <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                        Legal Basis
                      </label>
                      <div className="mt-1.5">
                        <Badge variant="outline" className="text-xs font-medium">
                          {node.legalBasis}
                        </Badge>
                      </div>
                    </div>
                  )}
                </div>
              )
            )}
            <Separator />
            {/* Paragraphs */}
            <div>
              <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Paragraphen
              </label>
              <div className="mt-2 space-y-2">
                {(node.paragraphs || []).map((p) => (
                  <div key={p.id} className="group flex items-start gap-2 p-2 rounded-lg bg-secondary/50">
                    <p className="text-xs text-foreground flex-1 leading-relaxed">{p.text}</p>
                    <button
                      onClick={() => handleRemoveParagraph(p.id)}
                      className="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-destructive/10 transition-all shrink-0"                    >
                      <X size={12} className="text-destructive" />
                    </button>
                  </div>
                ))}
                <div className="flex gap-1.5">
                  <Input
                    value={newParagraph}
                    onChange={(e) => setNewParagraph(e.target.value)}
                    placeholder="§ Paragraph hinzufügen..."
                    className="text-xs h-8"
                    onKeyDown={(e) => e.key === 'Enter' && handleAddParagraph()}
                  />
                  <Button size="sm" variant="ghost" className="h-8 px-2 shrink-0" onClick={handleAddParagraph} disabled={!newParagraph.trim()}>
                    <Plus size={14} />
                  </Button>
                </div>
              </div>
            </div>
            {/* File Links */}
            <div>
              <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Dateien / Links
              </label>
              <div className="mt-2 space-y-2">
                {(node.fileLinks || []).map((f) => (
                  <div key={f.id} className="group flex items-center gap-2 p-2 rounded-lg bg-secondary/50">
                    <Link size={12} className="text-muted-foreground shrink-0" />
                    <a
                      href={f.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-primary hover:underline flex-1 truncate"
                    >
                      {f.name}
                    </a>
                    <button
                      onClick={() => handleRemoveFileLink(f.id)}
                      className="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-destructive/10 transition-all shrink-0"                    >
                      <X size={12} className="text-destructive" />
                    </button>
                  </div>
                ))}
                <div className="space-y-1.5">
                  <Input
                    value={newFileName}
                    onChange={(e) => setNewFileName(e.target.value)}
                    placeholder="Name der Datei..."
                    className="text-xs h-8"
                  />
                  <div className="flex gap-1.5">
                    <Input
                      value={newFileUrl}
                      onChange={(e) => setNewFileUrl(e.target.value)}
                      placeholder="URL / Link..."
                      className="text-xs h-8"
                      onKeyDown={(e) => e.key === 'Enter' && handleAddFileLink()}
                    />
                    <Button size="sm" variant="ghost" className="h-8 px-2 shrink-0" onClick={handleAddFileLink} disabled={!newFileName.trim() || !newFileUrl.trim()}>
                      <Plus size={14} />
                    </Button>
                  </div>
                </div>
              </div>
            </div>
            {/* Created date */}
            <div>
              <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Created
              </label>
              <p className="mt-1 text-sm text-muted-foreground">
                {node.createdAt.toLocaleDateString('en-US', {
                  month: 'long',
                  day: 'numeric',
                  year: 'numeric',
                })}
              </p>
            </div>
          </div>
          {/* Footer actions */}
          <div className="p-4 border-t border-border flex gap-2">
            {isEditing ? (
              <>
                <Button
                  variant="ghost"
                  size="sm"
                  className="flex-1"
                  onClick={() => {
                    setIsEditing(false);
                    if (node) {
                      setEditTitle(node.title);
                      setEditDescription(node.description);
                      setEditStrength(node.strength);
                      setEditCaseRef(node.caseReference || '');
                      setEditLegalBasis(node.legalBasis || '');
                      setEditType(node.type);
                    }
                  }}
                >
                  Cancel
                </Button>
                <Button size="sm" className="flex-1" onClick={handleSave} disabled={!editTitle.trim()}>
                  <Check size={14} />
                  Save
                </Button>
              </>
            ) : (
              <Button
                variant="destructive"
                size="sm"
                className="w-full"
                onClick={() => onDelete(node.id)}
              >
                <Trash2 size={14} />
                Remove Argument
              </Button>
            )}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
