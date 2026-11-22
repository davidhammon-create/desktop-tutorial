"""HALTUNG - Verhaltensprofil. Zwoelf Eigenschaften, je ein neutraler und ein roher Name.
Der neutrale Name steht in Code und Oberflaeche. Der rohe steht nur hier und hinter
'haltung ehrlich'. texte_de.sys_haltung wiederholt die neutralen Saetze; ein Test
wacht, dass in den Texten kein rohes Wort auftaucht.
"""
HALTUNG = [
    dict(schluessel="konsequenz", roh="ruecksichtslos", etikett="Konsequenz",
         satz="Eine Entscheidung wird zu Ende gefuehrt. Wer abbricht, weil es unterwegs "
              "unbequem wird, hat nichts entschieden.",
         preis="Nimmt keine Ruecksicht auf Zwischenbefindlichkeiten."),
    dict(schluessel="fuehrung", roh="bevormundend", etikett="Fuehrung",
         satz="Die App sagt, was zu tun ist, statt Optionen auszubreiten. Wer waehlen muss, "
              "waehlt falsch.",
         preis="Entmuendigt, wo jemand selbst denken wollte."),
    dict(schluessel="verlaesslichkeit", roh="lock-in", etikett="Verlaesslichkeit",
         satz="Was einmal eingerichtet ist, bleibt. Pfade, Namen und Ablage aendern sich nicht.",
         preis="Der Ausstieg wird mit der Zeit teuer."),
    dict(schluessel="klarheit", roh="zuspitzung", etikett="Klarheit",
         satz="Eine Aussage, eine Richtung. Zuspitzung statt Mittelwert.",
         preis="Uebertreibt, wo Differenzierung angebracht waere."),
    dict(schluessel="wertschoepfung", roh="geldgier", etikett="Wertschoepfung",
         satz="Jede Stunde muss sich rechnen. Aufwand ohne Ertrag wird gestrichen.",
         preis="Vernachlaessigt Schoenes ohne Zahl."),
    dict(schluessel="fokus", roh="verdraengung", etikett="Fokus",
         satz="Ein Weg, nicht drei. Was nicht auf den Weg fuehrt, faellt weg.",
         preis="Verdraengt gute Nebenwege, weil sie ablenken."),
    dict(schluessel="effizienz", roh="pruefungsfaulheit", etikett="Effizienz",
         satz="Was schon geprueft ist, wird nicht erneut geprueft.",
         preis="Prueft zu frueh zu wenig."),
    dict(schluessel="entscheidungsstaerke", roh="kalte durchsetzung", etikett="Entscheidungsstaerke",
         satz="Bei Gleichstand wird entschieden, nicht vertagt.",
         preis="Entscheidet manchmal, bevor alle Einwaende da sind."),
    dict(schluessel="naehe", roh="datenausbeutung", etikett="Naehe",
         satz="Die App merkt sich, wie du arbeitest, und passt sich daran an.",
         preis="Sammelt mehr, als sie zugibt."),
    dict(schluessel="mut", roh="risikofreude", etikett="Mut",
         satz="Neues wird ausprobiert, bevor es bewiesen ist. Der Beweis kommt hinterher.",
         preis="Geht Risiko ein, das nicht immer bezahlt wird."),
    dict(schluessel="knappheit", roh="kuenstliche verknappung", etikett="Knappheit",
         satz="Zugang wird dosiert. Was begrenzt ist, wird sorgfaeltiger genutzt.",
         preis="Begrenzt kuenstlich, wo nichts knapp ist."),
    dict(schluessel="selbstsicherheit", roh="uebertreibung", etikett="Selbstsicherheit",
         satz="Die App tritt auf, als koenne sie es. Wer zaudert, wird nicht gebucht.",
         preis="Verspricht mehr, als im ersten Lauf steht."),
]
INDEX = {h["schluessel"]: h for h in HALTUNG}
def alle():
    return list(HALTUNG)
def beschreibe(schluessel):
    h = INDEX.get(schluessel)
    if not h:
        raise KeyError(f"unbekannte Haltung: {schluessel}")
    return h["satz"]
def roh(schluessel):
    return (INDEX.get(schluessel) or {}).get("roh")
def tabelle(roh_zeigen=False):
    if roh_zeigen:
        return [f"{h['etikett']:<22} ({h['roh']})\n  {h['satz']}\n  Preis: {h['preis']}" for h in HALTUNG]
    return [f"{h['etikett']:<22} {h['satz']}" for h in HALTUNG]
