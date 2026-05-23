
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { Sparkles, Plus, CheckCircle2, CircleDot, Circle, Trash2, Download, Flame, Zap, Target, Rocket } from "lucide-react";
import { AppleCard, AppleButton, ApplePill, AppleInput, AppleSelect, AppleTextarea, AppleField, SF } from "../AppleCard";

const ROLLEN = ["Rechtsabteilung intern", "Externer Anwalt", "Vorstand / GF", "Compliance", "Steuerberater", "Patentanwalt", "Kombination"];
const HORIZONTE = {
  sofort: { label: "SOFORT", sub: "0–7 Tage", icon: Flame, color: "#FF3B30" },
  kurzfristig: { label: "KURZFRISTIG", sub: "7–90 Tage", icon: Zap, color: "#FF9500" },
  mittelfristig: { label: "MITTELFRISTIG", sub: "3–18 Monate", icon: Target, color: "#007AFF" },
  langfristig: { label: "LANGFRISTIG", sub: "18+ Monate", icon: Rocket, color: "#34C759" },
};
const STATUS_MAP = {
  offen: { icon: Circle, color: "#8E8E93" },
  in_bearbeitung: { icon: CircleDot, color: "#FF9500" },
  erledigt: { icon: CheckCircle2, color: "#34C759" },
};

function MCard({ m, onUpdate, onRemove }) {
  const h = HORIZONTE[m.horizont] || HORIZONTE.sofort;
  const s = STATUS_MAP[m.status || "offen"];
  const SI = s.icon;
  const nextStatus = m.status === "erledigt" ? "offen" : m.status === "offen" ? "in_bearbeitung" : "erledigt";
  return (
    <div style={{ background: "rgba(255,255,255,0.92)", border: "1px solid rgba(0,0,0,0.07)", borderLeft: `4px solid ${h.color}`, borderRadius: 14, padding: "12px 14px", marginBottom: 9 }}>
      <div style={{ display: "flex", alignItems: "flex-start", gap: 10 }}>
        <button onClick={() => onUpdate({ status: nextStatus })} style={{ background: "none", border: "none", cursor: "pointer", padding: 0, marginTop: 2, flexShrink: 0 }}>
          <SI style={{ width: 17, height: 17, color: s.color }} />
        </button>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", gap: 5, flexWrap: "wrap", marginBottom: 4 }}>
            <ApplePill color={h.color}>{h.label}</ApplePill>
            {m.rechtsgebiet && <ApplePill color="#5856D6">{m.rechtsgebiet}</ApplePill>}
            {m.aufwand && <ApplePill color="#888">{m.aufwand}</ApplePill>}
          </div>
          <p style={{ fontSize: 13, fontWeight: 700, color: "#1a1a1a", textDecoration: m.status === "erledigt" ? "line-through" : "none", opacity: m.status === "erledigt" ? 0.55 : 1 }}>{m.titel}</p>
          {m.wirkung && <p style={{ fontSize: 11, color: "#555", marginTop: 3 }}><strong>Wirkung:</strong> {m.wirkung}</p>}
          {m.risiko_unterlassen && <p style={{ fontSize: 11, color: "#FF3B30", marginTop: 2 }}><strong>Risiko:</strong> {m.risiko_unterlassen}</p>}
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(130px,1fr))", gap: 6, marginTop: 7 }}>
            {m.verantwortlich && <p style={{ fontSize: 11 }}><span style={{ color: "#888" }}>Verantw.: </span><strong>{m.verantwortlich}</strong></p>}
            {m.frist && <p style={{ fontSize: 11 }}><span style={{ color: "#888" }}>Frist: </span><strong style={{ color: h.color }}>{m.frist}</strong></p>}
            {m.kosten_eur ? <p style={{ fontSize: 11 }}><span style={{ color: "#888" }}>€: </span><strong>{m.kosten_eur.toLocaleString()}€</strong></p> : null}
            {m.stunden_intern ? <p style={{ fontSize: 11 }}><span style={{ color: "#888" }}>h: </span><strong>{m.stunden_intern}h</strong></p> : null}
          </div>
          {m.abhaengigkeiten && <p style={{ fontSize: 10, color: "#888", marginTop: 5, fontStyle: "italic" }}>↳ {m.abhaengigkeiten}</p>}
          {m.erfolgsmessung && <p style={{ fontSize: 10, color: "#34C759", marginTop: 3 }}>✓ {m.erfolgsmessung}</p>}
          <div style={{ marginTop: 6 }}>
            <AppleSelect value={m.assignee || ""} onChange={e => onUpdate({ assignee: e.target.value })} style={{ fontSize: 11, padding: "5px 8px", maxWidth: 220 }}>
              <option value="">Zuweisung…</option>
              {ROLLEN.map(r => <option key={r} value={r}>{r}</option>)}
            </AppleSelect>
          </div>
        </div>
        <button onClick={onRemove} style={{ background: "transparent", border: "none", cursor: "pointer", color: "#ccc", padding: 3, flexShrink: 0 }}>
          <Trash2 style={{ width: 12, height: 12 }} />
        </button>
      </div>
    </div>
  );
}

export default function Step4Aktionsplan({ scenario, onSave }) {
  const ctx = scenario.unternehmenskontext || {};
  const sit = scenario.situationsanalyse || {};
  const mat = scenario.szenario_matrix || {};
  const [plan, setPlan] = useState(scenario.aktionsplan || { massnahmen: [], ressourcen_gesamt: {} });
  const [gen, setGen] = useState(false);
  const [customF, setCustomF] = useState(null);
  const [filter, setFilter] = useState("alle");

  const persist = (u) => { setPlan(u); onSave({ aktionsplan: u }); };

  const generate = async () => {
    setGen(true);
    const r = await base44.integrations.Core.InvokeLLM({
      prompt: `Senior-Strategieberater. Konkreter, spezifischer Aktionsplan — KEINE abstrakten Empfehlungen.
KONTEXT: ${ctx.unternehmen_name} (${ctx.branche}), MA: ${ctx.mitarbeiter}
SACHVERHALT: ${ctx.sachverhalt_lang}
TOP-RISIKEN: ${(sit.kritische_punkte || []).join(" | ")}
SZENARIEN: ${(mat.szenarien || []).slice(0, 3).map(s => s.bezeichnung).join("; ")}
Erzeuge 10-15 Maßnahmen auf 4 Horizonte (sofort/kurzfristig/mittelfristig/langfristig).
Pro Maßnahme: titel(präzise!), rechtsgebiet, verantwortlich(aus: ${ROLLEN.join(", ")}),
wirkung(ein Satz), risiko_unterlassen, aufwand(Gering/Mittel/Hoch/Sehr hoch),
kosten_eur, stunden_intern, frist(konkret/relativ), abhaengigkeiten, erfolgsmessung, horizont.
Plus: ressourcen_gesamt{anwaltsstunden_gesamt, budget_extern_eur, budget_intern_eur, anzahl_personen}.`,
      response_json_schema: {
        type: "object",
        properties: {
          massnahmen: { type: "array", items: { type: "object", properties: {
            titel: { type: "string" }, rechtsgebiet: { type: "string" }, verantwortlich: { type: "string" },
            wirkung: { type: "string" }, risiko_unterlassen: { type: "string" }, aufwand: { type: "string" },
            kosten_eur: { type: "number" }, stunden_intern: { type: "number" }, frist: { type: "string" },
            abhaengigkeiten: { type: "string" }, erfolgsmessung: { type: "string" }, horizont: { type: "string" }
          }}},
          ressourcen_gesamt: { type: "object", properties: {
            anwaltsstunden_gesamt: { type: "number" }, budget_extern_eur: { type: "number" },
            budget_intern_eur: { type: "number" }, anzahl_personen: { type: "number" }
          }}
        }
      },
      model: "claude_sonnet_4_6"
    });
    const withIds = (r.massnahmen || []).map((m, i) => ({ ...m, id: `m_${Date.now()}_${i}`, status: "offen" }));
    persist({ massnahmen: withIds, ressourcen_gesamt: r.ressourcen_gesamt || {} });
    setGen(false);
  };

  const addCustom = () => {
    if (!customF?.titel?.trim()) return;
    persist({ ...plan, massnahmen: [...(plan.massnahmen || []), { ...customF, id: `c_${Date.now()}`, status: "offen", user_generated: true }] });
    setCustomF(null);
  };
  const updateM = (id, u) => persist({ ...plan, massnahmen: plan.massnahmen.map(m => m.id
