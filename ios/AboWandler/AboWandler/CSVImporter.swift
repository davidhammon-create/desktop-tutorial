import Foundation

/// Kontoauszug-Import ohne KI: extrahiert Datum, Name, IBAN, Betreff und
/// Betrag pro Zeile aus eingefügtem Text oder CSV-Dateien (Bank-Exporte).
enum CSVImporter {

    static func parse(text: String, accountId: UUID) -> [Txn] {
        var result: [Txn] = []
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        let deFormatter = DateFormatter()
        deFormatter.dateFormat = "dd.MM.yyyy"

        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            // Datum: ISO (2026-06-15) oder deutsch (15.06.2026 / 15.6.26)
            var date: Date?
            var dateRangeText = ""
            if let m = line.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                date = isoFormatter.date(from: String(line[m]))
                dateRangeText = String(line[m])
            } else if let m = line.range(of: #"\d{1,2}\.\d{1,2}\.\d{2,4}"#, options: .regularExpression) {
                var text = String(line[m])
                let parts = text.split(separator: ".")
                if parts.count == 3 {
                    let yyyy = parts[2].count == 2 ? "20\(parts[2])" : String(parts[2])
                    text = String(format: "%02d.%02d.%@", Int(parts[0]) ?? 1, Int(parts[1]) ?? 1, yyyy)
                    date = deFormatter.date(from: text)
                }
                dateRangeText = String(line[m])
            }
            guard let parsedDate = date else { continue }

            // Betrag am Zeilenende: -17,99 / -17.99 (optional € / EUR)
            guard let amountMatch = line.range(of: #"-?\d{1,6}[.,]\d{2}\s*(€|EUR)?\s*$"#, options: .regularExpression) else { continue }
            let amountText = String(line[amountMatch])
                .replacingOccurrences(of: "€", with: "")
                .replacingOccurrences(of: "EUR", with: "")
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: ",", with: ".")
            guard let amount = Double(amountText) else { continue }

            // IBAN (optional)
            var iban: String?
            var ibanText = ""
            if let m = line.range(of: #"[A-Z]{2}\d{2}(\s?[A-Z0-9]{2,4}){2,8}"#, options: .regularExpression) {
                iban = String(line[m])
                ibanText = String(line[m])
            }

            // Rest = Name + Betreff
            var rest = line
                .replacingOccurrences(of: dateRangeText, with: "")
                .replacingOccurrences(of: String(line[amountMatch]), with: "")
            if !ibanText.isEmpty { rest = rest.replacingOccurrences(of: ibanText, with: "") }
            let fields = rest
                .replacingOccurrences(of: ";", with: "  ")
                .replacingOccurrences(of: "|", with: "  ")
                .components(separatedBy: "  ")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            let name = fields.first ?? "Unbekannt"
            let subject = fields.dropFirst().joined(separator: " ")

            result.append(Txn(accountId: accountId, date: parsedDate, name: name, iban: iban, subject: subject, amount: amount))
        }
        return result
    }
}
