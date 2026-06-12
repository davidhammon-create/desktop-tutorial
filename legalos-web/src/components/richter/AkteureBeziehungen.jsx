
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Button } from "@/components/ui/button";
import { RefreshCw, Users, ArrowRight } from "lucide-react";

const KAT_ICONS = { Richter: "⚖️", Anwalt: "👔", Kanzlei: "🏛️", Zeuge: "👁️", Sachverstaendiger: "🔬", Partei: "🏢", Sonstiges: "📋" };
const DYNAMIK_COLOR = {
  positiv: "bg-green-100 text-green-800 border-green-200",
  neutral: "bg-gray-100 text-gray-600 border-gray-200",
  angespannt: "bg-amber-100 text-amber-800 border-amber-200",
  konfliktiv: "bg-red-100 text-red-800 border-red-200",
};

export default function AkteureBeziehungen({ profile, allProfiles, cases }) {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(profile.beziehungsanalyse || null);
  const [expanded, setExpanded] = useState(null);

  const sharedCaseActors = allProfiles.filter(p => {
    if (p.id
