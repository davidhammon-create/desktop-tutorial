//
//  StripeService.swift
//  Öffnet Stripe-Checkout-URLs im System-Browser.
//  Ersetzt base44/functions/stripeCheckout + stripeWebhook
//  (Webhook nicht nötig: Status wird beim App-Start gegen Stripe-API geprüft).
//

import Foundation
import AppKit

@MainActor
public enum StripeService {

    /// Stripe-Pricing-Tabellen-URL aus Settings (Platzhalter).
    public static let publicCheckoutURL = "https://buy.stripe.com/test_legalos_pro"

    public enum Plan: String { case basic, pro, enterprise }

    public static func openCheckout(plan: Plan, userEmail: String) {
        var url = publicCheckoutURL + "?plan=\(plan.rawValue)"
        if let enc = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url += "&prefilled_email=\(enc)"
        }
        if let u = URL(string: url) { NSWorkspace.shared.open(u) }
    }

    /// Direkter Status-Check (Stub – produktiv via Stripe Customer API).
    public static func hasActiveSubscription(userEmail: String) async -> Bool {
        false
    }
}
