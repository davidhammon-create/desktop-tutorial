import Foundation

// MARK: - InvokeLLM Response Parser
//
// Base44 InvokeLLM kann je nach Modus unterschiedliche Formate liefern:
// - Plain-String: "OK"
// - Direktes JSON-Objekt: {"fristen":[...]}
// - Wrapper: {"response":"..."} oder {"text":"..."}
// - JSON als String (ggf. in Markdown-Codeblöcken)

enum InvokeLLMResponseParser {
static func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
  // WICHTIG: Base44 verpackt JSON-Schema-Antworten in {"response": {...}}.
  // Daher IMMER zuerst strukturiert lesen und auspacken -- niemals vorab
  // direkt dekodieren, da z.B. AnyCodable den Wrapper sonst ungeauspackt
  // übernähme und KIJson die Felder auf der falschen Ebene suchen würde.
  if let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
    let unwrapped = unwrap(json)

    if T.self == String.self {
      if let text = textFrom(unwrapped), let cast = text as? T {
        return cast
      }
      throw Base44Error.decodingError(
        NSError(domain: "InvokeLLM", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kein Text in InvokeLLM-Antwort"])
      )
    }

    if T.self == AnyCodable.self {
      let value = AnyCodable(normalize(unwrapped))
      if let cast = value as? T { return cast }
      throw Base44Error.decodingError(
        NSError(domain: "InvokeLLM", code: 0, userInfo: [NSLocalizedDescriptionKey: "AnyCodable-Cast fehlgeschlagen"])
      )
    }

    let normalized = normalize(unwrapped)
    let reencoded = try JSONSerialization.data(withJSONObject: normalized, options: [.fragmentsAllowed])
    return try JSONDecoder.base44.decode(T.self, from: reencoded)
  }

  // Fallback (z.B. unerwartetes Rohformat): direkt dekodieren.
  return try JSONDecoder.base44.decode(T.self, from: data)
}

static func decodeText(_ data: Data) throws -> String {
  try decode(data, as: String.self)
}

private static func unwrap(_ json: Any) -> Any {
  if let dict = json as? [String: Any] {
    for key in ["response", "result", "output", "data", "content"] {
      if let inner = dict[key] {
        if dict.count == 1 || key == "response" || key == "result" {
          return unwrap(inner)
        }
      }
    }
    if let text = dict["text"] as? String ?? dict["response"] as? String {
      if let parsed = parseJSONString(text) {
        return unwrap(parsed)
      }
    }
    return dict
  }

  if let text = json as? String {
    if let parsed = parseJSONString(text) {
      return unwrap(parsed)
    }
  }

  return json
}

private static func parseJSONString(_ text: String) -> Any? {
  var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
  if cleaned.hasPrefix("```") {
    cleaned = cleaned
      .replacingOccurrences(of: "```json", with: "")
      .replacingOccurrences(of: "```", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  guard cleaned.hasPrefix("{") || cleaned.hasPrefix("[") else { return nil }
  guard let data = cleaned.data(using: .utf8) else { return nil }
  return try? JSONSerialization.jsonObject(with: data)
}

private static func textFrom(_ json: Any) -> String? {
  if let s = json as? String { return s }
  if let dict = json as? [String: Any] {
    for key in ["response", "text", "output", "content", "result"] {
      if let s = dict[key] as? String { return s }
    }
    if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
     let s = String(data: data, encoding: .utf8) {
      return s
    }
  }
 return nil
}

private static func normalize(_ json: Any) -> Any {
 switch json {
 case let dict as [String: Any]:
   return dict.mapValues { normalize($0) }
 case let array as [Any]:
   return array.map { normalize($0) }
 case is NSNull:
   return NSNull()
 default:
   return json
 }
}
}

