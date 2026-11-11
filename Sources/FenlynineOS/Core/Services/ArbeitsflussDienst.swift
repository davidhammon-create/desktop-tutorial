import Foundation
import Combine
import FenlynineOSKern

// MARK: - ArbeitsflussDienst
//
// Liest den Stand aller Akten und lässt den Kern daraus ableiten, was als
// Nächstes ansteht. Der Kern bekommt nur Zählwerte und Ja/Nein-Merkmale;
// die Aktennamen bleiben hier und dienen nur der Anzeige.

@MainActor
final class ArbeitsflussDienst: ObservableObject {
    static let shared = ArbeitsflussDienst()

    @Published private(set) var schritte: [Arbeitsschritt] = []
    /// Akten-id -> Anzeigename.
    @Published private(set) var aktennamen: [String: String] = [:]
    @Published private(set) var laedt = false
    @Published private(set) var aktualisiertAm: Date?

    func aktualisieren() async {
        guard !laedt else { return }
        laedt = true
        defer { laedt = false }

        let faelle = (try? await Services.cases.list()) ?? []
        let argumente = (try? await Services.arguments.list()) ?? []
        let beweise = (try? await Services.evidence.list()) ?? []
        let fristen = (try? await Services.deadlines.list()) ?? []
        let dokumente = (try? await Services.documents.list()) ?? []

        let argNachAkte = Dictionary(grouping: argumente, by: { $0.case_id })
        let bewNachAkte = Dictionary(grouping: beweise, by: { $0.case_id })
        let friNachAkte = Dictionary(grouping: fristen, by: { $0.case_id })
        let dokNachAkte = Dictionary(grouping: dokumente, by: { $0.case_id })

        let kal = Calendar.current
        let heute = kal.startOfDay(for: Date())
        var staende: [Aktenstand] = []
        var namen: [String: String] = [:]

        for f in faelle {
            guard let id = f.id, f.status != .ruhend else { continue }
            namen[id] = f.fallname
            let args = argNachAkte[id] ?? []
            let eigene = args.filter { $0.side == .eigen }
            let offen = (friNachAkte[id] ?? []).filter { $0.status == .offen }
            let tage = offen.map {
                kal.dateComponents([.day], from: heute, to: kal.startOfDay(for: $0.due_date)).day ?? 0
            }
            staende.append(Aktenstand(
                akteId: id,
                istAbgeschlossen: f.status == .abgeschlossen,
                hatRechtsfrage: !(f.zentrale_rechtsfrage ?? "").trimmingCharacters(in: .whitespaces).isEmpty,
                hatProzessziel: !(f.prozessziel ?? "").trimmingCharacters(in: .whitespaces).isEmpty,
                hatStreitwert: (f.streitwert ?? 0) > 0,
                hatPrognose: f.prognose != nil,
                hatVergleichsangebot: (f.vergleichsangebot ?? 0) > 0,
                hatErgebnis: !(f.urteil ?? "").trimmingCharacters(in: .whitespaces).isEmpty,
                eigeneArgumente: eigene.count,
                gegnerArgumente: args.count - eigene.count,
                eigeneArgumenteOhneBeweis: eigene.filter { ($0.linked_evidence_ids ?? []).isEmpty }.count,
                beweismittel: (bewNachAkte[id] ?? []).count,
                dokumente: (dokNachAkte[id] ?? []).count,
                offeneFristen: offen.count,
                ueberfaelligeFristen: tage.filter { $0 < 0 }.count,
                tageBisNaechsteFrist: tage.filter { $0 >= 0 }.min()))
        }

        schritte = Arbeitsfluss.uebersicht(staende, limit: 12, jeAkte: 2)
        aktennamen = namen
        aktualisiertAm = Date()
    }

    func aktenname(_ schritt: Arbeitsschritt) -> String {
        aktennamen[schritt.akteId] ?? "Akte"
    }
}
