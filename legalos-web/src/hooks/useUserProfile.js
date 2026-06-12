import { useState } from "react";

const DEFAULT_PROFILE = { language: "DE", jurisdiction: "DE", usState: "CA", disclaimerAccepted: true, onboardingDone: true, hasModuleAccess: true, kiCredits: 500 };

export function useUserProfile() {
  const [profile, setProfile] = useState(DEFAULT_PROFILE);
  const setLanguage = (lang) => setProfile(p => ({ ...p, language: lang }));
  const setJurisdiction = (jur) => setProfile(p => ({ ...p, jurisdiction: jur }));
  const setUsState = (state) => setProfile(p => ({ ...p, usState: state }));
  const completeOnboarding = async () => setProfile(p => ({ ...p, disclaimerAccepted: true, onboardingDone: true }));
  return { ...profile, isLoadingProfile: false, setLanguage, setJurisdiction, setUsState, completeOnboarding };
}
