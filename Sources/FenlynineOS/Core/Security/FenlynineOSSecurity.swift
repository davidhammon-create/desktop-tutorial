import Foundation

// MARK: - Sicherheits-Hilfen (URLs, Dateinamen, Upload-Limits)

enum FenlynineOSSecurity {
/// Maximale Upload-Größe (50 MB) -- verhindert Speicherüberlauf bei großen PDFs.
static let maxUploadBytes: Int = 50 * 1024 * 1024

/// HTTPS-URLs für externe Dokumente (kein file://, kein javascript:).
static func isSafeHTTPSURL(_ urlString: String) -> Bool {
  KIFileURLs.isValidAttachmentURL(urlString)
}

/// Stripe-Checkout nur von vertrauenswürdigen Hosts öffnen.
static func isSafeStripeCheckoutURL(_ urlString: String) -> Bool {
  guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)),
     url.scheme?.lowercased() == "https",
     let host = url.host?.lowercased(), !host.isEmpty else { return false }
  return host == "checkout.stripe.com" || host.hasSuffix(".stripe.com")
}

/// Dateiname für lokale Exporte/Pfade bereinigen.
static func sanitizedFileName(_ name: String, maxLength: Int = 120) -> String {
  let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>\r\n")
  var s = name.components(separatedBy: forbidden).joined(separator: "_")
    .trimmingCharacters(in: .whitespacesAndNewlines)
  if s.isEmpty { s = "Export" }
  if s.count > maxLength {
    s = String(s.prefix(maxLength))
  }
  return s
}

/// Multipart-Header-Injection verhindern.
static func sanitizedMultipartFileName(_ name: String) -> String {
  sanitizedFileName(
    name.replacingOccurrences(of: "\"", with: "_")
      .replacingOccurrences(of: "\r", with: "")
      .replacingOccurrences(of: "\n", with: ""),
    maxLength: 200
  )
}

/// Dateigröße vor dem Einlesen prüfen.
static func validateFileSize(at url: URL) throws {
  let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
  guard values.isRegularFile != false else {
    throw FenlynineOSSecurityError.invalidFile
  }
  try validateDataSize(values.fileSize ?? 0)
}

/// Dateigröße für bereits geladene Daten (Upload-Pipeline).
static func validateDataSize(_ byteCount: Int) throws {
  guard byteCount > 0 else {
    throw FenlynineOSSecurityError.invalidFile
  }
  guard byteCount <= maxUploadBytes else {
    throw FenlynineOSSecurityError.fileTooLarge(maxMB: maxUploadBytes / (1024 * 1024))
  }
}
}

enum FenlynineOSSecurityError: LocalizedError {
case fileTooLarge(maxMB: Int)
case invalidFile
case unsafeURL

var errorDescription: String? {
  switch self {
  case .fileTooLarge(let maxMB):
    return "Datei zu groß (max. \(maxMB) MB)."
  case .invalidFile:
    return "Ungültige Datei."
  case .unsafeURL:
    return "URL aus Sicherheitsgründen blockiert."
  }
}
}

