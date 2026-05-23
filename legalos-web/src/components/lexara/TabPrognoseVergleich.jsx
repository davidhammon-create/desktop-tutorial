
/**
 * TabPrognoseVergleich – Zentrale Prognose-Übersicht im Abschluss-Reiter
 * Sammelt alle Prognosen aus allen Reitern, erklärt Unterschiede per KI.
 */
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { computeVollanalyse } from "@/lib/legalAlgorithms";
import { RefreshCw, Sparkles, ChevronDown, ChevronRight, Info } from "lucide-react";
import { Button } from "@/components/ui/button";
import { RadarChart, PolarGrid, PolarAngleAxis, Radar, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell, Legend } from "recharts";

function PrognoseCircle({ value, label, color = "#1a1a1a", size = 80 }) {
  const r = size * 0.38, circ = 2 * Math.PI * r;
  const offset = circ - (value / 100) * circ;
  return (
    <div className="flex flex-col items-center gap-1">
      <div className="relative inline-flex items-center justify-center">
        <svg width={size} height={size} style={{ transform: "rotate(-90deg)" }}>
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#e5e7eb" strokeWidth={size * 0.06} />
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={size * 0.06}
            strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round" />
        </svg>
        <div className="absolute text-center">
          <div className="font-black text-gray-900" style={{ fontSize: size * 0.22 }}>{Math.round(value)}%</div>
        </div>
      </div>
      <p className="text-[10px] text-gray-500 text-center leading-tight max-w-[90px]">{label}</p>
    </div>
  );
}

function ScoreBar({ value, color = "bg-blue-500", label }) {
  return (
    <div className="flex items-center gap-3">
      <span className="text-xs text-gray-500 w-44 flex-shrink-0">{label}</span>
      <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all`} style={{ width: `${Math.min(100, value)}%` }} />
      </div>
      <span className="text-xs font-bold text-gray-700 w-8 text-right">{Math.round(value)}%</span>
    </div>
  );
}

export default function TabPrognoseVergleich({ caseId, caseData, kiMode }) {
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [deadlines, setDeadlines] = useState([]);
  const [persons, setPersons] = useState([]);
  const [gegnerVerhalten, setGegnerVerhalten] = useState([]);
  const [loaded, setLoaded] = useState(false);
  const [algoResult, setAlgoResult] = useState(null);
  const [kiErklarung, setKiErklarung] = useState(null);
  const [kiLoading, setKiLoading] = useState(false);
  const [showDetail, setShowDetail] = useState({});

  useEffect(() => {
    Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId }),
      base44.entities.Deadline.filter({ case_id: caseId }),
      base44.entities.Person.filter({ case_id: caseId }),
      base44.entities.GegnerVerhalten.filter({ case_id: caseId }),
    ]).then(([a, e, d, p, gv]) => {
      setArgs(a); setEvidence(e); setDeadlines(d); setPersons(p); setGegnerVerhalten(gv);
      setLoaded(true);
    });
  }, [caseId]);

  useEffect(() => {
    if (!loaded) return;
    const result = computeVollanalyse({ args, evidence, deadlines, persons, caseData });
    setAlgoResult(result);
  }, [loaded, args, evidence, deadlines, persons]);

  // ── Prognose-1: Strategie-Tab (einfacher 6-Stufen-Algorithmus) ──
  const computeStrategiePrognose = () => {
    const eigene = args.filter(x => x.side === "eigen");
    const gegner = args.filter(x => x.side === "gegner");
    const eigenStaerke = eigene.reduce((s, x) => s + (x.strength || 5), 0);
    const gegnerStaerke = gegner.reduce((s, x) => s + (x.strength || 5), 0);
    const argBasis = (eigene.length > 0 || gegner.length > 0)
      ? Math.max(0, ((eigenStaerke / Math.max(1, eigene.length)) - (gegnerStaerke / Math.max(1, gegner.length))) * 5 + 50)
      : 50;
    const avgEvidW = evidence.length > 0 ? evidence.reduce((s, x) => s + (x.weight || 5), 0) / evidence.length : 5;
    const beweisBoost = 1 + (avgEvidW / 10) * 0.5;
    const contradictions = args.filter(x => x.is_contradiction).length;
    const kantenEffekt = Math.max(0.2, 1 - contradictions * 0.2);
    const judges = persons.filter(x => x.role === "Richter");
    const avgGlaubw = judges.length > 0 ? judges.reduce((s, x) => s + (x.glaubwuerdigkeit || 80), 0) / judges.length : 80;
    const zeugenMult = 0.70 + (avgGlaubw / 100) * 0.30;
    const richterRate = judges[0]?.klaeger_rate || caseData?.richter_klaeger_rate || 50;
    const richterAdj = 1 + (richterRate - 50) / 100 * 0.15;
    const versaeumt = deadlines.filter(x => x.status === "versaeumt").length;
    const fristenFaktor = Math.max(0.5, 1 - versaeumt * 0.30);
    const raw = argBasis * beweisBoost * kantenEffekt * zeugenMult * richterAdj * fristenFaktor;
    return Math.min(99, Math.max(1, Math.round(raw)));
  };

  // ── Prognose-2: Prozessstärke-Gesamtscore (Strategie-Tab, unteres Panel) ──
  const computeProzessStaerke = () => {
    const eigenArgs = args.filter(a => a.side === "eigen");
    const gegnerArgs = args.filter(a => a.side === "gegner");
    const eigenStaerke = eigenArgs.length ? eigenArgs.reduce((s, a) => s + (a.strength || 5), 0) / eigenArgs.length : 5;
    const gegnerStaerke = gegnerArgs.length ? gegnerArgs.reduce((s, a) => s + (a.strength || 5), 0) / gegnerArgs.length : 5;
    const argScore = Math.min(100, Math.max(0, (eigenStaerke - gegnerStaerke) * 5 + 50));
    const beweisScore = evidence.length > 0 ? Math.min(100, evidence.reduce((s, e) => s + (e.weight || 5), 0) / evidence.length * 10) : 50;
    const versaeumtCount = deadlines.filter(d => d.status === "versaeumt").length;
    const ueberfaellig = deadlines.filter(d => d.status === "offen" && d.due_date && new Date(d.due_date) < new Date()).length;
    const fristenScore = Math.max(0, 100 - versaeumtCount * 25 - ueberfaellig * 10);
    const gvSum = gegnerVerhalten.reduce((s, g) => s + (g.auswirkung_prognose || 0), 0);
    const gegnerScore = Math.min(100, Math.max(0, 50 + gvSum));
    const richterScore = caseData?.richter_klaeger_rate || 50;
    return Math.round(argScore * 0.30 + beweisScore * 0.20 + fristenScore * 0.20 + gegnerScore * 0.15 + richterScore * 0.15);
  };

  // ── Prognose-3: Gespeicherte KI-Prognose (aus TabStrategie) ──
  const kiPrognoseGespeichert = caseData?.ki_berater_result?.ki_prognose_wert || null;

  // ── Prognose-4: Gespeicherte manuelle Prognose ──
  const manuellePrognose = caseData?.prognose || null;

  // ── Prognose-5: Bayesianische Vollanalyse (TabRisiko) ──
  const bayesPrognose = algoResult?.prognose?.score || null;
  const monteCarloMedian = algoResult?.monteCarlo?.median || null;

  const prognosen = loaded && algoResult ? [
    {
      id: "manuell",
      label: "Manuelle Prognose",
      reiter: "Reiter 6 · Strategie",
      wert: manuellePrognose || computeStrategiePrognose(),
      farbe: "#3b82f6",
      methode: "Manuell gespeichert oder aus dem 6-Stufen-Algorithmus",
      faktoren: [
        `Argumente: ${args.filter(a => a.side === "eigen").length} eigen / ${args.filter(a => a.side === "gegner").length} Gegner`,
        `Beweise: ${evidence.length} Stück`,
        `Richter-Klägerquote: ${caseData?.richter_klaeger_rate || 50}%`,
        `Versäumte Fristen: ${deadlines.filter(d => d.status === "versaeumt").length}`,
      ],
      beschreibung: "Der einfache 6-Stufen-Algorithmus berechnet eine Basisprognose aus Argumentstärke, Beweislage, Widersprüchen, Glaubwürdigkeit der Zeugen, Richter-Kalibrierung und Fristenrisiko. Diese Prognose ist eine schnelle Indikation und reagiert linear auf Datenänderungen."
    },
    {
      id: "prozessstaerke",
      label: "Prozessstärke-Score",
      reiter: "Reiter 6 · Strategie (unten)",
      wert: computeProzessStaerke(),
      farbe: "#8b5cf6",
      methode: "Gewichtete Faktoren-Matrix (5 Dimensionen)",
      faktoren: [
        `Argumente-Balance (30%): ${Math.round(Math.min(100, Math.max(0, (args.filter(a=>a.side==="eigen").reduce((s,a)=>s+(a.strength||5),0)/Math.max(1,args.filter(a=>a.side==="eigen").length) - args.filter(a=>a.side==="gegner").reduce((s,a)=>s+(a.strength||5),0)/Math.max(1,args.filter(a=>a.side==="gegner").length)) * 5 + 50)))}%`,
        `Beweislage (20%): ${evidence.length > 0 ? Math.round(evidence.reduce((s,e)=>s+(e.weight||5),0)/evidence.length*10) : 50}%`,
        `Fristen-Risiko (20%): ${Math.max(0, 100 - deadlines.filter(d=>d.status==="versaeumt").length*25)}%`,
        `Gegnerverhalten (15%): ${Math.min(100, Math.max(0, 50 + gegnerVerhalten.reduce((s,g)=>s+(g.auswirkung_prognose||0),0)))}%`,
        `Richter-Profil (15%): ${caseData?.richter_klaeger_rate || 50}%`,
      ],
      beschreibung: "Diese Prognose gewichtet 5 unabhängige Faktoren. Im Unterschied zum 6-Stufen-Algorithmus werden Gegnerverhalten und Fristen-Überfälligkeit stärker berücksichtigt. Die Multiplikation der Faktoren entfällt, stattdessen wird ein gewichtetes Mittel gebildet."
    },
    {
      id: "bayes",
      label: "Bayesianische Prognose",
      reiter: "Reiter 6 · Risikoformeln",
      wert: bayesPrognose,
      farbe: "#10b981",
      methode: "Bayesianisches Modell mit Log-Odds + σ-Funktion",
      faktoren: [
        `Konfidenzintervall: [${algoResult?.prognose?.ci_low}%, ${algoResult?.prognose?.ci_high}%]`,
        `Unsicherheit σ: ${algoResult?.prognose?.sigma != null ? (algoResult.prognose.sigma * 100).toFixed(1) : "?"}pp`,
        `${algoResult?.prognose?.steps?.length || 0} Berechnungsschritte`,
        `Gesamtrisiko: ${algoResult?.risikofaktoren?.gesamtrisiko?.toUpperCase() || "?"}`,
      ],
      beschreibung: "Das Bayesianische Modell startet mit einer Basiswahrscheinlichkeit und akkumuliert Log-Odds-Änderungen pro Faktor (σ-Funktion). Dies ist mathematisch robuster als lineare Multiplikation, weil extreme Werte abgefangen werden. Daher kann diese Prognose von den anderen abweichen, besonders wenn einzelne Faktoren extrem stark oder schwach sind."
    },
    {
      id: "montecarlo",
      label: "Monte Carlo Median",
      reiter: "Reiter 6 · Risikoformeln",
      wert: monteCarloMedian,
      farbe: "#f59e0b",
      methode: `${(algoResult?.monteCarlo?.iterations || 0).toLocaleString()} stochastische Simulationen`,
      faktoren: [
        `P10 (pessimistisch): ${algoResult?.monteCarlo?.p10}%`,
        `P25: ${algoResult?.monteCarlo?.p25}%`,
        `Median: ${algoResult?.monteCarlo?.median}%`,
        `P75: ${algoResult?.monteCarlo?.p75}%`,
        `P90 (optimistisch): ${algoResult?.monteCarlo?.p90}%`,
      ],
      beschreibung: "Monte Carlo simuliert tausende Szenarien mit zufälligen Abweichungen der Eingangsdaten (Argumentstärken, Beweisgewichte etc.). Der Median ist die robusteste Schätzung. Diese Prognose ist breiter als die anderen — sie zeigt die realistische Bandbreite möglicher Ergebnisse, nicht nur einen Punktwert."
    },
    ...(caseData?.prognose_richter_ki != null ? [{
      id: "richter",
      label: "Richter-KI-Prognose",
      reiter: "Reiter 4 · Gegner / Richter",
      wert: caseData.prognose_richter_ki,
      farbe: "#ef4444",
      methode: "KI-Analyse des Richterprofils",
      faktoren: [`Klägerquote: ${caseData?.richter_klaeger_rate || "?"}%`],
      beschreibung: "Diese Prognose basiert auf dem gespeicherten Richterprofil und dessen historischen Entscheidungsmustern."
    }] : []),
  ].filter(p => p.wert != null) : [];

  const runKiErklarung = async () => {
    if (!prognosen.length) return;
    setKiLoading(true);
    setKiErklarung(null);

    const res = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist ein erfahrener Rechtsanwalt und Statistiker. Erkläre einem Mandanten (nicht-technisch) warum die folgenden Prognosen für seinen Fall unterschiedlich ausfallen. Sei konkret und klar.

FALL: ${caseData?.fallname || "Unbekannt"} | ${caseData?.rechtsgebiet || ""} | Instanz: ${caseData?.instanz || ""}
Zentrale Frage: ${caseData?.zentrale_rechtsfrage || ""}

PROGNOSEN IM VERGLEICH:
${prognosen.map(p => `• ${p.label} (${p.reiter}): ${p.wert}% — Methode: ${p.methode}`).join("\n")}

FALL-DATEN:
- Argumente: ${args.filter(a=>a.side==="eigen").length} eigene, ${args.filter(a=>a.side==="gegner").length} Gegner-Argumente
- Beweise: ${evidence.length} Stück (Ø-Gewicht: ${evidence.length > 0 ? Math.round(evidence.reduce((s,e)=>s+(e.weight||5),0)/evidence.length*10)/10 : "–"}/10)
- Versäumte Fristen: ${deadlines.filter(d=>d.status==="versaeumt").length}
- Richter-Klägerquote: ${caseData?.richter_klaeger_rate || 50}%
- Gegnerverhalten-Einträge: ${gegnerVerhalten.length}

Beantworte:
1. WARUM weichen die Prognosen voneinander ab? (konkrete Gründe für jede Methode)
2. WELCHE Prognose ist am verlässlichsten für diesen Fall und warum?
3. Was sind die 3 wichtigsten Faktoren die aktuell die Prognose am stärksten beeinflussen?
4. Was könnte man konkret tun, um die Erfolgschancen zu verbessern?`,
      response_json_schema: {
        type: "object",
        properties: {
          abweichungs_erklaerung: { type: "string" },
          verlasslichste_prognose: { type: "string" },
          begruendung_verlasslich: { type: "string" },
          top_faktoren: {
            type: "array",
            items: {
              type: "object",
              properties: {
                faktor: { type: "string" },
                einfluss: { type: "string" },
                richtung: { type: "string", enum: ["positiv", "negativ", "neutral"] }
              }
            }
          },
          verbesserungsmassnahmen: {
            type: "array",
            items: {
              type: "object",
              properties: {
                massnahme: { type: "string" },
                erwartete_wirkung: { type: "string" },
                prioritaet: { type: "string", enum: ["hoch", "mittel", "niedrig"] }
              }
            }
          },
          gesamtbewertung: { type: "string" }
        }
      }
    });

    setKiErklarung(res);
    setKiLoading(false);
  };

  if (!loaded || !algoResult) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="flex flex-col items-center gap-3 text-gray-400">
          <div className="w-8 h-8 border-2 border-gray-200 border-t-gray-800 rounded-full animate-spin" />
          <p className="text-sm">Lade und berechne alle Prognosen…</p>
        </div>
      </div>
    );
  }

  const minPrognose = Math.min(...prognosen.map(p => p.wert));
  const maxPrognose = Math.max(...prognosen.map(p => p.wert));
  const spannweite = maxPrognose - minPrognose;

  const barData = prognosen.map(p => ({ name: p.label.split(" ").slice(0, 2).join(" "), wert: p.wert, farbe: p.farbe }));

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="bg-gray-900 text-white rounded-2xl p-5">
        <p className="text-[10px] text-gray-400 uppercase tracking-widest mb-2">Prognose-Vergleich — Alle Modelle</p>
        <div className="flex items-end gap-4 flex-wrap">
          <div>
            <p className="text-4xl font-black">{prognosen.length} Prognosen</p>
            <p className="text-sm text-gray-400 mt-1">Spannweite: {minPrognose}% – {maxPrognose}% (Δ {spannweite.toFixed(0)}pp)</p>
          </div>
          <div className="flex-1" />
          <Button onClick={runKiErklarung} disabled={kiLoading || prognosen.length
