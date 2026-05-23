
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Sparkles, Plus, Shield, Sword, Pause, TrendingUp, Eye, X, GitCompare } from "lucide-react";
import { AppleCard, AppleButton, ApplePill, AppleInput, AppleSelect, AppleField, SF } from "../AppleCard";

const FRAGEN = [
  "Was passiert wenn wir handeln?",
  "Was passiert wenn wir nichts tun?",
  "Was passiert wenn die Gegenpartei handelt?",
  "Vergleiche Option A vs. Option B",
  "Was ist die beste Handlung in dieser Situation?",
];

const TYPEN = {
  "aktiv-offensiv": { icon: Sword, color: "#FF3B30", label: "Aktiv-offensiv" },
  "aktiv-defensiv": { icon: Shield, color: "#007AFF", label: "Aktiv-defensiv" },
  "passiv-abwartend": { icon: Pause, color: "#8E8E93", label: "Passiv" },
  "strategisch-langfristig": { icon: TrendingUp, color: "#34C759", label: "Strategisch" },
};

function SzCard({ sz, expanded, onExpand, selected, onSelect, onRemove }) {
  const t = TYPEN[sz.handlungstyp] || TYPEN["aktiv-defensiv"];
  const Icon = t.icon;
  const awC = sz.auswirkungsgrad === "existenziell" ? "#FF3B30" : sz.auswirkungsgrad === "hoch" ? "#FF9500" : sz.auswirkungsgrad === "mittel" ? "#007AFF" : "#34C759";
  return (
    <div style={{ background: "rgba(255,255,255,0.92)", backdropFilter: "blur(20px)", border: selected ? `2px solid ${t.color}` : "1px solid rgba(0,0,0,0.07)", borderRadius: 16, boxShadow: selected ? `0 4px 16px ${t.color}20` : "0 2px 10px rgba(0,0,0,0.05)", overflow: "hidden", ...SF }}>
      <div style={{ padding: "13px 15px", cursor: "pointer" }} onClick={onExpand}>
        <div style={{ display: "flex", alignItems: "flex-start", gap: 10 }}>
          <div style={{ width: 30, height: 30, borderRadius: 9, background: `${t.color}15`, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
            <Icon style={{ width: 14, height: 14, color: t.color }} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 5, marginBottom: 2, flexWrap: "wrap" }}>
              <ApplePill color={t.color}>{t.label}</ApplePill>
              {sz.auswirkungsgrad && <ApplePill color={awC}>{sz.auswirkungsgrad}</ApplePill>}
            </div>
            <p style={{ fontSize: 13, fontWeight: 700, color: "#1a1a1a" }}>{sz.bezeichnung}</p>
            <p style={{ fontSize: 11, color: "#888", marginTop: 2 }}>{sz.zeithorizont || "—"}</p>
          </div>
          <div style={{ display: "flex", gap: 4, flexShrink: 0 }}>
            {onRemove && (
              <button onClick={e => { e.stopPropagation(); onRemove(); }} style={{ background: "rgba(255,59,48,0.1)", border: "none", borderRadius: 6, padding: 4, cursor: "pointer", color: "#FF3B30" }}>
                <X style={{ width: 10, height: 10 }} />
              </button>
            )}
            <button onClick={e => { e.stopPropagation(); onSelect(); }} style={{ width: 22, height: 22, borderRadius: 6, border: selected ? "none" : "1px solid rgba(0,0,0,0.15)", background: selected ? t.color : "rgba(255,255,255,0.8)", color: selected ? "#fff" : "#ccc", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <GitCompare style={{ width: 11, height: 11 }} />
            </button>
          </div>
        </div>
        <div style={{ marginTop: 9, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
          <div>
            <p style={{ fontSize: 9, color: "#888", textTransform: "uppercase", fontWeight: 600 }}>Erfolg</p>
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 2 }}>
              <div style={{ flex: 1, height: 5, background: "rgba(0,0,0,0.06)", borderRadius: 3, overflow: "hidden" }}>
                <div style={{ height: "100%", width: `${sz.erfolg_pct || 0}%`, background: t.color, borderRadius: 3 }} />
              </div>
              <span style={{ fontSize: 11, fontWeight: 700, color: t.color }}>{sz.erfolg_pct || 0}%</span>
            </div>
          </div>
          <div>
            <p style={{ fontSize: 9, color: "#888", textTransform: "uppercase", fontWeight: 600 }}>Finanz</p>
            <p style={{ fontSize: 12, fontWeight: 700, color: "#1a1a1a", marginTop: 2 }}>{sz.finanzielle_folge_eur ? `${(sz.finanzielle_folge_eur / 1000).toFixed(0)}k€` : "—"}</p>
          </div>
        </div>
      </div>
      {expanded && (
        <div style={{ borderTop: "1px solid rgba(0,0,0,0.06)", padding: "11px 15px", background: "rgba(0,0,0,0.015)" }}>
          {sz.konsequenzen?.length > 0 && (
            <div style={{ marginBottom: 9 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: "#888", textTransform: "uppercase", marginBottom: 4 }}>Konsequenzen</p>
              {sz.konsequenzen.map((k, i) => (
                <div key={i} style={{ fontSize: 11, color: "#333", marginBottom: 3, display: "flex", gap: 8 }}>
                  <span style={{ fontWeight: 600, color: t.color, minWidth: 70 }}>{k.art}:</span>
                  <span style={{ flex: 1 }}>{k.text}</span>
                </div>
              ))}
            </div>
          )}
          {sz.gegner_reaktion && (
            <div style={{ marginBottom: 9, padding: "7px 10px", background: "rgba(255,59,48,0.06)", borderRadius: 9 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: "#FF3B30", textTransform: "uppercase", marginBottom: 3 }}>🎯 Gegner-Reaktion (Zug 1)</p>
              <p style={{ fontSize: 11, color: "#333" }}>{sz.gegner_reaktion}</p>
            </div>
          )}
          {sz.gegen_gegen_reaktion && (
            <div style={{ marginBottom: 9, padding: "7px 10px", background: "rgba(52,199,89,0.06)", borderRadius: 9 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: "#34C759", textTransform: "uppercase", marginBottom: 3 }}>♟ Unsere Gegen-Reaktion (Zug 2)</p>
              <p style={{ fontSize: 11, color: "#333" }}>{sz.gegen_gegen_reaktion}</p>
            </div>
          )}
          {sz.strategos_empfehlung && (
            <div style={{ marginBottom: 9, padding: "7px 10px", background: "linear-gradient(135deg,rgba(88,86,214,0.08),rgba(175,82,222,0.08))", borderRadius: 9 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: "#5856D6", textTransform: "uppercase", marginBottom: 3 }}>✨ Strategos — {sz.strategos_quelle || "Empfehlung"}</p>
              <p style={{ fontSize: 11, color: "#333" }}>{sz.strategos_empfehlung}</p>
            </div>
          )}
          {sz.rechtliche_grundlage && (
            <p style={{ fontSize: 10, color: "#666", fontFamily: "SF Mono, Monaco, monospace", marginBottom: 6 }}><strong>Norm:</strong> {sz.rechtliche_grundlage}</p>
          )}
          {sz.kosten && (
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 4, fontSize: 10, color: "#555" }}>
              {sz.kosten.anwaltskosten_eur ? <p>Anwalt: <strong>{sz.kosten.anwaltskosten_eur.toLocaleString()}€</strong></p> : null}
              {sz.kosten.gerichtskosten_eur ? <p>Gericht: <strong>{sz.kosten.gerichtskosten_eur.toLocaleString()}€</strong></p> : null}
              {sz.kosten.interne_ressourcen ? <p>Intern: <strong>{sz.kosten.interne_ressourcen}</strong></p> : null}
              {sz.kosten.externe_berater ? <p>Extern: <strong>{sz.kosten.externe_berater}</strong></p> : null}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default function Step3Matrix({ scenario, onSave }) {
  const ctx = scenario.unternehmenskontext || {};
  const sit = scenario.situationsanalyse || {};
  const [matrix, setMatrix] = useState(scenario.szenario_matrix || { szenarien: [], ausgangsfrage: "" });
  const [frage, setFrage] = useState(matrix.ausgangsfrage || FRAGEN[0]);
  const [gen, setGen] = useState(false);
  const [expId, setExpId] = useState(null);
  const [selIds, setSelIds] = useState([]);
  const [customF, setCustomF] = useState(null);
  const [view, setView] = useState("cards");

  const persist = (u) => { setMatrix(u); onSave({ szenario_matrix: u }); };

  const generate = async () => {
    setGen(true);
    const r = await base44.integrations.Core.InvokeLLM({
      prompt: `Strategischer Senior-Berater. Generiere Handlungsoptionen mit 2-Zug-Gegnerprognose.
KONTEXT: ${ctx.unternehmen_name} (${ctx.branche}), Sachverhalt: ${ctx.sachverhalt_lang}
Gegner: ${ctx.gegner_name} (${ctx.gegner_rolle}), Zeitkritikalität: ${ctx.zeitkritikalitaet}/10
TOP-RISIKEN: ${(sit.kritische_punkte || []).join(" | ")}
EXPOSURE: ${sit.gesamt_exposure_eur || "—"}€
FRAGE: ${frage}
Generiere 5-7 differenzierte Szenarien. Pro Szenario:
bezeichnung, handlungstyp(aktiv-offensiv/aktiv-defensiv/passiv-abwartend/strategisch-langfristig),
erfolg_pct, zeithorizont, auswirkungsgrad(gering/mittel/hoch/existenziell),
konsequenzen(4-6 Objekte mit art: finanziell/operativ/rechtlich/reputation/praezedenz + text),
finanzielle_folge_eur, gegner_reaktion(Zug 1), gegen_gegen_reaktion(Zug 2 unsererseits),
strategos_empfehlung(Sun-Tzu für Offensive, Machiavelli für Machterhalt, Harvard für Kooperation — DIREKTE Handlungsanleitung!),
strategos_quelle, rechtliche_grundlage(§§),
kosten{anwaltskosten_eur, gerichtskosten_eur, interne_ressourcen, externe_berater}.`,
      response_json_schema: {
        type: "object",
        properties: {
          szenarien: { type: "array", items: { type: "object", properties: {
            bezeichnung: { type: "string" },
            handlungstyp: { type: "string" },
            erfolg_pct: { type: "number" },
            zeithorizont: { type: "string" },
            auswirkungsgrad: { type: "string" },
            konsequenzen: { type: "array", items: { type: "object", properties: { art: { type: "string" }, text: { type: "string" } } } },
            finanzielle_folge_eur: { type: "number" },
            gegner_reaktion: { type: "string" },
            gegen_gegen_reaktion: { type: "string" },
            strategos_empfehlung: { type: "string" },
            strategos_quelle: { type: "string" },
            rechtliche_grundlage: { type: "string" },
            kosten: { type: "object", properties: {
              anwaltskosten_eur: { type: "number" },
              gerichtskosten_eur: { type: "number" },
              interne_ressourcen: { type: "string" },
              externe_berater: { type: "string" }
            }}
          }}}
        }
      },
      model: "claude_sonnet_4_6"
    });
    const existing = (matrix.szenarien || []).filter(s => s.user_generated);
    const ki = (r.szenarien || []).map((s, i) => ({ ...s, id: `ki_${Date.now()}_${i}`, ki_generated: true }));
    persist({ ...matrix, ausgangsfrage: frage, szenarien: [...existing, ...ki] });
    setGen(false);
  };

  const addCustom = () => {
    if (!customF?.bezeichnung?.trim()) return;
    persist({ ...matrix, szenarien: [...(matrix.szenarien || []), { ...customF, id: `u_${Date.now()}`, user_generated: true }] });
    setCustomF(null);
  };

  const remove = (id) => { persist({ ...matrix, szenarien: matrix.szenarien.filter(s => s.id !== id) }); setSelIds(i => i.filter(x => x !== id)); };
  const toggleSel = (id) => setSelIds(i => i.includes(id) ? i.filter(x => x !== id) : i.length < 2 ? [...i, id] : [i[1], id]);

  const szs = matrix.szenarien || [];
  const scA = szs.find(s => s.id
