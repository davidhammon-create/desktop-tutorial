import SwiftUI
struct OpportunismaKontextLeiste: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        HStack(spacing: 8) {
            ketteItem("Fragebogen", ok: vm.fragebogenAbgeschlossen || !vm.fragebogenAntworten.isEmpty, tab: .fragebogen)
            Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
            ketteItem("Strategos", ok: vm.verknuepftesStrategosId != nil || vm.strategosSzenarien.isEmpty == false, tab: .strategosLink)
            Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
            ketteItem("Lagebild", ok: vm.fragebogenAbgeschlossen, tab: .uebersicht)
            Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
            ketteItem("Module", ok: vm.modulQuellen.contains { $0.aktiv && $0.modul != .fragebogen }, tab: .dossier)
            Spacer()
            if let name = vm.verknuepftesStrategosName {
                Label(name, systemImage: "link")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(OpportunismaTheme.sidebarBg)
        .overlay(OpportunismaTheme.line.frame(height: 1), alignment: .bottom)
    }
    private func ketteItem(_ titel: String, ok: Bool, tab: OpportunismaTab) -> some View {
        Button {
            vm.selectedTab = tab
        } label: {
            HStack(spacing: 4) {
                Image(systemName: ok ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 9))
                    .foregroundStyle(ok ? OpportunismaTheme.red : OpportunismaTheme.gray)
                Text(titel.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.ink)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(OpportunismaTheme.card, in: Capsule())
            .overlay(Capsule().stroke(OpportunismaTheme.line))
        }
        .buttonStyle(.plain)
    }
}
struct OpportunismaStrategosLinkView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PragWidgetCard(titel: "Strategos-Erweiterung", transparenz: .opportunismaWidget(
                titel: "Strategos ↔ Opportunisma",
                formel: "Enterprise-Daten → Unternehmens-Lagebild → Module",
                begruendung: "Opportunisma operationalisiert Strategos-Analysen für Politik, Wirtschaft und Wissenschaft.",
                ergebnis: vm.verknuepftesStrategosName ?? "Nicht verknüpft"
            )) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Opportunisma ist die Umsetzungsebene von Strategos: Vertrags-, Patent- und Situationsanalysen fließen in Unternehmensposition, Netzwerk, Risiken und Strategie-Bäume ein.")
                        .font(.system(size: 10))
                        .foregroundStyle(OpportunismaTheme.gray)
                    if vm.strategosSzenarien.isEmpty {
                        Text("Kein Strategos-Szenario vorhanden. Legen Sie zuerst in Strategos ein Enterprise-Szenario an — der Fragebogen kann trotzdem starten.")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(OpportunismaTheme.red)
                    }
                }
            }
            PragWidgetCard(titel: "Szenario verknüpfen") {
                if vm.strategosSzenarien.isEmpty {
                    Text("Strategos → Neues Enterprise-Szenario anlegen")
                        .font(.system(size: 10)).foregroundStyle(OpportunismaTheme.gray)
                } else {
                    VStack(spacing: 6) {
                        ForEach(Array(vm.strategosSzenarien.enumerated()), id: \.offset) { idx, sz in
                            let id = sz.id ?? "sz-\(idx)"
                            let aktiv = vm.verknuepftesStrategosId == id
                            Button {
                                vm.verknuepftesStrategosId = id
                                Task { await vm.synchronisiereMitStrategos() }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sz.titel).font(.system(size: 11, weight: aktiv ? .bold : .medium))
                                        if let rg = sz.rechtsgebiet {
                                            Text(rg).font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
                                        }
                                    }
                                    Spacer()
                                    if aktiv {
                                        Image(systemName: "link.circle.fill").foregroundStyle(OpportunismaTheme.red)
                                    }
                                }
                                .padding(10)
                                .background(aktiv ? OpportunismaTheme.red.opacity(0.12) : OpportunismaTheme.card, in: OpportunismaTheme.buttonShape)
                                .overlay(OpportunismaTheme.buttonShape.stroke(aktiv ? OpportunismaTheme.red : OpportunismaTheme.line))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if let sz = vm.verknuepftesStrategos {
                strategosDetails(sz)
            }
            PragWidgetCard(titel: "Vertrags-Kausalität (Strategos)") {
                if let sz = vm.verknuepftesStrategos,
                   let va = StrategosOpportunismaVertragsService.vertragsAnalyseDict(fuer: sz) {
                    StrategosOpportunismaVertragsPanel(vertrag: va, szenario: sz)
                    Button("In Opportunisma vertiefen") { vm.selectedTab = .machtStrategie }
                        .font(.system(size: 9, weight: .bold))
                        .buttonStyle(FenlynineOSGlassBorderedButtonStyle())
                        .tint(OpportunismaTheme.red)
                } else {
                    Text("Vertragsanalyse in Strategos (Schritt 3) durchführen — Kausalität erscheint hier automatisch.")
                        .font(.system(size: 10)).foregroundStyle(OpportunismaTheme.gray)
                }
            }
            PragWidgetCard(titel: "Modul-Verknüpfungen") {
                VStack(spacing: 8) {
                    ForEach(vm.modulQuellen.filter { $0.modul != .fragebogen && $0.modul != .strategosLink }) { mq in
                        HStack(alignment: .top) {
                            Image(systemName: mq.aktiv ? "circle.fill" : "circle")
                                .font(.system(size: 6))
                                .foregroundStyle(mq.aktiv ? OpportunismaTheme.red : OpportunismaTheme.gray)
                                .padding(.top, 4)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mq.modul.titel).font(.system(size: 9, weight: .bold))
                                if mq.quellen.isEmpty {
                                    Text("Wartet auf Fragebogen-Auswertung").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
                                } else {
                                    ForEach(mq.quellen.prefix(2), id: \.self) { q in
                                        Text("↳ \(q)").font(.system(size: 8)).foregroundStyle(OpportunismaTheme.gray)
                                    }
                                }
                            }
                            Spacer()
                            Button("Öffnen") { vm.selectedTab = mq.modul }
                                .font(.system(size: 8, weight: .bold))
                                .buttonStyle(.plain)
                                .foregroundStyle(OpportunismaTheme.red)
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func strategosDetails(_ sz: StrategosScenario) -> some View {
        PragWidgetCard(titel: "Verknüpfte Strategos-Daten") {
            VStack(alignment: .leading, spacing: 8) {
                if let ki = sz.ki_analyse?.dictValue {
                    if ki["vertrags_analyse"] != nil {
                        Label("Vertragsanalyse vorhanden → Risiken & Ressourcen", systemImage: "doc.text")
                            .font(.system(size: 9))
                    }
                    if ki["patent_analyse"] != nil {
                        Label("Patent/IP-Analyse → Wissenschaft & Innovation", systemImage: "lightbulb")
                            .font(.system(size: 9))
                    }
                }
                if sz.situationsanalyse != nil {
                    Label("Situationsanalyse → Politik & Regulatorik", systemImage: "chart.bar")
                        .font(.system(size: 9))
                }
                if let ctx = sz.unternehmenskontext?.dictValue?["unternehmen_name"] as? String {
                    Text("Unternehmen: \(ctx)").font(.system(size: 9, weight: .bold))
                }
            }
        }
    }
}
struct PragModulQuellenBadge: View {
    let quellen: [String]
    var body: some View {
        if !quellen.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "link").font(.system(size: 7))
                Text(quellen.first ?? "")
                    .font(.system(size: 7))
                    .lineLimit(1)
            }
            .foregroundStyle(OpportunismaTheme.gray)
        }
    }
}
struct PragModulKopf: View {
    @Bindable var vm: OpportunismaViewModel
    let tab: OpportunismaTab
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            let quellen = vm.quellen(fuer: tab)
            if !quellen.isEmpty {
                PragModulQuellenBadge(quellen: quellen)
            } else if !vm.fragebogenAbgeschlossen {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 9))
                        .foregroundStyle(OpportunismaTheme.red)
                    Text("Daten aus Lagefragebogen (Multiple Choice) und Strategos-Verknüpfung.")
                        .font(.system(size: 8))
                        .foregroundStyle(OpportunismaTheme.gray)
                    Spacer()
                    Button("Fragebogen") { vm.selectedTab = .fragebogen }
                        .font(.system(size: 8, weight: .bold))
                        .buttonStyle(.plain)
                        .foregroundStyle(OpportunismaTheme.red)
                }
            }
            if let sz = vm.verknuepftesStrategosName, tab != .strategosLink && tab != .fragebogen {
                Label("Strategos: \(sz)", systemImage: "link.circle")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(OpportunismaTheme.red)
            }
        }
    }
}
