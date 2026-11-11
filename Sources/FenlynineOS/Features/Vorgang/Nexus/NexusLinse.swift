import SwiftUI
extension Notification.Name {
    static let oeffneNexusLinse = Notification.Name("fenlynineos.oeffneNexusLinse")
}
enum NexusAnsichtsModus: String, CaseIterable, Identifiable {
    case liste, netz, schriftsatz
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .liste: return "Liste"
        case .netz: return "Netz"
        case .schriftsatz: return "Schriftsatz"
        }
    }
    var taste: String {
        switch self {
        case .liste: return "L"
        case .netz: return "N"
        case .schriftsatz: return "S"
        }
    }
}
enum NexusDichte: String, CaseIterable, Identifiable {
    case punkt, karte, voll
    var id: String { rawValue }
    var titel: String {
        switch self {
        case .punkt: return "Punkt"
        case .karte: return "Karte"
        case .voll: return "Voll"
        }
    }
}
struct NexusLinse: View {
    let vorgangId: UUID
    var body: some View {
        NexusBrett(vorgangId: vorgangId)
    }
}
