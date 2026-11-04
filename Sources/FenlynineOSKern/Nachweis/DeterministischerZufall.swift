import Foundation

/// SplitMix64 -- kompakt, schnell, vollständig deterministisch.
/// Gleicher Startwert bedeutet immer gleiche Zahlenfolge, auf jedem Gerät und in
/// jeder Swift-Version. Der System-Generator wäre dagegen nicht wiederholbar, und
/// was sich nicht wiederherstellen lässt, ist kein Beleg.
public struct DeterministischerZufall: RandomNumberGenerator {
    private var zustand: UInt64

    public init(startwert: UInt64) {
        self.zustand = startwert
    }

    public mutating func next() -> UInt64 {
        zustand = zustand &+ 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
