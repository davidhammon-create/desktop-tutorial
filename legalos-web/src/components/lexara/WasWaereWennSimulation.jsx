
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Eye, EyeOff, RefreshCw, Brain, AlertTriangle, Clock, ChevronDown, ChevronUp, FileDown, BookOpen } from "lucide-react";
import { Button } from "@/components/ui/button";
import { jsPDF } from "jspdf";

function computePrognose(args, evidence, persons, deadlines, hiddenIds, caseData) {
  const activeArgs = args.filter(a => !hiddenIds.has(a.id));
  const activeEvidence = evidence.filter(e => !hiddenIds.has(e.id));
  const activeDeadlines = deadlines.filter(d => !hiddenIds.has(d.id));

  const eigene = activeArgs.filter(x => x.side === "eigen");
  const gegner = activeArgs.filter(x => x.side === "gegner");
  const eigenStaerke = eigene.reduce((s, x) => s + (x.strength || 5), 0);
  const gegnerStaerke = gegner.reduce((s, x) => s + (x.strength || 5), 0);
  const argBasis = (eigene.length > 0 || gegner.length > 0)
    ? Math.max(0, ((eigenStaerke / Math.max(1, eigene.length)) - (gegnerStaerke / Math.max(1, gegner.length))) * 5 + 50)
    : 50;
  const avgEvidW = activeEvidence.length > 0 ? activeEvidence.reduce((s, x) => s + (x.weight || 5), 0) / activeEvidence.length : 5;
  const beweisBoost = 1 + (avgEvidW / 10) * 0.5;
  const contradictions = activeArgs.filter(x => x.is_contradiction).length;
  const kantenEffekt = Math.max(0.2, 1 - contradictions * 0.2);
  const judges = persons.filter(x => x.role === "Richter");
  const avgGlaubw = judges.length > 0 ? judges.reduce((s, x) => s + (x.glaubwuerdigkeit || 80), 0) / judges.length : 80;
  const zeugenMult = 0.70 + (avgGlaubw / 100) * 0.30;
  const richterRate = judges[0]?.klaeger_rate || caseData?.richter_klaeger_rate || 50;
  const richterAdj = 1 + (richterRate - 50) / 100 * 0.15;
  const versaeumt = activeDeadlines.filter(x => x.status === "versaeumt").length;
  const fristenFaktor = Math.max(0.5, 1 - versaeumt * 0.30);
  const raw = argBasis * beweisBoost * kantenEffekt * zeugenMult * richterAdj * fristenFaktor;
  return Math.min(99, Math.max(1, Math.round(raw)));
}

function ToggleRow({ item, type, isHidden, onToggle, badge, badgeColor }) {
  return (
    <div className={`flex items-center gap-2 px-3 py-2 rounded-lg border transition-all ${isHidden ? "opacity-40 bg-gray-50 border-gray-100" : "bg-white border-gray-200"}`}>
      <button onClick={() => onToggle(item.id)} className="text-gray-400 hover:text-gray-700 transition-colors flex-shrink-0">
        {isHidden ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
      </button>
      <div className="flex-1 min-w-0">
        <p className={`text-xs font-medium truncate ${isHidden ? "line-through text-gray-400" : "text-gray-800"}`}>{item.title || item.name || item.fallname}</p>
        {item.due_date && <p className="text-[10px] text-gray-400">{item.due_date} · {item.status}</p>}
      </div>
      <span className={`text-[9px] px-1.5 py-0.5 rounded font-semibold ${badgeColor}`}>{badge}</span>
    </div>
  );
}

function PrognoseBar({ value, label, delta }) {
  const color = value >= 60 ? "bg-green-600" : value >= 40 ? "bg-amber-500" : "bg-red-600";
  return (
    <div>
      <div className="flex items-center justify-between mb-1">
        <span className="text-xs text-gray-500">{label}</span>
        <div className="flex items-center gap-2">
          <span className="text-sm font-bold text-gray-900">{value}%</span>
          {delta !== undefined && delta !== 0 && (
            <span className={`text-xs font-semibold ${delta > 0 ? "text-green-600" : "text-red-600"}`}>
              {delta > 0 ? "+" : ""}{delta}%
            </span>
          )}
        </div>
      </div>
      <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
        <div className={`h-full rounded-full transition-all duration-500 ${color}`} style={{ width: `${value}%` }} />
      </div>
    </div>
  );
}

function Section({ id, label, children, expandedSection, setExpandedSection }) {
  return (
    <div className="border border-gray-200 rounded-xl overflow-hidden">
      <button onClick={() => setExpandedSection(expandedSection
