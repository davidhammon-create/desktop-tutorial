import SwiftUI
import UniformTypeIdentifiers
struct OrganonLinse: View {
    let vorgangId: UUID
    @Bindable var store: VorgangStore = .shared
    @State private var ebene: OrganonEbene = .firma
    @State private var importOffen = false
    enum OrganonEbene: String, CaseIterable, Identifiable {
        case firma = "Firmenebene"
        case abteilung = "Abteilungsebene"
        case person = "Personenebene"
        var id: String { rawValue }
    }
    private var vorgang: Vorgang? { store.vorgang(vorgangId) }
    var body: some View {
        if let v = vorgang {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Organon hat keinen Zugriff auf den NEXUS-Argumentgraphen. Personenbezogene Netzwerke und die Fallrechnung bleiben getrennt.")
                        .font(.system(size: 11))
                        .foregroundStyle(InterfacePalette.sekundaer)
                    ebenenWaehler
                    if ebene == .person {
                        gesperrtBlock
                    } else {
                        beteiligungsBlock(v)
                    }
                }
                .padding(16)
            }
            .fileImporter(isPresented: $importOffen, allowedContentTypes: [.pdf, .plainText], allowsMultipleSelection: false) { ergebnis in
                if case .success(let urls) = ergebnis, let url = urls.first {
                    store.hinterlegeBetriebsvereinbarung(vorgangId, titel: url.lastPathComponent)
                }
            }
        } else {
            Text("Vorgang nicht gefunden").foregroundStyle(Premium.text)
        }
    }
    private var ebenenWaehler: some View {
        HStack(spacing: 8) {
            ForEach(OrganonEbene.allCases) { e in
                Button {
                    ebene = e
                } label: {
                    Text(e.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .foregroundStyle(ebene == e ? .white : InterfacePalette.sekundaer)
                        .background(RoundedRectangle(cornerRadius: 8).fill(ebene == e ? InterfacePalette.aktion.opacity(0.24) : InterfacePalette.Material.l2))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ebene == e ? InterfacePalette.aktion : InterfacePalette.trennlinie, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
    private func beteiligungsBlock(_ v: Vorgang) -> some View {
        InterfaceKarte(ebene: 2) {
            VStack(alignment: .leading, spacing: 10) {
                Text("BETEILIGUNGSSTRUKTUR — UNBEDENKLICH")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.4)
                    .foregroundStyle(InterfacePalette.berechnet)
                if let partei = v.parteien.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(partei.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Premium.text)
                        Text("│").foregroundStyle(InterfacePalette.sekundaer)
                        HStack(spacing: 12) {
                            konzernKnoten(name: "\(partei.name) DE", anteil: 100)
                            konzernKnoten(name: "\(partei.name) NL", anteil: 94)
                            konzernKnoten(name: "\(partei.name) IE", anteil: 100)
                        }
                    }
                }
                Divider().overlay(InterfacePalette.trennlinie)
                Text("\(v.parteien.first?.name ?? "Alpha") IE berührt Vorgang \(v.titel). → § 42 AO relevant.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Quelle: Handelsregister · kein Personenbezug · keine Mitbestimmung")
                    .font(.system(size: 10))
                    .foregroundStyle(InterfacePalette.sekundaer)
            }
            .padding(14)
        }
    }
    private func konzernKnoten(name: String, anteil: Int) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.system(size: 11, weight: .semibold)).foregroundStyle(Premium.text)
            Text("\(anteil) %").font(.system(size: 10, design: .monospaced)).foregroundStyle(InterfacePalette.sekundaer)
        }
        .padding(8)
        .frame(minWidth: 110)
        .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.Material.l3))
    }
    private var gesperrtBlock: some View {
        InterfaceKarte(ebene: 2) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").foregroundStyle(InterfacePalette.kritisch)
                    Text("PERSONENEBENE — GESPERRT")
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(InterfacePalette.kritisch)
                }
                Text("§ 87 Abs. 1 Nr. 6 BetrVG")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Premium.text)
                Text("Individuelle Leistungsdaten sichtbar für Vorgesetzte = technische Überwachungseinrichtung — unabhängig von der Absicht.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
                Text("Freischaltung nur nach dokumentierter Betriebsvereinbarung.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Premium.text)
                Button {
                    importOffen = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.badge.plus")
                        Text(store.vorgang(vorgangId)?.betriebsvereinbarungTitel == nil
                             ? "Betriebsvereinbarung hinterlegen"
                             : "Weitere BV hinterlegen")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(InterfacePalette.aktion.opacity(0.18)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterfacePalette.aktion.opacity(0.5), lineWidth: 1))
                    .foregroundStyle(InterfacePalette.aktion)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                if let t = store.vorgang(vorgangId)?.betriebsvereinbarungTitel {
                    Text("Hinterlegt: \(t). Die Personenebene bleibt gesperrt — § 87 Abs. 1 Nr. 6 BetrVG ist keine Checkbox.")
                        .font(.system(size: 11))
                        .foregroundStyle(InterfacePalette.sekundaer)
                }
            }
            .padding(14)
        }
    }
}
