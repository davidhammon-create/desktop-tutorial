
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { RefreshCw, Sparkles, Target, Shield, Zap, AlertTriangle, Calculator, ChevronDown, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { computePrognose, computeBreakEven } from "@/lib/legalAlgorithms";

// Einfache Laienerklärungen pro Berechnungsschritt-Label
const SIMPLE_EXPLANATIONS = {
  "Prior-Wahrscheinlichkeit (Basisrate)":
    "💡 Einfach erklärt: Bevor wir irgendetwas über den Fall wissen, fragen wir: Wie oft gewinnt der Kläger in diesem Rechtsgebiet statistisch? Das ist unser Startpunkt – wie ein Wettertipp vor Betrachtung der Wolken.",
  "Argumentationsbilanz":
    "💡 Einfach erklärt: Wie stark sind unsere Argumente im Vergleich zu den gegnerischen? Starke eigene Argumente verbessern die Prognose, starke Gegenargumente verschlechtern sie – ähnlich wie bei einer Waage.",
  "Beweisqualität & -quantität":
    "💡 Einfach erklärt: Mehr gute Beweise = bessere Chancen. Aber mehr Beweise bringen immer weniger zusätzlichen Nutzen (der 10. Beweis zählt weniger als der 1.). Die Qualität jedes Beweises fließt gewichtet ein.",
  "Richter-Statistik (Bayesianisch)":
    "💡 Einfach erklärt: Wenn wir wissen, wie oft dieser Richter den Kläger gewinnen lässt, passen wir unsere Prognose entsprechend an – wie ein Tipp auf einen Tennisspieler, wenn man dessen Siegquote auf diesem Platz kennt.",
  "Richter-Statistik":
    "💡 Einfach erklärt: Kein Richter bekannt – deshalb bleibt die Prognose an dieser Stelle unverändert.",
  "Fristenrisiko (Malus)":
    "💡 Einfach erklärt: Versäumte Fristen schaden dem Fall erheblich – Gerichte nehmen das sehr ernst. Jede versäumte Frist zieht die Prognose nach unten, wie ein Strafstoß beim Fußball.",
  "Vergleichsangebot-Signal":
    "💡 Einfach erklärt: Ein hohes Vergleichsangebot der Gegenseite zeigt, dass die Gegner nervös sind – ein positives Zeichen für uns. Ein niedriges Angebot deutet auf ihre Stärke hin.",
  "Finale Wahrscheinlichkeit (Logistische Transformation)":
    "💡 Einfach erklärt: Alle Faktoren wurden auf einer technischen Skala addiert. Die logistische Funktion wandelt diese Summe in eine echte Prozentzahl zwischen 0% und 100% um – wie ein Thermometer, das eine Zahl in 'heiß' oder 'kalt' übersetzt.",
  "90%-Konfidenzintervall (Fehlerfortpflanzung)":
    "💡 Einfach erklärt: Kein Ergebnis ist 100% sicher. Das Konfidenzintervall zeigt den realistischen Korridor: 'Mit 90% Wahrscheinlichkeit liegt die echte Chance zwischen X% und Y%.' Je breiter der Bereich, desto unsicherer die Datenlage.",
};

function AlgoStepCard({ step, index }) {
  const [open, setOpen] = useState(false);
  const wert = typeof step.wert === "number"
    ? `${step.wert > 0 ? "+" : ""}${step.wert.toFixed(4)} ${step.einheit || ""}`
    : typeof step.wert === "object" && step.wert?.ciLow !== undefined
      ? `[${(step.wert.ciLow * 100).toFixed(1)}%, ${(step.wert.ciHigh * 100).toFixed(1)}%]`
      : "";
  const simpleExpl = SIMPLE_EXPLANATIONS[step.label];
  return (
    <div className="border border-gray-100 rounded-xl overflow-hidden">
      <button onClick={() => setOpen(o => !o)}
        className="w-full flex items-center gap-3 px-3 py-2.5 hover:bg-gray-50 transition-colors text-left">
        <span className="w-5 h-5 rounded-full bg-gray-900 text-white text-[9px] font-bold flex items-center justify-center flex-shrink-0">{index + 1}</span>
        <span className="flex-1 text-xs font-medium text-gray-700">{step.label}</span>
        <code className="text-[10px] text-violet-700 font-mono">{wert}</code>
        {open ? <ChevronDown className="w-3 h-3 text-gray-400" /> : <ChevronRight className="w-3 h-3 text-gray-400" />}
      </button>
      {open && (
        <div className="px-3 pb-3 bg-gray-50 border-t border-gray-100 space-y-2 pt-2">
          {step.formel && (
            <div className="bg-white border border-gray-200 rounded-lg px-3 py-2">
              <p className="text-[9px] font-bold text-gray-400 mb-0.5">FORMEL</p>
              <code className="text-[10px] text-blue-800 font-mono break-all">{step.formel}</code>
            </div>
          )}
          <p className="text-xs text-gray-600">{step.erklaerung}</p>
          {simpleExpl && (
            <div className="bg-blue-50 border border-blue-100 rounded-lg px-3 py-2">
              <p className="text-xs text-blue-800 leading-relaxed">{simpleExpl}</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function ScoreBar({ value, max = 10, color = "bg-blue-500" }) {
  return (
    <div className="flex items-center gap-2">
      <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all`} style={{ width: `${(value / max) * 100}%` }} />
      </div>
      <span className="text-xs font-semibold text-gray-700 w-10 text-right">{value?.toFixed(1)}/10</span>
    </div>
  );
}

function ScoreCard({ label, manual, ki, icon }) {
  return (
    <div className="bg-white border border-gray-100 rounded-xl p-4 space-y-2">
      <p className="text-xs font-semibold text-gray-600">{icon} {label}</p>
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <span className="text-[10px] text-gray-400 w-16">Manuell</span>
          <ScoreBar value={manual} color="bg-blue-400" />
        </div>
        {ki !== null && ki !== undefined && (
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-violet-500 w-16">KI</span>
            <ScoreBar value={ki} color="bg-violet-500" />
          </div>
        )}
      </div>
    </div>
  );
}

const avg = (arr, field) => {
  const vals = arr.map(x => x[field]).filter(v => v !== undefined && v !== null && !isNaN(v));
  return vals.length ? vals.reduce((a, b) => a + b, 0) / vals.length : 0;
};

export default function TabGesamtbewertung({ caseId, caseData }) {
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [persons, setPersons] = useState([]);
  const [deadlines, setDeadlines] = useState([]);
  const [kiAnalysis, setKiAnalysis] = useState(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [algoResult, setAlgoResult] = useState(null);
  const [showAlgoSteps, setShowAlgoSteps] = useState(false);

  useEffect(() => {
    Promise.all([
      base44.entities.Argument.filter({ case_id: caseId }),
      base44.entities.Evidence.filter({ case_id: caseId }),
      base44.entities.Person.filter({ case_id: caseId }),
      base44.entities.Deadline.filter({ case_id: caseId }),
    ]).then(([a, e, p, d]) => { setArgs(a); setEvidence(e); setPersons(p); setDeadlines(d); setLoaded(true); });
  }, [caseId]);

  const eigeneArgs = args.filter(a => a.side === "eigen");
  const gegnerArgs = args.filter(a => a.side === "gegner");

  // Algorithmus-Prognose
  const algoPrognose = loaded
    ? computePrognose({ args, evidence, deadlines, persons, caseData })
    : null;
  const breakEven = loaded ? computeBreakEven({ caseData }) : null;

  // Manual scores
  const manEigeneArg = avg(eigeneArgs, "strength");
  const manGegnerArg = avg(gegnerArgs, "strength");
  const manEv = avg(evidence, "weight");

  // KI scores (if available)
  const kiEigeneArg = avg(eigeneArgs.filter(a => a.ki_strength !== undefined && a.ki_strength !== null), "ki_strength");
  const kiGegnerArg = avg(gegnerArgs.filter(a => a.ki_strength !== undefined && a.ki_strength !== null), "ki_strength");
  const kiEv = avg(evidence.filter(e => e.ki_weight !== undefined && e.ki_weight !== null), "ki_weight");

  const hasKiWeights = eigeneArgs.some(a => a.ki_strength !== null && a.ki_strength !== undefined) ||
    evidence.some(e => e.ki_weight !== null && e.ki_weight !== undefined);

  // Overall score (manual)
  const manualScore = eigeneArgs.length + evidence.length
