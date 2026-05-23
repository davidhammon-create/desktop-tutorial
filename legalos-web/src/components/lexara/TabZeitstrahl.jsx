
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import {
  Plus, Calendar, FileText, Edit2, Trash2, Upload, X, Sparkles,
  ChevronDown, ChevronUp, Image, Video, Link2, AlertTriangle, CheckCircle, Clock, ZoomIn
} from "lucide-react";
import { Button } from "@/components/ui/button";

// ── CONFIG ───────────────────────────────────────────────────────────────────

const CATEGORY_CONFIG = {
  vertrag:      { label: "Vertrag",       color: "#34C759", bg: "#e8f5e9" },
  zahlung:      { label: "Zahlung",       color: "#007AFF", bg: "#e3f2fd" },
  klage:        { label: "Klage",         color: "#FF3B30", bg: "#fce4ec" },
  urteil:       { label: "Urteil",        color: "#5856D6", bg: "#e8eaf6" },
  frist:        { label: "Frist",         color: "#FF9500", bg: "#fff8e1" },
  verhandlung:  { label: "Verhandlung",   color: "#AF52DE", bg: "#f3e5f5" },
  gutachten:    { label: "Gutachten",     color: "#00BCD4", bg: "#e0f7fa" },
  korrespondenz:{ label: "Korrespondenz", color: "#8BC34A", bg: "#f1f8e9" },
  foto:         { label: "Foto",          color: "#FF6B35", bg: "#fff3ee" },
  video:        { label: "Video",         color: "#C0392B", bg: "#fde8e8" },
  sonstiges:    { label: "Sonstiges",     color: "#9E9E9E", bg: "#fafafa" },
};

const IMPORTANCE_CONFIG = {
  kritisch: { label: "Kritisch", color: "#FF3B30" },
  hoch:     { label: "Hoch",     color: "#FF9500" },
  mittel:   { label: "Mittel",   color: "#007AFF" },
  niedrig:  { label: "Niedrig",  color: "#8E8E93" },
};

const MEDIA_TYPE = {
  image: ["jpg","jpeg","png","gif","webp","heic","bmp","tiff","svg"],
  video: ["mp4","mov","avi","mkv","webm","wmv","flv","m4v"],
  pdf:   ["pdf"],
};

function getMediaType(url = "", mime = "") {
  const ext = url.split(".").pop().toLowerCase().split("?")[0];
  if (MEDIA_TYPE.image.includes(ext) || mime.startsWith("image/")) return "image";
  if (MEDIA_TYPE.video.includes(ext) || mime.startsWith("video/")) return "video";
  if (ext === "pdf" || mime === "application/pdf") return "pdf";
  return "file";
}

function MediaIcon({ type, size = 12 }) {
  if (type === "image") return <Image style={{ width: size, height: size, color: "#FF6B35" }} />;
  if (type === "video") return <Video style={{ width: size, height: size, color: "#C0392B" }} />;
  return <FileText style={{ width: size, height: size, color: "#555" }} />;
}

// ── RELATION BADGE ────────────────────────────────────────────────────────────

function RelationBadge({ type }) {
  if (type === "beweist")   return <span className="text-[9px] px-1.5 py-0.5 rounded bg-green-100 text-green-700 font-semibold flex items-center gap-0.5"><CheckCircle style={{width:9,height:9}}/> bestätigt</span>;
  if (type === "widerlegt") return <span className="text-[9px] px-1.5 py-0.5 rounded bg-red-100 text-red-600 font-semibold flex items-center gap-0.5"><AlertTriangle style={{width:9,height:9}}/> widerlegt</span>;
  if (type === "überschneidet") return <span className="text-[9px] px-1.5 py-0.5 rounded bg-amber-100 text-amber-700 font-semibold flex items-center gap-0.5"><Link2 style={{width:9,height:9}}/> überschneidet</span>;
  return null;
}

// ── CONTRACT CHECKLIST ────────────────────────────────────────────────────────

function ContractChecklist({ checklist, onChange }) {
  return (
    <div className="mt-2 space-y-1">
      <p className="text-[10px] font-semibold text-gray-400 uppercase mb-1">Vertragspunkte / Erfüllung</p>
      {checklist.map((item, i) => (
        <div key={i} className="flex items-start gap-2 bg-gray-50 rounded-lg p-2">
          <button onClick={() => onChange(checklist.map((c,j) => j === i ? { ...c, done: !c.done } : c))}
            className={`w-4 h-4 rounded border flex-shrink-0 mt-0.5 flex items-center justify-center ${item.done ? "bg-green-500 border-green-500" : "border-gray-300"}`}>
            {item.done && <CheckCircle className="w-3 h-3 text-white" />}
          </button>
          <span className={`text-xs ${item.done ? "line-through text-gray-400" : "text-gray-700"}`}>{item.text || item}</span>
        </div>
      ))}
    </div>
  );
}

export default function TabZeitstrahl({ caseId, caseData }) {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({ datum: "", titel: "", beschreibung: "", kategorie: "sonstiges", wichtigkeit: "mittel" });
  const [saving, setSaving] = useState(false);

  useEffect(() => { load(); }, [caseId]);

  const load = async () => {
    setLoading(true);
    const data = await base44.entities.TimelineEvent.filter({ case_id: caseId });
    setEvents(data.sort((a, b) => new Date(a.datum || 0) - new Date(b.datum || 0)));
    setLoading(false);
  };

  const save = async () => {
    if (!form.titel.trim()) return;
    setSaving(true);
    await base44.entities.TimelineEvent.create({ case_id: caseId, ...form });
    setForm({ datum: "", titel: "", beschreibung: "", kategorie: "sonstiges", wichtigkeit: "mittel" });
    setShowAdd(false);
    setSaving(false);
    load();
  };

  const del = async (id) => {
    await base44.entities.TimelineEvent.delete(id);
    load();
  };

  if (loading) return <div className="flex justify-center py-10"><div className="w-5 h-5 border-2 border-gray-200 border-t-blue-500 rounded-full animate-spin" /></div>;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-sm font-semibold text-gray-700">📅 Zeitstrahl</h3>
          <p className="text-xs text-gray-400">Ereignisse chronologisch</p>
        </div>
        <Button size="sm" onClick={() => setShowAdd(!showAdd)} className="bg-gray-900 text-white rounded-xl text-xs gap-1">
          <Plus className="w-3 h-3" /> Ereignis
        </Button>
      </div>

      {showAdd && (
        <div className="bg-gray-50 border border-gray-200 rounded-xl p-4 space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[10px] text-gray-400 block mb-1">Datum</label>
              <input type="date" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" value={form.datum} onChange={e => setForm({...form, datum: e.target.value})} />
            </div>
            <div>
              <label className="text-[10px] text-gray-400 block mb-1">Kategorie</label>
              <select className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" value={form.kategorie} onChange={e => setForm({...form, kategorie: e.target.value})}>
                {Object.entries(CATEGORY_CONFIG).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
              </select>
            </div>
            <input className="border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white col-span-2" placeholder="Titel *" value={form.titel} onChange={e => setForm({...form, titel: e.target.value})} />
            <textarea className="border border-gray-200 rounded-lg px-3 py-2 text-xs bg-white col-span-2" rows={2} placeholder="Beschreibung" value={form.beschreibung} onChange={e => setForm({...form, beschreibung: e.target.value})} />
          </div>
          <div className="flex gap-2">
            <Button size="sm" onClick={save} disabled={saving} className="bg-gray-900 text-white rounded-lg text-xs">{saving ? "Speichern…" : "Hinzufügen"}</Button>
            <Button size="sm" variant="outline" onClick={() => setShowAdd(false)} className="rounded-lg text-xs">Abbrechen</Button>
          </div>
        </div>
      )}

      {events.length === 0 ? (
        <div className="text-center py-10 text-gray-400">
          <Calendar className="w-10 h-10 mx-auto mb-2 opacity-30" />
          <p className="text-sm">Noch keine Ereignisse</p>
        </div>
      ) : (
        <div className="relative">
          <div className="absolute left-4 top-0 bottom-0 w-px bg-gray-200" />
          <div className="space-y-4 pl-10">
            {events.map(ev => {
              const cat = CATEGORY_CONFIG[ev.kategorie] || CATEGORY_CONFIG.sonstiges;
              const imp = IMPORTANCE_CONFIG[ev.wichtigkeit] || IMPORTANCE_CONFIG.mittel;
              return (
                <div key={ev.id} className="relative">
                  <div className="absolute -left-10 w-8 h-8 rounded-full flex items-center justify-center text-xs" style={{ background: cat.bg, border: `2px solid ${cat.color}` }}>
                    <FileText className="w-3.5 h-3.5" style={{ color: cat.color }} />
                  </div>
                  <div className="bg-white border border-gray-100 rounded-xl p-3">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="flex items-center gap-2 flex-wrap mb-0.5">
                          {ev.datum && <span className="text-[10px] text-gray-400">{new Date(ev.datum).toLocaleDateString("de-DE")}</span>}
                          <span className="text-[9px] px-1.5 py-0.5 rounded font-medium" style={{ background: cat.bg, color: cat.color }}>{cat.label}</span>
                          <span className="text-[9px] font-medium" style={{ color: imp.color }}>{imp.label}</span>
                        </div>
                        <p className="text-sm font-semibold text-gray-900">{ev.titel}</p>
                        {ev.beschreibung && <p className="text-xs text-gray-500 mt-0.5">{ev.beschreibung}</p>}
                      </div>
                      <button onClick={() => del(ev.id)} className="text-gray-300 hover:text-red-400 flex-shrink-0">
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
