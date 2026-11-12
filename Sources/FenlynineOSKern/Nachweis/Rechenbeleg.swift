import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Jedes Rechenergebnis führt mit, wie es entstanden ist.
public struct Rechenbeleg<Ergebnis: Codable>: Codable {
    public var ergebnis: Ergebnis
    /// SHA256 über die kanonisch serialisierten Eingaben.
    public var eingabenHash: String
    /// Damit ist der Zufall wiederholbar.
    public var startwert: UInt64
    /// z. B. "2026.1" -- Formeln können sich ändern.
    public var kernVersion: String
    public var berechnetAm: Date
    public var berechnetVon: String

    public init(ergebnis: Ergebnis,
                eingabenHash: String,
                startwert: UInt64,
                kernVersion: String = Rechenkern.version,
                berechnetAm: Date = Date(),
                berechnetVon: String) {
        self.ergebnis = ergebnis
        self.eingabenHash = eingabenHash
        self.startwert = startwert
        self.kernVersion = kernVersion
        self.berechnetAm = berechnetAm
        self.berechnetVon = berechnetVon
    }

    /// Prüft, ob der Beleg zu den heutigen Eingaben passt. Weicht der Hash ab, wurde
    /// am Fall etwas geändert und die Zahl ist veraltet -- die Oberfläche muss das
    /// anzeigen, statt eine alte Zahl weiter als gültig auszugeben.
    public func giltNochFuer(eingabenHash aktuell: String) -> Bool {
        eingabenHash == aktuell
    }
}

public enum Rechenkern {
    public static let version = "2026.1"

    /// Startwert aus den Eingaben ableiten: gleiche Eingabe, gleiches Ergebnis --
    /// aber verschiedene Fälle bekommen verschiedene Zufallsfolgen. (FNV-1a, 64 Bit)
    public static func startwert(fuer hash: String) -> UInt64 {
        var wert: UInt64 = 0xCBF2_9CE4_8422_2325        // FNV-1a Offset
        for byte in hash.utf8 {
            wert = (wert ^ UInt64(byte)) &* 0x100_0000_01B3
        }
        return wert
    }

    /// Kanonische Serialisierung (sortierte Schlüssel, ISO-8601-Daten), damit
    /// gleiche Eingaben auf jedem Gerät denselben Hash ergeben.
    public static func hash<T: Encodable>(_ eingaben: T) throws -> String {
        let kodierer = JSONEncoder()
        kodierer.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        kodierer.dateEncodingStrategy = .iso8601
        let daten = try kodierer.encode(eingaben)
        #if canImport(CryptoKit)
        return SHA256.hash(data: daten).map { String(format: "%02x", $0) }.joined()
        #else
        // Fallback ohne CryptoKit (z. B. Linux-CI): KEIN SHA256, nur FNV-1a 64 Bit.
        // Taugt zur Änderungserkennung, nicht als kryptografischer Nachweis. Das
        // Präfix verhindert, dass beide Verfahren versehentlich verglichen werden.
        // Für produktiven Einsatz dort swift-crypto (import Crypto) einbinden.
        var wert: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in daten {
            wert = (wert ^ UInt64(byte)) &* 0x100_0000_01B3
        }
        return "fnv1a64:" + String(format: "%016llx", wert)
        #endif
    }
}
