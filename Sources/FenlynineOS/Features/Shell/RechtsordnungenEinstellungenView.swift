import SwiftUI
import AppKit
struct RechtsordnungenEinstellungenView: View {
    @ObservedObject private var manager = RechtsordnungManager.shared
    @ObservedObject private var ordner = RechtsdatenOrdner.shared
    var body: some View {
        Form {
            Section("Aktive Rechtsordnungen") {
                Text("Rechtsradar, KI-Analysen (Lexara · Strategos · Opportunisma), Fristenwissen und Gebührenmodelle arbeiten über alle aktivierten Rechtsordnungen — auf Wunsch rechtsvergleichend.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(Rechtsordnung.allCases) { r in
                    Toggle(isOn: Binding(
                        get: { manager.aktive.contains(r) },
                        set: { _ in manager.umschalten(r) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(r.flagge)  \(r.name)")
                                .font(.system(size: 13, weight: .semibold))
                            Text(r.rechtstradition)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("Instanzen: " + r.gerichtsaufbau.joined(separator: " → "))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("Quellen: " + r.amtlicheQuellen.joined(separator: " · "))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .toggleStyle(.switch)
                }
            }
            Section("Funktions-Union") {
                Text("Werkzeuge, die nur in einer Rechtsordnung existieren, stehen in allen anderen als übertragbare Funktion bereit — mit Herkunftskennzeichnung.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(Array(Rechtsordnung.funktionsUnion.enumerated()), id: \.offset) { _, paket in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(paket.ursprung.flagge)
                            Text(paket.funktion).font(.system(size: 12, weight: .semibold))
                        }
                        Text(paket.beschreibung).font(.caption2).foregroundStyle(.secondary)
                        Text(paket.uebertragbar).font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
            Section("Rechtsdaten-Ordner (dieser Rechner)") {
                LabeledContent("Pfad") {
                    Text(ordner.wurzel.path)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Status") { Text(ordner.status) }
                LabeledContent("Importierte Dateien") { Text("\(ordner.importierteDateien)") }
                if let datum = ordner.letzterImport {
                    LabeledContent("Letzter Import") {
                        Text(datum.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                HStack(spacing: 10) {
                    Button {
                        ordner.importiere()
                    } label: {
                        Label("Jetzt importieren", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        ordner.strukturAnlegen()
                        NSWorkspace.shared.activateFileViewerSelecting([ordner.wurzel])
                    } label: {
                        Label("Ordner öffnen", systemImage: "folder")
                    }
                    Button {
                        ordner.exportiereRadarFunde()
                        NSWorkspace.shared.activateFileViewerSelecting(
                            [ordner.wurzel.appendingPathComponent("Radar-Funde")])
                    } label: {
                        Label("Radar-Funde exportieren", systemImage: "square.and.arrow.up")
                    }
                }
                Text("Rechtstexte (.txt, .md, .json) im Eingang oder in einem Länderordner ablegen — der Radar importiert sie automatisch und ordnet sie der Rechtsordnung zu. KI-Funde werden nach Radar-Funde/ gespiegelt. Keine Mandantendaten ablegen.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}
