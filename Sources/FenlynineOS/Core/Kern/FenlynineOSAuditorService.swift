import Foundation
enum FenlynineOSAuditorSchwere: String, Codable {
    case kritisch, pruefen, ok
    var bezeichnung: String {
        switch self {
        case .kritisch: return "kritisch"
        case .pruefen: return "prüfen"
        case .ok: return "ok"
        }
    }
}
struct FenlynineOSAuditorFund: Identifiable, Hashable {
    let id = UUID()
    let schwere: FenlynineOSAuditorSchwere
    let pruefung: String
    let fundort: String
    let begruendung: String
    let knotenId: String?
}
enum FenlynineOSAuditorService {
    static func pruefen(store: FenlynineOSKernStore) -> [FenlynineOSAuditorFund] {
        var funde: [FenlynineOSAuditorFund] = []
        for k in store.knoten where k.typ == .option && k.pErfolg == nil {
            funde.append(.init(schwere: .pruefen, pruefung: "Vollständigkeit",
                fundort: "\(k.modul.bezeichnung) · \(k.titel)",
                begruendung: "Option ohne P(Erfolg) — nicht berechenbar",
                knotenId: k.id))
        }
        let ids = Set(store.knoten.map(\.id))
        for kante in store.kanten {
            if !ids.contains(kante.vonId) || !ids.contains(kante.zuId) {
                funde.append(.init(schwere: .kritisch, pruefung: "Graph-Integrität",
                    fundort: "Kante \(kante.id)",
                    begruendung: "Verwaiste Kante: \(kante.vonId) → \(kante.zuId)",
                    knotenId: nil))
            }
        }
        let kritischeRisiken = store.knoten.filter { ($0.rpn ?? 0) > 100 }.count
        for k in store.knoten where k.typ == .option && (k.pErfolg ?? 0) > 0.9 && kritischeRisiken >= 2 {
            funde.append(.init(schwere: .pruefen, pruefung: "Plausibilität",
                fundort: "\(k.titel)",
                begruendung: "P(Erfolg)=\(Int((k.pErfolg ?? 0)*100))% trotz \(kritischeRisiken) kritischer Risiken (RPN>100)",
                knotenId: k.id))
        }
        for opt in store.knoten where opt.typ == .option {
            let args = store.kanten.filter { $0.zuId == opt.id && ($0.typ == .begruendet || $0.typ == .widerlegt) }
            if args.isEmpty && opt.tiefe > 1 {
                funde.append(.init(schwere: .pruefen, pruefung: "Vollständigkeit",
                    fundort: opt.titel,
                    begruendung: "Option ohne verknüpfte Argumente",
                    knotenId: opt.id))
            }
        }
        for k in store.knoten where k.typ == .frist && k.fristKritisch == true && (k.tageRestlauf ?? 99) <= 0 {
            funde.append(.init(schwere: .kritisch, pruefung: "Frist",
                fundort: k.titel,
                begruendung: "Kritische Frist — Restlauf 0",
                knotenId: k.id))
        }
        if funde.isEmpty {
            funde.append(.init(schwere: .ok, pruefung: "Gesamt",
                fundort: "Alle Module",
                begruendung: "Keine Auffälligkeiten im deterministischen Prüflauf",
                knotenId: nil))
        }
        return funde
    }
    static func pruefberichtText(store: FenlynineOSKernStore, funde: [FenlynineOSAuditorFund]) -> String {
        var lines = [
            "FENLYNINEOS AUDITOR — PRÜFBERICHT",
            "Datum: \(ISO8601DateFormatter().string(from: Date()))",
            "Basis: \(store.basisSituation)",
            "Ziel: \(store.ziel)",
            "Knoten: \(store.knoten.count) | Kanten: \(store.kanten.count)",
            ""
        ]
        for f in funde {
            lines.append("[\(f.schwere.bezeichnung.uppercased())] \(f.pruefung)")
            lines.append("  Ort: \(f.fundort)")
            lines.append("  \(f.begruendung)")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
