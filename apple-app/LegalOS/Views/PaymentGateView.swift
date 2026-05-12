//
//  PaymentGateView.swift
//  Gate-Komponente für Premium-Module. Pendant zu PaymentGate.jsx.
//  Stripe-Checkout entfällt auf macOS – wir verweisen auf die Web-App.
//

import SwiftUI

struct PaymentGateView<Content: View>: View {
    let hasAccess: Bool
    @ViewBuilder var content: () -> Content
    @EnvironmentObject var auth: AuthService

    @State private var loading = false

    private var language: String { auth.currentUser?.language.uppercased() ?? "DE" }

    private var labels: (title: String, sub: String, price: String, btn: String, back: String, note: String) {
        switch language {
        case "EN": return ("Premium Module",
                           "This section requires an active subscription.",
                           "$29/month",
                           "Unlock now",
                           "Back to overview",
                           "Secure checkout via Stripe. Cancel anytime.")
        case "FR": return ("Module Premium",
                           "Cette section nécessite un abonnement actif.",
                           "29 $/mois",
                           "Débloquer maintenant",
                           "Retour à l'aperçu",
                           "Paiement sécurisé via Stripe. Résiliation possible à tout moment.")
        default:   return ("Premium-Modul",
                           "Dieser Bereich erfordert ein aktives Abonnement.",
                           "29 $/Monat",
                           "Jetzt freischalten",
                           "Zurück zur Übersicht",
                           "Sicherer Checkout via Stripe. Kündigung jederzeit möglich.")
        }
    }

    var body: some View {
        if hasAccess {
            content()
        } else {
            VStack {
                Spacer()
                GroupBox {
                    VStack(spacing: 18) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.accentColor)
                            .padding(20)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))

                        Text(labels.title)
                            .font(.title2.bold())
                        Text(labels.sub)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                            Text(labels.price).font(.title.bold())
                        }
                        Text(labels.note)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Button {
                            Task { await openCheckout() }
                        } label: {
                            Text(loading ? "..." : labels.btn)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(loading)
                    }
                    .padding(20)
                    .frame(maxWidth: 360)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
        }
    }

    @MainActor
    private func openCheckout() async {
        loading = true
        // Auf macOS: Stripe-Checkout-Seite im Browser öffnen.
        if let url = URL(string: "https://machiavellex.app/checkout?type=module") {
            NSWorkspace.shared.open(url)
        }
        loading = false
    }
}
