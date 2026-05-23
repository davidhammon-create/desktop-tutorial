
import { useState } from "react";
import TabPersonen from "./TabPersonen";
import TabFristen from "./TabFristen";
import SubTabBar from "./SubTabBar";

const SUB_TABS = ["👥 Personen & Beteiligte", "⏰ Fristen & Termine"];

export default function Tab3AkteureFristen({ caseId, caseData, onCountChange, kiMode, activeSub }) {
  const [sub, setSub] = useState(activeSub || 0);
  return (
    <div className="space-y-4">
      <SubTabBar tabs={SUB_TABS} active={sub} onChange={setSub} level="primary" />
      <div className={sub
