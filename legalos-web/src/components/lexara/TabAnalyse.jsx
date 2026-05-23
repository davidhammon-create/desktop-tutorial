
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Button } from "@/components/ui/button";
import { Sparkles, RefreshCw, ExternalLink } from "lucide-react";

export default function TabAnalyse({ caseId, caseData, onUpdate, kiMode = true }) {
  const [args, setArgs] = useState([]);
  const [rechtsprechung, setRechtsprechung] = useState(null);
  const [rpLoading, setRpLoading] = useState(false);
  const [savedInsights, setSavedInsights] = useState([]);
  const [savingInsights, setSavingInsights] = useState(false);
  const [form, setForm] = useState({
    streitwert: caseData?.streitwert || 100000,
    gebuehrenstufe: caseData?.gebuehrenstufe || 1.3,
    sv_kosten: caseData?.sv_kosten || 0,
    reisekosten: caseData?.reisekosten || 0,
    vergleichsangebot: caseData?.vergleichsangebot || 0,
    instanz: caseData?.instanz || "Erstinstanz",
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    base44.entities.Argument.filter({ case_id: caseId }).then(setArgs);
    // Load previously saved insights for this jurisdiction/topic
    base44.entities.JurisdictionInsight.filter({}).then(insights => {
      const relevant = insights.filter(i =>
        !caseData?.rechtsgebiet || i.jurisdiction === (caseData?.rechtsgebiet || "DE") || i.topic
