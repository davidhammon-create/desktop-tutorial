
import { useState } from "react";
import TabKIBerater from "./TabKIBerater";
import GegnerVerhaltenDashboard from "./GegnerVerhaltenDashboard";
import GegnerRisikoMatrix from "./GegnerRisikoMatrix";
import GegnerProfilSimulation from "./GegnerProfilSimulation";
import SubTabBar from "./SubTabBar";

const SUB_TABS = ["🎯 Profil & Simulation", "🧠 KI-Berater", "📊 Verhaltenstracking", "⚠️ Risikomatrix"];

export default function Tab3Gegneranalyse({ caseId, caseData, onUpdate, kiMode }) {
  const [sub, setSub] = useState(0);
  return (
    <div className="space-y-4">
      <SubTabBar tabs={SUB_TABS} active={sub} onChange={setSub} level="primary" />
      <div className={sub
