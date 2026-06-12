
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { RefreshCw, Sparkles, AlertTriangle, CheckCircle2, Clock, Target, Shield } from "lucide-react";
import { Button } from "@/components/ui/button";

function PrognoseGauge({ value = 0 }) {
  const color = value >= 65 ? "#16a34a" : value >= 40 ? "#d97706" : "#dc2626";
  const r = 52, circ = Math.PI * r, offset = circ - (value / 100) * circ;
  return (
    <div className="flex flex-col items-center">
      <svg width="120" height="68" viewBox="0 0 120 68">
        <path d={`M 14 60 A ${r} ${r} 0 0 1 106 60`} fill="none" stroke="#e5e7eb" strokeWidth="10" strokeLinecap="round" />
        <path d={`M 14 60 A ${r} ${r} 0 0 1 106 60`} fill="none" stroke={color} strokeWidth="10" strokeLinecap="round"
          strokeDasharray={circ} strokeDashoffset={offset} style={{ transition: "stroke-dashoffset 0.8s ease" }} />
      </svg>
      <div className="text-2xl font-bold -mt-8" style={{ color }}>{value}%</div>
      <div className="text-xs text-gray-400 mt-0.5">Erfolgswahrscheinlichkeit</div>
    </div>
  );
}

export default function TabCockpit({ caseId, caseData }) {
  const [deadlines, setDeadlines] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [args, setArgs] = useState([]);
  const [lastMinute, setLastMinute] = useState(null);
  const [loadingCheck, setLoadingCheck] = useState(false);
  const [warnings, setWarnings] = useState([]);

  useEffect(() => {
    Promise.all([
      base44.entities.Deadline.filter({ case_id: caseId }),
      base44.entities.Task.filter({ case_id: caseId }),
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.CaseWarning.filter({ case_id: caseId, resolved: false }),
    ]).then(([d, t, a, w]) => { setDeadlines(d); setTasks(t); setArgs(a); setWarnings(w); });
  }, [caseId]);

  const criticalWarnings = warnings.filter(w => w.severity === "kritisch");
  const highWarnings = warnings.filter(w => w.severity === "hoch");

  const now = new Date();
  const prognose = caseData?.prognose || 0;

  const urgentTasks = tasks
    .filter(t => t.status !== "erledigt")
    .sort((a, b) => {
      const pa = a.priority === "hoch" ? 0 : a.priority === "mittel" ? 1 : 2;
      const pb = b.priority === "hoch" ? 0 : b.priority === "mittel" ? 1 : 2;
      return pa - pb || new Date(a.due_date) - new Date(b.due_date);
    })
    .slice(0, 3);

  const upcomingDeadlines = deadlines
    .filter(d => d.status !== "erledigt" && new Date(d.due_date) >= now)
    .sort((a, b) => new Date(a.due_date) - new Date(b.due_date))
    .slice(0, 5);

  // Event-Alerts
  const alerts = [];

  // Compliance-Warnungen hinzufügen
  if (criticalWarnings.length > 0) {
    alerts.push({
      type: "compliance",
      severity: "critical",
      title: `⚠️ ${criticalWarnings.length} KRITISCHE Compliance-Warnung(en)`,
      description: criticalWarnings.map(w => w.title).slice(0, 2).join(" | "),
      icon: "🔴"
    });
  } else if (highWarnings.length > 0) {
    alerts.push({
      type: "compliance",
      severity: "high",
      title: `${highWarnings.length} Compliance-Warnung(en)`,
      description: "Überprüfen Sie die Analyse für Details",
      icon: "🟠"
    });
  }
  
  const missedDeadlines = deadlines.filter(d => d.status === "versaeumt");
  const missedDeadlinesThisWeek = missedDeadlines.filter(d => {
    const daysAgo = (now - new Date(d.due_date)) / 86400000;
    return daysAgo >= 0 && daysAgo <= 7;
  });
  if (missedDeadlines.length > 0) {
    alerts.push({
      type: "deadline",
      severity: "critical",
      title: `${missedDeadlines.length} Frist(en) versäumt`,
      description: missedDeadlinesThisWeek.length > 0 ? `${missedDeadlinesThisWeek.length} diese Woche` : "Auswirkung auf Prognose",
      icon: "⚠️"
    });
  }
  if (args.filter(a => a.side === "gegner" && (a.strength || 5) >= 7).length >= 3) {
    alerts.push({
      type: "arguments",
      severity: "high",
      title: "Starke Gegenerargumente",
      description: "3+ starke Gegnerargumente vorhanden",
      icon: "🛡️"
    });
  }
  if (prognose < 40) {
    alerts.push({
      type: "prognose",
      severity: "high",
      title: "Niedriges Erfolgsrisiko",
      description: `Prognose nur ${prognose}%`,
      icon: "📉"
    });
  }

  const gegnerArgs = args.filter(a => a.side === "gegner").sort((a, b) => (b.strength || 5) - (a.strength || 5)).slice(0, 4);

  const daysUntil = (d) => Math.ceil((new Date(d) - now) / 86400000);
  const formatDate = (d) => { try { return new Date(d).toLocaleDateString("de-DE", { day: "2-digit", month: "short" }); } catch { return d; } };

  const runLastMinuteCheck = async () => {
    setLoadingCheck(true);
    const res = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist ein Verhandlungscoach. Führe einen Last-Minute-Check für den bevorstehenden Gerichtstermin durch.

Fall: ${caseData?.fallname || ""}, ${caseData?.rechtsgebiet || ""}
Prognose: ${caseData?.prognose || 0}%
Prozessziel: ${caseData?.prozessziel || ""}

Stärkste Gegenargumente des Gegners:
${gegnerArgs.map(a => `- ${a.title} (Stärke ${a.strength || 5}/10): ${a.description || ""}`).join("\n")}

Eigene Argumente:
${args.filter(a => a.side === "eigen").slice(0, 5).map(a => `- ${a.title} (Stärke ${a.strength || 5}/10)`).join("\n")}

Liefere:
1. Die 3 gefährlichsten Angriffspunkte des Gegners mit schnellen Konterstrategien
2. Die 3 wichtigsten Dinge, die der Anwalt im Termin NICHT tun sollte
3. Einen motivierenden, prägnanten Schluss-Satz für den Anwalt`,
      response_json_schema: {
        type: "object",
        properties: {
          gefahren: { type: "array", items: { type: "object", properties: { angriff: { type: "string" }, konter: { type: "string" } } } },
          verbote: { type: "array", items: { type: "string" } },
          motiviation: { type: "string" }
        }
      }
    });
    setLastMinute(res);
    setLoadingCheck(false);
  };

  const prognoseColor = prognose >= 65 ? "text-green-600" : prognose >= 40 ? "text-amber-600" : "text-red-600";
  const prognoseLabel = prognose >= 65 ? "Gute Ausgangslage" : prognose >= 40 ? "Ausgangslage unklar" : "Schwierige Ausgangslage";

  return (
    <div className="space-y-5">
      {/* Event-Alerts */}
      {alerts.length > 0 && (
        <div className="space-y-2">
          {alerts.map((alert, i) => {
            const bgColor = alert.severity === "critical" ? "bg-red-50 border-red-200" : "bg-amber-50 border-amber-200";
            const textColor = alert.severity === "critical" ? "text-red-700" : "text-amber-700";
            return (
              <div key={i} className={`border rounded-xl p-3 ${bgColor}`}>
                <div className="flex items-start gap-2">
                  <span className="text-lg">{alert.icon}</span>
                  <div>
                    <p className={`text-xs font-semibold ${textColor}`}>{alert.title}</p>
                    <p className={`text-[10px] ${textColor} opacity-80`}>{alert.description}</p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold text-gray-900">⚖️ Verhandlungs-Cockpit</h2>
          <p className="text-xs text-gray-400 mt-0.5">Alle kritischen Informationen für den Gerichtstermin auf einen Blick</p>
        </div>
        <span className={`text-xs font-medium px-3 py-1 rounded-full border ${caseData?.status === "Aktiv" ? "bg-blue-50 text-blue-700 border-blue-200" : "bg-gray-100 text-gray-600 border-gray-200"}`}>
          {caseData?.status || "Unbekannt"}
        </span>
      </div>

      {/* Top row: Prognose + Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl border border-gray-100 p-5 flex flex-col items-center justify-center">
          <PrognoseGauge value={prognose} />
          <span className={`text-xs font-semibold mt-1 ${prognoseColor}`}>{prognoseLabel}</span>
        </div>

        <div className="md:col-span-2 grid grid-cols-2 gap-3">
          {[
            { icon: "⚔️", label: "Eigene Argumente", value: args.filter(a => a.side === "eigen").length, sub: "erfasst", color: "text-blue-600" },
            { icon: "🛡️", label: "Gegner-Argumente", value: args.filter(a => a.side === "gegner").length, sub: "bekannt", color: "text-red-600" },
            { icon: "📋", label: "Offene Aufgaben", value: tasks.filter(t => t.status !== "erledigt").length, sub: "ausstehend", color: "text-amber-600" },
            { icon: "⏰", label: "Kommende Fristen", value: upcomingDeadlines.length, sub: "aktiv", color: "text-purple-600" },
          ].map((s, i) => (
            <div key={i} className="bg-white rounded-xl border border-gray-100 p-4">
              <div className="text-lg mb-1">{s.icon}</div>
              <div className={`text-2xl font-bold ${s.color}`}>{s.value}</div>
              <div className="text-xs text-gray-400">{s.label}</div>
              <div className="text-[10px] text-gray-300">{s.sub}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Middle row: Tasks + Deadlines */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Top 3 Tasks */}
        <div className="bg-white rounded-2xl border border-gray-100 p-5">
          <div className="flex items-center gap-2 mb-4">
            <Target className="w-4 h-4 text-amber-500" />
            <h3 className="text-sm font-semibold text-gray-800">3 Dringendste To-Dos</h3>
          </div>
          {urgentTasks.length
