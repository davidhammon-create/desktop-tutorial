# -*- coding: utf-8 -*-
"""Setzt das Sanierungshandbuch als PDF (reportlab Platypus)."""
import os, sys, datetime
from xml.sax.saxutils import escape

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph,
                                Spacer, Table, TableStyle, PageBreak, KeepTogether,
                                Preformatted, HRFlowable)

SCR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCR)
from bauplan_teil1 import B1
from bauplan_teil2 import B2
from bauplan_teil3 import B3

OUT = os.path.join(SCR, "FenlynineOS_Bauplan.pdf")
F = "/usr/share/fonts/truetype/dejavu/"
pdfmetrics.registerFont(TTFont("Serif",   F + "DejaVuSerif.ttf"))
pdfmetrics.registerFont(TTFont("SerifB",  F + "DejaVuSerif-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Sans",    F + "DejaVuSans.ttf"))
pdfmetrics.registerFont(TTFont("SansB",   F + "DejaVuSans-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Mono",    F + "DejaVuSansMono.ttf"))
pdfmetrics.registerFont(TTFont("MonoB",   F + "DejaVuSansMono-Bold.ttf"))
pdfmetrics.registerFontFamily("Serif", normal="Serif", bold="SerifB",
                              italic="Serif", boldItalic="SerifB")

# ---------------------------------------------------------------- Farben
INK      = colors.HexColor("#15171F")
INK_SOFT = colors.HexColor("#4A4F60")
INK_FAINT= colors.HexColor("#7B8095")
AKZENT   = colors.HexColor("#26386E")
AKZENT_BG= colors.HexColor("#EDF0F8")
KRIT     = colors.HexColor("#A3231C")
KRIT_BG  = colors.HexColor("#FBEDEB")
WARN     = colors.HexColor("#7D5308")
WARN_BG  = colors.HexColor("#FAF3E6")
GUT      = colors.HexColor("#1C5539")
GUT_BG   = colors.HexColor("#EAF3ED")
RULE     = colors.HexColor("#D5D8E3")
CODE_BG  = colors.HexColor("#F5F6FA")

# ---------------------------------------------------------------- Stile
def S(name, **kw):
    basis = dict(name=name, fontName="Serif", fontSize=9.4, leading=14.2,
                 textColor=INK, alignment=TA_LEFT, spaceAfter=0)
    basis.update(kw)
    return ParagraphStyle(**basis)

ST = {
 "h1":        S("h1", fontName="SansB", fontSize=20, leading=24, textColor=INK,
                spaceBefore=4, spaceAfter=10),
 "untertitel":S("untertitel", fontSize=11.5, leading=17, textColor=INK_SOFT, spaceAfter=14),
 "h2":        S("h2", fontName="SansB", fontSize=14, leading=18, textColor=AKZENT,
                spaceBefore=10, spaceAfter=3),
 "h3":        S("h3", fontName="SansB", fontSize=10.6, leading=14, textColor=INK,
                spaceBefore=12, spaceAfter=4),
 "p":         S("p", spaceAfter=8),
 "p_final":   S("p_final", fontSize=10.2, leading=15.5, textColor=AKZENT, spaceAfter=8),
 "etikett":   S("etikett", fontName="Mono", fontSize=7.8, leading=11, textColor=INK_FAINT,
                spaceAfter=10),
 "klein":     S("klein", fontSize=8.4, leading=12.4, textColor=INK_SOFT),
 "kasten_t":  S("kasten_t", fontName="SansB", fontSize=9.6, leading=13, spaceAfter=4),
 "kasten_p":  S("kasten_p", fontSize=8.9, leading=13.4),
 "zellkopf":  S("zellkopf", fontName="SansB", fontSize=7.6, leading=10.4, textColor=colors.white),
 "zelle":     S("zelle", fontSize=8.3, leading=12.0),
 "zelle_k":   S("zelle_k", fontSize=7.8, leading=11.2, textColor=INK_SOFT),
 "zelle_m":   S("zelle_m", fontName="Mono", fontSize=7.6, leading=11),
 "nr":        S("nr", fontName="MonoB", fontSize=11, leading=13, textColor=AKZENT),
 "grad":      S("grad", fontName="MonoB", fontSize=7, leading=9.5),
 "inh_a":     S("inh_a", fontName="MonoB", fontSize=8.4, leading=13, textColor=AKZENT),
 "inh_b":     S("inh_b", fontSize=9.2, leading=13),
 "inh_c":     S("inh_c", fontSize=8.2, leading=13, textColor=INK_FAINT),
}
CODE_ST = ParagraphStyle(name="code", fontName="Mono", fontSize=6.9, leading=9.3,
                         textColor=INK, alignment=TA_LEFT)

BREITE = A4[0] - 40*mm

# ---------------------------------------------------------------- Bausteine
def tabelle(kopf, zeilen, breiten, kopf_bg=AKZENT, zellstil="zelle", klein_ab=1):
    daten = []
    if kopf:
        daten.append([Paragraph(escape(k), ST["zellkopf"]) for k in kopf])
    for z in zeilen:
        reihe = []
        for i, c in enumerate(z):
            if isinstance(c, str):
                st = ST[zellstil] if i < klein_ab else ST["zelle_k"]
                reihe.append(Paragraph(c, st))
            else:
                reihe.append(c)      # bereits gesetzter Flowable
        daten.append(reihe)
    t = Table(daten, colWidths=breiten, repeatRows=1 if kopf else 0)
    stil = [
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 5),
        ("RIGHTPADDING", (0,0), (-1,-1), 5),
        ("TOPPADDING", (0,0), (-1,-1), 4),
        ("BOTTOMPADDING", (0,0), (-1,-1), 4),
        ("LINEBELOW", (0,0), (-1,-2), 0.4, RULE),
    ]
    if kopf:
        stil += [("BACKGROUND", (0,0), (-1,0), kopf_bg),
                 ("BOTTOMPADDING", (0,0), (-1,0), 5),
                 ("TOPPADDING", (0,0), (-1,0), 5)]
    t.setStyle(TableStyle(stil))
    return t

def kasten(titel, text, farbe, bg):
    inhalt = [Paragraph(titel, ST["kasten_t"]), Paragraph(text, ST["kasten_p"])]
    t = Table([[inhalt]], colWidths=[BREITE])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), bg),
        ("LINEBEFORE", (0,0), (0,-1), 2.2, farbe),
        ("LEFTPADDING", (0,0), (-1,-1), 9),
        ("RIGHTPADDING", (0,0), (-1,-1), 9),
        ("TOPPADDING", (0,0), (-1,-1), 8),
        ("BOTTOMPADDING", (0,0), (-1,-1), 8),
    ]))
    return t

CODE_MAX = 112          # Zeichen, die bei 6.9pt Mono in den Satzspiegel passen

def _code_zeilen(text):
    """Zerlegt in Zeilen und bricht zu lange Zeilen mit Einzug um."""
    aus = []
    for z in text.split("\n"):
        z = z.replace("\t", "  ")
        if len(z) <= CODE_MAX:
            aus.append(z)
            continue
        einzug = len(z) - len(z.lstrip())
        rest = z
        erste = True
        while rest:
            breite = CODE_MAX if erste else CODE_MAX - einzug - 4
            aus.append(rest[:breite] if erste
                       else " " * (einzug + 4) + rest[:breite])
            rest = rest[breite:]
            erste = False
    return aus

def codeblock(text):
    """Eine Tabellenzeile je Codezeile -- so kann der Block über Seiten umbrechen."""
    zeilen = _code_zeilen(text)
    daten = [[Preformatted(z if z.strip() else " ", CODE_ST)] for z in zeilen]
    t = Table(daten, colWidths=[BREITE], splitByRow=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), CODE_BG),
        ("LINEBEFORE", (0,0), (0,-1), 1.6, RULE),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 8),
        ("RIGHTPADDING", (0,0), (-1,-1), 4),
        ("TOPPADDING", (0,0), (-1,-1), 0),
        ("BOTTOMPADDING", (0,0), (-1,-1), 0),
    ]))
    return t

GRAD_FARBE = {"kritisch": (KRIT, KRIT_BG), "erheblich": (WARN, WARN_BG),
              "strategisch": (AKZENT, AKZENT_BG),
              "erfunden": (WARN, WARN_BG),
              "falsch modelliert": (WARN, WARN_BG),
              "ineffizient": (AKZENT, AKZENT_BG)}

# ---------------------------------------------------------------- Aufbau
def baue(bloecke):
    fl = []
    for block in bloecke:
        art = block[0]

        if art == "seitenumbruch":
            fl.append(PageBreak())

        elif art in ("h1",):
            fl.append(Spacer(1, 4))
            fl.append(Paragraph(escape(block[1]), ST["h1"]))
            fl.append(HRFlowable(width="100%", thickness=1.4, color=INK,
                                 spaceBefore=1, spaceAfter=10))

        elif art == "h2":
            fl.append(Spacer(1, 8))
            fl.append(Paragraph(escape(block[1]), ST["h2"]))
            fl.append(HRFlowable(width="100%", thickness=0.6, color=RULE,
                                 spaceBefore=2, spaceAfter=7))

        elif art == "h3":
            fl.append(Paragraph(escape(block[1]), ST["h3"]))

        elif art in ("p", "p_final", "klein", "etikett", "untertitel"):
            fl.append(Paragraph(block[1], ST[art]))

        elif art == "meta":
            fl.append(tabelle(None, [[f"<b>{k}</b>", v] for k, v in block[1]],
                              [38*mm, BREITE - 38*mm], zellstil="zelle", klein_ab=99))
            fl.append(Spacer(1, 12))

        elif art == "inhalt":
            zeilen = [[a, b, c] for a, b, c in block[1]]
            daten = [[Paragraph(a, ST["inh_a"]), Paragraph(b, ST["inh_b"]),
                      Paragraph(c, ST["inh_c"])] for a, b, c in zeilen]
            t = Table(daten, colWidths=[16*mm, 105*mm, BREITE - 121*mm])
            t.setStyle(TableStyle([
                ("VALIGN", (0,0), (-1,-1), "TOP"),
                ("TOPPADDING", (0,0), (-1,-1), 2.5),
                ("BOTTOMPADDING", (0,0), (-1,-1), 2.5),
                ("LEFTPADDING", (0,0), (0,-1), 0),
            ]))
            fl.append(t)

        elif art == "code":
            fl.append(Spacer(1, 3))
            fl.append(codeblock(block[1]))
            fl.append(Spacer(1, 9))

        elif art == "kasten_wichtig":
            fl.append(Spacer(1, 4))
            fl.append(kasten(escape(block[1]), block[2], AKZENT, AKZENT_BG))
            fl.append(Spacer(1, 10))

        elif art == "kasten_achtung":
            fl.append(Spacer(1, 4))
            fl.append(kasten(escape(block[1]), block[2], WARN, WARN_BG))
            fl.append(Spacer(1, 10))

        elif art == "befund_gut":
            nr, titel, text = block[1], block[2], block[3]
            inhalt = [[Paragraph(nr, ST["nr"]),
                       [Paragraph("<b>" + escape(titel) + "</b>", ST["zelle"]),
                        Spacer(1, 2), Paragraph(text, ST["zelle_k"])]]]
            t = Table(inhalt, colWidths=[9*mm, BREITE - 9*mm])
            t.setStyle(TableStyle([
                ("VALIGN", (0,0), (-1,-1), "TOP"),
                ("LEFTPADDING", (0,0), (0,-1), 0),
                ("TOPPADDING", (0,0), (-1,-1), 5),
                ("BOTTOMPADDING", (0,0), (-1,-1), 5),
                ("LINEBELOW", (0,0), (-1,-1), 0.4, RULE),
                ("LINEBEFORE", (0,0), (0,-1), 2.0, GUT),
                ("BACKGROUND", (0,0), (-1,-1), GUT_BG),
                ("LEFTPADDING", (0,0), (0,-1), 6),
            ]))
            fl.append(t)
            fl.append(Spacer(1, 3))

        elif art == "befund_tabelle":
            zeilen = []
            for nr, titel, grad, text, kapitel in block[1]:
                farbe, _ = GRAD_FARBE.get(grad, (INK_SOFT, AKZENT_BG))
                zeilen.append([
                    Paragraph(f'<font color="#{farbe.hexval()[2:]}"><b>{nr}</b></font>', ST["zelle"]),
                    Paragraph("<b>" + escape(titel) + "</b><br/>"
                              + f'<font size="7.4" color="#7B8095">{escape(text)}</font>',
                              ST["zelle"]),
                    Paragraph(f'<font color="#{farbe.hexval()[2:]}"><b>{grad}</b></font>',
                              ST["grad"]),
                    Paragraph(f"<b>{escape(kapitel)}</b>", ST["zelle_m"]),
                ])
            fl.append(tabelle(["Nr.", "Befund", "Schwere", "Lösung"], zeilen,
                              [10*mm, BREITE - 58*mm, 22*mm, 26*mm], klein_ab=99))
            fl.append(Spacer(1, 8))

        elif art == "regel_tabelle":
            zeilen = [[f"<b>{escape(a)}</b>", escape(b), c] for a, b, c in block[1]]
            fl.append(tabelle(["Norm", "Regel", "Inhalt"], zeilen,
                              [30*mm, 34*mm, BREITE - 64*mm], klein_ab=2))
            fl.append(Spacer(1, 9))

        elif art == "tabelle":
            kopf, zeilen = block[1], block[2]
            n = len(kopf)
            if n == 2:
                br = [BREITE*0.34, BREITE*0.66]
            elif n == 3:
                br = [BREITE*0.24, BREITE*0.28, BREITE*0.48]
            else:
                br = [BREITE/n] * n
            fl.append(tabelle(kopf, zeilen, br, klein_ab=1))
            fl.append(Spacer(1, 9))

        elif art == "testtabelle":
            kopf, zeilen = block[1], block[2]
            daten = [[Paragraph(escape(k), ST["zellkopf"]) for k in kopf]]
            for z in zeilen:
                daten.append([
                    Paragraph(escape(z[0]), ST["zelle_m"]),
                    Paragraph(escape(z[1]), ST["zelle_k"]),
                    Paragraph(escape(z[2]), ST["zelle_m"]),
                    Paragraph("<b>" + escape(z[3]) + "</b>", ST["zelle_m"]),
                    Paragraph(escape(z[4]), ST["zelle_k"]),
                ])
            t = Table(daten, colWidths=[36*mm, 30*mm, 12*mm, 30*mm, BREITE - 108*mm],
                      repeatRows=1)
            t.setStyle(TableStyle([
                ("VALIGN", (0,0), (-1,-1), "TOP"),
                ("BACKGROUND", (0,0), (-1,0), AKZENT),
                ("LEFTPADDING", (0,0), (-1,-1), 4),
                ("RIGHTPADDING", (0,0), (-1,-1), 4),
                ("TOPPADDING", (0,0), (-1,-1), 4),
                ("BOTTOMPADDING", (0,0), (-1,-1), 4),
                ("LINEBELOW", (0,0), (-1,-2), 0.4, RULE),
                ("BACKGROUND", (3,1), (3,-1), GUT_BG),
            ]))
            fl.append(t)
            fl.append(Spacer(1, 9))

        elif art == "nummerierte_liste":
            for i, (titel, text) in enumerate(block[1], 1):
                inhalt = [[Paragraph(str(i), ST["nr"]),
                           [Paragraph("<b>" + escape(titel) + "</b>", ST["zelle"]),
                            Spacer(1, 2), Paragraph(text, ST["zelle_k"])]]]
                t = Table(inhalt, colWidths=[8*mm, BREITE - 8*mm])
                t.setStyle(TableStyle([
                    ("VALIGN", (0,0), (-1,-1), "TOP"),
                    ("LEFTPADDING", (0,0), (-1,-1), 0),
                    ("RIGHTPADDING", (0,0), (-1,-1), 4),
                    ("TOPPADDING", (0,0), (-1,-1), 4),
                    ("BOTTOMPADDING", (0,0), (-1,-1), 4),
                    ("LINEBELOW", (0,0), (-1,-1), 0.4, RULE),
                ]))
                fl.append(t)
            fl.append(Spacer(1, 8))

        elif art == "ablauf":
            zeilen = []
            for i, (schritt, text) in enumerate(block[1], 1):
                zeilen.append([
                    Paragraph(f"<b>{i}</b>", ST["nr"]),
                    Paragraph("<b>" + escape(schritt) + "</b>", ST["zelle"]),
                    Paragraph(escape(text), ST["zelle_k"]),
                ])
            fl.append(tabelle(None, [], [0], klein_ab=99) if False else
                      tabelle(["", "Schritt", "Was passiert"], zeilen,
                              [8*mm, 42*mm, BREITE - 50*mm], klein_ab=99))
            fl.append(Spacer(1, 9))

        elif art == "plan_tabelle":
            zeilen = []
            for nr, kap, titel, aufwand, wirkung in block[1]:
                zeilen.append([
                    Paragraph(f"<b>{nr}</b>", ST["nr"]),
                    Paragraph(f"<b>{kap}</b>", ST["zelle_m"]),
                    Paragraph("<b>" + escape(titel) + "</b>", ST["zelle"]),
                    Paragraph(escape(aufwand), ST["zelle_m"]),
                    Paragraph(escape(wirkung), ST["zelle_k"]),
                ])
            t = Table([[Paragraph(escape(k), ST["zellkopf"]) for k in
                        ["", "Kap.", "Schritt", "Aufwand", "Wirkung"]]] + zeilen,
                      colWidths=[8*mm, 12*mm, 52*mm, 20*mm, BREITE - 92*mm], repeatRows=1)
            t.setStyle(TableStyle([
                ("VALIGN", (0,0), (-1,-1), "TOP"),
                ("BACKGROUND", (0,0), (-1,0), AKZENT),
                ("LEFTPADDING", (0,0), (-1,-1), 4),
                ("RIGHTPADDING", (0,0), (-1,-1), 4),
                ("TOPPADDING", (0,0), (-1,-1), 4),
                ("BOTTOMPADDING", (0,0), (-1,-1), 4),
                ("LINEBELOW", (0,0), (-1,-2), 0.4, RULE),
            ]))
            fl.append(t)
            fl.append(Spacer(1, 9))

        elif art == "wert_tabelle":
            zeilen = [[f"<b>{escape(a)}</b>", f"<b>{escape(b)}</b>", escape(c)]
                      for a, b, c in block[1]]
            fl.append(tabelle(["Stand", "Wert", "Begründung"], zeilen,
                              [46*mm, 42*mm, BREITE - 88*mm], klein_ab=2))
            fl.append(Spacer(1, 9))

        elif art == "quellen_tabelle":
            zeilen = []
            for zahlenart, quelle, takt, modul in block[1]:
                zeilen.append([
                    Paragraph("<b>" + escape(zahlenart) + "</b>", ST["zelle"]),
                    Paragraph(escape(quelle), ST["zelle_k"]),
                    Paragraph(escape(takt), ST["zelle_m"]),
                    Paragraph(escape(modul), ST["zelle_k"]),
                ])
            t = Table([[Paragraph(escape(k), ST["zellkopf"]) for k in
                        ["Zahlenart", "Quelle", "Aktualisierung", "Modul"]]] + zeilen,
                      colWidths=[34*mm, 62*mm, 26*mm, BREITE - 122*mm], repeatRows=1)
            t.setStyle(TableStyle([
                ("VALIGN", (0,0), (-1,-1), "TOP"),
                ("BACKGROUND", (0,0), (-1,0), AKZENT),
                ("LEFTPADDING", (0,0), (-1,-1), 4),
                ("RIGHTPADDING", (0,0), (-1,-1), 4),
                ("TOPPADDING", (0,0), (-1,-1), 4),
                ("BOTTOMPADDING", (0,0), (-1,-1), 4),
                ("LINEBELOW", (0,0), (-1,-2), 0.4, RULE),
            ]))
            fl.append(t)
            fl.append(Spacer(1, 9))

        elif art == "burg_tabelle":
            farbe_zu = {"kopierbar": KRIT, "teilweise": WARN,
                        "schwer kopierbar": GUT, "nicht kopierbar": GUT}
            zeilen = []
            for funktion, grad, text in block[1]:
                f = farbe_zu.get(grad, INK_SOFT)
                zeilen.append([
                    Paragraph("<b>" + escape(funktion) + "</b>", ST["zelle"]),
                    Paragraph('<font color="#%s"><b>%s</b></font>' % (f.hexval()[2:], escape(grad)),
                              ST["grad"]),
                    Paragraph(escape(text), ST["zelle_k"]),
                ])
            fl.append(tabelle(["Funktion", "Kopierbarkeit", "Warum"], zeilen,
                              [44*mm, 28*mm, BREITE - 72*mm], klein_ab=99))
            fl.append(Spacer(1, 9))

    return fl

# ---------------------------------------------------------------- Dokument
class Doc(BaseDocTemplate):
    def __init__(self, pfad, **kw):
        super().__init__(pfad, pagesize=A4,
                         leftMargin=20*mm, rightMargin=20*mm,
                         topMargin=18*mm, bottomMargin=16*mm, **kw)
        rahmen = Frame(self.leftMargin, self.bottomMargin,
                       self.width, self.height, id="text",
                       leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
        self.addPageTemplates([PageTemplate(id="seite", frames=[rahmen],
                                            onPage=self.dekor)])

    def dekor(self, c, doc):
        c.saveState()
        c.setFont("Mono", 6.6)
        c.setFillColor(INK_FAINT)
        if doc.page > 1:
            c.drawString(20*mm, A4[1] - 12*mm,
                         "FenlynineOS Legal Suite · Bauplan · Snapshot Fenlynine-11.08.26-R1")
            c.setStrokeColor(RULE)
            c.setLineWidth(0.4)
            c.line(20*mm, A4[1] - 14.5*mm, A4[0] - 20*mm, A4[1] - 14.5*mm)
        c.drawRightString(A4[0] - 20*mm, 10*mm, f"Seite {doc.page}")
        c.drawString(20*mm, 10*mm, "Technische Bewertung — keine Rechtsberatung")
        c.restoreState()

if __name__ == "__main__":
    fl = baue(B1) + baue(B2) + baue(B3)
    Doc(OUT).build(fl)
    print(f"FERTIG: {OUT}  {os.path.getsize(OUT)/1e6:.2f} MB")
