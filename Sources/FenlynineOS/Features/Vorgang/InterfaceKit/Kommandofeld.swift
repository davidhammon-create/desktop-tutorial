import SwiftUI
// MARK: - Kommandofeld (⌘K)
//
// Eine Eingabe für alles: Module, Kategorien, Befehle, Vorgänge, Fristen,
// Normen und Schwellenwerte. Leere Eingabe zeigt die häufigsten Befehle.
// Treffer laufen über dieselben Nachrichten wie Menü und Seitenleiste, damit
// sie aus jeder Ansicht heraus wirken (auch aus einem geöffneten Vorgang).

struct Kommandofeld: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var auswahl: Int = 0
    @FocusState private var fokus: Bool
    var onOeffnen: ((Vorgang) -> Void)? = nil
    var aktuellerVorgang: Vorgang? = nil
    private var treffer: [KommandoTreffer] {
        KommandoParser.parse(text, store: VorgangStore.shared, kontext: aktuellerVorgang,
                             istAdmin: KontoStore.shared.istAdmin)
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(InterfacePalette.sekundaer)
                TextField("Modul, Befehl, Vorgang, Frist, § Norm …", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Premium.text)
                    .focused($fokus)
                    .onSubmit { ausfuehren(neueLinse: false) }
                    .onKeyPress(.downArrow) {
                        auswahl = min(auswahl + 1, max(0, treffer.count - 1)); return .handled
                    }
                    .onKeyPress(.upArrow) {
                        auswahl = max(auswahl - 1, 0); return .handled
                    }
                    .onKeyPress(.return, phases: .down) { press in
                        guard press.modifiers.contains(.command) else { return .ignored }
                        ausfuehren(neueLinse: true); return .handled
                    }
                    .onChange(of: text) { _, _ in auswahl = 0 }
                Spacer()
                Text("⌘K")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(InterfacePalette.Material.l3))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            Divider().overlay(InterfacePalette.trennlinie)
            if treffer.isEmpty {
                Text("Nichts gefunden. Tipp: „frist 14“ zeigt Fristen der nächsten 14 Tage, „§ 626“ verknüpfte Normen, „> 1,5 Mio“ große Vorgänge, „?“ unbestätigte KI-Werte.")
                    .font(.system(size: 11))
                    .foregroundStyle(InterfacePalette.sekundaer)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(treffer.enumerated()), id: \.offset) { idx, t in
                                if idx == 0 || treffer[idx - 1].kategorie != t.kategorie {
                                    Text(t.kategorie.uppercased())
                                        .font(.system(size: 9, weight: .bold))
                                        .tracking(0.6)
                                        .foregroundStyle(InterfacePalette.sekundaer)
                                        .padding(.horizontal, 12)
                                        .padding(.top, idx == 0 ? 2 : 8)
                                }
                                treffer_zeile(t, aktiv: idx == auswahl)
                                    .id(idx)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        auswahl = idx
                                        ausfuehren(neueLinse: false)
                                    }
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 340)
                    .onChange(of: auswahl) { _, neu in proxy.scrollTo(neu) }
                }
            }
            Divider().overlay(InterfacePalette.trennlinie)
            HStack(spacing: 12) {
                Text("↑↓ wählen")
                Text("↵ öffnen")
                Text("⌘↵ als Fenster")
                Spacer()
                Text("esc schließen")
            }
            .font(.system(size: 10))
            .foregroundStyle(InterfacePalette.sekundaer)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 640)
        .background(RoundedRectangle(cornerRadius: 12).fill(InterfacePalette.Material.l1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(InterfacePalette.trennlinie, lineWidth: 1))
        .onAppear { fokus = true }
    }
    private func treffer_zeile(_ t: KommandoTreffer, aktiv: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: t.symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(t.farbe)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(t.titel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Premium.text)
                if let u = t.untertitel {
                    Text(u)
                        .font(.system(size: 11))
                        .foregroundStyle(InterfacePalette.sekundaer)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let k = t.kurzbefehl {
                Text(k)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 6).fill(aktiv ? InterfacePalette.aktion.opacity(0.18) : Color.clear))
    }
    /// - Parameter neueLinse: ⌘↵ -- Module als eigenes Fenster öffnen.
    private func ausfuehren(neueLinse: Bool) {
        guard let t = treffer[safe: auswahl] else { return }
        dismiss()
        // Erst nach dem Schließen des Blatts ausführen, sonst landet eine
        // Navigation im gerade verschwindenden Blatt.
        Task { @MainActor in
            switch t.aktion {
            case let .vorgang(v):
                if let onOeffnen { onOeffnen(v) }
                else { NotificationCenter.default.post(name: .oeffneVorgang, object: v.id) }
            case let .modul(e):
                if neueLinse {
                    ModulFensterHost.shared.oeffneModul(e)
                } else {
                    NotificationCenter.default.post(name: .navigateToSidebar, object: e.rawValue)
                }
            case let .kategorie(k):
                NotificationCenter.default.post(name: .oeffneKategorie, object: k.rawValue)
            case let .befehl(b):
                b.ausfuehren()
            }
        }
    }
}

// MARK: - Befehle

enum KommandoBefehl: String, CaseIterable {
    case neuerVorgang, neuerFall, fristBerechnen, kiFragen, vergleich
    case ansichtApple, ansichtNoir, ansichtAtelier, einfuehrung

    var titel: String {
        switch self {
        case .neuerVorgang: return "Neuer Vorgang"
        case .neuerFall: return "Neuer Fall anlegen"
        case .fristBerechnen: return "Frist berechnen"
        case .kiFragen: return "KI-Assistent fragen"
        case .vergleich: return "Module nebeneinander vergleichen"
        case .ansichtApple: return "Darstellung: Apple"
        case .ansichtNoir: return "Darstellung: Noir (dunkel)"
        case .ansichtAtelier: return "Darstellung: Atelier (hell)"
        case .einfuehrung: return "Einführung anzeigen"
        }
    }
    var symbol: String {
        switch self {
        case .neuerVorgang: return "plus.square.on.square"
        case .neuerFall: return "folder.badge.plus"
        case .fristBerechnen: return "calendar.badge.clock"
        case .kiFragen: return "sparkles"
        case .vergleich: return "rectangle.split.3x1"
        case .ansichtApple: return "storefront"
        case .ansichtNoir: return "moon.fill"
        case .ansichtAtelier: return "sun.max.fill"
        case .einfuehrung: return "questionmark.circle"
        }
    }
    var kurzbefehl: String? {
        switch self {
        case .neuerVorgang: return "⌘N"
        case .neuerFall: return "⇧⌘N"
        case .vergleich: return "⌥⌘V"
        case .einfuehrung: return "⇧⌘T"
        default: return nil
        }
    }
    /// Zusätzliche Suchwörter, damit man den Befehl auch mit eigenen Worten findet.
    var stichworte: String {
        switch self {
        case .neuerVorgang: return "anlegen neu auftrag akte erstellen"
        case .neuerFall: return "anlegen neu akte mandat lexara erstellen"
        case .fristBerechnen: return "frist ablauf berufung zustellung notfrist termin rechner"
        case .kiFragen: return "ki chat frage assistent antwort"
        case .vergleich: return "nebeneinander fenster split vergleich"
        case .ansichtApple, .ansichtNoir, .ansichtAtelier: return "darstellung design hell dunkel ansicht modus farbe"
        case .einfuehrung: return "hilfe tutorial einführung lernen"
        }
    }
    @MainActor
    func ausfuehren() {
        switch self {
        case .neuerVorgang: NotificationCenter.default.post(name: .neuerVorgang, object: nil)
        case .neuerFall: NotificationCenter.default.post(name: .createNewCase, object: nil)
        case .fristBerechnen:
            NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.zeitleiste.rawValue)
        case .kiFragen:
            NotificationCenter.default.post(name: .navigateToSidebar, object: SeitenleistenEintrag.kiChat.rawValue)
        case .vergleich: ModulFensterHost.shared.oeffneVergleich()
        case .ansichtApple: AppearanceStore.shared.setze(.apple)
        case .ansichtNoir: AppearanceStore.shared.setze(.noir)
        case .ansichtAtelier: AppearanceStore.shared.setze(.atelier)
        case .einfuehrung: NotificationCenter.default.post(name: .oeffneTutorial, object: nil)
        }
    }
}

enum KommandoAktion {
    case vorgang(Vorgang)
    case modul(SeitenleistenEintrag)
    case kategorie(NavKategorie)
    case befehl(KommandoBefehl)
}

extension Notification.Name {
    static let oeffneVorgang = Notification.Name("fenlynineos.oeffneVorgang")
    static let oeffneKategorie = Notification.Name("fenlynineos.oeffneKategorie")
}

struct KommandoTreffer: Identifiable {
    let id = UUID()
    let symbol: String
    let farbe: Color
    let titel: String
    let untertitel: String?
    let kategorie: String
    let aktion: KommandoAktion
    var kurzbefehl: String? = nil

    init(symbol: String, farbe: Color, titel: String, untertitel: String?, kategorie: String,
         aktion: KommandoAktion, kurzbefehl: String? = nil) {
        self.symbol = symbol; self.farbe = farbe; self.titel = titel
        self.untertitel = untertitel; self.kategorie = kategorie
        self.aktion = aktion; self.kurzbefehl = kurzbefehl
    }
    /// Treffer, die einen Vorgang öffnen.
    init(symbol: String, farbe: Color, titel: String, untertitel: String?, kategorie: String, vorgang: Vorgang) {
        self.init(symbol: symbol, farbe: farbe, titel: titel, untertitel: untertitel,
                  kategorie: kategorie, aktion: .vorgang(vorgang))
    }
}
enum KommandoParser {
    static func parse(_ query: String, store: VorgangStore, kontext: Vorgang?,
                      istAdmin: Bool = false) -> [KommandoTreffer] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            // Leere Eingabe: die häufigsten Befehle als Startpunkt.
            return [KommandoBefehl.neuerVorgang, .neuerFall, .fristBerechnen, .kiFragen, .vergleich]
                .map(befehlTreffer)
        }
        var ergebnisse: [KommandoTreffer] = []
        let woerter = q.lowercased().split(separator: " ").map(String.init)
        func passt(_ heuhaufen: String) -> Bool {
            let h = heuhaufen.lowercased()
            return woerter.allSatisfy { h.contains($0) }
        }
        // Befehle, Module und Kategorien zuerst: Das ist, was man meistens sucht.
        if !q.hasPrefix("§"), !q.hasPrefix(">"), q != "?" {
            for b in KommandoBefehl.allCases where passt(b.titel + " " + b.stichworte) {
                ergebnisse.append(befehlTreffer(b))
            }
            for k in NavKategorie.allCases where passt(k.titel + " " + k.frage) {
                ergebnisse.append(.init(symbol: k.symbol, farbe: k.farbe, titel: k.titel,
                                        untertitel: k.frage, kategorie: "Bereich", aktion: .kategorie(k)))
            }
            for k in NavKategorie.allCases {
                for e in k.module(istAdmin: istAdmin)
                where passt(e.bezeichnung + " " + (e.commandSubtitle ?? "") + " " + k.titel) {
                    ergebnisse.append(.init(symbol: e.symbol, farbe: e.macSettingsIconColor, titel: e.bezeichnung,
                                            untertitel: k.titel + (e.commandSubtitle.map { " · " + $0 } ?? ""),
                                            kategorie: "Modul", aktion: .modul(e)))
                }
            }
        }
        if q == "?", let k = kontext {
            let ki = k.optionen.flatMap { o in
                [o.chancen.pErfolg, o.chancen.best, o.chancen.worst, o.chancen.likely].filter { $0.herkunft == .ki }
            }
            for wert in ki {
                ergebnisse.append(.init(
                    symbol: "circle",
                    farbe: InterfacePalette.vorgeschlagen,
                    titel: "Unbestätigt: \(InterfaceZahl.dezimal(wert.wert))",
                    untertitel: wert.quelle,
                    kategorie: "Zweifel",
                    vorgang: k
                ))
            }
            return ergebnisse
        }
        if q.hasPrefix("§") {
            for v in store.vorgaenge where v.beschreibung.contains(q) || v.fristen.contains(where: { $0.quelle.contains(q) }) {
                ergebnisse.append(.init(
                    symbol: "book.closed",
                    farbe: InterfacePalette.sekundaer,
                    titel: v.titel,
                    untertitel: "Norm \(q) verknüpft",
                    kategorie: "Norm",
                    vorgang: v
                ))
            }
        }
        if q.hasPrefix(">") {
            let rest = q.dropFirst().trimmingCharacters(in: .whitespaces)
            let (schwelle, _) = extractZahl(rest)
            if let s = schwelle {
                for v in store.vorgaenge where v.volumen >= s {
                    ergebnisse.append(.init(
                        symbol: "chart.line.uptrend.xyaxis",
                        farbe: InterfacePalette.berechnet,
                        titel: v.titel,
                        untertitel: "Volumen: " + InterfaceZahl.waehrung(v.volumen, mitVorzeichen: false),
                        kategorie: "Schwelle",
                        vorgang: v
                    ))
                }
            }
        }
        if q.lowercased().hasPrefix("frist") {
            let rest = q.replacingOccurrences(of: "frist", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            let (tage, _) = extractZahl(rest)
            let limit = Int(tage ?? 30)
            for v in store.vorgaenge {
                let dringlich = v.fristen.filter { $0.tageBisAblauf <= limit && $0.tageBisAblauf >= 0 }
                for f in dringlich {
                    ergebnisse.append(.init(
                        symbol: "calendar",
                        farbe: f.kritisch ? InterfacePalette.kritisch : InterfacePalette.aktion,
                        titel: "\(f.art) · \(f.tageBisAblauf) Tage",
                        untertitel: v.titel,
                        kategorie: "Frist",
                        vorgang: v
                    ))
                }
            }
        }
        for v in store.suche(q) {
            ergebnisse.append(.init(
                symbol: v.typ.linsenSymbol,
                farbe: InterfacePalette.aktion,
                titel: v.titel,
                untertitel: "\(v.typ.moduleName) · \(v.zustand.bezeichnung)",
                kategorie: "Vorgang",
                vorgang: v
            ))
        }
        return ergebnisse
    }
    private static func befehlTreffer(_ b: KommandoBefehl) -> KommandoTreffer {
        .init(symbol: b.symbol, farbe: InterfacePalette.aktion, titel: b.titel, untertitel: nil,
              kategorie: "Befehl", aktion: .befehl(b), kurzbefehl: b.kurzbefehl)
    }
    private static func extractZahl(_ s: String) -> (Double?, String?) {
        var einheit: String?
        var zahltxt = s
        if let range = s.range(of: "mio", options: .caseInsensitive) {
            einheit = "mio"
            zahltxt = String(s[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        // "1.500.000" und "1,5" -- erst Tausenderpunkte weg, dann Komma als Dezimaltrenner.
        // (Vorher wurde das Komma zum Punkt und dann mit entfernt: "1,5 Mio" ergab 15 Mio.)
        let normiert = zahltxt.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let wert = Double(normiert) else { return (nil, einheit) }
        return (einheit == "mio" ? wert * 1_000_000 : wert, einheit)
    }
}
private extension Array {
    subscript(safe idx: Int) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}
