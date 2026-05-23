
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Download, RefreshCw, FileText, ChevronDown, ChevronUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import jsPDF from "jspdf";

function LogCard({ log }) {
  const [open, setOpen] = useState(false);
  const ts = log.timestamp ? new Date(log.timestamp) : new Date(log.created_date);
  const timeStr = ts.toLocaleDateString("de-DE") + " " + ts.toLocaleTimeString("de-DE", { hour: "2-digit", minute: "2-digit" });

  let outputParsed = null;
  try { outputParsed = JSON.parse(log.output); } catch {}

  return (
    <div className="bg-white border border-gray-100 rounded-xl overflow-hidden">
      <button onClick={() => setOpen(!open)} className="w-full flex items-start gap-3 p-4 text-left hover:bg-gray-50 transition-colors">
        <div className="w-8 h-8 bg-violet-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
          <FileText className="w-4 h-4 text-violet-600" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs font-bold text-violet-700 bg-violet-50 px-2 py-0.5 rounded">{log.ki_function || "KI"}</span>
            <span className="text-[10px] text-gray-400">{timeStr}</span>
            {log.model && log.model !== "standard" && (
              <span className="text-[10px] text-gray-400 bg-gray-100 px-1.5 py-0.5 rounded">{log.model}</span>
            )}
          </div>
          <p className="text-xs text-gray-600 mt-1 line-clamp-2">{log.input_summary}</p>
        </div>
        <div className="flex-shrink-0 mt-1">
          {open ? <ChevronUp className="w-4 h-4 text-gray-400" /> : <ChevronDown className="w-4 h-4 text-gray-400" />}
        </div>
      </button>

      {open && (
        <div className="border-t border-gray-100 p-4 space-y-4 bg-gray-50">
          <div>
            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">Eingabe / Fragestellung</p>
            <div className="bg-white border border-gray-200 rounded-lg p-3 text-xs text-gray-700 whitespace-pre-wrap leading-relaxed max-h-48 overflow-y-auto">
              {log.input_summary}
            </div>
          </div>

          <div>
            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">KI-Antwort & Begründung</p>
            {outputParsed && typeof outputParsed === "object" ? (
              <div className="space-y-2">
                {Object.entries(outputParsed).map(([key, val]) => (
                  <div key={key} className="bg-white border border-gray-200 rounded-lg p-3">
                    <p className="text-[10px] font-bold text-gray-500 uppercase mb-1">{key.replace(/_/g, " ")}</p>
                    <p className="text-xs text-gray-700 whitespace-pre-wrap leading-relaxed">
                      {typeof val === "object" ? JSON.stringify(val, null, 2) : String(val)}
                    </p>
                  </div>
                ))}
              </div>
            ) : (
              <div className="bg-white border border-gray-200 rounded-lg p-3 text-xs text-gray-700 whitespace-pre-wrap leading-relaxed max-h-64 overflow-y-auto">
                {log.output}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default function TabKIProtokoll({ caseId, caseData }) {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [filterKI, setFilterKI] = useState("alle");

  useEffect(() => { load(); }, [caseId]);

  const load = async () => {
    setLoading(true);
    const data = await base44.entities.KIUsageLog.filter({ case_id: caseId }, "-timestamp", 200);
    setLogs(data);
    setLoading(false);
  };

  const kiNames = ["alle", ...Array.from(new Set(logs.map(l => l.ki_function).filter(Boolean)))];
  const filtered = filterKI === "alle" ? logs : logs.filter(l => l.ki_function
