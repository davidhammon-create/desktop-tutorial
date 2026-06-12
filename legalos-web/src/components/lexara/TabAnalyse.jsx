
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Button } from "@/components/ui/button";
import { Sparkles, RefreshCw } from "lucide-react";

export default function TabAnalyse({ caseId, caseData, onUpdate, kiMode = true }) {
  const [args, setArgs] = useState([]);
  const [rechtsprechung, setRechtsprechung] = useState(null);
  const [rpLoading, setRpLoading] = useState(false);
  const [savedInsights, setSavedInsights] = useState([]);
  const [form, setForm] = useState({
    streitwert: caseData?.streitwert || 100000,
    gebuehrenstufe: caseData?.gebuehrenstufe || 1.3,
    sv_kosten: caseData?.sv_kosten || 0,
    reisekosten: caseData?.reisekosten || 0,
    vergleichsangebot: caseData?.vergleichsangebot || 0,
    instanz: caseData?.instanz || "Erstinstanz",
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    base44.entities.Argument.filter({ case_id: caseId }).then(setArgs);
    base44.entities.JurisdictionInsight.filter({}).then(insights => {
      const relevant = insights.filter(i =>
        !caseData?.rechtsgebiet ||
        i.jurisdiction === (caseData?.rechtsgebiet || "DE") ||
        (i.topic && caseData?.rechtsgebiet && i.topic.toLowerCase().includes(caseData.rechtsgebiet.toLowerCase()))
      );
      setSavedInsights(relevant.slice(0, 5));
    });
  }, [caseId]);

  const gvg = (streitwert) => {
    if (streitwert <= 500) return 35;
    if (streitwert <= 1000) return 53;
    if (streitwert <= 1500) return 71;
    if (streitwert <= 2000) return 89;
    if (streitwert <= 3000) return 107;
    if (streitwert <= 4000) return 125;
    if (streitwert <= 5000) return 143;
    if (streitwert <= 6000) return 161;
    if (streitwert <= 7000) return 179;
    if (streitwert <= 8000) return 197;
    if (streitwert <= 9000) return 215;
    if (streitwert <= 10000) return 233;
    return 233 + Math.ceil((streitwert - 10000) / 10000) * 127;
  };

  const anwaltskosten = gvg(form.streitwert) * form.gebuehrenstufe * 2;
  const gerichtskosten = gvg(form.streitwert) * 3;
  const gesamtkosten = anwaltskosten + gerichtskosten + form.sv_kosten + form.reisekosten;
  const vergleichsersparnis = form.vergleichsangebot > 0
    ? Math.round(((gesamtkosten - form.vergleichsangebot) / gesamtkosten) * 100)
    : null;

  const saveForm = async () => {
    setSaving(true);
    await base44.entities.Case.update(caseId, form);
    onUpdate && onUpdate(form);
    setSaving(false);
  };

  const loadRechtsprechung = async () => {
    setRpLoading(true);
    const r = await base44.integrations.Core.InvokeLLM({
      prompt: `Analysiere die Rechtsprechung für folgenden Fall:
Fallname: ${caseData?.fallname || "—"}
Rechtsgebiet: ${caseData?.rechtsgebiet || "—"}
Streitwert: ${form.streitwert}€
Argumente: ${args.map(a => a.titel).join(", ") || "—"}

Gib die wichtigsten Urteile, Normen und strategischen Empfehlungen.`,
      response_json_schema: {
        type: "object",
        properties: {
          schluessel_urteile: { type: "array", items: { type: "string" } },
          relevante_normen: { type: "array", items: { type: "string" } },
          strategische_empfehlungen: { type: "array", items: { type: "string" } },
          prognose_bewertung: { type: "string" },
          risikofaktoren: { type: "array", items: { type: "string" } }
        }
      }
    });
    setRechtsprechung(r);
    setRpLoading(false);
  };

  const INSTANZEN = ["Erstinstanz", "Berufung", "Revision", "Bundesgericht", "EuGH"];

  return (
    <div className="space-y-5">
      {/* Kostenrechner */}
      <div className="bg-white border border-gray-100 rounded-xl p-4">
        <h3 className="text-sm font-semibold text-gray-800 mb-3">📊 Kostenrechner (RVG/GKG)</h3>
        <div className="grid grid-cols-2 gap-3 mb-3">
          <div>
            <label className="text-[10px] text-gray-400 block mb-1">Streitwert (€)</label>
            <input type="number" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" value={form.streitwert} onChange={e => setForm({...form, streitwert: +e.target.value})} />
          </div>
          <div>
            <label className="text-[10px] text-gray-400 block mb-1">Gebührenstufe</label>
            <input type="number" step="0.1" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" value={form.gebuehrenstufe} onChange={e => setForm({...form, gebuehrenstufe: +e.target.value})} />
          </div>
          <div>
            <label className="text-[10px] text-gray-400 block mb-1">Sachverständigenkosten (€)</label>
            <input type="number" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" value={form.sv_kosten} onChange={e => setForm({...form, sv_kosten: +e.target.value})} />
          </div>
          <div>
            <label className="text-[10px] text-gray-400 block mb-1">Reisekosten (€)</label>
            <input type="number" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" value={form.reisekosten} onChange={e => setForm({...form, reisekosten: +e.target.value})} />
          </div>
          <div>
            <label className="text-[10px] text-gray-400 block mb-1">Vergleichsangebot (€)</label>
            <input type="number" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" value={form.vergleichsangebot} onChange={e => setForm({...form, vergleichsangebot: +e.target.value})} />
          </div>
          <div>
            <label className="text-[10px] text-gray-400 block mb-1">Instanz</label>
            <select className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" value={form.instanz} onChange={e => setForm({...form, instanz: e.target.value})}>
              {INSTANZEN.map(i => <option key={i}>{i}</option>)}
            </select>
          </div>
        </div>

        <div className="bg-gray-50 rounded-xl p-3 grid grid-cols-2 gap-3 mb-3">
          <div className="text-center">
            <p className="text-[10px] text-gray-400">Anwaltskosten (beide Seiten)</p>
            <p className="text-base font-bold text-gray-900">{anwaltskosten.toLocaleString("de-DE")} €</p>
          </div>
          <div className="text-center">
            <p className="text-[10px] text-gray-400">Gerichtskosten</p>
            <p className="text-base font-bold text-gray-900">{gerichtskosten.toLocaleString("de-DE")} €</p>
          </div>
          <div className="text-center col-span-2 pt-2 border-t border-gray-200">
            <p className="text-[10px] text-gray-400 font-semibold uppercase">Gesamtkosten (Worst Case)</p>
            <p className="text-xl font-bold text-red-600">{gesamtkosten.toLocaleString("de-DE")} €</p>
          </div>
          {vergleichsersparnis !== null && (
            <div className="col-span-2 text-center">
              <p className="text-xs text-green-600 font-medium">
                Vergleich spart {vergleichsersparnis > 0 ? `${vergleichsersparnis}%` : "nichts"} der Gesamtkosten
              </p>
            </div>
          )}
        </div>
        <Button size="sm" onClick={saveForm} disabled={saving} className="text-xs bg-gray-900 text-white rounded-lg">
          {saving ? "Speichern…" : "Speichern"}
        </Button>
      </div>

      {/* KI Rechtsprechungsanalyse */}
      {kiMode && (
        <div className="bg-white border border-gray-100 rounded-xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-gray-800">🤖 KI-Rechtsprechungsanalyse</h3>
            <Button size="sm" onClick={loadRechtsprechung} disabled={rpLoading} className="text-xs bg-violet-600 text-white rounded-lg gap-1">
              {rpLoading ? <RefreshCw className="w-3 h-3 animate-spin" /> : <Sparkles className="w-3 h-3" />}
              {rpLoading ? "Analysiere…" : "Analysieren"}
            </Button>
          </div>
          {rechtsprechung ? (
            <div className="space-y-3">
              {rechtsprechung.schluessel_urteile?.length > 0 && (
                <div>
                  <p className="text-[10px] font-semibold uppercase text-gray-400 mb-1">Schlüssel-Urteile</p>
                  <ul className="space-y-1">
                    {rechtsprechung.schluessel_urteile.map((u, i) => (
                      <li key={i} className="text-xs text-gray-600 flex gap-2"><span className="text-gray-300">•</span>{u}</li>
                    ))}
                  </ul>
                </div>
              )}
              {rechtsprechung.relevante_normen?.length > 0 && (
                <div>
                  <p className="text-[10px] font-semibold uppercase text-gray-400 mb-1">Relevante Normen</p>
                  <div className="flex flex-wrap gap-1">
                    {rechtsprechung.relevante_normen.map((n, i) => (
                      <span key={i} className="text-[10px] font-mono px-1.5 py-0.5 bg-gray-100 rounded">{n}</span>
                    ))}
                  </div>
                </div>
              )}
              {rechtsprechung.strategische_empfehlungen?.length > 0 && (
                <div>
                  <p className="text-[10px] font-semibold uppercase text-gray-400 mb-1">Strategische Empfehlungen</p>
                  <ul className="space-y-1">
                    {rechtsprechung.strategische_empfehlungen.map((e, i) => (
                      <li key={i} className="text-xs text-gray-600 flex gap-2"><span className="text-green-500">→</span>{e}</li>
                    ))}
                  </ul>
                </div>
              )}
              {rechtsprechung.prognose_bewertung && (
                <div className="bg-blue-50 rounded-lg p-3">
                  <p className="text-[10px] font-semibold text-blue-600 uppercase mb-1">Prognosebewertung</p>
                  <p className="text-xs text-blue-800">{rechtsprechung.prognose_bewertung}</p>
                </div>
              )}
            </div>
          ) : (
            <p className="text-xs text-gray-400 text-center py-6">Klicke auf „Analysieren" für eine KI-gestützte Rechtsprechungsanalyse</p>
          )}
        </div>
      )}

      {/* Gespeicherte Insights */}
      {savedInsights.length > 0 && (
        <div className="bg-white border border-gray-100 rounded-xl p-4">
          <h3 className="text-sm font-semibold text-gray-800 mb-3">💡 Gespeicherte Erkenntnisse</h3>
          <div className="space-y-2">
            {savedInsights.map(ins => (
              <div key={ins.id} className="bg-gray-50 rounded-lg p-3">
                <p className="text-xs font-medium text-gray-800">{ins.title || ins.topic}</p>
                <p className="text-[11px] text-gray-500 mt-1">{ins.content || ins.insight}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
