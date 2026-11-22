"""MODELLE - Auswahl nach Staerke und Haerte, nicht nach Anbieter.
Haerte 3: moralisiert nicht. Haerte 1: klug, aber weich. Der Planer setzt die
Mindesthaerte je Schritt. Kosten laufen ueber apireg.
"""
import random
MODELLE = [
    dict(name="venice-uncensored", haerte=3, staerke=74, lokal=False, api="venice"),
    dict(name="deepseek-v3", haerte=3, staerke=91, lokal=False, api="deepseek"),
    dict(name="qwen-2.5-72b", haerte=3, staerke=83, lokal=False, api="together"),
    dict(name="kimi-k2", haerte=2, staerke=86, lokal=False, api="moonshot"),
    dict(name="glm-4.6", haerte=2, staerke=81, lokal=False, api="zhipu"),
    dict(name="mistral-large", haerte=2, staerke=78, lokal=False, api="mistral"),
    dict(name="llama-3.3-70b", haerte=2, staerke=77, lokal=False, api="groq"),
    dict(name="ollama-lokal", haerte=2, staerke=56, lokal=True, api="ollama"),
    dict(name="grok-4", haerte=2, staerke=88, lokal=False, api="xai"),
    dict(name="claude-sonnet", haerte=1, staerke=87, lokal=False, api="anthropic"),
    dict(name="gpt-4o", haerte=1, staerke=86, lokal=False, api="openai"),
    dict(name="gemini-2.5-pro", haerte=1, staerke=85, lokal=False, api="google"),
]
HAERTE_TEXT = {3: "haelt", 2: "zaehmt selten", 1: "zaehmt"}
MINDEST = {"erklaeren": 3, "schreiben": 3, "pruefen": 2, "bauen": 2, "suchen": 2}
def alle():
    return sorted(MODELLE, key=lambda m: (-m["haerte"], -m["staerke"]))
def waehle(haerte_min=1, staerke_min=0, nur_lokal=False):
    k = [m for m in MODELLE if m["haerte"] >= haerte_min and m["staerke"] >= staerke_min
         and (m["lokal"] or not nur_lokal)]
    if not k:
        return None
    top = max(m["staerke"] for m in k)
    return random.choice([m for m in k if m["staerke"] == top])
def fuer_schritt(art, nur_lokal=False):
    return waehle(MINDEST.get(art, 1), nur_lokal=nur_lokal)
def profil():
    return dict(gesamt=len(MODELLE), haelt=sum(m["haerte"] == 3 for m in MODELLE),
                lokal=sum(m["lokal"] for m in MODELLE))
def bericht():
    z = [f"{len(MODELLE)} Modelle, davon {profil()['haelt']} ohne Zaehmung"]
    for m in alle():
        z.append(f"  Haerte {m['haerte']} {m['name']:<20} Staerke {m['staerke']:>3} "
                 f"{'lokal' if m['lokal'] else 'API':<5} {HAERTE_TEXT[m['haerte']]}")
    return "\n".join(z)
