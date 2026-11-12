import Foundation
enum MachtLageDienst {
    struct Lage: Equatable {
        var erhaltChancen: [String]
        var erhaltRisiken: [String]
        var wegnahmeLegal: [String]
        var wegnahmeGrenzen: [String]
        var schwaecheEigen: [String]
        var schwaecheRival: [String]
        var naechsteZuege: [String]
        var scoreText: String
    }
    static func analysiere(_ e: ERErgebnis, rivalGenannt: Bool) -> Lage {
        let resilienz = e.resilienzIndex
        let risiko = e.gesamtscoreEigen
        let vorteil = e.vorteilsIndex
        var erhalt: [String] = []
        var erhaltRisiko: [String] = []
        var wegnahme: [String] = []
        var grenzen: [String] = []
        var eigen: [String] = []
        var rival: [String] = []
        var zuege: [String] = []
        if resilienz >= 60 {
            erhalt.append("Resilienz \(resilienz)/100 stützt die Beibehaltung erworbener Positionen — Compliance und Fristen halten den Vorsprung.")
        } else {
            erhaltRisiko.append("Resilienz nur \(resilienz)/100: erworbene Position kann durch eigene Lücken (nicht durch den Gegner) wieder verloren gehen.")
        }
        if vorteil >= 50 {
            erhalt.append("Vorteilsindex \(vorteil)/100: bestehende rechtliche Hebel reichen zum Absichern der Lage.")
        } else {
            erhaltRisiko.append("Vorteilsindex \(vorteil)/100: ohne Nacharbeit an Hebeln und Leitplanken bleibt der Erhalt fragil.")
        }
        for s in e.eigeneSchwachstellen.prefix(3) {
            eigen.append("\(s.titel) — \(s.dimension.titel). Ausnutzbarkeit \(s.ausnutzbarkeit)/100. \(kurz(s.beschreibung))")
            erhaltRisiko.append("Eigene Schwäche „\(s.titel)“ bedroht den Macht-Erhalt, wenn sie ungeschlossen bleibt.")
            zuege.append("Schließen: \(s.titel) · Maßnahme aus Radar/Strategos priorisieren.")
        }
        for v in e.vorteile.prefix(3) {
            erhalt.append("Hebel „\(v.titel)“ (\(v.typ.titel)): \(kurz(v.leitplanken))")
        }
        if rivalGenannt {
            for s in e.wettbewerberSchwachstellen.prefix(4) {
                rival.append("\(s.titel) — \(s.dimension.titel). Ausnutzbarkeit \(s.ausnutzbarkeit)/100.")
                if s.ausnutzbarkeit >= 40 {
                    wegnahme.append("Zulässiger Druckpunkt: \(s.titel). Differenz zum eigenen Profil nutzen — ohne Anschwärzung, ohne koordinierte Boykotte.")
                }
            }
            if e.wettbewerberSchwachstellen.isEmpty {
                wegnahme.append("Kein belastbarer Rival-Befund. Mehr Fakten zum Wettbewerber liefern oder Radar erneut rechnen.")
            }
        } else {
            wegnahme.append("Ohne benannten Wettbewerber keine Wegnahme-Analyse. Namen und Fakten eintragen.")
        }
        grenzen.append("Art. 101/102 AEUV · GWB: keine Absprachen, keine missbräuchliche Ausnutzung von Marktmacht, keine unlautere Anschwärzung (§ 4 UWG).")
        grenzen.append("Nur öffentlich belegbare oder mandatsintern dokumentierte Befunde. Keine Beschaffung durch unzulässige Mittel.")
        for st in e.strategien.prefix(3) {
            zuege.append("Strategie „\(st.titel)“ (\(st.archetyp.titel), P=\(st.erfolgswahrscheinlichkeit)%): \(kurz(st.ziel))")
        }
        let score = "Risiko eigen \(risiko) · Resilienz \(resilienz) · Vorteil \(vorteil) · Rival-Schwächen \(e.wettbewerberSchwachstellen.count) · eigene Schwächen \(e.eigeneSchwachstellen.count)"
        return Lage(
            erhaltChancen: erhalt,
            erhaltRisiken: erhaltRisiko,
            wegnahmeLegal: wegnahme,
            wegnahmeGrenzen: grenzen,
            schwaecheEigen: eigen,
            schwaecheRival: rival,
            naechsteZuege: zuege,
            scoreText: score
        )
    }
    static func text(fuer e: ERErgebnis, ziel: DurchlaufZiel, rivalGenannt: Bool) -> String {
        let l = analysiere(e, rivalGenannt: rivalGenannt)
        var zeilen = ["MACHTLAGE (rechtlich) — \(ziel.titel)", l.scoreText, ""]
        switch ziel {
        case .machtErhalt, .machtBeibehalten:
            zeilen.append("CHANCEN ERHALT / BEIBEHALTEN")
            zeilen += l.erhaltChancen.map { "• \($0)" }
            zeilen.append("")
            zeilen.append("RISIKEN FÜR DEN ERHALT")
            zeilen += (l.erhaltRisiken.isEmpty ? ["• Keine akuten Erhalt-Risiken aus dem aktuellen Befund."] : l.erhaltRisiken.map { "• \($0)" })
            zeilen.append("")
            zeilen.append("EIGENE SCHWACHSTELLEN (schließen)")
            zeilen += (l.schwaecheEigen.isEmpty ? ["• Keine prioritäre eigene Schwäche."] : l.schwaecheEigen.map { "• \($0)" })
        case .machtWegnahme, .schwaecheNutzen:
            zeilen.append("ZULÄSSIGE WEGNAHME- / VORTEILSHEBEL")
            zeilen += l.wegnahmeLegal.map { "• \($0)" }
            zeilen.append("")
            zeilen.append("RIVAL-SCHWACHSTELLEN")
            zeilen += (l.schwaecheRival.isEmpty ? ["• Keine Rival-Schwäche berechnet."] : l.schwaecheRival.map { "• \($0)" })
            zeilen.append("")
            zeilen.append("GRENZEN")
            zeilen += l.wegnahmeGrenzen.map { "• \($0)" }
        case .schwaecheEigen:
            zeilen.append("EIGENE SCHWACHSTELLEN")
            zeilen += (l.schwaecheEigen.isEmpty ? ["• Keine prioritäre eigene Schwäche — Profil und Signale verdichten."] : l.schwaecheEigen.map { "• \($0)" })
            zeilen.append("")
            zeilen.append("ERHALT-RISIKEN")
            zeilen += l.erhaltRisiken.map { "• \($0)" }
        case .chancenRisiken:
            zeilen.append("CHANCEN")
            zeilen += l.erhaltChancen.map { "• \($0)" }
            zeilen += l.wegnahmeLegal.prefix(3).map { "• \($0)" }
            zeilen.append("")
            zeilen.append("RISIKEN")
            zeilen += l.erhaltRisiken.map { "• \($0)" }
            zeilen += l.schwaecheEigen.prefix(2).map { "• Eigen: \($0)" }
        default:
            zeilen.append("CHANCEN")
            zeilen += l.erhaltChancen.prefix(3).map { "• \($0)" }
            zeilen.append("RISIKEN")
            zeilen += l.erhaltRisiken.prefix(3).map { "• \($0)" }
        }
        zeilen.append("")
        zeilen.append("NÄCHSTE ZÜGE (aus Radar/Strategien)")
        zeilen += (l.naechsteZuege.isEmpty ? ["• Radar-Strategien öffnen und priorisieren."] : l.naechsteZuege.map { "• \($0)" })
        zeilen.append("")
        zeilen.append("Nur rechtlich zulässige Maßnahmen. Zahlen und Befunde stehen auch im Enterprise-Radar.")
        return zeilen.joined(separator: "\n")
    }
    private static func kurz(_ t: String) -> String {
        t.count <= 160 ? t : String(t.prefix(160)) + "…"
    }
}
