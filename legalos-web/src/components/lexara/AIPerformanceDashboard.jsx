
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { TrendingUp, AlertCircle, CheckCircle, Zap, Edit2, X, Star } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

export default function AIPerformanceDashboard({ caseId }) {
  const [feedbacks, setFeedbacks] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({});
  const [saving, setSaving] = useState(false);
  const [filterPeriod, setFilterPeriod] = useState("all");
  const [filterAdvisor, setFilterAdvisor] = useState("all");
  const [editingId, setEditingId] = useState(null);
  const [editForm, setEditForm] = useState({});
  const [showEditModal, setShowEditModal] = useState(false);
  const [trendData, setTrendData] = useState([]);
  const [advisors, setAdvisors] = useState([]);
  const [kiLogs, setKiLogs] = useState([]);
  const [showKiHistory, setShowKiHistory] = useState(false);
  const [ratingLog, setRatingLog] = useState(null);
  const [ratingForm, setRatingForm] = useState({});

  useEffect(() => {
    loadData();
  }, [caseId]);

  const loadData = async () => {
    setLoading(true);
    const data = await base44.entities.AIPerformanceFeedback.filter({});
    const logs = await base44.entities.KIUsageLog.filter({ case_id: caseId });
    setFeedbacks(data);
    setKiLogs(logs.sort((a, b) => new Date(b.created_date) - new Date(a.created_date)));
    calculateStats(data);
    buildTrendData(data);
    extractAdvisors(data);
    setLoading(false);
  };

  const buildTrendData = (data) => {
    const sorted = [...data].sort((a, b) => new Date(a.created_date) - new Date(b.created_date));
    const grouped = {};
    sorted.forEach(item => {
      const date = new Date(item.created_date).toLocaleDateString('de-DE');
      if (!grouped[date]) grouped[date] = { date, ratings: [], successCount: 0 };
      if (item.gesamtbewertung) grouped[date].ratings.push(item.gesamtbewertung);
      if (item.fall_erfolgreich) grouped[date].successCount++;
    });
    const trend = Object.values(grouped).map(g => ({
      date: g.date,
      gesamtbewertung: g.ratings.length > 0 ? (g.ratings.reduce((a, b) => a + b) / g.ratings.length).toFixed(2) : 0,
      erfolgsquote: g.successCount,
    }));
    setTrendData(trend);
  };

  const extractAdvisors = (data) => {
    const uniqueAdvisors = [...new Set(data.map(d => d.created_by))];
    setAdvisors(uniqueAdvisors);
  };

  const handleCreate = async () => {
    if (!form.gesamtbewertung) {
      alert('Bitte Gesamtbewertung angeben');
      return;
    }
    setSaving(true);
    const caseData = await base44.entities.Case.filter({ id: caseId }).then(c => c[0]);
    await base44.entities.AIPerformanceFeedback.create({
      case_id: caseId,
      case_name: caseData?.fallname || "",
      gesamtbewertung: form.gesamtbewertung,
      prognose_rating: form.prognose_rating,
      strategie_rating: form.strategie_rating,
      ki_berater_rating: form.ki_berater_rating,
      fall_erfolgreich: form.fall_erfolgreich,
      ki_feedback: form.ki_feedback,
    });
    setForm({});
    setShowForm(false);
    await loadData();
    setSaving(false);
  };

  const handleEditOpen = (feedback) => {
    setEditingId(feedback.id);
    setEditForm({ ...feedback });
    setShowEditModal(true);
  };

  const handleEditSave = async () => {
    setSaving(true);
    await base44.entities.AIPerformanceFeedback.update(editingId, editForm);
    setEditingId(null);
    setShowEditModal(false);
    await loadData();
    setSaving(false);
  };

  const handleRateKiLog = async () => {
    if (!ratingForm.rating) {
      alert('Bitte Bewertung angeben');
      return;
    }
    setSaving(true);
    await base44.entities.KIUsageLog.update(ratingLog.id, ratingForm);
    setRatingLog(null);
    setRatingForm({});
    await loadData();
    setSaving(false);
  };

  const getFilteredData = () => {
    let filtered = feedbacks;
    if (filterPeriod !== "all") {
      const now = new Date();
      filtered = filtered.filter(f => {
        const date = new Date(f.created_date);
        if (filterPeriod === "month") return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
        if (filterPeriod === "week") return (now - date) <= 7 * 24 * 60 * 60 * 1000;
        return true;
      });
    }
    if (filterAdvisor !== "all") filtered = filtered.filter(f => f.ki_modell === filterAdvisor);
    return filtered;
  };

  const filtered = getFilteredData();
  const avgRating = filtered.length ? (filtered.reduce((a, f) => a + (f.bewertung || 0), 0) / filtered.length).toFixed(1) : "—";

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h3 className="text-sm font-semibold text-gray-800">📊 KI-Performance Dashboard</h3>
        <div className="flex gap-2">
          <select className="border border-gray-200 rounded-lg px-2 py-1 text-xs bg-white" value={filterPeriod} onChange={e => setFilterPeriod(e.target.value)}>
            <option value="all">Alle Zeiträume</option>
            <option value="month">Dieser Monat</option>
            <option value="week">Diese Woche</option>
          </select>
          <button onClick={() => setShowForm(!showForm)} className="text-xs px-3 py-1 bg-violet-600 text-white rounded-lg">+ Feedback</button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {[
          ["Ø Bewertung", avgRating, "⭐"],
          ["Feedbacks", filtered.length, "💬"],
          ["KI-Logs", kiLogs.length, "🤖"],
        ].map(([l, v, icon]) => (
          <div key={l} className="bg-white border border-gray-100 rounded-xl p-3 text-center">
            <p className="text-xl">{icon}</p>
            <p className="text-xl font-bold text-gray-900 mt-1">{v}</p>
            <p className="text-[10px] text-gray-400">{l}</p>
          </div>
        ))}
      </div>

      {trendData.length > 0 && (
        <div className="bg-white border border-gray-100 rounded-xl p-4">
          <p className="text-xs font-semibold text-gray-600 mb-3">Bewertungs-Trend</p>
          <ResponsiveContainer width="100%" height={120}>
            <LineChart data={trendData}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
              <XAxis dataKey="month" tick={{ fontSize: 9, fill: "#aaa" }} />
              <YAxis domain={[0, 5]} tick={{ fontSize: 9, fill: "#aaa" }} />
              <Tooltip />
              <Line type="monotone" dataKey="avg" stroke="#5856D6" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}

      {filtered.length > 0 && (
        <div className="space-y-2">
          {filtered.slice(0, 5).map(fb => (
            <div key={fb.id} className="bg-white border border-gray-100 rounded-xl p-3">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-xs font-semibold text-gray-700">{fb.ki_modell || "KI"}</span>
                <span className="text-xs text-yellow-500">{"★".repeat(fb.bewertung || 0)}</span>
                <span className="ml-auto text-[10px] text-gray-400">{fb.created_date ? new Date(fb.created_date).toLocaleDateString("de-DE") : ""}</span>
              </div>
              {fb.kommentar && <p className="text-xs text-gray-600">{fb.kommentar}</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
}
