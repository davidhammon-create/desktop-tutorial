import SwiftUI
struct TutorialView: View {
@Bindable private var appearance = AppearanceStore.shared
@AppStorage("fenlynineos_tutorial_gesehen_v3") private var gesehen = false
@AppStorage("fenlynineos_tutorial_aktiv") private var tutorialAktiv = true
let onFertig: () -> Void
@State private var schritt = 0
private struct Schritt {
  let titel: String
  let symbol: String
  let text: String
  let tipps: [String]
  let shortcut: String?
}
private let schritte: [Schritt] = [
  .init(titel: "Studio -- Ihr Arbeitsplatz",
     symbol: "scale.3d",
     text: "FenlynineOS Legal Suite startet im Studio. Die beschriftete Leiste links führt zu: Vorgänge, Lage, Team, Module, Wissen und System.",
     tipps: ["JI oben links öffnet das Hauptmenü", "Noir = Entscheidung · Atelier = Dokument"],
     shortcut: nil),
  .init(titel: "Vorgänge -- ein Objekt, viele Linsen",
     symbol: "square.stack.3d.up.fill",
     text: "Home der Produktion. Erfasst -> strukturiert -> bewertet -> entschieden -- Formelkaskade schreibt, KI schlägt vor.",
     tipps: ["nN neuer Vorgang", "nK Kommandofeld"],
     shortcut: "nN"),
  .init(titel: "Berufspflicht-Desk",
     symbol: "scalemass.fill",
     text: "BGH-Ausgangskontrolle, Mandatsannahme-Gate und KI-Endprüfung -- aus Rechtsprechung und Verbandsforderungen abgeleitet.",
     tipps: ["Abendkontrolle protokollieren", "Kein Aktiv ohne Annahme-Freigabe"],
     shortcut: nil),
  .init(titel: "Lagezentrale & Imperium",
     symbol: "rectangle.3.group.bubble.left.fill",
     text: "KonfliktRadar, Mandats-Pipeline, Honorare, beA-Check und Entscheidungsjournal -- Querschnitt über alle Module.",
     tipps: ["Praxisprofil steuert Checklisten", "Portfolio steckt in der Lage-Zone"],
     shortcut: nil),
  .init(titel: "Alle Module",
     symbol: "wrench.and.screwdriver.fill",
     text: "Die Zone 'Module' bündelt jede Funktion der Suite -- nach Tätigkeit sortiert, jede Zeile mit Erklärsatz, oben filterbar.",
     tipps: ["Fälle & Mandate (Lexara) · Zukunfts-Szenarien (Strategos)", "Chancen-Radar (Opportunisma) standalone = Pro"],
     shortcut: nil),
  .init(titel: "Fenster & Vergleich",
     symbol: "macwindow.on.rectangle",
     text: "Module als eigene Fenster oder nebeneinander im Vergleich -- ohne doppelte Navigationstitel.",
     tipps: ["Top-Bar \"Fenster\"", "⌘1-3 · ⌘V Vergleich"],
     shortcut: "⌘V"),
  .init(titel: "Schreibtisch",
     symbol: "rectangle.3.group.fill",
     text: "Fenstermodus, Kausalgraph, Verknüpfen, Advocatus und Verbundnetz -- systemweite Multiview.",
     tipps: ["Fokus-Kachel = voll interaktiv", "Mini-Kacheln wechseln den Fokus"],
     shortcut: nil),
  .init(titel: "KI & Tour steuern",
     symbol: "brain",
     text: "Globale oder modulweise KI-APIs. Diese Tour lässt sich dauerhaft abschalten und jederzeit erneut starten.",
     tipps: ["Einstellungen -> KI", "nnT öffnet die Tour"],
     shortcut: "⌘T")
]
var body: some View {
  VStack(spacing: 0) {
    HStack {
      Text("Geführte Tour")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Premium.textSoft)
      Spacer()
      AppearanceToggle()
      Button("Schließen") { abschliessen(markiert: false) }
        .buttonStyle(.plain)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Premium.textFaint)
    }
    .padding(16)
    Divider().overlay(Premium.hairline)
    let s = schritte[schritt]
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          Image(systemName: s.symbol)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Premium.action)
            .frame(width: 48, height: 48)
            .background(RoundedRectangle(cornerRadius: 12).fill(Premium.action.opacity(0.12)))
          VStack(alignment: .leading, spacing: 4) {
            Text("Schritt \(schritt + 1) von \(schritte.count)")
              .font(.system(size: 11, weight: .semibold))
              .foregroundStyle(Premium.textFaint)
            Text(s.titel)
              .font(.system(size: 20, weight: .bold))
              .foregroundStyle(Premium.text)
          }
       }
       Text(s.text)
         .font(.system(size: 14))
         .foregroundStyle(Premium.textSoft)
         .fixedSize(horizontal: false, vertical: true)
       VStack(alignment: .leading, spacing: 8) {
         ForEach(s.tipps, id: \.self) { tip in
           HStack(alignment: .top, spacing: 8) {
             Image(systemName: "checkmark.circle.fill")
               .font(.system(size: 12))
               .foregroundStyle(Premium.computed)
             Text(tip)
               .font(.system(size: 12))
               .foregroundStyle(Premium.text)
           }
         }
       }
       .padding(12)
       .frame(maxWidth: .infinity, alignment: .leading)
       .background(RoundedRectangle(cornerRadius: 10).fill(Premium.panel))
       .overlay(RoundedRectangle(cornerRadius: 10).stroke(Premium.hairline, lineWidth: 1))
       if let sc = s.shortcut {
         Label("Tastenkürzel: \(sc)", systemImage: "keyboard")
           .font(.system(size: 12, weight: .semibold, design: .monospaced))
           .foregroundStyle(Premium.action)
       }
       if schritt == schritte.count - 1 {
         Toggle("Tutorial automatisch beim Start zeigen", isOn: $tutorialAktiv)
           .toggleStyle(.switch)
           .font(.system(size: 12))
           .foregroundStyle(Premium.text)
       }
     }
     .padding(24)
   }
   Divider().overlay(Premium.hairline)
   HStack {
     Button("Zurück") {
       if schritt > 0 { schritt -= 1 }
     }
     .buttonStyle(.plain)
     .disabled(schritt == 0)
     .foregroundStyle(schritt == 0 ? Premium.textFaint : Premium.textSoft)
     Spacer()
     HStack(spacing: 5) {
       ForEach(0..<schritte.count, id: \.self) { i in
         Capsule()
           .fill(i == schritt ? Premium.action : Premium.hairline)
           .frame(width: i == schritt ? 14 : 6, height: 6)
       }
     }
     Spacer()
     Button(schritt == schritte.count - 1 ? "Tour beenden" : "Weiter") {
       if schritt == schritte.count - 1 {
         abschliessen(markiert: true)
       } else {
         schritt += 1
       }
     }
     .buttonStyle(.plain)
     .font(.system(size: 12, weight: .semibold))
     .foregroundStyle(Premium.onAction)
     .padding(.horizontal, 14).padding(.vertical, 8)
     .background(RoundedRectangle(cornerRadius: 8).fill(Premium.action))
     .keyboardShortcut(.defaultAction)
   }
   .padding(16)
 }
 .frame(width: 600, height: 620)
 .background(Premium.void)
 .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
 .overlay(RoundedRectangle(cornerRadius: 16).stroke(Premium.hairline, lineWidth: 1))
}
private func abschliessen(markiert: Bool) {
 if markiert { gesehen = true }
 onFertig()
}
}
