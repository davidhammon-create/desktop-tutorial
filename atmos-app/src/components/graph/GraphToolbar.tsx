import React, { useRef } from 'react';
import { motion } from 'framer-motion';
import { Plus, ZoomIn, ZoomOut, Maximize, RotateCcw, MousePointer2, Undo2, Redo2, Save, FolderOpen, GitBranch } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipTrigger, TooltipContent } from '@/components/ui/tooltip';
import { Separator } from '@/components/ui/separator';
import { ExportMenu } from './ExportMenu';
import { toast } from 'sonner';
interface GraphToolbarProps {
  zoom: number;
  onZoomIn: () => void;
  onZoomOut: () => void;
  onResetView: () => void;
  onFitView: () => void;
  onAddNode: () => void;
  nodeCount: number;
  edgeCount: number;
  clickConnectMode: boolean;
  onToggleClickConnect: () => void;
  onUndo: () => void;
  onRedo: () => void;
  canUndo: boolean;
  canRedo: boolean;
  onSave: () => void;
  onLoad: (file: File) => void;
  onAutoLayout: () => void;
}
export const GraphToolbar: React.FC<GraphToolbarProps> = ({
  zoom, onZoomIn, onZoomOut, onResetView, onFitView, onAddNode,
  nodeCount, edgeCount, clickConnectMode, onToggleClickConnect,
  onUndo, onRedo, canUndo, canRedo, onSave, onLoad, onAutoLayout,
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      try {
        onLoad(file);
        toast.success('Graph loaded successfully');
      } catch {
        toast.error('Failed to load graph file');
      }
    }
    if (fileInputRef.current) fileInputRef.current.value = '';
  };
  return (
    <motion.div
      initial={{ y: -20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ delay: 0.2, type: 'spring', damping: 25 }}
      className="absolute top-4 right-4 glass rounded-2xl px-2 py-1.5 flex items-center gap-1 z-10"
    >
      <input ref={fileInputRef} type="file" accept=".json" className="hidden" onChange={handleFileChange} />
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onAddNode}>
            <Plus size={18} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Add Argument</TooltipContent>
      </Tooltip>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant={clickConnectMode ? "default" : "ghost"} size="icon" className="h-9 w-9 rounded-xl" onClick={onToggleClickConnect}>
            <MousePointer2 size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>{clickConnectMode ? 'Click-Connect: Click 2 Nodes' : 'Click-Connect Mode'}</TooltipContent>
      </Tooltip>
      <Separator orientation="vertical" className="h-6 mx-1" />
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onUndo} disabled={!canUndo}>
            <Undo2 size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Undo (Ctrl+Z)</TooltipContent>
      </Tooltip>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onRedo} disabled={!canRedo}>
            <Redo2 size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Redo (Ctrl+Shift+Z)</TooltipContent>
      </Tooltip>
      <Separator orientation="vertical" className="h-6 mx-1" />
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onZoomOut}>
            <ZoomOut size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Zoom Out</TooltipContent>
      </Tooltip>
      <span className="text-xs font-medium text-muted-foreground w-12 text-center tabular-nums">
        {Math.round(zoom * 100)}%
      </span>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onZoomIn}>
            <ZoomIn size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Zoom In</TooltipContent>
      </Tooltip>
      <Separator orientation="vertical" className="h-6 mx-1" />
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onFitView}>
            <Maximize size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Fit View</TooltipContent>
      </Tooltip>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onAutoLayout}>
            <GitBranch size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Auto Layout</TooltipContent>
      </Tooltip>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onResetView}>
            <RotateCcw size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Reset View</TooltipContent>
      </Tooltip>
      <Separator orientation="vertical" className="h-6 mx-1" />
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={onSave}>
            <Save size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Save as JSON</TooltipContent>
      </Tooltip>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" onClick={() => fileInputRef.current?.click()}>
            <FolderOpen size={16} />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Load from JSON</TooltipContent>
      </Tooltip>
      <Separator orientation="vertical" className="h-6 mx-1" />
      <ExportMenu targetId="graph-canvas-container" />
      <Separator orientation="vertical" className="h-6 mx-1" />
      <div className="flex items-center gap-3 px-2">
        <span className="text-xs text-muted-foreground">
          <span className="font-medium text-foreground">{nodeCount}</span> nodes
        </span>
        <span className="text-xs text-muted-foreground">
          <span className="font-medium text-foreground">{edgeCount}</span> edges
        </span>
      </div>
    </motion.div>
  );
};
