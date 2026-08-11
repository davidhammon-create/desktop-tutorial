import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// LINSE 1 -- STREIT (Lexara)
// PDF Interface Design, Teil IV, Abb. 12
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// „Der Konflikt ist da. … Was ist der beste Weg durch etwas, das
// bereits läuft."
// Merkmale:
// (cid:127) RVG-Rechner (100 % Formel)
// (cid:127) Frist-Formel (100 % Formel)
// (cid:127) „Option D · Nichts tun" ist immer sichtbar und durchgerechnet
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct StreitLinse: View {
let vorgangId: UUID
@Bindable var store: VorgangStore = .shared
@State private var gewichte: [String: Double] = ["Erwartungswert": 0.5, "Risiko (niedrig)": 0.5]
@State private var filter: Herkunft? = nil
@State private var risikoAversion: Double = 0.5

private var vorgang: Vorgang? { store.vorgang(vorgangId) }

var body: some View {
  if let v = vorgang {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        kopfInfo(v)
        optionenReihe(v)
        HStack(alignment: .top, spacing: 14) {
          rvgBlock(v)
          fristBlock(v)
        }
        rechenwerkBlock(v)
        GewichtungsPanel(gewichte: $gewichte, optionen: v.optionen.filter { !$0.istVorgeschichte })
      }
      .padding(16)
    }
  } else {
    Text("Vorgang nicht gefunden").foregroundStyle(Premium.text)
  }
}

// MARK: Rechenwerk -- Monte-Carlo · Risikonutzen · Vergleichskorridor

/// Beste bewertete Option (Empfehlung, sonst höchster EV).
private func leitOption(_ v: Vorgang) -> VorgangOption? {
  let aktive = v.optionen.filter { !$0.istVorgeschichte }
  if let empf = v.empfehlung?.optionId, let o = aktive.first(where: { $0.id == empf }) {
    return o
  }
  return aktive.max(by: { ($0.bewertung.ev?.wert ?? -.infinity) < ($1.bewertung.ev?.wert ?? -.infinity) })
}

@ViewBuilder
private func rechenwerkBlock(_ v: Vorgang) -> some View {
  if let o = leitOption(v), o.bewertung.ev != nil {
    let mc = Rechenwerk.monteCarlo(o, risikoAversion: risikoAversion)
    let korridor = Rechenwerk.vergleichskorridor(o, risikoAversion: risikoAversion)

    InterfaceKarte(ebene: 2) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 6) {
          Herkunftsmarke(herkunft: .formel, groesse: 8)
          Text("RECHENWERK · MONTE-CARLO · 100 % FORMEL")
            .font(.system(size: 10, weight: .semibold))
            .kerning(0.4)
            .foregroundStyle(InterfacePalette.berechnet)
          Spacer()
          QuellenInfo(auskunft: .formel(
            "Ergebnisverteilung der Option „\(o.label)\u{201C}",
            formel: mc.modell,
            datenbasis: "Ihre Optionswerte (P, best, worst, Kosten) -- keine KI"
          ))
        }

        // Verteilung
        HStack(spacing: 14) {
          rwKennzahl("P10 (pessimistisch)", mc.p10, kritischWennNegativ: true)
          rwKennzahl("Median", mc.median, kritischWennNegativ: true)
          rwKennzahl("P90 (optimistisch)", mc.p90, kritischWennNegativ: false)
          rwKennzahl("P(Gewinn)", mc.gewinnQuote, prozent: true)
          rwKennzahl("Zertitätsäquivalent", mc.zertitaet, kritischWennNegativ: true)
        }

        // Risikoaversion
        HStack(spacing: 10) {
          Text("Risikoaversion")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(InterfacePalette.sekundaer)
          Slider(value: $risikoAversion, in: 0.05...1.0)
            .frame(maxWidth: 220)
          Text(risikoAversion < 0.35 ? "risikofreudig" : (risikoAversion > 0.65 ? "vorsichtig" : "neutral"))
            .font(.system(size: 10.5))
            .foregroundStyle(Premium.textFaint)
          QuellenInfo(auskunft: .formel(
            "Wirkung des Reglers",
            formel: "l = Aversion / Spannweite -> CE = -(1/l)·ln E[e^(-lX)]",
            datenbasis: "Exponentieller Nutzen (Standardmodell der Entscheidungstheorie)"
         ))
       }

       Divider().overlay(InterfacePalette.trennlinie)

       // Vergleichskorridor
       HStack(spacing: 6) {
         Text("VERGLEICHSKORRIDOR (ZOPA)")
           .font(.system(size: 10, weight: .semibold))
           .kerning(0.4)
           .foregroundStyle(InterfacePalette.berechnet)
         Spacer()
         QuellenInfo(auskunft: .formel(
           "Verhandlungsbereich zwischen unserem Walk-away und der geschätzten Schmerzgrenze der Gegenseite",
           formel: "Unten = CE · Oben = P x best + Kostenersparnis · Anker = Unten + 0,7 x Breite",
           datenbasis: "Ihre Optionswerte; Gegnerseite konservativ gespiegelt"
         ))
       }

       if korridor.existiert {
         HStack(spacing: 14) {
           rwKennzahl("Walk-away (unten)", korridor.untergrenze, kritischWennNegativ: true)
           rwKennzahl("Anker (Empfehlung)", korridor.anker, hervor: true)
           rwKennzahl("Schmerzgrenze Gegner", korridor.obergrenze)
         }
       } else {
         Text("Kein Korridor: Die risikoadjustierte Prozessfortführung dominiert derzeit einen Vergleich.")
           .font(.system(size: 11))
           .foregroundStyle(InterfacePalette.kritisch)
       }
     }
     .padding(12)
   }
 }
}

private func rwKennzahl(_ label: String, _ w: WertMitHerkunft, prozent: Bool = false, kritischWennNegativ: Bool = false, hervor: Bool = false) -> some View {
 VStack(alignment: .leading, spacing: 3) {
   Text(label.uppercased())
     .font(.system(size: 8.5, weight: .bold))
     .kerning(0.4)
     .foregroundStyle(InterfacePalette.sekundaer)
     .lineLimit(1)
   HStack(spacing: 5) {
     Herkunftsmarke(herkunft: w.herkunft, groesse: 6)
     Text(prozent ? InterfaceZahl.prozent(w.wert) : InterfaceZahl.waehrung(w.wert))
       .font(.system(size: hervor ? 15 : 13, weight: hervor ? .bold : .semibold))
       .monospacedDigit()
       .foregroundStyle(
         hervor ? InterfacePalette.berechnet
         : (kritischWennNegativ && w.wert < 0 ? InterfacePalette.kritisch : Premium.text)
       )
   }
 }
 .help(w.quelle)
}

// Streit-Header
private func kopfInfo(_ v: Vorgang) -> some View {
 HStack(spacing: 20) {
   VStack(alignment: .leading, spacing: 2) {
     Text("Streitwert")
       .font(.system(size: 10, weight: .semibold))
       .kerning(0.4)
       .foregroundStyle(InterfacePalette.sekundaer)
     Text(InterfaceZahl.waehrung(v.volumen, mitVorzeichen: false))
       .font(.system(size: 20, weight: .bold))
       .monospacedDigit()
       .foregroundStyle(Premium.text)
   }
   if let frist = v.fristen.min(by: { $0.tageBisAblauf < $1.tageBisAblauf }) {
     VStack(alignment: .leading, spacing: 2) {
       Text("Nächste Frist")
         .font(.system(size: 10, weight: .semibold))
         .kerning(0.4)
         .foregroundStyle(InterfacePalette.sekundaer)
       HStack(spacing: 6) {
         Herkunftsmarke(herkunft: .formel, groesse: 8)
         Text("\(frist.art) · \(frist.tageBisAblauf) Tage")
           .font(.system(size: 16, weight: .semibold))
           .monospacedDigit()
           .foregroundStyle(frist.kritisch ? InterfacePalette.kritisch : .white)
       }
     }
   }
   Spacer()
   HerkunftsFilter(aktiv: $filter, zaehler: zaehlerHerkunft(v))
 }
}

// Wege durch den Konflikt (mit Option D)
private func optionenReihe(_ v: Vorgang) -> some View {
 VStack(alignment: .leading, spacing: 8) {
   Text("WEGE DURCH DEN KONFLIKT")
     .font(.system(size: 10, weight: .semibold))
     .kerning(0.4)
     .foregroundStyle(InterfacePalette.sekundaer)

   LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 10)], spacing: 10) {
     ForEach(v.optionen.filter { !$0.istVorgeschichte }) { o in
       optionKarte(o)
     }
   }
 }
}

private func optionKarte(_ o: VorgangOption) -> some View {
 InterfaceKarte(ebene: 2) {
   VStack(alignment: .leading, spacing: 8) {
     Text(o.label)
       .font(.system(size: 13, weight: .semibold))
       .foregroundStyle(Premium.text)

     if let ev = o.bewertung.ev {
       WertBohrer(
         wert: ev,
         label: "Erwartungswert",
         kinder: [
           ("P(Erfolg)", o.chancen.pErfolg),
           ("Best", o.chancen.best),
           ("Worst", o.chancen.worst)
         ]
       )
     }

     VStack(spacing: 4) {
       WertZeile(label: "P(Erfolg)", wert: o.chancen.pErfolg, format: { InterfaceZahl.prozent($0) })
       if let rav = o.bewertung.rav {
         WertZeile(label: "RAV", wert: rav)
       }
       if let kelly = o.bewertung.kelly {
         WertZeile(label: "Kelly", wert: kelly, format: { InterfaceZahl.prozent($0) })
       }
       HStack {
         Text("Kosten")
           .font(.system(size: 11, weight: .semibold))
           .foregroundStyle(InterfacePalette.sekundaer)
         Spacer()
         Text(InterfaceZahl.waehrung(o.kosten.summe, mitVorzeichen: false))
           .font(.system(size: 13, weight: .medium))
           .monospacedDigit()
           .foregroundStyle(Premium.text)
       }
       HStack {
         Text("Dauer")
           .font(.system(size: 11, weight: .semibold))
           .foregroundStyle(InterfacePalette.sekundaer)
         Spacer()
         Text("\(o.zeit.minMonate)-\(o.zeit.maxMonate) Mon.")
           .font(.system(size: 13, weight: .medium))
           .monospacedDigit()
           .foregroundStyle(Premium.text)
       }
     }
   }
   .padding(12)
 }
}

// RVG-Rechner
private func rvgBlock(_ v: Vorgang) -> some View {
 let rvg = Formelkaskade.rvg(streitwert: v.volumen)
 return InterfaceKarte(ebene: 2) {
   VStack(alignment: .leading, spacing: 6) {
     HStack {
       Herkunftsmarke(herkunft: .formel, groesse: 8)
       Text("RVG-RECHNER · 100 % FORMEL")
         .font(.system(size: 10, weight: .semibold))
         .kerning(0.4)
         .foregroundStyle(InterfacePalette.berechnet)
     }
     Text("Streitwert \(InterfaceZahl.waehrung(v.volumen, mitVorzeichen: false)) -> Tabelle § 13 RVG")
       .font(.system(size: 11))
       .foregroundStyle(InterfacePalette.sekundaer)
     rvgZeile("1,3 Verfahrensgebühr", rvg.verfahren)
     rvgZeile("1,2 Terminsgebühr", rvg.termin)
     rvgZeile("Auslagen + USt", rvg.auslagen + rvg.ust)
     Divider().overlay(InterfacePalette.trennlinie)
     rvgZeile("Gesamt", rvg.gesamt, fett: true)
   }
   .padding(12)
 }
}

private func rvgZeile(_ label: String, _ wert: Double, fett: Bool = false) -> some View {
 HStack {
   Text(label)
     .font(.system(size: 11, weight: fett ? .semibold : .regular))
     .foregroundStyle(fett ? .white : InterfacePalette.sekundaer)
   Spacer()
   Text(InterfaceZahl.waehrung(wert, mitVorzeichen: false))
     .font(.system(size: 12, weight: fett ? .bold : .medium, design: .monospaced))
     .monospacedDigit()
     .foregroundStyle(fett ? InterfacePalette.berechnet : .white)
 }
}

// Frist-Block
private func fristBlock(_ v: Vorgang) -> some View {
 InterfaceKarte(ebene: 2) {
   VStack(alignment: .leading, spacing: 6) {
     HStack {
       Herkunftsmarke(herkunft: .formel, groesse: 8)
       Text("FRIST · 100 % FORMEL")
         .font(.system(size: 10, weight: .semibold))
         .kerning(0.4)
         .foregroundStyle(InterfacePalette.berechnet)
     }
     if let f = v.fristen.first {
       Text("\(f.art)")
         .font(.system(size: 12, weight: .semibold))
         .foregroundStyle(Premium.text)
       Text("Fällig: \(fristDatum(f.datum)) · noch \(f.tageBisAblauf) Tage")
         .font(.system(size: 11, weight: .medium, design: .monospaced))
         .monospacedDigit()
         .foregroundStyle(f.kritisch ? InterfacePalette.kritisch : .white)
       Text(f.quelle)
         .font(.system(size: 10))
         .foregroundStyle(InterfacePalette.sekundaer)
     } else {
       Text("Keine Frist hinterlegt.").font(.system(size: 11)).foregroundStyle(InterfacePalette.sekundaer)
     }
   }
   .padding(12)
 }
}

private static let df: DateFormatter = {
 let f = DateFormatter()
 f.locale = Locale(identifier: "de_DE")
 f.dateFormat = "dd.MM.yyyy"
 return f
}()
private func fristDatum(_ d: Date) -> String { StreitLinse.df.string(from: d) }

private func zaehlerHerkunft(_ v: Vorgang) -> [Herkunft: Int] {
 var z: [Herkunft: Int] = [:]
 for o in v.optionen where !o.istVorgeschichte {
   for w in [o.chancen.pErfolg, o.chancen.best, o.chancen.worst, o.chancen.likely] {
     z[w.herkunft, default: 0] += 1
   }
 }
 return z
}
}

