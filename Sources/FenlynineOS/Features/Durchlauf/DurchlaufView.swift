import SwiftUI
enum DurchlaufZiel: String, CaseIterable, Identifiable {
    case risikoFinden, risikoBeseitigen, problemLoesen
    case schwaecheNutzen, schwaecheEigen
    case machtErhalt, machtBeibehalten, machtWegnahme, chancenRisiken
    case alleFunktionen, selbst
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .risikoFinden: return "Risiko finden"
        case .risikoBeseitigen: return "Risiko beseitigen"
        case .problemLoesen: return "Problem lösen"
        case .schwaecheNutzen: return "Rival-Schwäche nutzen"
        case .schwaecheEigen: return "Eigene Schwäche finden"
        case .machtErhalt: return "Macht-Erhalt"
        case .machtBeibehalten: return "Macht beibehalten"
        case .machtWegnahme: return "Macht-Wegnahme (legal)"
        case .chancenRisiken: return "Chancen & Risiken Macht"
        case .alleFunktionen: return "Alle Funktionen"
        case .selbst: return "Selbst wählen"
        }
    }
    var satz: String {
        switch self {
        case .risikoFinden: return "Der Radar rechnet das eigene Unternehmen. Danach prüfen Sie Lage und Fristen."
        case .risikoBeseitigen: return "Erst der Befund, dann Szenario, Aufgabe und die Spur im Journal."
        case .problemLoesen: return "Fallakte, Fristen und ein Weg aus dem Problem — in dieser Reihenfolge."
        case .schwaecheNutzen: return "Schwäche des Wettbewerbers rechnen, dann als zulässigen Vorteil in Position bringen."
        case .schwaecheEigen: return "Eigene Lücken finden, bevor der Markt sie ausnutzt — rechtlich und operativ schließen."
        case .machtErhalt: return "Erworbene Position rechtlich absichern: Hebel, Fristen, Compliance, Opportunisma."
        case .machtBeibehalten: return "Nach Erlangung halten: Resilienz, Rival-Gegenzüge, Journal und Strategos."
        case .machtWegnahme: return "Nur zulässige Hebel gegen Rival-Schwächen — Kartell- und UWG-Grenzen bleiben hart."
        case .chancenRisiken: return "Macht-Chancen und -Risiken aus Radar, Strategos und Opportunisma in einem Durchlauf."
        case .alleFunktionen: return "Jedes Modul der Suite, eines nach dem anderen. Was Sie nicht brauchen, nehmen Sie heraus."
        case .selbst: return "Leere Liste. Sie setzen die Funktionen selbst in die Reihenfolge."
        }
    }
    var symbol: String {
        switch self {
        case .risikoFinden: return "magnifyingglass"
        case .risikoBeseitigen: return "checkmark.shield"
        case .problemLoesen: return "wrench.and.screwdriver"
        case .schwaecheNutzen: return "scope"
        case .schwaecheEigen: return "building.2.crop.circle"
        case .machtErhalt: return "shield.checkered"
        case .machtBeibehalten: return "lock.shield"
        case .machtWegnahme: return "arrow.down.right.and.arrow.up.left"
        case .chancenRisiken: return "chart.xyaxis.line"
        case .alleFunktionen: return "list.number"
        case .selbst: return "slider.horizontal.3"
        }
    }
    static func aus(frage: String) -> DurchlaufZiel? {
        let t = frage.lowercased()
        guard t.count >= 8 else { return nil }
        if t.contains("beibehalt") || t.contains("position halten") || t.contains("nach erlang") {
            return .machtBeibehalten
        }
        if t.contains("macht-erhalt") || t.contains("machterhalt") || t.contains("macht erhalt")
            || t.contains("position sichern") || t.contains("vorsprung sichern") {
            return .machtErhalt
        }
        if t.contains("wegnahme") || t.contains("macht nehmen") || t.contains("schwächen des konkurr")
            || t.contains("schwächen des wettbewerb") || t.contains("konkurrenz schwäch") {
            return .machtWegnahme
        }
        if t.contains("eigene schwach") || t.contains("eigenes risiko") || t.contains("bei uns lücke")
            || t.contains("eigene lücke") || t.contains("selbst prüfen") {
            return .schwaecheEigen
        }
        if (t.contains("chance") && t.contains("risiko")) || t.contains("chancen und risiken")
            || t.contains("machtchance") || t.contains("macht-risiko") {
            return .chancenRisiken
        }
        if (t.contains("rival") && (t.contains("schwach") || t.contains("nutzen")))
            || t.contains("wettbewerber schwach") || t.contains("gegner schwach") {
            return .schwaecheNutzen
        }
        if t.contains("beseitig") || t.contains("risiko weg") || (t.contains("schließen") && t.contains("risiko")) {
            return .risikoBeseitigen
        }
        if t.contains("fall") || t.contains("mandat") || t.contains("klage") || t.contains("verfahren") {
            return .problemLoesen
        }
        if t.contains("risiko") || t.contains("radar") || t.contains("compliance") {
            return .risikoFinden
        }
        return nil
    }
}
enum DurchlaufModus: String, CaseIterable, Identifiable {
    case manuell, automatisch
    var id: String { rawValue }
    var titel: String { self == .manuell ? "Manuell" : "Automatisch" }
}
enum DurchlaufArt {
    case auftrag, radar, macht, mensch
}
struct DurchlaufSchritt: Identifiable {
    var id = UUID().uuidString
    var modul: SeitenleistenEintrag?
    var titel: String
    var warum: String
    var tun: String
    var art: DurchlaufArt
    var ergebnis: String?
    var erledigt = false
}
@MainActor
struct DurchlaufModell {
    var ziel: DurchlaufZiel = .risikoFinden
    var modus: DurchlaufModus = .manuell
    var firma = ""
    var rival = ""
    var gesamttext = ""
    var faktenEigen = ""
    var faktenRival = ""
    var mitarbeiterText = ""
    var branche: ERBranche = .software
    var radarBericht = ""
    var letztesErgebnis: ERErgebnis?
    var schritte: [DurchlaufSchritt] = []
    var index = 0
    var laeuft = false
    var hinzufuegen = false
    var suche = ""
    var aktuell: DurchlaufSchritt? {
        guard schritte.indices.contains(index) else { return nil }
        return schritte[index]
    }
    mutating func starten() {
        textUebernehmen()
        if let erkannt = DurchlaufZiel.aus(frage: gesamttext + " " + firma + " " + rival) {
            ziel = erkannt
        }
        schritte = DurchlaufPlan.bauen(
            ziel: ziel,
            firma: firma,
            rival: rival
        )
        index = 0
        laeuft = true
        if modus == .automatisch { automatik() }
    }
    var vorschlagZiel: DurchlaufZiel? {
        DurchlaufZiel.aus(frage: gesamttext)
    }
    mutating func neu() {
        laeuft = false
        schritte = []
        index = 0
    }
    mutating func waehle(_ i: Int) {
        guard schritte.indices.contains(i) else { return }
        index = i
    }
    mutating func entferne(_ id: String) {
        guard let i = schritte.firstIndex(where: { $0.id == id }) else { return }
        schritte.remove(at: i)
        if schritte.isEmpty { index = 0; return }
        if index >= schritte.count { index = schritte.count - 1 }
    }
    mutating func einfuegen(_ modul: SeitenleistenEintrag) {
        let schritt = DurchlaufSchritt(
            modul: modul,
            titel: modul.bezeichnung,
            warum: modul.commandSubtitle ?? "Zusätzlich von Ihnen gewählt.",
            tun: "Öffnen Sie \(modul.bezeichnung) und arbeiten Sie den Auftrag dort ab.",
            art: .mensch
        )
        let zielIndex = schritte.isEmpty ? 0 : min(index + 1, schritte.count)
        schritte.insert(schritt, at: zielIndex)
        index = zielIndex
        hinzufuegen = false
        suche = ""
    }
    mutating func erledigtUndWeiter() {
        guard schritte.indices.contains(index) else { return }
        if schritte[index].ergebnis == nil, schritte[index].art == .mensch {
            schritte[index].ergebnis = "Von Hand erledigt."
        }
        schritte[index].erledigt = true
        if index + 1 < schritte.count {
            index += 1
            if modus == .automatisch { automatik() }
        }
    }
    mutating func zurueck() {
        if index > 0 { index -= 1 }
    }
    func oeffneModul() {
        guard let modul = aktuell?.modul else { return }
        ModulFensterHost.shared.oeffneModul(modul)
        ModulFensterBridge.installieren()
    }
    mutating func erneutRechnen() {
        guard schritte.indices.contains(index) else { return }
        rechne(an: index)
    }
    mutating func automatik() {
        guard modus == .automatisch else { return }
        while schritte.indices.contains(index) {
            rechne(an: index)
            schritte[index].erledigt = true
            if index + 1 >= schritte.count { return }
            index += 1
        }
    }
    private mutating func rechne(an i: Int) {
        switch schritte[i].art {
        case .auftrag:
            schritte[i].ergebnis = auftragstext()
        case .radar:
            schritte[i].ergebnis = radarRechnen()
        case .macht:
            if letztesErgebnis == nil { _ = radarRechnen() }
            if let e = letztesErgebnis {
                schritte[i].ergebnis = MachtLageDienst.text(
                    fuer: e,
                    ziel: ziel,
                    rivalGenannt: !rival.trimmingCharacters(in: .whitespaces).isEmpty
                )
            } else {
                schritte[i].ergebnis = "Kein Radar-Ergebnis. Erst den Radar-Schritt rechnen."
            }
        case .mensch:
            schritte[i].ergebnis = einfuegenFuerSchritt(schritte[i])
        }
    }
    mutating func textUebernehmen() {
        let roh = gesamttext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !roh.isEmpty else { return }
        var eigen: [String] = []
        var fremd: [String] = []
        var beiRival = false
        for line in roh.components(separatedBy: .newlines) {
            let trim = line.trimmingCharacters(in: .whitespaces)
            if trim.isEmpty { continue }
            if let name = DurchlaufText.wert(trim, schluessel: ["unternehmen", "firma", "eigenes unternehmen"]) {
                firma = name
                beiRival = false
                continue
            }
            if let name = DurchlaufText.wert(trim, schluessel: ["wettbewerber", "konkurrent", "gegner"]) {
                if name.count <= 80 { rival = name } else { fremd.append(name) }
                beiRival = true
                continue
            }
            if let zahl = DurchlaufText.wert(trim, schluessel: ["beschäftigte", "beschaeftigte", "mitarbeiter"]) {
                mitarbeiterText = zahl
                continue
            }
            if let brancheText = DurchlaufText.wert(trim, schluessel: ["branche"]) {
                if let treffer = DurchlaufText.branche(aus: brancheText) { branche = treffer }
                continue
            }
            let klein = trim.lowercased()
            if klein == "über uns" || klein == "ueber uns" || klein == "eigenes unternehmen" {
                beiRival = false
                continue
            }
            if klein == "wettbewerber" || klein == "konkurrent" || klein == "über den wettbewerber" {
                beiRival = true
                continue
            }
            if beiRival { fremd.append(trim) } else { eigen.append(trim) }
        }
        faktenEigen = eigen.isEmpty ? roh : eigen.joined(separator: "\n")
        if !fremd.isEmpty { faktenRival = fremd.joined(separator: "\n") }
    }
    private func auftragstext() -> String {
        var zeilen = ["Auftrag: \(ziel.titel)."]
        if !firma.isEmpty { zeilen.append("Unternehmen: \(firma).") }
        if !rival.isEmpty { zeilen.append("Wettbewerber: \(rival).") }
        zeilen.append("Branche: \(branche.titel).")
        if let n = Int(mitarbeiterText.filter(\.isNumber)), n > 0 {
            zeilen.append("Beschäftigte: \(n).")
        } else {
            zeilen.append("Beschäftigte nicht genannt. Der Radar rechnet mit 250, bis Sie die Zahl im Modul ändern.")
        }
        if !faktenEigen.isEmpty { zeilen.append("Bekannt über uns:\n\(faktenEigen)") }
        if !faktenRival.isEmpty { zeilen.append("Bekannt über den Wettbewerber:\n\(faktenRival)") }
        return zeilen.joined(separator: "\n\n")
    }
    private func einfuegenFuerSchritt(_ schritt: DurchlaufSchritt) -> String {
        let ort = schritt.modul?.bezeichnung ?? schritt.titel
        var zeilen = ["Für \(ort) eingesetzt."]
        if let e = letztesErgebnis {
            switch schritt.modul {
            case .aufgaben:
                if let zug = e.strategien.first?.zuege.first {
                    zeilen.append("Maßnahme: \(zug.schritt). Verantwortlich: \(zug.verantwortlich). Frist: \(zug.frist).")
                }
            case .zeitleiste:
                let fristen = e.fristen.prefix(4).map { "\($0.titel): \($0.datum). \($0.relevanz)" }
                if !fristen.isEmpty { zeilen.append(fristen.joined(separator: "\n")) }
            case .strategos, .sunTzu, .opportunisma:
                if let st = e.strategien.first {
                    zeilen.append("Strategie: \(st.titel). \(st.ziel)")
                }
                if let v = e.vorteile.first {
                    zeilen.append("Vorteil: \(v.titel). Leitplanke: \(v.leitplanken)")
                }
            default:
                break
            }
        }
        if !radarBericht.isEmpty {
            zeilen.append(radarBericht)
        } else if !gesamttext.isEmpty {
            zeilen.append("Gesamttext übernommen (\(gesamttext.count) Zeichen). Er steht vollständig im Auftrag.")
        }
        return zeilen.joined(separator: "\n\n")
    }
    private mutating func radarRechnen() -> String {
        let store = EnterpriseRadarStore.shared
        if !firma.trimmingCharacters(in: .whitespaces).isEmpty {
            store.eigen.name = firma.trimmingCharacters(in: .whitespaces)
        }
        store.eigen.branche = branche
        if let n = Int(mitarbeiterText.filter(\.isNumber)), n > 0 {
            store.eigen.mitarbeiter = n
        }
        let signaleEigen = DurchlaufSignale.aus(faktenEigen)
        if !faktenEigen.trimmingCharacters(in: .whitespaces).isEmpty {
            store.eigen.belegteFakten = faktenEigen.trimmingCharacters(in: .whitespaces)
        }
        if !signaleEigen.isEmpty { store.eigen.signale = signaleEigen }
        let rivalName = rival.trimmingCharacters(in: .whitespaces)
        if !rivalName.isEmpty {
            if store.wettbewerber.isEmpty { store.wettbewerberHinzufuegen() }
            store.wettbewerber[0].name = rivalName
            store.wettbewerber[0].branche = branche
            store.wettbewerber[0].rolle = .konkurrent
            if !faktenRival.trimmingCharacters(in: .whitespaces).isEmpty {
                store.wettbewerber[0].belegteFakten = faktenRival.trimmingCharacters(in: .whitespaces)
            }
            let signaleRival = DurchlaufSignale.aus(faktenRival)
            if !signaleRival.isEmpty { store.wettbewerber[0].signale = signaleRival }
        }
        let e = store.analysiere()
        letztesErgebnis = e
        let text = DurchlaufRadarText.aus(e, ziel: ziel, signaleEigen: signaleEigen, hatRival: !rivalName.isEmpty)
        radarBericht = text
        return text
    }
}
enum DurchlaufText {
    static func wert(_ zeile: String, schluessel: [String]) -> String? {
        let klein = zeile.lowercased()
        for key in schluessel {
            let prefix = key + ":"
            guard klein.hasPrefix(prefix) else { continue }
            let rest = zeile.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
            return rest.isEmpty ? nil : rest
        }
        return nil
    }
    static func branche(aus text: String) -> ERBranche? {
        let klein = text.lowercased()
        return ERBranche.allCases.first { branche in
            klein == branche.rawValue
                || klein.contains(branche.titel.lowercased())
                || (klein.count >= 4 && branche.titel.lowercased().contains(klein))
        }
    }
}
enum DurchlaufSignale {
    static func aus(_ text: String) -> Set<ERSignal> {
        let t = " \(text.lowercased()) "
        var set = Set<ERSignal>()
        let regeln: [(String, ERSignal)] = [
            ("künstliche intelligenz", .setztKIEin),
            (" ki ", .setztKIEin),
            (" ki-", .setztKIEin),
            ("keine ki-governance", .keineKIGovernance),
            ("ohne ki-governance", .keineKIGovernance),
            ("hochrisiko-ki", .kiHochrisiko),
            ("tracking", .trackingOhneConsent),
            ("cookies ohne", .trackingOhneConsent),
            ("außerhalb europas", .lieferketteAussereuropa),
            ("ausserhalb europas", .lieferketteAussereuropa),
            ("außereuropa", .lieferketteAussereuropa),
            ("kein lieferketten", .keinLieferkettenRisikomanagement),
            ("ohne lieferkettenrisiko", .keinLieferkettenRisikomanagement),
            ("veraltete agb", .agbVeraltet),
            ("agb veraltet", .agbVeraltet),
            ("marktführer", .marktfuehrer),
            ("marktfuehrer", .marktfuehrer),
            ("kein isms", .keinISMS),
            ("ohne isms", .keinISMS),
            ("greenwashing", .nachhaltigkeitsClaims),
            ("vergleichende werbung", .vergleichendeWerbung),
            ("datenpanne", .datenpanneLetzte3J),
            ("entgeltlücke", .entgeltLuecke),
            ("entgeltluecke", .entgeltLuecke)
        ]
        for (wort, signal) in regeln where t.contains(wort) {
            set.insert(signal)
        }
        return set
    }
}
enum DurchlaufRadarText {
    static func aus(_ e: ERErgebnis, ziel: DurchlaufZiel, signaleEigen: Set<ERSignal>, hatRival: Bool) -> String {
        var zeilen: [String] = []
        zeilen.append("Gesamtrisiko eigenes Unternehmen: \(e.gesamtscoreEigen). Resilienz \(e.resilienzIndex). Vorteilsindex \(e.vorteilsIndex).")
        if signaleEigen.isEmpty {
            zeilen.append("Im Text stand kein konkretes Signal. Der Radar hat die vorhandene Checkliste benutzt. Ergänzen Sie Fakten, wenn der Befund zu dünn ist.")
        } else {
            zeilen.append("Aus dem Text gelesen: \(signaleEigen.map(\.titel).joined(separator: "; ")).")
        }
        if let s = e.eigeneSchwachstellen.first {
            zeilen.append("Eigene Schwäche: \(s.titel). \(kurz(s.beschreibung))")
        }
        if hatRival, let s = e.wettbewerberSchwachstellen.first {
            zeilen.append("Schwäche des Wettbewerbers: \(s.titel). \(kurz(s.beschreibung))")
        } else if ziel == .schwaecheNutzen || ziel == .machtWegnahme {
            zeilen.append("Ohne Namen des Wettbewerbers gibt es keinen Vergleich. Namen eintragen und diesen Schritt erneut rechnen.")
        }
        if ziel == .schwaecheEigen || ziel == .machtErhalt || ziel == .machtBeibehalten {
            if e.eigeneSchwachstellen.isEmpty {
                zeilen.append("Keine prioritäre eigene Schwäche im aktuellen Profil — Signale und Fakten verdichten.")
            }
        }
        if let v = e.vorteile.first {
            zeilen.append("Vorteil: \(v.titel). Leitplanke: \(kurz(v.leitplanken))")
        }
        if let st = e.strategien.first {
            zeilen.append("Strategie: \(st.titel). \(kurz(st.ziel))")
        }
        zeilen.append("Dieselben Zahlen stehen jetzt im Enterprise-Radar.")
        return zeilen.joined(separator: "\n\n")
    }
    private static func kurz(_ text: String) -> String {
        if text.count <= 220 { return text }
        return String(text.prefix(220)) + "…"
    }
}
enum DurchlaufPlan {
    static func bauen(ziel: DurchlaufZiel, firma: String, rival: String) -> [DurchlaufSchritt] {
        switch ziel {
        case .risikoFinden:
            return [
                auftrag(ziel),
                radar("Risiken des eigenen Unternehmens rechnen", "Der Radar legt die Befunde auf die Angaben aus dem Auftrag."),
                mensch(.lageZentrale, "Lagezentrale gegen den Befund halten", "Sehen Sie, welche offenen Punkte zum Risiko schon in der Kanzlei liegen."),
                mensch(.zeitleiste, "Fristen zum Risiko", "Prüfen Sie, welche Frist an diesem Risiko hängt."),
                mensch(.entscheidungsjournal, "Befund festhalten", "Schreiben Sie den Befund ins Journal, damit die Spur bleibt.")
            ]
        case .risikoBeseitigen:
            return [
                auftrag(ziel),
                radar("Risiko benennen, das beseitigt werden soll", "Ohne Befund gibt es keine Maßnahme. Der Radar liefert ihn aus dem Auftrag."),
                mensch(.strategos, "Szenario der Beseitigung", "Legen Sie in Strategos den Weg an, der das Risiko senkt."),
                mensch(.aufgaben, "Maßnahme zuweisen", "Aus dem Szenario wird eine Aufgabe mit Verantwortlichem."),
                mensch(.berufspflicht, "Ausgang prüfen", "Wenn die Maßnahme nach außen geht, läuft sie über den Berufspflicht-Desk."),
                mensch(.entscheidungsjournal, "Entscheidung sichern", "Halten Sie fest, warum dieser Weg gewählt wurde.")
            ]
        case .problemLoesen:
            return [
                auftrag(ziel),
                mensch(.lexara, "Fallakte und Substanz", "Das Problem sitzt im Mandat: Akte, Substanz, dann die Parteien."),
                mensch(.zeitleiste, "Akteure und Fristen", "Welche Frist entscheidet, ob das Problem noch lösbar ist?"),
                mensch(.strategos, "Weg aus dem Problem", "Ein Szenario, das zum Auftrag passt, nicht ein zweites Gutachten."),
                mensch(.aufgaben, "Nächsten Schritt setzen", "Eine Aufgabe, die den Weg anfängt."),
                mensch(.entscheidungsjournal, "Weg dokumentieren", "Der gewählte Weg bleibt nachvollziehbar.")
            ]
        case .schwaecheNutzen:
            return [
                auftrag(ziel),
                radar("Schwäche des Wettbewerbers rechnen", rival.isEmpty
                      ? "Tragen Sie den Wettbewerber ein. Sonst bleibt der Vergleich leer."
                      : "Der Radar stellt \(rival) gegen \(firma.isEmpty ? "das eigene Unternehmen" : firma)."),
                macht("Zulässige Wegnahme-/Vorteilshebel", "Machtlage aus Radar: Rival-Schwächen, Grenzen, nächste Züge."),
                mensch(.opportunisma, "Vorteil in eine Position bringen", "Nur der zulässige Hebel. Die Leitplanke aus dem Radar gilt weiter."),
                mensch(.sunTzu, "Strategieraum", "Prüfen Sie, welcher Zug zum Vorteil passt und welcher zu weit geht."),
                mensch(.entscheidungsjournal, "Zug festhalten", "Strategie und Grenze gehören ins Journal.")
            ]
        case .schwaecheEigen:
            return [
                auftrag(ziel),
                radar("Eigene Schwächen rechnen", "Der Radar legt Lücken im eigenen Profil offen."),
                macht("Eigene Schwachstellen & Erhalt-Risiken", "Was den Macht-Erhalt von innen bedroht."),
                mensch(.lageZentrale, "Lage gegen den Befund", "Offene Punkte der Kanzlei mit dem Radar abgleichen."),
                mensch(.aufgaben, "Schließung zuweisen", "Jede prioritäre Schwäche wird zur Aufgabe."),
                mensch(.berufspflicht, "Ausgang prüfen", "Wenn Maßnahmen nach außen gehen."),
                mensch(.entscheidungsjournal, "Befund sichern", "Eigene Schwächen und Gegenmaßnahmen dokumentieren.")
            ]
        case .machtErhalt:
            return [
                auftrag(ziel),
                radar("Lage für Macht-Erhalt", "Resilienz, Vorteile und eigene Lücken — Basis für Absicherung."),
                macht("Macht-Erhalt: Chancen & Risiken", "Was die Position hält und was sie bedroht — rechtlich."),
                mensch(.opportunisma, "Position absichern", "Hebel und Hegemonogramm für den Erhalt."),
                mensch(.strategos, "Szenario Absicherung", "Wege, die den Vorsprung rechtlich halten."),
                mensch(.zeitleiste, "Fristen am Vorsprung", "Welche Frist den Erhalt gefährdet."),
                mensch(.entscheidungsjournal, "Erhalt dokumentieren", "Entscheidung und Leitplanke festhalten.")
            ]
        case .machtBeibehalten:
            return [
                auftrag(ziel),
                radar("Beibehaltung nach Erlangung", "Nach dem Gewinn: Resilienz und Rival-Gegenzüge."),
                macht("Beibehalten: Risiken & Züge", "Was nach Erlangung droht und welche Züge halten."),
                mensch(.strategos, "Halten-Szenario", "Prospektiv: wie der Vorsprung bleibt."),
                mensch(.opportunisma, "Lage nachhalten", "Positionsradar und Action Board."),
                mensch(.enterpriseRadar, "KI-Vertiefung im Radar", "Optional: KI-Synthese zu Dynamik und Strategien."),
                mensch(.entscheidungsjournal, "Halten dokumentieren", "Auditierbare Spur der Beibehaltung.")
            ]
        case .machtWegnahme:
            return [
                auftrag(ziel),
                radar("Rival-Schwächen für Wegnahme", rival.isEmpty
                      ? "Wettbewerber benennen — sonst keine Wegnahme-Rechnung."
                      : "Vergleich \(firma.isEmpty ? "Eigen" : firma) gegen \(rival)."),
                macht("Legal Wegnahme-Hebel & Grenzen", "Nur zulässige Druckpunkte. Kartell/UWG bleiben hart."),
                mensch(.opportunisma, "Hebel in Position", "CI-Desk: zulässige Optionen ohne Grenzüberschreitung."),
                mensch(.sunTzu, "Zugwahl", "Welcher Zug wirkt, welcher zu weit geht."),
                mensch(.strategos, "Szenario Druck", "Rechtlich saubere Szenarien gegen Rival-Lücken."),
                mensch(.entscheidungsjournal, "Grenze festhalten", "Hebel und Verbote ins Journal.")
            ]
        case .chancenRisiken:
            return [
                auftrag(ziel),
                radar("Macht-Chancen und -Risiken rechnen", "Eigen + Rival in einem Befund."),
                macht("Chancen / Risiken Machtlage", "Erhalt, Wegnahme legal, eigene und Rival-Schwächen."),
                mensch(.strategos, "Chancen-Szenarien", "Welche Szenarien Chancen heben, welche Risiken senken."),
                mensch(.opportunisma, "Optionsraum", "Positionierung und Hebel priorisieren."),
                mensch(.entscheidungsjournal, "Prioritäten sichern", "Gewählte Chance/Risiko-Antwort dokumentieren.")
            ]
        case .alleFunktionen:
            return SeitenleistenEintrag.commandSidebarOrder
                .filter { $0 != .durchlauf }
                .map { modul in
                    mensch(modul, modul.bezeichnung, modul.commandSubtitle ?? "Modul der Suite.")
                }
        case .selbst:
            return []
        }
    }
    private static func auftrag(_ ziel: DurchlaufZiel) -> DurchlaufSchritt {
        DurchlaufSchritt(
            modul: nil,
            titel: "Auftrag",
            warum: ziel.satz,
            tun: "Die Angaben aus dem Start werden hier festgehalten. Im Automatik-Modus passiert das von selbst.",
            art: .auftrag
        )
    }
    private static func radar(_ titel: String, _ warum: String) -> DurchlaufSchritt {
        DurchlaufSchritt(
            modul: .enterpriseRadar,
            titel: titel,
            warum: warum,
            tun: "Der Radar rechnet mit Name, Branche, Größe und den Signalen aus dem Text. Im Automatik-Modus ohne weiteren Klick.",
            art: .radar
        )
    }
    private static func macht(_ titel: String, _ warum: String) -> DurchlaufSchritt {
        DurchlaufSchritt(
            modul: .enterpriseRadar,
            titel: titel,
            warum: warum,
            tun: "Die Machtlage wird aus dem Radar-Ergebnis abgeleitet — Erhalt, Beibehalten, Wegnahme nur legal, eigene und Rival-Schwächen.",
            art: .macht
        )
    }
    private static func mensch(_ modul: SeitenleistenEintrag, _ titel: String, _ warum: String) -> DurchlaufSchritt {
        DurchlaufSchritt(
            modul: modul,
            titel: titel,
            warum: warum,
            tun: "Dieser Schritt öffnet \(modul.bezeichnung) als Fenster. Die Führung bleibt hier. Erledigt setzen Sie selbst.",
            art: .mensch
        )
    }
}
struct DurchlaufView: View {
    @State private var modell = DurchlaufModell()
    @Bindable private var appearance = AppearanceStore.shared
    var body: some View {
        ZStack {
            PremiumAurora()
            Group {
                if modell.laeuft {
                    lauf
                } else {
                    start
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fenlynineOSAdaptiveNavigationTitle("Durchlauf")
        .sheet(isPresented: $modell.hinzufuegen) {
            funktionswahl
        }
        .id(appearance.modus)
    }
    private var start: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Durchlauf")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Premium.text)
                    Text("Frage oder Auftrag einfügen — die Suite wählt die Funktionen. Macht-Erhalt, Beibehalten, legale Wegnahme, eigene und Rival-Schwächen.")
                        .font(.system(size: 13))
                        .foregroundStyle(Premium.textSoft)
                }
                if let v = modell.vorschlagZiel, v != modell.ziel {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Premium.action)
                        Text("Aus dem Text erkannt: \(v.titel)")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Button("Übernehmen") { modell.ziel = v }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                    .padding(12)
                    .premiumGlas(radius: 14, elevated: true)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(DurchlaufZiel.allCases) { ziel in
                        Button {
                            modell.ziel = ziel
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: ziel.symbol)
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(width: 22)
                                    .foregroundStyle(Premium.action)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ziel.titel)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Premium.text)
                                    Text(ziel.satz)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Premium.textSoft)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                            .premiumGlas(radius: 16, elevated: modell.ziel == ziel)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(modell.ziel == ziel ? Premium.action.opacity(0.55) : Color.clear, lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Angaben für die Rechnung")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Premium.text)
                    feld("Eigenes Unternehmen", text: $modell.firma)
                    feld("Wettbewerber", text: $modell.rival)
                    HStack(spacing: 8) {
                        feld("Beschäftigte, optional", text: $modell.mitarbeiterText)
                        Picker("Branche", selection: $modell.branche) {
                            ForEach(ERBranche.allCases) { b in
                                Text(b.titel).tag(b)
                            }
                        }
                        .frame(maxWidth: 280)
                    }
                    Text("Gesamttext / Frage")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Frage oder Bericht einfügen. Die Suite erkennt z. B. Macht-Erhalt, Beibehalten, legale Wegnahme, eigene Schwäche. Optional Zeilen: Unternehmen: …, Wettbewerber: …, Beschäftigte: …, Branche: ….")
                        .font(.system(size: 11))
                        .foregroundStyle(Premium.textSoft)
                    TextEditor(text: $modell.gesamttext)
                        .font(.system(size: 13))
                        .frame(minHeight: 260)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .premiumGlas(radius: 16, elevated: false)
                }
                Text("„Einfügen und durchlaufen“ setzt den Text in den Auftrag und den Enterprise-Radar und arbeitet danach jeden Schritt ab.")
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.textSoft)
                HStack(spacing: 8) {
                    Button("Einfügen und durchlaufen") {
                        modell.modus = .automatisch
                        modell.starten()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Nur Schritt für Schritt") {
                        modell.modus = .manuell
                        modell.starten()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
            .frame(maxWidth: 820, alignment: .leading)
        }
    }
    private var lauf: some View {
        HStack(spacing: 0) {
            liste
            Rectangle().fill(Premium.hairline).frame(width: 1)
            schrittKarte
        }
    }
    private var liste: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(modell.ziel.titel)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                Text(modell.modus.titel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Premium.textSoft)
            }
            .padding(12)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(modell.schritte.enumerated()), id: \.element.id) { i, schritt in
                        HStack(spacing: 6) {
                            Button {
                                modell.waehle(i)
                            } label: {
                                HStack(spacing: 8) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .frame(width: 18)
                                        .foregroundStyle(modell.index == i ? Premium.action : Premium.textFaint)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(schritt.titel)
                                            .font(.system(size: 12, weight: modell.index == i ? .semibold : .regular))
                                            .lineLimit(2)
                                        if schritt.erledigt {
                                            Text("erledigt")
                                                .font(.system(size: 9))
                                                .foregroundStyle(Premium.textFaint)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(modell.index == i ? Premium.action.opacity(0.12) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                            Button {
                                modell.entferne(schritt.id)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Premium.textFaint)
                            }
                            .buttonStyle(.plain)
                            .help("Schritt entfernen")
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.bottom, 8)
            }
            Button {
                modell.hinzufuegen = true
            } label: {
                Label("Funktion hinzufügen", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .padding(12)
            Divider().overlay(Premium.hairline)
            Button("Neuer Auftrag") { modell.neu() }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(Premium.textSoft)
                .padding(12)
        }
        .frame(width: 272)
        .premiumGlasLeiste()
    }
    private var schrittKarte: some View {
        Group {
            if modell.schritte.isEmpty {
                VStack(spacing: 12) {
                    Text("Keine Funktion in diesem Durchlauf.")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Fügen Sie links die Module hinzu, in der Reihenfolge, in der Sie sie brauchen.")
                        .font(.system(size: 12))
                        .foregroundStyle(Premium.textSoft)
                        .multilineTextAlignment(.center)
                    Button("Funktion hinzufügen") { modell.hinzufuegen = true }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else if let schritt = modell.aktuell {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Schritt \(modell.index + 1) von \(modell.schritte.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Premium.textSoft)
                        Text(schritt.titel)
                            .font(.system(size: 22, weight: .semibold))
                        if let modul = schritt.modul {
                            Text(modul.commandLabel)
                                .font(.system(size: 12))
                                .foregroundStyle(Premium.action)
                        }
                        Text(schritt.warum)
                            .font(.system(size: 14))
                        Text(schritt.tun)
                            .font(.system(size: 13))
                            .foregroundStyle(Premium.textSoft)
                        if let ergebnis = schritt.ergebnis, !ergebnis.isEmpty {
                            Text(ergebnis)
                                .font(.system(size: 13))
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .premiumGlas(radius: 14, elevated: false)
                        }
                        HStack(spacing: 8) {
                            Button("Zurück") { modell.zurueck() }
                                .buttonStyle(.bordered)
                                .disabled(modell.index == 0)
                            if schritt.modul != nil {
                                Button("Modul öffnen") { modell.oeffneModul() }
                                    .buttonStyle(.bordered)
                            }
                            if schritt.art == .radar || schritt.art == .macht {
                                Button("Erneut rechnen") { modell.erneutRechnen() }
                                    .buttonStyle(.bordered)
                            }
                            Spacer()
                            Button(modell.index + 1 == modell.schritte.count ? "Erledigt" : "Erledigt und weiter") {
                                modell.erledigtUndWeiter()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(schritt.erledigt && modell.index + 1 == modell.schritte.count)
                        }
                        if modell.schritte.allSatisfy(\.erledigt), !modell.schritte.isEmpty {
                            Text("Durchlauf ist durch. Die Ergebnisse stehen bei den einzelnen Schritten.")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: 720, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var funktionswahl: some View {
        NavigationStack {
            List(gefilterteModule, id: \.self) { modul in
                Button {
                    modell.einfuegen(modul)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(modul.bezeichnung)
                        if let sub = modul.commandSubtitle {
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $modell.suche, prompt: "Funktion suchen")
            .navigationTitle("Funktion hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { modell.hinzufuegen = false }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 480)
    }
    private var gefilterteModule: [SeitenleistenEintrag] {
        let basis = SeitenleistenEintrag.commandSidebarOrder.filter { $0 != .durchlauf }
        let q = modell.suche.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return basis }
        return basis.filter {
            $0.bezeichnung.lowercased().contains(q)
                || $0.commandLabel.lowercased().contains(q)
                || ($0.commandSubtitle?.lowercased().contains(q) ?? false)
        }
    }
    private func feld(_ platz: String, text: Binding<String>) -> some View {
        TextField(platz, text: text)
            .textFieldStyle(.roundedBorder)
    }
}
