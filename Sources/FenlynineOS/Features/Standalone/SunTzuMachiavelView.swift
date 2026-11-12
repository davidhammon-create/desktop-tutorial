import SwiftUI
import AppKit
struct StrategiePrinzip: Identifiable, Hashable {
    let id: String
    let autor: String
    let titel: String
    let kerngedanke: String
    let anwaltlich: String
    let quelle: String
    let tags: [String]
}
enum StrategieLexikon {
    static let alle: [StrategiePrinzip] = [
        StrategiePrinzip(
            id: "st-know", autor: "Sun Tzu",
            titel: "Sich und den Gegner kennen",
            kerngedanke: "Kennt man den Gegner und sich selbst, ist man in hundert Schlachten unbesiegt.",
            anwaltlich: "Vor jedem Schriftsatz / Termin: Beweis- und Rechtslage beider Seiten tabellarisch gegenüberstellen. Unklarheiten explizit als Informationslücken markieren.",
            quelle: "Sun Tzu, Die Kunst des Krieges, Kap. III",
            tags: ["information", "lage"]
        ),
        StrategiePrinzip(
            id: "st-terrain", autor: "Sun Tzu",
            titel: "Das Terrain wählen",
            kerngedanke: "Wer das Terrain bestimmt, bestimmt den Kampf.",
            anwaltlich: "Forum, Gerichtszweig, Vergleichs- vs. Prozessspur, Beweisaufnahme-Ort — aktiv steuern, nicht hinnehmen. Zuständigkeit und Rechtsweg früh prüfen.",
            quelle: "Sun Tzu, Die Kunst des Krieges, Kap. X–XI",
            tags: ["forum", "prozess"]
        ),
        StrategiePrinzip(
            id: "st-speed", autor: "Sun Tzu",
            titel: "Geschwindigkeit schlägt Masse",
            kerngedanke: "Schnell handeln, wo der Gegner unvorbereitet ist.",
            anwaltlich: "Fristen als Waffe: frühe Beweisangebote, einstweilige Verfügungen, Vorbringen vor der Gegenseite — aber nur, wenn die Substanz trägt.",
            quelle: "Sun Tzu, Die Kunst des Krieges, Kap. VI",
            tags: ["zeit", "frist"]
        ),
        StrategiePrinzip(
            id: "st-deception", autor: "Sun Tzu",
            titel: "Schein und Sein",
            kerngedanke: "Krieg beruht auf Täuschung — aber nur gegenüber dem Feind.",
            anwaltlich: "Prozessuales Taktiertes Vorbringen ist legitim; bewusstes Täuschen des Gerichts ist berufsrechtswidrig. Unterschied: Strategie ≠ Unwahrheit.",
            quelle: "Sun Tzu, Die Kunst des Krieges, Kap. I; § 43 BRAO",
            tags: ["ethik", "taktik"]
        ),
        StrategiePrinzip(
            id: "st-avoid", autor: "Sun Tzu",
            titel: "Den direkten Kampf meiden",
            kerngedanke: "Die höchste Kunst ist, den Feind ohne Kampf zu unterwerfen.",
            anwaltlich: "Vergleich, Mediation, Anerkenntnis mit Kostenregelung, Abgabe an Schiedsgericht — oft wertvoller als ein pyrrhischer Sieg. Rechenwerk (ZOPA) nutzen.",
            quelle: "Sun Tzu, Die Kunst des Krieges, Kap. III",
            tags: ["vergleich", "nutzen"]
        ),
        StrategiePrinzip(
            id: "st-spies", autor: "Sun Tzu",
            titel: "Informationsvorsprung",
            kerngedanke: "Vorausschauende Kenntnis entscheidet.",
            anwaltlich: "Akteneinsicht, Auskunftsansprüche, Discovery (US), Zeugenaussagen vorbereiten, öffentliche Register — legal beschaffen, früh auswerten.",
            quelle: "Sun Tzu, Die Kunst des Krieges, Kap. XIII",
            tags: ["information"]
        ),
        StrategiePrinzip(
            id: "m-virtu", autor: "Machiavelli",
            titel: "Virtù — Handlungskraft",
            kerngedanke: "Virtù ist die Fähigkeit, Gelegenheit zu ergreifen und Fortuna zu zwingen.",
            anwaltlich: "Mandat aktiv führen: Entscheidungsvorlagen, klare Empfehlung, Fristkalender. Passivität ist oft die teuerste Option (Option D durchrechnen).",
            quelle: "Machiavelli, Il Principe, Kap. VI–VII, XXV",
            tags: ["führung", "entscheidung"]
        ),
        StrategiePrinzip(
            id: "m-fortuna", autor: "Machiavelli",
            titel: "Fortuna vorbereiten",
            kerngedanke: "Fortuna begünstigt den Vorbereiteten.",
            anwaltlich: "Szenarien A/B/C vorhalten (Prozess, Vergleich, Abbruch). Beweise und Schriftsatz-Entwürfe vor dem kritischen Termin fertigstellen.",
            quelle: "Machiavelli, Il Principe, Kap. XXV",
            tags: ["szenario", "vorbereitung"]
        ),
        StrategiePrinzip(
            id: "m-fear", autor: "Machiavelli",
            titel: "Furcht und Liebe",
            kerngedanke: "Besser gefürchtet als geliebt — wenn man nicht beides sein kann. Aber gehasst werden ist tödlich.",
            anwaltlich: "Glaubwürdigkeit vor Gericht und der Gegenseite: konsequente Linie, keine leeren Drohungen. Reputation der Kanzlei ist Verhandlungskapital.",
            quelle: "Machiavelli, Il Principe, Kap. XVII",
            tags: ["reputation", "verhandlung"]
        ),
        StrategiePrinzip(
            id: "m-appear", autor: "Machiavelli",
            titel: "Schein der Tugend",
            kerngedanke: "Ein Fürst muss die Tugenden scheinen, nicht immer besitzen.",
            anwaltlich: "Prozesskommunikation und Öffentlichkeit: Haltung, Ton, Medienstrategie. Inhaltlich wahrhaftig bleiben; Darstellung steuern.",
            quelle: "Machiavelli, Il Principe, Kap. XVIII; § 43a BRAO",
            tags: ["kommunikation", "ethik"]
        ),
        StrategiePrinzip(
            id: "m-fox", autor: "Machiavelli",
            titel: "Löwe und Fuchs",
            kerngedanke: "Der Löwe schreckt die Wölfe, der Fuchs erkennt die Fallen.",
            anwaltlich: "Härte (Klage, Vollstreckung, Kostenandrohung) und List (Vergleichsangebot mit Frist, Teilklage, Anerkenntnisdruck) kombiniert einsetzen.",
            quelle: "Machiavelli, Il Principe, Kap. XVIII",
            tags: ["taktik", "verhandlung"]
        ),
        StrategiePrinzip(
            id: "m-alliance", autor: "Machiavelli",
            titel: "Bündnisse wählen",
            kerngedanke: "Schwächere Verbündete machen abhängig; stärkere können beherrschen.",
            anwaltlich: "Ko-Mandant, Streitverkündung, Nebenintervention, Litigation Funding — Allianzen prüfen, Interessenkonflikte (BRAO) dokumentieren.",
            quelle: "Machiavelli, Il Principe, Kap. XXI",
            tags: ["allianz", "mandat"]
        )
    ]
    static func fuer(tags: Set<String>) -> [StrategiePrinzip] {
        alle
            .map { p in (p, Set(p.tags).intersection(tags).count) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }
}
struct LageFaktoren {
    var fristendruck: Double = 0.4
    var beweisstaerke: Double = 0.5
    var kostenDruck: Double = 0.4
    var oeffentlichkeit: Double = 0.2
    var machtAsymmetrie: Double = 0.5
    var informationsVorsprung: Double = 0.5
    var vergleichBereit: Double = 0.5
}
struct StrategieEmpfehlung: Identifiable {
    let id = UUID()
    let prioritaet: Int
    let titel: String
    let text: String
    let prinzipId: String?
    let herkunft: QuellenAuskunft
}
enum StrategieMotor {
    struct Ergebnis {
        let lageScore: Double
        let lageLabel: String
        let empfehlungen: [StrategieEmpfehlung]
        let aktivePrinzipien: [StrategiePrinzip]
        let roteLinien: [String]
        let modell: String
    }
    static func analysieren(
        fall: String,
        gegner: String,
        ziel: String,
        f: LageFaktoren
    ) -> Ergebnis {
        let score =
            100 * (
                0.22 * f.beweisstaerke +
                0.18 * f.informationsVorsprung +
                0.15 * f.machtAsymmetrie +
                0.15 * (1 - f.fristendruck) +
                0.12 * (1 - f.kostenDruck) +
                0.10 * f.vergleichBereit +
                0.08 * (1 - f.oeffentlichkeit)
            )
        let label: String
        switch score {
        case 70...: label = "Günstig — Initiative nutzen"
        case 45..<70: label = "Ausgewogen — Lage aktiv steuern"
        default: label = "Angespannt — Absichern und Zeit kaufen"
        }
        var tags = Set<String>()
        if f.fristendruck > 0.6 { tags.insert("frist"); tags.insert("zeit") }
        if f.informationsVorsprung < 0.45 { tags.insert("information") }
        if f.beweisstaerke < 0.45 { tags.insert("information") }
        if f.machtAsymmetrie < 0.4 { tags.insert("allianz"); tags.insert("verhandlung") }
        if f.vergleichBereit > 0.55 { tags.insert("vergleich"); tags.insert("nutzen") }
        if f.oeffentlichkeit > 0.5 { tags.insert("kommunikation"); tags.insert("reputation") }
        if f.kostenDruck > 0.6 { tags.insert("vergleich"); tags.insert("nutzen") }
        tags.insert("lage"); tags.insert("führung"); tags.insert("ethik")
        let prinzipien = StrategieLexikon.fuer(tags: tags)
        var empfehlungen: [StrategieEmpfehlung] = []
        empfehlungen.append(StrategieEmpfehlung(
            prioritaet: 1,
            titel: "Lagebild dokumentieren",
            text: "Beweis- und Rechtslage beider Seiten in einer Tabelle fixieren. Informationslücken als eigene Zeilen führen — nicht stillschweigend annehmen.",
            prinzipId: "st-know",
            herkunft: .formel(
                "Pflichtschritt vor jeder Strategieempfehlung",
                formel: "LageScore = 0,22·Beweis + 0,18·Info + 0,15·Macht + 0,15·(1−Frist) + 0,12·(1−Kosten) + 0,10·Vergleich + 0,08·(1−Öffentlichkeit)",
                datenbasis: "Ihre Schieberegler · keine KI"
            )
        ))
        if f.fristendruck > 0.55 {
            empfehlungen.append(StrategieEmpfehlung(
                prioritaet: 2,
                titel: "Fristen als Steuerungsinstrument",
                text: "Nächste Notfrist und gegnerische Reaktionsfenster kalendern. Frühes Vorbringen nur, wenn die Substanz trägt — sonst Zeit kaufen (Fristverlängerung, Vergleichsgespräch).",
                prinzipId: "st-speed",
                herkunft: .formel("Fristendruck > 0,55", formel: "Priorität Zeit/Frist", datenbasis: "Regler Fristendruck")
            ))
        }
        if f.informationsVorsprung < 0.5 || f.beweisstaerke < 0.45 {
            empfehlungen.append(StrategieEmpfehlung(
                prioritaet: 2,
                titel: "Informationsvorsprung herstellen",
                text: "Akteneinsicht, Auskunftsansprüche, Zeugenlisten, Registerauszüge — legal und früh. Keine Spekulation über ungesicherte Fakten in Schriftsätzen.",
                prinzipId: "st-spies",
                herkunft: .formel("Info oder Beweis < Schwelle", formel: "Info < 0,5 ∨ Beweis < 0,45", datenbasis: "Regler Informationsvorsprung / Beweisstärke")
            ))
        }
        if f.vergleichBereit > 0.5 || f.kostenDruck > 0.6 || score < 50 {
            empfehlungen.append(StrategieEmpfehlung(
                prioritaet: 3,
                titel: "Vergleichskorridor berechnen",
                text: "Im Vorgang-Rechenwerk ZOPA und Zertitätsäquivalent prüfen. Ein pyrrhischer Prozesssieg ist oft schlechter als ein früher Vergleich.",
                prinzipId: "st-avoid",
                herkunft: .formel(
                    "Vergleichsbereitschaft hoch, Kostendruck hoch oder Lage angespannt",
                    formel: "Vergleich ≥ 0,5 ∨ Kosten ≥ 0,6 ∨ Score < 50",
                    datenbasis: "Lagefaktoren · Verweis auf Monte-Carlo/ZOPA"
                )
            ))
        }
        if f.machtAsymmetrie < 0.4 {
            empfehlungen.append(StrategieEmpfehlung(
                prioritaet: 3,
                titel: "Asymmetrie ausgleichen",
                text: "Streitverkündung, Nebenintervention, Prozessfinanzierung oder Spezialmandat prüfen. Interessenkonflikte nach BRAO dokumentieren.",
                prinzipId: "m-alliance",
                herkunft: .formel("Machtasymmetrie < 0,4 (Gegner stärker)", formel: "Macht < 0,4", datenbasis: "Regler Machtasymmetrie")
            ))
        }
        if f.oeffentlichkeit > 0.55 {
            empfehlungen.append(StrategieEmpfehlung(
                prioritaet: 4,
                titel: "Kommunikationslinie festlegen",
                text: "Eine abgestimmte Linie für Gericht, Gegenseite und ggf. Medien. Inhaltlich wahrhaftig; Darstellung steuern. Keine Vorverurteilung in der Öffentlichkeit.",
                prinzipId: "m-appear",
                herkunft: .formel("Öffentlichkeit > 0,55", formel: "Öffentlichkeit > 0,55", datenbasis: "Regler Öffentlichkeit")
            ))
        }
        empfehlungen.append(StrategieEmpfehlung(
            prioritaet: 5,
            titel: "Entscheidung vorbereiten (Virtù)",
            text: "Dem Mandanten eine klare Empfehlung mit Alternativen A/B/C vorlegen — inkl. Option ‚Nichts tun‘. Passivität ist oft die teuerste Wahl.",
            prinzipId: "m-virtu",
            herkunft: .formel("Standard-Abschluss jedes Strategielaufs", formel: "immer", datenbasis: "Machiavelli Virtù → Mandatsführung")
        ))
        let blob = (fall + " " + gegner + " " + ziel).lowercased()
        if blob.contains("vergleich") || blob.contains("mediation") || blob.contains("settlement") {
            empfehlungen.insert(StrategieEmpfehlung(
                prioritaet: 2,
                titel: "Vergleichsspur priorisieren",
                text: "Im Eingabetext ist Vergleich/Mediation angelegt — ZOPA und Ankerempfehlung zuerst rechnen, Prozessspur parallel absichern.",
                prinzipId: "st-avoid",
                herkunft: .lokal("Schlüsselwort im Falltext", basis: "Lokal erkannt: Vergleich/Mediation/Settlement")
            ), at: min(1, empfehlungen.count))
        }
        if blob.contains("einstweilige") || blob.contains("injunction") || blob.contains("verfügung") {
            empfehlungen.insert(StrategieEmpfehlung(
                prioritaet: 1,
                titel: "Eilrechtsschutz prüfen",
                text: "Einstweilige Verfügung / injunction angedeutet — Dringlichkeit, Verfügungsanspruch und Sicherheitsleistung sofort skizzieren.",
                prinzipId: "st-speed",
                herkunft: .lokal("Schlüsselwort im Falltext", basis: "Lokal erkannt: einstweilige Verfügung / injunction")
            ), at: 0)
        }
        let roteLinien = [
            "Kein bewusstes Täuschen des Gerichts — Taktik ≠ Unwahrheit (§ 43 BRAO).",
            "Keine Interessenkollision ohne Dokumentation / Mandatsablehnung (§ 43a Abs. 4 BRAO).",
            "Keine Drohungen ohne Substanz — leere Drohungen zerstören Glaubwürdigkeit.",
            "KI-Ausgaben (falls genutzt) sind unbestätigte Vorschläge — Endprüfung bleibt beim Anwalt."
        ]
        return Ergebnis(
            lageScore: score,
            lageLabel: label,
            empfehlungen: empfehlungen.sorted { $0.prioritaet < $1.prioritaet },
            aktivePrinzipien: Array(prinzipien.prefix(6)),
            roteLinien: roteLinien,
            modell: "Heuristik v1 · Gewichte fest · deterministisch"
        )
    }
}
struct FenylawStrategiesView: View {
    @State private var fallText = ""
    @State private var gegner = ""
    @State private var ziel = ""
    @State private var faktoren = LageFaktoren()
    @State private var lokal: StrategieMotor.Ergebnis?
    @State private var kiResult: [String: Any]?
    @State private var laeuftKI = false
    @State private var fehler: String?
    @State private var tab = 0
    @State private var briefKopiert: SeitenleistenEintrag?
    var body: some View {
        VStack(spacing: 0) {
            kopf
            Divider().overlay(Premium.hairline)
            Picker("", selection: $tab) {
                Text("Lage & Empfehlung").tag(0)
                Text("Prozessstrecke").tag(1)
                Text("Prinzipien-Lexikon").tag(2)
                Text("KI-Vertiefung").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            Group {
                switch tab {
                case 1: prozessAnsicht
                case 2: lexikonAnsicht
                case 3: kiAnsicht
                default: lageAnsicht
                }
            }
        }
        .background(Color.clear)
        .fenlynineOSAdaptiveNavigationTitle("Fenylaw Strategies")
    }
    private var kopf: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Fenylaw Strategies")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Premium.text)
                    QuellenInfo(auskunft: .formel(
                        "Klassische Strategielehre, übersetzt in Prozess- und Verhandlungsführung",
                        formel: "Lokaler Heuristik-Motor + kuratiertes Lexikon · optional KI",
                        datenbasis: "Strategie-Engine Sun Tzu × Machiavelli · BRAO-Rote-Linien · Ihre Eingaben"
                    ))
                }
                Text("Strategieraum — Lagebild, Prinzipien, Prozessstrecke zu Lexara · Strategos · Opportunisma. Ohne KI nutzbar.")
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.textSoft)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .premiumGlasLeiste()
    }
    private var modulEmpfehlung: (ziel: SeitenleistenEintrag, grund: String) {
        let blob = (fallText + " " + ziel).lowercased()
        if faktoren.beweisstaerke < 0.5 || faktoren.informationsVorsprung < 0.45 {
            return (.lexara, "Beweis- oder Informationslage unter Schwelle — zuerst Fakten und Rechtslage in Lexara härten.")
        }
        if faktoren.vergleichBereit > 0.55 || blob.contains("vergleich") || blob.contains("forderung") || blob.contains("anspruch") {
            return (.opportunisma, "Vergleichs-/Forderungslage angelegt — Chancen und Forderungsstrategie in Opportunisma quantifizieren.")
        }
        return (.strategos, "Lage tragfähig — Szenarien und Optionen in Strategos durchspielen.")
    }
    private var prozessAnsicht: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("DER FENYLAW-PROZESS")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(Premium.textFaint)
                    QuellenInfo(auskunft: .formel(
                        "Vier-Phasen-Strecke durch die Kernmodule",
                        formel: "Fenylaw (Lage) → Lexara (Recht & Fakten) → Strategos (Szenarien) → Opportunisma (Chancen)",
                        datenbasis: "Modul-Empfehlung aus Ihren Lagefaktoren — keine KI"
                    ))
                    Spacer()
                }
                if lokal == nil {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "1.circle.fill")
                            .foregroundStyle(Premium.action)
                        Text("Zuerst im Tab „Lage & Empfehlung“ Fall eingeben und Lage berechnen — die Prozessstrecke übernimmt Ihre Eingaben in die Übergabe-Briefe.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Premium.textSoft)
                    }
                    .padding(12)
                    .premiumGlas(radius: 10)
                } else {
                    let emp = modulEmpfehlung
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(Premium.computed)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Empfohlener nächster Schritt: \(emp.ziel.bezeichnung)")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(Premium.text)
                            Text(emp.grund)
                                .font(.system(size: 11.5))
                                .foregroundStyle(Premium.textSoft)
                        }
                        Spacer()
                        QuellenInfo(auskunft: .formel(
                            "Routing-Regel",
                            formel: "Beweis < 0,5 ∨ Info < 0,45 → Lexara · Vergleich > 0,55 ∨ Keyword → Opportunisma · sonst Strategos",
                            datenbasis: "Ihre Lagefaktoren + Falltext-Keywords"
                        ))
                    }
                    .padding(12)
                    .premiumGlas(radius: 10, elevated: true)
                }
                phasenKarte(
                    nummer: 1, ziel: nil,
                    titel: "Fenylaw Strategies — Lage",
                    text: "Lagescore, Empfehlungen und rote Linien bestimmen. Ergebnis ist die Grundlage aller Übergaben.",
                    erledigt: lokal != nil
                )
                phasenKarte(
                    nummer: 2, ziel: .lexara,
                    titel: "Lexara — Recht & Fakten",
                    text: "Anspruchsgrundlagen, Beweise, Fristen und Richterprofile härten. Der Strategie-Brief liegt nach der Übergabe in der Zwischenablage.",
                    erledigt: false
                )
                phasenKarte(
                    nummer: 3, ziel: .strategos,
                    titel: "Strategos — Szenarien",
                    text: "Optionen und Was-wäre-wenn-Szenarien durchrechnen; Verhandlungs- und Prozessspur vergleichen.",
                    erledigt: false
                )
                phasenKarte(
                    nummer: 4, ziel: .opportunisma,
                    titel: "Opportunisma — Chancen",
                    text: "Forderungs- und Vergleichsstrategie quantifizieren; Anker und Walk-away aus dem Rechenwerk übernehmen.",
                    erledigt: false
                )
                Text("Bei jeder Übergabe wird ein kompakter Strategie-Brief (Fall, Gegner, Ziel, Lagescore, Top-Empfehlungen) in die Zwischenablage gelegt — im Zielmodul einfach einfügen.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Premium.textFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
    }
    private func phasenKarte(nummer: Int, ziel: SeitenleistenEintrag?, titel: String, text: String, erledigt: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: erledigt ? "checkmark.circle.fill" : "\(nummer).circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(erledigt ? Premium.computed : Premium.action)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(titel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Premium.text)
                Text(text)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Premium.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if let ziel {
                Button {
                    uebergabe(an: ziel)
                } label: {
                    Label(briefKopiert == ziel ? "Brief kopiert ✓" : "Übergeben", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Premium.onAction)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(briefKopiert == ziel ? Premium.computed : Premium.action))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .premiumGlas(radius: Premium.rOuter)
    }
    private func uebergabe(an zielModul: SeitenleistenEintrag) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(strategieBrief(), forType: .string)
        briefKopiert = zielModul
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            NotificationCenter.default.post(name: .navigateToSidebar, object: zielModul.rawValue)
        }
    }
    private func strategieBrief() -> String {
        var teile: [String] = ["── FENYLAW STRATEGIE-BRIEF ──"]
        if !fallText.isEmpty { teile.append("FALL:\n\(fallText)") }
        if !gegner.isEmpty { teile.append("GEGNER: \(gegner)") }
        if !ziel.isEmpty { teile.append("ZIEL: \(ziel)") }
        if let e = lokal {
            teile.append("LAGESCORE: \(Int(e.lageScore)) / 100 — \(e.lageLabel)")
            let top = e.empfehlungen.prefix(3).map { "• \($0.titel): \($0.text)" }
            if !top.isEmpty { teile.append("TOP-EMPFEHLUNGEN:\n" + top.joined(separator: "\n")) }
        }
        teile.append("(Quelle: Fenylaw Strategies · deterministische Heuristik · \(Date().formatted(date: .abbreviated, time: .shortened)))")
        return teile.joined(separator: "\n\n")
    }
    private var lageAnsicht: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                eingabeKarte
                faktorKarte
                Button {
                    lokal = StrategieMotor.analysieren(
                        fall: fallText, gegner: gegner, ziel: ziel, f: faktoren
                    )
                } label: {
                    Label("Lage berechnen", systemImage: "function")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Premium.onAction)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Premium.action))
                }
                .buttonStyle(.plain)
                .disabled(fallText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if let e = lokal {
                    ergebnisBlock(e)
                }
            }
            .padding(16)
        }
    }
    private var eingabeKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FALL")
                .font(.system(size: 10, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(Premium.textFaint)
            TextEditor(text: $fallText)
                .font(.system(size: 12.5))
                .frame(minHeight: 90, maxHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(8)
                .premiumGlas(radius: 8)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GEGNER / GEGENSEITE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Premium.textFaint)
                    TextField("Kanzlei, Stil, bekannte Taktik…", text: $gegner)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .premiumGlas(radius: 8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("STRATEGISCHES ZIEL")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Premium.textFaint)
                    TextField("z. B. früher Vergleich / Abwehr EV…", text: $ziel)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .premiumGlas(radius: 8)
                }
            }
        }
        .padding(14)
        .premiumGlas(radius: Premium.rOuter, elevated: true)
    }
    private var faktorKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LAGEFAKTOREN")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(Premium.textFaint)
                Spacer()
                QuellenInfo(auskunft: .formel(
                    "Eingaben für den deterministischen Lagescore",
                    formel: "Score = Σ (Gewichtᵢ × Faktorᵢ) · Gewichte fest",
                    datenbasis: "Ihre Einschätzung 0–1 — keine KI"
                ))
            }
            faktorZeile("Fristendruck", $faktoren.fristendruck, "hoch = ungünstig")
            faktorZeile("Beweisstärke", $faktoren.beweisstaerke, "eigene Seite")
            faktorZeile("Informationsvorsprung", $faktoren.informationsVorsprung, "Kenntnis Vorsprung")
            faktorZeile("Machtasymmetrie", $faktoren.machtAsymmetrie, ">0,5 = wir stärker")
            faktorZeile("Kostendruck", $faktoren.kostenDruck, "Mandant / Gegner")
            faktorZeile("Vergleichsbereitschaft", $faktoren.vergleichBereit, "eigene Seite")
            faktorZeile("Öffentlichkeit", $faktoren.oeffentlichkeit, "Medien / Reputation")
        }
        .padding(14)
        .premiumGlas(radius: Premium.rOuter)
    }
    private func faktorZeile(_ label: String, _ value: Binding<Double>, _ hint: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Premium.text)
                .frame(width: 160, alignment: .leading)
            Slider(value: value, in: 0...1)
            Text(String(format: "%.0f%%", value.wrappedValue * 100))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Premium.textSoft)
                .frame(width: 40, alignment: .trailing)
            Text(hint)
                .font(.system(size: 10))
                .foregroundStyle(Premium.textFaint)
                .frame(width: 120, alignment: .leading)
        }
    }
    private func ergebnisBlock(_ e: StrategieMotor.Ergebnis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LAGESCORE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Premium.textFaint)
                    Text(String(format: "%.0f", e.lageScore))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(e.lageScore >= 70 ? Premium.computed : (e.lageScore >= 45 ? Premium.proposed : Premium.critical))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.lageLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Premium.text)
                    Text(e.modell)
                        .font(.system(size: 10))
                        .foregroundStyle(Premium.textFaint)
                }
                Spacer()
                QuellenInfo(auskunft: .formel(
                    "Gesamtbewertung der Prozesslage",
                    formel: e.modell,
                    datenbasis: "Lagefaktoren + Keyword-Boost aus Falltext"
                ))
            }
            .padding(14)
            .premiumGlas(radius: Premium.rOuter, elevated: true)
            Text("EMPFEHLUNGEN")
                .font(.system(size: 10, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(Premium.textFaint)
            ForEach(e.empfehlungen) { emp in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(emp.prioritaet)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Premium.action)
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(emp.titel)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Premium.text)
                        Text(emp.text)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Premium.textSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    QuellenInfo(auskunft: emp.herkunft, groesse: 11)
                }
                .padding(12)
                .premiumGlas(radius: 10)
            }
            if !e.aktivePrinzipien.isEmpty {
                Text("AKTIVE PRINZIPIEN")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(Premium.textFaint)
                    .padding(.top, 4)
                ForEach(e.aktivePrinzipien) { p in
                    prinzipZeile(p, kompakt: true)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("BERUFSRECHTLICHE ROTE LINIEN")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(Premium.critical)
                    Spacer()
                    QuellenInfo(auskunft: .quelle(
                        "Nicht verhandelbare Grenzen der Strategie",
                        fundstelle: "§§ 43, 43a BRAO · anwaltliche Wahrheitspflicht"
                    ))
                }
                ForEach(e.roteLinien, id: \.self) { r in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Premium.critical)
                        Text(r)
                            .font(.system(size: 11))
                            .foregroundStyle(Premium.textSoft)
                    }
                }
            }
            .padding(12)
            .premiumGlas(radius: 10)
        }
    }
    private var lexikonAnsicht: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                Text("Zwölf Prinzipien — klassische Quelle und anwaltliche Übersetzung. Jede Zeile mit Fundstelle.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Premium.textSoft)
                    .padding(.bottom, 4)
                ForEach(StrategieLexikon.alle) { p in
                    prinzipZeile(p, kompakt: false)
                }
            }
            .padding(16)
        }
    }
    private func prinzipZeile(_ p: StrategiePrinzip, kompakt: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(p.autor.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.5)
                    .foregroundStyle(p.autor == "Sun Tzu" ? Premium.action : Premium.proposed)
                Text(p.titel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Premium.text)
                Spacer()
                QuellenInfo(auskunft: .quelle(p.titel, fundstelle: p.quelle), groesse: 11)
            }
            if !kompakt {
                Text(p.kerngedanke)
                    .font(.system(size: 11.5).italic())
                    .foregroundStyle(Premium.textFaint)
            }
            Text(p.anwaltlich)
                .font(.system(size: 11.5))
                .foregroundStyle(Premium.textSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .premiumGlas(radius: 10)
    }
    private var kiAnsicht: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Premium.proposed)
                    Text("Optionale Vertiefung durch ein Sprachmodell. Unbestätigt — jede Ausgabe anwaltlich prüfen. Zuerst die lokale Lage berechnen.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Premium.textSoft)
                    QuellenInfo(auskunft: .ki(
                        "Strategische Vertiefung zu Fall, Gegner und Ziel",
                        datenbasis: fallText.isEmpty ? "noch kein Falltext" : "Ihr Falltext + Gegner + Ziel"
                    ))
                }
                .padding(12)
                .premiumGlas(radius: 10)
                if let fehler {
                    Text(fehler).font(.caption).foregroundStyle(Premium.critical)
                }
                Button {
                    Task { await analysierenKI() }
                } label: {
                    HStack {
                        if laeuftKI { ProgressView().controlSize(.small) }
                        Label(laeuftKI ? "Analysiert…" : "KI-Vertiefung starten", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Premium.onAction)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Premium.action))
                }
                .buttonStyle(.plain)
                .disabled(fallText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || laeuftKI)
                if let r = kiResult {
                    kiErgebnis(r)
                }
            }
            .padding(16)
        }
    }
    @ViewBuilder
    private func kiErgebnis(_ r: [String: Any]) -> some View {
        if let summary = r["strategic_summary"] as? String {
            kiKarte("Strategische Zusammenfassung", summary)
        }
        if let path = r["strategic_path"] as? [[String: Any]] {
            VStack(alignment: .leading, spacing: 6) {
                Text("STRATEGISCHER PFAD").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
                ForEach(Array(path.enumerated()), id: \.offset) { _, phase in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase["phase"] as? String ?? "Phase").font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
                        Text(phase["action"] as? String ?? "").font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                        if let t = phase["timing"] as? String {
                            Text("Timing: \(t)").font(.system(size: 10)).foregroundStyle(Premium.textFaint)
                        }
                    }
                    .padding(10)
                    .premiumGlas(radius: 8)
                }
            }
        }
        if let risk = r["risk_assessment"] as? [String: Any] {
            VStack(alignment: .leading, spacing: 4) {
                Text("RISIKO").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
                if let overall = risk["overall_risk"] as? String {
                    Text("Gesamt: \(overall)").font(.system(size: 12, weight: .semibold)).foregroundStyle(Premium.text)
                }
                if let items = risk["critical_risks"] as? [String] {
                    ForEach(items, id: \.self) { item in
                        Text("• \(item)").font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                    }
                }
            }
            .padding(12)
            .premiumGlas(radius: 10)
        }
        if let moves = r["machiavellian_moves"] as? [String] {
            VStack(alignment: .leading, spacing: 4) {
                Text("TAKTISCHE ZÜGE").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.textFaint)
                ForEach(moves, id: \.self) { item in
                    Text("• \(item)").font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                }
            }
            .padding(12)
            .premiumGlas(radius: 10)
        }
        if let red = r["red_lines"] as? [String] {
            VStack(alignment: .leading, spacing: 4) {
                Text("KI-ROTE LINIEN").font(.system(size: 10, weight: .bold)).foregroundStyle(Premium.critical)
                ForEach(red, id: \.self) { item in
                    Text("• \(item)").font(.system(size: 11)).foregroundStyle(Premium.textSoft)
                }
            }
            .padding(12)
            .premiumGlas(radius: 10)
        }
    }
    private func kiKarte(_ titel: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Premium.textFaint)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Premium.text)
                .textSelection(.enabled)
        }
        .padding(12)
        .premiumGlas(radius: 10)
    }
    private func analysierenKI() async {
        laeuftKI = true
        fehler = nil
        kiResult = nil
        defer { laeuftKI = false }
        let lageHinweis: String
        if let e = lokal {
            lageHinweis = "Lokaler Lagescore: \(Int(e.lageScore)) — \(e.lageLabel). Nutze das als Ausgangspunkt, widersprich ihm nur mit Begründung."
        } else {
            lageHinweis = "Kein lokaler Lagescore berechnet — bitte vorsichtig und mit Unsicherheitsmarkierung antworten."
        }
        let prompt = """
        Du bist Strategieberater für zugelassene Anwälte (DACH/EU, ggf. Common Law).
        Beziehe dich auf Sun Tzu und Machiavelli nur als Heuristik — übersetze immer in konkrete Prozess-/Verhandlungsschritte.
        Beachte Berufsrecht: keine Empfehlung zu Gerichtstäuschung oder Interessenkollision.
        FALL:
        \(fallText)
        GEGNER:
        \(gegner.isEmpty ? "unbekannt" : gegner)
        ZIEL:
        \(ziel.isEmpty ? "bestmögliches Ergebnis" : ziel)
        \(lageHinweis)
        Antworte strukturiert gemäß Schema. Sprache: Deutsch.
        """
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "strategic_summary": ["type": "string"],
                "strategic_path": ["type": "array", "items": ["type": "object"]],
                "risk_assessment": ["type": "object"],
                "machiavellian_moves": ["type": "array", "items": ["type": "string"]],
                "red_lines": ["type": "array", "items": ["type": "string"]],
                "win_probability_assessment": ["type": "string"]
            ]
        ]
        do {
            let response: AnyCodable = try await LLMService.shared.invoke(
                prompt: prompt, schema: schema, model: "claude_sonnet_4_6"
            )
            await MainActor.run { kiResult = response.dictValue }
        } catch {
            await MainActor.run { fehler = error.localizedDescription }
        }
    }
}
