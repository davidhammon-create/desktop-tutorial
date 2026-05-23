
import { useState } from "react";
import TabVerhandlungssimulation from "./TabVerhandlungssimulation";
import TabGesamtbewertung from "./TabGesamtbewertung";
import TabCockpit from "./TabCockpit";
import CaseInfluenceGraph from "./CaseInfluenceGraph";
import SubstanzDiagramme from "./SubstanzDiagramme";
import SubTabBar from "./SubTabBar";
import StrategieCheckliste from "./StrategieCheckliste";

const SUB_TABS = [
  "🎭 Verhandlung",
  "🏆 Gesamtbewertung",
  "🎛️ Cockpit",
  "🕸️ Netzwerk",
  "📊 Stärken-Analyse",
  "⚔️ Strategie-Checkliste",
];

export default function TabSimulationCockpit({ caseId, caseData, kiMode, activeSub }) {
  const [sub, setSub] = useState(activeSub || 0);
  return (
    <div className="space-y-4">
      <SubTabBar tabs={SUB_TABS} active={sub} onChange={setSub} level="primary" />
      <div className={sub
