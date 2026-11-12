import Foundation
@MainActor
final class RechtsdatenOrdner: ObservableObject {
    static let shared = RechtsdatenOrdner()
    @Published private(set) var wurzel: URL
    @Published private(set) var letzterImport: Date?
    @Published private(set) var importierteDateien: Int = 0
    @Published private(set) var status: String = "bereit"
    private var fingerprints: [String: String] = [:]   // pfad → fingerprint
    private let metaURL: URL
    private let erlaubteEndungen: Set<String> = ["txt", "md", "markdown", "json"]
    nonisolated static func portablerBasisOrdner() -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var kandidat = docs.appendingPathComponent("FenlynineOS-Rechtsdaten", isDirectory: true)
        try? fm.createDirectory(at: kandidat, withIntermediateDirectories: true)
        if !fm.fileExists(atPath: kandidat.path) {
            kandidat = fm.homeDirectoryForCurrentUser
                .appendingPathComponent("FenlynineOS-Rechtsdaten", isDirectory: true)
            try? fm.createDirectory(at: kandidat, withIntermediateDirectories: true)
        }
        return kandidat
    }
    private init() {
        wurzel = Self.portablerBasisOrdner()
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FenlynineOS", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        metaURL = support.appendingPathComponent("rechtsdaten_ordner_meta.json")
        fingerprints = (try? JSONDecoder().decode([String: String].self, from: Data(contentsOf: metaURL))) ?? [:]
        strukturAnlegen()
    }
    func strukturAnlegen() {
        let fm = FileManager.default
        var ordner = ["Eingang", "Radar-Funde"]
        ordner += Rechtsordnung.allCases.map(\.name)
        for name in ordner {
            try? fm.createDirectory(at: wurzel.appendingPathComponent(name, isDirectory: true),
                                    withIntermediateDirectories: true)
        }
        let readme = wurzel.appendingPathComponent("LIES-MICH.md")
        if !fm.fileExists(atPath: readme.path) {
            let text = """
            # FenlynineOS Rechtsdaten-Ordner
            Dieser Ordner verbindet FenlynineOS mit lokalen Rechtsdaten auf diesem Rechner.
            ## So funktioniert es
            - **Eingang/** — beliebige Rechtstexte hier ablegen (.txt, .md, .json).
              Der Rechtsradar importiert sie automatisch ins lokale Rechtswissen.
            - **Deutschland/ · Schweiz/ · Norwegen/ · Japan/ · China/** — Dateien in
              einem Länderordner werden der jeweiligen Rechtsordnung zugeordnet.
            - **Radar-Funde/** — hier spiegelt der KI-Radar seine Funde als Markdown,
              damit sie auch außerhalb der App nutzbar sind (z. B. Cloud-Sync).
            ## Datenschutz
            Es werden ausschließlich Rechtsdaten verarbeitet.
            Keine Mandanten- oder personenbezogenen Daten hier ablegen.
            """
            try? text.data(using: .utf8)?.write(to: readme)
        }
    }
    func importiere() {
        strukturAnlegen()
        status = "scannt Ordner …"
        let fm = FileManager.default
        var neu = 0
        var quellen: [(URL, Rechtsordnung?)] = [(wurzel.appendingPathComponent("Eingang"), nil)]
        for r in Rechtsordnung.allCases {
            quellen.append((wurzel.appendingPathComponent(r.name), r))
        }
        for (ordner, rechtsordnung) in quellen {
            guard let inhalt = try? fm.contentsOfDirectory(at: ordner, includingPropertiesForKeys:
                    [.contentModificationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else { continue }
            for datei in inhalt where erlaubteEndungen.contains(datei.pathExtension.lowercased()) {
                guard let werte = try? datei.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else { continue }
                let fp = "\(werte.fileSize ?? 0)-\(werte.contentModificationDate?.timeIntervalSince1970 ?? 0)"
                if fingerprints[datei.path] == fp { continue }   // unverändert → schon importiert
                guard let text = try? String(contentsOf: datei, encoding: .utf8), !text.isEmpty else { continue }
                let titel = datei.deletingPathExtension().lastPathComponent
                let kurz = text.count > 400 ? String(text.prefix(400)) + " …" : text
                RechtswissenStore.shared.fuegeHinzu(.init(
                    titel: titel,
                    zusammenfassung: kurz,
                    norm: erkanntNorm(in: text),
                    rechtsgebiet: nil,
                    quelle: "Ordner · \(rechtsordnung?.name ?? "Eingang")",
                    tags: ["ordner"] + (rechtsordnung.map { [$0.rawValue] } ?? []),
                    confidence: 0.75,
                    rohtext: text.count > 4000 ? String(text.prefix(4000)) : text,
                    rechtsordnung: rechtsordnung?.rawValue
                ))
                fingerprints[datei.path] = fp
                neu += 1
            }
        }
        if neu > 0 {
            importierteDateien += neu
            letzterImport = .init()
            metaSpeichern()
        }
        status = neu > 0 ? "\(neu) neue Datei(en) importiert" : "keine neuen Dateien"
    }
    private func erkanntNorm(in text: String) -> String? {
        let muster = [#"§+\s?\d+[a-z]?\s?(Abs\.\s?\d+\s?)?[A-ZÄÖÜ][A-Za-zÄÖÜäöü]+"#,
                      #"Art\.\s?\d+[a-z]?\s?[A-ZÄÖÜ][A-Za-zÄÖÜäöü\-]+"#,
                      #"[\u4E00-\u9FFF]+\d+条"#]
        for m in muster {
            if let bereich = text.range(of: m, options: .regularExpression) {
                return String(text[bereich])
            }
        }
        return nil
    }
    func exportiereRadarFunde() {
        let ziel = wurzel.appendingPathComponent("Radar-Funde", isDirectory: true)
        try? FileManager.default.createDirectory(at: ziel, withIntermediateDirectories: true)
        let alle = RechtswissenStore.shared.eintraege
        for r in Rechtsordnung.allCases {
            let eintraege = alle.filter { $0.rechtsordnung == r.rawValue }
            guard !eintraege.isEmpty else { continue }
            let md = """
            # Radar-Funde · \(r.flagge) \(r.name)
            Stand: \(ISO8601DateFormatter().string(from: Date())) · \(eintraege.count) Einträge
            \(eintraege.map(\.kontextBlock).joined(separator: "\n\n---\n\n"))
            """
            try? md.data(using: .utf8)?.write(to: ziel.appendingPathComponent("\(r.name).md"), options: .atomic)
        }
        let allgemein = alle.filter { $0.rechtsordnung == nil }
        if !allgemein.isEmpty {
            let md = """
            # Radar-Funde · Allgemein
            Stand: \(ISO8601DateFormatter().string(from: Date())) · \(allgemein.count) Einträge
            \(allgemein.map(\.kontextBlock).joined(separator: "\n\n---\n\n"))
            """
            try? md.data(using: .utf8)?.write(to: ziel.appendingPathComponent("Allgemein.md"), options: .atomic)
        }
    }
    private func metaSpeichern() {
        try? JSONEncoder().encode(fingerprints).write(to: metaURL, options: .atomic)
    }
}
