"""ANBIETER - eine Schnittstelle zu allen KIs (nur Standardbibliothek).

Drei Bauarten decken praktisch jeden Anbieter ab:
    anthropic   Claude (Messages-API)
    gemini      Google Gemini (generateContent)
    openai      OpenAI und alles, was die OpenAI-Schnittstelle spricht: Mistral, Groq, DeepSeek, xAI,
                OpenRouter, Together, Perplexity, Fireworks, Cerebras, Ollama, LM Studio, vLLM, LiteLLM ...

Ein einheitlicher Effort-Regler (aus | low | medium | high | xhigh | max) wird je Anbieter auf dessen
eigenen Parameter uebersetzt. Schluessel kommen aus der Umgebung oder aus ~/.koordinat/schluessel.json
(Dateirechte 600). Kein Schluessel verlaesst den Rechner ausser zum jeweiligen Anbieter, und keiner wird
je ueber MCP oder die Oberflaeche angezeigt.

Standardmodelle sind Startwerte. Die aktuelle Liste eines Anbieters liefert `koordinat modelle <anbieter>`;
ein eigenes Standardmodell setzt `koordinat anbieter <id> modell <name>`.
"""
import concurrent.futures, json, os, time, urllib.error, urllib.request
from . import verfassung

EFFORT = ("aus", "low", "medium", "high", "xhigh", "max")

# id: name, bauart, basis-URL, Umgebungsvariable(n) fuer den Schluessel, Standardmodell, Effort-Uebersetzung, Doku
ANBIETER = {
    "anthropic":  dict(name="Anthropic Claude", bauart="anthropic", basis="https://api.anthropic.com/v1",
                       env=["ANTHROPIC_API_KEY"], modell="claude-opus-5-5", effort="output_config.effort",
                       doku="https://platform.claude.com/docs"),
    "openai":     dict(name="OpenAI", bauart="openai", basis="https://api.openai.com/v1",
                       env=["OPENAI_API_KEY"], modell="gpt-5", effort="reasoning_effort",
                       doku="https://platform.openai.com/docs"),
    "gemini":     dict(name="Google Gemini", bauart="gemini", basis="https://generativelanguage.googleapis.com/v1beta",
                       env=["GEMINI_API_KEY", "GOOGLE_API_KEY"], modell="gemini-2.5-flash", effort="thinkingBudget",
                       doku="https://ai.google.dev/gemini-api/docs"),
    "mistral":    dict(name="Mistral", bauart="openai", basis="https://api.mistral.ai/v1",
                       env=["MISTRAL_API_KEY"], modell="mistral-large-latest", effort=None,
                       doku="https://docs.mistral.ai"),
    "deepseek":   dict(name="DeepSeek", bauart="openai", basis="https://api.deepseek.com/v1",
                       env=["DEEPSEEK_API_KEY"], modell="deepseek-chat", effort=None,
                       doku="https://api-docs.deepseek.com"),
    "xai":        dict(name="xAI Grok", bauart="openai", basis="https://api.x.ai/v1",
                       env=["XAI_API_KEY"], modell="grok-4", effort=None, doku="https://docs.x.ai"),
    "groq":       dict(name="Groq", bauart="openai", basis="https://api.groq.com/openai/v1",
                       env=["GROQ_API_KEY"], modell="llama-3.3-70b-versatile", effort=None,
                       doku="https://console.groq.com/docs"),
    "openrouter": dict(name="OpenRouter (hunderte Modelle)", bauart="openai", basis="https://openrouter.ai/api/v1",
                       env=["OPENROUTER_API_KEY"], modell="openrouter/auto", effort="reasoning.effort",
                       doku="https://openrouter.ai/docs"),
    "together":   dict(name="Together AI", bauart="openai", basis="https://api.together.xyz/v1",
                       env=["TOGETHER_API_KEY"], modell="meta-llama/Llama-3.3-70B-Instruct-Turbo", effort=None,
                       doku="https://docs.together.ai"),
    "perplexity": dict(name="Perplexity (mit Websuche)", bauart="openai", basis="https://api.perplexity.ai",
                       env=["PERPLEXITY_API_KEY"], modell="sonar", effort=None, doku="https://docs.perplexity.ai"),
    "fireworks":  dict(name="Fireworks AI", bauart="openai", basis="https://api.fireworks.ai/inference/v1",
                       env=["FIREWORKS_API_KEY"], modell="accounts/fireworks/models/llama-v3p3-70b-instruct",
                       effort=None, doku="https://docs.fireworks.ai"),
    "cerebras":   dict(name="Cerebras", bauart="openai", basis="https://api.cerebras.ai/v1",
                       env=["CEREBRAS_API_KEY"], modell="llama-3.3-70b", effort=None,
                       doku="https://inference-docs.cerebras.ai"),
    "ollama":     dict(name="Ollama (lokal, kostenlos)", bauart="openai", basis="http://localhost:11434/v1",
                       env=[], modell="llama3.2", effort=None, lokal=True, doku="https://github.com/ollama/ollama"),
    "lmstudio":   dict(name="LM Studio (lokal)", bauart="openai", basis="http://localhost:1234/v1",
                       env=[], modell="local-model", effort=None, lokal=True, doku="https://lmstudio.ai/docs"),
    "eigener":    dict(name="Eigener Server (OpenAI-kompatibel: vLLM, LiteLLM, LocalAI ...)", bauart="openai",
                       basis="http://localhost:8000/v1", env=["KOORDINAT_EIGENER_KEY"], modell="", effort=None,
                       lokal=True, doku="koordinat anbieter eigener basis <url>"),
}

# Effort -> Anbieter-Parameter
_OPENAI_EFFORT = {"low": "low", "medium": "medium", "high": "high", "xhigh": "high", "max": "high"}
_GEMINI_BUDGET = {"low": 1024, "medium": 8192, "high": 24576, "xhigh": 32768, "max": -1}   # -1 = Modell entscheidet
_FALLBACK_BETA = "server-side-fallback-2026-07-01"
_MIT_FALLBACK = ("claude-fable-5-2", "claude-fable-5-1", "claude-opus-5-5", "claude-opus-5", "claude-sonnet-5-5")


# ------------------------------------------------------------------ Einstellungen und Schluessel
def _datei(name):
    return verfassung.HEIM / name


def _lies(name):
    try:
        return json.loads(_datei(name).read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def _schreibe(name, daten, geheim=False):
    verfassung.HEIM.mkdir(parents=True, exist_ok=True)
    p = _datei(name)
    p.write_text(json.dumps(daten, indent=1, ensure_ascii=False))
    if geheim:
        os.chmod(p, 0o600)


def einstellungen():
    return _lies("anbieter.json")


def setze(anbieter_id, feld, wert):
    """Setzt modell | basis | standard (welcher Anbieter ohne Angabe genutzt wird) | effort (Standard-Effort)."""
    e = einstellungen()
    if feld in ("standard", "effort"):
        if feld == "standard" and anbieter_id not in ANBIETER:
            raise KeyError(f"unbekannter Anbieter: {anbieter_id}")
        if feld == "effort" and wert not in EFFORT:
            raise ValueError(f"Effort muss einer von {', '.join(EFFORT)} sein")
        e["_" + feld] = anbieter_id if feld == "standard" else wert
    else:
        if anbieter_id not in ANBIETER:
            raise KeyError(f"unbekannter Anbieter: {anbieter_id}")
        if feld not in ("modell", "basis"):
            raise ValueError("Feld muss modell oder basis sein")
        e.setdefault(anbieter_id, {})[feld] = wert
    _schreibe("anbieter.json", e)


def setze_schluessel(anbieter_id, schluessel):
    if anbieter_id not in ANBIETER:
        raise KeyError(f"unbekannter Anbieter: {anbieter_id}")
    s = _lies("schluessel.json")
    if schluessel:
        s[anbieter_id] = schluessel.strip()
    else:
        s.pop(anbieter_id, None)
    _schreibe("schluessel.json", s, geheim=True)


def schluessel(anbieter_id):
    for n in ANBIETER[anbieter_id]["env"]:
        if os.environ.get(n):
            return os.environ[n]
    return _lies("schluessel.json").get(anbieter_id)


def konfig(anbieter_id):
    if anbieter_id not in ANBIETER:
        raise KeyError(f"unbekannter Anbieter: {anbieter_id}. Bekannt: {', '.join(ANBIETER)}")
    k = dict(ANBIETER[anbieter_id], id=anbieter_id)
    k.update(einstellungen().get(anbieter_id, {}))
    if anbieter_id == "eigener" and os.environ.get("KOORDINAT_EIGENER_BASIS"):
        k["basis"] = os.environ["KOORDINAT_EIGENER_BASIS"]
    return k


def standard_anbieter():
    e = einstellungen().get("_standard")
    if e:
        return e
    for a in ANBIETER:                      # erster Anbieter mit Schluessel
        if ANBIETER[a]["env"] and schluessel(a):
            return a
    return "ollama"


def standard_effort():
    return einstellungen().get("_effort", "high")


def _erreichbar(basis, timeout=0.4):
    """Lokale Dienste: kurzer Blick, ob unter der Adresse etwas antwortet."""
    try:
        urllib.request.urlopen(urllib.request.Request(basis + "/models"), timeout=timeout).close()
        return True
    except urllib.error.HTTPError:
        return True                          # antwortet, nur ohne Freigabe
    except Exception:
        return False


def uebersicht(pruefen=True):
    """Alle Anbieter mit Stand - ohne Schluessel, nur ob einer da ist. Lokale werden kurz angepingt."""
    std = standard_anbieter()
    out = []
    for a in ANBIETER:
        k = konfig(a)
        bereit = bool(schluessel(a)) if not k.get("lokal") else (pruefen and _erreichbar(k["basis"]))
        out.append(dict(id=a, name=k["name"], bauart=k["bauart"], modell=k["modell"], basis=k["basis"],
                        bereit=bool(bereit), lokal=bool(k.get("lokal")),
                        schluessel_variable=(k["env"] or ["-"])[0], effort=k["effort"] or "-",
                        standard=a == std, doku=k["doku"]))
    return out


# ------------------------------------------------------------------ Anfragen bauen (ohne Netz pruefbar)
def _nachrichten(nachricht, verlauf):
    m = [dict(x) for x in (verlauf or [])]
    if nachricht:
        m.append(dict(role="user", content=nachricht))
    return m


def baue(anbieter_id, nachricht, verlauf=None, modell=None, effort=None, system=None, max_tokens=16000):
    """Liefert (url, kopfzeilen, koerper) fuer genau eine Anfrage. Effort None -> Standard-Effort."""
    k = konfig(anbieter_id)
    modell = modell or k["modell"]
    if not modell:
        raise ValueError(f"Fuer {anbieter_id} ist kein Modell gesetzt: koordinat anbieter {anbieter_id} modell <name>")
    effort = effort or standard_effort()
    if effort not in EFFORT:
        raise ValueError(f"Effort muss einer von {', '.join(EFFORT)} sein")
    msgs = _nachrichten(nachricht, verlauf)
    key = schluessel(anbieter_id)
    h = {"content-type": "application/json", "user-agent": "koordinat"}

    if k["bauart"] == "anthropic":
        h.update({"x-api-key": key or "", "anthropic-version": "2023-06-01"})
        body = dict(model=modell, max_tokens=max_tokens, messages=msgs)
        if system:
            body["system"] = system
        if effort != "aus":
            body["output_config"] = {"effort": effort}
        if modell in _MIT_FALLBACK:          # bei Ablehnung uebernimmt serverseitig ein passendes Modell
            h["anthropic-beta"] = _FALLBACK_BETA
            body["fallbacks"] = "default"
        return k["basis"] + "/messages", h, body

    if k["bauart"] == "gemini":
        h["x-goog-api-key"] = key or ""
        inhalt = [dict(role="model" if x["role"] == "assistant" else "user", parts=[dict(text=x["content"])]) for x in msgs]
        body = dict(contents=inhalt)
        if system:
            body["systemInstruction"] = dict(parts=[dict(text=system)])
        if effort != "aus":
            body["generationConfig"] = dict(thinkingConfig=dict(thinkingBudget=_GEMINI_BUDGET[effort]))
        return f"{k['basis']}/models/{modell}:generateContent", h, body

    # OpenAI-kompatibel
    if key:
        h["authorization"] = "Bearer " + key
    body = dict(model=modell, messages=([dict(role="system", content=system)] if system else []) + msgs)
    if effort != "aus" and k["effort"] == "reasoning_effort":
        body["reasoning_effort"] = _OPENAI_EFFORT[effort]
    elif effort != "aus" and k["effort"] == "reasoning.effort":
        body["reasoning"] = {"effort": _OPENAI_EFFORT[effort]}
    return k["basis"] + "/chat/completions", h, body


def lies_antwort(bauart, daten):
    """Zieht Text, Modell und Verbrauch aus der Antwort einer der drei Bauarten."""
    if bauart == "anthropic":
        if daten.get("stop_reason") == "refusal":
            d = daten.get("stop_details") or {}
            return dict(text="[abgelehnt] " + (d.get("explanation") or d.get("category") or ""), modell=daten.get("model"),
                        verbrauch=daten.get("usage"), ende="refusal")
        text = "".join(b.get("text", "") for b in daten.get("content", []) if b.get("type") == "text")
        return dict(text=text, modell=daten.get("model"), verbrauch=daten.get("usage"), ende=daten.get("stop_reason"))
    if bauart == "gemini":
        kand = (daten.get("candidates") or [{}])[0]
        text = "".join(p.get("text", "") for p in kand.get("content", {}).get("parts", []) if not p.get("thought"))
        return dict(text=text, modell=daten.get("modelVersion"), verbrauch=daten.get("usageMetadata"), ende=kand.get("finishReason"))
    wahl = (daten.get("choices") or [{}])[0]
    return dict(text=(wahl.get("message") or {}).get("content") or "", modell=daten.get("model"),
                verbrauch=daten.get("usage"), ende=wahl.get("finish_reason"))


# ------------------------------------------------------------------ Netz
def _http(url, h, body=None, timeout=600):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, headers=h,
                                 method="POST" if body is not None else "GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        try:
            info = json.loads(e.read())
            info = (info.get("error") or {}).get("message") if isinstance(info.get("error"), dict) else info.get("error") or info
        except Exception:
            info = e.reason
        raise RuntimeError(f"HTTP {e.code}: {info}") from None
    except urllib.error.URLError as e:
        raise RuntimeError(f"nicht erreichbar ({e.reason}). Laeuft der Dienst / stimmt die Adresse?") from None


def frage(nachricht, anbieter_id=None, modell=None, effort=None, system=None, verlauf=None, senden=_http):
    """Stellt einer KI eine Frage. Gibt dict(text, modell, verbrauch, ende, anbieter, sekunden) zurueck."""
    if verfassung.stop_gesetzt():
        raise PermissionError("STOP ist gesetzt.")
    anbieter_id = anbieter_id or standard_anbieter()
    k = konfig(anbieter_id)
    if not k.get("lokal") and not schluessel(anbieter_id) and senden is _http:
        raise PermissionError(f"Kein Schluessel fuer {k['name']}. Setzen: Umgebungsvariable {k['env'][0]} "
                              f"oder 'koordinat schluessel {anbieter_id}'.")
    url, h, body = baue(anbieter_id, nachricht, verlauf, modell, effort, system)
    t = time.time()
    out = lies_antwort(k["bauart"], senden(url, h, body))
    out.update(anbieter=anbieter_id, sekunden=round(time.time() - t, 1))
    return out


def frage_alle(nachricht, anbieter=None, effort=None, system=None, senden=_http):
    """Dieselbe Frage parallel an mehrere KIs (Standard: alle, die bereit sind) - zum Vergleichen."""
    ids = anbieter or [a["id"] for a in uebersicht() if a["bereit"] and a["modell"]]

    def eins(a):
        try:
            return frage(nachricht, a, effort=effort, system=system, senden=senden)
        except Exception as e:
            return dict(anbieter=a, text="", fehler=str(e))
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, min(8, len(ids)))) as ex:
        return list(ex.map(eins, ids))


def modelle(anbieter_id, senden=_http):
    """Holt die aktuelle Modellliste direkt beim Anbieter."""
    k = konfig(anbieter_id)
    key = schluessel(anbieter_id)
    if k["bauart"] == "anthropic":
        d = senden(k["basis"] + "/models?limit=100", {"x-api-key": key or "", "anthropic-version": "2023-06-01"})
        return [m["id"] for m in d.get("data", [])]
    if k["bauart"] == "gemini":
        d = senden(k["basis"] + "/models?pageSize=200", {"x-goog-api-key": key or ""})
        return [m["name"].split("/", 1)[-1] for m in d.get("models", [])]
    d = senden(k["basis"] + "/models", {"authorization": "Bearer " + key} if key else {})
    return sorted(m["id"] for m in d.get("data", []))
