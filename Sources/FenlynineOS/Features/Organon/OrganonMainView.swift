import SwiftUI
enum OrganonHauptReiter: String, CaseIterable, Identifiable {
    case hierarchie, karte, suche, profil, skills, kapazitaet, verknuepfung, bearbeiten, audit, compliance
    var id: String { rawValue }
    var bezeichnung: String {
        switch self {
        case .hierarchie: return "Hierarchie"
        case .karte: return "Karte"
        case .suche: return "Suche"
        case .profil: return "Personen"
        case .skills: return "Skills"
        case .kapazitaet: return "Kapazität"
        case .verknuepfung: return "Links"
        case .bearbeiten: return "Bearbeiten"
        case .audit: return "Audit"
        case .compliance: return "Transparenz"
        }
    }
    var symbol: String {
        switch self {
        case .hierarchie: return "arrow.triangle.branch"
        case .karte: return "map"
        case .suche: return "magnifyingglass"
        case .profil: return "person.text.rectangle"
        case .skills: return "square.grid.3x3"
        case .kapazitaet: return "gauge.with.dots.needle.33percent"
        case .verknuepfung: return "link"
        case .bearbeiten: return "pencil"
        case .audit: return "list.clipboard"
        case .compliance: return "checkmark.shield"
        }
    }
}
struct OrganonView: View {
    @State private var vm = OrganonViewModel()
    @State private var reiter: OrganonHauptReiter = .hierarchie
    @Bindable private var appearance = AppearanceStore.shared
    var body: some View {
        VStack(spacing: 0) {
            OrganonKopfzeile(vm: vm)
            if !vm.statusMeldung.isEmpty {
                Text(vm.statusMeldung)
                    .font(.system(size: 11))
                    .foregroundStyle(InterfacePalette.berechnet)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(InterfacePalette.berechnet.opacity(0.10))
            }
            Divider().overlay(Premium.hairline)
            OrganonReiterLeiste(auswahl: $reiter)
            Divider().overlay(Premium.hairline)
            Group {
                switch reiter {
                case .hierarchie:
                    OrganonHierarchieView(vm: vm, onZurKarte: { reiter = .karte })
                case .karte:
                    OrganonCanvasView(vm: vm, onPersonDetail: { reiter = .bearbeiten })
                case .suche:
                    OrganonSearchView(vm: vm, onTreffer: { reiter = .karte })
                case .profil:
                    OrganonProfilListeView(vm: vm)
                case .skills:
                    OrganonSkillsMatrixView(vm: vm)
                case .kapazitaet:
                    OrganonKapazitaetView(vm: vm)
                case .verknuepfung:
                    OrganonVerknuepfungenView(vm: vm)
                case .bearbeiten:
                    OrganonEditorView(vm: vm)
                case .audit:
                    OrganonAuditView(vm: vm)
                case .compliance:
                    OrganonComplianceView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Premium.void)
        .fontDesign(.default)
        .preferredColorScheme(appearance.modus.preferredScheme)
        .onAppear {
            OrganonStore.shared.repariereHierarchie(still: true)
        }
    }
}
struct OrganonKopfzeile: View {
    @Bindable var vm: OrganonViewModel
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("ORGANON")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.4)
                    .foregroundStyle(Premium.textSoft)
                Text("Organisation — Abteilungen & Personen")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Premium.text)
                Text("Hierarchie: Gesellschaft → Abteilung → Team → Person")
                    .font(.system(size: 11))
                    .foregroundStyle(Premium.textSoft)
            }
            Spacer()
            organonZahl("Abteilungen", "\(vm.abteilungen.count)", OrganonKnotenTyp.bereich.farbe)
            organonZahl("Teams", "\(vm.teams.count)", OrganonKnotenTyp.team.farbe)
            organonZahl("Personen", "\(vm.personen.filter { !$0.istVakanz }.count)", InterfacePalette.berechnet)
            organonZahl("Vakanzen", "\(vm.vakanzen.count)", InterfacePalette.kritisch)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Premium.ink)
    }
    private func organonZahl(_ titel: String, _ wert: String, _ farbe: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(titel)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(InterfacePalette.sekundaer)
            Text(wert)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(farbe)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Premium.panel))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Premium.hairline, lineWidth: 1))
    }
}
struct OrganonReiterLeiste: View {
    @Binding var auswahl: OrganonHauptReiter
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(OrganonHauptReiter.allCases) { r in
                    Button {
                        auswahl = r
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: r.symbol)
                                    .font(.system(size: 11))
                                Text(r.bezeichnung)
                                    .font(.system(size: 12, weight: auswahl == r ? .semibold : .regular))
                            }
                            .foregroundStyle(auswahl == r ? Premium.text : InterfacePalette.sekundaer)
                            Rectangle()
                                .fill(auswahl == r ? Premium.text : Color.clear)
                                .frame(height: 1.5)
                        }
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .background(Premium.ink)
    }
}
struct OrganonComplianceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rechtskonformes Design")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Premium.text)
                Text("Organon trennt Strukturebene (Karte, Profile, Skills, Verknüpfungen) strikt von Leistungsüberwachung. Aggregation ist Standard — personenscharfe Auswertungen nur mit dokumentierter Betriebsvereinbarung. Das Audit-Protokoll dokumentiert Strukturänderungen, keine Produktivität.")
                    .font(.system(size: 12))
                    .foregroundStyle(InterfacePalette.sekundaer)
                ForEach(prinzipien, id: \.titel) { p in
                    InterfaceKarte(ebene: 2) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(p.titel, systemImage: p.symbol)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Premium.text)
                            Text(p.text)
                                .font(.system(size: 12))
                                .foregroundStyle(InterfacePalette.sekundaer)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                InterfaceKarte(ebene: 2) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Was sieht wer über mich?", systemImage: "eye.slash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Premium.text)
                        Text("Jede Person kann einsehen, welche Profildaten gespeichert sind und welche Rollen Zugriff haben. Keine verdeckte Auswertung — Voraussetzung für Betriebsrats-Tauglichkeit.")
                            .font(.system(size: 12))
                            .foregroundStyle(InterfacePalette.sekundaer)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .background(Premium.void)
    }
    private var prinzipien: [(titel: String, symbol: String, text: String)] {
        [
            ("Zweckbindung", "target", "Nur Organisations- und Zuständigkeitszwecke — keine Bewertung individueller Leistung."),
            ("Datenminimierung", "leaf", "Skills und Kapazität nur soweit für Staffing nötig; Notizen freiwillig."),
            ("Transparenz", "eye", "Audit-Tab zeigt Strukturänderungen; Profile sind einsehbar."),
            ("Mitbestimmung", "person.3", "Betriebsvereinbarung vor personenscharfen Auswertungen.")
        ]
    }
}
