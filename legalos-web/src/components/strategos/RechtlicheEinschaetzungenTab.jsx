
import { useState } from "react";
import { Copy, Check, ChevronDown, ChevronUp, Scale, FileText, AlertTriangle, Lightbulb, BarChart2, Map } from "lucide-react";

function CopyButton({ text }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      onClick={() => { navigator.clipboard.writeText(text); setCopied(true); setTimeout(() => setCopied(false), 2000); }}
      style={{ display: "flex", alignItems: "center", gap: 4, padding: "4px 9px", borderRadius: 7, fontSize: 10, fontWeight: 600, background: copied ? "#34C75915" : "rgba(0,0,0,0.05)", color: copied ? "#34C759" : "#888", border: `1px solid ${copied ? "#34C75930" : "rgba(0,0,0,0.08)"}`, cursor: "pointer", transition: "all 0.15s", flexShrink: 0 }}>
      {copied ? <Check size={10} /> : <Copy size={10} />}
      {copied ? "Kopiert" : "Kopieren"}
    </button>
  );
}

function EinschaetzungBlock({ title, icon: Icon, color, content, subItems }) {
  const [open, setOpen] = useState(true);
  if (!content && (!subItems || subItems.length
