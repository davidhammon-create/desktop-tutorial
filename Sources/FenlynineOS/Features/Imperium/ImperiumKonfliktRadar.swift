import Foundation
import SwiftUI

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// KONFLIKTRADAR -- Interessenkonflikt-Engine (lokal, querschnittlich)
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

enum ImperiumKonfliktSchwere: String, Codable, CaseIterable {
case kritisch, hoch, mittel, hinweis

var label: String {
  switch self {
  case .kritisch: return "Kritisch"
  case .hoch: return "Hoch"
  case .mittel: return "Mittel"
  case .hinweis: return "Hinweis"
  }
}

var farbe: Color {
  switch self {
  case .kritisch: return Color(red: 0.85, green: 0.22, blue: 0.2)
  case .hoch: return Color(red: 0.9, green: 0.45, blue: 0.15)
  case .mittel: return Color(red: 0.85, green: 0.7, blue: 0.2)
  case .hinweis: return Premium.action
  }
}
}

struct ImperiumKonfliktTreffer: Identifiable, Hashable {
let id = UUID()
let schwere: ImperiumKonfliktSchwere
let titel: String
let detail: String
let quelleA: String
let quelleB: String
let empfehlung: String
}

@MainActor
@Observable
final class ImperiumKonfliktEngine {
static let shared = ImperiumKonfliktEngine()

var treffer: [ImperiumKonfliktTreffer] = []
var suchtext = ""
var isScanning = false
var letztePruefung: Date?
var manuelleParteien: [String] = []
var audit: [String] = []

private let auditKey = "imperium_konflikt_audit_v1"

private init() {
  if let a: [String] = ImperiumDisk.load(auditKey, as: [String].self) {
    audit = a
  }
}

func parteiHinzufuegen(_ name: String) {
  let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !n.isEmpty, !manuelleParteien.contains(where: { $0.caseInsensitiveCompare(n) == .orderedSame }) else { return }
  manuelleParteien.append(n)
}

func scannen(faelle: [LegalCase], mandanten: [Mandant] = [], organonNamen: [String] = []) {
  isScanning = true
  defer { isScanning = false }

  var hits: [ImperiumKonfliktTreffer] = []
  let norm: (String) -> String = {
    $0.lowercased()
      .replacingOccurrences(of: "ä", with: "ae")
      .replacingOccurrences(of: "ö", with: "oe")
      .replacingOccurrences(of: "ü", with: "ue")
      .replacingOccurrences(of: "ß", with: "ss")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  // 1) Gleicher Mandant in mehreren aktiven Mandaten
  var mandantZuFaellen: [String: [LegalCase]] = [:]
  for f in faelle {
    guard let m = f.mandant_name, !m.isEmpty else { continue }
    mandantZuFaellen[norm(m), default: []].append(f)
  }
  for (m, liste) in mandantZuFaellen where liste.count > 1 {
    let akt = liste.filter { $0.status == .aktiv || $0.status == .vorbereitung }
    if akt.count > 1 {
      hits.append(.init(
        schwere: .hinweis,
        titel: "Mehrfachmandate: \(liste.first?.mandant_name ?? m)",
        detail: "\(akt.count) offene Mandate für denselben Mandanten -- Kapazität & Interessenlage prüfen.",
        quelleA: akt[0].fallname,
        quelleB: akt[1].fallname,
        empfehlung: "Organon-Zuständigkeit und Honorarrahmen abstimmen."
      ))
    }
  }

 // 2) Name-Überlappung Mandant « Gegnerhinweis in Notes / Fallname
 for a in faelle {
   guard let ma = a.mandant_name, !ma.isEmpty else { continue }
   for b in faelle where a.id != b.id {
     let blob = [b.fallname, b.notes ?? "", b.mandant_name ?? "", b.prozessziel ?? ""].joined(separator: " ")
     if blob.localizedCaseInsensitiveContains(ma), a.mandant_name?.caseInsensitiveCompare(b.mandant_name ?? "") != .orderedSame {
       hits.append(.init(
         schwere: .hoch,
         titel: "Möglicher Interessenkonflikt",
         detail: "Mandant „\(ma)" taucht im Kontext von „\(b.fallname)" auf.",
         quelleA: a.fallname,
         quelleB: b.fallname,
         empfehlung: "Conflict-Waiver prüfen oder Mandat ablehnen / Chinese Wall."
       ))
     }
   }
 }

 // 3) Manuelle Parteien vs. Mandate
 for p in manuelleParteien {
   for f in faelle {
     let blob = [f.fallname, f.mandant_name ?? "", f.notes ?? "", f.richter_name ?? ""].joined(separator: " ")
     if blob.localizedCaseInsensitiveContains(p) {
       hits.append(.init(
         schwere: .kritisch,
         titel: "Manuelle Partei „\(p)" in Akte",
         detail: "Die geprüfte Partei ist bereits in Falldaten referenziert.",
         quelleA: p,
         quelleB: f.fallname,
         empfehlung: "Sofortige Konfliktprüfung vor Mandatsannahme."
       ))
     }
   }
   for name in organonNamen where name.localizedCaseInsensitiveContains(p) || p.localizedCaseInsensitiveContains(name) {
     hits.append(.init(
       schwere: .mittel,
       titel: "Organon-Treffer: \(name)",
       detail: "Netzwerkknoten überschneidet sich mit Konfliktprüfung.",
       quelleA: p,
       quelleB: name,
       empfehlung: "Beziehungen in Organon Links prüfen."
     ))
   }
 }

 // 4) Mandantenstamm vs. Fallgegner-Heuristik
 for m in mandanten {
   let name = m.anzeigename
   for f in faelle {
     guard (f.mandant_name ?? "").caseInsensitiveCompare(name) != .orderedSame else { continue }
     if f.fallname.localizedCaseInsensitiveContains(name) || (f.notes ?? "").localizedCaseInsensitiveContains(name) {
       hits.append(.init(
         schwere: .hoch,
         titel: "Stamm-Mandant in Fremdmandat",
         detail: "„\(name)" erscheint in „\(f.fallname)" ohne Mandatszuordnung.",
         quelleA: name,
         quelleB: f.fallname,
         empfehlung: "Rolle klären (Gegner / Zeuge / Dritter)."
       ))
     }
   }
 }

 if let q = suchtext.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
   hits = hits.filter {
     $0.titel.localizedCaseInsensitiveContains(q)
       || $0.detail.localizedCaseInsensitiveContains(q)
       || $0.quelleA.localizedCaseInsensitiveContains(q)
       || $0.quelleB.localizedCaseInsensitiveContains(q)
   }
 }

 // Dedup by titel+quellen
 var seen = Set<String>()
 treffer = hits.filter { h in
   let k = "\(h.titel)|\(h.quelleA)|\(h.quelleB)"
   return seen.insert(k).inserted
 }.sorted { lhs, rhs in
   ImperiumKonfliktSchwere.allCases.firstIndex(of: lhs.schwere)! < ImperiumKonfliktSchwere.allCases.firstIndex(of: rhs.schwere)!
 }

 letztePruefung = Date()
 let msg = "Konflikt-Scan \(treffer.count) Treffer · \(Date.now.formatted(date: .abbreviated, time: .shortened))"
 audit.insert(msg, at: 0)
 if audit.count > 80 { audit = Array(audit.prefix(80)) }
 ImperiumDisk.save(audit, key: auditKey)

 ImperiumEntscheidungsJournal.shared.eintrag(
   typ: .compliance,
   titel: "Konflikt-Scan",
   detail: msg,
   module: ["KonfliktRadar", "Lexara", "Organon"]
 )
}
}

private extension String {
var nilIfEmpty: String? { isEmpty ? nil : self }
}

struct ImperiumKonfliktRadarView: View {
@State private var engine = ImperiumKonfliktEngine.shared
@State private var neuePartei = ""
@State private var faelle: [LegalCase] = []
@State private var mandanten: [Mandant] = []

var body: some View {
 VStack(spacing: 0) {
   header
   Divider().overlay(Premium.hairline)
   HStack(spacing: 0) {
     steuerung.frame(width: 300)
     Divider().overlay(Premium.hairline)
     ergebnisse
   }
 }
 .background(Premium.void)
 .fenlynineOSAdaptiveNavigationTitle("KonfliktRadar")
 .task { await laden() }
}

private var header: some View {
 HStack(spacing: 12) {
   VStack(alignment: .leading, spacing: 4) {
     Text("KonfliktRadar")
       .font(.system(size: 18, weight: .bold))
       .foregroundStyle(Premium.text)
     Text("Interessenkonflikte über Mandate, Mandantenstamm und Organon -- vor Mandatsannahme und laufend.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
   }
   Spacer()
   if let d = engine.letztePruefung {
     Text("Zuletzt \(d.formatted(date: .omitted, time: .shortened))")
       .font(.system(size: 10))
       .foregroundStyle(Premium.textFaint)
   }
   Button {
     Task { await laden(); scannen() }
   } label: {
     Label(engine.isScanning ? "Scan…" : "Jetzt prüfen", systemImage: "dot.radiowaves.left.and.right")
   }
   .buttonStyle(.borderedProminent)
   .tint(Premium.action)
   .disabled(engine.isScanning)
 }
 .padding(16)
 .background(Premium.ink)
}

private var steuerung: some View {
 VStack(alignment: .leading, spacing: 14) {
   Text("Prüfobjekt")
     .font(.system(size: 10, weight: .bold))
     .foregroundStyle(Premium.textFaint)
     .tracking(0.8)

   HStack {
     TextField("Partei / Gegner / Zeuge…", text: $neuePartei)
       .textFieldStyle(.plain)
       .font(.system(size: 12))
     Button("Add") {
       engine.parteiHinzufuegen(neuePartei)
       neuePartei = ""
     }
     .disabled(neuePartei.trimmingCharacters(in: .whitespaces).isEmpty)
   }
   .padding(10)
   .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))

   if engine.manuelleParteien.isEmpty {
     Text("Noch keine manuellen Parteien -- für Neumandate eintragen.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
   } else {
     ForEach(engine.manuelleParteien, id: \.self) { p in
       HStack {
         Image(systemName: "person.fill.questionmark")
           .foregroundStyle(Premium.action)
         Text(p).font(.system(size: 12)).foregroundStyle(Premium.text)
         Spacer()
         Button {
           engine.manuelleParteien.removeAll { $0 == p }
         } label: {
           Image(systemName: "xmark.circle.fill").foregroundStyle(Premium.textFaint)
         }
         .buttonStyle(.plain)
       }
     }
   }

   TextField("Treffer filtern…", text: $engine.suchtext)
     .textFieldStyle(.roundedBorder)
     .font(.system(size: 11))

   Text("Audit")
     .font(.system(size: 10, weight: .bold))
     .foregroundStyle(Premium.textFaint)
     .padding(.top, 8)
   ScrollView {
     VStack(alignment: .leading, spacing: 6) {
       ForEach(engine.audit.prefix(12), id: \.self) { line in
         Text(line)
           .font(.system(size: 10, design: .monospaced))
           .foregroundStyle(Premium.textSoft)
       }
     }
   }
   Spacer()
 }
 .padding(14)
 .background(Premium.ink)
}

private var ergebnisse: some View {
 Group {
   if engine.treffer.isEmpty {
     VStack(spacing: 12) {
       Image(systemName: "checkmark.shield.fill")
         .font(.system(size: 36))
         .foregroundStyle(Premium.computed)
       Text(engine.letztePruefung == nil ? "Noch kein Scan" : "Keine Konflikte erkannt")
         .font(.system(size: 16, weight: .semibold))
         .foregroundStyle(Premium.text)
       Text("Das ersetzt keine anwaltliche Konfliktprüfung -- es beschleunigt sie über alle Module.")
         .font(.system(size: 12))
         .foregroundStyle(Premium.textSoft)
         .multilineTextAlignment(.center)
         .frame(maxWidth: 360)
     }
     .frame(maxWidth: .infinity, maxHeight: .infinity)
   } else {
     List {
       ForEach(engine.treffer) { t in
         VStack(alignment: .leading, spacing: 8) {
           HStack {
             Text(t.schwere.label.uppercased())
               .font(.system(size: 9, weight: .bold))
               .foregroundStyle(t.schwere.farbe)
               .padding(.horizontal, 8)
               .padding(.vertical, 3)
               .background(Capsule().fill(t.schwere.farbe.opacity(0.15)))
             Spacer()
           }
           Text(t.titel)
             .font(.system(size: 13, weight: .semibold))
             .foregroundStyle(Premium.text)
           Text(t.detail)
             .font(.system(size: 11))
             .foregroundStyle(Premium.textSoft)
           HStack {
             Label(t.quelleA, systemImage: "arrow.left")
             Label(t.quelleB, systemImage: "arrow.right")
           }
           .font(.system(size: 10))
           .foregroundStyle(Premium.textFaint)
           Text(t.empfehlung)
             .font(.system(size: 11, weight: .medium))
             .foregroundStyle(Premium.action)
         }
         .padding(.vertical, 6)
         .listRowBackground(Premium.void)
       }
     }
     .scrollContentBackground(.hidden)
   }
 }
 .background(Premium.void)
}

private func laden() async {
 faelle = (try? await Services.cases.list()) ?? []
 mandanten = (try? await Services.mandanten.list()) ?? []
}

private func scannen() {
 let namen = OrganonStore.shared.knoten.map(\.name)
 engine.scannen(faelle: faelle, mandanten: mandanten, organonNamen: namen)
}
}

