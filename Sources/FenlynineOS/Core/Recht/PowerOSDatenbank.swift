import Foundation
import SQLite3
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
@MainActor
final class PowerOSDatenbank: ObservableObject {
    static let shared = PowerOSDatenbank()
    @Published private(set) var pfad: URL
    @Published private(set) var anzahlEintraege: Int = 0
    @Published private(set) var anzahlLog: Int = 0
    @Published private(set) var letzterSync: Date?
    @Published private(set) var status: String = "bereit"
    private var db: OpaquePointer?
    private init() {
        pfad = Self.ermittlePfad()
        oeffnen()
        readmeAnlegen()
        zaehleNeu()
    }
    private static func ermittlePfad() -> URL {
        let fm = FileManager.default
        if let eigen = UserDefaults.standard.string(forKey: "poweros_pfad"), !eigen.isEmpty {
            let url = URL(fileURLWithPath: eigen, isDirectory: true)
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
            if fm.fileExists(atPath: url.path) { return url }
        }
        let bundleEltern = Bundle.main.bundleURL.deletingLastPathComponent()
        let projektWurzel = bundleEltern.deletingLastPathComponent()
        if fm.fileExists(atPath: projektWurzel.appendingPathComponent("FenlynineOS-App").path) {
            let ziel = projektWurzel.appendingPathComponent("PowerOS", isDirectory: true)
            try? fm.createDirectory(at: ziel, withIntermediateDirectories: true)
            if fm.fileExists(atPath: ziel.path) { return ziel }
        }
        let fallback = RechtsdatenOrdner.portablerBasisOrdner()
            .appendingPathComponent("PowerOS", isDirectory: true)
        try? fm.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }
    private func oeffnen() {
        let dbURL = pfad.appendingPathComponent("poweros-rechtsdatenbank.sqlite")
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            status = "Datenbank konnte nicht geöffnet werden"
            db = nil
            return
        }
        exec("""
        CREATE TABLE IF NOT EXISTS wissen (
            id TEXT PRIMARY KEY,
            titel TEXT NOT NULL,
            zusammenfassung TEXT,
            norm TEXT,
            rechtsgebiet TEXT,
            quelle TEXT,
            tags TEXT,
            confidence REAL,
            rechtsordnung TEXT,
            erfasst TEXT,
            aktualisiert TEXT,
            geteilt INTEGER DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS sammlung_log (
            lfd INTEGER PRIMARY KEY AUTOINCREMENT,
            zeit TEXT,
            aktion TEXT,
            details TEXT
        );
        CREATE TABLE IF NOT EXISTS residenz_log (
            lfd INTEGER PRIMARY KEY AUTOINCREMENT,
            zeit TEXT,
            angefragt TEXT,
            entschieden TEXT,
            region TEXT,
            begruendung TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_wissen_ro ON wissen(rechtsordnung);
        CREATE INDEX IF NOT EXISTS idx_wissen_norm ON wissen(norm);
        """)
    }
    private func exec(_ sql: String) {
        guard let db else { return }
        sqlite3_exec(db, sql, nil, nil, nil)
    }
    private func zaehleNeu() {
        anzahlEintraege = zaehle("SELECT COUNT(*) FROM wissen")
        anzahlLog = zaehle("SELECT COUNT(*) FROM sammlung_log")
    }
    private func zaehle(_ sql: String) -> Int {
        guard let db else { return 0 }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK,
              sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int64(stmt, 0))
    }
    func synchronisiere() {
        guard let db else { return }
        let iso = ISO8601DateFormatter()
        let eintraege = RechtswissenStore.shared.eintraege
        exec("BEGIN TRANSACTION")
        var stmt: OpaquePointer?
        let sql = """
        INSERT INTO wissen (id, titel, zusammenfassung, norm, rechtsgebiet, quelle, tags,
                            confidence, rechtsordnung, erfasst, aktualisiert)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
        ON CONFLICT(id) DO UPDATE SET
            titel=excluded.titel, zusammenfassung=excluded.zusammenfassung,
            norm=excluded.norm, rechtsgebiet=excluded.rechtsgebiet, quelle=excluded.quelle,
            tags=excluded.tags, confidence=excluded.confidence,
            rechtsordnung=excluded.rechtsordnung, aktualisiert=excluded.aktualisiert
        """
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            for e in eintraege {
                sqlite3_bind_text(stmt, 1, e.id.uuidString, -1, sqliteTransient)
                sqlite3_bind_text(stmt, 2, e.titel, -1, sqliteTransient)
                sqlite3_bind_text(stmt, 3, e.zusammenfassung, -1, sqliteTransient)
                sqlite3_bind_text(stmt, 4, e.norm ?? "", -1, sqliteTransient)
                sqlite3_bind_text(stmt, 5, e.rechtsgebiet ?? "", -1, sqliteTransient)
                sqlite3_bind_text(stmt, 6, e.quelle, -1, sqliteTransient)
                sqlite3_bind_text(stmt, 7, e.tags.joined(separator: ","), -1, sqliteTransient)
                sqlite3_bind_double(stmt, 8, e.confidence)
                sqlite3_bind_text(stmt, 9, e.rechtsordnung ?? "", -1, sqliteTransient)
                sqlite3_bind_text(stmt, 10, iso.string(from: e.erfasstAm), -1, sqliteTransient)
                sqlite3_bind_text(stmt, 11, iso.string(from: e.aktualisiertAm), -1, sqliteTransient)
                sqlite3_step(stmt)
                sqlite3_reset(stmt)
            }
        }
        sqlite3_finalize(stmt)
        exec("COMMIT")
        letzterSync = .init()
        zaehleNeu()
        status = "synchron · \(anzahlEintraege) Einträge"
        spiegelSchreiben()
    }
    func protokolliere(aktion: String, details: String) {
        guard let db else { return }
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "INSERT INTO sammlung_log (zeit, aktion, details) VALUES (?,?,?)", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, ISO8601DateFormatter().string(from: Date()), -1, sqliteTransient)
            sqlite3_bind_text(stmt, 2, aktion, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 3, details, -1, sqliteTransient)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        anzahlLog += 1
    }
    func protokolliereResidenz(angefragt: String, entschieden: String, region: String, begruendung: String) {
        guard let db else { return }
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "INSERT INTO residenz_log (zeit, angefragt, entschieden, region, begruendung) VALUES (?,?,?,?,?)", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, ISO8601DateFormatter().string(from: Date()), -1, sqliteTransient)
            sqlite3_bind_text(stmt, 2, angefragt, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 3, entschieden, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 4, region, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 5, begruendung, -1, sqliteTransient)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
    func markiereGeteilt(ids: [UUID]) {
        guard let db, !ids.isEmpty else { return }
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "UPDATE wissen SET geteilt = 1 WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            for id in ids {
                sqlite3_bind_text(stmt, 1, id.uuidString, -1, sqliteTransient)
                sqlite3_step(stmt)
                sqlite3_reset(stmt)
            }
        }
        sqlite3_finalize(stmt)
    }
    private func spiegelSchreiben() {
        let eintraege = RechtswissenStore.shared.eintraege
        let md = """
        # PowerOS Rechtsdatenbank — lesbarer Spiegel
        Stand: \(ISO8601DateFormatter().string(from: Date())) · \(eintraege.count) Einträge
        Quelle der Wahrheit: poweros-rechtsdatenbank.sqlite
        \(eintraege.map(\.kontextBlock).joined(separator: "\n\n---\n\n"))
        """
        try? md.data(using: .utf8)?.write(to: pfad.appendingPathComponent("Rechtsdatenbank.md"), options: .atomic)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        try? enc.encode(eintraege).write(to: pfad.appendingPathComponent("Rechtsdatenbank.json"), options: .atomic)
    }
    private func readmeAnlegen() {
        let readme = pfad.appendingPathComponent("LIES-MICH.md")
        guard !FileManager.default.fileExists(atPath: readme.path) else { return }
        let text = """
        # PowerOS — FenlynineOS Rechtsdatenbank
        Hier entsteht fortlaufend die zentrale Rechtsdatenbank von FenlynineOS:
        - **poweros-rechtsdatenbank.sqlite** — SQLite-Datenbank (Quelle der Wahrheit).
          Tabellen: wissen · sammlung_log · residenz_log
        - **Rechtsdatenbank.md / .json** — lesbarer Spiegel für Menschen und Tools.
        - **Beitraege/** — von Anwälten freiwillig geteilte Dokumente (Opt-in).
        - **Pakete/** — exportierte Wissenspakete zum Weitergeben.
        Die KIs (Rechtsradar, Lexara, Strategos, Opportunisma) sammeln ständig
        Rechtsinformationen über alle aktiven Rechtsordnungen und speichern sie hier.
        Es werden ausschließlich Rechtsdaten verarbeitet — keine Mandantendaten.
        """
        try? text.data(using: .utf8)?.write(to: readme)
        try? FileManager.default.createDirectory(at: pfad.appendingPathComponent("Beitraege"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: pfad.appendingPathComponent("Pakete"), withIntermediateDirectories: true)
    }
}
