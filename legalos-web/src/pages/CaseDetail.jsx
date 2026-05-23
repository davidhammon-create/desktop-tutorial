
/**
 * CaseDetail.jsx — Haupt-Fallansicht (9-Reiter-Struktur)
 *
 * URL: /lexara/case?id=<caseId>
 *
 * Reiter-Übersicht:
 *   1  Fallakte           → Tab1Fallerfassung     (Basisdaten, Dokumente & KI-Analyse)
 *   2  Substanz           → Tab2SubstanzCore       (Argumente, Beweise, Zeitstrahl)
 *   3  Akteure & Fristen  → Tab3AkteureFristen     (Personen, Fristen)
 *   4  Gegner             → Tab3Gegneranalyse      (Profil, KI-Berater, Verhaltenstracking)
 *   5  Recht & Compliance → Tab4RechtlicheAnalyse  (Compliance, Kosten, Präzedenzfälle)
 *   6  Strategie          → TabStrategiePrognose   (Strategie, Was-wäre-wenn, Risiko, Risikomatrix)
 *   7  Simulation         → TabSimulationCockpit   (Verhandlung, Gesamtbewertung, Cockpit, Netzwerk)
 *   8  Aktion             → Tab8Aktion             (Verhandlungsführung, Schriftsatz)
 *   9  Abschluss          → TabAbschlussProtokoll  (Abschluss, KI-Protokoll, Zeitstrahl, Prognosen, Risiko)
 *
 * Navigation zwischen Reitern:
 *   - Klick auf Tab-Bar oben
 *   - Sidebar-Links dispatchen CustomEvent "lexara_goto_step"
 *   - Zurück/Weiter-Buttons unten
 */

import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { ArrowLeft, ArrowRight, Check, Download } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";

// ── Reiter-Komponenten (in Reihenfolge der 9 Schritte) ───────────────────────
import Tab1Fallerfassung from "../components/lexara/Tab1Fallerfassung";
import Tab2SubstanzCore from "../components/lexara/Tab2SubstanzCore";
import Tab3AkteureFristen from "../components/lexara/Tab3AkteureFristen";
import Tab3Gegneranalyse from "../components/lexara/Tab3Gegneranalyse";    // Reiter 4
import Tab4RechtlicheAnalyse from "../components/lexara/Tab4RechtlicheAnalyse"; // Reiter 5
import TabStrategiePrognose from "../components/lexara/TabStrategiePrognose";
import TabSimulationCockpit from "../components/lexara/TabSimulationCockpit";
import Tab8Aktion from "../components/lexara/Tab8Aktion";
import TabAbschlussProtokoll from "../components/lexara/TabAbschlussProtokoll";
import VerfahrensBegründung from "../components/lexara/VerfahrensBegründung";

import { exportCasePDF } from "@/functions/exportCasePDF";

// ── Tab-Konfiguration ─────────────────────────────────────────────────────────
// Arbeitslogik: Erfassen → Verstehen → Delegieren → Analysieren → Entscheiden → Handeln → Abschließen
const TABS = [
  {id:1, label:"Fallakte",          subs:["Basisdaten","Dokumente & KI-Analyse"]},
  {id:2, label:"Substanz",          subs:["Argumente & Beweise","Dokumentenanalyse / Zeitstrahl"]},
  {id:3, label:"Akteure & Fristen", subs:["Personen & Beteiligte","Fristen & Termine"]},
  {id:4, label:"Gegner",            subs:["Profil & Simulation","KI-Berater","Verhaltenstracking","Risikomatrix"]},
  {id:5, label:"Recht & Compliance",subs:["Compliance-Prüfung","Kostenanalyse","Präzedenzfälle"]},
  {id:6, label:"Strategie & Prognose", subs:["Strategie & KI-Prognose","Was-wäre-wenn","Monte Carlo","KI-Risikomatrix"]},
  {id:7, label:"Simulation & Cockpit", subs:["Verhandlungssimulation","Gesamtbewertung","Fall-Cockpit","Fallanalyse-Netzwerk"]},
  {id:8, label:"Aktion",            subs:["Verhandlungsführung","Schriftsatz-Generator"]},
  {id:9, label:"Abschluss",         subs:["Abschluss & Monte Carlo","KI-Protokoll","Zeitstrahl (Gesamt)"]},
];

function PrognoseCircle({ value = 0 }) {
  const r = 18, circ = 2 * Math.PI * r, offset = circ - (value/100)*circ;
  return (
    <svg width="46" height="46" style={{transform:"rotate(-90deg)"}}>
      <circle cx="23" cy="23" r={r} fill="none" stroke="#e5e7eb" strokeWidth="3"/>
      <circle cx="23" cy="23" r={r} fill="none" stroke="#1f2937" strokeWidth="3" strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round"/>
      <text x="23" y="23" dominantBaseline="central" textAnchor="middle"
        style={{transform:"rotate(90deg)",transformOrigin:"23px 23px",fontSize:10,fontWeight:700,fill:"#111827"}}>
        {Math.round(value)}
      </text>
    </svg>
  );
}

export default function CaseDetail() {
  const urlParams = new URLSearchParams(window.location.search);
  const caseId = urlParams.get("id");
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState(1);
  const [activeSub, setActiveSub] = useState(0);
  const [caseData, setCaseData] = useState(null);
  const [counts, setCounts] = useState({args:0,evidence:0,persons:0,deadlines:0});
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [kiMode, setKiMode] = useState(() => localStorage.getItem('lexara_ki_mode') !== 'false');

  const toggleKiMode = () => setKiMode(prev => {
    const next = !prev;
    localStorage.setItem('lexara_ki_mode', String(next));
    return next;
  });

  const handleExportCSV = async () => {
    setExporting(true);
    const [args, evs, pers, deadlines] = await Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId }),
      base44.entities.Person.filter({ case_id: caseId }),
      base44.entities.Deadline.filter({ case_id: caseId }),
    ]);

    const sections = [];

    // Case header
    sections.push("
