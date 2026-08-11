import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// KOMMANDOFELD nK (PDF Interface Design, Abb. 9)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// Ein Feld für: Vorgänge · Werte · Befehle · Gesetze · Fristen · Hilfe
// „Juristen tippen schneller, als sie klicken."
//
// Diese Version läuft gegen den VorgangStore und versteht:
// Partei-Name -> Alle Vorgänge dieser Partei
// § 370 -> Alle Vorgänge, in denen die Norm hinterlegt ist
// > 1 mio -> Alle Vorgänge mit Volumen > 1 Mio
// frist 30 -> Alles fällig in 30 Tagen
// ?   -> Alles Unbestätigte im aktuellen Vorgang
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

struct Kommandofeld: View {
@Environment(\.dismiss) private var dismiss
@State private var text = ""
@State private var auswahl: Int = 0
let onOeffnen: (Vorgang) -> Void
var aktuellerVorgang: Vorgang? = nil

private var treffer: [KommandoTreffer] {
  KommandoParser.parse(text, store: VorgangStore.shared, kontext: aktuellerVorgang)
}

var body: some View {
  VStack(spacing: 0) {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(InterfacePalette.sekundaer)
      TextField("Vorgänge · Werte · Befehle · Gesetze · Fristen · Hilfe", text: $text)
        .textFieldStyle(.plain)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Premium.text)
        .onSubmit(oeffneAktuellenTreffer)
      Spacer()
      Text("nK")
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 4).fill(InterfacePalette.Material.l3))
        .foregroundStyle(InterfacePalette.sekundaer)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)

    if !treffer.isEmpty {
      Divider().overlay(InterfacePalette.trennlinie)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 4) {
          ForEach(Array(treffer.enumerated()), id: \.offset) { idx, t in
            treffer_zeile(t, aktiv: idx == auswahl)
              .onTapGesture {
                auswahl = idx
                oeffneAktuellenTreffer()
              }
          }
        }
        .padding(8)
      }
      .frame(maxHeight: 280)
    }

    Divider().overlay(InterfacePalette.trennlinie)
    HStack(spacing: 12) {
      Text("¿ öffnen")
      Text("n¿ in neuer Linse")
      Spacer()
      Text("esc schließen")
    }
    .font(.system(size: 10))
    .foregroundStyle(InterfacePalette.sekundaer)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
  .frame(width: 620)
  .background(RoundedRectangle(cornerRadius: 12).fill(InterfacePalette.Material.l1))
  .overlay(RoundedRectangle(cornerRadius: 12).stroke(InterfacePalette.trennlinie, lineWidth: 1))
}

private func treffer_zeile(_ t: KommandoTreffer, aktiv: Bool) -> some View {
  HStack(spacing: 10) {
    Image(systemName: t.symbol)
      .font(.system(size: 12, weight: .medium))
      .foregroundStyle(t.farbe)
      .frame(width: 20)
    VStack(alignment: .leading, spacing: 2) {
      Text(t.titel)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Premium.text)
      if let u = t.untertitel {
        Text(u)
          .font(.system(size: 11))
          .foregroundStyle(InterfacePalette.sekundaer)
      }
    }
    Spacer()
   Text(t.kategorie)
     .font(.system(size: 10, weight: .semibold))
     .foregroundStyle(InterfacePalette.sekundaer)
 }
 .padding(.horizontal, 12)
 .padding(.vertical, 8)
 .background(RoundedRectangle(cornerRadius: 6).fill(aktiv ? InterfacePalette.aktion.opacity(0.18) : Color.clear))
}

private func oeffneAktuellenTreffer() {
 guard let t = treffer[safe: auswahl], let v = t.vorgang else { return }
 onOeffnen(v)
 dismiss()
}
}

// MARK: - Kommando-Parser

struct KommandoTreffer: Identifiable {
let id = UUID()
let symbol: String
let farbe: Color
let titel: String
let untertitel: String?
let kategorie: String
let vorgang: Vorgang?
}

enum KommandoParser {
static func parse(_ query: String, store: VorgangStore, kontext: Vorgang?) -> [KommandoTreffer] {
 let q = query.trimmingCharacters(in: .whitespaces)
 guard !q.isEmpty else { return [] }

 var ergebnisse: [KommandoTreffer] = []

 // ? -- Alles Unbestätigte im aktuellen Vorgang
 if q == "?", let k = kontext {
   let ki = k.optionen.flatMap { o in
     [o.chancen.pErfolg, o.chancen.best, o.chancen.worst, o.chancen.likely].filter { $0.herkunft == .ki }
   }
   for wert in ki {
     ergebnisse.append(.init(
       symbol: "circle",
       farbe: InterfacePalette.vorgeschlagen,
       titel: "Unbestätigt: \(InterfaceZahl.dezimal(wert.wert))",
       untertitel: wert.quelle,
       kategorie: "Zweifel",
       vorgang: k
     ))
   }
   return ergebnisse
 }

 // § -- Norm-Suche
 if q.hasPrefix("§") {
   for v in store.vorgaenge where v.beschreibung.contains(q) || v.fristen.contains(where: { $0.quelle.contains(q) }) {
     ergebnisse.append(.init(
       symbol: "book.closed",
       farbe: InterfacePalette.sekundaer,
       titel: v.titel,
       untertitel: "Norm \(q) verknüpft",
       kategorie: "Norm",
       vorgang: v
     ))
   }
 }

 // > N mio | > N -- Schwellensuche
 if q.hasPrefix(">") {
   let rest = q.dropFirst().trimmingCharacters(in: .whitespaces)
   let (schwelle, _) = extractZahl(rest)
   if let s = schwelle {
     for v in store.vorgaenge where v.volumen >= s {
       ergebnisse.append(.init(
         symbol: "chart.line.uptrend.xyaxis",
         farbe: InterfacePalette.berechnet,
         titel: v.titel,
         untertitel: "Volumen: " + InterfaceZahl.waehrung(v.volumen, mitVorzeichen: false),
         kategorie: "Schwelle",
         vorgang: v
       ))
     }
   }
 }

 // frist N -- Zeitraumsuche
 if q.lowercased().hasPrefix("frist") {
   let rest = q.replacingOccurrences(of: "frist", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
   let (tage, _) = extractZahl(rest)
   let limit = Int(tage ?? 30)
   for v in store.vorgaenge {
     let dringlich = v.fristen.filter { $0.tageBisAblauf <= limit && $0.tageBisAblauf >= 0 }
     for f in dringlich {
       ergebnisse.append(.init(
         symbol: "calendar",
         farbe: f.kritisch ? InterfacePalette.kritisch : InterfacePalette.aktion,
         titel: "\(f.art) · \(f.tageBisAblauf) Tage",
         untertitel: v.titel,
         kategorie: "Frist",
         vorgang: v
       ))
     }
   }
 }

 // Standard: Volltextsuche
 for v in store.suche(q) {
   ergebnisse.append(.init(
     symbol: v.typ.linsenSymbol,
     farbe: InterfacePalette.aktion,
     titel: v.titel,
     untertitel: "\(v.typ.moduleName) · \(v.zustand.bezeichnung)",
     kategorie: "Vorgang",
     vorgang: v
   ))
 }

 return ergebnisse
}

private static func extractZahl(_ s: String) -> (Double?, String?) {
 var einheit: String?
 var zahltxt = s
 if let range = s.range(of: "mio", options: .caseInsensitive) {
   einheit = "mio"
   zahltxt = String(s[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
 }
 let normiert = zahltxt.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: ".", with: "")
 guard let wert = Double(normiert) else { return (nil, einheit) }
 return (einheit == "mio" ? wert * 1_000_000 : wert, einheit)
}
}

// MARK: - Safe subscript

private extension Array {
subscript(safe idx: Int) -> Element? {
 indices.contains(idx) ? self[idx] : nil
}
}

