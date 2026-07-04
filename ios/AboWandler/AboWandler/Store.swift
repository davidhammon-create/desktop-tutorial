import Foundation
import SwiftUI

/// Zentraler App-Zustand — das komplette "Backend" der App in Swift:
/// Profile (Accounts), Daten je Profil, Abrechnungs-Ledger, Persistenz.
/// Alles lokal auf dem Gerät; kostenpflichtige Aktionen werden je Profil
/// erfasst und über das verknüpfte Stripe-Konto abgerechnet.
@MainActor
final class AppStore: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var currentProfileId: UUID?
    @Published var dataByProfile: [UUID: ProfileData] = [:]
    @Published var stripeSecretKey: String = ""
    @Published var lastScanSummary: String?

    private struct Persisted: Codable {
        var profiles: [Profile]
        var currentProfileId: UUID?
        var dataByProfile: [UUID: ProfileData]
        var stripeSecretKey: String
    }

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("abowandler-v2.json")
    }

    init() {
        load()
        if profiles.isEmpty {
            let admin = Profile(name: "David", isAdmin: true)
            profiles = [admin]
            dataByProfile[admin.id] = Self.demoData()
            currentProfileId = nil // Profil-Auswahl beim Start zeigen
            save()
        }
    }

    // MARK: Profil-Zugriff

    var currentProfile: Profile? {
        profiles.first { $0.id == currentProfileId }
    }

    var currentData: ProfileData {
        get { currentProfileId.flatMap { dataByProfile[$0] } ?? ProfileData() }
        set { if let id = currentProfileId { dataByProfile[id] = newValue } }
    }

    var accounts: [Account] { currentData.accounts }
    var transactions: [Txn] { currentData.transactions }
    var subscriptions: [Subscription] { currentData.subscriptions }
    var aiEnabled: Bool { currentProfile?.aiEnabled ?? false }
    var scanMethod: ScanMethod { currentProfile?.scanMethod ?? .algorithmus }

    /// Kostenpflichtige Services nur mit verknüpftem Stripe-Konto UND Pro-Plan.
    var canUsePaidServices: Bool {
        guard let p = currentProfile else { return false }
        return p.plan == .pro && p.hasStripe && !stripeSecretKey.isEmpty
    }

    var paidServicesHint: String {
        guard let p = currentProfile else { return "Kein Profil gewählt." }
        if stripeSecretKey.isEmpty { return "Stripe ist nicht eingerichtet (Admin → Einstellungen → Stripe-Schlüssel)." }
        if !p.hasStripe { return "Dieses Profil hat kein Stripe-Konto verknüpft — kostenpflichtige Services sind gesperrt." }
        if p.plan != .pro { return "KI-Funktionen brauchen den Pro-Plan (\(Pricing.proMonthly.euro)/Monat)." }
        return ""
    }

    func mutateProfile(_ change: (inout Profile) -> Void) {
        guard let idx = profiles.firstIndex(where: { $0.id == currentProfileId }) else { return }
        change(&profiles[idx])
        save()
    }

    func selectProfile(_ id: UUID?) {
        currentProfileId = id
        lastScanSummary = nil
        save()
    }

    func addProfile(name: String) {
        let p = Profile(name: name)
        profiles.append(p)
        dataByProfile[p.id] = ProfileData()
        save()
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == id }
        dataByProfile.removeValue(forKey: id)
        if currentProfileId == id { currentProfileId = nil }
        save()
    }

    // MARK: Abrechnung (jede kostenpflichtige Aktion landet im Profil-Ledger)

    /// Belastet das aktuelle Profil. Liefert false, wenn kostenpflichtige
    /// Services nicht nutzbar sind (kein Stripe-Konto / kein Pro-Plan).
    @discardableResult
    func charge(action: String, cost: Double) -> Bool {
        guard canUsePaidServices else { return false }
        mutateProfile { $0.usage.append(UsageEntry(action: action, cost: cost)) }
        return true
    }

    func markUsageBilled() {
        mutateProfile { profile in
            profile.usage = profile.usage.map { entry in
                var e = entry
                e.billed = true
                return e
            }
        }
    }

    func activatePro() -> Bool {
        guard let p = currentProfile, p.hasStripe, !stripeSecretKey.isEmpty else { return false }
        mutateProfile {
            $0.plan = .pro
            $0.usage.append(UsageEntry(action: "Pro-Abo aktiviert (\(Pricing.proMonthly.euro)/Monat)", cost: Pricing.proMonthly))
        }
        return true
    }

    func cancelPro() {
        mutateProfile { $0.plan = .free }
    }

    // MARK: Persistenz

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let p = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        profiles = p.profiles
        currentProfileId = p.currentProfileId
        dataByProfile = p.dataByProfile
        stripeSecretKey = p.stripeSecretKey
    }

    func save() {
        let p = Persisted(profiles: profiles, currentProfileId: currentProfileId, dataByProfile: dataByProfile, stripeSecretKey: stripeSecretKey)
        if let data = try? JSONEncoder().encode(p) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: Konten & Umsätze

    func connect(provider: Provider) {
        var d = currentData
        d.accounts.append(Account(providerId: provider.id, label: provider.name))
        currentData = d
        save()
    }

    func removeAccount(_ account: Account) {
        var d = currentData
        d.accounts.removeAll { $0.id == account.id }
        d.transactions.removeAll { $0.accountId == account.id }
        currentData = d
        save()
    }

    @discardableResult
    func importStatement(text: String, accountId: UUID) -> Int {
        let imported = CSVImporter.parse(text: text, accountId: accountId)
        var d = currentData
        d.transactions.append(contentsOf: imported)
        currentData = d
        save()
        return imported.count
    }

    // MARK: Scan — Algorithmus (kostenlos) und/oder KI (kostenpflichtig)

    /// Algorithmus-Scan: erkennt wiederkehrende Zahlungen, ohne KI, kostenlos.
    func scanAlgorithm() {
        let detected = RecurrenceScanner.detect(transactions: transactions)
        var d = currentData
        var created = 0
        var updated = 0
        for rec in detected {
            let recIban = RecurrenceScanner.ibanKey(rec.iban)
            if let idx = d.subscriptions.firstIndex(where: {
                (!recIban.isEmpty && RecurrenceScanner.ibanKey($0.iban) == recIban) ||
                (recIban.isEmpty && RecurrenceScanner.normalize($0.name) == RecurrenceScanner.normalize(rec.name))
            }) {
                d.subscriptions[idx].amount = rec.amount
                d.subscriptions[idx].cycle = rec.cycle
                d.subscriptions[idx].priceHistory = rec.priceHistory
                d.subscriptions[idx].occurrences = rec.occurrences
                if d.subscriptions[idx].paymentDay == nil { d.subscriptions[idx].paymentDay = rec.paymentDay }
                if d.subscriptions[idx].status == .pending || d.subscriptions[idx].status == .warning {
                    d.subscriptions[idx].status = rec.status
                    d.subscriptions[idx].note = rec.note
                }
                updated += 1
            } else {
                d.subscriptions.append(rec)
                created += 1
            }
        }
        currentData = d
        let warnings = detected.filter { $0.status == .warning }.count
        lastScanSummary = "Algorithmus: \(transactions.count) Umsätze geprüft — \(detected.count) wiederkehrende Zahlungen (\(created) neu, \(updated) aktualisiert), \(warnings) Warnung\(warnings == 1 ? "" : "en"). Kostenlos."
        save()
    }

    /// KI-Scan: verfeinert die Erkennung per Apple Intelligence.
    /// Kostenpflichtig — wird dem Profil zugewiesen. Wichtig: erst die
    /// KI-Verfügbarkeit prüfen, DANN belasten — nie fürs Scheitern kassieren.
    func scanWithAI() async {
        guard AppleAI.isAvailable else {
            scanAlgorithm()
            lastScanSummary = (lastScanSummary ?? "") + " KI übersprungen (nicht berechnet): \(AppleAI.availabilityText)"
            return
        }
        guard charge(action: "KI-Scan der Umsätze", cost: Pricing.kiScan) else {
            lastScanSummary = paidServicesHint
            return
        }
        scanAlgorithm()
        do {
            let refinements = try await AppleAI.refineSubscriptions(subscriptions)
            var d = currentData
            var refined = 0
            for r in refinements {
                if let idx = d.subscriptions.firstIndex(where: { $0.id == r.id }) {
                    d.subscriptions[idx].status = r.status
                    if !r.reason.isEmpty { d.subscriptions[idx].note = r.reason }
                    refined += 1
                }
            }
            currentData = d
            lastScanSummary = (lastScanSummary ?? "") + " KI-Verfeinerung: \(refined) Abos neu bewertet (on-device, \(Pricing.kiScan.euro) abgerechnet)."
            save()
        } catch {
            lastScanSummary = (lastScanSummary ?? "") + " KI-Verfeinerung fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    func update(_ sub: Subscription) {
        var d = currentData
        if let idx = d.subscriptions.firstIndex(where: { $0.id == sub.id }) {
            d.subscriptions[idx] = sub
            currentData = d
            save()
        }
    }

    func removeSubscription(_ sub: Subscription) {
        var d = currentData
        d.subscriptions.removeAll { $0.id == sub.id }
        currentData = d
        save()
    }

    func resetToDemo() {
        var d = Self.demoData()
        d.subscriptions = []
        currentData = d
        lastScanSummary = nil
        save()
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

    // MARK: Demo-Daten

    static func demoData() -> ProfileData {
        let bank = Account(providerId: "sparkasse", label: "Sparkasse Girokonto", iban: "DE89 3704 0044 0532 0130 00")
        let paypal = Account(providerId: "paypal", label: "PayPal")

        func d(_ s: String) -> Date {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: s) ?? Date()
        }
        func t(_ date: String, _ name: String, _ iban: String?, _ subject: String, _ amount: Double, paypal usePaypal: Bool = false) -> Txn {
            Txn(accountId: usePaypal ? paypal.id : bank.id, date: d(date), name: name, iban: iban, subject: subject, amount: amount)
        }

        var txs: [Txn] = []
        for m in ["03", "04", "05", "06"] {
            txs.append(t("2026-\(m)-01", "Wohnbau Rhein GmbH", "DE45 5001 0517 6000 1111 22", "Miete Wohnung 4B", -950.00))
            txs.append(t("2026-\(m)-15", "NETFLIX INTERNATIONAL B.V.", "NL91 ABNA 0417 1643 00", "Netflix Mitgliedschaft", -17.99))
            txs.append(t("2026-\(m)-03", "SPOTIFY AB", "LU96 0000 0000 0000 1234", "Spotify Premium", -10.99))
            txs.append(t("2026-\(m)-20", "ADOBE SYSTEMS SOFTWARE IRELAND LTD", "IE29 AIBK 9311 5212 3456 78", "Creative Cloud Abo", -59.99))
            txs.append(t("2026-\(m)-15", "FITNESS FIRST GERMANY GMBH", "DE12 5005 0201 0200 4455 66", "Mitgliedsbeitrag", -39.90))
            txs.append(t("2026-\(m)-22", "AMAZON PRIME DE", "DE87 3007 0010 0111 2223 33", "Prime Mitgliedschaft", -8.99))
            txs.append(t("2026-\(m)-05", "Stadtwerke Köln", "DE55 3705 0198 0000 4433 22", "Abschlag Strom/Gas", -85.00))
            txs.append(t("2026-\(m)-10", "Disney Plus", nil, "PayPal Zahlung Disney+", -8.99, paypal: true))
            txs.append(t("2026-\(m)-27", "TechCorp GmbH", "DE20 1005 0000 0000 9999 01", "Gehalt", 2850.00))
        }
        txs.append(t("2026-03-27", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -29.99))
        txs.append(t("2026-04-27", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -29.99))
        txs.append(t("2026-05-27", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -39.99))
        txs.append(t("2026-06-26", "Vodafone GmbH", "DE33 5002 0000 0011 2233 44", "Mobilfunk Rechnung", -39.99))
        txs.append(t("2026-05-29", "CLOUDSECURE PRO LTD", "FI21 1234 5600 0007 85", "Service Fee", -24.99))
        txs.append(t("2026-06-29", "CLOUDSECURE PRO LTD", "FI21 1234 5600 0007 85", "Service Fee", -24.99))
        txs.append(t("2026-03-08", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -23.47))
        txs.append(t("2026-04-02", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -35.80))
        txs.append(t("2026-05-11", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -52.30))
        txs.append(t("2026-06-14", "REWE Markt GmbH", "DE11 3701 0050 0000 1112 23", "Kartenzahlung", -44.60))
        txs.append(t("2026-04-12", "Shell Deutschland", "DE66 3004 0000 0555 6667 77", "Tankstelle", -65.40))
        txs.append(t("2026-05-17", "Shell Deutschland", "DE66 3004 0000 0555 6667 77", "Tankstelle", -58.20))
        txs.append(t("2026-06-20", "Shell Deutschland", "DE66 3004 0000 0555 6667 77", "Tankstelle", -71.00))

        return ProfileData(accounts: [bank, paypal], transactions: txs, subscriptions: [])
    }
}
