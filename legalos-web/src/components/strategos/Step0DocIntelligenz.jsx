
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
      setDocs(prev => prev.map(d => d.id === tempId ? uploaded : d));

      // Analyze document content
      const analyzed = await base44.integrations.Core.InvokeLLM({
        prompt: `Analysiere dieses Dokument und extrahiere die wichtigsten rechtlichen und geschäftlichen Informationen für ein Strategos-Szenario. Dokument: ${f.name}`,
        response_json_schema: {
          type: "object",
          properties: {
            zusammenfassung: { type: "string" },
            unternehmen: { type: "string" },
            rechtsgebiet: { type: "string" },
            sachverhalt: { type: "string" },
            key_facts: { type: "array", items: { type: "string" } }
          }
        }
      });
      const done = { ...uploaded, status: "done", summary: analyzed.zusammenfassung || "Analysiert", analysis: analyzed };
      setDocs(prev => prev.map(d => d.id === tempId ? done : d));
      newDocs.push(done);
    }
    setUploading(false);
  };

  const runKiBriefing = async () => {
    if (!docs.length) return;
    setAnalyzing(true);
    const allSummaries = docs.map(d => `${d.name}: ${d.summary || "—"}`).join("\n");
    const r = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist ein erfahrener Senior-Anwalt. Erstelle ein vollständiges KI-Briefing für ein Strategos-Szenario basierend auf diesen Dokumenten:\n\n${allSummaries}`,
      response_json_schema: {
        type: "object",
        properties: {
          ki_briefing: { type: "string" },
          unternehmen_name: { type: "string" },
          rechtsgebiet_hauptthema: { type: "string" },
          rechtsgebiete: { type: "array", items: { type: "string" } },
          sachverhalt: { type: "string" },
          dokument_typen: { type: "array", items: { type: "string" } }
        }
      }
    });
    setResult(r);
    setDone(true);
    const updates = {
      ki_kontext: { docs, analyse: r, ki_briefing: r.ki_briefing },
    };
    if (r.unternehmen_name && !ctx.unternehmen_name) {
      updates.unternehmenskontext = { ...(scenario.unternehmenskontext || {}), unternehmen_name: r.unternehmen_name };
    }
    await onSave(updates);
    setAnalyzing(false);
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 18, ...SF }}>
      <div style={{ textAlign: "center", paddingBottom: 4 }}>
        <p style={{ fontSize: 11, fontWeight: 700, color: "#5856D6", letterSpacing: "0.15em", textTransform: "uppercase" }}>Schritt 0 · Strategos</p>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: "#1a1a1a", letterSpacing: "-0.4px", marginTop: 4 }}>Dokumente & KI-Briefing</h2>
        <p style={{ fontSize: 12, color: "#888", marginTop: 3 }}>Lade Dokumente hoch — KI befüllt alle Felder automatisch</p>
      </div>

      {/* Upload area */}
      <div
        style={{ border: "2px dashed rgba(88,86,214,0.3)", borderRadius: 16, padding: "28px 20px", textAlign: "center", cursor: "pointer", background: "rgba(88,86,214,0.02)" }}
        onClick={() => inputRef.current?.click()}
        onDragOver={e => e.preventDefault()}
        onDrop={e => { e.preventDefault(); handleFiles(Array.from(e.dataTransfer.files)); }}
      >
        <input ref={inputRef} type="file" multiple accept={ACCEPTED} style={{ display: "none" }} onChange={e => handleFiles(Array.from(e.target.files))} />
        <Upload style={{ width: 28, height: 28, color: "#5856D6", margin: "0 auto 10px" }} />
        <p style={{ fontSize: 13, fontWeight: 600, color: "#1a1a1a" }}>Dokumente hochladen</p>
        <p style={{ fontSize: 11, color: "#aaa", marginTop: 4 }}>PDF, DOCX, TXT, Bilder — Drag & Drop oder klicken</p>
      </div>

      {docs.length > 0 && (
        <div>
          <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 8 }}>Hochgeladene Dokumente ({docs.length})</p>
          {docs.map(doc => <FileRow key={doc.id} doc={doc} onRemove={id => setDocs(prev => prev.filter(d => d.id !== id))} />)}
          {!done && (
            <button
              onClick={runKiBriefing}
              disabled={analyzing || docs.some(d => d.status !== "done")}
              style={{ marginTop: 10, width: "100%", padding: "11px", borderRadius: 12, border: "none", background: analyzing ? "#f0f0f0" : "linear-gradient(135deg,#5856D6,#0A84FF)", color: analyzing ? "#999" : "#fff", fontSize: 13, fontWeight: 700, cursor: analyzing ? "not-allowed" : "pointer" }}
            >
              {analyzing ? "KI analysiert alle Dokumente…" : "✦ KI-Briefing erstellen & Felder befüllen"}
            </button>
          )}
        </div>
      )}

      {result && (
        <div style={{ padding: "14px 16px", background: "rgba(29,185,84,0.06)", border: "1px solid rgba(29,185,84,0.2)", borderRadius: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 10 }}>
            <CheckCircle style={{ width: 16, height: 16, color: "#1DB954" }} />
            <p style={{ fontSize: 13, fontWeight: 700, color: "#1DB954" }}>KI-Briefing erstellt — Felder befüllt</p>
          </div>
          {result.rechtsgebiete?.length > 0 && (
            <p style={{ fontSize: 11, color: "#555" }}>Erkannte Rechtsgebiete: {result.rechtsgebiete.join(", ")}</p>
          )}
          {result.ki_briefing && (
            <p style={{ fontSize: 11, color: "#333", marginTop: 6, lineHeight: 1.5 }}>{result.ki_briefing.slice(0, 300)}{result.ki_briefing.length > 300 ? "…" : ""}</p>
          )}
        </div>
      )}
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );
}
