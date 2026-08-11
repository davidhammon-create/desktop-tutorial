import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// IMPERIUM -- Macht, Einfluss & Steuerung (letzter fallrelevanter Reiter)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Eigene Visualisierungen (keine Opportunisma-Kopie):
// · Macht-Gauge -- halbrunde Machtbalance-Anzeige mit Nadel
// · Machtbilanz -- Tornado-Diagramm eigen « Gegner über 7 Dimensionen
// · Szenario-Fächer -- Monte-Carlo-Perzentilfächer über die Zugfolge
// · Hebel-Matrix -- Steuerbarkeit x Eintritts-Wk (Blasengröße = Nutzen)
// · Ressourcen-Hebelwerk -- verfügbar vs. aktivierbar, Rechtsgrundlagen
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Farbwelt

enum ImperiumFarbe {
static var eigen: Color { Color(red: 0.25, green: 0.60, blue: 1.0) }
static var gegner: Color { Color(red: 0.95, green: 0.36, blue: 0.32) }
static var gold: Color { Color(red: 0.85, green: 0.66, blue: 0.28) }
static var gruen: Color { Color(red: 0.20, green: 0.74, blue: 0.44) }
static var flaeche: Color { FenlynineOSTheme.surface }
}

// MARK: - Haupt-Tab

struct TabMachtEinfluss: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var store: MachtEinflussStore
@State private var optionInBearbeitung: MachtOption? = nil
@State private var ressourceInBearbeitung: MachtRessource? = nil
@State private var neueOptionAnlegen = false
@State private var neueRessourceAnlegen = false

init(viewModel: CaseDetailViewModel, kiMode: Bool = true) {
  self.viewModel = viewModel
  self.kiMode = kiMode
  _store = State(initialValue: MachtEinflussStore(caseId: viewModel.caseId))
}

var body: some View {
  VStack(alignment: .leading, spacing: 14) {
    kopfzeile

    if store.zustand.optionen.isEmpty && store.zustand.ressourcen.isEmpty && (store.aktiverStrang?.ereignisse.isEmpty ?? true) {
      leererZustand
    } else {
      zielzeile
      kpiLeiste
      machtbilanzSektion
      simulationSektion
      KausalstrangSektion(store: store, viewModel: viewModel, kiMode: kiMode)
      optionenSektion
      ressourcenSektion
      kiSektion
    }

    if let fehler = store.kiFehler {
      Label(fehler, systemImage: "exclamationmark.triangle.fill")
        .font(.caption)
        .foregroundStyle(Premium.critical)
    }
  }
  .frame(maxWidth: .infinity, alignment: .topLeading)
  .sheet(item: $optionInBearbeitung) { option in
    MachtOptionEditor(option: option) { neu in
      if let idx = store.zustand.optionen.firstIndex(where: { $0.id == neu.id }) {
        store.zustand.optionen[idx] = neu
      } else {
        store.zustand.optionen.append(neu)
      }
      store.simuliere(); store.speichern()
    } onDelete: { id in
      store.zustand.optionen.removeAll { $0.id == id }
      store.simuliere(); store.speichern()
    }
  }
  .sheet(item: $ressourceInBearbeitung) { ressource in
    MachtRessourceEditor(ressource: ressource) { neu in
      if let idx = store.zustand.ressourcen.firstIndex(where: { $0.id == neu.id }) {
        store.zustand.ressourcen[idx] = neu
      } else {
        store.zustand.ressourcen.append(neu)
      }
      store.simuliere(); store.speichern()
    } onDelete: { id in
      store.zustand.ressourcen.removeAll { $0.id == id }
      store.simuliere(); store.speichern()
    }
  }
}

// nn Kopf nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

private var kopfzeile: some View {
  HStack(alignment: .center, spacing: 10) {
    VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 8) {
        Image(systemName: "crown.fill")
         .foregroundStyle(ImperiumFarbe.gold)
       Text("Imperium -- Macht, Einfluss & Steuerung")
         .font(.system(size: 16, weight: .bold))
     }
     Text("Wie viel Macht besitzen wir in diesem Fall -- und mit welchen legalen Hebeln lassen sich Ereignisse herbeiführen, verhindern oder beeinflussen?")
       .font(.system(size: 11))
       .foregroundStyle(.secondary)
   }
   Spacer()
   Button {
     store.uebernehmeFalldaten(viewModel: viewModel)
   } label: {
     Label("Aus Falldaten ableiten", systemImage: "function")
   }
   .help("Deterministische Formelableitung aus Argumenten, Beweisen, Fristen und Rechtslücken -- ohne KI.")

   if kiMode {
     Button {
       Task { await store.kiAnalyse(viewModel: viewModel) }
     } label: {
       if store.kiLaeuft {
         HStack(spacing: 6) {
           ProgressView().controlSize(.small)
           Text("KI analysiert…")
         }
       } else {
         Label("KI-Tiefenanalyse", systemImage: "brain.filled.head.profile")
       }
     }
     .disabled(store.kiLaeuft)
     .buttonStyle(.borderedProminent)
   }
 }
}

private var leererZustand: some View {
 VStack(spacing: 14) {
   Image(systemName: "crown")
     .font(.system(size: 34, weight: .light))
     .foregroundStyle(ImperiumFarbe.gold)
   Text("Machtanalyse noch nicht aufgebaut")
     .font(.system(size: 14, weight: .semibold))
   Text("Leite Machtprofil, Handlungsoptionen und Ressourcen automatisch aus den Falldaten ab -- oder lass die KI eine Tiefenanalyse mit konkreten Rechtsgrundlagen erstellen. Danach kannst du alles manuell verfeinern und live simulieren.")
     .font(.system(size: 12))
     .foregroundStyle(.secondary)
     .multilineTextAlignment(.center)
     .frame(maxWidth: 520)
   HStack(spacing: 10) {
     Button {
       store.uebernehmeFalldaten(viewModel: viewModel)
     } label: {
       Label("Aus Falldaten ableiten", systemImage: "function")
     }
     if kiMode {
       Button {
         Task { await store.kiAnalyse(viewModel: viewModel) }
       } label: {
         Label("KI-Tiefenanalyse starten", systemImage: "brain.filled.head.profile")
       }
       .buttonStyle(.borderedProminent)
       .disabled(store.kiLaeuft)
     }
   }
   if store.kiLaeuft { ProgressView().controlSize(.small) }
 }
 .frame(maxWidth: .infinity)
 .padding(.vertical, 44)
 .background(FenlynineOSTheme.surface, in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(FenlynineOSTheme.border, lineWidth: 1))
}

// nn Ziel & Ausgangslage nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

private var zielzeile: some View {
 HStack(spacing: 12) {
   Image(systemName: "target")
     .foregroundStyle(FenlynineOSTheme.accent)
   TextField("Zielereignis / Prozessziel (z. B. „Einstweilige Verfügung erwirken")", text: Binding(
     get: { store.zustand.ziel },
     set: { store.zustand.ziel = $0; store.speichern() }
   ))
   .textFieldStyle(.plain)
   .font(.system(size: 12, weight: .medium))

   Divider().frame(height: 16)

   Text("Ausgangslage")
     .font(.system(size: 11))
     .foregroundStyle(.secondary)
   Slider(value: Binding(
     get: { store.zustand.baseline },
     set: { store.zustand.baseline = $0; store.simuliere(); store.speichern() }
   ), in: 0.05...0.95)
   .frame(width: 130)
   Text("\(Int(store.zustand.baseline * 100)) %")
     .font(.system(size: 11, weight: .bold).monospacedDigit())
     .frame(width: 38, alignment: .trailing)
   ImperiumFormelInfo(
     titel: "Ausgangslage",
     formel: "Start-Wahrscheinlichkeit der Zielerreichung ohne eigene Züge.\nVorbelegt mit der Fallprognose; manuell justierbar.\nGeht als Startwert in jede Monte-Carlo-Simulation ein."
   )
 }
 .padding(.horizontal, 12)
 .padding(.vertical, 8)
 .background(FenlynineOSTheme.surface, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(FenlynineOSTheme.border, lineWidth: 1))
}

// nn KPI-Leiste nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

private var kpiLeiste: some View {
 let k = store.kennzahlen
 return HStack(spacing: 10) {
   ImperiumKPI(
     titel: "Macht-Index", wert: k.machtIndex, symbol: "crown.fill",
     farbe: farbe(fuer: k.machtIndex),
     formel: "50 + 50 · S(Gewichtn · (Eigenn - Gegnern)) / S Gewichtn\nGewichtete Machtbalance über alle 7 Dimensionen.\n> 50 = eigene Übermacht, < 50 = Gegner dominiert."
   )
   ImperiumKPI(
     titel: "Steuerbarkeit", wert: k.steuerbarkeit, symbol: "slider.horizontal.3",
     farbe: farbe(fuer: k.steuerbarkeit),
     formel: "Ø(Beeinflussbarkeit · Nutzbarkeit) aktiver Optionen · Machtfaktor\nMachtfaktor = 0,8…1,2 aus dem Macht-Index.\nWie stark lässt sich der Verlauf aktiv kontrollieren?"
   )
   ImperiumKPI(
     titel: "Ziel-Wahrscheinlichkeit", wert: k.zielWahrscheinlichkeit, symbol: "target",
     farbe: farbe(fuer: k.zielWahrscheinlichkeit),
     formel: "Anteil der Monte-Carlo-Läufe (n=\(store.simulation.iterationen)) mit End-Score >= 50 %.\nSeeded Simulation -- reproduzierbar und manipulationsfrei."
   )
   ImperiumKPI(
     titel: "Einfluss-Reichweite", wert: k.einflussReichweite, symbol: "antenna.radiowaves.left.and.right",
     farbe: farbe(fuer: k.einflussReichweite),
     formel: "100 · (1 - Pi(1 - Kraftn · 0,6))\nKraftn = (verfügbar + ½·aktivierbar) · Hebelwirkung.\nSättigende Abdeckung durch Ressourcen & Rechtsgrundlagen."
   )
   ImperiumKPI(
     titel: "Folgen-Sicherheit", wert: k.folgenSicherheit, symbol: "shield.checkerboard",
     farbe: farbe(fuer: k.folgenSicherheit),
     formel: "Ø(0,7 · Folgen-Handhabbarkeit + 0,3 · Reversibilität)\nWie gut sind Konsequenzen der Züge beherrschbar und rückholbar?"
   )
 }
}

private func farbe(fuer wert: Double) -> Color {
 if wert >= 65 { return ImperiumFarbe.gruen }
 if wert >= 45 { return ImperiumFarbe.gold }
 return ImperiumFarbe.gegner
}

// nn Sektionen nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

private var machtbilanzSektion: some View {
 ImperiumSektion(
   titel: "Machtbilanz",
   symbol: "scalemass.fill",
   untertitel: "Eigene Machtquellen gegen die des Gegners -- pro Dimension justierbar",
   formel: "Tornado-Diagramm: Balken links = Gegnermacht, rechts = eigene Macht.\nNetto-Marker = Eigen - Gegner. Gewicht steuert den Einfluss der Dimension auf den Macht-Index."
 ) {
   HStack(alignment: .top, spacing: 18) {
     MachtGaugeView(machtIndex: store.kennzahlen.machtIndex)
       .frame(width: 210, height: 150)
     MachtTornadoView(store: store)
       .frame(maxWidth: .infinity)
   }
 }
}

private var simulationSektion: some View {
 ImperiumSektion(
   titel: "Szenario-Fächer -- Monte-Carlo über die Zugfolge",
   symbol: "chart.line.uptrend.xyaxis",
   untertitel: "\(store.simulation.iterationen) Simulationsläufe · Züge in Netto-Score-Reihenfolge",
   formel: "Jeder Lauf spielt die aktiven Optionen als Zugfolge:\n· Zug greift mit p = Eintritts-Wk · Machtfaktor\n· Wirkung = Nutzbarkeit · Beeinflussbarkeit · 0,28 (± Rauschen)\n· Misslungener Zug (cid:222) Folge mit p = 1 - Handhabbarkeit (Rückschlag, ggf. Eskalation)\nFächer = 10.-90. Perzentil des Ziel-Scores nach jedem Zug."
 ) {
   VStack(alignment: .leading, spacing: 12) {
     HStack(spacing: 10) {
       ImperiumChip(
         text: "Zielerreichung \(Int(store.simulation.zielWk * 100)) %",
         farbe: farbe(fuer: store.simulation.zielWk * 100)
       )
       ImperiumChip(
         text: "Eskalationsrisiko \(Int(store.simulation.eskalationsWk * 100)) %",
         farbe: store.simulation.eskalationsWk > 0.25 ? ImperiumFarbe.gegner : .secondary
       )
       Spacer()
       Text("Median · 25-75 % · 10-90 %")
         .font(.system(size: 10))
         .foregroundStyle(.tertiary)
     }
     SzenarioFaecherView(ergebnis: store.simulation)
       .frame(height: 220)
     if store.simulation.schritte.count > 1 {
       zugLegende
     }
     HStack(alignment: .top, spacing: 14) {
       VStack(alignment: .leading, spacing: 4) {
         Text("Verteilung der Endzustände")
           .font(.system(size: 11, weight: .semibold))
         EndVerteilungView(werte: store.simulation.endVerteilung)
           .frame(height: 70)
       }
       .frame(maxWidth: .infinity)
     }
   }
 }
}

private var zugLegende: some View {
 ScrollView(.horizontal, showsIndicators: false) {
   HStack(spacing: 8) {
     ForEach(store.simulation.schritte.dropFirst()) { schritt in
       HStack(spacing: 5) {
         Text("\(schritt.index)")
           .font(.system(size: 9, weight: .bold))
           .frame(width: 15, height: 15)
           .background(Circle().fill(FenlynineOSTheme.accent.opacity(0.18)))
         Text(schritt.label)
           .font(.system(size: 10))
           .lineLimit(1)
       }
       .padding(.horizontal, 8)
       .padding(.vertical, 4)
       .background(FenlynineOSTheme.surfaceElevated, in: Capsule())
     }
   }
 }
}

private var optionenSektion: some View {
 ImperiumSektion(
   titel: "Handlungsoptionen & Hebel-Matrix",
   symbol: "square.grid.2x2.fill",
   untertitel: "Steuerbarkeit x Eintritts-Wahrscheinlichkeit · Blasengröße = erwarteter Nutzen",
   formel: "Hebelwirkung = Eintritts-Wk · Beeinflussbarkeit\nSteuerbarkeit = Beeinflussbarkeit · Nutzbarkeit\nNutzen = Eintritts-Wk · Nutzbarkeit · (0,5 + 0,5·Beeinflussbarkeit)\nRestrisiko = (0,6·(1-Handhabbarkeit) + 0,4·(1-Reversibilität)) · Aufwandsfaktor\nNetto-Score = Nutzen - 0,5 · Restrisiko",
   aktion: {
     Button {
       optionInBearbeitung = MachtOption(titel: "")
     } label: {
       Label("Option", systemImage: "plus")
     }
   }
 ) {
   VStack(alignment: .leading, spacing: 14) {
     HebelMatrixView(optionen: store.zustand.optionen.filter(\.aktiv))
       .frame(height: 250)
     machtQuadrantLegende
     optionKarten
   }
 }
}

private var machtQuadrantLegende: some View {
 HStack(spacing: 14) {
   legendePunkt("Machtzone -- hohe Kontrolle, hohe Wk.", ImperiumFarbe.gruen)
   legendePunkt("Chancenzone -- hohe Wk., wenig Kontrolle", ImperiumFarbe.gold)
   legendePunkt("Aufbauzone -- Kontrolle da, Wk. steigern", ImperiumFarbe.eigen)
   legendePunkt("Beobachten -- weder noch", .secondary)
 }
}

private func legendePunkt(_ text: String, _ farbe: Color) -> some View {
 HStack(spacing: 4) {
   Circle().fill(farbe).frame(width: 7, height: 7)
   Text(text).font(.system(size: 9.5)).foregroundStyle(.secondary)
 }
}

private var optionKarten: some View {
 let sortiert = store.zustand.optionen.sorted { $0.nettoScore > $1.nettoScore }
 return LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 10)], spacing: 10) {
   ForEach(Array(sortiert.enumerated()), id: \.element.id) { index, option in
     MachtOptionKarte(
       option: option,
       rang: index + 1,
       onToggle: {
         if let idx = store.zustand.optionen.firstIndex(where: { $0.id == option.id }) {
           store.zustand.optionen[idx].aktiv.toggle()
           store.simuliere(); store.speichern()
         }
       },
       onEdit: { optionInBearbeitung = option }
     )
   }
 }
}

private var ressourcenSektion: some View {
 ImperiumSektion(
   titel: "Ressourcen-Hebelwerk",
   symbol: "wrench.and.screwdriver.fill",
   untertitel: "Was wir haben -- und was wir aktivieren könnten (inkl. Rechtsgrundlagen)",
   formel: "Effektive Kraft = (verfügbar + ½ · (Potenzial - verfügbar)) · Hebelwirkung\nHeller Balken = heute verfügbar, schraffierter Anteil = aktivierbares Potenzial.",
   aktion: {
     Button {
       ressourceInBearbeitung = MachtRessource(titel: "")
     } label: {
       Label("Ressource", systemImage: "plus")
     }
   }
 ) {
   LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 10)], spacing: 10) {
     ForEach(store.zustand.ressourcen.sorted { $0.effektiveKraft > $1.effektiveKraft }) { ressource in
       MachtRessourceKarte(ressource: ressource) {
         ressourceInBearbeitung = ressource
       }
     }
   }
 }
}

@ViewBuilder
private var kiSektion: some View {
 if !store.zustand.kiZusammenfassung.isEmpty {
   ImperiumSektion(
     titel: "KI-Lagebeurteilung",
     symbol: "brain.filled.head.profile",
     untertitel: store.zustand.kiZeitpunkt.map { "Stand: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "",
     formel: "Strukturierte KI-Analyse (Machtprofil, Optionen, Ressourcen) -- orange markierte Einträge stammen aus der KI und sind unbestätigt, bis du sie bearbeitest."
   ) {
     Text(store.zustand.kiZusammenfassung)
       .font(.system(size: 12))
       .lineSpacing(4)
       .textSelection(.enabled)
   }
 }
}
}

// MARK: - Sektion-Rahmen

struct ImperiumSektion<Inhalt: View, Aktion: View>: View {
let titel: String
let symbol: String
var untertitel: String = ""
var formel: String = ""
@ViewBuilder var aktion: () -> Aktion
@ViewBuilder var inhalt: () -> Inhalt

init(
 titel: String,
 symbol: String,
 untertitel: String = "",
 formel: String = "",
 @ViewBuilder aktion: @escaping () -> Aktion,
 @ViewBuilder inhalt: @escaping () -> Inhalt
) {
 self.titel = titel
 self.symbol = symbol
 self.untertitel = untertitel
 self.formel = formel
 self.aktion = aktion
 self.inhalt = inhalt
}

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack(alignment: .firstTextBaseline, spacing: 8) {
     Image(systemName: symbol)
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(FenlynineOSTheme.accent)
     VStack(alignment: .leading, spacing: 2) {
       Text(titel).font(.system(size: 13, weight: .bold))
       if !untertitel.isEmpty {
         Text(untertitel).font(.system(size: 10.5)).foregroundStyle(.secondary)
       }
     }
     if !formel.isEmpty {
       ImperiumFormelInfo(titel: titel, formel: formel)
     }
     Spacer()
     aktion()
       .controlSize(.small)
   }
   inhalt()
 }
 .padding(14)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(FenlynineOSTheme.surface, in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(FenlynineOSTheme.border, lineWidth: 1))
}
}

extension ImperiumSektion where Aktion == EmptyView {
init(
 titel: String,
 symbol: String,
 untertitel: String = "",
 formel: String = "",
 @ViewBuilder inhalt: @escaping () -> Inhalt
) {
 self.init(titel: titel, symbol: symbol, untertitel: untertitel, formel: formel, aktion: { EmptyView() }, inhalt: inhalt)
}
}

// MARK: - Formel-Transparenz

struct ImperiumFormelInfo: View {
let titel: String
let formel: String
@State private var offen = false

var body: some View {
 Button {
   offen.toggle()
 } label: {
   Image(systemName: "info.circle")
     .font(.system(size: 10.5))
     .foregroundStyle(.tertiary)
 }
 .buttonStyle(.plain)
 .popover(isPresented: $offen, arrowEdge: .bottom) {
   VStack(alignment: .leading, spacing: 8) {
     Label(titel, systemImage: "function")
       .font(.system(size: 12, weight: .bold))
     Text(formel)
       .font(.system(size: 11).monospaced())
       .lineSpacing(3)
       .foregroundStyle(.secondary)
   }
   .padding(14)
   .frame(maxWidth: 380, alignment: .leading)
 }
 .help("Berechnungsgrundlage anzeigen")
}
}

// MARK: - KPI-Kachel

struct ImperiumKPI: View {
let titel: String
let wert: Double
let symbol: String
let farbe: Color
let formel: String

var body: some View {
 VStack(alignment: .leading, spacing: 6) {
   HStack(spacing: 5) {
     Image(systemName: symbol)
       .font(.system(size: 10))
       .foregroundStyle(farbe)
     Text(titel)
       .font(.system(size: 10, weight: .semibold))
       .foregroundStyle(.secondary)
       .lineLimit(1)
     Spacer(minLength: 0)
     ImperiumFormelInfo(titel: titel, formel: formel)
   }
   HStack(alignment: .lastTextBaseline, spacing: 3) {
     Text("\(Int(wert.rounded()))")
       .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
       .foregroundStyle(farbe)
     Text("/100")
       .font(.system(size: 10))
       .foregroundStyle(.tertiary)
   }
   GeometryReader { geo in
     ZStack(alignment: .leading) {
       Capsule().fill(FenlynineOSTheme.border.opacity(0.5))
       Capsule()
         .fill(farbe)
         .frame(width: max(3, geo.size.width * wert / 100))
     }
   }
   .frame(height: 4)
 }
 .padding(10)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(FenlynineOSTheme.surface, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(FenlynineOSTheme.border, lineWidth: 1))
}
}

struct ImperiumChip: View {
let text: String
let farbe: Color

var body: some View {
 Text(text)
   .font(.system(size: 10.5, weight: .semibold).monospacedDigit())
   .foregroundStyle(farbe)
   .padding(.horizontal, 9)
   .padding(.vertical, 4)
   .background(farbe.opacity(0.12), in: Capsule())
   .overlay(Capsule().stroke(farbe.opacity(0.35), lineWidth: 1))
}
}

// MARK: - Macht-Gauge (halbrunde Balance-Anzeige)

struct MachtGaugeView: View {
let machtIndex: Double // 0…100

var body: some View {
 VStack(spacing: 4) {
   Canvas { context, size in
     let cx = size.width / 2
     let cy = size.height - 14
     let radius = min(size.width / 2 - 12, size.height - 30)

     // Bogensegmente: rot (Gegner) -> gold (ausgeglichen) -> grün (Übermacht)
     let segmente: [(von: Double, bis: Double, farbe: Color)] = [
       (180, 250, ImperiumFarbe.gegner),
       (250, 290, ImperiumFarbe.gold),
       (290, 360, ImperiumFarbe.gruen)
     ]
     for seg in segmente {
       var pfad = Path()
       pfad.addArc(
         center: CGPoint(x: cx, y: cy),
         radius: radius,
         startAngle: .degrees(seg.von),
         endAngle: .degrees(seg.bis),
         clockwise: false
       )
       context.stroke(pfad, with: .color(seg.farbe.opacity(0.85)), style: StrokeStyle(lineWidth: 10, lineCap: .butt))
     }

     // Skalenstriche
     for schritt in stride(from: 0.0, through: 100.0, by: 25.0) {
       let winkel = (180 + schritt / 100 * 180) * .pi / 180
       let p1 = CGPoint(x: cx + cos(winkel) * (radius - 10), y: cy + sin(winkel) * (radius - 10))
       let p2 = CGPoint(x: cx + cos(winkel) * (radius - 16), y: cy + sin(winkel) * (radius - 16))
       var strich = Path()
       strich.move(to: p1); strich.addLine(to: p2)
       context.stroke(strich, with: .color(.secondary.opacity(0.5)), lineWidth: 1)
     }

     // Nadel
     let nadelWinkel = (180 + machtIndex / 100 * 180) * .pi / 180
     let spitze = CGPoint(x: cx + cos(nadelWinkel) * (radius - 18), y: cy + sin(nadelWinkel) * (radius - 18))
     var nadel = Path()
     nadel.move(to: CGPoint(x: cx, y: cy))
     nadel.addLine(to: spitze)
     context.stroke(nadel, with: .color(.primary), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
     context.fill(
       Path(ellipseIn: CGRect(x: cx - 4, y: cy - 4, width: 8, height: 8)),
       with: .color(.primary)
     )
   }
   .overlay(alignment: .bottom) {
     VStack(spacing: 0) {
       Text("\(Int(machtIndex.rounded()))")
         .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
       Text(bewertung)
         .font(.system(size: 9, weight: .semibold))
         .foregroundStyle(.secondary)
     }
     .padding(.bottom, 0)
   }
   HStack {
     Text("Gegner dominiert").font(.system(size: 8.5)).foregroundStyle(ImperiumFarbe.gegner)
     Spacer()
     Text("Eigene Übermacht").font(.system(size: 8.5)).foregroundStyle(ImperiumFarbe.gruen)
   }
   .padding(.horizontal, 4)
 }
}

private var bewertung: String {
 switch machtIndex {
 case ..<35: return "UNTERLEGEN"
 case ..<48: return "IM NACHTEIL"
 case ..<55: return "AUSGEGLICHEN"
 case ..<70: return "IM VORTEIL"
 default: return "DOMINANT"
 }
}
}

// MARK: - Machtbilanz-Tornado

struct MachtTornadoView: View {
let store: MachtEinflussStore
@State private var bearbeiteteDimension: MachtDimension? = nil

var body: some View {
 VStack(spacing: 5) {
   HStack {
     Text("GEGNER").font(.system(size: 8.5, weight: .bold)).foregroundStyle(ImperiumFarbe.gegner)
     Spacer()
     Text("EIGEN").font(.system(size: 8.5, weight: .bold)).foregroundStyle(ImperiumFarbe.eigen)
   }
   ForEach(store.zustand.dimensionen) { dim in
     MachtTornadoZeile(wert: dim, aktivBearbeitung: bearbeiteteDimension == dim.dimension) {
       bearbeiteteDimension = dim.dimension
     }
     .popover(
       isPresented: Binding(
         get: { bearbeiteteDimension == dim.dimension },
         set: { if !$0 { bearbeiteteDimension = nil } }
       ),
       arrowEdge: .trailing
     ) {
       MachtDimensionEditor(store: store, dimension: dim.dimension)
     }
   }
   Text("Zeile anklicken zum Justieren · Gewicht steuert Einfluss auf den Macht-Index")
     .font(.system(size: 9))
     .foregroundStyle(.tertiary)
     .frame(maxWidth: .infinity, alignment: .center)
     .padding(.top, 2)
 }
}
}

struct MachtTornadoZeile: View {
let wert: MachtDimensionWert
var aktivBearbeitung: Bool
let onTap: () -> Void

var body: some View {
 Button(action: onTap) {
   HStack(spacing: 8) {
     Image(systemName: wert.dimension.symbol)
       .font(.system(size: 10))
       .foregroundStyle(.secondary)
       .frame(width: 16)
     Text(wert.dimension.rawValue)
       .font(.system(size: 10.5, weight: .medium))
       .frame(width: 128, alignment: .leading)
       .lineLimit(1)

     GeometryReader { geo in
       let mitte = geo.size.width / 2
       ZStack(alignment: .leading) {
         // Mittelachse
         Rectangle()
           .fill(FenlynineOSTheme.border)
           .frame(width: 1)
           .offset(x: mitte)
         // Gegner (links)
         Capsule()
           .fill(ImperiumFarbe.gegner.opacity(0.75))
           .frame(width: mitte * wert.gegner, height: 9)
           .offset(x: mitte - mitte * wert.gegner)
         // Eigen (rechts)
         Capsule()
           .fill(ImperiumFarbe.eigen.opacity(0.85))
           .frame(width: mitte * wert.eigen, height: 9)
           .offset(x: mitte)
         // Netto-Marker
         Circle()
           .fill(wert.netto >= 0 ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
           .frame(width: 7, height: 7)
           .offset(x: mitte + mitte * wert.netto - 3.5)
       }
       .frame(height: 9)
       .frame(maxHeight: .infinity, alignment: .center)
     }
     .frame(height: 16)

     Text(String(format: "%+.0f", wert.netto * 100))
       .font(.system(size: 10, weight: .bold).monospacedDigit())
       .foregroundStyle(wert.netto >= 0 ? ImperiumFarbe.gruen : ImperiumFarbe.gegner)
       .frame(width: 30, alignment: .trailing)
     Text("x\(String(format: "%.1f", wert.gewicht))")
       .font(.system(size: 9).monospacedDigit())
       .foregroundStyle(.tertiary)
       .frame(width: 28, alignment: .trailing)
   }
   .padding(.vertical, 2)
   .padding(.horizontal, 4)
   .background(
     RoundedRectangle(cornerRadius: 6)
       .fill(aktivBearbeitung ? FenlynineOSTheme.accent.opacity(0.08) : Color.clear)
   )
   .contentShape(Rectangle())
 }
 .buttonStyle(.plain)
}
}

struct MachtDimensionEditor: View {
let store: MachtEinflussStore
let dimension: MachtDimension

private var index: Int? {
 store.zustand.dimensionen.firstIndex { $0.dimension == dimension }
}

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   Label(dimension.rawValue, systemImage: dimension.symbol)
     .font(.system(size: 12, weight: .bold))
   if let idx = index {
     ImperiumProzentSlider(
       label: "Eigene Stärke",
       farbe: ImperiumFarbe.eigen,
       wert: Binding(
         get: { store.zustand.dimensionen[idx].eigen },
         set: { store.zustand.dimensionen[idx].eigen = $0; store.simuliere(); store.speichern() }
       )
     )
     ImperiumProzentSlider(
       label: "Gegnerstärke",
       farbe: ImperiumFarbe.gegner,
       wert: Binding(
         get: { store.zustand.dimensionen[idx].gegner },
         set: { store.zustand.dimensionen[idx].gegner = $0; store.simuliere(); store.speichern() }
       )
     )
     HStack {
       Text("Gewicht").font(.system(size: 11))
       Slider(value: Binding(
         get: { store.zustand.dimensionen[idx].gewicht },
         set: { store.zustand.dimensionen[idx].gewicht = $0; store.simuliere(); store.speichern() }
       ), in: 0.2...2.0)
       Text("x\(String(format: "%.1f", store.zustand.dimensionen[idx].gewicht))")
         .font(.system(size: 11, weight: .semibold).monospacedDigit())
         .frame(width: 32, alignment: .trailing)
     }
   }
 }
 .padding(14)
 .frame(width: 300)
}
}

// MARK: - Szenario-Fächer (Monte-Carlo-Fan)

struct SzenarioFaecherView: View {
let ergebnis: MachtSimulationsErgebnis

var body: some View {
 Canvas { context, size in
   let schritte = ergebnis.schritte
   guard schritte.count > 1 else {
     let text = Text("Mindestens eine aktive Handlungsoption nötig, um die Zugfolge zu simulieren.")
       .font(.system(size: 11)).foregroundStyle(.secondary)
     context.draw(text, at: CGPoint(x: size.width / 2, y: size.height / 2))
     return
   }

   let links: CGFloat = 34
   let rechts: CGFloat = 10
   let oben: CGFloat = 8
   let unten: CGFloat = 22
   let plotB = size.width - links - rechts
   let plotH = size.height - oben - unten

   func x(_ i: Int) -> CGFloat { links + plotB * CGFloat(i) / CGFloat(schritte.count - 1) }
   func y(_ v: Double) -> CGFloat { oben + plotH * (1 - CGFloat(v)) }

   // Gitter + y-Beschriftung
   for stufe in [0.0, 0.25, 0.5, 0.75, 1.0] {
     var linie = Path()
     linie.move(to: CGPoint(x: links, y: y(stufe)))
     linie.addLine(to: CGPoint(x: size.width - rechts, y: y(stufe)))
     let istZiel = stufe == 0.5
     context.stroke(
       linie,
       with: .color(istZiel ? ImperiumFarbe.gold.opacity(0.6) : Color.secondary.opacity(0.15)),
       style: StrokeStyle(lineWidth: istZiel ? 1.2 : 0.8, dash: istZiel ? [4, 3] : [])
     )
     context.draw(
       Text("\(Int(stufe * 100))%").font(.system(size: 8.5)).foregroundStyle(.secondary),
       at: CGPoint(x: links - 16, y: y(stufe))
     )
   }

   // Fächer-Bänder
   func band(_ lo: (MachtSimulationsErgebnis.Schritt) -> Double, _ hi: (MachtSimulationsErgebnis.Schritt) -> Double, opazitaet: Double) {
     var pfad = Path()
     pfad.move(to: CGPoint(x: x(0), y: y(hi(schritte[0]))))
     for (i, s) in schritte.enumerated() { pfad.addLine(to: CGPoint(x: x(i), y: y(hi(s)))) }
     for (i, s) in schritte.enumerated().reversed() { pfad.addLine(to: CGPoint(x: x(i), y: y(lo(s)))) }
     pfad.closeSubpath()
     context.fill(pfad, with: .color(FenlynineOSTheme.accent.opacity(opazitaet)))
   }
   band({ $0.p10 }, { $0.p90 }, opazitaet: 0.10)
   band({ $0.p25 }, { $0.p75 }, opazitaet: 0.18)

   // Medianlinie
   var median = Path()
   median.move(to: CGPoint(x: x(0), y: y(schritte[0].p50)))
   for (i, s) in schritte.enumerated() { median.addLine(to: CGPoint(x: x(i), y: y(s.p50))) }
   context.stroke(median, with: .color(FenlynineOSTheme.accent), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

   // Punkte + x-Beschriftung
   for (i, s) in schritte.enumerated() {
     context.fill(
       Path(ellipseIn: CGRect(x: x(i) - 3, y: y(s.p50) - 3, width: 6, height: 6)),
       with: .color(FenlynineOSTheme.accent)
     )
     let label = i == 0 ? "Start" : "Zug \(i)"
     context.draw(
       Text(label).font(.system(size: 8.5)).foregroundStyle(.secondary),
       at: CGPoint(x: x(i), y: size.height - 10)
     )
   }
 }
}
}

// MARK: - Endverteilung (Histogramm)

struct EndVerteilungView: View {
let werte: [Double]

var body: some View {
 Canvas { context, size in
   guard !werte.isEmpty else { return }
   let bins = 24
   var zaehler = Array(repeating: 0, count: bins)
   for w in werte {
     let idx = min(bins - 1, max(0, Int(w * Double(bins))))
     zaehler[idx] += 1
   }
   let maxZ = max(1, zaehler.max() ?? 1)
   let breite = size.width / CGFloat(bins)
   for (i, z) in zaehler.enumerated() {
     let h = size.height * CGFloat(z) / CGFloat(maxZ)
     let istErfolg = Double(i) / Double(bins) >= 0.5
     let rect = CGRect(x: CGFloat(i) * breite + 1, y: size.height - h, width: breite - 2, height: h)
     context.fill(
       Path(roundedRect: rect, cornerRadius: 1.5),
       with: .color((istErfolg ? ImperiumFarbe.gruen : ImperiumFarbe.gegner).opacity(0.7))
     )
   }
   // 50 %-Marke
   var linie = Path()
   linie.move(to: CGPoint(x: size.width / 2, y: 0))
   linie.addLine(to: CGPoint(x: size.width / 2, y: size.height))
   context.stroke(linie, with: .color(ImperiumFarbe.gold.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
 }
}
}

// MARK: - Hebel-Matrix (Streudiagramm)

struct HebelMatrixView: View {
let optionen: [MachtOption]

var body: some View {
 Canvas { context, size in
   let links: CGFloat = 34
   let unten: CGFloat = 24
   let oben: CGFloat = 8
   let rechts: CGFloat = 10
   let plotB = size.width - links - rechts
   let plotH = size.height - oben - unten

   func x(_ v: Double) -> CGFloat { links + plotB * CGFloat(v) }
   func y(_ v: Double) -> CGFloat { oben + plotH * (1 - CGFloat(v)) }

   // Quadranten-Hintergründe
   let quadranten: [(rect: CGRect, farbe: Color)] = [
     (CGRect(x: x(0.5), y: y(1.0), width: plotB / 2, height: plotH / 2), ImperiumFarbe.gruen), // rechts oben
     (CGRect(x: x(0.0), y: y(1.0), width: plotB / 2, height: plotH / 2), ImperiumFarbe.gold), // links oben
     (CGRect(x: x(0.5), y: y(0.5), width: plotB / 2, height: plotH / 2), ImperiumFarbe.eigen), // rechts unten
   ]
   for q in quadranten {
     context.fill(Path(q.rect), with: .color(q.farbe.opacity(0.05)))
   }

   // Gitter
   for stufe in [0.0, 0.25, 0.5, 0.75, 1.0] {
     var h = Path(); h.move(to: CGPoint(x: links, y: y(stufe))); h.addLine(to: CGPoint(x: size.width - rechts, y: y(stufe)))
     var v = Path(); v.move(to: CGPoint(x: x(stufe), y: oben)); v.addLine(to: CGPoint(x: x(stufe), y: size.height - unten))
     let stark = stufe == 0.5
     context.stroke(h, with: .color(.secondary.opacity(stark ? 0.3 : 0.12)), lineWidth: stark ? 1 : 0.7)
     context.stroke(v, with: .color(.secondary.opacity(stark ? 0.3 : 0.12)), lineWidth: stark ? 1 : 0.7)
     context.draw(Text("\(Int(stufe * 100))").font(.system(size: 8)).foregroundStyle(.tertiary), at: CGPoint(x: links - 14, y: y(stufe)))
     context.draw(Text("\(Int(stufe * 100))").font(.system(size: 8)).foregroundStyle(.tertiary), at: CGPoint(x: x(stufe), y: size.height - 12))
   }

   // Achsentitel
   context.draw(
     Text("Steuerbarkeit (Beeinflussbarkeit x Nutzbarkeit) ->").font(.system(size: 9)).foregroundStyle(.secondary),
     at: CGPoint(x: links + plotB / 2, y: size.height - 3)
   )
   var vertikal = context
   vertikal.rotate(by: .degrees(-90))
   vertikal.draw(
     Text("Eintritts-Wk. ->").font(.system(size: 9)).foregroundStyle(.secondary),
     at: CGPoint(x: -(oben + plotH / 2), y: 10)
   )

   // Blasen (Rang = Netto-Score-Reihenfolge)
   let sortiert = optionen.sorted { $0.nettoScore > $1.nettoScore }
   for (i, opt) in sortiert.enumerated() {
     let px = x(opt.steuerbarkeit)
     let py = y(opt.eintrittsWk)
     let radius = 7 + CGFloat(opt.erwarteterNutzen) * 16
     let kreis = Path(ellipseIn: CGRect(x: px - radius, y: py - radius, width: radius * 2, height: radius * 2))
     context.fill(kreis, with: .color(opt.wirkung.farbe.opacity(0.28)))
     context.stroke(kreis, with: .color(opt.wirkung.farbe), lineWidth: 1.5)
     context.draw(
       Text("\(i + 1)").font(.system(size: 9, weight: .bold)).foregroundStyle(opt.wirkung.farbe),
       at: CGPoint(x: px, y: py)
     )
   }
 }
}
}

// MARK: - Options-Karte

struct MachtOptionKarte: View {
let option: MachtOption
let rang: Int
let onToggle: () -> Void
let onEdit: () -> Void

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack(alignment: .top, spacing: 8) {
     Text("\(rang)")
       .font(.system(size: 10, weight: .bold))
       .frame(width: 18, height: 18)
       .background(Circle().fill(option.wirkung.farbe.opacity(0.18)))
       .foregroundStyle(option.wirkung.farbe)
     VStack(alignment: .leading, spacing: 2) {
       Text(option.titel)
         .font(.system(size: 12, weight: .semibold))
         .lineLimit(2)
       HStack(spacing: 6) {
         Label(option.wirkung.rawValue, systemImage: option.wirkung.symbol)
           .font(.system(size: 9, weight: .semibold))
           .foregroundStyle(option.wirkung.farbe)
         if !option.rechtsgrundlage.isEmpty {
           Text(option.rechtsgrundlage)
             .font(.system(size: 9, weight: .medium).monospaced())
             .padding(.horizontal, 5)
             .padding(.vertical, 1.5)
             .background(FenlynineOSTheme.accent.opacity(0.1), in: Capsule())
             .foregroundStyle(FenlynineOSTheme.accent)
         }
         if option.herkunft == .ki {
           Text("KI")
             .font(.system(size: 8, weight: .bold))
             .padding(.horizontal, 4).padding(.vertical, 1.5)
             .background(Premium.proposed.opacity(0.15), in: Capsule())
             .foregroundStyle(Premium.proposed)
         }
       }
     }
     Spacer()
     Toggle("", isOn: Binding(get: { option.aktiv }, set: { _ in onToggle() }))
       .toggleStyle(.switch)
       .controlSize(.mini)
       .help("In Simulation einbeziehen")
     Button(action: onEdit) {
       Image(systemName: "slider.horizontal.3")
         .font(.system(size: 10))
     }
     .buttonStyle(.plain)
     .foregroundStyle(.secondary)
     .help("Bearbeiten")
   }

   if !option.beschreibung.isEmpty {
     Text(option.beschreibung)
       .font(.system(size: 10.5))
       .foregroundStyle(.secondary)
       .lineLimit(2)
   }

   HStack(spacing: 6) {
     metrik("Wk.", option.eintrittsWk)
     metrik("Kontrolle", option.beeinflussbarkeit)
     metrik("Nutzbar", option.nutzbarkeit)
     metrik("Folgen ok", option.folgenHandhabbarkeit)
     Spacer()
     Text(String(format: "Netto %+.2f", option.nettoScore))
       .font(.system(size: 10, weight: .bold).monospacedDigit())
       .foregroundStyle(option.nettoScore >= 0.3 ? ImperiumFarbe.gruen : (option.nettoScore >= 0.1 ? ImperiumFarbe.gold : ImperiumFarbe.gegner))
   }
 }
 .padding(10)
 .background(FenlynineOSTheme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
 .overlay(
   RoundedRectangle(cornerRadius: 10)
     .stroke(option.aktiv ? option.wirkung.farbe.opacity(0.3) : FenlynineOSTheme.border, lineWidth: 1)
 )
 .opacity(option.aktiv ? 1 : 0.55)
}

private func metrik(_ label: String, _ wert: Double) -> some View {
 VStack(spacing: 2) {
   Text("\(Int(wert * 100))")
     .font(.system(size: 10, weight: .bold).monospacedDigit())
   Text(label)
     .font(.system(size: 7.5))
     .foregroundStyle(.tertiary)
 }
 .frame(minWidth: 34)
}
}

// MARK: - Ressourcen-Karte

struct MachtRessourceKarte: View {
let ressource: MachtRessource
let onEdit: () -> Void

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack(alignment: .top, spacing: 8) {
     Image(systemName: ressource.art.symbol)
       .font(.system(size: 12))
       .foregroundStyle(ImperiumFarbe.gold)
       .frame(width: 18)
     VStack(alignment: .leading, spacing: 2) {
       Text(ressource.titel)
         .font(.system(size: 12, weight: .semibold))
         .lineLimit(2)
       HStack(spacing: 6) {
         Text(ressource.art.rawValue)
           .font(.system(size: 9))
           .foregroundStyle(.secondary)
         Label(ressource.zweck.rawValue, systemImage: ressource.zweck.symbol)
           .font(.system(size: 9, weight: .semibold))
           .foregroundStyle(ressource.zweck.farbe)
         if !ressource.rechtsgrundlage.isEmpty {
           Text(ressource.rechtsgrundlage)
             .font(.system(size: 9, weight: .medium).monospaced())
             .padding(.horizontal, 5).padding(.vertical, 1.5)
             .background(FenlynineOSTheme.accent.opacity(0.1), in: Capsule())
             .foregroundStyle(FenlynineOSTheme.accent)
         }
         if ressource.herkunft == .ki {
           Text("KI")
             .font(.system(size: 8, weight: .bold))
             .padding(.horizontal, 4).padding(.vertical, 1.5)
             .background(Premium.proposed.opacity(0.15), in: Capsule())
             .foregroundStyle(Premium.proposed)
         }
       }
     }
     Spacer()
     Text("\(Int(ressource.effektiveKraft * 100))")
       .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
       .foregroundStyle(ImperiumFarbe.gold)
     Button(action: onEdit) {
       Image(systemName: "slider.horizontal.3")
         .font(.system(size: 10))
     }
     .buttonStyle(.plain)
     .foregroundStyle(.secondary)
   }

   // Verfügbar vs. Potenzial
   GeometryReader { geo in
     ZStack(alignment: .leading) {
       Capsule().fill(FenlynineOSTheme.border.opacity(0.4))
       Capsule()
         .fill(ImperiumFarbe.gold.opacity(0.35))
         .frame(width: max(3, geo.size.width * max(ressource.potenzial, ressource.verfuegbarkeit)))
       Capsule()
         .fill(ImperiumFarbe.gold)
         .frame(width: max(3, geo.size.width * ressource.verfuegbarkeit))
     }
   }
   .frame(height: 6)

   HStack {
     Text("Verfügbar \(Int(ressource.verfuegbarkeit * 100)) %")
       .font(.system(size: 9).monospacedDigit())
       .foregroundStyle(.secondary)
     Spacer()
     Text("Aktivierbar bis \(Int(max(ressource.potenzial, ressource.verfuegbarkeit) * 100)) %")
       .font(.system(size: 9).monospacedDigit())
       .foregroundStyle(.tertiary)
   }
 }
 .padding(10)
 .background(FenlynineOSTheme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(FenlynineOSTheme.border, lineWidth: 1))
}
}

// MARK: - Editoren

struct ImperiumProzentSlider: View {
let label: String
var farbe: Color = FenlynineOSTheme.accent
@Binding var wert: Double

var body: some View {
 HStack(spacing: 8) {
   Text(label)
     .font(.system(size: 11))
     .frame(width: 130, alignment: .leading)
   Slider(value: $wert, in: 0...1)
     .tint(farbe)
   Text("\(Int(wert * 100)) %")
     .font(.system(size: 11, weight: .semibold).monospacedDigit())
     .foregroundStyle(farbe)
     .frame(width: 40, alignment: .trailing)
 }
}
}

struct MachtOptionEditor: View {
@State var option: MachtOption
let onSave: (MachtOption) -> Void
let onDelete: (UUID) -> Void
@Environment(\.dismiss) private var dismiss

var body: some View {
 VStack(alignment: .leading, spacing: 14) {
   Label(option.titel.isEmpty ? "Neue Handlungsoption" : "Option bearbeiten", systemImage: "square.grid.2x2.fill")
     .font(.system(size: 13, weight: .bold))

   TextField("Titel (z. B. „Antrag auf einstweilige Verfügung")", text: $option.titel)
     .textFieldStyle(.roundedBorder)
   TextField("Beschreibung", text: $option.beschreibung, axis: .vertical)
     .textFieldStyle(.roundedBorder)
     .lineLimit(2...4)
   HStack(spacing: 10) {
     TextField("Rechtsgrundlage (z. B. § 935 ZPO)", text: $option.rechtsgrundlage)
       .textFieldStyle(.roundedBorder)
     Picker("Wirkung", selection: $option.wirkung) {
       ForEach(MachtWirkung.allCases) { w in
         Label(w.rawValue, systemImage: w.symbol).tag(w)
       }
     }
     .frame(width: 180)
   }

   Divider()

   ImperiumProzentSlider(label: "Eintritts-Wk.", wert: $option.eintrittsWk)
   ImperiumProzentSlider(label: "Beeinflussbarkeit", wert: $option.beeinflussbarkeit)
   ImperiumProzentSlider(label: "Nutzbarkeit", wert: $option.nutzbarkeit)
   ImperiumProzentSlider(label: "Folgen-Handhabbarkeit", wert: $option.folgenHandhabbarkeit)
   ImperiumProzentSlider(label: "Reversibilität", wert: $option.reversibilitaet)
   ImperiumProzentSlider(label: "Aufwand/Exponierung", farbe: ImperiumFarbe.gegner, wert: $option.aufwand)

   HStack(spacing: 10) {
     ImperiumChip(text: String(format: "Hebel %.2f", option.hebelwirkung), farbe: FenlynineOSTheme.accent)
     ImperiumChip(text: String(format: "Nutzen %.2f", option.erwarteterNutzen), farbe: ImperiumFarbe.gruen)
     ImperiumChip(text: String(format: "Risiko %.2f", option.restrisiko), farbe: ImperiumFarbe.gegner)
     ImperiumChip(text: String(format: "Netto %+.2f", option.nettoScore), farbe: ImperiumFarbe.gold)
   }

   HStack {
     Button(role: .destructive) {
       onDelete(option.id)
       dismiss()
     } label: {
       Label("Löschen", systemImage: "trash")
     }
     Spacer()
     Button("Abbrechen") { dismiss() }
     Button("Speichern") {
       var gespeichert = option
       if gespeichert.herkunft == .ki { gespeichert.herkunft = .manuell } // bestätigt
       onSave(gespeichert)
       dismiss()
     }
     .buttonStyle(.borderedProminent)
     .disabled(option.titel.trimmingCharacters(in: .whitespaces).isEmpty)
   }
 }
 .padding(18)
 .frame(width: 520)
}
}

struct MachtRessourceEditor: View {
@State var ressource: MachtRessource
let onSave: (MachtRessource) -> Void
let onDelete: (UUID) -> Void
@Environment(\.dismiss) private var dismiss

var body: some View {
 VStack(alignment: .leading, spacing: 14) {
   Label(ressource.titel.isEmpty ? "Neue Ressource / Hebel" : "Ressource bearbeiten", systemImage: "wrench.and.screwdriver.fill")
     .font(.system(size: 13, weight: .bold))

   TextField("Titel (z. B. „Gutachten Sachverständiger", „§ 142 ZPO Vorlageanordnung")", text: $ressource.titel)
     .textFieldStyle(.roundedBorder)
   HStack(spacing: 10) {
     Picker("Art", selection: $ressource.art) {
       ForEach(MachtRessourcenArt.allCases) { a in
         Label(a.rawValue, systemImage: a.symbol).tag(a)
       }
     }
     Picker("Zweck", selection: $ressource.zweck) {
       ForEach(MachtWirkung.allCases) { w in
         Label(w.rawValue, systemImage: w.symbol).tag(w)
       }
     }
   }
   TextField("Rechtsgrundlage (optional)", text: $ressource.rechtsgrundlage)
     .textFieldStyle(.roundedBorder)
   TextField("Notiz", text: $ressource.notiz, axis: .vertical)
     .textFieldStyle(.roundedBorder)
     .lineLimit(1...3)

   Divider()

   ImperiumProzentSlider(label: "Heute verfügbar", farbe: ImperiumFarbe.gold, wert: $ressource.verfuegbarkeit)
   ImperiumProzentSlider(label: "Aktivierbares Potenzial", farbe: ImperiumFarbe.gold.opacity(0.6), wert: $ressource.potenzial)
   ImperiumProzentSlider(label: "Hebelwirkung", wert: $ressource.hebelwirkung)

   ImperiumChip(
     text: "Effektive Kraft \(Int(ressource.effektiveKraft * 100)) / 100",
     farbe: ImperiumFarbe.gold
   )

   HStack {
     Button(role: .destructive) {
       onDelete(ressource.id)
       dismiss()
     } label: {
       Label("Löschen", systemImage: "trash")
     }
     Spacer()
     Button("Abbrechen") { dismiss() }
     Button("Speichern") {
       var gespeichert = ressource
       if gespeichert.herkunft == .ki { gespeichert.herkunft = .manuell }
       onSave(gespeichert)
       dismiss()
     }
     .buttonStyle(.borderedProminent)
     .disabled(ressource.titel.trimmingCharacters(in: .whitespaces).isEmpty)
   }
 }
 .padding(18)
 .frame(width: 520)
}
}

