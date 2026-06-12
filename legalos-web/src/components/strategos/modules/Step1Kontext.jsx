
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Upload, FileUp, Check, Sparkles, Trash2 } from "lucide-react";
import { AppleCard, AppleField, AppleInput, AppleTextarea, AppleSelect, AppleButton, ApplePill, SF } from "../AppleCard";
import { RECHTSGEBIETE_VOLLSTAENDIG } from "@/lib/strategosRechtsgebiete";

const RECHTSFORMEN = ["GmbH","AG","GmbH & Co. KG","SE","Ltd.","Inc.","OHG","KG","Einzelunternehmen","Sonstige"];
const BRANCHEN = ["Technologie","Pharma","Automobil","Energie","Finanzdienstleistungen","Handel","Immobilien","Maschinenbau","Chemie","Telekommunikation","Medien","Rüstung / Verteidigung","Agrar / Lebensmittel","Sonstige"];
const LAENDER = ["Deutschland","Österreich","Schweiz","Niederlande","Frankreich","Italien","Spanien","UK","USA","China","Sonstige"];
const MAERKTE = ["DE","AT","CH","UK","US","EU","CN","Asien-Pazifik","MENA","LATAM","Global"];
const SITUATIONSTYPEN = [
  { value: "geplante_handlung", label: "Geplante Handlung", icon: "🎯" },
  { value: "bestehende_situation", label: "Bestehende Situation", icon: "🔍" },
  { value: "reaktion_dritte", label: "Reaktion auf Dritten", icon: "⚡" },
  { value: "vertrag_analyse", label: "Vertrag / Dokument", icon: "📄" },
  { value: "risikovorsorge", label: "Compliance-Check", icon: "🛡️" },
];
// Alle 19 Rechtsgebiete aus der zentralen Wissensbasis
const RECHTSGEBIETE = RECHTSGEBIETE_VOLLSTAENDIG;

export default function Step1Kontext({ scenario, onSave }) {
  const [ctx, setCtx] = useState(scenario.unternehmenskontext || {});
  const [docs, setDocs] = useState((scenario.unternehmenskontext || {}).dokumente || []);
  const [uploading, setUploading] = useState(false);
  const [selRG, setSelRG] = useState((scenario.unternehmenskontext || {}).rechtsgebiete || []);
  const [selM, setSelM] = useState((scenario.unternehmenskontext || {}).operative_maerkte || []);
  const [analyzing, setAnalyzing] = useState(false);
  const [lexCases, setLexCases] = useState([]);
  const [linkedCase, setLinkedCase] = useState(null);

  useEffect(() => {
    base44.entities.Case.list("-updated_date", 50).then(setLexCases);
  }, []);

  const persist = (p) => {
    const m = { ...ctx, ...p };
    setCtx(m);
    onSave({ unternehmenskontext: m });
  };

  const toggleM = (m) => {
    const n = selM.includes(m) ? selM.filter(x => x !== m) : [...selM, m];
    setSelM(n);
    persist({ operative_maerkte: n });
  };

  const toggleRG = (k) => {
    const n = selRG.includes(k) ? selRG.filter(x => x !== k) : [...selRG, k];
    setSelRG(n);
    persist({ rechtsgebiete: n });
  };

  const handleUpload = async (e) => {
    const files = Array.from(e.target.files || []);
    if (!files.length) return;
    setUploading(true);
    const up = [];
    for (const f of files) {
      const r = await base44.integrations.Core.UploadFile({ file: f });
      up.push({ name: f.name, url: r.file_url, type: f.name.split(".").pop().toLowerCase(), uploaded_at: new Date().toISOString() });
    }
    const n = [...docs, ...up];
    setDocs(n);
    persist({ dokumente: n });
    setUploading(false);
  };

  const analyzeDoc = async (doc) => {
    setUploading(true);
    const r = await base44.integrations.Core.ExtractDataFromUploadedFile({
      file_url: doc.url,
      json_schema: {
        type: "object",
        properties: {
          dokumenttyp: { type: "string" },
          parteien: { type: "array", items: { type: "string" } },
          fristen: { type: "array", items: { type: "object", properties: { datum: { type: "string" }, beschreibung: { type: "string" } } } },
          kritische_klauseln: { type: "array", items: { type: "string" } }
        }
      }
    });
    const n = docs.map(d => d.url
