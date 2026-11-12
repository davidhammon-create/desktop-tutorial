import SwiftUI
import AppKit
struct RechtswissenPanel: View {
    @Bindable private var store = RechtswissenStore.shared
    @Bindable private var radar = RechtsradarAgent.shared
    @ObservedObject private var rechtsordnungen = RechtsordnungManager.shared
    @ObservedObject private var ordner = RechtsdatenOrdner.shared
    @State private var suche = ""
    @State private var auswahl: RechtswissenEintrag?
    @State private var landFilter: Rechtsordnung?
    private var liste: [RechtswissenEintrag] {
        var pool = suche.isEmpty ? store.eintraege : store.suche(suche)
        if let land = landFilter {
            pool = pool.filter { $0.rechtsordnung == land.rawValue }
        }
        return pool
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    TextField("Normen · Stichworte …", text: $suche)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
                    Button(radar.laeuft ? "Pausieren" : "Radar") {
                        if radar.laeuft { radar.stoppen() } else { radar.starten() }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Premium.action)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Premium.action.opacity(0.1)))
                    Button("Export") {
                        NSWorkspace.shared.activateFileViewerSelecting([store.exportPfad])
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Premium.textSoft)
                }
                .padding(12)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Rechtsordnung.allCases) { r in
                            let aktiv = rechtsordnungen.aktive.contains(r)
                            Button {
                                if aktiv {
                                    landFilter = landFilter == r ? nil : r
                                } else {
                                    rechtsordnungen.umschalten(r)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(r.flagge)
                                    Text(r.name).font(.system(size: 10, weight: .semibold))
                                    if aktiv {
                                        Image(systemName: landFilter == r ? "line.3.horizontal.decrease.circle.fill" : "checkmark.circle.fill")
                                            .font(.system(size: 9))
                                    }
                                }
                                .foregroundStyle(aktiv ? Premium.action : Premium.textFaint)
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 7)
                                    .fill(aktiv ? Premium.action.opacity(0.12) : Premium.well))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(aktiv ? "Rechtsordnung deaktivieren" : "Rechtsordnung aktivieren") {
                                    rechtsordnungen.umschalten(r)
                                    if landFilter == r { landFilter = nil }
                                }
                            }
                            .help(aktiv ? "Klick: nur \(r.name) anzeigen · Rechtsklick: deaktivieren" : "Klick: \(r.name) für Radar & KI aktivieren")
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.bottom, 6)
                HStack(spacing: 8) {
                    Text(store.agentStatus)
                        .font(.system(size: 10))
                        .foregroundStyle(Premium.textFaint)
                    Spacer()
                    Button {
                        RechtsdatenOrdner.shared.importiere()
                        NSWorkspace.shared.activateFileViewerSelecting([ordner.wurzel])
                    } label: {
                        Label("Rechtsdaten-Ordner", systemImage: "folder.badge.gearshape")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Premium.action)
                    .help("Öffnet ~/Documents/FenlynineOS-Rechtsdaten — dort abgelegte Rechtstexte importiert der Radar automatisch. Status: \(ordner.status)")
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
                Divider().overlay(Premium.hairline)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(liste) { e in
                            Button {
                                auswahl = e
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        if let ro = e.rechtsordnungWert {
                                            Text(ro.flagge).font(.system(size: 11))
                                        }
                                        Text(e.titel)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Premium.text)
                                            .lineLimit(1)
                                        Spacer()
                                        if let n = e.norm {
                                            Text(n)
                                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                .foregroundStyle(Premium.action)
                                        }
                                    }
                                    Text(e.zusammenfassung)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Premium.textSoft)
                                        .lineLimit(2)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(auswahl?.id == e.id ? Premium.action.opacity(0.08) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(Premium.hairline)
                        }
                    }
                }
            }
            .frame(minWidth: 320)
            Rectangle().fill(Premium.hairline).frame(width: 1)
            Group {
                if let e = auswahl {
                    ScrollView {
                        KIEntscheidungsKarte(
                            titel: e.titel,
                            badge: e.confidence >= 0.85 ? .bestaetigt : (e.herkunftModell != nil ? .geschaetzt : .quelle),
                            abschnitte: [
                                .init(titel: "Kern", zeilen: [
                                    ("Rechtsordnung", e.rechtsordnungWert.map { "\($0.flagge) \($0.name)" } ?? "Allgemein / übergreifend", nil),
                                    ("Norm", e.norm ?? "—", .quelle),
                                    ("Gebiet", e.rechtsgebiet ?? "—", nil),
                                    ("Quelle", e.quelle, .quelle),
                                    ("Konfidenz", "\(Int(e.confidence * 100)) %", e.confidence >= 0.85 ? .bestaetigt : .geschaetzt)
                                ]),
                                .init(titel: "Inhalt", untertitel: e.zusammenfassung, zeilen: [
                                    ("Tags", e.tags.joined(separator: ", "), nil),
                                    ("Modell-Metadaten", e.herkunftModell ?? "modellfrei", .bestaetigt)
                                ])
                            ],
                            hinweis: "Gespeichert unter Application Support/FenlynineOS/Rechtswissen — bleibt bei Wechsel auf Apple Intelligence erhalten."
                        )
                        .padding(16)
                    }
                    .background(Premium.void)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 28))
                            .foregroundStyle(Premium.textFaint)
                        Text("Rechtswissen")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Premium.text)
                        Text("Der Radar sammelt Normen und Fristen lokal.\nBei KI-Modellwechsel bleibt alles erhalten.")
                            .font(.system(size: 12))
                            .foregroundStyle(Premium.textSoft)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Premium.void)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(Premium.panel)
    }
}
