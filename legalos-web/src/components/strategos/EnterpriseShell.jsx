
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
        const active = current
