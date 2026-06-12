import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Search, Plus, X, Scale, TrendingUp, Clock, AlertCircle, Folder } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/lib/AuthContext";

const C = { bg:"#F2F2F7", card:"#FFFFFF", separator:"rgba(0,0,0,0.08)", label:"#1C1C1E", label2:"#636366", label3:"#AEAEB2", emerald:"#1DB954", emeraldDim:"rgba(29,185,84,0.10)", emeraldText:"#166F38", ocean:"#0A84FF", bordeaux:"#B81C3A", bordeauxDim:"rgba(184,28,58,0.09)", shadowSm:"0 1px 4px rgba(0,0,0,0.07)", shadow:"0 4px 20px rgba(0,0,0,0.07)" };
const SF = { fontFamily:"-apple-system,'SF Pro Text','Helvetica Neue',Arial,sans-serif" };

function PrognoseArc({ value=0 }) {
  const color = value>=65?C.emerald:value>=40?"#FF9500":C.bordeaux;
  const r=15, circ=2*Math.PI*r, offset=circ-(value/100)*circ;
  return (
    <div style={{position:"relative",width:38,height:38,display:"flex",alignItems:"center",justifyContent:"center"}}>
      <svg width="38" height="38" style={{transform:"rotate(-90deg)",position:"absolute",inset:0}}>
        <circle cx="19" cy="19" r={r} fill="none" stroke="rgba(0,0,0,0.07)" strokeWidth="3"/>
        <circle cx="19" cy="19" r={r} fill="none" stroke={color} strokeWidth="3" strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round" style={{transition:"stroke-dashoffset 0.5s ease"}}/>
      </svg>
      <span style={{position:"relative",fontSize:9,fontWeight:700,color}}>{Math.round(value)}</span>
    </div>
  );
}

function CaseCard({ caseData, counts, onOpen }) {
  const progColor = (caseData.prognose||0)>=65?C.emerald:(caseData.prognose||0)>=40?"#FF9500":C.bordeaux;
  const done = [caseData.fallname,caseData.gericht,caseData.zentrale_rechtsfrage,(counts?.args||0)>0,(counts?.evidence||0)>0,(counts?.persons||0)>0,(counts?.deadlines||0)>0,caseData.prognose,caseData.streitwert].filter(Boolean).length;
  const pct = Math.round((done/9)*100);
  const statusStyle = {Aktiv:{bg:C.emeraldDim,color:C.emeraldText},Vorbereitung:{bg:"rgba(10,132,255,0.09)",color:"#0A5FC4"},Abgeschlossen:{bg:"rgba(0,0,0,0.05)",color:C.label2},Ruhend:{bg:"rgba(255,149,0,0.09)",color:"#BF7200"}}[caseData.status]||{bg:"rgba(0,0,0,0.05)",color:C.label2};
  return (
    <div onClick={() => onOpen(caseData)} style={{background:C.card,border:`1px solid ${C.separator}`,borderRadius:18,boxShadow:C.shadowSm,cursor:"pointer",transition:"box-shadow 0.18s, transform 0.18s",display:"flex",flexDirection:"column",...SF}} onMouseEnter={e=>{e.currentTarget.style.boxShadow=C.shadow;e.currentTarget.style.transform="translateY(-2px)"}} onMouseLeave={e=>{e.currentTarget.style.boxShadow=C.shadowSm;e.currentTarget.style.transform="none"}}>
      <div style={{padding:"18px 20px 14px",display:"flex",alignItems:"flex-start",justifyContent:"space-between",gap:12}}>
        <div style={{flex:1,minWidth:0}}>
          {caseData.aktenzeichen&&<p style={{fontFamily:"'SF Mono',Menlo,monospace",fontSize:9.5,color:C.label3,letterSpacing:"0.04em",marginBottom:4}}>{caseData.aktenzeichen}</p>}
          <h3 style={{fontSize:13.5,fontWeight:600,color:C.label,lineHeight:1.35,marginBottom:8}}>{caseData.fallname}</h3>
          <div style={{display:"flex",flexWrap:"wrap",gap:5}}>
            {caseData.status&&<span style={{fontSize:10.5,fontWeight:600,padding:"2px 8px",borderRadius:6,background:statusStyle.bg,color:statusStyle.color}}>{caseData.status}</span>}
            {caseData.rechtsgebiet&&<span style={{fontSize:10.5,padding:"2px 8px",borderRadius:6,background:"rgba(0,0,0,0.04)",color:C.label2}}>{caseData.rechtsgebiet}</span>}
          </div>
        </div>
        <div style={{flexShrink:0,textAlign:"right"}}>
          <p style={{fontSize:22,fontWeight:700,color:progColor,lineHeight:1,letterSpacing:"-0.03em"}}>{Math.round(caseData.prognose||0)}%</p>
          <p style={{fontSize:9,color:C.label3,marginTop:2}}>Prognose</p>
        </div>
      </div>
      <div style={{paddingInline:20,paddingBottom:14}}>
        <div style={{display:"flex",justifyContent:"space-between",marginBottom:5}}>
          <span style={{fontSize:10,color:C.label3}}>Vollständigkeit</span>
          <span style={{fontSize:10,fontWeight:600,color:C.label2}}>{pct}%</span>
        </div>
        <div style={{height:4,background:"rgba(0,0,0,0.06)",borderRadius:99,overflow:"hidden"}}>
          <div style={{height:"100%",borderRadius:99,width:`${pct}%`,background:pct>=80?C.emerald:pct>=50?"#FF9500":"rgba(0,0,0,0.15)",transition:"width 0.35s ease"}}/>
        </div>
      </div>
      <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",borderTop:`1px solid ${C.separator}`,paddingBlock:12}}>
        {[["Argum.",counts?.args||0],["Beweise",counts?.evidence||0],["Personen",counts?.persons||0],["Fristen",counts?.deadlines||0]].map(([l,v])=>(
          <div key={l} style={{textAlign:"center"}}><p style={{fontSize:15,fontWeight:700,color:C.label,lineHeight:1}}>{v}</p><p style={{fontSize:9.5,color:C.label3,marginTop:3}}>{l}</p></div>
        ))}
      </div>
    </div>
  );
}

function KpiChip({ icon: Icon, label, value, accent }) {
  return (
    <div style={{background:C.card,border:`1px solid ${C.separator}`,borderRadius:16,padding:"16px 18px",display:"flex",alignItems:"center",gap:14,boxShadow:C.shadowSm}}>
      <div style={{width:40,height:40,borderRadius:12,background:accent?`${accent}14`:"rgba(0,0,0,0.05)",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
        <Icon style={{width:18,height:18,color:accent||C.label3}}/>
      </div>
      <div><p style={{fontSize:22,fontWeight:700,color:C.label,lineHeight:1,letterSpacing:"-0.03em"}}>{value}</p><p style={{fontSize:10.5,color:C.label3,marginTop:4}}>{label}</p></div>
    </div>
  );
}

export default function LexaraDashboard() {
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const [cases, setCases] = useState([]);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newCase, setNewCase] = useState({ fallname:"", aktenzeichen:"", rechtsgebiet:"", status:"Aktiv", instanz:"Erstinstanz" });
  const [caseCounts, setCaseCounts] = useState({});
  const [creating, setCreating] = useState(false);

  useEffect(() => { loadData(); }, [isAuthenticated]);

  const loadData = async () => {
    setLoading(true);
    try {
      const [cs, args, evs, pers, deadlines] = await Promise.all([
        base44.entities.Case.list("-created_date").catch(() => []),
        base44.entities.Argument.filter({}).catch(() => []),
        base44.entities.Evidence.filter({}).catch(() => []),
        base44.entities.Person.filter({}).catch(() => []),
        base44.entities.Deadline.filter({}).catch(() => []),
      ]);
      setCases(cs);
      const counts = {};
      cs.forEach(c => { counts[c.id] = { args: args.filter(a=>a.case_id===c.id).length, evidence: evs.filter(e=>e.case_id===c.id).length, persons: pers.filter(p=>p.case_id===c.id).length, deadlines: deadlines.filter(d=>d.case_id===c.id).length }; });
      setCaseCounts(counts);
    } catch(e) { console.error(e); }
    setLoading(false);
  };

  const createCase = async () => {
    if (!newCase.fallname.trim()) return;
    setCreating(true);
    try {
      const c = await base44.entities.Case.create({ ...newCase, prognose: 50, streitwert: 0 });
      setShowCreate(false);
      setNewCase({ fallname:"", aktenzeichen:"", rechtsgebiet:"", status:"Aktiv", instanz:"Erstinstanz" });
      navigate(`/lexara/case?id=${c.id}`);
    } catch(e) { console.error(e); }
    setCreating(false);
  };

  const filtered = cases.filter(c => {
    const q = search.toLowerCase();
    if (q && !c.fallname?.toLowerCase().includes(q) && !c.aktenzeichen?.toLowerCase().includes(q) && !c.rechtsgebiet?.toLowerCase().includes(q)) return false;
    if (statusFilter !== "all" && c.status !== statusFilter) return false;
    return true;
  });

  const aktiv = cases.filter(c=>c.status==="Aktiv").length;
  const overdue = Object.values(caseCounts).reduce((s,c)=>s,0);
  const avgProg = cases.length ? Math.round(cases.reduce((s,c)=>s+(c.prognose||0),0)/cases.length) : 0;

  return (
    <div style={{minHeight:"100vh",background:C.bg,...SF}}>
      {/* Header */}
      <div style={{background:"rgba(242,242,247,0.95)",borderBottom:`1px solid ${C.separator}`,backdropFilter:"blur(20px)",padding:"20px 24px 16px"}}>
        <div style={{maxWidth:1200,margin:"0 auto"}}>
          <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:16}}>
            <div style={{display:"flex",alignItems:"center",gap:10}}>
              <div style={{width:36,height:36,borderRadius:10,background:"#1a3560",display:"flex",alignItems:"center",justifyContent:"center"}}>
                <Scale style={{width:18,height:18,color:"white"}}/>
              </div>
              <div>
                <h1 style={{fontSize:18,fontWeight:700,color:C.label,lineHeight:1}}>LEXARA</h1>
                <p style={{fontSize:10.5,color:C.label3,marginTop:2}}>Fallmanagement & KI-Analyse</p>
              </div>
            </div>
            <button onClick={()=>setShowCreate(true)} style={{display:"flex",alignItems:"center",gap:6,background:"#1a3560",color:"white",border:"none",borderRadius:10,padding:"8px 16px",fontSize:12,fontWeight:600,cursor:"pointer"}}>
              <Plus style={{width:14,height:14}}/> Neuer Fall
            </button>
          </div>
          {/* KPIs */}
          <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(160px,1fr))",gap:10,marginBottom:16}}>
            <KpiChip icon={Scale} label="Aktive Fälle" value={aktiv} accent={C.ocean}/>
            <KpiChip icon={TrendingUp} label="Ø Prognose" value={`${avgProg}%`} accent={C.emerald}/>
            <KpiChip icon={AlertCircle} label="Fälle gesamt" value={cases.length} accent="#FF9500"/>
            <KpiChip icon={Clock} label="In Vorbereitung" value={cases.filter(c=>c.status==="Vorbereitung").length} accent="#5856D6"/>
          </div>
          {/* Search + Filter */}
          <div style={{display:"flex",gap:8}}>
            <div style={{flex:1,position:"relative"}}>
              <Search style={{position:"absolute",left:10,top:"50%",transform:"translateY(-50%)",width:14,height:14,color:C.label3}}/>
              <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Fälle suchen…" style={{width:"100%",paddingLeft:32,paddingRight:12,paddingBlock:8,border:`1px solid ${C.separator}`,borderRadius:10,fontSize:12.5,background:C.card,outline:"none",boxSizing:"border-box"}}/>
              {search && <button onClick={()=>setSearch("")} style={{position:"absolute",right:8,top:"50%",transform:"translateY(-50%)",background:"none",border:"none",cursor:"pointer",padding:0}}><X style={{width:12,height:12,color:C.label3}}/></button>}
            </div>
            <div style={{display:"flex",gap:4,background:C.card,border:`1px solid ${C.separator}`,borderRadius:10,padding:3}}>
              {["all","Aktiv","Vorbereitung","Abgeschlossen","Ruhend"].map(s=>(
                <button key={s} onClick={()=>setStatusFilter(s)} style={{fontSize:10.5,padding:"4px 10px",borderRadius:7,border:"none",cursor:"pointer",fontWeight:statusFilter===s?600:400,background:statusFilter===s?"white":"transparent",color:statusFilter===s?C.label:C.label3,boxShadow:statusFilter===s?"0 1px 3px rgba(0,0,0,0.1)":"none"}}>
                  {s==="all"?"Alle":s}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Cases Grid */}
      <div style={{maxWidth:1200,margin:"0 auto",padding:"20px 24px"}}>
        {loading ? (
          <div style={{display:"flex",justifyContent:"center",paddingTop:80}}>
            <div style={{width:24,height:24,border:"3px solid rgba(0,0,0,0.1)",borderTopColor:C.ocean,borderRadius:"50%",animation:"spin 0.8s linear infinite"}}/>
          </div>
        ) : filtered.length === 0 ? (
          <div style={{textAlign:"center",paddingTop:80,color:C.label3}}>
            <Scale style={{width:48,height:48,margin:"0 auto 12px",opacity:0.2}}/>
            <p style={{fontSize:14,fontWeight:500}}>{search||statusFilter!=="all"?"Keine Treffer":"Noch keine Fälle"}</p>
            <p style={{fontSize:12,marginTop:6}}>{search||statusFilter!=="all"?"Suchfilter anpassen":"Erstelle deinen ersten Fall"}</p>
            {!search&&statusFilter==="all"&&<button onClick={()=>setShowCreate(true)} style={{marginTop:16,background:"#1a3560",color:"white",border:"none",borderRadius:10,padding:"8px 20px",fontSize:12,fontWeight:600,cursor:"pointer"}}><Plus style={{width:12,height:12,display:"inline",marginRight:4}}/>Neuer Fall</button>}
          </div>
        ) : (
          <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fill,minmax(300px,1fr))",gap:14}}>
            {filtered.map(c=>(
              <CaseCard key={c.id} caseData={c} counts={caseCounts[c.id]||{}} onOpen={c=>navigate(`/lexara/case?id=${c.id}`)}/>
            ))}
          </div>
        )}
      </div>

      {/* Create Modal */}
      {showCreate && (
        <div style={{position:"fixed",inset:0,zIndex:50,display:"flex",alignItems:"center",justifyContent:"center",background:"rgba(0,0,0,0.4)",backdropFilter:"blur(8px)"}} onClick={()=>setShowCreate(false)}>
          <div style={{background:"white",borderRadius:20,padding:28,width:"100%",maxWidth:440,boxShadow:"0 20px 60px rgba(0,0,0,0.15)",...SF}} onClick={e=>e.stopPropagation()}>
            <h2 style={{fontSize:16,fontWeight:700,color:C.label,marginBottom:20}}>Neuen Fall anlegen</h2>
            <div style={{display:"flex",flexDirection:"column",gap:14}}>
              {[["Fallname *","text","Müller vs. Schmidt GmbH","fallname"],["Aktenzeichen","text","LG München I – 4 O 12342/26","aktenzeichen"],["Rechtsgebiet","text","Vertragsrecht, IP-Recht, …","rechtsgebiet"]].map(([label,type,ph,key])=>(
                <div key={key}>
                  <label style={{fontSize:11,color:C.label3,marginBottom:5,display:"block"}}>{label}</label>
                  <input type={type} placeholder={ph} value={newCase[key]} onChange={e=>setNewCase(p=>({...p,[key]:e.target.value}))} style={{width:"100%",border:`1px solid ${C.separator}`,borderRadius:10,padding:"9px 12px",fontSize:13,outline:"none",boxSizing:"border-box"}} onKeyDown={e=>e.key==="Enter"&&createCase()}/>
                </div>
              ))}
              <div>
                <label style={{fontSize:11,color:C.label3,marginBottom:5,display:"block"}}>Status</label>
                <select value={newCase.status} onChange={e=>setNewCase(p=>({...p,status:e.target.value}))} style={{width:"100%",border:`1px solid ${C.separator}`,borderRadius:10,padding:"9px 12px",fontSize:13,outline:"none"}}>
                  {["Aktiv","Vorbereitung","Ruhend","Abgeschlossen"].map(s=><option key={s}>{s}</option>)}
                </select>
              </div>
            </div>
            <div style={{display:"flex",gap:10,marginTop:22}}>
              <button onClick={()=>setShowCreate(false)} style={{flex:1,padding:"10px",borderRadius:10,border:`1px solid ${C.separator}`,fontSize:13,color:C.label2,background:"none",cursor:"pointer"}}>Abbrechen</button>
              <button onClick={createCase} disabled={!newCase.fallname.trim()||creating} style={{flex:1,padding:"10px",borderRadius:10,border:"none",fontSize:13,fontWeight:600,color:"white",background:"#1a3560",cursor:"pointer",opacity:!newCase.fallname.trim()||creating?0.5:1}}>
                {creating?"Erstelle…":"Fall erstellen"}
              </button>
            </div>
          </div>
        </div>
      )}
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );
}
