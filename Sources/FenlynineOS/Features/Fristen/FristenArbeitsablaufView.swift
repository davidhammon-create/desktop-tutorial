import SwiftUI
import FenlynineOSKern

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// FRISTEN-ARBEITSABLAUF
// Post kommt rein -> Frist berechnen -> notieren mit Vorfrist ->
// Wiedervorlage -> Ausgangskontrolle -> erledigt.
// Eine Spalte, sechs nummerierte Schritte, keine Reiter.
// Alle Daten liegen vorerst nur im Speicher (kein Store-Zugriff).
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Fristarten

/// TODO: Der Kern liefert (noch) keinen Katalog von Fristdefinitionen.
/// Dieser lokale Katalog baut echte `Fristdefinition`-Werte und gehört
/// langfristig nach FenlynineOSKern/Fristen. Normen vor Produktivbetrieb prüfen.
enum Fristart: String, CaseIterable, Identifiable {
  case berufung, berufungsbegruendung, revision, sofortigeBeschwerde
  case einspruchVersaeumnisurteil, kuendigungsschutzklage, eigene

  var id: String { rawValue }

  var titel: String {
    switch self {
    case .berufung: return "Berufung einlegen"
    case .berufungsbegruendung: return "Berufung begründen"
    case .revision: return "Revision einlegen"
    case .sofortigeBeschwerde: return "Sofortige Beschwerde"
    case .einspruchVersaeumnisurteil: return "Einspruch gegen Versäumnisurteil"
    case .kuendigungsschutzklage: return "Kündigungsschutzklage"
    case .eigene: return "Andere Frist (vom Gericht gesetzt)"
    }
  }

  /// Fester Katalogeintrag; für `.eigene` nil (wird aus den Eingaben gebaut).
  var definition: Fristdefinition? {
    switch self {
    case .berufung:
      // § 517 ZPO: Der Beginn ist gekappt, nicht das Ende -- ohne Zustellung
      // beginnt die Frist spätestens fünf Monate nach Verkündung und endet einen
      // Monat später. Der Kern bildet das über `spaetesterBeginnMonateAbVerkuendung`
      // ab; wirksam wird es, sobald das Verkündungsdatum übergeben wird
      // (FristenRechner.berechne(..., verkuendung:)).
      return Fristdefinition(laenge: 1, einheit: .monate, anfang: .ereignis,
                             norm: "§ 517 ZPO", istNotfrist: true, verlaengerbar: false,
                             spaetesterBeginnMonateAbVerkuendung: 5)
    case .berufungsbegruendung:
      return Fristdefinition(laenge: 2, einheit: .monate, anfang: .ereignis,
                             norm: "§ 520 Abs. 2 ZPO", istNotfrist: false, verlaengerbar: true)
    case .revision:
      return Fristdefinition(laenge: 1, einheit: .monate, anfang: .ereignis,
                             norm: "§ 548 ZPO", istNotfrist: true, verlaengerbar: false)
    case .sofortigeBeschwerde:
      return Fristdefinition(laenge: 2, einheit: .wochen, anfang: .ereignis,
                             norm: "§ 569 Abs. 1 ZPO", istNotfrist: true, verlaengerbar: false)
    case .einspruchVersaeumnisurteil:
      return Fristdefinition(laenge: 2, einheit: .wochen, anfang: .ereignis,
                             norm: "§ 339 ZPO", istNotfrist: true, verlaengerbar: false)
    case .kuendigungsschutzklage:
      return Fristdefinition(laenge: 3, einheit: .wochen, anfang: .ereignis,
                             norm: "§ 4 KSchG", istNotfrist: false, verlaengerbar: false)
    case .eigene:
      return nil
    }
  }
}

/// Einheiten, die für eine frei eingegebene Frist angeboten werden.
private let eigeneEinheiten: [(Fristeinheit, String)] = [
  (.tage, "Tage"), (.wochen, "Wochen"), (.monate, "Monate")
]

// MARK: - Datenmodell

struct ProtokollEintrag: Identifiable {
  let id = UUID()
  let zeit = Date()
  let text: String
}

struct NotierteFrist: Identifiable {
  let id = UUID()
  var bezeichnung: String
  var absender: String
  var faelligkeit: Date
  var vorfrist: Date
  var verantwortlicher: String
  var istNotfrist: Bool
  var land: Bundesland
  var herkunft: Herkunft
  var klartext: String
  var erledigt = false
  var zweitePerson = ""
  var gestrichen = false
  var streichGrund = ""
}

@Observable
final class FristenArbeitsablaufModell {
  // 1 Post erfassen
  var bezeichnung = ""
  var zustellung = Date()
  var absender = ""

  // 2 Berechnen
  var fristart: Fristart = .berufung
  var eigeneLaenge = 2
  var eigeneEinheit: Fristeinheit = .wochen
  var eigeneNotfrist = false
  var land: Bundesland = .by

  // 3 Ergebnis
  var herleitung: Fristherleitung?
  var ueberschriebenesDatum: Date?
  var abweichungsGrund = ""
  var datumWirdGeaendert = false

  // 4 Notieren
  var vorfristTage = 7
  var verantwortlicher = ""

  // 5/6
  var fristen: [NotierteFrist] = []
  var protokoll: [ProtokollEintrag] = []

  // MARK: Eingabe-Signatur (ein geändertes Eingabefeld macht das Ergebnis ungültig)

  struct Eingabe: Equatable {
    var bezeichnung: String
    var absender: String
    var zustellung: Date
    var fristart: Fristart
    var laenge: Int
    var einheit: Fristeinheit
    var notfrist: Bool
    var land: Bundesland
  }

  var eingabe: Eingabe {
    Eingabe(bezeichnung: bezeichnung, absender: absender, zustellung: zustellung,
            fristart: fristart, laenge: eigeneLaenge, einheit: eigeneEinheit,
            notfrist: eigeneNotfrist, land: land)
  }

  var kannBerechnen: Bool {
    !bezeichnung.trimmingCharacters(in: .whitespaces).isEmpty
  }

  // MARK: Berechnen

  var aktuelleDefinition: Fristdefinition {
    if let d = fristart.definition { return d }
    // TODO: Rechtsgrundlage für richterliche Fristen mit dem Kern abstimmen.
    return Fristdefinition(
      laenge: eigeneLaenge, einheit: eigeneEinheit, anfang: .ereignis,
      norm: "richterliche Frist (§ 224 Abs. 2 ZPO)",
      istNotfrist: eigeneNotfrist, verlaengerbar: !eigeneNotfrist)
  }

  func berechne() {
    let ereignis = absender.trimmingCharacters(in: .whitespaces).isEmpty
      ? "Zustellung \(bezeichnung)"
      : "Zustellung \(bezeichnung) (\(absender))"
    herleitung = FristenRechner.berechne(
      ereignis: zustellung,
      ereignisBezeichnung: ereignis,
      definition: aktuelleDefinition,
      land: land)
    ueberschriebenesDatum = nil
    abweichungsGrund = ""
    datumWirdGeaendert = false
  }

  func verwirfErgebnis() {
    herleitung = nil
    ueberschriebenesDatum = nil
    abweichungsGrund = ""
    datumWirdGeaendert = false
  }

  /// Gültiges Fälligkeitsdatum: das überschriebene, sonst das berechnete.
  var faelligkeit: Date? { ueberschriebenesDatum ?? herleitung?.faelligkeit }
  var herkunft: Herkunft { ueberschriebenesDatum == nil ? .formel : .mensch }

  /// Klartext der Herleitung, bei Abweichung um die Abweichung ergänzt.
  var klartextGesamt: String {
    guard let h = herleitung else { return "" }
    var s = h.klartext
    if let neu = ueberschriebenesDatum {
      s += " ABWEICHUNG: Von Hand auf \(Fmt.kurz(neu)) gesetzt (berechnet: \(Fmt.kurz(h.faelligkeit)))"
      let g = abweichungsGrund.trimmingCharacters(in: .whitespacesAndNewlines)
      s += g.isEmpty ? "." : ", Grund: \(g)."
    }
    return s
  }

  func uebernehmeAbweichung(_ neu: Date, grund: String) {
    guard let h = herleitung else { return }
    let tag = Feiertagskalender.kalender.startOfDay(for: neu)
    if tag == h.faelligkeit {
      ueberschriebenesDatum = nil
      abweichungsGrund = ""
    } else {
      ueberschriebenesDatum = tag
      abweichungsGrund = grund
      log("Abweichung von der Berechnung: \(Fmt.kurz(h.faelligkeit)) -> \(Fmt.kurz(tag)). Grund: \(grund)")
    }
    datumWirdGeaendert = false
  }

  func nehmeAbweichungZurueck() {
    guard let h = herleitung, ueberschriebenesDatum != nil else { return }
    ueberschriebenesDatum = nil
    abweichungsGrund = ""
    log("Abweichung zurückgenommen, wieder berechnetes Datum \(Fmt.kurz(h.faelligkeit)).")
  }

  // MARK: Notieren

  var kannNotieren: Bool {
    herleitung != nil
      && !verantwortlicher.trimmingCharacters(in: .whitespaces).isEmpty
  }

  func vorfristDatum(fuer faelligkeit: Date) -> Date {
    let kal = Feiertagskalender.kalender
    var d = kal.date(byAdding: .day, value: -vorfristTage, to: faelligkeit) ?? faelligkeit
    // Vorfrist nie auf einen Tag legen, an dem keiner da ist: auf den Werktag davor.
    while Feiertagskalender.istWochenende(d) || Feiertagskalender.istFeiertag(d, land: land) != nil {
      d = kal.date(byAdding: .day, value: -1, to: d) ?? d
    }
    return d
  }

  func uebernehmen() {
    guard let h = herleitung, let f = faelligkeit, kannNotieren else { return }
    let frist = NotierteFrist(
      bezeichnung: bezeichnung,
      absender: absender,
      faelligkeit: f,
      vorfrist: vorfristDatum(fuer: f),
      verantwortlicher: verantwortlicher,
      istNotfrist: h.istNotfrist,
      land: h.land,
      herkunft: herkunft,
      klartext: klartextGesamt)
    // TODO: an VorgangStore anbinden (Frist dauerhaft speichern)
    fristen.append(frist)
    log("Notiert: \(bezeichnung), fällig \(Fmt.kurz(f)), Vorfrist \(Fmt.kurz(frist.vorfrist)), zuständig \(verantwortlicher).")

    // Formular für die nächste Post zurücksetzen
    bezeichnung = ""
    absender = ""
    zustellung = Date()
    verwirfErgebnis()
  }

  // MARK: Wiedervorlage

  var offeneFristen: [NotierteFrist] {
    fristen.filter { !$0.erledigt && !$0.gestrichen }.sorted { $0.faelligkeit < $1.faelligkeit }
  }

  /// Alle Fristen für die Ausgangskontrolle, gestrichene bleiben bewusst sichtbar.
  var kontrollListe: [NotierteFrist] {
    fristen.sorted { $0.faelligkeit < $1.faelligkeit }
  }

  /// Werktage von morgen bis einschließlich Fälligkeit (negativ: überfällig).
  func restwerktage(_ f: NotierteFrist) -> Int {
    let kal = Feiertagskalender.kalender
    let heute = kal.startOfDay(for: Date())
    let ziel = kal.startOfDay(for: f.faelligkeit)
    if ziel == heute { return 0 }
    let vorwaerts = ziel > heute
    var d = vorwaerts ? heute : ziel
    let ende = vorwaerts ? ziel : heute
    var zaehler = 0
    while d < ende {
      d = kal.date(byAdding: .day, value: 1, to: d) ?? ende
      if !Feiertagskalender.istWochenende(d) && Feiertagskalender.istFeiertag(d, land: f.land) == nil {
        zaehler += 1
      }
    }
    return vorwaerts ? zaehler : -zaehler
  }

  func kalendertage(_ f: NotierteFrist) -> Int {
    let kal = Feiertagskalender.kalender
    return kal.dateComponents([.day], from: kal.startOfDay(for: Date()),
                              to: kal.startOfDay(for: f.faelligkeit)).day ?? 0
  }

  func istKritisch(_ f: NotierteFrist) -> Bool { kalendertage(f) < 14 }

  // MARK: Ausgangskontrolle

  func index(_ id: UUID) -> Int? { fristen.firstIndex { $0.id == id } }

  func zweitePerson(_ id: UUID) -> String {
    index(id).map { fristen[$0].zweitePerson } ?? ""
  }
  func setzeZweitePerson(_ id: UUID, _ text: String) {
    if let i = index(id) { fristen[i].zweitePerson = text }
  }

  /// Vier-Augen-Prinzip: Bei Notfristen muss eine zweite, andere Person eingetragen sein.
  func darfErledigen(_ f: NotierteFrist) -> Bool {
    if f.gestrichen { return false }
    guard f.istNotfrist else { return true }
    let zweite = f.zweitePerson.trimmingCharacters(in: .whitespaces)
    return !zweite.isEmpty
      && zweite.caseInsensitiveCompare(f.verantwortlicher.trimmingCharacters(in: .whitespaces)) != .orderedSame
  }

  func setzeErledigt(_ id: UUID, _ wert: Bool) {
    guard let i = index(id) else { return }
    if wert && !darfErledigen(fristen[i]) { return }
    fristen[i].erledigt = wert
    // TODO: an VorgangStore anbinden (Erledigung samt Zweitbestätigung speichern)
    let f = fristen[i]
    if wert {
      let zusatz = f.istNotfrist ? ", bestätigt von \(f.zweitePerson)" : ""
      log("Erledigt: \(f.bezeichnung) (fällig \(Fmt.kurz(f.faelligkeit)))\(zusatz).")
    } else {
      log("Erledigt-Haken entfernt: \(f.bezeichnung).")
    }
  }

  func streiche(_ id: UUID, grund: String) {
    guard let i = index(id) else { return }
    let g = grund.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !g.isEmpty, !fristen[i].gestrichen else { return }
    // Notfristen dürfen nur mit zweiter Person gestrichen werden.
    if fristen[i].istNotfrist && !darfStreichen(fristen[i]) { return }
    fristen[i].gestrichen = true
    fristen[i].streichGrund = g
    // TODO: an VorgangStore anbinden (Streichung mit Grund speichern, nie löschen)
    log("Gestrichen: \(fristen[i].bezeichnung) (fällig \(Fmt.kurz(fristen[i].faelligkeit))). Grund: \(g)")
  }

  func darfStreichen(_ f: NotierteFrist) -> Bool {
    guard f.istNotfrist else { return true }
    let zweite = f.zweitePerson.trimmingCharacters(in: .whitespaces)
    return !zweite.isEmpty
      && zweite.caseInsensitiveCompare(f.verantwortlicher.trimmingCharacters(in: .whitespaces)) != .orderedSame
  }

  func log(_ text: String) {
    protokoll.insert(ProtokollEintrag(text: text), at: 0)
  }
}

// MARK: - Formatierung

private enum Fmt {
  private static func formatter(_ muster: String) -> DateFormatter {
    let df = DateFormatter()
    df.locale = Locale(identifier: "de_DE")
    df.calendar = Feiertagskalender.kalender
    df.timeZone = Feiertagskalender.kalender.timeZone
    df.dateFormat = muster
    return df
  }
  private static let kurzF = formatter("dd.MM.yyyy")
  private static let langF = formatter("EEEE, d. MMMM yyyy")
  private static let zeitF = formatter("dd.MM.yyyy HH:mm")

  static func kurz(_ d: Date) -> String { kurzF.string(from: d) }
  static func lang(_ d: Date) -> String { langF.string(from: d) }
  static func zeit(_ d: Date) -> String { zeitF.string(from: d) }
}

// MARK: - View

struct FristenArbeitsablaufView: View {
  @State private var modell = FristenArbeitsablaufModell()
  @State private var abweichungsEntwurf = Date()
  @State private var abweichungsGrundEntwurf = ""
  @State private var streichenFuer: UUID?
  @State private var streichGrundEntwurf = ""

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        schritt1
        schritt2
        schritt3
        schritt4
        schritt5
        schritt6
        verlauf
      }
      .frame(maxWidth: 640)
      .padding(20)
      .frame(maxWidth: .infinity)
    }
    .background(Premium.void)
    .onChange(of: modell.eingabe) { _, _ in
      // Eingabe geändert: ein altes Ergebnis passt nicht mehr dazu.
      if modell.herleitung != nil { modell.verwirfErgebnis() }
    }
  }

  // MARK: Bausteine

  private func abschnitt<Inhalt: View>(
    _ nummer: Int, _ titel: String, _ untertitel: String,
    @ViewBuilder inhalt: () -> Inhalt
  ) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 10) {
        Text("\(nummer)")
          .font(.system(size: 12, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(Premium.text)
          .frame(width: 24, height: 24)
          .background(Circle().fill(Premium.well))
          .overlay(Circle().stroke(Premium.hairline, lineWidth: 1))
        VStack(alignment: .leading, spacing: 2) {
          Text(titel)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Premium.text)
          Text(untertitel)
            .font(.system(size: 12))
            .foregroundStyle(Premium.textFaint)
        }
      }
      inhalt()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .premiumGlas(radius: Premium.rOuter)
  }

  private func feld(_ titel: String, text: Binding<String>, prompt: String = "") -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(titel)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(Premium.textSoft)
      TextField(prompt, text: text)
        .textFieldStyle(.plain)
        .font(.system(size: 13))
        .foregroundStyle(Premium.text)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Premium.rChip, style: .continuous).fill(Premium.well))
        .overlay(RoundedRectangle(cornerRadius: Premium.rChip, style: .continuous).stroke(Premium.hairline, lineWidth: 1))
    }
  }

  private func beschriftet<Inhalt: View>(_ titel: String, @ViewBuilder inhalt: () -> Inhalt) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(titel)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(Premium.textSoft)
      inhalt()
    }
  }

  private func hauptknopf(_ titel: String, aktiv: Bool, aktion: @escaping () -> Void) -> some View {
    Button(action: aktion) {
      Text(titel)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Premium.onAction)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Premium.rChip, style: .continuous).fill(Premium.action))
        .opacity(aktiv ? 1 : 0.4)
    }
    .buttonStyle(.plain)
    .disabled(!aktiv)
  }

  private func hinweis(_ text: String, farbe: Color = Premium.textFaint) -> some View {
    Text(text)
      .font(.system(size: 11))
      .foregroundStyle(farbe)
      .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: 1 Post erfassen

  private var schritt1: some View {
    abschnitt(1, "Post erfassen", "Was ist angekommen, und wann wurde es zugestellt?") {
      feld("Bezeichnung des Schreibens", text: $modell.bezeichnung, prompt: "z. B. Urteil vom 12.10.")
      feld("Gericht oder Absender", text: $modell.absender, prompt: "z. B. Landgericht München I")
      beschriftet("Zugestellt am") {
        DatePicker("", selection: $modell.zustellung, displayedComponents: .date)
          .labelsHidden()
          .datePickerStyle(.field)
      }
    }
  }

  // MARK: 2 Frist berechnen

  private var schritt2: some View {
    abschnitt(2, "Frist berechnen", "Welche Frist läuft, und wo muss die Erklärung eingehen?") {
      beschriftet("Art der Frist") {
        Picker("", selection: $modell.fristart) {
          ForEach(Fristart.allCases) { Text($0.titel).tag($0) }
        }
        .labelsHidden()
      }

      if modell.fristart == .eigene {
        HStack(spacing: 12) {
          Stepper(value: $modell.eigeneLaenge, in: 1...52) {
            Text("Dauer: \(modell.eigeneLaenge)")
              .font(.system(size: 13)).monospacedDigit()
              .foregroundStyle(Premium.text)
          }
          Picker("", selection: $modell.eigeneEinheit) {
            ForEach(eigeneEinheiten, id: \.0) { Text($0.1).tag($0.0) }
          }
          .labelsHidden()
          .frame(maxWidth: 120)
        }
        Toggle("Ist eine Notfrist", isOn: $modell.eigeneNotfrist)
          .font(.system(size: 13))
          .foregroundStyle(Premium.text)
      }

      beschriftet("Bundesland des Gerichts bzw. der Stelle, bei der die Erklärung eingehen muss") {
        Picker("", selection: $modell.land) {
          ForEach(Bundesland.allCases) { Text($0.bezeichnung).tag($0) }
        }
        .labelsHidden()
      }
      hinweis("Maßgeblich ist der Ort, an dem die Erklärung abzugeben ist, nicht der Sitz der Kanzlei (§ 193 BGB). Feiertage dieses Landes verschieben das Fristende.")

      hauptknopf("Berechnen", aktiv: modell.kannBerechnen) { modell.berechne() }
      if !modell.kannBerechnen {
        hinweis("Bitte zuerst die Bezeichnung des Schreibens eintragen.")
      }
    }
  }

  // MARK: 3 Ergebnis

  @ViewBuilder
  private var schritt3: some View {
    abschnitt(3, "Ergebnis", "Das Datum ist immer mit seiner Herleitung zu lesen.") {
      if let h = modell.herleitung, let datum = modell.faelligkeit {
        HStack(alignment: .center, spacing: 10) {
          Herkunftsmarke(herkunft: modell.herkunft, groesse: 10)
          Text(Fmt.lang(datum))
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(Premium.text)
            .fixedSize(horizontal: false, vertical: true)
        }

        if h.istNotfrist {
          HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(Premium.critical)
            Text("Notfrist (§ 224 ZPO) — nicht verlängerbar")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(Premium.critical)
          }
          .padding(10)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).fill(Premium.critical.opacity(0.12)))
          .overlay(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).stroke(Premium.critical.opacity(0.5), lineWidth: 1))
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("So wurde gerechnet")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Premium.textSoft)
          Text(modell.klartextGesamt)
            .font(.system(size: 13))
            .foregroundStyle(Premium.text)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
          hinweis("Rechner-Version \(h.rechnerVersion) · Erklärungsort: \(h.land.bezeichnung)")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).fill(Premium.well))

        abweichungBereich(h)
      } else {
        hinweis("Noch keine Berechnung. Bitte Schritt 2 ausführen.")
      }
    }
  }

  @ViewBuilder
  private func abweichungBereich(_ h: Fristherleitung) -> some View {
    if modell.ueberschriebenesDatum != nil {
      HStack(spacing: 8) {
        Herkunftsmarke(herkunft: .mensch, groesse: 8)
        Text("Von Hand geändert. Berechnet war: \(Fmt.kurz(h.faelligkeit)). Grund: \(modell.abweichungsGrund)")
          .font(.system(size: 12))
          .foregroundStyle(Premium.proposed)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
        Button("Zurücknehmen") { modell.nehmeAbweichungZurueck() }
          .buttonStyle(.plain)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Premium.action)
      }
    } else if !modell.datumWirdGeaendert {
      Button("Datum selbst festlegen") {
        abweichungsEntwurf = h.faelligkeit
        abweichungsGrundEntwurf = ""
        modell.datumWirdGeaendert = true
      }
      .buttonStyle(.plain)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(Premium.action)
    }

    if modell.datumWirdGeaendert {
      VStack(alignment: .leading, spacing: 10) {
        if h.istNotfrist {
          hinweis("Eine Notfrist lässt sich nicht verlängern. Es ist nur ein früheres Datum möglich.", farbe: Premium.critical)
          DatePicker("Neues Datum", selection: $abweichungsEntwurf,
                     in: ...h.faelligkeit, displayedComponents: .date)
            .datePickerStyle(.field)
        } else {
          DatePicker("Neues Datum", selection: $abweichungsEntwurf, displayedComponents: .date)
            .datePickerStyle(.field)
        }
        feld("Grund der Abweichung (Pflicht)", text: $abweichungsGrundEntwurf,
             prompt: "z. B. Fristverlängerung gewährt am …")
        HStack(spacing: 12) {
          hauptknopf("Datum übernehmen",
                     aktiv: !abweichungsGrundEntwurf.trimmingCharacters(in: .whitespaces).isEmpty) {
            modell.uebernehmeAbweichung(abweichungsEntwurf,
                                        grund: abweichungsGrundEntwurf.trimmingCharacters(in: .whitespacesAndNewlines))
          }
          Button("Abbrechen") { modell.datumWirdGeaendert = false }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Premium.textSoft)
        }
      }
      .padding(12)
      .background(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).fill(Premium.well))
    }
  }

  // MARK: 4 Notieren

  private var schritt4: some View {
    abschnitt(4, "Notieren", "Mit Vorfrist, damit nichts auf den letzten Drücker liegt.") {
      HStack(spacing: 12) {
        Stepper(value: $modell.vorfristTage, in: 1...60) {
          Text("Vorfrist: \(modell.vorfristTage) Tage vorher")
            .font(.system(size: 13)).monospacedDigit()
            .foregroundStyle(Premium.text)
        }
      }
      if let f = modell.faelligkeit {
        hinweis("Vorfrist am \(Fmt.lang(modell.vorfristDatum(fuer: f))) (fällt sie auf ein Wochenende oder einen Feiertag, rückt sie auf den Werktag davor).")
      }
      feld("Wer ist zuständig?", text: $modell.verantwortlicher, prompt: "Name")
      hauptknopf("In Fristenkalender übernehmen", aktiv: modell.kannNotieren) { modell.uebernehmen() }
      if modell.herleitung == nil {
        hinweis("Erst möglich, wenn eine Frist berechnet wurde.")
      } else if modell.verantwortlicher.trimmingCharacters(in: .whitespaces).isEmpty {
        hinweis("Bitte eine zuständige Person eintragen.")
      }
    }
  }

  // MARK: 5 Wiedervorlage

  private var schritt5: some View {
    abschnitt(5, "Wiedervorlage", "Offene Fristen, die nächste zuerst. Rot: weniger als 14 Tage.") {
      let offen = modell.offeneFristen
      if offen.isEmpty {
        hinweis("Keine offenen Fristen.")
      } else {
        VStack(spacing: 8) {
          ForEach(offen) { f in wiedervorlageZeile(f) }
        }
      }
    }
  }

  private func wiedervorlageZeile(_ f: NotierteFrist) -> some View {
    let kritisch = modell.istKritisch(f)
    let rest = modell.restwerktage(f)
    return VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Herkunftsmarke(herkunft: f.herkunft, groesse: 8)
        Text(Fmt.kurz(f.faelligkeit))
          .font(.system(size: 15, weight: .bold)).monospacedDigit()
          .foregroundStyle(kritisch ? Premium.critical : Premium.text)
        Text(f.bezeichnung)
          .font(.system(size: 13))
          .foregroundStyle(kritisch ? Premium.critical : Premium.text)
          .lineLimit(2)
        Spacer(minLength: 0)
        Text(restText(rest))
          .premiumChip(active: kritisch, tint: Premium.critical)
      }
      HStack(spacing: 8) {
        if f.istNotfrist {
          Text("Notfrist")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Premium.critical)
        }
        Text("Vorfrist \(Fmt.kurz(f.vorfrist)) · \(f.verantwortlicher)")
          .font(.system(size: 11))
          .foregroundStyle(Premium.textFaint)
      }
      DisclosureGroup("Herleitung") {
        Text(f.klartext)
          .font(.system(size: 12))
          .foregroundStyle(Premium.textSoft)
          .textSelection(.enabled)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 4)
      }
      .font(.system(size: 11))
      .foregroundStyle(Premium.textFaint)
    }
    .padding(12)
    .background(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
      .fill(kritisch ? Premium.critical.opacity(0.08) : Premium.well))
    .overlay(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
      .stroke(kritisch ? Premium.critical.opacity(0.5) : Premium.hairline, lineWidth: 1))
  }

  private func restText(_ rest: Int) -> String {
    if rest < 0 { return "\(-rest) Werktage überfällig" }
    if rest == 0 { return "heute fällig" }
    return rest == 1 ? "noch 1 Werktag" : "noch \(rest) Werktage"
  }

  // MARK: 6 Ausgangskontrolle

  private var schritt6: some View {
    let liste = modell.kontrollListe
    let zuPruefen = liste.filter { !$0.gestrichen }
    let erledigt = zuPruefen.filter { $0.erledigt }.count
    return abschnitt(6, "Ausgangskontrolle", "Abends prüfen: Ist jede Frist wirklich erledigt? Gestrichenes bleibt sichtbar.") {
      if liste.isEmpty {
        hinweis("Noch nichts zu kontrollieren.")
      } else {
        Text("\(erledigt) von \(zuPruefen.count) erledigt · Stand \(Fmt.kurz(Date()))")
          .font(.system(size: 12, weight: .semibold)).monospacedDigit()
          .foregroundStyle(Premium.textSoft)
        VStack(spacing: 8) {
          ForEach(liste) { f in kontrollZeile(f) }
        }
      }
    }
  }

  private func kontrollZeile(_ f: NotierteFrist) -> some View {
    let darf = modell.darfErledigen(f)
    return VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Toggle("", isOn: Binding(
          get: { f.erledigt },
          set: { modell.setzeErledigt(f.id, $0) }))
          .toggleStyle(.checkbox)
          .labelsHidden()
          .disabled(f.gestrichen || (!f.erledigt && !darf))
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 8) {
            Text(Fmt.kurz(f.faelligkeit))
              .font(.system(size: 13, weight: .bold)).monospacedDigit()
            Text(f.bezeichnung)
              .font(.system(size: 13))
            if f.istNotfrist {
              Text("Notfrist")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(f.gestrichen ? Premium.textFaint : Premium.critical)
            }
          }
          .strikethrough(f.gestrichen, color: Premium.textSoft)
          .foregroundStyle(f.gestrichen ? Premium.textFaint : Premium.text)
          Text("Zuständig: \(f.verantwortlicher)")
            .font(.system(size: 11))
            .foregroundStyle(Premium.textFaint)
        }
        Spacer(minLength: 0)
        if f.gestrichen {
          Text("gestrichen").premiumChip(active: false)
        } else if f.erledigt {
          Text("erledigt").premiumChip(active: true, tint: Premium.computed)
        }
      }

      if f.gestrichen {
        hinweis("Gestrichen. Grund: \(f.streichGrund)")
      }

      // Vier-Augen-Feld: sperrt das Erledigen, solange es leer ist.
      if f.istNotfrist && !f.gestrichen {
        if f.erledigt {
          hinweis("Zweite Prüfung durch \(f.zweitePerson).", farbe: Premium.computed)
        } else {
          feld("Zweite Person bestätigt (Pflicht bei Notfristen)",
               text: Binding(get: { modell.zweitePerson(f.id) },
                             set: { modell.setzeZweitePerson(f.id, $0) }),
               prompt: "Name der zweiten Person")
          if !darf {
            hinweis("Erledigen ist gesperrt, bis eine zweite, andere Person als \(f.verantwortlicher) eingetragen ist.",
                    farbe: Premium.critical)
          }
        }
      }

      if !f.gestrichen && !f.erledigt {
        streichenBereich(f)
      }
    }
    .padding(12)
    .background(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).fill(Premium.well))
    .overlay(RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).stroke(Premium.hairline, lineWidth: 1))
  }

  @ViewBuilder
  private func streichenBereich(_ f: NotierteFrist) -> some View {
    if streichenFuer == f.id {
      VStack(alignment: .leading, spacing: 8) {
        feld("Warum wird die Frist gestrichen?", text: $streichGrundEntwurf, prompt: "Pflichtangabe")
        if f.istNotfrist && !modell.darfStreichen(f) {
          hinweis("Eine Notfrist streichen nur zwei Personen gemeinsam: bitte oben die zweite Person eintragen.",
                  farbe: Premium.critical)
        }
        HStack(spacing: 12) {
          hauptknopf("Frist streichen",
                     aktiv: !streichGrundEntwurf.trimmingCharacters(in: .whitespaces).isEmpty
                       && modell.darfStreichen(f)) {
            modell.streiche(f.id, grund: streichGrundEntwurf)
            streichenFuer = nil
            streichGrundEntwurf = ""
          }
          Button("Abbrechen") { streichenFuer = nil; streichGrundEntwurf = "" }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Premium.textSoft)
        }
      }
    } else {
      Button("Frist streichen …") {
        streichenFuer = f.id
        streichGrundEntwurf = ""
      }
      .buttonStyle(.plain)
      .font(.system(size: 12))
      .foregroundStyle(Premium.textSoft)
    }
  }

  // MARK: Verlauf

  @ViewBuilder
  private var verlauf: some View {
    if !modell.protokoll.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("Verlauf")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Premium.textSoft)
        ForEach(modell.protokoll) { e in
          HStack(alignment: .top, spacing: 8) {
            Text(Fmt.zeit(e.zeit))
              .font(.system(size: 11)).monospacedDigit()
              .foregroundStyle(Premium.textFaint)
            Text(e.text)
              .font(.system(size: 11))
              .foregroundStyle(Premium.textSoft)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .premiumPanel()
    }
  }
}
