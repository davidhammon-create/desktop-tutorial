import Foundation
import FenlynineOSKern
struct AbschlussMonteCarloInputs {
    var algoPrognose: Double
    var kiPrognose: Double
    var kiAvail: Bool
    var complianceScore: Double
    var risikoScore: Double
    var argCount: Int
    var evidenceCount: Int
    var kiAccuracy: Double
}
struct AbschlussMonteCarloSzenario {
    var p5: Double
    var p50: Double
    var p95: Double
    var mean: Double
    var std: Double
    var hist: [AbschlussHistogramBin]
}
struct AbschlussHistogramBin: Identifiable {
    let id = UUID()
    var range: String
    var count: Int
}
struct AbschlussMonteCarloErgebnis {
    var correct: AbschlussMonteCarloSzenario
    var wrong: AbschlussMonteCarloSzenario
    var combinedMean: Int
    var combinedP5: Double
    var combinedP95: Double
    var combinedStd: Double
    var combinedHist: [AbschlussHistogramBin]
    var kiInfluence: Int
}
struct KITreffsicherheitErgebnis {
    var accuracy: Int
    var factors: [(label: String, delta: Int, formula: String)]
}
enum AbschlussMonteCarloEngine {
    static func runMonteCarlo(inputs: AbschlussMonteCarloInputs, n: Int = 3000) -> AbschlussMonteCarloErgebnis {
        let algoStd = 5.0
        let kiStdCorrect = 8.0
        let kiStdWrong = 18.0
        let complianceStd = 6.0
        let riskStd = 5.0
        let basisSeed = DeterministischerZufall.seed(
            ausDoubles: [
                inputs.algoPrognose, inputs.kiPrognose, inputs.complianceScore,
                inputs.risikoScore, inputs.kiAccuracy
            ],
            ints: [inputs.argCount, inputs.evidenceCount, inputs.kiAvail ? 1 : 0, n]
        )
        func simulate(kiStd: Double, salt: UInt64) -> AbschlussMonteCarloSzenario {
            var rng = DeterministischerZufall(seed: basisSeed &+ salt)
            var results: [Double] = []
            results.reserveCapacity(n)
            for _ in 0..<n {
                var score = inputs.algoPrognose + rng.normal() * algoStd
                if inputs.kiAvail {
                    let kiAdj = (inputs.kiPrognose - inputs.algoPrognose) * 0.4 + rng.normal() * kiStd
                    score += kiAdj
                }
                score += (inputs.complianceScore * 10) + rng.normal() * complianceStd
                score -= (inputs.risikoScore * 8) + rng.normal() * riskStd
                score += Double(min(inputs.argCount, 10)) * 0.3 + Double(min(inputs.evidenceCount, 10)) * 0.2
                results.append(min(99, max(1, score)))
            }
            results.sort()
            let mean = results.reduce(0, +) / Double(n)
            let variance = results.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(n)
            let std = sqrt(variance)
            var hist = (0..<20).map { i in AbschlussHistogramBin(range: "\(i * 5)-\(i * 5 + 5)", count: 0) }
            for v in results {
                let b = min(19, Int(v / 5))
                hist[b].count += 1
            }
            return AbschlussMonteCarloSzenario(
                p5: results[Int(Double(n) * 0.05)],
                p50: results[Int(Double(n) * 0.50)],
                p95: results[Int(Double(n) * 0.95)],
                mean: (mean * 10).rounded() / 10,
                std: (std * 10).rounded() / 10,
                hist: hist
            )
        }
        let correct = simulate(kiStd: kiStdCorrect, salt: 0xC0_FF_EE)
        let wrong = simulate(kiStd: kiStdWrong, salt: 0xBAD_C0_DE)
        let w = inputs.kiAvail ? inputs.kiAccuracy / 100 : 0
        let combinedMean = Int((w * correct.mean + (1 - w) * wrong.mean).rounded())
        let combinedP5 = w * correct.p5 + (1 - w) * wrong.p5
        let combinedP95 = w * correct.p95 + (1 - w) * wrong.p95
        let combinedStd = sqrt(w * correct.std * correct.std + (1 - w) * wrong.std * wrong.std)
        let combinedHist = zip(correct.hist, wrong.hist).map { c, wr in
            AbschlussHistogramBin(range: c.range, count: Int((w * Double(c.count) + (1 - w) * Double(wr.count)).rounded()))
        }
        let kiInfluence = inputs.kiAvail
            ? Int((kiStdCorrect * kiStdCorrect) / (algoStd * algoStd + kiStdCorrect * kiStdCorrect + complianceStd * complianceStd / 2) * 100)
            : 0
        return AbschlussMonteCarloErgebnis(
            correct: correct,
            wrong: wrong,
            combinedMean: combinedMean,
            combinedP5: combinedP5,
            combinedP95: combinedP95,
            combinedStd: (combinedStd * 10).rounded() / 10,
            combinedHist: combinedHist,
            kiInfluence: kiInfluence
        )
    }
    static func estimateKiAccuracy(
        args: [Argument],
        evs: [Evidence],
        warnings: [CaseWarning],
        behaviors: [GegnerVerhalten],
        kiResult: AnyCodable?
    ) -> KITreffsicherheitErgebnis {
        guard kiResult != nil else { return KITreffsicherheitErgebnis(accuracy: 0, factors: []) }
        var score = 0.0
        var factors: [(label: String, delta: Int, formula: String)] = []
        let argScore = min(Double(args.count) / 8, 1)
        let argDelta = Int((argScore * 35).rounded())
        score += Double(argDelta)
        factors.append((label: "Argumentabdeckung", delta: argDelta, formula: "min(Argumente/8, 1) × 35 = +\(argDelta)"))
        let evScore = min(Double(evs.count) / 6, 1)
        let evDelta = Int((evScore * 30).rounded())
        score += Double(evDelta)
        factors.append((label: "Beweisabdeckung", delta: evDelta, formula: "min(Beweise/6, 1) × 30 = +\(evDelta)"))
        let critWarn = warnings.filter { $0.severity == .kritisch }.count
        let warnPenalty = -critWarn * 8
        score += Double(warnPenalty)
        factors.append((label: "Offene krit. Warnungen", delta: warnPenalty, formula: "Kritische × (−8) = \(warnPenalty)"))
        let behaviorBonus = min(behaviors.count * 5, 20)
        score += Double(behaviorBonus)
        factors.append((label: "Verhaltensdaten", delta: behaviorBonus, formula: "min(Einträge × 5, 20) = +\(behaviorBonus)"))
        let linked = args.filter { !($0.linked_evidence_ids ?? []).isEmpty }.count
        let linkDelta = args.isEmpty ? 0 : Int((Double(linked) / Double(args.count) * 15).rounded())
        score += Double(linkDelta)
        factors.append((label: "Argument–Beweis-Verknüpfung", delta: linkDelta, formula: "Anteil verknüpfter Argumente × 15 = +\(linkDelta)"))
        return KITreffsicherheitErgebnis(
            accuracy: min(92, max(5, Int(score.rounded()))),
            factors: factors
        )
    }
    static func feedbackAdjustedAccuracy(baseAccuracy: Int, feedbackLogs: [KIUsageLog]) -> Int {
        let kiKeys = ["ki_strategie", "ki_prognose", "ki_risiko", "ki_gegner", "ki_dokumente"]
        let ratings = feedbackLogs.compactMap { log -> Int? in
            guard let ctx = log.context, kiKeys.contains(ctx), let r = log.rating else { return nil }
            return r
        }
        guard !ratings.isEmpty else { return baseAccuracy }
        let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
        let multiplier = 0.6 + (avg - 1) / 9 * 0.6
        return min(92, max(20, Int((Double(baseAccuracy) * multiplier).rounded())))
    }
}
