import SwiftUI
struct TutorialView: View {
@Bindable private var appearance = AppearanceStore.shared
@AppStorage("fenlynineos_tutorial_gesehen_v4") private var gesehen = false
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
  .init(titel: "Willkommen -- so ist die App aufgebaut",
     symbol: "sidebar.left",
     text: "Links stehen vier Bereiche: Arbeit, Analyse & Strategie, Kanzlei sowie KI & System. Jeder Bereich hat Kategorien mit farbigem Symbol. Ein Klick auf eine Kategorie zeigt, wofür sie da ist und wie man vorgeht; der Pfeil daneben klappt ihre Funktionen auf.",
     tipps: ["Jede Funktion ist in höchstens zwei Klicks erreichbar", "Suchfeld oben durchsucht alle Funktionen"],
     shortcut: nil),
  .init(titel: "Heute -- was als Nächstes ansteht",
     symbol: "house.fill",
     text: "„Heute“ zeigt die dringendsten Schritte über alle Akten: abgelaufene oder nahe Fristen zuerst, dann fehlende Grundlagen, Beweise und Bewertungen. Ein Klick öffnet die Akte im passenden Modul.",
     tipps: ["Rote Zahlen in der Seitenleiste = sofort erledigen", "Die Reihenfolge folgt der anwaltlichen Sorgfalt"],
     shortcut: nil),
  .init(titel: "Vorgänge & Akten",
     symbol: "tray.full.fill",
     text: "Jeder Auftrag beginnt als Vorgang: erfasst, strukturiert, bewertet, entschieden. Zahlen rechnet der Rechenkern; KI-Werte sind markiert und lassen sich bestätigen oder überschreiben.",
     tipps: ["⌘N neuer Vorgang", "⇧⌘N neuer Fall"],
     shortcut: "⌘N"),
  .init(titel: "Fristen & Berufspflichten",
     symbol: "calendar.badge.clock",
     text: "Fristen werden nach §§ 187 ff. BGB und § 222 ZPO mit Herleitung berechnet. Danach Bearbeitung zuweisen und vor Ablauf die Ausgangskontrolle durchführen.",
     tipps: ["Kategorie „Fristen & Aufgaben“ zeigt den Ablauf", "Berufspflichten: Ausgangskontrolle und Mandatsannahme"],
     shortcut: nil),
  .init(titel: "Kommandofeld -- alles mit der Tastatur",
     symbol: "command",
     text: "⌘K öffnet eine Eingabe für alles: Funktionen, Bereiche, Befehle, Vorgänge. „frist 14“ zeigt Fristen der nächsten 14 Tage, „§ 626“ verknüpfte Normen, „?“ unbestätigte KI-Werte.",
     tipps: ["↑↓ wählen · ↵ öffnen", "⌘↵ öffnet ein Modul als eigenes Fenster"],
     shortcut: "⌘K"),
  .init(titel: "Fenster & Vergleich",
     symbol: "macwindow.on.rectangle",
     text: "Jede Funktion lässt sich als eigenes Fenster öffnen -- über den Fenster-Knopf oben, das Fenstersymbol in jeder Kategorie oder ⌘↵ im Kommandofeld. Der Vergleich zeigt zwei oder drei Funktionen nebeneinander.",
     tipps: ["⌥⌘1–5 häufige Module als Fenster", "⌥⌘V Vergleichsfenster"],
     shortcut: "⌥⌘V"),
  .init(titel: "KI mit Nachweis",
     symbol: "checkmark.shield.fill",
     text: "Jede KI-Antwort wird ohne KI nachgeprüft: Gibt es die Paragraphen, stammen die Beträge aus Ihren Daten, welche Entscheidungen hat das Modell beigesteuert. Vor dem Versand an eine Cloud-KI werden Namen durch Platzhalter ersetzt.",
     tipps: ["Schild oben rechts = Prüfergebnis", "Büroklammer im Chat liest Dokumente lokal ein"],
     shortcut: nil),
  .init(titel: "Darstellung & Tour",
     symbol: "paintpalette.fill",
     text: "Drei Darstellungen, alle mit denselben Funktionen: Apple (Seitenleiste wie die Systemeinstellungen), Noir (dunkel) und Atelier (hell). Diese Tour lässt sich jederzeit erneut starten.",
     tipps: ["Umschalter oben rechts", "⇧⌘T öffnet die Tour"],
     shortcut: "⇧⌘T")
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
