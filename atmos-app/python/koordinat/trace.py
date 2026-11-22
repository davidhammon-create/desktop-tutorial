"""TRACE - jeder Schritt wird mitgeschrieben und erklaert. Keine Schluessel, keine langen Inhalte."""
import time
from . import verfassung
ARTEN = ("plan", "schritt", "werkzeug", "ergebnis", "halt", "fehler", "ende")
MAX_TEXT = 200
def _kuerzen(t):
    t = " ".join(str(t).split())
    return t if len(t) <= MAX_TEXT else t[:MAX_TEXT] + " ..."
def schreibe(db, lauf, art, text, erklaerung="", werkzeug="", modell="", cent=0.0):
    if art not in ARTEN:
        raise ValueError(f"unbekannte Art: {art}")
    t = _kuerzen(text)
    db.execute("INSERT INTO spur(zeit,lauf,art,text,erklaerung,werkzeug,modell,cent) "
               "VALUES(?,?,?,?,?,?,?,?)",
               (time.time(), lauf, art, t, _kuerzen(erklaerung), werkzeug, modell, float(cent)))
    db.commit()
    ordner = verfassung.HEIM / "laeufe" / str(lauf)
    ordner.mkdir(parents=True, exist_ok=True)
    with (ordner / "spur.log").open("a") as f:
        f.write(f"{time.strftime('%H:%M:%S')} {art:<9} {t}\n")
        if erklaerung:
            f.write(f"          -> {_kuerzen(erklaerung)}\n")
    return t
def zeige(db, lauf=None, n=80):
    wo, args = ("WHERE lauf=?", (lauf,)) if lauf else ("", ())
    zeilen = db.execute(f"SELECT zeit, lauf, art, text, erklaerung, modell, cent FROM spur {wo} "
                        "ORDER BY id DESC LIMIT ?", args + (n,)).fetchall()
    if not zeilen:
        return "Spur leer."
    z = []
    for zeit, lf, art, text, erk, modell, cent in reversed(zeilen):
        k = f"{time.strftime('%H:%M:%S', time.localtime(zeit))} L{lf} {art:<9} {text}"
        if modell:
            k += f" [{modell}]"
        if cent:
            k += f" ({cent:.2f} Cent)"
        z.append(k)
        if erk:
            z.append(f"          {erk}")
    return "\n".join(z)
def zaehle(db, lauf=None):
    wo, args = ("WHERE lauf=?", (lauf,)) if lauf else ("", ())
    r = db.execute(f"SELECT COUNT(*), COALESCE(SUM(cent),0) FROM spur {wo}", args).fetchone()
    return dict(zeilen=r[0], cent=r[1])
