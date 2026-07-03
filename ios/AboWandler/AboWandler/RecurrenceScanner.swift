import Foundation

/// Rein algorithmische Erkennung wiederkehrender Zahlungen — ohne KI.
/// Gruppiert nach IBAN (stärkstes Signal) oder normalisiertem Namen/Betreff,
/// prüft Intervall-Regelmäßigkeit und Betrags-Konsistenz.
/// 1:1-Portierung von server/lib/recurrence.js der Web-App.
enum RecurrenceScanner {

    static let knownBrands = [
        "netflix", "spotify", "adobe", "amazon", "vodafone", "telekom", "o2", "1und1",
        "disney", "dazn", "sky", "youtube", "apple", "google", "microsoft", "dropbox",
        "fitness", "mcfit", "urban sports", "stadtwerke", "rewe", "edeka", "aldi", "lidl",
        "shell", "aral", "dm-", "rossmann", "miete", "wohnbau", "wohnung", "steam", "ebay",
        "paypal", "klarna", "allianz", "huk", "adac", "bahn", "rundfunk", "audible",
    ]

    static let genericTokens = ["ltd", "limited", "service", "services", "pro", "solutions", "consulting", "billing", "payment", "fee"]

    static let categoryRules: [([String], String)] = [
        (["netflix", "disney", "dazn", "sky", "wow", "paramount"], "Streaming"),
        (["spotify", "deezer", "tidal", "apple music"], "Musik"),
        (["adobe", "microsoft", "dropbox", "notion", "figma"], "Software"),
        (["vodafone", "telekom", "o2", "1und1", "congstar", "mobilfunk"], "Mobilfunk & Internet"),
        (["fitness", "mcfit", "gym", "urban sports"], "Sport"),
        (["amazon prime", "prime mitglied"], "Shopping"),
        (["miete", "wohnbau", "wohnung", "hausverwaltung"], "Wohnen"),
        (["stadtwerke", "strom", "gas", "energie"], "Energie"),
        (["allianz", "huk", "versicherung"], "Versicherung"),
        (["steam", "playstation", "xbox", "nintendo"], "Gaming"),
        (["audible", "kindle"], "Medien"),
    ]

    static func normalize(_ s: String) -> String {
        let lowered = s.lowercased()
        let filtered = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.letters.contains(scalar) || scalar == " " { return Character(scalar) }
            return " "
        }
        return String(filtered).split(separator: " ").joined(separator: " ")
    }

    static func ibanKey(_ iban: String?) -> String {
        (iban ?? "").replacingOccurrences(of: " ", with: "").uppercased()
    }

    static func nameKey(_ name: String, _ subject: String) -> String {
        let n = normalize(name)
        let source = n.isEmpty ? normalize(subject) : n
        return source.split(separator: " ").prefix(3).joined(separator: " ")
    }

    static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let s = values.sorted()
        let mid = s.count / 2
        return s.count % 2 == 1 ? s[mid] : (s[mid - 1] + s[mid]) / 2
    }

    static func detectCycle(gapsDays: [Double]) -> String? {
        guard !gapsDays.isEmpty else { return nil }
        let m = median(gapsDays)
        switch m {
        case 5...9: return "wöchentlich"
        case 26...35: return "monatlich"
        case 80...105: return "vierteljährlich"
        case 330...400: return "jährlich"
        default: return nil
        }
    }

    static func guessCategory(name: String, subject: String) -> String {
        let hay = "\(name) \(subject)".lowercased()
        for (keys, cat) in categoryRules where keys.contains(where: { hay.contains($0) }) {
            return cat
        }
        return "Sonstiges"
    }

    /// Bewertet eine Gruppe von Umsätzen; liefert ein Abo oder nil.
    static func assess(_ txs: [Txn], today: Date = Date()) -> Subscription? {
        guard txs.count >= 2 else { return nil }
        let sorted = txs.sorted { $0.date < $1.date }
        var gaps: [Double] = []
        for i in 1..<sorted.count {
            gaps.append(sorted[i].date.timeIntervalSince(sorted[i - 1].date) / 86400)
        }
        guard let cycle = detectCycle(gapsDays: gaps) else { return nil }

        // Betrags-Konsistenz: wenige verschiedene Beträge (identische Gebühren
        // oder Preistreppe) — variable Ausgaben werden verworfen.
        let amounts = sorted.map { abs($0.amount) }
        let distinct = Set(amounts.map { String(format: "%.2f", $0) })
        let distinctRatio = Double(distinct.count) / Double(amounts.count)
        let med = median(amounts)
        let nearMedian = amounts.filter { med > 0 && abs($0 - med) / med <= 0.02 }.count
        if distinctRatio > 0.5 && Double(nearMedian) / Double(amounts.count) < 0.6 { return nil }

        let last = sorted[sorted.count - 1]
        let name = last.name.isEmpty ? last.subject : last.name
        let hay = "\(name) \(last.subject)".lowercased()
        let known = knownBrands.contains { hay.contains($0) }
        let country = String(ibanKey(last.iban).prefix(2))
        let foreign = !country.isEmpty && !["DE", "AT"].contains(country)
        let generic = genericTokens.contains { hay.contains($0) }
        let firstSeenDays = today.timeIntervalSince(sorted[0].date) / 86400

        // Regelbasierter Verdachts-Score (keine KI).
        var score = 0
        if !known { score += 2 }
        if foreign { score += 1 }
        if generic { score += 1 }
        if firstSeenDays < 75 { score += 1 }
        let suspicious = score >= 3

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        var priceHistory: [PricePoint] = []
        for t in sorted {
            let amt = abs(t.amount)
            if priceHistory.last?.amount != amt {
                priceHistory.append(PricePoint(month: monthFormatter.string(from: t.date), amount: amt))
            }
        }
        let priceRose = priceHistory.count > 1 && (priceHistory.last?.amount ?? 0) > priceHistory[0].amount

        var notes: [String] = []
        if suspicious {
            var reasons: [String] = []
            if !known { reasons.append("unbekannter Anbieter") }
            if foreign { reasons.append("ausländische IBAN (\(country))") }
            if generic { reasons.append("generischer Name") }
            if firstSeenDays < 75 { reasons.append("neue Abbuchung") }
            notes.append("⚠ " + reasons.joined(separator: " · "))
        }
        if priceRose {
            notes.append("Preis gestiegen: \(priceHistory[0].amount.euro) → \((priceHistory.last?.amount ?? 0).euro)")
        }

        let days = sorted.map { Double(Calendar.current.component(.day, from: $0.date)) }

        return Subscription(
            name: name,
            amount: abs(last.amount),
            cycle: cycle,
            sinceMonth: monthFormatter.string(from: sorted[0].date),
            category: guessCategory(name: name, subject: last.subject),
            status: suspicious ? .warning : .pending,
            iban: last.iban,
            note: notes.joined(separator: " — "),
            paymentDay: min(28, Int(median(days).rounded())),
            occurrences: sorted.count,
            priceHistory: priceHistory
        )
    }

    /// Scannt alle Umsätze; liefert erkannte wiederkehrende Zahlungen.
    static func detect(transactions: [Txn], today: Date = Date()) -> [Subscription] {
        let expenses = transactions.filter { $0.amount < 0 }
        var groups: [String: [Txn]] = [:]
        for t in expenses {
            let key = ibanKey(t.iban).isEmpty ? "n:\(nameKey(t.name, t.subject))" : ibanKey(t.iban)
            if key == "n:" { continue }
            groups[key, default: []].append(t)
        }
        return groups.values
            .compactMap { assess($0, today: today) }
            .sorted { $0.amount > $1.amount }
    }
}
