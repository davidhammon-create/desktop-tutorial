
import { useState, useRef, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Sparkles, Loader2, Info, X, TrendingUp } from "lucide-react";
import { format } from "date-fns";

const CONN_COLOR = {
  "stützt":      { stroke: "#22c55e", label: "stützt",      prob: +0.15 },
  "verstärkt":   { stroke: "#16a34a", label: "verstärkt",   prob: +0.20 },
  "kausal":      { stroke: "#3b82f6", label: "kausal",      prob: +0.12 },
  "entkräftet":  { stroke: "#ef4444", label: "entkräftet",  prob: -0.18 },
  "schwächt":    { stroke: "#f97316", label: "schwächt",    prob: -0.10 },
  "widerspricht":{ stroke: "#f59e0b", label: "widerspricht",prob: -0.15 },
  "schließt aus":{ stroke: "#6b7280", label: "schließt aus",prob: -0.25 },
};

function getProbColor(p) {
  if (p > 0.1) return "text-emerald-600 bg-emerald-50 border-emerald-200";
  if (p < -0.1) return "text-red-500 bg-red-50 border-red-200";
  return "text-slate-500 bg-slate-50 border-slate-200";
}

// Map argument + deadline to a canvas X position based on date
function toX(dateStr, minMs, maxMs, w) {
  const ms = new Date(dateStr).getTime();
  if (maxMs
