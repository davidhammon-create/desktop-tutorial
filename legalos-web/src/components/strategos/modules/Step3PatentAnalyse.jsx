
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Upload, Sparkles, Shield, AlertTriangle, CheckCircle, Zap, FileSearch, Lock } from "lucide-react";
import { AppleCard, AppleButton, ApplePill, AppleField, AppleInput, AppleTextarea, SF } from "../AppleCard";

export default function Step3PatentAnalyse({ scenario, onSave }) {
  const ctx = scenario.unternehmenskontext || {};
  const [patentDocs, setPatentDocs] = useState(scenario.ki_analyse?.patent_docs || []);
  const [eigeneProduktion, setEigeneProduktion] = useState(scenario.ki_analyse?.eigene_produktion || "");
  const [patentNummern, setPatentNummern] = useState(scenario.ki_analyse?.patent_nummern || "");
  const [uploading, setUploading] = useState(false);
  const [analysing, setAnalysing] = useState(false);
  const [result, setResult] = useState(scenario.ki_analyse?.patent_analyse || null);

  const handleUpload = async (e) => {
    const files = Array.from(e.target.files || []);
    if (!files.length) return;
    setUploading(true);
    const up = [];
    for (const f of files) {
      const r = await base44.integrations.Core.UploadFile({ file: f });
      up.push({ name: f.name, url: r.file_url });
    }
    const n = [...patentDocs, ...up];
    setPatentDocs(n);
    await onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), patent_docs: n } });
    setUploading(false);
  };

  const analyse = async () => {
    setAnalysing(true);
    const r = await base44.integrations.Core.InvokeLLM({
      prompt: `Du bist ein führender Patentanwalt und technischer Experte mit Spezialisierung auf deutsches, europäisches und internationales Patentrecht. Führe eine vollständige Patentanalyse durch.

UNTERNEHMENSKONTEXT:
Unternehmen: ${ctx.unternehmen_name || "—"} (${ctx.branche || "—"}, ${ctx.hauptsitz_land || "—"})
Branche: ${ctx.branche || "—"} — ${ctx.branche_freitext || ""}
Operative Märkte: ${(ctx.operative_maerkte || []).join(", ") || "—"}
Sachverhalt: ${ctx.sachverhalt_lang || "—"}

PATENTDATEN:
Patentnummern: ${patentNummern || "—"}
Eigene Produktion/Produkt: ${eigeneProduktion || "—"}
Hochgeladene Dokumente: ${patentDocs.length > 0 ? patentDocs.map(d => d.name).join(", ") : "Keine"}

Analysiere auf folgenden Dimensionen:

1. SCHUTZBEREICHSANALYSE nach § 14 PatG / Art. 69 EPÜ mit Auslegungsprotokoll + BGH-Rspr. zur äquivalenten Verletzung (gleichwirkend, auffindbar, gleichwertig)

2. VERLETZUNGSRISIKO: Welche eigenen Produktionsprozesse könnten das Patent verletzen?

3. RECHTSBESTÄNDIGKEIT: Nichtigkeitsrisiko nach § 22 PatG (fehlende Patentfähigkeit, unzureichende Offenbarung, unzulässige Erweiterung)

4. FREEDOM-TO-OPERATE: Sind geplante Produktionen durch fremde Patente blockiert?

5. STRATEGISCHE OPTIONEN: Zeige ALLE sinnvollen Optionen auf (keine feste Anzahl). Für jede Option: juristische_vorteile (array), juristische_nachteile (array), folgen (kurzfristig/mittelfristig/langfristig), reaktionsszenarien (array mit szenario, reaktion), ist_illegal (bool), strafen (falls illegal).
Lizenzierung, Blockadestrategie, Sperrpatente, Opt-out UPC (7-Jahre-Übergangsfrist EPÜ), FRAND-Verpflichtung (Huawei/ZTE, Sisvel/Haier). FALLS es illegale Wege gibt (z.B. Patentverletzung in Kauf nehmen, Reverse Engineering ohne Lizenz) — aufzeigen mit ist_illegal=true und Strafen.

6. STANDARDESSENTIELLE PATENTE: FRAND-Analyse falls anwendbar

7. MITARBEITERERFINDUNGEN: § 9 ArbNErfG — Vergütungspflichten?

8. EXPORTKONTROLLE: Dual-Use-VO EU, § AWG falls technologietransfer-relevant

9. LIZENZVERTRAG: TTGVO (Technologietransfer-Gruppenfreistellungsverordnung), Art. 101 AEUV

Liefere konkrete quantitative Bewertungen (Verletzungswahrscheinlichkeit %, Nichtigkeitsrisiko %).`,
      response_json_schema: {
        type: "object",
        properties: {
          schutzbereich: { type: "object", properties: {
            zusammenfassung: { type: "string" },
            hauptansprueche: { type: "array", items: { type: "string" } },
            aequivalenzrisiko: { type: "string" }
          }},
          verletzungsrisiko: { type: "object", properties: {
            wahrscheinlichkeit_pct: { type: "number" },
            bewertung: { type: "string" },
            gefaehrdete_prozesse: { type: "array", items: { type: "string" } },
            nicht_betroffene_bereiche: { type: "array", items: { type: "string" } }
          }},
          rechtsbestaendigkeit: { type: "object", properties: {
            nichtigkeitsrisiko_pct: { type: "number" },
            schwachstellen: { type: "array", items: { type: "string" } },
            staerken: { type: "array", items: { type: "string" } }
          }},
          freedom_to_operate: { type: "object", properties: {
            status: { type: "string" },
            blockierende_patente: { type: "array", items: { type: "string" } },
            handlungsoptionen: { type: "array", items: { type: "string" } }
          }},
          strategische_optionen: { type: "array", items: { type: "object", properties: {
            option: { type: "string" },
            beschreibung: { type: "string" },
            empfehlung_score: { type: "number" },
            kosten_indikation: { type: "string" },
            zeithorizont: { type: "string" },
            ist_illegal: { type: "boolean" },
            strafen: { type: "string" },
            juristische_vorteile: { type: "array", items: { type: "string" } },
            juristische_nachteile: { type: "array", items: { type: "string" } },
            folgen: { type: "object", properties: { kurzfristig: { type: "string" }, mittelfristig: { type: "string" }, langfristig: { type: "string" } } },
            reaktionsszenarien: { type: "array", items: { type: "object", properties: { szenario: { type: "string" }, reaktion: { type: "string" } } } }
          }}},
          frand_analyse: { type: "object", properties: {
            relevant: { type: "boolean" },
            bewertung: { type: "string" }
          }},
          schadensberechnung: { type: "object", properties: {
            methode_1_entgangener_gewinn: { type: "string" },
            methode_2_lizenzanalogie: { type: "string" },
            methode_3_verletzergewinn: { type: "string" },
            empfohlene_methode: { type: "string" }
          }},
          upc_opt_out: { type: "object", properties: {
            empfehlung: { type: "string" },
            begruendung: { type: "string" }
          }},
          sofortmassnahmen: { type: "array", items: { type: "string" } }
        }
      },
      file_urls: patentDocs.length > 0 ? patentDocs.map(d => d.url) : undefined,
      model: "claude_sonnet_4_6"
    });
    setResult(r);
    await onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), patent_analyse: r, eigene_produktion: eigeneProduktion, patent_nummern: patentNummern } });
    setAnalysing(false);
  };

  const ScoreRing = ({ pct, color, label }) => {
    const r = 22, circ = 2 * Math.PI * r;
    const c = pct >= 70 ? "#B81C3A" : pct >= 40 ? "#FF9500" : "#1DB954";
    return (
      <div style={{ textAlign: "center" }}>
        <svg width={52} height={52}>
          <circle cx={26} cy={26} r={r} fill="none" stroke="rgba(0,0,0,0.07)" strokeWidth={5} />
          <circle cx={26} cy={26} r={r} fill="none" stroke={color || c} strokeWidth={5}
            strokeDasharray={circ} strokeDashoffset={circ * (1 - pct / 100)}
            strokeLinecap="round" style={{ transform: "rotate(-90deg)", transformOrigin: "26px 26px" }} />
          <text x="26" y="30" textAnchor="middle" fontSize="12" fontWeight="800" fill={color || c}>{pct}%</text>
        </svg>
        <p style={{ fontSize: 9, color: "#888", marginTop: 2, fontWeight: 600, textTransform: "uppercase" }}>{label}</p>
      </div>
    );
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 18, ...SF }}>
      <div style={{ textAlign: "center", padding: "8px 0 2px" }}>
        <p style={{ fontSize: 11, fontWeight: 700, color: "#FF9500", letterSpacing: "0.15em", textTransform: "uppercase" }}>Schritt 3 · Strategos</p>
        <h2 style={{ fontSize: 24, fontWeight: 700, color: "#1a1a1a", letterSpacing: "-0.5px", marginTop: 4 }}>Patent- & Technologieanalyse</h2>
        <p style={{ fontSize: 12, color: "#888", marginTop: 3 }}>Schutzbereich · Verletzungsrisiko · Freedom-to-Operate · Strategische Optionen</p>
      </div>

      {/* Patent-Dokumente */}
      <AppleCard title="A · Patentdokumente & Nummern" accentColor="#FF9500" action={
        <label style={{ cursor: "pointer" }}>
          <input type="file" multiple accept=".pdf,.docx,.txt" onChange={handleUpload} style={{ display: "none" }} />
          <span style={{ display: "inline-flex", alignItems: "center", gap: 6, padding: "7px 13px", fontSize: 12, fontWeight: 600, background: "#FF9500", color: "#fff", borderRadius: 10, cursor: "pointer" }}>
            <Upload style={{ width: 12, height: 12 }} /> {uploading ? "Lädt…" : "Patent hochladen"}
          </span>
        </label>
      }>
        <AppleField label="Patentnummern (kommagetrennt)">
          <AppleInput value={patentNummern} onChange={e => setPatentNummern(e.target.value)}
            onBlur={() => onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), patent_nummern: patentNummern } })}
            placeholder="z.B. DE10 2023 001234 A1, EP3456789 B1, US11234567 B2" />
        </AppleField>
        {patentDocs.length > 0 && (
          <div style={{ marginTop: 8, display: "flex", flexDirection: "column", gap: 5 }}>
            {patentDocs.map((d, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, padding: "6px 10px", background: "rgba(255,149,0,0.06)", borderRadius: 8 }}>
                <FileSearch style={{ width: 12, height: 12, color: "#FF9500" }} />
                <p style={{ fontSize: 11, color: "#1a1a1a", flex: 1 }}>{d.name}</p>
                <button onClick={() => { const n = patentDocs.filter((_, j) => j !== i); setPatentDocs(n); onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), patent_docs: n } }); }} style={{ background: "none", border: "none", cursor: "pointer", color: "#ccc", fontSize: 11 }}>✕</button>
              </div>
            ))}
          </div>
        )}
      </AppleCard>

      {/* Eigene Produktion */}
      <AppleCard title="B · Eigene Produktion / Produkt" accentColor="#636366">
        <AppleField label="Produktionsprozesse, Methoden, Materialien, Parameter (so detailliert wie möglich)">
          <AppleTextarea rows={5} value={eigeneProduktion} onChange={e => setEigeneProduktion(e.target.value)}
            onBlur={() => onSave({ ki_analyse: { ...(scenario.ki_analyse || {}), eigene_produktion: eigeneProduktion } })}
            placeholder="z.B. Herstellungsverfahren: Reaktionstemperatur 250°C, Katalysator: Palladium, Ausgangsstoff: Isopren. Verwendung in Produkt X für Markt Y. Bestehende eigene Schutzrechte: DE-Patent Nr. ..." />
        </AppleField>
      </AppleCard>

      {/* Analyse starten */}
      <AppleCard accentColor="#FF9500">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
          <div>
            <p style={{ fontSize: 13, fontWeight: 700, color: "#1a1a1a" }}>KI-Patentanalyse starten</p>
            <p style={{ fontSize: 11, color: "#888", marginTop: 2 }}>§ 14 PatG · Art. 69 EPÜ · FRAND · UPC Opt-out · Freedom-to-Operate</p>
          </div>
          <AppleButton onClick={analyse} disabled={analysing} variant="warning" icon={Sparkles}>
            {analysing ? "Analysiert…" : result ? "Neu analysieren" : "Analyse starten"}
          </AppleButton>
        </div>
      </AppleCard>

      {/* Ergebnis */}
      {result && (
        <>
          {/* Hauptkennzahlen */}
          <AppleCard title="Risikoübersicht" accentColor="#B81C3A">
            <div style={{ display: "flex", gap: 24, alignItems: "center", flexWrap: "wrap" }}>
              {result.verletzungsrisiko?.wahrscheinlichkeit_pct !== undefined && (
                <ScoreRing pct={result.verletzungsrisiko.wahrscheinlichkeit_pct} label="Verletzungsrisiko" />
              )}
              {result.rechtsbestaendigkeit?.nichtigkeitsrisiko_pct !== undefined && (
                <ScoreRing pct={result.rechtsbestaendigkeit.nichtigkeitsrisiko_pct} color="#FF9500" label="Nichtigkeitsrisiko" />
              )}
              <div style={{ flex: 1, minWidth: 160 }}>
                {result.verletzungsrisiko?.bewertung && <p style={{ fontSize: 12, color: "#333", lineHeight: 1.5, marginBottom: 6 }}>{result.verletzungsrisiko.bewertung}</p>}
                {result.freedom_to_operate?.status && (
                  <div style={{ padding: "6px 10px", background: "rgba(10,132,255,0.07)", borderRadius: 8 }}>
                    <p style={{ fontSize: 10, fontWeight: 700, color: "#0A84FF", textTransform: "uppercase", marginBottom: 2 }}>Freedom to Operate</p>
                    <p style={{ fontSize: 11, color: "#333" }}>{result.freedom_to_operate.status}</p>
                  </div>
                )}
              </div>
            </div>
          </AppleCard>

          {/* Schutzbereich */}
          {result.schutzbereich && (
            <AppleCard title="Schutzbereichsanalyse (§ 14 PatG / Art. 69 EPÜ)" accentColor="#5856D6">
              <p style={{ fontSize: 12, color: "#333", lineHeight: 1.5, marginBottom: 10 }}>{result.schutzbereich.zusammenfassung}</p>
              {result.schutzbereich.hauptansprueche?.length > 0 && (
                <div>
                  <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 6 }}>Hauptansprüche</p>
                  {result.schutzbereich.hauptansprueche.map((h, i) => (
                    <div key={i} style={{ fontSize: 11, color: "#333", padding: "5px 9px", background: "rgba(88,86,214,0.06)", borderRadius: 7, marginBottom: 4 }}>• {h}</div>
                  ))}
                </div>
              )}
              {result.schutzbereich.aequivalenzrisiko && (
                <div style={{ marginTop: 9, padding: "8px 10px", background: "rgba(255,149,0,0.07)", borderRadius: 8 }}>
                  <p style={{ fontSize: 10, fontWeight: 700, color: "#FF9500", textTransform: "uppercase", marginBottom: 3 }}>Äquivalenz-Risiko (BGH)</p>
                  <p style={{ fontSize: 11, color: "#333" }}>{result.schutzbereich.aequivalenzrisiko}</p>
                </div>
              )}
            </AppleCard>
          )}

          {/* Strategische Optionen */}
          {result.strategische_optionen?.length > 0 && (
            <AppleCard title="Strategische Optionen" accentColor="#1DB954">
              <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
                {result.strategische_optionen.sort((a, b) => (b.empfehlung_score || 0) - (a.empfehlung_score || 0)).map((o, i) => (
                  <div key={i} style={{ padding: "10px 13px", background: o.ist_illegal ? "rgba(184,28,58,0.06)" : "rgba(0,0,0,0.025)", borderRadius: 11, borderLeft: `3px solid ${o.ist_illegal ? "#B81C3A" : i
