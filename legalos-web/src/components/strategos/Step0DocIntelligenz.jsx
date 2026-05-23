
import { useState, useRef } from "react";
import { base44 } from "@/api/base44Client";
import { Upload, Sparkles, FileUp, Trash2, CheckCircle, Loader, ChevronRight, Brain } from "lucide-react";
import { SF } from "./AppleCard";

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Dokumenten-Intelligenz & KI-Basis-Briefing
// Nimmt beliebige Dokumente entgegen, analysiert sie mit KI und befüllt
// automatisch alle leeren Felder im Szenario (unternehmenskontext, ausgangslage,
// fragestellung, szenario_typ, rechtsgebiet, ki_kontext als shared KI-Basis).
// ─────────────────────────────────────────────────────────────────────────────

const ACCEPTED = ".pdf,.docx,.doc,.txt,.jpg,.jpeg,.png,.xlsx,.csv,.eml,.msg";

function FileRow({ doc, onRemove }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 11,
      padding: "10px 14px",
      background: doc.status === "done" ? "rgba(29,185,84,0.06)" : "rgba(88,86,214,0.05)",
      border: `1px solid ${doc.status === "done" ? "rgba(29,185,84,0.2)" : "rgba(88,86,214,0.15)"}`,
      borderRadius: 12, marginBottom: 6,
    }}>
      <FileUp style={{ width: 15, height: 15, color: doc.status === "done" ? "#1DB954" : "#5856D6", flexShrink: 0 }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontSize: 12, fontWeight: 600, color: "#1a1a1a", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{doc.name}</p>
        {doc.status === "done" && doc.summary && (
          <p style={{ fontSize: 10, color: "#5856D6", marginTop: 2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{doc.summary}</p>
        )}
        {doc.status === "uploading" && <p style={{ fontSize: 10, color: "#888", marginTop: 1 }}>Lädt hoch…</p>}
        {doc.status === "analyzing" && <p style={{ fontSize: 10, color: "#FF9500", marginTop: 1 }}>KI analysiert…</p>}
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}>
        {doc.status === "done" && <CheckCircle style={{ width: 14, height: 14, color: "#1DB954" }} />}
        {(doc.status === "uploading" || doc.status === "analyzing") && (
          <Loader style={{ width: 14, height: 14, color: "#888", animation: "spin 1s linear infinite" }} />
        )}
        <button onClick={() => onRemove(doc.id)} style={{ background: "none", border: "none", cursor: "pointer", color: "#ccc", padding: 2 }}>
          <Trash2 style={{ width: 12, height: 12 }} />
        </button>
      </div>
    </div>
  );
}

function FieldRow({ label, value, filled }) {
  if (!value) return null;
  return (
    <div style={{ display: "flex", gap: 10, padding: "7px 0", borderBottom: "1px solid rgba(0,0,0,0.05)" }}>
      <div style={{ width: 120, flexShrink: 0 }}>
        <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase" }}>{label}</p>
      </div>
      <div style={{ flex: 1 }}>
        <p style={{ fontSize: 12, color: filled ? "#1a1a1a" : "#bbb" }}>{value}</p>
      </div>
      {filled && <CheckCircle style={{ width: 13, height: 13, color: "#1DB954", flexShrink: 0, marginTop: 1 }} />}
    </div>
  );
}

export default function Step0DocIntelligenz({ scenario, onSave, onProceed }) {
  const [docs, setDocs] = useState(scenario.ki_kontext?.docs || []);
  const [uploading, setUploading] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [result, setResult] = useState(scenario.ki_kontext?.analyse || null);
  const [done, setDone] = useState(!!scenario.ki_kontext?.analyse);
  const inputRef = useRef();

  const ctx = scenario.unternehmenskontext || {};

  // ── Upload & sofort-Analyse ──────────────────────────────────────────────
  const handleFiles = async (files) => {
    if (!files.length) return;
    setUploading(true);

    const newDocs = [];
    for (const f of files) {
      const tempId = Math.random().toString(36).slice(2);
      const pending = { id: tempId, name: f.name, status: "uploading", url: null, summary: null };
      setDocs(prev => [...prev, pending]);

      const r = await base44.integrations.Core.UploadFile({ file: f });
      const uploaded = { ...pending, url: r.file_url, status: "analyzing" };
      setDocs(prev => prev.map(d => d.id
