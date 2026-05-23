
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Upload, FileUp, Sparkles, Trash2, AlertTriangle, CheckCircle, MinusCircle, Scale, Shield, FileSearch, BarChart3 } from "lucide-react";
import { AppleCard, AppleButton, ApplePill, AppleField, AppleTextarea, SF } from "../AppleCard";
import KlauselHeatmap from "../visualisierung/KlauselHeatmap";
import WirkungsBaum from "../visualisierung/WirkungsBaum";
import ZeitachseSzenarien from "../visualisierung/ZeitachseSzenarien";
import OptionenCards from "../visualisierung/OptionenCards";
import ChancenRisikoQuadrant from "../visualisierung/ChancenRisikoQuadrant";
import KlauselVergleich from "../visualisierung/KlauselVergleich";

const RISIKO_FARBEN = {
  kritisch: { bg: "rgba(184,28,58,0.08)", border: "rgba(184,28,58,0.25)", text: "#B81C3A", icon: AlertTriangle },
  hoch:     { bg: "rgba(255,149,0,0.08)", border: "rgba(255,149,0,0.25)", text: "#FF9500", icon: AlertTriangle },
  mittel:   { bg: "rgba(10,132,255,0.06)", border: "rgba(10,132,255,0.2)", text: "#0A84FF", icon: MinusCircle },
  niedrig:  { bg: "rgba(29,185,84,0.07)", border: "rgba(29,185,84,0.2)", text: "#1DB954", icon: CheckCircle },
  positiv:  { bg: "rgba(29,185,84,0.07)", border: "rgba(29,185,84,0.2)", text: "#1DB954", icon: CheckCircle },
};

function KlauselCard({ k, idx }) {
  const [open, setOpen] = useState(false);
  const cfg = RISIKO_FARBEN[k.risiko_stufe] || RISIKO_FARBEN.mittel;
  const Icon = cfg.icon;
  return (
    <div style={{ background: cfg.bg, border: `1px solid ${cfg.border}`, borderRadius: 14, overflow: "hidden", marginBottom: 8 }}>
      <div onClick={() => setOpen(!open)} style={{ padding: "11px 14px", cursor: "pointer", display: "flex", alignItems: "flex-start", gap: 10 }}>
        <Icon style={{ width: 15, height: 15, color: cfg.text, flexShrink: 0, marginTop: 2 }} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, flexWrap: "wrap" }}>
            <span style={{ fontSize: 12, fontWeight: 700, color: "#1a1a1a" }}>{k.klausel_typ || `Klausel ${idx + 1}`}</span>
            <ApplePill color={cfg.text}>{k.risiko_stufe || "mittel"}</ApplePill>
            {k.norm && <span style={{ fontSize: 10, fontFamily: "monospace", color: "#666", background: "rgba(0,0,0,0.06)", padding: "2px 6px", borderRadius: 5 }}>{k.norm}</span>}
          </div>
          <p style={{ fontSize: 11, color: "#555", marginTop: 4, lineHeight: 1.4 }}>{k.kurzbeschreibung}</p>
        </div>
        <span style={{ fontSize: 14, color: "#bbb", flexShrink: 0 }}>{open ? "▲" : "▼"}</span>
      </div>
      {open && (
        <div style={{ padding: "0 14px 13px", borderTop: `1px solid ${cfg.border}` }}>
          {k.rechtliche_mechanik && (
            <div style={{ marginTop: 10 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 4 }}>Rechtliche Mechanik</p>
              <p style={{ fontSize: 12, color: "#333", lineHeight: 1.5 }}>{k.rechtliche_mechanik}</p>
            </div>
          )}
          {(k.juristische_vorteile?.length > 0 || k.juristische_nachteile?.length > 0) && (
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginTop: 10 }}>
              {k.juristische_vorteile?.length > 0 && (
                <div style={{ padding: "7px 10px", background: "rgba(29,185,84,0.07)", borderRadius: 8 }}>
                  <p style={{ fontSize: 9, fontWeight: 700, color: "#1DB954", textTransform: "uppercase", marginBottom: 4 }}>Juristische Vorteile</p>
                  {k.juristische_vorteile.map((v, i) => <p key={i} style={{ fontSize: 10, color: "#333", marginBottom: 2 }}>+ {v}</p>)}
                </div>
              )}
              {k.juristische_nachteile?.length > 0 && (
                <div style={{ padding: "7px 10px", background: "rgba(184,28,58,0.07)", borderRadius: 8 }}>
                  <p style={{ fontSize: 9, fontWeight: 700, color: "#B81C3A", textTransform: "uppercase", marginBottom: 4 }}>Juristische Nachteile</p>
                  {k.juristische_nachteile.map((v, i) => <p key={i} style={{ fontSize: 10, color: "#333", marginBottom: 2 }}>− {v}</p>)}
                </div>
              )}
            </div>
          )}
          {k.illegale_umgehung && (
            <div style={{ marginTop: 10, padding: "9px 12px", background: "rgba(184,28,58,0.08)", border: "2px solid rgba(184,28,58,0.4)", borderRadius: 9 }}>
              <p style={{ fontSize: 10, fontWeight: 800, color: "#B81C3A", textTransform: "uppercase", marginBottom: 4 }}>⚠ ILLEGALE UMGEHUNGSMÖGLICHKEIT — NUR ZUR INFORMATION</p>
              <p style={{ fontSize: 11, color: "#B81C3A" }}>{k.illegale_umgehung}</p>
            </div>
          )}
          {k.szenarien?.length > 0 && (
            <div style={{ marginTop: 10 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 5 }}>Szenario-Projektionen & Reaktionsempfehlungen</p>
              {k.szenarien.map((s, i) => (
                <div key={i} style={{ padding: "7px 10px", background: "rgba(0,0,0,0.03)", borderRadius: 8, marginBottom: 4 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 3 }}>
                    <span style={{ fontSize: 10, fontWeight: 700, color: s.horizont === "kurzfristig" ? "#FF3B30" : s.horizont === "mittelfristig" ? "#FF9500" : "#34C759", textTransform: "uppercase" }}>{s.horizont}</span>
                    {s.eintrittsbedingung && <span style={{ fontSize: 10, color: "#888" }}>→ wenn: {s.eintrittsbedingung}</span>}
                  </div>
                  <p style={{ fontSize: 11, color: "#333", marginBottom: s.empfohlene_reaktion ? 4 : 0 }}>{s.beschreibung}</p>
                  {s.empfohlene_reaktion && (
                    <div style={{ padding: "4px 8px", background: "rgba(29,185,84,0.08)", borderRadius: 6, borderLeft: "2px solid #1DB954" }}>
                      <p style={{ fontSize: 10, color: "#1DB954", fontWeight: 600 }}>Empfohlene Reaktion: {s.empfohlene_reaktion}</p>
                    </div>
                  )}
                  {s.chancen && <p style={{ fontSize: 10, color: "#1DB954", marginTop: 3 }}>+ {s.chancen}</p>}
                  {s.risiken && <p style={{ fontSize: 10, color: "#B81C3A", marginTop: 2 }}>− {s.risiken}</p>}
                </div>
              ))}
            </div>
          )}
          {k.verhandlungsempfehlung && (
            <div style={{ marginTop: 10, padding: "8px 11px", background: "rgba(29,185,84,0.08)", borderRadius: 9, borderLeft: "3px solid #1DB954" }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: "#1DB954", textTransform: "uppercase", marginBottom: 3 }}>Verhandlungsempfehlung</p>
              <p style={{ fontSize: 11, color: "#333" }}>{k.verhandlungsempfehlung}</p>
              {k.alternativ_formulierung && (
                <div style={{ marginTop: 6, padding: "6px 9px", background: "rgba(255,255,255,0.7)", borderRadius: 7, fontFamily: "monospace", fontSize: 11, color: "#1DB954" }}>
                  📝 {k.alternativ_formulierung}
                </div>
              )}
            </div>
          )}
          {k.durchsetzbarkeit && (
            <p style={{ fontSize: 10, marginTop: 8, color: "#888" }}>⚖ Durchsetzbarkeit: <strong style={{ color: k.durchsetzbar ? "#1DB954" : "#FF3B30" }}>{k.durchsetzbar ? "Durchsetzbar" : "Angreifbar"}</strong> — {k.durchsetzbarkeit}</p>
          )}
        </div>
      )}
    </div>
  );
}

const VIZ_TABS = [
  { id: "heatmap",   label: "01 · Heatmap",       icon: "🔥", desc: "Wo liegt das Risiko?" },
  { id: "wirkung",   label: "02 · Wirkungsbaum",  icon: "🌳", desc: "Wie wirkt die Klausel?" },
  { id: "zeitachse", label: "03 · Zeitachse",     icon: "⏱", desc: "Wann wird sie scharf?" },
  { id: "optionen",  label: "04 · Optionen",      icon: "⚖️", desc: "Was kann ich tun?" },
  { id: "quadrant",  label: "05 · Quadrant",      icon: "📊", desc: "Gesamtportfolio?" },
  { id: "vergleich", label: "10 · Vorher/Nachher", icon: "✏️", desc: "Wie neu formulieren?" },
];

// KI-Prompts pro Visualisierungsformat
const VIZ_PROMPTS = {
  heatmap: (klauseln, klausel, ctx) => ({
    prompt: `Du bist ein Senior-Vertragsrechtler. Analysiere die folgenden Klauseln speziell für eine Risiko-Heatmap-Darstellung. Vergib für jede Klausel einen präzisen Risiko-Score (0-10), begründe die Einstufung und priorisiere nach Handlungsbedarf für das Unternehmen.

Unternehmenskontext: ${ctx.unternehmen_name || "—"} (${ctx.branche || "—"})
Klauseln: ${klauseln.map(k => `${k.klausel_typ} [${k.risiko_stufe}]: ${k.kurzbeschreibung}`).join("\n")}

Erstelle für JEDE Klausel eine Heatmap-Bewertung: exakter Score, Hauptrisiko in einem Satz, sofortiger Handlungsbedarf (ja/nein) und Priorität (1=höchste).`,
    response_json_schema: {
      type: "object",
      properties: {
        bewertungen: { type: "array", items: { type: "object", properties: {
          klausel_typ: { type: "string" },
          score: { type: "number" },
          hauptrisiko: { type: "string" },
          sofortiger_handlungsbedarf: { type: "boolean" },
          prioritaet: { type: "number" },
          ki_hinweis: { type: "string" }
        }}},
        gesamt_heatmap_fazit: { type: "string" },
        top3_kritische_klauseln: { type: "array", items: { type: "string" } }
      }
    }
  }),

  wirkung: (klauseln, klausel, ctx) => ({
    prompt: `Du bist Unternehmensberater und Vertragsrechtler. Analysiere die Klausel "${klausel?.klausel_typ}" speziell für einen Wirkungsbaum: Wie wirkt diese Klausel konkret ins Unternehmen hinein? Welche Abteilungen, Prozesse, Finanzen und strategischen Ziele sind betroffen?

Klausel: ${klausel?.klausel_typ}
Beschreibung: ${klausel?.kurzbeschreibung}
Mechanik: ${klausel?.rechtliche_mechanik || "—"}
Unternehmen: ${ctx.unternehmen_name || "—"} (${ctx.branche || "—"}, Umsatz ${ctx.umsatz ? (ctx.umsatz/1e6).toFixed(1)+"Mio. EUR" : "unbekannt"})

Erstelle konkrete Wirkungspfade mit quantifizierten Auswirkungen (in EUR wo möglich).`,
    response_json_schema: {
      type: "object",
      properties: {
        wirkungspfade: { type: "array", items: { type: "object", properties: {
          bereich: { type: "string" },
          beschreibung: { type: "string" },
          finanzieller_einfluss_eur: { type: "number" },
          zeitrahmen: { type: "string" },
          positiv: { type: "boolean" },
          betroffene_abteilungen: { type: "array", items: { type: "string" } }
        }}},
        gesamteinfluss_eur: { type: "number" },
        kritischster_pfad: { type: "string" },
        empfehlung: { type: "string" }
      }
    }
  }),

  zeitachse: (klauseln, klausel, ctx) => ({
    prompt: `Du bist ein strategischer Rechtsberater. Analysiere die Klausel "${klausel?.klausel_typ}" speziell für eine Zeitachse: Wann und unter welchen Bedingungen wird diese Klausel scharf? Welche konkreten Trigger-Ereignisse gibt es in welchem Zeitraum?

Klausel: ${klausel?.klausel_typ} [${klausel?.risiko_stufe}]
Beschreibung: ${klausel?.kurzbeschreibung}
Vorhandene Szenarien: ${JSON.stringify(klausel?.szenarien || [])}
Kontext: ${ctx.sachverhalt_lang?.slice(0, 200) || "—"}

Erstelle eine präzise Zeitachsen-Analyse mit konkreten Meilensteinen, Wahrscheinlichkeiten und Frühwarnsignalen.`,
    response_json_schema: {
      type: "object",
      properties: {
        meilensteine: { type: "array", items: { type: "object", properties: {
          zeitpunkt: { type: "string" },
          ereignis: { type: "string" },
          trigger: { type: "string" },
          wahrscheinlichkeit_pct: { type: "number" },
          handlungsfenster_tage: { type: "number" },
          kritisch: { type: "boolean" }
        }}},
        fruehwarnsignale: { type: "array", items: { type: "string" } },
        kritischer_zeitpunkt: { type: "string" },
        empfohlene_ueberwachung: { type: "string" }
      }
    }
  }),

  optionen: (klauseln, klausel, ctx) => ({
    prompt: `Du bist ein strategischer Verhandlungsexperte und Senior-Anwalt. Analysiere die Klausel "${klausel?.klausel_typ}" und erarbeite alle konkreten Handlungsoptionen — von der einfachsten Akzeptanz bis zum Klauselangriff. Jede Option soll realistisch, mit Kosten, Wahrscheinlichkeit und strategischem Wert bewertet sein.

Klausel: ${klausel?.klausel_typ} [Risiko: ${klausel?.risiko_stufe}]
${klausel?.kurzbeschreibung}
Verhandlungsempfehlung bisher: ${klausel?.verhandlungsempfehlung || "—"}
Durchsetzbar: ${klausel?.durchsetzbar ? "Ja" : "Nein"} — ${klausel?.durchsetzbarkeit || "—"}
Unternehmen: ${ctx.unternehmen_name || "—"} (Gegenpartei: ${ctx.gegner_name || "—"})

Erstelle 4-6 differenzierte Optionen von konservativ bis aggressiv.`,
    response_json_schema: {
      type: "object",
      properties: {
        optionen: { type: "array", items: { type: "object", properties: {
          id: { type: "string" },
          titel: { type: "string" },
          beschreibung: { type: "string" },
          vorgehen: { type: "string" },
          kosten_eur: { type: "number" },
          kosten_label: { type: "string" },
          wahrscheinlichkeit_pct: { type: "number" },
          strategischer_wert: { type: "string" },
          zeitaufwand: { type: "string" },
          empfohlen: { type: "boolean" },
          risiken: { type: "array", items: { type: "string" } }
        }}},
        beste_option_begruendung: { type: "string" },
        verhandlungsstrategie: { type: "string" }
      }
    }
  }),

  quadrant: (klauseln, klausel, ctx) => ({
    prompt: `Du bist ein Portfolio-Risikostratege. Analysiere ALLE Klauseln dieses Vertrags für eine Chancen-Risiken-Portfolio-Analyse. Positioniere jede Klausel im Quadrant nach Eintrittswahrscheinlichkeit und Wirkungstiefe.

Unternehmen: ${ctx.unternehmen_name || "—"} (${ctx.branche || "—"})
Alle Klauseln:
${klauseln.map(k => `- ${k.klausel_typ} [${k.risiko_stufe}]: ${k.kurzbeschreibung?.slice(0, 80)}`).join("\n")}

Gib für jede Klausel: genaue Koordinaten (x=Wahrscheinlichkeit 0-100, y=Wirkungstiefe 0-10), Quadrant-Kategorie und strategische Einordnung. Leite daraus Portfolio-Empfehlungen ab.`,
    response_json_schema: {
      type: "object",
      properties: {
        portfolio: { type: "array", items: { type: "object", properties: {
          klausel_typ: { type: "string" },
          x_wahrscheinlichkeit: { type: "number" },
          y_wirkungstiefe: { type: "number" },
          quadrant: { type: "string" },
          strategische_einordnung: { type: "string" },
          sofortmassnahme: { type: "string" }
        }}},
        portfolio_fazit: { type: "string" },
        top_prioritaet: { type: "string" },
        gesamtrisiko_score: { type: "number" }
      }
    }
  }),

  vergleich: (klauseln, klausel, ctx) => ({
    prompt: `Du bist ein Vertragsformulierungsexperte und Senior-Anwalt für Vertragsrecht. Erstelle für die Klausel "${klausel?.klausel_typ}" eine professionelle Vorher-Nachher-Analyse: IST-Formulierung mit allen Risiken, und optimierte SOLL-Formulierung die die Risiken minimiert aber wirtschaftlich realistisch ist.

IST-Klausel: ${klausel?.klausel_typ}
Beschreibung: ${klausel?.kurzbeschreibung}
Risiko: ${klausel?.risiko_stufe}
Bisherige Nachteile: ${(klausel?.juristische_nachteile || []).join("; ")}
Bisherige Verhandlungsempfehlung: ${klausel?.verhandlungsempfehlung || "—"}
Bisherige Alternativformulierung: ${klausel?.alternativ_formulierung || "—"}
Gegenpartei: ${ctx.gegner_name || "—"} (${ctx.gegner_rolle || "—"})

Erstelle eine vollständige, juristisch präzise Neuformulierung mit Begründung und Verhandlungsstrategie.`,
    response_json_schema: {
      type: "object",
      properties: {
        ist_formulierung: { type: "string" },
        ist_probleme: { type: "array", items: { type: "string" } },
        soll_formulierung: { type: "string" },
        soll_vorteile: { type: "array", items: { type: "string" } },
        risiko_reduktion_pct: { type: "number" },
        verhandlungsargument: { type: "string" },
        gegner_einwand: { type: "string" },
        kompromiss_formulierung: { type: "string" },
        rechtliche_grundlage: { type: "string" }
      }
    }
  }),
};

function KlauselSelector({ sorted, selectedIdx, onChange }) {
  return (
    <div style={{ marginBottom: 12 }}>
      <p style={{ fontSize: 9, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 6 }}>Klausel auswählen</p>
      <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
        {sorted.map((k, i) => {
          const color = { kritisch: "#B81C3A", hoch: "#FF9500", mittel: "#0A84FF", niedrig: "#1DB954", positiv: "#1DB954" }[k.risiko_stufe] || "#888";
          return (
            <button key={i} onClick={() => onChange(i)}
              style={{
                padding: "4px 10px", borderRadius: 7,
                border: `1px solid ${selectedIdx === i ? color : "rgba(0,0,0,0.1)"}`,
                background: selectedIdx === i ? `${color}15` : "rgba(0,0,0,0.02)",
                color: selectedIdx === i ? color : "#666",
                fontSize: 11, fontWeight: selectedIdx === i ? 700 : 500,
                cursor: "pointer",
              }}>
              {k.klausel_typ || `Klausel ${i + 1}`}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export default function Step2VertragsAnalyse({ scenario, onSave }) {
  const ctx = scenario.unternehmenskontext || {};
  const ki = scenario.ki_analyse || {};
  const [result, setResult] = useState(ki.vertrags_analyse || null);
  const [analysing, setAnalysing] = useState(false);
  const [activeViz, setActiveViz] = useState("heatmap");
  const [vizResult, setVizResult] = useState({});
  const [vizLoading, setVizLoading] = useState({});
  const [selectedKlauselIdx, setSelectedKlauselIdx] = useState(0);

  const klauseln = result?.kritische_klauseln || [];
  const sorted = [...klauseln].sort((a, b) => {
    const order = { kritisch: 0, hoch: 1, mittel: 2, niedrig: 3, positiv: 4 };
    return (order[a.risiko_stufe] ?? 2) - (order[b.risiko_stufe] ?? 2);
  });
  const selectedKlausel = sorted[selectedKlauselIdx] || null;

  const analyse = async () => {
    setAnalysing(true);
    try {
      const r = await base44.integrations.Core.InvokeLLM({
        prompt: `Du bist Senior-Partner einer Großkanzlei für Vertragsrecht. Analysiere den folgenden Vertrag aus juristisch-strategischer Sicht.

Unternehmen: ${ctx.unternehmen_name} (${ctx.rechtsform}, ${ctx.branche})
Gegner: ${ctx.gegner_name || "—"} (${ctx.gegner_rolle || "—"})
Sachverhalt: ${ctx.sachverhalt_lang?.slice(0, 500) || "—"}
Dokumente: ${(scenario.ki_kontext?.dokument_typen || []).join(", ") || "—"}

Analysiere alle kritischen Klauseln, deren Risiken, Szenarien und Verhandlungsempfehlungen.`,
        response_json_schema: {
          type: "object",
          properties: {
            kritische_klauseln: { type: "array", items: { type: "object", properties: {
              klausel_typ: { type: "string" },
              risiko_stufe: { type: "string" },
              kurzbeschreibung: { type: "string" },
              rechtliche_mechanik: { type: "string" },
              norm: { type: "string" },
              juristische_vorteile: { type: "array", items: { type: "string" } },
              juristische_nachteile: { type: "array", items: { type: "string" } },
              szenarien: { type: "array", items: { type: "object", properties: {
                horizont: { type: "string" },
                beschreibung: { type: "string" },
                eintrittsbedingung: { type: "string" },
                empfohlene_reaktion: { type: "string" },
                chancen: { type: "string" },
                risiken: { type: "string" }
              }}},
              verhandlungsempfehlung: { type: "string" },
              alternativ_formulierung: { type: "string" },
              durchsetzbarkeit: { type: "string" },
              durchsetzbar: { type: "boolean" },
              illegale_umgehung: { type: "string" }
            }}},
            gesamtbewertung: { type: "string" },
            vertragstyp: { type: "string" },
            risiko_index: { type: "number" },
            top_prioritaet: { type: "string" }
          }
        },
        model: "claude_sonnet_4_6"
      });
      setResult(r);
      await onSave({ ki_analyse: { ...ki, vertrags_analyse: r } });
    } catch (err) {
      console.error("Vertragsanalyse fehlgeschlagen", err);
    } finally {
      setAnalysing(false);
    }
  };

  const runViz = async (vizId) => {
    if (!result || klauseln.length === 0) return;
    setVizLoading(v => ({ ...v, [vizId]: true }));
    try {
      const promptCfg = VIZ_PROMPTS[vizId]?.(sorted, selectedKlausel, ctx);
      if (!promptCfg) return;
      const r = await base44.integrations.Core.InvokeLLM(promptCfg);
      setVizResult(v => ({ ...v, [vizId]: r }));
    } catch (err) {
      console.error("Viz-Analyse fehlgeschlagen", err);
    } finally {
      setVizLoading(v => ({ ...v, [vizId]: false }));
    }
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16, ...SF }}>
      <div style={{ textAlign: "center", paddingBottom: 4 }}>
        <p style={{ fontSize: 11, fontWeight: 700, color: "#0A84FF", letterSpacing: "0.15em", textTransform: "uppercase" }}>Schritt 3 · Strategos</p>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: "#1a1a1a", letterSpacing: "-0.4px", marginTop: 4 }}>Vertragsanalyse</h2>
        <p style={{ fontSize: 12, color: "#888", marginTop: 3 }}>Klausel-Risiko · Szenarioprojektion · Visualisierungen</p>
      </div>

      <AppleCard accentColor="#0A84FF" action={
        <AppleButton onClick={analyse} disabled={analysing} variant="blue" icon={Sparkles}>
          {analysing ? "Analysiert…" : result ? "Neu analysieren" : "Analyse starten"}
        </AppleButton>
      }>
        <p style={{ fontSize: 13, color: "#1a1a1a" }}>
          {result
            ? `${klauseln.length} Klauseln analysiert · Risiko-Index: ${result.risiko_index ?? "—"}/10 · Typ: ${result.vertragstyp || "—"}`
            : "Klicke auf Analyse starten, um den Vertrag zu untersuchen."}
        </p>
        {result?.gesamtbewertung && (
          <p style={{ fontSize: 11, color: "#666", marginTop: 6, lineHeight: 1.5 }}>{result.gesamtbewertung}</p>
        )}
      </AppleCard>

      {result && klauseln.length > 0 && (
        <>
          {/* Klausel-Liste */}
          <AppleCard title="Kritische Klauseln" accentColor="#B81C3A">
            {sorted.map((k, i) => <KlauselCard key={i} k={k} idx={i} />)}
          </AppleCard>

          {/* Visualisierungen */}
          <AppleCard title="Visualisierungen & KI-Tiefenanalysen" accentColor="#5856D6">
            <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 12 }}>
              {VIZ_TABS.map(v => (
                <button key={v.id} onClick={() => setActiveViz(v.id)}
                  style={{
                    padding: "5px 11px", borderRadius: 8,
                    border: `1px solid ${activeViz === v.id ? "#5856D6" : "rgba(0,0,0,0.1)"}`,
                    background: activeViz === v.id ? "rgba(88,86,214,0.1)" : "rgba(0,0,0,0.02)",
                    color: activeViz === v.id ? "#5856D6" : "#666",
                    fontSize: 11, fontWeight: activeViz === v.id ? 700 : 500, cursor: "pointer"
                  }}>
                  {v.icon} {v.label}
                </button>
              ))}
            </div>

            {["heatmap", "quadrant", "wirkung", "zeitachse", "vergleich"].includes(activeViz) && (
              <KlauselSelector sorted={sorted} selectedIdx={selectedKlauselIdx} onChange={setSelectedKlauselIdx} />
            )}

            <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 10 }}>
              <AppleButton onClick={() => runViz(activeViz)} disabled={vizLoading[activeViz]} variant="violet" icon={Sparkles}>
                {vizLoading[activeViz] ? "Analysiert…" : "KI-Analyse für diese Ansicht"}
              </AppleButton>
            </div>

            {vizResult[activeViz] ? (
              <div style={{ padding: "12px", background: "rgba(88,86,214,0.04)", borderRadius: 12 }}>
                <pre style={{ fontSize: 11, color: "#333", whiteSpace: "pre-wrap", lineHeight: 1.5 }}>
                  {JSON.stringify(vizResult[activeViz], null, 2)}
                </pre>
              </div>
            ) : (
              <p style={{ fontSize: 11, color: "#aaa", textAlign: "center", padding: "20px 0" }}>
                Klicke auf „KI-Analyse für diese Ansicht" um die {VIZ_TABS.find(v => v.id === activeViz)?.desc || "Analyse"} zu laden.
              </p>
            )}
          </AppleCard>
        </>
      )}
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );
}
}
}
