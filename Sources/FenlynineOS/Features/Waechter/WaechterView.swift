import SwiftUI
import FenlynineOSKern

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// WÄCHTER
// Prüf- und Korrektur-Agent: Zustand, Befunde, Grenzen, Nachweis,
// Änderungen an der App. Eine Spalte, ruhig.
// Alle Daten liegen vorerst nur im Speicher (Platzhalter, siehe TODOs).
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

// MARK: - Platzhalter: Prüfzustand

// TODO: an echte Stores anbinden -- der Prüfzustand muss aus Fristen-, Vorgangs-
// und Modul-Store gebildet werden. Die Strukturen enthalten (wie im Kern
// gefordert) nur Kennungen und Ja/Nein-Merkmale, keine Mandatsinhalte.

private struct PlatzhalterFrist: PruefbareFrist {
  var id: String
  var faelligkeit: Date
  var istNotfrist: Bool
  var hatHerleitung: Bool
  var berechnetMitVersion: String?
  var vierAugenBestaetigt: Bool
  var erledigt: Bool
  var gestrichen: Bool
  var hatVorfrist: Bool
  var verantwortlicherGesetzt: Bool
}

private struct PlatzhalterVorgang: PruefbarerVorgang {
  var id: String
  var hatAnnahmenBegruendung: Bool
  var prognoseVorhanden: Bool
  var kostenrisikoBerechnet: Bool
  var streitwertGesetzt: Bool
  var konfliktpruefungErfolgt: Bool
  var rechtsgebietGesetzt: Bool
}

private struct PlatzhalterWert: PruefbarerWert {
  var id: String
  var quelleGenannt: Bool
  var abgerufenAm: Date?
  var istVeraltet: Bool
}

private struct PlatzhalterModul: PruefbaresModul {
  var id: String
  var sichtbar: Bool
  var zuletztBenutzt: Date?
  var benutzungenLetzte90Tage: Int
  var istPflichtmodul: Bool
}

private struct PlatzhalterPruefzustand: Pruefzustand {
  var fristen: [any PruefbareFrist]
  var vorgaenge: [any PruefbarerVorgang]
  var belegteWerte: [any PruefbarerWert]
  var modul: [any PruefbaresModul]
  var letzteAusgangskontrolle: Date?
  var heute: Date
  var aktuelleKernversion: String

  /// Beispieldaten mit ein paar absichtlichen Lücken, damit die Befundliste nicht leer bleibt.
  static func beispiel() -> PlatzhalterPruefzustand {
    let heute = Date()
    let tag: TimeInterval = 86_400
    return PlatzhalterPruefzustand(
      fristen: [
        PlatzhalterFrist(id: "frist-001", faelligkeit: heute.addingTimeInterval(3 * tag),
                         istNotfrist: true, hatHerleitung: false, berechnetMitVersion: nil,
                         vierAugenBestaetigt: false, erledigt: false, gestrichen: false,
                         hatVorfrist: false, verantwortlicherGesetzt: true),
        PlatzhalterFrist(id: "frist-002", faelligkeit: heute.addingTimeInterval(20 * tag),
                         istNotfrist: false, hatHerleitung: true, berechnetMitVersion: "1.0.0",
                         vierAugenBestaetigt: true, erledigt: false, gestrichen: false,
                         hatVorfrist: true, verantwortlicherGesetzt: false)
      ],
      vorgaenge: [
        PlatzhalterVorgang(id: "vorgang-001", hatAnnahmenBegruendung: false, prognoseVorhanden: true,
                           kostenrisikoBerechnet: false, streitwertGesetzt: true,
                           konfliktpruefungErfolgt: true, rechtsgebietGesetzt: true)
      ],
      belegteWerte: [
        PlatzhalterWert(id: "wert-001", quelleGenannt: false, abgerufenAm: nil, istVeraltet: true)
      ],
      modul: [
        PlatzhalterModul(id: "zeitleiste", sichtbar: true, zuletztBenutzt: heute,
                         benutzungenLetzte90Tage: 80, istPflichtmodul: true)
      ],
      letzteAusgangskontrolle: nil,
      heute: heute,
      aktuelleKernversion: "1.0.0")
  }
}

// MARK: - Platzhalter: Korrekturausführer

/// Platzhalter: führt nichts aus, sondern schreibt nur mit.
/// TODO: an echte Stores anbinden -- jeder Fall von `Korrektur` muss einzeln umgesetzt werden
/// (Hinweis anlegen, Markierung setzen, Neuberechnung, Prüfung anfordern, Modelländerung über
/// den `Modellverwalter`). Falldaten kann der Ausführer nicht ändern: Es gibt keinen Fall dafür.
final class PlatzhalterKorrekturausfuehrer: Korrekturausfuehrer {
  private(set) var mitschrift: [String] = []

  func fuehreAus(_ k: Korrektur) throws {
    mitschrift.append(k.beschreibung)
    print("[Wächter] Korrektur (nur protokolliert): \(k.beschreibung)")
  }
}

// MARK: - Modell

@Observable
final class WaechterModell {
  // Zustand des Agenten
  var autonomie: Autonomie = Autonomie.empfohlen
  private(set) var letzterLauf: Prueflauf?
  private(set) var laufAnzahl = 0
  private(set) var uebernommen: Set<UUID> = []
  private(set) var meldung: String?

  // Nachweis
  var nachweisTag = Date()
  private(set) var protokollErgebnis: String?

  // Änderungen an der App (Spiegel des Modellverwalters, damit die Ansicht aktualisiert)
  private(set) var modellVerlauf: [Modellversion] = []
  private(set) var modellFehler: String?

  // Nicht beobachtet: die Kern-Objekte selbst
  @ObservationIgnored let protokoll = Pruefprotokoll()
  @ObservationIgnored private let verwalter = Modellverwalter()
  @ObservationIgnored private let ausfuehrer = PlatzhalterKorrekturausfuehrer()
  // TODO: an echte Stores anbinden -- hier den echten Prüfzustand liefern.
  @ObservationIgnored private let zustand = PlatzhalterPruefzustand.beispiel()
  // TODO: an echte Stores anbinden -- Regelwerk ggf. aus Kanzleikonfiguration.
  @ObservationIgnored private let regeln: [any Regel] = Standardregelwerk.alle

  init() {
    // Beispielverlauf, damit der Abschnitt "Änderungen an der App" etwas zeigt.
    // TODO: an echte Stores anbinden -- der echte Modellverwalter gehört der App, nicht dieser Ansicht.
    _ = try? verwalter.anwenden(.erklaersaetze(an: false), von: "Wächter (Beispiel)")
    _ = try? verwalter.anwenden(.darstellungDichte(.kompakt), von: "Kanzlei (Beispiel)")
    _ = try? verwalter.anwenden(
      .bestaetigungErforderlich(ablaufId: "fristen.arbeitsablauf", schrittId: "notieren", erforderlich: false),
      von: "Wächter (Beispiel)")
    modellVerlauf = verwalter.verlauf
  }

  // MARK: Prüfen

  func pruefen() {
    let waechter = Waechter(regeln: regeln, autonomie: autonomie, protokoll: protokoll)
    let lauf = waechter.pruefe(zustand, ausfuehrer: ausfuehrer)
    letzterLauf = lauf
    laufAnzahl = protokoll.laeufe.count
    uebernommen = []
    protokollErgebnis = nil
    meldung = nil
  }

  /// Befunde des letzten Laufs plus KI-Vorschläge, schwerste zuerst.
  var befunde: [Befund] {
    guard let lauf = letzterLauf else { return [] }
    let alle = lauf.befunde + kiBefundePlatzhalter
    return alle.sorted { a, b in
      if a.schwere != b.schwere { return a.schwere > b.schwere }
      return a.titel < b.titel
    }
  }

  /// TODO: an echte Stores anbinden -- KI-Schicht liefert hier Befunde mit `ausKI: true`.
  /// Der Wächter selbst erzeugt keine; das ist ein Beispiel für die Darstellung.
  private var kiBefundePlatzhalter: [Befund] {
    [Befund(regelId: "ki.beispiel", regelVersion: "0",
            schwere: .auffaellig,
            titel: "Möglicher Widerspruch in den Angaben zum Vorgang",
            erklaerung: "Die KI vermutet, dass zwei Angaben nicht zusammenpassen. Das ist eine Vermutung, kein Prüfergebnis.",
            objektId: "vorgang-001",
            belegstelle: "Vorgang, Angaben zum Streitwert",
            korrektur: .pruefungAnfordern(objektId: "vorgang-001",
                                          frage: "Passen Streitwert und Antrag zusammen?"),
            ausKI: true)]
  }

  // MARK: Korrektur übernehmen

  func uebernehmen(_ befund: Befund) {
    guard let korrektur = befund.korrektur else { return }
    do {
      try ausfuehrer.fuehreAus(korrektur)
      uebernommen.insert(befund.id)
      meldung = "Übernommen. (Platzhalter: es wurde nur protokolliert.)"
    } catch {
      meldung = "Das ließ sich nicht übernehmen: \(error.localizedDescription)"
    }
  }

  // MARK: Nachweis

  var negativnachweis: String {
    _ = laufAnzahl // Abhängigkeit, damit die Ansicht nach einem neuen Lauf aktualisiert
    return protokoll.negativnachweis(fuer: nachweisTag)
      ?? "Für diesen Tag gibt es keinen Nachweis: Entweder lief keine Prüfung, oder das Protokoll ist beschädigt."
  }

  func protokollPruefen() {
    let anzahl = protokoll.laeufe.count
    protokollErgebnis = protokoll.istUnversehrt()
      ? "Protokollkette unversehrt, \(anzahl) \(anzahl == 1 ? "Lauf" : "Läufe")"
      : "Kette beschädigt"
  }

  // MARK: Änderungen an der App

  /// Neueste zuerst.
  var letzteVersionen: [Modellversion] { Array(modellVerlauf.reversed().prefix(10)) }

  /// Zurücknehmen geht nur bei einer echten Einzeländerung; der Ausgangsstand und
  /// frühere Rückrolle haben nichts, was sich "zurücknehmen" ließe.
  func kannZuruecknehmen(_ v: Modellversion) -> Bool {
    v.aenderung != nil && v.modell.version > 1
  }

  /// Würde das Zurücknehmen eine Sicherung abschwächen? Dann braucht es eine ausdrückliche Bestätigung.
  func zuruecknehmenSchwaechtAb(_ v: Modellversion) -> Bool {
    verwalter.rueckrollSchwaechtSicherungAb(bisVersion: v.modell.version - 1) ?? false
  }

  func zuruecknehmen(_ v: Modellversion) {
    do {
      // TODO: an echte Stores anbinden -- Name des angemeldeten Anwalts statt Platzhalter.
      try verwalter.zuruecknehmen(bisVersion: v.modell.version - 1, von: "Anwalt (Beispiel)")
      modellVerlauf = verwalter.verlauf
      modellFehler = nil
    } catch {
      modellFehler = error.localizedDescription
    }
  }
}

// MARK: - Ansicht

struct WaechterView: View {
  @State private var model = WaechterModell()
  @State private var rueckrollKandidat: Modellversion?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        kopfbereich
        befundliste
        grenzen
        nachweis
        aenderungen
      }
      .padding(24)
      .frame(maxWidth: 760, alignment: .leading)
      .frame(maxWidth: .infinity)
    }
    .background(Premium.void)
    .confirmationDialog(
      "Diese Änderung schwächt eine Sicherung ab",
      isPresented: Binding(get: { rueckrollKandidat != nil },
                           set: { if !$0 { rueckrollKandidat = nil } }),
      titleVisibility: .visible
    ) {
      Button("Trotzdem zurücknehmen", role: .destructive) {
        if let v = rueckrollKandidat { model.zuruecknehmen(v) }
        rueckrollKandidat = nil
      }
      Button("Abbrechen", role: .cancel) { rueckrollKandidat = nil }
    } message: {
      Text("Beim Zurücknehmen entfällt ein Pflichtfeld oder eine Bestätigung (z. B. Vier-Augen-Prinzip). Das sollte bewusst ein Mensch entscheiden.")
    }
  }

  // MARK: Bausteine

  private func abschnitt(_ titel: String) -> some View {
    Text(titel.uppercased())
      .font(.system(size: 11, weight: .semibold))
      .tracking(0.8)
      .foregroundStyle(Premium.textFaint)
  }

  private func schwereFarbe(_ s: Schwere) -> Color {
    switch s {
    case .kritisch: return Premium.critical
    case .ernst: return Premium.proposed
    case .auffaellig, .hinweis: return Premium.textSoft
    }
  }

  // MARK: 1 Kopfbereich

  private var zustandssatz: String {
    guard let lauf = model.letzterLauf else { return "Noch nicht geprüft" }
    let kalender = Calendar.current
    let f = DateFormatter()
    f.locale = Locale(identifier: "de_DE")
    f.dateFormat = kalender.isDateInToday(lauf.beendetAm) ? "HH:mm" : "dd.MM.yyyy HH:mm"
    let wann = (kalender.isDateInToday(lauf.beendetAm) ? "heute " : "") + f.string(from: lauf.beendetAm)
    let n = model.befunde.count
    return "Letzte Prüfung \(wann) · \(lauf.anzahlRegeln) Regeln · \(n) \(n == 1 ? "Befund" : "Befunde")"
  }

  private var kopfbereich: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Wächter")
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(Premium.text)
      Text(zustandssatz)
        .font(.system(size: 13))
        .foregroundStyle(Premium.textSoft)

      VStack(alignment: .leading, spacing: 8) {
        Picker("Wie selbstständig darf der Wächter sein?", selection: $model.autonomie) {
          ForEach(Autonomie.allCases, id: \.self) { stufe in
            Text(stufe.bezeichnung).tag(stufe)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()

        Text(model.autonomie.erklaerung)
          .font(.system(size: 12))
          .foregroundStyle(Premium.textSoft)
          .fixedSize(horizontal: false, vertical: true)
      }

      if model.autonomie == .selbstheilend {
        HStack(alignment: .top, spacing: 10) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(Premium.proposed)
          VStack(alignment: .leading, spacing: 4) {
            Text("Achtung: Der Wächter handelt jetzt selbst")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(Premium.text)
            Text("Auf dieser Stufe führt der Agent folgenlose Korrekturen selbst aus, ohne vorher zu fragen. Empfohlen ist die Stufe „\(Autonomie.empfohlen.bezeichnung)“: Beobachten Sie zuerst einige Wochen, was der Wächter vorschlägt.")
              .font(.system(size: 12))
              .foregroundStyle(Premium.textSoft)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
            .fill(Premium.proposed.opacity(0.12))
        )
        .overlay(
          RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
            .stroke(Premium.proposed.opacity(0.6), lineWidth: 1)
        )
      }

      Button {
        model.pruefen()
      } label: {
        Text("Jetzt prüfen")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(Premium.onAction)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Capsule().fill(Premium.action))
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: 2 Befundliste

  private var befundliste: some View {
    VStack(alignment: .leading, spacing: 12) {
      abschnitt("Befunde")
      if let meldung = model.meldung {
        Text(meldung)
          .font(.system(size: 12))
          .foregroundStyle(Premium.computed)
      }
      if model.letzterLauf == nil {
        Text("Sobald Sie „Jetzt prüfen“ drücken, erscheinen die Befunde hier, schwerste zuerst.")
          .font(.system(size: 12))
          .foregroundStyle(Premium.textFaint)
      } else if model.befunde.isEmpty {
        Text("Nichts aufgefallen.")
          .font(.system(size: 13))
          .foregroundStyle(Premium.textSoft)
      } else {
        ForEach(model.befunde) { befund in
          befundKarte(befund)
        }
      }
    }
  }

  private func befundKarte(_ befund: Befund) -> some View {
    let farbe = schwereFarbe(befund.schwere)
    return HStack(alignment: .top, spacing: 12) {
      RoundedRectangle(cornerRadius: 2)
        .fill(farbe)
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          Text(befund.schwere.bezeichnung.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(farbe)
          if befund.ausKI {
            HStack(spacing: 5) {
              Herkunftsmarke(herkunft: .ki, groesse: 8)
              Text("KI-Vorschlag")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Premium.textSoft)
            }
          }
        }

        Text(befund.titel)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Premium.text)
          .fixedSize(horizontal: false, vertical: true)

        Text(befund.erklaerung)
          .font(.system(size: 12))
          .foregroundStyle(Premium.textSoft)
          .fixedSize(horizontal: false, vertical: true)

        if befund.ausKI {
          Text("Das ist eine Vermutung der KI, kein Prüfergebnis. Hier entscheidet immer ein Mensch; der Wächter führt das nie von selbst aus.")
            .font(.system(size: 11))
            .foregroundStyle(Premium.textFaint)
            .fixedSize(horizontal: false, vertical: true)
        }

        if befund.norm != nil || befund.belegstelle != nil {
          HStack(spacing: 10) {
            if let norm = befund.norm {
              Text(norm).premiumChip(active: false)
            }
            if let beleg = befund.belegstelle {
              Text("Beleg: \(beleg)")
                .font(.system(size: 11))
                .foregroundStyle(Premium.textFaint)
            }
          }
        }

        if let korrektur = befund.korrektur {
          korrekturZeile(befund, korrektur)
        }
      }
    }
    .padding(14)
    .premiumGlas(radius: Premium.rCard)
  }

  @ViewBuilder
  private func korrekturZeile(_ befund: Befund, _ korrektur: Korrektur) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(korrektur.beschreibung)
        .font(.system(size: 12))
        .foregroundStyle(Premium.textSoft)
        .fixedSize(horizontal: false, vertical: true)

      if case .feldErgaenzen = korrektur {
        Button("Zum Feld springen") {
          // TODO: Navigation anbinden
        }
        .buttonStyle(.plain)
        .premiumChip(active: true)
      } else if model.uebernommen.contains(befund.id) {
        Text("Übernommen")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(Premium.computed)
      } else {
        Button("Übernehmen") {
          model.uebernehmen(befund)
        }
        .buttonStyle(.plain)
        .premiumChip(active: true)
      }
    }
    .padding(.top, 4)
  }

  // MARK: 3 Was der Agent nicht darf

  private var grenzen: some View {
    VStack(alignment: .leading, spacing: 12) {
      abschnitt("Was der Agent nicht darf")
      Text("Diese Grenze läuft nicht über eine Einstellung, sondern über den Code: Es gibt keine Funktion, die eine Frist ändert. Der Wächter kann es nicht, auch nicht aus Versehen.")
        .font(.system(size: 13))
        .foregroundStyle(Premium.text)
        .fixedSize(horizontal: false, vertical: true)

      HStack(alignment: .top, spacing: 16) {
        liste("Niemals", Sperren.niemals, farbe: Premium.critical, symbol: "xmark.circle.fill")
        liste("Darf er", Sperren.erlaubt, farbe: Premium.computed, symbol: "checkmark.circle.fill")
      }
    }
  }

  private func liste(_ titel: String, _ eintraege: [String], farbe: Color, symbol: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(titel)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(farbe)
      ForEach(eintraege, id: \.self) { eintrag in
        HStack(alignment: .top, spacing: 6) {
          Image(systemName: symbol)
            .font(.system(size: 11))
            .foregroundStyle(farbe)
            .padding(.top, 1)
          Text(eintrag)
            .font(.system(size: 12))
            .foregroundStyle(Premium.textSoft)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).fill(Premium.panel)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
        .stroke(Premium.hairline, lineWidth: 1)
    )
  }

  // MARK: 4 Nachweis

  private var nachweis: some View {
    VStack(alignment: .leading, spacing: 12) {
      abschnitt("Nachweis")
      Text("Das Protokoll belegt, dass Ihre Fristenorganisation funktioniert hat und was an einem Tag geprüft wurde, wichtig für die Wiedereinsetzung nach § 233 ZPO.")
        .font(.system(size: 12))
        .foregroundStyle(Premium.textSoft)
        .fixedSize(horizontal: false, vertical: true)

      DatePicker("Tag", selection: $model.nachweisTag, displayedComponents: .date)
        .datePickerStyle(.field)
        .font(.system(size: 12))
        .foregroundStyle(Premium.text)
        .frame(maxWidth: 220, alignment: .leading)

      Text(model.negativnachweis)
        .font(.system(size: 13))
        .foregroundStyle(Premium.text)
        .fixedSize(horizontal: false, vertical: true)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).fill(Premium.well)
        )

      HStack(spacing: 12) {
        Button("Protokoll prüfen") { model.protokollPruefen() }
          .buttonStyle(.plain)
          .premiumChip(active: true)
        if let ergebnis = model.protokollErgebnis {
          Text(ergebnis)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ergebnis.hasPrefix("Kette beschädigt") ? Premium.critical : Premium.computed)
        }
      }
    }
  }

  // MARK: 5 Änderungen an der App

  private var aenderungen: some View {
    VStack(alignment: .leading, spacing: 12) {
      abschnitt("Änderungen an der App")
      if let fehler = model.modellFehler {
        Text(fehler)
          .font(.system(size: 12))
          .foregroundStyle(Premium.critical)
      }
      ForEach(model.letzteVersionen, id: \.id) { version in
        versionZeile(version)
      }
    }
  }

  private func versionZeile(_ v: Modellversion) -> some View {
    let schwaecht = v.aenderung?.schwaechtSicherungAb ?? false
    let f = DateFormatter()
    f.locale = Locale(identifier: "de_DE")
    f.dateFormat = "dd.MM.yyyy HH:mm"
    let beschreibung: String = {
      if let a = v.aenderung { return a.beschreibung(gegen: v.modell) }
      return v.modell.version == 1 ? "Ausgangsstand" : "Früheren Stand wiederhergestellt"
    }()

    return VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top, spacing: 10) {
        VStack(alignment: .leading, spacing: 3) {
          Text(beschreibung)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Premium.text)
            .fixedSize(horizontal: false, vertical: true)
          Text("Version \(v.modell.version) · \(v.angewendetVon) · \(f.string(from: v.angewendetAm))")
            .font(.system(size: 11))
            .foregroundStyle(Premium.textFaint)
        }
        Spacer(minLength: 8)
        if model.kannZuruecknehmen(v) {
          Button("Zurücknehmen") {
            if model.zuruecknehmenSchwaechtAb(v) {
              rueckrollKandidat = v
            } else {
              model.zuruecknehmen(v)
            }
          }
          .buttonStyle(.plain)
          .premiumChip(active: false)
        }
      }
      if schwaecht {
        HStack(spacing: 6) {
          Image(systemName: "exclamationmark.triangle.fill")
          Text("Schwächt eine Sicherung ab (Pflichtfeld oder Bestätigung). Darf nur ein Mensch freigeben.")
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(Premium.proposed)
      }
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous).fill(Premium.panel)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Premium.rCard, style: .continuous)
        .stroke(schwaecht ? Premium.proposed.opacity(0.6) : Premium.hairline, lineWidth: 1)
    )
  }
}
