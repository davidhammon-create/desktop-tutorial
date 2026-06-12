
import { useState } from "react";
import { SF } from "./AppleCard";
import Step0DocIntelligenz from "./Step0DocIntelligenz";
import Step1Kontext from "./modules/Step1Kontext";
import Step2Situation from "./modules/Step2Situation";
import Step2VertragsAnalyse from "./modules/Step2VertragsAnalyse";
import Step3PatentAnalyse from "./modules/Step3PatentAnalyse";
import Step4HandlungsOptionen from "./modules/Step4HandlungsOptionen";
import Step5QuantitativeAnalyse from "./modules/Step5QuantitativeAnalyse";
import Step6UmsetzungsPlan from "./modules/Step6UmsetzungsPlan";
import { Brain, Share2, BookOpen } from "lucide-react";
import NotionExportTab from "./NotionExportTab";
import RechtlicheEinschaetzungenTab from "./RechtlicheEinschaetzungenTab";

const STEPS = [
  { num: 0,  label: "Dokumente & KI-Briefing", sub: "Upload · Extraktion · Automatisch befüllen",    color: "#5856D6" },
  { num: 1,  label: "Kontext & Situation",      sub: "Unternehmen · Sachverhalt · Rechtsgebiete",    color: "#0A84FF" },
  { num: 2,  label: "Rechtsgebiet-Analyse",     sub: "KI-Tiefenanalyse pro Rechtsgebiet",            color: "#FF9500" },
  { num: 3,  label: "Vertragsanalyse",          sub: "Klausel-Risiko · Szenarioprojektion",          color: "#0A84FF" },
  { num: 4,  label: "Patentanalyse",            sub: "Schutzbereich · FTO · Strategische Optionen",  color: "#FF9500" },
  { num: 5,  label: "Handlungsoptionen",        sub: "Von A nach C · Gegner-Antizipation",           color: "#1DB954" },
  { num: 6,  label: "Quantitative Analyse",     sub: "EV · Monte Carlo · Bußgeld-Worst-Case",        color: "#5856D6" },
  { num: 7,  label: "Umsetzungsplan",           sub: "Roadmap · Monitoring · LEXARA-Export",         color: "#AF52DE" },
];

function Stepper({ current, onSelect, scenario }) {
  const ctx = scenario.unternehmenskontext || {};
  const sit = scenario.situationsanalyse || {};
  const ki  = scenario.ki_analyse || {};

  const doneMap = {
    0: !!(scenario.ki_kontext?.analyse),
    1: Object.keys(ctx).length > 3,
    2: (sit.module?.length || 0) > 0,
    3: !!ki.vertrags_analyse,
    4: !!ki.patent_analyse,
    5: !!ki.handlungsoptionen,
    6: !!ki.quant_analyse,
    7: !!ki.umsetzungsplan,
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 2, marginBottom: 16 }}>
      {STEPS.map(s => {
        const active = current === s.num;
        const done = !!doneMap[s.num];
        return (
          <button
            key={s.num}
            onClick={() => onSelect(s.num)}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              padding: "9px 13px",
              borderRadius: 11,
              border: "none",
              cursor: "pointer",
              background: active ? `${s.color}12` : "transparent",
              textAlign: "left",
              width: "100%",
              transition: "background 0.15s",
            }}
          >
            <div style={{
              width: 24, height: 24, borderRadius: "50%", flexShrink: 0,
              display: "flex", alignItems: "center", justifyContent: "center",
              background: active ? s.color : done ? "#34C75920" : "rgba(0,0,0,0.06)",
              border: active ? `2px solid ${s.color}` : done ? "2px solid #34C759" : "2px solid rgba(0,0,0,0.08)",
            }}>
              {done && !active
                ? <span style={{ fontSize: 10, color: "#34C759" }}>✓</span>
                : <span style={{ fontSize: 10, fontWeight: 800, color: active ? s.color : "#aaa" }}>{s.num}</span>
              }
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <p style={{ fontSize: 11, fontWeight: active ? 700 : 500, color: active ? s.color : "#333", lineHeight: 1.2 }}>{s.label}</p>
              <p style={{ fontSize: 9, color: "#aaa", marginTop: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{s.sub}</p>
            </div>
          </button>
        );
      })}
    </div>
  );
}

export default function EnterpriseShell({ scenario, onSave }) {
  const [step, setStep] = useState(scenario.enterprise_step ?? 0);
  const [sc, setSc] = useState(scenario);

  const handleSave = async (updates) => {
    const merged = { ...sc, ...updates };
    setSc(merged);
    const saved = await onSave(updates);
    return saved;
  };

  const goStep = (n) => {
    setStep(n);
    onSave({ enterprise_step: n });
  };

  const advance = () => { const next = Math.min(STEPS.length - 1, step + 1); goStep(next); };
  const back = () => { const prev = Math.max(0, step - 1); goStep(prev); };

  const stepProps = { scenario: sc, onSave: handleSave };

  const STEP_COMPONENTS = {
    0: <Step0DocIntelligenz {...stepProps} />,
    1: <Step1Kontext {...stepProps} />,
    2: <Step2Situation {...stepProps} />,
    3: <Step2VertragsAnalyse {...stepProps} />,
    4: <Step3PatentAnalyse {...stepProps} />,
    5: <Step4HandlungsOptionen {...stepProps} />,
    6: <Step5QuantitativeAnalyse {...stepProps} />,
    7: <Step6UmsetzungsPlan {...stepProps} />,
  };

  return (
    <div style={{ display: "flex", gap: 20, alignItems: "flex-start", ...SF }}>
      {/* Left sidebar: stepper */}
      <div style={{
        width: 240,
        flexShrink: 0,
        background: "rgba(255,255,255,0.88)",
        backdropFilter: "blur(20px)",
        borderRadius: 18,
        border: "1px solid rgba(0,0,0,0.06)",
        boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
        padding: "16px 8px",
        position: "sticky",
        top: 70,
      }}>
        <p style={{ fontSize: 10, fontWeight: 700, color: "#bbb", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: 8, paddingLeft: 13 }}>Workflow</p>
        <Stepper current={step} onSelect={goStep} scenario={sc} />
        <div style={{ marginTop: 12, padding: "0 8px", display: "flex", flexDirection: "column", gap: 6 }}>
          {step > 0 && (
            <button onClick={back} style={{ padding: "8px", borderRadius: 10, border: "1px solid rgba(0,0,0,0.1)", background: "transparent", fontSize: 11, color: "#666", cursor: "pointer" }}>
              ← Zurück
            </button>
          )}
          {step < STEPS.length - 1 && (
            <button onClick={advance} style={{ padding: "8px", borderRadius: 10, border: "none", background: STEPS[step]?.color || "#007AFF", color: "#fff", fontSize: 11, fontWeight: 700, cursor: "pointer" }}>
              Weiter →
            </button>
          )}
        </div>

        {/* Additional tabs */}
        <div style={{ marginTop: 12, borderTop: "1px solid rgba(0,0,0,0.07)", paddingTop: 12, padding: "12px 8px 0" }}>
          <p style={{ fontSize: 10, fontWeight: 700, color: "#bbb", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: 6, paddingLeft: 5 }}>Extras</p>
          {[
            { icon: <Brain size={12} />, label: "Rechtliche Einschätzungen", component: "einschaetzungen" },
            { icon: <BookOpen size={12} />, label: "Notion Export", component: "notion" },
          ].map(item => (
            <button key={item.label} style={{ display: "flex", alignItems: "center", gap: 8, padding: "7px 8px", width: "100%", borderRadius: 9, border: "none", background: "transparent", fontSize: 11, color: "#666", cursor: "pointer", textAlign: "left" }}>
              {item.icon} {item.label}
            </button>
          ))}
        </div>
      </div>

      {/* Right: step content */}
      <div style={{ flex: 1, minWidth: 0 }}>
        {STEP_COMPONENTS[step] || (
          <div style={{ textAlign: "center", padding: 40, color: "#999" }}>
            <p>Schritt {step} wird geladen…</p>
          </div>
        )}
      </div>
    </div>
  );
}
