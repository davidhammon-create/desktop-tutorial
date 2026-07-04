import Foundation

/// Schlanker Stripe-REST-Client in reinem Swift (URLSession) — kein SDK nötig.
/// Verwende einen TEST-Schlüssel (sk_test_…) zum Ausprobieren; echte
/// Abbuchungen erst mit Live-Schlüssel. Der Schlüssel wird nur lokal
/// gespeichert (Admin → Einstellungen).
///
/// Hinweis fürs App-Store-Release: Apple verlangt für digitale Leistungen
/// in veröffentlichten iOS-Apps In-App-Purchases; für eine private/eigene
/// Nutzung oder Web-Abrechnung ist Stripe der richtige Weg.
enum StripeService {

    struct StripeError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private static func request(
        path: String,
        secretKey: String,
        form: [String: String]
    ) async throws -> [String: Any] {
        guard !secretKey.isEmpty else { throw StripeError(message: "Kein Stripe-Schlüssel hinterlegt.") }
        var req = URLRequest(url: URL(string: "https://api.stripe.com/v1/\(path)")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        req.httpBody = form
            .map { key, value in
                let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(key)=\(v)"
            }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status >= 400 {
            let msg = ((json["error"] as? [String: Any])?["message"] as? String) ?? "Stripe-Fehler (\(status))"
            throw StripeError(message: msg)
        }
        return json
    }

    /// Legt einen Stripe-Kunden für ein Profil an und liefert die Customer-ID.
    static func createCustomer(name: String, secretKey: String) async throws -> String {
        let json = try await request(path: "customers", secretKey: secretKey, form: [
            "name": name,
            "description": "AboWandler Profil \(name)",
        ])
        guard let id = json["id"] as? String else { throw StripeError(message: "Antwort ohne Customer-ID.") }
        return id
    }

    /// Rechnet offene Nutzung ab: legt eine Rechnungsposition + Rechnung an.
    /// Liefert die Rechnungs-ID.
    static func billUsage(customerId: String, amountEuro: Double, description: String, secretKey: String) async throws -> String {
        let cents = max(1, Int((amountEuro * 100).rounded()))
        _ = try await request(path: "invoiceitems", secretKey: secretKey, form: [
            "customer": customerId,
            "amount": String(cents),
            "currency": "eur",
            "description": description,
        ])
        let invoice = try await request(path: "invoices", secretKey: secretKey, form: [
            "customer": customerId,
            "auto_advance": "false",
            "pending_invoice_items_behavior": "include",
        ])
        guard let id = invoice["id"] as? String else { throw StripeError(message: "Antwort ohne Rechnungs-ID.") }
        return id
    }
}
