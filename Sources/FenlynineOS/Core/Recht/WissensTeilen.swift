import Foundation
import AppKit

// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
// WISSENS-TEILEN -- strikt freiwillig (Opt-in)
//
// Anwältinnen und Anwälte entscheiden selbst, ob sie Rechtswissen beitragen:
// · Standard: AUS -- nichts wird geteilt, alles bleibt lokal.
// · Eingeschaltet: Dokumente/Wissenspakete können aktiv hochgeladen werden.
// Sie landen im PowerOS-Ordner (Beitraege/) und in der Datenbank (geteilt=1).
// · Jederzeit widerrufbar; jeder Beitrag wird protokolliert.
//
// Es geht ausschließlich um RECHTSWISSEN (Normen, Urteile, Aufsätze, Muster) --
// niemals um Mandats- oder personenbezogene Daten.
// nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

@MainActor
final class WissensTeilenManager: ObservableObject {
static let shared = WissensTeilenManager()

@Published var teilenAktiv: Bool {
  didSet {
    UserDefaults.standard.set(teilenAktiv, forKey: "fenlynineos_wissen_teilen")
    PowerOSDatenbank.shared.protokolliere(
      aktion: teilenAktiv ? "Teilen aktiviert" : "Teilen deaktiviert",
      details: "Opt-in-Entscheidung der Nutzerin/des Nutzers"
    )
  }
}

@Published private(set) var beitraege: Int = 0
@Published private(set) var status: String = ""

private init() {
  teilenAktiv = UserDefaults.standard.bool(forKey: "fenlynineos_wissen_teilen") // Default: false
  let ordner = PowerOSDatenbank.shared.pfad.appendingPathComponent("Beitraege")
  beitraege = (try? FileManager.default.contentsOfDirectory(atPath: ordner.path))?
    .filter { !$0.hasPrefix(".") }.count ?? 0
}

/// Dokumente/Pakete mit Rechtsinfos hochladen -- nur bei aktivem Opt-in.
func beitragHochladen() {
  guard teilenAktiv else {
    status = "Teilen ist deaktiviert -- zuerst Opt-in aktivieren."
    return
  }
  let panel = NSOpenPanel()
  panel.title = "Rechtswissen beitragen (keine Mandantendaten)"
  panel.allowsMultipleSelection = true
  panel.canChooseDirectories = false
  panel.allowedContentTypes = [.plainText, .pdf, .json, .rtf]
  guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }

  let ziel = PowerOSDatenbank.shared.pfad.appendingPathComponent("Beitraege", isDirectory: true)
  try? FileManager.default.createDirectory(at: ziel, withIntermediateDirectories: true)
  var neueIds: [UUID] = []
  var kopiert = 0

  for url in panel.urls {
    let zielDatei = ziel.appendingPathComponent(url.lastPathComponent)
    try? FileManager.default.removeItem(at: zielDatei)
    guard (try? FileManager.default.copyItem(at: url, to: zielDatei)) != nil else { continue }
    kopiert += 1

    // Textinhalte zusätzlich als Wissen erfassen
    if let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
      let eintrag = RechtswissenEintrag(
        titel: url.deletingPathExtension().lastPathComponent,
        zusammenfassung: text.count > 400 ? String(text.prefix(400)) + " …" : text,
        norm: nil,
        rechtsgebiet: nil,
        quelle: "Beitrag · geteilt",
        tags: ["beitrag", "geteilt"],
        confidence: 0.7,
        rohtext: text.count > 4000 ? String(text.prefix(4000)) : text
      )
      RechtswissenStore.shared.fuegeHinzu(eintrag)
      neueIds.append(eintrag.id)
    }
  }

  PowerOSDatenbank.shared.synchronisiere()
  PowerOSDatenbank.shared.markiereGeteilt(ids: neueIds)
  PowerOSDatenbank.shared.protokolliere(
    aktion: "Beitrag hochgeladen",
    details: "\(kopiert) Datei(en) freiwillig geteilt"
  )
  beitraege += kopiert
  status = "\(kopiert) Datei(en) beigetragen -- danke!"
}

/// Exportiert ein Wissenspaket (JSON + Markdown) zum Weitergeben an Kollegen.
func wissenspaketExportieren() {
  let ziel = PowerOSDatenbank.shared.pfad.appendingPathComponent("Pakete", isDirectory: true)
  try? FileManager.default.createDirectory(at: ziel, withIntermediateDirectories: true)
  let stempel = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
  let eintraege = RechtswissenStore.shared.eintraege

  let enc = JSONEncoder()
 enc.outputFormatting = [.prettyPrinted, .sortedKeys]
 enc.dateEncodingStrategy = .iso8601
 try? enc.encode(eintraege).write(to: ziel.appendingPathComponent("Wissenspaket-\(stempel).json"))

 let md = """
 # FenlynineOS Wissenspaket
 Erstellt: \(stempel) · \(eintraege.count) Einträge · nur Rechtswissen, keine Mandantendaten

 \(eintraege.map(\.kontextBlock).joined(separator: "\n\n---\n\n"))
 """
 try? md.data(using: .utf8)?.write(to: ziel.appendingPathComponent("Wissenspaket-\(stempel).md"))

 PowerOSDatenbank.shared.protokolliere(aktion: "Wissenspaket exportiert", details: "\(eintraege.count) Einträge")
 NSWorkspace.shared.activateFileViewerSelecting([ziel])
 status = "Wissenspaket exportiert (\(eintraege.count) Einträge)."
}
}

