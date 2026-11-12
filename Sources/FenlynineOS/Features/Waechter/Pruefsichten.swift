import Foundation
import FenlynineOSKern

// ────────────────────────────────────────────────────────────────────────────
// PRÜFSICHTEN — was der Wächter von der App zu sehen bekommt
// ────────────────────────────────────────────────────────────────────────────
//
// Diese Datei ist sicherheitsrelevant und nicht bloß Verdrahtung.
//
// Der Wächter arbeitet gegen die schlanken Protokolle aus `FenlynineOSKern`.
// Es wäre naheliegend, einfach `Deadline: PruefbareFrist` zu schreiben und
// fertig. Genau das darf nicht passieren: Eine Regel könnte dann per
// `as? Deadline` auf den konkreten Typ zurückcasten und käme an Titel,
// Aktenzeichen, Mandantennamen und Notizen — an alles, was die Sicht
// gerade NICHT herausgeben soll.
//
// Deshalb kopieren die Sichten unten nur die Ja/Nein-Merkmale in eigene
// Strukturen. Was hier nicht abgeschrieben wird, existiert für den Wächter
// nicht. Der Rückcast läuft ins Leere, weil es nichts zurückzucasten gibt.
//
// Regel für künftige Änderungen: In diese Strukturen kommen ausschließlich
// Bool, Int, Date und stabile Kennungen. Niemals ein Freitext, niemals ein
// Betrag, niemals ein Name.
// ────────────────────────────────────────────────────────────────────────────

/// Fristarten, die das Gesetz als Notfrist bezeichnet (§ 224 Abs. 1 ZPO).
/// Notfristen sind weder verlängerbar noch abkürzbar; ihre Versäumung ist nur
/// über die Wiedereinsetzung (§ 233 ZPO) zu heilen. Deshalb prüft der Wächter
/// sie strenger — etwa auf die Vier-Augen-Bestätigung.
private let notfristArten: Set<Deadline.FristTyp> = [
  .berufungsfrist,
  .revisionsfrist,
  .einspruchVersaeumnisurteil
  // Bewusst NICHT enthalten: .berufungsbegruendung und .revisionsbegruendung
  // sind auf Antrag verlängerbar (§ 520 Abs. 2, § 551 Abs. 2 ZPO) und damit
  // keine Notfristen. .widerspruchMahnbescheid ebenfalls nicht: Der
  // Widerspruch bleibt möglich, solange kein Vollstreckungsbescheid ergangen
  // ist (§ 694 ZPO).
]

/// Schlanke Sicht auf eine Frist. Enthält keine Inhalte.
struct FristSicht: PruefbareFrist {
  let id: String
  let faelligkeit: Date
  let istNotfrist: Bool
  let hatHerleitung: Bool
  let berechnetMitVersion: String?
  let vierAugenBestaetigt: Bool
  let erledigt: Bool
  let gestrichen: Bool
  let hatVorfrist: Bool
  let verantwortlicherGesetzt: Bool

  init(_ d: Deadline) {
    self.id = d.id ?? UUID().uuidString
    self.faelligkeit = d.due_date
    self.istNotfrist = notfristArten.contains(d.frist_type)
    // Eine Herleitung liegt vor, wenn die Frist aus einer Norm gerechnet wurde
    // und die Rechnung dokumentiert ist. Ein bloßes Datum reicht nicht.
    self.hatHerleitung = (d.paragraph?.isEmpty == false)
                      && (d.notizen?.isEmpty == false)
    // TODO: Sobald Deadline die Kernversion mitführt, hier durchreichen.
    // Bis dahin meldet die Regel `frist.veraltete.berechnung` jede Frist --
    // das ist die sichere Richtung: lieber einmal zu viel prüfen lassen.
    self.berechnetMitVersion = nil
    // TODO: Vier-Augen-Bestätigung wird derzeit nur im Arbeitsablauf gehalten
    // und nicht persistiert. Bis dahin gilt sie als nicht erteilt.
    self.vierAugenBestaetigt = false
    self.erledigt = d.status == .erledigt
    // Das Datenmodell kennt kein "gestrichen"; versäumte Fristen sind der
    // nächstliegende Fall, der nicht mehr zu bearbeiten ist.
    self.gestrichen = d.status == .versaeumt
    self.hatVorfrist = d.erinnerung_tage > 0
    self.verantwortlicherGesetzt = d.responsible?.isEmpty == false
  }
}

/// Schlanke Sicht auf einen Vorgang. Enthält weder Streitwert noch Parteien.
struct VorgangSicht: PruefbarerVorgang {
  let id: String
  let hatAnnahmenBegruendung: Bool
  let prognoseVorhanden: Bool
  let kostenrisikoBerechnet: Bool
  let streitwertGesetzt: Bool
  let konfliktpruefungErfolgt: Bool
  let rechtsgebietGesetzt: Bool

  /// Beachte: Der Konstruktor nimmt nur Wahrheitswerte entgegen, keine
  /// Fallobjekte. Wer ihn aufruft, entscheidet bewusst, was preisgegeben wird.
  init(id: String,
       hatAnnahmenBegruendung: Bool,
       prognoseVorhanden: Bool,
       kostenrisikoBerechnet: Bool,
       streitwertGesetzt: Bool,
       konfliktpruefungErfolgt: Bool,
       rechtsgebietGesetzt: Bool) {
    self.id = id
    self.hatAnnahmenBegruendung = hatAnnahmenBegruendung
    self.prognoseVorhanden = prognoseVorhanden
    self.kostenrisikoBerechnet = kostenrisikoBerechnet
    self.streitwertGesetzt = streitwertGesetzt
    self.konfliktpruefungErfolgt = konfliktpruefungErfolgt
    self.rechtsgebietGesetzt = rechtsgebietGesetzt
  }

  init(_ f: LegalCase) {
    self.id = f.id ?? UUID().uuidString
    // TODO: Begründung der Annahmen wird erst mit dem Szenariorechner erfasst.
    self.hatAnnahmenBegruendung = false
    self.prognoseVorhanden = f.prognose != nil
    // Das Kostenrisiko wird heute nur flüchtig berechnet und nicht am Fall
    // gespeichert. Die Streitwert- und Gebührenfelder sagen also nichts
    // darüber aus, ob jemand das Risiko tatsächlich ermittelt hat.
    // TODO: an Kostenrisiko aus dem Kern anbinden, sobald es persistiert wird.
    self.kostenrisikoBerechnet = false
    self.streitwertGesetzt = (f.streitwert ?? 0) > 0
    // TODO: Konfliktprüfung wird im KonfliktRadar gehalten, noch nicht am Fall.
    self.konfliktpruefungErfolgt = false
    self.rechtsgebietGesetzt = f.rechtsgebiet?.isEmpty == false
  }
}

/// Schlanke Sicht auf einen belegten Wert.
struct WertSicht: PruefbarerWert {
  let id: String
  let quelleGenannt: Bool
  let abgerufenAm: Date
  let istVeraltet: Bool

  init(id: String, quelleGenannt: Bool, abgerufenAm: Date, istVeraltet: Bool) {
    self.id = id
    self.quelleGenannt = quelleGenannt
    self.abgerufenAm = abgerufenAm
    self.istVeraltet = istVeraltet
  }
}

/// Schlanke Sicht auf ein Modul. Hier darf der Wächter umbauen.
struct ModulSicht: PruefbaresModul {
  let id: String
  let sichtbar: Bool
  let zuletztBenutzt: Date?
  let benutzungenLetzte90Tage: Int
  let istPflichtmodul: Bool

  init(id: String, sichtbar: Bool, zuletztBenutzt: Date?,
       benutzungenLetzte90Tage: Int, istPflichtmodul: Bool) {
    self.id = id
    self.sichtbar = sichtbar
    self.zuletztBenutzt = zuletztBenutzt
    self.benutzungenLetzte90Tage = benutzungenLetzte90Tage
    self.istPflichtmodul = istPflichtmodul
  }

  init(_ m: Moduleintrag, benutzungen: Int, zuletzt: Date?) {
    self.id = m.id
    self.sichtbar = m.sichtbar
    self.zuletztBenutzt = zuletzt
    self.benutzungenLetzte90Tage = benutzungen
    self.istPflichtmodul = m.istPflichtmodul
  }
}

/// Der Zustand, den der Wächter prüft. Zusammengesetzt aus den Sichten oben —
/// und aus nichts sonst.
struct AppPruefzustand: Pruefzustand {
  let fristen: [any PruefbareFrist]
  let vorgaenge: [any PruefbarerVorgang]
  let belegteWerte: [any PruefbarerWert]
  let modul: [any PruefbaresModul]
  let letzteAusgangskontrolle: Date?
  let heute: Date
  let aktuelleKernversion: String

  init(fristen: [Deadline],
       faelle: [LegalCase],
       werte: [WertSicht] = [],
       module: [ModulSicht] = [],
       letzteAusgangskontrolle: Date?,
       heute: Date = Date(),
       aktuelleKernversion: String = FristenRechner.version) {
    self.fristen = fristen.map(FristSicht.init)
    self.vorgaenge = faelle.map(VorgangSicht.init)
    self.belegteWerte = werte
    self.modul = module
    self.letzteAusgangskontrolle = letzteAusgangskontrolle
    self.heute = heute
    self.aktuelleKernversion = aktuelleKernversion
  }
}
