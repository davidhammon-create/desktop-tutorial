
import { useState } from "react";
import { Sword, Crown, Shield, ChevronDown, ChevronUp, Loader2, FileText, AlertTriangle, Lightbulb, Target } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { useJurisdiction } from "../hooks/useJurisdiction";
import { getAIContext } from "../lib/jurisdictionConfig";

const LAWS_OF_POWER = [
  "Never outshine the master","Never put too much trust in friends, learn how to use enemies",
  "Conceal your intentions","Always say less than necessary","Court attention at all costs",
  "Get others to do the work, take the credit","Make other people come to you",
  "Make others come to you – use bait if necessary","Win through your actions, never through argument",
  "Avoid the unhappy and the unlucky","Keep people dependent on you",
  "Use selective honesty to disarm your victim","Appeal to self-interest, never to mercy",
  "Pose as a friend, work as a spy","Crush your enemy totally","Use absence to increase respect and honor",
  "Keep others in suspended terror","Do not build fortresses – isolation is dangerous",
  "Know who you're dealing with","Do not commit to anyone",
];

const SUN_TZU_PRINCIPLES = [
  "Know yourself and know your enemy",
  "Supreme excellence consists in breaking the enemy's resistance without fighting",
  "All warfare is based on deception","Attack weakness, avoid strength",
  "Speed is the essence of war","Use spies to gather intelligence",
  "Win without fighting","Adapt to circumstances","Strike at the enemy's strategy",
];

export default function SunTzuMachiavel() {
  const { jurisdiction } = useJurisdiction();
  const [caseText, setCaseText] = useState("");
  const [opponent, setOpponent] = useState("");
  const [goal, setGoal] = useState("");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [expandedSection, setExpandedSection] = useState(null);

  const analyze = async () => {
    if (!caseText.trim()) return;
    setLoading(true);
    setResult(null);
    const legalCtx = getAIContext(jurisdiction);
    const res = await base44.integrations.Core.InvokeLLM({
      prompt: `You are a master strategist combining Sun Tzu's "The Art of War", Machiavelli's "The Prince", and Robert Greene's "48 Laws of Power" with expert legal knowledge.\n\nLEGAL CONTEXT: ${legalCtx}\n\nCASE DESCRIPTION:\n${caseText}\n\nOPPONENT DESCRIPTION:\n${opponent || "Unknown opponent / opposing counsel"}\n\nSTRATEGIC GOAL:\n${goal || "Win the case / achieve the best possible outcome"}\n\nSUN TZU PRINCIPLES TO APPLY: ${SUN_TZU_PRINCIPLES.join(", ")}\n\n48 LAWS OF POWER (select the most relevant): ${LAWS_OF_POWER.join("; ")}\n\nTASK: Provide a deep strategic and psychological analysis of this legal case.`,
      model: "claude_sonnet_4_6",
      response_json_schema: {
        type: "object",
        properties: {
          strategic_summary: { type: "string" },
          strategic_path: { type: "array", items: { type: "object", properties: { phase: { type: "string" }, action: { type: "string" }, rationale: { type: "string" }, timing: { type: "string" } } } },
          risk_assessment: { type: "object", properties: { overall_risk: { type: "string" }, critical_risks: { type: "array", items: { type: "string" } }, hidden_dangers: { type: "array", items: { type: "string" } }, mitigation: { type: "array", items: { type: "string" } } } },
          power_laws: { type: "array", items: { type: "object", properties: { law_number: { type: "number" }, law_name: { type: "string" }, application: { type: "string" } } } },
          sun_tzu_plan: { type: "array", items: { type: "object", properties: { principle: { type: "string" }, tactical_move: { type: "string" } } } },
          opponent_profile: { type: "object", properties: { psychological_type: { type: "string" }, weaknesses: { type: "array", items: { type: "string" } }, likely_tactics: { type: "array", items: { type: "string" } }, exploitation_strategy: { type: "string" } } },
          machiavellian_moves: { type: "array", items: { type: "string" } },
          red_lines: { type: "array", items: { type: "string" } },
          win_probability_assessment: { type: "string" },
          master_quote: { type: "string" }
        }
      }
    });
    setResult(res);
    setLoading(false);
  };

  const toggle = (s) => setExpandedSection(prev => prev
