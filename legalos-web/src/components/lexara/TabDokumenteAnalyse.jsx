
import { useState, useRef, useEffect, useCallback } from "react";
import { base44 } from "@/api/base44Client";
import { uploadFile } from "@/lib/kiProvider";
import { Upload, Loader2, X, Check, AlertCircle, FileText, Image, Film, File, ChevronDown, ChevronUp, RefreshCw, Info, ArrowRight } from "lucide-react";

const FILE_ACCEPT = "*/*";

// ── STEP MAPPING: was wird wo in Lexara eingetragen ─────────────────────────
const STEP_MAP = [
  {
    num: 1, label: "Fallerfassung — Basisdaten", color: "#34C759",
    wo: "Tab 1 › Basisdaten",
    felder: ["Gericht", "Aktenzeichen", "Rechtsgebiet", "Instanz", "Prozessziel", "Zentrale Rechtsfrage", "Streitwert"],
    hinweis: "Nur wenn Feld noch leer — kein Überschreiben",
    getItems: r => [
      r?.basisdaten?.gericht && `Gericht: ${r.basisdaten.gericht}`,
      r?.basisdaten?.aktenzeichen && `AZ: ${r.basisdaten.aktenzeichen}`,
      r?.basisdaten?.rechtsgebiet && `Rechtsgebiet: ${r.basisdaten.rechtsgebiet}`,
      r?.basisdaten?.prozessziel && `Prozessziel: ${r.basisdaten.prozessziel}`,
      r?.basisdaten?.instanz && `Instanz: ${r.basisdaten.instanz}`,
      r?.streitwert && `Streitwert: ${Number(r.streitwert).toLocaleString()} €`,
    ].filter(Boolean),
    isCovered: r => !!(r?.basisdaten?.gericht || r?.basisdaten?.aktenzeichen || r?.basisdaten?.rechtsgebiet || r?.streitwert),
  },
  {
    num: 2, label: "Fallsubstanz", color: "#007AFF",
    wo: "Tab 2 › Argumente, Beweise, Fristen, Personen",
    felder: ["Argumente (eigen/gegner)", "Beweise → Quelle = Dokument", "Fristen mit Datum", "Beteiligte Personen"],
    hinweis: "Beweise werden dem Dokument als Quelle zugeordnet, aber nicht automatisch Argumenten verknüpft (→ Tab 2 › Verkettung)",
    getItems: r => {
      const args = r?.argumente || [];
      const bew = r?.beweise || [];
      const fri = r?.fristen || [];
      const per = r?.personen || [];
      if (!args.length && !bew.length && !fri.length && !per.length) return [];
      return [
        args.length && `${args.length} Argumente (${args.filter(a => a.seite === "eigen").length} eigene, ${args.filter(a => a.seite === "gegner").length} Gegner)`,
        bew.length && `${bew.length} Beweise`,
        fri.length && `${fri.length} Fristen`,
        per.length && `${per.length} Personen`,
      ].filter(Boolean);
    },
    getDetails: r => [
      ...(r?.argumente || []).map(a => `${a.seite === "gegner" ? "⚔" : "✓"} ${a.titel}`),
      ...(r?.beweise || []).map(b => `📎 ${b.titel}`),
      ...(r?.fristen || []).map(f => `📅 ${f.titel}${f.datum ? ` (${f.datum})` : ""}`),
      ...(r?.personen || []).map(p => `👤 ${p.name}${p.rolle ? ` — ${p.rolle}` : ""}`),
    ],
    isCovered: r => !!(r?.argumente?.length || r?.beweise?.length || r?.personen?.length || r?.fristen?.length),
  },
  {
    num: 3, label: "Gegneranalyse", color: "#FF3B30",
    wo: "Tab 3 › Gegner-Profil (Feld: gegner_profil)",
    felder: ["Gegner-Strategie / Profil", "Erkannte Taktiken", "Schwachstellen des Gegners"],
    hinweis: "Wird in Case.gegner_profil gespeichert und unter Tab 3 sichtbar",
    getItems: r => {
      const g = r?.schritt3_gegneranalyse;
      if (!g?.zusammenfassung) return [];
      return [
        g.zusammenfassung,
        g.taktiken?.length && `${g.taktiken.length} Taktiken erkannt`,
        g.schwachstellen?.length && `${g.schwachstellen.length} Schwachstellen`,
      ].filter(Boolean);
    },
    getDetails: r => [
      ...(r?.schritt3_gegneranalyse?.taktiken || []).map(t => `⚔ ${t}`),
      ...(r?.schritt3_gegneranalyse?.schwachstellen || []).map(s => `⚠ ${s}`),
    ],
    isCovered: r => !!(r?.schritt3_gegneranalyse?.zusammenfassung || r?.argumente?.some(a => a.seite === "gegner")),
  },
  {
    num: 4, label: "Rechtliche Analyse", color: "#FF9500",
    wo: "Tab 4 › Compliance, Streitwert, Präzedenzfälle",
    felder: ["Relevante Paragrafen / Gesetze", "Präzedenzfälle", "Compliance-Risiken", "Streitwert"],
    hinweis: "Informiert Tab 4 inhaltlich; Streitwert wird in Basisdaten gespeichert",
    getItems: r => {
      const g = r?.schritt4_rechtliche_analyse;
      return [
        g?.zusammenfassung,
        g?.relevante_paragrafen?.length && `${g.relevante_paragrafen.length} Paragrafen`,
        g?.praezedenzfaelle?.length && `${g.praezedenzfaelle.length} Präzedenzfälle`,
        g?.compliance_risiken?.length && `${g.compliance_risiken.length} Compliance-Risiken`,
      ].filter(Boolean);
    },
    getDetails: r => [
      ...(r?.schritt4_rechtliche_analyse?.relevante_paragrafen || []).map(p => `§ ${p}`),
      ...(r?.schritt4_rechtliche_analyse?.praezedenzfaelle || []).map(p => `⚖ ${p}`),
      ...(r?.schritt4_rechtliche_analyse?.compliance_risiken || []).map(c => `⚠ ${c}`),
    ],
    isCovered: r => !!(r?.schritt4_rechtliche_analyse?.zusammenfassung || r?.streitwert),
  },
  {
    num: 5, label: "Strategie", color: "#5856D6",
    wo: "Tab 5 › Fallnotizen (Case.notes)",
    felder: ["Empfohlene Prozessstrategie", "Stärken unserer Position", "Schwächen / Risiken"],
    hinweis: "Strategie-Erkenntnisse werden als Notiz zu Case.notes hinzugefügt",
    getItems: r => {
      const g = r?.schritt5_strategie;
      return [
        g?.empfohlene_strategie,
        g?.staerken?.length && `${g.staerken.length} Stärken identifiziert`,
        g?.schwaechen?.length && `${g.schwaechen.length} Schwächen identifiziert`,
      ].filter(Boolean);
    },
    getDetails: r => [
      ...(r?.schritt5_strategie?.staerken || []).map(s => `+ ${s}`),
      ...(r?.schritt5_strategie?.schwaechen || []).map(s => `– ${s}`),
    ],
    isCovered: r => !!(r?.schritt5_strategie?.empfohlene_strategie || r?.schritt5_strategie?.zusammenfassung),
  },
  {
    num: 6, label: "Risiko", color: "#FF2D55",
    wo: "Tab 6 › Risikoanalyse (Case.notes + ki_berater_result)",
    felder: ["Risiko-Level (gering/mittel/hoch)", "Konkrete Risiken", "Beweisprobleme"],
    hinweis: "Risiko-Zusammenfassung wird in Fallnotizen ergänzt",
    getItems: r => {
      const g = r?.schritt6_risiko;
      return [
        g?.risiko_level && `Risiko-Level: ${g.risiko_level}`,
        g?.zusammenfassung,
        g?.risiken?.length && `${g.risiken.length} Risiken erkannt`,
      ].filter(Boolean);
    },
    getDetails: r => (r?.schritt6_risiko?.risiken || []).map(ri => `⚠ ${ri}`),
    isCovered: r => !!(r?.schritt6_risiko?.zusammenfassung),
  },
  {
    num: 7, label: "Simulation", color: "#AF52DE",
    wo: "Tab 7 › Verhandlungssimulation (Case.ki_berater_result)",
    felder: ["Vergleichswert in €", "Prognose-Einfluss", "Verhandlungsszenarien"],
    hinweis: "Vergleichswert & Prognosehinweis werden in ki_berater_result gespeichert",
    getItems: r => {
      const g = r?.schritt7_simulation;
      return [
        g?.prognose_einfluss,
        g?.vergleichswert_eur && `Vergleichswert: ${Number(g.vergleichswert_eur).toLocaleString()} €`,
        g?.zusammenfassung,
      ].filter(Boolean);
    },
    getDetails: () => [],
    isCovered: r => !!(r?.schritt7_simulation?.zusammenfassung || r?.schritt7_simulation?.prognose_einfluss),
  },
  {
    num: 8, label: "Aktion / Schriftsätze", color: "#FF6B35",
    wo: "Tab 8 › Verhandlungsführung, Schriftsatz-Generator",
    felder: ["Nächste Handlungsschritte", "Einzureichende Dokumente", "Antwortfristen"],
    hinweis: "Handlungsempfehlungen werden als Notiz und in ki_berater_result ergänzt",
    getItems: r => {
      const g = r?.schritt8_aktion;
      return [
        g?.zusammenfassung,
        g?.naechste_schritte?.length && `${g.naechste_schritte.length} nächste Schritte`,
        g?.erforderliche_dokumente?.length && `${g.erforderliche_dokumente.length} einzureichende Dokumente`,
      ].filter(Boolean);
    },
    getDetails: r => [
      ...(r?.schritt8_aktion?.naechste_schritte || []).map(s => `→ ${s}`),
      ...(r?.schritt8_aktion?.erforderliche_dokumente || []).map(d => `📄 ${d}`),
    ],
    isCovered: r => !!(r?.schritt8_aktion?.zusammenfassung),
  },
  {
    num: 9, label: "Cockpit", color: "#00BCD4",
    wo: "Tab 9 › Fall-Cockpit (Case.ki_berater_result.prognose_delta)",
    felder: ["Prognose-Delta (%)", "Gesamteinfluss des Dokuments"],
    hinweis: "Prognose-Delta wird in ki_berater_result gespeichert und im Cockpit sichtbar",
    getItems: r => {
      const g = r?.schritt9_cockpit;
      const delta = g?.prognose_delta_pct;
      return [
        g?.zusammenfassung,
        delta != null && `Prognose-Einfluss: ${delta > 0 ? "+" : ""}${delta}%`,
      ].filter(Boolean);
    },
    getDetails: () => [],
    isCovered: r => !!(r?.schritt9_cockpit?.zusammenfassung),
  },
  {
    num: 10, label: "Abschluss", color: "#34C759",
    wo: "Tab 10 › Abschluss (Case.ki_berater_result.vergleichsempfehlung)",
    felder: ["Prozessziel erreichbar?", "Vergleichsempfehlung"],
    hinweis: "Vergleichsempfehlung wird in ki_berater_result gespeichert",
    getItems: r => {
      const g = r?.schritt10_abschluss;
      return [
        g?.zusammenfassung,
        g?.vergleichsempfehlung,
        g?.prozessziel_erreichbar != null && `Prozessziel erreichbar: ${g.prozessziel_erreichbar ? "✓ Ja" : "⚠ Unklar"}`,
      ].filter(Boolean);
    },
    getDetails: () => [],
    isCovered: r => !!(r?.schritt10_abschluss?.zusammenfassung),
  },
];

// ── HELPERS ──────────────────────────────────────────────────────────────────
function fileIcon(type) {
  if (!type) return <File className="w-4 h-4" style={{ color: "#aaa" }} />;
  if (type.startsWith("image/")) return <Image className="w-4 h-4" style={{ color: "#007AFF" }} />;
  if (type.startsWith("video/")) return <Film className="w-4 h-4" style={{ color: "#FF9500" }} />;
  if (type.includes("pdf")) return <FileText className="w-4 h-4" style={{ color: "#FF3B30" }} />;
  if (type.includes("word") || type.includes("document")) return <FileText className="w-4 h-4" style={{ color: "#007AFF" }} />;
  return <File className="w-4 h-4" style={{ color: "#aaa" }} />;
}

// ── KI EXPLANATION PANEL ─────────────────────────────────────────────────────
function KIExplanationPanel() {
  const [open, setOpen] = useState(false);
  const [detailStep, setDetailStep] = useState(null);

  return (
    <div className="rounded-xl border" style={{ borderColor: "rgba(0,122,255,0.2)", background: "rgba(0,122,255,0.03)" }}>
      <button onClick={() => setOpen(o => !o)} className="w-full flex items-center gap-2 px-4 py-3 text-left">
        <Info className="w-4 h-4 flex-shrink-0" style={{ color: "#007AFF" }} />
        <div className="flex-1">
          <p className="text-xs font-semibold" style={{ color: "#007AFF" }}>Was macht die KI-Analyse genau?</p>
          <p className="text-[10px]" style={{ color: "#888" }}>Welche Daten aus diesem Dokument werden in welchem Schritt eingetragen</p>
        </div>
        {open ? <ChevronUp className="w-4 h-4" style={{ color: "#aaa" }} /> : <ChevronDown className="w-4 h-4" style={{ color: "#aaa" }} />}
      </button>

      {open && (
        <div className="px-4 pb-4 space-y-3" style={{ borderTop: "1px solid rgba(0,0,0,0.06)" }}>
          <div className="flex items-center gap-1 text-[10px] text-gray-500 flex-wrap pt-3">
            <span className="px-2 py-0.5 rounded bg-gray-100">📄 Dokument</span>
            <ArrowRight style={{ width: 10, height: 10 }} />
            <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-600">Text extrahieren</span>
            <ArrowRight style={{ width: 10, height: 10 }} />
            <span className="px-2 py-0.5 rounded bg-violet-50 text-violet-600">KI analysiert alle 10 Schritte</span>
            <ArrowRight style={{ width: 10, height: 10 }} />
            <span className="px-2 py-0.5 rounded bg-green-50 text-green-600">Daten in Lexara eintragen</span>
          </div>

          <div className="space-y-1.5">
            {STEP_MAP.map((step, i) => (
              <div key={i} className="rounded-lg border cursor-pointer transition-all"
                style={{ borderColor: detailStep
