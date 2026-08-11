import SwiftUI

// MARK: - Advocatus Live-Modus (PDF Teil 4)

enum AdvocatusSprecher: String, CaseIterable, Identifiable {
case richter, eigen, zeuge, gegner, ich

var id: String { rawValue }

var bezeichnung: String {
  switch self {
  case .richter: return "Richter"
  case .eigen: return "Eigener Anwalt"
  case .zeuge: return "Zeuge"
  case .gegner: return "Gegenanwalt"
  case .ich: return "Ich"
  }
}
}

enum AdvocatusKlassifikation: String, CaseIterable, Identifiable {
case fakt, zusage, frist, widerspruch, risiko, notiz

var id: String { rawValue }

var bezeichnung: String { rawValue.capitalized }

var kantenTyp: FenlynineOSKernKantenTyp {
  switch self {
  case .fakt: return .begruendet
  case .zusage: return .bedingt
  case .frist: return .verschiebt_frist
  case .widerspruch: return .widerlegt
  case .risiko: return .erhoeht_risiko
  case .notiz: return .bedingt
  }
}
}

struct AdvocatusProtokollEintrag: Identifiable, Equatable {
let id: String
let ereignisId: String
let zeit: String
let sprecher: AdvocatusSprecher
let klassifikation: AdvocatusKlassifikation
let text: String
let wirkung: String
var analyse: AdvocatusAussageAnalyse
var fragen: [AdvocatusFrageAntwort]
var frageEingabe: String
}

struct FenlynineOSAdvocatusView: View {
@Bindable var store: FenlynineOSKernStore
@State private var eingabe = ""
@State private var sprecher: AdvocatusSprecher = .richter
@State private var klassifikation: AdvocatusKlassifikation = .fakt
@State private var zielKnotenId: String = ""
@State private var protokoll: [AdvocatusProtokollEintrag] = []
@State private var ausgewaehlteId: String?
@State private var frageLaufId: String?

private static let zeitFormatter: DateFormatter = {
  let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
}()

var body: some View {
  HSplitView {
    protokollBereich.frame(minWidth: 420)
    steuerung.frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
  }
}

// MARK: - Protokoll

private var protokollBereich: some View {
  VStack(alignment: .leading, spacing: 0) {
    HStack {
      Image(systemName: "waveform.circle.fill").foregroundStyle(FenlynineOSTheme.danger)
      Text("Advocatus -- Live-Protokoll").font(.subheadline.bold())
      Spacer()
      Text("\(protokoll.count) Aussagen")
        .font(.caption2).foregroundStyle(.secondary)
      Text(store.phase == .live ? "LIVE" : "Bereit")
        .font(.caption2.bold())
        .foregroundStyle(store.phase == .live ? FenlynineOSTheme.danger : .secondary)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(FenlynineOSTheme.danger.opacity(0.12), in: Capsule())
    }
    .padding(12)
    Divider()

    ScrollView {
      if protokoll.isEmpty {
        Text("Protokoll leer -- Aussagen erfassen per Tippen (deterministisch, ohne KI-Zwang)")
          .font(.caption).foregroundStyle(.secondary)
          .padding()
      } else {
        LazyVStack(alignment: .leading, spacing: 8) {
         ForEach($protokoll) { $eintrag in
           protokollZeile(eintrag: $eintrag)
         }
       }
       .padding(12)
     }
   }

   if let konter = store.hoechsteOption {
     konterTipp(konter)
   }
 }
}

private func protokollZeile(eintrag: Binding<AdvocatusProtokollEintrag>) -> some View {
 let istOffen = ausgewaehlteId == eintrag.wrappedValue.id
 return VStack(alignment: .leading, spacing: 0) {
   Button {
     withAnimation(.easeOut(duration: 0.2)) {
       ausgewaehlteId = istOffen ? nil : eintrag.wrappedValue.id
     }
   } label: {
     HStack(alignment: .top, spacing: 8) {
       Text(eintrag.wrappedValue.zeit)
         .font(.caption2.monospacedDigit()).foregroundStyle(.secondary).frame(width: 42)
       VStack(alignment: .leading, spacing: 2) {
         HStack(spacing: 6) {
           Text(eintrag.wrappedValue.sprecher.bezeichnung)
             .font(.caption2.bold()).foregroundStyle(FenlynineOSTheme.accent)
           Text(eintrag.wrappedValue.klassifikation.bezeichnung)
             .font(.system(size: 8, weight: .bold))
             .padding(.horizontal, 5).padding(.vertical, 2)
             .background(FenlynineOSTheme.warning.opacity(0.12), in: Capsule())
         }
         Text(eintrag.wrappedValue.text).font(.caption)
         if !eintrag.wrappedValue.wirkung.isEmpty {
           Text(eintrag.wrappedValue.wirkung).font(.caption2).foregroundStyle(FenlynineOSTheme.warning)
         }
       }
       Spacer()
       Image(systemName: istOffen ? "chevron.up" : "chevron.down")
         .font(.caption2).foregroundStyle(.tertiary)
     }
     .padding(8)
     .contentShape(Rectangle())
   }
   .buttonStyle(.plain)

   if istOffen {
     aussageDetail(eintrag: eintrag)
       .padding(.horizontal, 8).padding(.bottom, 8)
   }
 }
 .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
 .overlay(
   RoundedRectangle(cornerRadius: 8)
     .stroke(istOffen ? FenlynineOSTheme.accent.opacity(0.35) : Color.clear, lineWidth: 1)
 )
}

private func aussageDetail(eintrag: Binding<AdvocatusProtokollEintrag>) -> some View {
 VStack(alignment: .leading, spacing: 10) {
   analyseAbschnitt(titel: "Handlungsoptionen", symbol: "bolt.fill", farbe: FenlynineOSTheme.success, items: eintrag.wrappedValue.analyse.handlungsoptionen)
   analyseAbschnitt(titel: "Konter", symbol: "scope", farbe: FenlynineOSTheme.accent, items: eintrag.wrappedValue.analyse.konter)
   analyseAbschnitt(titel: "Gegenargumente", symbol: "exclamationmark.bubble", farbe: FenlynineOSTheme.warning, items: eintrag.wrappedValue.analyse.gegenargumente)
   if !eintrag.wrappedValue.analyse.risikoHinweise.isEmpty {
     analyseAbschnitt(titel: "Risiko", symbol: "exclamationmark.triangle", farbe: FenlynineOSTheme.danger, items: eintrag.wrappedValue.analyse.risikoHinweise)
   }

   Divider().opacity(0.3)

   Label("Fragen zu dieser Aussage", systemImage: "questionmark.circle")
     .font(.caption.bold())

   ForEach(eintrag.wrappedValue.analyse.vorgeschlageneFragen.prefix(3), id: \.self) { vorschlag in
     Button { stelleFrage(vorschlag, eintrag: eintrag) } label: {
       Text(vorschlag).font(.caption2)
         .frame(maxWidth: .infinity, alignment: .leading)
         .padding(.horizontal, 8).padding(.vertical, 5)
         .background(FenlynineOSTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
     }
     .buttonStyle(.plain)
   }

   HStack(spacing: 6) {
     TextField("Eigene Frage …", text: eintrag.frageEingabe)
       .font(.caption).textFieldStyle(.plain)
       .padding(6)
       .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
     Button {
       let q = eintrag.wrappedValue.frageEingabe.trimmingCharacters(in: .whitespacesAndNewlines)
       guard !q.isEmpty else { return }
       stelleFrage(q, eintrag: eintrag)
       eintrag.wrappedValue.frageEingabe = ""
     } label: {
       Image(systemName: "paperplane.fill")
     }
     .buttonStyle(.borderless)
     .disabled(eintrag.wrappedValue.frageEingabe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
   }

   ForEach(eintrag.wrappedValue.fragen) { fa in
     VStack(alignment: .leading, spacing: 4) {
       Text("F: \(fa.frage)").font(.caption2.bold())
       if fa.laedt {
         ProgressView().controlSize(.small)
       } else {
         Text("A: \(fa.antwort)").font(.caption2).foregroundStyle(.secondary)
       }
     }
     .padding(8)
     .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
   }
 }
 .padding(8)
 .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
}

private func analyseAbschnitt(titel: String, symbol: String, farbe: Color, items: [String]) -> some View {
 VStack(alignment: .leading, spacing: 4) {
   Label(titel, systemImage: symbol).font(.caption2.bold()).foregroundStyle(farbe)
   ForEach(items.prefix(4), id: \.self) { item in
     HStack(alignment: .top, spacing: 4) {
       Text("(cid:127)").font(.caption2).foregroundStyle(farbe)
       Text(item).font(.caption2)
     }
   }
 }
}

private func konterTipp(_ opt: FenlynineOSKernKnoten) -> some View {
 HStack(spacing: 8) {
   Image(systemName: "scope").foregroundStyle(FenlynineOSTheme.success)
   VStack(alignment: .leading, spacing: 2) {
     Text("Konter-Tipp").font(.caption2.bold())
     Text("\(opt.titel) -- EV \(Int(opt.ev ?? 0))")
       .font(.caption)
   }
   Spacer()
 }
 .padding(10)
 .background(FenlynineOSTheme.success.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
 .padding(12)
}

// MARK: - Steuerung

private var steuerung: some View {
 ScrollView {
   VStack(alignment: .leading, spacing: 14) {
     Label("Erfassen & Routen", systemImage: "mic.fill")
       .font(.subheadline.bold())

     Picker("Sprecher", selection: $sprecher) {
       ForEach(AdvocatusSprecher.allCases) { s in
         Text(s.bezeichnung).tag(s)
       }
     }

     Picker("Klassifikation", selection: $klassifikation) {
       ForEach(AdvocatusKlassifikation.allCases) { k in
         Text(k.bezeichnung).tag(k)
       }
     }

     TextField("Aussage eingeben …", text: $eingabe, axis: .vertical)
       .font(.caption).lineLimit(3...6)
       .textFieldStyle(.plain)
       .padding(8)
       .background(FenlynineOSTheme.danger.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

     HStack(spacing: 6) {
       ForEach(["Gegner lenkt um", "Neuer Beweis", "Richter interveniert"], id: \.self) { chip in
         Button(chip) { eingabe = chip }
           .font(.caption2).padding(.horizontal, 8).padding(.vertical, 4)
           .background(Color.gray.opacity(0.1), in: Capsule()).buttonStyle(.plain)
       }
     }

     if !store.knoten.isEmpty {
       Picker("An Knoten routen", selection: $zielKnotenId) {
         Text("-- wählen --").tag("")
         ForEach(store.knoten.filter { $0.typ == .option }) { k in
           Text(k.titel).tag(k.id)
         }
       }
     }

     Button { erfasse() } label: {
       Label("Protokollieren & Routen", systemImage: "arrow.right.circle.fill")
     }
     .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
     .disabled(eingabe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

     Text("Regelfilter (PDF): Datum, §-Zitat, Zahlen und Zusage-Verben werden deterministisch erkannt -- KI nur für den Rest.")
       .font(.caption2).foregroundStyle(.secondary)
   }
   .padding(14)
 }
}

// MARK: - Aktionen

private func erfasse() {
 let text = eingabe.trimmingCharacters(in: .whitespacesAndNewlines)
 guard !text.isEmpty else { return }
 let zeit = Self.zeitFormatter.string(from: Date())
 let ereignisId = "evt_\(UUID().uuidString.prefix(6))"
 let ereignis = FenlynineOSKernKnoten(
   id: ereignisId, typ: .ereignis,
   titel: String(text.prefix(60)), beschreibung: text,
   modul: .advocatus, modulAktion: "Live-Ereignis",
   herkunft: "advocatus.protokoll", tiefe: 4, status: .erledigt, automatisiert: false,
   pErfolg: nil, gewinn: nil, verlust: nil, kosten: nil,
   rav: nil, ev: nil, rpn: nil, a: nil, b: nil, e: nil,
   fristDatum: nil, fristKritisch: FenlynineOSAdvocatusAnalyseService.regelFilterFrist(text),
   tageRestlauf: FenlynineOSAdvocatusAnalyseService.regelFilterFrist(text) ? 0 : nil,
   kausalTrigger: text
 )
 var wirkung = ""
 var neueKante: FenlynineOSKernKante?
 let ziel = zielKnotenId.isEmpty ? store.hoechsteOption?.id : zielKnotenId
 if let ziel, store.knoten.contains(where: { $0.id == ziel }) {
   neueKante = FenlynineOSKernKante(
     id: "adv_\(ereignisId)", vonId: ereignisId, zuId: ziel,
     typ: klassifikation.kantenTyp,
     kausalitaet: "\(sprecher.bezeichnung): \(text)",
     payload: klassifikation == .risiko ? ["delta": "0.15"] : klassifikation == .fakt ? ["delta": "-0.05"] : [:],
     origin: "advocatus.live"
   )
   if let titel = store.knoten.first(where: { $0.id == ziel })?.titel {
     wirkung = "-> \(titel): \(klassifikation.kantenTyp.bezeichnung)"
   }
 }

 store.fuegeKnotenHinzuBatch([ereignis], kanten: neueKante.map { [$0] } ?? [])
 store.phase = .live

 let analyse = FenlynineOSAdvocatusAnalyseService.analysiere(
   text: text, sprecher: sprecher, klassifikation: klassifikation, store: store
 )
 let eintrag = AdvocatusProtokollEintrag(
   id: UUID().uuidString,
   ereignisId: ereignisId,
   zeit: zeit,
   sprecher: sprecher,
   klassifikation: klassifikation,
   text: text,
   wirkung: wirkung,
   analyse: analyse,
   fragen: [],
   frageEingabe: ""
 )
 protokoll.append(eintrag)
 ausgewaehlteId = eintrag.id
 eingabe = ""
}

private func stelleFrage(_ frage: String, eintrag: Binding<AdvocatusProtokollEintrag>) {
 let frageId = UUID().uuidString
 let neu = AdvocatusFrageAntwort(id: frageId, frage: frage, antwort: "", laedt: true)
 eintrag.wrappedValue.fragen.append(neu)
 frageLaufId = frageId

 let text = eintrag.wrappedValue.text
 let sp = eintrag.wrappedValue.sprecher
 let kl = eintrag.wrappedValue.klassifikation

 Task {
   let antwort = await FenlynineOSAdvocatusAnalyseService.beantworteFrage(
     frage: frage, aussage: text, sprecher: sp, klassifikation: kl, store: store
   )
   await MainActor.run {
     if let idx = protokoll.firstIndex(where: { $0.id == eintrag.wrappedValue.id }),
      let fIdx = protokoll[idx].fragen.firstIndex(where: { $0.id == frageId }) {
       protokoll[idx].fragen[fIdx].antwort = antwort
       protokoll[idx].fragen[fIdx].laedt = false
     }
     frageLaufId = nil
   }
 }
}
}

