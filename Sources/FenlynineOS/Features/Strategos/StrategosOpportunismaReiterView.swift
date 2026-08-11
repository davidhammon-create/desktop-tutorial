import SwiftUI

// MARK: - Opportunisma als optionaler Voll-Reiter in Strategos Enterprise
// Unverändertes Legacy-UI via eingebettetInStrategos: true

struct StrategosOpportunismaReiterView: View {
let szenario: StrategosScenario

var body: some View {
  VStack(alignment: .leading, spacing: 0) {
    HStack(spacing: 10) {
      Image(systemName: "chart.line.uptrend.xyaxis")
        .font(.caption.bold())
        .foregroundStyle(.red)
      Text("Opportunisma")
        .font(.subheadline.bold())
      Text("OPTIONAL")
        .font(.system(size: 8, weight: .black))
        .foregroundStyle(.orange)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.15), in: Capsule())
      Text("·")
        .foregroundStyle(.tertiary)
      Text("Unternehmenslage · Fragebogen · Module")
        .font(.caption2)
        .foregroundStyle(.secondary)
      Spacer()
      Text(szenario.titel)
        .font(.caption2.bold())
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    .padding(.bottom, 12)

    OpportunismaView(
      initialStrategosId: szenario.id,
      eingebettetInStrategos: true
    )
    .id(szenario.id ?? szenario.titel)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
}
}

