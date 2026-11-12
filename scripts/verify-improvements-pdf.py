# -*- coding: utf-8 -*-
"""Liest das Verbesserungs-PDF zurück und vergleicht jede Datei mit dem Repo."""
import pdfplumber, re, os, sys
from collections import defaultdict

ROOT = "/home/user/desktop-tutorial"
SCR = os.path.dirname(os.path.abspath(__file__))
PDF = os.path.join(SCR, "FenlynineOS_Verbesserungen_fuer_Cursor.pdf")
UMBRUCH, FORTS = "↩", "↳"
K = "═" * 3

KOPF = re.compile(r'^' + K + r' (NEU|GEAENDERT) (\d+)/(\d+) ' + K + r' (\S.*)$')
ENDE = re.compile(r'^' + K + r' ENDE ' + K + r' (\S.*)$')
META = re.compile(r'^Zeilen: (\d+) · SHA256: ([0-9a-f]{64})$')
FUSS = re.compile(r'^\[Seite \d+\]$')
CONT = 1

dateien, meta, reihe = {}, {}, []
cur = None
with pdfplumber.open(PDF) as pdf:
    seiten = len(pdf.pages)
    for page in pdf.pages:
        rows = defaultdict(list)
        for ch in page.chars:
            rows[round(ch['top'], 1)].append(ch)
        for top in sorted(rows):
            row = sorted(rows[top], key=lambda ch: ch['x0'])
            l = "".join(ch['text'] for ch in row)
            ls = l.rstrip()
            if FUSS.match(ls) or ls.startswith("FenlynineOS · Verbesserungen"):
                continue
            m = KOPF.match(ls)
            if m:
                cur = m.group(4); reihe.append((cur, m.group(1))); dateien[cur] = []
                continue
            if ENDE.match(ls):
                cur = None; continue
            if cur is None:
                continue
            mm = META.match(ls)
            if mm and not dateien[cur]:
                meta[cur] = int(mm.group(1)); continue
            if ls.startswith(FORTS):
                st = l[1:]
                dateien[cur][-1] += st.rstrip()[:-1] if st.rstrip().endswith(UMBRUCH) else st
            elif ls.endswith(UMBRUCH):
                dateien[cur].append(ls[:-1])
            else:
                dateien[cur].append(l)

print(f"Seiten: {seiten} · Dateien im PDF: {len(reihe)}")
zf = inf_ = 0
for p, art in reihe:
    rl = open(os.path.join(ROOT, p), encoding="utf-8").read().splitlines()
    got = dateien[p]
    if len(got) != len(rl):
        zf += 1; print(f"ZEILENZAHL {p}: {len(got)} statt {len(rl)}"); continue
    for i, (a, b) in enumerate(zip(got, rl)):
        if a.rstrip() != b.replace("\t", "  ").rstrip():
            inf_ += 1
            print(f"DIFF {p} Zeile {i+1}")
            print("  PDF :", repr(a[:100]))
            print("  REPO:", repr(b[:100]))
            break
print(f"\nZeilenzahl-Fehler: {zf} · Inhalts-Abweichungen: {inf_} von {len(reihe)} Dateien")
sys.exit(1 if (zf or inf_) else 0)
