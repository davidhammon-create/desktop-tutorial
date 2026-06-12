
import { useState, useEffect, useRef } from "react";
import { base44 } from "@/api/base44Client";
import { Upload, FileText, Trash2, Loader2, Sparkles, File, CheckCircle, RefreshCw, Copy, Check } from "lucide-react";
import { Button } from "@/components/ui/button";

const DOC_TYPES = [
  { value: "klageschrift", label: "Klageschrift" },
  { value: "klageerweiterung", label: "Klageerweiterung" },
  { value: "erwiderung", label: "Klageerwiderung" },
  { value: "berufungsschrift", label: "Berufungsschrift" },
  { value: "schlussvortrag", label: "Schlussvortrag / Plädoyer" },
  { value: "vergleichsangebot", label: "Vergleichsangebot" },
];

export default function TabDokumente({ caseId, caseData }) {
  const [imported, setImported] = useState({});
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [analyzing, setAnalyzing] = useState(null);
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
  const [activeTab, setActiveTab] = useState("dokumente");
  const fileRef = useRef();

  useEffect(() => { loadDocs(); }, [caseId]);
  useEffect(() => {
    Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId }),
    ]).then(([a, e]) => { setArgs(a); setEvidence(e); });
  }, [caseId]);

  const loadDocs = async () => {
    setLoading(true);
    const docs = await base44.entities.Document.filter({ case_id: caseId });
    setDocuments(docs);
    setLoading(false);
  };

  const handleUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    const { file_url } = await base44.integrations.Core.UploadFile({ file });
    await base44.entities.Document.create({
      case_id: caseId,
      title: file.name,
      file_url,
      file_type: file.type,
      description: "",
    });
    await loadDocs();
    setUploading(false);
    fileRef.current.value = "";
  };

  const handleAnalyze = async (doc) => {
    setAnalyzing(doc.id);
    const result = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist juristischer Experte. Erstelle eine Executive Summary dieses Dokuments.
Extrahiere strukturiert:
1. Kurze Zusammenfassung (2-3 Sätze)
2. Wichtigste Argumente
3. Fristen (Titel, Datum im Format YYYY-MM-DD, Typ)
4. Beteiligte Personen (Name, Rolle)
5. Beweisfragen

Dokument: ${doc.title}`,
      file_urls: [doc.file_url],
      response_json_schema: {
        type: "object",
        properties: {
          summary: { type: "string" },
          arguments: { type: "array", items: { type: "string" } },
          fristen: { type: "array", items: { type: "object", properties: { titel: {type:"string"}, datum: {type:"string"}, typ: {type:"string"} } } },
          personen: { type: "array", items: { type: "object", properties: { name: {type:"string"}, rolle: {type:"string"} } } },
          beweisfragen: { type: "array", items: { type: "string" } }
        }
      }
    });
    await base44.entities.Document.update(doc.id, {
      ai_summary: result.summary,
      extracted_arguments: result.arguments,
      ai_raw: result,
    });
    await loadDocs();
    setAnalyzing(null);
  };

  const importFrist = async (caseId, frist) => {
    if (!frist.titel || !frist.datum) return;
    await base44.entities.Deadline.create({ case_id: caseId, title: frist.titel, due_date: frist.datum, frist_type: frist.typ || "Sonstige", status: "offen", side: "Eigene" });
  };

  const importPerson = async (caseId, person) => {
    if (!person.name) return;
    await base44.entities.Person.create({ case_id: caseId, name: person.name, role: person.rolle || "Partei" });
  };

  const handleDelete = async (id) => {
    await base44.entities.Document.delete(id);
    setDocuments(prev => prev.filter(d => d.id !== id));
  };

  const generate = async () => {
    setGenerating(true);
    setResult(null);
    const eigene = args.filter(a => a.side === "eigen");
    const gegnerArgs = args.filter(a => a.side === "gegner");
    const evByArg = (argId) => evidence.filter(e => e.argument_id
