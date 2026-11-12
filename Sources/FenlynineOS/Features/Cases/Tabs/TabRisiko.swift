import SwiftUI
import Charts

struct TabRisiko: View {
let viewModel: CaseDetailViewModel

var body: some View {
  VStack(spacing: 20) {
    Text("Risikoanalyse")
      .font(.title2.bold())

    if let vollanalyse = viewModel.vollanalyse {
      RisikoAnalyseView(ergebnis: vollanalyse.risikofaktoren, breakEven: vollanalyse.breakEven)
    } else if let fall = viewModel.fall {
      let ergebnis = LegalAlgorithmsService.computeRisikoFaktoren(
        args: viewModel.argumente,
        evidence: viewModel.beweise,
        deadlines: viewModel.fristen,
        persons: viewModel.personen,
        caseData: fall
      )
      let breakEven = LegalAlgorithmsService.computeBreakEven(caseData: fall)
      RisikoAnalyseView(ergebnis: ergebnis, breakEven: breakEven)
    } else {
      PlatzhalterView(nachricht: "Fall wird geladen…")
    }
  }
}
}

struct RisikoAnalyseView: View {
let ergebnis: RisikoFaktorenErgebnis
let breakEven: BreakEvenErgebnis
@State private var chartMode = 0

var body: some View {
  VStack(spacing: 20) {
    // Gesamtrisiko-Banner
    GesamtrisikoBanner(ergebnis: ergebnis)

    // Risikofaktoren-Tabelle
    HStack(alignment: .top, spacing: 20) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("8 Risikodimensionen")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
          Spacer()
          Picker("", selection: $chartMode) {
            Text("Radar").tag(0)
            Text("Balken").tag(1)
          }
          .pickerStyle(.segmented)
          .frame(width: 140)
        }

        if chartMode == 0 {
          LexaraRadarChartView(
            data: ergebnis.faktoren.map { (label: risikoLabel($0.key), value: Double($0.score)) },
            maxValue: 10,
            fillColor: .orange,
            strokeColor: .red
          )
          .frame(height: 280)
        } else {
          Chart(ergebnis.faktoren) { faktor in
            BarMark(
              x: .value("Score", faktor.score),
              y: .value("Dimension", risikoLabel(faktor.key))
            )
            .foregroundStyle(risikoFarbe(faktor.level))
            .cornerRadius(4)
            .annotation(position: .trailing) {
              Text("\(faktor.score)/10")
                .font(.caption2.bold())
                .foregroundStyle(risikoFarbe(faktor.level))
            }
          }
          .chartXScale(domain: 0...10)
          .chartXAxis {
            AxisMarks(values: [0, 2, 4, 6, 8, 10])
          }
          .frame(height: 280)
        }
      }
      .frame(maxWidth: .infinity)

      // Faktoren-Detail
      VStack(spacing: 8) {
        ForEach(ergebnis.faktoren) { faktor in
          RisikoFaktorZeile(faktor: faktor)
        }
      }
      .frame(maxWidth: .infinity)
    }

    // Break-Even-Analyse
    BreakEvenView(ergebnis: breakEven)
  }
}

private func risikoLabel(_ key: String) -> String {
 switch key {
 case "beweis_risiko": return "Beweislage"
 case "richter_risiko": return "Richter"
 case "rechts_risiko": return "Rechtsunsicherheit"
 case "kosten_risiko": return "Kosten"
 case "zeit_risiko": return "Zeit/Fristen"
 case "gegner_risiko": return "Gegnerstärke"
 case "reputation_risiko": return "Reputation"
 case "vergleich_chance": return "Vergleichschance"
 default: return key
 }
}

private func risikoFarbe(_ level: RisikoFaktor.RisikoLevel) -> Color {
 switch level {
 case .niedrig: return .green
 case .mittel: return .orange
 case .hoch: return .red
 }
}
}

struct GesamtrisikoBanner: View {
let ergebnis: RisikoFaktorenErgebnis

var body: some View {
 HStack(spacing: 20) {
   VStack(alignment: .leading, spacing: 4) {
     HStack(spacing: 4) {
       Text("Gesamtrisiko")
         .font(.caption)
         .foregroundStyle(.secondary)
       FenlynineOSTransparenzInfoButton(inhalt: .gesamtrisiko(ergebnis))
     }
     Text(ergebnis.gesamtrisiko.capitalized)
       .font(.system(size: 24, weight: .bold))
       .foregroundStyle(gesamtFarbe)
   }

   Spacer()

   VStack(alignment: .leading, spacing: 4) {
     Text("Gesamt-Score")
       .font(.caption)
       .foregroundStyle(.secondary)
     Text(String(format: "%.1f / 10", ergebnis.gesamtScore))
       .font(.system(size: 20, weight: .bold, design: .rounded))
       .foregroundStyle(gesamtFarbe)
   }

   Spacer()

   // Score-Gauge
   ZStack {
     Circle()
       .stroke(Color.gray.opacity(0.15), lineWidth: 8)
       .frame(width: 70, height: 70)
     Circle()
       .trim(from: 0, to: ergebnis.gesamtScore / 10)
       .stroke(gesamtFarbe, style: StrokeStyle(lineWidth: 8, lineCap: .round))
       .frame(width: 70, height: 70)
       .rotationEffect(.degrees(-90))
     Text(String(format: "%.0f%%", ergebnis.gesamtScore * 10))
       .font(.system(size: 12, weight: .bold))
   }
 }
 .padding(16)
 .background(gesamtFarbe.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(gesamtFarbe.opacity(0.2), lineWidth: 1))
}

private var gesamtFarbe: Color {
 switch ergebnis.gesamtrisiko {
 case "niedrig": return .green
 case "mittel": return .orange
 default: return .red
 }
}
}

struct RisikoFaktorZeile: View {
let faktor: RisikoFaktor
@State private var aufgeklappt = false

private var farbe: Color {
 switch faktor.level {
 case .niedrig: return .green
 case .mittel: return .orange
 case .hoch: return .red
 }
}

var body: some View {
 VStack(alignment: .leading, spacing: 0) {
   HStack(spacing: 8) {
     Circle()
       .fill(farbe)
       .frame(width: 8, height: 8)
     Text(risikoLabel)
       .font(.system(size: 12, weight: .medium))
     Spacer()
     Text("\(faktor.score)/10")
       .font(.system(size: 11, weight: .bold))
       .foregroundStyle(farbe)
     FenlynineOSTransparenzInfoButton(inhalt: .risikoFaktor(faktor))
     Button {
       withAnimation { aufgeklappt.toggle() }
     } label: {
       Image(systemName: aufgeklappt ? "chevron.up" : "chevron.down")
         .font(.caption2)
     }
     .buttonStyle(.plain)
   }
   .padding(8)

   if aufgeklappt {
     VStack(alignment: .leading, spacing: 4) {
       Text(faktor.bewertung)
         .font(.caption)
         .foregroundStyle(.secondary)
       Text(faktor.massnahme)
         .font(.caption)
         .fontWeight(.medium)
         .foregroundStyle(farbe)
       KITransparenzFormel(formel: faktor.formel, transparenz: .risikoFaktor(faktor))
     }
     .padding(.horizontal, 8)
     .padding(.bottom, 8)
   }
 }
 .background(farbe.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(farbe.opacity(0.12), lineWidth: 1))
}

private var risikoLabel: String {
 switch faktor.key {
 case "beweis_risiko": return "Beweislage"
 case "richter_risiko": return "Richter-Risiko"
 case "rechts_risiko": return "Rechtsunsicherheit"
 case "kosten_risiko": return "Kosten-Risiko"
 case "zeit_risiko": return "Zeitrisiko"
 case "gegner_risiko": return "Gegnerstärke"
 case "reputation_risiko": return "Reputationsrisiko"
 case "vergleich_chance": return "Vergleichschance"
 default: return faktor.key
 }
}
}

// MARK: - KI-Transparenz-Formel

struct KITransparenzFormel: View {
let formel: String
var transparenz: TransparenzInhalt? = nil

var body: some View {
 HStack(spacing: 4) {
   Image(systemName: "function")
     .font(.system(size: 9))
     .foregroundStyle(.purple)
   Text(formel)
     .font(.system(size: 10, design: .monospaced))
     .foregroundStyle(.secondary)
   Spacer(minLength: 0)
   if let t = transparenz {
     FenlynineOSTransparenzInfoButton(inhalt: t)
   } else {
     FenlynineOSTransparenzInfoButton(inhalt: TransparenzInhalt(
       titel: "Berechnungsformel",
       quelle: .algorithmus,
       modell: "LegalAlgorithms v2",
       formel: formel,
       erklaerung: "Mathematische Grundlage dieser Bewertung."
     ))
   }
 }
 .padding(5)
 .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 4))
}
}

// MARK: - Break-Even

struct BreakEvenView: View {
let ergebnis: BreakEvenErgebnis

var body: some View {
 VStack(alignment: .leading, spacing: 14) {
   HStack {
     Text("Break-Even-Analyse")
       .font(.system(size: 14, weight: .semibold))
     FenlynineOSTransparenzInfoButton(inhalt: .breakEven(ergebnis))
   }

   if let pct = ergebnis.breakEvenPct {
     HStack(spacing: 24) {
       VStack(alignment: .leading, spacing: 4) {
         Text("Break-Even-Schwelle")
           .font(.caption)
           .foregroundStyle(.secondary)
         Text("\(pct)%")
           .font(.system(size: 28, weight: .bold, design: .rounded))
           .foregroundStyle(pct > 60 ? .red : pct > 40 ? .orange : .green)
         Text("Mindest-Erfolgschance")
           .font(.caption2)
           .foregroundStyle(.secondary)
       }

       VStack(alignment: .leading, spacing: 4) {
         Text("Gesamtkosten")
           .font(.caption)
           .foregroundStyle(.secondary)
         Text(formatEuro(ergebnis.gesamtkosten))
           .font(.system(size: 18, weight: .semibold))
         Text("bei Niederlage")
           .font(.caption2)
           .foregroundStyle(.secondary)
       }

       Spacer()

       Text(ergebnis.empfehlung)
         .font(.system(size: 12, weight: .medium))
         .multilineTextAlignment(.center)
         .frame(maxWidth: 180)
     }

     // Formel-Transparenz
     KITransparenzFormel(formel: ergebnis.formel, transparenz: .breakEven(ergebnis))

     // Zusatzoptionen
     Text("Klageoptionen & Werterhöhungen")
       .font(.system(size: 12, weight: .semibold))
       .foregroundStyle(.secondary)
       .padding(.top, 4)

     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
       ForEach(ergebnis.zusatzoptionen) { option in
         BreakEvenOptionKarte(option: option)
       }
     }
   } else {
     Text("Streitwert nicht angegeben. Bitte in den Basisdaten eintragen.")
       .font(.subheadline)
       .foregroundStyle(.secondary)
   }
 }
 .padding(16)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12), lineWidth: 1))
}
}

struct BreakEvenOptionKarte: View {
let option: BreakEvenOption

var body: some View {
 VStack(alignment: .leading, spacing: 6) {
   HStack(spacing: 6) {
     Image(systemName: option.symbol)
       .font(.system(size: 12))
       .foregroundStyle(.blue)
     Text(option.titel)
       .font(.system(size: 11, weight: .semibold))
       .lineLimit(2)
   }
   Text(option.beschreibung)
     .font(.system(size: 10))
     .foregroundStyle(.secondary)
     .lineLimit(3)
   HStack {
     Text("Break-Even: \(option.breakEvenPct)%")
       .font(.caption2.bold())
       .foregroundStyle(option.breakEvenPct > 50 ? .orange : .green)
     Spacer()
     Text(option.rechtsgrundlage)
       .font(.system(size: 9))
       .foregroundStyle(.secondary)
   }
 }
 .padding(10)
 .background(Color.blue.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
 .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.12), lineWidth: 1))
}
}

private func formatEuro(_ value: Double) -> String {
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.currencyCode = "EUR"
formatter.locale = Locale(identifier: "de_DE")
return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value)) €"
}

