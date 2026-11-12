import Foundation
enum KIJson {
    private static let aliasPaare: [(String, String)] = [
        ("begruendung", "beguendung"),
        ("gegenmassnahme", "gegenmasnahme"),
        ("gegenmassnahmen", "gegenmasnahmen"),
        ("massnahme", "masnahme"),
        ("massnahmen", "masnahmen"),
        ("massnahmen_folgen", "masnahmen_folgen"),
        ("verbesserungsmassnahmen", "verbesserungsmasnahmen"),
        ("erklaerung", "erklarung"),
        ("abweichungs_erklaerung", "abweichungs_erklarung"),
        ("erfolgswahrscheinlichkeit_begruendung", "erfolgswahrscheinlichkeit_beguendung"),
        ("verfassungsverstoss_begruendung", "verfassungsverstoss_beguendung"),
        ("wahrscheinlichkeit", "warscheinlichkeit"),
    ]
    static func expandedKeys(_ keys: [String]) -> [String] {
        var out: [String] = []
        var seen = Set<String>()
        func add(_ k: String) {
            guard !k.isEmpty, seen.insert(k).inserted else { return }
            out.append(k)
        }
        for k in keys {
            add(k)
            if k.contains("massnahme") {
                add(k.replacingOccurrences(of: "massnahme", with: "maßnahme"))
                add(k.replacingOccurrences(of: "massnahme", with: "masnahme"))
            }
            if k.contains("maßnahme") {
                add(k.replacingOccurrences(of: "maßnahme", with: "massnahme"))
                add(k.replacingOccurrences(of: "maßnahme", with: "masnahme"))
            }
            for (a, b) in aliasPaare {
                if k == a { add(b) }
                else if k == b { add(a) }
                else if k.contains(a) { add(k.replacingOccurrences(of: a, with: b)) }
                else if k.contains(b) { add(k.replacingOccurrences(of: b, with: a)) }
            }
        }
        return out
    }
    static func requireObject(_ value: AnyCodable, kontext: String = "KI") throws -> [String: Any] {
        if let dict = value.dictValue { return dict }
        if let text = value.stringValue, let parsed = parseJSONObject(text) as? [String: Any] {
            return parsed
        }
        throw Base44Error.serverError("\(kontext): Keine verwertbare JSON-Antwort erhalten.")
    }
    static func numberValue(_ value: Any?) -> Double? {
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        if let n = value as? Float { return Double(n) }
        if let s = value as? String, let n = Double(s.replacingOccurrences(of: ",", with: ".")) { return n }
        return nil
    }
    static func intValue(_ value: Any?) -> Int? {
        if let n = numberValue(value) { return Int(n.rounded()) }
        return nil
    }
    static func array(in dict: [String: Any], keys: String...) -> [[String: Any]] {
        for key in expandedKeys(keys) {
            if let arr = dict[key] as? [[String: Any]] { return arr }
            if let arr = dict[key] as? [Any] {
                return arr.compactMap { $0 as? [String: Any] }
            }
        }
        return []
    }
    static func string(in dict: [String: Any], keys: String...) -> String? {
        for key in expandedKeys(keys) {
            if let s = dict[key] as? String, !s.isEmpty { return s }
        }
        return nil
    }
    static func stringList(in dict: [String: Any], keys: String...) -> [String] {
        for key in expandedKeys(keys) {
            if let arr = dict[key] as? [String] { return arr.filter { !$0.isEmpty } }
            if let arr = dict[key] as? [Any] {
                let out = arr.compactMap { $0 as? String }.filter { !$0.isEmpty }
                if !out.isEmpty { return out }
            }
        }
        return []
    }
    static func number(in dict: [String: Any], keys: String...) -> Double? {
        for key in expandedKeys(keys) {
            if let n = dict[key] as? Double { return n }
            if let n = dict[key] as? Int { return Double(n) }
            if let s = dict[key] as? String, let n = Double(s) { return n }
        }
        return nil
    }
    static func int(in dict: [String: Any], keys: String...) -> Int? {
        for key in expandedKeys(keys) {
            if let n = dict[key] as? Double { return Int(n.rounded()) }
            if let n = dict[key] as? Int { return n }
            if let s = dict[key] as? String, let n = Double(s) { return Int(n.rounded()) }
        }
        return nil
    }
    private static func parseJSONObject(_ text: String) -> Any? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let data = cleaned.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
}
enum KIFileURLs {
    static func sanitize(_ urls: [String]?) -> [String]? {
        guard let urls, !urls.isEmpty else { return nil }
        let valid = urls
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter(isValidAttachmentURL)
        return valid.isEmpty ? nil : valid
    }
    static func isValidAttachmentURL(_ url: String) -> Bool {
        guard !url.isEmpty else { return false }
        let lower = url.lowercased()
        if lower.hasPrefix("file://") || lower.hasPrefix("/") { return false }
        guard lower.hasPrefix("https://"), let parsed = URL(string: url), let host = parsed.host, !host.isEmpty else {
            return false
        }
        return true
    }
    static func isInvalidAttachmentError(_ message: String) -> Bool {
        let m = message.lowercased()
        return m.contains("invalid file") || m.contains("file attachment") || m.contains("file_url")
    }
}
