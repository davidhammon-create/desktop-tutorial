
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { CheckCircle, Loader2, Zap, AlertCircle, ChevronDown, ChevronRight, Check, Info, BookOpen, Lightbulb } from "lucide-react";
import { Button } from "@/components/ui/button";

const SEVERITY_CONFIG = {
  kritisch: { label: "Kritisch", dot: "#1C1C1E", weight: 700 },
  hoch:     { label: "Hoch",     dot: "#636366", weight: 600 },
  mittel:   { label: "Mittel",   dot: "#8E8E93", weight: 500 },
  niedrig:  { label: "Niedrig",  dot: "#AEAEB2", weight: 400 },
};

const WARNING_TYPE_LABELS = {
  diskrepanz:          "Diskrepanz",
  fehlender_beleg:     "Fehlender Beleg",
  veraltete_rspr:      "Veraltete Rechtsprechung",
  unterstuetzung_fehlt:"Unterstützung fehlt",
  widerspruch:         "Widerspruch",
};

const SF = { fontFamily: "-apple-system,'SF Pro Text','Helvetica Neue',Arial,sans-serif" };
const C = {
  label:  "#1C1C1E",
  label2: "#636366",
  label3: "#AEAEB2",
  sep:    "rgba(0,0,0,0.08)",
  card:   "#FFFFFF",
  bg:     "#F4F4F4",
};

export default function ComplianceChecker({ caseId, caseData }) {
  const [warnings, setWarnings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [checking, setChecking] = useState(false);
  const [expandedId, setExpandedId] = useState(null);
  const [filter, setFilter] = useState("all");
  const [lastCheck, setLastCheck] = useState(null);

  useEffect(() => { loadWarnings(); }, [caseId]);

  const loadWarnings = async () => {
    setLoading(true);
    const data = await base44.entities.CaseWarning.filter({ case_id: caseId, resolved: false });
    setWarnings(data.sort((a, b) => {
      const o = { kritisch: 0, hoch: 1, mittel: 2, niedrig: 3 };
      return o[a.severity] - o[b.severity];
    }));
    setLoading(false);
  };

  const runCompliance = async () => {
    setChecking(true);
    try {
      await base44.functions.invoke("checkCaseCompliance", { caseId });
      setLastCheck(new Date());
      await loadWarnings();
    } catch (error) {
      console.error("Compliance-Prüfung Fehler:", error);
    }
    setChecking(false);
  };

  const resolveWarning = async (warningId) => {
    await base44.entities.CaseWarning.update(warningId, {
      resolved: true,
      resolved_date: new Date().toISOString(),
    });
    await loadWarnings();
  };

  const filteredWarnings = filter === "all" ? warnings : warnings.filter(w => w.severity
