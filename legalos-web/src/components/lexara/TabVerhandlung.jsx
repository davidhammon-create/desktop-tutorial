
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { RefreshCw, Clock, CheckCircle2, AlertCircle, Calendar, ChevronDown, ChevronUp, Plus, X } from "lucide-react";
import { Button } from "@/components/ui/button";

const EVENT_TYPES = [
  { value: "frist", label: "Frist", color: "bg-red-100 text-red-700 border-red-200", icon: "⏰" },
  { value: "korrespondenz", label: "Korrespondenz", color: "bg-blue-100 text-blue-700 border-blue-200", icon: "✉️" },
  { value: "schritt", label: "Verhandlungsschritt", color: "bg-green-100 text-green-700 border-green-200", icon: "⚖️" },
  { value: "termin", label: "Gerichtstermin", color: "bg-purple-100 text-purple-700 border-purple-200", icon: "🏛️" },
  { value: "massnahme", label: "Maßnahme", color: "bg-amber-100 text-amber-700 border-amber-200", icon: "📋" },
];

function TimelineSection({ caseId, caseData }) {
  const [deadlines, setDeadlines] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [events, setEvents] = useState(() => {
    try { return JSON.parse(localStorage.getItem(`timeline_${caseId}`) || "[]"); } catch { return []; }
  });
  const [showAdd, setShowAdd] = useState(false);
  const [newEv, setNewEv] = useState({ title: "", date: "", type: "schritt", notes: "", done: false });
  const [showTimeline, setShowTimeline] = useState(true);

  useEffect(() => {
    Promise.all([
      base44.entities.Deadline.filter({ case_id: caseId }),
      base44.entities.Task.filter({ case_id: caseId }),
    ]).then(([d, t]) => { setDeadlines(d); setTasks(t); });
  }, [caseId]);

  const saveEvents = (evs) => {
    setEvents(evs);
    localStorage.setItem(`timeline_${caseId}`, JSON.stringify(evs));
  };

  const addEvent = () => {
    if (!newEv.title.trim() || !newEv.date) return;
    saveEvents([...events, { ...newEv, id: Date.now().toString() }]);
    setNewEv({ title: "", date: "", type: "schritt", notes: "", done: false });
    setShowAdd(false);
  };

  const toggleDone = (id) => saveEvents(events.map(e => e.id
