
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { X, Scale, Loader2, ChevronDown } from "lucide-react";
import { getAIContext, JURISDICTION_META } from "../../lib/jurisdictionConfig";
import { useUserProfile } from "../../hooks/useUserProfile";
import ReactMarkdown from "react-markdown";
import FeedbackWidget from "../FeedbackWidget";

export default function FallAnalyseModal({ cases, onClose, t = {} }) {
  const { jurisdiction, usState, language } = useUserProfile();
  const [selectedCaseId, setSelectedCaseId] = useState("");
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const selectedCase = cases.find(c => c.id
