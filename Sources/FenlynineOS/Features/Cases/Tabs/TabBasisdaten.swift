import SwiftUI

struct TabBasisdaten: View {
let viewModel: CaseDetailViewModel

@State private var bearbeitung = false
@State private var fallKopie: LegalCase?

private var rechtsgebietBinding: Binding<LexaraRechtsgebietAuswahl> {
  Binding(
    get: {
      if bearbeitung, let k = fallKopie { return k.rechtsgebietAuswahl() }
      return viewModel.fall?.rechtsgebietAuswahl() ?? LexaraRechtsgebietAuswahl()
    },
    set: { neu in
      guard var k = fallKopie else { return }
      k.applyRechtsgebietAuswahl(neu)
      fallKopie = k
    }
  )
}

var body: some View {
  VStack(spacing: 20) {
    // Kopfzeile
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("Basisdaten")
          .font(.title2.bold())
        Text("Grundlegende Fallinformationen und Metadaten")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button(bearbeitung ? "Speichern" : "Bearbeiten") {
        if bearbeitung {
          Task {
            if let kopie = fallKopie {
              viewModel.fall = kopie
              try? await viewModel.fallSpeichern()
            }
            bearbeitung = false
          }
        } else {
          fallKopie = viewModel.fall
          bearbeitung = true
        }
      }
      .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
      if bearbeitung {
        Button("Abbrechen") {
          fallKopie = nil
          bearbeitung = false
        }
        .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
      }
    }

    if let fall = bearbeitung ? fallKopie : viewModel.fall {
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ], spacing: 16) {
        // Grunddaten
        InfoAbschnitt(titel: "Identifikation") {
          if bearbeitung, let binding = Binding($fallKopie) {
            InfoFeldEditierbar("Fallname", text: binding.fallname)
            InfoFeldEditierbarOptional("Aktenzeichen", text: binding.aktenzeichen)
            InfoFeldEditierbarOptional("Mandant", text: binding.mandant_name)
          } else {
            InfoFeld("Fallname", wert: fall.fallname)
            InfoFeld("Aktenzeichen", wert: fall.aktenzeichen)
            InfoFeld("Mandant", wert: fall.mandant_name)
          }
        }

        InfoAbschnitt(titel: "Verfahren") {
          if bearbeitung, let binding = Binding($fallKopie) {
            InfoFeldEditierbarOptional("Gericht", text: binding.gericht)
            InfoPickerEnum("Status", selection: binding.status, displayName: \.rawValue)
            InfoPickerEnum("Instanz", selection: binding.instanz, displayName: \.rawValue)
          } else {
            InfoFeld("Gericht", wert: fall.gericht)
            InfoFeld("Status", wert: fall.status.rawValue)
            InfoFeld("Instanz", wert: fall.instanz.rawValue)
          }
        }

        InfoAbschnitt(titel: "Finanzielle Eckdaten") {
          if bearbeitung, let binding = Binding($fallKopie) {
            InfoFeldZahl("Streitwert (€)", wert: binding.streitwert)
            InfoFeldZahl("Gebührenstufe (RVG)", wert: binding.gebuehrenstufe)
            InfoFeldZahl("SV-Kosten (€)", wert: binding.sv_kosten)
            InfoFeldZahl("Reisekosten (€)", wert: binding.reisekosten)
            InfoFeldZahl("Vergleichsangebot Gegenseite (€)", wert: binding.vergleichsangebot)
          } else {
            InfoFeld("Streitwert", wert: fall.streitwert.map { formatEuro($0) })
            InfoFeld("Gebührenstufe", wert: fall.gebuehrenstufe.map { "\($0)-fach (RVG)" })
            InfoFeld("SV-Kosten", wert: fall.sv_kosten.map { formatEuro($0) })
           InfoFeld("Reisekosten", wert: fall.reisekosten.map { formatEuro($0) })
           InfoFeld("Vergleichsangebot", wert: fall.vergleichsangebot.map { formatEuro($0) })
         }
       }

       InfoAbschnitt(titel: "Richter & Prognose") {
         if bearbeitung, let binding = Binding($fallKopie) {
           InfoFeldEditierbarOptional("Richter Name", text: binding.richter_name)
           InfoFeldZahl("Richter Klägerquote (%)", wert: binding.richter_klaeger_rate)
         } else {
           InfoFeld("Richter", wert: fall.richter_name)
           InfoFeld("Klägerquote Richter", wert: fall.richter_klaeger_rate.map { "\(Int($0))%" })
           InfoFeld("Aktuelle Prognose", wert: fall.prognose.map { "\(Int($0))%" })
         }
       }
     }

     InfoAbschnitt(titel: "Rechtsgebiete & Schwerpunkte") {
       LexaraRechtsgebietPickerView(
         auswahl: rechtsgebietBinding,
         bearbeitung: bearbeitung
       )
     }

     // Notizen
     InfoAbschnitt(titel: "Fallnotizen") {
       if bearbeitung, let binding = Binding($fallKopie) {
         TextEditor(text: Binding(
           get: { binding.notes.wrappedValue ?? "" },
           set: { binding.notes.wrappedValue = $0 }
         ))
         .font(.system(size: 13))
         .frame(minHeight: 80)
         .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2)))
       } else {
         Text(fall.notes ?? "Keine Notizen vorhanden.")
           .font(.system(size: 13))
           .foregroundStyle(fall.notes == nil ? .secondary : .primary)
           .frame(maxWidth: .infinity, alignment: .leading)
       }
     }

     // Prozessziel
     InfoAbschnitt(titel: "Prozessziel & zentrale Rechtsfrage") {
       if bearbeitung, let binding = Binding($fallKopie) {
         InfoFeldEditierbarOptional("Prozessziel", text: binding.prozessziel)
         InfoFeldEditierbarOptional("Zentrale Rechtsfrage", text: binding.zentrale_rechtsfrage)
       } else {
         InfoFeld("Prozessziel", wert: fall.prozessziel)
         InfoFeld("Zentrale Rechtsfrage", wert: fall.zentrale_rechtsfrage)
       }
     }
   }
 }
}
}

// MARK: - Info-Komponenten

struct InfoAbschnitt<Content: View>: View {
let titel: String
@ViewBuilder let content: Content

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   Text(titel)
     .font(.system(size: 12, weight: .semibold))
     .foregroundStyle(.secondary)
     .textCase(.uppercase)

   VStack(alignment: .leading, spacing: 8) {
     content
   }
   .padding(14)
   .background(.background, in: RoundedRectangle(cornerRadius: 10))
   .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.12), lineWidth: 1))
 }
}
}

struct InfoFeld: View {
let label: String
let wert: String?

init(_ label: String, wert: String?) {
 self.label = label
 self.wert = wert
}

var body: some View {
 HStack {
   Text(label)
     .font(.system(size: 12))
     .foregroundStyle(.secondary)
     .frame(width: 160, alignment: .leading)
   Text(wert ?? "--")
     .font(.system(size: 12, weight: .medium))
     .foregroundStyle(wert == nil ? .tertiary : .primary)
   Spacer()
 }
}
}

struct InfoFeldEditierbar: View {
let label: String
@Binding var text: String

init(_ label: String, text: Binding<String>) {
 self.label = label
 self._text = text
}

var body: some View {
 HStack {
   Text(label)
     .font(.system(size: 12))
     .foregroundStyle(.secondary)
     .frame(width: 160, alignment: .leading)
   TextField("", text: $text)
     .textFieldStyle(.plain)
     .font(.system(size: 12))
     .padding(.horizontal, 6)
     .padding(.vertical, 3)
     .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
 }
}
}

struct InfoFeldEditierbarOptional: View {
let label: String
@Binding var text: String?

init(_ label: String, text: Binding<String?>) {
 self.label = label
 self._text = text
}

var body: some View {
 HStack {
   Text(label)
     .font(.system(size: 12))
     .foregroundStyle(.secondary)
     .frame(width: 160, alignment: .leading)
   TextField("", text: Binding(
     get: { text ?? "" },
     set: { text = $0.isEmpty ? nil : $0 }
   ))
   .textFieldStyle(.plain)
   .font(.system(size: 12))
   .padding(.horizontal, 6)
   .padding(.vertical, 3)
   .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
 }
}
}

struct InfoFeldZahl: View {
let label: String
@Binding var wert: Double?

init(_ label: String, wert: Binding<Double?>) {
 self.label = label
 self._wert = wert
}

@State private var text = ""

var body: some View {
 HStack {
   Text(label)
     .font(.system(size: 12))
     .foregroundStyle(.secondary)
     .frame(width: 200, alignment: .leading)
   TextField("", text: Binding(
     get: { wert.map { String($0) } ?? "" },
     set: { wert = Double($0) }
   ))
   .textFieldStyle(.plain)
   .font(.system(size: 12))
   .padding(.horizontal, 6)
   .padding(.vertical, 3)
   .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
 }
}
}

struct InfoPickerOptional: View {
let label: String
@Binding var selection: String?
let optionen: [String]

init(_ label: String, selection: Binding<String?>, optionen: [String]) {
 self.label = label
 self._selection = selection
 self.optionen = optionen
}

var body: some View {
 HStack {
   Text(label)
     .font(.system(size: 12))
     .foregroundStyle(.secondary)
     .frame(width: 160, alignment: .leading)
   Picker("", selection: Binding(
     get: { selection ?? "" },
     set: { selection = $0.isEmpty ? nil : $0 }
   )) {
     Text("--").tag("")
     ForEach(optionen, id: \.self) { Text($0).tag($0) }
   }
   .labelsHidden()
   .pickerStyle(.menu)
 }
}
}

struct InfoPickerEnum<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
let label: String
@Binding var selection: T
let displayName: KeyPath<T, String>

init(_ label: String, selection: Binding<T>, displayName: KeyPath<T, String>) {
 self.label = label
 self._selection = selection
 self.displayName = displayName
}

var body: some View {
 HStack {
   Text(label)
     .font(.system(size: 12))
     .foregroundStyle(.secondary)
     .frame(width: 160, alignment: .leading)
   Picker("", selection: $selection) {
     ForEach(Array(T.allCases), id: \.self) { option in
       Text(option[keyPath: displayName]).tag(option)
     }
   }
   .labelsHidden()
   .pickerStyle(.menu)
 }
}
}

private func formatEuro(_ value: Double) -> String {
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.currencyCode = "EUR"
formatter.locale = Locale(identifier: "de_DE")
return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value)) €"
}

// MARK: - Tab Fallakte (Wrapper mit 2 Sub-Tabs: Basisdaten + Dokumente & KI-Analyse)

struct TabFallakte: View {
let viewModel: CaseDetailViewModel
var kiMode: Bool = true
@State private var subTab = 0

var body: some View {
 VStack(spacing: 0) {
   Picker("", selection: $subTab) {
     Text("Basisdaten").tag(0)
     Text("Dokumente & KI-Analyse").tag(1)
   }
   .pickerStyle(.segmented)
   .padding(.bottom, 16)

   if subTab == 0 {
     TabBasisdaten(viewModel: viewModel)
   } else {
     TabDokumenteAnalyse(viewModel: viewModel, kiMode: kiMode)
   }
 }
}
}

