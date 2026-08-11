import SwiftUI

// MARK: - Design-Modell Picker

struct FenlynineOSDesignModellPicker: View {
@Bindable var store: FenlynineOSDesignStore
var kompakt: Bool = false

var body: some View {
  if kompakt {
    Menu {
      modellAuswahl
    } label: {
      Label(store.aktivesModell.bezeichnung, systemImage: store.aktivesModell.symbol)
        .font(.caption)
    }
  } else {
    modellRaster
  }
}

@ViewBuilder
private var modellAuswahl: some View {
  Section("Arbeitsansicht") {
    ForEach(FenlynineOSDesignModell.allCases.filter(\.istArbeitsmodell)) { m in
      modellButton(m)
    }
  }
  Section("Präsentation") {
    ForEach(FenlynineOSDesignModell.allCases.filter(\.istPraesentationsmodell)) { m in
      modellButton(m)
    }
  }
  Section("Analyse") {
    ForEach([FenlynineOSDesignModell.treemap, .corporateHell]) { m in
      modellButton(m)
    }
  }
}

private func modellButton(_ m: FenlynineOSDesignModell) -> some View {
  Button {
    store.setzeModell(m)
  } label: {
    HStack {
      Text("Modell \(m.nummer): \(m.bezeichnung)")
      if m.istHauptmodell { Text("H") }
      if store.aktivesModell == m { Image(systemName: "checkmark") }
    }
  }
}

private var modellRaster: some View {
  VStack(alignment: .leading, spacing: 16) {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Design-Modell")
          .font(.headline)
        Text("Modell 3 (visionOS) ist Standard -- Glas, Systemblau, ruhige Flächen")
          .font(.caption)
          .foregroundStyle(FenlynineOSTheme.textSecondary)
      }
      Spacer()
      if store.aktivesModell.istHauptmodell {
        Text("HAUPTMODELL")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(FenlynineOSTheme.accent)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(FenlynineOSTheme.accent.opacity(0.15), in: Capsule())
      }
    }

    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
      ForEach(FenlynineOSDesignModell.allCases) { modell in
        FenlynineOSDesignModellKarte(
          modell: modell,
          istAktiv: store.aktivesModell == modell
        ) {
          withAnimation(.easeInOut(duration: 0.25)) {
            store.setzeModell(modell)
          }
        }
      }
    }
  }
}
}

struct FenlynineOSDesignModellKarte: View {
let modell: FenlynineOSDesignModell
let istAktiv: Bool
let action: () -> Void

private var vorschau: FenlynineOSDesignTokens { FenlynineOSDesignTokens.fuer(modell) }

var body: some View {
  Button(action: action) {
    VStack(alignment: .leading, spacing: 10) {
     HStack {
       Image(systemName: modell.symbol)
         .font(.title3)
         .foregroundStyle(vorschau.accent)
       VStack(alignment: .leading, spacing: 2) {
         HStack(spacing: 4) {
           Text("Modell \(modell.nummer)")
             .font(.caption2.bold())
             .foregroundStyle(FenlynineOSTheme.textTertiary)
           if modell.istHauptmodell {
             Text("H Standard")
               .font(.system(size: 8, weight: .bold))
               .foregroundStyle(FenlynineOSTheme.accent)
           }
         }
         Text(modell.bezeichnung)
           .font(.subheadline.weight(.semibold))
           .foregroundStyle(FenlynineOSTheme.textPrimary)
       }
       Spacer()
       if istAktiv {
         Image(systemName: "checkmark.circle.fill")
           .foregroundStyle(FenlynineOSTheme.accent)
       }
     }

     // Mini-Vorschau
     ZStack {
       RoundedRectangle(cornerRadius: 10, style: .continuous)
         .fill(vorschau.background)
       if vorschau.useGrid {
         OrganonRasterVorschau()
       }
       HStack(spacing: 6) {
         vorschauKnoten(vorschau, groesse: 28)
         vorschauKnoten(vorschau, groesse: 20)
         vorschauKnoten(vorschau, groesse: 14)
       }
     }
     .frame(height: 52)
     .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

     Text(modell.kurzbeschreibung)
       .font(.caption2)
       .foregroundStyle(FenlynineOSTheme.textSecondary)
       .lineLimit(2)
   }
   .padding(12)
   .background {
     if FenlynineOSTheme.useGlass {
       RoundedRectangle(cornerRadius: FenlynineOSDesign.cornerRadiusLarge, style: .continuous)
         .fill(.ultraThinMaterial)
         .overlay(
           RoundedRectangle(cornerRadius: FenlynineOSDesign.cornerRadiusLarge, style: .continuous)
             .stroke(istAktiv ? FenlynineOSTheme.accent.opacity(0.6) : FenlynineOSTheme.border, lineWidth: istAktiv ? 2 : 0.5)
         )
     } else {
       RoundedRectangle(cornerRadius: FenlynineOSDesign.cornerRadiusLarge, style: .continuous)
         .fill(FenlynineOSTheme.surfaceElevated)
         .overlay(
           RoundedRectangle(cornerRadius: FenlynineOSDesign.cornerRadiusLarge, style: .continuous)
             .stroke(istAktiv ? FenlynineOSTheme.accent : FenlynineOSTheme.border, lineWidth: istAktiv ? 2 : 1)
         )
     }
   }
 }
 .buttonStyle(.plain)
}

@ViewBuilder
private func vorschauKnoten(_ t: FenlynineOSDesignTokens, groesse: CGFloat) -> some View {
 switch t.organonStil {
 case .bubbles:
   Circle().fill(t.accent.opacity(0.35)).frame(width: groesse, height: groesse)
 case .metro:
   RoundedRectangle(cornerRadius: 2).fill(t.accent).frame(width: groesse * 1.5, height: 4)
 case .treemap:
   RoundedRectangle(cornerRadius: 2).fill(t.accent.opacity(0.4)).frame(width: groesse, height: groesse * 0.7)
 default:
   RoundedRectangle(cornerRadius: groesse * 0.25, style: .continuous)
     .fill(t.glassFill)
     .frame(width: groesse, height: groesse * 0.65)
     .overlay(RoundedRectangle(cornerRadius: groesse * 0.25).stroke(t.glassBorder, lineWidth: 0.5))
 }
}
}

struct OrganonRasterVorschau: View {
var body: some View {
 Canvas { ctx, size in
   let grid = 12.0
   for x in stride(from: 0, through: size.width, by: grid) {
     var p = Path()
     p.move(to: CGPoint(x: x, y: 0))
     p.addLine(to: CGPoint(x: x, y: size.height))
     ctx.stroke(p, with: .color(.white.opacity(0.06)), lineWidth: 0.5)
   }
   for y in stride(from: 0, through: size.height, by: grid) {
     var p = Path()
     p.move(to: CGPoint(x: 0, y: y))
     p.addLine(to: CGPoint(x: size.width, y: y))
     ctx.stroke(p, with: .color(.white.opacity(0.06)), lineWidth: 0.5)
   }
 }
}
}

// MARK: - visionOS Ambient-Hintergrund -> siehe FenlynineOSAppBackground.swift

// MARK: - Kontext-Leiste (Organisation)

struct FenlynineOSKontextLeiste: View {
let modul: String
let titel: String
var untertitel: String? = nil
var breadcrumb: [String] = []

var body: some View {
 HStack(spacing: 12) {
   VStack(alignment: .leading, spacing: 3) {
     HStack(spacing: 6) {
       Text(modul.uppercased())
         .font(.system(size: 9, weight: .bold))
         .foregroundStyle(FenlynineOSTheme.brand)
         .tracking(1.2)
       if !breadcrumb.isEmpty {
         Image(systemName: "chevron.right")
           .font(.system(size: 8))
           .foregroundStyle(FenlynineOSTheme.textTertiary)
         Text(breadcrumb.joined(separator: " · "))
           .font(.system(size: 9))
           .foregroundStyle(FenlynineOSTheme.textTertiary)
       }
     }
     Text(titel)
       .font(.system(size: 15, weight: .semibold))
       .foregroundStyle(FenlynineOSTheme.textPrimary)
     if let untertitel {
       Text(untertitel)
         .font(.caption2)
         .foregroundStyle(FenlynineOSTheme.textSecondary)
     }
   }
   Spacer()
 }
 .padding(.horizontal, 20)
 .padding(.vertical, 10)
}
}

