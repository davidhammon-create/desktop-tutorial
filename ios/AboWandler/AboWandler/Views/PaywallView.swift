import SwiftUI

/// Abo-/Zahlungsmodell der App — App-Store-artige Plan-Karten.
/// Free: nur Algorithmus. Pro: schaltet KI frei; KI-Nutzung wird zusätzlich
/// pro Aktion abgerechnet. Ohne verknüpftes Stripe-Konto sind alle
/// kostenpflichtigen Services gesperrt.
struct PaywallView: View {
    @EnvironmentObject var store: AppStore
    @State private var message: String?
    @State private var linking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Wähle deinen Plan")
                    .font(.largeTitle.bold())
                    .padding(.top)
                Text("Transparent: KI kostet — und jede Nutzung wird deinem Profil zugewiesen.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                planCard(
                    title: "Free",
                    price: "0 €",
                    tint: .gray,
                    features: [
                        "Algorithmus-Scan (unbegrenzt, kostenlos)",
                        "Konten, Import, Abo-Verwaltung",
                        "Kündigungs-Links & Sparplan-Checkliste",
                        "Invest-Rechner & Finanz-Radar",
                    ],
                    isCurrent: store.currentProfile?.plan == .free,
                    action: { store.cancelPro(); message = "Free-Plan aktiv." },
                    actionLabel: "Zu Free wechseln"
                )

                planCard(
                    title: "Pro",
                    price: "\(Pricing.proMonthly.euro)/Monat",
                    tint: .blue,
                    features: [
                        "Alles aus Free",
                        "KI-Scan der Umsätze (+\(Pricing.kiScan.euro)/Scan)",
                        "KI-Seriositäts-Check (+\(Pricing.kiAssessment.euro)/Abo)",
                        "KI-Kündigungsschreiben (+\(Pricing.kiLetter.euro))",
                        "KI-Anlage-Einordnung (+\(Pricing.kiInvest.euro))",
                    ],
                    isCurrent: store.currentProfile?.plan == .pro,
                    action: activatePro,
                    actionLabel: "Pro aktivieren"
                )

                stripeSection

                if let message {
                    Text(message).font(.callout).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("KI-Aktionen laufen on-device über Apple Intelligence; die genannten Preise sind das Nutzungs-Modell dieser App und werden dem Profil-Ledger zugewiesen und über Stripe abgerechnet. Hinweis: Für eine Veröffentlichung im App Store verlangt Apple für digitale Leistungen In-App-Purchases.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Abo & Plan")
    }

    private var stripeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Stripe-Konto", systemImage: "creditcard")
                .font(.headline)
            if store.stripeSecretKey.isEmpty {
                Text("Stripe ist noch nicht eingerichtet. Admin: Einstellungen → Stripe-Schlüssel eintragen (sk_test_… zum Testen).")
                    .font(.callout).foregroundStyle(.secondary)
            } else if store.currentProfile?.hasStripe == true {
                Label("Verknüpft: \(store.currentProfile?.stripeCustomerId ?? "")", systemImage: "checkmark.circle.fill")
                    .font(.callout).foregroundStyle(.green)
            } else {
                Text("Dieses Profil ist noch nicht mit Stripe verknüpft — kostenpflichtige Services sind gesperrt.")
                    .font(.callout).foregroundStyle(.orange)
                Button(linking ? "Verknüpft…" : "Stripe-Kundenkonto für dieses Profil anlegen") {
                    linkStripe()
                }
                .buttonStyle(.borderedProminent)
                .disabled(linking)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    private func planCard(title: String, price: String, tint: Color, features: [String], isCurrent: Bool, action: @escaping () -> Void, actionLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.title2.bold())
                Spacer()
                Text(price).font(.headline).foregroundStyle(tint)
            }
            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            if isCurrent {
                Label("Aktueller Plan", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            } else {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isCurrent ? tint : .clear, lineWidth: 2))
    }

    private func activatePro() {
        if store.activatePro() {
            message = "✓ Pro aktiv — \(Pricing.proMonthly.euro)/Monat, deinem Profil-Ledger zugewiesen."
        } else {
            message = "Pro braucht ein verknüpftes Stripe-Konto. " + store.paidServicesHint
        }
    }

    private func linkStripe() {
        guard let profile = store.currentProfile else { return }
        linking = true
        Task {
            do {
                let customerId = try await StripeService.createCustomer(name: profile.name, secretKey: store.stripeSecretKey)
                store.mutateProfile { $0.stripeCustomerId = customerId }
                message = "✓ Stripe-Kundenkonto angelegt (\(customerId))."
            } catch {
                message = error.localizedDescription
            }
            linking = false
        }
    }
}
