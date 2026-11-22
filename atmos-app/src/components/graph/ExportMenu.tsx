import React, { useState } from 'react';
import { Download, FileImage, FileText, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipTrigger, TooltipContent } from '@/components/ui/tooltip';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { toPng } from 'html-to-image';
import { jsPDF } from 'jspdf';
import { toast } from 'sonner';
interface ExportMenuProps {
  targetId: string;
}
export const ExportMenu: React.FC<ExportMenuProps> = ({ targetId }) => {
  const [isExporting, setIsExporting] = useState(false);
  const getTargetElement = () => {
    const el = document.getElementById(targetId);
    if (!el) {
      toast.error('Could not find graph element to export');
      return null;
    }
    return el;
  };
  const exportAsPng = async () => {
    const el = getTargetElement();
    if (!el) return;
    setIsExporting(true);
    try {
      const dataUrl = await toPng(el, {
        backgroundColor: '#fafafa',
        pixelRatio: 2,
        filter: (node) => {
          // Exclude interactive UI overlays from export
          if (node instanceof HTMLElement && node.classList?.contains('z-10')) return false;
          return true;
        },
      });
      const link = document.createElement('a');
      link.download = `argument-graph-${Date.now()}.png`;
      link.href = dataUrl;
      link.click();
      toast.success('Graph exported as PNG');
    } catch (err) {
      console.error(err);
      toast.error('Failed to export as PNG');
    } finally {
      setIsExporting(false);
    }
  };
  const exportAsPdf = async () => {
    const el = getTargetElement();
    if (!el) return;
    setIsExporting(true);
    try {
      const dataUrl = await toPng(el, {
        backgroundColor: '#fafafa',
        pixelRatio: 2,
        filter: (node) => {
          if (node instanceof HTMLElement && node.classList?.contains('z-10')) return false;
          return true;
        },
      });
      const img = new Image();
      img.src = dataUrl;
      await new Promise((resolve) => { img.onload = resolve; });
      const pdf = new jsPDF({
        orientation: img.width > img.height ? 'landscape' : 'portrait',
        unit: 'px',
        format: [img.width / 2, img.height / 2],
      });
      pdf.addImage(dataUrl, 'PNG', 0, 0, img.width / 2, img.height / 2);
      pdf.save(`argument-graph-${Date.now()}.pdf`);
      toast.success('Graph exported as PDF');
    } catch (err) {
      console.error(err);
      toast.error('Failed to export as PDF');
    } finally {
      setIsExporting(false);
    }
  };
  return (
    <DropdownMenu>
      <Tooltip>
        <TooltipTrigger asChild>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-9 w-9 rounded-xl" disabled={isExporting}>
              {isExporting ? <Loader2 size={16} className="animate-spin" /> : <Download size={16} />}
            </Button>
          </DropdownMenuTrigger>
        </TooltipTrigger>
        <TooltipContent>Export Graph</TooltipContent>
      </Tooltip>
      <DropdownMenuContent align="center" sideOffset={8}>
        <DropdownMenuItem onClick={exportAsPng} className="gap-2">
          <FileImage size={14} />
          Export as PNG
        </DropdownMenuItem>
        <DropdownMenuItem onClick={exportAsPdf} className="gap-2">
          <FileText size={14} />
          Export as PDF
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
};
