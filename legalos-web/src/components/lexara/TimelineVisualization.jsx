
import { useState, useEffect, useRef } from "react";
import { base44 } from "@/api/base44Client";
import { DragDropContext, Droppable, Draggable } from "@hello-pangea/dnd";
import { Link2, X, ChevronDown, ChevronUp, Calendar, Clock, AlertTriangle, CheckCircle2, Circle } from "lucide-react";
import { Button } from "@/components/ui/button";

const STATUS_CONFIG = {
  offen: { label: "Offen", color: "bg-blue-100 text-blue-700 border-blue-200", dot: "bg-blue-500" },
  erledigt: { label: "Erledigt", color: "bg-green-100 text-green-700 border-green-200", dot: "bg-green-500" },
  versaeumt: { label: "Versäumt", color: "bg-red-100 text-red-700 border-red-200", dot: "bg-red-500" },
  in_bearbeitung: { label: "In Bearb.", color: "bg-yellow-100 text-yellow-700 border-yellow-200", dot: "bg-yellow-500" },
};

const STATUS_COLS = ["offen", "in_bearbeitung", "erledigt", "versaeumt"];

function ArgLinkModal({ deadline, args, onClose, onSave }) {
  const [selected, setSelected] = useState(deadline.linked_arg_ids || []);
  const toggle = (id) => setSelected(s => s.includes(id) ? s.filter(x => x !== id) : [...s, id]);
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={onClose}>
      <div className="bg-white rounded-2xl shadow-xl p-5 max-w-md w-full mx-4" onClick={e => e.stopPropagation()}>
        <div className="flex items-start justify-between mb-3">
          <div>
            <h4 className="text-sm font-bold text-gray-800">🔗 Argumente verknüpfen</h4>
            <p className="text-xs text-gray-500 mt-0.5">{deadline.title}</p>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600"><X className="w-4 h-4" /></button>
        </div>
        <div className="space-y-1.5 max-h-60 overflow-y-auto mb-4">
          {args.length
