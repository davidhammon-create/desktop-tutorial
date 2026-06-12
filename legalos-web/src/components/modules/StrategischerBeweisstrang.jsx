
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { GitBranch, ChevronDown } from "lucide-react";
import ArgumentationskettenVisualisierung from "@/components/lexara/ArgumentationskettenVisualisierung";
import { useAuth } from "@/lib/AuthContext";
import { useNavigate } from "react-router-dom";

export default function StrategischerBeweisstrang() {
  const { isAuthenticated, navigateToLogin } = useAuth();
  const navigate = useNavigate();
  const [cases, setCases] = useState([]);
  const [selectedCaseId, setSelectedCaseId] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) { setLoading(false); return; }
    base44.entities.Case.list("-updated_date", 20).then(cs => {
      setCases(cs);
      if (cs.length > 0) setSelectedCaseId(cs[0].id);
      setLoading(false);
    });
  }, [isAuthenticated]);

  const sf = { fontFamily: "-apple-system, 'Helvetica Neue', Arial, sans-serif" };

  if (!isAuthenticated) {
    return (
      <div
        className="rounded-xl overflow-hidden"
        style={{ background: "#fff", border: "1px solid rgba(0,0,0,0.07)", boxShadow: "0 2px 16px rgba(0,0,0,0.10)", ...sf }}
      >
        <div className="px-8 py-5" style={{ borderBottom: "1px solid rgba(0,0,0,0.07)" }}>
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg flex items-center justify-center" style={{ background: "#e8eaf6" }}>
              <GitBranch className="w-4 h-4" style={{ color: "#5856D6" }} />
            </div>
            <div>
              <p className="text-[13px] font-semibold" style={{ color: "#1a1a1a" }}>Strategischer Beweisstrang</p>
              <p className="text-[10px]" style={{ color: "#999" }}>Argumentationsketten & Lückenanalyse</p>
            </div>
          </div>
        </div>
        <div className="px-8 py-10 text-center">
          <p className="text-[12px]" style={{ color: "#888", marginBottom: 16 }}>Bitte anmelden, um Argumentationsketten zu sehen.</p>
          <button onClick={navigateToLogin}
            style={{ background: "#5856D6", color: "#fff", fontSize: 12, fontWeight: 600, padding: "8px 18px", borderRadius: 8, border: "none", cursor: "pointer" }}>
            Anmelden
          </button>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="rounded-xl flex items-center justify-center py-12" style={{ background: "#fff", border: "1px solid rgba(0,0,0,0.07)" }}>
        <div className="w-5 h-5 border-2 rounded-full animate-spin" style={{ borderColor: "rgba(0,0,0,0.1)", borderTopColor: "#5856D6" }} />
      </div>
    );
  }

  if (cases.length  === 0) {
    return (
      <div className="rounded-xl flex items-center justify-center py-12 text-center" style={{ background: "#fff", border: "1px solid rgba(0,0,0,0.07)" }}>
        <div>
          <p className="text-sm font-medium text-gray-500">Keine Fälle vorhanden</p>
          <p className="text-xs text-gray-400 mt-1">Erstelle zuerst einen Fall in LEXARA.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-xl p-4" style={{ background: "#fff", border: "1px solid rgba(0,0,0,0.07)" }}>
      <p className="text-xs text-gray-500 mb-3">Strategischer Beweisstrang – {cases.length} Fall/Fälle</p>
      <div className="space-y-2">
        {cases.map(c => (
          <div key={c.id} className="flex items-center gap-3 p-2 rounded-lg bg-gray-50">
            <div className="w-2 h-2 rounded-full bg-blue-400 flex-shrink-0" />
            <span className="text-sm text-gray-800 font-medium">{c.fallname}</span>
            <span className="ml-auto text-xs text-gray-400">{Math.round(c.prognose || 0)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}
