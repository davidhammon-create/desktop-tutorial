import SwiftUI

// MARK: - Seitenleiste im Stil der Systemeinstellungen
//
// Bereiche als Überschrift, darunter Kategorien mit farbigem Symbolquadrat.
// Jede Kategorie lässt sich aufklappen und zeigt dann ihre Module als
// Unterpunkte -- ein Klick auf die Kategorie selbst öffnet ihre Übersichtsseite
// mit Ablauf und allen Funktionen. Alle Module sind damit in höchstens zwei
// Klicks erreichbar, ohne dass die Leiste mit 30 Einträgen überläuft.

enum AppleZiel: Hashable {
    case heute
    case kategorie(NavKategorie)
    case modul(SeitenleistenEintrag)
    case wissen
}

struct AppleSymbolQuadrat: View {
    let symbol: String
    let farbe: Color
    var groesse: CGFloat = 22
    var body: some View {
        RoundedRectangle(cornerRadius: groesse * 0.26, style: .continuous)
            .fill(LinearGradient(colors: [farbe, farbe.opacity(0.82)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: groesse, height: groesse)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: groesse * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}

struct AppleSeitenleiste: View {
    let auswahl: AppleZiel
    @Binding var suchtext: String
    let istAdmin: Bool
    /// Zahl der dringenden Schritte je Kategorie (aus dem Arbeitsfluss).
    let hinweise: (NavKategorie) -> Int
    let dringendGesamt: Int
    let profilName: String
    let profilInitialen: String
    let onWaehle: (AppleZiel) -> Void
    let onSuche: () -> Void
    let onHilfe: () -> Void

    @AppStorage("fenlynineos_seitenleiste_aufgeklappt") private var aufgeklapptRoh = "akten,fristen"

    private var aufgeklappt: Set<String> {
        Set(aufgeklapptRoh.split(separator: ",").map(String.init))
    }

    private func umschalten(_ k: NavKategorie) {
        var s = aufgeklappt
        if s.contains(k.rawValue) { s.remove(k.rawValue) } else { s.insert(k.rawValue) }
        aufgeklapptRoh = s.sorted().joined(separator: ",")
    }

    private var suche: String { suchtext.trimmingCharacters(in: .whitespaces).lowercased() }

    private func treffer(_ k: NavKategorie) -> [SeitenleistenEintrag] {
        let alle = k.module(istAdmin: istAdmin)
        guard !suche.isEmpty else { return alle }
        if k.titel.lowercased().contains(suche) { return alle }
        return alle.filter {
            $0.bezeichnung.lowercased().contains(suche)
                || ($0.commandSubtitle?.lowercased().contains(suche) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StoreSearchField(text: $suchtext, placeholder: "Suchen")
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .onSubmit(onSuche)
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    if suche.isEmpty {
                        zeile(symbol: "house.fill", farbe: Store.accent, titel: "Heute",
                              badge: dringendGesamt, ausgewaehlt: auswahl == .heute) { onWaehle(.heute) }
                    }
                    ForEach(NavBereich.allCases) { bereich in
                        let kategorien = bereich.kategorien.filter { !treffer($0).isEmpty }
                        if !kategorien.isEmpty {
                            Text(bereich.titel)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Store.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.top, 14)
                                .padding(.bottom, 4)
                            ForEach(kategorien) { k in
                                kategorieBlock(k)
                                if k == .ki, suche.isEmpty || "rechtswissen".contains(suche) {
                                    zeile(symbol: "books.vertical.fill",
                                          farbe: Color(red: 0.62, green: 0.42, blue: 0.24),
                                          titel: "Rechtswissen", ausgewaehlt: auswahl == .wissen) {
                                        onWaehle(.wissen)
                                    }
                                }
                            }
                        }
                    }
                    if suche.isEmpty {
                        zeile(symbol: "questionmark", farbe: Color(white: 0.45), titel: "Hilfe & Einführung",
                              ausgewaehlt: false, action: onHilfe)
                            .padding(.top, 14)
                    } else if NavKategorie.allCases.allSatisfy({ treffer($0).isEmpty }) {
                        Text("Kein Modul gefunden.\nEingabetaste durchsucht auch Vorgänge.")
                            .font(Store.caption)
                            .foregroundStyle(Store.textTertiary)
                            .padding(12)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
            Divider().overlay(Color.white.opacity(0.08))
            StoreProfilFuss(initials: profilInitialen, name: profilName)
        }
        .frame(width: Store.sidebarWidth + 28)
        .storeSidebarMaterial()
        .overlay(alignment: .trailing) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1)
        }
    }

    @ViewBuilder
    private func kategorieBlock(_ k: NavKategorie) -> some View {
        let offen = !suche.isEmpty || aufgeklappt.contains(k.rawValue) || modulAusgewaehlt(in: k)
        let module = treffer(k)
        HStack(spacing: 0) {
            zeile(symbol: k.symbol, farbe: k.farbe, titel: k.titel, badge: hinweise(k),
                  ausgewaehlt: auswahl == .kategorie(k)) { onWaehle(.kategorie(k)) }
            Button { withAnimation(.easeOut(duration: 0.15)) { umschalten(k) } } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Store.textTertiary)
                    .rotationEffect(.degrees(offen ? 90 : 0))
                    .frame(width: 22, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(offen ? "Unterpunkte ausblenden" : "Unterpunkte zeigen")
            .disabled(!suche.isEmpty)
        }
        if offen {
            ForEach(module, id: \.self) { m in
                unterzeile(m)
            }
        }
    }

    private func modulAusgewaehlt(in k: NavKategorie) -> Bool {
        if case let .modul(m) = auswahl { return m.navKategorie == k }
        return false
    }

    private func zeile(symbol: String, farbe: Color, titel: String, badge: Int = 0,
                       ausgewaehlt: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                AppleSymbolQuadrat(symbol: symbol, farbe: farbe)
                Text(titel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ausgewaehlt ? .white : Store.text)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.red))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(ausgewaehlt ? Store.accent : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func unterzeile(_ m: SeitenleistenEintrag) -> some View {
        let ausgewaehlt = auswahl == .modul(m)
        return Button { onWaehle(.modul(m)) } label: {
            HStack(spacing: 8) {
                Image(systemName: m.symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ausgewaehlt ? .white : m.macSettingsIconColor)
                    .frame(width: 16)
                Text(m.bezeichnung)
                    .font(.system(size: 12.5))
                    .foregroundStyle(ausgewaehlt ? .white : Store.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.leading, 34)
            .padding(.trailing, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(ausgewaehlt ? Store.accent : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(m.commandSubtitle ?? m.bezeichnung)
    }
}

// MARK: - Kategorie-Seite

/// Übersichtsseite einer Kategorie: wofür sie da ist, wie man vorgeht, und
/// alle Funktionen als gruppierte Liste -- wie eine Seite der Systemeinstellungen.
struct KategorieSeite: View {
    let kategorie: NavKategorie
    let istAdmin: Bool
    let darf: (SeitenleistenEintrag) -> Bool
    let onOeffnen: (SeitenleistenEintrag) -> Void
    let onFenster: (SeitenleistenEintrag) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 16) {
                    AppleSymbolQuadrat(symbol: kategorie.symbol, farbe: kategorie.farbe, groesse: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kategorie.bereich.titel.uppercased())
                            .font(Store.eyebrow)
                            .tracking(0.6)
                            .foregroundStyle(Store.textTertiary)
                        Text(kategorie.titel)
                            .font(Store.titleLarge)
                            .foregroundStyle(Store.text)
                        Text(kategorie.frage)
                            .font(Store.body)
                            .foregroundStyle(Store.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("So gehen Sie vor")
                        .font(Store.titleSection)
                        .foregroundStyle(Store.text)
                    gruppe {
                        ForEach(Array(kategorie.ablauf.enumerated()), id: \.element.id) { i, schritt in
                            if i > 0 { trenner }
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(i + 1)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(kategorie.farbe))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(schritt.titel)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Store.text)
                                    Text(schritt.text)
                                        .font(Store.caption)
                                        .foregroundStyle(Store.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(schritt.modul.bezeichnung)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Store.textTertiary)
                                }
                                Spacer(minLength: 8)
                                StorePillButton(titel: darf(schritt.modul) ? "Öffnen" : "Freischalten") {
                                    onOeffnen(schritt.modul)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Alle Funktionen")
                        .font(Store.titleSection)
                        .foregroundStyle(Store.text)
                    gruppe {
                        let module = kategorie.module(istAdmin: istAdmin)
                        ForEach(Array(module.enumerated()), id: \.element) { i, m in
                            if i > 0 { trenner }
                            HStack(spacing: 12) {
                                AppleSymbolQuadrat(symbol: m.symbol, farbe: m.macSettingsIconColor, groesse: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(m.bezeichnung)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Store.text)
                                    if let sub = m.commandSubtitle {
                                        Text(sub)
                                            .font(Store.caption)
                                            .foregroundStyle(Store.textSecondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer(minLength: 8)
                                Button { onFenster(m) } label: {
                                    Image(systemName: "macwindow")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Store.accent)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Store.pillFill))
                                }
                                .buttonStyle(.plain)
                                .help("In eigenem Fenster öffnen")
                                StorePillButton(titel: darf(m) ? "Öffnen" : "Freischalten") { onOeffnen(m) }
                            }
                            .padding(.vertical, 9)
                            .padding(.horizontal, 14)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) { onOeffnen(m) }
                        }
                    }
                }
            }
            .padding(.horizontal, Store.contentInset)
            .padding(.vertical, 24)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Store.canvas)
    }

    private var trenner: some View {
        Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 50)
    }

    private func gruppe<Inhalt: View>(@ViewBuilder _ inhalt: () -> Inhalt) -> some View {
        VStack(alignment: .leading, spacing: 0, content: inhalt)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Store.canvasElevated))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
