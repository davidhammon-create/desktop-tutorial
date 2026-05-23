
import { useState, useEffect, useRef } from "react";
import { base44 } from "@/api/base44Client";
import { Send, RefreshCw, Bot, User, Sparkles, ChevronDown, ChevronUp } from "lucide-react";
import { Button } from "@/components/ui/button";

const ROLLEN = [
  { id: "anwalt_gegner", label: "Gegnerischer Anwalt", desc: "Aggressiv, taktisch, sucht Schwachstellen", emoji: "⚖️" },
  { id: "richter", label: "Kritischer Richter", desc: "Hinterfragt beide Seiten, skeptisch, präzise", emoji: "🧑‍⚖️" },
  { id: "verhandlungsfuehrer", label: "Verhandlungsführer (Harvard)", desc: "Win-Win orientiert, sachlich, lösungsfokussiert", emoji: "🤝" },
  { id: "mandant_gegner", label: "Gegnerischer Mandant", desc: "Emotional, stur, will maximalen Druck", emoji: "😤" },
];

const SZENARIEN = [
  { id: "eroefffnung", label: "Verhandlungseröffnung", desc: "Erste Positionierung und Weichenstellung" },
  { id: "beweisangriff", label: "Beweisangriff", desc: "Gegner greift Ihre Hauptbeweise an" },
  { id: "vergleich", label: "Vergleichsverhandlung", desc: "Annäherung auf einen Vergleich" },
  { id: "kreuzverhör", label: "Kreuzverhör Zeuge", desc: "Glaubwürdigkeit eines Zeugen testen" },
  { id: "plädoyer", label: "Schlussplädoyer", desc: "Finale Argumentation vor Urteilsfindung" },
];

export default function TabVerhandlungssimulation({ caseId, caseData }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [gewaehltRolle, setGewaehltRolle] = useState(null);
  const [gewaehltSzenario, setGewaehltSzenario] = useState(null);
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [started, setStarted] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [showFeedback, setShowFeedback] = useState(false);
  const [urteilsAnalyse, setUrteilsAnalyse] = useState(null);
  const [showUrteil, setShowUrteil] = useState(false);
  const [urteilLoading, setUrteilLoading] = useState(false);
  const bottomRef = useRef(null);

  useEffect(() => {
    Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId }),
    ]).then(([a, e]) => { setArgs(a); setEvidence(e); });
  }, [caseId]);

  useEffect(() => {
    if (bottomRef.current) bottomRef.current.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const startSession = async () => {
    if (!gewaehltRolle || !gewaehltSzenario) return;
    setStarted(true);
    setLoading(true);
    const rolle = ROLLEN.find(r => r.id
