
import { useState, useEffect } from "react";
import Tab10Abschluss from "./Tab10Abschluss";
import TabKIProtokoll from "./TabKIProtokoll";
import TabZeitstrahl from "./TabZeitstrahl";
import TabPrognoseVergleich from "./TabPrognoseVergleich";
import RiskMatrix from "./RiskMatrix";
import TabRisiko from "./TabRisiko";
import SubTabBar from "./SubTabBar";

const SUB_TABS = [
  "🏁 Abschluss",
  "📋 KI-Protokoll",
  "📅 Zeitstrahl",
  "📊 Prognose-Vergleich",
  "⚠️ Risiko",
];

export default function TabAbschlussProtokoll({ caseId, caseData, kiMode, activeSub }) {
  const [sub, setSub] = useState(activeSub || 0);
  useEffect(() => { setSub(activeSub || 0); }, [activeSub]);
  return (
    <div className="space-y-4">
      <SubTabBar tabs={SUB_TABS} active={sub} onChange={setSub} level="primary" />
      <div className={sub
