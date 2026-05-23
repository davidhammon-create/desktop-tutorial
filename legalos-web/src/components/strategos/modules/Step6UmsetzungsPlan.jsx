
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Sparkles, Download, Scale, ArrowRight, CheckCircle, Clock, AlertTriangle, Link2, ExternalLink } from "lucide-react";
import { AppleCard, AppleButton, ApplePill, SF } from "../AppleCard";
import { useNavigate } from "react-router-dom";

const HORIZONTE_CFG = [
  { key: "sofort", label: "Sofort", sub: "Nächste 30 Tage", color: "#B81C3A" },
  { key: "mittelfristig", label: "6–12 Monate", sub: "Strategische Umsetzung", color: "#FF9500" },
  { key: "langfristig", label: "Langfristig", sub: "Positionierung & Monitoring", color: "#1DB954" },
];

export default function Step6UmsetzungsPlan({ scenario, onSave }) {
  const navigate = useNavigate();
  const ctx = scenario.unternehmenskontext || {};
  const sit = scenario.situationsanalyse || {};
  const mat = scenario.szenario_matrix || {};
  const act = scenario.aktionsplan || {};
  const emp = scenario.strategos_empfehlung || {};
  const quant = scenario.ki_analyse?.quant_analyse || {};
  const opts = scenario.ki_analyse?.handlungsoptionen || {};
  const [plan, setPlan] = useState(scenario.ki_analyse?.umsetzungsplan || null);
  const [generating, setGenerating] = useState(false);
  const [creatingLexara, setCreatingLexara] = useState(false);
  const [lexaraCreated, setLexaraCreated] = useState(scenario.ki_analyse?.lexara_case_created || null);

  const generate = async () => {
    setGenerating(true);
    const r = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist Strategos — Senior-Berater und Rechtsexperte. Erstelle den finalen, vollständig operativen Umsetzungsplan.

VOLLSTÄNDIGE ANALYSE:
Unternehmen: ${ctx.unternehmen_name} (${ctx.rechtsform}, ${ctx.branche}), Umsatz: ${ctx.umsatz ? (ctx.umsatz/1e6).toFixed(1)+"Mio.€" : "—"}
Sachverhalt: ${ctx.sachverhalt_lang || "—"}
Gegner: ${ctx.gegner_name || "—"} (${ctx.gegner_rolle || "—"})
Gesamt-Risiko: ${sit.gesamt_risiko || "—"}/10 | Exposure: ${sit.gesamt_exposure_eur ? (sit.gesamt_exposure_eur/1e6).toFixed(1)+"Mio.€" : "—"}
Empfohlene Option: ${quant.empfohlene_option || emp.grundhaltung || opts.empfohlene_option || "—"}
Top-3 Hebel: ${(emp.groesste_hebel || []).slice(0, 3).join(" · ") || "—"}
Aktionsplan: ${(act.massnahmen || []).length} Maßnahmen

LIEFERE:

1. UMSETZUNGSPLAN mit 3 Horizonten:
   - sofort (0-30 Tage): 5-7 konkrete Sofortmaßnahmen mit genauer Frist, Verantwortlichem, §§, Kosten
   - mittelfristig (6-12 Monate): 5-7 strategische Maßnahmen
   - langfristig (18+ Monate): 3-5 Positionierungsmaßnahmen

2. MONITORING-PLAN: 5-7 konkrete Indikatoren die das Unternehmen beobachten muss, um zu erkennen ob die Strategie angepasst werden muss

3. COMPLIANCE-DOKUMENTATION: Was muss für Business Judgment Rule (§ 93 Abs. 2 AktG) dokumentiert werden? Was hilft bei Steuerprüfung (§ 90 Abs. 3 AO)? Was entlastet bei Kartelluntersuchung?

4. ZEITSTRAHL mit 8-10 kritischen Meilensteinen (datum/zeitraum + ereignis + konsequenz bei Versäumnis)

5. SCHIEDSVERFAHREN-EMPFEHLUNG: Falls Konflikt eskaliert — ordentlicher Rechtsweg oder Schiedsgericht? Welche Institution (ICC / DIS / LCIA / SCC), welcher Schiedsort, welches Recht?

6. LEXARA-ÜBERGABE-CHECKLISTE: Falls Strategos-Szenario in Rechtsstreit übergeht — welche Daten müssen in Lexara erfasst werden?

7. DOKUMENTATIONS-STANDARD für §§ 93 AktG, 30/130 OWiG, 266 StGB, 370 AO als Verteidigungsmittel`,
      response_json_schema: {
        type: "object",
        properties: {
          umsetzung_sofort: { type: "array", items: { type: "object", properties: {
            massnahme: { type: "string" }, frist: { type: "string" }, verantwortlich: { type: "string" },
            norm: { type: "string" }, kosten_eur: { type: "number" }, prioritaet: { type: "string" }
          }}},
          umsetzung_mittelfristig: { type: "array", items: { type: "object", properties: {
            massnahme: { type: "string" }, zeitraum: { type: "string" }, verantwortlich: { type: "string" }, wirkung: { type: "string" }
          }}},
          umsetzung_langfristig: { type: "array", items: { type: "object", properties: {
            massnahme: { type: "string" }, zeitraum: { type: "string" }, ziel: { type: "string" }
          }}},
          monitoring_indikatoren: { type: "array", items: { type: "object", properties: {
            indikator: { type: "string" }, schwellenwert: { type: "string" }, massnahme_bei_abweichung: { type: "string" }, frequenz: { type: "string" }
          }}},
          zeitstrahl: { type: "array", items: { type: "object", properties: {
            datum: { type: "string" }, ereignis: { type: "string" }, konsequenz_versaeumnis: { type: "string" }, kritisch: { type: "boolean" }
          }}},
          schiedsverfahren_empfehlung: { type: "object", properties: {
            empfehlung: { type: "string" },
            institution: { type: "string" },
            schiedsort: { type: "string" },
            schiedsrecht: { type: "string" },
            begruendung: { type: "string" },
            kostenindikation: { type: "string" }
          }},
          compliance_dokumentation: { type: "array", items: { type: "object", properties: {
            rechtsgrundlage: { type: "string" },
            was_dokumentieren: { type: "string" },
            zweck: { type: "string" }
          }}},
          lexara_checkliste: { type: "array", items: { type: "string" } },
          executive_summary: { type: "string" }
        }
      },
      model: "claude_sonnet_4_6"
    });
    setPlan(r);
    await onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), umsetzungsplan: r } });
    setGenerating(false);
  };

  const createLexaraCase = async () => {
    setCreatingLexara(true);
    const newCase = await base44.entities.Case.create({
      fallname: `[STRATEGOS] ${scenario.title}`,
      rechtsgebiet: (ctx.rechtsgebiete || []).join(", ") || scenario.rechtsgebiet || "",
      status: "Vorbereitung",
      instanz: "Erstinstanz",
      zentrale_rechtsfrage: ctx.sachverhalt_lang?.slice(0, 200) || "",
      prognose: sit.gesamt_risiko ? Math.max(0, 100 - sit.gesamt_risiko * 10) : null,
      streitwert: scenario.finanzdaten?.transaktionswert || sit.gesamt_exposure_eur || null,
      notes: `[Aus STRATEGOS-Szenario migriert — ${new Date().toLocaleDateString("de-DE")}]\n\nSachverhalt: ${ctx.sachverhalt_lang || "—"}\n\nGegner: ${ctx.gegner_name || "—"} (${ctx.gegner_rolle || "—"})\n\nStrategos-Empfehlung: ${emp.machtposition?.slice(0, 300) || "—"}\n\nTop-Hebel: ${(emp.groesste_hebel || []).join(" · ")}\n\nGroesste Risiken: ${(emp.groesste_risiken || []).join(" · ")}`,
      ki_berater_result: {
        strategos_scenario_id: scenario.id,
        empfohlene_option: quant.empfohlene_option || opts.empfohlene_option,
        gesamt_risiko: sit.gesamt_risiko,
        exposure_eur: sit.gesamt_exposure_eur,
      },
    });
    const info = { case_id: newCase.id, case_name: newCase.fallname, created_at: new Date().toISOString() };
    setLexaraCreated(info);
    await onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), lexara_case_created: info }, unternehmenskontext: { ...ctx, lexara_case_id: newCase.id } });
    setCreatingLexara(false);
  };

  const exportReport = async () => {
    const text = `STRATEGOS — GESAMTBERICHT & UMSETZUNGSPLAN
${"=".repeat(60)}
Unternehmen: ${ctx.unternehmen_name || "—"}
Szenario: ${scenario.title}
Datum: ${new Date().toLocaleDateString("de-DE")}

EXECUTIVE SUMMARY:
${plan?.executive_summary || "—"}

SOFORTMASSNAHMEN (0-30 Tage):
${(plan?.umsetzung_sofort || []).map((m, i) => `${i + 1}. ${m.massnahme}\n   Frist: ${m.frist} | Verantw.: ${m.verantwortlich} | Norm: ${m.norm}`).join("\n")}

MITTELFRISTIG (6-12 Monate):
${(plan?.umsetzung_mittelfristig || []).map((m, i) => `${i + 1}. ${m.massnahme} (${m.zeitraum})`).join("\n")}

MONITORING-INDIKATOREN:
${(plan?.monitoring_indikatoren || []).map(m => `• ${m.indikator}: ${m.schwellenwert} | Frequenz: ${m.frequenz}`).join("\n")}

SCHIEDSVERFAHREN-EMPFEHLUNG:
${plan?.schiedsverfahren_empfehlung?.begruendung || "—"}
Institution: ${plan?.schiedsverfahren_empfehlung?.institution || "—"} | Ort: ${plan?.schiedsverfahren_empfehlung?.schiedsort || "—"}

COMPLIANCE-DOKUMENTATION:
${(plan?.compliance_dokumentation || []).map(c => `• ${c.rechtsgrundlage}: ${c.was_dokumentieren}`).join("\n")}
${"=".repeat(60)}
Vertraulich — Erstellt mit STRATEGOS · ${new Date().toLocaleDateString("de-DE")}`;
    const blob = new Blob([text], { type: "text/plain;charset=utf-8;" });
    const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = `Strategos_Umsetzungsplan_${new Date().toISOString().slice(0, 10)}.txt`; a.click();
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 18, ...SF }}>
      <div style={{ textAlign: "center", padding: "8px 0 2px" }}>
        <p style={{ fontSize: 11, fontWeight: 700, color: "#AF52DE", letterSpacing: "0.15em", textTransform: "uppercase" }}>Schritt 6 · Strategos</p>
        <h2 style={{ fontSize: 24, fontWeight: 700, color: "#1a1a1a", letterSpacing: "-0.5px", marginTop: 4 }}>Handlungsempfehlung & Umsetzungsplan</h2>
        <p style={{ fontSize: 12, color: "#888", marginTop: 3 }}>Operative Roadmap · Monitoring · Schiedsempfehlung · LEXARA-Export</p>
      </div>

      {/* Generieren */}
      <AppleCard accentColor="#AF52DE">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
          <div>
            <p style={{ fontSize: 13, fontWeight: 700, color: "#1a1a1a" }}>Umsetzungsplan generieren</p>
            <p style={{ fontSize: 11, color: "#888", marginTop: 2 }}>BJR-Dokumentation · Monitoring · Zeitstrahl · Schiedsempfehlung</p>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <AppleButton onClick={generate} disabled={generating} variant="violet" icon={Sparkles}>
              {generating ? "Generiert…" : plan ? "Neu generieren" : "Plan erstellen"}
            </AppleButton>
            {plan && <AppleButton onClick={exportReport} variant="ghost" icon={Download}>Export</AppleButton>}
          </div>
        </div>
      </AppleCard>

      {plan && (
        <>
          {/* Executive Summary */}
          {plan.executive_summary && (
            <AppleCard title="Executive Summary" accentColor="#1a1a1a">
              <div style={{ padding: "13px 15px", background: "rgba(0,0,0,0.03)", borderRadius: 12 }}>
                <p style={{ fontSize: 13, color: "#1a1a1a", lineHeight: 1.65 }}>{plan.executive_summary}</p>
              </div>
            </AppleCard>
          )}

          {/* Umsetzung 3 Horizonte */}
          {HORIZONTE_CFG.map(h => {
            const data = plan[`umsetzung_${h.key}`] || [];
            if (data.length
