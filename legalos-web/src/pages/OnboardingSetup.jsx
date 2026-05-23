
import { useState } from "react";
import { Scale } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useUserProfile } from "../hooks/useUserProfile";
import DisclaimerStep from "../components/onboarding/DisclaimerStep";
import LanguageStep from "../components/onboarding/LanguageStep";
import JurisdictionStep from "../components/onboarding/JurisdictionStep";

const STEP_LABELS = {
  DE: ["Sprache", "Nutzungsbedingungen", "Rechtsordnung"],
  EN: ["Language", "Terms of Use", "Jurisdiction"],
  FR: ["Langue", "Conditions d'utilisation", "Juridiction"],
};

export default function OnboardingSetup() {
  const { language, jurisdiction, usState, setLanguage, setJurisdiction, setUsState, completeOnboarding } = useUserProfile();
  const [step, setStep] = useState(1);
  const navigate = useNavigate();

  const handleComplete = async () => {
    await completeOnboarding();
    navigate("/", { replace: true });
  };

  const labels = STEP_LABELS[language] || STEP_LABELS.DE;

  const handleAdminSkip = async () => {
    await completeOnboarding();
    navigate("/", { replace: true });
  };

  return (
    <div className="min-h-screen bg-[#F5F6F8] flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-lg">
        {/* Brand */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2.5 mb-5">
            <div className="w-9 h-9 rounded-xl bg-[#1a3560] flex items-center justify-center shadow-lg">
              <Scale className="w-[18px] h-[18px] text-white" />
            </div>
            <span className="font-bold text-[17px] text-slate-900 tracking-tight">MachiavelLEX</span>
          </div>
          {/* Step indicators */}
          <div className="flex items-center justify-center gap-0">
            {[1, 2, 3].map((s, i) => (
              <div key={s} className="flex items-center">
                <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                  s
