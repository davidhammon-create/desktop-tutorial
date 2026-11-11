import Foundation
public struct DeterministischerZufall: RandomNumberGenerator {
    private var zustand: UInt64
    public init(startwert: UInt64) {
        self.zustand = startwert == 0 ? 0x9E3779B97F4A7C15 : startwert
    }
    public init(seed: UInt64) {
        self.init(startwert: seed)
    }
    public static func seed(aus werten: [UInt64]) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for w in werten {
            h ^= w
            h &*= 0x100000001b3
        }
        return h == 0 ? 0xF9A711C0DE : h
    }
    public static func seed(ausDoubles werte: [Double], ints: [Int] = []) -> UInt64 {
        var bits: [UInt64] = werte.map { $0.bitPattern }
        bits.append(contentsOf: ints.map { UInt64(bitPattern: Int64($0)) })
        return seed(aus: bits)
    }
    public mutating func next() -> UInt64 {
        zustand = zustand &+ 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    public mutating func einheit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
    public mutating func normal() -> Double {
        let u = max(1e-12, einheit())
        let v = einheit()
        return sqrt(-2 * log(u)) * cos(2 * .pi * v)
    }
}
