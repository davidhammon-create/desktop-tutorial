import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// ABO · FENSTER-FREISCHALTUNG -- Premium-Optik & Katalog
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Drei kumulativ gestaffelte Stufen (kompatibel zu AboPlan):
// Basis (0 €) -> Kernfenster für den Tagesbetrieb
// Kanzlei Pro (49 €) -> Mandatsarbeit inkl. Lexara, Organon, KI
// Imperium (99 €) -> Strategische Suite, alle Fenster
// Admin: immer alles. Gesperrte Fenster öffnen die Paywall statt Inhalt.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

extension AboPlan {
var stufeIndex: Int {
  switch self {
  case .frei: return 0
  case .kanzlei: return 1
  case .imperium: return 2
  }
}

var symbol: String {
  switch self {
  case .frei: return "square.stack.3d.up"
  case .kanzlei: return "building.columns.fill"
  case .imperium: return "crown.fill"
  }
}

/// Monochrome-fähige Akzentfarbe (eine Bedeutung pro Stufe).
var akzent: Color {
  switch self {
  case .frei: return Color(red: 0.45, green: 0.48, blue: 0.55)
  case .kanzlei: return Premium.action
  case .imperium: return Color(red: 0.78, green: 0.62, blue: 0.22)
  }
}

var kiEnthalten: Bool {
  self != .frei
}

var fensterAnzahlText: String {
  let n = freigeschalteteFenster.count
  return n == SeitenleistenEintrag.alleModulFenster.count
    ? "Alle \(n) Fenster"
    : "\(n) von \(SeitenleistenEintrag.alleModulFenster.count) Fenstern"
}

/// Alle Fenster, die diese Stufe (kumulativ) freischaltet -- ohne Admin-Zentrale.
var freigeschalteteFenster: [SeitenleistenEintrag] {
  SeitenleistenEintrag.alleModulFenster.filter { erlaubt($0) }
}

var gesperrteFenster: [SeitenleistenEintrag] {
  SeitenleistenEintrag.alleModulFenster.filter { !erlaubt($0) }
}
}

extension SeitenleistenEintrag {
/// Alle plan-relevanten Modul-Fenster (ohne reine Admin-Oberfläche).
static var alleModulFenster: [SeitenleistenEintrag] {
  let alle = AboPlan.basisModule
    .union(AboPlan.kanzleiModule)
    .union(AboPlan.imperiumModule)
  return alle.sorted { $0.bezeichnung.localizedCaseInsensitiveCompare($1.bezeichnung) == .orderedAscending }
}
}

// MARK: - Paywall (optisch neu)

struct AboPaywallView: View {
let eintrag: SeitenleistenEintrag
@ObservedObject private var store = KontoStore.shared
@State private var animiere = false

private var benoetigt: AboPlan { AboPlan.benoetigteStufe(fuer: eintrag) }
private var aktuell: AboPlan { store.aktuellesKonto?.plan ?? .frei }

var body: some View {
  ZStack {
    // Atmosphäre -- kein flaches Panel
    Premium.void.ignoresSafeArea()
    RadialGradient(
      colors: [benoetigt.akzent.opacity(0.14), .clear],
      center: .topLeading, startRadius: 40, endRadius: 520
    )
    .ignoresSafeArea()
    RadialGradient(
      colors: [Premium.action.opacity(0.06), .clear],
      center: .bottomTrailing, startRadius: 20, endRadius: 480
    )
    .ignoresSafeArea()

    ScrollView {
      VStack(spacing: 28) {
        hero
        stufenLeiste
        planRaster
       fensterMatrix
       fusszeile
     }
     .padding(.horizontal, 28)
     .padding(.vertical, 32)
     .frame(maxWidth: 980)
     .frame(maxWidth: .infinity)
   }
 }
 .onAppear {
   withAnimation(.easeOut(duration: 0.55)) { animiere = true }
 }
}

private var hero: some View {
 VStack(spacing: 14) {
   ZStack {
     Circle()
       .fill(benoetigt.akzent.opacity(0.12))
       .frame(width: 88, height: 88)
       .scaleEffect(animiere ? 1 : 0.85)
     Image(systemName: "lock.rectangle.stack.fill")
       .font(.system(size: 30, weight: .semibold))
       .foregroundStyle(benoetigt.akzent)
       .symbolEffect(.pulse, options: .repeating.speed(0.4), isActive: animiere)
   }

   Text(eintrag.bezeichnung)
     .font(.system(size: 26, weight: .semibold, design: .rounded))
     .foregroundStyle(Premium.text)

   Text("Dieses Fenster ist in „\(benoetigt.titel)" freigeschaltet.")
     .font(.system(size: 13))
     .foregroundStyle(Premium.textSoft)

   HStack(spacing: 8) {
     kapsel("Aktuell: \(aktuell.titel)", farbe: aktuell.akzent)
     kapsel("Benötigt: \(benoetigt.titel)", farbe: benoetigt.akzent)
     if store.aktuellesKonto?.istAdmin == true {
       kapsel("Admin · alle Fenster", farbe: Premium.computed)
     }
   }
 }
 .opacity(animiere ? 1 : 0)
 .offset(y: animiere ? 0 : 10)
}

private var stufenLeiste: some View {
 HStack(spacing: 0) {
   ForEach(Array(AboPlan.allCases.enumerated()), id: \.element.id) { i, plan in
     let erreicht = aktuell.stufeIndex >= plan.stufeIndex
     VStack(spacing: 6) {
       ZStack {
         Circle()
           .fill(erreicht ? plan.akzent : Premium.well)
           .frame(width: 22, height: 22)
         if erreicht {
           Image(systemName: "checkmark")
             .font(.system(size: 9, weight: .bold))
             .foregroundStyle(.white)
         }
       }
       Text(plan.titel)
         .font(.system(size: 10, weight: erreicht ? .semibold : .regular))
         .foregroundStyle(erreicht ? Premium.text : Premium.textFaint)
     }
     .frame(maxWidth: .infinity)
     if i < AboPlan.allCases.count - 1 {
       Rectangle()
         .fill(aktuell.stufeIndex > i ? plan.akzent.opacity(0.55) : Premium.hairline)
         .frame(height: 2)
         .offset(y: -10)
     }
   }
 }
 .padding(.vertical, 8)
 .padding(.horizontal, 20)
}

private var planRaster: some View {
 HStack(alignment: .top, spacing: 14) {
   ForEach(AboPlan.allCases) { plan in
     AboPlanPremiumKarte(
       plan: plan,
       hervorgehoben: plan == benoetigt,
       istAktuell: plan == aktuell,
       onUpgrade: {
         store.upgradeAnfordern(plan)
       }
     )
   }
 }
}

private var fensterMatrix: some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack {
     Text("Fenster-Freischaltung")
       .font(.system(size: 13, weight: .bold))
       .foregroundStyle(Premium.text)
     Spacer()
     Text(aktuell.fensterAnzahlText)
       .font(.system(size: 11, weight: .medium))
       .foregroundStyle(Premium.textSoft)
   }

   LazyVGrid(columns: [GridItem(.adaptive(minimum: 168), spacing: 8)], spacing: 8) {
     ForEach(SeitenleistenEintrag.alleModulFenster, id: \.self) { fenster in
       let frei = aktuell.erlaubt(fenster) || store.istAdmin
       let ziel = fenster == eintrag
       HStack(spacing: 8) {
         Image(systemName: frei ? fenster.symbol : "lock.fill")
           .font(.system(size: 11, weight: .semibold))
           .foregroundStyle(frei ? (ziel ? benoetigt.akzent : Premium.computed) : Premium.textFaint)
           .frame(width: 16)
         VStack(alignment: .leading, spacing: 1) {
           Text(fenster.bezeichnung)
             .font(.system(size: 10.5, weight: ziel ? .bold : .medium))
             .foregroundStyle(frei ? Premium.text : Premium.textFaint)
             .lineLimit(1)
           Text(AboPlan.benoetigteStufe(fuer: fenster).titel)
             .font(.system(size: 8.5))
             .foregroundStyle(Premium.textFaint)
         }
         Spacer(minLength: 0)
       }
       .padding(.horizontal, 10)
       .padding(.vertical, 8)
       .background(
         RoundedRectangle(cornerRadius: 9, style: .continuous)
           .fill(ziel ? benoetigt.akzent.opacity(0.10) : Premium.panel.opacity(0.55))
       )
       .overlay(
         RoundedRectangle(cornerRadius: 9, style: .continuous)
           .stroke(ziel ? benoetigt.akzent.opacity(0.45) : Premium.hairline, lineWidth: 1)
       )
       .opacity(frei ? 1 : 0.72)
     }
   }
 }
 .padding(16)
 .background(
   RoundedRectangle(cornerRadius: 14, style: .continuous)
     .fill(Premium.panel.opacity(0.45))
 )
 .overlay(
   RoundedRectangle(cornerRadius: 14, style: .continuous)
     .stroke(Premium.hairline, lineWidth: 1)
 )
}

private var fusszeile: some View {
 VStack(spacing: 6) {
   if let konto = store.aktuellesKonto, !konto.istAdmin, store.hatOffeneAnfrage(kontoId: konto.id) {
     Label("Upgrade-Anfrage gesendet -- der Administrator schaltet frei.", systemImage: "checkmark.circle.fill")
       .font(.system(size: 12, weight: .medium))
       .foregroundStyle(Premium.computed)
   }
   Text("Freischaltung über den Administrator dieser Installation. KI wird zusätzlich verbrauchsgenau abgerechnet (ab Kanzlei Pro).")
     .font(.system(size: 10))
     .foregroundStyle(Premium.textFaint)
     .multilineTextAlignment(.center)
 }
 .padding(.bottom, 20)
}

private func kapsel(_ text: String, farbe: Color) -> some View {
 Text(text)
   .font(.system(size: 10, weight: .semibold))
   .foregroundStyle(farbe)
   .padding(.horizontal, 10)
   .padding(.vertical, 5)
   .background(Capsule().fill(farbe.opacity(0.12)))
   .overlay(Capsule().stroke(farbe.opacity(0.35), lineWidth: 1))
}
}

// MARK: - Plan-Karte

struct AboPlanPremiumKarte: View {
let plan: AboPlan
var hervorgehoben: Bool = false
var istAktuell: Bool = false
var onUpgrade: (() -> Void)? = nil
@ObservedObject private var store = KontoStore.shared

var body: some View {
 VStack(alignment: .leading, spacing: 14) {
   HStack(alignment: .top) {
     Image(systemName: plan.symbol)
       .font(.system(size: 16, weight: .semibold))
       .foregroundStyle(plan.akzent)
       .frame(width: 34, height: 34)
       .background(RoundedRectangle(cornerRadius: 9).fill(plan.akzent.opacity(0.12)))
     Spacer()
     if hervorgehoben {
       Text("BENÖTIGT")
         .font(.system(size: 8, weight: .black))
         .kerning(0.6)
         .foregroundStyle(.white)
         .padding(.horizontal, 7).padding(.vertical, 4)
         .background(Capsule().fill(plan.akzent))
     } else if istAktuell {
       Text("AKTIV")
         .font(.system(size: 8, weight: .black))
         .kerning(0.6)
         .foregroundStyle(Premium.computed)
         .padding(.horizontal, 7).padding(.vertical, 4)
         .background(Capsule().fill(Premium.computed.opacity(0.15)))
     }
   }

   VStack(alignment: .leading, spacing: 4) {
     Text(plan.titel)
       .font(.system(size: 16, weight: .bold))
       .foregroundStyle(Premium.text)
     Text(plan.preisText)
       .font(.system(size: 22, weight: .semibold, design: .rounded))
       .foregroundStyle(hervorgehoben ? plan.akzent : Premium.text)
     Text(plan.fensterAnzahlText)
       .font(.system(size: 10, weight: .medium))
       .foregroundStyle(Premium.textFaint)
   }

   Text(plan.untertitel)
     .font(.system(size: 11))
     .foregroundStyle(Premium.textSoft)
     .fixedSize(horizontal: false, vertical: true)

   VStack(alignment: .leading, spacing: 6) {
     ForEach(plan.leistungen, id: \.self) { l in
       HStack(alignment: .top, spacing: 7) {
         Image(systemName: "checkmark.circle.fill")
           .font(.system(size: 10))
           .foregroundStyle(Premium.computed)
           .padding(.top, 1)
         Text(l)
           .font(.system(size: 11))
           .foregroundStyle(Premium.textSoft)
           .fixedSize(horizontal: false, vertical: true)
       }
     }
   }

   Spacer(minLength: 0)

   if istAktuell {
     Text("Ihr aktuelles Abo")
       .font(.system(size: 11, weight: .semibold))
       .foregroundStyle(Premium.textFaint)
       .frame(maxWidth: .infinity)
       .padding(.vertical, 10)
       .background(RoundedRectangle(cornerRadius: 9).fill(Premium.well))
   } else if plan.stufeIndex > (store.aktuellesKonto?.plan.stufeIndex ?? 0),
        let konto = store.aktuellesKonto, !konto.istAdmin {
     Button {
       onUpgrade?()
     } label: {
       Text(store.hatOffeneAnfrage(kontoId: konto.id) ? "Anfrage offen" : "Upgrade anfordern")
         .font(.system(size: 12, weight: .semibold))
         .foregroundStyle(.white)
         .frame(maxWidth: .infinity)
         .padding(.vertical, 10)
         .background(
           RoundedRectangle(cornerRadius: 9, style: .continuous)
             .fill(plan.akzent)
         )
     }
     .buttonStyle(.plain)
     .disabled(store.hatOffeneAnfrage(kontoId: konto.id))
   } else if plan.stufeIndex < (store.aktuellesKonto?.plan.stufeIndex ?? 0) {
     Text("In Ihrem Abo enthalten")
       .font(.system(size: 11, weight: .medium))
       .foregroundStyle(Premium.computed)
       .frame(maxWidth: .infinity)
       .padding(.vertical, 10)
   }
 }
 .padding(16)
 .frame(maxWidth: .infinity, minHeight: 380, alignment: .top)
 .background(
   RoundedRectangle(cornerRadius: 16, style: .continuous)
     .fill(.ultraThinMaterial)
     .overlay(
       RoundedRectangle(cornerRadius: 16, style: .continuous)
         .fill(Premium.panel.opacity(AppearanceStore.shared.istAtelier ? 0.72 : 0.55))
     )
 )
 .overlay(
   RoundedRectangle(cornerRadius: 16, style: .continuous)
     .stroke(hervorgehoben ? plan.akzent.opacity(0.55) : Premium.hairline, lineWidth: hervorgehoben ? 1.5 : 1)
 )
 .shadow(color: .black.opacity(hervorgehoben ? 0.18 : 0.06), radius: hervorgehoben ? 18 : 8, y: hervorgehoben ? 8 : 3)
}
}

// MARK: - Abo-Übersicht (Einstellungen)

struct AboFensterUebersichtView: View {
@ObservedObject private var store = KontoStore.shared

private var plan: AboPlan { store.aktuellesKonto?.plan ?? .frei }

var body: some View {
 VStack(alignment: .leading, spacing: 16) {
   HStack(alignment: .firstTextBaseline) {
     VStack(alignment: .leading, spacing: 4) {
       Text("Abo & Fenster-Freischaltung")
         .font(.system(size: 15, weight: .bold))
         .foregroundStyle(Premium.text)
       Text("Je nach Stufe sind bestimmte Fenster freigeschaltet -- bis Imperium alle.")
         .font(.system(size: 11))
         .foregroundStyle(Premium.textSoft)
     }
     Spacer()
     VStack(alignment: .trailing, spacing: 2) {
       Text(plan.titel)
         .font(.system(size: 13, weight: .bold))
         .foregroundStyle(plan.akzent)
       Text(plan.fensterAnzahlText)
         .font(.system(size: 10))
         .foregroundStyle(Premium.textFaint)
     }
   }

   // Fortschritt
   GeometryReader { geo in
     ZStack(alignment: .leading) {
       Capsule().fill(Premium.well)
       Capsule()
         .fill(plan.akzent)
         .frame(width: max(8, geo.size.width * CGFloat(plan.freigeschalteteFenster.count) / CGFloat(max(1, SeitenleistenEintrag.alleModulFenster.count))))
     }
   }
   .frame(height: 6)

   HStack(alignment: .top, spacing: 12) {
     ForEach(AboPlan.allCases) { p in
       AboPlanPremiumKarte(
         plan: p,
         hervorgehoben: p == plan,
         istAktuell: p == plan,
         onUpgrade: { store.upgradeAnfordern(p) }
       )
     }
   }

   // Kurzliste freigeschaltet / gesperrt
   HStack(alignment: .top, spacing: 12) {
     fensterListe(
       titel: "Freigeschaltet",
       symbol: "checkmark.seal.fill",
       farbe: Premium.computed,
       eintraege: plan.freigeschalteteFenster
     )
     fensterListe(
       titel: "Noch gesperrt",
       symbol: "lock.fill",
       farbe: Premium.textFaint,
       eintraege: store.istAdmin ? [] : plan.gesperrteFenster
     )
   }
 }
 .padding(16)
 .background(
   RoundedRectangle(cornerRadius: 14, style: .continuous)
     .fill(Premium.panel.opacity(0.5))
 )
 .overlay(
   RoundedRectangle(cornerRadius: 14, style: .continuous)
     .stroke(Premium.hairline, lineWidth: 1)
 )
}

private func fensterListe(titel: String, symbol: String, farbe: Color, eintraege: [SeitenleistenEintrag]) -> some View {
 VStack(alignment: .leading, spacing: 8) {
   Label(titel, systemImage: symbol)
     .font(.system(size: 11, weight: .bold))
     .foregroundStyle(farbe)
   if eintraege.isEmpty {
     Text(store.istAdmin ? "Administrator -- alle Fenster offen." : "Keine")
       .font(.system(size: 10))
       .foregroundStyle(Premium.textFaint)
   } else {
     ForEach(eintraege, id: \.self) { e in
       HStack(spacing: 6) {
         Image(systemName: e.symbol)
           .font(.system(size: 9))
           .frame(width: 12)
         Text(e.bezeichnung)
           .font(.system(size: 10.5))
           .lineLimit(1)
         Spacer()
         Text(AboPlan.benoetigteStufe(fuer: e).titel)
           .font(.system(size: 8.5, weight: .medium))
           .foregroundStyle(Premium.textFaint)
       }
       .foregroundStyle(Premium.textSoft)
     }
   }
 }
 .padding(12)
 .frame(maxWidth: .infinity, alignment: .leading)
 .background(RoundedRectangle(cornerRadius: 10).fill(Premium.well.opacity(0.55)))
}
}

// MARK: - Studio-Sperrchip

struct AboFensterSperrBadge: View {
let eintrag: SeitenleistenEintrag
var body: some View {
 let plan = AboPlan.benoetigteStufe(fuer: eintrag)
 HStack(spacing: 3) {
   Image(systemName: "lock.fill")
     .font(.system(size: 8, weight: .bold))
   Text(plan.titel)
     .font(.system(size: 8, weight: .bold))
 }
 .foregroundStyle(plan.akzent)
 .padding(.horizontal, 6)
 .padding(.vertical, 3)
 .background(Capsule().fill(plan.akzent.opacity(0.12)))
 .overlay(Capsule().stroke(plan.akzent.opacity(0.35), lineWidth: 1))
 .help("Freigeschaltet ab \(plan.titel) (\(plan.preisText))")
}
}

