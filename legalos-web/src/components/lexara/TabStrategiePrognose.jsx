
import { useState } from "react";
import TabStrategie from "./TabStrategie";
import TabRisiko from "./TabRisiko";
import RiskMatrix from "./RiskMatrix";
import SubTabBar from "./SubTabBar";

const SUB_TABS = [
  "🎯 Strategie & Prognose",
  "🔀 Was-wäre-wenn",
  "📉 Monte Carlo & Risiko",
  "⚠️ KI-Risikomatrix",
];

export default function TabStrategiePrognose({ caseId, caseData, onUpdate, kiMode, activeSub }) {
  const [sub, setSub] = useState(activeSub || 0);
  return (
    <div className="space-y-4">
      <SubTabBar tabs={SUB_TABS} active={sub} onChange={setSub} level="primary" />
      <div className={sub
