import SwiftUI

enum ComplianceStatus: String {
case konform
case pruefen
case ungeprueft

var label: String {
  switch self {
  case .konform: return "DSGVO-konform"
  case .pruefen: return "Prüfung empfohlen"
  case .ungeprueft: return "KI-Prüfung ausstehend"
  }
}

var symbol: String {
  switch self {
  case .konform: return "checkmark.shield.fill"
  case .pruefen: return "exclamationmark.shield.fill"
  case .ungeprueft: return "questionmark.shield.fill"
  }
}

var farbe: Color {
  switch self {
  case .konform: return .green
  case .pruefen: return .orange
  case .ungeprueft: return .gray
  }
}
}

enum ComplianceStatusHelper {
static func status(for argument: Argument) -> ComplianceStatus {
  guard argument.ki_strength != nil else { return .ungeprueft }
  let disc = abs(Double(argument.strength) - (argument.ki_strength ?? Double(argument.strength)))
  if disc >= 4 { return .pruefen }
  return .konform
}

static func status(for beweis: Evidence) -> ComplianceStatus {
  guard beweis.ki_weight != nil else { return .ungeprueft }
  let disc = abs(Double(beweis.weight) - (beweis.ki_weight ?? Double(beweis.weight)))
  if disc >= 4 { return .pruefen }
  return .konform
}
}

struct ComplianceStatusBadge: View {
let status: ComplianceStatus

var body: some View {
  Label(status.label, systemImage: status.symbol)
    .font(.system(size: 9, weight: .semibold))
    .foregroundStyle(status.farbe)
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(status.farbe.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
    .overlay(RoundedRectangle(cornerRadius: 4).stroke(status.farbe.opacity(0.25), lineWidth: 0.5))
    .help(status.label)
}
}

