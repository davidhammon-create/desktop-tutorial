
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import ComplianceStatusBadge from "./ComplianceStatusBadge";
import { Plus, Trash2, ChevronDown, ChevronUp, Sparkles, RefreshCw, Pencil, Check, AlertTriangle, Link } from "lucide-react";
import { Button } from "@/components/ui/button";

const PARAGRAPHEN_REFERENZ = {
  "Zivilrecht (ZPO / BGB)": [
    { para: "§ 286 ZPO", titel: "Freie Beweiswürdigung", beschreibung: "Das Gericht entscheidet nach freier Überzeugung, ob eine Tatsache als bewiesen gilt." },
    { para: "§ 415 ZPO", titel: "Öffentliche Urkunden", beschreibung: "Volle Beweiskraft für den beurkundeten Vorgang (z.B. notarielle Akte, Behördenakte)." },
    { para: "§ 416 ZPO", titel: "Private Urkunden", beschreibung: "Beweis dafür, dass die enthaltenen Erklärungen vom Aussteller abgegeben wurden." },
    { para: "§ 371 ZPO", titel: "Augenscheinsbeweis", beschreibung: "Unmittelbare Wahrnehmung durch das Gericht (Fotos, Videos, Objekte)." },
    { para: "§ 373 ZPO", titel: "Zeugenbeweis", beschreibung: "Antrag auf Vernehmung benannter Zeugen; Glaubwürdigkeit ist gerichtlich zu würdigen." },
    { para: "§ 402 ZPO", titel: "Sachverständigenbeweis", beschreibung: "Gutachter mit besonderem Fachwissen; gerichtlich bestellt oder privat." },
    { para: "§ 445 ZPO", titel: "Parteivernehmung", beschreibung: "Vernehmung der Partei selbst; subsidiär, wenn andere Beweise fehlen." },
    { para: "§ 253 BGB", titel: "Immaterieller Schaden / Schmerzensgeld", beschreibung: "Geldentschädigung für nichtvermögensrechtliche Schäden (z.B. Körperverletzung)." },
    { para: "§ 249 BGB", titel: "Art und Umfang des Schadenersatzes", beschreibung: "Naturalrestitution als Grundprinzip; Geldersatz wenn Naturalrestitution unmöglich." },
    { para: "§ 280 BGB", titel: "Schadensersatz wegen Pflichtverletzung", beschreibung: "Schuldner haftet bei Verletzung einer Pflicht aus dem Schuldverhältnis." },
  ],
  "Öffentliches Recht (VwGO / GG)": [
    { para: "§ 86 VwGO", titel: "Untersuchungsgrundsatz", beschreibung: "Gericht erforscht den Sachverhalt von Amts wegen; Beweiserhebung auf Antrag oder von Amts wegen." },
    { para: "§ 98 VwGO", titel: "Anwendung der ZPO-Beweisregeln", beschreibung: "Im Verwaltungsprozess gelten die §§ 358–444 ZPO entsprechend." },
    { para: "Art. 19 Abs. 4 GG", titel: "Rechtsschutzgarantie", beschreibung: "Effektiver Rechtsschutz gegen Akte der öffentlichen Gewalt." },
    { para: "Art. 20 Abs. 3 GG", titel: "Rechtsstaatsprinzip", beschreibung: "Bindung der Verwaltung an Gesetz und Recht; Grundlage der Beweisführung im ÖR." },
    { para: "§ 108 VwGO", titel: "Freie Beweiswürdigung (VwGO)", beschreibung: "Richter entscheidet nach seiner freien, aus dem Gesamtergebnis gewonnenen Überzeugung." },
    { para: "§ 74 VwGO", titel: "Klagefrist", beschreibung: "Anfechtungsklage innerhalb eines Monats nach Bekanntgabe; Fristdokumente als Beweise kritisch." },
    { para: "§ 80 VwGO", titel: "Aufschiebende Wirkung", beschreibung: "Widerspruch und Anfechtungsklage haben grds. aufschiebende Wirkung; einstweiliger Rechtsschutz." },
  ],
  "Strafrecht (StPO / StGB)": [
    { para: "§ 261 StPO", titel: "Freie Beweiswürdigung (StPO)", beschreibung: "Gericht entscheidet nach seiner freien, aus dem Inbegriff der Hauptverhandlung geschöpften Überzeugung." },
    { para: "§ 244 StPO", titel: "Beweisantragsrecht", beschreibung: "Recht des Angeklagten, Beweisanträge zu stellen; Ablehnung nur aus gesetzlichen Gründen." },
    { para: "§ 136a StPO", titel: "Verbotene Vernehmungsmethoden", beschreibung: "Aussagen unter Zwang, Täuschung oder Drohung sind unverwertbar – Beweisverwertungsverbot." },
    { para: "§ 252 StPO", titel: "Verwertungsverbot bei Zeugnisverweigerung", beschreibung: "Vernehmungsprotokoll über frühere Aussage nicht verwertbar, wenn Zeuge sein Recht ausübt." },
    { para: "§ 100a StPO", titel: "Telekommunikationsüberwachung", beschreibung: "TKÜ-Protokolle als Beweismittel; nur bei richterlicher Anordnung verwertbar." },
    { para: "§ 94 StPO", titel: "Sicherstellung / Beschlagnahme", beschreibung: "Gegenstände als Beweismittel sicherstellen; Verwertbarkeit abhängig von Rechtmäßigkeit." },
    { para: "§ 170 StPO", titel: "Einstellung des Verfahrens", beschreibung: "Anklageschrift oder Einstellung – Beweislage entscheidet über Anklageerhebung." },
    { para: "§ 46 StGB", titel: "Strafzumessung", beschreibung: "Beweise zur Tatschwere, Schuld, Vorleben des Täters sind strafzumessungsrelevant." },
  ],
};

const BEWEIS_TYPES = ["Gesetzliche Grundlage / Normtext","BGH/BVerfG Entscheidung (einschlägig)","Notarielle Beurkundung","Öffentliche Urkunde §415 ZPO","BGH-Entscheidung (übertragbar)","Gerichtliches SV-Gutachten","OLG-Entscheidung (gleiches BL)","Private Urkunde §416 ZPO","Augenscheinsbeweis","Privates SV-Gutachten","E-Mail / elektronisch","Zeuge (unabhängig)","LG-Entscheidung","Parteivernehmung §445 ZPO","Zeuge (parteinah)","Indizien (kumulativ)","Negative Tatsache"];
const WEIGHTS = {"Gesetzliche Grundlage / Normtext":10,"BGH/BVerfG Entscheidung (einschlägig)":9.5,"Notarielle Beurkundung":9.5,"Öffentliche Urkunde §415 ZPO":9,"BGH-Entscheidung (übertragbar)":8.5,"Gerichtliches SV-Gutachten":8.5,"OLG-Entscheidung (gleiches BL)":7.5,"Private Urkunde §416 ZPO":7.5,"Augenscheinsbeweis":7,"Privates SV-Gutachten":6.5,"E-Mail / elektronisch":6,"Zeuge (unabhängig)":6,"LG-Entscheidung":5,"Parteivernehmung §445 ZPO":4,"Zeuge (parteinah)":3.5,"Indizien (kumulativ)":3.5,"Negative Tatsache":3};

function ScoreBar({ value, max = 10, color = "bg-green-500" }) {
  return (
    <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
      <div className={`h-full ${color} rounded-full transition-all`} style={{ width: `${((value || 0) / max) * 100}%` }} />
    </div>
  );
}

function EvidenceCard({ ev, onDelete, onSave }) {
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({ title: ev.title, description: ev.description || "", type: ev.type || BEWEIS_TYPES[0], source: ev.source || "", weight: ev.weight || 5, datum: ev.datum || "" });
  const [newPara, setNewPara] = useState("");
  const [paragraphen, setParagraphen] = useState(() => {
    // Paragraphen werden im description-Feld als "[§§: ...]" gespeichert
    const match = (ev.description || "").match(/\[§§: ([^\]]+)\]/);
    return match ? match[1].split(", ").filter(Boolean) : [];
  });
  const [kiWeighting, setKiWeighting] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [analysis, setAnalysis] = useState(null);

  const discrepancy = ev.ki_weight !== undefined && ev.ki_weight !== null
    ? Math.abs((ev.weight || 5) - ev.ki_weight)
    : 0;
  const hasDiscrepancy = discrepancy >= 2;

  const addParagraph = () => {
    if (!newPara.trim()) return;
    setParagraphen(p => [...p, newPara.trim()]);
    setNewPara("");
  };

  const removeParagraph = (i) => setParagraphen(p => p.filter((_, j) => j !== i));

  const save = async () => {
    // Paragraphen in die description einbetten (als Anhang)
    let desc = form.description.replace(/\s*\[§§: [^\]]*\]/, "").trim();
    if (paragraphen.length > 0) desc = desc + (desc ? " " : "") + `[§§: ${paragraphen.join(", ")}]`;
    await base44.entities.Evidence.update(ev.id, { ...form, description: desc });
    setEditing(false);
    onSave();
  };

  const kiWeight = async () => {
    setKiWeighting(true);
    const result = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist ein Rechtsanwalt. Bewerte die Beweiskraft dieses Beweismittels im deutschen Zivilprozess.\nTitel: "${ev.title}"\nTyp: "${ev.type || ""}"\nBeschreibung: "${ev.description || ""}"\n\nGib ein Gewicht (0-10) UND eine juristische Begründung (2-3 Sätze) zurück, warum dieser Beweis diese Beweiskraft hat.`,
      response_json_schema: {
        type: "object",
        properties: {
          gewicht: { type: "number", minimum: 0, maximum: 10 },
          begruendung: { type: "string" }
        }
      }
    });
    if (result && result.gewicht !== undefined) {
      await base44.entities.Evidence.update(ev.id, {
        ki_weight: Math.min(10, Math.max(0, result.gewicht)),
        ki_reasoning: result.begruendung || ""
      });
      onSave();
    }
    setKiWeighting(false);
  };

  const analyzeDiscrepancy = async () => {
    setAnalyzing(true);
    const res = await base44.integrations.Core.InvokeLLM({
      prompt: `Analysiere die Diskrepanz zwischen manueller und KI-Bewertung dieses Beweismittels:\n\nBeweis: "${ev.title}"\nTyp: "${ev.type || ""}"\nBeschreibung: "${ev.description || ""}"\nManuelles Gewicht: ${ev.weight || 5}/10\nKI-Gewicht: ${ev.ki_weight}/10\nDiskrepanz: ${discrepancy.toFixed(1)} Punkte\n\nErkläre warum die Bewertungen abweichen und mache 3 konkrete Verbesserungsvorschläge, um den Beweiswert zu stärken.`,
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
    <div className="relative group">
      <div className="absolute -left-6 top-2 w-4 h-4 border-2 border-gray-800 rounded-full bg-white flex items-center justify-center">
        <div className="w-1.5 h-1.5 bg-gray-800 rounded-full" />
      </div>
      <div className="bg-gray-50 rounded-xl p-3">
        {editing ? (
          <div className="space-y-2">
            <input className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} placeholder="Titel *" />
            <textarea className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" rows={2} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} placeholder="Beschreibung" />
            <select className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>
              {BEWEIS_TYPES.map(t => <option key={t}>{t}</option>)}
            </select>
            <input className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" placeholder="Quelle" value={form.source} onChange={e => setForm({ ...form, source: e.target.value })} />
            <div>
              <label className="text-[10px] text-gray-400 block mb-1">Datum des Beweises</label>
              <input type="date" className="w-full border border-gray-200 rounded-lg px-3 py-1.5 text-xs bg-white" value={form.datum} onChange={e => setForm({ ...form, datum: e.target.value })} />
            </div>
            <div className="flex items-center gap-2">
              <span className="text-xs text-gray-500">Manuelles Gewicht:</span>
              <input type="number" min={0} max={10} step={0.5} className="border border-gray-200 rounded-lg px-2 py-1 text-xs w-16 bg-white" value={form.weight} onChange={e => setForm({ ...form, weight: +e.target.value })} />
            </div>
            {/* Paragraphen */}
            <div>
              <label className="text-[10px] text-gray-400 block mb-1">Paragraphen / Normen</label>
              <div className="flex gap-1 mb-1 flex-wrap">
                {paragraphen.map((p, i) => (
                  <span key={i} className="flex items-center gap-1 text-[9px] font-mono bg-blue-50 text-blue-700 border border-blue-200 rounded px-1.5 py-0.5">
                    {p}<button onClick={() => removeParagraph(i)} className="text-blue-400 hover:text-red-500">×</button>
                  </span>
                ))}
              </div>
              <div className="flex gap-1">
                <input className="flex-1 border border-gray-200 rounded-lg px-2 py-1 text-xs bg-white" placeholder="z.B. § 286 ZPO" value={newPara} onChange={e => setNewPara(e.target.value)} onKeyDown={e => e.key === "Enter" && addParagraph()} />
                <button onClick={addParagraph} className="text-[10px] px-2 py-1 bg-blue-600 text-white rounded-lg hover:bg-blue-700">+</button>
              </div>
            </div>
            <div className="flex gap-2">
              <Button size="sm" onClick={save} className="bg-gray-900 text-white rounded-lg text-xs gap-1"><Check className="w-3 h-3" /> Speichern</Button>
              <Button size="sm" variant="outline" onClick={() => setEditing(false)} className="rounded-lg text-xs">Abbrechen</Button>
            </div>
          </div>
        ) : (
          <div>
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1 flex-wrap">
                  <span className="text-xs">📄</span>
                  <span className="font-medium text-sm text-gray-900">{ev.title}</span>
                  {hasDiscrepancy && (
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-50 text-amber-600 font-medium flex items-center gap-1">
                      <AlertTriangle className="w-2.5 h-2.5" /> Δ {discrepancy.toFixed(1)}
                    </span>
                  )}
                  <ComplianceStatusBadge item={ev} type="evidence" />
                </div>
                <div className="space-y-1.5 mb-2">
                  <div className="flex items-center gap-3">
                    <span className="text-[10px] text-gray-400 w-20 flex-shrink-0">Manuell</span>
                    <div className="flex-1"><ScoreBar value={ev.weight || 5} color="bg-blue-500" /></div>
                    <span className="text-xs font-semibold text-blue-600 w-8 text-right">{ev.weight || 5}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-[10px] text-gray-400 w-20 flex-shrink-0">KI-Gewicht</span>
                    <div className="flex-1">
                      {ev.ki_weight !== undefined && ev.ki_weight !== null
                        ? <ScoreBar value={ev.ki_weight} color="bg-violet-500" />
                        : <div className="w-full h-1.5 bg-gray-100 rounded-full" />}
                    </div>
                    <span className="text-xs font-semibold text-violet-600 w-8 text-right">
                      {ev.ki_weight !== undefined && ev.ki_weight !== null ? ev.ki_weight : "–"}
                    </span>
                  </div>
                </div>
                {ev.description && <p className="text-xs text-gray-500">{ev.description}</p>}
                {ev.type && <p className="text-[10px] text-gray-400 mt-0.5">{ev.type}</p>}
                {ev.datum && <p className="text-[10px] text-orange-500 font-medium">🗓 {new Date(ev.datum).toLocaleDateString("de-DE")}</p>}
                {ev.source && <p className="text-[10px] text-gray-400">Quelle: {ev.source}</p>}
                {paragraphen.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-1">
                    {paragraphen.map((p, i) => (
                      <span key={i} className="text-[9px] font-mono bg-blue-50 text-blue-700 border border-blue-200 rounded px-1.5 py-0.5">{p}</span>
                    ))}
                  </div>
                )}
                {ev.ki_reasoning && (
                  <div className="mt-2 bg-violet-50 border border-violet-100 rounded-lg p-2">
                    <p className="text-[10px] font-semibold text-violet-700 mb-0.5">KI-Begründung (Gewicht {ev.ki_weight}/10):</p>
                    <p className="text-[10px] text-violet-600 leading-relaxed">{ev.ki_reasoning}</p>
                  </div>
                )}
                <div className="flex items-center gap-2 mt-2 flex-wrap">
                  <button onClick={kiWeight} disabled={kiWeighting}
                    className="flex items-center gap-1 text-[10px] text-violet-600 hover:text-violet-800 border border-violet-200 rounded px-1.5 py-0.5 disabled:opacity-40">
                    {kiWeighting ? <RefreshCw className="w-2.5 h-2.5 animate-spin" /> : <Sparkles className="w-2.5 h-2.5" />}
                    KI gewichten
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
              <div className="flex items-center gap-1 flex-shrink-0 ml-2">
                <button onClick={() => setEditing(true)} className="text-gray-300 hover:text-blue-500 p-1 opacity-0 group-hover:opacity-100 transition-all"><Pencil className="w-3.5 h-3.5" /></button>
                <button onClick={() => onDelete(ev.id)} className="text-gray-300 hover:text-red-400 p-1 opacity-0 group-hover:opacity-100 transition-all"><Trash2 className="w-3.5 h-3.5" /></button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default function TabBeweise({ caseId }) {
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [selectedArg, setSelectedArg] = useState(null);
  const [showAdd, setShowAdd] = useState(false);
  const [showRef, setShowRef] = useState(false);
  const [showPara, setShowPara] = useState(false);
  const [activePara, setActivePara] = useState(null);
  const [showLink, setShowLink] = useState(false);
  const [newEv, setNewEv] = useState({ title: "", description: "", type: BEWEIS_TYPES[0], source: "", datum: "" });
  const [sortBy, setSortBy] = useState("created"); // "created" | "date" | "weight"
  const [argSortBy, setArgSortBy] = useState("created"); // "created" | "strength" | "evidence" | "date"

  useEffect(() => { load(); }, [caseId]);

  const load = async () => {
    const [a, e] = await Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId })
    ]);
    setArgs(a);
    setEvidence(e);
    if (a.length > 0 && !selectedArg) setSelectedArg(a[0].id);
  };

  const addEvidence = async () => {
    if (!newEv.title.trim() || !selectedArg) return;
    await base44.entities.Evidence.create({ case_id: caseId, argument_id: selectedArg, ...newEv, weight: WEIGHTS[newEv.type] || 5 });
    setNewEv({ title: "", description: "", type: BEWEIS_TYPES[0], source: "" });
    setShowAdd(false);
    load();
  };

  const del = async (id) => {
    try {
      await base44.entities.Evidence.delete(id);
    } catch (e) {
      console.warn("Evidence bereits gelöscht oder nicht gefunden:", id);
    }
    load();
  };

  const linkExisting = async (evId) => {
    await base44.entities.Evidence.update(evId, { argument_id: selectedArg });
    load();
  };

  const [kiSuggestions, setKiSuggestions] = useState(null); // { evId: { suggestedArgId, reason } }
  const [kiSugLoading, setKiSugLoading] = useState(false);
  const [pendingAssignments, setPendingAssignments] = useState({}); // evId -> argId

  const runKiSuggestions = async () => {
    if (!unlinkedEvidence.length || !args.length) return;
    setKiSugLoading(true);
    setKiSuggestions(null);
    const result = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist ein erfahrener Rechtsanwalt. Weise die folgenden Beweismittel den passendsten Argumenten zu.

ARGUMENTE:
${args.map(a => `ID: ${a.id} | Seite: ${a.side} | Titel: ${a.title}`).join('\n')}

BEWEISE (unverknüpft):
${unlinkedEvidence.map(e => `ID: ${e.id} | Titel: ${e.title} | Typ: ${e.type || ''} | Beschreibung: ${e.description || ''}`).join('\n')}

Gib für jeden Beweis die ID des am besten passenden Arguments an und eine kurze Begründung (max. 1 Satz).`,
      response_json_schema: {
        type: "object",
        properties: {
          zuordnungen: {
            type: "array",
            items: {
              type: "object",
              properties: {
                evidence_id: { type: "string" },
                argument_id: { type: "string" },
                reason: { type: "string" }
              }
            }
          }
        }
      }
    });
    const suggestions = {};
    const pending = {};
    (result?.zuordnungen || []).forEach(z => {
      suggestions[z.evidence_id] = { argId: z.argument_id, reason: z.reason };
      pending[z.evidence_id] = z.argument_id;
    });
    setKiSuggestions(suggestions);
    setPendingAssignments(pending);
    setKiSugLoading(false);
  };

  const applyAllSuggestions = async () => {
    await Promise.all(
      Object.entries(pendingAssignments).map(([evId, argId]) =>
        base44.entities.Evidence.update(evId, { argument_id: argId })
      )
    );
    setKiSuggestions(null);
    setPendingAssignments({});
    await load();
  };

  const selectedArgData = args.find(a => a.id
