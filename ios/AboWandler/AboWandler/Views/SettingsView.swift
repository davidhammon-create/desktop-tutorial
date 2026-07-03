import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Dein Name", text: $store.userName)
                        .onSubmit { store.save() }
                }

                Section {
                    Toggle(isOn: $store.aiEnabled.animation()) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KI-Funktionen (Apple Intelligence)")
                            Text("Läuft komplett on-device — kostenlos, ohne API-Schlüssel, deine Daten verlassen das Gerät nicht.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: store.aiEnabled) { store.save() }
                    Text(AppleAI.availabilityText)
                        .font(.caption)
                        .foregroundStyle(AppleAI.isAvailable ? .green : .secondary)
                } header: {
                    Text("KI")
                } footer: {
                    Text("Standardmäßig arbeitet AboWandler rein algorithmisch. Mit KI zusätzlich: Seriositäts-Einschätzungen, Kündigungsschreiben und Anlage-Einordnungen. Das On-Device-Modell hat keinen Internetzugang — für Live-Web-Recherche nutze die Web-App mit Anthropic-Key.")
                }

                Section("Daten") {
                    ShareLink(item: exportJSON(), preview: SharePreview("AboWandler-Export")) {
                        Label("Meine Daten als JSON exportieren", systemImage: "square.and.arrow.up")
                    }
                    Button("Demo-Daten neu laden", role: .destructive) { showResetConfirm = true }
                }

                Section {
                    Text("Alle Daten liegen ausschließlich lokal auf diesem Gerät. Kein Server, keine Cloud, keine Registrierung.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
            .confirmationDialog("Wirklich alle Daten löschen und Demo-Daten laden?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Zurücksetzen", role: .destructive) { store.resetToDemo() }
            }
        }
    }

    private func exportJSON() -> String {
        struct Export: Codable {
            let name: String
            let konten: [Account]
            let umsaetze: [Txn]
            let abos: [Subscription]
        }
        let export = Export(name: store.userName, konten: store.accounts, umsaetze: store.transactions, abos: store.subscriptions)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(export), let text = String(data: data, encoding: .utf8) {
            return text
        }
        return "{}"
    }
}
