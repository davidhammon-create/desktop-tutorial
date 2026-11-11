import Foundation
import SwiftUI
enum Residenzregion: String, CaseIterable, Identifiable {
    case nurLokal = "nur_lokal"
    case deutschland, eu, schweiz, weltweit
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .nurLokal: return "Nur dieses Gerät (maximal)"
        case .deutschland: return "Nur Deutschland"
        case .eu: return "Nur EU/EWR"
        case .schweiz: return "Nur Schweiz"
        case .weltweit: return "Weltweit (unbeschränkt)"
        }
    }
    var symbol: String {
        switch self {
        case .nurLokal: return "lock.laptopcomputer"
        case .deutschland: return "shield.lefthalf.filled"
        case .eu: return "star.circle"
        case .schweiz: return "cross.circle"
        case .weltweit: return "globe"
        }
    }
    var beschreibung: String {
        switch self {
        case .nurLokal:
            return "Alle KI-Berechnungen laufen ausschließlich auf diesem Mac (Apple Intelligence / lokale Modelle). Kein Byte verlässt das Gerät — Cloud und Uploads sind gesperrt."
        case .deutschland:
            return "Cloud-KI nur nach AV-Ausnahme oder wenn nachweislich DE-Hosting. Standard: Umleitung auf on-device KI. Mandatsdaten bleiben lokal."
        case .eu:
            return "Cloud-KI nur innerhalb EU/EWR nach Freigabe. Sonst on-device. Mandatsdaten bleiben lokal."
        case .schweiz:
            return "Cloud-KI nur auf CH-Infrastruktur nach Freigabe. Sonst on-device."
        case .weltweit:
            return "Keine Regionsbeschränkung — Cloud-Egress freigegeben. Für Mandatsdaten nur mit bewusster Entscheidung."
        }
    }
    var erlaubtBase44Cloud: Bool {
        switch self {
        case .weltweit: return true
        case .nurLokal, .deutschland, .eu, .schweiz: return false
        }
    }
}
enum DatenResidenz {
    static let regionKey = "fenlynineos_residenz_region"
    static let ausnahmeKey = "fenlynineos_residenz_base44_ausnahme"
    private static let migrationKey = "fenlynineos_residenz_migration_v2_offline"
    static var region: Residenzregion {
        get {
            migriereDefaultsFallsNoetig()
            return Residenzregion(rawValue: UserDefaults.standard.string(forKey: regionKey) ?? "") ?? .nurLokal
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: regionKey) }
    }
    static var base44Ausnahme: Bool {
        get {
            migriereDefaultsFallsNoetig()
            return UserDefaults.standard.bool(forKey: ausnahmeKey) // default false
        }
        set { UserDefaults.standard.set(newValue, forKey: ausnahmeKey) }
    }
    static var darfCloud: Bool {
        let r = region
        if r == .nurLokal { return false }
        return r.erlaubtBase44Cloud || base44Ausnahme
    }
    private static func migriereDefaultsFallsNoetig() {
        let d = UserDefaults.standard
        guard !d.bool(forKey: migrationKey) else { return }
        if d.object(forKey: regionKey) == nil {
            d.set(Residenzregion.nurLokal.rawValue, forKey: regionKey)
        }
        d.set(false, forKey: ausnahmeKey)
        d.set(true, forKey: migrationKey)
    }
    static func effektiverModus(fuer modus: KIModus) -> (modus: KIModus, umleitung: String?) {
        switch modus {
        case .appleIntelligence, .offline:
            return (modus, nil)
        case .base44:
            if darfCloud {
                return (.base44, region.erlaubtBase44Cloud ? nil :
                    "Base44 als AV-Vertragspartner zugelassen (Ausnahme aktiv)")
            }
            if AppleIntelligenceService.status.ok {
                return (.appleIntelligence, "Residenz \(region.titel): Cloud blockiert → Apple Intelligence")
            }
            return (.offline, "Residenz \(region.titel): Cloud blockiert → lokales Modell")
        }
    }
    static var statusLabel: String {
        let r = region
        if r == .nurLokal { return "\(r.titel) · Cloud gesperrt" }
        if base44Ausnahme && !r.erlaubtBase44Cloud {
            return "\(r.titel) · Base44-AV-Ausnahme"
        }
        if !darfCloud { return "\(r.titel) · Cloud gesperrt" }
        return r.titel
    }
    static func protokolliere(angefragt: KIModus, entschieden: KIModus, umleitung: String?) {
        let r = region
        Task { @MainActor in
            PowerOSDatenbank.shared.protokolliereResidenz(
                angefragt: angefragt.rawValue,
                entschieden: entschieden.rawValue,
                region: r.rawValue,
                begruendung: umleitung ?? (darfCloud ? "regulär zulässig" : "Cloud gesperrt")
            )
        }
    }
}
@MainActor
final class DatenResidenzStore: ObservableObject {
    static let shared = DatenResidenzStore()
    @Published var region: Residenzregion {
        didSet { DatenResidenz.region = region }
    }
    @Published var base44Ausnahme: Bool {
        didSet {
            if region == .nurLokal {
                DatenResidenz.base44Ausnahme = false
                if base44Ausnahme { base44Ausnahme = false; return }
            }
            DatenResidenz.base44Ausnahme = base44Ausnahme
        }
    }
    private init() {
        region = DatenResidenz.region
        base44Ausnahme = DatenResidenz.base44Ausnahme
    }
}
