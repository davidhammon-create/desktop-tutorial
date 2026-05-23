
import { useState } from "react";
import TabArgumenteBeweisVerkettung from "./TabArgumenteBeweisVerkettung";
import TabPersonen from "./TabPersonen";
import TabFristen from "./TabFristen";
import TabZeitstrahl from "./TabZeitstrahl";

const SUB_TABS = ["⚖️ Argumente & Beweise", "👥 Personen", "⏰ Fristen", "📅 Zeitstrahl"];

export default function Tab2Fallsubstanz({ caseId, caseData, onCountChange, kiMode, activeSub }) {
  const [sub, setSub] = useState(activeSub || 0);
  return (
    <div className="space-y-4">
      <div className="flex gap-2 border-b border-gray-100 overflow-x-auto">
        {SUB_TABS.map((label, i) => (
          <button key={i} onClick={() => setSub(i)}
            className={`px-3 py-2 text-sm font-medium border-b-2 transition-all whitespace-nowrap ${
              sub === i ? "border-blue-500 text-blue-600" : "border-transparent text-gray-500 hover:text-gray-700"
            }`}>
            {label}
          </button>
        ))}
      </div>
      {sub === 0 && <TabArgumenteBeweisVerkettung caseId={caseId} caseData={caseData} onCountChange={onCountChange} kiMode={kiMode} />}
      {sub === 1 && <TabPersonen caseId={caseId} onCountChange={onCountChange} />}
      {sub === 2 && <TabFristen caseId={caseId} />}
      {sub === 3 && <TabZeitstrahl caseId={caseId} caseData={caseData} />}
    </div>
  );
}
