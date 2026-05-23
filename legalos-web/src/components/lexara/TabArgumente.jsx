
import { useState, useEffect, useRef } from "react";
import { base44 } from "@/api/base44Client";
import { invokeLLM, uploadFile } from "@/lib/kiProvider";
import ComplianceStatusBadge from "./ComplianceStatusBadge";
import { Plus, Upload, X, RefreshCw, Trash2, ChevronDown, ChevronUp, Sparkles, Pencil, Check, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useKIProtokoll } from "@/hooks/useKIProtokoll";
import { toast } from "sonner";

function ScoreBar({ value, max = 10, color = "bg-green-500" }) {
  return (
    <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
      <div className={`h-full ${color} rounded-full transition-all`} style={{ width: `${((value || 0) / max) * 100}%` }} />
    </div>
  );
}

function ArgCard({ arg, onDelete, onSave, onKiWeight }) {
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({ title: arg.title, description: arg.description || "", side: arg.side || "eigen", type: arg.type || "Rechtsargument", strength: arg.strength || 5, zeitpunkt: arg.zeitpunkt || "", anmerkungen: arg.anmerkungen || "", paragraphs: arg.paragraphs || [] });
  const [newPara, setNewPara] = useState("");
  const [analyzing, setAnalyzing] = useState(false);
  const [analysis, setAnalysis] = useState(null);
  const [kiWeighting, setKiWeighting] = useState(false);

  const discrepancy = arg.ki_strength !== undefined && arg.ki_strength !== null
    ? Math.abs((arg.strength || 5) - arg.ki_strength)
    : 0;
  const hasDiscrepancy = discrepancy >= 2;

  const save = async () => {
    await base44.entities.Argument.update(arg.id, { ...form, zeitpunkt: form.zeitpunkt || null, anmerkungen: form.anmerkungen || null });
    setEditing(false);
    onSave();
  };

  const addParagraph = () => {
    if (!newPara.trim()) return;
    setForm(f => ({ ...f, paragraphs: [...(f.paragraphs || []), newPara.trim()] }));
    setNewPara("");
  };

  const removeParagraph = (i) => {
    setForm(f => ({ ...f, paragraphs: (f.paragraphs || []).filter((_, j) => j !== i) }));
  };

  const kiWeight = async () => {
    setKiWeighting(true);
    const result = await invokeLLM({
      prompt: `Du bist ein erfahrener Rechtsanwalt. Bewerte die Stärke dieses Rechtsarguments im deutschen Zivilprozess.\nArgument: "${arg.title}"\nBeschreibung: "${arg.description || ""}"\nTyp: ${arg.type || "Rechtsargument"}, Seite: ${arg.side || "eigen"}\n\nGib eine Stärke (0-10) UND eine kurze juristische Begründung (2-3 Sätze) zurück.`,
      response_json_schema: {
        type: "object",
        properties: {
          staerke: { type: "number", minimum: 0, maximum: 10 },
          begruendung: { type: "string" }
        }
      }
    });
    if (result && result.staerke !== undefined) {
      await base44.entities.Argument.update(arg.id, {
        ki_strength: Math.min(10, Math.max(0, result.staerke)),
        ki_reasoning: result.begruendung || ""
      });
      onSave();
    }
    setKiWeighting(false);
  };

  const analyzeDiscrepancy = async () => {
    setAnalyzing(true);
    const res = await invokeLLM({
      prompt: `Analysiere die Diskrepanz zwischen manueller und KI-Bewertung dieses Rechtsarguments:\n\nArgument: "${arg.title}"\nBeschreibung: "${arg.description || ""}"\nManuelle Stärke: ${arg.strength || 5}/10\nKI-Stärke: ${arg.ki_strength}/10\nDiskrepanz: ${discrepancy.toFixed(1)} Punkte\n\nErkläre warum die Bewertungen abweichen und mache 3 konkrete Verbesserungsvorschläge, um das Argument zu stärken.`,
      response_json_schema: {
        type: "object",
        properties: {
          erklaerung: { type: "string" },
          vorschlaege: { type: "array", items: { type: "string" } }
        }
      }
    });
    setAnalysis(res);
    setAnalyzing(false);
  };

  return (
    <div className="bg-white border border-gray-100 rounded-xl p-4 hover:border-gray-200 transition-all">
      {editing ? (
        <div className="space-y-2">
          <input className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} placeholder="Titel *" />
          <textarea className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" rows={2} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} placeholder="Beschreibung" />
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="text-[10px] text-gray-400 block mb-1">Zeitpunkt der Argumentation</label>
              <input type="date" className="w-full border border-gray-200 rounded-lg px-3 py-1.5 text-xs bg-white" value={form.zeitpunkt} onChange={e => setForm({ ...form, zeitpunkt: e.target.value })} />
            </div>
            <div>
              <label className="text-[10px] text-gray-400 block mb-1">Anmerkungen (Risiken / Vorteile)</label>
              <input className="w-full border border-gray-200 rounded-lg px-3 py-1.5 text-xs bg-white" placeholder="z.B. Beweis fehlt noch, starkes Argument..." value={form.anmerkungen} onChange={e => setForm({ ...form, anmerkungen: e.target.value })} />
            </div>
          </div>
          {/* Paragraphen im Edit-Modus */}
          <div>
            <label className="text-[10px] text-gray-400 block mb-1">Paragraphen / Normen</label>
            <div className="flex gap-1 mb-1 flex-wrap">
              {(form.paragraphs || []).map((p, i) => (
                <span key={i} className="flex items-center gap-1 text-[9px] font-mono bg-blue-50 text-blue-700 border border-blue-200 rounded px-1.5 py-0.5">
                  {p}
                  <button onClick={() => removeParagraph(i)} className="text-blue-400 hover:text-red-500">×</button>
                </span>
              ))}
            </div>
            <div className="flex gap-1">
              <input className="flex-1 border border-gray-200 rounded-lg px-2 py-1 text-xs bg-white" placeholder="z.B. § 280 BGB" value={newPara} onChange={e => setNewPara(e.target.value)} onKeyDown={e => e.key === "Enter" && addParagraph()} />
              <button onClick={addParagraph} className="text-[10px] px-2 py-1 bg-blue-600 text-white rounded-lg hover:bg-blue-700">+</button>
            </div>
          </div>
          <div className="flex gap-2 flex-wrap">
            <select className="border border-gray-200 rounded-lg px-2 py-1.5 text-xs bg-white" value={form.side} onChange={e => setForm({ ...form, side: e.target.value })}>
              <option value="eigen">Eigen</option><option value="gegner">Gegner</option>
            </select>
            <select className="border border-gray-200 rounded-lg px-2 py-1.5 text-xs bg-white" value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>
              <option>Rechtsargument</option><option>Tatsachenargument</option><option>Widerspruch</option><option>Druckmittel</option>
            </select>
            <div className="flex items-center gap-1">
              <span className="text-xs text-gray-500">Stärke:</span>
              <input type="number" min={0} max={10} step={0.5} className="border border-gray-200 rounded-lg px-2 py-1.5 text-xs w-16 bg-white" value={form.strength} onChange={e => setForm({ ...form, strength: +e.target.value })} />
            </div>
            <Button size="sm" onClick={save} className="bg-gray-900 text-white rounded-lg text-xs gap-1"><Check className="w-3 h-3" /> Speichern</Button>
            <Button size="sm" variant="outline" onClick={() => setEditing(false)} className="rounded-lg text-xs">Abbrechen</Button>
          </div>
        </div>
      ) : (
        <div>
          <div className="flex items-start gap-2">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1 flex-wrap">
                <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${arg.side === "eigen" ? "bg-blue-50 text-blue-700" : "bg-red-50 text-red-700"}`}>
                  {arg.side === "eigen" ? "Eigen" : "Gegner"}
                </span>
                {arg.type && <span className="text-[10px] text-gray-400">{arg.type}</span>}
                {hasDiscrepancy && (
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-50 text-amber-600 font-medium flex items-center gap-1">
                    <AlertTriangle className="w-2.5 h-2.5" /> Δ {discrepancy.toFixed(1)}
                  </span>
                )}
                <ComplianceStatusBadge item={arg} type="argument" />
              </div>
              <h4 className="font-medium text-gray-900 text-sm">{arg.title}</h4>
              {arg.description && <p className="text-xs text-gray-500 mt-0.5 line-clamp-2">{arg.description}</p>}
              <div className="flex flex-wrap gap-3 mt-1">
                {arg.zeitpunkt && (
                  <span className="text-[10px] text-gray-400 flex items-center gap-1">🗓 {new Date(arg.zeitpunkt).toLocaleDateString("de-DE")}</span>
                )}
                {arg.anmerkungen && (
                  <span className="text-[10px] text-amber-600 flex items-center gap-1">📝 {arg.anmerkungen}</span>
                )}
              </div>

              {/* Score comparison */}
              <div className="mt-3 space-y-1.5">
                <div className="flex items-center gap-3">
                  <span className="text-[10px] text-gray-400 w-20 flex-shrink-0">Manuell</span>
                  <div className="flex-1"><ScoreBar value={arg.strength || 5} color="bg-blue-500" /></div>
                  <span className="text-xs font-semibold text-blue-600 w-8 text-right">{arg.strength || 5}</span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-[10px] text-gray-400 w-20 flex-shrink-0">KI-Stärke</span>
                  <div className="flex-1">
                    {arg.ki_strength !== undefined && arg.ki_strength !== null
                      ? <ScoreBar value={arg.ki_strength} color="bg-violet-500" />
                      : <div className="w-full h-1.5 bg-gray-100 rounded-full" />}
                  </div>
                  <span className="text-xs font-semibold text-violet-600 w-8 text-right">
                    {arg.ki_strength !== undefined && arg.ki_strength !== null ? arg.ki_strength : "–"}
                  </span>
                </div>
              </div>

              {(arg.paragraphs && arg.paragraphs.length > 0) && (
                <div className="flex flex-wrap gap-1 mt-2">
                  {arg.paragraphs.map((p, i) => (
                    <span key={i} className="text-[9px] font-mono bg-blue-50 text-blue-700 border border-blue-200 rounded px-1.5 py-0.5">{p}</span>
                  ))}
                </div>
              )}
              <div className="flex items-center gap-2 mt-2 flex-wrap">
                <button onClick={kiWeight} disabled={kiWeighting}
                  className="flex items-center gap-1 text-[10px] text-violet-600 hover:text-violet-800 border border-violet-200 rounded px-1.5 py-0.5 disabled:opacity-40">
                  {kiWeighting ? <RefreshCw className="w-2.5 h-2.5 animate-spin" /> : <Sparkles className="w-2.5 h-2.5" />}
                  KI bewerten
                </button>
                {hasDiscrepancy && (
                  <button onClick={analyzeDiscrepancy} disabled={analyzing}
                    className="flex items-center gap-1 text-[10px] text-amber-600 hover:text-amber-800 border border-amber-200 rounded px-1.5 py-0.5 disabled:opacity-40">
                    {analyzing ? <RefreshCw className="w-2.5 h-2.5 animate-spin" /> : <AlertTriangle className="w-2.5 h-2.5" />}
                    Diskrepanz analysieren
                  </button>
                )}
              </div>

              {analysis && (
                <div className="mt-3 bg-amber-50 border border-amber-100 rounded-xl p-3 space-y-2">
                  <p className="text-xs text-amber-800">{analysis.erklaerung}</p>
                  {(analysis.vorschlaege || []).map((v, i) => (
                    <div key={i} className="flex gap-2 text-xs text-gray-700">
                      <span className="text-amber-500 font-bold flex-shrink-0">{i + 1}.</span>
                      <span>{v}</span>
                    </div>
                  ))}
                </div>
              )}

            </div>

            <div className="flex items-center gap-1 flex-shrink-0">
              <button onClick={() => setEditing(true)} className="text-gray-300 hover:text-blue-500 p-1"><Pencil className="w-3.5 h-3.5" /></button>
              <button onClick={() => onDelete(arg.id)} className="text-gray-300 hover:text-red-400 p-1"><Trash2 className="w-3.5 h-3.5" /></button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function TabArgumente({ caseId, caseData, onCountChange }) {
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [filter, setFilter] = useState("all");
  const [sortBy, setSortBy] = useState("created"); // "created" | "date" | "strength"
  const [showAdd, setShowAdd] = useState(false);
  const [newArg, setNewArg] = useState({ title: "", description: "", side: "eigen", strength: 5, type: "Rechtsargument", zeitpunkt: "", anmerkungen: "" });
  const [extractError, setExtractError] = useState(null);
  const [batchRating, setBatchRating] = useState(false);
  const [kiGenerating, setKiGenerating] = useState(false);
  const [kiGenResult, setKiGenResult] = useState(null);
  const { logKI } = useKIProtokoll(caseId);
  const [showExtraction, setShowExtraction] = useState(false);
  const [extractMode, setExtractMode] = useState("ki");
  const [dsgvo, setDsgvo] = useState(false);
  const [files, setFiles] = useState([]);
  const [text, setText] = useState("");
  const [extracting, setExtracting] = useState(false);
  const [extracted, setExtracted] = useState(null);
  const [detectingDuplicates, setDetectingDuplicates] = useState(false);
  const [duplicates, setDuplicates] = useState(null);
  const fileRef = useRef(null);

  useEffect(() => { loadAll(); }, [caseId]);

  const loadAll = async (notify = false) => {
    const [args, evs] = await Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId })
    ]);
    setArgs(args);
    setEvidence(evs);
    if (notify) onCountChange && onCountChange();
  };

  const load = loadAll;

  const handleExtract = async () => {
    if (extractMode === "ki" && !dsgvo) { setExtractError("Bitte DSGVO-Hinweis akzeptieren"); return; }
    if (!files.length && !text.trim()) { setExtractError("Dokument oder Text erforderlich"); return; }
    if (!caseId) { setExtractError("Fall-ID erforderlich"); return; }
    setExtracting(true);
    setExtractError(null);
    try {
      let fileUrls = [];
      if (files.length > 0) {
        const uploads = await Promise.all(files.map(f => uploadFile({ file: f })));
        fileUrls = uploads.map(r => r.file_url);
      }
      const result = await invokeLLM({
        prompt: `Du bist ein erfahrener Rechtsanwalt. Analysiere diese Dokumente gründlich und extrahiere:
1. EIGENE ARGUMENTE (welche Vertragsklauseln unterstützen unsere Position?)
2. GEGENSEITE-ARGUMENTE (was könnte der Gegner argumentieren?)
3. BEWEISE (konkrete Klauseln, Unterschriften, Daten aus dem Vertrag - dies sind die Belege!)
4. Für JEDES Argument: Welche Beweise aus Punkt 3 unterstützen es?
5. DATUM: Extrahiere für Argumente und Beweise das jeweilige Datum (YYYY-MM-DD) — z.B. Vertragsdatum, Schreibdatum, Ereignisdatum. Nur wenn im Dokument erkennbar.

Fallkontext: ${caseData?.fallname || ""} | ${caseData?.rechtsgebiet || ""}
Rechtsfrage: ${caseData?.zentrale_rechtsfrage || ""}
${!fileUrls.length ? "TEXT: " + text : ""}`,
        file_urls: fileUrls.length ? fileUrls : undefined,
        response_json_schema: {
          type: "object",
          properties: {
            zusammenfassung: { type: "string" },
            beweise: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  titel: { type: "string" },
                  beschreibung: { type: "string" },
                  typ: { type: "string", enum: ["Klausel", "Unterschrift", "Daten", "Dokument", "Sonstiges"] },
                  gewicht: { type: "number", minimum: 1, maximum: 10 }
                },
                required: ["titel"]
              }
            },
            eigene_argumente: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  titel: { type: "string" },
                  beschreibung: { type: "string" },
                  typ: { type: "string" },
                  staerke: { type: "number" },
                  datum: { type: "string", description: "Datum des Arguments (YYYY-MM-DD) falls im Dokument erkennbar" },
                  verlinkte_beweise: { type: "array", items: { type: "string" }, description: "Titel der Beweise die dieses Argument stützen" },
                  paragraphen: { type: "array", items: { type: "string" } }
                },
                required: ["titel"]
              }
              },
              gegenseite_argumente: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  titel: { type: "string" },
                  beschreibung: { type: "string" },
                  typ: { type: "string" },
                  staerke: { type: "number" },
                  datum: { type: "string", description: "Datum des Arguments (YYYY-MM-DD) falls erkennbar" },
                  verlinkte_beweise: { type: "array", items: { type: "string" } }
                },
                required: ["titel"]
              }
              },
            widersprueche: { type: "array", items: { type: "object", properties: { titel: { type: "string" }, staerke: { type: "number" } }, required: ["titel"] } },
            relevante_paragraphen: { type: "array", items: { type: "string" } }
          },
          required: ["beweise", "eigene_argumente"]
        }
      });
      if (!result) { setExtractError("KI-Analyse fehlgeschlagen. Bitte erneut versuchen."); setExtracting(false); return; }
      setExtracted(result);

      // Protokollieren
      await logKI({
        kiName: "Argument-Extraktion",
        eingabe: text || `Dokumente: ${files.map(f => f.name).join(", ")}`,
        ausgabe: result,
        dokumente: files.map(f => f.name),
        modell: "standard"
      });

      setFiles([]);
      setText("");
    } catch (error) {
      setExtractError("Fehler bei der Analyse: " + (error?.message || "Unbekannter Fehler"));
    } finally {
      setExtracting(false);
    }
  }

  const takeAll = async () => {
    if (!extracted) return;
    try {
      const all = [
        ...(extracted.eigene_argumente || []).map(a => ({ ...a, side: "eigen" })),
        ...(extracted.gegenseite_argumente || []).map(a => ({ ...a, side: "gegner" }))
      ];

      // Erstelle zuerst alle Beweise und baue eine Map Titel → ID
      const evidenceMap = {};
      if (extracted.beweise && Array.isArray(extracted.beweise)) {
        for (const ev of extracted.beweise) {
          if (!ev.titel) continue;
          const evEntity = await base44.entities.Evidence.create({
            case_id: caseId,
            title: ev.titel,
            description: ev.beschreibung || "",
            type: ev.typ || "Dokument",
            source: "Extraktion",
            weight: ev.gewicht || 5
          });
          evidenceMap[ev.titel] = evEntity?.id;
        }
      }

      // Erstelle alle Argumente (unabhängig von Beweisen)
      for (const a of all) {
        await base44.entities.Argument.create({
          case_id: caseId,
          title: a.titel,
          description: a.beschreibung || "",
          side: a.side,
          strength: a.staerke || 5,
          type: a.typ || "Rechtsargument",
          paragraphs: a.paragraphen || [],
          zeitpunkt: a.datum || null,
        });
      }

      setExtracted(null);
      await loadAll(true);
      toast.success(`${all.length} Argument(e) übernommen`, {
        description: Object.keys(evidenceMap).length > 0 ? `+ ${Object.keys(evidenceMap).length} Beweis(e) erstellt` : undefined,
        duration: 4000,
      });
    } catch (e) {
      console.error("Fehler beim Übernehmen all:", e);
      alert("Fehler beim Übernehmen der Argumente: " + e.message);
    }
  };

  const deleteExistingArgIfConverted = async (titel) => {
    const existing = args.find(arg => arg.title
