
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { RefreshCw, Copy, Check, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";

const DOC_TYPES = [
  { value: "klageschrift", label: "Klageschrift" },
  { value: "klageerweiterung", label: "Klageerweiterung" },
  { value: "erwiderung", label: "Klageerwiderung" },
  { value: "berufungsschrift", label: "Berufungsschrift" },
  { value: "schlussvortrag", label: "Schlussvortrag / Plädoyer" },
  { value: "vergleichsangebot", label: "Vergleichsangebot" },
];

export default function TabSchriftsatz({ caseId, caseData }) {
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [docType, setDocType] = useState("klageschrift");
  const [anwaltName, setAnwaltName] = useState("");
  const [kanzlei, setKanzlei] = useState("");
  const [mandant, setMandant] = useState("");
  const [gegner, setGegner] = useState("");
  const [freitext, setFreitext] = useState("");
  const [generating, setGenerating] = useState(false);
  const [result, setResult] = useState(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId }),
    ]).then(([a, e]) => { setArgs(a); setEvidence(e); });
  }, [caseId]);

  const generate = async () => {
    setGenerating(true);
    setResult(null);
    const eigene = args.filter(a => a.side === "eigen");
    const gegnerArgs = args.filter(a => a.side === "gegner");

    const evByArg = (argId) => evidence.filter(e => e.argument_id
