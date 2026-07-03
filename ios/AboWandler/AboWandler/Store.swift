import Foundation
import SwiftUI

/// Zentraler App-Zustand mit lokaler JSON-Persistenz (Documents-Ordner).
/// Alle Daten bleiben auf dem Gerät — kein Server, keine Cloud.
@MainActor
final class AppStore: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var transactions: [Txn] = []
    @Published var subscriptions: [Subscription] = []
    @Published var aiEnabled = false
    @Published var userName = ""
    @Published var lastScanSummary: String?

    private struct Persisted: Codable {
        var accounts: [Account]
        var transactions: [Txn]
        var subscriptions: [Subscription]
        var aiEnabled: Bool
        var userName: String
    }

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("abowandler.json")
    }

    init() {
        load()
        if accounts.isEmpty && transactions.isEmpty && subscriptions.isEmpty {
            seedDemoData()
        }
    }

    // MARK: Persistenz

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let p = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        accounts = p.accounts
        transactions = p.transactions
        subscriptions = p.subscriptions
        aiEnabled = p.aiEnabled
        userName = p.userName
    }

    func save() {
        let p = Persisted(accounts: accounts, transactions: transactions, subscriptions: subscriptions, aiEnabled: aiEnabled, userName: userName)
        if let data = try? JSONEncoder().encode(p) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: Aktionen

    func connect(provider: Provider) {
        accounts.append(Account(providerId: provider.id, label: provider.name))
        save()
    }

    func removeAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        transactions.removeAll { $0.accountId == account.id }
        save()
    }

    @discardableResult
    func importStatement(text: String, accountId: UUID) -> Int {
        let imported = CSVImporter.parse(text: text, accountId: accountId)
        transactions.append(contentsOf: imported)
        save()
        return imported.count
    }

    /// Algorithmus-Scan (ohne KI): erkennt wiederkehrende Zahlungen und
    /// aktualisiert die Abo-Liste, ohne Nutzer-Entscheidungen zu überschreiben.
    func scan() {
        let detected = RecurrenceScanner.detect(transactions: transactions)
        var created = 0
        var updated = 0
        for rec in detected {
            let recIban = RecurrenceScanner.ibanKey(rec.iban)
            if let idx = subscriptions.firstIndex(where: {
                (!recIban.isEmpty && RecurrenceScanner.ibanKey($0.iban) == recIban) ||
                (recIban.isEmpty && RecurrenceScanner.normalize($0.name) == RecurrenceScanner.normalize(rec.name))
            }) {
                subscriptions[idx].amount = rec.amount
                subscriptions[idx].cycle = rec.cycle
                subscriptions[idx].priceHistory = rec.priceHistory
                subscriptions[idx].occurrences = rec.occurrences
                if subscriptions[idx].paymentDay == nil { subscriptions[idx].paymentDay = rec.paymentDay }
                if subscriptions[idx].status == .pending || subscriptions[idx].status == .warning {
                    subscriptions[idx].status = rec.status
                    subscriptions[idx].note = rec.note
                }
                updated += 1
            } else {
                subscriptions.append(rec)
                created += 1
            }
        }
        let warnings = detected.filter { $0.status == .warning }.count
        lastScanSummary = "\(transactions.count) Umsätze geprüft — \(detected.count) wiederkehrende Zahlungen erkannt (\(created) neu, \(updated) aktualisiert), \(warnings) Warnung\(warnings == 1 ? "" : "en"). Rein algorithmisch: IBANs, Namen, Betreffe, Intervalle & Beträge."
        save()
    }

    func update(_ sub: Subscription) {
        if let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[idx] = sub
            save()
        }
    }

    func removeSubscription(_ sub: Subscription) {
        subscriptions.removeAll { $0.id == sub.id }
        save()
    }

    func resetToDemo() {
        accounts = []
        transactions = []
        subscriptions = []
        lastScanSummary = nil
        seedDemoData()
    }

    // MARK: Abgeleitete Werte

    var monthlyTotal: Double {
        subscriptions.filter { !$0.paused }.reduce(0) { $0 + $1.monthlyAmount }
    }
    var convertedSum: Double {
        subscriptions.filter { $0.conversion.confirmed }.reduce(0) { $0 + $1.monthlyAmount }
    }
    var conversionPotential: Double {
        subscriptions.filter { $0.status == .convert && !$0.conversion.confirmed }.reduce(0) { $0 + $1.monthlyAmount }
    }
    var warningsCount: Int {
        subscriptions.filter { $0.status == .warning }.count
    }
    var pendingConversions: [Subscription] {
        subscriptions.filter { !$0.conversion.confirmed && ($0.status == .convert || $0.conversion.cancelled || $0.conversion.planCreated) }
    }

    // MARK: Demo-Daten (gleicher Datensatz wie die Web-App)

    private func seedDemoData() {
        let bank = Account(providerId: "sparkasse", label: "Sparkasse Girokonto", iban: "DE89 3704 0044 0532 0130 00")
        let paypal = Account(providerId: "paypal", label: "PayPal")
        accounts = [bank, paypal]

        func d(_ s: String) -> Date {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: s) ?? Date()
        }
        func t(_ date: String, _ name: String, _ iban: String?, _ subject: String, _ amount: Double, paypal usePaypal: Bool = false) -> Txn {
            Txn(accountId: usePaypal ? paypal.id : bank.id, date: d(date), name: name, iban: iban, subject: subject, amount: amount)
        }

        var txs: [Txn] = []
        for (m, day) in [("03", "01"), ("04", "01"), ("05", "01"), ("06", "01")] {
            txs.append(t("2026-\(m)-\(day)", "Wohnbau Rhein GmbH", "DE45 5001 0517 6000 1111 22", "Miete Wohnung 4B", -950.00))
        }
        for m in ["03", "04", "05", "06"] {
            txs.append(t("2026-\(m)-15", "NETFLIX INTERNATIONAL B.V.", "NL91 ABNA 0417 1643 00", "Netflix Mitgliedschaft", -17.99))
            txs.append(t("2026-\(m)-03", "SPOTIFY AB", "LU96 0000 0000 0000 1234", "Spotify Premium", -10.99))
            txs.append(t("2026-\(m)-20", "ADOBE SYSTEMS SOFTWARE IRELAND LTD", "IE29 AIBK 9311 5212 3456 78", "Creative Cloud Abo", -59.99))
            txs.append(t("2026-\(m)-15", "FITNESS FIRST GERMANY GMBH", "DE12 5005 0201 0200 4455 66", "Mitgliedsbeitrag", -39.90))
            txs.append(t("2026-\(m)-22", "AMAZON PRIME DE", "DE87 3007 0010 0111 2223 33", "Prime Mitgliedschaft", -8.99))
            txs.append(t("2026-\(m)-05", "Stadtwerke Köln", "DE55 3705 0198 0000 4433 22", "Abschlag Strom/Gas", -85.00))
            txs.append(t("2026-\(m)-10", "Disney Plus", nil, "PayPal Zahlung Disney+", -8.99, paypal: true))
        }
        txs.append(t("2026-03-27", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -29.99))
        txs.append(t("2026-04-27", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -29.99))
        txs.append(t("2026-05-27", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -39.99))
        txs.append(t("2026-06-26", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -39.99))
        txs.append(t("2026-05-29", "CLOUDSECURE PRO LTD", "FI21 1234 5600 0007 85", "Service Fee", -24.99))
        txs.append(t("2026-06-29", "CLOUDSECURE PRO LTD", "FI21 1234 5600 0007 85", "Service Fee", -24.99))
        // Rauschen: variable Ausgaben, die der Algorithmus NICHT als Abo werten darf
        txs.append(t("2026-03-08", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -23.47))
        txs.append(t("2026-04-02", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -35.80))
        txs.append(t("2026-05-11", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -52.30))
        txs.append(t("2026-06-14", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -44.60))
        txs.append(t("2026-04-12", "Shell Deutschland", "DE66 3004 0000 0555 6667 77", "Tankstelle", -65.40))
        txs.append(t("2026-05-17", "Shell Deutschland", "DE66 3004 0000 0555 6667 77", "Tankstelle", -58.20))
        txs.append(t("2026-06-20", "Shell Deutschland", "DE66 3004 0000 0555 6667 77", "Tankstelle", -71.00))
        for (m, day) in [("03", "27"), ("04", "28"), ("05", "27"), ("06", "26")] {
            txs.append(t("2026-\(m)-\(day)", "TechCorp GmbH", "DE20 1005 0000 0000 9999 01", "Gehalt", 2850.00))
        }
        transactions = txs
        save()
    }
}
