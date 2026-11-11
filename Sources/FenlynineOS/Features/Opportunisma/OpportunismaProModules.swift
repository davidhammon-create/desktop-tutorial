import SwiftUI
struct OpportunismaProActionBoardView: View {
    @Bindable var vm: OpportunismaViewModel
    private let columns: [OpportunismaActionStatus] = [.offen, .laeuft, .erledigt]
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Board")
                        .font(OpportunismaPro.display)
                        .foregroundStyle(OpportunismaPro.text)
                    Text("CI wird zur Ausführung — Kanban der nächsten Züge.")
                        .font(OpportunismaPro.caption)
                        .foregroundStyle(OpportunismaPro.textSoft)
                }
                Spacer()
                Button {
                    vm.regeneriereActionBoardAusLage()
                } label: {
                    Label("Aus Lage aktualisieren", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(OpportunismaProGhostButton())
            }
            HStack(alignment: .top, spacing: 14) {
                ForEach(columns, id: \.self) { col in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(col.label.uppercased())
                                .font(OpportunismaPro.micro)
                                .tracking(0.8)
                                .foregroundStyle(OpportunismaPro.textFaint)
                            Spacer()
                            Text("\(vm.actionItems.filter { $0.status == col }.count)")
                                .font(OpportunismaPro.micro)
                                .foregroundStyle(OpportunismaPro.textSoft)
                        }
                        ForEach(vm.actionItems.filter { $0.status == col }) { item in
                            actionCard(item)
                        }
                        if vm.actionItems.filter({ $0.status == col }).isEmpty {
                            Text("—")
                                .font(OpportunismaPro.caption)
                                .foregroundStyle(OpportunismaPro.textFaint)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .opportunismaGlass(elevated: true, corner: OpportunismaPro.radius)
                }
            }
        }
    }
    private func actionCard(_ item: OpportunismaActionItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.prio.label.uppercased())
                    .font(OpportunismaPro.micro)
                    .foregroundStyle(item.prio.color)
                Spacer()
                Menu {
                    ForEach(OpportunismaActionStatus.allCases, id: \.self) { s in
                        Button(s.label) { vm.setzeActionStatus(item.id, s) }
                    }
                    Divider()
                    Button("Modul öffnen") { vm.selectedTab = item.tab }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(OpportunismaPro.textSoft)
                }
            }
            Text(item.titel)
                .font(OpportunismaPro.section)
                .foregroundStyle(OpportunismaPro.text)
            Text(item.detail)
                .font(OpportunismaPro.caption)
                .foregroundStyle(OpportunismaPro.textSoft)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Label(item.owner, systemImage: "person.fill")
                Label(item.dueLabel, systemImage: "calendar")
            }
            .font(OpportunismaPro.micro)
            .foregroundStyle(OpportunismaPro.textFaint)
            Button {
                vm.selectedTab = item.tab
            } label: {
                Label(item.tab.proTitel, systemImage: item.tab.symbol)
                    .font(OpportunismaPro.micro)
            }
            .buttonStyle(OpportunismaProGhostButton())
        }
        .padding(12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.6))
    }
}
struct OpportunismaProChancenView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chancenradar")
                        .font(OpportunismaPro.display)
                        .foregroundStyle(OpportunismaPro.text)
                    Text("Sector-led GTM: White-Space, Peer-Moves, Kooperationsfenster — priorisiert nach Score.")
                        .font(OpportunismaPro.caption)
                        .foregroundStyle(OpportunismaPro.textSoft)
                        .frame(maxWidth: 480, alignment: .leading)
                }
                Spacer()
                OpportunismaProMetricTile(label: "Ø Chance", value: "\(vm.chanceScore)", hint: "gewichteter Score", tone: OpportunismaPro.signal)
                    .frame(width: 160)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(vm.chancen.sorted(by: { $0.score > $1.score })) { c in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(c.sektor.uppercased())
                                .font(OpportunismaPro.micro)
                                .foregroundStyle(OpportunismaPro.accent)
                                .tracking(0.6)
                            Spacer()
                            Text("\(c.score)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(OpportunismaPro.text)
                        }
                        Text(c.titel)
                            .font(OpportunismaPro.title)
                            .foregroundStyle(OpportunismaPro.text)
                        Text(c.begruendung)
                            .font(OpportunismaPro.caption)
                            .foregroundStyle(OpportunismaPro.textSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Label("Aufwand \(c.effort)", systemImage: "clock")
                                .font(OpportunismaPro.micro)
                                .foregroundStyle(OpportunismaPro.textFaint)
                            Spacer()
                            Button("In Action Board") {
                                vm.actionItems.insert(
                                    .init(titel: c.titel, detail: c.begruendung, status: .offen, prio: c.score >= 75 ? .hoch : .mittel, tab: .chancen),
                                    at: 0
                                )
                                vm.selectedTab = .actionBoard
                            }
                            .buttonStyle(OpportunismaProPrimaryButton())
                        }
                    }
                    .padding(18)
                    .opportunismaGlass(elevated: true)
                }
            }
        }
    }
}
struct OpportunismaProFeedView: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("CI-Feed")
                .font(OpportunismaPro.display)
                .foregroundStyle(OpportunismaPro.text)
            Text("Was sich bewegt — aus Lage, Wettbewerb, Risiko und Sektor. Klick öffnet das passende Modul.")
                .font(OpportunismaPro.caption)
                .foregroundStyle(OpportunismaPro.textSoft)
            VStack(spacing: 0) {
                ForEach(Array(vm.feedEvents.enumerated()), id: \.element.id) { idx, ev in
                    Button {
                        if let t = ev.tab { vm.selectedTab = t }
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(OpportunismaPro.accent)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: OpportunismaPro.accent.opacity(0.6), radius: 6)
                                if idx < vm.feedEvents.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 12)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(ev.zeit)
                                        .font(OpportunismaPro.micro)
                                        .foregroundStyle(OpportunismaPro.textFaint)
                                    Text("·")
                                        .foregroundStyle(OpportunismaPro.textFaint)
                                    Text(ev.quelle.uppercased())
                                        .font(OpportunismaPro.micro)
                                        .foregroundStyle(OpportunismaPro.accent)
                                }
                                Text(ev.titel)
                                    .font(OpportunismaPro.section)
                                    .foregroundStyle(OpportunismaPro.text)
                                    .multilineTextAlignment(.leading)
                                Text(ev.wirkung)
                                    .font(OpportunismaPro.caption)
                                    .foregroundStyle(OpportunismaPro.textSoft)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(OpportunismaPro.textFaint)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if idx < vm.feedEvents.count - 1 {
                        Divider().overlay(Color.white.opacity(0.08))
                    }
                }
            }
            .padding(18)
            .opportunismaGlass(elevated: true)
        }
    }
}
struct OpportunismaProCommandDashboard: View {
    @Bindable var vm: OpportunismaViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                OpportunismaProMetricTile(label: "Position", value: "\(vm.machtIndex)", hint: vm.dominanzLabel, tone: OpportunismaPro.accent)
                OpportunismaProMetricTile(label: "Offene Züge", value: "\(vm.offenActions)", hint: "Action Board", tone: OpportunismaPro.accent)
                OpportunismaProMetricTile(label: "Chance Ø", value: "\(vm.chanceScore)", hint: "Sektor-Score", tone: OpportunismaPro.signal)
                OpportunismaProMetricTile(label: "Setup", value: "\(Int(vm.journeyFortschritt * 100))%", hint: vm.entscheidungsreif ? "reif" : "offen", tone: vm.entscheidungsreif ? OpportunismaPro.signal : OpportunismaPro.warn)
            }
            OpportunismaProSection(titel: "Schnellzugriff", untertitel: "Die verkaufsfähigen Oberflächen") {
                HStack(spacing: 10) {
                    Button { vm.selectedTab = .journey } label: { Label("Journey", systemImage: "map.fill") }
                        .buttonStyle(OpportunismaProGhostButton())
                    Button { vm.selectedTab = .playbooks } label: { Label("Playbooks", systemImage: "book.closed.fill") }
                        .buttonStyle(OpportunismaProGhostButton())
                    Button { vm.selectedTab = .warRoom } label: { Label("War Room", systemImage: "shield.lefthalf.filled") }
                        .buttonStyle(OpportunismaProGhostButton())
                    Button { vm.selectedTab = .weeklyBrief } label: { Label("Weekly", systemImage: "newspaper.fill") }
                        .buttonStyle(OpportunismaProGhostButton())
                    Button { vm.selectedTab = .exportStudio } label: { Label("Export", systemImage: "square.and.arrow.up.on.square") }
                        .buttonStyle(OpportunismaProGhostButton())
                    Button { vm.selectedTab = .actionBoard } label: { Label("Actions", systemImage: "rectangle.3.group") }
                        .buttonStyle(OpportunismaProPrimaryButton())
                }
            }
            HStack(alignment: .top, spacing: 14) {
                OpportunismaProSection(titel: "Hebel", untertitel: "Stärken & Engpässe") {
                    ForEach((vm.hebel.isEmpty ? vm.ressourcen : vm.hebel).prefix(5)) { h in
                        HStack {
                            Text(h.name).font(OpportunismaPro.caption).foregroundStyle(OpportunismaPro.textSoft)
                            Spacer()
                            Text("\(h.wert)").font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
                        }
                    }
                    Button("Ressourcen öffnen") { vm.selectedTab = .ressourcen }
                        .buttonStyle(OpportunismaProGhostButton())
                }
                OpportunismaProSection(titel: "Dimensionen", untertitel: "Politik · Markt · Wissenschaft") {
                    ForEach(vm.dimensionen.prefix(5)) { d in
                        HStack {
                            Text(d.name).font(OpportunismaPro.caption).foregroundStyle(OpportunismaPro.textSoft)
                            Spacer()
                            Text("\(d.wert)").font(OpportunismaPro.section).foregroundStyle(OpportunismaPro.text)
                        }
                    }
                    Button("Positionsradar") { vm.selectedTab = .hegemonogramm }
                        .buttonStyle(OpportunismaProGhostButton())
                }
                OpportunismaProSection(titel: "Ziele", untertitel: "Fortschritt") {
                    OpportunismaProZieleView(vm: vm)
                }
            }
            if let gap = vm.groessteHegemonieLuecke {
                OpportunismaProSection(titel: "Größte Positions-Lücke", untertitel: gap.label, accent: OpportunismaPro.warn) {
                    Text("Gap \(Int(gap.gap)) Punkte — priorisieren oder in Action Board übernehmen.")
                        .font(OpportunismaPro.caption)
                        .foregroundStyle(OpportunismaPro.textSoft)
                    Button("Als Action") {
                        vm.actionItems.insert(
                            .init(titel: "Lücke schließen: \(gap.label)", detail: "Gap \(Int(gap.gap))", status: .offen, prio: .hoch, tab: .hegemonogramm),
                            at: 0
                        )
                        vm.speichereProSession()
                        vm.selectedTab = .actionBoard
                    }
                    .buttonStyle(OpportunismaProPrimaryButton())
                }
            }
        }
    }
}
