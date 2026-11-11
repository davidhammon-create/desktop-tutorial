#!/usr/bin/env python3
"""Erzeugt die Rückgabe-Einzeldatei im Format des Uploads (// FILE: <Pfad>).

Enthalten sind nur Dateien, die gegenüber dem Upload neu sind oder deren Code
sich geändert hat (Kommentare und Leerzeilen zählen nicht als Änderung).

Aufruf: generate-rueckgabe-txt.py <Upload-Verzeichnis> <Ausgabedatei>
"""
import os, re, sys, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Oberflächen-Dateien aus früheren Lieferungen, die noch nie gegen die App
# gebaut wurden; sie bleiben im Repository, gehen aber nicht in die Rückgabe.
AUSGENOMMEN = {
    "Sources/FenlynineOS/Features/Waechter/WaechterView.swift",
    "Sources/FenlynineOS/Features/Waechter/Pruefsichten.swift",
    "Sources/FenlynineOS/Features/Shell/ProfilAuswahlView.swift",
}

def ohne_kommentare(src):
    out = []; i = 0; n = len(src); instr = False; multi = False
    while i < n:
        c = src[i]
        if instr:
            if multi and src.startswith('"""', i): out.append('"""'); i += 3; instr = multi = False; continue
            if c == '\\' and i + 1 < n: out.append(src[i:i+2]); i += 2; continue
            if not multi and c in '"\n': instr = False
            out.append(c); i += 1; continue
        if src.startswith('"""', i): instr = multi = True; out.append('"""'); i += 3; continue
        if c == '"': instr = True; out.append(c); i += 1; continue
        if src.startswith('//', i):
            while i < n and src[i] != '\n': i += 1
            continue
        if src.startswith('/*', i):
            d = 1; i += 2
            while i < n and d > 0:
                if src.startswith('/*', i): d += 1; i += 2
                elif src.startswith('*/', i): d -= 1; i += 2
                else: i += 1
            continue
        out.append(c); i += 1
    return ''.join(out)

def norm(path):
    s = ohne_kommentare(open(path, encoding="utf-8").read())
    return [re.sub(r'\s+', ' ', l).strip() for l in s.split('\n') if l.strip()]

def main():
    upload, ziel = sys.argv[1], sys.argv[2]
    neu, geaendert = [], []
    for basis in ("Sources", "Tests"):
        for d, _, fs in os.walk(os.path.join(ROOT, basis)):
            for f in sorted(fs):
                if not f.endswith(".swift"): continue
                p = os.path.join(d, f); rel = os.path.relpath(p, ROOT)
                if rel in AUSGENOMMEN: continue
                u = os.path.join(upload, rel)
                if not os.path.exists(u): neu.append(rel)
                elif norm(p) != norm(u): geaendert.append(rel)
    neu.sort(); geaendert.sort()
    with open(ziel, "w", encoding="utf-8") as o:
        o.write("FENLYNINEOS — RÜCKGABE VON CLAUDE\n")
        o.write(f"Zeit: {datetime.datetime.now():%Y-%m-%d %H:%M}\n")
        o.write(f"Dateien: {len(neu) + len(geaendert)} ({len(neu)} neu, {len(geaendert)} geändert)\n")
        o.write("Jede Datei beginnt mit: // FILE: <relativer Pfad>\n")
        o.write("Jede Datei ist vollständig und ersetzt die gleichnamige Datei bzw. wird neu angelegt.\n")
        o.write("NEU:\n" + "".join(f"  {r}\n" for r in neu))
        o.write("GEÄNDERT:\n" + "".join(f"  {r}\n" for r in geaendert))
        o.write("=" * 78 + "\n")
        for rel in neu + geaendert:
            o.write(f"\n// FILE: {rel}\n")
            o.write(open(os.path.join(ROOT, rel), encoding="utf-8").read().rstrip("\n") + "\n")
    print(f"{ziel}: {len(neu)} neu, {len(geaendert)} geändert")
    for r in geaendert: print("  geändert:", r)

if __name__ == "__main__":
    main()
