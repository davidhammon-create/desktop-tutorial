"""OBERFLAECHE - alles von KOORDINAT auf einer Seite im Browser.  Start: python3 -m koordinat ui [port]

Laeuft nur auf diesem Rechner (127.0.0.1), nur Standardbibliothek. Liest dieselbe Datenbank wie die Befehlszeile.
Schutz: Antworten nur fuer Host localhost/127.0.0.1 (gegen DNS-Rebinding); schreibende Aufrufe brauchen die
Kopfzeile X-Koordinat (fremde Webseiten koennen sie nicht setzen). Schalter und Kern bleiben der Befehlszeile
vorbehalten; die Seite zeigt sie nur an. Schluessel werden nie ausgeliefert.
"""
import json, urllib.parse, webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from . import anbieter, befehle, evolution, guide, leitfaden, module, speicher, verfassung, vital as vitalmod, wachstum, __version__


def _uebersicht(db, v):
    mods = module.liste(db, v)
    return dict(version=__version__, puls=v.puls(), modus=v.modus(), stop=verfassung.stop_gesetzt(),
                kern_intakt=verfassung.pruefe_integritaet(), entwurfsmodus=verfassung.entwicklungsmodus(),
                module=len(mods), module_an=sum(m["an"] for m in mods),
                katalog=db.execute("SELECT COUNT(*) FROM katalog").fetchone()[0],
                vorschlaege=len(wachstum.vorschlaege(db)), befehle=len(befehle.alle()),
                ablaeufe=len(leitfaden.ablaeufe()), guide=len(guide.eintraege()),
                anbieter=anbieter.uebersicht(), effort=anbieter.standard_effort(), effort_stufen=list(anbieter.EFFORT))


def get(db, v, pfad, q):
    """Lesende API. Gibt ein JSON-faehiges Objekt zurueck."""
    if pfad == "/api/uebersicht":
        return _uebersicht(db, v)
    if pfad == "/api/anbieter":
        return anbieter.uebersicht()
    if pfad == "/api/katalog":
        return [dict(kategorie=r[0], repo=r[1], zweck=r[2] or "", sterne=r[3], lizenz=r[4], quelle=r[5]) for r in db.execute(
            "SELECT kategorie, repo, zweck, sterne, lizenz, quelle FROM katalog ORDER BY kategorie, sterne DESC, repo")]
    if pfad == "/api/befehle":
        return befehle.suche(q.get("q", ""), q.get("werkzeug") or None)
    if pfad == "/api/ablaeufe":
        return [dict(id=a["id"], titel=a["titel"], ziel=a.get("ziel", ""), schritte=len(a["schritte"])) for a in leitfaden.ablaeufe()]
    if pfad == "/api/ablauf":
        return leitfaden.plan(db, q.get("anliegen", ""))
    if pfad == "/api/guide":
        if q.get("q"):
            return dict(text=guide.frage(db, q["q"]))
        return [dict(id=e["id"], titel=e["titel"], kurz=e["kurz"], stufe=e["stufe"]) for e in guide.eintraege()]
    if pfad == "/api/module":
        return module.liste(db, v)
    if pfad == "/api/vorschlaege":
        return wachstum.vorschlaege(db, True)
    if pfad == "/api/system":
        return dict(schalter=[dict(name=n, an=speicher.schalter(db, n), text=t) for n, (_, t) in speicher.SCHALTER.items()],
                    algorithmen=evolution.uebersicht(db), verfassung=dict(ziel=verfassung.ZIEL, artikel=verfassung.ARTIKEL),
                    in_not=v.not_liste(), hunger=v.hunger(), protokoll_intakt=v.kette_intakt())
    raise KeyError(pfad)


def post(db, v, pfad, d, senden=None):
    """Handelnde API: Fragen an KIs, Bedarf melden."""
    extra = {"senden": senden} if senden else {}
    if pfad == "/api/frage":
        if d.get("alle"):
            return anbieter.frage_alle(d["nachricht"], d.get("anbieter_liste"), d.get("effort"), d.get("system"), **extra)
        return anbieter.frage(d["nachricht"], d.get("anbieter") or None, d.get("modell") or None, d.get("effort") or None,
                              d.get("system") or None, d.get("verlauf"), **extra)
    if pfad == "/api/brauche":
        return dict(id=wachstum.brauche(db, d["bedarf"], "oberflaeche"))
    if pfad == "/api/modelle":
        return anbieter.modelle(d["anbieter"], **extra)
    raise KeyError(pfad)


class _Handler(BaseHTTPRequestHandler):
    server_version = "koordinat"

    def log_message(self, *a):
        pass

    def _host_ok(self):
        h = (self.headers.get("Host") or "").rsplit(":", 1)[0].strip("[]")
        return h in ("127.0.0.1", "localhost", "::1")

    def _send(self, code, daten, art="application/json; charset=utf-8"):
        roh = daten if isinstance(daten, bytes) else json.dumps(daten, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", art)
        self.send_header("Content-Length", str(len(roh)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(roh)

    def _rufe(self, fn, *args):
        db = speicher.db()
        try:
            self._send(200, fn(db, vitalmod.Vital(db), *args))
        except KeyError as e:
            self._send(404, dict(fehler=f"unbekannt: {e}"))
        except Exception as e:
            self._send(400, dict(fehler=f"{type(e).__name__}: {e}"))
        finally:
            db.close()

    def do_GET(self):
        if not self._host_ok():
            return self._send(403, dict(fehler="nur lokal"))
        u = urllib.parse.urlsplit(self.path)
        if u.path in ("/", "/index.html"):
            return self._send(200, SEITE.encode(), "text/html; charset=utf-8")
        q = {k: w[0] for k, w in urllib.parse.parse_qs(u.query).items()}
        self._rufe(get, u.path, q)

    def do_POST(self):
        if not self._host_ok() or self.headers.get("X-Koordinat") != "1":
            return self._send(403, dict(fehler="nur von der eigenen Oberflaeche"))
        try:
            d = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
        except json.JSONDecodeError:
            return self._send(400, dict(fehler="kein JSON"))
        self._rufe(post, urllib.parse.urlsplit(self.path).path, d)


def starte(port=8765, oeffnen=True):
    srv = ThreadingHTTPServer(("127.0.0.1", port), _Handler)
    url = f"http://127.0.0.1:{port}"
    print(f"KOORDINAT-Oberflaeche laeuft: {url}   (beenden: Strg+C)")
    if oeffnen:
        try:
            webbrowser.open(url)
        except Exception:
            pass
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("beendet.")
    finally:
        srv.server_close()


SEITE = r"""<!doctype html>
<html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>KOORDINAT</title>
<style>
:root{--bg:#f6f6f3;--fl:#fff;--tx:#1d1d1f;--mt:#6e6e73;--ln:#e3e3df;--ak:#0a66c2;--ok:#1a7f37;--wa:#b26a00;--er:#c62828;--ch:#eef3fa}
@media (prefers-color-scheme:dark){:root{--bg:#111214;--fl:#1b1c1f;--tx:#ececee;--mt:#9a9aa2;--ln:#2c2d31;--ak:#5aa2ff;--ok:#4cc46a;--wa:#e6a23c;--er:#ff6b6b;--ch:#1f2733}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--tx);font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
header{position:sticky;top:0;z-index:2;background:var(--fl);border-bottom:1px solid var(--ln);padding:10px 16px;display:flex;gap:16px;align-items:center;flex-wrap:wrap}
header b{font-size:17px;letter-spacing:.04em}#puls{font-size:13px;color:var(--mt)}
nav{display:flex;gap:4px;flex-wrap:wrap}nav button{border:0;background:none;color:var(--mt);padding:6px 10px;border-radius:8px;cursor:pointer;font:inherit}
nav button.an{background:var(--ch);color:var(--ak);font-weight:600}
main{max-width:1100px;margin:0 auto;padding:16px}section{display:none}section.an{display:block}
.karten{display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:12px}
.k{background:var(--fl);border:1px solid var(--ln);border-radius:12px;padding:14px}.k h3{margin:0 0 4px;font-size:14px}
.zahl{font-size:28px;font-weight:650}.mt{color:var(--mt);font-size:13px}
input,select,textarea{font:inherit;color:var(--tx);background:var(--fl);border:1px solid var(--ln);border-radius:8px;padding:8px 10px}
textarea{width:100%;min-height:80px;resize:vertical}button.h{background:var(--ak);color:#fff;border:0;border-radius:8px;padding:8px 14px;font:inherit;cursor:pointer}
button.h:disabled{opacity:.5}.zeile{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:8px 0}
table{width:100%;border-collapse:collapse;background:var(--fl);border:1px solid var(--ln);border-radius:12px;overflow:hidden}
th,td{text-align:left;padding:7px 10px;border-bottom:1px solid var(--ln);vertical-align:top;font-size:14px}th{font-size:12px;color:var(--mt);font-weight:600}
code{font:13px ui-monospace,SFMono-Regular,Menlo,monospace;background:var(--ch);padding:1px 5px;border-radius:5px;word-break:break-word}
.tab-wrap{overflow-x:auto}.pill{display:inline-block;font-size:12px;padding:1px 8px;border-radius:99px;border:1px solid var(--ln);color:var(--mt)}
.gut{color:var(--ok)}.warn{color:var(--wa)}.schlecht{color:var(--er)}
#verlauf{display:flex;flex-direction:column;gap:10px;margin-bottom:12px}.msg{background:var(--fl);border:1px solid var(--ln);border-radius:12px;padding:10px 12px;white-space:pre-wrap}
.msg.du{background:var(--ch);align-self:flex-end;max-width:85%}.msg .mt{display:block;margin-bottom:4px}
.vergleich{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:10px}
pre{white-space:pre-wrap;background:var(--fl);border:1px solid var(--ln);border-radius:12px;padding:12px;margin:0}
a{color:var(--ak)}h2{font-size:18px;margin:4px 0 12px}
</style></head><body>
<header><b>KOORDINAT</b><span id="puls">lädt …</span>
<nav id="nav"></nav></header>
<main>
<section id="s-uebersicht"><h2>Übersicht</h2><div class="karten" id="karten"></div>
 <h2 style="margin-top:20px">Verbundene KIs</h2><div class="tab-wrap"><table id="t-anb"></table></div>
 <p class="mt">Schlüssel setzen: <code>koordinat schluessel &lt;anbieter&gt;</code> oder Umgebungsvariable. Lokale KIs (Ollama, LM Studio) brauchen keinen.</p></section>
<section id="s-chat"><h2>Mit KIs sprechen</h2>
 <div class="zeile"><select id="c-anb"></select><input id="c-mod" placeholder="Modell (leer = Standard)" size="22">
 <label class="mt">Effort <select id="c-eff"></select></label>
 <label class="mt"><input type="checkbox" id="c-alle"> an alle bereiten KIs (vergleichen)</label>
 <button onclick="neu()">Neues Gespräch</button></div>
 <input id="c-sys" placeholder="Systemanweisung (optional)" style="width:100%;margin-bottom:8px">
 <div id="verlauf"></div>
 <textarea id="c-txt" placeholder="Deine Nachricht … (Strg+Enter sendet)"></textarea>
 <div class="zeile"><button class="h" id="c-btn" onclick="sende()">Senden</button><span class="mt" id="c-info"></span></div></section>
<section id="s-katalog"><h2>Katalog geprüfter Repos</h2>
 <div class="zeile"><input id="k-q" placeholder="Suchen …" oninput="zeigeKatalog()"><select id="k-kat" onchange="zeigeKatalog()"></select><span class="mt" id="k-n"></span></div>
 <div class="tab-wrap"><table id="t-kat"></table></div>
 <p class="mt">Laden und prüfen: <code>koordinat installiere owner/name</code> · ganze Kategorie: <code>koordinat katalog-laden &lt;kategorie&gt;</code></p></section>
<section id="s-befehle"><h2>Befehle &amp; Regler aller Werkzeuge</h2>
 <div class="zeile"><input id="b-q" placeholder="z. B. effort, mcp, compact …" oninput="zeigeBefehle()"><select id="b-w" onchange="zeigeBefehle()"></select><span class="mt" id="b-n"></span></div>
 <div class="tab-wrap"><table id="t-bef"></table></div></section>
<section id="s-ablaeufe"><h2>Geführte Abläufe</h2>
 <div class="zeile"><input id="a-q" placeholder="Was willst du erreichen? z. B. KI-Video erstellen" size="40"><button class="h" onclick="ablauf(document.getElementById('a-q').value)">Plan zeigen</button></div>
 <div class="karten" id="a-liste"></div><div id="a-plan" style="margin-top:14px"></div></section>
<section id="s-guide"><h2>Guide: Grundbegriffe</h2>
 <div class="zeile"><input id="g-q" placeholder="Begriff, z. B. token, rag, lizenz"><button class="h" onclick="guideFrage()">Erklären</button></div>
 <pre id="g-text" style="display:none"></pre><div class="karten" id="g-liste" style="margin-top:12px"></div></section>
<section id="s-module"><h2>Module &amp; Vorschläge</h2>
 <div class="zeile"><input id="m-bed" placeholder="Bedarf melden, z. B. Tabellen aus PDF-Rechnungen" size="44"><button class="h" onclick="brauche()">Bedarf melden</button><span class="mt" id="m-info"></span></div>
 <h3>Installierte Module</h3><div class="tab-wrap"><table id="t-mod"></table></div>
 <h3>Vorschläge der Wachstumsschleife</h3><div class="tab-wrap"><table id="t-vor"></table></div>
 <p class="mt">Entscheiden: <code>koordinat annehmen &lt;nr&gt;</code> / <code>ablehnen &lt;nr&gt;</code> · Takt: <code>koordinat wachse</code></p></section>
<section id="s-system"><h2>System, Schalter &amp; Verfassung</h2><div id="sys"></div></section>
</main>
<script>
const T={uebersicht:"Übersicht",chat:"Chat",katalog:"Katalog",befehle:"Befehle",ablaeufe:"Abläufe",guide:"Guide",module:"Module",system:"System"};
const $=id=>document.getElementById(id), esc=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const api=(p)=>fetch(p).then(r=>r.json());
const poste=(p,d)=>fetch(p,{method:"POST",headers:{"Content-Type":"application/json","X-Koordinat":"1"},body:JSON.stringify(d)}).then(r=>r.json());
let U,KAT=[],BEF=[],VERLAUF=[];
function tab(n){for(const k in T){$("s-"+k).classList.toggle("an",k==n);$("n-"+k).classList.toggle("an",k==n)}try{localStorage.setItem("tab",n)}catch(e){}lade(n)}
$("nav").innerHTML=Object.entries(T).map(([k,v])=>`<button id="n-${k}" onclick="tab('${k}')">${v}</button>`).join("");
async function start(){U=await api("/api/uebersicht");
 $("puls").innerHTML=`v${esc(U.version)} · Puls ${U.puls} · Modus <span class="${U.modus=="normal"?"gut":"warn"}">${esc(U.modus)}</span>${U.stop?' · <span class="schlecht">STOP</span>':""}`;
 const k=[["KIs bereit",U.anbieter.filter(a=>a.bereit).length+" / "+U.anbieter.length,"chat"],["Katalog",U.katalog+" Repos","katalog"],["Befehle",U.befehle+" Einträge","befehle"],
  ["Abläufe",U.ablaeufe+" geführt","ablaeufe"],["Guide",U.guide+" Begriffe","guide"],["Module",U.module_an+" an / "+U.module,"module"],["Vorschläge",U.vorschlaege+" offen","module"],
  ["Kern",U.kern_intakt?"intakt":"PRÜFEN","system"]];
 $("karten").innerHTML=k.map(([t,z,n])=>`<div class="k" style="cursor:pointer" onclick="tab('${n}')"><h3>${t}</h3><div class="zahl">${esc(z)}</div></div>`).join("");
 $("t-anb").innerHTML="<tr><th>Anbieter</th><th>Bereit</th><th>Standardmodell</th><th>Effort-Regler</th><th>Schlüssel</th></tr>"+U.anbieter.map(a=>
  `<tr><td>${esc(a.name)}${a.standard?' <span class="pill">Standard</span>':""}<br><span class="mt">${esc(a.id)}</span></td><td class="${a.bereit?"gut":"mt"}">${a.bereit?"ja":"nein"}</td><td><code>${esc(a.modell||"–")}</code></td><td>${esc(a.effort)}</td><td><code>${esc(a.schluessel_variable)}</code></td></tr>`).join("");
 $("c-anb").innerHTML=U.anbieter.map(a=>`<option value="${a.id}" ${a.standard?"selected":""}>${esc(a.name)}${a.bereit?"":" (nicht bereit)"}</option>`).join("");
 $("c-eff").innerHTML=U.effort_stufen.map(e=>`<option ${e==U.effort?"selected":""}>${e}</option>`).join("");
 let t="uebersicht";try{t=localStorage.getItem("tab")||t}catch(e){} tab(T[t]?t:"uebersicht")}
async function lade(n){
 if(n=="katalog"&&!KAT.length){KAT=await api("/api/katalog");$("k-kat").innerHTML='<option value="">Alle Kategorien</option>'+[...new Set(KAT.map(e=>e.kategorie))].map(k=>`<option>${esc(k)}</option>`).join("");zeigeKatalog()}
 if(n=="befehle"&&!BEF.length){BEF=await api("/api/befehle");$("b-w").innerHTML='<option value="">Alle Werkzeuge</option>'+[...new Set(BEF.map(e=>e.werkzeug))].map(k=>`<option>${esc(k)}</option>`).join("");zeigeBefehle()}
 if(n=="ablaeufe"){const a=await api("/api/ablaeufe");$("a-liste").innerHTML=a.map(x=>`<div class="k" style="cursor:pointer" onclick="ablauf('${esc(x.id)}')"><h3>${esc(x.titel)}</h3><div class="mt">${esc(x.ziel)}</div><span class="pill">${x.schritte} Schritte</span></div>`).join("")}
 if(n=="guide"){const g=await api("/api/guide");$("g-liste").innerHTML=g.map(x=>`<div class="k" style="cursor:pointer" onclick="guideFrage('${esc(x.id)}')"><h3>${esc(x.titel)}</h3><div class="mt">${esc(x.kurz)}</div></div>`).join("")}
 if(n=="module"){const m=await api("/api/module"),v=await api("/api/vorschlaege");
  $("t-mod").innerHTML="<tr><th>Modul</th><th>Schalter</th><th>Score</th><th>Lizenz</th><th>Sicherheit</th><th>Vital</th></tr>"+(m.length?m.map(x=>`<tr><td>${esc(x.name)}</td><td class="${x.an?"gut":"mt"}">${x.an?"AN":"aus"}</td><td>${x.score}</td><td>${esc(x.lizenz||"keine")}</td><td>${esc(x.sicherheit)}</td><td>${x.vital??"–"}</td></tr>`).join(""):'<tr><td colspan="6" class="mt">Noch keine Module. Im Katalog etwas aussuchen und installieren.</td></tr>');
  $("t-vor").innerHTML="<tr><th>Nr</th><th>Repo</th><th>für Bedarf</th><th>Score</th><th>Status</th></tr>"+(v.length?v.map(x=>`<tr><td>${x.id}</td><td>${esc(x.repo)}<br><span class="mt">${esc(x.grund||"")}</span></td><td>${esc(x.bedarf)}</td><td>${x.score}</td><td>${esc(x.status)}</td></tr>`).join(""):'<tr><td colspan="5" class="mt">Keine Vorschläge.</td></tr>')}
 if(n=="system"){const s=await api("/api/system");
  $("sys").innerHTML=`<h3>Was die App selbstständig darf</h3><table><tr><th>Schalter</th><th>Stand</th><th>Wirkung</th></tr>${s.schalter.map(x=>`<tr><td><code>${esc(x.name)}</code></td><td class="${x.an?"gut":"mt"}">${x.an?"AN":"aus"}</td><td>${esc(x.text)}</td></tr>`).join("")}</table>
  <p class="mt">Umstellen nur über die Befehlszeile: <code>koordinat schalter &lt;name&gt; an|aus</code> · Not-Aus: <code>koordinat stop</code></p>
  <h3>Selbstverbessernde Algorithmen</h3><table><tr><th>Name</th><th>Fälle</th><th>Champion</th></tr>${s.algorithmen.map(a=>`<tr><td>${esc(a.name)}<br><span class="mt">${esc(a.beschreibung)}</span></td><td>${a.faelle}</td><td>v${a.champion||0}</td></tr>`).join("")}</table>
  <h3>Ziel</h3><pre>${esc(s.verfassung.ziel)}</pre><h3>Die Artikel</h3><table>${s.verfassung.artikel.map(([t,x])=>`<tr><td><b>${esc(t)}</b><br>${esc(x)}</td></tr>`).join("")}</table>
  <p class="mt">Protokoll intakt: ${s.protokoll_intakt?"ja":"NEIN"} · Hunger: ${esc(s.hunger.map(h=>h.problemtyp).join(", ")||"–")}</p>`}}
function zeigeKatalog(){const q=$("k-q").value.toLowerCase(),k=$("k-kat").value,l=KAT.filter(e=>(!k||e.kategorie==k)&&(e.repo+" "+e.zweck+" "+e.kategorie).toLowerCase().includes(q));
 $("k-n").textContent=l.length+" Repos";$("t-kat").innerHTML="<tr><th>Kategorie</th><th>Repo</th><th>Zweck</th><th>★</th><th>Lizenz</th></tr>"+l.map(e=>
 `<tr><td class="mt">${esc(e.kategorie)}</td><td><a href="https://github.com/${esc(e.repo)}" target="_blank" rel="noopener">${esc(e.repo)}</a></td><td>${esc(e.zweck)}</td><td>${e.sterne?e.sterne.toLocaleString("de"):"–"}</td><td>${esc(e.lizenz||"–")}</td></tr>`).join("")}
function zeigeBefehle(){const q=$("b-q").value.toLowerCase().split(/\s+/).filter(Boolean),w=$("b-w").value,l=BEF.filter(e=>(!w||e.werkzeug==w)&&q.every(x=>(e.werkzeug+" "+e.gruppe+" "+e.befehl+" "+e.was).toLowerCase().includes(x)));
 $("b-n").textContent=l.length+" Einträge";$("t-bef").innerHTML="<tr><th>Werkzeug</th><th>Gruppe</th><th>Befehl</th><th>Wirkung</th></tr>"+l.map(e=>
 `<tr><td>${esc(e.werkzeug)}</td><td class="mt">${esc(e.gruppe)}</td><td><code>${esc(e.befehl)}</code></td><td>${esc(e.was)}</td></tr>`).join("")}
async function ablauf(a){const p=await api("/api/ablauf?anliegen="+encodeURIComponent(a));
 if(!p.gefunden){$("a-plan").innerHTML='<p class="mt">Kein passender Ablauf. Wähle oben einen aus.</p>';return}
 $("a-plan").innerHTML=`<h2>${esc(p.titel)}</h2><p>${esc(p.ziel)}</p>`+p.schritte.map(s=>`<div class="k" style="margin-bottom:8px"><h3>Schritt ${s.nr}: ${esc(s.titel)}</h3><div style="white-space:pre-wrap">${esc(s.text)}</div>${s.befehl?`<div style="margin-top:6px"><code>${esc(s.befehl)}</code></div>`:""}${(s.projekte||[]).length?`<div class="mt" style="margin-top:6px">Projekte: ${s.projekte.map(esc).join(", ")}</div>`:""}</div>`).join("")}
async function guideFrage(b){b=b||$("g-q").value;const r=await api("/api/guide?q="+encodeURIComponent(b));$("g-text").style.display="block";$("g-text").textContent=r.text}
async function brauche(){const b=$("m-bed").value.trim();if(!b)return;const r=await poste("/api/brauche",{bedarf:b});$("m-info").textContent=r.fehler||("Bedarf "+r.id+" notiert. 'koordinat wachse' sucht dafür.")}
function neu(){VERLAUF=[];$("verlauf").innerHTML=""}
function zeig(rolle,text,info){const d=document.createElement("div");d.className="msg"+(rolle=="du"?" du":"");d.innerHTML=(info?`<span class="mt">${esc(info)}</span>`:"")+esc(text);$("verlauf").appendChild(d);d.scrollIntoView({block:"end"})}
async function sende(){const t=$("c-txt").value.trim();if(!t)return;$("c-btn").disabled=true;$("c-info").textContent="denkt …";zeig("du",t);$("c-txt").value="";
 const eff=$("c-eff").value,sys=$("c-sys").value.trim();
 try{if($("c-alle").checked){const r=await poste("/api/frage",{nachricht:t,alle:true,effort:eff,system:sys});const box=document.createElement("div");box.className="vergleich";
   (Array.isArray(r)?r:[r]).forEach(x=>{const d=document.createElement("div");d.className="msg";d.innerHTML=`<span class="mt">${esc(x.anbieter)} ${esc(x.modell||"")} ${x.sekunden?x.sekunden+" s":""}</span>`+esc(x.fehler?"Fehler: "+x.fehler:x.text);box.appendChild(d)});
   if(Array.isArray(r)&&!r.length)box.innerHTML='<div class="msg">Keine KI mit Schlüssel bereit.</div>';$("verlauf").appendChild(box)}
  else{const r=await poste("/api/frage",{nachricht:t,anbieter:$("c-anb").value,modell:$("c-mod").value.trim(),effort:eff,system:sys,verlauf:VERLAUF});
   if(r.fehler){zeig("ki","Fehler: "+r.fehler)}else{VERLAUF.push({role:"user",content:t},{role:"assistant",content:r.text});zeig("ki",r.text,`${r.anbieter} · ${r.modell||""} · ${r.sekunden} s · Effort ${eff}`)}}}
 catch(e){zeig("ki","Fehler: "+e)} $("c-btn").disabled=false;$("c-info").textContent=""}
$("c-txt").addEventListener("keydown",e=>{if(e.key=="Enter"&&(e.ctrlKey||e.metaKey))sende()});
start();
</script></body></html>"""
