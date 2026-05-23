
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { AlertTriangle, CheckCircle, XCircle, ArrowRight, Info, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";

// ── CONFIG ────────────────────────────────────────────────────────────────────

const CONN_COLORS = {
  "stützt":       { bg: "#e8f5e9", border: "#34C759", text: "#1a7f37",  arrow: "#34C759" },
  "verstärkt":    { bg: "#e8f5e9", border: "#34C759", text: "#1a7f37",  arrow: "#34C759" },
  "entkräftet":   { bg: "#fce4ec", border: "#FF3B30", text: "#c0392b",  arrow: "#FF3B30" },
  "widerspricht":  { bg: "#fff3e0", border: "#FF9500", text: "#a05f00",  arrow: "#FF9500" },
  "schwächt":     { bg: "#fff3e0", border: "#FF9500", text: "#a05f00",  arrow: "#FF9500" },
  "schließt aus": { bg: "#f5f5f5", border: "#9E9E9E", text: "#555",     arrow: "#9E9E9E" },
  "kausal":       { bg: "#e3f2fd", border: "#007AFF", text: "#005ec4",  arrow: "#007AFF" },
};

const GAP_TYPES = {
  no_evidence:      { label: "Kein Beweis verknüpft", color: "#FF3B30", icon: "🔴" },
  weak_chain:       { label: "Schwache Kette",         color: "#FF9500", icon: "🟠" },
  contradiction:    { label: "Widerspruch",            color: "#FF9500", icon: "⚡" },
  isolated:         { label: "Isoliertes Argument",    color: "#9E9E9E", icon: "⚫" },
  missing_counter:  { label: "Kein Gegenargument",    color: "#007AFF", icon: "🔵" },
};

// ── GAP DETECTION ─────────────────────────────────────────────────────────────

function detectGaps(args, evidence) {
  const gaps = [];
  const allConnections = [];
  args.forEach(a => (a.connections || []).forEach(c => allConnections.push({ from: a.id, to: c.targetId, type: c.type })));

  args.forEach(arg => {
    // No evidence linked
    const hasEvidence = evidence.some(e => e.argument_id
