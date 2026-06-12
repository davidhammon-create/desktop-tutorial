
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { ArrowLeft, Plus, RefreshCw, Star } from "lucide-react";
import ErfolgsMatrix from "./ErfolgsMatrix";
import AkteureBeziehungen from "./AkteureBeziehungen";
import { Button } from "@/components/ui/button";
import { getTByLanguage } from "../../lib/jurisdictionConfig";
import { useUserProfile } from "../../hooks/useUserProfile";

const EMPTY_EXP = { datum: new Date().toISOString().split("T")[0], autor: "", fall_kontext: "", vergleichsbereitschaft: 5, entscheidungsgeschwindigkeit: 5, sachkompetenz: 5, text: "" };

function StarRating({ value, onChange, max = 10 }) {
  return (
    <div className="flex items-center gap-1">
      {Array.from({ length: max }, (_, i) => (
        <button key={i} type="button" onClick={() => onChange && onChange(i + 1)}
          className={`w-5 h-5 rounded-full text-[10px] font-bold transition-colors ${i < value ? "bg-gray-800 text-white" : "bg-gray-100 text-gray-400"}`}>
          {i + 1}
        </button>
      ))}
    </div>
  );
}

export default function RichterDetail({ profile, cases, allProfiles = [], onBack, onUpdate }) {
  const { language } = useUserProfile();
  const t = getTByLanguage(language);
  const [showExpForm, setShowExpForm] = useState(false);
  const [expForm, setExpForm] = useState(EMPTY_EXP);
  const [kiLoading, setKiLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const erfahrungen = profile.erfahrungen || [];
  const linkedCases = cases.filter(c => c.richter_name
