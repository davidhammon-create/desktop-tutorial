import SwiftUI
import AppKit

// MARK: - Stripe / Zahlungsservice

/// Ruft createStripeCheckout auf dem Base44-Backend auf und öffnet
/// die Checkout-URL im Standard-Browser (oder in einem In-App-Sheet).
@MainActor
final class PaymentService: ObservableObject {

static let shared = PaymentService()
private init() {}

@Published var isLoading = false
@Published var error: String?
@Published var checkoutURL: URL?

// MARK: - Checkout starten

func checkoutStarten(plan: User.UserPlan, userId: String) async {
  guard plan != .free else { return }
  isLoading = true
  error = nil
  defer { isLoading = false }

  do {
    // Stripe Backend: type = "module" (Abo) oder "ki" (Einzel-KI-Nutzung)
    let result = try await FunctionService.shared.createStripeCheckout(
      type: .module,
      successUrl: "fenlynineos://checkout/success",
      cancelUrl: "fenlynineos://checkout/cancel"
    )
    if FenlynineOSSecurity.isSafeStripeCheckoutURL(result.url),
     let url = URL(string: result.url) {
      checkoutURL = url
      NSWorkspace.shared.open(url)
    } else {
      error = "Checkout-URL aus Sicherheitsgründen blockiert."
    }
  } catch {
    self.error = "Zahlung fehlgeschlagen: \(error.localizedDescription)"
  }
}

// MARK: - Abo-Status prüfen

func aboStatusPruefen(userId: String) async -> Bool {
  do {
    let user = try await Services.users.get(id: userId)
    return user.plan == .professional || user.plan == .enterprise
  } catch {
    return false
  }
}
}

// MARK: - Zahlungsgate (Payment Gate View)

struct ZahlungsGateView: View {
let erforderlichesPlan: User.UserPlan
let feature: String
@ObservedObject private var auth = AuthManager.shared
@StateObject private var payment = PaymentService.shared

var hatZugriff: Bool {
  let aktuell = auth.currentUser?.plan ?? .free
  return planRang(aktuell) >= planRang(erforderlichesPlan)
}

var body: some View {
  if hatZugriff {
    EmptyView()
  } else {
    VStack(spacing: 20) {
      Image(systemName: "lock.shield")
        .font(.system(size: 48))
        .foregroundStyle(.blue)

      Text("\(feature) freischalten")
        .font(.title2.bold())

      Text("Diese Funktion erfordert **\(erforderlichesPlan.rawValue.capitalized)**.\nUpgraden Sie jetzt für vollständigen Zugriff.")
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .font(.system(size: 14))

      VStack(spacing: 10) {
        PlanKarte(plan: .basis, aktuell: auth.currentUser?.plan ?? .free, feature: feature)
        PlanKarte(plan: .professional, aktuell: auth.currentUser?.plan ?? .free, feature: feature)
        PlanKarte(plan: .enterprise, aktuell: auth.currentUser?.plan ?? .free, feature: feature)
      }

      if let fehler = payment.error {
        Label(fehler, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.red)
          .font(.caption)
      }
    }
    .padding(32)
   .frame(maxWidth: 500)
 }
}

private func planRang(_ plan: User.UserPlan) -> Int {
 switch plan {
 case .free: return 0
 case .basis: return 1
 case .professional: return 2
 case .enterprise: return 3
 }
}
}

struct PlanKarte: View {
let plan: User.UserPlan
let aktuell: User.UserPlan
let feature: String
@StateObject private var payment = PaymentService.shared
@ObservedObject private var auth = AuthManager.shared

private var istAktuell: Bool { plan == aktuell }

var body: some View {
 HStack(spacing: 16) {
   VStack(alignment: .leading, spacing: 4) {
     HStack {
       Text(plan.rawValue.capitalized)
         .font(.system(size: 14, weight: .semibold))
       if istAktuell {
         Text("Aktuell")
           .font(.caption2)
           .padding(.horizontal, 6)
           .padding(.vertical, 2)
           .background(Color.green.opacity(0.15), in: Capsule())
           .foregroundStyle(.green)
       }
     }
     Text(planBeschreibung)
       .font(.caption)
       .foregroundStyle(.secondary)
   }

   Spacer()

   Text(planPreis)
     .font(.system(size: 13, weight: .medium))
     .foregroundStyle(.secondary)

   if !istAktuell {
     Button {
       guard let userId = auth.currentUser?.id else { return }
       Task { await payment.checkoutStarten(plan: plan, userId: userId) }
     } label: {
       if payment.isLoading {
         ProgressView().scaleEffect(0.7)
       } else {
         Text("Auswählen")
           .font(.system(size: 12, weight: .medium))
       }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .controlSize(.small)
     .disabled(payment.isLoading)
   }
 }
 .padding(14)
 .background(istAktuell ? Color.blue.opacity(0.05) : Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(
   RoundedRectangle(cornerRadius: 10)
     .stroke(istAktuell ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
 )
}

private var planBeschreibung: String {
 switch plan {
 case .free: return "Bis zu 3 Fälle, Basis-Analyse"
 case .basis: return "Bis zu 20 Fälle, Richterprofile, Monte-Carlo"
 case .professional: return "Unbegrenzte Fälle, Strategos, KI-Chat"
 case .enterprise: return "Alles inkl. Multi-User, API, SLA"
 }
}

private var planPreis: String {
 switch plan {
 case .free: return "Kostenlos"
 case .basis: return "€ 49/Monat"
 case .professional: return "€ 149/Monat"
 case .enterprise: return "Auf Anfrage"
 }
}
}

