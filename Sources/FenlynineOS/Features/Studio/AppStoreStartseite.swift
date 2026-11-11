import SwiftUI
import FenlynineOSKern

// MARK: - App-Store-Startseite ("Entdecken")
//
// Die Modulübersicht der Apple-Ansicht, aufgebaut wie die Startseite des
// Mac App Store: großer Seitentitel, große Karten für das Wichtigste des
// Tages, darunter Regale mit Modulen als Zeilen aus Symbol, Titel, Untertitel
// und Knopf.
//
// Die großen Karten sind keine Werbung, sondern der Arbeitsfluss: die
// dringendsten nächsten Schritte über alle Akten. Ein Klick öffnet die Akte
// im passenden Modul.
//
// Diese Ansicht ändert keine Funktion. Jedes Modul wird über denselben Weg
// geöffnet wie bisher; die klassischen Ansichten (Noir, Atelier) bleiben
// unverändert.

struct AppStoreRegal: Identifiable {
    let titel: String
    let eintraege: [SeitenleistenEintrag]
    var id: String { titel }
}

struct AppStoreStartseite: View {
    let regale: [AppStoreRegal]
    let suchtext: String
    let darf: (SeitenleistenEintrag) -> Bool
    let onOeffnen: (SeitenleistenEintrag) -> Void
    let onFenster: (SeitenleistenEintrag) -> Void
    let onSchritt: (Arbeitsschritt) -> Void

    @ObservedObject private var fluss = ArbeitsflussDienst.shared
    @ObservedObject private var pruefung = KIPruefberichtStore.shared
    @State private var zeigePruefberichte = false

    private let spalten = [GridItem(.adaptive(minimum: 320, maximum: 520), spacing: 28, alignment: .top)]

    private var sucht: Bool { !suchtext.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Store.sectionGap) {
                if sucht {
                    suchergebnisse
                } else {
                    StorePageHeader(eyebrow: datumszeile, titel: "Heute")
                    heute
                    if fluss.schritte.count > 2 { alsNaechstes }
                    if !pruefung.berichte.isEmpty { kiPruefung }
                    ForEach(regale) { regal in
                        regalAnsicht(regal)
                    }
                }
            }
            .padding(.horizontal, Store.contentInset)
            .padding(.top, 20)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Store.canvas)
        .task { await fluss.aktualisieren() }
        .sheet(isPresented: $zeigePruefberichte) {
            VStack(spacing: 0) {
                KIPruefberichtListe()
                Divider()
                HStack {
                    Spacer()
                    Button("Fertig") { zeigePruefberichte = false }
                        .keyboardShortcut(.defaultAction)
                }
                .padding(12)
            }
            .frame(width: 480, height: 560)
        }
    }

    // MARK: Heute

    private var datumszeile: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE, d. MMMM"
        return f.string(from: Date())
    }

    @ViewBuilder
    private var heute: some View {
        let oben = Array(fluss.schritte.prefix(2))
        if oben.isEmpty {
            HStack(alignment: .top, spacing: 20) {
                Button { onOeffnen(.vorgaenge) } label: {
                    StoreHeroCard(
                        eyebrow: fluss.laedt ? "Wird geladen" : "Alles erledigt",
                        titel: "Keine dringenden Schritte",
                        text: "In keiner laufenden Akte steht heute etwas Dringendes an. Neue Vorgänge beginnen hier.",
                        gradient: [Color(red: 0.10, green: 0.42, blue: 0.86), Color(red: 0.25, green: 0.20, blue: 0.62)],
                        symbol: "checkmark.seal")
                }
                .buttonStyle(.plain)
                Button { onOeffnen(.kiChat) } label: {
                    StoreHeroCard(
                        eyebrow: "KI-Assistent",
                        titel: "Fragen zur Akte stellen",
                        text: "Jede Antwort wird auf Normzitate, Beträge und zitierte Entscheidungen nachgeprüft.",
                        gradient: [Color(red: 0.36, green: 0.22, blue: 0.70), Color(red: 0.10, green: 0.12, blue: 0.32)],
                        symbol: "bubble.left.and.bubble.right")
                }
                .buttonStyle(.plain)
            }
        } else {
            HStack(alignment: .top, spacing: 20) {
                ForEach(oben) { schritt in
                    Button { onSchritt(schritt) } label: {
                        StoreHeroCard(
                            eyebrow: schritt.dringlichkeit.bezeichnung + " · " + fluss.aktenname(schritt),
                            titel: schritt.titel,
                            text: schritt.grund,
                            gradient: verlauf(schritt.dringlichkeit),
                            symbol: symbol(fuer: schritt.modulId))
                    }
                    .buttonStyle(.plain)
                    .help("Akte im passenden Modul öffnen")
                }
            }
        }
    }

    private var alsNaechstes: some View {
        VStack(alignment: .leading, spacing: 8) {
            StoreSectionHeader(titel: "Als Nächstes")
            LazyVGrid(columns: spalten, alignment: .leading, spacing: 0) {
                ForEach(Array(fluss.schritte.dropFirst(2))) { schritt in
                    VStack(spacing: 0) {
                        StoreAppZeile(
                            symbol: symbol(fuer: schritt.modulId),
                            iconColor: farbe(schritt.dringlichkeit),
                            titel: schritt.titel,
                            untertitel: fluss.aktenname(schritt) + " · " + schritt.dringlichkeit.bezeichnung,
                            pillTitel: "Öffnen",
                            action: { onSchritt(schritt) })
                        .help(schritt.grund)
                        Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 70)
                    }
                }
            }
        }
    }

    // MARK: KI-Prüfung

    private var kiPruefung: some View {
        VStack(alignment: .leading, spacing: 8) {
            StoreSectionHeader(titel: "KI-Prüfung", link: "Alle anzeigen",
                               onLink: { zeigePruefberichte = true })
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(pruefung.berichte.prefix(3))) { bericht in
                    HStack(spacing: 12) {
                        Image(systemName: bericht.stufe.symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(bericht.stufe.farbe)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bericht.modul)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Store.text)
                                .lineLimit(1)
                            Text(bericht.kurztext)
                                .font(Store.caption)
                                .foregroundStyle(Store.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 8)
                        Text(bericht.stufe.bezeichnung)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(bericht.stufe.farbe)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 54)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Store.radiusCard, style: .continuous)
                    .fill(Store.canvasElevated))
        }
    }

    // MARK: Regale

    private func regalAnsicht(_ regal: AppStoreRegal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StoreSectionHeader(titel: regal.titel)
            LazyVGrid(columns: spalten, alignment: .leading, spacing: 0) {
                ForEach(regal.eintraege, id: \.self) { eintrag in
                    modulZeile(eintrag)
                }
            }
        }
    }

    private func modulZeile(_ eintrag: SeitenleistenEintrag) -> some View {
        VStack(spacing: 0) {
            StoreAppZeile(
                symbol: eintrag.symbol,
                iconColor: eintrag.macSettingsIconColor,
                titel: eintrag.bezeichnung,
                untertitel: eintrag.commandSubtitle,
                pillTitel: darf(eintrag) ? "Öffnen" : "Freischalten",
                action: { onOeffnen(eintrag) })
            .contextMenu {
                Button("Öffnen") { onOeffnen(eintrag) }
                Button("Als Fenster öffnen") { onFenster(eintrag) }
            }
            Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 70)
        }
    }

    // MARK: Suche

    private var treffer: [SeitenleistenEintrag] {
        let q = suchtext.trimmingCharacters(in: .whitespaces).lowercased()
        var gesehen = Set<SeitenleistenEintrag>()
        return regale.flatMap(\.eintraege).filter { e in
            guard gesehen.insert(e).inserted else { return false }
            return e.bezeichnung.lowercased().contains(q)
                || (e.commandSubtitle?.lowercased().contains(q) ?? false)
        }
    }

    @ViewBuilder
    private var suchergebnisse: some View {
        let gefunden = treffer
        StorePageHeader(
            titel: "Ergebnisse für „\(suchtext.trimmingCharacters(in: .whitespaces))“",
            untertitel: gefunden.isEmpty ? "Kein Modul gefunden. Mit der Eingabetaste durchsuchen Sie auch Vorgänge."
                                         : "\(gefunden.count) Modul\(gefunden.count == 1 ? "" : "e")")
        LazyVGrid(columns: spalten, alignment: .leading, spacing: 0) {
            ForEach(gefunden, id: \.self) { eintrag in
                modulZeile(eintrag)
            }
        }
    }

    // MARK: Darstellung

    private func verlauf(_ d: Arbeitsschritt.Dringlichkeit) -> [Color] {
        switch d {
        case .kritisch:
            return [Color(red: 0.86, green: 0.18, blue: 0.22), Color(red: 0.45, green: 0.08, blue: 0.20)]
        case .wichtig:
            return [Color(red: 0.95, green: 0.52, blue: 0.12), Color(red: 0.62, green: 0.22, blue: 0.10)]
        case .empfohlen:
            return [Color(red: 0.10, green: 0.42, blue: 0.86), Color(red: 0.25, green: 0.20, blue: 0.62)]
        }
    }

    private func farbe(_ d: Arbeitsschritt.Dringlichkeit) -> Color {
        switch d {
        case .kritisch: return Color(red: 0.92, green: 0.22, blue: 0.24)
        case .wichtig: return Color(red: 0.98, green: 0.58, blue: 0.14)
        case .empfohlen: return Store.accent
        }
    }

    private func symbol(fuer modulId: String) -> String {
        SeitenleistenEintrag(rawValue: modulId)?.symbol ?? "square.grid.2x2"
    }
}
