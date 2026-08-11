import SwiftUI
import Charts

// MARK: - Richterprofile Hauptansicht

struct RichterProfileView: View {
@State private var profile: [JudgeProfile] = []
@State private var cases: [LegalCase] = []
@State private var isLoading = false
@State private var loadError: String?
@State private var selectedId: String? = nil
@State private var suchtext = ""
@State private var zeigeNeuesProfil = false
@State private var zeigeNetzwerk = false
@State private var zeigeBearbeiten = false

var gefiltert: [JudgeProfile] {
  if suchtext.isEmpty { return profile }
  return profile.filter {
    $0.name.localizedCaseInsensitiveContains(suchtext) ||
    ($0.gericht?.localizedCaseInsensitiveContains(suchtext) ?? false) ||
    ($0.fachgebiet?.localizedCaseInsensitiveContains(suchtext) ?? false)
  }
}

var body: some View {
  NavigationSplitView {
    VStack(spacing: 0) {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(Premium.textSoft)
          .font(.system(size: 12))
        TextField("Richter suchen…", text: $suchtext)
          .textFieldStyle(.plain)
          .font(.system(size: 13))
          .foregroundStyle(Premium.text)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(Premium.well)
      .overlay(Divider(), alignment: .bottom)

      if isLoading {
        ProgressView().padding()
      }
      if let loadError {
        Text(loadError)
          .font(.caption)
          .foregroundStyle(Premium.critical)
          .padding(8)
      }

      List(gefiltert, selection: $selectedId) { profil in
        RichterListenZeile(profil: profil)
          .tag(profil.id ?? profil.name)
          .contextMenu {
            Button("Bearbeiten") {
              selectedId = profil.id ?? profil.name
              zeigeBearbeiten = true
            }
            Button("Löschen", role: .destructive) {
              Task { await loesche(profil) }
            }
          }
      }
      .listStyle(.plain)
    }
    .navigationSplitViewColumnWidth(min: 240, ideal: 260)
    .toolbar {
      ToolbarItem {
        Button { zeigeNeuesProfil = true } label: {
          Image(systemName: "plus")
        }
      }
    }
  } detail: {
    VStack(spacing: 0) {
      // Richter wechseln ohne Modul/Reiter zu verlassen
      FenlynineOSEntitySwitcher(
        label: "Richter",
        symbol: "person.text.rectangle",
        items: gefiltert.map { p in
          FenlynineOSEntityItem(
            id: p.id ?? p.name,
            titel: p.name,
            untertitel: [p.gericht, p.fachgebiet].compactMap { $0 }.joined(separator: " · "),
            gruppe: p.gericht ?? "Ohne Gericht",
            symbol: "person.fill"
          )
        },
        selectedId: $selectedId,
        onListe: {
          // Zurück zum Profil, falls Netzwerk offen
          if zeigeNetzwerk { zeigeNetzwerk = false }
        },
        listenLabel: zeigeNetzwerk ? "Zum Profil" : "Liste"
      )

      Group {
       if zeigeNetzwerk {
         ScrollView {
           RichterNetzwerkGlobalView(profiles: profile, cases: cases)
             .padding(20)
         }
       } else if let id = selectedId, let idx = profile.firstIndex(where: { ($0.id ?? $0.name) == id }) {
         RichterDetailView(
           profil: profile[idx],
           allProfiles: profile,
           cases: cases
         ) { updated in
           profile[idx] = updated
         }
         .id(id)
       } else {
         PlatzhalterView(nachricht: "Richterprofil auswählen", symbol: "person.text.rectangle")
           .frame(maxWidth: .infinity, maxHeight: .infinity)
       }
     }
     .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
 }
 .fenlynineOSAdaptiveNavigationTitle("Richterprofile & Parteienanalyse")
 .toolbar {
   ToolbarItemGroup {
     if selectedId != nil && !zeigeNetzwerk {
       Button {
         zeigeBearbeiten = true
       } label: {
         Label("Bearbeiten", systemImage: "pencil")
       }
     }
     Button {
       zeigeNetzwerk.toggle()
     } label: {
       Label(zeigeNetzwerk ? "Profil" : "Netzwerk",
          systemImage: zeigeNetzwerk ? "person.text.rectangle" : "point.3.connected.trianglepath.dotted")
     }
     .help(zeigeNetzwerk ? "Zurück zum Richterprofil" : "Globales Akteursnetzwerk")
   }
 }
 .onChange(of: selectedId) { _, _ in
   // Beim Richterwechsel aus dem Netzwerk zurück zum Profil
   if zeigeNetzwerk { zeigeNetzwerk = false }
 }
 .task { await laden() }
 .sheet(isPresented: $zeigeNeuesProfil) {
   NeuesRichterProfilSheet { neues in
     profile.append(neues)
     selectedId = neues.id ?? neues.name
   }
 }
 .sheet(isPresented: $zeigeBearbeiten) {
   if let id = selectedId, let idx = profile.firstIndex(where: { ($0.id ?? $0.name) == id }) {
     RichterBearbeitenSheet(profil: profile[idx]) { updated in
       Task { await speichere(updated, index: idx) }
     }
   }
 }
}

private func laden() async {
 isLoading = true
 loadError = nil
 defer { isLoading = false }
 do {
   async let p = Services.judgeProfiles.list()
   async let c = Services.cases.list()
   profile = try await p
   cases = try await c
   if selectedId == nil { selectedId = profile.first.flatMap { $0.id ?? $0.name } }
 } catch {
   loadError = "Laden fehlgeschlagen: \(error.localizedDescription)"
   profile = []
   cases = []
 }
}

private func speichere(_ p: JudgeProfile, index: Int) async {
 guard let id = p.id else {
   loadError = "Profil ohne ID -- bitte neu anlegen."
   return
 }
 do {
   let saved = try await Services.judgeProfiles.update(id: id, entity: p)
   if index < profile.count { profile[index] = saved }
 } catch {
   loadError = error.localizedDescription
 }
}

private func loesche(_ p: JudgeProfile) async {
 guard let id = p.id else { return }
 do {
   try await Services.judgeProfiles.delete(id: id)
   profile.removeAll { $0.id == id }
   if selectedId == id || selectedId == p.name {
     selectedId = profile.first.flatMap { $0.id ?? $0.name }
   }
 } catch {
   loadError = error.localizedDescription
 }
}
}

struct RichterListenZeile: View {
let profil: JudgeProfile

var body: some View {
 VStack(alignment: .leading, spacing: 4) {
   Text(profil.name)
     .font(.system(size: 13, weight: .semibold))
   HStack(spacing: 6) {
     if let gericht = profil.gericht {
       Text(gericht)
         .font(.caption2)
         .foregroundStyle(.secondary)
     }
     if let kq = profil.klaeger_rate {
       Text("Kl: \(Int(kq))%")
         .font(.caption2.bold())
         .foregroundStyle(kq >= 55 ? .green : kq >= 45 ? .orange : .red)
     }
   }
 }
 .padding(.vertical, 2)
}
}

// MARK: - Richter-Detail

struct RichterDetailView: View {
@State private var profil: JudgeProfile
let allProfiles: [JudgeProfile]
let cases: [LegalCase]
let onUpdate: (JudgeProfile) -> Void
@State private var kiProfilLaeuft = false
@State private var selectedTab = 0

init(
 profil: JudgeProfile,
 allProfiles: [JudgeProfile] = [],
 cases: [LegalCase] = [],
 onUpdate: @escaping (JudgeProfile) -> Void = { _ in }
) {
 _profil = State(initialValue: profil)
 self.allProfiles = allProfiles
 self.cases = cases
 self.onUpdate = onUpdate
}

var body: some View {
 ScrollView {
   VStack(spacing: 20) {
     // Header
     RichterHeaderCard(profil: profil)
       .padding(.horizontal, 20)
       .padding(.top, 20)

     // Tabs
     Picker("", selection: $selectedTab) {
       Text("Profil").tag(0)
       Text("Statistiken").tag(1)
       Text("KI-Analyse").tag(2)
       Text("Netzwerk").tag(3)
     }
     .pickerStyle(.segmented)
     .padding(.horizontal, 20)

     switch selectedTab {
     case 0:
       VStack(spacing: 16) {
         RichterProfilTab(profil: profil)
         AkteureBeziehungenView(
           profil: $profil,
           allProfiles: allProfiles.isEmpty ? [profil] : allProfiles,
           cases: cases,
           onUpdate: { updated in
             profil = updated
             onUpdate(updated)
           }
         )
       }
       .padding(.horizontal, 20)
     case 1:
       VStack(spacing: 20) {
         RichterStatistikTab(profil: profil)
         RichterErfolgsMatrixView(profil: $profil, onUpdate: onUpdate)
       }
       .padding(.horizontal, 20)
     case 2:
       RichterKIAnalyseTab(profil: $profil, onUpdate: onUpdate, kiProfilLaeuft: $kiProfilLaeuft)
         .padding(.horizontal, 20)
     case 3:
       RichterNetzwerkTab(profil: profil, allProfiles: allProfiles, cases: cases)
         .padding(.horizontal, 20)
     default:
       EmptyView()
     }
   }
   .padding(.bottom, 32)
 }
 .navigationTitle(profil.name)
 .navigationSubtitle(profil.gericht ?? "")
}
}

// MARK: - Richter-Header

struct RichterHeaderCard: View {
let profil: JudgeProfile

var body: some View {
 HStack(spacing: 20) {
   // Avatar
   ZStack {
     Circle()
       .fill(
         LinearGradient(
           colors: [.blue.opacity(0.7), .purple.opacity(0.6)],
           startPoint: .topLeading,
           endPoint: .bottomTrailing
         )
       )
       .frame(width: 72, height: 72)
     Text(profil.name.prefix(2).uppercased())
       .font(.system(size: 22, weight: .bold))
       .foregroundStyle(.white)
   }

   VStack(alignment: .leading, spacing: 6) {
     Text(profil.name)
       .font(.system(size: 22, weight: .bold))
     if let gericht = profil.gericht {
       HStack(spacing: 4) {
         Image(systemName: "building.columns.fill")
           .font(.caption)
           .foregroundStyle(.secondary)
         Text(gericht)
           .font(.subheadline)
           .foregroundStyle(.secondary)
       }
     }
     HStack(spacing: 8) {
       if let kammer = profil.kammer {
         BadgeView(text: kammer, farbe: .blue)
       }
       if let fachgebiet = profil.fachgebiet {
         BadgeView(text: fachgebiet, farbe: .purple)
       }
       if let stil = profil.stil {
         BadgeView(text: stil.rawValue, farbe: .orange)
       }
     }
   }

   Spacer()

   // KPI-Chips
   HStack(spacing: 12) {
     if let kq = profil.klaeger_rate {
       KPIKarte(
         titel: "Klägerquote",
         wert: "\(Int(kq))%",
         gesamt: "historisch",
         symbol: "person.fill",
         farbe: kq >= 55 ? .green : kq >= 45 ? .orange : .red
       )
       .frame(width: 100)
     }
     if let vq = profil.vergleich_rate {
       KPIKarte(
         titel: "Vergleichsrate",
         wert: "\(Int(vq))%",
         gesamt: "aller Verfahren",
         symbol: "handshake",
         farbe: .teal
       )
       .frame(width: 110)
     }
     if let fa = profil.faelle_analysiert {
       KPIKarte(
         titel: "Analysierte Fälle",
         wert: "\(fa)",
         gesamt: "Datenbasis",
         symbol: "doc.on.doc",
         farbe: .indigo
       )
       .frame(width: 110)
     }
   }
 }
 .padding(20)
 .background(.background, in: RoundedRectangle(cornerRadius: 16))
 .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.12), lineWidth: 1))
 .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
}
}

// MARK: - Profil-Tab

struct RichterProfilTab: View {
let profil: JudgeProfile

var body: some View {
 VStack(spacing: 16) {
   RichterErfahrungenPanel(erfahrungen: profil.erfahrungen ?? [])

   if let psychoProfil = profil.psycho_profil {
     VStack(alignment: .leading, spacing: 8) {
       Label("Psychologisches Profil", systemImage: "brain.fill")
         .font(.system(size: 13, weight: .semibold))
         .foregroundStyle(.purple)
       Text(psychoProfil)
         .font(.system(size: 13))
         .foregroundStyle(Premium.text)
         .textSelection(.enabled)
     }
     .padding(14)
     .background(Color.purple.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
   }

   LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
     if let staerken = profil.staerken, !staerken.isEmpty {
       ListKarte(titel: "Stärken", eintraege: staerken, farbe: .green, symbol: "plus.circle.fill")
     }
     if let schwaechen = profil.schwaechen, !schwaechen.isEmpty {
       ListKarte(titel: "Schwachstellen", eintraege: schwaechen, farbe: .orange, symbol: "minus.circle.fill")
     }
     if let bevArgs = profil.bevorzugte_argumente, !bevArgs.isEmpty {
       ListKarte(titel: "Bevorzugte Argumenttypen", eintraege: bevArgs, farbe: .blue, symbol: "text.bubble.fill")
     }
     if let fallstricke = profil.fallstricke, !fallstricke.isEmpty {
       ListKarte(titel: "Fallstricke", eintraege: fallstricke, farbe: .red, symbol: "exclamationmark.triangle.fill")
     }
   }

   if let muster = profil.entscheidungsmuster, !muster.isEmpty {
     VStack(alignment: .leading, spacing: 8) {
       Label("Entscheidungsmuster", systemImage: "chart.bar.doc.horizontal")
         .font(.system(size: 13, weight: .semibold))
       ForEach(muster, id: \.self) { muster in
         HStack(spacing: 8) {
           Image(systemName: "chevron.right")
             .font(.caption2)
             .foregroundStyle(.blue)
           Text(muster)
             .font(.system(size: 12))
         }
       }
     }
     .padding(14)
     .background(.background, in: RoundedRectangle(cornerRadius: 12))
     .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1)))
   }
 }
}
}

// MARK: - Statistik-Tab

struct RichterStatistikTab: View {
let profil: JudgeProfile

var statistiken: [(label: String, wert: Double, max: Double, farbe: Color)] {
 var result: [(String, Double, Double, Color)] = []
 if let kq = profil.klaeger_rate {
   result.append(("Klägerquote", kq, 100, kq >= 55 ? .green : kq >= 45 ? .orange : .red))
 }
 if let vq = profil.vergleich_rate {
   result.append(("Vergleichsrate", vq, 100, .teal))
 }
 if let eq = profil.erfolgsquote_bei_uns {
   result.append(("Unsere Erfolgsquote", eq, 100, .blue))
 }
 return result
}

var body: some View {
 VStack(spacing: 20) {
   if statistiken.isEmpty {
     PlatzhalterView(nachricht: "Noch keine Statistiken erfasst")
   } else {
     VStack(spacing: 12) {
       ForEach(statistiken, id: \.label) { stat in
         VStack(alignment: .leading, spacing: 4) {
           HStack {
             Text(stat.label)
               .font(.system(size: 13))
             Spacer()
             Text("\(Int(stat.wert))%")
               .font(.system(size: 14, weight: .bold))
               .foregroundStyle(stat.farbe)
           }
           GeometryReader { proxy in
             ZStack(alignment: .leading) {
               RoundedRectangle(cornerRadius: 4)
                 .fill(Color.gray.opacity(0.1))
                 .frame(height: 10)
               RoundedRectangle(cornerRadius: 4)
                 .fill(stat.farbe)
                 .frame(width: proxy.size.width * CGFloat(stat.wert / stat.max), height: 10)
               // 50%-Marker
               Rectangle()
                 .fill(Color.gray.opacity(0.4))
                 .frame(width: 1, height: 16)
                 .offset(x: proxy.size.width * 0.5)
             }
           }
           .frame(height: 10)
         }
       }
     }
     .padding(16)
     .background(.background, in: RoundedRectangle(cornerRadius: 12))

     // Urteilsdauer
     if let dauer = profil.urteil_dauer_tage {
       HStack {
         Image(systemName: "clock.fill")
           .foregroundStyle(.blue)
         Text("Durchschnittliche Verfahrensdauer:")
           .font(.system(size: 13))
         Text("\(Int(dauer)) Tage")
           .font(.system(size: 13, weight: .bold))
       }
       .padding(12)
       .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
     }
   }
 }
}
}

// MARK: - KI-Analyse Tab

struct RichterKIAnalyseTab: View {
@Binding var profil: JudgeProfile
let onUpdate: (JudgeProfile) -> Void
@Binding var kiProfilLaeuft: Bool
@State private var fehler: String?

var body: some View {
 VStack(spacing: 16) {
   Button {
     Task { await kiAnalyseErstellen() }
   } label: {
     if kiProfilLaeuft {
       ProgressView().scaleEffect(0.8)
     } else {
       Label(profil.ki_analyse != nil ? "Neu analysieren" : "KI-Tiefenanalyse mit Internetrecherche", systemImage: "globe")
     }
   }
   .buttonStyle(FenlynineOSGlassProminentButtonStyle())
   .disabled(kiProfilLaeuft)

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   if let ki = profil.ki_analyse?.dictValue {
     RichterKIAnalyseErgebnisView(ki: ki)
   } else if !kiProfilLaeuft {
     InfoHinweis(
       titel: "KI-Richteranalyse",
       nachricht: "Die KI recherchiert Urteile im Internet (juris, openJur, dejure), analysiert Entscheidungsmuster und gibt taktische Empfehlungen für Verhandlungen vor diesem Richter.",
       symbol: "globe"
     )
   }
 }
}

private static let kiSchema: [String: Any] = [
 "type": "object",
 "properties": [
   "zusammenfassung": ["type": "string"],
   "gefundene_urteile": [
     "type": "array",
     "items": [
       "type": "object",
       "properties": [
         "aktenzeichen": ["type": "string"],
         "datum": ["type": "string"],
         "streitgegenstand": ["type": "string"],
         "ergebnis": ["type": "string"],
         "argumentationsweise": ["type": "string"],
         "quelle": ["type": "string"]
       ] as [String: Any]
     ] as [String: Any]
   ],
   "argumentationsmuster": ["type": "array", "items": ["type": "string"]],
   "bevorzugte_normen": ["type": "array", "items": ["type": "string"]],
   "haltung_zu_argumenten": [
     "type": "array",
     "items": [
       "type": "object",
       "properties": [
         "argumenttyp": ["type": "string"],
         "haltung": ["type": "string"],
         "begruendung": ["type": "string"]
       ] as [String: Any]
     ] as [String: Any]
   ],
   "bevorzugte_antragstypen": [
     "type": "array",
     "items": [
       "type": "object",
       "properties": [
         "antragstyp": ["type": "string"],
         "erfolgsrate": ["type": "string"],
         "hinweis": ["type": "string"]
       ] as [String: Any]
     ] as [String: Any]
   ],
   "schadensersatz_bandbreite": [
     "type": "object",
     "properties": [
       "typischer_bereich": ["type": "string"],
       "faktoren": ["type": "array", "items": ["type": "string"]],
       "besonderheiten": ["type": "string"]
     ] as [String: Any]
   ],
   "umgang_beweismittel": ["type": "string"],
   "staerken_klaeger": ["type": "array", "items": ["type": "string"]],
   "risiken_klaeger": ["type": "array", "items": ["type": "string"]],
   "verhandlungstipps": [
     "type": "array",
     "items": [
       "type": "object",
       "properties": [
         "tipp": ["type": "string"],
         "begruendung": ["type": "string"],
         "prioritaet": ["type": "string"]
       ] as [String: Any]
     ] as [String: Any]
   ],
   "vergleichsstrategie": ["type": "string"],
   "timing_empfehlung": ["type": "string"],
   "do_dont": [
     "type": "object",
     "properties": [
       "dos": ["type": "array", "items": ["type": "string"]],
       "donts": ["type": "array", "items": ["type": "string"]]
     ] as [String: Any]
   ],
   "gesamteinschaetzung": ["type": "string"]
 ] as [String: Any]
]

private func kiAnalyseErstellen() async {
 kiProfilLaeuft = true
 fehler = nil
 defer { kiProfilLaeuft = false }

 let erfahrungen = profil.erfahrungen ?? []
 let erfText = erfahrungen.enumerated().map { i, e in
   "\(i + 1). \(e.datum ?? "?"): Vergleichsbereitschaft \(e.vergleichsbereitschaft ?? 0)/10, Geschwindigkeit \(e.entscheidungsgeschwindigkeit ?? 0)/10, Sachkompetenz \(e.sachkompetenz ?? 0)/10 - \"\(e.text ?? "")\""
 }.joined(separator: "\n")

 let prompt = """
 Du bist ein juristischer Strategieberater und Rechtsrecherche-Experte. Deine Aufgabe ist eine vollständige Analyse des folgenden Richters.

 Richterprofil:
 - Name: \(profil.name)
 - Gericht: \(profil.gericht ?? "unbekannt")\(profil.kammer.map { " · \($0)" } ?? "")
 - Rechtsgebiet: \(profil.rechtsgebiet ?? profil.fachgebiet ?? "unbekannt")
 - Verhandlungsstil: \(profil.stil?.rawValue ?? "Neutral")
 - Klägerquote: \(Int(profil.klaeger_rate ?? 0))%
 - Vergleichsrate: \(Int(profil.vergleich_rate ?? 0))%
 - Ø Verfahrensdauer: \(Int(profil.durchschnitt_dauer_monate ?? 0)) Monate
 - Urteile gesamt: \(profil.urteile_gesamt ?? 0)
 - Bekannt für: \(profil.bekannt_fuer ?? "-")

 Kanzlei-Erfahrungen (\(erfahrungen.count)):
 \(erfText.isEmpty ? "Noch keine Erfahrungen dokumentiert." : erfText)

 AUFGABE 1 - Internetrecherche: Suche im Internet nach echten Urteilen und Entscheidungen von Richter/in "\(profil.name)" am \(profil.gericht ?? "")\(profil.kammer.map { " (\($0))" } ?? ""). Suche in:
 - juris.de, dejure.org, rewis.io, openJur.de
 - Bundesrechtsprechungsdatenbanken
 - Anwaltsblogs und Kommentare zu Entscheidungen
 - Pressemitteilungen des Gerichts

 Für jeden gefundenen Fall: Aktenzeichen, Datum, Streitgegenstand, Ergebnis (Urteil/Vergleich), wie der Richter argumentiert hat, welche rechtlichen Maßstäbe angelegt wurden.

 AUFGABE 2 - Musteranalyse: Leite aus den gefundenen Fällen + Kanzleierfahrungen ab:
 - Typische Argumentationsmuster des Richters
 - Bevorzugte Rechtsnormen und Auslegungsmethoden
 - Wie er/sie mit Beweismitteln umgeht
 - Wann er/sie zu Vergleichen neigt
 - Typische Fallstricke für Anwälte bei diesem Richter

 AUFGABE 3 - Taktische Empfehlungen für Anwälte basierend auf allem Obigen.
 TRANSPARENZ: Erkläre GENAU, auf welchen Daten und welcher Methodik deine Einschätzungen beruhen.
 """

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: Self.kiSchema,
     webContext: true,
     model: "gemini_3_flash"
   )
   guard var dict = result.dictValue else {
     await MainActor.run { fehler = "KI-Antwort konnte nicht verarbeitet werden." }
     return
   }
   dict["erstellt"] = ISO8601DateFormatter().string(from: Date())
   let kiPayload = AnyCodable(dict)

   guard let id = profil.id else { return }
   var updated = profil
   updated.ki_analyse = kiPayload
   let saved = try await Services.judgeProfiles.update(id: id, entity: updated)
   await MainActor.run {
     profil = saved
     onUpdate(saved)
   }

   let ausgabe = (dict["zusammenfassung"] as? String ?? "") + "\n" + (dict["gesamteinschaetzung"] as? String ?? "")
   await KIProtokollService.log(
     caseId: id,
     kiName: "Richter-KI-Analyse (Internetrecherche)",
     eingabe: prompt,
     ausgabe: ausgabe,
     modell: "gemini_3_flash"
   )
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

// MARK: - KI-Analyse Ergebnis-Anzeige

struct RichterKIAnalyseErgebnisView: View {
let ki: [String: Any]

var body: some View {
 VStack(alignment: .leading, spacing: 14) {
   if let erstellt = ki["erstellt"] as? String {
     Text("Letzte Analyse: \(erstellt)")
       .font(.caption2)
       .foregroundStyle(.secondary)
   }

   if let zus = ki["zusammenfassung"] as? String, !zus.isEmpty {
     VStack(alignment: .leading, spacing: 4) {
       Text("Zusammenfassung").font(.caption.bold()).foregroundStyle(.secondary)
       Text(zus).font(.system(size: 12))
     }
     .padding(12)
     .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
   }

   if let urteile = ki["gefundene_urteile"] as? [[String: Any]], !urteile.isEmpty {
     VStack(alignment: .leading, spacing: 8) {
       Text("Gefundene Urteile (\(urteile.count))").font(.caption.bold())
       ForEach(Array(urteile.enumerated()), id: \.offset) { _, u in
         VStack(alignment: .leading, spacing: 4) {
           HStack {
             if let az = u["aktenzeichen"] as? String {
               Text(az).font(.caption2.monospaced()).padding(.horizontal, 6).padding(.vertical, 2)
                 .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
             }
             if let datum = u["datum"] as? String {
               Text(datum).font(.caption2).foregroundStyle(.secondary)
             }
           }
           if let sg = u["streitgegenstand"] as? String {
             Text(sg).font(.system(size: 12, weight: .medium))
           }
           if let erg = u["ergebnis"] as? String {
             Text("Ergebnis: \(erg)").font(.caption)
           }
           if let arg = u["argumentationsweise"] as? String {
             Text("-> \(arg)").font(.caption).italic().foregroundStyle(.secondary)
           }
         }
         .padding(10)
         .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
       }
     }
   }

   if let muster = ki["argumentationsmuster"] as? [String], !muster.isEmpty {
     ListKarte(titel: "Argumentationsmuster", eintraege: muster, farbe: .orange, symbol: "text.quote")
   }

   if let normen = ki["bevorzugte_normen"] as? [String], !normen.isEmpty {
     WrapLayout(normen) { n in
       Text(n).font(.caption2.monospaced())
         .padding(.horizontal, 8).padding(.vertical, 3)
         .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
     }
   }

   if let umgang = ki["umgang_beweismittel"] as? String, !umgang.isEmpty {
     VStack(alignment: .leading, spacing: 4) {
       Label("Umgang mit Beweismitteln", systemImage: "doc.viewfinder")
         .font(.caption.bold()).foregroundStyle(.blue)
       Text(umgang).font(.system(size: 12))
     }
     .padding(12)
     .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
   }

   if let staerken = ki["staerken_klaeger"] as? [String], !staerken.isEmpty {
     ListKarte(titel: "Stärken für Kläger", eintraege: staerken, farbe: .green, symbol: "plus.circle.fill")
   }
   if let risiken = ki["risiken_klaeger"] as? [String], !risiken.isEmpty {
     ListKarte(titel: "Risiken für Kläger", eintraege: risiken, farbe: .red, symbol: "exclamationmark.triangle.fill")
   }

   if let tipps = ki["verhandlungstipps"] as? [[String: Any]], !tipps.isEmpty {
     VStack(alignment: .leading, spacing: 8) {
       Text("Verhandlungstipps").font(.caption.bold())
       ForEach(Array(tipps.enumerated()), id: \.offset) { _, t in
         HStack(alignment: .top, spacing: 8) {
           if let prio = t["prioritaet"] as? String {
             Text(prio).font(.caption2.bold())
               .padding(.horizontal, 6).padding(.vertical, 2)
               .background(prio == "hoch" ? Color.red.opacity(0.15) : Color.yellow.opacity(0.15), in: Capsule())
           }
           VStack(alignment: .leading, spacing: 2) {
             Text(t["tipp"] as? String ?? "").font(.system(size: 12, weight: .medium))
             Text(t["begruendung"] as? String ?? "").font(.caption).foregroundStyle(.secondary)
           }
         }
       }
     }
   }

   if let vergleich = ki["vergleichsstrategie"] as? String, !vergleich.isEmpty {
     VStack(alignment: .leading, spacing: 4) {
       Label("Vergleichsstrategie", systemImage: "handshake").font(.caption.bold()).foregroundStyle(.purple)
       Text(vergleich).font(.system(size: 12))
     }
     .padding(12)
     .background(Color.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
   }

   if let timing = ki["timing_empfehlung"] as? String, !timing.isEmpty {
     VStack(alignment: .leading, spacing: 4) {
       Label("Timing-Empfehlung", systemImage: "clock").font(.caption.bold())
       Text(timing).font(.system(size: 12))
     }
     .padding(12)
     .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
   }

   if let haltungen = ki["haltung_zu_argumenten"] as? [[String: Any]], !haltungen.isEmpty {
     VStack(alignment: .leading, spacing: 8) {
       Text("Haltung zu Argumenttypen").font(.caption.bold())
       ForEach(Array(haltungen.enumerated()), id: \.offset) { _, h in
         HStack(alignment: .top) {
           Text(h["argumenttyp"] as? String ?? "--").font(.caption.bold()).frame(width: 100, alignment: .leading)
           Text(h["haltung"] as? String ?? "").font(.caption2)
             .padding(.horizontal, 6).padding(.vertical, 2)
             .background(Color.gray.opacity(0.1), in: Capsule())
           Text(h["begruendung"] as? String ?? "").font(.caption2).foregroundStyle(.secondary)
         }
       }
     }
   }

   if let antraege = ki["bevorzugte_antragstypen"] as? [[String: Any]], !antraege.isEmpty {
     VStack(alignment: .leading, spacing: 6) {
       Text("Bevorzugte Antragstypen").font(.caption.bold())
       ForEach(Array(antraege.enumerated()), id: \.offset) { _, a in
         Text("(cid:127) \(a["antragstyp"] as? String ?? "") -- \(a["erfolgsrate"] as? String ?? "")")
           .font(.caption)
       }
     }
   }

   if let band = ki["schadensersatz_bandbreite"] as? [String: Any] {
     VStack(alignment: .leading, spacing: 4) {
       Text("Schadensersatz-Bandbreite").font(.caption.bold())
       if let typ = band["typischer_bereich"] as? String { Text(typ).font(.caption) }
       if let fakt = band["faktoren"] as? [String] {
         ForEach(fakt, id: \.self) { f in Text("-> \(f)").font(.caption2) }
       }
     }
     .padding(12)
     .background(Color.yellow.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
   }

   if let dd = ki["do_dont"] as? [String: Any] {
     HStack(alignment: .top, spacing: 12) {
       if let dos = dd["dos"] as? [String] {
         ListKarte(titel: "Do's", eintraege: dos, farbe: .green, symbol: "checkmark.circle")
       }
       if let donts = dd["donts"] as? [String] {
         ListKarte(titel: "Don'ts", eintraege: donts, farbe: .red, symbol: "xmark.circle")
       }
     }
   }

   if let gesamt = ki["gesamteinschaetzung"] as? String, !gesamt.isEmpty {
     VStack(alignment: .leading, spacing: 4) {
       Text("Gesamteinschätzung").font(.caption.bold()).foregroundStyle(.white.opacity(0.8))
       Text(gesamt).font(.system(size: 13)).foregroundStyle(.white)
     }
     .padding(14)
     .frame(maxWidth: .infinity, alignment: .leading)
     .background(Color(white: 0.15), in: RoundedRectangle(cornerRadius: 12))
   }
 }
}
}

// MARK: - Netzwerk-Tab (Canvas-basiertes Netzwerkdiagramm)

struct RichterNetzwerkTab: View {
let profil: JudgeProfile
var allProfiles: [JudgeProfile] = []
var cases: [LegalCase] = []

var body: some View {
 VStack(spacing: 16) {
   Text("Beziehungsnetzwerk -- \(profil.name)")
     .font(.system(size: 14, weight: .semibold))

   NetzwerkDiagrammView(zentralesProfil: profil)
     .frame(height: 320)
     .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
     .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1)))

   if allProfiles.count > 1 {
     GlobalNetzwerkCanvasView(
       profiles: allProfiles,
       edges: netzwerkKanten(),
       selectedId: .constant(profil.id)
     )
     .frame(height: 280)
     .background(Color.gray.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
   }
 }
}

private func netzwerkKanten() -> [(String, String, Int)] {
 var kanten: [(String, String, Int)] = []
 guard let zid = profil.id else { return kanten }
 for p in allProfiles where p.id != zid {
   if let pid = p.id {
     if profil.gericht != nil && profil.gericht == p.gericht {
       kanten.append((zid, pid, 1))
     } else {
       kanten.append((zid, pid, 1))
     }
   }
 }
 return kanten
}
}

struct NetzwerkDiagrammView: View {
let zentralesProfil: JudgeProfile

@State private var knoten: [NetzwerkKnoten] = []
@State private var kanten: [NetzwerkKante] = []

var body: some View {
 Canvas { context, size in
   let mitte = CGPoint(x: size.width / 2, y: size.height / 2)

   // Kanten zeichnen
   for kante in kanten {
     guard let von = knoten.first(where: { $0.id == kante.von }),
        let zu = knoten.first(where: { $0.id == kante.zu }) else { continue }

     let vonPos = position(knoten: von, groesse: size)
     let zuPos = position(knoten: zu, groesse: size)

     var path = Path()
     path.move(to: vonPos)
     path.addLine(to: zuPos)

     context.stroke(path, with: .color(.gray.opacity(0.3)), lineWidth: 1.5)
   }

   // Knoten zeichnen
   for knoten in self.knoten {
     let pos = position(knoten: knoten, groesse: size)
     let radius: CGFloat = knoten.zentral ? 40 : 22

     // Kreis
     let circle = Path(ellipseIn: CGRect(
       x: pos.x - radius, y: pos.y - radius,
       width: radius * 2, height: radius * 2
     ))
     context.fill(circle, with: .color(knoten.farbe.opacity(knoten.zentral ? 0.9 : 0.7)))
     context.stroke(circle, with: .color(.white.opacity(0.3)), lineWidth: 1.5)

     // Label
     context.draw(
       Text(knoten.label)
         .font(.system(size: knoten.zentral ? 11 : 9, weight: .semibold))
         .foregroundStyle(.white),
       at: pos
     )
   }
 }
 .onAppear {
   erstelleNetzwerk()
 }
}

private func erstelleNetzwerk() {
 let zentralId = "zentral"
 knoten = [
   NetzwerkKnoten(id: zentralId, label: zentralesProfil.name.components(separatedBy: " ").last ?? "Richter",
          x: 0.5, y: 0.5, zentral: true, farbe: .blue)
 ]

 // Verbundene Gerichte und Kammern
 let verbindungen: [(String, Double, Double, Color)] = [
   (zentralesProfil.gericht ?? "Gericht", 0.2, 0.3, .purple),
   (zentralesProfil.fachgebiet ?? "Fachgebiet", 0.8, 0.3, .orange),
   ("Vergleiche (\(Int(zentralesProfil.vergleich_rate ?? 0))%)", 0.2, 0.7, .teal),
   ("Kl.-Quote (\(Int(zentralesProfil.klaeger_rate ?? 50))%)", 0.8, 0.7, zentralesProfil.klaeger_rate ?? 50 >= 55 ? .green : .red),
 ]

 for (index, (label, x, y, farbe)) in verbindungen.enumerated() {
   let id = "node_\(index)"
   knoten.append(NetzwerkKnoten(id: id, label: label, x: x, y: y, zentral: false, farbe: farbe))
   kanten.append(NetzwerkKante(von: zentralId, zu: id))
 }
}

private func position(knoten: NetzwerkKnoten, groesse: CGSize) -> CGPoint {
 CGPoint(x: knoten.x * groesse.width, y: knoten.y * groesse.height)
}
}

struct NetzwerkKnoten: Identifiable {
let id: String
let label: String
let x: CGFloat
let y: CGFloat
let zentral: Bool
let farbe: Color
}

struct NetzwerkKante: Identifiable {
let id = UUID()
let von: String
let zu: String
}

// MARK: - Hilfskomponenten

struct ListKarte: View {
let titel: String
let eintraege: [String]
let farbe: Color
let symbol: String

var body: some View {
 VStack(alignment: .leading, spacing: 8) {
   Label(titel, systemImage: symbol)
     .font(.system(size: 12, weight: .semibold))
     .foregroundStyle(farbe)
   ForEach(eintraege, id: \.self) { eintrag in
     HStack(spacing: 6) {
       Circle().fill(farbe.opacity(0.5)).frame(width: 5, height: 5)
       Text(eintrag)
         .font(.system(size: 11))
         .lineLimit(2)
     }
   }
 }
 .padding(12)
 .background(farbe.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
 .overlay(RoundedRectangle(cornerRadius: 10).stroke(farbe.opacity(0.12), lineWidth: 1))
}
}

struct BadgeView: View {
let text: String
let farbe: Color

var body: some View {
 Text(text)
   .font(.caption2)
   .fontWeight(.medium)
   .foregroundStyle(farbe)
   .padding(.horizontal, 8)
   .padding(.vertical, 3)
   .background(farbe.opacity(0.1), in: Capsule())
}
}

// MARK: - Erfolgsmatrix (wie ErfolgsMatrix.jsx)

private struct ErfolgsMatrixCompareRow: Identifiable {
let id = UUID()
let name: String
let urteil: Double
let vergleich: Double
}

struct RichterErfolgsMatrixView: View {
@Binding var profil: JudgeProfile
let onUpdate: (JudgeProfile) -> Void
@State private var laeuft = false
@State private var fehler: String?

private var matrix: [String: Any]? { profil.erfolgs_matrix?.dictValue }

var body: some View {
 VStack(alignment: .leading, spacing: 12) {
   HStack {
     VStack(alignment: .leading, spacing: 2) {
       Label("Erfolgswahrscheinlichkeits-Matrix", systemImage: "chart.line.uptrend.xyaxis")
         .font(.caption.bold())
       Text("Vergleich vs. Urteil -- KI-basierte Strategiebewertung")
         .font(.caption2).foregroundStyle(.secondary)
     }
     Spacer()
     Button {
       Task { await matrixBerechnen() }
     } label: {
       if laeuft { ProgressView().scaleEffect(0.7) }
       else { Label(matrix == nil ? "Berechnen" : "Neu berechnen", systemImage: "arrow.triangle.2.circlepath") }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .controlSize(.small)
     .disabled(laeuft)
   }

   if let err = fehler {
     Text(err).font(.caption).foregroundStyle(.red)
   }

   if let m = matrix {
     if let emp = m["empfehlung"] as? String {
       VStack(alignment: .leading, spacing: 4) {
         Text("Optimale Strategie").font(.caption2).foregroundStyle(.secondary)
         Text(emp).font(.title3.bold())
         if let begr = m["begruendung"] as? String, !begr.isEmpty {
           Text(begr).font(.caption)
         }
       }
       .padding(12)
       .frame(maxWidth: .infinity, alignment: .leading)
       .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
     }
     HStack(spacing: 16) {
       matrixKachel(label: "Urteil anstreben", wert: m["urteil_erfolg"] as? Double, farbe: .blue)
       matrixKachel(label: "Vergleich anstreben", wert: m["vergleich_erfolg"] as? Double, farbe: .purple)
     }
     if let monate = m["zeitvorteil_monate"] as? Double, monate > 0 {
       Text("Zeitvorteil Vergleich: ca. \(Int(monate)) Monate schneller")
         .font(.caption2).foregroundStyle(.secondary)
     }

     matrixBarChart(m)
     matrixRadarChart(m)
   } else if !laeuft {
     Text("Klicken Sie auf „Berechnen", um die KI-Strategiematrix zu erstellen.")
       .font(.caption).foregroundStyle(.secondary)
       .frame(maxWidth: .infinity)
       .padding(.vertical, 20)
   }
 }
 .padding(14)
 .background(.background, in: RoundedRectangle(cornerRadius: 12))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12)))
}

@ViewBuilder
private func matrixKachel(label: String, wert: Double?, farbe: Color) -> some View {
 VStack(spacing: 4) {
   Text("\(Int(wert ?? 0))%").font(.title2.bold())
   Text(label).font(.caption2).foregroundStyle(.secondary)
   ProgressView(value: (wert ?? 0) / 100).tint(farbe)
 }
 .frame(maxWidth: .infinity)
 .padding(10)
 .background(farbe.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
}

@ViewBuilder
private func matrixBarChart(_ m: [String: Any]) -> some View {
 let rows = [
   ErfolgsMatrixCompareRow(name: "Erfolgswahrscheinlichkeit", urteil: m["urteil_erfolg"] as? Double ?? 0, vergleich: m["vergleich_erfolg"] as? Double ?? 0),
   ErfolgsMatrixCompareRow(name: "Kosteneffizienz", urteil: m["kosten_index_urteil"] as? Double ?? 0, vergleich: m["kosten_index_vergleich"] as? Double ?? 0),
 ]
 VStack(alignment: .leading, spacing: 8) {
   Text("DIREKTVERGLEICH").font(.caption2.bold()).foregroundStyle(.secondary)
   Chart(rows) { row in
     BarMark(x: .value("Urteil", row.urteil), y: .value("Metrik", row.name))
       .foregroundStyle(.blue)
     BarMark(x: .value("Vergleich", row.vergleich), y: .value("Metrik", row.name))
       .foregroundStyle(.purple)
   }
   .chartXScale(domain: 0...100)
   .frame(height: 140)
 }
}

@ViewBuilder
private func matrixRadarChart(_ m: [String: Any]) -> some View {
 let ru = m["radar_urteil"] as? [String: Any] ?? [:]
 let rv = m["radar_vergleich"] as? [String: Any] ?? [:]
 let keys = ["zeiteffizienz", "kosteneffizienz", "erfolgsaussicht", "risiko", "kontrolle"]
 let labels = ["Zeiteffizienz", "Kosten", "Erfolg", "Risikoarm", "Kontrolle"]
 let seriesA = keys.map { ru[$0] as? Double ?? 0 }
 let seriesB = keys.map { rv[$0] as? Double ?? 0 }

 VStack(alignment: .leading, spacing: 8) {
   Text("5-DIMENSIONEN-ANALYSE").font(.caption2.bold()).foregroundStyle(.secondary)
   LexaraDualRadarChartView(labels: labels, seriesA: seriesA, seriesB: seriesB)
     .frame(height: 240)
 }
}

private func matrixBerechnen() async {
 guard let id = profil.id else { return }
 laeuft = true
 fehler = nil
 defer { laeuft = false }

 let erfahrungen = profil.erfahrungen ?? []
 let avgVergleich = erfahrungen.isEmpty ? 5.0 :
   Double(erfahrungen.reduce(0) { $0 + ($1.vergleichsbereitschaft ?? 5) }) / Double(erfahrungen.count)

 let prompt = """
 Du bist ein juristischer Datenanalyst. Berechne für dieses Profil die optimale Prozessstrategie.

 PROFIL:
 Name: \(profil.name)
 Kategorie: \(profil.fachgebiet ?? "Richter")
 Gericht/Institution: \(profil.gericht ?? "-")
 Klägerquote/Erfolgsquote: \(Int(profil.klaeger_rate ?? 50))%
 Vergleichsrate: \(Int(profil.vergleich_rate ?? 30))%
 Ø Dauer: \(Int(profil.durchschnitt_dauer_monate ?? 12)) Monate
 Verhandlungsstil: \(profil.stil?.rawValue ?? "Neutral")
 Ø Vergleichsbereitschaft (Kanzleierfahrungen): \(String(format: "%.1f", avgVergleich))/10
 Erfahrungen: \(erfahrungen.count) dokumentiert

 Berechne Urteil vs. Vergleich Erfolgswahrscheinlichkeiten, Zeitvorteil, Kostenindizes, Empfehlung und 5-Dimensionen-Radar.
 """

 do {
   let result: AnyCodable = try await LLMService.shared.invoke(
     prompt: prompt,
     schema: ["type": "object", "properties": [
       "urteil_erfolg": ["type": "number"],
       "vergleich_erfolg": ["type": "number"],
       "zeitvorteil_monate": ["type": "number"],
       "kosten_index_urteil": ["type": "number"],
       "kosten_index_vergleich": ["type": "number"],
       "empfehlung": ["type": "string"],
       "begruendung": ["type": "string"],
       "radar_urteil": ["type": "object", "properties": [
         "zeiteffizienz": ["type": "number"], "kosteneffizienz": ["type": "number"],
         "erfolgsaussicht": ["type": "number"], "risiko": ["type": "number"], "kontrolle": ["type": "number"]
       ]],
       "radar_vergleich": ["type": "object", "properties": [
         "zeiteffizienz": ["type": "number"], "kosteneffizienz": ["type": "number"],
         "erfolgsaussicht": ["type": "number"], "risiko": ["type": "number"], "kontrolle": ["type": "number"]
       ]]
     ]] as [String: Any]
   )
   guard var dict = result.dictValue else {
     await MainActor.run { fehler = "Keine Matrix-Daten erhalten." }
     return
   }
   dict["berechnet"] = ISO8601DateFormatter().string(from: Date())
   var updated = profil
   updated.erfolgs_matrix = AnyCodable(dict)
   let saved = try await Services.judgeProfiles.update(id: id, entity: updated)
   await MainActor.run {
     profil = saved
     onUpdate(saved)
   }
 } catch {
   await MainActor.run { fehler = error.localizedDescription }
 }
}
}

// MARK: - Neues Richterprofil Sheet

struct NeuesRichterProfilSheet: View {
let onCreated: (JudgeProfile) -> Void
@Environment(\.dismiss) var dismiss

@State private var name = ""
@State private var gericht = ""
@State private var klaegerRate = ""
@State private var vergleichRate = ""
@State private var isSaving = false
@State private var speicherFehler: String?

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Label("Neues Richterprofil", systemImage: "person.badge.plus")
       .font(.title3.bold())
     Spacer()
     Button("Abbrechen") { dismiss() }
   }
   .padding(20)
   Divider()
   Form {
     TextField("Name *", text: $name)
     TextField("Gericht", text: $gericht)
     TextField("Klägerquote (%)", text: $klaegerRate)
     TextField("Vergleichsrate (%)", text: $vergleichRate)
   }
   .formStyle(.grouped)
   if let err = speicherFehler {
     Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
   }
   Divider()
   HStack {
     Spacer()
     Button("Erstellen") {
       Task { await erstellen() }
     }
     .buttonStyle(FenlynineOSGlassProminentButtonStyle())
     .disabled(name.isEmpty || isSaving)
   }
   .padding(16)
 }
 .frame(width: 380, height: 340)
}

private func erstellen() async {
 isSaving = true
 speicherFehler = nil
 var profil = JudgeProfile(name: name)
 if !gericht.isEmpty { profil.gericht = gericht }
 if let kr = Double(klaegerRate) { profil.klaeger_rate = kr }
 if let vr = Double(vergleichRate) { profil.vergleich_rate = vr }

 do {
   let created = try await Services.judgeProfiles.create(profil)
   await MainActor.run { onCreated(created); dismiss() }
 } catch {
   await MainActor.run { speicherFehler = error.localizedDescription }
 }
 isSaving = false
}
}

// MARK: - Erfahrungen anzeigen

struct RichterErfahrungenPanel: View {
let erfahrungen: [JudgeProfile.RichterErfahrung]

var body: some View {
 VStack(alignment: .leading, spacing: 10) {
   Label("Kanzlei-Erfahrungen (\(erfahrungen.count))", systemImage: "text.book.closed.fill")
     .font(.system(size: 13, weight: .semibold))
     .foregroundStyle(Premium.text)

   if erfahrungen.isEmpty {
     Text("Noch keine Erfahrungen dokumentiert -- über „Bearbeiten" hinzufügen. Die KI nutzt sie für Matrix & Taktik.")
       .font(.system(size: 11))
       .foregroundStyle(Premium.textSoft)
   } else {
     ForEach(Array(erfahrungen.enumerated()), id: \.offset) { _, e in
       VStack(alignment: .leading, spacing: 4) {
         HStack {
           Text(e.datum ?? "ohne Datum")
             .font(.system(size: 10, weight: .semibold))
             .foregroundStyle(Premium.action)
           if let a = e.autor {
             Text("· \(a)").font(.system(size: 10)).foregroundStyle(Premium.textFaint)
           }
           Spacer()
           if let v = e.vergleichsbereitschaft {
             Text("Vergleich \(v)/10")
               .font(.system(size: 10, design: .monospaced))
               .foregroundStyle(Premium.textSoft)
           }
         }
         if let k = e.fall_kontext, !k.isEmpty {
           Text(k).font(.system(size: 11, weight: .medium)).foregroundStyle(Premium.text)
         }
         if let t = e.text, !t.isEmpty {
           Text(t).font(.system(size: 11)).foregroundStyle(Premium.textSoft)
         }
       }
       .padding(10)
       .background(RoundedRectangle(cornerRadius: 8).fill(Premium.well))
     }
   }
 }
 .padding(14)
 .background(RoundedRectangle(cornerRadius: 12).fill(Premium.panel))
 .overlay(RoundedRectangle(cornerRadius: 12).stroke(Premium.hairline, lineWidth: 1))
}
}

// MARK: - Profil bearbeiten + Erfahrungen

struct RichterBearbeitenSheet: View {
let onSave: (JudgeProfile) -> Void
@Environment(\.dismiss) private var dismiss
@State private var draft: JudgeProfile
@State private var neueErfahrungText = ""
@State private var neueErfahrungKontext = ""
@State private var neueVergleich = 5.0

init(profil: JudgeProfile, onSave: @escaping (JudgeProfile) -> Void) {
 self.onSave = onSave
 _draft = State(initialValue: profil)
}

var body: some View {
 VStack(spacing: 0) {
   HStack {
     Text("Richterprofil bearbeiten").font(.headline).foregroundStyle(Premium.text)
     Spacer()
     Button("Abbrechen") { dismiss() }
     Button("Speichern") {
       onSave(draft)
       dismiss()
     }
     .buttonStyle(.borderedProminent)
     .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
   }
   .padding()

   Form {
     Section("Stammdaten") {
       TextField("Name", text: $draft.name)
       TextField("Gericht", text: Binding(
         get: { draft.gericht ?? "" },
         set: { draft.gericht = $0.isEmpty ? nil : $0 }
       ))
       TextField("Kammer", text: Binding(
         get: { draft.kammer ?? "" },
         set: { draft.kammer = $0.isEmpty ? nil : $0 }
       ))
       TextField("Fachgebiet", text: Binding(
         get: { draft.fachgebiet ?? "" },
         set: { draft.fachgebiet = $0.isEmpty ? nil : $0 }
       ))
       Picker("Stil", selection: Binding(
         get: { draft.stil ?? .pragmatisch },
         set: { draft.stil = $0 }
       )) {
         ForEach(JudgeProfile.RichterStil.allCases, id: \.self) { Text($0.rawValue).tag($0) }
       }
     }
     Section("Quoten") {
       TextField("Klägerquote %", text: Binding(
         get: { draft.klaeger_rate.map { String(Int($0)) } ?? "" },
         set: { draft.klaeger_rate = Double($0) }
       ))
       TextField("Vergleichsrate %", text: Binding(
         get: { draft.vergleich_rate.map { String(Int($0)) } ?? "" },
         set: { draft.vergleich_rate = Double($0) }
       ))
     }
     Section("Psychologie & Beobachtungen") {
       TextEditor(text: Binding(
         get: { draft.psycho_profil ?? "" },
         set: { draft.psycho_profil = $0.isEmpty ? nil : $0 }
       ))
       .frame(minHeight: 60)
     }
     Section("Neue Erfahrung") {
       TextField("Fall-Kontext", text: $neueErfahrungKontext)
       TextEditor(text: $neueErfahrungText).frame(minHeight: 50)
       Slider(value: $neueVergleich, in: 1...10, step: 1) {
         Text("Vergleichsbereitschaft \(Int(neueVergleich))/10")
       }
       Button("Erfahrung hinzufügen") {
         var list = draft.erfahrungen ?? []
         let df = DateFormatter()
         df.dateFormat = "yyyy-MM-dd"
         list.insert(JudgeProfile.RichterErfahrung(
           datum: df.string(from: Date()),
           autor: "Kanzlei",
           fall_kontext: neueErfahrungKontext.isEmpty ? nil : neueErfahrungKontext,
           vergleichsbereitschaft: Int(neueVergleich),
           text: neueErfahrungText.isEmpty ? nil : neueErfahrungText
         ), at: 0)
         draft.erfahrungen = list
         neueErfahrungText = ""
         neueErfahrungKontext = ""
       }
       .disabled(neueErfahrungText.trimmingCharacters(in: .whitespaces).isEmpty
            && neueErfahrungKontext.trimmingCharacters(in: .whitespaces).isEmpty)
     }
     if let erf = draft.erfahrungen, !erf.isEmpty {
       Section("Gespeicherte Erfahrungen (\(erf.count))") {
         ForEach(Array(erf.enumerated()), id: \.offset) { idx, e in
           HStack {
             VStack(alignment: .leading) {
               Text(e.fall_kontext ?? e.text ?? "Erfahrung").lineLimit(2)
               Text(e.datum ?? "").font(.caption2).foregroundStyle(.secondary)
             }
             Spacer()
             Button(role: .destructive) {
               draft.erfahrungen?.remove(at: idx)
             } label: {
               Image(systemName: "trash")
             }
             .buttonStyle(.borderless)
           }
         }
       }
     }
   }
   .formStyle(.grouped)
 }
 .frame(width: 560, height: 640)
}
}

