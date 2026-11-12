import SwiftUI

struct CaseIntelligenceScoreView: View {
let fall: LegalCase

private var progress: (erledigt: Int, gesamt: Int, module: [(name: String, done: Bool)]) {
  KIResultStore.moduleFortschritt(fall: fall)
}

private var score: Int {
  guard progress.gesamt > 0 else { return 0 }
  return Int((Double(progress.erledigt) / Double(progress.gesamt)) * 100)
}

var body: some View {
  FenlynineOSCard(elevated: false) {
    HStack(spacing: 16) {
      FenlynineOSPrognoseRing(
        wert: score,
        groesse: 56,
        transparenz: .intelligenceScore(erledigt: progress.erledigt, gesamt: progress.gesamt, module: progress.module)
      )
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 4) {
          Text("FENLYNINEOS INTELLIGENCE")
            .font(AppleUIKitTokens.widgetTitle)
            .foregroundStyle(FenlynineOSDesignStore.shared.nutztVisionOSBlau ? FenlynineOSTheme.accent : FenlynineOSTheme.gold)
            .tracking(AppleUIKitTokens.widgetTitleTracking)
          FenlynineOSTransparenzInfoButton(inhalt: .intelligenceScore(
            erledigt: progress.erledigt,
            gesamt: progress.gesamt,
            module: progress.module
          ))
        }
        Text("\(progress.erledigt)/\(progress.gesamt) KI-Module aktiv")
          .font(.caption2)
          .foregroundStyle(FenlynineOSTheme.textSecondary)
        HStack(spacing: 5) {
          ForEach(progress.module, id: \.name) { m in
            RoundedRectangle(cornerRadius: 2)
              .fill(m.done ? (FenlynineOSDesignStore.shared.nutztVisionOSBlau ? FenlynineOSTheme.accent : FenlynineOSTheme.gold) : FenlynineOSTheme.border)
              .frame(width: 18, height: 4)
          }
        }
      }
      Spacer()
      FenlynineOSKIStatusBadge(status: score >= 50 ? .bereit : .deaktiviert)
    }
  }
  .padding(.horizontal, 16)
  .padding(.vertical, 6)
}
}

