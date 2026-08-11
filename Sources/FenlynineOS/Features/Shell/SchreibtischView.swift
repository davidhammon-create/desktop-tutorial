import SwiftUI

// MARK: - Schreibtisch (systemweite Multiview + Verbundnetz)
//
// Fenstermodus: Strategos, Opportunisma, Lexara, Lagebild als Kacheln.
// Fokus-Fenster ist voll interaktiv; Mini-Kacheln sind Vorschau (Klick = Fokus).

enum SchreibtischAnsicht: String, CaseIterable {
case fenster, kausalgraph, verknuepfung, advocatus, verbund

var bezeichnung: String {
  switch self {
  case .fenster: return "Fenster"
  case .kausalgraph: return "Kausalgraph"
  case .verknuepfung: return "Verknüpfen"
  case .advocatus: return "Advocatus"
  case .verbund: return "Verbund"
  }
}

var symbol: String {
  switch self {
  case .fenster: return "rectangle.3.group.fill"
  case .kausalgraph: return "point.3.connected.trianglepath.dotted"
  case .verknuepfung: return "link.circle.fill"
  case .advocatus: return "waveform.circle.fill"
  case .verbund: return "circle.hexagongrid.fill"
  }
}
}

enum SchreibtischModul: String, CaseIterable, Identifiable, Codable {
case strategos
case opportunisma
case lexara
case lagebild

var id: String { rawValue }

var eintrag: SeitenleistenEintrag {
  switch self {
  case .strategos: return .strategos
  case .opportunisma: return .opportunisma
  case .lexara: return .lexara
  case .lagebild: return .dashboard
  }
}

var titel: String {
  switch self {
  case .strategos: return "Strategos"
  case .opportunisma: return "Opportunisma"
  case .lexara: return "Lexara"
  case .lagebild: return "Lagebild"
  }
}

var untertitel: String {
  switch self {
  case .strategos: return "Enterprise · Verträge · Szenarien"
  case .opportunisma: return "Machtstrategie · Lagebild · Module"
  case .lexara: return "Mandate · Fälle · Verfahren"
  case .lagebild: return "KPIs · Risiko · Koordination"
  }
}
}

struct SchreibtischView: View {
@State private var fokus: SchreibtischModul = .strategos
@State private var ansicht: SchreibtischAnsicht = .fenster
@Bindable private var appearance = AppearanceStore.shared

private let abstand: CGFloat = 10
private let kopfHoehe: CGFloat = 36
private let miniBreite: CGFloat = 200

var body: some View {
  VStack(alignment: .leading, spacing: 10) {
    kopfzeile

    Group {
      switch ansicht {
      case .fenster:
        fensterAnsicht
      case .kausalgraph:
        FenlynineOSKernCockpitView(store: FenlynineOSKernStore.shared, modulOeffnen: modulOeffnen, verknuepfungsModus: false)
      case .verknuepfung:
        FenlynineOSKernCockpitView(store: FenlynineOSKernStore.shared, modulOeffnen: modulOeffnen, verknuepfungsModus: true)
      case .advocatus:
        FenlynineOSAdvocatusView(store: FenlynineOSKernStore.shared)
      case .verbund:
        SchreibtischVerbundnetzView(
          store: SchreibtischVerbundnetzStore.shared,
          modulOeffnen: modulOeffnen
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .layoutPriority(1)
 }
 .padding(12)
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .background(Premium.void)
}

private func modulOeffnen(_ modul: SchreibtischModul) {
 withAnimation(.spring(duration: 0.28)) {
   fokus = modul
   ansicht = .fenster
 }
}

// MARK: - Fenstermodus (HStack, kein scaleEffect / kein ZStack-Offset)

private var fensterAnsicht: some View {
 let andere = SchreibtischModul.allCases.filter { $0 != fokus }

 return HStack(alignment: .top, spacing: abstand) {
   SchreibtischFenster(
     modul: fokus,
     istFokus: true,
     kopfHoehe: kopfHoehe,
     aktivieren: {}
   )
   .frame(maxWidth: .infinity, maxHeight: .infinity)
   .layoutPriority(1)

   VStack(spacing: abstand) {
     ForEach(andere) { modul in
       SchreibtischFenster(
         modul: modul,
         istFokus: false,
         kopfHoehe: kopfHoehe,
         aktivieren: {
           withAnimation(.spring(duration: 0.28)) { fokus = modul }
         }
       )
       .frame(maxWidth: .infinity, maxHeight: .infinity)
     }
   }
   .frame(width: miniBreite)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
}

private var kopfzeile: some View {
 HStack(spacing: 10) {
   Image(systemName: ansicht.symbol)
     .foregroundStyle(Premium.action)
   VStack(alignment: .leading, spacing: 1) {
     Text("Schreibtisch")
       .font(.subheadline.bold())
       .foregroundStyle(Premium.text)
     Text(ansicht == .fenster
       ? "Fenstermodus -- Fokus bearbeiten, Mini-Kacheln zum Umschalten"
       : ansicht == .advocatus
       ? "Live-Protokoll -- Aussagen werden zu EREIGNIS-Knoten"
       : ansicht == .verknuepfung
       ? "Kante ziehen -> Typ wählen -> Rechenkern aktualisiert"
       : "Ein Graph, drei Denkrichtungen")
       .font(.caption2)
       .foregroundStyle(Premium.textSoft)
   }
   Spacer()

   Picker("Ansicht", selection: $ansicht) {
     ForEach(SchreibtischAnsicht.allCases, id: \.self) { a in
       Label(a.bezeichnung, systemImage: a.symbol).tag(a)
     }
   }
   .pickerStyle(.segmented)
   .frame(maxWidth: 400)

   if ansicht == .fenster {
     // Alle vier Module sichtbar -- kein horizontales Abschneiden
     HStack(spacing: 5) {
       ForEach(SchreibtischModul.allCases) { modul in
         Button {
           withAnimation(.spring(duration: 0.28)) { fokus = modul }
         } label: {
           HStack(spacing: 3) {
             Image(systemName: modul.eintrag.macSettingsSymbol)
               .font(.system(size: 9))
             Text(modul.titel)
               .font(.system(size: 10, weight: fokus == modul ? .bold : .regular))
               .lineLimit(1)
               .minimumScaleFactor(0.85)
           }
           .foregroundStyle(fokus == modul ? Premium.text : Premium.textSoft)
           .padding(.horizontal, 8).padding(.vertical, 5)
           .background(
             fokus == modul
               ? modul.eintrag.macSettingsIconColor.opacity(appearance.istAtelier ? 0.14 : 0.22)
               : Premium.well,
             in: Capsule()
           )
           .overlay(Capsule().stroke(
             fokus == modul ? modul.eintrag.macSettingsIconColor.opacity(0.45) : Premium.hairline,
             lineWidth: 1
           ))
           .contentShape(Capsule())
         }
         .buttonStyle(.plain)
       }
     }
     .layoutPriority(1)
   }
 }
}
}

// MARK: - Einzelnes Schreibtisch-Fenster

struct SchreibtischFenster: View {
let modul: SchreibtischModul
let istFokus: Bool
let kopfHoehe: CGFloat
let aktivieren: () -> Void
@Bindable private var appearance = AppearanceStore.shared

var body: some View {
 VStack(spacing: 0) {
   fensterKopf
     .frame(height: kopfHoehe)
     .contentShape(Rectangle())
     .onTapGesture {
       if !istFokus { aktivieren() }
     }

   Group {
     if istFokus {
       // Eigener Stack nur für Fokus-Modul (Studio hat oft keinen).
       // Titel bleiben leer via fensterModus in den Modul-Views.
       NavigationStack {
         vollerModulInhalt
           .frame(maxWidth: .infinity, maxHeight: .infinity)
       }
       .environment(\.fenlynineOSFensterModus, true)
       .environment(\.fenlynineOSVergleichSpalte, false)
       .environment(\.fenlynineOSGlasModus, .kein)
       .environment(\.fenlynineOSVisionOSChrome, false)
       .background(Premium.void)
     } else {
       Button(action: aktivieren) {
         SchreibtischMiniVorschau(modul: modul)
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .contentShape(Rectangle())
       }
       .buttonStyle(.plain)
       .help("\(modul.titel) vergrößern & bearbeiten")
     }
   }
   .frame(maxWidth: .infinity, maxHeight: .infinity)
   .clipped()
   .contentShape(Rectangle())
 }
 .background(
   RoundedRectangle(cornerRadius: 14, style: .continuous)
     .fill(appearance.istAtelier ? Premium.panel : Color(red: 0.09, green: 0.09, blue: 0.10))
 )
 .overlay(
   RoundedRectangle(cornerRadius: 14, style: .continuous)
     .stroke(
       istFokus
         ? modul.eintrag.macSettingsIconColor.opacity(0.55)
         : Premium.hairline,
       lineWidth: istFokus ? 1.5 : 1
     )
 )
 .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
 .shadow(color: .black.opacity(istFokus ? 0.18 : 0.08), radius: istFokus ? 12 : 6, y: 4)
}

private var fensterKopf: some View {
 HStack(spacing: 8) {
   Image(systemName: modul.eintrag.macSettingsSymbol)
     .font(.system(size: 11, weight: .semibold))
     .foregroundStyle(modul.eintrag.macSettingsIconColor)
   VStack(alignment: .leading, spacing: 0) {
     Text(modul.titel)
       .font(.system(size: 11, weight: .bold))
       .foregroundStyle(Premium.text)
     if istFokus {
       Text(modul.untertitel)
         .font(.system(size: 8))
         .foregroundStyle(Premium.textFaint)
         .lineLimit(1)
     }
   }
   Spacer()
   if istFokus {
     Text("AKTIV")
       .font(.system(size: 7, weight: .black))
       .foregroundStyle(modul.eintrag.macSettingsIconColor)
       .padding(.horizontal, 6).padding(.vertical, 2)
       .background(modul.eintrag.macSettingsIconColor.opacity(0.14), in: Capsule())
   } else {
     Image(systemName: "arrow.up.left.and.arrow.down.right")
       .font(.system(size: 9, weight: .bold))
       .foregroundStyle(Premium.textFaint)
   }
 }
 .padding(.horizontal, 12)
 .background(appearance.istAtelier ? Premium.well : Color.black.opacity(0.22))
}

@ViewBuilder
private var vollerModulInhalt: some View {
 switch modul {
 case .strategos:
   StrategosView()
     .fenlynineOSSFTypographyOnly()
 case .opportunisma:
   OpportunismaView()
 case .lexara:
   CaseListView()
 case .lagebild:
   HomeView(inVisionPanel: false)
 }
}
}

// MARK: - Leichte Mini-Vorschau (kein volles Modul -- Performance + keine Geister-Klicks)

struct SchreibtischMiniVorschau: View {
let modul: SchreibtischModul

var body: some View {
 VStack(spacing: 10) {
   Spacer(minLength: 8)
   Image(systemName: modul.eintrag.macSettingsSymbol)
     .font(.system(size: 26, weight: .semibold))
     .foregroundStyle(modul.eintrag.macSettingsIconColor.opacity(0.85))
   Text(modul.titel)
     .font(.system(size: 13, weight: .bold))
     .foregroundStyle(Premium.text)
   Text(modul.untertitel)
     .font(.system(size: 10))
     .foregroundStyle(Premium.textSoft)
     .multilineTextAlignment(.center)
     .padding(.horizontal, 10)
   Text("Klicken zum Öffnen")
     .font(.system(size: 9, weight: .semibold))
     .foregroundStyle(Premium.action)
     .padding(.horizontal, 8).padding(.vertical, 4)
     .background(Premium.action.opacity(0.12), in: Capsule())
   Spacer(minLength: 8)
 }
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .background(modul.eintrag.macSettingsIconColor.opacity(0.06))
}
}

