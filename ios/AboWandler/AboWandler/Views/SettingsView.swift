import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showResetConfirm = false
    @State private var stripeKeyInput = ""

    var body: some View {
        NavigationStack {
            Form {
                if let profile = store.currentProfile {
                    Section("Profil") {
                        TextField("Name", text: Binding(
                            get: { profile.name },
                            set: { newValue in store.mutateProfile { $0.name = newValue } }
                        ))
                        Button("Profil wechseln") { store.selectProfile(nil) }
                        if store.profiles.count > 1 && !profile.isAdmin {
                            Button("Dieses Profil löschen", role: .destructive) {
                                store.deleteProfile(profile.id)
                            }
                        }
                    }

                    Section {
                        NavigationLink {
                            PaywallView()
                        } label: {
                            LabeledContent("Plan") {
                                Text(profile.plan.label + " · " + profile.plan.priceLabel)
                                    .foregroundStyle(profile.plan == .pro ? .blue : .secondary)
                            }
                        }
                        NavigationLink {
                            UsageView()
                        } label: {
                            LabeledContent("Nutzung & Kosten") {
                                Text(profile.openUsageTotal > 0 ? "offen: \(profile.openUsageTotal.euro)" : "0 € offen")
                                    .foregroundStyle(profile.openUsageTotal > 0 ? .orange : .secondary)
                            }
                        }
                        LabeledContent("Stripe") {
                            Text(profile.hasStripe ? "verknüpft" : "nicht verknüpft")
                                .foregroundStyle(profile.hasStripe ? .green : .orange)
                        }
                    } header: {
                        Text("Abo & Abrechnung")
                    } footer: {
                        Text("Kostenpflichtige Services (alle KI-Funktionen) sind ohne verknüpftes Stripe-Konto gesperrt. Jede KI-Aktion wird diesem Profil zugewiesen.")
                    }

                    Section {
                        Toggle(isOn: Binding(
                            get: { profile.aiEnabled },
                            set: { newValue in store.mutateProfile { $0.aiEnabled = newValue } }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("KI-Funktionen anzeigen")
                                Text("Apple Intelligence, on-device — Preise laut Plan-Seite.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Picker("Scan-Methode", selection: Binding(
                            get: { profile.scanMethod },
                            set: { newValue in store.mutateProfile { $0.scanMethod = newValue } }
                        )) {
                            ForEach(ScanMethod.allCases, id: \.self) { method in
                                Text(method.label).tag(method)
                            }
                        }
                        Text(AppleAI.availabilityText)
                            .font(.caption)
                            .foregroundStyle(AppleAI.isAvailable ? .green : .secondary)
                    } header: {
                        Text("KI")
                    } footer: {
                        Text("Standard ist der kostenlose Algorithmus. Der KI-Scan kostet \(Pricing.kiScan.euro) pro Durchlauf und wird deinem Ledger zugewiesen.")
                    }

                    if profile.isAdmin {
                        Section {
                            SecureField("sk_test_… (Stripe Secret Key)", text: $stripeKeyInput)
                            Button("Stripe-Schlüssel speichern") {
                                store.stripeSecretKey = stripeKeyInput.trimmingCharacters(in: .whitespaces)
                                store.save()
                                stripeKeyInput = ""
                            }
                            .disabled(stripeKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                            LabeledContent("Status") {
                                Text(store.stripeSecretKey.isEmpty ? "kein Schlüssel" : "hinterlegt (\(String(store.stripeSecretKey.prefix(8)))…)")
                                    .foregroundStyle(store.stripeSecretKey.isEmpty ? .orange : .green)
                            }
                            if !store.stripeSecretKey.isEmpty {
                                Button("Schlüssel entfernen", role: .destructive) {
                                    store.stripeSecretKey = ""
                                    store.save()
                                }
                            }
                        } header: {
                            Text("Stripe (Admin)")
                        } footer: {
                            Text("Nur lokal gespeichert. Zum Testen einen sk_test_-Schlüssel aus dem Stripe-Dashboard verwenden — dann entstehen keine echten Abbuchungen.")
                        }
                    }

                    Section("Daten") {
                        ShareLink(item: exportJSON(), preview: SharePreview("AboWandler-Export")) {
                            Label("Meine Daten als JSON exportieren", systemImage: "square.and.arrow.up")
                        }
                        Button("Demo-Daten neu laden", role: .destructive) { showResetConfirm = true }
                    }

                    Section {
                        Text("Frontend und Backend dieser App sind vollständig in Swift. Alle Daten liegen lokal auf diesem Gerät; nur Stripe-Abrechnungen gehen an api.stripe.com.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .confirmationDialog("Wirklich die Daten dieses Profils löschen und Demo-Daten laden?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Zurücksetzen", role: .destructive) { store.resetToDemo() }
            }
        }
    }

    private func exportJSON() -> String {
        struct Export: Codable {
            let profil: String
            let konten: [Account]
            let umsaetze: [Txn]
            let abos: [Subscription]
            let nutzung: [UsageEntry]
        }
        let export = Export(
            profil: store.currentProfile?.name ?? "",
            konten: store.accounts,
            umsaetze: store.transactions,
            abos: store.subscriptions,
            nutzung: store.currentProfile?.usage ?? []
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(export), let text = String(data: data, encoding: .utf8) {
            return text
        }
        return "{}"
    }
}
