"""PANEL - eine Seite, zwei Spalten: Griffe links, alles sichtbar rechts. Nur lokal."""
import http.server, json, socketserver
from . import apireg, erklaeren, haltung, speicher, trace, verfassung, vital as vitalmod, wachstum, werkstatt
SEITE = """<!DOCTYPE html><html lang=de><meta charset=utf-8><title>KOORDINAT</title>
<style>
:root{--b:#fff;--t:#1d1d1f;--m:#6e6e73;--l:#f5f5f7;--a:#b25000}
*{box-sizing:border-box}body{margin:0;font:14px/1.55 -apple-system,Helvetica,sans-serif;
color:var(--t);background:var(--b);display:grid;grid-template-columns:300px 1fr;min-height:100vh}
aside{background:var(--l);padding:18px;border-right:1px solid #e5e5ea}
main{padding:18px 22px}h1{font-size:17px;margin:0 0 4px;letter-spacing:-.3px}
.s{font-size:12px;color:var(--m);margin:0 0 16px}
button{font:13px/1 inherit;padding:9px 11px;border:0;border-radius:9px;background:#fff;color:var(--t);
cursor:pointer;width:100%;text-align:left;margin-bottom:5px;font-weight:500}button:hover{background:#e8e8ed}
input{width:100%;font:13px/1.4 inherit;padding:8px;border:1px solid #d2d2d7;border-radius:8px;
margin-bottom:6px;background:#fff;color:var(--t)}
pre{font:11.5px/1.5 ui-monospace,Menlo,monospace;background:var(--l);border-radius:10px;padding:12px;
white-space:pre-wrap;word-break:break-word;margin:0}
.k{font-size:11px;text-transform:uppercase;letter-spacing:.7px;color:var(--m);margin:16px 0 6px}
</style>
<aside><h1>KOORDINAT</h1><p class=s id=kopf></p>
<div class=k>Auftrag</div><input id=auftrag placeholder="was soll entstehen">
<button onclick="mach()">Planen und starten</button>
<div class=k>Laeufe</div><div id=laeufe></div>
<div class=k>Werkstatt</div><button onclick="ruf('/api/wachse')">Takt fahren</button>
<button onclick="ruf('/api/vorschlaege')">Vorschlaege</button>
<div class=k>Lehre</div><input id=begriff placeholder="Begriff"><button onclick="erk()">Erklaeren</button>
<div class=k>Profil</div><button onclick="ruf('/api/haltung')">Tafel</button>
<div class=k>System</div><button onclick="ruf('/api/stop')">STOP umschalten</button></aside>
<main><div id=aus><pre>Bereit.</pre></div></main>
<script>
const esc=t=>t.replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
const zeig=t=>document.getElementById('aus').innerHTML='<pre>'+esc(t)+'</pre>';
async function ruf(p){zeig(await (await fetch(p,{method:'POST'})).text());lade()}
async function mach(){const a=document.getElementById('auftrag').value;if(a)zeig(await (await fetch('/api/mach',{method:'POST',body:a})).text()),lade()}
async function erk(){const b=document.getElementById('begriff').value;if(b)zeig(await (await fetch('/api/erklaere',{method:'POST',body:b})).text())}
async function spur(i){zeig(await (await fetch('/api/trace/'+i,{method:'POST'})).text())}
async function lade(){const d=await (await fetch('/api/stand')).json();
document.getElementById('kopf').textContent='Puls '+d.puls+' '+d.modus+' ? Ampel '+d.ampel+' ? '+d.an+' Module an';
document.getElementById('laeufe').innerHTML=d.laeufe.map(l=>'<button onclick="spur('+l.id+')">#'+l.id+' '+esc(l.titel)+' ('+l.stand+')</button>').join('')}
setInterval(lade,4000);lade();
</script></html>"""
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass
    def _send(self, t, art="text/plain"):
        b = t.encode()
        self.send_response(200)
        self.send_header("Content-Type", art + "; charset=utf-8")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)
    def do_GET(self):
        if self.path in ("/", "/index.html"):
            return self._send(SEITE, "text/html")
        if self.path == "/api/stand":
            db, v = speicher.db(), None
            v = vitalmod.Vital(db)
            return self._send(json.dumps(dict(
                puls=v.puls(), modus=v.modus(), ampel=apireg.ampel(db),
                an=db.execute("SELECT COUNT(*) FROM modul WHERE schalter=1").fetchone()[0],
                laeufe=werkstatt.laeufe(db))), "application/json")
        self._send("unbekannt")
    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        leib = self.rfile.read(n).decode() if n else ""
        db = speicher.db()
        v = vitalmod.Vital(db)
        p = self.path
        try:
            if p == "/api/mach":
                from . import planer
                lauf, m = werkstatt.starte(db, v, planer.plan(leib))
                return self._send(m + "\n\n" + (werkstatt.stand(db, lauf) if lauf else ""))
            if p == "/api/wachse":
                r = wachstum.zyklus(db, v)
                return self._send(json.dumps({k: r[k] for k in ("status", "geladen", "eingeschaltet",
                                                                "entdeckt", "wartet_auf_dich")},
                                             ensure_ascii=False, indent=1))
            if p == "/api/vorschlaege":
                return self._send("\n".join(f"{x['id']:>3} {x['repo']} {x['score']} {x['bedarf'][:30]}"
                                            for x in wachstum.vorschlaege(db)) or "keine")
            if p == "/api/haltung":
                return self._send("\n".join(haltung.tabelle(True)))
            if p == "/api/stop":
                if verfassung.stop_gesetzt():
                    verfassung.STOP.unlink()
                    return self._send("STOP aufgehoben.")
                verfassung.abschalten("Panel")
                return self._send("STOP gesetzt.")
            if p == "/api/erklaere":
                return self._send(erklaeren.erklaere(db, leib))
            if p.startswith("/api/trace/"):
                return self._send(trace.zeige(db, int(p.rsplit("/", 1)[1]), 60))
        except Exception as e:
            return self._send(f"Fehler: {type(e).__name__}: {e}")
        self._send("unbekannt")
def starte(port=8712):
    with socketserver.TCPServer(("127.0.0.1", port), H) as s:
        print(f"Panel: http://127.0.0.1:{port}  (nur lokal)")
        s.serve_forever()
