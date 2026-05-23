
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
        if (filterPeriod === "month") return date.getMonth()
