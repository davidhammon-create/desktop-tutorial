import SwiftUI
import Charts

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - KI-Transparenz-Komponente (EU AI Act Art. 13 konform)
//
// Zeigt bei jeder KI-Antwort, Berechnung oder Prognose vollständig:
// 1. Welche Eingabedaten verwendet wurden
// 2. Welches Modell / welchen Algorithmus
// 3. Jeden einzelnen Berechnungsschritt
// 4. Konfidenzintervalle und Unsicherheiten
// 5. Welche Faktoren die Antwort beeinflusst haben
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Transparenz-Protokoll (für jede KI-Antwort)

struct KITransparenzProtokoll: Identifiable {
let id = UUID()
let zeitstempel: Date
let modell: String
let kontext: String // z.B. "Prognose für Fall XY"
let eingaben: [TransparenzEingabe]
let schritte: [TransparenzSchritt]
let ergebnis: String
let konfidenz: Double // 0.0-1.0
let unsicherheitsFaktoren: [String]
let eu_ai_act_konform: Bool
var dauer_ms: Int?
}

struct TransparenzEingabe: Identifiable {
let id = UUID()
let name: String
let wert: String
let gewichtung: Double // 0.0-1.0 relative Wichtigkeit
let quelle: String // "Benutzer", "Datenbank", "Berechnet"
}

struct TransparenzSchritt: Identifiable {
let id = UUID()
let nummer: Int
let bezeichnung: String
let formel: String
let eingangswert: String
let ausgangswert: String
let erklaerung: String
}

// MARK: - Haupt-Transparenz-View

struct KITransparenzView: View {
let protokoll: KITransparenzProtokoll
@State private var zeigeDetails = false
@State private var aktiverTab: TransparenzTab = .eingaben

enum TransparenzTab: String, CaseIterable {
  case eingaben = "Eingaben"
  case schritte = "Schritte"
  case konfidenz = "Konfidenz"
  case compliance = "EU AI Act"
}

var body: some View {
  GroupBox {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(spacing: 10) {
        Image(systemName: "brain.filled.head.profile")
          .font(.system(size: 16))
          .foregroundStyle(.purple)

        VStack(alignment: .leading, spacing: 2) {
          Text("KI-Transparenz")
            .font(.system(size: 13, weight: .semibold))
          Text("\(protokoll.modell) · \(protokoll.zeitstempel.formatted(date: .omitted, time: .shortened))")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Konfidenz-Pill
        KonfidenzBadge(wert: protokoll.konfidenz)

        // EU AI Act Badge
        if protokoll.eu_ai_act_konform {
          Label("EU AI Act", systemImage: "checkmark.shield.fill")
            .font(.caption2)
            .foregroundStyle(.green)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.1), in: Capsule())
        }

        Button {
          withAnimation(.spring(duration: 0.2)) {
            zeigeDetails.toggle()
          }
        } label: {
         Label(zeigeDetails ? "Weniger" : "Details",
            systemImage: zeigeDetails ? "chevron.up" : "chevron.down")
           .font(.caption)
           .foregroundStyle(.blue)
       }
       .buttonStyle(.plain)
     }

     // Ergebnis-Zusammenfassung
     Text(protokoll.ergebnis)
       .font(.system(size: 12))
       .foregroundStyle(.secondary)
       .lineLimit(zeigeDetails ? nil : 2)

     // Aufklappbare Details
     if zeigeDetails {
       Divider()

       // Tab-Leiste
       HStack(spacing: 0) {
         ForEach(TransparenzTab.allCases, id: \.self) { tab in
           Button {
             withAnimation { aktiverTab = tab }
           } label: {
             Text(tab.rawValue)
               .font(.system(size: 11, weight: aktiverTab == tab ? .semibold : .regular))
               .foregroundStyle(aktiverTab == tab ? .white : .primary)
               .padding(.horizontal, 10)
               .padding(.vertical, 5)
               .background(aktiverTab == tab ? Color.purple : Color.clear,
                     in: RoundedRectangle(cornerRadius: 6))
           }
           .buttonStyle(.plain)
         }
       }
       .padding(3)
       .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

       // Tab-Inhalt
       Group {
         switch aktiverTab {
         case .eingaben: EingabenView(eingaben: protokoll.eingaben)
         case .schritte: SchritteView(schritte: protokoll.schritte)
         case .konfidenz: KonfidenzView(protokoll: protokoll)
         case .compliance: ComplianceView(protokoll: protokoll)
         }
       }
       .transition(.opacity.combined(with: .move(edge: .top)))
     }
   }
   .padding(.vertical, 4)
 }
}
}

// MARK: - Eingaben-Tab

private struct EingabenView: View {
let eingaben: [TransparenzEingabe]

var body: some View {
 VStack(alignment: .leading, spacing: 6) {
   ForEach(eingaben) { eingabe in
     HStack(spacing: 10) {
       // Gewichtungs-Balken
       RoundedRectangle(cornerRadius: 2)
         .fill(gewichtungsFarbe(eingabe.gewichtung))
         .frame(width: 3, height: 32)

       VStack(alignment: .leading, spacing: 2) {
         HStack {
           Text(eingabe.name)
             .font(.system(size: 11, weight: .medium))
           Spacer()
           Text(eingabe.quelle)
             .font(.caption2)
             .foregroundStyle(.secondary)
             .padding(.horizontal, 5)
             .padding(.vertical, 1)
             .background(Color.gray.opacity(0.1), in: Capsule())
         }
         Text(eingabe.wert)
           .font(.system(size: 11, design: .monospaced))
           .foregroundStyle(.secondary)
       }

       // Gewichtungs-Prozent
       Text("\(Int(eingabe.gewichtung * 100))%")
         .font(.system(size: 10, weight: .medium))
         .foregroundStyle(gewichtungsFarbe(eingabe.gewichtung))
         .frame(width: 34, alignment: .trailing)
     }
     .padding(8)
     .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
   }
 }
}

private func gewichtungsFarbe(_ w: Double) -> Color {
 if w >= 0.7 { return .red }
 if w >= 0.4 { return .orange }
 return .blue
}
}

// MARK: - Schritte-Tab

private struct SchritteView: View {
let schritte: [TransparenzSchritt]

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   ForEach(schritte) { schritt in
     SchrittzeilenView(schritt: schritt)
   }
 }
}
}

private struct SchrittzeilenView: View {
let schritt: TransparenzSchritt
@State private var aufgeklappt = false

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   Button {
     withAnimation(.easeInOut(duration: 0.15)) { aufgeklappt.toggle() }
   } label: {
     HStack(spacing: 10) {
       Text("\(schritt.nummer)")
         .font(.system(size: 10, weight: .bold, design: .monospaced))
         .foregroundStyle(.white)
         .frame(width: 20, height: 20)
         .background(Color.purple, in: Circle())

       Text(schritt.bezeichnung)
         .font(.system(size: 11, weight: .medium))
       Spacer()
       Text(schritt.ausgangswert)
         .font(.system(size: 11, design: .monospaced))
         .foregroundStyle(.blue)
       Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
         .font(.caption2)
         .foregroundStyle(.secondary)
     }
     .padding(.horizontal, 10)
     .padding(.vertical, 7)
   }
   .buttonStyle(.plain)

   if aufgeklappt {
     VStack(alignment: .leading, spacing: 6) {
       // Formel
       if !schritt.formel.isEmpty {
         HStack(spacing: 4) {
           Image(systemName: "function").font(.caption2).foregroundStyle(.purple)
           Text(schritt.formel)
             .font(.system(size: 10, design: .monospaced))
             .foregroundStyle(.secondary)
         }
         .padding(5)
         .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
       }
       // Eingangswert
       HStack(spacing: 4) {
         Text("Eingang:")
           .font(.caption2)
           .foregroundStyle(.secondary)
         Text(schritt.eingangswert)
           .font(.system(size: 10, design: .monospaced))
       }
       // Erklärung
       Text(schritt.erklaerung)
         .font(.caption2)
         .foregroundStyle(.secondary)
         .fixedSize(horizontal: false, vertical: true)
     }
     .padding(.horizontal, 40)
     .padding(.bottom, 8)
   }
 }
 .background(Color.gray.opacity(aufgeklappt ? 0.05 : 0), in: RoundedRectangle(cornerRadius: 8))
}
}

// MARK: - Konfidenz-Tab

private struct KonfidenzView: View {
let protokoll: KITransparenzProtokoll

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   // Konfidenz-Balken
   VStack(alignment: .leading, spacing: 6) {
     HStack {
       Text("Gesamtkonfidenz")
         .font(.system(size: 11, weight: .medium))
       Spacer()
       Text("\(Int(protokoll.konfidenz * 100))%")
         .font(.system(size: 13, weight: .bold))
         .foregroundStyle(konfidenzFarbe(protokoll.konfidenz))
     }

     GeometryReader { geo in
       ZStack(alignment: .leading) {
         RoundedRectangle(cornerRadius: 4)
           .fill(Color.gray.opacity(0.1))
           .frame(height: 8)
         RoundedRectangle(cornerRadius: 4)
           .fill(konfidenzFarbe(protokoll.konfidenz))
           .frame(width: geo.size.width * protokoll.konfidenz, height: 8)
       }
     }
     .frame(height: 8)
   }

   // Unsicherheitsfaktoren
   if !protokoll.unsicherheitsFaktoren.isEmpty {
     Text("Unsicherheitsfaktoren")
       .font(.caption.bold())
       .foregroundStyle(.secondary)
     ForEach(protokoll.unsicherheitsFaktoren, id: \.self) { faktor in
       HStack(spacing: 6) {
         Image(systemName: "exclamationmark.triangle.fill")
           .font(.caption2)
           .foregroundStyle(.orange)
         Text(faktor)
           .font(.caption2)
           .foregroundStyle(.secondary)
       }
     }
   }

   // Dauer
   if let ms = protokoll.dauer_ms {
     HStack(spacing: 4) {
       Image(systemName: "timer").font(.caption2).foregroundStyle(.secondary)
       Text("Berechnungszeit: \(ms) ms")
         .font(.caption2)
         .foregroundStyle(.secondary)
     }
   }
 }
 .padding(.vertical, 4)
}

private func konfidenzFarbe(_ k: Double) -> Color {
 if k >= 0.75 { return .green }
 if k >= 0.50 { return .blue }
 if k >= 0.30 { return .orange }
 return .red
}
}

// MARK: - EU AI Act Compliance-Tab

private struct ComplianceView: View {
let protokoll: KITransparenzProtokoll

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Image(systemName: "shield.checkered")
       .foregroundStyle(.blue)
     Text("EU AI Act Compliance")
       .font(.system(size: 12, weight: .semibold))
   }

   complianceZeile(
     icon: "checkmark.circle.fill",
     farbe: .green,
     titel: "Art. 13 - Transparenzpflicht",
     status: "Erfüllt: Berechnungsschritte vollständig offengelegt"
   )
   complianceZeile(
     icon: protokoll.eu_ai_act_konform ? "checkmark.circle.fill" : "xmark.circle.fill",
     farbe: protokoll.eu_ai_act_konform ? .green : .red,
     titel: "Art. 14 - Menschliche Aufsicht",
     status: protokoll.eu_ai_act_konform ?
       "Erfüllt: KI liefert Empfehlungen, Anwalt entscheidet" :
       "Prüfen: Finale Entscheidung muss beim Menschen liegen"
   )
   complianceZeile(
     icon: "checkmark.circle.fill",
     farbe: .green,
     titel: "Art. 9 - Risikomanagement",
     status: "Konfidenzintervalle und Unsicherheiten dokumentiert"
   )
   complianceZeile(
     icon: "checkmark.circle.fill",
     farbe: .green,
     titel: "DSGVO Art. 22 - Automatisierte Entscheidung",
     status: "Keine automatische Rechtsentscheidung ohne Anwaltsfreigabe"
   )

   Divider()

   Text("Modell: \(protokoll.modell)")
     .font(.caption2)
     .foregroundStyle(.secondary)
   Text("Kontext: \(protokoll.kontext)")
     .font(.caption2)
     .foregroundStyle(.secondary)
 }
 .padding(.vertical, 4)
}

private func complianceZeile(icon: String, farbe: Color, titel: String, status: String) -> some View {
 HStack(alignment: .top, spacing: 8) {
   Image(systemName: icon)
     .font(.system(size: 12))
     .foregroundStyle(farbe)
     .frame(width: 16)
   VStack(alignment: .leading, spacing: 1) {
     Text(titel).font(.system(size: 11, weight: .medium))
     Text(status).font(.caption2).foregroundStyle(.secondary)
   }
 }
}
}

// MARK: - Konfidenz-Badge (wiederverwendbare Komponente)

struct KonfidenzBadge: View {
let wert: Double // 0.0-1.0

var body: some View {
 HStack(spacing: 3) {
   Circle()
     .fill(farbe)
     .frame(width: 6, height: 6)
   Text("\(Int(wert * 100))%")
     .font(.system(size: 11, weight: .semibold))
     .foregroundStyle(farbe)
 }
 .padding(.horizontal, 7)
 .padding(.vertical, 3)
 .background(farbe.opacity(0.1), in: Capsule())
}

private var farbe: Color {
 if wert >= 0.75 { return .green }
 if wert >= 0.50 { return .blue }
 if wert >= 0.30 { return .orange }
 return .red
}
}

// MARK: - Kompakte KI-Karte (für Schnelldarstellung ohne Details)

struct KIProfilKarteKompakt: View {
let titel: String
let inhalt: String
let konfidenz: Double?
var modell: String = "Claude Sonnet 4.6"

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Label(titel, systemImage: "brain.filled.head.profile")
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(.purple)
     Spacer()
     if let k = konfidenz {
       KonfidenzBadge(wert: k)
     }
   }

   Text(inhalt)
     .font(.system(size: 12))
     .foregroundStyle(.primary)
     .fixedSize(horizontal: false, vertical: true)

   HStack(spacing: 4) {
     Image(systemName: "cpu")
       .font(.caption2)
       .foregroundStyle(.secondary)
     Text(modell)
       .font(.caption2)
       .foregroundStyle(.secondary)
   }
 }
 .padding(12)
 .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(
   RoundedRectangle(cornerRadius: 10)
     .stroke(Color.purple.opacity(0.12), lineWidth: 1)
 )
}
}

// MARK: - KI-Erklärungsbuilder (Hilfsmethoden)

extension KITransparenzProtokoll {

/// Erstellt ein Protokoll aus einer LLM-Antwort
static func ausBerechnungsSchritten(
 schritte: [BerechnungsSchritt],
 ergebnis: String,
 kontext: String,
 konfidenz: Double,
 modell: String = "LegalAlgorithms v2"
) -> KITransparenzProtokoll {
 let transparenzSchritte = schritte.enumerated().map { idx, s in
   TransparenzSchritt(
     nummer: idx + 1,
     bezeichnung: s.label,
     formel: s.formel,
     eingangswert: "-",
     ausgangswert: "\(String(format: "%.2f", s.wert)) \(s.einheit)",
     erklaerung: s.erklaerung
   )
 }

 return KITransparenzProtokoll(
   zeitstempel: Date(),
   modell: modell,
   kontext: kontext,
   eingaben: [],
   schritte: transparenzSchritte,
   ergebnis: ergebnis,
   konfidenz: konfidenz,
   unsicherheitsFaktoren: [],
   eu_ai_act_konform: true
 )
}
}

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// MARK: - Kompaktes Info-„i" für KI- & Algorithmus-Ergebnisse
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum TransparenzQuelle: String {
case ki = "KI-Modell"
case algorithmus = "Algorithmus"
}

struct TransparenzInhalt {
let titel: String
let quelle: TransparenzQuelle
var modell: String = ""
var ergebnis: String = ""
var begruendung: String = ""
var formel: String = ""
var erklaerung: String = ""
var eingaben: [(name: String, wert: String)] = []
var berechnungsschritte: [(label: String, formel: String, wert: String, erklaerung: String)] = []
var unsicherheiten: [String] = []
var juristischerHinweis: String = "Diese Auswertung dient der juristischen Nachvollziehbarkeit. Die endgültige rechtliche Bewertung liegt beim bearbeitenden Anwalt."

static func risikoFaktor(_ faktor: RisikoFaktor) -> TransparenzInhalt {
 TransparenzInhalt(
   titel: risikoLabel(faktor.key),
   quelle: .algorithmus,
   modell: "LegalAlgorithms v2 -- 8-Dimensionen-Risiko",
   ergebnis: "\(faktor.score)/10 (\(faktor.level.rawValue.capitalized))",
   begruendung: faktor.bewertung,
   formel: faktor.formel,
   erklaerung: faktor.massnahme
 )
}

static func gesamtrisiko(_ ergebnis: RisikoFaktorenErgebnis) -> TransparenzInhalt {
 TransparenzInhalt(
   titel: "Gesamtrisiko",
   quelle: .algorithmus,
   modell: "LegalAlgorithms v2 -- gewichteter Mittelwert",
   ergebnis: "\(ergebnis.gesamtrisiko.capitalized) · \(String(format: "%.1f", ergebnis.gesamtScore))/10",
   begruendung: "Mittelwert über 8 Risikodimensionen (Beweis, Richter, Recht, Kosten, Zeit, Gegner, Reputation, Vergleich).",
   formel: "GesamtScore = S(RisikoScoren) / 8",
   erklaerung: "Stufe: <=3,3 niedrig · <=6,6 mittel · >6,6 hoch",
   eingaben: ergebnis.faktoren.map { (name: risikoLabel($0.key), wert: "\($0.score)/10") }
 )
}

static func breakEven(_ ergebnis: BreakEvenErgebnis) -> TransparenzInhalt {
 TransparenzInhalt(
   titel: "Break-Even-Analyse",
   quelle: .algorithmus,
   modell: "LegalAlgorithms v2 -- RVG-Kostenmodell",
   ergebnis: ergebnis.breakEvenPct.map { "Mindest-Erfolgschance: \($0)%" } ?? "Nicht berechenbar",
   begruendung: ergebnis.empfehlung,
   formel: ergebnis.formel,
   erklaerung: ergebnis.erklaerung,
   eingaben: [
     ("Gesamtkosten", formatEuroTransparenz(ergebnis.gesamtkosten)),
     ("Eigene Kosten", formatEuroTransparenz(ergebnis.eigeneKosten)),
     ("Gegner-Kosten", formatEuroTransparenz(ergebnis.gegnerKosten)),
     ("Gerichtskosten", formatEuroTransparenz(ergebnis.gerichtkosten))
   ]
 )
}

static func prognose(_ p: PrognoseErgebnis, kontext: String = "Erfolgsprognose") -> TransparenzInhalt {
 TransparenzInhalt(
   titel: kontext,
   quelle: .algorithmus,
   modell: "LegalAlgorithms v2 -- Bayesianisches Update + Monte Carlo",
   ergebnis: "\(p.score)% (90%-KI: \(p.ciLow)-\(p.ciHigh)%)",
   begruendung: "Gewichtete Kombination aus Argumentstärke, Beweislage, Fristen, Richterquote und Instanzfaktor.",
   formel: "log-odds Update: logit(P) = logit(Pn) + S Dn",
   erklaerung: "s = \(String(format: "%.3f", p.sigma)) · Raw = \(String(format: "%.1f", p.scoreRaw * 100))%",
   eingaben: [
     ("Eigene Argumente", "\(p.inputs.eigeneArgs)"),
     ("Gegner-Argumente", "\(p.inputs.gegnerArgs)"),
     ("Beweise", "\(p.inputs.beweise)"),
     ("Fristen", "\(p.inputs.fristen)"),
     ("Richter bekannt", p.inputs.richterBekannt ? "Ja" : "Nein")
   ],
   berechnungsschritte: p.schritte.map {
     ($0.label, $0.formel, "\(String(format: "%.2f", $0.wert)) \($0.einheit)", $0.erklaerung)
   },
   unsicherheiten: ["Konfidenzintervall ±\(p.ciHigh - p.score)% oben / \(p.score - p.ciLow)% unten"]
 )
}

static func monteCarlo(_ mc: MonteCarloErgebnis) -> TransparenzInhalt {
 TransparenzInhalt(
   titel: "Monte-Carlo-Simulation",
   quelle: .algorithmus,
   modell: "LegalAlgorithms v2 -- SIMD Monte Carlo (\(mc.iterationen) Iterationen)",
   ergebnis: "Median \(mc.median)% · Mittel \(mc.mean)%",
   begruendung: mc.szenarien.baseCase.erklaerung,
   formel: "Pnn=\(mc.p10)% · Pnn=\(mc.p25)% · Pnn=\(mc.p75)% · Pnn=\(mc.p90)%",
   erklaerung: "Best Case \(mc.szenarien.bestCase.wahrscheinlichkeit)% · Worst Case \(mc.szenarien.worstCase.wahrscheinlichkeit)%",
   unsicherheiten: [
     "Best Case: \(mc.szenarien.bestCase.erklaerung)",
     "Worst Case: \(mc.szenarien.worstCase.erklaerung)"
   ]
 )
}

static func kiModul(
 titel: String,
 modell: String = "Claude Sonnet 4.6",
 begruendung: String,
 eingabe: String? = nil,
 ausgabe: String? = nil,
 erklaerung: String? = nil
) -> TransparenzInhalt {
 var eingaben: [(name: String, wert: String)] = []
 if let eingabe, !eingabe.isEmpty {
   eingaben.append(("Prompt / Eingabe", eingabe))
 }
 return TransparenzInhalt(
   titel: titel,
   quelle: .ki,
   modell: modell,
   ergebnis: ausgabe.map { String($0.prefix(200)) } ?? begruendung,
   begruendung: begruendung,
   erklaerung: erklaerung ?? "KI-generierte Einschätzung auf Basis der übergebenen Falldaten. Bitte kritisch prüfen.",
   eingaben: eingaben
 )
}

static func kiLog(_ log: KIUsageLog) -> TransparenzInhalt {
 TransparenzInhalt(
   titel: log.anzeigeFunktion,
   quelle: .ki,
   modell: log.model ?? log.modell ?? "Standard",
   ergebnis: String((log.output ?? "").prefix(300)),
   begruendung: log.input_summary ?? "Keine Eingabe-Zusammenfassung",
   erklaerung: "Protokollierte KI-Nutzung -- vollständige Ein-/Ausgabe unten aufklappbar.",
   eingaben: log.input_summary.map { [("Eingabe-Zusammenfassung", $0)] } ?? []
 )
}

static func argumentKIBewertung(_ argument: Argument) -> TransparenzInhalt {
 kiModul(
   titel: "KI-Bewertung: \(argument.title)",
   begruendung: argument.ki_bewertung ?? "",
   ausgabe: argument.ki_bewertung,
   erklaerung: "Stärke \(Int(argument.effectiveStrength))/10 · Seite: \(argument.side.rawValue)"
 )
}

static func beweisKIBewertung(_ beweis: Evidence) -> TransparenzInhalt {
 kiModul(
   titel: "KI-Bewertung: \(beweis.title)",
   begruendung: beweis.ki_bewertung ?? "",
   ausgabe: beweis.ki_bewertung,
   erklaerung: "Gewicht \(Int(beweis.effectiveWeight))/10 · Typ: \(beweis.type.rawValue)"
 )
}

static func intelligenceScore(erledigt: Int, gesamt: Int, module: [(name: String, done: Bool)]) -> TransparenzInhalt {
 TransparenzInhalt(
   titel: "FenlynineOS Intelligence Score",
   quelle: .algorithmus,
   modell: "KIResultStore -- Modul-Fortschritt",
   ergebnis: gesamt > 0 ? "\(Int((Double(erledigt) / Double(gesamt)) * 100))% (\(erledigt)/\(gesamt) Module)" : "0%",
   begruendung: "Anteil abgeschlossener KI-Analysemodule für diesen Fall.",
   erklaerung: module.map { "\($0.done ? "3" : "n") \($0.name)" }.joined(separator: " · ")
 )
}

static func fallPrognoseChip(prognose: Double, vollanalyse: VollanalyseErgebnis?) -> TransparenzInhalt {
 if let p = vollanalyse?.prognose {
   return Self.prognose(p, kontext: "Fallprognose (Header)")
 }
 return TransparenzInhalt(
   titel: "Fallprognose",
   quelle: .algorithmus,
   modell: "LegalAlgorithms v2",
   ergebnis: "\(Int(prognose))%",
   begruendung: "Gespeicherte Prognose aus Falldaten. Vollständige Berechnungsschritte nach Analyse-Laden verfügbar.",
   formel: "Bayesianisches Update über Argumente, Beweise, Fristen, Richter"
 )
}

static func kiFallanalyse(_ ergebnis: CaseDetailViewModel.KIFallanalyseErgebnis) -> TransparenzInhalt {
 kiModul(
   titel: "KI-Fallanalyse -- Erfolgswahrscheinlichkeit",
   modell: "Claude Sonnet 4.6",
   begruendung: ergebnis.begruendung,
   ausgabe: "\(ergebnis.erfolgswahrscheinlichkeit)% -- \(ergebnis.strategischeEmpfehlung)",
   erklaerung: "\(ergebnis.staerksteGegenargumente.count) Gegenargumente · \(ergebnis.kritischeSchwachstellen.count) Schwachstellen · \(ergebnis.gegenmassnahmen.count) Gegenmaßnahmen"
 )
}

private static func risikoLabel(_ key: String) -> String {
 switch key {
 case "beweis_risiko": return "Beweislage"
 case "richter_risiko": return "Richter-Risiko"
 case "rechts_risiko": return "Rechtsunsicherheit"
 case "kosten_risiko": return "Kosten-Risiko"
 case "zeit_risiko": return "Zeitrisiko"
 case "gegner_risiko": return "Gegnerstärke"
 case "reputation_risiko": return "Reputationsrisiko"
 case "vergleich_chance": return "Vergleichschance"
 default: return key
 }
}

private static func formatEuroTransparenz(_ value: Double) -> String {
 let f = NumberFormatter()
 f.numberStyle = .currency
 f.currencyCode = "EUR"
 f.locale = Locale(identifier: "de_DE")
 return f.string(from: NSNumber(value: value)) ?? "\(Int(value)) €"
}
}

// MARK: - Info-Button & Detail-Sheet

struct FenlynineOSTransparenzInfoButton: View {
let inhalt: TransparenzInhalt
@State private var zeigeSheet = false

var body: some View {
 Button {
   zeigeSheet = true
 } label: {
   Image(systemName: "info.circle")
     .font(.system(size: 12, weight: .medium))
     .foregroundStyle(inhalt.quelle == .ki ? .purple.opacity(0.85) : .blue.opacity(0.85))
 }
 .buttonStyle(.plain)
 .help("Nachvollziehbarkeit: Quelle, Formel & Begründung")
 .sheet(isPresented: $zeigeSheet) {
   FenlynineOSTransparenzSheet(inhalt: inhalt)
 }
}
}

struct FenlynineOSTransparenzSheet: View {
let inhalt: TransparenzInhalt
@Environment(\.dismiss) private var dismiss

var body: some View {
 NavigationStack {
   ScrollView {
     VStack(alignment: .leading, spacing: 16) {
       metaZeile("Quelle", wert: inhalt.quelle.rawValue, symbol: inhalt.quelle == .ki ? "brain.head.profile" : "function")
       if !inhalt.modell.isEmpty {
         metaZeile("Modell / Engine", wert: inhalt.modell, symbol: "cpu")
       }
       if !inhalt.ergebnis.isEmpty {
         abschnitt("Ergebnis", text: inhalt.ergebnis, farbe: .primary)
       }
       if !inhalt.begruendung.isEmpty {
         abschnitt("Begründung", text: inhalt.begruendung, farbe: .secondary)
       }
       if !inhalt.formel.isEmpty {
         formelBlock(inhalt.formel)
       }
       if !inhalt.erklaerung.isEmpty {
         abschnitt("Erläuterung", text: inhalt.erklaerung, farbe: .secondary)
       }
       if !inhalt.eingaben.isEmpty {
         Text("Eingabedaten").font(.caption.bold()).foregroundStyle(.tertiary)
         ForEach(Array(inhalt.eingaben.enumerated()), id: \.offset) { _, e in
           HStack {
             Text(e.name).font(.caption).foregroundStyle(.secondary)
             Spacer()
             Text(e.wert).font(.caption.monospaced()).textSelection(.enabled)
           }
           .padding(8)
           .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
         }
       }
       if !inhalt.berechnungsschritte.isEmpty {
         Text("Berechnungsschritte").font(.caption.bold()).foregroundStyle(.tertiary)
         ForEach(Array(inhalt.berechnungsschritte.enumerated()), id: \.offset) { idx, s in
           VStack(alignment: .leading, spacing: 4) {
             HStack {
               Text("\(idx + 1).").font(.caption2.bold()).foregroundStyle(.purple)
               Text(s.label).font(.caption.bold())
               Spacer()
               Text(s.wert).font(.caption2.monospaced()).foregroundStyle(.blue)
             }
             if !s.formel.isEmpty {
               Text(s.formel).font(.caption2.monospaced()).foregroundStyle(.secondary)
             }
             Text(s.erklaerung).font(.caption2).foregroundStyle(.tertiary)
           }
           .padding(8)
           .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
         }
       }
       if !inhalt.unsicherheiten.isEmpty {
         Text("Unsicherheiten").font(.caption.bold()).foregroundStyle(.orange)
         ForEach(inhalt.unsicherheiten, id: \.self) { u in
           Label(u, systemImage: "exclamationmark.triangle").font(.caption2).foregroundStyle(.secondary)
         }
       }
       Divider()
       Label(inhalt.juristischerHinweis, systemImage: "person.fill.checkmark")
         .font(.caption2)
         .foregroundStyle(.secondary)
     }
     .padding(20)
   }
   .navigationTitle(inhalt.titel)
   .toolbar {
     ToolbarItem(placement: .confirmationAction) {
       Button("Schließen") { dismiss() }
     }
   }
 }
 .frame(minWidth: 480, minHeight: 420)
}

private func metaZeile(_ label: String, wert: String, symbol: String) -> some View {
 HStack(spacing: 8) {
   Image(systemName: symbol).foregroundStyle(.secondary)
   Text(label).font(.caption).foregroundStyle(.secondary)
   Text(wert).font(.caption.bold())
   Spacer()
 }
}

private func abschnitt(_ titel: String, text: String, farbe: Color) -> some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(titel).font(.caption.bold()).foregroundStyle(.tertiary)
   Text(text).font(.subheadline).foregroundStyle(farbe).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
 }
}

private func formelBlock(_ formel: String) -> some View {
 VStack(alignment: .leading, spacing: 4) {
   Text("Formel").font(.caption.bold()).foregroundStyle(.tertiary)
   HStack(spacing: 4) {
     Image(systemName: "function").font(.caption2).foregroundStyle(.purple)
     Text(formel).font(.caption.monospaced()).textSelection(.enabled)
   }
   .padding(8)
   .frame(maxWidth: .infinity, alignment: .leading)
   .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
 }
}
}

struct BerechnungsTransparenzView: View {
let schritte: [BerechnungsSchritt]

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   HStack {
     Label("Algorithmus-Berechnungsschritte", systemImage: "function")
       .font(.subheadline.bold())
     Spacer()
     FenlynineOSTransparenzInfoButton(inhalt: .prognose(
       PrognoseErgebnis(
         score: 0, scoreRaw: 0, logOdds: 0, ciLow: 0, ciHigh: 0, sigma: 0,
         schritte: schritte,
         inputs: PrognoseInputs(eigeneArgs: 0, gegnerArgs: 0, beweise: 0, fristen: 0, richterBekannt: false)
       ),
       kontext: "Vollanalyse -- Berechnungsschritte"
     ))
   }
   ForEach(schritte) { s in
     HStack(alignment: .top, spacing: 8) {
       Text(s.label).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
       Text("\(String(format: "%.2f", s.wert)) \(s.einheit)")
         .font(.caption.monospaced()).foregroundStyle(.blue)
       FenlynineOSTransparenzInfoButton(inhalt: TransparenzInhalt(
         titel: s.label,
         quelle: .algorithmus,
         modell: "LegalAlgorithms v2 -- \(s.kategorie)",
         ergebnis: "\(String(format: "%.2f", s.wert)) \(s.einheit)",
         formel: s.formel,
         erklaerung: s.erklaerung
       ))
     }
   }
 }
 .padding(14)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
}
}

extension View {
func fenlynineOSTransparenz(_ inhalt: TransparenzInhalt?) -> some View {
 overlay(alignment: .topTrailing) {
   if let inhalt {
     FenlynineOSTransparenzInfoButton(inhalt: inhalt)
       .padding(4)
   }
 }
}

@ViewBuilder
func fenlynineOSTransparenzInline(_ inhalt: TransparenzInhalt?) -> some View {
 HStack(alignment: .top, spacing: 6) {
   self
   if let inhalt {
     FenlynineOSTransparenzInfoButton(inhalt: inhalt)
   }
 }
}
}

