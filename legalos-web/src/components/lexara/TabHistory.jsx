
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { ChevronDown, Search, Filter, Download, Sparkles } from "lucide-react";

const ENTITY_ICONS = {
  Argument: "⚖️",
  Evidence: "📄",
  Deadline: "⏰",
  Person: "👤",
  Document: "📋",
  Case: "📁",
  Risk: "⚠️",
};

const ACTION_COLORS = {
  create: "bg-green-50 text-green-700 border-green-200",
  update: "bg-blue-50 text-blue-700 border-blue-200",
  delete: "bg-red-50 text-red-700 border-red-200",
};

function TimelineEntry({ entry, expanded, onToggle }) {
  const icon = ENTITY_ICONS[entry.entity_type] || "•";
  const date = new Date(entry.timestamp);
  const timeStr = date.toLocaleTimeString("de-DE", { hour: "2-digit", minute: "2-digit" });
  const dateStr = date.toLocaleDateString("de-DE");

  let oldVal, newVal;
  try {
    oldVal = entry.old_value ? JSON.parse(entry.old_value) : null;
    newVal = entry.new_value ? JSON.parse(entry.new_value) : null;
  } catch {
    oldVal = entry.old_value;
    newVal = entry.new_value;
  }

  return (
    <div className="bg-white border border-gray-100 rounded-xl overflow-hidden hover:border-gray-200 transition-colors">
      <button
        onClick={() => onToggle()}
        className="w-full flex items-start gap-4 px-4 py-3 text-left hover:bg-gray-50/50 transition-colors"
      >
        {/* Timeline dot */}
        <div className="flex flex-col items-center gap-2 pt-1 flex-shrink-0">
          <div className={`w-3 h-3 rounded-full ring-4 ring-white ${
            entry.action === 'create' ? 'bg-green-500' :
            entry.action === 'update' ? 'bg-blue-500' :
            'bg-red-500'
          }`} />
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1 flex-wrap">
            <span className="text-base">{icon}</span>
            <span className="text-xs font-bold text-gray-700 uppercase tracking-widest">
              {entry.entity_type}
            </span>
            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${ACTION_COLORS[entry.action]}`}>
              {entry.action}
            </span>
            <span className="text-xs text-gray-400 ml-auto flex-shrink-0">{timeStr}</span>
          </div>
          <p className="text-sm text-gray-800 font-medium mb-1">{entry.entity_title || entry.summary}</p>
          <p className="text-xs text-gray-600">{entry.summary}</p>
          {entry.user_email && (
            <p className="text-[10px] text-gray-400 mt-1">von {entry.user_email}</p>
          )}
        </div>

        {/* Expand button */}
        <div className="flex-shrink-0">
          <ChevronDown
            className={`w-4 h-4 text-gray-400 transition-transform ${expanded ? 'rotate-180' : ''}`}
          />
        </div>
      </button>

      {/* Details */}
      {expanded && (
        <div className="px-4 pb-4 bg-gray-50/50 border-t border-gray-100 space-y-3 pt-3">
          {entry.field_changed && (
            <div>
              <p className="text-[10px] font-bold text-gray-400 uppercase mb-1">Feld</p>
              <p className="text-xs text-gray-700 font-mono">{entry.field_changed}</p>
            </div>
          )}

          {entry.old_value && (
            <div>
              <p className="text-[10px] font-bold text-red-600 uppercase mb-1">Alter Wert</p>
              <div className="bg-white rounded-lg p-2 border border-red-100">
                <code className="text-[10px] text-gray-700 break-all">
                  {typeof oldVal === 'object' ? JSON.stringify(oldVal, null, 2) : String(oldVal)}
                </code>
              </div>
            </div>
          )}

          {entry.new_value && (
            <div>
              <p className="text-[10px] font-bold text-green-600 uppercase mb-1">Neuer Wert</p>
              <div className="bg-white rounded-lg p-2 border border-green-100">
                <code className="text-[10px] text-gray-700 break-all">
                  {typeof newVal === 'object' ? JSON.stringify(newVal, null, 2) : String(newVal)}
                </code>
              </div>
            </div>
          )}

          {entry.entity_id && (
            <div>
              <p className="text-[10px] font-bold text-gray-400 uppercase mb-1">Entity ID</p>
              <p className="text-[10px] text-gray-600 font-mono">{entry.entity_id}</p>
            </div>
          )}

          <div>
            <p className="text-[10px] font-bold text-gray-400 uppercase mb-1">Zeitstempel</p>
            <p className="text-[10px] text-gray-600 font-mono">{entry.timestamp}</p>
          </div>
        </div>
      )}
    </div>
  );
}

export default function TabHistory({ caseId }) {
  const [history, setHistory] = useState([]);
  const [caseData, setCaseData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterType, setFilterType] = useState("all");
  const [filterAction, setFilterAction] = useState("all");
  const [expandedSummary, setExpandedSummary] = useState(null);

  useEffect(() => {
    loadHistory();
  }, [caseId]);

  const loadHistory = async () => {
    setLoading(true);
    const [entries, cs] = await Promise.all([
      base44.entities.CaseHistory.filter({ case_id: caseId }, "-timestamp", 100),
      base44.entities.Case.filter({ id: caseId }),
    ]);
    setHistory(entries);
    setCaseData(cs[0] || null);
    setLoading(false);
  };

  const filtered = history.filter(h => {
    const matchSearch = !searchTerm ||
      h.summary?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      h.entity_title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      h.entity_type?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchType = filterType === "all" || h.entity_type
