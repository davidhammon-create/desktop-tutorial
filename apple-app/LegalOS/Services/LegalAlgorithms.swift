//
//  LegalAlgorithms.swift
//  Swift-Pendant zu lib/legalAlgorithms.js – berechnet Prognosen,
//  Gewichtungen und Vergleichsempfehlungen aus Fallparametern.
//

import Foundation

public enum LegalAlgorithms {

    // MARK: - Prognose

    /// Berechnet eine Roh-Prognose aus eigenen vs. gegnerischen Argumenten.
    /// 0 = aussichtslos, 100 = sicher.
    public static func prognose(arguments: [Argument]) -> Double {
        let eigene = arguments.filter { $0.side == .eigen }
        let gegner = arguments.filter { $0.side == .gegner }

        let eigenSum = eigene.reduce(0.0) { $0 + ($1.kiStrength ?? $1.strength ?? 5) }
        let gegnerSum = gegner.reduce(0.0) { $0 + ($1.kiStrength ?? $1.strength ?? 5) }
        let total = eigenSum + gegnerSum
        guard total > 0 else { return 50 }
        let raw = eigenSum / total * 100
        return min(95, max(5, raw))
    }

    /// Wendet Frist-Verstöße als Abzug auf die Prognose an.
    public static func prognoseMitFristen(base: Double, deadlines: [Deadline]) -> Double {
        let versaeumt = deadlines.filter { $0.status == .versaeumt && $0.side == .eigene }.count
        return max(5, base - Double(versaeumt) * 8)
    }

    // MARK: - Argument-Gewichtung

    public static func argumentScore(_ arg: Argument, evidence: [Evidence]) -> Double {
        let evidenceWeight = evidence
            .filter { $0.argumentId == arg.id }
            .map { $0.kiWeight ?? $0.weight ?? 5 }
            .reduce(0, +)
        let base = arg.kiStrength ?? arg.strength ?? 5
        let bonus = min(3, evidenceWeight / 10)
        let penalty = arg.isContradiction ? 2.0 : 0
        return max(0, min(10, base + bonus - penalty))
    }

    // MARK: - Vergleichsempfehlung

    /// Empfehlung Vergleich vs. Prozess auf Basis Streitwert, Kosten und Prognose.
    public struct VergleichEmpfehlung: Hashable {
        public let prozessErwartet: Double
        public let vergleichErwartet: Double
        public let empfehlung: String
    }

    public static func vergleichsEmpfehlung(streitwert: Double,
                                            gebuehren: Double,
                                            svKosten: Double,
                                            reisekosten: Double,
                                            prognosePct: Double,
                                            vergleichsangebot: Double?) -> VergleichEmpfehlung {
        let gewinnAnteil = prognosePct / 100
        let prozessErwartet =
            (streitwert * gewinnAnteil) - (gebuehren + svKosten + reisekosten) * (1 - gewinnAnteil)
        let vergleich = vergleichsangebot ?? (streitwert * 0.5)
        let empfehlung: String
        if vergleich > prozessErwartet * 1.05 {
            empfehlung = "Vergleich annehmen (höherer Erwartungswert)."
        } else if prozessErwartet > vergleich * 1.15 {
            empfehlung = "Prozess weiterführen (deutlich höherer Erwartungswert)."
        } else {
            empfehlung = "Erwartungswerte ähnlich – Risikoabwägung mit Mandant."
        }
        return .init(prozessErwartet: prozessErwartet,
                     vergleichErwartet: vergleich,
                     empfehlung: empfehlung)
    }

    // MARK: - Frist-Status

    public static func fristStatus(_ d: Deadline, today: Date = Date()) -> String {
        if d.status == .erledigt { return "Erledigt" }
        if d.status == .versaeumt { return "Versäumt" }
        let diff = Calendar.current.dateComponents([.day], from: today, to: d.dueDate).day ?? 0
        if diff < 0 { return "Überfällig" }
        if diff < 3 { return "Kritisch" }
        if diff < 14 { return "Demnächst" }
        return "Geplant"
    }
}
