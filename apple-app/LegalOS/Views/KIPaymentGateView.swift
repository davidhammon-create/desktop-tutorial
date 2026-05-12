//
//  KIPaymentGateView.swift
//  Gate für KI-Funktionen mit Credit-System. Pendant zu KIPaymentGate.jsx.
//

import SwiftUI

struct KIPaymentGateView<Content: View>: View {
    let kiCredits: Int
    var onCreditUsed: () -> Void
    @ViewBuilder var content: () -> Content
    @EnvironmentObject var auth: AuthService

    @State private var loading = false

    private var language: String { auth.currentUser?.language.uppercased() ?? "DE" }

    private var labels: (title: String, sub: String, price: String, btn: String,
                         use: String, credits: (Int) -> String) {
        switch language {
        case "EN": return ("AI Function",
                           "This AI analysis costs 1 credit per use.",
                           "$1.99 / use",
                           "Buy credit & run",
                           "Use credit",
                           { n in "You have \(n) credit\(n != 1 ? "s" : "")" })
        case "FR": return ("Fonction IA",
                           "Cette analyse IA coûte 1 crédit par utilisation.",
                           "1,99 $ / utilisation",
                           "Acheter un crédit et lancer",
                           "Utiliser un crédit",
                           { n in "Vous avez \(n) crédit\(n != 1 ? "s" : "")" })
        default:   return ("KI-Funktion",
                           "Diese KI-Analyse kostet 1 Credit pro Nutzung.",
                           "1,99 $ / Nutzung",
                           "Credit kaufen & ausführen",
                           "Credit verwenden",
                           { n in "Du hast \(n) Credit\(n != 1 ? "s" : "")" })
        }
    }

    var body: some View {
        if kiCredits > 0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(labels.credits(kiCredits), systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(labels.use) { onCreditUsed() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                content()
            }
        } else {
            GroupBox {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.purple)
                        .padding(12)
                        .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                    Text(labels.title).font(.headline)
                    Text(labels.sub).font(.caption).foregroundStyle(.secondary)
                    Text(labels.price).font(.title3.bold())

                    Button {
                        Task { await openCheckout() }
                    } label: {
                        Text(loading ? "..." : labels.btn)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(loading)
                }
                .padding(16)
                .frame(maxWidth: 360)
            }
        }
    }

    @MainActor
    private func openCheckout() async {
        loading = true
        if let url = URL(string: "https://machiavellex.app/checkout?type=ki") {
            NSWorkspace.shared.open(url)
        }
        loading = false
    }
}
