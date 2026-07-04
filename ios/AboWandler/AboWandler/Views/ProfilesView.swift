import SwiftUI

/// Profil-Auswahl beim Start — jedes Profil hat eigene Daten, eigenen Plan
/// und ein eigenes Kosten-Ledger (Stripe-Zuordnung pro Account).
struct ProfilePickerView: View {
    @EnvironmentObject var store: AppStore
    @State private var newName = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Wer nutzt AboWandler?")
                .font(.largeTitle.bold())
            Text("Jedes Profil hat eigene Konten, Abos und eine eigene Kosten-Abrechnung.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(store.profiles) { profile in
                    Button {
                        store.selectProfile(profile.id)
                    } label: {
                        HStack(spacing: 14) {
                            Text(String(profile.name.prefix(1)).uppercased())
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(profile.isAdmin ? Color.blue : Color.gray, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name).font(.headline).foregroundStyle(.primary)
                                HStack(spacing: 6) {
                                    Text(profile.plan.label)
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(profile.plan == .pro ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15), in: Capsule())
                                    if profile.isAdmin {
                                        Text("Admin").font(.caption2.weight(.bold))
                                            .padding(.horizontal, 8).padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.15), in: Capsule())
                                    }
                                    if profile.openUsageTotal > 0 {
                                        Text("offen: \(profile.openUsageTotal.euro)")
                                            .font(.caption2).foregroundStyle(.orange)
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    TextField("Name des neuen Profils", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    Button("Anlegen") {
                        let name = newName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        store.addProfile(name: name)
                        newName = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: 440)
            Spacer()
            Spacer()
        }
        .padding()
    }
}

/// Nutzungs-Ledger: jede kostenpflichtige Aktion, dem Profil zugewiesen.
struct UsageView: View {
    @EnvironmentObject var store: AppStore
    @State private var billingMessage: String?
    @State private var billing = false

    var body: some View {
        List {
            if let profile = store.currentProfile {
                Section {
                    LabeledContent("Offener Betrag") {
                        Text(profile.openUsageTotal.euro).fontWeight(.bold).foregroundStyle(profile.openUsageTotal > 0 ? .orange : .green)
                    }
                    LabeledContent("Gesamt (inkl. abgerechnet)", value: profile.usageTotal.euro)
                    Button(billing ? "Erstellt Stripe-Rechnung…" : "Jetzt über Stripe abrechnen") {
                        settle(profile: profile)
                    }
                    .disabled(billing || profile.openUsageTotal <= 0 || !store.canUsePaidServices)
                    if let billingMessage {
                        Text(billingMessage).font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Abrechnung — \(profile.name)")
                } footer: {
                    Text("Kosten entstehen nur bei KI-Nutzung und werden diesem Profil zugewiesen. Abgerechnet wird über das verknüpfte Stripe-Konto.")
                }

                Section("Einzelposten (\(profile.usage.count))") {
                    if profile.usage.isEmpty {
                        Text("Noch keine kostenpflichtige Nutzung.").foregroundStyle(.secondary)
                    }
                    ForEach(profile.usage.sorted(by: { $0.date > $1.date })) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.action).font(.subheadline)
                                Text(entry.date, style: .date).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(entry.cost.euro).font(.subheadline.weight(.semibold))
                                Text(entry.billed ? "abgerechnet" : "offen")
                                    .font(.caption2)
                                    .foregroundStyle(entry.billed ? .green : .orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Nutzung & Kosten")
    }

    private func settle(profile: Profile) {
        billing = true
        Task {
            do {
                let invoiceId = try await StripeService.billUsage(
                    customerId: profile.stripeCustomerId ?? "",
                    amountEuro: profile.openUsageTotal,
                    description: "AboWandler KI-Nutzung — Profil \(profile.name)",
                    secretKey: store.stripeSecretKey
                )
                store.markUsageBilled()
                billingMessage = "✓ Stripe-Rechnung erstellt (\(invoiceId))."
            } catch {
                billingMessage = error.localizedDescription
            }
            billing = false
        }
    }
}
