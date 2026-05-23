
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Plus, Trash2, Edit } from "lucide-react";
import { Button } from "@/components/ui/button";

const ROLES = ["Richter","Zeuge","Sachverständiger","Partei","Anwalt","Gutachter"];
const ROLE_COLORS = { Richter:"bg-purple-100 text-purple-700", Zeuge:"bg-blue-100 text-blue-700", Sachverständiger:"bg-green-100 text-green-700", Partei:"bg-orange-100 text-orange-700", Anwalt:"bg-gray-100 text-gray-700", Gutachter:"bg-teal-100 text-teal-700" };
const EMPTY = { name:"", role:"Richter", organization:"", aussagen:0, widersprueche:0, glaubwuerdigkeit:100, klaeger_rate:50, vergleich_rate:30, dauer_monate:12, notizen:"" };

export default function TabPersonen({ caseId, onCountChange }) {
  const [persons, setPersons] = useState([]);
  const [showAdd, setShowAdd] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(EMPTY);

  useEffect(() => { load(); }, [caseId]);

  const load = async (notify = false) => {
    const data = await base44.entities.Person.filter({ case_id: caseId });
    setPersons(data);
    if (notify) onCountChange && onCountChange();
  };

  const save = async () => {
    if (!form.name.trim()) return;
    if (editing) { await base44.entities.Person.update(editing, form); setEditing(null); }
    else { await base44.entities.Person.create({ case_id: caseId, ...form }); setShowAdd(false); }
    setForm(EMPTY);
    load(true);
  };

  const del = async (id) => { await base44.entities.Person.delete(id); load(true); };
  const startEdit = (p) => {
    setForm({ name:p.name||"", role:p.role||"Richter", organization:p.organization||"", aussagen:p.aussagen||0, widersprueche:p.widersprueche||0, glaubwuerdigkeit:p.glaubwuerdigkeit||100, klaeger_rate:p.klaeger_rate||50, vergleich_rate:p.vergleich_rate||30, dauer_monate:p.dauer_monate||12, notizen:p.notizen||"" });
    setEditing(p.id);
    setShowAdd(false);
  };

  const PersonForm = () => (
    <div className="bg-gray-50 border border-gray-200 rounded-xl p-4 space-y-3">
      <div className="grid grid-cols-2 gap-3">
        <input className="border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" placeholder="Name *" value={form.name} onChange={e=>setForm({...form,name:e.target.value})} />
        <select className="border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white" value={form.role} onChange={e=>setForm({...form,role:e.target.value})}>
          {ROLES.map(r=><option key={r}>{r}</option>)}
        </select>
        <input className="border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white col-span-2" placeholder="Organisation / Gericht" value={form.organization} onChange={e=>setForm({...form,organization:e.target.value})} />
      </div>
      <div className="grid grid-cols-3 gap-2">
        {[["Aussagen","aussagen"],["Widersprüche","widersprueche"],["Glaubw. %","glaubwuerdigkeit"],["Kläger %","klaeger_rate"],["Vergleiche %","vergleich_rate"],["Dauer (Mo.)","dauer_monate"]].map(([l,f]) => (
          <div key={f}>
            <label className="text-[10px] text-gray-400 block mb-1">{l}</label>
            <input type="number" className="w-full border border-gray-200 rounded-lg px-2 py-2 text-xs bg-white" value={form[f]} onChange={e=>setForm({...form,[f]:+e.target.value})} />
          </div>
        ))}
      </div>
      <textarea className="w-full border border-gray-200 rounded-lg px-3 py-2 text-xs bg-white" placeholder="Notizen" rows={2} value={form.notizen} onChange={e=>setForm({...form,notizen:e.target.value})} />
      <div className="flex gap-2">
        <Button size="sm" onClick={save} className="bg-gray-900 text-white rounded-lg text-xs">{editing?"Aktualisieren":"Hinzufügen"}</Button>
        <Button size="sm" variant="outline" onClick={()=>{setShowAdd(false);setEditing(null);setForm(EMPTY);}} className="rounded-lg text-xs">Abbrechen</Button>
      </div>
    </div>
  );

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div><h3 className="text-sm font-semibold text-gray-700">👤 Personen</h3><p className="text-xs text-gray-400">Zeugen, Richter, Parteien</p></div>
        <Button size="sm" onClick={()=>{setShowAdd(!showAdd);setEditing(null);setForm(EMPTY);}} className="bg-gray-900 text-white rounded-xl text-xs gap-1"><Plus className="w-3 h-3" /> Person hinzufügen</Button>
      </div>
      {showAdd && !editing && <PersonForm />}
      <div className="space-y-3">
        {persons.map(p => (
          <div key={p.id}>
            {editing === p.id ? (
              <PersonForm />
            ) : (
              <div className="bg-white border border-gray-100 rounded-xl p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1">
                      <span className="text-sm font-semibold text-gray-900">{p.name}</span>
                      <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${ROLE_COLORS[p.role] || "bg-gray-100 text-gray-600"}`}>{p.role}</span>
                      {p.organization && <span className="text-[10px] text-gray-400">{p.organization}</span>}
                    </div>
                    <div className="flex gap-4 text-xs text-gray-500 mt-1">
                      {p.aussagen > 0 && <span>Aussagen: <strong>{p.aussagen}</strong></span>}
                      {p.widersprueche > 0 && <span>Wid.: <strong className="text-red-500">{p.widersprueche}</strong></span>}
                      {p.glaubwuerdigkeit < 100 && <span>Glaubw.: <strong>{p.glaubwuerdigkeit}%</strong></span>}
                      {p.klaeger_rate > 0 && <span>Kläger: <strong>{p.klaeger_rate}%</strong></span>}
                    </div>
                    {p.notizen && <p className="text-xs text-gray-400 mt-1 line-clamp-1">{p.notizen}</p>}
                  </div>
                  <div className="flex gap-1 flex-shrink-0">
                    <button onClick={() => startEdit(p)} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600"><Edit className="w-3.5 h-3.5" /></button>
                    <button onClick={() => del(p.id)} className="p-1.5 rounded-lg hover:bg-red-50 text-gray-400 hover:text-red-500"><Trash2 className="w-3.5 h-3.5" /></button>
                  </div>
                </div>
              </div>
            )}
          </div>
        ))}
        {persons.length === 0 && (
          <div className="text-center py-10 text-gray-400">
            <p className="text-sm">Noch keine Personen erfasst</p>
            <p className="text-xs mt-1">Füge Zeugen, Richter oder Parteien hinzu</p>
          </div>
        )}
      </div>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );
}
